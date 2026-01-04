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

## Build truth (authoritative)
- build_files/build.sh runs during image build via /ctx mount.
  - build_files/ is NOT copied into the final image.
  - Therefore: any config assets must be explicitly installed into the image filesystem by build.sh.
- services/ is copied into /usr/lib/systemd/user/ in the final image.
- After build.sh, we run: `ostree container commit`
- Final image is validated by: `bootc container lint` (runs in Containerfile)

Agent rules:
- If you need to change packages/config: edit build_files/build.sh (and any assets under build_files/) and ensure build.sh installs them into final locations.
- If you need to add/modify services: edit services/*.service and verify they land in /usr/lib/systemd/user/.
- Never assume configs in ~/.config inside the image unless build.sh explicitly creates defaults.

## Testing expectations
- Provide a local build path (container build) and CI path (GitHub Actions) if available.
- For config-only changes: include a fast validation (syntax checks, unit file checks, etc).

## Output format for changes
- A short plan
- Then a patch (or file list + diff summary)
- Then exact test commands
- Then risk notes (what could break)
