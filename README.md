# ARKSA Server Maintainer

🌐 [English](./README.en.md) | **日本語**

**ARK: Survival Ascended** のローカルサーバーを運用するための Rust + Slint 製 GUI ツール。Windows 専用。マルチサーバーは非対応。

[ASA Server Manager (ASASM)](https://sites.google.com/view/asa-server-manager) (作者: *Dの人*) の **個人用リワーク**。原作の Object Pascal ソースは本リポジトリに同梱していません — クロスリファレンスが必要であれば原作配布物から入手してください。

---

## ドキュメント

- 📦 **[インストール / セットアップ](./docs/INSTALL.md)** — ビルド前提、初期セットアップ、推奨ディスクレイアウト
- 🎮 **[運用 / 使い方](./docs/USAGE.md)** — ライフサイクル、World Settings、バックアップ、接続、MOD 設定
- 🛠️ **[トラブルシュート](./docs/TROUBLESHOOTING.md)** — （メモ）既知の問題、ARK / Slint / INI の癖と回避策
- 🗺️ **[ロードマップ](./docs/ROADMAP.md)** — （メモ）フェーズ完了履歴と今後の計画
- 📘 **[アーキテクチャ](./docs/architecture.md)** — crate 責務 + 原作 .pas → Rust 対応表
- 📚 **[パラメーターリファレンス](./docs/parameters.md)** — Game.ini / GameUserSettings.ini ルーティング
- 🔒 **[manifest pinning runbook](./docs/manifest-pinning.md)** — サーバー / クライアントバージョン不一致時の対処

## 主要機能

- **GUI 編集** — 約 280 個の World Settings パラメーターを 18 カテゴリ + 仮想検索ビューに分類、ラベルクリックで英日バイリンガル説明をその場ポップアップ
- **クロスカテゴリライブ検索** — キー名 / 説明文の両方を対象に検索可能
- **バックアップ / ロールバック** — 定期 / 手動 / ロールバック前自動退避

## ダウンロード

[GitHub Releases](https://github.com/cetusk/ARKSA_ServerMaintainer/releases) に 2 種類:

- `arksa-server-maintainer-vX.Y.Z.zip` — 初回インストール用フル一式 (exe + assets + run.bat)
- `arksa-gui-vX.Y.Z.exe` — 単体 exe (既存環境のアップデート用、上書き 1 つで完結)

どちらも Rust ビルド環境不要、Visual C++ ランタイム不要。詳しい手順は [INSTALL.md の A 節](./docs/INSTALL.md#a-配布版を使う) を参照。

## ステータス

最新: **Phase 16** (プログレスバー対応)。詳細とフェーズ計画は [ROADMAP.md](./docs/ROADMAP.md) を参照。

## ライセンス

- コード: **MIT** — [`LICENSE`](./LICENSE) 参照
- 原作帰属: [`NOTICE`](./NOTICE) 参照
- 原作 Pascal / Lazarus ソースは本リポジトリに**含まれません** — 移植判断のクロスリファレンスが必要な場合は原作配布物から入手してください
