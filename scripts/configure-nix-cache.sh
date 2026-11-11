#!/bin/sh
set -eu

config=/etc/nix/nix.custom.conf
substituter='https://autc04.cachix.org'
key='autc04.cachix.org-1:MyPhhbTlMACU1jhpdXlPlU4R4gyDEeNbuVYi/dU/2iU='

sudo touch "$config"
grep -Fqx "extra-substituters = $substituter" "$config" || \
  printf '%s\n' "extra-substituters = $substituter" | sudo tee -a "$config" >/dev/null
grep -Fqx "extra-trusted-substituters = $substituter" "$config" || \
  printf '%s\n' "extra-trusted-substituters = $substituter" | sudo tee -a "$config" >/dev/null
grep -Fqx "extra-trusted-public-keys = $key" "$config" || \
  printf '%s\n' "extra-trusted-public-keys = $key" | sudo tee -a "$config" >/dev/null

sudo launchctl kickstart -k system/systems.determinate.nix-daemon
printf '%s\n' "Configured the Retro68 cache in $config"
