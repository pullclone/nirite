# Nirite

Nirite is a containerised desktop image built on top of [Bazzite](https://bazzite.gg/) and the developer‑focused [Bazzite‑DX](https://dev.bazzite.gg/). Bazzite provides a Fedora Atomic base with image‑based updates, pre‑installed gaming tools and drivers, while Bazzite‑DX layers in developer tooling such as container runtimes, devcontainers and a rich CLI environment. Nirite extends this foundation with a modern Wayland desktop stack centred around the [niri](https://github.com/YaLTeR/niri) compositor, the [Noctalia shell](https://noctalia.dev/) and the fuzzel launcher. The goal of this project is to remain as close as possible to upstream Bazzite while shipping a cohesive Niri‑powered desktop experience.

## Why Niri + Noctalia?

Niri is a scrollable‑tiling Wayland compositor inspired by PaperWM. It provides a continuous, horizontally scrollable workspace across multiple monitors, seamless tiling of windows, support for tabs and layers, gestures, scratchpads and full Xwayland compatibility. Written in Rust, Niri aims to be efficient, predictable and minimal. By pairing Niri with the **Noctalia** shell you gain a complete desktop environment: Noctalia is a beautiful, minimal Wayland shell built on Quickshell. It features a warm lavender aesthetic, dynamic colour schemes via Matugen, built‑in panels, docks, notifications and a lock screen, and it is easy to customise. Noctalia supports multiple Wayland compositors; Nirite ships it pre‑configured for Niri.

## What’s Included

The image includes the Bazzite and Bazzite‑DX defaults along with extra packages to make Niri and Noctalia usable out‑of‑the‑box. Highlights include:

-   **Wayland desktop**: `niri` compositing manager, `noctalia-shell`, and `fuzzel` application launcher.
    
-   **Display & hardware**: `gdm` display manager, `bluez` for Bluetooth, `brightnessctl` and `wlsunset` for brightness/colour temperature, and `astroterm` for star tracking.
    
-   **Audio & media**: `cava` terminal audio visualiser, `evolution-data-server` for GNOME Online Accounts.
    
-   **Shell & terminals**: `kitty` terminal emulator, `tmux` multiplexer, `micro` and `emacs` editors, `typespeed` typing game, and `astroterm`.
    
-   **CLI enhancers**: `starship` prompt, `zoxide` (fast directory jumper), `navi` (cheat‑sheet tool), `glow` (Markdown previewer), `btop` system monitor, `age` encryption tool, `eza` (modern `ls` replacement) and `trash-cli`.
    
-   **Developer tools**: `python3` with [`uv`](https://pypi.org/project/uv/) for Python packaging, `rustup` for managing Rust toolchains, `docker-buildkit` and `docker-distribution` alongside the Bazzite‑DX container stack, `iproute` and `mtr` for networking, and `ollama` for AI models.
    
-   **System integration**: `gnome-keyring`, `gnupg2` and `gnupg2-keyboxd` (with stub man pages to satisfy systemd), `polkit-kde` authentication agent and `xwayland-satellite` for Xwayland bridging.
    
-   **File manager**: `nautilus` file browser.
    

During the build process the script installs stub manual pages for `mpris-proxy` and `keyboxd`, ensures the GnuPG keybox daemon is at the expected path, and enables the `podman.socket` service for container builds. KDE packages are removed to avoid conflicts with the Niri environment.

## Repository Layout

The repository is organised to make contributions safe and predictable:

| Path | Purpose |
| --- | --- |
| `Containerfile` | Multi‑stage container build. It starts from `ghcr.io/ublue-os/bazzite-dx:stable`, copies `services/` into `/usr/lib/systemd/user/`, mounts `build_files/` as `/ctx` and runs `/ctx/build.sh`, then performs `ostree container commit` and `bootc container lint`[github.com](https://github.com/pullclone/nirite/blob/main/Containerfile#L2-L19)[github.com](https://github.com/pullclone/nirite/blob/main/Containerfile#L65-L72). |
| `build_files/` | Build‑time scripts and assets. `build.sh` installs packages (see above), configures stub man pages and services, and cleans caches[github.com](https://github.com/pullclone/nirite/blob/main/build_files/build.sh#L1-L75)[github.com](https://github.com/pullclone/nirite/blob/main/build_files/build.sh#L76-L125). Contents of this directory are not copied to the final image; anything required at runtime must be installed by `build.sh`[github.com](https://github.com/pullclone/nirite/blob/main/docs/CONFIG_MAP.md#L49-L61). |
| `services/` | Systemd **user** units that are copied into `/usr/lib/systemd/user/` in the final image[github.com](https://github.com/pullclone/nirite/blob/main/docs/CONFIG_MAP.md#L80-L86). Nirite ships a `plasma-polkit-agent.service` unit to start the KDE polkit agent[github.com](https://github.com/pullclone/nirite/blob/main/services/plasma-polkit-agent.service#L1-L12). |
| `disk_config/` | Partitioning and installer configuration for VM/ISO builds (e.g., `disk.toml`, `iso.toml`)[github.com](https://github.com/pullclone/nirite/blob/main/disk_config/disk.toml#L1-L7). These files define minimum sizes for `/` and `/boot` and include a kickstart post script that rebases onto the Nirite image via `bootc switch`[github.com](https://github.com/pullclone/nirite/blob/main/disk_config/iso.toml#L2-L19)[github.com](https://github.com/pullclone/nirite/blob/main/disk_config/iso-gnome.toml#L2-L20)[github.com](https://github.com/pullclone/nirite/blob/main/disk_config/iso-kde.toml#L2-L21). Do not modify this directory unless explicitly instructed[github.com](https://github.com/pullclone/nirite/blob/main/docs/CONFIG_MAP.md#L93-L101). |
| `docs/` | Documentation for maintainers. `AGENTS.md` explains how to work in this repository and lists golden rules[github.com](https://github.com/pullclone/nirite/blob/main/docs/AGENTS.md#L18-L28); `CONFIG_MAP.md` maps repository structure and boundaries[github.com](https://github.com/pullclone/nirite/blob/main/docs/CONFIG_MAP.md#L24-L61); `ASSERTIONS.md` defines runtime invariants and machine‑checkable tests, including that Niri, Noctalia and Fuzzel binaries must be present[github.com](https://github.com/pullclone/nirite/blob/main/docs/ASSERTIONS.md#L65-L73). |
| `Justfile` | Defines convenient tasks for building, testing and running the image. Notable recipes include: |

-   `just lint`: run shellcheck and verify systemd units;
    
-   `just build` / `just build type=iso|raw|qcow`: build a container image or disk image;
    
-   `just run`: run the built image in QEMU;
    
-   `just test`: perform runtime assertions defined in `docs/ASSERTIONS.md`[github.com](https://github.com/pullclone/nirite/blob/main/Justfile#L146-L170);
    
-   `just ci`: run lint, build and test; used by CI workflows[github.com](https://github.com/pullclone/nirite/blob/main/docs/ASSERTIONS.md#L86-L94). |  
    | `.github/workflows/` | GitHub Actions for continuous integration. The `ci.yml` workflow installs `just`, sets up `podman`, builds the container and runs the tests[github.com](https://github.com/pullclone/nirite/blob/main/.github/workflows/ci.yml#L2-L16)[github.com](https://github.com/pullclone/nirite/blob/main/.github/workflows/ci.yml#L17-L34). |
    

## Building and Running

To build Nirite locally you’ll need Podman, Bootc Image Builder and the `just` command. Clone this repository, then run:

`just build          # build the container and produce an OCI image just run            # boot the image in a VM (requires QEMU) just test           # run runtime assertions`

To produce a bootable raw or ISO image, pass `type=raw` or `type=iso` to the `build` recipe. Bootc Image Builder will use the `disk_config` TOML files to partition the disk and produce a bootable artefact.

### Rebasing an Existing System

Because Nirite is built as an ostree container image, you can rebase an existing Bazzite or Fedora Atomic installation onto it. After verifying the image tag on your registry, run:

`sudo bootc switch --mutate-in-place --transport registry ghcr.io/pullclone/nirite:latest`

This will download the Nirite image, mutate your ostree deployment and set Niri/Noctalia as the desktop stack. You can roll back to your previous deployment via the bootloader menu.

### Updating

Nirite benefits from Bazzite’s image‑based updates: new releases are distributed as signed container images and applied atomically. To update, simply run:

`sudo bootc update`

Bootc will fetch the latest Nirite image from the registry; if anything goes wrong you can boot into the previous deployment via the boot menu.

## Contributing

If you wish to modify Nirite, please read `docs/AGENTS.md` and `docs/CONFIG_MAP.md` first. Some key guidelines[github.com](https://github.com/pullclone/nirite/blob/main/docs/AGENTS.md#L18-L28)[github.com](https://github.com/pullclone/nirite/blob/main/docs/CONFIG_MAP.md#L65-L77):

-   Keep as close to upstream Bazzite as possible; avoid unnecessary changes.
    
-   Install new packages and configuration via `build_files/build.sh` rather than ad‑hoc mechanisms.
    
-   When adding or modifying services, place unit files in `services/` and ensure they are enabled or started appropriately.
    
-   Do not edit anything under `disk_config/` unless explicitly requested.
    
-   Use `just` tasks to build, lint and test your changes; CI requires `just ci` to succeed[github.com](https://github.com/pullclone/nirite/blob/main/docs/ASSERTIONS.md#L86-L94).
    
-   Update `docs/ASSERTIONS.md` if you add new runtime guarantees.
    

## License and Credits

This repository is licensed under the **Apache License 2.0**[github.com](https://github.com/pullclone/nirite/blob/main/LICENSE#L1-L5). Nirite would not exist without the work of the upstream projects:

-   **Bazzite** and **Bazzite‑DX** — provide the base image, GPU drivers, gaming tweaks and developer tooling[bazzite.gg](https://bazzite.gg/#:~:text=The%20operating%20system%20for%20the,next%20generation%20of%20gamers)[docs.bazzite.gg](https://docs.bazzite.gg/Dev/#:~:text=Bazzite%20for%20Developers%C2%B6).
    
-   **Niri** — scrollable‑tiling Wayland compositor[gvolpe.com](https://gvolpe.com/blog/niri/#:~:text=A%20new%20tiling%20Wayland%20compositor).
    
-   **Noctalia** — minimal Quickshell‑based Wayland shell[github.com](https://github.com/noctalia-dev/noctalia-shell#:~:text=A%20beautiful%2C%20minimal%20desktop%20shell,customize%20to%20match%20your%20vibe)[docs.noctalia.dev](https://docs.noctalia.dev/#:~:text=About%20Noctalia).
    
-   **Fuzzel** — slick application launcher.
    
-   **uBlue OS / Universal Blue** — maintain the container tooling and continuous integration.
    

Please see the linked upstream projects for support, documentation and inspiration. We hope you enjoy using Nirite!
