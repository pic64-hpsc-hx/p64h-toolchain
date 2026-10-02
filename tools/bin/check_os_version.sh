#! /bin/bash
#----------------------------------------------------------------------------
# This script checks the OS version and returns the LIN_VER and TOOL_VER
# for consumption by other scripts
#
# (c) 2024 Microchip Technology Inc.
# SPDX-License-Identifier: MIT
#----------------------------------------------------------------------------

bin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
. "$bin_dir"/logging.sh

# check if linux version is RHEL8, RHEL9, UBUNTU 18.04, UBUNTU 20.04, UBUNTU 22.04. default to UBUNTU 20.04. use ID_LIKE to identify the distro
if [[ -f /etc/os-release ]]; then
  # eval specific variables to avoid overwriting $VERSION used by sysc
  eval "$(cat /etc/os-release | grep "ID_LIKE=")"
  eval "$(cat /etc/os-release | grep "ID=")"
  eval "$(cat /etc/os-release | grep "VERSION_ID=")"
  os_id="$ID_LIKE"
  if [[ "$ID" == "rhel" ]]; then
    os_id="$ID"
  fi
  case $os_id in
  rhel*)
    # Covers distributions similar to RedHat such as AlmaLinux
    case $VERSION_ID in
    7*)
      log_error "ERROR: RHEL 7 is not supported; contact Microchip Applications for support"
      exit 1
      ;;
    8*)
      log_error "ERROR: RHEL 8 is not supported; contact Microchip Applications for support"
      exit 1
      ;;
    9*)
      export LIN_VER="RHEL_9.0"
      export TOOL_VER=redhat9
      ;;
    *)
      log_warning "WARNING: Could not determine distribution. Assuming RHEL 9"
      export LIN_VER="RHEL_9.0"
      export TOOL_VER=redhat9
      ;;
    esac
    ;;
  debian*)
    case $VERSION_ID in
    18.04)
      log_error "ERROR: ubuntu 18.04 is not supported; contact Microchip Applications for support"
      exit 1
      ;;
    20.04)
      log_error "ERROR: ubuntu 20.04 is not supported; contact Microchip Applications for support"
      exit 1
      ;;
    22.04 | 24.04)
      export LIN_VER="ubuntu_22.04"
      export TOOL_VER=ubuntu22
      ;;
    *)
      log_warning "WARNING: Could not determine distribution. Assuming Ubuntu 22.04"
      export LIN_VER="ubuntu_22.04"
      export TOOL_VER=ubuntu22
      ;;
    esac
    ;;
  *)
    log_warning "WARNING: Could not identify distribution. Assuming ubuntu 22.04"
    export LIN_VER="ubuntu_22.04"
    export TOOL_VER=ubuntu22
    ;;
  esac
elif [[ -f /etc/almalinux-release ]] || [[ -f /etc/redhat-release ]]; then
  TOOL_VER=redhat9
elif [[ -f /etc/debian_version ]]; then
  TOOL_VER=ubuntu22
else
  log_warning "WARNING: Could not identify distribution. Assuming ubuntu 22.04"
  export LIN_VER="UBUNTU_22.04"
  export TOOL_VER=ubuntu22
fi
