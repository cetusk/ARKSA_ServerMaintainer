//! arksa-notify
//!
//! Notification subsystem for ARKSA_ServerMaintainer.
//! - `discord`: Discord Webhook with an async send queue
//!   (replaces `discord.pas`'s TDiscordSenderThread).
//! - `tray`: Windows toast / tray balloon notification
//!   (replaces `notify_ui.pas` / TrayIcon usage in the original).

pub mod discord;
pub mod tray;

/// Event kinds the notification layer cares about.
/// Mirrors the upstream tray/Discord notification kind enum.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NotifyEvent {
    ServerStarting,
    ServerOnline,
    ServerStopped,
    ServerCrashDetected,
    AsasmUpdateAvailable,
    ServerAppUpdateAvailable,
}
