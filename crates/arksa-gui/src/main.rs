// Hide the console window on Windows release builds; keep it for debug builds
// so println!/tracing output stays visible during development.
#![cfg_attr(all(target_os = "windows", not(debug_assertions)), windows_subsystem = "windows")]

//! ARKSA_ServerMaintainer GUI (Phase 4).
//!
//! Two windows:
//!   * `MainWindow`        — profile picker / status / lifecycle / RCON / log
//!   * `NewProfileWindow`  — modal-style dialog to create a brand-new profile
//!
//! Long-running operations (start, stop, RCON, steamcmd) run on std::thread
//! workers; UI updates from those threads go through
//! `slint::Weak::upgrade_in_event_loop`.

use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{anyhow, Context, Result};
use arksa_core::{
    ark_config, game_config,
    gamedata, launch_args::{self, LaunchArgs, COMMON_MAPS}, modlist,
    profile::Profile,
    rcon::RconClient,
    server::{self, ServerStatus, StopOptions, StopOutcome},
    settings::AppSettings,
    steamcmd,
};
use arksa_notify::{NotifyConfig, NotifyContext, NotifyEvent};
use slint::{ComponentHandle, ModelRc, SharedString, VecModel};
use tracing_subscriber::EnvFilter;

slint::include_modules!();

const POLL_INTERVAL: Duration = Duration::from_secs(5);
/// Cap on rows rendered in the Find window. Mods can be thousands of rows;
/// no UI ever needs more than a few hundred at a time.
const FIND_RESULT_LIMIT: usize = 500;

// Bake the data files into the binary so the GUI doesn't depend on a side
// `assets/` folder being shipped next to the exe.
const ASSET_MODLIST: &[u8] = include_bytes!("../../../assets/ModList.txt");
const ASSET_ENGRAMS: &[u8] = include_bytes!("../../../assets/EngramData.txt");
const ASSET_ITEMS: &[u8] = include_bytes!("../../../assets/ItemData.txt");
const ASSET_DINOS: &[u8] = include_bytes!("../../../assets/DinoData.txt");

/// Language code as stored in `AppSettings::language()`:
///   0 = auto (system locale; for now treated as English on Windows)
///   1 = English
///   2 = Japanese
const LANG_AUTO: i64 = 0;
const LANG_ENGLISH: i64 = 1;
const LANG_JAPANESE: i64 = 2;

#[derive(Clone)]
struct AppCtx {
    install_dir: PathBuf,
    notify_config: Arc<Mutex<NotifyConfig>>,
    labels: Arc<Labels>,
}

type ProfileList = Arc<Mutex<Vec<(String, PathBuf)>>>;
type SelectedIndex = Arc<Mutex<usize>>;
type LogBuffer = Arc<Mutex<String>>;

fn main() -> Result<()> {
    // Slint's text layout calls into ICU4X for line-break analysis and
    // ICU4X writes "ICU4X data error: No segmentation model for language: ja"
    // *directly to stderr via eprintln!* on every Japanese segment, because
    // its bundled data ships only Western locales. The fallback (char-wrap)
    // is fine for Japanese, but the spam drowns the console.
    //
    // EnvFilter doesn't catch this since it's not going through `log` /
    // `tracing`. Redirect the process-level stderr handle to NUL on Windows
    // before any GUI code runs. Skip when RUST_LOG is set so devs can still
    // see everything.
    redirect_stderr_to_null_unless_debug();

    // Route the `log` crate output through `tracing` (the bridge is
    // installed by tracing-subscriber's default `tracing-log` feature — do
    // NOT also call LogTracer::init() here, only one global `log` logger
    // can exist or `SetLoggerError` panics).
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| {
                EnvFilter::new(
                    "info,\
                     icu_segmenter=off,\
                     icu_provider=off,\
                     i_slint_core=error,\
                     i_slint_renderer_software=error",
                )
            }),
        )
        .init();

    let install_dir = detect_install_dir().context("could not determine ARKSA install dir")?;

    // Load (or initialise) the persistent app settings + derive the notify
    // config from it. Both are shared with worker threads and the
    // notifications dialog.
    let settings_path = install_dir.join(arksa_core::settings::DEFAULT_FILENAME);
    let app_settings =
        AppSettings::load(&settings_path).context("load app settings INI")?;
    let notify_config = Arc::new(Mutex::new(notify_config_from_settings(&app_settings)));

    // i18n labels for the current session. Live language switching requires
    // a restart so we capture the value once here.
    let labels = Arc::new(Labels::for_language(app_settings.language()));
    let language_setting = app_settings.language();
    let app_settings = Arc::new(Mutex::new(app_settings));

    let ctx = AppCtx {
        install_dir: install_dir.clone(),
        notify_config: notify_config.clone(),
        labels: labels.clone(),
    };
    let profiles: ProfileList = Arc::new(Mutex::new(scan_profiles(&install_dir)));
    let selected: SelectedIndex = Arc::new(Mutex::new(0));
    let log: LogBuffer = Arc::new(Mutex::new(String::new()));

    let window = MainWindow::new()?;
    window.set_labels(labels.to_ui());
    window.set_install_dir(install_dir.display().to_string().into());
    push_profiles_to_ui(&window, &profiles.lock().unwrap());
    append_log(
        &log,
        &window,
        &format!("ARKSA dir: {}", install_dir.display()),
    );

    let dialog = NewProfileWindow::new()?;
    dialog.set_labels(labels.to_ui());
    push_map_suggestions(&dialog);
    wire_dialog_callbacks(
        &dialog,
        &window,
        ctx.clone(),
        profiles.clone(),
        selected.clone(),
        log.clone(),
    );

    // Find window — pre-load the bundled data once at startup.
    let find_data = Arc::new(FindData::load());
    let find_window = FindWindow::new()?;
    find_window.set_labels(labels.to_ui());
    refresh_find(&find_window, &find_data);
    wire_find_callbacks(&find_window, find_data.clone());

    // Notification settings dialog.
    let notif_window = NotificationsWindow::new()?;
    notif_window.set_labels(labels.to_ui());
    notif_window.set_language_index(language_index_for_setting(language_setting));
    populate_notifications_window(&notif_window, &notify_config.lock().unwrap());
    wire_notifications_callbacks(
        &notif_window,
        app_settings.clone(),
        notify_config.clone(),
        settings_path.clone(),
        log.clone(),
        window.as_weak(),
    );

    // World settings dialog (Game.ini + GameUserSettings.ini editor).
    let world_window = WorldSettingsWindow::new()?;
    world_window.set_labels(labels.to_ui());
    // Drive bilingual descriptions on each row from the resolved language.
    world_window.set_lang_ja(Labels::resolve_is_japanese(language_setting));
    // Live row search — Slint 1.16 strings have no `.contains()`, so the
    // case-insensitive substring test is computed in Rust via this
    // pure callback. Slint reactively re-evaluates each row's `visible`
    // when query / match-description / label / description change.
    world_window
        .global::<WorldSearch>()
        .on_test_match(|label, description, query, match_description| {
            if query.is_empty() {
                return true;
            }
            let q = query.to_lowercase();
            label.to_lowercase().contains(&q)
                || (match_description && description.to_lowercase().contains(&q))
        });
    wire_world_settings_callbacks(
        &world_window,
        ctx.clone(),
        profiles.clone(),
        selected.clone(),
        log.clone(),
        window.as_weak(),
    );

    // Pre-fill the main-window language picker so it reflects the saved
    // preference on launch. Mirrors how NotificationsWindow seeds its own
    // ComboBox (notif_window.set_language_index just above).
    window.set_language_index(language_index_for_setting(language_setting));
    wire_main_callbacks(
        &window,
        &dialog,
        &find_window,
        &notif_window,
        &world_window,
        ctx.clone(),
        profiles.clone(),
        selected.clone(),
        log.clone(),
        app_settings.clone(),
        settings_path.clone(),
    );
    initial_status_refresh(&window, &ctx, &profiles, &selected, &log);

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

// ─── startup helpers ───────────────────────────────────────────────────────

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
            .or_else(|| path.file_stem().map(|s| s.to_string_lossy().into_owned()))
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
    // Also surface the selected profile's full file path so the UI can
    // show "↳ File: D:\…\Profile\<name>.ini" under the dropdown.
    let idx = window.get_selected_profile_index().max(0) as usize;
    let path = profiles
        .get(idx)
        .map(|(_, p)| p.display().to_string())
        .unwrap_or_default();
    window.set_selected_profile_path(SharedString::from(path.as_str()));
}

/// Refresh just the "selected profile path" label from the current
/// selection without re-pushing the entire profile model. Used from the
/// `on_profile_selected` callback.
fn push_selected_profile_path(window: &MainWindow, profiles: &ProfileList, idx: usize) {
    let profiles = profiles.lock().unwrap();
    let path = profiles
        .get(idx)
        .map(|(_, p)| p.display().to_string())
        .unwrap_or_default();
    window.set_selected_profile_path(SharedString::from(path.as_str()));
}

fn push_map_suggestions(dialog: &NewProfileWindow) {
    let names: Vec<SharedString> = COMMON_MAPS
        .iter()
        .map(|m| SharedString::from(*m))
        .collect();
    let model = std::rc::Rc::new(VecModel::from(names));
    dialog.set_map_suggestions(ModelRc::from(model));
}

// ─── main window callbacks ─────────────────────────────────────────────────

#[allow(clippy::too_many_arguments)]
#[allow(clippy::too_many_arguments)]
fn wire_main_callbacks(
    window: &MainWindow,
    dialog: &NewProfileWindow,
    find_window: &FindWindow,
    notif_window: &NotificationsWindow,
    world_window: &WorldSettingsWindow,
    ctx: AppCtx,
    profiles: ProfileList,
    selected: SelectedIndex,
    log: LogBuffer,
    app_settings: Arc<Mutex<AppSettings>>,
    settings_path: PathBuf,
) {
    let _ = settings_path; // path is captured by AppSettings; kept in arg list for symmetry
    {
        // Top-bar language picker. Persists immediately and asks the user to
        // restart for the new translations to load — mirrors the
        // notifications-dialog flow but doesn't require diving into a
        // settings sub-screen.
        let weak = window.as_weak();
        let app_settings = app_settings.clone();
        let log = log.clone();
        window.on_language_changed(move |idx| {
            let new_lang = language_setting_for_index(idx);
            let changed = {
                let mut s = app_settings.lock().unwrap();
                let prev = s.language();
                s.set_language(new_lang);
                if let Err(e) = s.save() {
                    push_log_async(&weak, &log, &format!("Save language failed: {e:#}"));
                    return;
                }
                prev != new_lang
            };
            if changed {
                push_log_async(
                    &weak,
                    &log,
                    "Language changed. Restart the app to apply the new translations.",
                );
            }
        });
    }
    {
        let selected = selected.clone();
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let log = log.clone();
        window.on_profile_selected(move |idx| {
            let idx_usize = idx.max(0) as usize;
            *selected.lock().unwrap() = idx_usize;
            if let Some(w) = weak.upgrade() {
                push_selected_profile_path(&w, &profiles, idx_usize);
            }
            refresh_status_async(&weak, &ctx, &profiles, &selected, &log);
        });
    }
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
                    fire_notification(
                        ctx.notify_config.clone(),
                        NotifyEvent::ServerStarting,
                        build_notify_context(&prof),
                    );
                    Ok(format!("Server started (PID {pid})."))
                }
            });
        });
    }
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
                    if matches!(
                        outcome,
                        StopOutcome::GracefulRcon | StopOutcome::GracefulWindowClose
                    ) {
                        fire_notification(
                            ctx.notify_config.clone(),
                            NotifyEvent::ServerStopped,
                            build_notify_context(&prof),
                        );
                    }
                    Ok(format!("Stop result: {}.", describe_stop(outcome)))
                }
            });
        });
    }
    {
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        window.on_restart_server(move || {
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

                    // 1. graceful stop
                    let outcome = server::stop_graceful(
                        &prof,
                        &ctx.install_dir,
                        StopOptions::default(),
                    )?;
                    if matches!(outcome, StopOutcome::StillRunning) {
                        return Err(anyhow!(
                            "Restart aborted: stop_graceful timed out, server still running"
                        ));
                    }
                    if matches!(
                        outcome,
                        StopOutcome::GracefulRcon | StopOutcome::GracefulWindowClose
                    ) {
                        fire_notification(
                            ctx.notify_config.clone(),
                            NotifyEvent::ServerStopped,
                            build_notify_context(&prof),
                        );
                    }

                    // 2. small grace period for ARK to release file/socket handles
                    std::thread::sleep(std::time::Duration::from_secs(2));

                    // 3. start fresh — Profile is reloaded so any World Settings
                    //    edits made between Stop and Start take effect.
                    let prof = Profile::load(&profile_path)
                        .with_context(|| format!("reload {}", profile_path.display()))?;
                    let pid = server::start(&prof, &ctx.install_dir)?;
                    fire_notification(
                        ctx.notify_config.clone(),
                        NotifyEvent::ServerStarting,
                        build_notify_context(&prof),
                    );
                    Ok(format!(
                        "Restarted via {}; new PID {pid}.",
                        describe_stop(outcome)
                    ))
                }
            });
        });
    }
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
    {
        let weak = window.as_weak();
        let log = log.clone();
        let install_dir = ctx.install_dir.clone();
        window.on_browse_install_dir(move || {
            let chosen = pick_folder(Some(&install_dir));
            let Some(path) = chosen else {
                return;
            };
            // We don't have a runtime-restart mechanism, so this is
            // informational: the user has to update run.ps1 / ARKSA_DIR
            // manually for the change to apply on next launch.
            push_log_async(
                &weak,
                &log,
                &format!(
                    "Selected {}. To use it next launch, edit run.ps1 (set $env:ARKSA_DIR) or set the ARKSA_DIR env var.",
                    path.display()
                ),
            );
        });
    }
    {
        let dialog_weak = dialog.as_weak();
        let install_dir = ctx.install_dir.clone();
        window.on_new_profile(move || {
            let Some(dialog) = dialog_weak.upgrade() else { return };
            reset_dialog_to_defaults(&dialog, &install_dir);
            let _ = dialog.show();
        });
    }
    {
        let find_weak = find_window.as_weak();
        window.on_open_find(move || {
            if let Some(w) = find_weak.upgrade() {
                let _ = w.show();
            }
        });
    }
    {
        let notif_weak = notif_window.as_weak();
        let cfg = ctx.notify_config.clone();
        window.on_open_notifications(move || {
            if let Some(w) = notif_weak.upgrade() {
                // Re-populate from current config in case it changed since
                // the dialog was last shown.
                populate_notifications_window(&w, &cfg.lock().unwrap());
                w.set_validation_error(SharedString::default());
                let _ = w.show();
            }
        });
    }
    {
        let world_weak = world_window.as_weak();
        let weak = window.as_weak();
        let log = log.clone();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        window.on_open_world_settings(move || {
            let Some(profile_path) = current_profile_path(&profiles, &selected) else {
                push_log_async(&weak, &log, "No profile selected.");
                return;
            };
            // Resolve install root from profile so the dialog knows which
            // pair of INIs to read/write.
            let install_root = match Profile::load(&profile_path)
                .ok()
                .and_then(|p| p.resolved_install_path(&ctx.install_dir))
            {
                Some(r) => r,
                None => {
                    push_log_async(&weak, &log, "Profile has no install location.");
                    return;
                }
            };
            if let Some(w) = world_weak.upgrade() {
                populate_world_settings_window(&w, &install_root, Some(&profile_path));
                w.set_validation_error(SharedString::default());
                let _ = w.show();
            }
        });
    }
    {
        let weak = window.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        window.on_install_update_server(move || {
            let Some(profile_path) = current_profile_path(&profiles, &selected) else {
                push_log_async(&weak, &log, "No profile selected.");
                return;
            };
            set_busy_async(&weak, true);
            let weak_for_worker = weak.clone();
            let log_for_worker = log.clone();
            let ctx_for_worker = ctx.clone();
            std::thread::spawn(move || {
                let outcome = (|| -> Result<i32> {
                    let prof = Profile::load(&profile_path)
                        .with_context(|| format!("load {}", profile_path.display()))?;
                    let install_path = prof
                        .resolved_install_path(&ctx_for_worker.install_dir)
                        .ok_or_else(|| anyhow!("profile is missing install location"))?;
                    let steamcmd_exe =
                        steamcmd::ensure_steamcmd(&ctx_for_worker.install_dir)?;
                    push_log_async(
                        &weak_for_worker,
                        &log_for_worker,
                        &format!(
                            "Running steamcmd against {}…",
                            install_path.display()
                        ),
                    );
                    let weak_log = weak_for_worker.clone();
                    let log_clone = log_for_worker.clone();
                    let exit_code = steamcmd::install_or_update_server(
                        &steamcmd_exe,
                        &install_path,
                        move |line| {
                            push_log_async(&weak_log, &log_clone, line);
                        },
                    )?;
                    Ok(exit_code)
                })();
                let line = match outcome {
                    Ok(code) => format!("steamcmd exited with code {code}."),
                    Err(e) => format!("steamcmd error: {e:#}"),
                };
                push_log_async(&weak_for_worker, &log_for_worker, &line);
                set_busy_async(&weak_for_worker, false);
            });
        });
    }
}

// ─── new-profile dialog callbacks ──────────────────────────────────────────

fn reset_dialog_to_defaults(dialog: &NewProfileWindow, install_dir: &Path) {
    let defaults = LaunchArgs::defaults();
    dialog.set_profile_name(SharedString::from("MyServer"));
    dialog.set_display_name(SharedString::from("MyServer"));
    dialog.set_map_name(SharedString::from(defaults.map.as_str()));
    dialog.set_install_location(SharedString::from("MyServer"));
    dialog.set_use_relative_path(true);
    dialog.set_session_name(SharedString::from(defaults.session_name.as_str()));
    dialog.set_max_players(defaults.max_players as i32);
    dialog.set_game_port(defaults.game_port as i32);
    dialog.set_query_port(defaults.query_port as i32);
    dialog.set_rcon_enabled(defaults.rcon_enabled);
    dialog.set_rcon_port(defaults.rcon_port as i32);
    dialog.set_admin_password(SharedString::from(defaults.admin_password.as_str()));
    dialog.set_server_password(SharedString::default());
    dialog.set_mods_csv(SharedString::default());
    dialog.set_extra_flags(SharedString::from(defaults.extra_flags.join(" ")));
    dialog.set_validation_error(SharedString::default());
    dialog.set_busy(false);
    let _ = install_dir; // unused right now; will inform the install-location placeholder later.
}

fn wire_dialog_callbacks(
    dialog: &NewProfileWindow,
    main: &MainWindow,
    ctx: AppCtx,
    profiles: ProfileList,
    selected: SelectedIndex,
    log: LogBuffer,
) {
    {
        let dialog_weak = dialog.as_weak();
        dialog.on_regenerate_password(move || {
            let Some(dialog) = dialog_weak.upgrade() else { return };
            dialog.set_admin_password(SharedString::from(
                launch_args::generate_password(16).as_str(),
            ));
        });
    }
    {
        let dialog_weak = dialog.as_weak();
        dialog.on_choose_map(move |idx| {
            let Some(dialog) = dialog_weak.upgrade() else { return };
            let i = idx.max(0) as usize;
            if let Some(name) = COMMON_MAPS.get(i) {
                dialog.set_map_name(SharedString::from(*name));
            }
        });
    }
    {
        let dialog_weak = dialog.as_weak();
        dialog.on_cancel_clicked(move || {
            if let Some(dialog) = dialog_weak.upgrade() {
                let _ = dialog.hide();
            }
        });
    }
    {
        let dialog_weak = dialog.as_weak();
        let main_weak = main.as_weak();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        let log = log.clone();
        dialog.on_create_profile(move || {
            let Some(dialog) = dialog_weak.upgrade() else { return };
            dialog.set_validation_error(SharedString::default());
            let inputs = match collect_dialog_inputs(&dialog) {
                Ok(v) => v,
                Err(msg) => {
                    dialog.set_validation_error(SharedString::from(msg.as_str()));
                    return;
                }
            };
            dialog.set_busy(true);

            let profile_dir = ctx.install_dir.join("Profile");
            let dialog_weak = dialog.as_weak();
            let main_weak = main_weak.clone();
            let ctx = ctx.clone();
            let profiles = profiles.clone();
            let selected = selected.clone();
            let log = log.clone();
            std::thread::spawn(move || {
                let DialogInputs {
                    file_stem,
                    display_name,
                    install_location,
                    use_relative_path,
                    args,
                } = inputs;
                let result = std::fs::create_dir_all(&profile_dir).map_err(anyhow::Error::from)
                    .and_then(|_| {
                        Profile::create_new(
                            &profile_dir,
                            &file_stem,
                            &display_name,
                            &install_location,
                            use_relative_path,
                            &args,
                        )
                        .map_err(anyhow::Error::from)
                    });

                match result {
                    Ok(prof) => {
                        let saved_path = prof.path().to_path_buf();
                        push_log_async(
                            &main_weak,
                            &log,
                            &format!("Created profile {}.", saved_path.display()),
                        );
                        // Refresh main window's profile list and select the new entry.
                        let new_list = scan_profiles(&ctx.install_dir);
                        let new_idx = new_list.iter().position(|(_, p)| p == &saved_path).unwrap_or(0);
                        *profiles.lock().unwrap() = new_list.clone();
                        *selected.lock().unwrap() = new_idx;
                        let _ = main_weak.upgrade_in_event_loop(move |window| {
                            push_profiles_to_ui(&window, &new_list);
                            window.set_selected_profile_index(new_idx as i32);
                        });
                        // Trigger status refresh.
                        refresh_status_async(&main_weak, &ctx, &profiles, &selected, &log);
                        let _ = dialog_weak.upgrade_in_event_loop(move |dialog| {
                            dialog.set_busy(false);
                            let _ = dialog.hide();
                        });
                    }
                    Err(e) => {
                        let msg = format!("{e:#}");
                        push_log_async(
                            &main_weak,
                            &log,
                            &format!("Create profile failed: {msg}"),
                        );
                        let _ = dialog_weak.upgrade_in_event_loop(move |dialog| {
                            dialog.set_busy(false);
                            dialog.set_validation_error(SharedString::from(msg.as_str()));
                        });
                    }
                }
            });
        });
    }
}

struct DialogInputs {
    file_stem: String,
    display_name: String,
    install_location: String,
    use_relative_path: bool,
    args: LaunchArgs,
}

fn collect_dialog_inputs(dialog: &NewProfileWindow) -> Result<DialogInputs, String> {
    let file_stem = dialog.get_profile_name().to_string().trim().to_string();
    let display_name = dialog.get_display_name().to_string().trim().to_string();
    let install_location = dialog.get_install_location().to_string().trim().to_string();
    let use_relative_path = dialog.get_use_relative_path();
    let map_name = dialog.get_map_name().to_string().trim().to_string();
    let session_name = dialog.get_session_name().to_string();
    let admin_password = dialog.get_admin_password().to_string();
    let server_password = dialog.get_server_password().to_string();

    if file_stem.is_empty() {
        return Err("File name is required.".into());
    }
    if file_stem.contains(['/', '\\', ':', '*', '?', '"', '<', '>', '|']) {
        return Err("File name contains invalid characters (/ \\ : * ? \" < > |).".into());
    }
    if map_name.is_empty() {
        return Err("Map name is required.".into());
    }
    if install_location.is_empty() {
        return Err("Install location is required.".into());
    }
    if admin_password.is_empty() {
        return Err("Admin password is required (RCON needs it).".into());
    }

    let args = LaunchArgs {
        map: map_name,
        session_name,
        server_password,
        admin_password,
        game_port: clamp_port(dialog.get_game_port()),
        query_port: clamp_port(dialog.get_query_port()),
        rcon_enabled: dialog.get_rcon_enabled(),
        rcon_port: clamp_port(dialog.get_rcon_port()),
        max_players: dialog.get_max_players().clamp(1, 200) as u16,
        mods: launch_args::parse_mods_csv(&dialog.get_mods_csv()),
        extra_flags: launch_args::parse_extra_flags(&dialog.get_extra_flags()),
    };

    Ok(DialogInputs {
        file_stem,
        display_name: if display_name.is_empty() {
            args.session_name.clone()
        } else {
            display_name
        },
        install_location,
        use_relative_path,
        args,
    })
}

fn clamp_port(v: i32) -> u16 {
    v.clamp(1, 65535) as u16
}

// ─── i18n ─────────────────────────────────────────────────────────────────

/// Translated UI strings, owned by Rust. We hand these to Slint via
/// `Labels::to_ui` whenever we need to populate a window's `labels`
/// property; status / error strings shown later are also drawn from here so
/// the whole UI follows one language source.
#[derive(Clone)]
struct Labels {
    main_window_title: String,
    main_language_label: String,
    section_setup: String,
    section_profile: String,
    section_lifecycle: String,
    section_tools: String,
    profile_hint: String,
    profile_path_label: String,
    arksa_dir: String,
    btn_browse: String,
    profile_label: String,
    btn_new: String,
    btn_find: String,
    btn_notifications: String,
    btn_refresh: String,
    panel_server_status: String,
    label_status: String,
    label_map: String,
    label_ports: String,
    label_memory: String,
    label_uptime: String,
    btn_start: String,
    btn_stop: String,
    btn_restart: String,
    btn_install: String,
    panel_rcon: String,
    placeholder_rcon: String,
    btn_send: String,
    panel_log: String,
    empty_title: String,
    empty_subtitle: String,
    empty_create_first: String,
    status_stopped: String,
    /// Format string used as `format!("{prefix} {pid}")` — the prefix already
    /// contains the parenthesised "PID" word so callers just append the PID.
    status_running_prefix: String,
    status_no_profile: String,
    status_profile_error: String,
    find_window_title: String,
    find_category: String,
    find_filter: String,
    find_filter_placeholder: String,
    find_col_name: String,
    find_col_class: String,
    find_col_info: String,
    new_profile_window_title: String,
    notifications_window_title: String,
    notif_section_discord: String,
    notif_webhook_url: String,
    notif_display_name: String,
    notif_btn_test: String,
    notif_section_tray: String,
    notif_tray_enabled_text: String,
    notif_section_events: String,
    notif_section_language: String,
    notif_btn_save: String,
    notif_btn_cancel: String,
    btn_world_settings: String,
    world_window_title: String,
    world_tab_rates: String,
    world_tab_day: String,
    world_tab_player: String,
    world_tab_tamed: String,
    world_tab_wild: String,
    world_tab_difficulty: String,
    world_tab_pvp: String,
    world_tab_ops: String,
    world_tab_breeding: String,
    world_tab_loot: String,
    world_tab_stats: String,
    world_tab_combat: String,
    world_tab_xp: String,
    world_tab_chat: String,
    world_tab_cluster: String,
    world_tab_clamps: String,
    world_tab_flags: String,
    world_btn_import: String,
    world_btn_reset: String,
    world_btn_save: String,
    world_btn_cancel: String,
    world_hint: String,
    world_col_param: String,
    world_col_value: String,
    world_col_category: String,
    world_search_label: String,
    world_search_placeholder: String,
    world_search_match_desc: String,
    world_search_results: String,
    world_tab_mods: String,
    world_mods_hint: String,
    world_mods_footnote: String,
}

impl Labels {
    fn english() -> Self {
        Self {
            main_window_title: "ARKSA Server Maintainer".into(),
            main_language_label: "Language:".into(),
            section_setup: "Setup".into(),
            section_profile: "Profile".into(),
            section_lifecycle: "Server control".into(),
            section_tools: "Tools".into(),
            profile_hint:
                "Profiles are .ini files saved under <ARKSA dir>/Profile/. \
                 The dropdown lists every profile file the tool currently sees."
                    .into(),
            profile_path_label: "File:".into(),
            arksa_dir: "ARKSA dir:".into(),
            btn_browse: "Browse folder".into(),
            profile_label: "Profile:".into(),
            btn_new: "New profile".into(),
            btn_find: "Find data".into(),
            btn_notifications: "Notifications".into(),
            btn_refresh: "Refresh status".into(),
            panel_server_status: "Server status".into(),
            label_status: "Status:".into(),
            label_map: "Map:".into(),
            label_ports: "Ports:".into(),
            label_memory: "Memory:".into(),
            label_uptime: "Uptime:".into(),
            btn_start: "Start".into(),
            btn_stop: "Stop (graceful)".into(),
            btn_restart: "Restart server".into(),
            btn_install: "Install / Update server".into(),
            panel_rcon: "RCON".into(),
            placeholder_rcon: "Command, e.g. ListPlayers".into(),
            btn_send: "Send".into(),
            panel_log: "Log".into(),
            empty_title: "No server profiles yet.".into(),
            empty_subtitle:
                "Create one to install and run your ARK Survival Ascended server.".into(),
            empty_create_first: "Create your first server".into(),
            status_stopped: "Stopped".into(),
            status_running_prefix: "Running (PID".into(),
            status_no_profile: "(no profile loaded)".into(),
            status_profile_error: "(profile error)".into(),
            find_window_title: "Find — Mods / Engrams / Items / Dinos".into(),
            find_category: "Category:".into(),
            find_filter: "Filter:".into(),
            find_filter_placeholder: "type a substring (case-insensitive)".into(),
            find_col_name: "Name".into(),
            find_col_class: "Class / ID".into(),
            find_col_info: "Info".into(),
            new_profile_window_title: "New profile".into(),
            notifications_window_title: "Notifications".into(),
            notif_section_discord: "Discord Webhook".into(),
            notif_webhook_url: "Webhook URL:".into(),
            notif_display_name: "Display name:".into(),
            notif_btn_test: "Test".into(),
            notif_section_tray: "Windows Toast".into(),
            notif_tray_enabled_text:
                "Show Windows toast notifications for the events below".into(),
            notif_section_events: "Events".into(),
            notif_section_language: "Language (requires restart)".into(),
            notif_btn_save: "Save".into(),
            notif_btn_cancel: "Cancel".into(),
            btn_world_settings: "World Settings".into(),
            world_window_title: "World settings".into(),
            world_tab_rates: "Rates".into(),
            world_tab_day: "Day cycle".into(),
            world_tab_player: "Player".into(),
            world_tab_tamed: "Tamed dino".into(),
            world_tab_wild: "Wild dino".into(),
            world_tab_difficulty: "Difficulty / structure".into(),
            world_tab_pvp: "PvE / PvP".into(),
            world_tab_ops: "Ops".into(),
            world_tab_breeding: "Breeding".into(),
            world_tab_loot: "Loot / Spoilage".into(),
            world_tab_stats: "Stat arrays".into(),
            world_tab_combat: "Combat / Structures".into(),
            world_tab_xp: "XP gain".into(),
            world_tab_chat: "Cosmetic / Chat".into(),
            world_tab_cluster: "Cluster / Lists".into(),
            world_tab_clamps: "Clamps / Blueprints".into(),
            world_tab_flags: "Launch flags".into(),
            world_btn_import: "Import settings from file".into(),
            world_btn_reset: "Reset to defaults".into(),
            world_btn_save: "Save".into(),
            world_btn_cancel: "Cancel".into(),
            world_hint:
                "Edits Game.ini and GameUserSettings.ini for the current profile. \
                 ARK only re-reads these at server start, so changes take effect on next launch."
                    .into(),
            world_col_param: "Parameter".into(),
            world_col_value: "Value".into(),
            world_col_category: "Category".into(),
            world_search_label: "Search:".into(),
            world_search_placeholder: "type to filter rows…".into(),
            world_search_match_desc: "Include description".into(),
            world_search_results: "Search results".into(),
            world_tab_mods: "Mods".into(),
            world_mods_hint:
                "Enter mod IDs (CurseForge Project IDs), one per line or \
                 comma-separated. Saved into the profile's MM_Command_Val \
                 as `-mods=ID,ID,...`. Example: 947033,883957"
                    .into(),
            world_mods_footnote:
                "Mod files unpack to <Install>/ShooterGame/Mods/<id>/. \
                 Auto-downloaded from CurseForge on first server start. \
                 Restart the server (Stop → Start) after editing."
                    .into(),
        }
    }

    fn japanese() -> Self {
        Self {
            main_window_title: "ARKSA サーバーメンテナー".into(),
            main_language_label: "言語:".into(),
            section_setup: "セットアップ".into(),
            section_profile: "プロファイル".into(),
            section_lifecycle: "サーバー操作".into(),
            section_tools: "ツール".into(),
            profile_hint:
                "プロファイルとは <ARKSA フォルダ>/Profile/ 配下に保存される \
                 .ini ファイルです。ドロップダウンには本ツールが現在認識している \
                 プロファイルファイルが一覧表示されます。"
                    .into(),
            profile_path_label: "ファイル:".into(),
            arksa_dir: "ARKSA フォルダ:".into(),
            btn_browse: "フォルダを参照".into(),
            profile_label: "プロファイル:".into(),
            btn_new: "新規プロファイル".into(),
            btn_find: "データ検索".into(),
            btn_notifications: "通知設定".into(),
            btn_refresh: "状態を更新".into(),
            panel_server_status: "サーバー状態".into(),
            label_status: "状態:".into(),
            label_map: "マップ:".into(),
            label_ports: "ポート:".into(),
            label_memory: "メモリ:".into(),
            label_uptime: "稼働時間:".into(),
            btn_start: "サーバー起動".into(),
            btn_stop: "サーバー停止 (正規)".into(),
            btn_restart: "サーバー再起動".into(),
            btn_install: "サーバーをインストール／更新".into(),
            panel_rcon: "RCON".into(),
            placeholder_rcon: "コマンド (例: ListPlayers)".into(),
            btn_send: "送信".into(),
            panel_log: "ログ".into(),
            empty_title: "サーバープロファイルがありません。".into(),
            empty_subtitle:
                "新規作成すると ARK Survival Ascended サーバーをインストール・起動できます。"
                    .into(),
            empty_create_first: "最初のサーバーを作成".into(),
            status_stopped: "停止中".into(),
            status_running_prefix: "起動中 (PID".into(),
            status_no_profile: "(プロファイル未選択)".into(),
            status_profile_error: "(プロファイルエラー)".into(),
            find_window_title: "検索 ─ Mod / エングラム / アイテム / 恐竜".into(),
            find_category: "種別:".into(),
            find_filter: "フィルタ:".into(),
            find_filter_placeholder: "部分一致 (大文字小文字無視)".into(),
            find_col_name: "名前".into(),
            find_col_class: "クラス / ID".into(),
            find_col_info: "情報".into(),
            new_profile_window_title: "新規プロファイル".into(),
            notifications_window_title: "通知設定".into(),
            notif_section_discord: "Discord Webhook".into(),
            notif_webhook_url: "Webhook URL:".into(),
            notif_display_name: "表示名:".into(),
            notif_btn_test: "テスト".into(),
            notif_section_tray: "Windows トースト".into(),
            notif_tray_enabled_text: "下記イベントで Windows トースト通知を表示する".into(),
            notif_section_events: "イベント".into(),
            notif_section_language: "言語 (再起動が必要)".into(),
            notif_btn_save: "保存".into(),
            notif_btn_cancel: "キャンセル".into(),
            btn_world_settings: "ワールド設定".into(),
            world_window_title: "ワールド設定".into(),
            world_tab_rates: "倍率".into(),
            world_tab_day: "昼夜".into(),
            world_tab_player: "プレイヤー".into(),
            world_tab_tamed: "テイム済み恐竜".into(),
            world_tab_wild: "野生恐竜".into(),
            world_tab_difficulty: "難易度・建造物".into(),
            world_tab_pvp: "PvE / PvP".into(),
            world_tab_ops: "運用".into(),
            world_tab_breeding: "繁殖".into(),
            world_tab_loot: "戦利品・腐敗".into(),
            world_tab_stats: "ステータス配列".into(),
            world_tab_combat: "戦闘・建造".into(),
            world_tab_xp: "XP 獲得".into(),
            world_tab_chat: "表示・チャット".into(),
            world_tab_cluster: "クラスタ・リスト".into(),
            world_tab_clamps: "上限・設計図".into(),
            world_tab_flags: "起動フラグ".into(),
            world_btn_import: "ファイルから設定をインポート".into(),
            world_btn_reset: "デフォルトに戻す".into(),
            world_btn_save: "保存".into(),
            world_btn_cancel: "キャンセル".into(),
            world_hint:
                "現在のプロファイルの Game.ini と GameUserSettings.ini を編集します。\
                 ARK は起動時にしかこれらを読み込まないため、変更は次回 Start から反映されます。"
                    .into(),
            world_col_param: "パラメーター".into(),
            world_col_value: "値".into(),
            world_col_category: "カテゴリ".into(),
            world_search_label: "検索:".into(),
            world_search_placeholder: "入力して絞り込み…".into(),
            world_search_match_desc: "説明文も検索".into(),
            world_search_results: "検索結果".into(),
            world_tab_mods: "MOD".into(),
            world_mods_hint:
                "MOD ID (CurseForge の Project ID) を 1 行 1 つ、または \
                 カンマ区切りで入力します。プロファイルの MM_Command_Val に \
                 `-mods=ID,ID,...` として保存されます。例: 947033,883957"
                    .into(),
            world_mods_footnote:
                "MOD ファイルは <Install>/ShooterGame/Mods/<id>/ に展開されます。\
                 サーバー初回起動時に CurseForge から自動 DL されます。\
                 編集後はサーバーの Restart で反映してください。"
                    .into(),
        }
    }

    fn for_language(setting: i64) -> Self {
        if Self::resolve_is_japanese(setting) {
            Self::japanese()
        } else {
            Self::english()
        }
    }

    /// Resolve `AppSettings::language()` (auto/EN/JA) into the concrete
    /// English-or-Japanese choice. Used both by `Labels::for_language` and by
    /// the World Settings dialog to drive its `lang-ja` property so per-row
    /// bilingual descriptions match the rest of the UI.
    pub fn resolve_is_japanese(setting: i64) -> bool {
        match setting {
            LANG_JAPANESE => true,
            LANG_ENGLISH => false,
            // LANG_AUTO and unknown: detect from `LANG` env var, fall back to English.
            _ => std::env::var("LANG")
                .unwrap_or_default()
                .starts_with("ja"),
        }
    }

    fn to_ui(&self) -> UiLabels {
        UiLabels {
            main_window_title: self.main_window_title.as_str().into(),
            main_language_label: self.main_language_label.as_str().into(),
            section_setup: self.section_setup.as_str().into(),
            section_profile: self.section_profile.as_str().into(),
            section_lifecycle: self.section_lifecycle.as_str().into(),
            section_tools: self.section_tools.as_str().into(),
            profile_hint: self.profile_hint.as_str().into(),
            profile_path_label: self.profile_path_label.as_str().into(),
            arksa_dir: self.arksa_dir.as_str().into(),
            btn_browse: self.btn_browse.as_str().into(),
            profile_label: self.profile_label.as_str().into(),
            btn_new: self.btn_new.as_str().into(),
            btn_find: self.btn_find.as_str().into(),
            btn_notifications: self.btn_notifications.as_str().into(),
            btn_refresh: self.btn_refresh.as_str().into(),
            panel_server_status: self.panel_server_status.as_str().into(),
            label_status: self.label_status.as_str().into(),
            label_map: self.label_map.as_str().into(),
            label_ports: self.label_ports.as_str().into(),
            label_memory: self.label_memory.as_str().into(),
            label_uptime: self.label_uptime.as_str().into(),
            btn_start: self.btn_start.as_str().into(),
            btn_stop: self.btn_stop.as_str().into(),
            btn_restart: self.btn_restart.as_str().into(),
            btn_install: self.btn_install.as_str().into(),
            panel_rcon: self.panel_rcon.as_str().into(),
            placeholder_rcon: self.placeholder_rcon.as_str().into(),
            btn_send: self.btn_send.as_str().into(),
            panel_log: self.panel_log.as_str().into(),
            empty_title: self.empty_title.as_str().into(),
            empty_subtitle: self.empty_subtitle.as_str().into(),
            empty_create_first: self.empty_create_first.as_str().into(),
            status_stopped: self.status_stopped.as_str().into(),
            status_no_profile: self.status_no_profile.as_str().into(),
            status_profile_error: self.status_profile_error.as_str().into(),
            find_window_title: self.find_window_title.as_str().into(),
            find_category: self.find_category.as_str().into(),
            find_filter: self.find_filter.as_str().into(),
            find_filter_placeholder: self.find_filter_placeholder.as_str().into(),
            find_col_name: self.find_col_name.as_str().into(),
            find_col_class: self.find_col_class.as_str().into(),
            find_col_info: self.find_col_info.as_str().into(),
            new_profile_window_title: self.new_profile_window_title.as_str().into(),
            notifications_window_title: self.notifications_window_title.as_str().into(),
            notif_section_discord: self.notif_section_discord.as_str().into(),
            notif_webhook_url: self.notif_webhook_url.as_str().into(),
            notif_display_name: self.notif_display_name.as_str().into(),
            notif_btn_test: self.notif_btn_test.as_str().into(),
            notif_section_tray: self.notif_section_tray.as_str().into(),
            notif_tray_enabled_text: self.notif_tray_enabled_text.as_str().into(),
            notif_section_events: self.notif_section_events.as_str().into(),
            notif_section_language: self.notif_section_language.as_str().into(),
            notif_btn_save: self.notif_btn_save.as_str().into(),
            notif_btn_cancel: self.notif_btn_cancel.as_str().into(),
            btn_world_settings: self.btn_world_settings.as_str().into(),
            world_window_title: self.world_window_title.as_str().into(),
            world_tab_rates: self.world_tab_rates.as_str().into(),
            world_tab_day: self.world_tab_day.as_str().into(),
            world_tab_player: self.world_tab_player.as_str().into(),
            world_tab_tamed: self.world_tab_tamed.as_str().into(),
            world_tab_wild: self.world_tab_wild.as_str().into(),
            world_tab_difficulty: self.world_tab_difficulty.as_str().into(),
            world_tab_pvp: self.world_tab_pvp.as_str().into(),
            world_tab_ops: self.world_tab_ops.as_str().into(),
            world_tab_breeding: self.world_tab_breeding.as_str().into(),
            world_tab_loot: self.world_tab_loot.as_str().into(),
            world_tab_stats: self.world_tab_stats.as_str().into(),
            world_tab_combat: self.world_tab_combat.as_str().into(),
            world_tab_xp: self.world_tab_xp.as_str().into(),
            world_tab_chat: self.world_tab_chat.as_str().into(),
            world_tab_cluster: self.world_tab_cluster.as_str().into(),
            world_tab_clamps: self.world_tab_clamps.as_str().into(),
            world_tab_flags: self.world_tab_flags.as_str().into(),
            world_btn_import: self.world_btn_import.as_str().into(),
            world_btn_reset: self.world_btn_reset.as_str().into(),
            world_btn_save: self.world_btn_save.as_str().into(),
            world_btn_cancel: self.world_btn_cancel.as_str().into(),
            world_hint: self.world_hint.as_str().into(),
            world_col_param: self.world_col_param.as_str().into(),
            world_col_value: self.world_col_value.as_str().into(),
            world_col_category: self.world_col_category.as_str().into(),
            world_search_label: self.world_search_label.as_str().into(),
            world_search_placeholder: self.world_search_placeholder.as_str().into(),
            world_search_match_desc: self.world_search_match_desc.as_str().into(),
            world_search_results: self.world_search_results.as_str().into(),
            world_tab_mods: self.world_tab_mods.as_str().into(),
            world_mods_hint: self.world_mods_hint.as_str().into(),
            world_mods_footnote: self.world_mods_footnote.as_str().into(),
        }
    }
}

/// Map AppSettings.language() → ComboBox index. Auto = 0, English = 1, JA = 2.
fn language_index_for_setting(setting: i64) -> i32 {
    match setting {
        LANG_ENGLISH => 1,
        LANG_JAPANESE => 2,
        _ => 0,
    }
}

/// Reverse of `language_index_for_setting`.
fn language_setting_for_index(index: i32) -> i64 {
    match index {
        1 => LANG_ENGLISH,
        2 => LANG_JAPANESE,
        _ => LANG_AUTO,
    }
}

// ─── Notifications ────────────────────────────────────────────────────────

fn notify_config_from_settings(settings: &AppSettings) -> NotifyConfig {
    let mask = settings.discord_admin_event_mask().unwrap_or_default();
    let events_enabled = NotifyConfig::parse_events_mask(&mask);
    // Tray on/off is encoded as a single-character mask: any '1' counts as on.
    let tray_mask = settings.tray_event_mask().unwrap_or_default();
    let tray_enabled = tray_mask.chars().any(|c| c == '1');
    NotifyConfig {
        discord_webhook_url: settings.discord_admin_webhook_url().unwrap_or_default(),
        display_name: settings.discord_display_name().unwrap_or_default(),
        events_enabled,
        tray_enabled,
    }
}

fn populate_notifications_window(window: &NotificationsWindow, cfg: &NotifyConfig) {
    window.set_webhook_url(SharedString::from(cfg.discord_webhook_url.as_str()));
    window.set_display_name(SharedString::from(cfg.display_name.as_str()));
    window.set_tray_enabled(cfg.tray_enabled);
    window.set_ev_server_starting(cfg.events_enabled[NotifyEvent::ServerStarting as usize]);
    window.set_ev_server_online(cfg.events_enabled[NotifyEvent::ServerOnline as usize]);
    window.set_ev_server_stopped(cfg.events_enabled[NotifyEvent::ServerStopped as usize]);
    window.set_ev_crash_detected(cfg.events_enabled[NotifyEvent::ServerCrashDetected as usize]);
    window.set_ev_asasm_update(cfg.events_enabled[NotifyEvent::AsasmUpdateAvailable as usize]);
    window.set_ev_server_app_update(cfg.events_enabled[NotifyEvent::ServerAppUpdateAvailable as usize]);
}

fn collect_notifications_window(window: &NotificationsWindow) -> NotifyConfig {
    let events_enabled = [
        window.get_ev_server_starting(),
        window.get_ev_server_online(),
        window.get_ev_server_stopped(),
        window.get_ev_crash_detected(),
        window.get_ev_asasm_update(),
        window.get_ev_server_app_update(),
    ];
    NotifyConfig {
        discord_webhook_url: window.get_webhook_url().to_string().trim().to_string(),
        display_name: window.get_display_name().to_string().trim().to_string(),
        events_enabled,
        tray_enabled: window.get_tray_enabled(),
    }
}

fn wire_notifications_callbacks(
    window: &NotificationsWindow,
    settings: Arc<Mutex<AppSettings>>,
    notify_config: Arc<Mutex<NotifyConfig>>,
    settings_path: PathBuf,
    log: LogBuffer,
    main_weak: slint::Weak<MainWindow>,
) {
    {
        let weak = window.as_weak();
        window.on_cancel_clicked(move || {
            if let Some(w) = weak.upgrade() {
                let _ = w.hide();
            }
        });
    }
    {
        let weak = window.as_weak();
        let settings = settings.clone();
        let notify_config = notify_config.clone();
        let log = log.clone();
        let main_weak = main_weak.clone();
        let settings_path = settings_path.clone();
        window.on_save_clicked(move || {
            let Some(window) = weak.upgrade() else { return };
            let new_cfg = collect_notifications_window(&window);
            let new_language = language_setting_for_index(window.get_language_index());

            // Persist into AppSettings + INI on disk.
            let language_changed = {
                let mut s = settings.lock().unwrap();
                let prev_lang = s.language();
                s.set_discord_admin_webhook_url(&new_cfg.discord_webhook_url);
                s.set_discord_display_name(&new_cfg.display_name);
                s.set_discord_admin_event_mask(&new_cfg.events_mask_string());
                // Single-bit "tray on/off" stored as a 1-char mask, the same
                // shape the upstream INI uses.
                s.set_tray_event_mask(if new_cfg.tray_enabled { "1" } else { "0" });
                s.set_language(new_language);
                if let Err(e) = s.save() {
                    window.set_validation_error(SharedString::from(
                        format!("Save failed: {e:#}").as_str(),
                    ));
                    return;
                }
                prev_lang != new_language
            };

            *notify_config.lock().unwrap() = new_cfg;
            let msg = if language_changed {
                "Notification settings saved. Language change takes effect on next launch."
            } else {
                "Notification settings saved."
            };
            push_log_async(&main_weak, &log, msg);
            let _ = settings_path; // settings.save() reuses its bound path
            let _ = window.hide();
        });
    }
    {
        let weak = window.as_weak();
        let log = log.clone();
        let main_weak = main_weak.clone();
        window.on_test_webhook_clicked(move || {
            let Some(window) = weak.upgrade() else { return };
            let url = window.get_webhook_url().to_string().trim().to_string();
            let display = window.get_display_name().to_string();
            if url.is_empty() {
                window.set_validation_error(SharedString::from("Enter a webhook URL first."));
                return;
            }
            window.set_validation_error(SharedString::from("Sending test message…"));
            let log = log.clone();
            let weak = weak.clone();
            let main_weak = main_weak.clone();
            std::thread::spawn(move || {
                let name = if display.trim().is_empty() {
                    "ARKSA".to_string()
                } else {
                    display.trim().to_string()
                };
                let msg = format!("**[{name}] test message**\nWebhook is reachable.");
                let result = arksa_notify::discord::send(&url, &msg);
                let label = match &result {
                    Ok(()) => "Test message sent successfully.".to_string(),
                    Err(e) => format!("Test failed: {e:#}"),
                };
                push_log_async(&main_weak, &log, &label);
                let label_for_dialog = label.clone();
                let _ = weak.upgrade_in_event_loop(move |w| {
                    w.set_validation_error(SharedString::from(label_for_dialog.as_str()));
                });
            });
        });
    }
}

/// Fire a notification on a background thread so the calling lifecycle path
/// is never blocked by Discord HTTP latency or toast initialisation.
fn fire_notification(
    config: Arc<Mutex<NotifyConfig>>,
    event: NotifyEvent,
    ctx: NotifyContext,
) {
    std::thread::spawn(move || {
        let cfg = config.lock().unwrap().clone();
        arksa_notify::dispatch(&cfg, event, &ctx);
    });
}

fn build_notify_context(profile: &Profile) -> NotifyContext {
    let name = profile
        .display_name()
        .or_else(|| {
            profile
                .path()
                .file_stem()
                .map(|s| s.to_string_lossy().into_owned())
        })
        .unwrap_or_else(|| "(unnamed)".into());
    let mut ctx = NotifyContext::new(name);
    if let Some(map) = profile.map_name() {
        ctx = ctx.with_map(map);
    }
    ctx
}

// ─── World settings ───────────────────────────────────────────────────────

/// Format a float for display in a `LineEdit`. Always carries at least one
/// digit after the point so users can see "this is a float".
fn fmt_float_for_form(v: f64) -> SharedString {
    let s = format!("{}", v);
    if s.contains('.') || s.contains('e') {
        s.into()
    } else {
        format!("{s}.0").into()
    }
}

/// Format an integer for display in a `LineEdit`.
fn fmt_int_for_form(v: i64) -> SharedString {
    v.to_string().into()
}

/// Apply the values from the two INIs at `install_root` to the form. Missing
/// keys fall back to ARK's documented vanilla defaults so a brand-new
/// profile (no Game.ini yet) shows sensible starting values.
///
/// `profile_path` is also consulted to populate the Launch flags tab from
/// the profile's `MM_Command_Val`. When None the flags textarea is left
/// empty (Phase 8k entry point).
fn populate_world_settings_window(
    window: &WorldSettingsWindow,
    install_root: &Path,
    profile_path: Option<&Path>,
) {
    let game = game_config::GameSettings::load_or_empty(
        game_config::game_ini_path(install_root),
    )
    .ok();
    let gus = ark_config::GameUserSettings::load_or_empty(
        ark_config::game_user_settings_path(install_root),
    )
    .ok();

    let g = |get: fn(&game_config::GameSettings) -> Option<f64>, default: f64| -> SharedString {
        let v = game.as_ref().and_then(get).unwrap_or(default);
        fmt_float_for_form(v)
    };
    let gb = |get: fn(&game_config::GameSettings) -> Option<bool>, default: bool| -> bool {
        game.as_ref().and_then(get).unwrap_or(default)
    };
    let u = |get: fn(&ark_config::GameUserSettings) -> Option<f64>, default: f64| -> SharedString {
        let v = gus.as_ref().and_then(get).unwrap_or(default);
        fmt_float_for_form(v)
    };
    let ub = |get: fn(&ark_config::GameUserSettings) -> Option<bool>, default: bool| -> bool {
        gus.as_ref().and_then(get).unwrap_or(default)
    };
    let ui_ = |get: fn(&ark_config::GameUserSettings) -> Option<i64>, default: i64| -> SharedString {
        let v = gus.as_ref().and_then(get).unwrap_or(default);
        fmt_int_for_form(v)
    };

    // Rates (now correctly routed to GameUserSettings.ini [ServerSettings])
    window.set_f_xp_multiplier(u(ark_config::GameUserSettings::xp_multiplier, 1.0));
    window.set_f_harvest_amount_multiplier(u(ark_config::GameUserSettings::harvest_amount_multiplier, 1.0));
    window.set_f_harvest_health_multiplier(u(ark_config::GameUserSettings::harvest_health_multiplier, 1.0));
    window.set_f_resources_respawn_period_multiplier(u(ark_config::GameUserSettings::resources_respawn_period_multiplier, 1.0));
    window.set_f_taming_speed_multiplier(u(ark_config::GameUserSettings::taming_speed_multiplier, 1.0));
    // Breeding (these stay in Game.ini)
    window.set_f_mating_interval_multiplier(g(game_config::GameSettings::mating_interval_multiplier, 1.0));
    window.set_f_egg_hatch_speed_multiplier(g(game_config::GameSettings::egg_hatch_speed_multiplier, 1.0));
    window.set_f_baby_mature_speed_multiplier(g(game_config::GameSettings::baby_mature_speed_multiplier, 1.0));

    // Day cycle (GameUserSettings.ini)
    window.set_f_day_cycle_speed_scale(u(ark_config::GameUserSettings::day_cycle_speed_scale, 1.0));
    window.set_f_day_time_speed_scale(u(ark_config::GameUserSettings::day_time_speed_scale, 1.0));
    window.set_f_night_time_speed_scale(u(ark_config::GameUserSettings::night_time_speed_scale, 1.0));

    // Player (GameUserSettings.ini except harvesting which stays in Game.ini)
    window.set_f_player_food(u(ark_config::GameUserSettings::player_food_drain_multiplier, 1.0));
    window.set_f_player_water(u(ark_config::GameUserSettings::player_water_drain_multiplier, 1.0));
    window.set_f_player_stamina(u(ark_config::GameUserSettings::player_stamina_drain_multiplier, 1.0));
    window.set_f_player_health_recovery(u(ark_config::GameUserSettings::player_health_recovery_multiplier, 1.0));
    window.set_f_player_damage(u(ark_config::GameUserSettings::player_damage_multiplier, 1.0));
    window.set_f_player_resistance(u(ark_config::GameUserSettings::player_resistance_multiplier, 1.0));
    window.set_f_player_harvesting(g(game_config::GameSettings::player_harvesting_damage_multiplier, 1.0));

    // Tamed dino (GameUserSettings.ini)
    window.set_f_dino_food(u(ark_config::GameUserSettings::dino_food_drain_multiplier, 1.0));
    window.set_f_dino_stamina(u(ark_config::GameUserSettings::dino_stamina_drain_multiplier, 1.0));
    window.set_f_dino_health_recovery(u(ark_config::GameUserSettings::dino_health_recovery_multiplier, 1.0));
    window.set_f_tamed_damage(u(ark_config::GameUserSettings::tamed_dino_damage_multiplier, 1.0));
    window.set_f_tamed_resistance(u(ark_config::GameUserSettings::tamed_dino_resistance_multiplier, 1.0));

    // Wild dino: food/torpor live in Game.ini, stamina lives in GameUserSettings.ini
    window.set_f_wild_food(g(game_config::GameSettings::wild_dino_food_drain_multiplier, 1.0));
    window.set_f_wild_stamina(u(ark_config::GameUserSettings::wild_dino_stamina_drain_multiplier, 1.0));
    window.set_f_wild_torpor(g(game_config::GameSettings::wild_dino_torpor_drain_multiplier, 1.0));
    window.set_f_dino_count(u(ark_config::GameUserSettings::dino_count_multiplier, 1.0));

    // Difficulty / structure
    window.set_f_difficulty_offset(u(ark_config::GameUserSettings::difficulty_offset, 0.2));
    window.set_f_override_official_difficulty(u(ark_config::GameUserSettings::override_official_difficulty, 5.0));
    window.set_f_structure_damage(u(ark_config::GameUserSettings::structure_damage_multiplier, 1.0));
    window.set_f_structure_resistance(u(ark_config::GameUserSettings::structure_resistance_multiplier, 1.0));
    window.set_f_structure_repair_cooldown(g(game_config::GameSettings::structure_damage_repair_cooldown, 180.0));
    window.set_b_disable_imprint_dino_buff(gb(game_config::GameSettings::disable_imprint_dino_buff, false));
    window.set_b_allow_anyone_baby_imprint(gb(game_config::GameSettings::allow_anyone_baby_imprint_cuddle, false));

    // PvE / PvP toggles (Phase 8b — all GameUserSettings.ini)
    window.set_b_server_pve(ub(ark_config::GameUserSettings::server_pve, false));
    window.set_b_allow_flyer_carry_pve(ub(ark_config::GameUserSettings::allow_flyer_carry_pve, false));
    window.set_b_enable_cryo_sickness_pve(ub(ark_config::GameUserSettings::enable_cryo_sickness_pve, false));
    window.set_b_disable_structure_decay_pve(ub(ark_config::GameUserSettings::disable_structure_decay_pve, false));

    // Operations basics (Phase 8b)
    window.set_f_max_tamed_dinos(u(ark_config::GameUserSettings::max_tamed_dinos, 5000.0));
    window.set_f_kick_idle_players_period(u(ark_config::GameUserSettings::kick_idle_players_period, 3600.0));
    window.set_f_auto_save_period_minutes(u(ark_config::GameUserSettings::auto_save_period_minutes, 15.0));
    window.set_f_the_max_structures_in_range(ui_(ark_config::GameUserSettings::the_max_structures_in_range, 10500));

    // Phase 8c — Breeding / Imprint (Game.ini)
    window.set_f_mating_speed_multiplier(g(game_config::GameSettings::mating_speed_multiplier, 1.0));
    window.set_f_lay_egg_interval_multiplier(g(game_config::GameSettings::lay_egg_interval_multiplier, 1.0));
    window.set_f_passive_tame_interval_multiplier(g(game_config::GameSettings::passive_tame_interval_multiplier, 1.0));
    window.set_f_baby_food_consumption_speed_multiplier(g(game_config::GameSettings::baby_food_consumption_speed_multiplier, 1.0));
    window.set_f_baby_imprint_amount_multiplier(g(game_config::GameSettings::baby_imprint_amount_multiplier, 1.0));
    window.set_f_baby_imprinting_stat_scale_multiplier(g(game_config::GameSettings::baby_imprinting_stat_scale_multiplier, 1.0));
    window.set_f_baby_cuddle_interval_multiplier(g(game_config::GameSettings::baby_cuddle_interval_multiplier, 1.0));
    window.set_f_baby_cuddle_grace_period_multiplier(g(game_config::GameSettings::baby_cuddle_grace_period_multiplier, 1.0));
    window.set_f_baby_cuddle_lose_imprint_quality_speed_multiplier(g(game_config::GameSettings::baby_cuddle_lose_imprint_quality_speed_multiplier, 1.0));
    window.set_b_disable_dino_breeding(gb(game_config::GameSettings::disable_dino_breeding, false));
    window.set_b_disable_dino_taming(gb(game_config::GameSettings::disable_dino_taming, false));

    // Phase 8d — Loot / Spoilage (Game.ini)
    window.set_f_supply_crate_loot_quality_multiplier(g(game_config::GameSettings::supply_crate_loot_quality_multiplier, 1.0));
    window.set_f_fishing_loot_quality_multiplier(g(game_config::GameSettings::fishing_loot_quality_multiplier, 1.0));
    window.set_f_crop_growth_speed_multiplier(g(game_config::GameSettings::crop_growth_speed_multiplier, 1.0));
    window.set_f_crop_decay_speed_multiplier(g(game_config::GameSettings::crop_decay_speed_multiplier, 1.0));
    window.set_b_disable_loot_crates(gb(game_config::GameSettings::disable_loot_crates, false));
    let gi = |get: fn(&game_config::GameSettings) -> Option<i64>, default: i64| -> SharedString {
        let v = game.as_ref().and_then(get).unwrap_or(default);
        fmt_int_for_form(v)
    };
    window.set_f_limit_non_player_dropped_items_count(gi(game_config::GameSettings::limit_non_player_dropped_items_count, 0));
    window.set_f_limit_non_player_dropped_items_range(gi(game_config::GameSettings::limit_non_player_dropped_items_range, 0));
    window.set_f_global_spoiling_time_multiplier(g(game_config::GameSettings::global_spoiling_time_multiplier, 1.0));
    window.set_f_global_item_decomposition_time_multiplier(g(game_config::GameSettings::global_item_decomposition_time_multiplier, 1.0));
    window.set_f_global_corpse_decomposition_time_multiplier(g(game_config::GameSettings::global_corpse_decomposition_time_multiplier, 1.0));
    window.set_f_use_corpse_life_span_multiplier(g(game_config::GameSettings::use_corpse_life_span_multiplier, 1.0));
    window.set_b_use_corpse_locator(gb(game_config::GameSettings::use_corpse_locator, true));
    window.set_f_poop_interval_multiplier(g(game_config::GameSettings::poop_interval_multiplier, 1.0));
    window.set_f_fuel_consumption_interval_multiplier(g(game_config::GameSettings::fuel_consumption_interval_multiplier, 1.0));
    window.set_f_max_fall_speed_multiplier(g(game_config::GameSettings::max_fall_speed_multiplier, 1.0));

    // Phase 8e — Stat arrays (Game.ini)
    window.set_f_pls_player_0(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(0)).unwrap_or(1.0)));
    window.set_f_pls_player_1(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(1)).unwrap_or(1.0)));
    window.set_f_pls_player_2(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(2)).unwrap_or(1.0)));
    window.set_f_pls_player_3(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(3)).unwrap_or(1.0)));
    window.set_f_pls_player_4(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(4)).unwrap_or(1.0)));
    window.set_f_pls_player_5(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(5)).unwrap_or(1.0)));
    window.set_f_pls_player_6(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(6)).unwrap_or(1.0)));
    window.set_f_pls_player_7(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(7)).unwrap_or(1.0)));
    window.set_f_pls_player_8(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(8)).unwrap_or(1.0)));
    window.set_f_pls_player_9(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(9)).unwrap_or(1.0)));
    window.set_f_pls_player_10(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(10)).unwrap_or(1.0)));
    window.set_f_pls_player_11(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_player(11)).unwrap_or(1.0)));
    window.set_f_pls_tamed_0(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(0)).unwrap_or(1.0)));
    window.set_f_pls_tamed_1(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(1)).unwrap_or(1.0)));
    window.set_f_pls_tamed_2(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(2)).unwrap_or(1.0)));
    window.set_f_pls_tamed_3(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(3)).unwrap_or(1.0)));
    window.set_f_pls_tamed_4(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(4)).unwrap_or(1.0)));
    window.set_f_pls_tamed_5(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(5)).unwrap_or(1.0)));
    window.set_f_pls_tamed_6(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(6)).unwrap_or(1.0)));
    window.set_f_pls_tamed_7(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(7)).unwrap_or(1.0)));
    window.set_f_pls_tamed_8(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(8)).unwrap_or(1.0)));
    window.set_f_pls_tamed_9(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(9)).unwrap_or(1.0)));
    window.set_f_pls_tamed_10(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(10)).unwrap_or(1.0)));
    window.set_f_pls_tamed_11(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed(11)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_0(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(0)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_1(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(1)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_2(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(2)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_3(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(3)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_4(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(4)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_5(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(5)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_6(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(6)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_7(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(7)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_8(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(8)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_9(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(9)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_10(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(10)).unwrap_or(1.0)));
    window.set_f_pls_tamed_add_11(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_add(11)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_0(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(0)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_1(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(1)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_2(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(2)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_3(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(3)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_4(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(4)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_5(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(5)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_6(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(6)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_7(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(7)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_8(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(8)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_9(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(9)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_10(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(10)).unwrap_or(1.0)));
    window.set_f_pls_tamed_affinity_11(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_tamed_affinity(11)).unwrap_or(1.0)));
    window.set_f_pls_wild_0(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(0)).unwrap_or(1.0)));
    window.set_f_pls_wild_1(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(1)).unwrap_or(1.0)));
    window.set_f_pls_wild_2(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(2)).unwrap_or(1.0)));
    window.set_f_pls_wild_3(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(3)).unwrap_or(1.0)));
    window.set_f_pls_wild_4(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(4)).unwrap_or(1.0)));
    window.set_f_pls_wild_5(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(5)).unwrap_or(1.0)));
    window.set_f_pls_wild_6(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(6)).unwrap_or(1.0)));
    window.set_f_pls_wild_7(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(7)).unwrap_or(1.0)));
    window.set_f_pls_wild_8(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(8)).unwrap_or(1.0)));
    window.set_f_pls_wild_9(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(9)).unwrap_or(1.0)));
    window.set_f_pls_wild_10(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(10)).unwrap_or(1.0)));
    window.set_f_pls_wild_11(fmt_float_for_form(game.as_ref().and_then(|g| g.per_level_stats_multiplier_dino_wild(11)).unwrap_or(1.0)));
    window.set_f_pls_base_0(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(0)).unwrap_or(1.0)));
    window.set_f_pls_base_1(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(1)).unwrap_or(1.0)));
    window.set_f_pls_base_2(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(2)).unwrap_or(1.0)));
    window.set_f_pls_base_3(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(3)).unwrap_or(1.0)));
    window.set_f_pls_base_4(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(4)).unwrap_or(1.0)));
    window.set_f_pls_base_5(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(5)).unwrap_or(1.0)));
    window.set_f_pls_base_6(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(6)).unwrap_or(1.0)));
    window.set_f_pls_base_7(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(7)).unwrap_or(1.0)));
    window.set_f_pls_base_8(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(8)).unwrap_or(1.0)));
    window.set_f_pls_base_9(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(9)).unwrap_or(1.0)));
    window.set_f_pls_base_10(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(10)).unwrap_or(1.0)));
    window.set_f_pls_base_11(fmt_float_for_form(game.as_ref().and_then(|g| g.player_base_stat_multipliers(11)).unwrap_or(1.0)));

    // Phase 8f — Combat / Structures
    window.set_f_dino_harvesting_damage_multiplier(g(game_config::GameSettings::dino_harvesting_damage_multiplier, 3.2));
    window.set_f_dino_turret_damage_multiplier(g(game_config::GameSettings::dino_turret_damage_multiplier, 1.0));
    window.set_b_allow_speed_leveling(gb(game_config::GameSettings::allow_speed_leveling, true));
    window.set_b_allow_flyer_speed_leveling(gb(game_config::GameSettings::allow_flyer_speed_leveling, false));
    window.set_b_disable_friendly_fire(gb(game_config::GameSettings::disable_friendly_fire, false));
    window.set_b_pve_disable_friendly_fire(gb(game_config::GameSettings::pve_disable_friendly_fire, false));
    window.set_b_allow_unlimited_respecs(gb(game_config::GameSettings::allow_unlimited_respecs, false));
    window.set_b_hard_limit_turrets_in_range(gb(game_config::GameSettings::hard_limit_turrets_in_range, false));
    window.set_b_limit_turrets_in_range(gb(game_config::GameSettings::limit_turrets_in_range, true));
    let gi2 = |get: fn(&game_config::GameSettings) -> Option<i64>, default: i64| -> SharedString {
        let v = game.as_ref().and_then(get).unwrap_or(default);
        fmt_int_for_form(v)
    };
    window.set_f_limit_turrets_num(gi2(game_config::GameSettings::limit_turrets_num, 100));
    window.set_f_limit_turrets_range(g(game_config::GameSettings::limit_turrets_range, 10000.0));
    window.set_f_structure_prevent_resource_radius_multiplier(u(ark_config::GameUserSettings::structure_prevent_resource_radius_multiplier, 1.0));
    window.set_f_per_platform_max_structures_multiplier(u(ark_config::GameUserSettings::per_platform_max_structures_multiplier, 1.0));
    window.set_b_always_allow_structure_pickup(ub(ark_config::GameUserSettings::always_allow_structure_pickup, false));
    window.set_f_structure_pickup_time_after_placement(u(ark_config::GameUserSettings::structure_pickup_time_after_placement, 30.0));
    window.set_f_structure_pickup_hold_duration(u(ark_config::GameUserSettings::structure_pickup_hold_duration, 0.5));
    let ui_2 = |get: fn(&ark_config::GameUserSettings) -> Option<i64>, default: i64| -> SharedString {
        let v = gus.as_ref().and_then(get).unwrap_or(default);
        fmt_int_for_form(v)
    };
    window.set_f_max_platform_saddle_structure_limit(ui_2(ark_config::GameUserSettings::max_platform_saddle_structure_limit, 75));
    window.set_b_enable_cryopod_nerf(ub(ark_config::GameUserSettings::enable_cryopod_nerf, false));
    window.set_f_cryopod_nerf_damage_mult(u(ark_config::GameUserSettings::cryopod_nerf_damage_mult, 0.01));
    window.set_f_cryopod_nerf_duration(u(ark_config::GameUserSettings::cryopod_nerf_duration, 0.0));
    window.set_b_allow_cryo_fridge_on_saddle(ub(ark_config::GameUserSettings::allow_cryo_fridge_on_saddle, false));
    window.set_b_disable_cryopod_fridge_requirement(ub(ark_config::GameUserSettings::disable_cryopod_fridge_requirement, false));
    // Phase 8T — additional Cryopod knobs
    window.set_f_cryopod_nerf_incoming_damage_mult_percent(u(ark_config::GameUserSettings::cryopod_nerf_incoming_damage_mult_percent, 0.0));
    window.set_b_disable_cryopod_enemy_check(ub(ark_config::GameUserSettings::disable_cryopod_enemy_check, false));
    window.set_f_cryopod_fridge_cooldowntime(ui_2(ark_config::GameUserSettings::cryopod_fridge_cooldowntime, 90));

    // Phase 8g — XP gain breakdown (Game.ini)
    window.set_f_generic_xp_multiplier(g(game_config::GameSettings::generic_xp_multiplier, 1.0));
    window.set_f_harvest_xp_multiplier(g(game_config::GameSettings::harvest_xp_multiplier, 1.0));
    window.set_f_kill_xp_multiplier(g(game_config::GameSettings::kill_xp_multiplier, 1.0));
    window.set_f_craft_xp_multiplier(g(game_config::GameSettings::craft_xp_multiplier, 1.0));
    window.set_f_special_xp_multiplier(g(game_config::GameSettings::special_xp_multiplier, 1.0));
    window.set_f_explorer_note_xp_multiplier(g(game_config::GameSettings::explorer_note_xp_multiplier, 1.0));
    window.set_f_boss_kill_xp_multiplier(g(game_config::GameSettings::boss_kill_xp_multiplier, 1.0));
    window.set_f_cave_kill_xp_multiplier(g(game_config::GameSettings::cave_kill_xp_multiplier, 1.0));
    window.set_f_wild_kill_xp_multiplier(g(game_config::GameSettings::wild_kill_xp_multiplier, 1.0));
    window.set_f_tamed_kill_xp_multiplier(g(game_config::GameSettings::tamed_kill_xp_multiplier, 1.0));
    window.set_f_unclaimed_kill_xp_multiplier(g(game_config::GameSettings::unclaimed_kill_xp_multiplier, 1.0));
    window.set_f_alpha_kill_xp_multiplier(g(game_config::GameSettings::alpha_kill_xp_multiplier, 1.0));
    window.set_f_override_max_experience_points_player(gi2(game_config::GameSettings::override_max_experience_points_player, 0));
    window.set_f_override_max_experience_points_dino(gi2(game_config::GameSettings::override_max_experience_points_dino, 0));

    // Phase 8h — Cosmetic / Chat (GUS)
    window.set_b_global_voice_chat(ub(ark_config::GameUserSettings::global_voice_chat, false));
    window.set_b_proximity_chat(ub(ark_config::GameUserSettings::proximity_chat, false));
    window.set_b_dont_always_notify_player_joined(ub(ark_config::GameUserSettings::dont_always_notify_player_joined, false));
    window.set_b_always_notify_player_left(ub(ark_config::GameUserSettings::always_notify_player_left, false));
    window.set_b_admin_logging(ub(ark_config::GameUserSettings::admin_logging, false));
    window.set_b_allow_hide_damage_source_from_logs(ub(ark_config::GameUserSettings::allow_hide_damage_source_from_logs, false));
    window.set_b_show_floating_damage_text(ub(ark_config::GameUserSettings::show_floating_damage_text, false));
    window.set_b_show_map_player_location(ub(ark_config::GameUserSettings::show_map_player_location, true));
    window.set_b_server_crosshair(ub(ark_config::GameUserSettings::server_crosshair, true));
    window.set_b_server_force_no_hud(ub(ark_config::GameUserSettings::server_force_no_hud, false));
    window.set_b_allow_third_person_player(ub(ark_config::GameUserSettings::allow_third_person_player, true));
    window.set_b_allow_hit_markers(ub(ark_config::GameUserSettings::allow_hit_markers, true));
    window.set_b_disable_pve_gamma(ub(ark_config::GameUserSettings::disable_pve_gamma, false));
    window.set_b_enable_pvp_gamma(ub(ark_config::GameUserSettings::enable_pvp_gamma, false));

    // Phase 8i — Cluster / Lists (GUS)
    let us = |get: fn(&ark_config::GameUserSettings) -> Option<String>| -> SharedString {
        gus.as_ref().and_then(get).unwrap_or_default().as_str().into()
    };
    window.set_f_server_password(us(ark_config::GameUserSettings::server_password));
    window.set_f_ban_list_url(us(ark_config::GameUserSettings::ban_list_url));
    window.set_f_admin_list_url(us(ark_config::GameUserSettings::admin_list_url));
    window.set_f_bad_word_list_url(us(ark_config::GameUserSettings::bad_word_list_url));
    window.set_f_bad_word_white_list_url(us(ark_config::GameUserSettings::bad_word_white_list_url));
    window.set_f_custom_live_tuning_url(us(ark_config::GameUserSettings::custom_live_tuning_url));
    window.set_b_no_tribute_downloads(ub(ark_config::GameUserSettings::no_tribute_downloads, false));
    window.set_b_prevent_download_dinos(ub(ark_config::GameUserSettings::prevent_download_dinos, false));
    window.set_b_prevent_download_items(ub(ark_config::GameUserSettings::prevent_download_items, false));
    window.set_b_prevent_download_survivors(ub(ark_config::GameUserSettings::prevent_download_survivors, false));
    window.set_b_prevent_upload_dinos(ub(ark_config::GameUserSettings::prevent_upload_dinos, false));
    window.set_b_prevent_upload_items(ub(ark_config::GameUserSettings::prevent_upload_items, false));
    window.set_b_prevent_upload_survivors(ub(ark_config::GameUserSettings::prevent_upload_survivors, false));
    window.set_b_cross_ark_allow_foreign_dino_downloads(ub(ark_config::GameUserSettings::cross_ark_allow_foreign_dino_downloads, false));
    window.set_b_prevent_tribe_alliances(ub(ark_config::GameUserSettings::prevent_tribe_alliances, false));
    window.set_f_max_number_of_players_in_tribe(ui_2(ark_config::GameUserSettings::max_number_of_players_in_tribe, 0));

    // Phase 8j — Stat clamps / Blueprint caps
    window.set_f_max_blueprint_dino_level(ui_2(ark_config::GameUserSettings::max_blueprint_dino_level, 0));
    window.set_f_max_blueprint_dino_quality(ui_2(ark_config::GameUserSettings::max_blueprint_dino_quality, 0));
    window.set_f_max_blueprint_item_quality(ui_2(ark_config::GameUserSettings::max_blueprint_item_quality, 0));
    window.set_f_max_blueprint_scout_quality(ui_2(ark_config::GameUserSettings::max_blueprint_scout_quality, 0));
    window.set_f_max_hexagons_per_character(ui_2(ark_config::GameUserSettings::max_hexagons_per_character, 2_000_000_000));
    window.set_b_clamp_item_spoiling_times(ub(ark_config::GameUserSettings::clamp_item_spoiling_times, false));
    window.set_b_clamp_item_stats(ub(ark_config::GameUserSettings::clamp_item_stats, false));
    window.set_b_clamp_resource_harvest_damage(ub(ark_config::GameUserSettings::clamp_resource_harvest_damage, false));
    window.set_f_implant_suicide_cd(ui_2(ark_config::GameUserSettings::implant_suicide_cd, 28800));
    window.set_f_server_auto_force_respawn_wild_dinos_interval(u(ark_config::GameUserSettings::server_auto_force_respawn_wild_dinos_interval, 0.0));
    window.set_f_destroy_tames_over_level_clamp(gi2(game_config::GameSettings::destroy_tames_over_level_clamp, 0));

    // Phase 8L — extra GameUserSettings.ini knobs
    window.set_b_fast_decay_unsnapped_core_structures(ub(ark_config::GameUserSettings::fast_decay_unsnapped_core_structures, false));
    window.set_b_override_structure_platform_prevention(ub(ark_config::GameUserSettings::override_structure_platform_prevention, false));
    window.set_b_prevent_offline_pvp(ub(ark_config::GameUserSettings::prevent_offline_pvp, false));
    window.set_f_prevent_offline_pvp_interval(u(ark_config::GameUserSettings::prevent_offline_pvp_interval, 0.0));
    window.set_b_pvp_dino_decay(ub(ark_config::GameUserSettings::pvp_dino_decay, false));
    window.set_b_pvp_structure_decay(ub(ark_config::GameUserSettings::pvp_structure_decay, false));
    window.set_f_pve_dino_decay_period_multiplier(u(ark_config::GameUserSettings::pve_dino_decay_period_multiplier, 1.0));
    window.set_b_only_auto_destroy_core_structures(ub(ark_config::GameUserSettings::only_auto_destroy_core_structures, false));
    window.set_b_auto_destroy_decayed_dinos(ub(ark_config::GameUserSettings::auto_destroy_decayed_dinos, false));
    window.set_b_tribe_log_destroyed_enemy_structures(ub(ark_config::GameUserSettings::tribe_log_destroyed_enemy_structures, false));
    window.set_b_pve_allow_structures_at_supply_drops(ub(ark_config::GameUserSettings::pve_allow_structures_at_supply_drops, false));
    window.set_f_oxygen_swim_speed_stat_multiplier(u(ark_config::GameUserSettings::oxygen_swim_speed_stat_multiplier, 1.0));
    window.set_f_tribe_name_change_cooldown(u(ark_config::GameUserSettings::tribe_name_change_cooldown, 15.0));
    window.set_f_platform_saddle_build_area_bounds_multiplier(u(ark_config::GameUserSettings::platform_saddle_build_area_bounds_multiplier, 1.0));
    window.set_f_raid_dino_character_food_drain_multiplier(u(ark_config::GameUserSettings::raid_dino_character_food_drain_multiplier, 1.0));
    window.set_f_item_stack_size_multiplier(u(ark_config::GameUserSettings::item_stack_size_multiplier, 1.0));
    window.set_f_start_time_hour(u(ark_config::GameUserSettings::start_time_hour, -1.0));
    window.set_f_rcon_server_game_log_buffer(ui_2(ark_config::GameUserSettings::rcon_server_game_log_buffer, 600));
    window.set_b_allow_raid_dino_feeding(ub(ark_config::GameUserSettings::allow_raid_dino_feeding, true));
    window.set_b_enable_extra_structure_prevention_volumes(ub(ark_config::GameUserSettings::enable_extra_structure_prevention_volumes, false));
    window.set_b_prevent_spawn_animations(ub(ark_config::GameUserSettings::prevent_spawn_animations, false));
    window.set_b_prevent_diseases(ub(ark_config::GameUserSettings::prevent_diseases, false));
    window.set_b_non_permanent_diseases(ub(ark_config::GameUserSettings::non_permanent_diseases, false));
    window.set_b_use_optimized_harvesting_health(ub(ark_config::GameUserSettings::use_optimized_harvesting_health, false));
    window.set_b_allow_multiple_attached_c4(ub(ark_config::GameUserSettings::allow_multiple_attached_c4, false));
    window.set_b_allow_flying_stamina_recovery(ub(ark_config::GameUserSettings::allow_flying_stamina_recovery, false));
    window.set_b_allow_crate_spawns_on_top_of_structures(ub(ark_config::GameUserSettings::allow_crate_spawns_on_top_of_structures, false));

    // Phase 8P — MOTD
    let motd_msg = gus.as_ref().and_then(|g| g.motd_message()).unwrap_or_default();
    window.set_f_motd_message(motd_msg.as_str().into());
    let motd_dur = gus.as_ref().and_then(|g| g.motd_duration()).unwrap_or(20);
    window.set_f_motd_duration(fmt_int_for_form(motd_dur));

    // Phase 8k — Launch flags (Profile MM_Command_Val)
    let flags_text = profile_path
        .and_then(|p| Profile::load(p).ok())
        .and_then(|p| p.server_command_line())
        .map(|cmd| {
            let (_, flags) = launch_args::split_command_line(&cmd);
            flags.join("\n")
        })
        .unwrap_or_default();
    window.set_f_launch_flags(flags_text.as_str().into());
    window.set_f_launch_flags_reference(launch_args::COMMON_LAUNCH_FLAGS.join("  ").into());

    // Phase 8R — Mod IDs (Profile MM_Command_Val `-mods=` token)
    let mods_text = profile_path
        .and_then(|p| Profile::load(p).ok())
        .and_then(|p| p.server_command_line())
        .map(|cmd| {
            launch_args::extract_mods_from_command_line(&cmd)
                .iter()
                .map(|m| m.to_string())
                .collect::<Vec<_>>()
                .join("\n")
        })
        .unwrap_or_default();
    window.set_f_mods_csv(mods_text.as_str().into());
}

/// Reset every form field to ARK's vanilla defaults (mostly 1.0, plus the
/// difficulty/structure values noted upstream).
fn reset_world_settings_window(window: &WorldSettingsWindow) {
    let one = SharedString::from("1.0");
    window.set_f_xp_multiplier(one.clone());
    window.set_f_harvest_amount_multiplier(one.clone());
    window.set_f_harvest_health_multiplier(one.clone());
    window.set_f_resources_respawn_period_multiplier(one.clone());
    window.set_f_taming_speed_multiplier(one.clone());
    window.set_f_mating_interval_multiplier(one.clone());
    window.set_f_egg_hatch_speed_multiplier(one.clone());
    window.set_f_baby_mature_speed_multiplier(one.clone());

    window.set_f_day_cycle_speed_scale(one.clone());
    window.set_f_day_time_speed_scale(one.clone());
    window.set_f_night_time_speed_scale(one.clone());

    window.set_f_player_food(one.clone());
    window.set_f_player_water(one.clone());
    window.set_f_player_stamina(one.clone());
    window.set_f_player_health_recovery(one.clone());
    window.set_f_player_damage(one.clone());
    window.set_f_player_resistance(one.clone());
    window.set_f_player_harvesting(one.clone());

    window.set_f_dino_food(one.clone());
    window.set_f_dino_stamina(one.clone());
    window.set_f_dino_health_recovery(one.clone());
    window.set_f_tamed_damage(one.clone());
    window.set_f_tamed_resistance(one.clone());

    window.set_f_wild_food(one.clone());
    window.set_f_wild_stamina(one.clone());
    window.set_f_wild_torpor(one.clone());
    window.set_f_dino_count(one.clone());

    window.set_f_difficulty_offset(SharedString::from("0.2"));
    window.set_f_override_official_difficulty(SharedString::from("5.0"));
    window.set_f_structure_damage(one.clone());
    window.set_f_structure_resistance(one);
    window.set_f_structure_repair_cooldown(SharedString::from("180.0"));
    window.set_b_disable_imprint_dino_buff(false);
    window.set_b_allow_anyone_baby_imprint(false);

    // Phase 8b — PvE/PvP defaults (all PvP-on / non-PvE)
    window.set_b_server_pve(false);
    window.set_b_allow_flyer_carry_pve(false);
    window.set_b_enable_cryo_sickness_pve(false);
    window.set_b_disable_structure_decay_pve(false);

    // Phase 8b — Operations basics
    window.set_f_max_tamed_dinos(SharedString::from("5000.0"));
    window.set_f_kick_idle_players_period(SharedString::from("3600.0"));
    window.set_f_auto_save_period_minutes(SharedString::from("15.0"));
    window.set_f_the_max_structures_in_range(SharedString::from("10500"));

    // Phase 8c — Breeding / Imprint
    let one = SharedString::from("1.0");
    window.set_f_mating_speed_multiplier(one.clone());
    window.set_f_lay_egg_interval_multiplier(one.clone());
    window.set_f_passive_tame_interval_multiplier(one.clone());
    window.set_f_baby_food_consumption_speed_multiplier(one.clone());
    window.set_f_baby_imprint_amount_multiplier(one.clone());
    window.set_f_baby_imprinting_stat_scale_multiplier(one.clone());
    window.set_f_baby_cuddle_interval_multiplier(one.clone());
    window.set_f_baby_cuddle_grace_period_multiplier(one.clone());
    window.set_f_baby_cuddle_lose_imprint_quality_speed_multiplier(one.clone());
    window.set_b_disable_dino_breeding(false);
    window.set_b_disable_dino_taming(false);

    // Phase 8d — Loot / Spoilage
    window.set_f_supply_crate_loot_quality_multiplier(one.clone());
    window.set_f_fishing_loot_quality_multiplier(one.clone());
    window.set_f_crop_growth_speed_multiplier(one.clone());
    window.set_f_crop_decay_speed_multiplier(one.clone());
    window.set_b_disable_loot_crates(false);
    window.set_f_limit_non_player_dropped_items_count(SharedString::from("0"));
    window.set_f_limit_non_player_dropped_items_range(SharedString::from("0"));
    window.set_f_global_spoiling_time_multiplier(one.clone());
    window.set_f_global_item_decomposition_time_multiplier(one.clone());
    window.set_f_global_corpse_decomposition_time_multiplier(one.clone());
    window.set_f_use_corpse_life_span_multiplier(one.clone());
    window.set_b_use_corpse_locator(true);
    window.set_f_poop_interval_multiplier(one.clone());
    window.set_f_fuel_consumption_interval_multiplier(one.clone());
    window.set_f_max_fall_speed_multiplier(one.clone());

    // Phase 8e — Stat arrays — every cell to 1.0
    let one_s = SharedString::from("1.0");
    window.set_f_pls_player_0(one_s.clone()); window.set_f_pls_player_1(one_s.clone()); window.set_f_pls_player_2(one_s.clone()); window.set_f_pls_player_3(one_s.clone()); window.set_f_pls_player_4(one_s.clone()); window.set_f_pls_player_5(one_s.clone()); window.set_f_pls_player_6(one_s.clone()); window.set_f_pls_player_7(one_s.clone()); window.set_f_pls_player_8(one_s.clone()); window.set_f_pls_player_9(one_s.clone()); window.set_f_pls_player_10(one_s.clone()); window.set_f_pls_player_11(one_s.clone());
    window.set_f_pls_tamed_0(one_s.clone()); window.set_f_pls_tamed_1(one_s.clone()); window.set_f_pls_tamed_2(one_s.clone()); window.set_f_pls_tamed_3(one_s.clone()); window.set_f_pls_tamed_4(one_s.clone()); window.set_f_pls_tamed_5(one_s.clone()); window.set_f_pls_tamed_6(one_s.clone()); window.set_f_pls_tamed_7(one_s.clone()); window.set_f_pls_tamed_8(one_s.clone()); window.set_f_pls_tamed_9(one_s.clone()); window.set_f_pls_tamed_10(one_s.clone()); window.set_f_pls_tamed_11(one_s.clone());
    window.set_f_pls_tamed_add_0(one_s.clone()); window.set_f_pls_tamed_add_1(one_s.clone()); window.set_f_pls_tamed_add_2(one_s.clone()); window.set_f_pls_tamed_add_3(one_s.clone()); window.set_f_pls_tamed_add_4(one_s.clone()); window.set_f_pls_tamed_add_5(one_s.clone()); window.set_f_pls_tamed_add_6(one_s.clone()); window.set_f_pls_tamed_add_7(one_s.clone()); window.set_f_pls_tamed_add_8(one_s.clone()); window.set_f_pls_tamed_add_9(one_s.clone()); window.set_f_pls_tamed_add_10(one_s.clone()); window.set_f_pls_tamed_add_11(one_s.clone());
    window.set_f_pls_tamed_affinity_0(one_s.clone()); window.set_f_pls_tamed_affinity_1(one_s.clone()); window.set_f_pls_tamed_affinity_2(one_s.clone()); window.set_f_pls_tamed_affinity_3(one_s.clone()); window.set_f_pls_tamed_affinity_4(one_s.clone()); window.set_f_pls_tamed_affinity_5(one_s.clone()); window.set_f_pls_tamed_affinity_6(one_s.clone()); window.set_f_pls_tamed_affinity_7(one_s.clone()); window.set_f_pls_tamed_affinity_8(one_s.clone()); window.set_f_pls_tamed_affinity_9(one_s.clone()); window.set_f_pls_tamed_affinity_10(one_s.clone()); window.set_f_pls_tamed_affinity_11(one_s.clone());
    window.set_f_pls_wild_0(one_s.clone()); window.set_f_pls_wild_1(one_s.clone()); window.set_f_pls_wild_2(one_s.clone()); window.set_f_pls_wild_3(one_s.clone()); window.set_f_pls_wild_4(one_s.clone()); window.set_f_pls_wild_5(one_s.clone()); window.set_f_pls_wild_6(one_s.clone()); window.set_f_pls_wild_7(one_s.clone()); window.set_f_pls_wild_8(one_s.clone()); window.set_f_pls_wild_9(one_s.clone()); window.set_f_pls_wild_10(one_s.clone()); window.set_f_pls_wild_11(one_s.clone());
    window.set_f_pls_base_0(one_s.clone()); window.set_f_pls_base_1(one_s.clone()); window.set_f_pls_base_2(one_s.clone()); window.set_f_pls_base_3(one_s.clone()); window.set_f_pls_base_4(one_s.clone()); window.set_f_pls_base_5(one_s.clone()); window.set_f_pls_base_6(one_s.clone()); window.set_f_pls_base_7(one_s.clone()); window.set_f_pls_base_8(one_s.clone()); window.set_f_pls_base_9(one_s.clone()); window.set_f_pls_base_10(one_s.clone()); window.set_f_pls_base_11(one_s);

    // Phase 8f — Combat / Structures
    window.set_f_dino_harvesting_damage_multiplier(SharedString::from("3.2"));
    window.set_f_dino_turret_damage_multiplier(SharedString::from("1.0"));
    window.set_b_allow_speed_leveling(true);
    window.set_b_allow_flyer_speed_leveling(false);
    window.set_b_disable_friendly_fire(false);
    window.set_b_pve_disable_friendly_fire(false);
    window.set_b_allow_unlimited_respecs(false);
    window.set_b_hard_limit_turrets_in_range(false);
    window.set_b_limit_turrets_in_range(true);
    window.set_f_limit_turrets_num(SharedString::from("100"));
    window.set_f_limit_turrets_range(SharedString::from("10000"));
    window.set_f_structure_prevent_resource_radius_multiplier(SharedString::from("1.0"));
    window.set_f_per_platform_max_structures_multiplier(SharedString::from("1.0"));
    window.set_b_always_allow_structure_pickup(false);
    window.set_f_structure_pickup_time_after_placement(SharedString::from("30.0"));
    window.set_f_structure_pickup_hold_duration(SharedString::from("0.5"));
    window.set_f_max_platform_saddle_structure_limit(SharedString::from("75"));
    window.set_b_enable_cryopod_nerf(false);
    window.set_f_cryopod_nerf_damage_mult(SharedString::from("0.01"));
    window.set_f_cryopod_nerf_duration(SharedString::from("0.0"));
    window.set_b_allow_cryo_fridge_on_saddle(false);
    window.set_b_disable_cryopod_fridge_requirement(false);
    // Phase 8T — additional Cryopod knobs
    window.set_f_cryopod_nerf_incoming_damage_mult_percent(SharedString::from("0.0"));
    window.set_b_disable_cryopod_enemy_check(false);
    window.set_f_cryopod_fridge_cooldowntime(SharedString::from("90"));

    // Phase 8g — XP gain breakdown
    let one_xp = SharedString::from("1.0");
    window.set_f_generic_xp_multiplier(one_xp.clone());
    window.set_f_harvest_xp_multiplier(one_xp.clone());
    window.set_f_kill_xp_multiplier(one_xp.clone());
    window.set_f_craft_xp_multiplier(one_xp.clone());
    window.set_f_special_xp_multiplier(one_xp.clone());
    window.set_f_explorer_note_xp_multiplier(one_xp.clone());
    window.set_f_boss_kill_xp_multiplier(one_xp.clone());
    window.set_f_cave_kill_xp_multiplier(one_xp.clone());
    window.set_f_wild_kill_xp_multiplier(one_xp.clone());
    window.set_f_tamed_kill_xp_multiplier(one_xp.clone());
    window.set_f_unclaimed_kill_xp_multiplier(one_xp.clone());
    window.set_f_alpha_kill_xp_multiplier(one_xp);
    window.set_f_override_max_experience_points_player(SharedString::from("0"));
    window.set_f_override_max_experience_points_dino(SharedString::from("0"));

    // Phase 8h — Cosmetic / Chat
    window.set_b_global_voice_chat(false);
    window.set_b_proximity_chat(false);
    window.set_b_dont_always_notify_player_joined(false);
    window.set_b_always_notify_player_left(false);
    window.set_b_admin_logging(false);
    window.set_b_allow_hide_damage_source_from_logs(false);
    window.set_b_show_floating_damage_text(false);
    window.set_b_show_map_player_location(true);
    window.set_b_server_crosshair(true);
    window.set_b_server_force_no_hud(false);
    window.set_b_allow_third_person_player(true);
    window.set_b_allow_hit_markers(true);
    window.set_b_disable_pve_gamma(false);
    window.set_b_enable_pvp_gamma(false);

    // Phase 8i — Cluster / Lists
    let empty = SharedString::default();
    window.set_f_server_password(empty.clone());
    window.set_f_ban_list_url(empty.clone());
    window.set_f_admin_list_url(empty.clone());
    window.set_f_bad_word_list_url(empty.clone());
    window.set_f_bad_word_white_list_url(empty.clone());
    window.set_f_custom_live_tuning_url(empty);
    window.set_b_no_tribute_downloads(false);
    window.set_b_prevent_download_dinos(false);
    window.set_b_prevent_download_items(false);
    window.set_b_prevent_download_survivors(false);
    window.set_b_prevent_upload_dinos(false);
    window.set_b_prevent_upload_items(false);
    window.set_b_prevent_upload_survivors(false);
    window.set_b_cross_ark_allow_foreign_dino_downloads(false);
    window.set_b_prevent_tribe_alliances(false);
    window.set_f_max_number_of_players_in_tribe(SharedString::from("0"));

    // Phase 8j — Stat clamps / Blueprint caps
    let zero = SharedString::from("0");
    window.set_f_max_blueprint_dino_level(zero.clone());
    window.set_f_max_blueprint_dino_quality(zero.clone());
    window.set_f_max_blueprint_item_quality(zero.clone());
    window.set_f_max_blueprint_scout_quality(zero.clone());
    window.set_f_max_hexagons_per_character(SharedString::from("2000000000"));
    window.set_b_clamp_item_spoiling_times(false);
    window.set_b_clamp_item_stats(false);
    window.set_b_clamp_resource_harvest_damage(false);
    window.set_f_implant_suicide_cd(SharedString::from("28800"));
    window.set_f_server_auto_force_respawn_wild_dinos_interval(SharedString::from("0.0"));
    window.set_f_destroy_tames_over_level_clamp(zero);

    // Phase 8L — extra GameUserSettings.ini knobs (defaults)
    window.set_b_fast_decay_unsnapped_core_structures(false);
    window.set_b_override_structure_platform_prevention(false);
    window.set_b_prevent_offline_pvp(false);
    window.set_f_prevent_offline_pvp_interval(SharedString::from("0.0"));
    window.set_b_pvp_dino_decay(false);
    window.set_b_pvp_structure_decay(false);
    window.set_f_pve_dino_decay_period_multiplier(SharedString::from("1.0"));
    window.set_b_only_auto_destroy_core_structures(false);
    window.set_b_auto_destroy_decayed_dinos(false);
    window.set_b_tribe_log_destroyed_enemy_structures(false);
    window.set_b_pve_allow_structures_at_supply_drops(false);
    window.set_f_oxygen_swim_speed_stat_multiplier(SharedString::from("1.0"));
    window.set_f_tribe_name_change_cooldown(SharedString::from("15.0"));
    window.set_f_platform_saddle_build_area_bounds_multiplier(SharedString::from("1.0"));
    window.set_f_raid_dino_character_food_drain_multiplier(SharedString::from("1.0"));
    window.set_f_item_stack_size_multiplier(SharedString::from("1.0"));
    window.set_f_start_time_hour(SharedString::from("-1.0"));
    window.set_f_rcon_server_game_log_buffer(SharedString::from("600"));
    window.set_b_allow_raid_dino_feeding(true);
    window.set_b_enable_extra_structure_prevention_volumes(false);
    window.set_b_prevent_spawn_animations(false);
    window.set_b_prevent_diseases(false);
    window.set_b_non_permanent_diseases(false);
    window.set_b_use_optimized_harvesting_health(false);
    window.set_b_allow_multiple_attached_c4(false);
    window.set_b_allow_flying_stamina_recovery(false);
    window.set_b_allow_crate_spawns_on_top_of_structures(false);

    // Phase 8P — MOTD
    window.set_f_motd_message(SharedString::default());
    window.set_f_motd_duration(SharedString::from("20"));

    // Phase 8k — Launch flags (default to common starting set)
    window.set_f_launch_flags(SharedString::from("-log\n-NoBattlEye"));
    window.set_f_launch_flags_reference(launch_args::COMMON_LAUNCH_FLAGS.join("  ").into());
}

/// Read all form fields, parse floats, return per-file struct values or a
/// validation error pinpointing the first bad input.
///
/// Routing comment per field: (G) = Game.ini, (U) = GameUserSettings.ini.
/// Phase 8b corrected the routing: most multipliers used to be saved to
/// Game.ini but the canonical home for the bulk of them is GameUserSettings.
#[allow(dead_code)]
struct WorldFormValues {
    // Rates — (U) GameUserSettings.ini [ServerSettings]
    xp_multiplier: f64,
    harvest_amount_multiplier: f64,
    harvest_health_multiplier: f64,
    resources_respawn_period_multiplier: f64,
    taming_speed_multiplier: f64,
    // Breeding rates — (G) Game.ini
    mating_interval_multiplier: f64,
    egg_hatch_speed_multiplier: f64,
    baby_mature_speed_multiplier: f64,

    // Day cycle — (U)
    day_cycle_speed_scale: f64,
    day_time_speed_scale: f64,
    night_time_speed_scale: f64,

    // Player tuning — (U) except harvesting which is (G)
    player_food: f64,
    player_water: f64,
    player_stamina: f64,
    player_health_recovery: f64,
    player_damage: f64,
    player_resistance: f64,
    player_harvesting: f64,

    // Tamed dino — (U)
    dino_food: f64,
    dino_stamina: f64,
    dino_health_recovery: f64,
    tamed_damage: f64,
    tamed_resistance: f64,

    // Wild dino — food/torpor (G), stamina (U), count (U)
    wild_food: f64,
    wild_stamina: f64,
    wild_torpor: f64,
    dino_count: f64,

    // Structures — damage/resistance (U), repair cooldown (G)
    structure_damage: f64,
    structure_resistance: f64,
    structure_repair_cooldown: f64,
    // Imprint behaviour — (G)
    disable_imprint_dino_buff: bool,
    allow_anyone_baby_imprint: bool,

    // Difficulty — (U)
    difficulty_offset: f64,
    override_official_difficulty: f64,

    // PvE / PvP toggles — (U)
    server_pve: bool,
    allow_flyer_carry_pve: bool,
    enable_cryo_sickness_pve: bool,
    disable_structure_decay_pve: bool,

    // Operations basics — (U)
    max_tamed_dinos: f64,
    kick_idle_players_period: f64,
    auto_save_period_minutes: f64,
    the_max_structures_in_range: i64,

    // Phase 8c — Breeding / Imprint — (G)
    mating_speed_multiplier: f64,
    lay_egg_interval_multiplier: f64,
    passive_tame_interval_multiplier: f64,
    baby_food_consumption_speed_multiplier: f64,
    baby_imprint_amount_multiplier: f64,
    baby_imprinting_stat_scale_multiplier: f64,
    baby_cuddle_interval_multiplier: f64,
    baby_cuddle_grace_period_multiplier: f64,
    baby_cuddle_lose_imprint_quality_speed_multiplier: f64,
    disable_dino_breeding: bool,
    disable_dino_taming: bool,

    // Phase 8d — Loot / Spoilage — (G)
    supply_crate_loot_quality_multiplier: f64,
    fishing_loot_quality_multiplier: f64,
    crop_growth_speed_multiplier: f64,
    crop_decay_speed_multiplier: f64,
    disable_loot_crates: bool,
    limit_non_player_dropped_items_count: i64,
    limit_non_player_dropped_items_range: i64,
    global_spoiling_time_multiplier: f64,
    global_item_decomposition_time_multiplier: f64,
    global_corpse_decomposition_time_multiplier: f64,
    use_corpse_life_span_multiplier: f64,
    use_corpse_locator: bool,
    poop_interval_multiplier: f64,
    fuel_consumption_interval_multiplier: f64,
    max_fall_speed_multiplier: f64,

    // Phase 8e — Stat arrays (Game.ini)
    pls_player: [f64; 12],
    pls_tamed: [f64; 12],
    pls_tamed_add: [f64; 12],
    pls_tamed_affinity: [f64; 12],
    pls_wild: [f64; 12],
    pls_base: [f64; 12],

    // Phase 8f — Combat / Structures
    dino_harvesting_damage_multiplier: f64,
    dino_turret_damage_multiplier: f64,
    allow_speed_leveling: bool,
    allow_flyer_speed_leveling: bool,
    disable_friendly_fire: bool,
    pve_disable_friendly_fire: bool,
    allow_unlimited_respecs: bool,
    hard_limit_turrets_in_range: bool,
    limit_turrets_in_range: bool,
    limit_turrets_num: i64,
    limit_turrets_range: f64,
    structure_prevent_resource_radius_multiplier: f64,
    per_platform_max_structures_multiplier: f64,
    always_allow_structure_pickup: bool,
    structure_pickup_time_after_placement: f64,
    structure_pickup_hold_duration: f64,
    max_platform_saddle_structure_limit: i64,
    enable_cryopod_nerf: bool,
    cryopod_nerf_damage_mult: f64,
    cryopod_nerf_duration: f64,
    allow_cryo_fridge_on_saddle: bool,
    disable_cryopod_fridge_requirement: bool,
    // Phase 8T — additional Cryopod knobs
    cryopod_nerf_incoming_damage_mult_percent: f64,
    disable_cryopod_enemy_check: bool,
    cryopod_fridge_cooldowntime: i64,

    // Phase 8g — XP gain breakdown (Game.ini)
    generic_xp_multiplier: f64,
    harvest_xp_multiplier: f64,
    kill_xp_multiplier: f64,
    craft_xp_multiplier: f64,
    special_xp_multiplier: f64,
    explorer_note_xp_multiplier: f64,
    boss_kill_xp_multiplier: f64,
    cave_kill_xp_multiplier: f64,
    wild_kill_xp_multiplier: f64,
    tamed_kill_xp_multiplier: f64,
    unclaimed_kill_xp_multiplier: f64,
    alpha_kill_xp_multiplier: f64,
    override_max_experience_points_player: i64,
    override_max_experience_points_dino: i64,

    // Phase 8h — Cosmetic / Chat (GUS)
    global_voice_chat: bool,
    proximity_chat: bool,
    dont_always_notify_player_joined: bool,
    always_notify_player_left: bool,
    admin_logging: bool,
    allow_hide_damage_source_from_logs: bool,
    show_floating_damage_text: bool,
    show_map_player_location: bool,
    server_crosshair: bool,
    server_force_no_hud: bool,
    allow_third_person_player: bool,
    allow_hit_markers: bool,
    disable_pve_gamma: bool,
    enable_pvp_gamma: bool,

    // Phase 8i — Cluster / Lists (GUS)
    server_password: String,
    ban_list_url: String,
    admin_list_url: String,
    bad_word_list_url: String,
    bad_word_white_list_url: String,
    custom_live_tuning_url: String,
    no_tribute_downloads: bool,
    prevent_download_dinos: bool,
    prevent_download_items: bool,
    prevent_download_survivors: bool,
    prevent_upload_dinos: bool,
    prevent_upload_items: bool,
    prevent_upload_survivors: bool,
    cross_ark_allow_foreign_dino_downloads: bool,
    prevent_tribe_alliances: bool,
    max_number_of_players_in_tribe: i64,

    // Phase 8j — Stat clamps / Blueprint caps
    max_blueprint_dino_level: i64,
    max_blueprint_dino_quality: i64,
    max_blueprint_item_quality: i64,
    max_blueprint_scout_quality: i64,
    max_hexagons_per_character: i64,
    clamp_item_spoiling_times: bool,
    clamp_item_stats: bool,
    clamp_resource_harvest_damage: bool,
    implant_suicide_cd: i64,
    server_auto_force_respawn_wild_dinos_interval: f64,
    destroy_tames_over_level_clamp: i64,

    // Phase 8L — extra GameUserSettings.ini knobs
    fast_decay_unsnapped_core_structures: bool,
    override_structure_platform_prevention: bool,
    prevent_offline_pvp: bool,
    prevent_offline_pvp_interval: f64,
    pvp_dino_decay: bool,
    pvp_structure_decay: bool,
    pve_dino_decay_period_multiplier: f64,
    only_auto_destroy_core_structures: bool,
    auto_destroy_decayed_dinos: bool,
    tribe_log_destroyed_enemy_structures: bool,
    pve_allow_structures_at_supply_drops: bool,
    oxygen_swim_speed_stat_multiplier: f64,
    tribe_name_change_cooldown: f64,
    platform_saddle_build_area_bounds_multiplier: f64,
    raid_dino_character_food_drain_multiplier: f64,
    item_stack_size_multiplier: f64,
    start_time_hour: f64,
    rcon_server_game_log_buffer: i64,
    allow_raid_dino_feeding: bool,
    enable_extra_structure_prevention_volumes: bool,
    prevent_spawn_animations: bool,
    prevent_diseases: bool,
    non_permanent_diseases: bool,
    use_optimized_harvesting_health: bool,
    allow_multiple_attached_c4: bool,
    allow_flying_stamina_recovery: bool,
    allow_crate_spawns_on_top_of_structures: bool,

    // Phase 8P — MOTD ([MessageOfTheDay] section in GameUserSettings.ini)
    motd_message: String,
    motd_duration: i64,

    // Phase 8k — Launch flags (saved into Profile MM_Command_Val)
    launch_flags: String,

    // Phase 8R — Mod IDs (also saved into Profile MM_Command_Val)
    mods: Vec<u64>,
}

fn parse_form_float(value: SharedString, label: &str) -> Result<f64, String> {
    value
        .as_str()
        .trim()
        .parse::<f64>()
        .map_err(|_| format!("Invalid number for {label}: {value:?}"))
}

fn parse_form_int(value: SharedString, label: &str) -> Result<i64, String> {
    value
        .as_str()
        .trim()
        .parse::<i64>()
        .map_err(|_| format!("Invalid integer for {label}: {value:?}"))
}

fn collect_world_form(window: &WorldSettingsWindow) -> Result<WorldFormValues, String> {
    Ok(WorldFormValues {
        xp_multiplier: parse_form_float(window.get_f_xp_multiplier(), "XPMultiplier")?,
        harvest_amount_multiplier: parse_form_float(
            window.get_f_harvest_amount_multiplier(),
            "HarvestAmountMultiplier",
        )?,
        harvest_health_multiplier: parse_form_float(
            window.get_f_harvest_health_multiplier(),
            "HarvestHealthMultiplier",
        )?,
        resources_respawn_period_multiplier: parse_form_float(
            window.get_f_resources_respawn_period_multiplier(),
            "ResourcesRespawnPeriodMultiplier",
        )?,
        taming_speed_multiplier: parse_form_float(
            window.get_f_taming_speed_multiplier(),
            "TamingSpeedMultiplier",
        )?,
        mating_interval_multiplier: parse_form_float(
            window.get_f_mating_interval_multiplier(),
            "MatingIntervalMultiplier",
        )?,
        egg_hatch_speed_multiplier: parse_form_float(
            window.get_f_egg_hatch_speed_multiplier(),
            "EggHatchSpeedMultiplier",
        )?,
        baby_mature_speed_multiplier: parse_form_float(
            window.get_f_baby_mature_speed_multiplier(),
            "BabyMatureSpeedMultiplier",
        )?,
        day_cycle_speed_scale: parse_form_float(
            window.get_f_day_cycle_speed_scale(),
            "DayCycleSpeedScale",
        )?,
        day_time_speed_scale: parse_form_float(
            window.get_f_day_time_speed_scale(),
            "DayTimeSpeedScale",
        )?,
        night_time_speed_scale: parse_form_float(
            window.get_f_night_time_speed_scale(),
            "NightTimeSpeedScale",
        )?,
        player_food: parse_form_float(window.get_f_player_food(), "PlayerCharacterFoodDrainMultiplier")?,
        player_water: parse_form_float(window.get_f_player_water(), "PlayerCharacterWaterDrainMultiplier")?,
        player_stamina: parse_form_float(window.get_f_player_stamina(), "PlayerCharacterStaminaDrainMultiplier")?,
        player_health_recovery: parse_form_float(window.get_f_player_health_recovery(), "PlayerCharacterHealthRecoveryMultiplier")?,
        player_damage: parse_form_float(window.get_f_player_damage(), "PlayerDamageMultiplier")?,
        player_resistance: parse_form_float(window.get_f_player_resistance(), "PlayerResistanceMultiplier")?,
        player_harvesting: parse_form_float(window.get_f_player_harvesting(), "PlayerHarvestingDamageMultiplier")?,
        dino_food: parse_form_float(window.get_f_dino_food(), "DinoCharacterFoodDrainMultiplier")?,
        dino_stamina: parse_form_float(window.get_f_dino_stamina(), "DinoCharacterStaminaDrainMultiplier")?,
        dino_health_recovery: parse_form_float(window.get_f_dino_health_recovery(), "DinoCharacterHealthRecoveryMultiplier")?,
        tamed_damage: parse_form_float(window.get_f_tamed_damage(), "TamedDinoDamageMultiplier")?,
        tamed_resistance: parse_form_float(window.get_f_tamed_resistance(), "TamedDinoResistanceMultiplier")?,
        wild_food: parse_form_float(window.get_f_wild_food(), "WildDinoCharacterFoodDrainMultiplier")?,
        wild_stamina: parse_form_float(window.get_f_wild_stamina(), "WildDinoCharacterStaminaDrainMultiplier")?,
        wild_torpor: parse_form_float(window.get_f_wild_torpor(), "WildDinoTorporDrainMultiplier")?,
        dino_count: parse_form_float(window.get_f_dino_count(), "DinoCountMultiplier")?,
        structure_damage: parse_form_float(window.get_f_structure_damage(), "StructureDamageMultiplier")?,
        structure_resistance: parse_form_float(window.get_f_structure_resistance(), "StructureResistanceMultiplier")?,
        structure_repair_cooldown: parse_form_float(window.get_f_structure_repair_cooldown(), "StructureDamageRepairCooldown")?,
        disable_imprint_dino_buff: window.get_b_disable_imprint_dino_buff(),
        allow_anyone_baby_imprint: window.get_b_allow_anyone_baby_imprint(),
        difficulty_offset: parse_form_float(window.get_f_difficulty_offset(), "DifficultyOffset")?,
        override_official_difficulty: parse_form_float(window.get_f_override_official_difficulty(), "OverrideOfficialDifficulty")?,
        server_pve: window.get_b_server_pve(),
        allow_flyer_carry_pve: window.get_b_allow_flyer_carry_pve(),
        enable_cryo_sickness_pve: window.get_b_enable_cryo_sickness_pve(),
        disable_structure_decay_pve: window.get_b_disable_structure_decay_pve(),
        max_tamed_dinos: parse_form_float(window.get_f_max_tamed_dinos(), "MaxTamedDinos")?,
        kick_idle_players_period: parse_form_float(window.get_f_kick_idle_players_period(), "KickIdlePlayersPeriod")?,
        auto_save_period_minutes: parse_form_float(window.get_f_auto_save_period_minutes(), "AutoSavePeriodMinutes")?,
        the_max_structures_in_range: parse_form_int(window.get_f_the_max_structures_in_range(), "TheMaxStructuresInRange")?,
        mating_speed_multiplier: parse_form_float(window.get_f_mating_speed_multiplier(), "MatingSpeedMultiplier")?,
        lay_egg_interval_multiplier: parse_form_float(window.get_f_lay_egg_interval_multiplier(), "LayEggIntervalMultiplier")?,
        passive_tame_interval_multiplier: parse_form_float(window.get_f_passive_tame_interval_multiplier(), "PassiveTameIntervalMultiplier")?,
        baby_food_consumption_speed_multiplier: parse_form_float(window.get_f_baby_food_consumption_speed_multiplier(), "BabyFoodConsumptionSpeedMultiplier")?,
        baby_imprint_amount_multiplier: parse_form_float(window.get_f_baby_imprint_amount_multiplier(), "BabyImprintAmountMultiplier")?,
        baby_imprinting_stat_scale_multiplier: parse_form_float(window.get_f_baby_imprinting_stat_scale_multiplier(), "BabyImprintingStatScaleMultiplier")?,
        baby_cuddle_interval_multiplier: parse_form_float(window.get_f_baby_cuddle_interval_multiplier(), "BabyCuddleIntervalMultiplier")?,
        baby_cuddle_grace_period_multiplier: parse_form_float(window.get_f_baby_cuddle_grace_period_multiplier(), "BabyCuddleGracePeriodMultiplier")?,
        baby_cuddle_lose_imprint_quality_speed_multiplier: parse_form_float(window.get_f_baby_cuddle_lose_imprint_quality_speed_multiplier(), "BabyCuddleLoseImprintQualitySpeedMultiplier")?,
        disable_dino_breeding: window.get_b_disable_dino_breeding(),
        disable_dino_taming: window.get_b_disable_dino_taming(),
        supply_crate_loot_quality_multiplier: parse_form_float(window.get_f_supply_crate_loot_quality_multiplier(), "SupplyCrateLootQualityMultiplier")?,
        fishing_loot_quality_multiplier: parse_form_float(window.get_f_fishing_loot_quality_multiplier(), "FishingLootQualityMultiplier")?,
        crop_growth_speed_multiplier: parse_form_float(window.get_f_crop_growth_speed_multiplier(), "CropGrowthSpeedMultiplier")?,
        crop_decay_speed_multiplier: parse_form_float(window.get_f_crop_decay_speed_multiplier(), "CropDecaySpeedMultiplier")?,
        disable_loot_crates: window.get_b_disable_loot_crates(),
        limit_non_player_dropped_items_count: parse_form_int(window.get_f_limit_non_player_dropped_items_count(), "LimitNonPlayerDroppedItemsCount")?,
        limit_non_player_dropped_items_range: parse_form_int(window.get_f_limit_non_player_dropped_items_range(), "LimitNonPlayerDroppedItemsRange")?,
        global_spoiling_time_multiplier: parse_form_float(window.get_f_global_spoiling_time_multiplier(), "GlobalSpoilingTimeMultiplier")?,
        global_item_decomposition_time_multiplier: parse_form_float(window.get_f_global_item_decomposition_time_multiplier(), "GlobalItemDecompositionTimeMultiplier")?,
        global_corpse_decomposition_time_multiplier: parse_form_float(window.get_f_global_corpse_decomposition_time_multiplier(), "GlobalCorpseDecompositionTimeMultiplier")?,
        use_corpse_life_span_multiplier: parse_form_float(window.get_f_use_corpse_life_span_multiplier(), "UseCorpseLifeSpanMultiplier")?,
        use_corpse_locator: window.get_b_use_corpse_locator(),
        poop_interval_multiplier: parse_form_float(window.get_f_poop_interval_multiplier(), "PoopIntervalMultiplier")?,
        fuel_consumption_interval_multiplier: parse_form_float(window.get_f_fuel_consumption_interval_multiplier(), "FuelConsumptionIntervalMultiplier")?,
        max_fall_speed_multiplier: parse_form_float(window.get_f_max_fall_speed_multiplier(), "MaxFallSpeedMultiplier")?,
        pls_player: [
            parse_form_float(window.get_f_pls_player_0(), "PerLevelStatsMultiplier_Player[0]")?,
            parse_form_float(window.get_f_pls_player_1(), "PerLevelStatsMultiplier_Player[1]")?,
            parse_form_float(window.get_f_pls_player_2(), "PerLevelStatsMultiplier_Player[2]")?,
            parse_form_float(window.get_f_pls_player_3(), "PerLevelStatsMultiplier_Player[3]")?,
            parse_form_float(window.get_f_pls_player_4(), "PerLevelStatsMultiplier_Player[4]")?,
            parse_form_float(window.get_f_pls_player_5(), "PerLevelStatsMultiplier_Player[5]")?,
            parse_form_float(window.get_f_pls_player_6(), "PerLevelStatsMultiplier_Player[6]")?,
            parse_form_float(window.get_f_pls_player_7(), "PerLevelStatsMultiplier_Player[7]")?,
            parse_form_float(window.get_f_pls_player_8(), "PerLevelStatsMultiplier_Player[8]")?,
            parse_form_float(window.get_f_pls_player_9(), "PerLevelStatsMultiplier_Player[9]")?,
            parse_form_float(window.get_f_pls_player_10(), "PerLevelStatsMultiplier_Player[10]")?,
            parse_form_float(window.get_f_pls_player_11(), "PerLevelStatsMultiplier_Player[11]")?,
        ],
        pls_tamed: [
            parse_form_float(window.get_f_pls_tamed_0(), "PerLevelStatsMultiplier_DinoTamed[0]")?,
            parse_form_float(window.get_f_pls_tamed_1(), "PerLevelStatsMultiplier_DinoTamed[1]")?,
            parse_form_float(window.get_f_pls_tamed_2(), "PerLevelStatsMultiplier_DinoTamed[2]")?,
            parse_form_float(window.get_f_pls_tamed_3(), "PerLevelStatsMultiplier_DinoTamed[3]")?,
            parse_form_float(window.get_f_pls_tamed_4(), "PerLevelStatsMultiplier_DinoTamed[4]")?,
            parse_form_float(window.get_f_pls_tamed_5(), "PerLevelStatsMultiplier_DinoTamed[5]")?,
            parse_form_float(window.get_f_pls_tamed_6(), "PerLevelStatsMultiplier_DinoTamed[6]")?,
            parse_form_float(window.get_f_pls_tamed_7(), "PerLevelStatsMultiplier_DinoTamed[7]")?,
            parse_form_float(window.get_f_pls_tamed_8(), "PerLevelStatsMultiplier_DinoTamed[8]")?,
            parse_form_float(window.get_f_pls_tamed_9(), "PerLevelStatsMultiplier_DinoTamed[9]")?,
            parse_form_float(window.get_f_pls_tamed_10(), "PerLevelStatsMultiplier_DinoTamed[10]")?,
            parse_form_float(window.get_f_pls_tamed_11(), "PerLevelStatsMultiplier_DinoTamed[11]")?,
        ],
        pls_tamed_add: [
            parse_form_float(window.get_f_pls_tamed_add_0(), "PerLevelStatsMultiplier_DinoTamed_Add[0]")?,
            parse_form_float(window.get_f_pls_tamed_add_1(), "PerLevelStatsMultiplier_DinoTamed_Add[1]")?,
            parse_form_float(window.get_f_pls_tamed_add_2(), "PerLevelStatsMultiplier_DinoTamed_Add[2]")?,
            parse_form_float(window.get_f_pls_tamed_add_3(), "PerLevelStatsMultiplier_DinoTamed_Add[3]")?,
            parse_form_float(window.get_f_pls_tamed_add_4(), "PerLevelStatsMultiplier_DinoTamed_Add[4]")?,
            parse_form_float(window.get_f_pls_tamed_add_5(), "PerLevelStatsMultiplier_DinoTamed_Add[5]")?,
            parse_form_float(window.get_f_pls_tamed_add_6(), "PerLevelStatsMultiplier_DinoTamed_Add[6]")?,
            parse_form_float(window.get_f_pls_tamed_add_7(), "PerLevelStatsMultiplier_DinoTamed_Add[7]")?,
            parse_form_float(window.get_f_pls_tamed_add_8(), "PerLevelStatsMultiplier_DinoTamed_Add[8]")?,
            parse_form_float(window.get_f_pls_tamed_add_9(), "PerLevelStatsMultiplier_DinoTamed_Add[9]")?,
            parse_form_float(window.get_f_pls_tamed_add_10(), "PerLevelStatsMultiplier_DinoTamed_Add[10]")?,
            parse_form_float(window.get_f_pls_tamed_add_11(), "PerLevelStatsMultiplier_DinoTamed_Add[11]")?,
        ],
        pls_tamed_affinity: [
            parse_form_float(window.get_f_pls_tamed_affinity_0(), "PerLevelStatsMultiplier_DinoTamed_Affinity[0]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_1(), "PerLevelStatsMultiplier_DinoTamed_Affinity[1]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_2(), "PerLevelStatsMultiplier_DinoTamed_Affinity[2]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_3(), "PerLevelStatsMultiplier_DinoTamed_Affinity[3]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_4(), "PerLevelStatsMultiplier_DinoTamed_Affinity[4]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_5(), "PerLevelStatsMultiplier_DinoTamed_Affinity[5]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_6(), "PerLevelStatsMultiplier_DinoTamed_Affinity[6]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_7(), "PerLevelStatsMultiplier_DinoTamed_Affinity[7]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_8(), "PerLevelStatsMultiplier_DinoTamed_Affinity[8]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_9(), "PerLevelStatsMultiplier_DinoTamed_Affinity[9]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_10(), "PerLevelStatsMultiplier_DinoTamed_Affinity[10]")?,
            parse_form_float(window.get_f_pls_tamed_affinity_11(), "PerLevelStatsMultiplier_DinoTamed_Affinity[11]")?,
        ],
        pls_wild: [
            parse_form_float(window.get_f_pls_wild_0(), "PerLevelStatsMultiplier_DinoWild[0]")?,
            parse_form_float(window.get_f_pls_wild_1(), "PerLevelStatsMultiplier_DinoWild[1]")?,
            parse_form_float(window.get_f_pls_wild_2(), "PerLevelStatsMultiplier_DinoWild[2]")?,
            parse_form_float(window.get_f_pls_wild_3(), "PerLevelStatsMultiplier_DinoWild[3]")?,
            parse_form_float(window.get_f_pls_wild_4(), "PerLevelStatsMultiplier_DinoWild[4]")?,
            parse_form_float(window.get_f_pls_wild_5(), "PerLevelStatsMultiplier_DinoWild[5]")?,
            parse_form_float(window.get_f_pls_wild_6(), "PerLevelStatsMultiplier_DinoWild[6]")?,
            parse_form_float(window.get_f_pls_wild_7(), "PerLevelStatsMultiplier_DinoWild[7]")?,
            parse_form_float(window.get_f_pls_wild_8(), "PerLevelStatsMultiplier_DinoWild[8]")?,
            parse_form_float(window.get_f_pls_wild_9(), "PerLevelStatsMultiplier_DinoWild[9]")?,
            parse_form_float(window.get_f_pls_wild_10(), "PerLevelStatsMultiplier_DinoWild[10]")?,
            parse_form_float(window.get_f_pls_wild_11(), "PerLevelStatsMultiplier_DinoWild[11]")?,
        ],
        pls_base: [
            parse_form_float(window.get_f_pls_base_0(), "PlayerBaseStatMultipliers[0]")?,
            parse_form_float(window.get_f_pls_base_1(), "PlayerBaseStatMultipliers[1]")?,
            parse_form_float(window.get_f_pls_base_2(), "PlayerBaseStatMultipliers[2]")?,
            parse_form_float(window.get_f_pls_base_3(), "PlayerBaseStatMultipliers[3]")?,
            parse_form_float(window.get_f_pls_base_4(), "PlayerBaseStatMultipliers[4]")?,
            parse_form_float(window.get_f_pls_base_5(), "PlayerBaseStatMultipliers[5]")?,
            parse_form_float(window.get_f_pls_base_6(), "PlayerBaseStatMultipliers[6]")?,
            parse_form_float(window.get_f_pls_base_7(), "PlayerBaseStatMultipliers[7]")?,
            parse_form_float(window.get_f_pls_base_8(), "PlayerBaseStatMultipliers[8]")?,
            parse_form_float(window.get_f_pls_base_9(), "PlayerBaseStatMultipliers[9]")?,
            parse_form_float(window.get_f_pls_base_10(), "PlayerBaseStatMultipliers[10]")?,
            parse_form_float(window.get_f_pls_base_11(), "PlayerBaseStatMultipliers[11]")?,
        ],
        dino_harvesting_damage_multiplier: parse_form_float(window.get_f_dino_harvesting_damage_multiplier(), "DinoHarvestingDamageMultiplier")?,
        dino_turret_damage_multiplier: parse_form_float(window.get_f_dino_turret_damage_multiplier(), "DinoTurretDamageMultiplier")?,
        allow_speed_leveling: window.get_b_allow_speed_leveling(),
        allow_flyer_speed_leveling: window.get_b_allow_flyer_speed_leveling(),
        disable_friendly_fire: window.get_b_disable_friendly_fire(),
        pve_disable_friendly_fire: window.get_b_pve_disable_friendly_fire(),
        allow_unlimited_respecs: window.get_b_allow_unlimited_respecs(),
        hard_limit_turrets_in_range: window.get_b_hard_limit_turrets_in_range(),
        limit_turrets_in_range: window.get_b_limit_turrets_in_range(),
        limit_turrets_num: parse_form_int(window.get_f_limit_turrets_num(), "LimitTurretsNum")?,
        limit_turrets_range: parse_form_float(window.get_f_limit_turrets_range(), "LimitTurretsRange")?,
        structure_prevent_resource_radius_multiplier: parse_form_float(window.get_f_structure_prevent_resource_radius_multiplier(), "StructurePreventResourceRadiusMultiplier")?,
        per_platform_max_structures_multiplier: parse_form_float(window.get_f_per_platform_max_structures_multiplier(), "PerPlatformMaxStructuresMultiplier")?,
        always_allow_structure_pickup: window.get_b_always_allow_structure_pickup(),
        structure_pickup_time_after_placement: parse_form_float(window.get_f_structure_pickup_time_after_placement(), "StructurePickupTimeAfterPlacement")?,
        structure_pickup_hold_duration: parse_form_float(window.get_f_structure_pickup_hold_duration(), "StructurePickupHoldDuration")?,
        max_platform_saddle_structure_limit: parse_form_int(window.get_f_max_platform_saddle_structure_limit(), "MaxPlatformSaddleStructureLimit")?,
        enable_cryopod_nerf: window.get_b_enable_cryopod_nerf(),
        cryopod_nerf_damage_mult: parse_form_float(window.get_f_cryopod_nerf_damage_mult(), "CryopodNerfDamageMult")?,
        cryopod_nerf_duration: parse_form_float(window.get_f_cryopod_nerf_duration(), "CryopodNerfDuration")?,
        allow_cryo_fridge_on_saddle: window.get_b_allow_cryo_fridge_on_saddle(),
        disable_cryopod_fridge_requirement: window.get_b_disable_cryopod_fridge_requirement(),
        cryopod_nerf_incoming_damage_mult_percent: parse_form_float(window.get_f_cryopod_nerf_incoming_damage_mult_percent(), "CryopodNerfIncomingDamageMultPercent")?,
        disable_cryopod_enemy_check: window.get_b_disable_cryopod_enemy_check(),
        cryopod_fridge_cooldowntime: parse_form_int(window.get_f_cryopod_fridge_cooldowntime(), "CryopodFridgeCooldowntime")?,
        generic_xp_multiplier: parse_form_float(window.get_f_generic_xp_multiplier(), "GenericXPMultiplier")?,
        harvest_xp_multiplier: parse_form_float(window.get_f_harvest_xp_multiplier(), "HarvestXPMultiplier")?,
        kill_xp_multiplier: parse_form_float(window.get_f_kill_xp_multiplier(), "KillXPMultiplier")?,
        craft_xp_multiplier: parse_form_float(window.get_f_craft_xp_multiplier(), "CraftXPMultiplier")?,
        special_xp_multiplier: parse_form_float(window.get_f_special_xp_multiplier(), "SpecialXPMultiplier")?,
        explorer_note_xp_multiplier: parse_form_float(window.get_f_explorer_note_xp_multiplier(), "ExplorerNoteXPMultiplier")?,
        boss_kill_xp_multiplier: parse_form_float(window.get_f_boss_kill_xp_multiplier(), "BossKillXPMultiplier")?,
        cave_kill_xp_multiplier: parse_form_float(window.get_f_cave_kill_xp_multiplier(), "CaveKillXPMultiplier")?,
        wild_kill_xp_multiplier: parse_form_float(window.get_f_wild_kill_xp_multiplier(), "WildKillXPMultiplier")?,
        tamed_kill_xp_multiplier: parse_form_float(window.get_f_tamed_kill_xp_multiplier(), "TamedKillXPMultiplier")?,
        unclaimed_kill_xp_multiplier: parse_form_float(window.get_f_unclaimed_kill_xp_multiplier(), "UnclaimedKillXPMultiplier")?,
        alpha_kill_xp_multiplier: parse_form_float(window.get_f_alpha_kill_xp_multiplier(), "AlphaKillXPMultiplier")?,
        override_max_experience_points_player: parse_form_int(window.get_f_override_max_experience_points_player(), "OverrideMaxExperiencePointsPlayer")?,
        override_max_experience_points_dino: parse_form_int(window.get_f_override_max_experience_points_dino(), "OverrideMaxExperiencePointsDino")?,
        global_voice_chat: window.get_b_global_voice_chat(),
        proximity_chat: window.get_b_proximity_chat(),
        dont_always_notify_player_joined: window.get_b_dont_always_notify_player_joined(),
        always_notify_player_left: window.get_b_always_notify_player_left(),
        admin_logging: window.get_b_admin_logging(),
        allow_hide_damage_source_from_logs: window.get_b_allow_hide_damage_source_from_logs(),
        show_floating_damage_text: window.get_b_show_floating_damage_text(),
        show_map_player_location: window.get_b_show_map_player_location(),
        server_crosshair: window.get_b_server_crosshair(),
        server_force_no_hud: window.get_b_server_force_no_hud(),
        allow_third_person_player: window.get_b_allow_third_person_player(),
        allow_hit_markers: window.get_b_allow_hit_markers(),
        disable_pve_gamma: window.get_b_disable_pve_gamma(),
        enable_pvp_gamma: window.get_b_enable_pvp_gamma(),
        server_password: window.get_f_server_password().as_str().to_string(),
        ban_list_url: window.get_f_ban_list_url().as_str().to_string(),
        admin_list_url: window.get_f_admin_list_url().as_str().to_string(),
        bad_word_list_url: window.get_f_bad_word_list_url().as_str().to_string(),
        bad_word_white_list_url: window.get_f_bad_word_white_list_url().as_str().to_string(),
        custom_live_tuning_url: window.get_f_custom_live_tuning_url().as_str().to_string(),
        no_tribute_downloads: window.get_b_no_tribute_downloads(),
        prevent_download_dinos: window.get_b_prevent_download_dinos(),
        prevent_download_items: window.get_b_prevent_download_items(),
        prevent_download_survivors: window.get_b_prevent_download_survivors(),
        prevent_upload_dinos: window.get_b_prevent_upload_dinos(),
        prevent_upload_items: window.get_b_prevent_upload_items(),
        prevent_upload_survivors: window.get_b_prevent_upload_survivors(),
        cross_ark_allow_foreign_dino_downloads: window.get_b_cross_ark_allow_foreign_dino_downloads(),
        prevent_tribe_alliances: window.get_b_prevent_tribe_alliances(),
        max_number_of_players_in_tribe: parse_form_int(window.get_f_max_number_of_players_in_tribe(), "MaxNumberOfPlayersInTribe")?,
        max_blueprint_dino_level: parse_form_int(window.get_f_max_blueprint_dino_level(), "MaxBlueprintDinoLevel")?,
        max_blueprint_dino_quality: parse_form_int(window.get_f_max_blueprint_dino_quality(), "MaxBlueprintDinoQuality")?,
        max_blueprint_item_quality: parse_form_int(window.get_f_max_blueprint_item_quality(), "MaxBlueprintItemQuality")?,
        max_blueprint_scout_quality: parse_form_int(window.get_f_max_blueprint_scout_quality(), "MaxBlueprintScoutQuality")?,
        max_hexagons_per_character: parse_form_int(window.get_f_max_hexagons_per_character(), "MaxHexagonsPerCharacter")?,
        clamp_item_spoiling_times: window.get_b_clamp_item_spoiling_times(),
        clamp_item_stats: window.get_b_clamp_item_stats(),
        clamp_resource_harvest_damage: window.get_b_clamp_resource_harvest_damage(),
        implant_suicide_cd: parse_form_int(window.get_f_implant_suicide_cd(), "ImplantSuicideCD")?,
        server_auto_force_respawn_wild_dinos_interval: parse_form_float(window.get_f_server_auto_force_respawn_wild_dinos_interval(), "ServerAutoForceRespawnWildDinosInterval")?,
        destroy_tames_over_level_clamp: parse_form_int(window.get_f_destroy_tames_over_level_clamp(), "DestroyTamesOverLevelClamp")?,
        fast_decay_unsnapped_core_structures: window.get_b_fast_decay_unsnapped_core_structures(),
        override_structure_platform_prevention: window.get_b_override_structure_platform_prevention(),
        prevent_offline_pvp: window.get_b_prevent_offline_pvp(),
        prevent_offline_pvp_interval: parse_form_float(window.get_f_prevent_offline_pvp_interval(), "PreventOfflinePvPInterval")?,
        pvp_dino_decay: window.get_b_pvp_dino_decay(),
        pvp_structure_decay: window.get_b_pvp_structure_decay(),
        pve_dino_decay_period_multiplier: parse_form_float(window.get_f_pve_dino_decay_period_multiplier(), "PvEDinoDecayPeriodMultiplier")?,
        only_auto_destroy_core_structures: window.get_b_only_auto_destroy_core_structures(),
        auto_destroy_decayed_dinos: window.get_b_auto_destroy_decayed_dinos(),
        tribe_log_destroyed_enemy_structures: window.get_b_tribe_log_destroyed_enemy_structures(),
        pve_allow_structures_at_supply_drops: window.get_b_pve_allow_structures_at_supply_drops(),
        oxygen_swim_speed_stat_multiplier: parse_form_float(window.get_f_oxygen_swim_speed_stat_multiplier(), "OxygenSwimSpeedStatMultiplier")?,
        tribe_name_change_cooldown: parse_form_float(window.get_f_tribe_name_change_cooldown(), "TribeNameChangeCooldown")?,
        platform_saddle_build_area_bounds_multiplier: parse_form_float(window.get_f_platform_saddle_build_area_bounds_multiplier(), "PlatformSaddleBuildAreaBoundsMultiplier")?,
        raid_dino_character_food_drain_multiplier: parse_form_float(window.get_f_raid_dino_character_food_drain_multiplier(), "RaidDinoCharacterFoodDrainMultiplier")?,
        item_stack_size_multiplier: parse_form_float(window.get_f_item_stack_size_multiplier(), "ItemStackSizeMultiplier")?,
        start_time_hour: parse_form_float(window.get_f_start_time_hour(), "StartTimeHour")?,
        rcon_server_game_log_buffer: parse_form_int(window.get_f_rcon_server_game_log_buffer(), "RCONServerGameLogBuffer")?,
        allow_raid_dino_feeding: window.get_b_allow_raid_dino_feeding(),
        enable_extra_structure_prevention_volumes: window.get_b_enable_extra_structure_prevention_volumes(),
        prevent_spawn_animations: window.get_b_prevent_spawn_animations(),
        prevent_diseases: window.get_b_prevent_diseases(),
        non_permanent_diseases: window.get_b_non_permanent_diseases(),
        use_optimized_harvesting_health: window.get_b_use_optimized_harvesting_health(),
        allow_multiple_attached_c4: window.get_b_allow_multiple_attached_c4(),
        allow_flying_stamina_recovery: window.get_b_allow_flying_stamina_recovery(),
        allow_crate_spawns_on_top_of_structures: window.get_b_allow_crate_spawns_on_top_of_structures(),
        motd_message: window.get_f_motd_message().as_str().to_string(),
        motd_duration: parse_form_int(window.get_f_motd_duration(), "MessageOfTheDay/Duration")?,
        launch_flags: window.get_f_launch_flags().as_str().to_string(),
        // Mods textarea is whitespace-or-comma separated. Normalise to a
        // single CSV form so parse_mods_csv can use its existing splitter.
        mods: launch_args::parse_mods_csv(
            &window.get_f_mods_csv().as_str().replace(['\n', ' ', '\t'], ","),
        ),
    })
}

/// Apply parsed form values to the install root's two INIs, preserving every
/// other key that already lived there. Phase 8b corrected the routing:
/// the bulk of multipliers now save to GameUserSettings.ini [ServerSettings].
///
/// `profile_path` is also rewritten when `Some` so the Launch flags tab
/// (Phase 8k) survives the round trip.
fn write_world_form(
    install_root: &Path,
    v: &WorldFormValues,
    profile_path: Option<&Path>,
) -> Result<()> {
    let mut game = game_config::GameSettings::load_or_empty(
        game_config::game_ini_path(install_root),
    )?;
    let mut gus = ark_config::GameUserSettings::load_or_empty(
        ark_config::game_user_settings_path(install_root),
    )?;

    // Game.ini-only fields
    game.set_mating_interval_multiplier(v.mating_interval_multiplier);
    game.set_egg_hatch_speed_multiplier(v.egg_hatch_speed_multiplier);
    game.set_baby_mature_speed_multiplier(v.baby_mature_speed_multiplier);
    game.set_player_harvesting_damage_multiplier(v.player_harvesting);
    game.set_wild_dino_food_drain_multiplier(v.wild_food);
    game.set_wild_dino_torpor_drain_multiplier(v.wild_torpor);
    game.set_structure_damage_repair_cooldown(v.structure_repair_cooldown);
    game.set_disable_imprint_dino_buff(v.disable_imprint_dino_buff);
    game.set_allow_anyone_baby_imprint_cuddle(v.allow_anyone_baby_imprint);

    // Rates → GUS
    gus.set_xp_multiplier(v.xp_multiplier);
    gus.set_harvest_amount_multiplier(v.harvest_amount_multiplier);
    gus.set_harvest_health_multiplier(v.harvest_health_multiplier);
    gus.set_resources_respawn_period_multiplier(v.resources_respawn_period_multiplier);
    gus.set_taming_speed_multiplier(v.taming_speed_multiplier);

    // Day cycle → GUS
    gus.set_day_cycle_speed_scale(v.day_cycle_speed_scale);
    gus.set_day_time_speed_scale(v.day_time_speed_scale);
    gus.set_night_time_speed_scale(v.night_time_speed_scale);

    // Player → GUS (harvesting stays in Game.ini above)
    gus.set_player_food_drain_multiplier(v.player_food);
    gus.set_player_water_drain_multiplier(v.player_water);
    gus.set_player_stamina_drain_multiplier(v.player_stamina);
    gus.set_player_health_recovery_multiplier(v.player_health_recovery);
    gus.set_player_damage_multiplier(v.player_damage);
    gus.set_player_resistance_multiplier(v.player_resistance);

    // Tamed dino → GUS
    gus.set_dino_food_drain_multiplier(v.dino_food);
    gus.set_dino_stamina_drain_multiplier(v.dino_stamina);
    gus.set_dino_health_recovery_multiplier(v.dino_health_recovery);
    gus.set_tamed_dino_damage_multiplier(v.tamed_damage);
    gus.set_tamed_dino_resistance_multiplier(v.tamed_resistance);

    // Wild dino → mostly Game.ini above; stamina + count → GUS
    gus.set_wild_dino_stamina_drain_multiplier(v.wild_stamina);
    gus.set_dino_count_multiplier(v.dino_count);

    // Structures → GUS (repair cooldown is Game.ini above)
    gus.set_structure_damage_multiplier(v.structure_damage);
    gus.set_structure_resistance_multiplier(v.structure_resistance);

    // Difficulty → GUS
    gus.set_difficulty_offset(v.difficulty_offset);
    gus.set_override_official_difficulty(v.override_official_difficulty);

    // Phase 8b — PvE/PvP toggles → GUS
    gus.set_server_pve(v.server_pve);
    gus.set_allow_flyer_carry_pve(v.allow_flyer_carry_pve);
    gus.set_enable_cryo_sickness_pve(v.enable_cryo_sickness_pve);
    gus.set_disable_structure_decay_pve(v.disable_structure_decay_pve);

    // Phase 8b — Operations basics → GUS
    gus.set_max_tamed_dinos(v.max_tamed_dinos);
    gus.set_kick_idle_players_period(v.kick_idle_players_period);
    gus.set_auto_save_period_minutes(v.auto_save_period_minutes);
    gus.set_the_max_structures_in_range(v.the_max_structures_in_range);

    // Phase 8c — Breeding / Imprint → Game.ini
    game.set_mating_speed_multiplier(v.mating_speed_multiplier);
    game.set_lay_egg_interval_multiplier(v.lay_egg_interval_multiplier);
    game.set_passive_tame_interval_multiplier(v.passive_tame_interval_multiplier);
    game.set_baby_food_consumption_speed_multiplier(v.baby_food_consumption_speed_multiplier);
    game.set_baby_imprint_amount_multiplier(v.baby_imprint_amount_multiplier);
    game.set_baby_imprinting_stat_scale_multiplier(v.baby_imprinting_stat_scale_multiplier);
    game.set_baby_cuddle_interval_multiplier(v.baby_cuddle_interval_multiplier);
    game.set_baby_cuddle_grace_period_multiplier(v.baby_cuddle_grace_period_multiplier);
    game.set_baby_cuddle_lose_imprint_quality_speed_multiplier(v.baby_cuddle_lose_imprint_quality_speed_multiplier);
    game.set_disable_dino_breeding(v.disable_dino_breeding);
    game.set_disable_dino_taming(v.disable_dino_taming);

    // Phase 8d — Loot / Spoilage → Game.ini
    game.set_supply_crate_loot_quality_multiplier(v.supply_crate_loot_quality_multiplier);
    game.set_fishing_loot_quality_multiplier(v.fishing_loot_quality_multiplier);
    game.set_crop_growth_speed_multiplier(v.crop_growth_speed_multiplier);
    game.set_crop_decay_speed_multiplier(v.crop_decay_speed_multiplier);
    game.set_disable_loot_crates(v.disable_loot_crates);
    game.set_limit_non_player_dropped_items_count(v.limit_non_player_dropped_items_count);
    game.set_limit_non_player_dropped_items_range(v.limit_non_player_dropped_items_range);
    game.set_global_spoiling_time_multiplier(v.global_spoiling_time_multiplier);
    game.set_global_item_decomposition_time_multiplier(v.global_item_decomposition_time_multiplier);
    game.set_global_corpse_decomposition_time_multiplier(v.global_corpse_decomposition_time_multiplier);
    game.set_use_corpse_life_span_multiplier(v.use_corpse_life_span_multiplier);
    game.set_use_corpse_locator(v.use_corpse_locator);
    game.set_poop_interval_multiplier(v.poop_interval_multiplier);
    game.set_fuel_consumption_interval_multiplier(v.fuel_consumption_interval_multiplier);
    game.set_max_fall_speed_multiplier(v.max_fall_speed_multiplier);

    // Phase 8e — Stat arrays → Game.ini
    for i in 0..12 {
        game.set_per_level_stats_multiplier_player(i as u8, v.pls_player[i]);
        game.set_per_level_stats_multiplier_dino_tamed(i as u8, v.pls_tamed[i]);
        game.set_per_level_stats_multiplier_dino_tamed_add(i as u8, v.pls_tamed_add[i]);
        game.set_per_level_stats_multiplier_dino_tamed_affinity(i as u8, v.pls_tamed_affinity[i]);
        game.set_per_level_stats_multiplier_dino_wild(i as u8, v.pls_wild[i]);
        game.set_player_base_stat_multipliers(i as u8, v.pls_base[i]);
    }

    // Phase 8f — Combat / Structures
    game.set_dino_harvesting_damage_multiplier(v.dino_harvesting_damage_multiplier);
    game.set_dino_turret_damage_multiplier(v.dino_turret_damage_multiplier);
    game.set_allow_speed_leveling(v.allow_speed_leveling);
    game.set_allow_flyer_speed_leveling(v.allow_flyer_speed_leveling);
    game.set_disable_friendly_fire(v.disable_friendly_fire);
    game.set_pve_disable_friendly_fire(v.pve_disable_friendly_fire);
    game.set_allow_unlimited_respecs(v.allow_unlimited_respecs);
    game.set_hard_limit_turrets_in_range(v.hard_limit_turrets_in_range);
    game.set_limit_turrets_in_range(v.limit_turrets_in_range);
    game.set_limit_turrets_num(v.limit_turrets_num);
    game.set_limit_turrets_range(v.limit_turrets_range);
    gus.set_structure_prevent_resource_radius_multiplier(v.structure_prevent_resource_radius_multiplier);
    gus.set_per_platform_max_structures_multiplier(v.per_platform_max_structures_multiplier);
    gus.set_always_allow_structure_pickup(v.always_allow_structure_pickup);
    gus.set_structure_pickup_time_after_placement(v.structure_pickup_time_after_placement);
    gus.set_structure_pickup_hold_duration(v.structure_pickup_hold_duration);
    gus.set_max_platform_saddle_structure_limit(v.max_platform_saddle_structure_limit);
    gus.set_enable_cryopod_nerf(v.enable_cryopod_nerf);
    gus.set_cryopod_nerf_damage_mult(v.cryopod_nerf_damage_mult);
    gus.set_cryopod_nerf_duration(v.cryopod_nerf_duration);
    gus.set_allow_cryo_fridge_on_saddle(v.allow_cryo_fridge_on_saddle);
    gus.set_disable_cryopod_fridge_requirement(v.disable_cryopod_fridge_requirement);
    gus.set_cryopod_nerf_incoming_damage_mult_percent(v.cryopod_nerf_incoming_damage_mult_percent);
    gus.set_disable_cryopod_enemy_check(v.disable_cryopod_enemy_check);
    gus.set_cryopod_fridge_cooldowntime(v.cryopod_fridge_cooldowntime);

    // Phase 8g — XP gain breakdown → Game.ini
    game.set_generic_xp_multiplier(v.generic_xp_multiplier);
    game.set_harvest_xp_multiplier(v.harvest_xp_multiplier);
    game.set_kill_xp_multiplier(v.kill_xp_multiplier);
    game.set_craft_xp_multiplier(v.craft_xp_multiplier);
    game.set_special_xp_multiplier(v.special_xp_multiplier);
    game.set_explorer_note_xp_multiplier(v.explorer_note_xp_multiplier);
    game.set_boss_kill_xp_multiplier(v.boss_kill_xp_multiplier);
    game.set_cave_kill_xp_multiplier(v.cave_kill_xp_multiplier);
    game.set_wild_kill_xp_multiplier(v.wild_kill_xp_multiplier);
    game.set_tamed_kill_xp_multiplier(v.tamed_kill_xp_multiplier);
    game.set_unclaimed_kill_xp_multiplier(v.unclaimed_kill_xp_multiplier);
    game.set_alpha_kill_xp_multiplier(v.alpha_kill_xp_multiplier);
    game.set_override_max_experience_points_player(v.override_max_experience_points_player);
    game.set_override_max_experience_points_dino(v.override_max_experience_points_dino);

    // Phase 8h — Cosmetic / Chat → GUS
    gus.set_global_voice_chat(v.global_voice_chat);
    gus.set_proximity_chat(v.proximity_chat);
    gus.set_dont_always_notify_player_joined(v.dont_always_notify_player_joined);
    gus.set_always_notify_player_left(v.always_notify_player_left);
    gus.set_admin_logging(v.admin_logging);
    gus.set_allow_hide_damage_source_from_logs(v.allow_hide_damage_source_from_logs);
    gus.set_show_floating_damage_text(v.show_floating_damage_text);
    gus.set_show_map_player_location(v.show_map_player_location);
    gus.set_server_crosshair(v.server_crosshair);
    gus.set_server_force_no_hud(v.server_force_no_hud);
    gus.set_allow_third_person_player(v.allow_third_person_player);
    gus.set_allow_hit_markers(v.allow_hit_markers);
    gus.set_disable_pve_gamma(v.disable_pve_gamma);
    gus.set_enable_pvp_gamma(v.enable_pvp_gamma);

    // Phase 8i — Cluster / Lists → GUS
    gus.set_server_password(&v.server_password);
    gus.set_ban_list_url(&v.ban_list_url);
    gus.set_admin_list_url(&v.admin_list_url);
    gus.set_bad_word_list_url(&v.bad_word_list_url);
    gus.set_bad_word_white_list_url(&v.bad_word_white_list_url);
    gus.set_custom_live_tuning_url(&v.custom_live_tuning_url);
    gus.set_no_tribute_downloads(v.no_tribute_downloads);
    gus.set_prevent_download_dinos(v.prevent_download_dinos);
    gus.set_prevent_download_items(v.prevent_download_items);
    gus.set_prevent_download_survivors(v.prevent_download_survivors);
    gus.set_prevent_upload_dinos(v.prevent_upload_dinos);
    gus.set_prevent_upload_items(v.prevent_upload_items);
    gus.set_prevent_upload_survivors(v.prevent_upload_survivors);
    gus.set_cross_ark_allow_foreign_dino_downloads(v.cross_ark_allow_foreign_dino_downloads);
    gus.set_prevent_tribe_alliances(v.prevent_tribe_alliances);
    gus.set_max_number_of_players_in_tribe(v.max_number_of_players_in_tribe);

    // Phase 8j — Stat clamps / Blueprint caps
    gus.set_max_blueprint_dino_level(v.max_blueprint_dino_level);
    gus.set_max_blueprint_dino_quality(v.max_blueprint_dino_quality);
    gus.set_max_blueprint_item_quality(v.max_blueprint_item_quality);
    gus.set_max_blueprint_scout_quality(v.max_blueprint_scout_quality);
    gus.set_max_hexagons_per_character(v.max_hexagons_per_character);
    gus.set_clamp_item_spoiling_times(v.clamp_item_spoiling_times);
    gus.set_clamp_item_stats(v.clamp_item_stats);
    gus.set_clamp_resource_harvest_damage(v.clamp_resource_harvest_damage);
    gus.set_implant_suicide_cd(v.implant_suicide_cd);
    gus.set_server_auto_force_respawn_wild_dinos_interval(v.server_auto_force_respawn_wild_dinos_interval);
    game.set_destroy_tames_over_level_clamp(v.destroy_tames_over_level_clamp);

    // Phase 8L — extra GameUserSettings.ini knobs
    gus.set_fast_decay_unsnapped_core_structures(v.fast_decay_unsnapped_core_structures);
    gus.set_override_structure_platform_prevention(v.override_structure_platform_prevention);
    gus.set_prevent_offline_pvp(v.prevent_offline_pvp);
    gus.set_prevent_offline_pvp_interval(v.prevent_offline_pvp_interval);
    gus.set_pvp_dino_decay(v.pvp_dino_decay);
    gus.set_pvp_structure_decay(v.pvp_structure_decay);
    gus.set_pve_dino_decay_period_multiplier(v.pve_dino_decay_period_multiplier);
    gus.set_only_auto_destroy_core_structures(v.only_auto_destroy_core_structures);
    gus.set_auto_destroy_decayed_dinos(v.auto_destroy_decayed_dinos);
    gus.set_tribe_log_destroyed_enemy_structures(v.tribe_log_destroyed_enemy_structures);
    gus.set_pve_allow_structures_at_supply_drops(v.pve_allow_structures_at_supply_drops);
    gus.set_oxygen_swim_speed_stat_multiplier(v.oxygen_swim_speed_stat_multiplier);
    gus.set_tribe_name_change_cooldown(v.tribe_name_change_cooldown);
    gus.set_platform_saddle_build_area_bounds_multiplier(v.platform_saddle_build_area_bounds_multiplier);
    gus.set_raid_dino_character_food_drain_multiplier(v.raid_dino_character_food_drain_multiplier);
    gus.set_item_stack_size_multiplier(v.item_stack_size_multiplier);
    gus.set_start_time_hour(v.start_time_hour);
    gus.set_rcon_server_game_log_buffer(v.rcon_server_game_log_buffer);
    gus.set_allow_raid_dino_feeding(v.allow_raid_dino_feeding);
    gus.set_enable_extra_structure_prevention_volumes(v.enable_extra_structure_prevention_volumes);
    gus.set_prevent_spawn_animations(v.prevent_spawn_animations);
    gus.set_prevent_diseases(v.prevent_diseases);
    gus.set_non_permanent_diseases(v.non_permanent_diseases);
    gus.set_use_optimized_harvesting_health(v.use_optimized_harvesting_health);
    gus.set_allow_multiple_attached_c4(v.allow_multiple_attached_c4);
    gus.set_allow_flying_stamina_recovery(v.allow_flying_stamina_recovery);
    gus.set_allow_crate_spawns_on_top_of_structures(v.allow_crate_spawns_on_top_of_structures);

    // Phase 8P — MOTD
    gus.set_motd_message(&v.motd_message);
    gus.set_motd_duration(v.motd_duration);

    // Phase 8S — strip Phase-8M-era misrouted breeding/loot keys from
    // GUS [ServerSettings] so a stale entry doesn't compete with the
    // canonical Game.ini value the engine actually reads.
    gus.cleanup_legacy_breeding_loot_keys();

    game.save()?;
    gus.save()?;

    // Phase 8k + 8R — Launch flags + Mods → Profile MM_Command_Val.
    // Both modify different parts of the same string, so we apply mods
    // first (they live in the URL/head portion of the line) and then
    // re-splice the flag portion.
    if let Some(pp) = profile_path {
        if let Ok(mut profile) = Profile::load(pp) {
            let current = profile.server_command_line().unwrap_or_default();
            let with_mods = launch_args::replace_mods_in_command_line(&current, &v.mods);
            let (head, _old_flags) = launch_args::split_command_line(&with_mods);
            let new_flags: Vec<String> = launch_args::parse_extra_flags(&v.launch_flags);
            let rebuilt = launch_args::join_command_line(&head, &new_flags);
            profile.set_server_command_line(&rebuilt);
            profile.save()?;
            let _ = pp; // path is captured by Profile::load above
        }
    }

    Ok(())
}

/// Overlay every recognised key from `source_path` onto the form, leaving
/// fields untouched when the source has no value for them.
fn import_world_settings(window: &WorldSettingsWindow, source_path: &Path) -> Result<()> {
    // The same file may declare both sections (rare, but possible) or only
    // one — try both wrappers so a Game.ini, a GameUserSettings.ini, or a
    // user-merged INI all import cleanly.
    let game = game_config::GameSettings::load_or_empty(source_path)?;
    let gus = ark_config::GameUserSettings::load_or_empty(source_path)?;

    let g = |get: fn(&game_config::GameSettings) -> Option<f64>| get(&game);
    let gb = |get: fn(&game_config::GameSettings) -> Option<bool>| get(&game);
    let u = |get: fn(&ark_config::GameUserSettings) -> Option<f64>| get(&gus);
    let ub = |get: fn(&ark_config::GameUserSettings) -> Option<bool>| get(&gus);
    let ui_ = |get: fn(&ark_config::GameUserSettings) -> Option<i64>| get(&gus);

    // Rates → GUS
    if let Some(v) = u(ark_config::GameUserSettings::xp_multiplier) {
        window.set_f_xp_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::harvest_amount_multiplier) {
        window.set_f_harvest_amount_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::harvest_health_multiplier) {
        window.set_f_harvest_health_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::resources_respawn_period_multiplier) {
        window.set_f_resources_respawn_period_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::taming_speed_multiplier) {
        window.set_f_taming_speed_multiplier(fmt_float_for_form(v));
    }
    // Breeding → Game.ini
    if let Some(v) = g(game_config::GameSettings::mating_interval_multiplier) {
        window.set_f_mating_interval_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::egg_hatch_speed_multiplier) {
        window.set_f_egg_hatch_speed_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::baby_mature_speed_multiplier) {
        window.set_f_baby_mature_speed_multiplier(fmt_float_for_form(v));
    }
    // Day cycle → GUS
    if let Some(v) = u(ark_config::GameUserSettings::day_cycle_speed_scale) {
        window.set_f_day_cycle_speed_scale(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::day_time_speed_scale) {
        window.set_f_day_time_speed_scale(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::night_time_speed_scale) {
        window.set_f_night_time_speed_scale(fmt_float_for_form(v));
    }
    // Player → GUS (harvesting → Game.ini)
    if let Some(v) = u(ark_config::GameUserSettings::player_food_drain_multiplier) {
        window.set_f_player_food(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::player_water_drain_multiplier) {
        window.set_f_player_water(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::player_stamina_drain_multiplier) {
        window.set_f_player_stamina(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::player_health_recovery_multiplier) {
        window.set_f_player_health_recovery(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::player_damage_multiplier) {
        window.set_f_player_damage(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::player_resistance_multiplier) {
        window.set_f_player_resistance(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::player_harvesting_damage_multiplier) {
        window.set_f_player_harvesting(fmt_float_for_form(v));
    }
    // Tamed dino → GUS
    if let Some(v) = u(ark_config::GameUserSettings::dino_food_drain_multiplier) {
        window.set_f_dino_food(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::dino_stamina_drain_multiplier) {
        window.set_f_dino_stamina(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::dino_health_recovery_multiplier) {
        window.set_f_dino_health_recovery(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::tamed_dino_damage_multiplier) {
        window.set_f_tamed_damage(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::tamed_dino_resistance_multiplier) {
        window.set_f_tamed_resistance(fmt_float_for_form(v));
    }
    // Wild dino — food/torpor (G), stamina (U), count (U)
    if let Some(v) = g(game_config::GameSettings::wild_dino_food_drain_multiplier) {
        window.set_f_wild_food(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::wild_dino_stamina_drain_multiplier) {
        window.set_f_wild_stamina(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::wild_dino_torpor_drain_multiplier) {
        window.set_f_wild_torpor(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::dino_count_multiplier) {
        window.set_f_dino_count(fmt_float_for_form(v));
    }
    // Structures
    if let Some(v) = u(ark_config::GameUserSettings::structure_damage_multiplier) {
        window.set_f_structure_damage(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::structure_resistance_multiplier) {
        window.set_f_structure_resistance(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::structure_damage_repair_cooldown) {
        window.set_f_structure_repair_cooldown(fmt_float_for_form(v));
    }
    if let Some(v) = gb(game_config::GameSettings::disable_imprint_dino_buff) {
        window.set_b_disable_imprint_dino_buff(v);
    }
    if let Some(v) = gb(game_config::GameSettings::allow_anyone_baby_imprint_cuddle) {
        window.set_b_allow_anyone_baby_imprint(v);
    }
    // Difficulty → GUS
    if let Some(v) = u(ark_config::GameUserSettings::difficulty_offset) {
        window.set_f_difficulty_offset(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::override_official_difficulty) {
        window.set_f_override_official_difficulty(fmt_float_for_form(v));
    }
    // Phase 8b — PvE/PvP
    if let Some(v) = ub(ark_config::GameUserSettings::server_pve) {
        window.set_b_server_pve(v);
    }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_flyer_carry_pve) {
        window.set_b_allow_flyer_carry_pve(v);
    }
    if let Some(v) = ub(ark_config::GameUserSettings::enable_cryo_sickness_pve) {
        window.set_b_enable_cryo_sickness_pve(v);
    }
    if let Some(v) = ub(ark_config::GameUserSettings::disable_structure_decay_pve) {
        window.set_b_disable_structure_decay_pve(v);
    }
    // Phase 8b — Operations basics
    if let Some(v) = u(ark_config::GameUserSettings::max_tamed_dinos) {
        window.set_f_max_tamed_dinos(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::kick_idle_players_period) {
        window.set_f_kick_idle_players_period(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::auto_save_period_minutes) {
        window.set_f_auto_save_period_minutes(fmt_float_for_form(v));
    }
    if let Some(v) = ui_(ark_config::GameUserSettings::the_max_structures_in_range) {
        window.set_f_the_max_structures_in_range(fmt_int_for_form(v));
    }
    // Phase 8c — Breeding / Imprint
    if let Some(v) = g(game_config::GameSettings::mating_speed_multiplier) {
        window.set_f_mating_speed_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::lay_egg_interval_multiplier) {
        window.set_f_lay_egg_interval_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::passive_tame_interval_multiplier) {
        window.set_f_passive_tame_interval_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::baby_food_consumption_speed_multiplier) {
        window.set_f_baby_food_consumption_speed_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::baby_imprint_amount_multiplier) {
        window.set_f_baby_imprint_amount_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::baby_imprinting_stat_scale_multiplier) {
        window.set_f_baby_imprinting_stat_scale_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::baby_cuddle_interval_multiplier) {
        window.set_f_baby_cuddle_interval_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::baby_cuddle_grace_period_multiplier) {
        window.set_f_baby_cuddle_grace_period_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::baby_cuddle_lose_imprint_quality_speed_multiplier) {
        window.set_f_baby_cuddle_lose_imprint_quality_speed_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = gb(game_config::GameSettings::disable_dino_breeding) {
        window.set_b_disable_dino_breeding(v);
    }
    if let Some(v) = gb(game_config::GameSettings::disable_dino_taming) {
        window.set_b_disable_dino_taming(v);
    }
    // Phase 8d — Loot / Spoilage
    let gi = |get: fn(&game_config::GameSettings) -> Option<i64>| get(&game);
    if let Some(v) = g(game_config::GameSettings::supply_crate_loot_quality_multiplier) {
        window.set_f_supply_crate_loot_quality_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::fishing_loot_quality_multiplier) {
        window.set_f_fishing_loot_quality_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::crop_growth_speed_multiplier) {
        window.set_f_crop_growth_speed_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::crop_decay_speed_multiplier) {
        window.set_f_crop_decay_speed_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = gb(game_config::GameSettings::disable_loot_crates) {
        window.set_b_disable_loot_crates(v);
    }
    if let Some(v) = gi(game_config::GameSettings::limit_non_player_dropped_items_count) {
        window.set_f_limit_non_player_dropped_items_count(fmt_int_for_form(v));
    }
    if let Some(v) = gi(game_config::GameSettings::limit_non_player_dropped_items_range) {
        window.set_f_limit_non_player_dropped_items_range(fmt_int_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::global_spoiling_time_multiplier) {
        window.set_f_global_spoiling_time_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::global_item_decomposition_time_multiplier) {
        window.set_f_global_item_decomposition_time_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::global_corpse_decomposition_time_multiplier) {
        window.set_f_global_corpse_decomposition_time_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::use_corpse_life_span_multiplier) {
        window.set_f_use_corpse_life_span_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = gb(game_config::GameSettings::use_corpse_locator) {
        window.set_b_use_corpse_locator(v);
    }
    if let Some(v) = g(game_config::GameSettings::poop_interval_multiplier) {
        window.set_f_poop_interval_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::fuel_consumption_interval_multiplier) {
        window.set_f_fuel_consumption_interval_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::max_fall_speed_multiplier) {
        window.set_f_max_fall_speed_multiplier(fmt_float_for_form(v));
    }
    // Phase 8e — Stat arrays
    if let Some(x) = game.per_level_stats_multiplier_player(0) { window.set_f_pls_player_0(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(1) { window.set_f_pls_player_1(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(2) { window.set_f_pls_player_2(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(3) { window.set_f_pls_player_3(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(4) { window.set_f_pls_player_4(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(5) { window.set_f_pls_player_5(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(6) { window.set_f_pls_player_6(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(7) { window.set_f_pls_player_7(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(8) { window.set_f_pls_player_8(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(9) { window.set_f_pls_player_9(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(10) { window.set_f_pls_player_10(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_player(11) { window.set_f_pls_player_11(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(0) { window.set_f_pls_tamed_0(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(1) { window.set_f_pls_tamed_1(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(2) { window.set_f_pls_tamed_2(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(3) { window.set_f_pls_tamed_3(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(4) { window.set_f_pls_tamed_4(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(5) { window.set_f_pls_tamed_5(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(6) { window.set_f_pls_tamed_6(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(7) { window.set_f_pls_tamed_7(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(8) { window.set_f_pls_tamed_8(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(9) { window.set_f_pls_tamed_9(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(10) { window.set_f_pls_tamed_10(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed(11) { window.set_f_pls_tamed_11(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(0) { window.set_f_pls_tamed_add_0(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(1) { window.set_f_pls_tamed_add_1(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(2) { window.set_f_pls_tamed_add_2(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(3) { window.set_f_pls_tamed_add_3(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(4) { window.set_f_pls_tamed_add_4(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(5) { window.set_f_pls_tamed_add_5(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(6) { window.set_f_pls_tamed_add_6(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(7) { window.set_f_pls_tamed_add_7(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(8) { window.set_f_pls_tamed_add_8(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(9) { window.set_f_pls_tamed_add_9(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(10) { window.set_f_pls_tamed_add_10(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_add(11) { window.set_f_pls_tamed_add_11(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(0) { window.set_f_pls_tamed_affinity_0(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(1) { window.set_f_pls_tamed_affinity_1(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(2) { window.set_f_pls_tamed_affinity_2(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(3) { window.set_f_pls_tamed_affinity_3(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(4) { window.set_f_pls_tamed_affinity_4(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(5) { window.set_f_pls_tamed_affinity_5(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(6) { window.set_f_pls_tamed_affinity_6(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(7) { window.set_f_pls_tamed_affinity_7(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(8) { window.set_f_pls_tamed_affinity_8(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(9) { window.set_f_pls_tamed_affinity_9(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(10) { window.set_f_pls_tamed_affinity_10(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_tamed_affinity(11) { window.set_f_pls_tamed_affinity_11(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(0) { window.set_f_pls_wild_0(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(1) { window.set_f_pls_wild_1(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(2) { window.set_f_pls_wild_2(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(3) { window.set_f_pls_wild_3(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(4) { window.set_f_pls_wild_4(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(5) { window.set_f_pls_wild_5(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(6) { window.set_f_pls_wild_6(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(7) { window.set_f_pls_wild_7(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(8) { window.set_f_pls_wild_8(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(9) { window.set_f_pls_wild_9(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(10) { window.set_f_pls_wild_10(fmt_float_for_form(x)); }
    if let Some(x) = game.per_level_stats_multiplier_dino_wild(11) { window.set_f_pls_wild_11(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(0) { window.set_f_pls_base_0(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(1) { window.set_f_pls_base_1(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(2) { window.set_f_pls_base_2(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(3) { window.set_f_pls_base_3(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(4) { window.set_f_pls_base_4(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(5) { window.set_f_pls_base_5(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(6) { window.set_f_pls_base_6(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(7) { window.set_f_pls_base_7(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(8) { window.set_f_pls_base_8(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(9) { window.set_f_pls_base_9(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(10) { window.set_f_pls_base_10(fmt_float_for_form(x)); }
    if let Some(x) = game.player_base_stat_multipliers(11) { window.set_f_pls_base_11(fmt_float_for_form(x)); }
    // Phase 8f — Combat / Structures
    if let Some(v) = g(game_config::GameSettings::dino_harvesting_damage_multiplier) {
        window.set_f_dino_harvesting_damage_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::dino_turret_damage_multiplier) {
        window.set_f_dino_turret_damage_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = gb(game_config::GameSettings::allow_speed_leveling) {
        window.set_b_allow_speed_leveling(v);
    }
    if let Some(v) = gb(game_config::GameSettings::allow_flyer_speed_leveling) {
        window.set_b_allow_flyer_speed_leveling(v);
    }
    if let Some(v) = gb(game_config::GameSettings::disable_friendly_fire) {
        window.set_b_disable_friendly_fire(v);
    }
    if let Some(v) = gb(game_config::GameSettings::pve_disable_friendly_fire) {
        window.set_b_pve_disable_friendly_fire(v);
    }
    if let Some(v) = gb(game_config::GameSettings::allow_unlimited_respecs) {
        window.set_b_allow_unlimited_respecs(v);
    }
    if let Some(v) = gb(game_config::GameSettings::hard_limit_turrets_in_range) {
        window.set_b_hard_limit_turrets_in_range(v);
    }
    if let Some(v) = gb(game_config::GameSettings::limit_turrets_in_range) {
        window.set_b_limit_turrets_in_range(v);
    }
    if let Some(v) = gi(game_config::GameSettings::limit_turrets_num) {
        window.set_f_limit_turrets_num(fmt_int_for_form(v));
    }
    if let Some(v) = g(game_config::GameSettings::limit_turrets_range) {
        window.set_f_limit_turrets_range(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::structure_prevent_resource_radius_multiplier) {
        window.set_f_structure_prevent_resource_radius_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::per_platform_max_structures_multiplier) {
        window.set_f_per_platform_max_structures_multiplier(fmt_float_for_form(v));
    }
    if let Some(v) = ub(ark_config::GameUserSettings::always_allow_structure_pickup) {
        window.set_b_always_allow_structure_pickup(v);
    }
    if let Some(v) = u(ark_config::GameUserSettings::structure_pickup_time_after_placement) {
        window.set_f_structure_pickup_time_after_placement(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::structure_pickup_hold_duration) {
        window.set_f_structure_pickup_hold_duration(fmt_float_for_form(v));
    }
    if let Some(v) = ui_(ark_config::GameUserSettings::max_platform_saddle_structure_limit) {
        window.set_f_max_platform_saddle_structure_limit(fmt_int_for_form(v));
    }
    if let Some(v) = ub(ark_config::GameUserSettings::enable_cryopod_nerf) {
        window.set_b_enable_cryopod_nerf(v);
    }
    if let Some(v) = u(ark_config::GameUserSettings::cryopod_nerf_damage_mult) {
        window.set_f_cryopod_nerf_damage_mult(fmt_float_for_form(v));
    }
    if let Some(v) = u(ark_config::GameUserSettings::cryopod_nerf_duration) {
        window.set_f_cryopod_nerf_duration(fmt_float_for_form(v));
    }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_cryo_fridge_on_saddle) {
        window.set_b_allow_cryo_fridge_on_saddle(v);
    }
    if let Some(v) = ub(ark_config::GameUserSettings::disable_cryopod_fridge_requirement) {
        window.set_b_disable_cryopod_fridge_requirement(v);
    }
    // Phase 8T — additional Cryopod knobs
    if let Some(v) = u(ark_config::GameUserSettings::cryopod_nerf_incoming_damage_mult_percent) {
        window.set_f_cryopod_nerf_incoming_damage_mult_percent(fmt_float_for_form(v));
    }
    if let Some(v) = ub(ark_config::GameUserSettings::disable_cryopod_enemy_check) {
        window.set_b_disable_cryopod_enemy_check(v);
    }
    if let Some(v) = ui_(ark_config::GameUserSettings::cryopod_fridge_cooldowntime) {
        window.set_f_cryopod_fridge_cooldowntime(fmt_int_for_form(v));
    }
    // Phase 8g — XP gain breakdown
    if let Some(v) = g(game_config::GameSettings::generic_xp_multiplier) { window.set_f_generic_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::harvest_xp_multiplier) { window.set_f_harvest_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::kill_xp_multiplier) { window.set_f_kill_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::craft_xp_multiplier) { window.set_f_craft_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::special_xp_multiplier) { window.set_f_special_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::explorer_note_xp_multiplier) { window.set_f_explorer_note_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::boss_kill_xp_multiplier) { window.set_f_boss_kill_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::cave_kill_xp_multiplier) { window.set_f_cave_kill_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::wild_kill_xp_multiplier) { window.set_f_wild_kill_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::tamed_kill_xp_multiplier) { window.set_f_tamed_kill_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::unclaimed_kill_xp_multiplier) { window.set_f_unclaimed_kill_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = g(game_config::GameSettings::alpha_kill_xp_multiplier) { window.set_f_alpha_kill_xp_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = gi(game_config::GameSettings::override_max_experience_points_player) { window.set_f_override_max_experience_points_player(fmt_int_for_form(v)); }
    if let Some(v) = gi(game_config::GameSettings::override_max_experience_points_dino) { window.set_f_override_max_experience_points_dino(fmt_int_for_form(v)); }
    // Phase 8h — Cosmetic / Chat
    if let Some(v) = ub(ark_config::GameUserSettings::global_voice_chat) { window.set_b_global_voice_chat(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::proximity_chat) { window.set_b_proximity_chat(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::dont_always_notify_player_joined) { window.set_b_dont_always_notify_player_joined(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::always_notify_player_left) { window.set_b_always_notify_player_left(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::admin_logging) { window.set_b_admin_logging(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_hide_damage_source_from_logs) { window.set_b_allow_hide_damage_source_from_logs(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::show_floating_damage_text) { window.set_b_show_floating_damage_text(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::show_map_player_location) { window.set_b_show_map_player_location(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::server_crosshair) { window.set_b_server_crosshair(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::server_force_no_hud) { window.set_b_server_force_no_hud(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_third_person_player) { window.set_b_allow_third_person_player(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_hit_markers) { window.set_b_allow_hit_markers(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::disable_pve_gamma) { window.set_b_disable_pve_gamma(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::enable_pvp_gamma) { window.set_b_enable_pvp_gamma(v); }
    // Phase 8i — Cluster / Lists
    let us = |get: fn(&ark_config::GameUserSettings) -> Option<String>| get(&gus);
    if let Some(v) = us(ark_config::GameUserSettings::server_password) { window.set_f_server_password(v.as_str().into()); }
    if let Some(v) = us(ark_config::GameUserSettings::ban_list_url) { window.set_f_ban_list_url(v.as_str().into()); }
    if let Some(v) = us(ark_config::GameUserSettings::admin_list_url) { window.set_f_admin_list_url(v.as_str().into()); }
    if let Some(v) = us(ark_config::GameUserSettings::bad_word_list_url) { window.set_f_bad_word_list_url(v.as_str().into()); }
    if let Some(v) = us(ark_config::GameUserSettings::bad_word_white_list_url) { window.set_f_bad_word_white_list_url(v.as_str().into()); }
    if let Some(v) = us(ark_config::GameUserSettings::custom_live_tuning_url) { window.set_f_custom_live_tuning_url(v.as_str().into()); }
    if let Some(v) = ub(ark_config::GameUserSettings::no_tribute_downloads) { window.set_b_no_tribute_downloads(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_download_dinos) { window.set_b_prevent_download_dinos(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_download_items) { window.set_b_prevent_download_items(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_download_survivors) { window.set_b_prevent_download_survivors(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_upload_dinos) { window.set_b_prevent_upload_dinos(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_upload_items) { window.set_b_prevent_upload_items(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_upload_survivors) { window.set_b_prevent_upload_survivors(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::cross_ark_allow_foreign_dino_downloads) { window.set_b_cross_ark_allow_foreign_dino_downloads(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_tribe_alliances) { window.set_b_prevent_tribe_alliances(v); }
    if let Some(v) = ui_(ark_config::GameUserSettings::max_number_of_players_in_tribe) { window.set_f_max_number_of_players_in_tribe(fmt_int_for_form(v)); }
    // Phase 8j — Stat clamps / Blueprint caps
    if let Some(v) = ui_(ark_config::GameUserSettings::max_blueprint_dino_level) { window.set_f_max_blueprint_dino_level(fmt_int_for_form(v)); }
    if let Some(v) = ui_(ark_config::GameUserSettings::max_blueprint_dino_quality) { window.set_f_max_blueprint_dino_quality(fmt_int_for_form(v)); }
    if let Some(v) = ui_(ark_config::GameUserSettings::max_blueprint_item_quality) { window.set_f_max_blueprint_item_quality(fmt_int_for_form(v)); }
    if let Some(v) = ui_(ark_config::GameUserSettings::max_blueprint_scout_quality) { window.set_f_max_blueprint_scout_quality(fmt_int_for_form(v)); }
    if let Some(v) = ui_(ark_config::GameUserSettings::max_hexagons_per_character) { window.set_f_max_hexagons_per_character(fmt_int_for_form(v)); }
    if let Some(v) = ub(ark_config::GameUserSettings::clamp_item_spoiling_times) { window.set_b_clamp_item_spoiling_times(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::clamp_item_stats) { window.set_b_clamp_item_stats(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::clamp_resource_harvest_damage) { window.set_b_clamp_resource_harvest_damage(v); }
    if let Some(v) = ui_(ark_config::GameUserSettings::implant_suicide_cd) { window.set_f_implant_suicide_cd(fmt_int_for_form(v)); }
    if let Some(v) = u(ark_config::GameUserSettings::server_auto_force_respawn_wild_dinos_interval) { window.set_f_server_auto_force_respawn_wild_dinos_interval(fmt_float_for_form(v)); }
    if let Some(v) = gi(game_config::GameSettings::destroy_tames_over_level_clamp) { window.set_f_destroy_tames_over_level_clamp(fmt_int_for_form(v)); }
    // Phase 8L — extra GameUserSettings.ini knobs
    if let Some(v) = ub(ark_config::GameUserSettings::fast_decay_unsnapped_core_structures) { window.set_b_fast_decay_unsnapped_core_structures(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::override_structure_platform_prevention) { window.set_b_override_structure_platform_prevention(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_offline_pvp) { window.set_b_prevent_offline_pvp(v); }
    if let Some(v) = u(ark_config::GameUserSettings::prevent_offline_pvp_interval) { window.set_f_prevent_offline_pvp_interval(fmt_float_for_form(v)); }
    if let Some(v) = ub(ark_config::GameUserSettings::pvp_dino_decay) { window.set_b_pvp_dino_decay(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::pvp_structure_decay) { window.set_b_pvp_structure_decay(v); }
    if let Some(v) = u(ark_config::GameUserSettings::pve_dino_decay_period_multiplier) { window.set_f_pve_dino_decay_period_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = ub(ark_config::GameUserSettings::only_auto_destroy_core_structures) { window.set_b_only_auto_destroy_core_structures(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::auto_destroy_decayed_dinos) { window.set_b_auto_destroy_decayed_dinos(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::tribe_log_destroyed_enemy_structures) { window.set_b_tribe_log_destroyed_enemy_structures(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::pve_allow_structures_at_supply_drops) { window.set_b_pve_allow_structures_at_supply_drops(v); }
    if let Some(v) = u(ark_config::GameUserSettings::oxygen_swim_speed_stat_multiplier) { window.set_f_oxygen_swim_speed_stat_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = u(ark_config::GameUserSettings::tribe_name_change_cooldown) { window.set_f_tribe_name_change_cooldown(fmt_float_for_form(v)); }
    if let Some(v) = u(ark_config::GameUserSettings::platform_saddle_build_area_bounds_multiplier) { window.set_f_platform_saddle_build_area_bounds_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = u(ark_config::GameUserSettings::raid_dino_character_food_drain_multiplier) { window.set_f_raid_dino_character_food_drain_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = u(ark_config::GameUserSettings::item_stack_size_multiplier) { window.set_f_item_stack_size_multiplier(fmt_float_for_form(v)); }
    if let Some(v) = u(ark_config::GameUserSettings::start_time_hour) { window.set_f_start_time_hour(fmt_float_for_form(v)); }
    if let Some(v) = ui_(ark_config::GameUserSettings::rcon_server_game_log_buffer) { window.set_f_rcon_server_game_log_buffer(fmt_int_for_form(v)); }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_raid_dino_feeding) { window.set_b_allow_raid_dino_feeding(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::enable_extra_structure_prevention_volumes) { window.set_b_enable_extra_structure_prevention_volumes(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_spawn_animations) { window.set_b_prevent_spawn_animations(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::prevent_diseases) { window.set_b_prevent_diseases(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::non_permanent_diseases) { window.set_b_non_permanent_diseases(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::use_optimized_harvesting_health) { window.set_b_use_optimized_harvesting_health(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_multiple_attached_c4) { window.set_b_allow_multiple_attached_c4(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_flying_stamina_recovery) { window.set_b_allow_flying_stamina_recovery(v); }
    if let Some(v) = ub(ark_config::GameUserSettings::allow_crate_spawns_on_top_of_structures) { window.set_b_allow_crate_spawns_on_top_of_structures(v); }
    // Phase 8P — MOTD
    if let Some(v) = gus.motd_message() { window.set_f_motd_message(v.as_str().into()); }
    if let Some(v) = gus.motd_duration() { window.set_f_motd_duration(fmt_int_for_form(v)); }
    Ok(())
}

#[cfg(target_os = "windows")]
fn pick_ini_file(start_dir: Option<&Path>) -> Option<PathBuf> {
    let mut dialog = rfd::FileDialog::new()
        .set_title("Import settings from .ini")
        .add_filter("INI files", &["ini"])
        .add_filter("All files", &["*"]);
    if let Some(p) = start_dir {
        dialog = dialog.set_directory(p);
    }
    dialog.pick_file()
}

#[cfg(not(target_os = "windows"))]
fn pick_ini_file(_start_dir: Option<&Path>) -> Option<PathBuf> {
    None
}

#[cfg(target_os = "windows")]
fn pick_folder(start_dir: Option<&Path>) -> Option<PathBuf> {
    let mut dialog = rfd::FileDialog::new().set_title("Choose ARKSA tool data folder");
    if let Some(p) = start_dir {
        dialog = dialog.set_directory(p);
    }
    dialog.pick_folder()
}

#[cfg(not(target_os = "windows"))]
fn pick_folder(_start_dir: Option<&Path>) -> Option<PathBuf> {
    None
}

/// Replace the process's STDERR handle with `NUL` so noisy `eprintln!`
/// callers (notably ICU4X's "No segmentation model for language: ja"
/// fallback warning, which fires on every Japanese line break and ignores
/// `log` / `tracing` filters) don't drown the console.
///
/// Skipped when `RUST_LOG` is set so developers running with explicit log
/// configuration still see everything.
#[cfg(target_os = "windows")]
fn redirect_stderr_to_null_unless_debug() {
    if std::env::var_os("RUST_LOG").is_some() {
        return;
    }
    use windows::core::w;
    use windows::Win32::Storage::FileSystem::{
        CreateFileW, FILE_ATTRIBUTE_NORMAL, FILE_GENERIC_WRITE, FILE_SHARE_READ,
        FILE_SHARE_WRITE, OPEN_EXISTING,
    };
    use windows::Win32::System::Console::{SetStdHandle, STD_ERROR_HANDLE};

    // SAFETY: CreateFileW + SetStdHandle are standard Win32 calls; the
    // returned handle is owned by the OS and we hand ownership to it via
    // SetStdHandle.
    unsafe {
        if let Ok(handle) = CreateFileW(
            w!("NUL"),
            FILE_GENERIC_WRITE.0,
            FILE_SHARE_READ | FILE_SHARE_WRITE,
            None,
            OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL,
            None,
        ) {
            let _ = SetStdHandle(STD_ERROR_HANDLE, handle);
        }
    }
}

#[cfg(not(target_os = "windows"))]
fn redirect_stderr_to_null_unless_debug() {
    // No-op outside Windows — the warning was a Windows-renderer artefact
    // and Linux dev builds run with the user's normal stderr anyway.
}

fn wire_world_settings_callbacks(
    window: &WorldSettingsWindow,
    ctx: AppCtx,
    profiles: ProfileList,
    selected: SelectedIndex,
    log: LogBuffer,
    main_weak: slint::Weak<MainWindow>,
) {
    {
        let weak = window.as_weak();
        window.on_cancel_clicked(move || {
            if let Some(w) = weak.upgrade() {
                let _ = w.hide();
            }
        });
    }
    {
        let weak = window.as_weak();
        window.on_reset_clicked(move || {
            if let Some(w) = weak.upgrade() {
                reset_world_settings_window(&w);
                w.set_validation_error(SharedString::default());
            }
        });
    }
    {
        let weak = window.as_weak();
        let log = log.clone();
        let main_weak = main_weak.clone();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        window.on_save_clicked(move || {
            let Some(window) = weak.upgrade() else { return };
            // Re-resolve install root each time — user could have switched
            // profiles after opening the dialog.
            let Some(profile_path) = current_profile_path(&profiles, &selected) else {
                window.set_validation_error(SharedString::from("No profile selected."));
                return;
            };
            let install_root = match Profile::load(&profile_path)
                .ok()
                .and_then(|p| p.resolved_install_path(&ctx.install_dir))
            {
                Some(r) => r,
                None => {
                    window.set_validation_error(SharedString::from(
                        "Profile has no install location.",
                    ));
                    return;
                }
            };
            match collect_world_form(&window) {
                Err(msg) => {
                    window.set_validation_error(SharedString::from(msg.as_str()));
                }
                Ok(values) => match write_world_form(&install_root, &values, Some(&profile_path)) {
                    Ok(()) => {
                        push_log_async(
                            &main_weak,
                            &log,
                            &format!(
                                "World settings saved to {} (effective on next Start).",
                                install_root.display()
                            ),
                        );
                        let _ = window.hide();
                    }
                    Err(e) => {
                        window.set_validation_error(SharedString::from(
                            format!("Save failed: {e:#}").as_str(),
                        ));
                    }
                },
            }
        });
    }
    {
        let weak = window.as_weak();
        let log = log.clone();
        let main_weak = main_weak.clone();
        let ctx = ctx.clone();
        let profiles = profiles.clone();
        let selected = selected.clone();
        window.on_import_clicked(move || {
            // Default the picker into the current profile's install dir if we
            // can — most imports come from a sibling install's INI files.
            let start_dir = current_profile_path(&profiles, &selected)
                .and_then(|p| Profile::load(&p).ok())
                .and_then(|p| p.resolved_install_path(&ctx.install_dir))
                .map(|r| {
                    r.join("ShooterGame")
                        .join("Saved")
                        .join("Config")
                        .join("WindowsServer")
                });
            let chosen = pick_ini_file(start_dir.as_deref());
            let Some(path) = chosen else {
                return; // user cancelled
            };
            let Some(window) = weak.upgrade() else { return };
            match import_world_settings(&window, &path) {
                Ok(()) => {
                    window.set_validation_error(SharedString::default());
                    push_log_async(
                        &main_weak,
                        &log,
                        &format!(
                            "Imported world settings from {}. Click Save to apply.",
                            path.display()
                        ),
                    );
                }
                Err(e) => {
                    window.set_validation_error(SharedString::from(
                        format!("Import failed: {e:#}").as_str(),
                    ));
                }
            }
        });
    }
}

// ─── Find window ──────────────────────────────────────────────────────────

/// Bundled-asset cache, parsed once at startup.
struct FindData {
    /// (id, display name), sorted alphabetically by name (case-insensitive).
    mods: Vec<(u64, String)>,
    engrams: Vec<gamedata::Engram>,
    items: Vec<gamedata::Item>,
    dinos: Vec<gamedata::Dino>,
}

impl FindData {
    fn load() -> Self {
        let mut mods: Vec<(u64, String)> = modlist::parse(ASSET_MODLIST).into_iter().collect();
        mods.sort_by_key(|a| a.1.to_lowercase());
        Self {
            mods,
            engrams: gamedata::parse_engrams_bytes(ASSET_ENGRAMS),
            items: gamedata::parse_items_bytes(ASSET_ITEMS),
            dinos: gamedata::parse_dinos_bytes(ASSET_DINOS),
        }
    }

    /// Build the entries displayed in the list view for a given category and
    /// substring filter. Returns `(entries_capped, filtered_count, total_count)`.
    fn entries_for(&self, category: usize, filter: &str) -> (Vec<FindEntry>, usize, usize) {
        let needle = filter.trim().to_lowercase();
        let pass = |hay: &str| -> bool {
            needle.is_empty() || hay.to_lowercase().contains(&needle)
        };

        match category {
            // Mods
            0 => {
                let total = self.mods.len();
                let filtered: Vec<&(u64, String)> = self
                    .mods
                    .iter()
                    .filter(|(id, name)| pass(name) || pass(&id.to_string()))
                    .collect();
                let count = filtered.len();
                let entries: Vec<FindEntry> = filtered
                    .into_iter()
                    .take(FIND_RESULT_LIMIT)
                    .map(|(id, name)| FindEntry {
                        name: name.as_str().into(),
                        class_name: id.to_string().into(),
                        detail: SharedString::default(),
                    })
                    .collect();
                (entries, count, total)
            }
            // Engrams
            1 => {
                let total = self.engrams.len();
                let filtered: Vec<&gamedata::Engram> = self
                    .engrams
                    .iter()
                    .filter(|e| pass(&e.name) || pass(&e.class_name))
                    .collect();
                let count = filtered.len();
                let entries: Vec<FindEntry> = filtered
                    .into_iter()
                    .take(FIND_RESULT_LIMIT)
                    .map(|e| FindEntry {
                        name: e.name.as_str().into(),
                        class_name: e.class_name.as_str().into(),
                        detail: format!("Lv {} / {}p", e.level, e.points).into(),
                    })
                    .collect();
                (entries, count, total)
            }
            // Items
            2 => {
                let total = self.items.len();
                let filtered: Vec<&gamedata::Item> = self
                    .items
                    .iter()
                    .filter(|i| pass(&i.name) || pass(&i.class_name))
                    .collect();
                let count = filtered.len();
                let entries: Vec<FindEntry> = filtered
                    .into_iter()
                    .take(FIND_RESULT_LIMIT)
                    .map(|i| FindEntry {
                        name: i.name.as_str().into(),
                        class_name: i.class_name.as_str().into(),
                        detail: format!("Stack {}", i.stack_size).into(),
                    })
                    .collect();
                (entries, count, total)
            }
            // Dinos (or any out-of-range index — treat as Dinos)
            _ => {
                let total = self.dinos.len();
                let filtered: Vec<&gamedata::Dino> = self
                    .dinos
                    .iter()
                    .filter(|d| pass(&d.name) || pass(&d.class_name))
                    .collect();
                let count = filtered.len();
                let entries: Vec<FindEntry> = filtered
                    .into_iter()
                    .take(FIND_RESULT_LIMIT)
                    .map(|d| FindEntry {
                        name: d.name.as_str().into(),
                        class_name: d.class_name.as_str().into(),
                        detail: SharedString::default(),
                    })
                    .collect();
                (entries, count, total)
            }
        }
    }
}

fn refresh_find(window: &FindWindow, data: &FindData) {
    let category = window.get_selected_category().max(0) as usize;
    let filter = window.get_filter_text().to_string();
    let (entries, filtered_count, total) = data.entries_for(category, &filter);
    let model = std::rc::Rc::new(VecModel::from(entries));
    window.set_entries(ModelRc::from(model));
    window.set_filtered_count(filtered_count as i32);
    window.set_total_count(total as i32);
}

fn wire_find_callbacks(window: &FindWindow, data: Arc<FindData>) {
    {
        let weak = window.as_weak();
        let data = data.clone();
        window.on_category_changed(move |_idx| {
            if let Some(w) = weak.upgrade() {
                refresh_find(&w, &data);
            }
        });
    }
    {
        let weak = window.as_weak();
        let data = data.clone();
        window.on_filter_changed(move |_text| {
            if let Some(w) = weak.upgrade() {
                refresh_find(&w, &data);
            }
        });
    }
}

// ─── status refresh ────────────────────────────────────────────────────────

fn initial_status_refresh(
    window: &MainWindow,
    ctx: &AppCtx,
    profiles: &ProfileList,
    selected: &SelectedIndex,
    log: &LogBuffer,
) {
    refresh_status_async(&window.as_weak(), ctx, profiles, selected, log);
}

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
    let labels = ctx.labels.clone();
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
                let pid = status
                    .pid
                    .map(|p| p.to_string())
                    .unwrap_or_else(|| "?".into());
                format!("{} {})", labels.status_running_prefix, pid)
            } else {
                labels.status_stopped.clone()
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
                    title: labels.status_profile_error.as_str().into(),
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

// ─── formatting ────────────────────────────────────────────────────────────

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
