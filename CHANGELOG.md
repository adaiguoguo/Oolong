# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - 2026-06-13

### Fixed
- **High energy use**: timers now pause completely while the panel is closed. Previously `ccusage` was spawned every 30s (~9s CPU) even when nobody was looking, which macOS flagged as "Using Significant Energy". Closed = zero work; open = 1s stats tick + usage refresh on open (throttled) and every 60s while visible.

### Changed
- Repositioned README around the real differentiators (zero-credential, all-in-one) with an honest comparison table vs. other Claude usage monitors.

### Docs
- Added FAQ covering notched-MacBook menu-bar hiding, multi-display behavior, the `env: node` PATH error, and `/usage` number differences.

## [1.0.0] - 2026-06-10

### Added
- Claude Code usage: today / week / month tokens & cost via `ccusage` (online pricing).
- Official 5h / 7d rate limits (% used + reset countdown) read from Claude Code's status-line `rate_limits` data — zero credentials, zero API calls.
- Burn rate and active-session indicator.
- Keep Awake: Standard (`caffeinate`) and Lid-closed (`pmset disablesleep`, admin), with Forever / 1h / 2h / 4h auto-off.
- System status: uptime, CPU, memory, battery.
- Launch at login (`SMAppService`).
- English / Chinese UI with in-app language switch; defaults to system language.
- Claude-inspired warm theme; fits small notched screens.
- Headless self-check (`--probe`) printing a verification JSON snapshot.
- Unit tests (swift-testing) for formatters, models, and rate-limit file parsing.
