# Build a self-contained release bundle for ARKSA Server Maintainer.
#
# What it does:
#   1. cargo build --release --target x86_64-pc-windows-msvc -p arksa-gui
#   2. Stages arksa-gui.exe + assets/ + run.bat + LICENSE + README.txt under
#      dist\arksa-server-maintainer-vX.Y.Z\
#   3. Zips that staging tree into dist\arksa-server-maintainer-vX.Y.Z.zip
#   4. Copies the standalone exe to dist\arksa-gui-vX.Y.Z.exe for
#      in-place updates (same binary, just no assets/ alongside)
#
# Output: a self-contained zip + a standalone exe. The user extracts the
# zip anywhere and double-clicks run.bat (first install), or drops the
# standalone exe over the previous one (update in place). No Visual C++
# redistributable required (the MSVC CRT is statically linked via
# +crt-static in .cargo/config.toml).
#
# Usage:
#   pwsh -File tools\build-release.ps1                  # build current version
#   pwsh -File tools\build-release.ps1 -Version 1.0.0   # override version
#   pwsh -File tools\build-release.ps1 -SkipBuild       # re-stage only

[CmdletBinding()]
param(
    [string]$Version,
    [switch]$SkipBuild,
    [switch]$KeepStaging
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

Push-Location $RepoRoot
try {
    # Resolve version from workspace Cargo.toml unless overridden.
    if (-not $Version) {
        $cargoToml = Get-Content -Raw -Path (Join-Path $RepoRoot 'Cargo.toml')
        if ($cargoToml -match '(?ms)^\[workspace\.package\].*?^version\s*=\s*"([0-9][^"]*)"') {
            $Version = $Matches[1]
        }
        else {
            throw "Could not parse [workspace.package] version from Cargo.toml"
        }
    }

    $Target = 'x86_64-pc-windows-msvc'
    $BundleName = "arksa-server-maintainer-v$Version"
    $DistDir = Join-Path $RepoRoot 'dist'
    $StageDir = Join-Path $DistDir $BundleName
    $ZipPath = Join-Path $DistDir "$BundleName.zip"
    # Standalone exe (in-place update) — same .exe that lives inside the
    # zip, copied to dist with a version-tagged name. Released alongside
    # the bundle so users who already have assets/ can swap binaries
    # without re-downloading 22 MiB of zip.
    $ExeDistName = "arksa-gui-v$Version.exe"
    $ExeDistPath = Join-Path $DistDir $ExeDistName

    Write-Host "-> Building arksa-gui v$Version for $Target" -ForegroundColor Cyan

    if (-not $SkipBuild) {
        # `+crt-static` lives in .cargo/config.toml — no extra flag needed.
        & cargo build --release --target $Target -p arksa-gui
        if ($LASTEXITCODE -ne 0) {
            throw "cargo build failed (exit $LASTEXITCODE)"
        }
    }

    $ExeSrc = Join-Path $RepoRoot "target\$Target\release\arksa-gui.exe"
    if (-not (Test-Path $ExeSrc)) {
        throw "Built exe not found at $ExeSrc"
    }

    Write-Host "-> Staging bundle under $StageDir" -ForegroundColor Cyan
    if (Test-Path $StageDir) {
        Remove-Item -Recurse -Force $StageDir
    }
    New-Item -ItemType Directory -Force -Path $StageDir | Out-Null

    Copy-Item $ExeSrc -Destination $StageDir
    Copy-Item -Recurse (Join-Path $RepoRoot 'assets') -Destination $StageDir
    Copy-Item (Join-Path $RepoRoot 'LICENSE') -Destination $StageDir
    Copy-Item (Join-Path $RepoRoot 'NOTICE') -Destination $StageDir
    Copy-Item -Force (Join-Path $RepoRoot 'tools\launcher\run.bat') -Destination $StageDir

    # Minimal README inside the zip so the recipient knows where to look.
    @"
ARKSA Server Maintainer v$Version

This is the redistributable bundle. To run:
  1. Extract this zip anywhere with write access (e.g. D:\ARK\Tool).
  2. Double-click run.bat (recommended) or arksa-gui.exe.

By default the tool stores its data (profiles, bundled steamcmd, logs)
right next to the .exe. To put it somewhere else, open run.bat in a
text editor and uncomment the ARKSA_DIR line, then point it at the
folder you want to use.

Full docs / source / issues:
  https://github.com/cetusk/ARKSA_ServerMaintainer

License: MIT (see LICENSE in this folder).
Upstream attribution: see NOTICE in this folder.
"@ | Set-Content -NoNewline -Path (Join-Path $StageDir 'README.txt') -Encoding UTF8

    # Strip any pre-existing zip with the same name — `Compress-Archive`
    # appends rather than replacing.
    if (Test-Path $ZipPath) {
        Remove-Item -Force $ZipPath
    }

    Write-Host "-> Packing zip $ZipPath" -ForegroundColor Cyan
    Compress-Archive -Path "$StageDir\*" -DestinationPath $ZipPath -CompressionLevel Optimal

    Write-Host "-> Copying standalone exe -> $ExeDistPath" -ForegroundColor Cyan
    Copy-Item -Force $ExeSrc -Destination $ExeDistPath

    if (-not $KeepStaging) {
        Remove-Item -Recurse -Force $StageDir
    }

    $zipSize = (Get-Item $ZipPath).Length
    $exeSize = (Get-Item $ExeDistPath).Length
    Write-Host ("[OK] Done.") -ForegroundColor Green
    Write-Host ("    {0,-60} {1,8:N1} MiB" -f $ZipPath, ($zipSize / 1MB))
    Write-Host ("    {0,-60} {1,8:N1} MiB" -f $ExeDistPath, ($exeSize / 1MB))
}
finally {
    Pop-Location
}
