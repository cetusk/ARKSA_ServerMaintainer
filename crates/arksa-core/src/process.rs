//! Win32 process monitoring.
//!
//! Ports the parts of upstream `asautils.pas` we need to watch the
//! `ArkAscendedServer.exe` lifecycle:
//!
//!   - `find_pid_by_path`     ↔ asautils.GetProcessIDFromPath
//!   - `is_process_alive`     ↔ asautils.IsProcessRunning
//!   - `working_set_mb`       ↔ asautils.ProcessMemoryMB
//!   - `cpu_time_ms`          ↔ asautils.ProcessTimeUSE
//!   - `started_at_unix`      ↔ asautils.ProcessTimePast
//!   - `close_main_window`    ↔ asautils.closeServer (EnumWindows + WM_CLOSE)
//!
//! All `OpenProcess`/`CloseHandle` pairs go through `ProcessHandle` so a leak
//! is structurally impossible. Upstream's Pascal version had several early-exit
//! paths that returned without `CloseHandle`; that bug class can not occur
//! here.

#![cfg(target_os = "windows")]

use std::path::{Path, PathBuf};

use windows::core::PWSTR;
use windows::Win32::Foundation::{CloseHandle, BOOL, HANDLE, HWND, LPARAM, MAX_PATH, WPARAM};
use windows::Win32::System::Diagnostics::ToolHelp::{
    CreateToolhelp32Snapshot, Process32FirstW, Process32NextW, PROCESSENTRY32W,
    TH32CS_SNAPPROCESS,
};
use windows::Win32::System::ProcessStatus::{GetProcessMemoryInfo, PROCESS_MEMORY_COUNTERS};
use windows::Win32::System::Threading::{
    GetProcessTimes, OpenProcess, QueryFullProcessImageNameW, PROCESS_NAME_FORMAT,
    PROCESS_QUERY_INFORMATION, PROCESS_QUERY_LIMITED_INFORMATION, PROCESS_TERMINATE,
    PROCESS_VM_READ,
};
use windows::Win32::UI::WindowsAndMessaging::{
    EnumWindows, GetWindowThreadProcessId, PostMessageW, WM_CLOSE,
};

use crate::error::Result;

/// Owned Win32 process handle. Closed automatically on drop.
pub struct ProcessHandle {
    raw: HANDLE,
}

impl ProcessHandle {
    /// Open a handle to `pid` with the rights needed for status / memory /
    /// time queries.
    pub fn open(pid: u32) -> Result<Self> {
        let raw = unsafe {
            OpenProcess(
                PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
                false,
                pid,
            )?
        };
        Ok(Self { raw })
    }

    /// Cheaper open used when only the executable path is needed
    /// (`QueryFullProcessImageNameW` accepts the *limited* right).
    pub fn open_limited(pid: u32) -> Result<Self> {
        let raw = unsafe { OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid)? };
        Ok(Self { raw })
    }

    pub fn open_terminate(pid: u32) -> Result<Self> {
        let raw = unsafe { OpenProcess(PROCESS_TERMINATE, false, pid)? };
        Ok(Self { raw })
    }

    pub fn raw(&self) -> HANDLE {
        self.raw
    }
}

impl Drop for ProcessHandle {
    fn drop(&mut self) {
        if !self.raw.is_invalid() {
            unsafe {
                let _ = CloseHandle(self.raw);
            }
        }
    }
}

/// Iterate the Toolhelp32 snapshot and return the PID of the first running
/// process whose full image path equals `target` (case-insensitive).
///
/// Returns `None` if no match is found, which the caller treats as
/// "not currently running".
pub fn find_pid_by_path(target: &Path) -> Result<Option<u32>> {
    let target_norm = canonicalize_for_compare(target);

    let snapshot = unsafe { CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)? };
    let _guard = ProcessHandle { raw: snapshot };

    let mut entry = PROCESSENTRY32W {
        dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
        ..Default::default()
    };

    let mut ok = unsafe { Process32FirstW(snapshot, &mut entry).is_ok() };
    while ok {
        let pid = entry.th32ProcessID;
        if pid != 0 {
            if let Ok(handle) = ProcessHandle::open_limited(pid) {
                if let Some(path) = full_image_path(&handle) {
                    if canonicalize_for_compare(&path) == target_norm {
                        return Ok(Some(pid));
                    }
                }
            }
        }
        ok = unsafe { Process32NextW(snapshot, &mut entry).is_ok() };
    }
    Ok(None)
}

/// Returns true when a process matching `target` is currently running.
pub fn is_process_alive(target: &Path) -> Result<bool> {
    Ok(find_pid_by_path(target)?.is_some())
}

/// Working set size of the process in MiB.
pub fn working_set_mb(handle: &ProcessHandle) -> Result<u64> {
    let mut counters = PROCESS_MEMORY_COUNTERS::default();
    let cb = std::mem::size_of::<PROCESS_MEMORY_COUNTERS>() as u32;
    unsafe { GetProcessMemoryInfo(handle.raw(), &mut counters, cb)? };
    Ok((counters.WorkingSetSize as u64) / (1024 * 1024))
}

/// Total CPU time consumed (kernel + user) in milliseconds.
pub fn cpu_time_ms(handle: &ProcessHandle) -> Result<u64> {
    let times = process_times(handle)?;
    Ok(filetime_to_100ns(times.kernel) / 10_000 + filetime_to_100ns(times.user) / 10_000)
}

/// Process creation time as a Unix timestamp (seconds since epoch).
/// `FILETIME` is 100-nanosecond intervals since 1601-01-01; the upstream code
/// subtracts the magic constant `116444736000000000` to convert to the Unix
/// epoch — we do the same, in 100 ns units, then divide.
pub fn started_at_unix(handle: &ProcessHandle) -> Result<i64> {
    let times = process_times(handle)?;
    let ns100 = filetime_to_100ns(times.creation);
    const EPOCH_DIFF_100NS: i64 = 116_444_736_000_000_000;
    Ok((ns100 as i64 - EPOCH_DIFF_100NS) / 10_000_000)
}

/// Process uptime in seconds, as `now_unix - started_at_unix`.
pub fn uptime_secs(handle: &ProcessHandle, now_unix: i64) -> Result<i64> {
    Ok((now_unix - started_at_unix(handle)?).max(0))
}

/// Post `WM_CLOSE` to every top-level window owned by `pid`. This is the
/// graceful-close path used by upstream `closeServer` — combined with the RCON
/// `SaveWorld DoExit` it gives the server a chance to flush state before
/// shutting down.
pub fn close_main_window(pid: u32) -> Result<()> {
    unsafe extern "system" fn enum_proc(hwnd: HWND, lparam: LPARAM) -> BOOL {
        let target_pid = lparam.0 as u32;
        let mut owner_pid: u32 = 0;
        GetWindowThreadProcessId(hwnd, Some(&mut owner_pid));
        if owner_pid == target_pid {
            // PostMessageW in `windows` 0.58 takes HWND directly (not Option<HWND>).
            // Explicit WPARAM/LPARAM constructors avoid generic-Param inference
            // ambiguity that `Default::default()` would otherwise cause.
            let _ = PostMessageW(hwnd, WM_CLOSE, WPARAM(0), LPARAM(0));
        }
        BOOL(1) // continue enumeration so all top-level windows get the message
    }
    unsafe {
        EnumWindows(Some(enum_proc), LPARAM(pid as isize))?;
    }
    Ok(())
}

// ---------- helpers ---------------------------------------------------------

struct Times {
    creation: windows::Win32::Foundation::FILETIME,
    kernel: windows::Win32::Foundation::FILETIME,
    user: windows::Win32::Foundation::FILETIME,
}

fn process_times(handle: &ProcessHandle) -> Result<Times> {
    use windows::Win32::Foundation::FILETIME;
    let mut creation = FILETIME::default();
    let mut exit = FILETIME::default();
    let mut kernel = FILETIME::default();
    let mut user = FILETIME::default();
    unsafe {
        GetProcessTimes(handle.raw(), &mut creation, &mut exit, &mut kernel, &mut user)?;
    }
    Ok(Times {
        creation,
        kernel,
        user,
    })
}

fn filetime_to_100ns(ft: windows::Win32::Foundation::FILETIME) -> u64 {
    ((ft.dwHighDateTime as u64) << 32) | (ft.dwLowDateTime as u64)
}

fn full_image_path(handle: &ProcessHandle) -> Option<PathBuf> {
    let mut buf: Vec<u16> = vec![0u16; (MAX_PATH as usize) * 2];
    let mut size = buf.len() as u32;
    let res = unsafe {
        QueryFullProcessImageNameW(
            handle.raw(),
            PROCESS_NAME_FORMAT(0),
            PWSTR(buf.as_mut_ptr()),
            &mut size,
        )
    };
    if res.is_err() || size == 0 {
        return None;
    }
    buf.truncate(size as usize);
    let s = String::from_utf16_lossy(&buf);
    Some(PathBuf::from(s))
}

fn canonicalize_for_compare(p: &Path) -> String {
    // Case-insensitive match because Windows paths are. Using lossy conversion
    // is acceptable here — we only compare against another path that came out
    // of the same Win32 query and ASCII-only directory names dominate ARK's
    // install layout.
    p.to_string_lossy().to_ascii_lowercase().replace('/', "\\")
}
