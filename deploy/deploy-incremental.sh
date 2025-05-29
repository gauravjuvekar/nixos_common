#!/usr/bin/env bash

FLAKE_REF="$1";
TARGET_HOST="$2";

nixos-anywhere \
  --phases install \
  --show-trace \
  --disk-encryption-keys /tmp/cryptBoot.key ./remote/etc/keys/cryptBoot.key  \
  --extra-files ./remote/ \
  --target-host "$TARGET_HOST" \
  --flake "$FLAKE_REF"
