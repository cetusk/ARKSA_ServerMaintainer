# Manifest pinning runbook — server / client version mismatch

When the ARK SA dedicated server is moved to a build that the players'
clients haven't received yet (e.g. server `v86.15` while clients are
still on `v86.11`), connection attempts hang on a black screen. Steam's
public branch always pulls the **latest** build, so the only reliable
fix is to install a **specific older manifest** of the dedicated server
that matches what the clients have.

`steamcmd` (which the GUI's *Install / Update server* button drives)
cannot pin to an arbitrary manifest. Use **DepotDownloader** as a
side-channel until manifest pinning is built into the GUI itself
(planned for Phase 9).

---

## 1. Symptoms that mean you need this runbook

- Joining via in-game console (`open <ip>:<port>`) gives a black screen
  that never advances to character select.
- The server's `ShooterGame.log` shows `Server has completed startup and
  is now advertising for join.` — i.e. the server itself is healthy.
- The Steam store page for *ARK: Survival Ascended* lists a client
  version different from what you see in `<install>/version.txt` of the
  server (or the build number printed on Steam's overlay when ARK is
  running).

If those three are true: the server is ahead of the client. Continue.

---

## 2. Prerequisites

- A real Steam account that owns ARK: Survival Ascended (anonymous
  downloads are blocked for ARK SA).
- Steam Guard / 2FA — DepotDownloader will prompt for the code at
  runtime.
- [DepotDownloader](https://github.com/SteamRE/DepotDownloader) —
  download the latest release zip and extract `DepotDownloader.exe`
  somewhere convenient (it's a self-contained .NET single-file binary,
  no install needed).

---

## 3. Choosing the manifest

Look up the ARK SA app in [SteamDB](https://steamdb.info/app/2430930/depots/),
open the *Depots* tab, and locate the dedicated-server depot's manifest
history. Each manifest entry is a `(manifest-id, build, timestamp)`
triple.

You want the **newest manifest whose build is ≤ the build your clients
have**. To find the client build, ask one of the players to open ARK,
then check the bottom-left of the main menu (it shows
`v<server>.<client>.<patch>`), or check `version.txt` in their game
install dir.

A known-good combination from May 2026:

| Server manifest | Server build | Compatible client build |
|---|---|---|
| **`684954496930236842`** | `v86.12` | `v86.11` |

Newer / older manifests can be substituted as long as the build matches.

---

## 4. The download command

Run from the directory containing `DepotDownloader.exe`:

```powershell
.\DepotDownloader.exe `
    -app 2430930 `
    -manifest 684954496930236842 `
    -username <your-steam-account-name> `
    -dir D:\ARK\ARKSA_Server
```

Notes:

- `-app 2430930` is the ARK SA Dedicated Server appid (same one
  steamcmd uses).
- `-manifest <id>` is the pinned manifest. Replace with whatever you
  picked in §3.
- `-username` is **required** — `-anonymous` returns HTTP 401 for ARK
  SA. DepotDownloader will prompt for password + 2FA on first run and
  cache a session token so subsequent runs only ask for the password
  if the session expires.
- `-dir <path>` is the output directory. Point it at the same
  `Install location` you set in the *New Profile* dialog so the
  ARKSA_ServerMaintainer GUI picks the install up automatically.
- DepotDownloader resolves `-app -manifest` to the right depot ID for
  you, so you don't normally need to pass `-depot`. If it errors with
  "must specify depot", look up the dedicated-server depot id on
  SteamDB (typically `2430931`) and add `-depot <id>`.

---

## 5. End-to-end procedure

1. **Stop the server** (GUI → *Stop (graceful)*).
2. **Optionally back up** `<install>\ShooterGame\Saved\` — the world
   saves live there and we don't want them touched. DepotDownloader
   only writes inside the same install dir but to game files, not
   `Saved\`. A backup is cheap insurance.
3. **Run the DepotDownloader command** above. First-run downloads ~13
   GB; subsequent re-pins of an adjacent manifest are a partial
   delta, much smaller.
4. Wait for `Total downloaded: …` and a clean exit. No error means
   success.
5. **Don't click *Install / Update server*** in the GUI again — that
   would re-pull the latest and undo the pin.
6. **Start the server** (GUI → *Start*).
7. **Verify with the client**: have a player connect via
   `open <server-ip>:<port>`. They should land at character creation
   instead of a black screen.

If the client still gets a black screen, you picked a manifest whose
build doesn't match the client. Try one manifest older.

---

## 6. Updating later

Steam **will** push another server build eventually. When it does, two
options:

1. **Stay pinned**: do nothing. The server keeps running v86.12
   forever. New ARK SA features that landed after v86.12 won't be
   available, but join compatibility is preserved as long as players
   don't update either.
2. **Update everyone together**: ask the players to update their ARK
   client first (in Steam → ARK Survival Ascended → right-click →
   Properties → Updates), then re-run DepotDownloader with the
   manifest matching the **new** client build. Or, if the new server
   build matches the new client build, just click *Install / Update
   server* in the GUI and let `steamcmd` go.

The DepotDownloader cache lives in `%APPDATA%\DepotDownloader\` — safe
to delete to force re-auth.

---

## 7. Why the GUI doesn't do this yet

`arksa-core::steamcmd` shells out to `steamcmd.exe app_update 2430930`
which has no manifest argument exposed by Valve's tooling. Pinning
requires either:

- shipping DepotDownloader alongside steamcmd (and switching the
  install path to use it), or
- driving `steamcmd` via `download_depot <appid> <depotid>
  <manifestid>` (a less-documented mode that requires a logged-in
  steamcmd session, not anonymous).

Phase 9 plans to add a `desired_manifest_id` field to `Profile` and a
DepotDownloader-backed install path so the GUI can do this without
the user having to drop to a shell.

---

## 8. Troubleshooting

| Symptom | Likely cause |
|---|---|
| `HTTP 401: Unauthorized` | Used `-anonymous`. Switch to `-username <account>`. |
| `Steam Guard required` prompt loops | 2FA code expired between attempts; re-run the same command, paste the latest code. |
| Manifest hash mismatch / "manifest not found" | The manifest id no longer exists (Valve sometimes prunes very old ones). Pick the next-older manifest from SteamDB. |
| Download stops at exactly N MB and hangs | Steam content servers are flaky — Ctrl-C and re-run; DepotDownloader resumes from the partial download. |
| Server starts but server browser still doesn't list it | Unrelated — that's the standing "Unofficial browser is unreliable" issue. Use `open <ip>:<port>` from the client. |
| Server starts but client gets `LoginFailed` instead of black screen | Different problem (BattlEye mismatch — ensure both server and client agree on `-NoBattlEye`). |
