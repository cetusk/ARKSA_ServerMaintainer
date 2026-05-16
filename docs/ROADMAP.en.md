# Roadmap

🌐 **English** | [日本語](./ROADMAP.md)

For the `.pas → Rust` mapping and crate responsibilities, see [`architecture.md`](./architecture.md).

## Completed phases

| Phase | Title | Status |
|---|---|---|
| 0 | Workspace skeleton | ✅ |
| 1 | INI / Profile / Settings / ModList / Win32 process | ✅ |
| 2 | RCON + steamcmd + server lifecycle | ✅ |
| 3 | Slint UI wired to core | ✅ |
| 4 | New Profile dialog + Install button + empty state | ✅ |
| 5 | Auto-generation of `GameUserSettings.ini` + Mod/Engram/Item/Dino find UI | ✅ |
| 6 | Discord webhook + tray notifications | ✅ |
| 7 | i18n (EN + JA) | ✅ |
| 8a | World Settings dialog (Game.ini + GameUserSettings.ini editor, ~30 fields) | ✅ |
| 8b | Wire-up fix: ~20 multipliers routed to GUS, PvE/PvP toggles + Ops basics | ✅ |
| 8c | Breeding / Imprint category (~11 fields) | ✅ |
| 8d | Loot / Spoilage category (~15 fields) | ✅ |
| 8e | Stat arrays category (6 × 12 = 72 fields) | ✅ |
| 8f | Combat / Structures category (~22 fields incl. Cryopod nerf) | ✅ |
| 8g | XP gain breakdown category (14 fields) | ✅ |
| 8h | Cosmetic / Chat category (14 toggles) | ✅ |
| 8i | Cluster / Lists category (16 fields incl. URL strings) | ✅ |
| 8j | Stat clamps / Blueprint caps category (11 fields) | ✅ |
| 8k | Launch flags editor — edits the `-flag` portion of the profile's `MM_Command_Val` | ✅ |
| 8L | 27 more GUS fields (PvP/decay, multiplier/volume, disease/safety/craft) | ✅ |
| 8M | Wire-up: moved 12 breeding / loot keys from `Game.ini` to GUS (reverted in 8S) | ⚠️ superseded |
| 8P | MOTD editor (`[MessageOfTheDay]` section: multi-line `Message` + `Duration`) | ✅ |
| 8R | Mods category (CurseForge ID list editor) + cross-category live search bar | ✅ |
| 8S | Revert Phase 8M: 12 breeding / loot keys back into `Game.ini`. Save also uses `IniDoc::remove_key` to strip the leftover `[ServerSettings]` entries from the 8M era and avoid conflicting duplicates | ✅ |
| 8T | 3 more Cryopod keys: `CryopodNerfIncomingDamageMultPercent`, `DisableCryopodEnemyCheck`, `CryopodFridgeCooldowntime` | ✅ |
| 8U | Row-spacing fix for the search filter (worked around Slint 1.16's `inherits HorizontalBox` + `visible:false` not releasing layout space, using `inherits Rectangle` + `height:0`) | ✅ |
| 8+ | Sidebar layout, click-popup descriptions, turquoise × dark theme, main-window language picker, `SectionGroup` panels, fixed column headers, single ScrollView, full-word button labels | ✅ |
| 11 | Backup / rollback (full set): `arksa-core::backup` (zip snapshots + atomic write + staging-swap rollback + zip-slip guard), BackupWindow single-screen dialog, auto scheduler (60 s wake, disk-mtime based, survives restart), 4-step compression picker (STORE / Deflate 1/6/9, default Deflate 1) | ✅ |
| 12 | Live language switch (no restart): re-injects UiLabels into all 6 windows via `AllWindowWeaks`, syncs Server Status copy via `invoke_refresh_status`, symmetric in both the main and notification language pickers | ✅ |
| 13 | Public-address display (playit.gg / Tailscale): Connection row under the Profile section, saved to `[Server] Edit_PublicAddress` (upstream INI schema compatible), `arboard`-backed clipboard copy, auto-follows profile switches | ✅ |
| 14 | MOD configs category + RTB schema: per-MOD INI schema registry (`crates/arksa-core/src/mod_configs.rs`), only MODs detected in `-mods=` are shown, disabling a MOD hides its GroupBox and skips writes (so settings persist when re-enabled) | ✅ |
| 15 | Backup window rework: `auto/` / `manual/` / `pre_rollback/` split into 3 sub-directories, sidebar collapsed to (paths / settings / list), list category gets 3 sub-tabs + sort + 🔁 related-backup badge, pre_rollback filename embeds the source timestamp for traceability, legacy layout auto-migrated | ✅ |
| 16 | Progress bars: determinate bar + byte counter for snapshots / rollback (100 ms throttle), indeterminate spinner + "Working…" label for server start / stop / restart / install / RCON / status refresh | ✅ |
| 17 | Release `.zip` pipeline: `x86_64-pc-windows-msvc` + `+crt-static` for a self-contained `.exe`, `tools/build-release.ps1` for local zip generation, `.github/workflows/release.yml` to attach zips to GitHub Releases on `v*` tag push, bundled `run.bat` for one-double-click launch | ✅ |

## What's next

| Phase | Title | Status |
|---|---|---|
| 9 | `arksa-commander` CLI — RCON + status from external scripts | next |
| 10 | `arksa-updater` self-update via GitHub Releases | |
| (?) | Scheduled restart + auto-restart on crash | |
| (?) | Per-profile manifest pin via steamcmd (Phase 9 will surface this as a GUI checkbox) | |
| (?) | Direct playit-cli integration to auto-fetch the tunnel address | |
| (?) | i18n coverage for NewProfileWindow's inner field labels | |
| (?) | Description popups for stat-array cells / niche fields | |
| (?) | Backup progress-bar polish (i18n the phase label, position tweaks) | |

## Doc maintenance log

- 2026-05-16: Split the README into README + INSTALL / USAGE / TROUBLESHOOTING / ROADMAP to lower the information density and localise diffs per topic
