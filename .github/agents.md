# Nirite Agent Instructions (read first)

## What this repo is
This repo builds a custom Bazzite/uBlue image ("nirite") using:
- niri (Wayland WM)
- noctalia-shell
- fuzzel launcher
Goal: stay close to upstream Bazzite while adding the niri + desktop stack.

## Repo map (where things live)
- Containerfile: base image + copies build_files/ and services/ into the image.
- build_files/: build scripts + config assets copied into the image during build.
- services/: systemd user services (installed into /usr/lib/systemd/user or equivalent).
- disk_config/: image/disk layout config (treat as sensitive; don’t change unless asked).
- .github/: CI workflows (must keep green).
- Justfile: the blessed developer interface (use `just ...` whenever possible).

## Golden rules
1) Prefer minimal, upstream-aligned changes.
2) Never “invent” config locations — locate existing configs in this repo first.
3) When adding software: do it in the same mechanism the repo already uses
   (Containerfile vs build_files/build.sh vs layered package list).
4) When changing systemd units: add/update files in services/ and ensure enablement logic exists.
5) Do not touch disk_config/ unless the task explicitly requires it.
6) All PRs must include:
   - What changed
   - Why
   - How to test (commands + expected output)

## Standard workflow (always do this)
- Start by scanning: README.md, Containerfile, Justfile, build_files/, services/, .github/workflows/
- Use `just` recipes for build/test/lint if present.
- If no recipe exists, propose adding one rather than ad-hoc commands.

## Testing expectations
- Provide a local build path (container build) and CI path (GitHub Actions) if available.
- For config-only changes: include a fast validation (syntax checks, unit file checks, etc).

## Output format for changes
- A short plan
- Then a patch (or file list + diff summary)
- Then exact test commands
- Then risk notes (what could break)
