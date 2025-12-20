#!/usr/bin/env bash

if [ -z "${PAMU2FCFG_ORIGIN}" ]
then
  echo "PAMU2FCFG_ORIGIN" must be set >/dev/stderr
  exit 1
fi

CONFIG_PATH="$HOME/.config/pam_sudo/pam_u2f_authorized_keys"

mkdir -p "$(dirname "${CONFIG_PATH}")"

set -x
pamu2fcfg --verbose --origin="${PAMU2FCFG_ORIGIN}" --type=ES256 > "$CONFIG_PATH"
