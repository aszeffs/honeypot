#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y git python3 python3-venv python3-pip openssh-server

if ! id cowrie >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash cowrie
fi

if ! id dashboard >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash dashboard
fi

install -d -m 0750 -o cowrie -g cowrie /opt/cowrie
install -d -m 0750 -o dashboard -g dashboard /opt/dashboard

sudo -u cowrie -H bash -lc 'printf "Cowrie runtime directory\n" > /opt/cowrie/README'
sudo -u dashboard -H bash -lc 'printf "Analyst dashboard runtime directory\n" > /opt/dashboard/README'
