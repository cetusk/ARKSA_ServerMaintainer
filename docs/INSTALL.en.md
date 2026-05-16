# Install / Setup

🌐 **English** | [日本語](./INSTALL.md)

This doc takes a **first-time user** from a clean checkout to a running ARK SA dedicated server with the GUI driving it.

## Build prerequisites

- **Rust** stable (`rustup default stable`)
- **MSVC toolchain** (`x86_64-pc-windows-msvc`) — `rustup`'s default on Windows
- **Visual Studio 2022 Build Tools** (Desktop development with C++ workload — provides `link.exe`):
  ```powershell
  winget install --id Microsoft.VisualStudio.2022.BuildTools `
    --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
  ```
  Restart PowerShell after installing so PATH picks up the new `link.exe`. Verify with `where.exe link`.

The first `cargo build` pulls ~300 crates (Slint, `windows`, software renderer, etc.) — 5–10 minutes on a cold cache.

> **Linker stack note**: `.cargo/config.toml` raises the reserved stack on Windows binaries to 8 MiB. The World Settings window's initialisation (~250 properties / 18 categories / 6 stat-array `GroupBox`es) overflows the default 1 MiB main-thread stack during Slint component construction (`STATUS_STACK_OVERFLOW = 0xC00000FD`). Active for `x86_64-pc-windows-msvc` / `-gnu` / `i686-pc-windows-msvc`.

## Quick start

### 1. Pick (or create) a folder for tool data

The tool stores profiles / the bundled `steamcmd` / logs under the folder pointed to by the `ARKSA_DIR` environment variable. **This is separate from the ARK dedicated-server install location** — the install path is per-profile, set inside the GUI.

```powershell
mkdir D:\ARK\ARKSA_Tools -Force
```

### 2. Create `run.ps1` from the template

```powershell
cd <repo-root>
copy run.example.ps1 run.ps1
notepad run.ps1
```

Edit this line:
```powershell
$env:ARKSA_DIR = "D:\ARK\ARKSA_Tools"
```

`run.ps1` is gitignored, so personal paths never reach the repo.

### 3. Launch the GUI

Either:
```powershell
.\run.ps1            # from a PowerShell prompt
```
or double-click `run.bat` from Explorer (it invokes `run.ps1` with `-ExecutionPolicy Bypass`, so a stock Windows install doesn't need `Set-ExecutionPolicy`).

The GUI opens in the empty state (no profiles yet).

### 4. Create a profile

Click **Create your first server**. In the dialog the fields you **must** change from defaults are:

| Field | Value |
|---|---|
| **Install location** | Absolute path where ARK SA should be installed (e.g. `D:\ARK\ARKSA_Server`) |
| **Use path relative to ARKSA dir** | **Uncheck** |

Everything else (file name, map = `TheIsland_WP`, ports, max players, auto-generated admin password) is fine at defaults. Click **Create**.

> The profile INI is written to `<ARKSA_DIR>\Profile\<file_name>.ini`.

### 5. Install the dedicated server

Back in the main window, click **Install / Update server**. The bundled steamcmd downloads itself first (~3 MB on first run), then pulls down ARK SA Dedicated Server (~13 GB). Progress streams to the Log panel; you're done when you see:
```
Success! App '2430930' fully installed.
steamcmd exited with code 0.
```

### 6. Start it

Click **Start** in the GUI. The Log panel shows `Server started (PID …).` and the Status panel refreshes every 5 s (`Running`, working set, uptime). While any lifecycle action is in flight, the *Server control* section shows an **indeterminate progress bar + "Working…"** so you always know something is happening.

First boot takes 30–60 s (TheIsland load). To confirm the server is ready for clients, tail ARK's own log:
```powershell
Get-Content "D:\ARK\ARKSA_Server\ShooterGame\Saved\Logs\ShooterGame.log" -Wait -Tail 10
```
Wait for `Server has completed startup and is now advertising for join.`.

### 7. Smoke-test RCON

Type `ListPlayers` into the GUI's RCON input and click **Send**. If the Log shows `No Players Connected` (or a player list once people join), RCON is wired up end-to-end.

> Phase 5 wires this automatically: `Profile::create_new` writes `RCONEnabled=True` / `RCONPort=…` / `ServerAdminPassword=…` straight into the install-root's `GameUserSettings.ini`. The hand-edit step earlier versions required is gone.

## Recommended disk layout

Following the steps above gives you:

```
D:\ARK\
├── ARKSA_Tools\                              ← ARKSA_DIR (tens of MB)
│   ├── Profile\
│   │   └── MyServer.ini                       per-server config
│   └── steamcmd\
│       └── steamcmd.exe                       bundled with the tool
└── ARKSA_Server\                             ← Install location (tens of GB)
    ├── ARKSA_Backups\                         ← backup tree (see below)
    │   └── <MapName>\
    │       ├── auto\                          periodic snapshots (ring buffer)
    │       ├── manual\                        manual snapshots (never auto-pruned)
    │       └── pre_rollback\                  emergency snapshots (last 3 kept)
    └── ShooterGame\
        ├── Binaries\Win64\
        │   └── ArkAscendedServer.exe
        ├── Content\                           game assets
        └── Saved\
            ├── SavedArks\                     world saves
            ├── Config\WindowsServer\
            │   ├── GameUserSettings.ini       authoritative for RCON etc.
            │   └── Game.ini
            └── Logs\
                └── ShooterGame.log            live server log
```

If `ARKSA_DIR` is unset, the tool falls back to the directory containing `arksa-gui.exe`. That's fine for distributed binaries; with `cargo run` it resolves to `target\debug\`, so set the variable for dev work.

`ARKSA_Backups\` is created as a **sibling** of the install root so future ARK engine reorganisations of `Saved\` can't collide with it. Full layout details are in [USAGE.en.md's backup section](./USAGE.en.md#backup--rollback).
