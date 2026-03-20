---
layout: default
title: "fresh-editor — i686 builds"
---

## Binaries

| File | Target | Requires |
|------|--------|----------|
| `fresh-k8-sse3` | AMD K8 / Sempron (Socket 754/939) | SSE3 (`pni`) |
| `fresh-pentium4` | Pentium 4 and compatible | SSE2 only |

Not sure which one you need? Run:

```sh
grep -ow 'pni' /proc/cpuinfo | head -1
```

If it prints `pni` — use `fresh-k8-sse3`. Otherwise — `fresh-pentium4`.

Both binaries are statically linked (musl + zig) and have no external dependencies.

Each release includes a `SHA256SUMS` file. Verify after download:

```sh
sha256sum -c SHA256SUMS
```

---

## Installer

A POSIX-compatible shell script that handles install, updates and removal for both the binary and the config.

### Download

```sh
curl -fsSL https://raw.githubusercontent.com/vapenyk/fresh-i686-build/main/fresh-install.sh \
  -o fresh-install.sh
chmod +x fresh-install.sh
```

### Commands

```sh
./fresh-install.sh install   # detect CPU variant, download binary + config
./fresh-install.sh update    # update binary and config to latest
./fresh-install.sh remove    # remove binary, config, and metadata
./fresh-install.sh status    # show installed version, variant, config path, PATH check
```

`install` and `update` ask about the binary and config separately. `remove` asks about the config separately. The installer verifies SHA256 checksums after every download.

---

## Config

The installer places `config.json` at `~/.config/fresh/config.json`. The goal is not to strip functionality but to prevent resource runaway on machines with limited RAM.

### What is changed and why

| Setting | Value | Why |
|---------|-------|-----|
| `recovery_save_interval` | 30s | Constant disk I/O every 2s is noticeable on slow HDDs |
| `auto_save_enabled` | false | Recovery saves still protect your work |
| `terminal.jump_to_end_on_output` | false | Prevents forced redraws while scrolling |
| `horizontal_scrollbar` | false | Fewer UI elements to render |
| LSP `process_limits` | per server | rust-analyzer alone can use 500 MB+ without limits |

### LSP memory limits

| Server | Max RAM | Max CPU | Status |
|--------|---------|---------|--------|
| rust-analyzer | 512 MB | 50% | enabled |
| gopls | 256 MB | 50% | enabled |
| typescript-language-server | 256 MB | 50% | enabled |
| intelephense (PHP) | 256 MB | 50% | enabled |
| marksman (Markdown) | 128 MB | 25% | enabled |
| typescript (separate) | 256 MB | 50% | disabled |

If a server exceeds the limit Fresh kills and restarts it. You may see a brief pause in diagnostics but the editor stays responsive.

### Disable an LSP you don't need

```json
{ "lsp": { "rust": { "enabled": false } } }
```

### Raise memory limit

```json
{
  "lsp": {
    "rust": {
      "enabled": true,
      "process_limits": { "max_memory_mb": 1024, "max_cpu_percent": 100 }
    }
  }
}
```

### Add Python LSP

```json
{
  "lsp": {
    "python": {
      "command": "pylsp", "args": [], "enabled": true,
      "process_limits": { "max_memory_mb": 256, "max_cpu_percent": 50 }
    }
  }
}
```

### LSP server install commands

| Language | Server | Install |
|----------|--------|---------|
| Rust | rust-analyzer | `rustup component add rust-analyzer` |
| Go | gopls | `go install golang.org/x/tools/gopls@latest` |
| JS/TS | typescript-language-server | `npm install -g typescript-language-server typescript` |
| PHP | intelephense | `npm install -g intelephense` |
| Markdown | marksman | [marksman releases](https://github.com/artempyanykh/marksman/releases) |
| Python | pylsp | `pip install python-lsp-server` |
| C/C++ | clangd | `apt install clangd` |

---

## Automatic Updates

This repository checks for new upstream releases every night at 00:00 UTC via GitHub Actions. When a new version is published, both variants are built and attached to a release automatically. Run `./fresh-install.sh update` any time to pull the latest.

---

## File Layout

```
.github/workflows/build-fresh-i686.yml   — nightly CI: build + release
.github/workflows/lint.yml               — shellcheck on shell scripts
_layouts/default.html                    — Jekyll site template
_data/nav.yml                            — navigation items
_config.yml                              — Jekyll configuration
index.md                                 — site content (this page)
fresh-install.sh                         — installer script
config.json                              — low-end editor config
README.md                                — GitHub repository overview
```

---

## Why This Exists

Fresh IDE does not publish pre-built Linux binaries, and its build toolchain assumes a modern x86-64 host. Older machines — Semprons, early Athlons, Pentium 4s — are still perfectly capable of running a lightweight text editor, but lack the ability to compile it themselves due to RAM and toolchain constraints. This repo fills that gap.
