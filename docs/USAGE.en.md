# Usage

🌐 **English** | [日本語](./USAGE.md)

This doc covers what each part of the GUI does. For first-time install see [INSTALL.en.md](./INSTALL.en.md); for known issues see [TROUBLESHOOTING.en.md](./TROUBLESHOOTING.en.md).

## Contents

1. [Action table](#action-table)
2. [Notifications](#notifications)
3. [World Settings dialog](#world-settings-dialog)
4. [MOD configs category](#mod-configs-category)
5. [Backup / rollback](#backup--rollback)
6. [Connection info](#connection-info)
7. [Connecting from an ARK SA client](#connecting-from-an-ark-sa-client)

## Action table

Button labels are full words, not abbreviated (no `…`). Features are grouped under turquoise-headed `SectionGroup`s (Setup / Profile / Server status / Server control / RCON / Log).

| Action | Where |
|---|---|
| **Start** | *Server control* → *Start* |
| **Stop (graceful)** | *Server control* → *Stop (graceful)* — sends `SaveWorld` + `DoExit` over RCON; falls back to `WM_CLOSE` if RCON is unreachable |
| **Restart** | *Server control* → *Restart server* — *Stop (graceful)* → 2 s wait → *Start*; fires notifications at each transition |
| **Update game version** | *Server control* → *Install / Update server* (re-runs steamcmd, keeps existing files) |
| **Ad-hoc RCON command** | Type into *RCON* section → *Send* |
| **Find mods / engrams / items / dinos** | *Setup* → *Find data* → pick a category + substring → name + class/ID listed |
| **Edit world / difficulty parameters** | *Profile* → *World Settings* → pick a category in the left sidebar → edit values → *Save* (applied at next Start) |
| **See what a parameter means** | Click the label (look for the **ⓘ** marker) in *World Settings* — a bilingual EN/JA popup appears **above** the label |
| **Cross-category parameter search** | Type into the *Search:* box at the top of *World Settings* — a **🔍 Search results** entry shows up in the sidebar and aggregates matching rows from every category (grouped, with the source category as a heading). Toggle *Include description* to extend the search to the bilingual description text |
| **Edit Message of the Day** | *World Settings* → *Cosmetic / Chat* → first *MessageOfTheDay* group (multi-line `Message` + `Duration` in seconds) |
| **Import settings from another install** | *World Settings* → *Import settings from file* → pick a `Game.ini` or `GameUserSettings.ini`. Routing was corrected per ARK's actual behaviour in Phases 8b / 8M / 8S |
| **Edit launch flags** | *World Settings* → *Launch flags* — edits only the `-flag` portion of the profile's `MM_Command_Val` (URL / mods unchanged) |
| **Add / remove MODs** | *World Settings* → *Mods* — paste CurseForge Project IDs (one per line or comma-separated). Saved as `-mods=ID,ID,...` in the profile's `MM_Command_Val` |
| **Edit MOD-specific INI** | *World Settings* → *MOD configs* — only MODs that are both installed (via `-mods=`) and registered in the schema registry appear. Currently RTB ([see below](#mod-configs-category)) |
| **Discord / toast notifications** | *Setup* → *Notifications* → set webhook URL + event types → *Save* |
| **Switch UI language (EN ↔ JA)** | *Language* dropdown in the *Setup* section — **applies live** (no restart), retranslates every open window including the Server Status copy |
| **Share public address** | *Connection* under the *Profile* section — type a playit.gg tunnel / Tailscale name / public IP (press Enter to save), *Copy* puts it on the clipboard |
| **Backup / rollback** | *Profile* → *Backup / Rollback* ([see below](#backup--rollback)) |
| **Edit the raw launch line by hand** | Edit `MM_Command_Val=` in `<ARKSA_DIR>\Profile\<file_name>.ini` → *Refresh status* in the GUI |
| **Switch profile** | Dropdown in the *Profile* section — the selected profile's actual file path is shown right under it (`↳ File: …`) |
| **Refresh server status manually** | *Server status* → *Refresh status* (status is already polled every 5 s, so this is rarely needed) |

The status panel polls `server::status` every 5 s — PID / working-set memory / uptime refresh automatically. Whenever any action (Start / Stop / Restart / Install / RCON / Refresh-status) is in flight, the *Server control* section shows an **indeterminate progress bar + "Working…"** so the GUI never looks frozen.

## Notifications

The *Notifications* dialog persists settings to `<ARKSA_DIR>/AsaServerManegerWin.ini` (compatible with the upstream layout). Wired event triggers:

| Event | Fires when |
|---|---|
| `Server starting` | right after `server::start` returns a PID |
| `Server stopped` | after `stop_graceful` returns `GracefulRcon` or `GracefulWindowClose` |

Other events (Server online / Crash detected / Tool update / Server-app update) can be toggled in the dialog, but the corresponding detectors will be wired in by later phases.

## World Settings dialog

*World Settings* opens with a left sidebar + a right-pane editor. It edits the current profile's `Game.ini`, `GameUserSettings.ini` (including `[MessageOfTheDay]`), and `MM_Command_Val` (both `-mods=` and `-flag`). Picking a sidebar category swaps the form. **18 categories + 1 virtual search view**, ~280 fields total:

| Category | Highlights | Stored in |
|---|---|---|
| Rates | XP / Harvest / Taming / Mating / Hatch / Mature | `GameUserSettings.ini` |
| Day cycle | day-night scale, StartTimeHour | `GameUserSettings.ini` |
| Player | Food / Water / Stamina / Health / Damage / Resistance / oxygen-swim, disease toggles | `GameUserSettings.ini` (drain/regen/dmg) + `Game.ini` (harvesting dmg) |
| Tamed dino | drain / Damage / Resistance / AllowFlyingStaminaRecovery | `GameUserSettings.ini` |
| Wild dino | Food / Stamina / Torpor / Count, raid dinos | `Game.ini` (food/torpor) + `GameUserSettings.ini` (stamina/count/raid) |
| Difficulty / structure | DifficultyOffset, override, structure dmg/resist/repair, imprint flags | `GameUserSettings.ini` + `Game.ini` |
| PvE / PvP | serverPVE, AllowFlyerCarryPvE, EnableCryoSicknessPVE, DisableStructureDecayPvE, PreventOfflinePvP(+Interval), PvP/PvE-DinoDecay, PvEAllowStructuresAtSupplyDrops | `GameUserSettings.ini` |
| Ops | MaxTamedDinos, KickIdle, AutoSavePeriodMinutes, TheMaxStructuresInRange | `GameUserSettings.ini` |
| Breeding | MatingSpeed / LayEggInterval / PassiveTame, **BabyImprint\* / BabyCuddle\* (correctly routed to Game.ini in 8S)**, DisableBreeding/Taming, BabyFoodConsumption | `Game.ini` |
| Loot / Spoilage | **SupplyCrate / Fishing / CropDecay (correctly routed to Game.ini in 8S)**, CropGrowth, GlobalSpoiling/Decomposition/Corpse, ItemStackSize, MaxFallSpeed | `Game.ini` |
| Stat arrays | `PerLevelStatsMultiplier_*[0..11]` (Player / Tamed / Tamed-Add / Tamed-Affinity / Wild) + `PlayerBaseStatMultipliers[0..11]` — 6 × 12 = 72 cells | `Game.ini` |
| Combat / Structures | DinoHarvest/TurretDmg, speed-leveling, friendly fire, turret caps, structure pickup, Cryopod nerf (all 8 keys), **decay & extras (FastDecayUnsnapped, OnlyAutoDestroyCore, AutoDestroyDecayedDinos, OverrideStructurePlatformPrev, ExtraStructurePreventionVolumes, AllowMultipleAttachedC4, AllowCrateSpawnsOnTopOfStructures, PlatformSaddleBuildAreaBounds)** | `Game.ini` + `GameUserSettings.ini` |
| XP gain | Generic / Harvest / Kill / Craft / Special / ExplorerNote / BossKill / CaveKill / WildKill / TamedKill / UnclaimedKill / AlphaKill XP, OverrideMax* | `Game.ini` |
| Cosmetic / Chat | **MessageOfTheDay (Phase 8P, multi-line Text + Duration, `[MessageOfTheDay]` section)**, globalVoiceChat, ProximityChat, FloatingDamageText, ServerCrosshair, AllowThirdPerson, hitmarkers, gamma toggles, PreventSpawnAnimations, TribeLogDestroyedEnemyStructures, RCONServerGameLogBuffer, UseOptimizedHarvestingHealth | `GameUserSettings.ini` (`[ServerSettings]` + MOTD in `[MessageOfTheDay]`) |
| Cluster / Lists | ServerPassword, BanListURL, AdminListURL, BadWordList, CustomLiveTuning, transfer toggles, MaxPlayersInTribe, TribeNameChangeCooldown | `GameUserSettings.ini` |
| Clamps / Blueprints | MaxBlueprint(Dino\|Item\|Scout)*, MaxHexagons, ClampItemSpoiling/Stats, Implant CD, AutoForceRespawnInterval, DestroyTamesOverLevelClamp | `GameUserSettings.ini` + `Game.ini` |
| Launch flags | free-form text edit for things like `-log -NoBattlEye -EpicApp=ArkAscended …` — only touches the `-flag` portion of `MM_Command_Val` | profile `MM_Command_Val` |
| **Mods** | CurseForge Project IDs (one per line or comma-separated). On Save, normalised into a single `-mods=ID,ID,...` token. Empty input drops the token. Server auto-downloads from CurseForge on first start; clients auto-download on connect | profile `MM_Command_Val` |
| **MOD configs** | Per-MOD INI settings for schema-registered MODs (currently RTB). See [next section](#mod-configs-category) | per-MOD INI section (e.g. `[RTB]` in `GameUserSettings.ini`) |
| 🔍 *Search results* (virtual) | Only appears in the sidebar while the search box is non-empty. Aggregates all matching rows across categories into one list, grouped with source-category headings | (read-only — same as the source category) |

**Click-to-show bilingual description popups** — almost every parameter label has the **ⓘ** marker. Click the label and a short EN / JA blurb (matching the UI language) pops up **above** the label. Click outside to dismiss.

**Cross-category live search** — type any substring into the *Search:* box at the top of the dialog. The moment it becomes non-empty, a **🔍 Search results** category appears in the sidebar and the dialog auto-jumps to it. The right pane lists every row whose label contains the substring (case-insensitive), grouped by source category (in bold turquoise). Toggle *Include description* to extend the search to the description text — handy when you don't remember the exact key name (e.g. typing `imprint` surfaces every imprint-related row across Breeding / Difficulty / etc.).

### Workflow

- *New profile* — open the dialog before the first Start. Defaults (mostly 1.0) are shown because `Game.ini` doesn't exist yet. Tweak → **Save** → **Start**.
- *Existing profile* — current values from both INIs are loaded. Non-destructive edit: keys we don't model (e.g. `OverrideEngramEntries[…]`) are preserved on Save.
- *Import another install's settings* — **Import settings from file** → pick a `Game.ini` (or `GameUserSettings.ini`, or a hand-merged composite). Recognised keys flow into the form; nothing hits disk until you press **Save**.
- *Reset* — **Reset to defaults** snaps every field back to vanilla (multipliers to 1.0, bools to false). **Cancel** discards; **Save** persists.

ARK only re-reads these files at startup, so changes take effect on the next *Start*.

## MOD configs category

A dedicated **MOD configs** sidebar (Phase 14), separate from the regular 18 World Settings categories. The design priority is "don't mix MOD-specific INI sections with the regular settings":

- Of the MODs detected in the profile's `-mods=` list, **only those registered in the schema registry** are rendered as `GroupBox`es
- Removing a MOD from `-mods=` hides its `GroupBox` and makes Save skip its section entirely
- Re-enabling the MOD **restores the previous values** (the INI section was untouched while disabled)

### Currently supported MODs

| MOD | Project ID | INI file | Section | Main keys |
|---|---|---|---|---|
| **Return The Beacons (RTB)** | `933576` | `GameUserSettings.ini` | `[RTB]` | `EnableBeaconUI` (bool) / `PlayerBeamColor` (hex) / `DinoBeamColor` (hex) / `EnableGUIKeybind` (bool) / `EnablePauseMenuButton` (bool) |

To add a new MOD, append a `ModConfigSchema` constant to the `ALL_MODS` slice in `crates/arksa-core/src/mod_configs.rs`. The GUI builds the `GroupBox` for it automatically.

## Backup / rollback

Open the **Backup / Rollback** button under the *Profile* section. The sidebar has 3 categories:

- **Paths** — target profile / map name / SavedArks path / backup destination
- **Snapshot settings** — auto-backup ON/OFF, interval (T minutes), retain count (N), compression level, and the *Take backup now* button (manual snapshot)
- **Snapshot list** — 3 sub-tabs (**Auto / Manual / Pre-rollback**), with the time / size column headers clickable to toggle sort

### Storage location and kinds

The `<install>\ARKSA_Backups\<MapName>\` tree is split three ways (Phase 15):

```
ARKSA_Backups\<MapName>\
├── auto\                          periodic snapshots (ring buffer of N)
│   └── YYYYMMDD_HHMMSS.zip
├── manual\                        user-initiated snapshots (never auto-pruned)
│   └── YYYYMMDD_HHMMSS.zip
└── pre_rollback\                  emergency snapshots taken before a rollback (last 3 kept)
    └── from_<SRC>_to_<RB>.zip     SRC = source snapshot's created, RB = rollback time
```

- **Auto (auto/)** — taken by the scheduler; oldest entries auto-deleted by the ring buffer
- **Manual (manual/)** — taken by *Take backup now*; **never auto-deleted**. Use these as milestones — they stick around until you delete them explicitly
- **Pre-rollback (pre_rollback/)** — auto-taken when you start a rollback, max 3 kept. The filename embeds the **source snapshot's timestamp** so the GUI can show which rollback each emergency backup belongs to

None of this touches ARK's own `ShooterGame\Saved\` tree, so future engine reorganisations can't collide.

A legacy flat layout (`snapshot_<MapName>_<TS>.zip`) is auto-migrated into `auto/<TS>.zip` on the first list call — existing users don't need to do anything.

### What's in a snapshot

The entire `SavedArks\<MapName>\` directory is rolled into **one zip**: not just `.ark` (world save) but `<TribeID>.arktribe` (per-tribe), `<SteamID>.arkprofile` (per-player), `.arktribebak` / `.arkprofilebak` (timestamped backups), the engine's `.arkrbf` (rolling backup file — engine hardcodes 3), and `LocalProfiles\` — all of it. The `.ark` blob references tribe IDs and steam IDs from the other files, so the only safe rollback is a **time-consistent, all-files-together restore**. Per-file selection is deliberately not exposed.

### Retention policy

A **T-minute / N-count ring buffer**. Defaults: T=30 / N=12 (= 6 h history). **Only `auto/` is touched** — manual and pre_rollback have their own rules. Out-of-range numbers are clamped on both read and write so a corrupted INI can't either run the scheduler away or silence it.

### Compression level

Pick from four levels:

| Setting | Method | Speed (1 GB save, ballpark) | Output size |
|---|---|---|---|
| **None** | STORE | ~seconds (file-copy speed) | 100% (uncompressed) |
| **Fast (default)** | Deflate 1 | ~10 s | ~70% |
| **Balanced** | Deflate 6 | ~30 s | ~65% |
| **Max** | Deflate 9 | ~80 s | ~60% |

ARK's `.ark` files are already semi-compressed binary, so even Max only shaves 30–40%. Meanwhile Deflate 9 costs 5–10× the CPU of Deflate 1, so the default is Deflate 1. If you have disk headroom to spare, *None* delivers file-copy-speed snapshots that match a manual copy.

### Progress bar

While a snapshot or rollback is in flight, a **determinate progress bar with byte counter (`1.2 GiB / 4.8 GiB`)** is pinned at the bottom of the dialog (Phase 16). A rollback runs in two phases — "Saving emergency backup…" (`pre_rollback/` write) → "Restoring…" (zip extract) — with the message and bar reset between phases.

### Auto scheduler

Turn on *Take periodic snapshots* and the scheduler wakes 30 s after launch, then every 60 s. Each tick it checks the currently-selected profile and, if `auto_backup_enabled` is on and the newest `auto` snapshot is at least *interval* minutes old, takes one and runs retention. The **"last snapshot" timestamp comes from the newest `auto` zip on disk**, so the schedule survives tool restarts. Profile switches are followed automatically. Manual snapshots are **not** counted toward the schedule (to avoid mistaking a user-triggered backup for the latest periodic one).

### Rollback flow (in the UI)

1. Click **Roll back to this** on the row you want to restore → a yellow confirm strip appears at the top
2. **If the server is running, the strip warns + disables the button** — extracting over a live save would race the engine and corrupt the world
3. On confirm:
   1. Current `SavedArks\<MapName>\` is auto-saved into `pre_rollback\from_<SRC>_to_<RB>.zip` (progress bar shows "Saving emergency backup…")
   2. The chosen snapshot is extracted into a staging dir (progress bar switches to "Restoring…"), the old tree is renamed to `.replaced_<TS>`, the staging dir is atomically renamed into place, and the old tree is deleted (recoverable from `.replaced_*` if any step fails midway)
   3. List is refreshed
4. If you change your mind, roll back again from the *Pre-rollback* sub-tab (up to 3 generations back)

### "Related backup" badge (🔁)

Auto / manual rows that have a matching pre_rollback (i.e. someone rolled back **from** this snapshot at some point) show a `🔁 has pre-rollback backup` badge. Clicking the badge opens a blue detail strip with:

- the related pre_rollback's date / size / source snapshot's date
- a **Restore from this backup** button for one-click recovery

So "oops, I rolled back, undo that" is two clicks.

**Verified on a real server** — taking a snapshot while sleeping in a bed on Aberration, rolling back (character returns to the bed), then rolling back from the pre_rollback (character returns to the chair) — all three states preserved correctly.

## Connection info

The **Connection** row, right under the *Profile* section, is a LineEdit + Copy button. Paste whatever string your players need to use to connect — a playit.gg tunnel, Tailscale name, raw public IP, whatever.

- Press **Enter** to save into `[Server] Edit_PublicAddress` (compatible with the upstream INI schema)
- **Copy** writes it to the Windows clipboard (via `arboard`) — handy for sharing with friends
- Switching profiles swaps the field to that profile's value automatically

Direct playit-cli integration is deferred (environment-dependent), so the MVP is just "user types it in, one-click share".

## Connecting from an ARK SA client

ARK SA's *Unofficial* server browser is unreliable for new personal servers — they take 5–30 minutes to register, sometimes never. The dependable route is **direct IP**:

### Same machine (server + client)

1. Launch ARK Survival Ascended (client) from Steam
2. Open the console at the main menu (`~` or `` ` ``)
3. Type:
   ```
   open 127.0.0.1:7777
   ```

### LAN

Find the server PC's LAN IP (`ipconfig | findstr IPv4`); on a client machine:
```
open <server-LAN-ip>:7777
```

### Internet

Forward UDP `7777` and UDP `27015` to the server PC on your router. Open the same ports in Windows Firewall (admin PowerShell):
```powershell
New-NetFirewallRule -DisplayName "ARK SA Game"  -Direction Inbound -Protocol UDP -LocalPort 7777  -Action Allow
New-NetFirewallRule -DisplayName "ARK SA Query" -Direction Inbound -Protocol UDP -LocalPort 27015 -Action Allow
```
Connect with `open <public-ip>:7777`. **Never expose the RCON port (TCP 27020) to the internet.**

If you disable BattlEye on the server (the default `extra_flags` includes `-NoBattlEye`), each **client** has to pass the same flag in their Steam launch options:
```
-NoBattlEye
```
Otherwise BattlEye refuses to connect to a server that doesn't have it.

### Behind CGNAT or with no router access (playit.gg, Tailscale)

If you can't forward ports (mobile / dorm / shared connection, ISP CGNAT), two practical options exist. ARK SA is **UDP only**, so HTTP-based tunnels (Cloudflare Tunnel, ngrok free tier) are out.

**[playit.gg](https://playit.gg/)** — a game-server-focused reverse proxy (free tier). Install the agent on the server PC, create a UDP tunnel, share the assigned `host:port` with friends. Verified end-to-end: a friend on a different ISP joined a tunnel of the form `147.185.221.30:38080` with in-game `open 147.185.221.30:38080`. The agent can be stopped between sessions; the tunnel address stays bound to your account, so it's the same address the next day. RCON (TCP 27020) is deliberately not tunneled — admin commands go through the GUI's RCON panel locally on the server PC, or in-game from a connected client via `enablecheats <admin-password>` and then `saveworld` / `broadcast` / `kickplayer`.

**[Tailscale](https://tailscale.com/)** (or [ZeroTier](https://www.zerotier.com/)) — mesh VPN for a friends group. Install on the server PC and each player PC, share an invite link, then `open 100.x.y.z:7777` (tailnet IP). No router config, transparent to CGNAT, lower latency than a relay. Tailscale **Funnel** is HTTPS-only so it's not usable for ARK.
