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
    gamedata, launch_args::{self, LaunchArgs, COMMON_MAPS}, modlist,
    profile::Profile,
    rcon::RconClient,
    server::{self, ServerStatus, StopOptions, StopOutcome},
    steamcmd,
};
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

#[derive(Clone)]
struct AppCtx {
    install_dir: PathBuf,
}

type ProfileList = Arc<Mutex<Vec<(String, PathBuf)>>>;
type SelectedIndex = Arc<Mutex<usize>>;
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

    let dialog = NewProfileWindow::new()?;
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
    refresh_find(&find_window, &find_data);
    wire_find_callbacks(&find_window, find_data.clone());

    wire_main_callbacks(
        &window,
        &dialog,
        &find_window,
        ctx.clone(),
        profiles.clone(),
        selected.clone(),
        log.clone(),
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

fn wire_main_callbacks(
    window: &MainWindow,
    dialog: &NewProfileWindow,
    find_window: &FindWindow,
    ctx: AppCtx,
    profiles: ProfileList,
    selected: SelectedIndex,
    log: LogBuffer,
) {
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
                    Ok(format!("Stop result: {}.", describe_stop(outcome)))
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
        window.on_browse_install_dir(move || {
            push_log_async(
                &weak,
                &log,
                "Browse… not yet implemented. Set ARKSA_DIR env var to override.",
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
                    status
                        .pid
                        .map(|p| p.to_string())
                        .unwrap_or_else(|| "?".into())
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
