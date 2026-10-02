<!--- (c) 2022 Microchip Technology Inc. --->
<!--- SPDX-License-Identifier: MIT --->

# Building the Docker image

The following command can be used to build a docker container for AlmaLinux 9, Ubuntu 22.04, and Ubuntu 24.04.
These containers have been verified for compiling the source code in the P64H repository.

    docker build . -f Dockerfile_almalinux-9.4 -t p64h:alma9
    docker build . -f Dockerfile_ubuntu-22.04 -t p64h:ubuntu22
    docker build . -f Dockerfile_ubuntu-24.04 -t p64h:ubuntu24

# Running inside the Docker Image

The command below starts up a bash shell inside the docker container and mounts your local
workspace to the /opt/microchip-p64h/p64h-toolchain folder inside the container

    docker run -it -v /path/to/workspace/p64h-toolchain:/opt/microchip-p64h/p64h-toolchain p64h:alma9 bash
