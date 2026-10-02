#!/usr/bin/bash
# (c) 2026 Microchip Technology Inc.
# SPDX-License-Identifier: MIT
set -e

TOOLCHAIN_VERSION=${TOOLCHAIN_VERSION:-2.3.0}
MODES=${MODES:-"newlib linux"}
COMPILERS=${COMPILERS:-"gcc llvm"}

# Determine the repo root and navigate to riscv-gnu-toolchain subdirectory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RISCV_TOOLCHAIN_DIR="${REPO_ROOT}/riscv-gnu-toolchain"

# Determine TOOL_VER (e.g. redhat9, ubuntu22) for the tarball name/directory below
export USE_GUM=0
. "${SCRIPT_DIR}/check_os_version.sh"

# Verify submodule exists
if [ ! -d "${RISCV_TOOLCHAIN_DIR}" ]; then
    echo "Error: riscv-gnu-toolchain submodule not found at ${RISCV_TOOLCHAIN_DIR}"
    echo "Initialize with: git submodule update --init --recursive"
    exit 1
fi

# Set TOOLCHAIN_DIR with proper path from submodule location
TOOLCHAIN_DIR=${TOOLCHAIN_DIR:-${RISCV_TOOLCHAIN_DIR}/install}

# Change to riscv-gnu-toolchain directory for build
cd "${RISCV_TOOLCHAIN_DIR}"

#Create the toolchain directory
mkdir -p ${TOOLCHAIN_DIR}

# if in docker, copy the source code from $WORKSPACE to the docker container at $WORKSPACE_local
#if [ "$DOCKER_BUILD" -eq 1 ]; then
#    echo "Copying source code from $WORKSPACE to ${WORKSPACE}_local"
#    #rsync -a --info=progress2 $WORKSPACE/* ${WORKSPACE}_local/*
#    git clone $WORKSPACE ${WORKSPACE}_local # a quick hacl to just copy the necessary files
#    cd ${WORKSPACE}_local
#fi


# Note: Following a on-standard toolchain dir naming convention following the SiFive naming convention we have been using in past releases.
for mode in ${MODES}; do
    for compiler in ${COMPILERS}; do
        if [ ${compiler} == "gcc" ]; then
            if [ ${mode} == "newlib" ]; then
                echo "Building GCC for Newlib"
                rm -rf build-* install-* stamps install-newlib-nano # make clean for the first pre-config stage
                ./configure --prefix=${TOOLCHAIN_DIR}/riscv64-unknown-elf-gnu-toolsuite-${TOOLCHAIN_VERSION} --with-cmodel=medany
                make -j32
            elif [ ${mode} == "linux" ]; then
                echo "Building GCC for Linux"
                make clean
                ./configure --prefix=${TOOLCHAIN_DIR}/riscv64-unknown-linux-toolsuite-${TOOLCHAIN_VERSION} --with-cmodel=medany
                make linux -j32
            fi
        elif [ ${compiler} == "llvm" ]; then
            if [ ${mode} == "newlib" ]; then
                echo "Building LLVM for Newlib"
                make clean
                ./configure --prefix=${TOOLCHAIN_DIR}/riscv64-unknown-elf-gnu-toolsuite-${TOOLCHAIN_VERSION} --enable-llvm --disable-linux --with-cmodel=medany
                make -j32
            elif [ ${mode} == "linux" ]; then
                echo "Building LLVM for Linux"
                make clean
                ./configure --prefix=${TOOLCHAIN_DIR}/riscv64-unknown-linux-toolsuite-${TOOLCHAIN_VERSION} --enable-llvm --enable-linux --with-cmodel=medany
                make -j32
            fi
        fi
    done
done

# Create the tarball in REPO_ROOT. The tarball must contain (and be named after)
# a top-level P64hTools-<version>-x86_64-linux-<os> directory, so rename just the
# leading path component at archive time via --transform, leaving TOOLCHAIN_DIR
# itself untouched for later stages (e.g. Pack Toolchain for PoCL). Avoid tar's -h
# (dereference) here: it recursively follows every symlink inside the install tree
# (compiler-name symlinks, versioned .so links, etc.), which segfaults tar on some
# hosts and would otherwise bloat the tarball by duplicating symlinked files.
TOOLCHAIN_PARENT_DIR="$(dirname "${TOOLCHAIN_DIR}")"
TOOLCHAIN_DIRNAME="$(basename "${TOOLCHAIN_DIR}")"
TARBALL_DIRNAME="P64hTools-${TOOLCHAIN_VERSION}-x86_64-linux-${TOOL_VER}"
TAR_TRANSFORM="s|^${TOOLCHAIN_DIRNAME}|${TARBALL_DIRNAME}|"
TARBALL_GZ_PATH="${REPO_ROOT}/${TARBALL_DIRNAME}.tar.gz"
TARBALL_XZ_PATH="${REPO_ROOT}/${TARBALL_DIRNAME}.tar.xz"

tar -czf "${TARBALL_GZ_PATH}" -C "${TOOLCHAIN_PARENT_DIR}" \
    --transform "${TAR_TRANSFORM}" "${TOOLCHAIN_DIRNAME}"
# .tar.xz is the format published to hpsc.microchip.com and GitHub (2 GiB per-asset limit).
# Use maximum compression; --memlimit-compress lets xz reduce the -T0 thread count so
# that -9e (~674 MiB per thread) does not exhaust memory on hosts with many cores.
# Override by setting XZ_OPT in the environment.
XZ_OPT=${XZ_OPT:-"-9e -T0 --memlimit-compress=50%"} tar -Jcf "${TARBALL_XZ_PATH}" -C "${TOOLCHAIN_PARENT_DIR}" \
    --transform "${TAR_TRANSFORM}" "${TOOLCHAIN_DIRNAME}"

#sha256sum/sha1sum files for the .tar.gz
sha256sum "${TARBALL_GZ_PATH}" > "${REPO_ROOT}/${TARBALL_DIRNAME}.sha256sum"
sha1sum "${TARBALL_GZ_PATH}" > "${REPO_ROOT}/${TARBALL_DIRNAME}.sha1sum"
#sha256 file for the .tar.xz (use the bare filename so that 'sha256sum -c' works after download)
(cd "${REPO_ROOT}" && sha256sum "${TARBALL_DIRNAME}.tar.xz" > "${TARBALL_DIRNAME}.tar.xz.sha256")
