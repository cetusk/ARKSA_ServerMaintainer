# Architecture

## Crate responsibilities

| Crate | Type | Responsibility | Upstream counterpart |
|---|---|---|---|
| `arksa-core` | lib | Server lifecycle, RCON, Win32 process monitoring, INI, mod data, backup | `frameui.pas`, `asautils.pas`, `rcon.pas`, `simplymm.pas` |
| `arksa-notify` | lib | Discord webhook (async queue), Windows tray + toast | `discord.pas`, `notify_ui.pas` |
| `arksa-gui` | bin | Slint GUI, hosts a tokio runtime for I/O work | `mainui.pas`, `frameui.pas`, `aboutui.pas`, `findui.pas`, `importui.pas` |
| `arksa-updater` | bin | Self-update via GitHub Releases | `ASASM_Updater.exe` (`asasm_upd_ui.pas`) |
| `arksa-commander` | bin | CLI: send a server command by profile name | `AsaServerCommander.exe` (`AsaServerCommander.lpr`) |
| `arksa-nbcall` | bin | ConPTY child runner | `NBCall.exe` (`NBCall.lpr`) |

## Source mapping (.pas → Rust)

| Upstream `.pas` | Lines | Rust home | Notes |
|---|---:|---|---|
| `mainui.pas` | 1391 | `arksa-gui/src/main.rs` + `ui/main.slint` | UI redesigned, behavior preserved |
| `mainui_arkestra.pas` | 1326 | — | **Dropped** (multi-server UI; out of scope for personal use) |
| `frameui.pas` | 7801 | split: `arksa-core::server` / `process` / `profile` / `backup` + `arksa-gui` panels | Largest unit; functionality fans out by domain |
| `aboutui.pas` | — | `arksa-gui::about` panel | Settings tabs |
| `findui.pas` | 917 | `arksa-gui::find` panel + `arksa-core::{modlist, gamedata}` | Mod / Dino / Item / Engram search |
| `importui.pas` | 395 | `arksa-gui::import` panel | Profile import |
| `asautils.pas` | 797 | `arksa-core::process` + `arksa-core::backup` + small helpers | Win32 + Zip + IP utils |
| `discord.pas` | 418 | `arksa-notify::discord` | Async queue using tokio mpsc |
| `rcon.pas` | 470 | `arksa-core::rcon` | Source RCON protocol |
| `notify_ui.pas` | 69 | `arksa-notify::tray` | Tray + toast |
| `nbprocesswin.pas` | 144 | (caller side, `arksa-gui`) | Wrapper around `arksa-nbcall.exe` |
| `other_proc_ctl.pas` | 68 | `arksa-core::process` | Window-message based command injection |
| `tracetime.pas` | 110 | — | Replaced by `tracing` |
| `messagetrans.pas` | 84 | — | Replaced by Slint `@tr()` |
| `simplymm.pas` | 2476 | (selectively, on demand) | Memory-mapped helpers; only port what we actually need |
| `splashui.pas` / `notify_ui.pas` | — | TBD | Optional; revisit Phase 3+ |
| `plPrivilegeUnit.pas` | 95 | TBD | Token privileges; only if needed for process termination |
| `shortcut.pas` | 159 | TBD | Start-menu shortcut creation; low priority |

## Phases

| Phase | Deliverable | Status | Key crates touched |
|---|---|---|---|
| 0 | Workspace skeleton, builds with stub UI | ✅ | (all) |
| 1 | INI / profile / settings / modlist / Win32 process monitoring | ✅ | `arksa-core` |
| 2 | RCON client + steamcmd wrapper + server start/stop | ✅ | `arksa-core` |
| 3 | Slint UI: status panel, start/stop wired to core, periodic poll | ✅ | `arksa-gui` |
| 4 | New Profile dialog + Install/Update button + empty state | ✅ | `arksa-gui` |
| 5 | Auto `GameUserSettings.ini` (`ark_config`) + Find UI (Mod/Engram/Item/Dino) | ✅ | `arksa-core::{ark_config,gamedata,modlist}`, `arksa-gui` |
| 6 | Discord webhook + Windows toast + notification settings UI | ✅ | `arksa-notify`, `arksa-gui` |
| 7 | i18n (English + Japanese) — UiLabels struct, Rust-side translation | ✅ | `arksa-gui` |
| 8 | `arksa-commander` CLI | next | `arksa-commander` |
| 9 | `arksa-updater` against GitHub Releases | | `arksa-updater` |
| ? | Backup, scheduled restart, crash auto-restart | | `arksa-core::backup`, `arksa-gui` |
| ? | Profile editor (full settings dialog) | | `arksa-gui` |

Each completed phase ships in a single runnable build with the new feature visible from the GUI (or, for binaries, from the command line).

## Async strategy

Long-running I/O (RCON, HTTP, steamcmd, zip) runs on `std::thread::spawn`
workers from `arksa-gui`; results are marshalled back to Slint via
`slint::Weak::upgrade_in_event_loop`. The `tokio` runtime is in the
dependency graph for future async-native work but the GUI does not currently
mount it. Notifications (Discord HTTP / toast) are fired on a fresh thread
from each lifecycle event so they never block the originating worker.

## Notifications wiring

`arksa-notify::dispatch(config, event, ctx)` is the single dispatch
function. The GUI calls it via `fire_notification`, which spawns a thread
that takes a snapshot of the (mutex-guarded) `NotifyConfig` and invokes
`dispatch`. Discord and toast failures are logged via `tracing::warn` and
never interrupt the calling lifecycle path.

`Profile::create_new` writes the RCON-relevant subset of `NotifyConfig`-style
settings (RCONEnabled / RCONPort / ServerAdminPassword) into the install
root's `GameUserSettings.ini` via `arksa-core::ark_config`, working around a
known ARK SA URL-parser bug that mangles the password and silently disables
RCON when those keys are passed via `?key=value` in the launch URL.

## i18n

UI strings flow through a Rust `Labels` struct (47 fields covering all four
top-level windows). At startup the GUI reads `AppSettings::language()`
(0 = auto, 1 = English, 2 = Japanese, matching upstream ASASM's encoding),
chooses a translation table, and pushes it into each Slint window's
`labels: UiLabels` property. Live language switching is intentionally not
supported — changing the dropdown in *Notifications…* persists the new
choice and the GUI applies it on next launch. This lets us avoid the
runtime cost (and library-dependency cost) of a gettext-style translation
loader while keeping the door open for a richer integration later.

## Win32 access

All direct Win32 calls go through the `windows` crate (Microsoft official
bindings). Handles are wrapped in newtype structs with `Drop` impls so leaks
that were possible in the original (`OpenProcess` without paired `CloseHandle`
in some error paths) are avoided structurally.
