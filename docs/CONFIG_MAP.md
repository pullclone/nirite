# Nirite Configuration & Structure Map

This document describes the **authoritative structure** of the Nirite repository
and the **runtime guarantees** of the resulting image.

It exists to prevent ambiguity for:
- human contributors
- automated agents
- CI validation

This document answers:
- Where things live in the repo
- What gets installed into the final image
- What is guaranteed to exist at runtime
- What must NOT be modified unless explicitly instructed

---

## 1. Repository Structure (Authoritative)

### Root Directory
- `.github/`
  - GitHub Actions workflows and repository automation
- `.gitignore`
  - Git ignore rules
- `Containerfile`
  - Defines the container image build contract
  - Invokes `build_files/build.sh`
  - Copies `services/` into the final image
  - Runs `bootc container lint`
- `Justfile`
  - **Primary developer and agent interface**
  - Defines build, lint, test, VM, and CI workflows
- `LICENSE`
  - Project license
- `README.md`
  - High-level project overview
- `artifacthub-repo.yml`
  - Artifact Hub metadata
- `cosign.pub`
  - Public key for verifying signed images

---

### build_files/
- **Purpose:** Build-time assets and installer logic
- **Important:** Contents are *not* present in the final image unless explicitly installed.

Files:
- `build_files/build.sh`
  - **Single authoritative installer**
  - Responsible for:
    - installing packages
    - placing configuration files
    - enabling or preparing runtime behavior

Rule:
> If a file or config matters at runtime, `build.sh` must explicitly place it.

---

### services/
- **Purpose:** systemd user service definitions shipped with the image

Files:
- `services/plasma-polkit-agent.service`
  - Polkit agent service

Behavior:
- Entire directory is copied into:
```

/usr/lib/systemd/user/

```
- No other location is authoritative for shipped services

Rules:
- Services must pass `systemd-analyze verify`
- Services must only reference paths that exist in the final image

---

### disk_config/
- **Purpose:** VM and ISO image layout configuration
- **Not part of the base container runtime**

Files:
- `disk.toml`
- `iso.toml`
- `iso-gnome.toml`
- `iso-kde.toml`

Rules:
- These files affect **only** VM / ISO output
- They must NOT be modified unless explicitly requested
- Changes here are considered higher risk

---

### docs/
- **Purpose:** Canonical project documentation

Files:
- `ASSERTIONS.md`
- Defines runtime invariants and image guarantees
- `CONFIG_MAP.md` (this file)
- Defines structure, paths, and responsibility boundaries

---

## 2. Build-Time vs Runtime Boundary (Critical)

### Build-Time Only
- `build_files/`
- Build context mounts (`/ctx`)
- Temporary files and caches
- Any script logic not explicitly installing artifacts

### Runtime (Final Image)
- Files installed by `build.sh`
- `/usr/lib/systemd/user/*.service`
- OS files inherited from the Bazzite base image
- EFI artifacts required by `bootc-image-builder`

Agents must never assume build-time paths exist at runtime.

---

## 3. Runtime Path Guarantees

The following paths are guaranteed to exist in the final image:

### systemd User Services
- `/usr/lib/systemd/user/`
- Contains all shipped user service units
- Includes:
  - `plasma-polkit-agent.service`

### EFI / bootc Compatibility
At least one of the following exists:
- `/usr/lib/ostree-boot/efi/EFI/`
- `/boot/efi/EFI/`

With vendor directories:
- `EFI/fedora`
- `EFI/BOOT`

(Exact binaries may vary; see `ASSERTIONS.md`.)

---

## 4. Services Guaranteed by the Image

### plasma-polkit-agent.service
- Purpose:
- Provides a Polkit authentication agent
- Scope:
- systemd **user** service
- Source:
- `services/plasma-polkit-agent.service`
- Installation Path:
```

/usr/lib/systemd/user/plasma-polkit-agent.service

```

No other services are guaranteed unless documented in `ASSERTIONS.md`.

---

## 5. Binaries & Packages (High-Level)

The image includes binaries installed via:
- the Bazzite base image
- `build_files/build.sh`

Rules:
- No assumptions should be made about binary paths unless documented
- New runtime binaries must be:
- installed by `build.sh`
- documented in `ASSERTIONS.md` when relied upon

---

## 6. Agent Rules (Summary)

Agents working on this repo must:

- Treat this file and `ASSERTIONS.md` as authoritative
- Modify only:
- `build_files/` for installation logic
- `services/` for shipped services
- `Containerfile` for build contract changes
- Never modify `disk_config/` unless explicitly instructed
- Never invent additional install paths or mechanisms
- Update documentation when guarantees change

---

## 7. Relationship to ASSERTIONS.md

- `CONFIG_MAP.md` answers **where and how**
- `ASSERTIONS.md` answers **what must always be true**

Changes that affect runtime guarantees must update both.

This document defines structure.
`ASSERTIONS.md` defines invariants.
Together they form the agent contract.

