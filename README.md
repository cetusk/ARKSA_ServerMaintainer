# ARKSA_ServerMaintainer

A Rust + Slint GUI tool to maintain a personal **ARK: Survival Ascended** dedicated server on Windows.

A personal-use **re-implementation** of [ASA Server Manager (ASASM)](https://sites.google.com/view/asa-server-manager) by *Dの人*. The upstream author explicitly permits forks and re-implementations in other languages. The upstream Object Pascal source is **not redistributed** here; obtain it from the upstream distribution above if you need to cross-reference.

> **Status: Phase 4 — first usable build, validated end-to-end.** The GUI can create a profile, install the dedicated server via the bundled steamcmd, start/stop the server, send RCON commands, and a real ARK SA client has successfully joined a server set up this way (via in-game `open <ip>:<port>`). Backups, scheduled restarts, and the Discord/tray notification UIs are still pending. See [`docs/architecture.md`](./docs/architecture.md) for the phase-by-phase plan.

---

## Table of Contents
1. [Goals & non-goals](#goals--non-goals)
2. [Architecture at a glance](#architecture-at-a-glance)
3. [Build prerequisites](#build-prerequisites)
4. [Quickstart](#quickstart)
5. [Recommended on-disk layout](#recommended-on-disk-layout)
6. [Daily operation](#daily-operation)
7. [Connecting from the ARK SA client](#connecting-from-the-ark-sa-client)
8. [Known issues & current workarounds](#known-issues--current-workarounds)
9. [Roadmap](#roadmap)
10. [License](#license)

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

### 6. Apply the manual RCON workaround (one-time, current limitation)

ARK SA's URL parser corrupts a few launch-line parameters. Until Phase 5
auto-generates `GameUserSettings.ini`, do this once:

a. Stop the server if it is running:
```powershell
Stop-Process -Name ArkAscendedServer* -Force
```

b. Open the freshly-installed `GameUserSettings.ini`:
```powershell
notepad "D:\ARK\ARKSA_Server\ShooterGame\Saved\Config\WindowsServer\GameUserSettings.ini"
```

c. In the `[ServerSettings]` section, ensure exactly these three lines exist
   (replace the password with the value of `Edit_ServerAdminPassword`
   from `<ARKSA_DIR>\Profile\<file_name>.ini`, with no `?…` tail):
```ini
[ServerSettings]
RCONEnabled=True
RCONPort=27020
ServerAdminPassword=<your-admin-password>
```

d. Open the profile INI:
```powershell
notepad "D:\ARK\ARKSA_Tools\Profile\<file_name>.ini"
```
Confirm the `MM_Command_Val=` line **does not contain** `?ServerAdminPassword=`. If it does, delete the `?ServerAdminPassword=…?` segment so the URL is just map / SessionName / Port / QueryPort / RCONEnabled / RCONPort / MaxPlayers, e.g.:
```
MM_Command_Val=ArkAscendedServer.exe TheIsland_WP?listen?SessionName=ARKSAServer?Port=7777?QueryPort=27015?RCONEnabled=True?RCONPort=27020?MaxPlayers=10 -log -NoBattlEye
```

> Why: see [Known issues](#known-issues--current-workarounds) below.

### 7. Start

Click **Start** in the GUI. The Log panel shows `Server started (PID …).`,
the Status panel updates every 5 s (`Running`, memory, uptime).

First startup takes 30–60 s (loading TheIsland). Tail the actual ARK log
to know when it is ready to accept clients:
```powershell
Get-Content "D:\ARK\ARKSA_Server\ShooterGame\Saved\Logs\ShooterGame.log" -Wait -Tail 10
```
Wait for `Server has completed startup and is now advertising for join.`

### 8. Test RCON

In the GUI's RCON box, type `ListPlayers` and **Send**. You should see
`No Players Connected` (or a list of names) in the log. RCON is now wired.

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
| **Update game version** | GUI → *Install / Update server* (re-runs steamcmd; existing files are preserved) |
| **Send arbitrary RCON command** | GUI's RCON input box → type a command → *Send* |
| **Edit the launch line** | Edit `MM_Command_Val=` in `<ARKSA_DIR>\Profile\<file_name>.ini`, then GUI *Refresh* |
| **Switch profile** | GUI's profile dropdown (when more than one profile exists) |

The Status panel polls `server::status` every 5 s — PID, working-set memory,
and uptime are kept current without you doing anything.

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

## Known issues & current workarounds

These are tracked for fixing in upcoming phases — they are listed here so
the workarounds are visible until then.

### 1. ARK URL parser corrupts `ServerAdminPassword` in `MM_Command_Val`
ARK SA's launch-URL parser swallows the rest of the URL into the value of
`?ServerAdminPassword=`, also breaks if the value starts with `-`, and
breaks if `?SessionName=` contains a space. Symptoms:
- `GameUserSettings.ini → ServerAdminPassword=…?Port=7777?…?MaxPlayers=10` (one giant string)
- RCON authentication fails (the password the client expects no longer matches what ARK stored)
- `RCONEnabled=True` from the URL is ignored

**Workaround (current):** the manual GameUserSettings.ini step in the
[Quickstart](#6-apply-the-manual-rcon-workaround-one-time-current-limitation),
plus removing `?ServerAdminPassword=…?` from `MM_Command_Val`.

**Fix planned (next phase):** `Profile::create_new` will write
`GameUserSettings.ini` itself with the correct `RCONEnabled=True`,
`RCONPort=`, and `ServerAdminPassword=` lines, and the launch URL will
omit those keys entirely. After that the workaround disappears.

### 2. Server does not appear in ARK SA's Unofficial server browser
Wildcard's matchmaking is slow / unreliable for small personal servers.
**Workaround:** connect via in-game console (`open <ip>:<port>`). See
[Connecting from the ARK SA client](#connecting-from-the-ark-sa-client).

### 3. ICU4X warning on JP-locale Windows
On startup the GUI may log:
```
ICU4X data error: No segmentation model for language: ja
```
Slint's bundled software renderer ships only English text-segmentation
data. The warning is harmless because the UI text is English. If it
becomes annoying later, switching the renderer feature in
`Cargo.toml` from `renderer-software` to `renderer-skia` (which carries
full CJK data) eliminates it — at the cost of needing the C++ Skia
toolchain at build time.

### 4. RCON port silently changes after a malformed first start
If ARK ever falls back to its default RCON port (often `query_port + 2`)
the value can stick in `GameUserSettings.ini`. Edit
`GameUserSettings.ini → RCONPort=27020` and restart to recover. The fix
in (1) makes this self-healing.

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
| 5 | Auto `GameUserSettings.ini` + Mod/Dino/Item search UI | next |
| 6 | Discord webhook + tray notifications | |
| 7 | i18n (EN + JA) | |
| 8 | `arksa-commander` CLI | |
| 9 | `arksa-updater` self-update against GitHub Releases | |

## License

- Code: **MIT** — see [`LICENSE`](./LICENSE)
- Upstream attribution: [`LICENSE`](./LICENSE) tail section
- The upstream Pascal/Lazarus source is **not** included here — fetch it
  from the upstream distribution if you need to cross-reference port
  decisions
