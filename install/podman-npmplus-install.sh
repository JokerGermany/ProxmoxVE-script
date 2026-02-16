#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ZoeyVid/NPMplus

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add \
  podman \
  podman-compose \ 
  tzdata \
  gawk \
  yq
msg_ok "Installed Dependencies"

msg_info "Enabling Podman"
$STD rc-service podman start
$STD rc-update add podman default
msg_ok "Enabled Podman"

msg_info "Fetching NPMplus"
cd /opt
curl -fsSL "https://raw.githubusercontent.com/ZoeyVid/NPMplus/refs/heads/develop/compose.yaml" -o compose.yaml
msg_ok "Fetched NPMplus"

attempts=0
while true; do
  read -r -p "${TAB3}Enter your TZ Identifier (e.g., Europe/Berlin): " TZ_INPUT
  if validate_tz "$TZ_INPUT"; then
    break
  fi
  msg_error "Invalid timezone! Please enter a valid TZ identifier."

  attempts=$((attempts + 1))
  if [[ "$attempts" -ge 3 ]]; then
    msg_error "Maximum attempts reached. Exiting."
    exit 1
  fi
done

read -r -p "${TAB3}Enter your ACME Email: " ACME_EMAIL_INPUT

yq -i "
  .services.npmplus.environment |=
    (map(select(. != \"TZ=*\" and . != \"ACME_EMAIL=*\" and . != \"INITIAL_ADMIN_EMAIL=*\" and . != \"INITIAL_ADMIN_PASSWORD=*\")) +
    [\"TZ=$TZ_INPUT\", \"ACME_EMAIL=$ACME_EMAIL_INPUT\", \"INITIAL_ADMIN_EMAIL=admin@local.com\", \"INITIAL_ADMIN_PASSWORD=helper-scripts.com\"])
" /opt/compose.yaml

motd_ssh
customize
