# ARKSA Server Maintainer

🌐 **English** | [日本語](./README.md)

Rust + Slint GUI tool for running a local **ARK: Survival Ascended** dedicated server. Windows only. Single-server use; no fleet management.

A **personal rework** of [ASA Server Manager (ASASM)](https://sites.google.com/view/asa-server-manager) by *Dの人*. The original Object Pascal sources are not vendored here — fetch them from the upstream release if you need cross-references.

---

## Documentation

- 📦 **[Install / Setup](./docs/INSTALL.en.md)** — build prerequisites, first-time setup, recommended disk layout
- 🎮 **[Usage](./docs/USAGE.en.md)** — lifecycle, World Settings, backup, connection, MOD configs
- 🛠️ **[Troubleshooting](./docs/TROUBLESHOOTING.en.md)** — (notes) known issues, ARK / Slint / INI quirks and the workarounds in the code
- 🗺️ **[Roadmap](./docs/ROADMAP.en.md)** — (notes) phase log + what's next
- 📘 **[Architecture](./docs/architecture.md)** — crate responsibilities + upstream `.pas` → Rust mapping
- 📚 **[Parameter reference](./docs/parameters.md)** — Game.ini / GameUserSettings.ini routing table
- 🔒 **[Manifest pinning runbook](./docs/manifest-pinning.md)** — handling server / client version mismatches

## Highlights

- **GUI editor** — ~280 World Settings parameters across 18 categories + a virtual search view, with click-to-show bilingual (EN / JA) descriptions inline
- **Cross-category live search** — matches key names or descriptions
- **Backup / rollback** — periodic / manual / pre-rollback emergency snapshots tracked independently

## Download

Prebuilt Windows zip from [GitHub Releases](https://github.com/cetusk/ARKSA_ServerMaintainer/releases). Extract anywhere and double-click `run.bat` — no Rust toolchain, no Visual C++ runtime required. Step-by-step in [INSTALL.en.md § A](./docs/INSTALL.en.md#a-use-the-prebuilt-release).

## Status

Latest: **Phase 16** (progress bars). See [ROADMAP.en.md](./docs/ROADMAP.en.md) for the full phase log and what's next.

## License

- Code: **MIT** — see [`LICENSE`](./LICENSE)
- Upstream attribution: end of [`LICENSE`](./LICENSE)
- The upstream Pascal / Lazarus sources are **not** vendored — fetch them from the original ASASM distribution if you need to cross-reference porting decisions
