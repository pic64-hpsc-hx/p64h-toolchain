<!--- (c) 2026 Microchip Technology Inc. --->
<!--- SPDX-License-Identifier: MIT --->

# PIC64-HPSC-HX Toolchain Repository

The p64h-toolchain repository contains the build scripts used to produce the RISC-V GCC and LLVM toolchains for the [PIC64-HPSC](https://www.microchip.com/en-us/products/microprocessors/64-bit-mpus/pic64-hpsc) device. The toolchain sources come from the `riscv-gnu-toolchain` submodule, which is based on the upstream [riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain) project and uses LLVM 22.1.8.

A build produces two tool suites:

| Tool suite | Target | Use |
|---|---|---|
| `riscv64-unknown-elf-gnu-toolsuite-<version>` | Newlib (bare metal) | Bare-metal, RTOS and System Controller firmware |
| `riscv64-unknown-linux-toolsuite-<version>` | glibc (Linux) | Linux applications and kernel modules |

Each suite contains both the GCC and the LLVM/Clang compilers.

## Repository layout

| Path | Description |
|---|---|
| `riscv-gnu-toolchain/` | Toolchain sources (git submodule) |
| `tools/bin/p64h_toolchain_build.sh` | Builds the toolchain and packages it as a tarball |
| `tools/bin/check_os_version.sh` | Detects the host OS; the result is used in the tarball name |
| `docker/` | Dockerfiles for the supported build hosts (see [docker/README.md](docker/README.md)) |
| `linux-headers/` | Linux UAPI headers for RISC-V |

## Using the pre-built toolchain

Pre-built toolchains are attached to each [GitHub release](https://github.com/pic64-hpsc-hx/p64h-toolchain/releases). Download the tarball for your host OS (`ubuntu22` for Ubuntu 22.04/24.04, `redhat9` for RHEL/AlmaLinux 9) and its `.sha256` file:

    sha256sum -c P64hTools-<version>-x86_64-linux-<os>.tar.xz.sha256
    tar -xJf P64hTools-<version>-x86_64-linux-<os>.tar.xz
    export PATH=$PWD/P64hTools-<version>-x86_64-linux-<os>/riscv64-unknown-linux-toolsuite-<version>/bin:$PATH

## Building the toolchain from source

### Supported host operating systems

- Ubuntu 22.04 and 24.04
- RHEL / AlmaLinux 9

The required host packages are listed in the Dockerfiles in the [docker/](docker/) directory. The easiest way to get a working build environment is to build inside one of those containers (see [Building inside Docker](#building-inside-docker)).

The full build needs a lot of disk space (tens of GB) and takes several hours. The build script runs `make -j32`.

### Clone the repository

The toolchain sources live in a submodule, so clone recursively:

    git clone --recurse-submodules https://github.com/pic64-hpsc-hx/p64h-toolchain.git
    cd p64h-toolchain

If you already cloned without submodules, run:

    git submodule update --init --recursive

### Build

    TOOLCHAIN_VERSION=<version> ./tools/bin/p64h_toolchain_build.sh

The script builds every combination of the selected modes and compilers. Each pass starts from a clean build directory. You can control the build with these environment variables:

| Variable | Default | Description |
|---|---|---|
| `TOOLCHAIN_VERSION` | `2.3.0` | Version string used in the install directory and tarball names |
| `MODES` | `newlib linux` | Targets to build: `newlib` (bare metal) and/or `linux` |
| `COMPILERS` | `gcc llvm` | Compilers to build: `gcc` and/or `llvm` |
| `TOOLCHAIN_DIR` | `riscv-gnu-toolchain/install` | Directory where the tool suites are installed |

For example, to build only the Linux GCC toolchain:

    TOOLCHAIN_VERSION=2.3.0 MODES=linux COMPILERS=gcc ./tools/bin/p64h_toolchain_build.sh

### Build outputs

The tool suites are installed under `$TOOLCHAIN_DIR`:

    $TOOLCHAIN_DIR/riscv64-unknown-elf-gnu-toolsuite-<version>/
    $TOOLCHAIN_DIR/riscv64-unknown-linux-toolsuite-<version>/

The script also packages `$TOOLCHAIN_DIR` into the repository root. The top-level directory of each archive is named `P64hTools-<version>-x86_64-linux-<os>`, where `<os>` is `ubuntu22` or `redhat9`:

| File | Description |
|---|---|
| `P64hTools-<version>-x86_64-linux-<os>.tar.xz` | Toolchain archive (the format published in releases) |
| `P64hTools-<version>-x86_64-linux-<os>.tar.xz.sha256` | SHA-256 checksum of the `.tar.xz` |
| `P64hTools-<version>-x86_64-linux-<os>.tar.gz` | Toolchain archive (gzip) |
| `P64hTools-<version>-x86_64-linux-<os>.sha256sum` / `.sha1sum` | Checksums of the `.tar.gz` |

### Building inside Docker

Build the image from the repository root. The example below uses Ubuntu 22.04; use `docker/Dockerfile_almalinux-9.4` for AlmaLinux 9.

    docker build -t p64h-toolchain-ubuntu22 -f docker/Dockerfile_ubuntu-22.04 .

Then run the build with the repository mounted into the container. Running as your own user keeps the output files owned by you:

    docker run --rm -it -u $(id -u):$(id -g) \
        -v $PWD:/opt/microchip-p64h/p64h-toolchain \
        -w /opt/microchip-p64h/p64h-toolchain \
        p64h-toolchain-ubuntu22 \
        bash -c "TOOLCHAIN_VERSION=<version> ./tools/bin/p64h_toolchain_build.sh"

See [docker/README.md](docker/README.md) for more details.

