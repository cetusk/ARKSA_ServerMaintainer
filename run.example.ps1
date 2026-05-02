# ARKSA_ServerMaintainer launcher (template).
#
# Usage:
#   1. Copy this file to `run.ps1` (which is gitignored).
#   2. Edit $env:ARKSA_DIR below to point at the folder you want this tool to
#      keep its working data in (Profile/, steamcmd/). It does NOT need to be
#      where the ARK dedicated server itself is installed — the install
#      location is set per-profile inside the GUI.
#   3. From the workspace root, run `.\run.ps1`.
#
# Recommended layout (Install location is set in the New Profile dialog):
#   D:\ARK\
#   ├── ARKSA_Tools\        ← ARKSA_DIR (this script's $env:ARKSA_DIR)
#   │   ├── Profile\
#   │   └── steamcmd\
#   └── ARKSA_Server\       ← per-profile Install location
#       └── ShooterGame\Binaries\Win64\ArkAscendedServer.exe

$ErrorActionPreference = "Stop"

# ── Edit this line ────────────────────────────────────────────────────────
$env:ARKSA_DIR = "C:\path\to\your\arksa-tools"
# ──────────────────────────────────────────────────────────────────────────

if (-not (Test-Path $env:ARKSA_DIR)) {
    New-Item -ItemType Directory -Path $env:ARKSA_DIR -Force | Out-Null
    Write-Host "Created $env:ARKSA_DIR"
}

Write-Host "ARKSA_DIR = $env:ARKSA_DIR"
cargo run -p arksa-gui $args
