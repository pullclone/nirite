# Nirite Image Assertions

This document defines **runtime invariants** for the Nirite image:
what must always be true in the final image and how we validate it.

It intentionally avoids duplicating repository layout details.
For repo structure and responsibility boundaries, see `docs/CONFIG_MAP.md`.

---

## Relationship to CONFIG_MAP.md

- `CONFIG_MAP.md` answers **where things live** and **who owns what**.
- `ASSERTIONS.md` answers **what must always be true** in the *final image*.

If you change:
- installer logic → update assertions that depend on installed artifacts
- services → update assertions about shipped units
- build contract → update build/lint assertions and CI expectations

---

## 1) Core Build Contract Invariants

A valid build must satisfy:

- The image builds successfully from `Containerfile`.
- The build performs `ostree container commit`.
- The final stage runs and passes `bootc container lint`.
- The resulting image can be started and execute `/bin/sh`.

---

## 2) Installer Model Invariants

- `build_files/` is build-time input only.
- No runtime file/config/binary may be “assumed” to exist unless installed into the final filesystem by `build_files/build.sh`.

(For the boundary and file locations, see `docs/CONFIG_MAP.md`.)

---

## 3) Shipped systemd User Services Invariants

- Shipped user units must be present under:
  - `/usr/lib/systemd/user/`
- Unit files must be syntactically valid (`systemd-analyze verify` where available).
- Unit files must not reference missing runtime paths.

---

## 4) EFI / bootc-image-builder Compatibility Invariants

The image must satisfy bootc-image-builder expectations:

- At least one EFI directory tree exists:
  - `/usr/lib/ostree-boot/efi/EFI/` OR `/boot/efi/EFI/`
- Vendor directories exist:
  - `EFI/fedora` and `EFI/BOOT`

This exists to prevent silent regressions in VM/ISO builds.

---

## 5) Desktop Stack Invariants (Initial / Non-Strict)

Nirite is expected to ship a Wayland desktop stack including:
- niri
- noctalia-shell
- fuzzel

At minimum (for now):
- binaries should be present and version-queryable (`--version`) once paths are stabilized

These are intentionally non-strict until canonical paths are confirmed.

---

## 6) disk_config Policy Invariant

- `disk_config/` is VM/ISO-only and must not be modified unless explicitly requested.
(Structure and intent are defined in `docs/CONFIG_MAP.md`.)

---

## 7) Testing Contract

Authoritative command:
- `just ci`

Expected meaning:
- `just lint && just build && just test`

No change is considered complete unless `just ci` succeeds (or a failure is explicitly explained and approved).

---

## 8) Machine-Checkable Assertions (Authoritative)

The following structured assertions are intended to be consumed by automation
(`just test`, CI, and agent tooling). This section is authoritative.

build_contract:
  containerfile:
    required: true
    runs:
      - ostree container commit
      - bootc container lint
  installer:
    path: build_files/build.sh
    exclusive: true

runtime_paths:
  must_exist:
    - /usr/lib/systemd/user
  efi_roots:
    any_of:
      - /usr/lib/ostree-boot/efi/EFI
      - /boot/efi/EFI
  efi_vendors:
    must_exist:
      - fedora
      - BOOT

systemd_user_services:
  source_dir: services
  install_dir: /usr/lib/systemd/user
  services:
    - name: plasma-polkit-agent.service
      required: true
      scope: user
  constraints:
    verify_with: systemd-analyze verify
    forbid_missing_paths: true

binaries:
  required_present:
    - name: niri
      strict: false
    - name: noctalia-shell
      strict: false
    - name: fuzzel
      strict: false

disk_config:
  path: disk_config
  scope: vm_iso_only
  mutation_policy: forbidden_unless_explicit

testing_contract:
  authoritative_command: just ci
  ci_definition:
    - just lint
    - just build
    - just test
  completion_rule: "No change is complete unless just ci succeeds."

agent_constraints:
  must_read:
    - AGENTS.md
    - docs/ASSERTIONS.md
    - docs/CONFIG_MAP.md
  forbidden_actions:
    - modify disk_config without explicit instruction
    - introduce parallel install mechanisms
    - assume build_files contents exist at runtime
  preferred_interface: just

evolution_rules:
  allowed:
    - tighten assertions
    - add new assertions
  discouraged:
    - weakening existing assertions
  requirement: "Runtime guarantee changes must update this section."

---

## 9) Change Discipline

* Tighten assertions over time; avoid weakening them.
* Any new runtime guarantee should eventually appear in the machine-checkable section.
