# Nirite Configuration & Structure Map

This document is the authoritative map of:
- repository layout
- responsibility boundaries
- build-time vs runtime boundary

It intentionally avoids listing “must always be true” guarantees.
For invariants and testable guarantees, see `docs/ASSERTIONS.md`.

---

## Relationship to ASSERTIONS.md

- `CONFIG_MAP.md` answers **where things live** and **who owns what**.
- `ASSERTIONS.md` answers **what must always be true in the final image** and **how we test it**.

When you add new runtime behavior:
1) wire it in the correct place (structure, here)
2) add/adjust invariants (guarantees, in ASSERTIONS.md)

---

## 1) Repository Structure (Authoritative)

### Root
- `.github/`
  - GitHub Actions workflows & automation
- `Containerfile`
  - Image build contract:
    - mounts build context (`build_files/`) as `/ctx`
    - runs `/ctx/build.sh`
    - copies `services/` into the final image
    - runs `bootc container lint`
- `Justfile`
  - Primary interface for humans and agents (`just ci` is the golden path)
- `README.md`
  - Project overview
- `artifacthub-repo.yml`
  - Artifact Hub metadata
- `cosign.pub`
  - Public key for signatures
- `LICENSE`, `.gitignore`

---

## 2) Critical Boundary: Build-Time vs Runtime

### Build-Time Inputs (not present at runtime unless installed)
- `build_files/`
  - build-time scripts and assets
  - mounted as `/ctx` during build
  - **not copied** into the final image by default

### Runtime Outputs (present in final image)
- Anything explicitly installed into the image filesystem by `build_files/build.sh`
- systemd user unit files copied from `services/` into:
  - `/usr/lib/systemd/user/`

Rule of thumb:
> If it matters at runtime, `build_files/build.sh` must install it into the final image.

---

## 3) build_files/ (Installer Domain)

**Purpose:** the *only* supported installation mechanism.

- `build_files/build.sh`
  - installs packages
  - installs configs into final filesystem paths
  - prepares runtime behavior

**Constraints:**
- Do not introduce parallel install mechanisms unless explicitly documented.
- Do not assume anything under `build_files/` exists at runtime.

---

## 4) services/ (Runtime Wiring Domain)

**Purpose:** systemd *user* units shipped with the image.

- All `services/*.service` are copied into:
  - `/usr/lib/systemd/user/`

**Constraints:**
- Units must be syntactically valid (verify via `systemd-analyze verify` where available).
- Units must not reference nonexistent runtime paths.

---

## 5) disk_config/ (VM / ISO Domain)

**Purpose:** VM / ISO output layout configuration only.

- `disk_config/*.toml` affects VM / ISO builds, not the base container runtime.

**Policy:**
- Do not modify `disk_config/` unless explicitly requested.

---

## 6) docs/ (Documentation Domain)

- `docs/CONFIG_MAP.md` (this file)
  - structure, boundaries, responsibilities
- `docs/ASSERTIONS.md`
  - runtime invariants + machine-checkable assertions + test contract

---

## 7) Quick “Where should I change X?” Guide

- Add/modify packages or install configs:
  - `build_files/build.sh` (and any build_files assets it installs)
- Add/modify shipped user services:
  - `services/*.service`
- Change the build contract (mount/copy/commit/lint behavior):
  - `Containerfile`
- Change VM/ISO layout behavior:
  - `disk_config/*.toml` (only when explicitly requested)
- Define or tighten runtime guarantees:
  - `docs/ASSERTIONS.md`

---

## 8) Component Runtime Map (Evolving)

This section documents **intended runtime locations**.
Values may be `TBD` until finalized.

- niri
  - binary: TBD
  - config: TBD
- noctalia-shell
  - binary: TBD
  - desktop file: TBD
- fuzzel
  - binary: TBD
  - config: TBD
