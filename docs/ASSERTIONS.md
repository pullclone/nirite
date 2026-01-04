# Nirite Image Assertions

This document defines **invariants** for the Nirite image.
If any assertion here becomes false, the image is considered broken.

These assertions are intended to be:
- human-readable
- agent-readable
- incrementally enforceable via `just test`

They describe *what the image guarantees*, not how it is built.

---

## 1. Build & Image-Level Assertions

These must be true for every successful build:

- The image builds successfully from `Containerfile`.
- `ostree container commit` completes successfully during build.
- `bootc container lint` passes in the final image stage.
- The resulting image can:
  - be inspected (`podman image inspect …`)
  - start a container and execute `/bin/sh`

---

## 2. Installer Model Assertions (build_files)

- `build_files/` contents are **not present** in the final image by default.
- All files, configs, or binaries originating from `build_files/` must be:
  - explicitly installed into the image filesystem by `build_files/build.sh`
- `build_files/build.sh` is the **only** supported installation mechanism.
- No parallel installation paths (e.g. ad-hoc `RUN dnf install …`) are allowed unless explicitly documented.

Rule of thumb:
> If it matters at runtime, it must be placed there by `build.sh`.

---

## 3. systemd User Services Assertions

- All systemd user services shipped by Nirite:
  - originate from `services/*.service`
  - are copied into the image at:
    ```
    /usr/lib/systemd/user/
    ```
- Unit files must:
  - pass `systemd-analyze verify`
  - not reference paths that are not present in the final image
- No unit files are generated dynamically at runtime unless explicitly documented.

---

## 4. EFI / bootc Image Builder Assertions

The image must satisfy `bootc-image-builder` expectations:

- At least one of the following EFI directory trees exists:
  - `/usr/lib/ostree-boot/efi/EFI/`
  - `/boot/efi/EFI/`
- The following vendor directories must exist:
  - `EFI/fedora`
  - `EFI/BOOT`
- The build attempts to populate:
  - `BOOTX64.EFI` (shim)
  - `grubx64.efi` (grub)
- Absence of shim/grub binaries is tolerated **only if** the build logs explicitly warn and continue.

These assertions exist to prevent silent regressions in VM / ISO builds.

---

## 5. Desktop Stack Presence (High-Level)

Nirite is expected to ship a Wayland desktop stack including:

- niri (Wayland compositor)
- noctalia-shell
- fuzzel (launcher)

At minimum:
- binaries must exist in the final image
- versions must be queryable (e.g. `--version`)

**Exact paths and configs may vary and should be tightened over time.**

---

## 6. Configuration Assertions (Initial, Non-Strict)

- Default configs, if provided, must be placed in documented system locations
  (e.g. `/usr/share/…`, `/etc/…`)
- No assumptions are made about `$HOME` or per-user state at image build time.
- Any default configuration paths introduced must be documented here.

---

## 7. disk_config Invariants

- `disk_config/*.toml` files:
  - define VM / ISO output layout only
  - must not affect the base container image
- These files must not be modified unless explicitly requested.

---

## 8. Testing Contract

The following commands are considered authoritative:

- Local validation:
- just ci
- `ci` must include:
- linting (scripts + unit files)
- image build
- smoke tests verifying these assertions

If an assertion cannot yet be tested automatically:
- it must still be listed here
- and tightened in a future change

---

## 9. Change Discipline

When modifying the image:
- Update this document **if and only if** the guarantees change.
- Prefer tightening assertions over weakening them.
- Every new runtime guarantee should eventually appear here.

This document is the contract between:
- the image
- its maintainers
- and any automated agent working on the repo.
