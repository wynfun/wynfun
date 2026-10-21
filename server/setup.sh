#!/usr/bin/env bash
# One-time server setup for wyn.fun (Ubuntu). Run as root:  bash /opt/wynfun-repo/server/setup.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Please run as root."; exit 1; }
DOMAIN="${DOMAIN:-wyn.fun}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEBIAN_FRONTEND=noninteractive

echo "==> 1/7 Installing packages"
apt-get update -y
apt-get install -y curl gnupg apt-transport-https ufw fail2ban unattended-upgrades git ca-certificates

echo "==> 2/7 Installing the Caddy web server"
if ! command -v caddy >/dev/null 2>&1; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -y
  apt-get install -y caddy
fi

echo "==> 3/7 Publishing tools"
install -m 755 "$SRC/wyn-deploy" /usr/local/bin/wyn-deploy
install -m 755 "$SRC/wyn-rollback" /usr/local/bin/wyn-rollback
install -m 755 "$SRC/wyn-deploy-all" /usr/local/bin/wyn-deploy-all
mkdir -p /srv/wynfun/releases /var/log/caddy
chown caddy:caddy /var/log/caddy
chmod 755 /srv /srv/wynfun /srv/wynfun/releases
git -C /opt/wynfun-repo fetch -q origin main staging || true
git -C /opt/wynfun-repo rev-parse -q --verify origin/staging >/dev/null || { echo "Branch 'staging' is missing on GitHub."; exit 1; }
wyn-deploy live --force
wyn-deploy staging --force
chmod -R a+rX /srv/wynfun

echo "==> 4/7 Private staging site (staging.$DOMAIN)"
HASH=""
if [ -f /etc/caddy/Caddyfile ] && [ -z "${CHANGE_STAGING_PW:-}" ]; then
  HASH="$(awk '$1=="staging" && $2 ~ /^\$2/ {print $2; exit}' /etc/caddy/Caddyfile)"
  [ -n "$HASH" ] && echo "    Keeping your existing staging password."
fi
if [ -z "$HASH" ]; then
  echo "    You will type it when you open the staging address. Username: staging"
  while :; do
    read -rsp "    Staging password (min 10 characters): " PW1 </dev/tty; echo
    read -rsp "    Type it again: " PW2 </dev/tty; echo
    [ "$PW1" = "$PW2" ] && [ "${#PW1}" -ge 10 ] && break
    echo "    They did not match or were too short. Try again."
  done
  HASH="$(caddy hash-password --plaintext "$PW1")"
  unset PW1 PW2
fi

echo "    Installing the admin login service"
apt-get install -y qrencode >/dev/null
id wynapi >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin wynapi
install -d -m 700 -o wynapi -g wynapi /var/lib/wyn /var/lib/wyn/live /var/lib/wyn/staging
install -m 755 "$SRC/wyn-api" /usr/local/bin/wyn-api
install -m 755 "$SRC/wyn-admin-setup" /usr/local/bin/wyn-admin-setup
install -m 755 "$SRC/wyn-mail-setup" /usr/local/bin/wyn-mail-setup
install -d -m 750 -o root -g wynapi /etc/wyn
install -m 644 "$SRC/wyn-api@.service" /etc/systemd/system/wyn-api@.service
systemctl daemon-reload
systemctl enable wyn-api@live wyn-api@staging >/dev/null 2>&1
systemctl restart wyn-api@live wyn-api@staging
sed -e "s|__DOMAIN__|$DOMAIN|g" -e "s|__HASH__|$HASH|g" "$SRC/Caddyfile.tpl" > /etc/caddy/Caddyfile
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
mkdir -p /var/log/caddy; chown -R caddy:caddy /var/log/caddy
systemctl enable caddy >/dev/null 2>&1
systemctl restart caddy

echo "==> 5/7 Automatic publishing (checks GitHub every minute)"
cat > /etc/systemd/system/wyn-deploy.service <<UNIT
[Unit]
Description=Publish wyn.fun from GitHub
[Service]
Type=oneshot
ExecStart=/usr/local/bin/wyn-deploy-all
UNIT
cat > /etc/systemd/system/wyn-deploy.timer <<UNIT
[Unit]
Description=Check GitHub for wyn.fun changes every minute
[Timer]
OnBootSec=60
OnUnitActiveSec=60
AccuracySec=5s
[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload
systemctl enable --now wyn-deploy.timer

echo "==> 6/7 Firewall and protection against password guessing"
ufw --force reset >/dev/null
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable
cat > /etc/fail2ban/jail.d/wyn.local <<JAIL
[sshd]
enabled = true
maxretry = 5
findtime = 10m
bantime = 1h
JAIL
systemctl enable --now fail2ban >/dev/null 2>&1
systemctl restart fail2ban

echo "==> 7/7 Checking"
sleep 2
curl -fsS -o /dev/null -w "admin service answers locally: HTTP %{http_code}\n" http://127.0.0.1:8081/api/health || true
curl -fsS -o /dev/null -w "web server answers locally: HTTP %{http_code} (301/308 = redirect to https, good)\n" -H "Host: $DOMAIN" http://127.0.0.1/ || true
echo
echo "Done. Next: make sure the DNS records for $DOMAIN, www and staging point to this server,"
echo "then open https://$DOMAIN and https://staging.$DOMAIN (user: staging)."
echo "To create your admin login, run:  wyn-admin-setup"
