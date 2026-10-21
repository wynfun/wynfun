#!/usr/bin/env bash
# One-line installer for a fresh server (public repo): 
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/wynfun/wynfun/main/server/bootstrap.sh)"
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Please run as root."; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl
if [ -d /opt/wynfun-repo/.git ]; then
  git -C /opt/wynfun-repo fetch -q origin main staging
  git -C /opt/wynfun-repo checkout -q main
  git -C /opt/wynfun-repo reset -q --hard origin/main
else
  git clone https://github.com/wynfun/wynfun.git /opt/wynfun-repo
fi
DOMAIN=wyn.fun bash /opt/wynfun-repo/server/setup.sh
