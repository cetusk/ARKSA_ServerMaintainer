// Hide the console window on Windows release builds; keep it for debug builds
// so println!/tracing output stays visible during development.
#![cfg_attr(all(target_os = "windows", not(debug_assertions)), windows_subsystem = "windows")]

use anyhow::Result;
use tracing_subscriber::EnvFilter;

slint::include_modules!();

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();

    let window = MainWindow::new()?;

    let weak = window.as_weak();
    window.on_start_server(move || {
        if let Some(w) = weak.upgrade() {
            w.set_server_status("Starting...".into());
        }
        // TODO Phase 3: invoke arksa_core::server::start(...)
        tracing::info!("start-server clicked");
    });

    let weak = window.as_weak();
    window.on_stop_server(move || {
        if let Some(w) = weak.upgrade() {
            w.set_server_status("Stopping...".into());
        }
        // TODO Phase 3: invoke arksa_core::server::stop(...)
        tracing::info!("stop-server clicked");
    });

    window.run()?;
    Ok(())
}
