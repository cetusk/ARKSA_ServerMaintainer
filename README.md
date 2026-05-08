# ARKSA_ServerMaintainer

🌐 [English](./README.en.md) | **日本語**

Windows 上で **ARK: Survival Ascended** の個人用専用サーバーを運用するための Rust + Slint 製 GUI ツール。

[ASA Server Manager (ASASM)](https://sites.google.com/view/asa-server-manager) (作者: *Dの人*) の **個人用リワーク**。原作者がフォーク・他言語移植を明示的に許可しています。原作の Object Pascal ソースは本リポジトリに同梱していません — クロスリファレンスが必要であれば原作配布物から入手してください。

> **ステータス: Phase 8a〜8T — プロファイルごとに約 280 項目のワールドエディタ (MOD / MOTD 含む) + 全カテゴリ横断ライブ検索 + ターコイズ × ダークモード + メイン画面言語ピッカー。**
> プロファイル作成・初回起動で RCON が動くよう `GameUserSettings.ini` を自動生成・同梱 steamcmd でのサーバーインストール・起動 / 停止 / 再起動・RCON コマンド送信・Mod / エングラム / アイテム / 恐竜検索・Discord & Windows トースト通知・**メイン画面から直接** の英日言語切替・**~280 項目のパラメーター編集** (世界 / 繁殖 / 戦利品 / ステータス配列 / 戦闘 / XP / チャット / クラスタ / 上限 / PvP-decay / 病気 / Cryopod / 起動フラグ / Mod リスト / MOTD) を `Game.ini` + `GameUserSettings.ini` (`[ServerSettings]` と `[MessageOfTheDay]`) + プロファイルの `MM_Command_Val` (URL + `-mods=` + `-flags`) に渡って **左サイドバー / 右ペインエディタ (18 カテゴリ + 仮想 *検索結果* ビュー)** で操作可能。各パラメーターはラベルクリックで英日説明ポップアップが出ます。
> **ARK SA クライアントの実機接続済み** (in-game `open <ip>:<port>`)、CGNAT 配下の友人とは [playit.gg](https://playit.gg/) UDP トンネル経由でテスト済み。MOD は CurseForge から自動 DL。
> CLI 版 (Phase 9)、自動アップデーター、バックアップ、定期再起動は未実装。
> 全フェーズの計画は [`docs/architecture.md`](./docs/architecture.md)、ARK SA パラメーターリファレンスは [`docs/parameters.md`](./docs/parameters.md)。

---

## 目次
1. [目的と非目的](#目的と非目的)
2. [アーキテクチャ概観](#アーキテクチャ概観)
3. [ビルド前提](#ビルド前提)
4. [クイックスタート](#クイックスタート)
5. [推奨ディスクレイアウト](#推奨ディスクレイアウト)
6. [日常運用](#日常運用)
7. [ARK SA クライアントから接続する](#ark-sa-クライアントから接続する)
8. [互換性 / 整合性対応](#互換性--整合性対応)
9. [既知の問題と回避策](#既知の問題と回避策)
10. [ロードマップ](#ロードマップ)
11. [ライセンス](#ライセンス)

---

## 目的と非目的

**目的**
- メモリ安全な Win32 API アクセス → **Rust**
- ネイティブ感のあるデスクトップ GUI → **Slint**
- 個人用の単一専用サーバー — マルチサーバー運用は対象外
- 英語第一 + 日本語ロケール (Phase 7)

**非目的**
- マルチサーバー艦隊運用 (原作の ARKestra UI は意図的に未移植)
- Linux / macOS サポート — Windows 専用

## アーキテクチャ概観

```
ARKSA_ServerMaintainer/
├── Cargo.toml              # ワークスペース
├── rust-toolchain.toml
├── assets/                 # ModList / EngramData / ItemData / DinoData / List
├── crates/
│   ├── arksa-core/         # lib: サーバーライフサイクル / RCON / Win32 プロセス監視 /
│   │                       #      INI / Mod データ / steamcmd ラッパー
│   ├── arksa-notify/       # lib: Discord webhook + tray (Phase 6)
│   ├── arksa-gui/          # bin: メイン GUI (Slint)
│   ├── arksa-updater/      # bin: 自動更新 (Phase 9)
│   ├── arksa-commander/    # bin: CLI コマンド送信 (Phase 8)
│   └── arksa-nbcall/       # bin: ConPTY 子プロセスランナー
└── docs/architecture.md    # crate 責務 + .pas → Rust 対応表
```

## ビルド前提

- **Rust** stable (`rustup default stable`)
- **MSVC ツールチェイン** (`x86_64-pc-windows-msvc`) — Windows 上では `rustup` の既定
- **Visual Studio 2022 Build Tools** (Desktop development with C++ ワークロード — `link.exe` を提供):
  ```powershell
  winget install --id Microsoft.VisualStudio.2022.BuildTools `
    --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
  ```
  インストール後は **PowerShell を再起動** して PATH を反映。`where.exe link` で確認できます。

初回 `cargo build` で約 300 個の crate (Slint / `windows` / ソフトウェアレンダラ等) が DL されます — コールドキャッシュで 5〜10 分。

> **リンカースタックの注記**: `.cargo/config.toml` で Windows バイナリの予約スタックを 8 MiB に拡張しています。World Settings ウィンドウの初期化 (約 250 プロパティ / 17 カテゴリ / 6 ステータス配列 GroupBox) が Slint コンポーネント構築時に既定の 1 MiB メインスレッドスタックを溢れさせる (`STATUS_STACK_OVERFLOW = 0xC00000FD`) ため。`x86_64-pc-windows-msvc` / `-gnu` / `i686-pc-windows-msvc` で有効化済み。

## クイックスタート

### 1. ツールデータ用フォルダを決める (or 作成)

ツールはプロファイル / 同梱 `steamcmd` / ログを `ARKSA_DIR` 環境変数で示すフォルダに保存します。**これは ARK 専用サーバーのインストール先とは別物** で、インストール先はプロファイルごとに GUI 内で設定します。

```powershell
mkdir D:\ARK\ARKSA_Tools -Force
```

### 2. テンプレートから `run.ps1` を作成

```powershell
cd <repo-root>
copy run.example.ps1 run.ps1
notepad run.ps1
```

以下の行を編集:
```powershell
$env:ARKSA_DIR = "D:\ARK\ARKSA_Tools"
```

`run.ps1` は gitignore 済みなので個人パスがリポジトリに混入しません。

### 3. GUI 起動

いずれかの方法で:
```powershell
.\run.ps1            # PowerShell プロンプトから
```
または `run.bat` をエクスプローラからダブルクリック (`-ExecutionPolicy Bypass` 付きで `run.ps1` を呼ぶので、初期 Windows でも `Set-ExecutionPolicy` 不要)。

GUI は空状態で起動 (まだプロファイルがないため)。

### 4. プロファイル作成

**最初のサーバーを作成** をクリック。ダイアログで **既定値から変更が必須** なフィールドは:

| フィールド | 設定値 |
|---|---|
| **Install location** | ARK SA をインストールしたい絶対パス (例: `D:\ARK\ARKSA_Server`) |
| **Use path relative to ARKSA dir** | **チェックを外す** |

それ以外 (ファイル名、map = `TheIsland_WP`、ポート、最大プレイヤー数、自動生成された admin password) は既定で OK。**Create** をクリック。

> プロファイル INI は `<ARKSA_DIR>\Profile\<file_name>.ini` に書かれます。

### 5. 専用サーバーをインストール

メインウィンドウに戻り、**Install / Update server** をクリック。同梱 steamcmd が自分自身を DL し (初回約 3 MB)、続いて ARK SA Dedicated Server を DL します (約 13 GB)。Log パネルに進捗が流れ、以下が出れば完了:
```
Success! App '2430930' fully installed.
steamcmd exited with code 0.
```

### 6. 起動

GUI で **Start** をクリック。Log パネルに `Server started (PID …).` と表示され、Status パネルが 5 秒ごとに更新されます (`Running`、メモリ、稼働時間)。

初回起動は 30〜60 秒かかります (TheIsland のロード)。クライアント受付準備が整ったかを確認するには ARK 自身のログを tail:
```powershell
Get-Content "D:\ARK\ARKSA_Server\ShooterGame\Saved\Logs\ShooterGame.log" -Wait -Tail 10
```
`Server has completed startup and is now advertising for join.` が出るまで待つ。

### 7. RCON テスト

GUI の RCON 入力欄に `ListPlayers` と入れて **Send**。Log に `No Players Connected` (またはプレイヤー名一覧) が出れば、RCON は配線済み。

> Phase 5 がこれを自動配線: `Profile::create_new` が `RCONEnabled=True` / `RCONPort=…` / `ServerAdminPassword=…` を `GameUserSettings.ini` (インストールルート配下) に直接書き込みます。以前必要だった手編集ステップは不要に。

## 推奨ディスクレイアウト

上記手順を踏むとディスクは:

```
D:\ARK\
├── ARKSA_Tools\                              ← ARKSA_DIR (数十 MB)
│   ├── Profile\
│   │   └── MyServer.ini                       サーバーごとの設定
│   └── steamcmd\
│       └── steamcmd.exe                       ツール同梱
└── ARKSA_Server\                             ← Install location (数十 GB)
    └── ShooterGame\
        ├── Binaries\Win64\
        │   └── ArkAscendedServer.exe
        ├── Content\                           ゲームアセット
        └── Saved\
            ├── SavedArks\                     ワールドセーブ
            ├── Config\WindowsServer\
            │   ├── GameUserSettings.ini       RCON 等の権威ファイル
            │   └── Game.ini
            └── Logs\
                └── ShooterGame.log            リアルタイムサーバーログ
```

`ARKSA_DIR` 未設定時は `arksa-gui.exe` のあるディレクトリにフォールバック。配布バイナリではこれで十分ですが、`cargo run` だと `target\debug\` に解決されるので注意。

## 日常運用

ボタンラベルは省略表示なし (`…` を使わずフルネーム表示)。各機能はターコイズヘッダの `SectionGroup` にグルーピング (Setup / Profile / Server status / Server control / RCON / Log)。

| 操作 | 場所 |
|---|---|
| **起動** | *Server control* → *Start* |
| **停止 (graceful)** | *Server control* → *Stop (graceful)* — RCON 経由で `SaveWorld` + `DoExit`、RCON 不通なら `WM_CLOSE` にフォールバック |
| **再起動** | *Server control* → *Restart server* — *Stop (graceful)* → 2 秒待機 → *Start*、各遷移で通知 |
| **ゲームバージョン更新** | *Server control* → *Install / Update server* (steamcmd 再実行、既存ファイルは保持) |
| **任意 RCON コマンド** | *RCON* セクションに入力 → *Send* |
| **Mod / Engram / Item / Dino 検索** | *Setup* → *Find data* → カテゴリと部分文字列を選択 → 名前 + class/ID 表示 |
| **ワールド / 難易度パラメーター編集** | *Profile* → *World Settings* → 左サイドバーでカテゴリ選択 → 値入力 → *Save* (次回 Start で反映) |
| **パラメーターの意味を見る** | *World Settings* でラベルクリック (**ⓘ** マーカーが目印) — ラベル直上に英日説明ポップアップ |
| **全カテゴリ横断でパラメーター検索** | *World Settings* 上部の *Search:* ボックスに入力 — サイドバーに **🔍 Search results** が出現し、全カテゴリのマッチ行が 1 リストに表示 (各グループにカテゴリ名見出し)。*Include description* でバイリンガル説明文も検索対象に |
| **Message of the Day 編集** | *World Settings* → *Cosmetic / Chat* → 先頭の *MessageOfTheDay* グループ (複数行 `Message` + `Duration` 秒) |
| **別インストールの設定を流用** | *World Settings* → *Import settings from file* → `Game.ini` か `GameUserSettings.ini` を選択。Phase 8b / 8M / 8S で読み出し routing を ARK の実挙動に合わせて補正済み |
| **起動フラグ編集** | *World Settings* → *Launch flags* — プロファイルの `MM_Command_Val` の `-flag` 部分のみ編集 (URL / mods は不変) |
| **MOD 追加 / 削除** | *World Settings* → *Mods* — CurseForge Project ID を 1 行 1 つ、またはカンマ区切りで貼り付け。プロファイルの `MM_Command_Val` に `-mods=ID,ID,...` として保存。サーバー初回起動時に CurseForge から自動 DL、クライアントは接続時に自動 DL |
| **Discord / トースト通知** | *Setup* → *Notifications* → webhook URL とイベント種別を設定 → *Save* |
| **UI 言語切替 (英 ↔ 日)** | *Setup* セクションの *Language* ドロップダウン — 永続化は即時、表示反映は再起動後 |
| **生の launch line を直接編集** | `<ARKSA_DIR>\Profile\<file_name>.ini` の `MM_Command_Val=` を編集 → GUI で *Refresh status* |
| **プロファイル切替** | *Profile* セクションのドロップダウン — ドロップダウン下に選択中プロファイルの実ファイルパス (`↳ File: …`) が表示 |
| **サーバーステータス手動更新** | *Server status* → *Refresh status* (5 秒ごとに自動 poll もしているので通常は不要) |

ステータスパネルは `server::status` を 5 秒ごとに poll — PID / ワーキングセットメモリ / 稼働時間が自動更新されます。

### 通知設定

*Notifications* ダイアログは設定を `<ARKSA_DIR>/AsaServerManegerWin.ini` に永続化 (原作レイアウトと互換)。配線済みイベントトリガー:

| イベント | 発火タイミング |
|---|---|
| `Server starting` | `server::start` が PID を返した直後 |
| `Server stopped` | `stop_graceful` が `GracefulRcon` または `GracefulWindowClose` を返した後 |

その他のイベント (Server online / Crash detected / Tool update / Server-app update) はダイアログで有効化可能ですが、対応する検出器が将来 Phase で実装され次第 payload を送るようになります。

### World Settings ダイアログ

*World Settings* は左サイドバー / 右ペインエディタを開きます。編集対象は現在のプロファイルの `Game.ini`、`GameUserSettings.ini` (`[MessageOfTheDay]` 含む)、および `MM_Command_Val` (`-mods=` と `-flag` の両方)。サイドバーでカテゴリを選択するとフォームが切り替わります。**18 カテゴリ + 1 仮想検索ビュー** で計約 280 項目:

| カテゴリ | 主な項目 | 保存先 |
|---|---|---|
| Rates | XP / Harvest / Taming / Mating / Hatch / Mature | `GameUserSettings.ini` |
| Day cycle | 昼夜スケール、StartTimeHour | `GameUserSettings.ini` |
| Player | Food / Water / Stamina / Health / Damage / Resistance / 酸素水泳、病気トグル | `GameUserSettings.ini` (drain/regen/dmg) + `Game.ini` (採取 dmg) |
| Tamed dino | drain / Damage / Resistance / AllowFlyingStaminaRecovery | `GameUserSettings.ini` |
| Wild dino | Food / Stamina / Torpor / Count、Raid 系恐竜 | `Game.ini` (food/torpor) + `GameUserSettings.ini` (stamina/count/raid) |
| Difficulty / structure | DifficultyOffset、Override、structure dmg/resist/repair、刷り込みフラグ | `GameUserSettings.ini` + `Game.ini` |
| PvE / PvP | serverPVE、AllowFlyerCarryPvE、EnableCryoSicknessPVE、DisableStructureDecayPvE、PreventOfflinePvP(+Interval)、PvP/PvE-DinoDecay、PvEAllowStructuresAtSupplyDrops | `GameUserSettings.ini` |
| Ops | MaxTamedDinos、KickIdle、AutoSavePeriodMinutes、TheMaxStructuresInRange | `GameUserSettings.ini` |
| Breeding | MatingSpeed / LayEggInterval / PassiveTame、**BabyImprint\* / BabyCuddle\* (8S で Game.ini に正しく routing)**、DisableBreeding/Taming、BabyFoodConsumption | `Game.ini` |
| Loot / Spoilage | **SupplyCrate / Fishing / CropDecay (8S で Game.ini に正しく routing)**、CropGrowth、GlobalSpoiling/Decomposition/Corpse、ItemStackSize、MaxFallSpeed | `Game.ini` |
| Stat arrays | `PerLevelStatsMultiplier_*[0..11]` (Player / Tamed / Tamed-Add / Tamed-Affinity / Wild) + `PlayerBaseStatMultipliers[0..11]` — 6 × 12 = 72 セル | `Game.ini` |
| Combat / Structures | DinoHarvest/TurretDmg、Speed-leveling、friendly fire、turret 上限、structure pickup、Cryopod nerf (全 8 キー)、**腐敗 & 追加 (FastDecayUnsnapped、OnlyAutoDestroyCore、AutoDestroyDecayedDinos、OverrideStructurePlatformPrev、ExtraStructurePreventionVolumes、AllowMultipleAttachedC4、AllowCrateSpawnsOnTopOfStructures、PlatformSaddleBuildAreaBounds)** | `Game.ini` + `GameUserSettings.ini` |
| XP gain | Generic / Harvest / Kill / Craft / Special / ExplorerNote / BossKill / CaveKill / WildKill / TamedKill / UnclaimedKill / AlphaKill XP、OverrideMax* | `Game.ini` |
| Cosmetic / Chat | **MessageOfTheDay (Phase 8P、複数行 Text + Duration、`[MessageOfTheDay]` セクション)**、globalVoiceChat、ProximityChat、FloatingDamageText、ServerCrosshair、AllowThirdPerson、ヒットマーカー、ガンマトグル、PreventSpawnAnimations、TribeLogDestroyedEnemyStructures、RCONServerGameLogBuffer、UseOptimizedHarvestingHealth | `GameUserSettings.ini` (`[ServerSettings]` + MOTD は `[MessageOfTheDay]`) |
| Cluster / Lists | ServerPassword、BanListURL、AdminListURL、BadWordList、CustomLiveTuning、転送系トグル、MaxPlayersInTribe、TribeNameChangeCooldown | `GameUserSettings.ini` |
| Clamps / Blueprints | MaxBlueprint(Dino\|Item\|Scout)*、MaxHexagons、ClampItemSpoiling/Stats、Implant CD、AutoForceRespawnInterval、DestroyTamesOverLevelClamp | `GameUserSettings.ini` + `Game.ini` |
| Launch flags | `-log -NoBattlEye -EpicApp=ArkAscended …` 等の自由形式テキスト編集 — `MM_Command_Val` の `-flag` 部分のみ操作 | プロファイル `MM_Command_Val` |
| **Mods** | CurseForge Project ID (1 行 1 つ or カンマ区切り)。Save 時に `-mods=ID,ID,...` 1 トークンに正規化。空入力でトークン削除。サーバー初回起動時に CurseForge から自動 DL、クライアントは接続時に自動 DL | プロファイル `MM_Command_Val` |
| 🔍 *Search results* (仮想) | 検索ボックス入力中のみサイドバーに出現。全カテゴリのマッチ行を 1 リストに集約、各グループにソースカテゴリ名見出し付き | (読み出しのみ — 元カテゴリと同じ) |

**英日クリックポップアップ説明** — ほぼ全パラメーターラベルに **ⓘ** マーカー付き。ラベルクリックで英日 (UI 言語と連動) の短い説明がラベル**直上**にポップアップ。外側クリックで閉じる。

**全カテゴリ横断ライブ検索** — ダイアログ上部の *Search:* ボックスに任意の部分文字列を入力。空でなくなった瞬間にサイドバーに **🔍 Search results** カテゴリが出現し、ダイアログは自動でそこへ移動します。右ペインにはラベルが部分一致 (大文字小文字無視) する行のみがソースカテゴリ名 (ターコイズ太字) でグループ化されて表示。検索ボックス横の *Include description* をオンにすると説明文も検索対象に — キー名を覚えていない時に便利 (例: `imprint` と打てば Breeding / Difficulty 等にまたがる刷り込み関連行が一覧)。

**ワークフロー**

- *新規プロファイル* — 最初の Start 前にダイアログを開く。Game.ini がまだ存在しないため既定値 (大半 1.0) が表示される。任意調整 → **Save** → **Start**。
- *既存プロファイル* — 両 INI の現在値を読み込み。非破壊編集 — モデル化していないキー (例: `OverrideEngramEntries[…]`) は Save 時に保持される。
- *別インストールの設定を流用* — **Import settings from file** → `Game.ini` (または `GameUserSettings.ini`、または手動マージした統合 INI) を選択。認識されたキーはフォームに流れ込み、**Save** を押すまでファイルには書かれない。
- *リセット* — **Reset to defaults** で全フィールドが vanilla 値 (multiplier は 1.0、bool は false) に戻る。**Cancel** で破棄、**Save** で永続化。

ARK は起動時にしかこれらのファイルを再読込しないので、変更は次回の *Start* で反映されます。

## ARK SA クライアントから接続する

ARK SA の *Unofficial* サーバーブラウザは新規個人サーバーに対して不安定です — 5〜30 分かけて登録される、または永久に出ない場合あり。確実なルートは **IP 直接接続**:

### 同一マシン (サーバー + クライアント)
1. Steam から ARK Survival Ascended (クライアント) を起動
2. メインメニューでコンソールを開く (`~` または `` ` ``)
3. 入力:
   ```
   open 127.0.0.1:7777
   ```

### LAN
サーバー PC の LAN IP を確認 (`ipconfig | findstr IPv4`)、クライアントマシンで:
```
open <server-LAN-ip>:7777
```

### インターネット
ルーターで UDP `7777` と UDP `27015` をサーバー PC に転送。Windows ファイアウォールでも同じポートを開ける (管理者 PowerShell):
```powershell
New-NetFirewallRule -DisplayName "ARK SA Game"  -Direction Inbound -Protocol UDP -LocalPort 7777  -Action Allow
New-NetFirewallRule -DisplayName "ARK SA Query" -Direction Inbound -Protocol UDP -LocalPort 27015 -Action Allow
```
`open <public-ip>:7777` で接続。**RCON ポート (TCP 27020) は絶対に公開しないこと**。

サーバーで BattlEye を無効化している場合 (既定の `extra_flags` に `-NoBattlEye` 入り) は、**クライアント側** の Steam 起動オプションにも同フラグが必要:
```
-NoBattlEye
```
さもなくば BattlEye 不在のサーバーへの接続を拒否されます。

### CGNAT 配下 / ルーターアクセス不可 (playit.gg、Tailscale)

ルーターのポート転送が出来ない (モバイル / 寮 / シェア回線、ISP が CGNAT) 場合の選択肢が 2 つあります。ARK SA は **UDP 専用** なので HTTP ベースのトンネル (Cloudflare Tunnel、ngrok 無料版) は使えません。

**[playit.gg](https://playit.gg/)** — ゲームサーバー特化のリバースプロキシ (無料枠あり)。サーバー PC に agent をインストール、UDP トンネルを作成、割り当てられた `host:port` を友人と共有。実機確認済み: 別 ISP の友人が `147.185.221.30:38080` のようなトンネル宛てに in-game `open 147.185.221.30:38080` で参加成功。agent プロセスはセッション間で停止可能、トンネルアドレスはアカウントに紐付き保持されるため翌日も同じアドレスが使えます。RCON (TCP 27020) は意図的にトンネル化しない — admin コマンドはサーバー PC の GUI RCON パネルからローカル送信、または接続中のクライアントから in-game `enablecheats <admin-password>` 経由で `saveworld` / `broadcast` / `kickplayer` 等が実行できます。

**[Tailscale](https://tailscale.com/)** (または [ZeroTier](https://www.zerotier.com/)) — 友人グループ向けメッシュ VPN。サーバー PC と各プレイヤー PC にインストール、招待リンク共有、`open 100.x.y.z:7777` (tailnet IP) で接続。ルーター設定不要、CGNAT 透過、リレー経由より低レイテンシ。Tailscale **Funnel** は HTTPS 専用なので ARK では使えません。

詳細手順は [`docs/manifest-pinning.md`](./docs/manifest-pinning.md) と同じノリで `docs/public-access.md` に書き起こす予定です。

## 互換性 / 整合性対応

原作 ASASM とのパリティ達成と動く ARK SA サーバーをデプロイする過程で発見された癖の集積。各項目はコードが暗黙裏に対処してくれているもので、将来のメンテナーが**なぜその回避策が入っているか**を分かるよう書いてあります。

### ARK SA URL パーサーが特殊文字以降の URL を飲み込む
ARK SA の起動 URL パーサーは脆い:

- `?ServerAdminPassword=` を URL に置く: パーサーが**URL の残り全部**をパスワード値に取り込み、RCON が黙って無効化、後続の `?key=value` トークンも全部破壊。
- パスワードが `-` で始まる (URL-safe Base64 アルファベットでよくある): `-flag` 引数の開始と解釈され、同じ呑み込み挙動。
- `SessionName` に空白を含む: Windows がコマンドラインを空白で分割するため、最初の空白で truncate。

`arksa-core::launch_args` と `ark_config` での回避策:

- `RCONEnabled` / `RCONPort` / `ServerAdminPassword` は **絶対に URL に置かない**。代わりに `[ServerSettings]` of `GameUserSettings.ini` に直接書き込み (Phase 5)。
- `generate_password()` は純粋英数字アルファベット — `-` / `_` なし — を使用、視覚的に紛らわしい文字 (`0/O/I/l/1`) もスキップ。長さ 16。
- 既定 `SessionName` は `ARKSAServer` (空白なし)。空白は依然 ARK が `[ServerSettings] SessionName=` のファイルベース指定で受け付けます。
- 不変条件はテストで強制: `never_includes_server_admin_password_in_url`、`generated_password_never_starts_with_dash_or_underscore`、`default_session_name_has_no_whitespace`。

### `[ServerSettings]` vs `Game.ini` ルーティング
ARK SA は legacy 互換でどちらの INI でも multiplier を受け付けますが、**実際にエンジンが読むのはどちらか一方** (ARK Wiki ベース)。GUI のルーティングは 3 段階で補正:

- **Phase 8b** (約 20 キー) — `XPMultiplier`、`Player*Drain*`、`Dino*Drain*`、`DayCycleSpeedScale`、`Structure*Multiplier`、`DinoCountMultiplier` 等が以前 `Game.ini` に書かれていたのを `GameUserSettings.ini [ServerSettings]` へ。
- **Phase 8M** *(撤回)* — ユーザー実機 INI を根拠に 12 個の繁殖 / 戦利品キーを Game.ini → GUS に移動。**これは誤り** — これらは Game.ini キーとして文書化されており、実機テストでエンジンが `[ServerSettings]` 配置時は無視することが確認された (メガロサウルス卵が `EggHatchSpeedMultiplier=100` で期待 1 分のはず 10 分、cuddle 間隔が `BabyCuddleIntervalMultiplier=0.00206` でも既定 8 時間のまま)。
- **Phase 8S** (撤回 + クリーンアップ) — 12 キーを `Game.ini [/Script/ShooterGame.ShooterGameMode]` に戻す: `MatingIntervalMultiplier`、`EggHatchSpeedMultiplier`、`BabyMatureSpeedMultiplier`、`BabyFoodConsumptionSpeedMultiplier`、`BabyImprintAmountMultiplier`、`BabyImprintingStatScaleMultiplier`、`BabyCuddleIntervalMultiplier`、`BabyCuddleGracePeriodMultiplier`、`BabyCuddleLoseImprintQualitySpeedMultiplier`、`SupplyCrateLootQualityMultiplier`、`FishingLootQualityMultiplier`、`CropDecaySpeedMultiplier`。**Save 時にこれらのキーが `[ServerSettings]` に残っていれば `IniDoc::remove_key` で削除**、Phase 8M 時代の古い書き込みが正規の Game.ini 値と競合しないようにする。

その他のキー (`PlayerHarvestingDamageMultiplier`、`WildDinoCharacterFoodDrainMultiplier`、`WildDinoTorporDrainMultiplier`、`StructureDamageRepairCooldown`、`MatingSpeedMultiplier`、`LayEggIntervalMultiplier`、`PassiveTameIntervalMultiplier`、`CropGrowthSpeedMultiplier`、XP gain breakdown、ステータス配列) は元から `Game.ini` 配置で変わっていません。完全 routing 表は [`docs/parameters.md`](./docs/parameters.md) を参照。

### ARK SA エンジン側の繁殖系倍率 clamp (こちらでは制御不能)
正しい routing でも、ARK SA エンジン自体が一部の繁殖系倍率を黙って clamp しています。Aberration 実機テスト結果:

- `EggHatchSpeedMultiplier` は 100 設定でも実効 **10〜30×** で頭打ち。メガロサウルス卵 (基礎 100 分) は 5〜10 分が下限。
- `BabyCuddleIntervalMultiplier` には実効 **5〜10 分の floor** あり — `0.00206` (理論上メガロサウルスで約 1.7 分) のような値は切り上げられる。`BabyMatureSpeedMultiplier` を高くしてベビーが分単位で成長すると、最初の cuddle 要求が成熟前に発火しない。

実用的アドバイス: 刷り込みを実用したいなら `BabyMatureSpeedMultiplier` を **30× 以下** に保ち、`BabyImprintAmountMultiplier ≥ 100` で 1 回の cuddle で 100% に到達させる。フォーラムガイドの「60× mature + 0.001 cuddle interval + 100 imprint amount」コンボは **ASA では機能しません** — ASE 由来です。

### INI バックスラッシュエスケープ (`D:\ARK\…` ラウンドトリップ)
`rust-ini` 既定の `EscapePolicy` は `Edit_Install_Location_Val=D:\\ARK\\ARKSA_Server` のように二重エスケープします。当方のロード側は (Lazarus `TIniFile` に合わせて `enabled_escape: false` で) その `\\` を 2 文字として読み返してしまい、実ファイルシステムのパスと一致しない壊れた Windows パスに。`arksa-core::ini_doc` で保存時に `EscapePolicy::Nothing` を設定して修正。回帰テスト: `windows_paths_round_trip_without_double_escaping`。

### Lazarus `TIniFile` の癖 (boolean / float 表現 + SHIFT_JIS)
原作のプロファイルは Lazarus が書いており、OS ANSI コードページ (JP Windows なら CP932 / SHIFT_JIS) を使用、boolean は `0/1`、float は locale 関係なく `.` 小数点で書かれます。当方の `IniDoc` は:

- 最初に UTF-8 を試行 (BOM 検出付き)、失敗時に SHIFT_JIS にフォールバック → 既存 `.ini` が綺麗に読める。
- boolean を `0`/`1` で書く (原作互換) — 例外として `GameUserSettings.ini` の `[ServerSettings]` では `True`/`False` (ARK 自身の出力に合わせる)。
- float を `format!("{value:?}")` で書き、`1.0` が `1.0` のまま (`1` にならない)、locale 依存のカンマも出ない。
- 読み込み時は `0/1` と `True/False` (大文字小文字無視) の両方を受理。

### サーバー / クライアントバージョン不一致 (manifest pinning)
Steam の自動更新でサーバービルドが先行 (例: server v86.15 vs client v86.11 → 黒画面) することがあります。GUI の *Install / Update server* ボタンは `steamcmd` で常に最新を取るため、古いビルドへの pin は別経路で行う必要があります。回避策: [DepotDownloader](https://github.com/SteamRE/DepotDownloader) で manifest 指定。確認済み組み合わせ: DepotDownloader manifest **`684954496930236842`** (server build v86.12) は client build v86.11 から綺麗に接続可能。

完全手順 (認証セットアップ、コマンドフラグ、SteamDB からの manifest 選び方、トラブルシューティング表) は [`docs/manifest-pinning.md`](./docs/manifest-pinning.md) に。Phase 9 で manifest をプロファイル単位の設定としてエクスポーズし、別コマンドラインワークフローではなく GUI チェックボックスにする予定。

### Slint コンポーネント初期化が Windows 既定スタックを溢れさせる
World Settings ウィンドウは現在約 250 プロパティ、17 条件付きコンテンツペイン、ステータス配列の 6 GroupBox を宣言します。Slint はコンポーネントごとに大量の静的初期化コードを生成するため、Windows 既定の 1 MiB メインスレッドスタックが構築中に `STATUS_STACK_OVERFLOW = 0xC00000FD` で溢れる。`.cargo/config.toml` で 8 MiB 予約に修正 (`x86_64-pc-windows-msvc` / `-gnu` / `i686-pc-windows-msvc`)。

### ICU4X 「No segmentation model for language: ja」ログスパム
Slint のテキストレイアウトが行折り返し位置決定で ICU4X を呼び、ICU4X バンドルデータには Western locale のみ同梱されているため、日本語テキストごとに `ICU4X data error: No segmentation model for language: ja` が出力され char-wrap にフォールバック (日本語は単語間スペース無視で OK)。メッセージ自体は無害ですが有用な出力を埋もれさせます。

二層防御で対処:
1. **`tracing` フィルタ** (`EnvFilter` 既定) で `icu_segmenter` / `icu_provider` / Slint warnings を `log` crate / `tracing` 経由なら抑制 (`tracing-subscriber` の既定 `tracing-log` フィーチャーがブリッジ — `LogTracer::init()` を併用すると `SetLoggerError` で panic するので注意)。
2. **Win32 stderr リダイレクト**。ICU4X 警告は実際には `log` をバイパスして `eprintln!` で stderr に直接書くため、フィルタだけでは捕まえられません。起動時にプロセスの `STD_ERROR_HANDLE` を `NUL` に置換 (`RUST_LOG` 設定時はスキップ — 開発時は出したい)。

両フィルタをバイパスして全ログを見たければ `RUST_LOG=info` を設定。

### ARK URL パーサーが `ServerAdminPassword` を破壊 (Phase 5 で解決済み)
以前のバージョンはユーザーに `GameUserSettings.ini` の手編集を要求していました — ARK SA の URL パーサーが起動 URL の残りを admin password 値にマージしていたため。Phase 5 の `arksa-core::ark_config` が `RCONEnabled` / `RCONPort` / `ServerAdminPassword` を `GameUserSettings.ini` に直接書き、起動 URL がこれらを携えなくなりました。*New…* で作成した新規プロファイルは即座に RCON 利用可能。

## 既知の問題と回避策

### 1. ARK SA Unofficial サーバーブラウザにサーバーが出ない
Wildcard のマッチメイキングは小規模個人サーバーに対して遅い / 不安定。**回避策:** in-game コンソール (`open <ip>:<port>`) で接続。[ARK SA クライアントから接続する](#ark-sa-クライアントから接続する) 参照。

### 2. ライブ言語切替に対応していない
メイン画面の Language ドロップダウンは選択を `AppSettings` に即時書き込みますが、UI ラベルは起動時に 1 回サンプリングされるだけ。言語変更を反映するには GUI 再起動が必要。*World Settings* 内のバイリンガル説明文はダイアログオープン時の設定値に従います。

### 3. NewProfileWindow の内部ラベルが英語のみ
クイックスタートの *New Profile* ダイアログには内部フィールドラベル (game port、query port、mods 等) で i18n 配線していないものが多数。セクション / ウィンドウタイトルとボタンは翻訳済みですが、フォーム内部のフィールドラベルは言語設定に関わらず英語のまま。今後段階的に対応予定。

### 4. ステータス配列タブにセル単位の説明ポップアップなし
72 個のステータス配列セル (Player / Tamed / Tamed-Add / Tamed-Affinity / Wild × Health / Stamina / … / CraftingSpeed) はラベル (`[3] Oxygen` 等) が自己説明的なので、クリックポップアップ説明をスキップ。最も特殊なフィールド約 80 個も説明未記述で、段階的に追加可能 — `main.slint` の行に `description: root.lang-ja ? "JA" : "EN";` を 1 行加えるだけ。

## ロードマップ

完全フェーズ計画と `.pas → Rust` 対応は [`docs/architecture.md`](./docs/architecture.md) を参照。

| Phase | タイトル | 状態 |
|---|---|---|
| 0 | ワークスペース骨組み | ✅ |
| 1 | INI / Profile / Settings / ModList / Win32 process | ✅ |
| 2 | RCON + steamcmd + サーバーライフサイクル | ✅ |
| 3 | Slint UI と core を配線 | ✅ |
| 4 | New Profile ダイアログ + Install ボタン + 空状態 | ✅ |
| 5 | `GameUserSettings.ini` 自動生成 + Mod/Engram/Item/Dino 検索 UI | ✅ |
| 6 | Discord webhook + tray 通知 | ✅ |
| 7 | i18n (EN + JA) | ✅ |
| 8a | World Settings ダイアログ (Game.ini + GameUserSettings.ini エディタ、約 30 項目) | ✅ |
| 8b | wire-up 修正: 約 20 個の multiplier を GUS にルーティング、PvE/PvP トグル + Ops 基本 | ✅ |
| 8c | Breeding / Imprint カテゴリ (約 11 項目) | ✅ |
| 8d | Loot / Spoilage カテゴリ (約 15 項目) | ✅ |
| 8e | Stat arrays カテゴリ (6 × 12 = 72 項目) | ✅ |
| 8f | Combat / Structures カテゴリ (約 22 項目、Cryopod nerf 含む) | ✅ |
| 8g | XP gain breakdown カテゴリ (14 項目) | ✅ |
| 8h | Cosmetic / Chat カテゴリ (14 トグル) | ✅ |
| 8i | Cluster / Lists カテゴリ (16 項目、URL 文字列含む) | ✅ |
| 8j | Stat clamps / Blueprint caps カテゴリ (11 項目) | ✅ |
| 8k | Launch flags エディタ — プロファイル `MM_Command_Val` の `-flag` 部分編集 | ✅ |
| 8L | 27 個の追加 GUS 項目 (PvP/decay、multiplier/物量、disease/safety/craft) | ✅ |
| 8M | wire-up: 12 個の breeding / loot キーを `Game.ini` → GUS に移動 (8S で撤回) | ⚠️ superseded |
| 8P | MOTD エディタ (`[MessageOfTheDay]` セクション: 複数行 `Message` + `Duration`) | ✅ |
| 8R | Mods カテゴリ (CurseForge ID リストエディタ) + クロスカテゴリライブ検索バー (仮想 *Search results* サイドバーエントリ、入力時 auto-jump、Slint 1.16 に `string.contains()` がないため Rust closure で大文字小文字無視部分一致を計算) | ✅ |
| 8S | Phase 8M 撤回: 12 個の breeding / loot キーを `Game.ini` に戻す。`IniDoc::remove_key` で Phase 8M 時代の `[ServerSettings]` 残存値を Save 時に除去、重複競合防止 | ✅ |
| 8T | Cryopod 追加 3 キー: `CryopodNerfIncomingDamageMultPercent`、`DisableCryopodEnemyCheck`、`CryopodFridgeCooldowntime` | ✅ |
| 8+ | サイドバーレイアウト、クリックポップアップ説明 (行の上に表示)、ターコイズ × ダークテーマ、メイン画面言語ピッカー、`SectionGroup` パネル、固定カラムヘッダ (Category / Parameter / Value)、単一 ScrollView 化、ボタンラベルフルネーム化 | ✅ |
| 9 | `arksa-commander` CLI | next |
| 10 | `arksa-updater` GitHub Releases 経由の自動更新 | |
| (?) | バックアップ / 定時再起動 / クラッシュ時自動再起動 | |
| (?) | ライブ言語切替 | |
| (?) | manifest pin steamcmd インストール (プロファイル単位) | |
| (?) | ステータスパネルでの公開アドレス表示 (playit.gg / Tailscale IP) | |

## ライセンス

- コード: **MIT** — [`LICENSE`](./LICENSE) 参照
- 原作帰属: [`LICENSE`](./LICENSE) 末尾
- 原作 Pascal/Lazarus ソースは本リポジトリに**含まれません** — 移植判断のクロスリファレンスが必要な場合は原作配布物から入手してください
