//! Windows toast notification.
//!
//! Uses `tauri-winrt-notification` to fire a single Win10/11 toast. There is
//! intentionally no persistent tray-icon UI here — the upstream tray menu is
//! out of scope for the personal-use rewrite.

use anyhow::Result;

#[cfg(target_os = "windows")]
pub fn show_toast(title: &str, body: &str) -> Result<()> {
    use tauri_winrt_notification::{Sound, Toast};
    Toast::new(Toast::POWERSHELL_APP_ID)
        .title(title)
        .text1(body)
        .sound(Some(Sound::Default))
        .show()
        .map_err(|e| anyhow::anyhow!("toast: {e}"))
}

#[cfg(not(target_os = "windows"))]
pub fn show_toast(_title: &str, _body: &str) -> Result<()> {
    // No-op on non-Windows builds so the rest of the workspace still
    // compiles for `cargo check` outside Windows.
    Ok(())
}
