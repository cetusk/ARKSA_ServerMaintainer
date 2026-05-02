//! ARK SA dedicated server launch argument builder.
//!
//! Produces a single string in the same shape as upstream's
//! `[General] MM_Command_Val`: an executable name, a `?`-separated map URL,
//! and `-flag` arguments. Example output:
//!
//! ```text
//! ArkAscendedServer.exe TheIsland_WP?listen?SessionName=My Server
//! ?ServerAdminPassword=hunter2?Port=7777?QueryPort=27015?RCONEnabled=True
//! ?RCONPort=27020?MaxPlayers=10 -mods=12345,67890 -log -NoBattlEye
//! ```
//!
//! For Phase 4 only the fields a brand-new admin actually needs are exposed;
//! the upstream form has dozens of additional toggles that we will revisit
//! when we port the structured editor.

use rand::Rng;

/// All inputs the new-profile dialog collects.
///
/// Field ordering mirrors how they get serialised into the URL portion of the
/// command line, so reading top-to-bottom matches the resulting string.
#[derive(Debug, Clone)]
pub struct LaunchArgs {
    /// e.g. "TheIsland_WP". The `?listen` flag is always appended.
    pub map: String,
    pub session_name: String,
    pub server_password: String,
    pub admin_password: String,
    pub game_port: u16,
    pub query_port: u16,
    pub rcon_enabled: bool,
    pub rcon_port: u16,
    pub max_players: u16,
    /// Mod IDs in the order ARK should load them.
    pub mods: Vec<u64>,
    /// Free-form `-flag` arguments appended after the URL portion. Each entry
    /// is one whitespace-separated token (e.g. `"-log"`, `"-NoBattlEye"`).
    pub extra_flags: Vec<String>,
}

impl LaunchArgs {
    /// Reasonable starting point for a brand-new profile: minimum-viable single
    /// island server with logging and BattlEye disabled.
    pub fn defaults() -> Self {
        Self {
            map: "TheIsland_WP".into(),
            session_name: "ARKSA Server".into(),
            server_password: String::new(),
            admin_password: generate_password(16),
            game_port: 7777,
            query_port: 27015,
            rcon_enabled: true,
            rcon_port: 27020,
            max_players: 10,
            mods: Vec::new(),
            extra_flags: vec!["-log".into(), "-NoBattlEye".into()],
        }
    }
}

/// Map names suggested in the New Profile dialog. The user can still type a
/// custom map (e.g. for community/mod maps).
pub const COMMON_MAPS: &[&str] = &[
    "TheIsland_WP",
    "ScorchedEarth_WP",
    "Aberration_WP",
    "Extinction_WP",
    "TheCenter_WP",
    "Astraeos_WP",
    "Ragnarok_WP",
];

/// Generate a URL-safe random password of `len` printable ASCII characters.
/// Used for the auto-generated RCON admin password.
pub fn generate_password(len: usize) -> String {
    // Avoid characters that would need URL-encoding in the map URL portion of
    // the command line: no '?', '=', '&', '%', '"', ' ', '\\', '/'.
    const ALPHABET: &[u8] =
        b"ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789-_";
    let mut rng = rand::rng();
    (0..len)
        .map(|_| ALPHABET[rng.random_range(0..ALPHABET.len())] as char)
        .collect()
}

/// Build a string suitable for `[General] MM_Command_Val`.
pub fn build_command_line(args: &LaunchArgs) -> String {
    let mut url = String::new();
    url.push_str(&args.map);
    url.push_str("?listen");
    push_param(&mut url, "SessionName", &args.session_name);
    if !args.server_password.is_empty() {
        push_param(&mut url, "ServerPassword", &args.server_password);
    }
    push_param(&mut url, "ServerAdminPassword", &args.admin_password);
    push_param(&mut url, "Port", &args.game_port.to_string());
    push_param(&mut url, "QueryPort", &args.query_port.to_string());
    if args.rcon_enabled {
        push_param(&mut url, "RCONEnabled", "True");
        push_param(&mut url, "RCONPort", &args.rcon_port.to_string());
    }
    push_param(&mut url, "MaxPlayers", &args.max_players.to_string());

    let mut cmd = format!("ArkAscendedServer.exe {url}");

    if !args.mods.is_empty() {
        let csv: Vec<String> = args.mods.iter().map(|m| m.to_string()).collect();
        cmd.push_str(" -mods=");
        cmd.push_str(&csv.join(","));
    }

    for flag in &args.extra_flags {
        let trimmed = flag.trim();
        if !trimmed.is_empty() {
            cmd.push(' ');
            cmd.push_str(trimmed);
        }
    }

    cmd
}

/// Append `?Key=Value` to `url`. Values are taken verbatim — callers must
/// pre-validate that the value contains no `?` (which would split it into a
/// new param).
fn push_param(url: &mut String, key: &str, value: &str) {
    url.push('?');
    url.push_str(key);
    url.push('=');
    url.push_str(value);
}

/// Parse a comma-separated list of mod IDs (whitespace tolerant). Empty
/// segments and non-numeric entries are silently skipped.
pub fn parse_mods_csv(csv: &str) -> Vec<u64> {
    csv.split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .filter_map(|s| s.parse::<u64>().ok())
        .collect()
}

/// Split a free-form extra-flags string ("-log -NoBattlEye") into tokens.
pub fn parse_extra_flags(s: &str) -> Vec<String> {
    s.split_whitespace().map(str::to_string).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_minimum_command() {
        let args = LaunchArgs {
            map: "TheIsland_WP".into(),
            session_name: "Test".into(),
            server_password: String::new(),
            admin_password: "pw".into(),
            game_port: 7777,
            query_port: 27015,
            rcon_enabled: true,
            rcon_port: 27020,
            max_players: 10,
            mods: vec![],
            extra_flags: vec!["-log".into()],
        };
        let cmd = build_command_line(&args);
        assert_eq!(
            cmd,
            "ArkAscendedServer.exe TheIsland_WP?listen?SessionName=Test\
             ?ServerAdminPassword=pw?Port=7777?QueryPort=27015\
             ?RCONEnabled=True?RCONPort=27020?MaxPlayers=10 -log"
        );
    }

    #[test]
    fn omits_server_password_when_empty() {
        let mut args = LaunchArgs::defaults();
        args.admin_password = "pw".into();
        let cmd = build_command_line(&args);
        assert!(!cmd.contains("ServerPassword="));
        assert!(cmd.contains("ServerAdminPassword=pw"));
    }

    #[test]
    fn omits_rcon_when_disabled() {
        let mut args = LaunchArgs::defaults();
        args.admin_password = "pw".into();
        args.rcon_enabled = false;
        let cmd = build_command_line(&args);
        assert!(!cmd.contains("RCONEnabled"));
        assert!(!cmd.contains("RCONPort"));
    }

    #[test]
    fn includes_mods_csv() {
        let mut args = LaunchArgs::defaults();
        args.admin_password = "pw".into();
        args.mods = vec![12345, 67890];
        let cmd = build_command_line(&args);
        assert!(cmd.contains(" -mods=12345,67890"));
    }

    #[test]
    fn parse_mods_csv_skips_garbage() {
        assert_eq!(parse_mods_csv(" 12, , 34, abc, 56 "), vec![12, 34, 56]);
    }

    #[test]
    fn parse_extra_flags_splits_whitespace() {
        assert_eq!(
            parse_extra_flags("  -log  -NoBattlEye -ServerPlatform=PC "),
            vec!["-log", "-NoBattlEye", "-ServerPlatform=PC"]
        );
    }

    #[test]
    fn generated_password_is_correct_length_and_charset() {
        let pw = generate_password(20);
        assert_eq!(pw.len(), 20);
        for c in pw.chars() {
            assert!(c.is_ascii_alphanumeric() || c == '-' || c == '_');
        }
    }
}
