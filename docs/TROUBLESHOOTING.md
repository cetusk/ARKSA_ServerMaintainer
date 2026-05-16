# トラブルシュート

🌐 [English](./TROUBLESHOOTING.en.md) | **日本語**

このドキュメントは、ARKSA Server Maintainer の運用中に遭遇しうる**既知の問題と回避策**、および**コード内に組み込まれている互換性 / 整合性対応**をまとめます。後者は将来のメンテナーが「なぜこの回避策が入っているか」を理解できるよう経緯付きで残してあります。

## 目次

1. [既知の問題](#既知の問題)
2. [ARK SA 周りの癖と回避策](#ark-sa-周りの癖と回避策)
3. [INI 周りの癖](#ini-周りの癖)
4. [Slint 周りの癖](#slint-周りの癖)
5. [ICU4X ログスパム](#icu4x-no-segmentation-model-for-language-ja-ログスパム)

## 既知の問題

### 1. ARK SA Unofficial サーバーブラウザにサーバーが出ない

Wildcard のマッチメイキングは小規模個人サーバーに対して遅い / 不安定。**回避策:** in-game コンソール (`open <ip>:<port>`) で接続。[USAGE.md の接続節](./USAGE.md#ark-sa-クライアントから接続する) 参照。

### 2. NewProfileWindow の内部ラベルが英語のみ

クイックスタートの *New Profile* ダイアログには内部フィールドラベル (game port、query port、mods 等) で i18n 配線していないものが多数。セクション / ウィンドウタイトルとボタンは翻訳済みですが、フォーム内部のフィールドラベルは言語設定に関わらず英語のまま。今後段階的に対応予定。

### 3. ステータス配列タブにセル単位の説明ポップアップなし

72 個のステータス配列セル (Player / Tamed / Tamed-Add / Tamed-Affinity / Wild × Health / Stamina / … / CraftingSpeed) はラベル (`[3] Oxygen` 等) が自己説明的なので、クリックポップアップ説明をスキップ。最も特殊なフィールド約 80 個も説明未記述で、段階的に追加可能 — `main.slint` の行に `description: root.lang-ja ? "JA" : "EN";` を 1 行加えるだけ。

## ARK SA 周りの癖と回避策

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

その他のキー (`PlayerHarvestingDamageMultiplier`、`WildDinoCharacterFoodDrainMultiplier`、`WildDinoTorporDrainMultiplier`、`StructureDamageRepairCooldown`、`MatingSpeedMultiplier`、`LayEggIntervalMultiplier`、`PassiveTameIntervalMultiplier`、`CropGrowthSpeedMultiplier`、XP gain breakdown、ステータス配列) は元から `Game.ini` 配置で変わっていません。完全 routing 表は [`parameters.md`](./parameters.md) を参照。

### ARK SA エンジン側の繁殖系倍率 clamp (こちらでは制御不能)

正しい routing でも、ARK SA エンジン自体が一部の繁殖系倍率を黙って clamp しています。Aberration 実機テスト結果:

- `EggHatchSpeedMultiplier` は 100 設定でも実効 **10〜30×** で頭打ち。メガロサウルス卵 (基礎 100 分) は 5〜10 分が下限。
- `BabyCuddleIntervalMultiplier` には実効 **5〜10 分の floor** あり — `0.00206` (理論上メガロサウルスで約 1.7 分) のような値は切り上げられる。`BabyMatureSpeedMultiplier` を高くしてベビーが分単位で成長すると、最初の cuddle 要求が成熟前に発火しない。

実用的アドバイス: 刷り込みを実用したいなら `BabyMatureSpeedMultiplier` を **30× 以下** に保ち、`BabyImprintAmountMultiplier ≥ 100` で 1 回の cuddle で 100% に到達させる。フォーラムガイドの「60× mature + 0.001 cuddle interval + 100 imprint amount」コンボは **ASA では機能しません** — ASE 由来です。

### サーバー / クライアントバージョン不一致 (manifest pinning)

Steam の自動更新でサーバービルドが先行 (例: server v86.15 vs client v86.11 → 黒画面) することがあります。GUI の *Install / Update server* ボタンは `steamcmd` で常に最新を取るため、古いビルドへの pin は別経路で行う必要があります。回避策: [DepotDownloader](https://github.com/SteamRE/DepotDownloader) で manifest 指定。確認済み組み合わせ: DepotDownloader manifest **`684954496930236842`** (server build v86.12) は client build v86.11 から綺麗に接続可能。

完全手順 (認証セットアップ、コマンドフラグ、SteamDB からの manifest 選び方、トラブルシューティング表) は [`manifest-pinning.md`](./manifest-pinning.md) に。Phase 9 で manifest をプロファイル単位の設定としてエクスポーズし、別コマンドラインワークフローではなく GUI チェックボックスにする予定。

### ARK URL パーサーが `ServerAdminPassword` を破壊 (Phase 5 で解決済み)

以前のバージョンはユーザーに `GameUserSettings.ini` の手編集を要求していました — ARK SA の URL パーサーが起動 URL の残りを admin password 値にマージしていたため。Phase 5 の `arksa-core::ark_config` が `RCONEnabled` / `RCONPort` / `ServerAdminPassword` を `GameUserSettings.ini` に直接書き、起動 URL がこれらを携えなくなりました。*New…* で作成した新規プロファイルは即座に RCON 利用可能。

## INI 周りの癖

### INI バックスラッシュエスケープ (`D:\ARK\…` ラウンドトリップ)

`rust-ini` 既定の `EscapePolicy` は `Edit_Install_Location_Val=D:\\ARK\\ARKSA_Server` のように二重エスケープします。当方のロード側は (Lazarus `TIniFile` に合わせて `enabled_escape: false` で) その `\\` を 2 文字として読み返してしまい、実ファイルシステムのパスと一致しない壊れた Windows パスに。`arksa-core::ini_doc` で保存時に `EscapePolicy::Nothing` を設定して修正。回帰テスト: `windows_paths_round_trip_without_double_escaping`。

### Lazarus `TIniFile` の癖 (boolean / float 表現 + SHIFT_JIS)

原作のプロファイルは Lazarus が書いており、OS ANSI コードページ (JP Windows なら CP932 / SHIFT_JIS) を使用、boolean は `0/1`、float は locale 関係なく `.` 小数点で書かれます。当方の `IniDoc` は:

- 最初に UTF-8 を試行 (BOM 検出付き)、失敗時に SHIFT_JIS にフォールバック → 既存 `.ini` が綺麗に読める。
- boolean を `0`/`1` で書く (原作互換) — 例外として `GameUserSettings.ini` の `[ServerSettings]` では `True`/`False` (ARK 自身の出力に合わせる)。
- float を `format!("{value:?}")` で書き、`1.0` が `1.0` のまま (`1` にならない)、locale 依存のカンマも出ない。
- 読み込み時は `0/1` と `True/False` (大文字小文字無視) の両方を受理。

## Slint 周りの癖

### Slint コンポーネント初期化が Windows 既定スタックを溢れさせる

World Settings ウィンドウは現在約 250 プロパティ、17 条件付きコンテンツペイン、ステータス配列の 6 GroupBox を宣言します。Slint はコンポーネントごとに大量の静的初期化コードを生成するため、Windows 既定の 1 MiB メインスレッドスタックが構築中に `STATUS_STACK_OVERFLOW = 0xC00000FD` で溢れる。`.cargo/config.toml` で 8 MiB 予約に修正 (`x86_64-pc-windows-msvc` / `-gnu` / `i686-pc-windows-msvc`)。

### Slint 1.16 の `visible: false` が `inherits HorizontalBox` した子のレイアウト空間を解放しない (Phase 8U で回避)

World Settings の検索フィルタで「マッチしない行を非表示」にした際、`WorldFloatRow` / `WorldBoolRow` (HorizontalBox 継承) を `visible: false` にしても親 VerticalBox がレイアウト空間を確保し続け、検索結果の行間に大きな空白が残る現象が発生 (cryo 検索でカテゴリ内に空白行が並ぶ問題)。本質的に Slint 1.16 の挙動: `inherits HorizontalBox` で構築したコンポーネントの `visible` プロパティがレイアウトコンテナまで波及しない。

回避策として **`inherits HorizontalBox` → `inherits Rectangle`** に変更し、内側に HorizontalBox を持つ二段構成にした上で外側 Rectangle の `height` を `show ? row.preferred-height : 0px` で明示的に 0 へ畳む方式に変更 (`clip: true` で念のため内側のはみ出し防止)。これでマッチしない行が真に高さゼロとなり、上詰めで連続表示されるように。

### Slint の標準フォントに無い Unicode 文字 (`↻` / `↺` 等) が見えない

Windows 上の Slint は標準で Segoe UI 系のフォントを使用しますが、フォールバック経路によっては U+21BA / U+21BB の矢印が描画されないケースがあります (Phase 16 でリフレッシュボタンを `↻` にしたら無地のボタンになった事例)。確実に出る代替:

- **絵文字グリフ** (U+1F500 台) を使う — `🔄` (リフレッシュ)、`🔁` (リピート)、`🔍` (検索) など。Segoe UI Emoji 経由で描画される。
- **テキストラベル + アイコン無し** — どうしても見えない場合は素直にテキスト (例: 「更新」/`Refresh`) に。

## ICU4X 「No segmentation model for language: ja」ログスパム

Slint のテキストレイアウトが行折り返し位置決定で ICU4X を呼び、ICU4X バンドルデータには Western locale のみ同梱されているため、日本語テキストごとに `ICU4X data error: No segmentation model for language: ja` が出力され char-wrap にフォールバック (日本語は単語間スペース無視で OK)。メッセージ自体は無害ですが有用な出力を埋もれさせます。

二層防御で対処:

1. **`tracing` フィルタ** (`EnvFilter` 既定) で `icu_segmenter` / `icu_provider` / Slint warnings を `log` crate / `tracing` 経由なら抑制 (`tracing-subscriber` の既定 `tracing-log` フィーチャーがブリッジ — `LogTracer::init()` を併用すると `SetLoggerError` で panic するので注意)。
2. **Win32 stderr リダイレクト**。ICU4X 警告は実際には `log` をバイパスして `eprintln!` で stderr に直接書くため、フィルタだけでは捕まえられません。起動時にプロセスの `STD_ERROR_HANDLE` を `NUL` に置換 (`RUST_LOG` 設定時はスキップ — 開発時は出したい)。

両フィルタをバイパスして全ログを見たければ `RUST_LOG=info` を設定。
