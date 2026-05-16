# ロードマップ

🌐 [English](./ROADMAP.en.md) | **日本語**

`.pas → Rust` 対応や crate 責務の詳細は [`architecture.md`](./architecture.md) を参照。

## フェーズ完了履歴

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
| 8R | Mods カテゴリ (CurseForge ID リストエディタ) + クロスカテゴリライブ検索バー | ✅ |
| 8S | Phase 8M 撤回: 12 個の breeding / loot キーを `Game.ini` に戻す。`IniDoc::remove_key` で Phase 8M 時代の `[ServerSettings]` 残存値を Save 時に除去、重複競合防止 | ✅ |
| 8T | Cryopod 追加 3 キー: `CryopodNerfIncomingDamageMultPercent`、`DisableCryopodEnemyCheck`、`CryopodFridgeCooldowntime` | ✅ |
| 8U | 検索フィルタの行間レイアウト修正 (`inherits HorizontalBox` + `visible:false` がレイアウト空間を解放しない Slint 1.16 挙動を `inherits Rectangle` + `height:0` で回避) | ✅ |
| 8+ | サイドバーレイアウト、クリックポップアップ説明、ターコイズ × ダークテーマ、メイン画面言語ピッカー、`SectionGroup` パネル、固定カラムヘッダ、単一 ScrollView 化、ボタンラベルフルネーム化 | ✅ |
| 11 | バックアップ / ロールバック (一式): `arksa-core::backup` (zip スナップショット + atomic write + staging swap rollback + zip slip 防御)、BackupWindow 一画面、自動スケジューラ (60 秒 wake、ディスク mtime ベース、再起動継続)、4 段階圧縮レベル選択 (STORE / Deflate 1/6/9、デフォルト Deflate 1) | ✅ |
| 12 | ライブ言語切替 (再起動不要): 全 6 ウィンドウへ `AllWindowWeaks` 経由で UiLabels 一括再注入、Server Status 文言も `invoke_refresh_status` で同期、メイン + 通知ダイアログのどちらの言語ピッカーでも対称動作 | ✅ |
| 13 | 公開アドレス表示 (playit.gg / Tailscale): Profile 直下に Connection セクション、`[Server] Edit_PublicAddress` (上流 INI スキーマ互換) に保存、`arboard` でクリップボードコピー、プロファイル切替自動追従 | ✅ |
| 14 | MOD 設定カテゴリ + RTB スキーマ: MOD 別 INI スキーマレジストリ (`crates/arksa-core/src/mod_configs.rs`)、`-mods=` リストから検出した MOD のみ表示、無効化時は GroupBox 非表示 + Save 非干渉で設定保全 | ✅ |
| 15 | バックアップ画面リワーク: `auto/` / `manual/` / `pre_rollback/` の 3 サブディレクトリ分離、サイドバーをカテゴリ集約 (パス / 設定 / 一覧)、一覧カテゴリに 3 サブタブ + 日時・サイズソート + 関連退避バッジ (🔁)、pre_rollback ファイル名に復元元 timestamp を埋め込んで紐付け可視化、レガシーレイアウト自動マイグレーション | ✅ |
| 16 | プログレスバー対応: スナップショット / ロールバックは決定的バー + バイト数表示 (100ms スロットル)、サーバー起動 / 停止 / 再起動 / インストール / RCON / ステータス更新は不確定スピナー + 「処理中…」ラベル | ✅ |
| 17 | 配布版 .zip ビルドパイプライン: `x86_64-pc-windows-msvc` + `+crt-static` で自己完結 .exe、`tools/build-release.ps1` でローカル zip 生成、`.github/workflows/release.yml` で `v*` タグ push 時に GitHub Releases へ自動添付 (zip + 単体 .exe)、`run.bat` 同梱で「解凍 → ダブルクリック」起動 | ✅ |
| 18 | ARKSA フォルダのホットスワップ + 永続化: Setup → Browse for folder で選んだフォルダを `AppCtx::install_dir` (`Arc<Mutex<PathBuf>>`) に in-process 反映、プロファイル一覧 / 選択 / Status を即更新、選択は exe と同階層の `arksa-launcher.ini` に保存して次回起動で復元、解決順は env → launcher.ini → exe ディレクトリ | ✅ |

## 今後の計画

| Phase | タイトル | 状態 |
|---|---|---|
| 9 | `arksa-commander` CLI — 外部スクリプトから RCON 送信 / 状態取得 | next |
| 10 | `arksa-updater` GitHub Releases 経由の自動更新 | |
| (?) | 定時再起動 / クラッシュ時自動再起動 | |
| (?) | manifest pin steamcmd インストール (プロファイル単位) — Phase 9 で GUI チェックボックスとして | |
| (?) | playit-cli 直接統合によるトンネルアドレス自動取得 | |
| (?) | NewProfileWindow の i18n 補完 (内部フィールドラベル) | |
| (?) | ステータス配列セル / 特殊フィールドへの説明ポップアップ追加 | |
| (?) | バックアップのプログレスバー UI 微調整 (フェーズラベル i18n 化、表示位置調整) | |

## ドキュメント整備履歴

- 2026-05-16: README を分割 (README + INSTALL / USAGE / TROUBLESHOOTING / ROADMAP)。情報密度を下げて目的別に独立、改修時の差分を局所化
