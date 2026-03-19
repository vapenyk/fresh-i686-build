# fresh — i686 Optimized Builds

Automated builds of [Fresh IDE](https://github.com/sinelaw/fresh) for older 32-bit x86 processors, with a config tuned for low-end hardware.

## Binaries

| File | Target | Requires |
|------|--------|----------|
| `fresh-k8-sse3` | AMD K8 / Sempron (Socket 754/939) | SSE3 (pni) |
| `fresh-pentium4` | Pentium 4 and compatible | SSE2 only |

Not sure which one you need? Run:
```sh
grep -ow 'pni' /proc/cpuinfo | head -1
```
If it prints `pni` — use `fresh-k8-sse3`. Otherwise — `fresh-pentium4`.

Both binaries are statically linked (musl + zig) and have no external dependencies.

---

## Config

The installer places a `config.json` at `~/.config/fresh/config.json`. The goal is not to strip functionality, but to prevent resource runaway on machines with limited RAM.

### What is actually changed and why

**`recovery_save_interval: 30`** (default: 2)  
Fresh saves a crash-recovery snapshot every N seconds. At 2 seconds this causes constant background disk I/O which is very noticeable on slow HDDs. Raised to 30 — your work is still protected on crash, just with a slightly wider window.

**`auto_save_enabled: false`** (default: off, keeping it off)  
Explicit periodic auto-save is kept disabled. Combined with recovery saves this means you won't lose work, but you control when the file is actually written.

**`terminal.jump_to_end_on_output: false`** (default: true)  
When a terminal in scrollback mode receives new output, Fresh normally forces a redraw and jumps back to the bottom. On slow machines this causes jitter when background processes produce output. Disabled — you scroll back manually when you want.

**`horizontal_scrollbar: false`** (default: off, keeping it off)  
Fewer UI elements to render. Vertical scrollbar is kept.

**`whitespace_indicators: false`** (default: off, keeping it off)  
Rendering space/tab characters requires an extra pass per line. Kept off unless you need it.

**LSP `process_limits`** — the main optimization  
This is the only meaningful memory optimization in the config. Without limits, rust-analyzer alone can consume 500MB–1GB. The limits are set conservatively:

| Server | Max RAM | Max CPU |
|--------|---------|---------|
| rust (rust-analyzer) | 512 MB | 50% |
| go (gopls) | 256 MB | 50% |
| javascript (typescript-language-server) | 256 MB | 50% |
| markdown (marksman) | 128 MB | 25% |
| php (intelephense) | 256 MB | 50% |

If a server exceeds the limit Fresh kills and restarts it. You may see a brief pause in diagnostics but the editor stays responsive.

Everything else — bracket matching, inline diagnostics, line wrap, scrollbars, auto-close, multi-cursor, code folding — is left at defaults. These are editor-side features and cost negligible CPU/RAM.

---

### Enabling or disabling an LSP server

To turn off a server you don't need, set `"enabled": false`:
```json
"lsp": {
  "rust": { "enabled": false }
}
```

To turn on typescript (disabled by default in this config):
```json
"lsp": {
  "typescript": { "enabled": true }
}
```

### Adjusting memory limits

If you have more RAM and want better LSP performance, raise the limit:
```json
"lsp": {
  "rust": {
    "enabled": true,
    "process_limits": {
      "max_memory_mb": 1024,
      "max_cpu_percent": 100
    }
  }
}
```

Or remove `process_limits` entirely to let the server use however much it wants.

### Adding an LSP server not in the list

For any language not configured here, add it to the `lsp` section:
```json
"lsp": {
  "python": {
    "command": "pylsp",
    "args": [],
    "enabled": true,
    "process_limits": {
      "max_memory_mb": 256,
      "max_cpu_percent": 50
    }
  }
}
```

You also need the server installed. Fresh will pick it up automatically for built-in languages (Rust, Go, JS/TS, Python, C/C++, Zig, Java, LaTeX, Markdown). For anything else, add a `languages` entry too — see the [Fresh configuration docs](https://github.com/sinelaw/fresh).

### LSP servers install commands

| Language | Server | Install |
|----------|--------|---------|
| Rust | rust-analyzer | `rustup component add rust-analyzer` |
| Go | gopls | `go install golang.org/x/tools/gopls@latest` |
| JS/TS | typescript-language-server | `npm install -g typescript-language-server typescript` |
| PHP | intelephense | `npm install -g intelephense` |
| Markdown | marksman | Download from [marksman releases](https://github.com/artempyanykh/marksman/releases) |
| Python | pylsp | `pip install python-lsp-server` |
| C/C++ | clangd | `apt install clangd` |

---

## Installer

A POSIX-compatible shell script that handles install, updates and removal for both the binary and the config.

### Download

```sh
curl -fsSL https://raw.githubusercontent.com/fresh-i686-build/main/fresh-install.sh -o fresh-install.sh
chmod +x fresh-install.sh
```

### Commands

```sh
./fresh-install.sh install   # detect CPU variant, download binary + config
./fresh-install.sh update    # update binary and config to latest
./fresh-install.sh remove    # remove binary, config, and metadata
./fresh-install.sh status    # show installed version, variant, config path, PATH check
```

`install` and `update` ask about the binary and config separately — you can update one without the other. `remove` also asks about the config separately.

---

## Automatic Updates

This repository checks for new upstream releases every night at 00:00 UTC. When a new version is published, both variants are built and attached to a release automatically.

---

## File Layout in This Repository

```
.github/workflows/build-fresh-i686.yml   — nightly CI workflow
fresh-install.sh                          — installer script
config.json                               — low-end user config
README.md
```

---

## Why This Exists

Fresh IDE does not publish pre-built Linux binaries, and its build toolchain assumes a modern x86-64 host. Older machines — Semprons, early Athlons, Pentium 4s — are still perfectly capable of running a lightweight text editor, but lack the ability to compile it themselves due to RAM and toolchain constraints. This repo fills that gap.
