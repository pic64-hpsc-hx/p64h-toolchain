#!/bin/bash
#----------------------------------------------------------------------------
# Logging functions
#
# (c) 2024 Microchip Technology Inc.
# SPDX-License-Identifier: MIT
#----------------------------------------------------------------------------
# shellcheck disable=SC2154

bin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

if [ -z "$WIN_ENV" ] && [ -e "$bin_dir/install_gum.sh" ]; then
  . "$bin_dir"/install_gum.sh
fi

# Parameters:
#    $* - The string(s) to be printed in color
#
endcolor="\e[0m"
log_info() {
  if [[ $USE_GUM -ne 0 ]]; then
    $GUM_TOOL style --foreground "#198754" "$1"
  else
    local green="\e[32m"
    local bold_green='\e[1;32m'
    if [[ $1 == "-hl" ]]; then
      echo -e "${bold_green}$2${endcolor}"
    else
      echo -e "${green}$*${endcolor}"
    fi
  fi
}
log_error() {
  if [[ $USE_GUM -ne 0 ]]; then
    $GUM_TOOL style --foreground "#CC0000" "$1"
  else
    local red="\e[31m"
    echo >&2 -e "${red}$*${endcolor}"
  fi
}
log_warning() {
  if [[ $USE_GUM -ne 0 ]]; then
    $GUM_TOOL style --foreground "#eed202" "$1"
  else
    local yellow="\e[33m"
    echo >&2 -e "${yellow}$*${endcolor}"
  fi
}
log_verbose_info() {
  if [[ "$verbose" -gt 0 ]]; then
    local cyan="\e[36m"
    echo -e "${cyan}$(basename "$0"): $*${endcolor}"
  fi
}

log_and_run() {
  log_info "Executing: $*"
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    log_error "Failed Executing: $*"
  fi
  return $status
}

#
# Function to log critical messages with a prompt
#
REPLY=""
log_confirm_action_with_prompt() {
  echo
  log_warning "$*"
  log_warning "Confirm? [y/N] (default: N)"
  read -r -n 1 REPLY
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    REPLY="YES"
  else
    REPLY="NO"
  fi
}

print_with_spinner_show_output() {
  # first argument is the title; second argument is the command
  if [[ $USE_GUM -ne 0 ]]; then
    $GUM_TOOL spin --spinner dot --show-output --spinner.foreground="#0f0" --title "$1" -- "${@:2}"
  else
    log_info "$1"
    "${@:2}"
  fi
}

print_with_spinner() {
  # first argument is the title; second argument is the command
  if [[ $USE_GUM -ne 0 ]]; then
    $GUM_TOOL spin --spinner dot --spinner.foreground="#0f0" --title "$1" -- "${@:2}"
  else
    lof_info "$1"
    "${@:2}"
  fi
}
