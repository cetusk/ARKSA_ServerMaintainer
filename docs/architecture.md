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

| Phase | Deliverable | Key crates touched |
|---|---|---|
| 0 | Workspace skeleton, builds with stub UI | (all) |
| 1 | INI / profile / settings / modlist / Win32 process monitoring | `arksa-core` |
| 2 | RCON client + steamcmd wrapper + server start/stop | `arksa-core` |
| 3 | Slint UI: status panel, start/stop wired to core, periodic poll | `arksa-gui` |
| 4 | Profile editor, settings dialog, backup | `arksa-gui`, `arksa-core::backup` |
| 5 | Find UI (Mod / Dino / Item / Engram) | `arksa-gui`, `arksa-core::{modlist,gamedata}` |
| 6 | Discord webhook + tray + toast notifications | `arksa-notify` |
| 7 | i18n: English + Japanese | `arksa-gui` |
| 8 | `arksa-commander` CLI | `arksa-commander` |
| 9 | `arksa-updater` against GitHub Releases | `arksa-updater` |

Each phase ends in a runnable build with the new feature visible from the GUI (or, for binaries, from the command line).

## Async strategy

A single multi-thread tokio runtime is owned by `arksa-gui`. Slint runs on the
main thread; long-running I/O (RCON, HTTP, steamcmd, zip) is spawned via
`tokio::spawn` and results are marshalled back to the UI using
`slint::invoke_from_event_loop`.

## Win32 access

All direct Win32 calls go through the `windows` crate (Microsoft official
bindings). Handles are wrapped in newtype structs with `Drop` impls so leaks
that were possible in the original (`OpenProcess` without paired `CloseHandle`
in some error paths) are avoided structurally.
