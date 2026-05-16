# Troubleshooting

🌐 **English** | [日本語](./TROUBLESHOOTING.md)

This doc collects **known issues + workarounds** users might hit, plus the **compatibility / consistency adjustments baked into the code**. The latter are written with their motivation so future maintainers understand *why* each workaround exists.

## Contents

1. [Known issues](#known-issues)
2. [ARK SA quirks and workarounds](#ark-sa-quirks-and-workarounds)
3. [INI quirks](#ini-quirks)
4. [Slint quirks](#slint-quirks)
5. [ICU4X log spam](#icu4x-no-segmentation-model-for-language-ja-log-spam)

## Known issues

### 1. The server doesn't appear in the ARK SA Unofficial browser

Wildcard's matchmaking is slow / unreliable for small personal servers. **Workaround:** use the in-game console (`open <ip>:<port>`). See [the connection section in USAGE.en.md](./USAGE.en.md#connecting-from-an-ark-sa-client).

### 2. Inner labels of the NewProfileWindow are English-only

The *New Profile* dialog has many internal field labels (game port, query port, mods, etc.) that aren't wired up for i18n. Section titles, window titles and buttons are translated, but the form's inner field labels stay English regardless of the language setting. To be addressed incrementally.

### 3. No per-cell description popups on the stat-array tab

The 72 stat-array cells (Player / Tamed / Tamed-Add / Tamed-Affinity / Wild × Health / Stamina / … / CraftingSpeed) have self-explanatory labels (`[3] Oxygen` etc.), so click popups were skipped. About 80 of the most niche fields also have no description text yet — easy to add incrementally: one `description: root.lang-ja ? "JA" : "EN";` line per row in `main.slint`.

## ARK SA quirks and workarounds

### ARK SA's URL parser swallows the rest of the URL after certain characters

ARK SA's launch URL parser is brittle:

- `?ServerAdminPassword=` in the URL: the parser consumes **the entire rest of the URL** into the password value. RCON is silently disabled and every subsequent `?key=value` token is destroyed.
- A password starting with `-` (common with URL-safe Base64 alphabets): parsed as the start of a `-flag` argument, same swallowing behaviour.
- Whitespace in `SessionName`: Windows splits the command line at whitespace, so the value truncates at the first space.

Workarounds in `arksa-core::launch_args` and `ark_config`:

- `RCONEnabled` / `RCONPort` / `ServerAdminPassword` are **never** placed in the URL. They're written straight into `[ServerSettings]` of `GameUserSettings.ini` (Phase 5).
- `generate_password()` uses a purely alphanumeric alphabet — no `-` / `_` — and also skips visually-confusable characters (`0/O/I/l/1`). Length 16.
- The default `SessionName` is `ARKSAServer` (no spaces). Whitespace is still accepted via the file-based `[ServerSettings] SessionName=` field.
- The invariants are enforced by tests: `never_includes_server_admin_password_in_url`, `generated_password_never_starts_with_dash_or_underscore`, `default_session_name_has_no_whitespace`.

### `[ServerSettings]` vs `Game.ini` routing

ARK SA accepts multipliers in either INI for legacy compatibility, but **the engine actually reads only one of the two** (per ARK Wiki). The GUI's routing was corrected in three passes:

- **Phase 8b** (~20 keys) — `XPMultiplier`, `Player*Drain*`, `Dino*Drain*`, `DayCycleSpeedScale`, `Structure*Multiplier`, `DinoCountMultiplier` etc. moved from `Game.ini` to `GameUserSettings.ini [ServerSettings]`.
- **Phase 8M** *(reverted)* — moved 12 breeding / loot keys from `Game.ini` to GUS based on a user's real INI. **This was wrong** — these are documented as Game.ini keys, and live testing confirmed the engine ignores them in `[ServerSettings]` (Megalosaurus eggs hatched in 10 min instead of the expected 1 min with `EggHatchSpeedMultiplier=100`; cuddle interval stayed at the default 8 h even with `BabyCuddleIntervalMultiplier=0.00206`).
- **Phase 8S** (revert + cleanup) — moved 12 keys back to `Game.ini [/Script/ShooterGame.ShooterGameMode]`: `MatingIntervalMultiplier`, `EggHatchSpeedMultiplier`, `BabyMatureSpeedMultiplier`, `BabyFoodConsumptionSpeedMultiplier`, `BabyImprintAmountMultiplier`, `BabyImprintingStatScaleMultiplier`, `BabyCuddleIntervalMultiplier`, `BabyCuddleGracePeriodMultiplier`, `BabyCuddleLoseImprintQualitySpeedMultiplier`, `SupplyCrateLootQualityMultiplier`, `FishingLootQualityMultiplier`, `CropDecaySpeedMultiplier`. **Save also calls `IniDoc::remove_key` on the leftover `[ServerSettings]` entries** from the Phase 8M era so they can't conflict with the authoritative Game.ini values.

The other keys (`PlayerHarvestingDamageMultiplier`, `WildDinoCharacterFoodDrainMultiplier`, `WildDinoTorporDrainMultiplier`, `StructureDamageRepairCooldown`, `MatingSpeedMultiplier`, `LayEggIntervalMultiplier`, `PassiveTameIntervalMultiplier`, `CropGrowthSpeedMultiplier`, XP gain breakdown, stat arrays) were always in `Game.ini` and stayed there. Full routing table in [`parameters.md`](./parameters.md).

### ARK SA engine-side clamps on breeding multipliers (out of our control)

Even with correct routing, the ARK SA engine itself silently clamps some breeding multipliers. Live test results on Aberration:

- `EggHatchSpeedMultiplier` effectively caps at **10–30×** even when set to 100. Megalosaurus eggs (100-min base) bottom out at 5–10 min.
- `BabyCuddleIntervalMultiplier` has an effective **5–10-minute floor** — values like `0.00206` (theoretically ~1.7 min for Megalosaurus) get rounded up. If `BabyMatureSpeedMultiplier` is high enough for babies to mature in minutes, the first cuddle request may never fire before maturation.

Practical advice: keep `BabyMatureSpeedMultiplier` ≤ **30×** if imprint matters, and use `BabyImprintAmountMultiplier ≥ 100` so a single cuddle reaches 100%. The forum-guide combo of "60× mature + 0.001 cuddle interval + 100 imprint amount" **does not work on ASA** — it's an ASE convention.

### Server / client version mismatch (manifest pinning)

Steam's auto-updates can push the server ahead of clients (e.g. server v86.15 vs client v86.11 → black screen). The GUI's *Install / Update server* always pulls the latest via `steamcmd`, so pinning to an older build goes through a different route. Workaround: [DepotDownloader](https://github.com/SteamRE/DepotDownloader) with a specific manifest. Verified combo: DepotDownloader manifest **`684954496930236842`** (server build v86.12) connects cleanly from client build v86.11.

Full runbook (auth setup, command flags, picking manifests off SteamDB, troubleshooting table) lives in [`manifest-pinning.md`](./manifest-pinning.md). Phase 9 plans to expose manifest as a per-profile setting so it's a GUI checkbox instead of a separate command-line workflow.

### ARK URL parser corrupted `ServerAdminPassword` (resolved in Phase 5)

Earlier versions required users to hand-edit `GameUserSettings.ini` — ARK SA's URL parser merged the rest of the launch URL into the admin password value. Phase 5's `arksa-core::ark_config` writes `RCONEnabled` / `RCONPort` / `ServerAdminPassword` straight into `GameUserSettings.ini`, and the launch URL no longer carries them. Profiles created via *New…* are immediately RCON-ready.

## INI quirks

### Backslash escaping in INI (round-trip of `D:\ARK\…`)

`rust-ini`'s default `EscapePolicy` writes `Edit_Install_Location_Val=D:\\ARK\\ARKSA_Server` (double-escaped). Our load side (Lazarus `TIniFile`-compatible: `enabled_escape: false`) reads back `\\` literally as two characters, producing a broken Windows path that doesn't match the actual filesystem. Fix: `arksa-core::ini_doc` sets `EscapePolicy::Nothing` on write. Regression test: `windows_paths_round_trip_without_double_escaping`.

### Lazarus `TIniFile` quirks (boolean / float representation + SHIFT_JIS)

The upstream profiles are written by Lazarus, which uses the OS ANSI codepage (CP932 / SHIFT_JIS on Japanese Windows), writes booleans as `0/1`, and uses `.` as the decimal separator regardless of locale. Our `IniDoc`:

- Tries UTF-8 first (with BOM detection), then falls back to SHIFT_JIS — existing `.ini` files load cleanly.
- Writes booleans as `0`/`1` for compatibility, except in `GameUserSettings.ini`'s `[ServerSettings]` where we use `True`/`False` (matching ARK's own output).
- Writes floats via `format!("{value:?}")` so `1.0` stays `1.0` (not `1`) and no locale-dependent comma sneaks in.
- Reads accept both `0/1` and `True/False` (case-insensitive).

## Slint quirks

### Slint component initialisation overflows Windows' default stack

The World Settings window declares ~250 properties, 17 conditional content panes, and 6 stat-array `GroupBox`es. Slint emits a lot of static initialisation per component, which overflows the default 1 MiB main-thread stack on Windows during construction (`STATUS_STACK_OVERFLOW = 0xC00000FD`). Fixed by reserving 8 MiB in `.cargo/config.toml` (`x86_64-pc-windows-msvc` / `-gnu` / `i686-pc-windows-msvc`).

### Slint 1.16 `visible: false` doesn't release layout space for `inherits HorizontalBox` children (worked around in Phase 8U)

When the World Settings search filter hid non-matching rows, setting `visible: false` on `WorldFloatRow` / `WorldBoolRow` (which inherited `HorizontalBox`) left the parent `VerticalBox` reserving their layout space — search results showed big gaps where the hidden rows would have been (visible when searching `cryo`, for instance). The behaviour is intrinsic to Slint 1.16: the `visible` property on components built via `inherits HorizontalBox` doesn't propagate down to the layout container.

Workaround: switch from `inherits HorizontalBox` to **`inherits Rectangle`** with an inner HorizontalBox, then collapse the outer rectangle to zero height via `height: show ? row.preferred-height : 0px` (`clip: true` defensively). Hidden rows now occupy zero height and the visible ones pack together as expected.

### Unicode glyphs missing from Slint's default font (`↻` / `↺` etc.)

Slint on Windows uses Segoe UI by default, but the fallback chain doesn't always render U+21BA / U+21BB arrows (in Phase 16 the refresh button rendered as a blank button when set to `↻`). Reliable alternatives:

- **Emoji glyphs** (U+1F500 range) — `🔄` (refresh), `🔁` (repeat), `🔍` (search) etc. render via Segoe UI Emoji.
- **Plain text + no icon** — when in doubt, fall back to a text label (e.g. `Refresh`).

## ICU4X "No segmentation model for language: ja" log spam

Slint's text layout calls ICU4X to compute line-break positions, and the bundled ICU4X data only ships Western locales — so each piece of Japanese text emits `ICU4X data error: No segmentation model for language: ja` before falling back to char-wrap (fine for Japanese, which doesn't space-separate words). The message itself is harmless but drowns useful output.

Defence in two layers:

1. **`tracing` filter** (`EnvFilter` default) suppresses `icu_segmenter` / `icu_provider` / Slint warnings if they arrive via `log` / `tracing` (the `tracing-subscriber` default `tracing-log` feature bridges — calling `LogTracer::init()` on top of it panics with `SetLoggerError`, so don't).
2. **Win32 stderr redirect**. The ICU4X warnings actually bypass `log` and go straight to stderr via `eprintln!`, so the filter alone can't catch them. At startup the process's `STD_ERROR_HANDLE` is swapped to `NUL` (skipped when `RUST_LOG` is set — devs want the output).

To see everything (bypass both filters), set `RUST_LOG=info`.
