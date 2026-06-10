<div align="center">

# Oolong

**A tiny, native macOS menu-bar companion for Claude Code** — live usage & official rate limits, keep-awake, and system stats, all in one dropdown.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![Size](https://img.shields.io/badge/.app-~760KB-success)
![License](https://img.shields.io/badge/license-MIT-blue)

English | [简体中文](README.zh-CN.md)

<img src="docs/screenshot.png" alt="Oolong panel" width="340">

<sub>Replace <code>docs/screenshot.png</code> with your own screenshot.</sub>

</div>

---

Oolong lives in your menu bar and shows everything you want to glance at while coding with Claude Code: how many tokens/dollars you've burned today, where you stand against the **official 5-hour and 7-day rate limits**, your machine's vitals, and a one-tap **keep-awake** for long-running tasks. Pure Swift/SwiftUI, ~760 KB, no Electron.

> Focused on **Claude Code only** (no Codex). Inspired by community menu-bar tools, rebuilt natively with a Claude-style warm theme.

## ✨ Features

- **Claude Code usage** — today / this-week / this-month **tokens & cost** (accurate online pricing via [`ccusage`](https://github.com/ryoppippi/ccusage)).
- **Official rate limits** — **5h** and **7d** windows with real **% used** and **reset countdown**, read from the same data `/usage` uses. Zero credentials, zero API calls, no ToS gray area.
- **Burn rate & active-session** indicator.
- **Keep Awake** — *Standard* (no idle/display sleep) and *Lid-closed* (stays awake with the lid shut, via `pmset`), with **Forever / 1h / 2h / 4h** auto-off.
- **System status** — uptime, CPU, memory, battery (native mach / IOKit).
- **Launch at login** (`SMAppService`), manual refresh, quit.
- **Claude-inspired warm theme**, native `NSStatusItem` + popover, fits small notched screens (scrolls when needed).
- **English / 中文 UI** with an in-app language switch (🌐 in the footer); defaults to your system language.

## 📦 Requirements

- **macOS 13+**
- **Apple Silicon** — the prebuilt `.app` is `arm64`. For Intel, build a universal binary (see [Development](#-development)).
- [**`ccusage`**](https://github.com/ryoppippi/ccusage) at runtime, for token/cost data.

## 🚀 Install

### Option A — Download
1. Download `Oolong.app` from [Releases](../../releases) and move it to `/Applications`.
2. First launch (ad-hoc signed): right-click → **Open**, or clear quarantine:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Oolong.app
   ```

### Option B — Build from source
```bash
git clone https://github.com/adaiguoguo/Oolong.git
cd Oolong
make install        # builds, bundles, copies to /Applications, and launches
```

## ⚙️ Setup

### 1. ccusage (token & cost data)
```bash
bun add -g ccusage      # or: npm i -g ccusage
```
Oolong auto-discovers `ccusage` in `~/.bun/bin`, Homebrew, npm-global, or your login `PATH`. It uses **online pricing** so model costs are correct (offline pricing tables are stale and undercount by tens of times).

### 2. Official rate limits (5h / 7d) — recommended
Claude Code (≥ 2.1.x) passes live rate-limit data to **status line** scripts via stdin. Add **one line** to your `~/.claude/statusline-command.sh` (right after `input=$(cat)`) so it hands that data to Oolong:

```bash
__ccbar_rl=$(jq -c '.rate_limits // empty' <<<"$input" 2>/dev/null); [ -n "$__ccbar_rl" ] && printf '%s' "$__ccbar_rl" > ~/.claude/ccbar-ratelimits.json
```

This writes `~/.claude/ccbar-ratelimits.json`; the app reads it. **No tokens, no API, no credentials.** Without it, the 5h section falls back to a reconstructed time window (clearly labelled as non-official).

## 🖥 Usage

Click the ☕ cup icon in the menu bar to open the panel.

- **Keep Awake** — pick a *mode* and *duration*, then flip the top switch. The two rows are sub-settings of the switch: greyed/outlined when off, lit in clay-orange when active. *Lid-closed* prompts for an admin password (it toggles `pmset disablesleep`).
- Everything else is read-only and refreshes automatically (~30 s for usage, 1 s for system/countdowns).

## 🔍 How it works

| Data | Source |
|------|--------|
| Token totals & cost | `ccusage daily/weekly/monthly` (online pricing) |
| 5h / 7d % used + reset | `rate_limits` from Claude Code's status-line stdin |
| Burn rate, active 5h block | `ccusage blocks --active` |
| CPU / memory / battery / uptime | `host_statistics`, `vm_statistics64`, IOKit, `ProcessInfo` |
| Keep awake | `caffeinate -di` + `pmset -a disablesleep` (admin) |
| Launch at login | `SMAppService` |

The usage layer sits behind a `UsageProvider` protocol, so the `ccusage` backend can be swapped for a native parser or a bundled sidecar later.

## 🛠 Development

```bash
make build     # swift build
make run        # build & run (swift run)
make test       # unit tests (swift-testing)
make probe      # headless self-check: prints system + usage + rate-limit JSON for verification
make bundle     # build release & assemble dist/Oolong.app (ad-hoc signed)
make install    # bundle + copy to /Applications + open
make clean
```

`make probe` is the verification harness — it prints a JSON snapshot you can diff against `ccusage` output. To produce a **universal (arm64 + x86_64)** binary for Intel Macs, build with both archs and re-bundle.

### Testing

Unit tests live in `Tests/OolongTests/` and use [swift-testing](https://github.com/swiftlang/swift-testing) (pulled as a package dependency, so plain Command Line Tools work — full Xcode not required). Coverage focuses on pure logic that has bitten before: number/time formatters, model edge cases, and rate-limit JSON parsing (including the float `used_percentage` regression). CI runs build + tests on every push/PR via GitHub Actions.

```
Sources/Oolong/
  App.swift               # @main; --probe branch + NSStatusItem/NSPopover host
  AppModel.swift          # @MainActor state machine, timers
  Models/                 # data models + formatters
  Services/               # ccusage, rate-limit file, system stats, caffeinate, login item
  Views/                  # SwiftUI panel + theme
```

## ⚠️ Known limitations

- **Rate-limit %** refreshes only while you're actively using Claude Code (status line renders). The **reset countdown stays accurate** regardless (it's an absolute timestamp). Idle for >2 min shows a "from last active session" note.
- **Lid-closed** changes a system power setting. If the app is force-killed while active, sleep stays disabled — restore manually:
  ```bash
  sudo pmset -a disablesleep 0
  ```
- Prebuilt binary is **arm64**; Intel needs a universal build.
- The `.app` is **ad-hoc signed** (no paid Developer ID), hence the first-launch Gatekeeper step.

## 🔒 Privacy

100% local. Oolong reads your local Claude Code logs (through `ccusage`) and the rate-limit file you opt into. The only network access is `ccusage` fetching **public** model-pricing data. No credentials are read, nothing is uploaded, no telemetry.

## 🤝 Contributing

Issues and PRs welcome. Keep it small, native, and dependency-light.

## 🙏 Acknowledgments

- [**ccusage**](https://github.com/ryoppippi/ccusage) — the token/cost engine.
- The Claude Code team for exposing `rate_limits` to status-line scripts.

## 📄 License

[MIT](LICENSE) © 2026 Damon Zhou.
