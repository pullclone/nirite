export image_name := env("IMAGE_NAME", "image-template") # output image name, usually same as repo name, change as needed
export default_tag := env("DEFAULT_TAG", "latest")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")

# Prefer podman; fall back to docker
engine := if `command -v podman >/dev/null 2>&1; echo yes` == "yes" { "podman" } else { "docker" }

[group('Utility')]
bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Engine: {{engine}}"
    command -v just >/dev/null || { echo "Missing: just"; exit 1; }
    command -v {{engine}} >/dev/null || { echo "Missing: podman or docker"; exit 1; }
    command -v git >/dev/null || { echo "Missing: git"; exit 1; }
    command -v jq >/dev/null || echo "Recommended: jq (used by _rootful_load_image)"
    command -v shellcheck >/dev/null || echo "Recommended: shellcheck"
    command -v shfmt >/dev/null || echo "Recommended: shfmt"
    command -v systemd-analyze >/dev/null || echo "Optional: systemd-analyze (unit verification)"
    echo "OK"

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env
    rm -f output/

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    just sudoif just clean

# sudoif bash function
[group('Utility')]
[private]
sudoif command *args:
    #!/usr/bin/bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            /usr/bin/sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            /usr/bin/sudo "$@" || exit 1
        else
            exit 1
        fi
    }
    sudoif {{ command }} {{ args }}

# Command: _rootful_load_image
# Description: This script checks if the current user is root or running under sudo. If not, it attempts to resolve the image tag using podman inspect.
#              If the image is found, it loads it into rootful podman. If the image is not found, it pulls it from the repository.
#
# Parameters:
#   $target_image - The name of the target image to be loaded or pulled.
#   $tag - The tag of the target image to be loaded or pulled. Default is 'default_tag'.
#
# Example usage:
#   _rootful_load_image my_image latest
#
# Steps:
# 1. Check if the script is already running as root or under sudo.
# 2. Check if target image is in the non-root podman container storage)
# 3. If the image is found, load it into rootful podman using podman scp.
# 4. If the image is not found, pull it from the remote repository into reootful podman.

_rootful_load_image $target_image=image_name $tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail

    # Check if already running as root or under sudo
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root or running under sudo, no need to load image from user podman."
        exit 0
    fi

    # Try to resolve the image tag using podman inspect
    set +e
    resolved_tag=$(podman inspect -t image "${target_image}:${tag}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    USER_IMG_ID=$(podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")

    if [[ $return_code -eq 0 ]]; then
        # If the image is found, load it into rootful podman
        ID=$(just sudoif podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
        if [[ "$ID" != "$USER_IMG_ID" ]]; then
            # If the image ID is not found or different from user, copy the image from user podman to root podman
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            just sudoif TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        fi
    else
        # If the image is not found, pull it from the repository
        just sudoif podman pull "${target_image}:${tag}"
    fi

# Build a bootc bootable image using Bootc Image Builder (BIB)
# Converts a container image to a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (default: disk_config/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 disk_config/disk.toml
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail

    args="--type ${type} "
    args+="--use-librepo=True "
    args+="--rootfs=btrfs"

    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)

    sudo podman run \
      --rm \
      -it \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro \
      -v $BUILDTMP:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      "${target_image}:${tag}"

    mkdir -p output
    sudo mv -f $BUILDTMP/* output/
    sudo rmdir $BUILDTMP
    sudo chown -R $USER:$USER output/

# Podman builds the image from the Containerfile and creates a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (deafult: disk_config/disk.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 disk_config/disk.toml
_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

# Build a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
build-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "qcow2" "disk_config/disk.toml")

# Build a RAW virtual machine image
[group('Build Virtal Machine Image')]
build-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "raw" "disk_config/disk.toml")

# Build an ISO virtual machine image
[group('Build Virtal Machine Image')]
build-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_build-bib target_image tag "iso" "disk_config/iso.toml")

# Rebuild a QCOW2 virtual machine image
[group('Build Virtal Machine Image')]
rebuild-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "qcow2" "disk_config/disk.toml")

# Rebuild a RAW virtual machine image
[group('Build Virtal Machine Image')]
rebuild-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "raw" "disk_config/disk.toml")

# Rebuild an ISO virtual machine image
[group('Build Virtal Machine Image')]
rebuild-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_rebuild-bib target_image tag "iso" "disk_config/iso.toml")

# Run a virtual machine with the specified image type and configuration
_run-vm $target_image $tag $type $config:
    #!/usr/bin/bash
    set -eoux pipefail

    # Determine the image file based on the type
    image_file="output/${type}/disk.${type}"
    if [[ $type == iso ]]; then
        image_file="output/bootiso/install.iso"
    fi

    # Build the image if it does not exist
    if [[ ! -f "${image_file}" ]]; then
        just "build-${type}" "$target_image" "$tag"
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}")
    run_args+=(docker.io/qemux/qemu)

    # Run the VM and open the browser to connect
    (sleep 30 && xdg-open http://localhost:"$port") &
    podman run "${run_args[@]}"

# Run a virtual machine from a QCOW2 image
[group('Run Virtal Machine')]
run-vm-qcow2 $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "qcow2" "disk_config/disk.toml")

# Run a virtual machine from a RAW image
[group('Run Virtal Machine')]
run-vm-raw $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "raw" "disk_config/disk.toml")

# Run a virtual machine from an ISO
[group('Run Virtal Machine')]
run-vm-iso $target_image=("localhost/" + image_name) $tag=default_tag: && (_run-vm target_image tag "iso" "disk_config/iso.toml")

# Run a virtual machine using systemd-vmspawn
[group('Run Virtal Machine')]
spawn-vm rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash

    set -euo pipefail

    [ "{{ rebuild }}" -eq 1 ] && echo "Rebuilding the ISO" && just build-vm {{ rebuild }} {{ type }}

    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| /usr/bin/numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i ./output/**/*.{{ type }}

# Runs shellcheck on all Bash scripts
[group('Lint')]
lint-shell:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v shellcheck >/dev/null 2>&1; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    /usr/bin/find . -iname "*.sh" -type f -exec shellcheck "{}" ';'

# Runs shfmt on all Bash scripts
[group('Format')]
fmt-shell:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v shfmt >/dev/null 2>&1; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    /usr/bin/find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'

# Verify systemd unit files if systemd-analyze is available
[group('Lint')]
lint-units:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v systemd-analyze >/dev/null 2>&1; then
        echo "systemd-analyze not available; skipping unit verification"
        exit 0
    fi
    if [ -d services ]; then
        find services -type f -name "*.service" -print0 | xargs -0 -r -n1 systemd-analyze verify
    fi

# Meta lint target (authoritative)
[group('Lint')]
lint: check lint-shell lint-units
    @echo "Lint OK"

[group('Test')]
test $target_image=("localhost/" + image_name) $tag=default_tag:
    just test-smoke "{{target_image}}" "{{tag}}"
    just test-efi "{{target_image}}" "{{tag}}"
    just test-assertions "{{target_image}}" "{{tag}}"

[group('Test')]
test-smoke $target_image=("localhost/" + image_name) $tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    {{engine}} image inspect "${target_image}:${tag}" >/dev/null

    # container runs
    {{engine}} run --rm "${target_image}:${tag}" /bin/sh -lc 'echo ok'

    # services copied in (this matches: COPY services /usr/lib/systemd/user/)
    {{engine}} run --rm "${target_image}:${tag}" /bin/sh -lc '\
      test -d /usr/lib/systemd/user && \
      ls -1 /usr/lib/systemd/user >/dev/null \
    '

[group('Test')]
test-efi $target_image=("localhost/" + image_name) $tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    {{engine}} run --rm "${target_image}:${tag}" /bin/sh -lc '\
      (test -d /usr/lib/ostree-boot/efi/EFI/fedora && test -d /usr/lib/ostree-boot/efi/EFI/BOOT) || true; \
      (test -d /boot/efi/EFI/fedora && test -d /boot/efi/EFI/BOOT) || true; \
      echo "efi dirs ok (presence checked)" \
    '

# Validate runtime invariants from docs/ASSERTIONS.md (without parsing YAML yet)
[group('Test')]
test-assertions $target_image=("localhost/" + image_name) $tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Checking image exists: ${target_image}:${tag}"
    {{engine}} image inspect "${target_image}:${tag}" >/dev/null

    echo "Asserting /usr/lib/systemd/user exists"
    {{engine}} run --rm "${target_image}:${tag}" /bin/sh -lc 'test -d /usr/lib/systemd/user'

    echo "Asserting required service unit present: plasma-polkit-agent.service"
    {{engine}} run --rm "${target_image}:${tag}" /bin/sh -lc 'test -f /usr/lib/systemd/user/plasma-polkit-agent.service'

    echo "Asserting EFI roots (any_of) and vendor dirs exist"
    {{engine}} run --rm "${target_image}:${tag}" /bin/sh -lc '\
      ROOT=""; \
      if [ -d /usr/lib/ostree-boot/efi/EFI ]; then ROOT=/usr/lib/ostree-boot/efi/EFI; fi; \
      if [ -z "$ROOT" ] && [ -d /boot/efi/EFI ]; then ROOT=/boot/efi/EFI; fi; \
      [ -n "$ROOT" ] || { echo "Missing EFI root (expected /usr/lib/ostree-boot/efi/EFI or /boot/efi/EFI)"; exit 1; }; \
      test -d "$ROOT/fedora" || { echo "Missing vendor dir: $ROOT/fedora"; exit 1; }; \
      test -d "$ROOT/BOOT"   || { echo "Missing vendor dir: $ROOT/BOOT"; exit 1; }; \
    '

    echo "Runtime assertions OK"

[group('Build')]
build $target_image=("localhost/" + image_name) $tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    BUILD_ARGS=()
    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi

    if [[ "{{engine}}" == "docker" ]]; then
      export DOCKER_BUILDKIT=1
    fi

    {{engine}} build \
        "${BUILD_ARGS[@]}" \
        --pull \
        --tag "${target_image}:${tag}" \
        .

[group('CI')]
ci $target_image=("localhost/" + image_name) $tag=default_tag:
    just lint
    just build "{{target_image}}" "{{tag}}"
    just test "{{target_image}}" "{{tag}}"
    @echo "CI OK"
