//! arksa-commander
//!
//! CLI tool: sends a server command to a running ARK: SA dedicated server
//! identified by a profile name. Equivalent of upstream `AsaServerCommander.exe`.
//!
//! Usage (Phase 8):
//!     arksa-commander <profile> <command> [args...]
//!
//! Behaviour:
//!   1. Read `Profile/<profile>.ini`, resolve install path + map name.
//!   2. Verify `ArkAscendedServer.exe` is running for that path.
//!   3. Send the command via RCON (or, when configured, by injecting it into
//!      the server console window — same fallback as upstream).

use anyhow::{bail, Result};
use std::env;

fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let args: Vec<String> = env::args().collect();
    if args.len() < 3 {
        bail!("Usage: arksa-commander <profile> <command> [args...]");
    }
    let profile = &args[1];
    let command = args[2..].join(" ");
    tracing::info!(%profile, %command, "arksa-commander (Phase 0 stub)");
    // TODO Phase 8: load profile, dispatch to RCON or window-injection.
    Ok(())
}
