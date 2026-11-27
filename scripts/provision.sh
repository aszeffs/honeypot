#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
COWRIE_COMMIT="894d398712b8558dca7a3a8ef6b427337b988d91"
COWRIE_SOURCE="/opt/cowrie/source"

apt-get update
apt-get install -y \
  build-essential git libffi-dev libssl-dev openssh-server python3 \
  python3-dev python3-pip python3-venv sshpass ufw

if ! id cowrie >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash cowrie
fi

if ! id dashboard >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash dashboard
fi

install -d -m 0750 -o cowrie -g cowrie "$COWRIE_SOURCE"
install -d -m 0750 -o dashboard -g dashboard /opt/dashboard

sudo -u cowrie git clone --quiet --depth 1 --branch v2.9.8 \
  https://github.com/cowrie/cowrie.git "$COWRIE_SOURCE"
if [[ "$(git -C "$COWRIE_SOURCE" rev-parse HEAD)" != "$COWRIE_COMMIT" ]]; then
  echo "Cowrie v2.9.8 resolved to an unexpected commit." >&2
  exit 1
fi

git -C "$COWRIE_SOURCE" apply --unidiff-zero --check /vagrant/patches/cowrie-v2.9.8.patch
git -C "$COWRIE_SOURCE" apply --unidiff-zero /vagrant/patches/cowrie-v2.9.8.patch

sudo -u cowrie python3 -m venv /opt/cowrie/venv
sudo -u cowrie /opt/cowrie/venv/bin/pip install --editable "$COWRIE_SOURCE"

install -m 0644 /vagrant/config/cowrie.cfg "$COWRIE_SOURCE/etc/cowrie.cfg"
install -m 0644 /vagrant/systemd/cowrie.service /etc/systemd/system/cowrie.service
chown -R root:root "$COWRIE_SOURCE" /opt/cowrie/venv
install -d -m 0750 -o cowrie -g cowrie \
  "$COWRIE_SOURCE/var/log/cowrie" \
  "$COWRIE_SOURCE/var/lib/cowrie" \
  "$COWRIE_SOURCE/var/run"
chown -R cowrie:cowrie "$COWRIE_SOURCE/var"

sudo -u dashboard -H bash -lc 'printf "Analyst dashboard runtime directory\n" > /opt/dashboard/README'

ufw default deny incoming
ufw default deny outgoing
ufw allow in on lo
ufw allow out on lo
for port in 22 2222 8080; do
  ufw allow from 192.168.56.1 to any port "$port" proto tcp
done
ufw --force enable

systemctl daemon-reload
systemctl enable --now cowrie.service

for attempt in $(seq 1 30); do
  if ss -ltnH | grep -q '192.168.56.10:2222'; then
    break
  fi
  sleep 1
done
if ! ss -ltnH | grep -q '192.168.56.10:2222'; then
  echo "Cowrie did not start listening on 192.168.56.10:2222." >&2
  systemctl status cowrie.service --no-pager >&2 || true
  exit 1
fi

/opt/cowrie/venv/bin/python /vagrant/scripts/verify_cowrie_redaction.py
