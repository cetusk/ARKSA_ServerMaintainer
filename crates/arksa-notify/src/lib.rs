//! arksa-notify
//!
//! Notification subsystem for ARKSA_ServerMaintainer.
//! - `discord`: Discord Webhook with a synchronous blocking client
//!   (replaces `discord.pas`'s TDiscordSenderThread).
//! - `tray`: Windows toast notification
//!   (replaces `notify_ui.pas` / TrayIcon usage in the original).
//!
//! `NotifyConfig` aggregates the user's preferences (webhook URL, display
//! name, per-event toggles) and `dispatch` is the single entry point the GUI
//! calls when something interesting happens.

pub mod discord;
pub mod tray;

/// Event kinds the notification layer cares about. The `as usize` ordering is
/// the bit position in `NotifyConfig::events_enabled` and the character
/// position in the upstream-compatible `events_mask` string.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(usize)]
pub enum NotifyEvent {
    ServerStarting = 0,
    ServerOnline = 1,
    ServerStopped = 2,
    ServerCrashDetected = 3,
    AsasmUpdateAvailable = 4,
    ServerAppUpdateAvailable = 5,
}

impl NotifyEvent {
    pub const ALL: [NotifyEvent; 6] = [
        Self::ServerStarting,
        Self::ServerOnline,
        Self::ServerStopped,
        Self::ServerCrashDetected,
        Self::AsasmUpdateAvailable,
        Self::ServerAppUpdateAvailable,
    ];

    pub fn label(self) -> &'static str {
        match self {
            Self::ServerStarting => "Server starting",
            Self::ServerOnline => "Server online",
            Self::ServerStopped => "Server stopped",
            Self::ServerCrashDetected => "Server crash detected",
            Self::AsasmUpdateAvailable => "ARKSA tool update available",
            Self::ServerAppUpdateAvailable => "ARK server update available",
        }
    }
}

/// Per-event payload describing what the notification should say.
#[derive(Debug, Clone, Default)]
pub struct NotifyContext {
    pub profile_name: String,
    pub map_name: Option<String>,
    /// Free-form text appended after the standard fields. Used for things
    /// like the new BuildID for an update notification.
    pub extra: Option<String>,
}

impl NotifyContext {
    pub fn new(profile_name: impl Into<String>) -> Self {
        Self {
            profile_name: profile_name.into(),
            ..Default::default()
        }
    }

    pub fn with_map(mut self, map: impl Into<String>) -> Self {
        self.map_name = Some(map.into());
        self
    }

    pub fn with_extra(mut self, extra: impl Into<String>) -> Self {
        self.extra = Some(extra.into());
        self
    }
}

/// User-controlled notification preferences. Persisted by the caller (the GUI
/// stores it in `AppSettings`).
#[derive(Debug, Clone, Default)]
pub struct NotifyConfig {
    /// Discord webhook URL. Empty = Discord disabled.
    pub discord_webhook_url: String,
    /// Optional display name shown in titles. Falls back to "ARKSA".
    pub display_name: String,
    /// Per-event toggles. Index with `event as usize`.
    pub events_enabled: [bool; 6],
    /// If false, no Windows toast notifications are shown.
    pub tray_enabled: bool,
}

impl NotifyConfig {
    /// Read 6-character mask string ("100101" style) into the boolean array.
    /// Missing/short masks are treated as all-off.
    pub fn parse_events_mask(mask: &str) -> [bool; 6] {
        let mut out = [false; 6];
        for (i, ch) in mask.chars().take(6).enumerate() {
            out[i] = ch == '1';
        }
        out
    }

    pub fn events_mask_string(&self) -> String {
        self.events_enabled.iter().map(|b| if *b { '1' } else { '0' }).collect()
    }

    pub fn is_event_enabled(&self, event: NotifyEvent) -> bool {
        self.events_enabled
            .get(event as usize)
            .copied()
            .unwrap_or(false)
    }

    pub fn discord_enabled(&self) -> bool {
        !self.discord_webhook_url.trim().is_empty()
    }
}

/// Fire a notification. Uses both Discord and tray as configured. Errors are
/// logged via `tracing` but not returned — notifications should never break
/// the calling lifecycle code path.
pub fn dispatch(config: &NotifyConfig, event: NotifyEvent, ctx: &NotifyContext) {
    if !config.is_event_enabled(event) {
        return;
    }

    let title = title_for(event, &config.display_name);
    let body = body_for(event, ctx);

    if config.discord_enabled() {
        let combined = format!("**{title}**\n{body}");
        if let Err(e) = discord::send(&config.discord_webhook_url, &combined) {
            tracing::warn!(error = %e, "discord webhook failed");
        }
    }

    if config.tray_enabled {
        if let Err(e) = tray::show_toast(&title, &body) {
            tracing::warn!(error = %e, "tray toast failed");
        }
    }
}

fn title_for(event: NotifyEvent, display_name: &str) -> String {
    let name = if display_name.trim().is_empty() {
        "ARKSA"
    } else {
        display_name.trim()
    };
    let suffix = match event {
        NotifyEvent::ServerStarting => "Server starting…",
        NotifyEvent::ServerOnline => "Server online",
        NotifyEvent::ServerStopped => "Server stopped",
        NotifyEvent::ServerCrashDetected => "Server CRASHED",
        NotifyEvent::AsasmUpdateAvailable => "Tool update available",
        NotifyEvent::ServerAppUpdateAvailable => "Server app update available",
    };
    format!("[{name}] {suffix}")
}

fn body_for(event: NotifyEvent, ctx: &NotifyContext) -> String {
    let mut s = format!("Profile: {}", ctx.profile_name);
    if let Some(m) = ctx.map_name.as_deref().filter(|s| !s.is_empty()) {
        s.push_str(&format!("\nMap: {m}"));
    }
    if let Some(e) = ctx.extra.as_deref().filter(|s| !s.is_empty()) {
        s.push_str(&format!("\n{e}"));
    }
    let _ = event; // event already encoded in the title
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mask_round_trip() {
        let mut cfg = NotifyConfig::default();
        cfg.events_enabled = NotifyConfig::parse_events_mask("101010");
        assert!(cfg.is_event_enabled(NotifyEvent::ServerStarting));
        assert!(!cfg.is_event_enabled(NotifyEvent::ServerOnline));
        assert!(cfg.is_event_enabled(NotifyEvent::ServerStopped));
        assert_eq!(cfg.events_mask_string(), "101010");
    }

    #[test]
    fn parse_short_mask_pads_with_false() {
        let arr = NotifyConfig::parse_events_mask("11");
        assert_eq!(arr, [true, true, false, false, false, false]);
    }

    #[test]
    fn discord_disabled_when_url_blank() {
        let cfg = NotifyConfig::default();
        assert!(!cfg.discord_enabled());
        let cfg = NotifyConfig {
            discord_webhook_url: "   ".into(),
            ..Default::default()
        };
        assert!(!cfg.discord_enabled());
    }

    #[test]
    fn title_uses_display_name_or_fallback() {
        assert_eq!(title_for(NotifyEvent::ServerOnline, "MyArk"), "[MyArk] Server online");
        assert_eq!(title_for(NotifyEvent::ServerOnline, ""), "[ARKSA] Server online");
    }

    #[test]
    fn body_includes_map_and_extra_when_present() {
        let ctx = NotifyContext::new("MyServer")
            .with_map("TheIsland_WP")
            .with_extra("BuildID 12345");
        let s = body_for(NotifyEvent::ServerStarting, &ctx);
        assert!(s.contains("Profile: MyServer"));
        assert!(s.contains("Map: TheIsland_WP"));
        assert!(s.contains("BuildID 12345"));
    }

    #[test]
    fn dispatch_short_circuits_when_event_disabled() {
        // No webhook + no tray + nothing enabled — must return without panic.
        let cfg = NotifyConfig::default();
        dispatch(
            &cfg,
            NotifyEvent::ServerStarting,
            &NotifyContext::new("X"),
        );
    }
}
