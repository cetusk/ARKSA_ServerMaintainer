//! High-level server lifecycle: start, graceful stop, status snapshot.
//!
//! Combines `process` (Win32 PID/memory/window) and `rcon` (graceful save +
//! exit). `Profile::server_command_line` provides the launch arguments —
//! upstream stores them as a single pre-assembled string in
//! `[General] MM_Command_Val`, which we honour verbatim for now.

#![cfg(target_os = "windows")]

use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;
use std::time::{Duration, Instant};

use crate::error::{Error, Result};
use crate::process;
use crate::profile::Profile;
use crate::rcon::RconClient;

/// Snapshot of a server's runtime state at one instant.
#[derive(Debug, Clone, Default)]
pub struct ServerStatus {
    pub running: bool,
    pub pid: Option<u32>,
    pub memory_mb: u64,
    pub cpu_time_ms: u64,
    /// `now - process creation time`, in seconds.
    pub uptime_secs: i64,
    /// Process creation time as a Unix timestamp.
    pub started_at_unix: Option<i64>,
}

/// Result of a stop attempt — useful for the UI to explain what actually
/// happened.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StopOutcome {
    /// The process was already not running when we asked.
    NotRunning,
    /// Server received `SaveWorld` + `DoExit` over RCON and exited cleanly.
    GracefulRcon,
    /// RCON could not save / exit; we sent `WM_CLOSE` to the server window.
    GracefulWindowClose,
    /// Both paths failed; the process is still alive after our timeout.
    StillRunning,
}

/// Subset of options consumers want to tune for `stop_graceful`.
#[derive(Debug, Clone)]
pub struct StopOptions {
    /// How long to wait between issuing `SaveWorld DoExit` and giving up on
    /// graceful RCON exit.
    pub rcon_wait: Duration,
    /// How long to wait between issuing `WM_CLOSE` and declaring failure.
    pub window_wait: Duration,
}

impl Default for StopOptions {
    fn default() -> Self {
        Self {
            rcon_wait: Duration::from_secs(30),
            window_wait: Duration::from_secs(15),
        }
    }
}

/// Spawn `ArkAscendedServer.exe` for `profile`, returning its PID.
///
/// `exe_dir` is the directory containing the ARKSA tool executable, used to
/// resolve the profile's install path when `Sys_RelativePath = 1`.
pub fn start(profile: &Profile, exe_dir: &Path) -> Result<u32> {
    let install = profile
        .resolved_install_path(exe_dir)
        .ok_or_else(|| Error::Other("profile is missing install location".into()))?;
    let bin_dir = install.join("ShooterGame").join("Binaries").join("Win64");

    let cmd_line = profile
        .server_command_line()
        .ok_or_else(|| Error::Other("profile is missing MM_Command_Val".into()))?;

    let (exe_name, args) = split_command_line(&cmd_line);
    let exe_path = bin_dir.join(&exe_name);
    if !exe_path.exists() {
        return Err(Error::Other(format!(
            "server executable not found: {}",
            exe_path.display()
        )));
    }

    let mut command = Command::new(&exe_path);
    command.current_dir(&bin_dir);
    command.args(&args);
    let child = command.spawn()?;
    Ok(child.id())
}

/// Send `SaveWorld` and `DoExit` over RCON, fall back to `WM_CLOSE` if RCON is
/// unusable or the process is still alive afterwards.
pub fn stop_graceful(
    profile: &Profile,
    exe_dir: &Path,
    options: StopOptions,
) -> Result<StopOutcome> {
    let exe_path = profile
        .server_exe_path(exe_dir)
        .ok_or_else(|| Error::Other("profile is missing install location".into()))?;

    let Some(pid) = process::find_pid_by_path(&exe_path)? else {
        return Ok(StopOutcome::NotRunning);
    };

    let rcon_ok = try_rcon_save_and_exit(profile).is_ok();
    if rcon_ok && wait_until_gone(&exe_path, options.rcon_wait)? {
        return Ok(StopOutcome::GracefulRcon);
    }

    process::close_main_window(pid)?;
    if wait_until_gone(&exe_path, options.window_wait)? {
        return Ok(StopOutcome::GracefulWindowClose);
    }

    Ok(StopOutcome::StillRunning)
}

/// One-shot status snapshot. Cheap enough to call from a UI poll timer.
pub fn status(profile: &Profile, exe_dir: &Path, now_unix: i64) -> Result<ServerStatus> {
    let exe_path = profile
        .server_exe_path(exe_dir)
        .ok_or_else(|| Error::Other("profile is missing install location".into()))?;

    let Some(pid) = process::find_pid_by_path(&exe_path)? else {
        return Ok(ServerStatus {
            running: false,
            ..Default::default()
        });
    };

    let handle = process::ProcessHandle::open(pid)?;
    let memory_mb = process::working_set_mb(&handle).unwrap_or(0);
    let cpu_time_ms = process::cpu_time_ms(&handle).unwrap_or(0);
    let started_at_unix = process::started_at_unix(&handle).ok();
    let uptime_secs = started_at_unix
        .map(|s| (now_unix - s).max(0))
        .unwrap_or(0);

    Ok(ServerStatus {
        running: true,
        pid: Some(pid),
        memory_mb,
        cpu_time_ms,
        uptime_secs,
        started_at_unix,
    })
}

// ---- helpers --------------------------------------------------------------

fn try_rcon_save_and_exit(profile: &Profile) -> Result<()> {
    if !profile.rcon_enabled() {
        return Err(Error::Other("RCON is disabled in this profile".into()));
    }
    let port = profile
        .rcon_port()
        .ok_or_else(|| Error::Other("missing SE_RCONPort".into()))?;
    let password = profile
        .admin_password()
        .ok_or_else(|| Error::Other("missing Edit_ServerAdminPassword".into()))?;
    if password.is_empty() {
        return Err(Error::Other("admin password is empty".into()));
    }
    let client = RconClient::connect("127.0.0.1", port, password)?;
    let _ = client.execute("SaveWorld")?;
    let _ = client.execute("DoExit")?;
    Ok(())
}

fn wait_until_gone(exe_path: &Path, max: Duration) -> Result<bool> {
    let deadline = Instant::now() + max;
    while Instant::now() < deadline {
        if process::find_pid_by_path(exe_path)?.is_none() {
            return Ok(true);
        }
        thread::sleep(Duration::from_millis(500));
    }
    Ok(process::find_pid_by_path(exe_path)?.is_none())
}

/// Tiny CommandLineToArgv-style splitter: respects `"..."` as a single token,
/// otherwise splits on whitespace. Sufficient for ARK launch lines where the
/// only quoting in practice is around session names that contain spaces.
fn split_command_line(line: &str) -> (PathBuf, Vec<String>) {
    let mut tokens: Vec<String> = Vec::new();
    let mut buf = String::new();
    let mut in_quotes = false;
    for ch in line.chars() {
        match ch {
            '"' => in_quotes = !in_quotes,
            c if c.is_whitespace() && !in_quotes => {
                if !buf.is_empty() {
                    tokens.push(std::mem::take(&mut buf));
                }
            }
            c => buf.push(c),
        }
    }
    if !buf.is_empty() {
        tokens.push(buf);
    }

    let exe = tokens
        .first()
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("ArkAscendedServer.exe"));
    let args = if tokens.is_empty() {
        Vec::new()
    } else {
        tokens[1..].to_vec()
    };
    (exe, args)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn splits_basic_command() {
        let (exe, args) = split_command_line(
            "ArkAscendedServer.exe TheIsland_WP?listen?Port=7777 -mods=123 -log",
        );
        assert_eq!(exe.to_str().unwrap(), "ArkAscendedServer.exe");
        assert_eq!(
            args,
            vec![
                "TheIsland_WP?listen?Port=7777".to_string(),
                "-mods=123".to_string(),
                "-log".to_string(),
            ]
        );
    }

    #[test]
    fn respects_quoted_session_name() {
        let (exe, args) = split_command_line(
            r#"ArkAscendedServer.exe "TheIsland_WP?listen?SessionName=My Cool Server" -log"#,
        );
        assert_eq!(exe.to_str().unwrap(), "ArkAscendedServer.exe");
        assert_eq!(
            args,
            vec![
                "TheIsland_WP?listen?SessionName=My Cool Server".to_string(),
                "-log".to_string(),
            ]
        );
    }

    #[test]
    fn empty_line_yields_default_exe() {
        let (exe, args) = split_command_line("");
        assert_eq!(exe.to_str().unwrap(), "ArkAscendedServer.exe");
        assert!(args.is_empty());
    }
}
