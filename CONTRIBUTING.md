# Contributing to Oolong

Thanks for your interest! Oolong aims to stay **small, native, and dependency-light** — please keep PRs in that spirit.

## Development setup

```bash
git clone https://github.com/adaiguoguo/Oolong.git
cd Oolong
make build      # swift build
make test       # swift test (swift-testing)
make probe      # headless data self-check (needs ccusage installed)
make bundle     # assemble dist/Oolong.app
```

Requirements: macOS 13+, Swift 5.9+ (Xcode or Command Line Tools), [`ccusage`](https://github.com/ryoppippi/ccusage) for runtime data.

## Before you open a PR

1. `swift test` passes.
2. `make probe` returns `ok: true` and numbers consistent with `ccusage` output.
3. If you touched UI strings, provide both English and Chinese via `I18n.t(en, zh)`.
4. No new runtime dependencies without prior discussion in an issue.

## Reporting bugs

Please include: macOS version, chip (Apple Silicon / Intel), Claude Code version, whether the status-line integration (`~/.claude/ccbar-ratelimits.json`) is set up, and the output of `make probe`.
