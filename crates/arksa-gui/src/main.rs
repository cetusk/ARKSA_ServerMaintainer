// Hide the console window on Windows release builds; keep it for debug builds
// so println!/tracing output stays visible during development.
#![cfg_attr(all(target_os = "windows", not(debug_assertions)), windows_subsystem = "windows")]

//! ARKSA_ServerMaintainer GUI (Phase 3).
//!
//! Single-server view that wires the Slint UI in `ui/main.slint` to
//! `arksa-core` for actual server lifecycle work. Long-running operations
//! (start, stop, RCON command) are dispatched onto std::thread workers; UI
//! updates from those threads go through `slint::Weak::upgrade_in_event_loop`.

use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{anyhow, Context, Result};
use arksa_core::{
    profile::Profile,
    rcon::RconClient,
    server::{self, ServerStatus, StopOptions, StopOutcome},
};
use slint::{ComponentHandle, ModelRc, SharedString, VecModel};
use tracing_subscriber::EnvFilter;

slint::include_modules!();

/// How often the status panel polls `server::status` while idle.
const POLL_INTERVAL: Duration = Duration::from_secs(5);

/// What the worker threads need to know to do their work. Cheap to clone.
#[derive(Clone)]
struct AppCtx {
    install_dir: PathBuf,
}

/// Shared mutable list of (display name, profile file path).
type ProfileList = Arc<Mutex<Vec<(String, PathBuf)>>>;
/// Index of the currently selected profile, shared across threads.
type SelectedIndex = Arc<Mutex<usize>>;
/// Append-only log buffer.
type LogBuffer = Arc<Mutex<String>>;

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let install_dir = detect_install_dir().context("could not determine ARKSA install dir")?;
    let ctx = AppCtx {
        install_dir: install_dir.clone(),
    };
    let profiles: ProfileList = Arc::new(Mutex::new(scan_profiles(&install_dir)));
    let selected: SelectedIndex = Arc::new(Mutex::new(0));
    let log: LogBuffer = Arc::new(Mutex::new(String::new()));

    let window = MainWindow::new()?;
    window.set_install_dir(install_dir.display().to_string().into());
    push_profiles_to_ui(&window, &profiles.lock().unwrap());
    append_log(
        &log,
        &window,
        &format!("ARKSA dir: {}", install_dir.display()),
    );

    wire_callbacks(&window, ctx.clone(), profiles.clone(), selected.clone(), log.clone());
    initial_status_refresh(&window, &ctx, &profiles, &selected, &log);

    // Periodic status poll.
    let poll_timer = slint::Timer::default();
    {
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        poll_timer.start(slint::TimerMode::Repeated, POLL_INTERVAL, move || {
            refresh_status_async(&weak, &ctx, &profiles, &selected, &log);
        });
    }

    window.run()?;
    Ok(())
}

// ---- startup helpers ------------------------------------------------------

/// Resolution order:
///   1. `ARKSA_DIR` env var (developer convenience)
///   2. `current_exe()` parent (production install)
fn detect_install_dir() -> Result<PathBuf> {
    if let Ok(p) = std::env::var("ARKSA_DIR") {
        return Ok(PathBuf::from(p));
    }
    let exe = std::env::current_exe().context("current_exe() failed")?;
    Ok(exe
        .parent()
        .ok_or_else(|| anyhow!("current_exe has no parent"))?
        .to_path_buf())
}

fn scan_profiles(install_dir: &Path) -> Vec<(String, PathBuf)> {
    let dir = install_dir.join("Profile");
    let Ok(entries) = std::fs::read_dir(&dir) else {
        return Vec::new();
    };
    let mut out = Vec::new();
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        if !path
            .extension()
            .is_some_and(|e| e.eq_ignore_ascii_case("ini"))
        {
            continue;
        }
        let display_name = Profile::load(&path)
            .ok()
            .and_then(|p| p.display_name())
            .or_else(|| {
                path.file_stem()
                    .map(|s| s.to_string_lossy().into_owned())
            })
            .unwrap_or_else(|| "(unnamed)".into());
        out.push((display_name, path));
    }
    out.sort_by_key(|a| a.0.to_lowercase());
    out
}

fn push_profiles_to_ui(window: &MainWindow, profiles: &[(String, PathBuf)]) {
    let names: Vec<SharedString> = profiles
        .iter()
        .map(|(n, _)| SharedString::from(n.as_str()))
        .collect();
    let model = std::rc::Rc::new(VecModel::from(names));
    window.set_profile_names(ModelRc::from(model));
}

// ---- wiring --------------------------------------------------------------

fn wire_callbacks(
    window: &MainWindow,
    ctx: AppCtx,
    profiles: ProfileList,
    selected: SelectedIndex,
    log: LogBuffer,
) {
    // Profile selected → just remember the index; status will refresh on the
    // next poll tick (or the user can hit Refresh).
    {
        let selected = selected.clone();
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let log = log.clone();
        window.on_profile_selected(move |idx| {
            *selected.lock().unwrap() = idx.max(0) as usize;
            refresh_status_async(&weak, &ctx, &profiles, &selected, &log);
        });
    }

    // Refresh button.
    {
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        window.on_refresh_status(move || {
            refresh_status_async(&weak, &ctx, &profiles, &selected, &log);
        });
    }

    // Start.
    {
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        window.on_start_server(move || {
            let Some(profile_path) = current_profile_path(&profiles, &selected) else {
                push_log_async(&weak, &log, "No profile selected.");
                return;
            };
            set_busy_async(&weak, true);
            spawn_worker(weak.clone(), log.clone(), {
                let ctx = ctx.clone();
                move || {
                    let prof = Profile::load(&profile_path)
                        .with_context(|| format!("load {}", profile_path.display()))?;
                    let pid = server::start(&prof, &ctx.install_dir)?;
                    Ok(format!("Server started (PID {pid})."))
                }
            });
        });
    }

    // Stop (graceful).
    {
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        window.on_stop_server(move || {
            let Some(profile_path) = current_profile_path(&profiles, &selected) else {
                push_log_async(&weak, &log, "No profile selected.");
                return;
            };
            set_busy_async(&weak, true);
            spawn_worker(weak.clone(), log.clone(), {
                let ctx = ctx.clone();
                move || {
                    let prof = Profile::load(&profile_path)
                        .with_context(|| format!("load {}", profile_path.display()))?;
                    let outcome = server::stop_graceful(
                        &prof,
                        &ctx.install_dir,
                        StopOptions::default(),
                    )?;
                    Ok(format!("Stop result: {}.", describe_stop(outcome)))
                }
            });
        });
    }

    // RCON one-shot.
    {
        let weak = window.as_weak();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        window.on_send_rcon(move || {
            let Some(window) = weak.upgrade() else { return };
            let cmd = window.get_rcon_input().to_string();
            if cmd.trim().is_empty() {
                push_log_async(&weak, &log, "(empty RCON command)");
                return;
            }
            let Some(profile_path) = current_profile_path(&profiles, &selected) else {
                push_log_async(&weak, &log, "No profile selected.");
                return;
            };
            // Clear input and disable controls while in flight.
            window.set_rcon_input(SharedString::default());
            set_busy_async(&weak, true);
            spawn_worker(weak.clone(), log.clone(), move || {
                let prof = Profile::load(&profile_path)
                    .with_context(|| format!("load {}", profile_path.display()))?;
                let port = prof
                    .rcon_port()
                    .ok_or_else(|| anyhow!("profile has no SE_RCONPort"))?;
                let password = prof
                    .admin_password()
                    .ok_or_else(|| anyhow!("profile has no Edit_ServerAdminPassword"))?;
                let client = RconClient::connect("127.0.0.1", port, password)?;
                let response = client.execute(&cmd)?;
                let body = response.body.trim_end_matches('\n');
                Ok(if body.is_empty() {
                    format!("RCON {cmd}: (empty response)")
                } else {
                    format!("RCON {cmd}:\n{body}")
                })
            });
        });
    }

    // Browse install dir — placeholder until a folder picker is wired in.
    {
        let weak = window.as_weak();
        let log = log.clone();
        window.on_browse_install_dir(move || {
            push_log_async(
                &weak,
                &log,
                "Browse… not yet implemented. Set ARKSA_DIR env var to override.",
            );
        });
    }
}

fn initial_status_refresh(
    window: &MainWindow,
    ctx: &AppCtx,
    profiles: &ProfileList,
    selected: &SelectedIndex,
    log: &LogBuffer,
) {
    refresh_status_async(&window.as_weak(), ctx, profiles, selected, log);
}

// ---- async-from-UI helpers ------------------------------------------------

fn current_profile_path(profiles: &ProfileList, selected: &SelectedIndex) -> Option<PathBuf> {
    let profiles = profiles.lock().unwrap();
    let idx = *selected.lock().unwrap();
    profiles.get(idx).map(|(_, p)| p.clone())
}

fn refresh_status_async(
    weak: &slint::Weak<MainWindow>,
    ctx: &AppCtx,
    profiles: &ProfileList,
    selected: &SelectedIndex,
    log: &LogBuffer,
) {
    let Some(profile_path) = current_profile_path(profiles, selected) else {
        return;
    };
    let weak = weak.clone();
    let ctx = ctx.clone();
    let log = log.clone();
    std::thread::spawn(move || {
        let result = (|| -> Result<(ServerStatus, String, String, String)> {
            let prof = Profile::load(&profile_path)
                .with_context(|| format!("load {}", profile_path.display()))?;
            let now = current_unix_time();
            let status = server::status(&prof, &ctx.install_dir, now)?;
            let map = prof.map_name().unwrap_or_else(|| "—".into());
            let ports = format!(
                "Game {}, Query {}, RCON {}",
                fmt_port(prof.game_port()),
                fmt_port(prof.query_port()),
                fmt_port(prof.rcon_port())
            );
            let title = if status.running {
                format!(
                    "Running (PID {})",
                    status.pid.map(|p| p.to_string()).unwrap_or_else(|| "?".into())
                )
            } else {
                "Stopped".to_string()
            };
            Ok((status, map, ports, title))
        })();

        let (view, error_text) = match result {
            Ok((st, map, ports, title)) => (
                ServerStatusView {
                    running: st.running,
                    title: title.into(),
                    map: map.into(),
                    ports: ports.into(),
                    memory: format!("{} MB", st.memory_mb).into(),
                    uptime: fmt_uptime(st.uptime_secs).into(),
                },
                None,
            ),
            Err(e) => (
                ServerStatusView {
                    running: false,
                    title: "(profile error)".into(),
                    map: "—".into(),
                    ports: "—".into(),
                    memory: "—".into(),
                    uptime: "—".into(),
                },
                Some(format!("{e:#}")),
            ),
        };

        if let Some(msg) = error_text {
            push_log_async(&weak, &log, &format!("status: {msg}"));
        }
        let _ = weak.upgrade_in_event_loop(move |window| {
            window.set_status(view);
        });
    });
}

fn spawn_worker<F>(weak: slint::Weak<MainWindow>, log: LogBuffer, work: F)
where
    F: FnOnce() -> Result<String> + Send + 'static,
{
    std::thread::spawn(move || {
        let outcome = work();
        let line = match outcome {
            Ok(msg) => msg,
            Err(e) => format!("error: {e:#}"),
        };
        push_log_async(&weak, &log, &line);
        set_busy_async(&weak, false);
    });
}

fn push_log_async(weak: &slint::Weak<MainWindow>, log: &LogBuffer, line: &str) {
    let new_text = {
        let mut buf = log.lock().unwrap();
        if !buf.is_empty() {
            buf.push('\n');
        }
        buf.push_str(&format!("[{}] {}", current_clock(), line));
        // Keep the last ~64 KB in the UI to bound memory.
        const MAX_LOG: usize = 64 * 1024;
        if buf.len() > MAX_LOG {
            let split = buf.len() - MAX_LOG;
            *buf = buf[split..].to_string();
        }
        buf.clone()
    };
    let weak = weak.clone();
    let _ = weak.upgrade_in_event_loop(move |window| {
        window.set_log_text(new_text.into());
    });
}

fn append_log(log: &LogBuffer, window: &MainWindow, line: &str) {
    let mut buf = log.lock().unwrap();
    if !buf.is_empty() {
        buf.push('\n');
    }
    buf.push_str(&format!("[{}] {}", current_clock(), line));
    window.set_log_text(buf.clone().into());
}

fn set_busy_async(weak: &slint::Weak<MainWindow>, busy: bool) {
    let weak = weak.clone();
    let _ = weak.upgrade_in_event_loop(move |window| {
        window.set_action_busy(busy);
    });
}

// ---- formatting ----------------------------------------------------------

fn current_unix_time() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

fn current_clock() -> String {
    let now = SystemTime::now();
    let secs = now
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    let h = (secs / 3600) % 24;
    let m = (secs / 60) % 60;
    let s = secs % 60;
    format!("{h:02}:{m:02}:{s:02}")
}

fn fmt_uptime(secs: i64) -> String {
    if secs <= 0 {
        return "—".to_string();
    }
    let secs = secs as u64;
    let d = secs / 86400;
    let h = (secs / 3600) % 24;
    let m = (secs / 60) % 60;
    let s = secs % 60;
    if d > 0 {
        format!("{d}d {h:02}h {m:02}m")
    } else if h > 0 {
        format!("{h}h {m:02}m {s:02}s")
    } else if m > 0 {
        format!("{m}m {s:02}s")
    } else {
        format!("{s}s")
    }
}

fn fmt_port(port: Option<u16>) -> String {
    port.map(|p| p.to_string()).unwrap_or_else(|| "—".into())
}

fn describe_stop(outcome: StopOutcome) -> &'static str {
    match outcome {
        StopOutcome::NotRunning => "server was not running",
        StopOutcome::GracefulRcon => "stopped via RCON SaveWorld + DoExit",
        StopOutcome::GracefulWindowClose => "stopped via WM_CLOSE (RCON unavailable)",
        StopOutcome::StillRunning => "FAILED — server still running",
    }
}
