# ARKSA_ServerMaintainer

A Rust + Slint GUI tool to maintain a personal **ARK: Survival Ascended** dedicated server on Windows.

A personal-use **re-implementation** of [ASA Server Manager (ASASM)](https://sites.google.com/view/asa-server-manager) by *Dの人*. The upstream author explicitly permits forks and re-implementations in other languages. The upstream Object Pascal source is **not redistributed** here; obtain it from the upstream distribution above if you need to cross-reference.

> **Status: Phase 8a–8k — full per-profile world editor (~250 fields) + dark mode + main-window language picker.** The GUI can create a profile, auto-write `GameUserSettings.ini` so RCON works on first start, install the dedicated server via the bundled steamcmd, start/stop/restart the server, send RCON commands, search Mods/Engrams/Items/Dinos, send Discord & Windows toast notifications, switch between English / Japanese **right from the main window**, and **edit ~250 world / breeding / loot / stat / combat / XP / chat / cluster / clamp / launch-flag parameters across `Game.ini` + `GameUserSettings.ini` + the profile's `MM_Command_Val` from a left-sidebar / right-pane editor (17 categories, click-the-label popups for bilingual descriptions, file-import for reusing settings from another install)**. Real ARK SA clients have joined a server set up this way (via in-game `open <ip>:<port>`). CLI commander, self-updater (Phase 9), backups, and scheduled restarts are still pending. See [`docs/architecture.md`](./docs/architecture.md) for the full phase plan and [`docs/parameters.md`](./docs/parameters.md) for the comprehensive ARK SA parameter reference.

---

## Table of Contents
1. [Goals & non-goals](#goals--non-goals)
2. [Architecture at a glance](#architecture-at-a-glance)
3. [Build prerequisites](#build-prerequisites)
4. [Quickstart](#quickstart)
5. [Recommended on-disk layout](#recommended-on-disk-layout)
6. [Daily operation](#daily-operation)
7. [Connecting from the ARK SA client](#connecting-from-the-ark-sa-client)
8. [Compatibility & integrity fixes](#compatibility--integrity-fixes)
9. [Known issues & current workarounds](#known-issues--current-workarounds)
10. [Roadmap](#roadmap)
11. [License](#license)

---

## Goals & non-goals

**Goals**
- Win32 API access with memory safety → **Rust**
- Native-looking desktop GUI → **Slint**
- A single dedicated server for personal use — no multi-server orchestration
- English first, Japanese as a second locale (Phase 7)

**Non-goals**
- Multi-server fleet management (upstream's ARKestra UI is intentionally not ported)
- Linux / macOS support — Windows-only

## Architecture at a glance

```
ARKSA_ServerMaintainer/
├── Cargo.toml              # workspace
├── rust-toolchain.toml
├── assets/                 # ModList / EngramData / ItemData / DinoData / List
├── crates/
│   ├── arksa-core/         # lib: server lifecycle, RCON, Win32 process,
│   │                       #      INI, mod data, steamcmd wrapper
│   ├── arksa-notify/       # lib: Discord webhook + tray (Phase 6)
│   ├── arksa-gui/          # bin: main GUI (Slint)
│   ├── arksa-updater/      # bin: self-updater (Phase 9)
│   ├── arksa-commander/    # bin: CLI command sender (Phase 8)
│   └── arksa-nbcall/       # bin: ConPTY child runner
└── docs/architecture.md    # crate responsibilities + .pas → Rust mapping
```

## Build prerequisites

- **Rust** stable (`rustup default stable`)
- **MSVC toolchain** (`x86_64-pc-windows-msvc`) — `rustup` selects it by default on Windows
- **Visual Studio 2022 Build Tools** with the *Desktop development with C++* workload (provides `link.exe`):
  ```powershell
  winget install --id Microsoft.VisualStudio.2022.BuildTools `
    --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
  ```
  After install, **restart PowerShell** so the toolchain is on `PATH`. Verify with `where.exe link`.

The first `cargo build` downloads ~300 crates (Slint, the `windows` crate, the software renderer, etc.) — expect 5–10 minutes on a cold cache.

> **Linker stack note**: `.cargo/config.toml` bumps the Windows binary's
> reserved stack to 8 MiB. The World Settings window construction
> (~250 properties / 17 categories / 6 stat-array group boxes) overflows
> the default 1 MiB main-thread stack during Slint component
> initialisation (`STATUS_STACK_OVERFLOW = 0xC00000FD`). The flag is set
> for `x86_64-pc-windows-msvc`, `-gnu`, and `i686-pc-windows-msvc`.

## Quickstart

### 1. Pick (or create) a working folder for tool data

The tool keeps its profiles, the bundled `steamcmd`, and any logs under the
folder pointed to by the `ARKSA_DIR` environment variable. **This is *not*
the same as the ARK dedicated server install location** — the install
location is set per-profile inside the GUI.

```powershell
mkdir D:\ARK\ARKSA_Tools -Force
```

### 2. Create your `run.ps1` from the template

```powershell
cd <repo-root>
copy run.example.ps1 run.ps1
notepad run.ps1
```

Set the line:
```powershell
$env:ARKSA_DIR = "D:\ARK\ARKSA_Tools"
```

`run.ps1` is gitignored so this personal path stays local.

### 3. Launch the GUI

Either:
```powershell
.\run.ps1            # from a PowerShell prompt
```
…or double-click `run.bat` in Explorer (it forwards to `run.ps1` with
`-ExecutionPolicy Bypass`, so a fresh Windows install does not need
`Set-ExecutionPolicy`).

The GUI opens in an empty state because no profile exists yet.

### 4. Create a profile

Click **Create your first server…**. In the dialog, the only fields you
*must* change from the defaults are:

| Field | Value to set |
|---|---|
| **Install location** | the absolute path where you want ARK SA installed (e.g. `D:\ARK\ARKSA_Server`) |
| **Use path relative to ARKSA dir** | **uncheck** |

Everything else (file name, map = `TheIsland_WP`, ports, max players,
auto-generated admin password) can stay as defaults. Click **Create**.

> The Profile INI is written to `<ARKSA_DIR>\Profile\<file_name>.ini`.

### 5. Install the dedicated server

Back on the main window, click **Install / Update server**. The bundled
steamcmd downloads itself (first time, ~3 MB) and then installs ARK SA
Dedicated Server (~13 GB). Progress streams into the Log panel. Wait for:
```
Success! App '2430930' fully installed.
steamcmd exited with code 0.
```

### 6. Start

Click **Start** in the GUI. The Log panel shows `Server started (PID …).`,
the Status panel updates every 5 s (`Running`, memory, uptime).

First startup takes 30–60 s (loading TheIsland). Tail the actual ARK log
to know when it is ready to accept clients:
```powershell
Get-Content "D:\ARK\ARKSA_Server\ShooterGame\Saved\Logs\ShooterGame.log" -Wait -Tail 10
```
Wait for `Server has completed startup and is now advertising for join.`

### 7. Test RCON

In the GUI's RCON box, type `ListPlayers` and **Send**. You should see
`No Players Connected` (or a list of names) in the log. RCON is now wired.

> Phase 5 wires this up automatically: `Profile::create_new` writes the
> right `RCONEnabled=True` / `RCONPort=…` / `ServerAdminPassword=…` lines
> directly into `GameUserSettings.ini` (under the install root), so the
> manual edit step earlier versions needed is no longer required.

## Recommended on-disk layout

After the steps above your disks look like this:

```
D:\ARK\
├── ARKSA_Tools\                              ← ARKSA_DIR (~tens of MB)
│   ├── Profile\
│   │   └── MyServer.ini                       per-server config
│   └── steamcmd\
│       └── steamcmd.exe                       bundled by the tool
└── ARKSA_Server\                             ← Install location (~tens of GB)
    └── ShooterGame\
        ├── Binaries\Win64\
        │   └── ArkAscendedServer.exe
        ├── Content\                           game assets
        └── Saved\
            ├── SavedArks\                     world saves
            ├── Config\WindowsServer\
            │   ├── GameUserSettings.ini       authoritative for RCON
            │   └── Game.ini
            └── Logs\
                └── ShooterGame.log            real-time server log
```

If `ARKSA_DIR` is not set, the tool falls back to the directory containing
`arksa-gui.exe`. That works for a shipped install but is awkward under
`cargo run` because the binary lives in `target\debug\`.

## Daily operation

| Action | How |
|---|---|
| **Start** | GUI → *Start* button |
| **Stop (graceful)** | GUI → *Stop (graceful)* — sends `SaveWorld` + `DoExit` over RCON, falls back to `WM_CLOSE` if RCON is down |
| **Restart** | GUI → *Restart* — *Stop (graceful)* → 2 s wait → *Start*, with notification on each transition |
| **Update game version** | GUI → *Install / Update server* (re-runs steamcmd; existing files are preserved) |
| **Send arbitrary RCON command** | GUI's RCON input box → type a command → *Send* |
| **Find a Mod / Engram / Item / Dino** | GUI → *Find…* → pick category, type substring → results show name + class/ID |
| **Edit world / difficulty parameters** | GUI → *World Settings…* → pick a category in the left sidebar → fill in fields → *Save* (re-reads on next Start) |
| **See what a parameter does** | In *World Settings…* click the parameter label (look for the **ⓘ** marker) — pops up a bilingual description |
| **Reuse settings from another install** | *World Settings…* → *Import settings from file…* → pick a `Game.ini` or `GameUserSettings.ini` |
| **Edit launch flags** | *World Settings…* → *Launch flags* category — edits the `-flag` portion of the profile's `MM_Command_Val` (URL / mods stay untouched) |
| **Discord / toast notifications** | GUI → *Notifications…* → set webhook URL, toggle event types, *Save* |
| **Switch UI language (EN ↔ JA)** | GUI top bar → *Language* dropdown → restart required to apply (the choice persists immediately) |
| **Edit the raw launch line** | Edit `MM_Command_Val=` in `<ARKSA_DIR>\Profile\<file_name>.ini`, then GUI *Refresh* |
| **Switch profile** | GUI's profile dropdown (when more than one profile exists) |

The Status panel polls `server::status` every 5 s — PID, working-set memory,
and uptime are kept current without you doing anything.

### Notifications

The *Notifications…* dialog persists settings to
`<ARKSA_DIR>/AsaServerManegerWin.ini` (compatible with the upstream layout).
Currently wired event triggers:

| Event | Fires when |
|---|---|
| `Server starting` | After `server::start` returns a PID |
| `Server stopped` | After `stop_graceful` returns `GracefulRcon` or `GracefulWindowClose` |

Other events (Server online / Crash detected / Tool update / Server-app
update) can be enabled in the dialog and will send out a payload once the
corresponding detector is implemented in a future phase.

### World Settings dialog

*World Settings…* opens a left-sidebar / right-pane editor over the current
profile's `Game.ini`, `GameUserSettings.ini`, and the `-flag` portion of
its `MM_Command_Val`. Pick a category in the sidebar to swap the form on
the right. ~250 fields total across 17 categories:

| Category | Notable fields | Where the values land |
|---|---|---|
| Rates | XP / Harvest / Taming / Mating / Hatch / Mature | `GameUserSettings.ini` (XP/harvest/taming) + `Game.ini` (breeding rates) |
| Day cycle | Day/Night scale | `GameUserSettings.ini` |
| Player | Food / Water / Stamina / Health / Damage / Resistance | `GameUserSettings.ini` (drain/regen/dmg) + `Game.ini` (harvesting dmg) |
| Tamed dino | Drains / Damage / Resistance | `GameUserSettings.ini` |
| Wild dino | Food / Stamina / Torpor / Count | `Game.ini` (food/torpor) + `GameUserSettings.ini` (stamina/count) |
| Difficulty / structure | DifficultyOffset, Override, structure dmg/resist/repair, imprint flags | `GameUserSettings.ini` + `Game.ini` |
| PvE / PvP | serverPVE, AllowFlyerCarryPvE, EnableCryoSicknessPVE, DisableStructureDecayPvE | `GameUserSettings.ini` |
| Ops | MaxTamedDinos, KickIdle, AutoSavePeriodMinutes, TheMaxStructuresInRange | `GameUserSettings.ini` |
| Breeding | MatingSpeed, LayEggInterval, PassiveTame, BabyImprint*, BabyCuddle*, DisableBreeding/Taming | `Game.ini` |
| Loot / Spoilage | SupplyCrate / Fishing / Crops / Spoiling / Decomposition / Fuel / MaxFallSpeed | `Game.ini` |
| Stat arrays | `PerLevelStatsMultiplier_*[0..11]` (Player / Tamed / Tamed-Add / Tamed-Affinity / Wild) + `PlayerBaseStatMultipliers[0..11]` — 6 × 12 = 72 cells | `Game.ini` |
| Combat / Structures | DinoHarvest/TurretDmg, Speed-leveling, friendly fire, turret limits, structure pickup, Cryopod nerf | `Game.ini` + `GameUserSettings.ini` |
| XP gain | Generic / Harvest / Kill / Craft / Special / ExplorerNote / BossKill / CaveKill / WildKill / TamedKill / UnclaimedKill / AlphaKill XP, OverrideMax* | `Game.ini` |
| Cosmetic / Chat | globalVoiceChat, ProximityChat, FloatingDamageText, ServerCrosshair, AllowThirdPerson, Hit-markers, gamma toggles | `GameUserSettings.ini` |
| Cluster / Lists | ServerPassword, BanListURL, AdminListURL, BadWordList, CustomLiveTuning, transfer toggles, MaxPlayersInTribe | `GameUserSettings.ini` |
| Clamps / Blueprints | MaxBlueprint(Dino|Item|Scout)*, MaxHexagons, ClampItemSpoiling/Stats, Implant CD, AutoForceRespawnInterval, DestroyTamesOverLevelClamp | `GameUserSettings.ini` + `Game.ini` |
| Launch flags | Free-form text edit of `-log -NoBattlEye -EpicApp=ArkAscended …` etc. — only the `-flag` portion of `MM_Command_Val` is touched | Profile `MM_Command_Val` |

**Bilingual click-to-popup descriptions** — most parameter labels carry
an **ⓘ** marker. Click the label to pop up a short English / Japanese
description (drives off the same EN / JA setting as the rest of the
GUI). Click anywhere outside the popup to dismiss.

**Workflows**

- *Brand-new profile* — open the dialog before first `Start`. Defaults
  (mostly `1.0`) are shown because no INI exists yet. Tweak whatever
  you want, hit **Save**, then **Start**.
- *Existing profile* — the dialog reads whatever is already in the two
  INIs and the profile. Editing is non-destructive: keys we don't model
  (e.g. `OverrideEngramEntries[…]`) are preserved on save.
- *Reuse settings from another install* — click **Import settings from
  file…**, pick a `Game.ini` (or `GameUserSettings.ini`, or a hand-merged
  combined INI). Recognised keys flow into the form; nothing is written
  until you click **Save**.
- *Reset* — **Reset to defaults** restores all fields to vanilla values
  (1.0 for multipliers, false for the booleans). Click **Cancel** to
  discard, **Save** to persist.

ARK only re-reads these files at startup, so changes take effect on the
next *Start*.

## Connecting from the ARK SA client

ARK SA's *Unofficial* server browser is unreliable for fresh personal
servers — it can take 5–30 minutes to register, or never appear at all. The
reliable path is **direct connect** by IP:

### Same machine (server + client)
1. Launch ARK Survival Ascended (the client) from Steam.
2. From the main menu, open the console with `~` / `` ` ``.
3. Run:
   ```
   open 127.0.0.1:7777
   ```

### LAN
Find the server PC's LAN IP (`ipconfig | findstr IPv4`), then on the client
machine:
```
open <server-LAN-ip>:7777
```

### Internet
Forward UDP `7777` and UDP `27015` on your router to the server PC. Open
the same ports in Windows Firewall (admin PowerShell):
```powershell
New-NetFirewallRule -DisplayName "ARK SA Game"  -Direction Inbound -Protocol UDP -LocalPort 7777  -Action Allow
New-NetFirewallRule -DisplayName "ARK SA Query" -Direction Inbound -Protocol UDP -LocalPort 27015 -Action Allow
```
Connect with `open <public-ip>:7777`. Do **not** open the RCON port (TCP
27020) to the public Internet.

If you also disabled BattlEye on the server (the default `extra_flags`
include `-NoBattlEye`), add the matching flag to the **client's** Steam
launch options:
```
-NoBattlEye
```
Otherwise the client refuses to connect to a non-BattlEye server.

## Compatibility & integrity fixes

A bag of quirks discovered while reaching parity with upstream ASASM and
shipping a working ARK SA server. Each is something the codebase
silently handles for you; collected here so future maintainers know
*why* the workaround is in the code.

### ARK SA URL parser swallows the rest of the URL after special chars
ARK SA's launch-URL parser is brittle:

- `?ServerAdminPassword=` in the URL: the parser folds **the rest of the
  URL** into the password value, silently disabling RCON and breaking
  every `?key=value` token after it.
- A password starting with `-` (common in URL-safe Base64 alphabets) is
  treated as the start of a `-flag` argument, with the same swallowing
  effect.
- A `SessionName` containing whitespace truncates at the first space
  because Windows splits the command line on spaces.

**Workarounds** in `arksa-core::launch_args` and `ark_config`:

- `RCONEnabled` / `RCONPort` / `ServerAdminPassword` are **never** put
  in the launch URL. They are written straight into `[ServerSettings]`
  of `GameUserSettings.ini` (`Phase 5`).
- `generate_password()` uses a pure alphanumeric alphabet — no `-` /
  `_` — and skips visually ambiguous chars (`0/O/I/l/1`). Length 16.
- Default `SessionName` is `ARKSAServer` (no whitespace). The user can
  still type spaces and ARK will accept them via the file-based
  `[ServerSettings] SessionName=`.
- Test cases enforce these invariants:
  `never_includes_server_admin_password_in_url`,
  `generated_password_never_starts_with_dash_or_underscore`,
  `default_session_name_has_no_whitespace`.

### `[ServerSettings]` vs `Game.ini` routing
The bulk of multipliers documented as "ServerSettings" actually accept
both files, but the canonical home is `GameUserSettings.ini` and ARK
sometimes prefers GUS when both contain the same key. Phase 8b corrected
the wire-up: ~20 multipliers (`XPMultiplier`, `Player*Drain*`,
`Dino*Drain*`, `DayCycleSpeedScale`, `Structure*Multiplier`,
`DinoCountMultiplier`, etc.) used to be written to `Game.ini` and are
now written to `GameUserSettings.ini`. A handful of keys
(`PlayerHarvestingDamageMultiplier`, `WildDinoCharacterFoodDrainMultiplier`,
`StructureDamageRepairCooldown`, breeding/imprint multipliers) genuinely
live in `Game.ini` and stay there. See
[`docs/parameters.md`](./docs/parameters.md) for the full routing table.

### INI backslash escaping (`D:\ARK\…` round-trip)
`rust-ini`'s default `EscapePolicy` would write
`Edit_Install_Location_Val=D:\\ARK\\ARKSA_Server` (double-escaping
backslashes), and our load path (which has `enabled_escape: false` to
match Lazarus's `TIniFile`) would then read those literal `\\`s back as
two characters, producing a broken Windows path that doesn't match the
real filesystem. Fixed by setting `EscapePolicy::Nothing` on save in
`arksa-core::ini_doc`. Regression test:
`windows_paths_round_trip_without_double_escaping`.

### Lazarus `TIniFile` quirks (boolean / float encoding + SHIFT_JIS)
Upstream profiles are written by Lazarus, which uses the OS ANSI
codepage (CP932 / SHIFT_JIS on JP Windows) and writes booleans as `0/1`,
floats with a `.` decimal separator regardless of locale. Our `IniDoc`:

- Tries UTF-8 first (with BOM detection), falls back to SHIFT_JIS so
  legacy `.ini` files load cleanly.
- Writes booleans as `0`/`1` to match upstream — except in
  `[ServerSettings]` of `GameUserSettings.ini`, where we write
  `True`/`False` to match what ARK itself emits.
- Writes floats with `format!("{value:?}")` so `1.0` stays `1.0` (not
  `1`) and locale-dependent commas never appear.
- Accepts both `0/1` and `True/False` (case-insensitive) on read.

### Server-client version mismatch (manifest pinning)
Steam's auto-update can move the server ahead of the client release the
players have installed (e.g. server v86.15 vs client v86.11 → black
screen on connect). Workaround documented for the `Install / Update`
flow: drive `steamcmd` (or [DepotDownloader](https://github.com/SteamRE/DepotDownloader))
with an explicit manifest pin. In practice we have used DepotDownloader
manifest **`684954496930236842`** (server build 86.12) which works with
client 86.11. Future work (Phase 9 / steamcmd integration polish) will
expose the manifest as a per-profile setting.

### Slint component initialisation overflows the default Windows stack
The World Settings window now declares ~250 properties, 17 conditional
content panes, and 6 GroupBoxes of stat-array rows. Slint generates a
lot of static initialiser code per component, and the default 1 MiB
Windows main-thread stack overflows during construction with
`STATUS_STACK_OVERFLOW = 0xC00000FD`. Fixed by reserving 8 MiB via
`.cargo/config.toml` (`x86_64-pc-windows-msvc`, `-gnu`,
`i686-pc-windows-msvc`).

### ICU4X "No segmentation model for language: ja" log spam
Slint's text layout calls into ICU4X to choose line-break positions,
and ICU4X's bundled data only ships Western locales. On any Japanese
text it logs `ICU4X data error: No segmentation model for language: ja`
and falls back to char-wrap (which is fine for Japanese — there are
no inter-word spaces to honour). The log is harmless but drowns out
useful output. Fixed by routing `log` crate output through `tracing`
(`tracing-log` bridge) and silencing `icu_segmenter` /
`icu_provider` / Slint warnings in `EnvFilter`. Set `RUST_LOG=info`
to bypass the filter and see everything again.

### ARK URL parser corrupting `ServerAdminPassword` (resolved by Phase 5)
Earlier versions required the user to manually edit
`GameUserSettings.ini` because ARK SA's URL parser merged the rest of
the launch URL into the admin-password value. Phase 5's
`arksa-core::ark_config` writes `RCONEnabled` / `RCONPort` /
`ServerAdminPassword` straight into `GameUserSettings.ini` and the
launch URL no longer carries them. New profiles created by *New…* are
RCON-ready immediately.

## Known issues & current workarounds

### 1. Server does not appear in ARK SA's Unofficial server browser
Wildcard's matchmaking is slow / unreliable for small personal servers.
**Workaround:** connect via in-game console (`open <ip>:<port>`). See
[Connecting from the ARK SA client](#connecting-from-the-ark-sa-client).

### 2. Live language switching is not supported
The Language dropdown on the main window writes the choice to
`AppSettings` immediately, but the actual UI labels are sampled from the
language setting once at startup. Restart the GUI to apply a language
change. The bilingual descriptions inside *World Settings…* honour the
setting at dialog open time.

### 3. NewProfileWindow internals are still English-only
The Quickstart's *New Profile* dialog has many internal field labels (game
port, query port, mods, etc.) that are not yet wired through the i18n
labels struct. Section/window titles and buttons are translated, but the
in-form field labels stay in English regardless of language setting. Will
be filled in incrementally.

### 4. Stat arrays tab has no per-cell description popups
The 72 stat-array cells (Player / Tamed / Tamed-Add / Tamed-Affinity /
Wild × Health / Stamina / … / CraftingSpeed) skip the click-to-popup
description because the labels (`[3] Oxygen` etc.) are already
self-documenting. Other ~80 of the most niche fields also still lack
descriptions and can be added incrementally — adding `description:
root.lang-ja ? "JA" : "EN";` to a row in `main.slint` is all that is
needed.

## Roadmap

See [`docs/architecture.md`](./docs/architecture.md) for the full phase plan
and the `.pas → Rust` mapping.

| Phase | Title | Status |
|---|---|---|
| 0 | Workspace skeleton | ✅ |
| 1 | INI / Profile / Settings / ModList / Win32 process | ✅ |
| 2 | RCON + steamcmd + server lifecycle | ✅ |
| 3 | Slint UI wired to core | ✅ |
| 4 | New Profile dialog + Install button + empty state | ✅ |
| 5 | Auto `GameUserSettings.ini` + Mod/Engram/Item/Dino search UI | ✅ |
| 6 | Discord webhook + tray notifications | ✅ |
| 7 | i18n (EN + JA) | ✅ |
| 8a | World Settings dialog (Game.ini + GameUserSettings.ini editor, ~30 fields) | ✅ |
| 8b | wire-up fix: ~20 multipliers re-routed to GUS; PvE/PvP toggles + Ops basics | ✅ |
| 8c | Breeding / Imprint category (~11 fields) | ✅ |
| 8d | Loot / Spoilage category (~15 fields) | ✅ |
| 8e | Stat arrays category (6 × 12 = 72 fields) | ✅ |
| 8f | Combat / Structures category (~22 fields, incl. Cryopod nerf) | ✅ |
| 8g | XP gain breakdown category (14 fields) | ✅ |
| 8h | Cosmetic / Chat category (14 toggles) | ✅ |
| 8i | Cluster / Lists category (16 fields incl. URL strings) | ✅ |
| 8j | Stat clamps / Blueprint caps category (11 fields) | ✅ |
| 8k | Launch flags editor — edits Profile `MM_Command_Val` `-flag` portion | ✅ |
| 8+ | Sidebar layout, click-to-popup descriptions, dark mode, top-bar language picker | ✅ |
| 9 | `arksa-commander` CLI | next |
| 10 | `arksa-updater` self-update against GitHub Releases | |
| (?) | Backup / scheduled restart / crash auto-restart | |
| (?) | Live language switching | |
| (?) | Manifest-pinned steamcmd installs (per-profile) | |

## License

- Code: **MIT** — see [`LICENSE`](./LICENSE)
- Upstream attribution: [`LICENSE`](./LICENSE) tail section
- The upstream Pascal/Lazarus source is **not** included here — fetch it
  from the upstream distribution if you need to cross-reference port
  decisions
