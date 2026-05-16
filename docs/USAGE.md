# 日常運用 / 使い方

🌐 [English](./USAGE.en.md) | **日本語**

このドキュメントは GUI の各機能の使い方をまとめます。初期セットアップは [INSTALL.md](./INSTALL.md)、トラブルシュートは [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) を参照してください。

## 目次

1. [操作一覧](#操作一覧)
2. [通知設定](#通知設定)
3. [World Settings ダイアログ](#world-settings-ダイアログ)
4. [MOD 設定カテゴリ](#mod-設定カテゴリ)
5. [バックアップ / ロールバック](#バックアップ--ロールバック)
6. [接続情報 (Connection)](#接続情報-connection)
7. [ARK SA クライアントから接続する](#ark-sa-クライアントから接続する)

## 操作一覧

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
| **MOD 追加 / 削除** | *World Settings* → *Mods* — CurseForge Project ID を 1 行 1 つ、またはカンマ区切りで貼り付け。プロファイルの `MM_Command_Val` に `-mods=ID,ID,...` として保存 |
| **MOD 別の INI 設定** | *World Settings* → *MOD 設定* — 導入済み MOD のうちスキーマ登録済みのものだけ表示。現在 RTB 対応 ([後述](#mod-設定カテゴリ)) |
| **Discord / トースト通知** | *Setup* → *Notifications* → webhook URL とイベント種別を設定 → *Save* |
| **UI 言語切替 (英 ↔ 日)** | *Setup* セクションの *Language* ドロップダウン — **即時反映** (再起動不要)、全ウィンドウ + サーバステータス文言まで一括翻訳 |
| **公開アドレス共有** | *Profile* セクション直下の *Connection* — playit.gg トンネル / Tailscale 名 / グローバル IP を入力 (Enter で保存)、*Copy* ボタンでクリップボードへ |
| **バックアップ / ロールバック** | *Profile* → *Backup / Rollback* ([後述](#バックアップ--ロールバック)) |
| **生の launch line を直接編集** | `<ARKSA_DIR>\Profile\<file_name>.ini` の `MM_Command_Val=` を編集 → GUI で *Refresh status* |
| **プロファイル切替** | *Profile* セクションのドロップダウン — ドロップダウン下に選択中プロファイルの実ファイルパス (`↳ File: …`) が表示 |
| **サーバーステータス手動更新** | *Server status* → *Refresh status* (5 秒ごとに自動 poll もしているので通常は不要) |

ステータスパネルは `server::status` を 5 秒ごとに poll — PID / ワーキングセットメモリ / 稼働時間が自動更新されます。Start / Stop / Restart / Install / RCON / Refresh-status のいずれを実行中も「サーバー操作」セクション内に**不確定プログレスバー + 「処理中…」**が点灯し、状態が常に見えます。

## 通知設定

*Notifications* ダイアログは設定を `<ARKSA_DIR>/AsaServerManegerWin.ini` に永続化 (原作レイアウトと互換)。配線済みイベントトリガー:

| イベント | 発火タイミング |
|---|---|
| `Server starting` | `server::start` が PID を返した直後 |
| `Server stopped` | `stop_graceful` が `GracefulRcon` または `GracefulWindowClose` を返した後 |

その他のイベント (Server online / Crash detected / Tool update / Server-app update) はダイアログで有効化可能ですが、対応する検出器が将来 Phase で実装され次第 payload を送るようになります。

## World Settings ダイアログ

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
| **MOD 設定** | スキーマ登録済み MOD の INI 設定 (現在 RTB)。詳細は [次節](#mod-設定カテゴリ) | MOD ごとの INI セクション (例: `[RTB]` in `GameUserSettings.ini`) |
| 🔍 *Search results* (仮想) | 検索ボックス入力中のみサイドバーに出現。全カテゴリのマッチ行を 1 リストに集約、各グループにソースカテゴリ名見出し付き | (読み出しのみ — 元カテゴリと同じ) |

**英日クリックポップアップ説明** — ほぼ全パラメーターラベルに **ⓘ** マーカー付き。ラベルクリックで英日 (UI 言語と連動) の短い説明がラベル**直上**にポップアップ。外側クリックで閉じる。

**全カテゴリ横断ライブ検索** — ダイアログ上部の *Search:* ボックスに任意の部分文字列を入力。空でなくなった瞬間にサイドバーに **🔍 Search results** カテゴリが出現し、ダイアログは自動でそこへ移動します。右ペインにはラベルが部分一致 (大文字小文字無視) する行のみがソースカテゴリ名 (ターコイズ太字) でグループ化されて表示。検索ボックス横の *Include description* をオンにすると説明文も検索対象に — キー名を覚えていない時に便利 (例: `imprint` と打てば Breeding / Difficulty 等にまたがる刷り込み関連行が一覧)。

### ワークフロー

- *新規プロファイル* — 最初の Start 前にダイアログを開く。Game.ini がまだ存在しないため既定値 (大半 1.0) が表示される。任意調整 → **Save** → **Start**。
- *既存プロファイル* — 両 INI の現在値を読み込み。非破壊編集 — モデル化していないキー (例: `OverrideEngramEntries[…]`) は Save 時に保持される。
- *別インストールの設定を流用* — **Import settings from file** → `Game.ini` (または `GameUserSettings.ini`、または手動マージした統合 INI) を選択。認識されたキーはフォームに流れ込み、**Save** を押すまでファイルには書かれない。
- *リセット* — **Reset to defaults** で全フィールドが vanilla 値 (multiplier は 1.0、bool は false) に戻る。**Cancel** で破棄、**Save** で永続化。

ARK は起動時にしかこれらのファイルを再読込しないので、変更は次回の *Start* で反映されます。

## MOD 設定カテゴリ

通常の World Settings 18 カテゴリとは独立した **「MOD 設定」サイドバー** (Phase 14)。「MOD ごとの INI セクションを通常設定と混ぜない」ことを優先設計しており、

- プロファイルの `-mods=` リストから検出された MOD のうち、コード側に**スキーマ登録済みの MOD だけが GroupBox として表示**される
- `-mods=` から MOD を抜くと該当 GroupBox は非表示になり、Save 時もそのセクションは触らない
- 再度有効化すると **以前の設定がそのまま復元** される (INI セクションが残っているため)

### 現在対応している MOD

| MOD | Project ID | INI ファイル | セクション | 主なキー |
|---|---|---|---|---|
| **Return The Beacons (RTB)** | `933576` | `GameUserSettings.ini` | `[RTB]` | `EnableBeaconUI` (bool) / `PlayerBeamColor` (hex) / `DinoBeamColor` (hex) / `EnableGUIKeybind` (bool) / `EnablePauseMenuButton` (bool) |

新規 MOD を追加する場合は `crates/arksa-core/src/mod_configs.rs` の `ALL_MODS` スライスに `ModConfigSchema` 定数を追加するだけで、GUI 側は自動的に GroupBox を生成します。

## バックアップ / ロールバック

*Profile* セクションの **Backup / Rollback** ボタンで開きます。サイドバー 3 カテゴリ構成:

- **パス情報** — 対象プロファイル / マップ名 / SavedArks パス / バックアップ保存先
- **スナップショット設定** — 自動取得 ON/OFF、間隔 (T 分)、保持数 (N 個)、圧縮レベル、「今すぐ取得」(手動スナップショット作成)
- **スナップショット一覧** — 3 サブタブ (**定期 / 手動 / ロールバック前自動退避**)、日時 / サイズの列ヘッダクリックでソート切替

### 保存場所と種別

`<install>\ARKSA_Backups\<MapName>\` 配下を 3 つに分離 (Phase 15):

```
ARKSA_Backups\<MapName>\
├── auto\                          定期スナップショット (リングバッファ N 件)
│   └── YYYYMMDD_HHMMSS.zip
├── manual\                        手動スナップショット (リテンション対象外)
│   └── YYYYMMDD_HHMMSS.zip
└── pre_rollback\                  ロールバック前自動退避 (最大 3 件)
    └── from_<SRC>_to_<RB>.zip     SRC = 復元元の created、RB = ロールバック実施時刻
```

- **定期スナップショット (auto/)** — スケジューラが取得、リングバッファで古いものから自動削除
- **手動スナップショット (manual/)** — 「今すぐ取得」で取得、**自動削除されない**。明示的に削除しない限り残り続けるため、節目の保存に向く
- **ロールバック前自動退避 (pre_rollback/)** — ロールバック実施時に自動取得、最大 3 件保持。ファイル名に**復元元スナップショットの timestamp** を埋め込んでいるため「どの復元に紐づくか」がトラッキング可能

ARK SA の `ShooterGame\Saved\` ツリーには一切干渉せず、エンジン側のフォルダ再編に巻き込まれない場所です。

旧フラットレイアウト (`snapshot_<MapName>_<TS>.zip`) は初回 list 呼び出し時に自動マイグレーション (`auto/<TS>.zip` へ移動) されるので、既存ユーザーは何もしなくて OK。

### スナップショットの中身

`SavedArks\<MapName>\` ディレクトリ全体を **1 つの zip に固める**。`.ark` (世界保存) だけでなく `<TribeID>.arktribe` (トライブ別)、`<SteamID>.arkprofile` (プレイヤー別)、`.arktribebak` / `.arkprofilebak` (時刻バックアップ)、エンジンの `.arkrbf` (rolling backup file、保持 3 はエンジン hardcode)、`LocalProfiles\` まで全部。これらは `.ark` 内が tribe ID / steam ID で互いを参照する関係なので **時刻整合した状態で一括ロールバック** しないとトライブ消失や恐竜ロストが起きます — 個別ファイル選択は意図的に未実装。

### 保持ポリシー

「**T 分周期で N 個保持**」のリングバッファ。デフォルト T=30 分 / N=12 (= 6 時間履歴)。**`auto/` のみに適用** — 手動と pre_rollback は別の方針です。範囲外の数値は読み書き両方で clamp、corrupt INI でもスケジューラが暴走 / 沈黙しないようにしてあります。

### 圧縮レベル

4 段階から選択:

| 設定 | 方式 | 速度 (1 GB セーブ目安) | 圧縮率 |
|---|---|---|---|
| **なし** | STORE | 〜数秒 (ファイルコピー速度) | 100% (無圧縮) |
| **速い (デフォルト)** | Deflate 1 | 〜10 秒 | 約 70% |
| **標準** | Deflate 6 | 〜30 秒 | 約 65% |
| **最大** | Deflate 9 | 〜80 秒 | 約 60% |

ARK の `.ark` ファイルは半圧縮済みバイナリで「最大」にしても 30〜40% しか縮みません。一方 Deflate 9 は Deflate 1 の 5〜10 倍 CPU を食うため、デフォルトを Deflate 1 にしています。ディスク容量に余裕があれば「なし」にすると手動コピーと同等の瞬時バックアップに。

### プログレスバー

スナップショット作成・ロールバック実行中は、ダイアログ底部の**決定的プログレスバー + `1.2 GiB / 4.8 GiB` バイト数表記**が進捗を可視化します (Phase 16)。ロールバックは「退避中…」(`pre_rollback/` 書き込み) → 「復元中…」(zip 展開) の 2 段階で、各段階ごとにメッセージとバーがリセットされます。

### 自動スケジューラ

「定期スナップショットを取得する」を ON にすると、起動 30 秒後から 60 秒ごとに wake、現在選択中プロファイルを参照、`auto_backup_enabled` かつ「最新 auto snapshot から interval 分以上経過」なら snapshot + retention 整理を実行。**「最終取得時刻」はディスクの newest auto snapshot から導出**するのでツール再起動後もスケジュールが継続します。プロファイル切替には自動追従。手動スナップショットはスケジュール判定に**含めません** (ユーザが任意に取ったものを「最終定期取得」と誤認するのを防ぐため)。

### ロールバック手順 (UI 操作)

1. 巻き戻したい行の **「この時点に巻き戻す」** をクリック → 黄色い確認ストリップが上部に出る
2. **サーバー起動中なら警告 + ボタン無効化** (起動中に展開するとエンジンの書き込みと競合してワールドが破損するため)
3. 「はい、巻き戻す」を押すと:
   1. 現在の `SavedArks\<MapName>\` を `pre_rollback\from_<SRC>_to_<RB>.zip` に自動退避 (プログレスバーが「退避中…」で進む)
   2. 選択したスナップショット zip を staging dir に展開 (プログレスバーが「復元中…」に切り替わって進む) → 旧ツリーを `.replaced_<TS>` にリネーム → staging を本番へ atomic rename → 旧を削除 (途中失敗時は `.replaced_*` から復旧可能)
   3. 一覧再描画
4. もし「思ったのと違う」となったら、pre_rollback 一覧から元の状態に再ロールバック可能 (3 世代まで)

### 関連退避バッジ (🔁)

定期 / 手動スナップショット行のうち、**そのスナップショットを元にロールバックされた履歴がある** ものには `🔁 関連退避あり` バッジが表示されます。クリックで青枠の詳細ストリップが開き、

- 関連 pre_rollback の日時 / サイズ / 元スナップショットの日時を表示
- **「この退避から復元」** ボタンでワンクリック復元

これにより「うっかり巻き戻したけどやっぱり戻したい」が 2 クリックで完結します。

**実機検証済み** — ベッドで寝ていた時点のスナップショットからロールバック → ベッド姿勢で復元、その pre_rollback から再ロールバック → 椅子姿勢に戻る、を Aberration で確認。

## 接続情報 (Connection)

*Profile* セクション直下の **Connection** に LineEdit + Copy ボタン。playit.gg トンネル / Tailscale 名 / 公開 IP など、他プレイヤーが接続に使う文字列を自由形式で入力。

- 入力 → **Enter** で `[Server] Edit_PublicAddress` (上流 INI スキーマ互換) に保存
- **Copy** ボタンでクリップボードへ (Windows clipboard、`arboard` 経由) — 友人への共有に最適
- プロファイル切替で自動的に当該プロファイルの値に切り替わり

playit-cli との直接統合は環境依存が大きいため将来拡張余地として、まずは「ユーザーが手動入力 + ワンクリック共有」の MVP に絞っています。

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
