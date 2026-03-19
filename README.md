# fresh — i686 Optimized Builds

Automated builds of [Fresh IDE](https://github.com/sinelaw/fresh) for older 32-bit x86 processors.

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

## Installer

A POSIX-compatible shell script that handles install, updates and removal.

### Download

```sh
curl -fsSL https://raw.githubusercontent.com/ТВОЙ_ЮЗЕР/ТВОЙ_РЕПО/main/fresh-install.sh -o fresh-install.sh
chmod +x fresh-install.sh
```

### Commands

```sh
./fresh-install.sh install   # detect CPU variant, download, place binary
./fresh-install.sh update    # check for new version and update
./fresh-install.sh remove    # uninstall binary and metadata
./fresh-install.sh status    # show installed version, variant, PATH check
```

### What install does

1. Reads `/proc/cpuinfo` and suggests the right variant for your CPU
2. Asks for confirmation or lets you pick manually
3. Asks where to install (default: `~/.local/bin`)
4. Downloads the binary, makes it executable, renames it to `fresh`
5. If the install directory is not in `$PATH`, shows you the line to add

Installation metadata (variant, version, install path) is saved to  
`~/.local/share/fresh-installer/install.meta` so that `update` knows  
exactly which binary to fetch next time without asking again.

---

## Automatic updates

This repository checks for new upstream releases every night at 00:00 UTC.  
When a new version of Fresh IDE is published, both variants are built and  
attached to a matching release automatically.

---

## Why this exists

Fresh IDE does not publish pre-built Linux binaries, and its build toolchain  
assumes a modern x86-64 host. Older machines — Semprons, early Athlons,  
Pentium 4s — are still perfectly capable of running a lightweight text editor,  
but lack the ability to compile it themselves due to RAM and toolchain  
constraints. This repo fills that gap.
