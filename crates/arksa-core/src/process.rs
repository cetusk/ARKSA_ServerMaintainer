//! Win32 process monitoring. Replaces the Win32 calls scattered through
//! `asautils.pas`:
//!   - `GetProcessIDFromPath`
//!   - `IsProcessRunning`
//!   - `ProcessMemoryMB` (GetProcessMemoryInfo)
//!   - `ProcessTimeUSE` / `ProcessTimePast` (GetProcessTimes)
//!   - `closeServer` (EnumWindows + WM_CLOSE)
//!
//! Uses the `windows` crate for type-safe Win32 access.

// TODO Phase 1: implement using windows::Win32::System::ProcessStatus / Threading.
