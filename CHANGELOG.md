# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
