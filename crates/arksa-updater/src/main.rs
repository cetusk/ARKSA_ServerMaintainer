// Hide the console window on Windows release builds.
#![cfg_attr(all(target_os = "windows", not(debug_assertions)), windows_subsystem = "windows")]

//! arksa-updater
//!
//! Self-updater for ARKSA_ServerMaintainer.
//! Checks the latest release of `cetusk/ARKSA_ServerMaintainer` on GitHub
//! and replaces the local binaries when a newer version is available.
//!
//! Equivalent of upstream `ASASM_Updater.exe`, but pointed at our own
//! GitHub Releases instead of the original Google Drive link.

use anyhow::Result;

const REPO_OWNER: &str = "cetusk";
const REPO_NAME: &str = "ARKSA_ServerMaintainer";
#[allow(dead_code)]
const RELEASES_API: &str = "https://api.github.com/repos/cetusk/ARKSA_ServerMaintainer/releases/latest";

fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    tracing::info!(repo = %format!("{}/{}", REPO_OWNER, REPO_NAME), "arksa-updater (Phase 0 stub)");
    // TODO Phase 9:
    //   1. fetch latest release JSON
    //   2. compare against the running binary's version
    //   3. download release asset (zip)
    //   4. replace binaries (using a sidecar swap, since the running exe is locked)
    //   5. notify the GUI on completion
    Ok(())
}
