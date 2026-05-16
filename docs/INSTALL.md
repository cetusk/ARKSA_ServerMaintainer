# インストール / セットアップ

🌐 [English](./INSTALL.en.md) | **日本語**

このドキュメントは ARKSA Server Maintainer を **初めて触る人** が、GUI が起動して ARK SA Dedicated Server を実際に動かせるまでをカバーします。

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

> **リンカースタックの注記**: `.cargo/config.toml` で Windows バイナリの予約スタックを 8 MiB に拡張しています。World Settings ウィンドウの初期化 (約 250 プロパティ / 18 カテゴリ / 6 ステータス配列 GroupBox) が Slint コンポーネント構築時に既定の 1 MiB メインスレッドスタックを溢れさせる (`STATUS_STACK_OVERFLOW = 0xC00000FD`) ため。`x86_64-pc-windows-msvc` / `-gnu` / `i686-pc-windows-msvc` で有効化済み。

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

GUI で **Start** をクリック。Log パネルに `Server started (PID …).` と表示され、Status パネルが 5 秒ごとに更新されます (`Running`、メモリ、稼働時間)。操作中は「サーバー操作」セクション内に**不確定プログレスバー + 「処理中…」**が点灯します。

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
    ├── ARKSA_Backups\                         ← バックアップツリー (後述)
    │   └── <MapName>\
    │       ├── auto\                          定期スナップショット (リングバッファ)
    │       ├── manual\                        手動スナップショット (リテンション対象外)
    │       └── pre_rollback\                  ロールバック前自動退避 (最大 3 個)
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

`ARKSA_Backups\` は install root の **sibling** として作られ、ARK のフォルダ再編に巻き込まれない場所に置かれます。詳細は [USAGE.md のバックアップ節](./USAGE.md#バックアップ--ロールバック) を参照してください。
