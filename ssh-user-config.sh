#!/bin/bash
# XD VPS — boot: set root password, optional extras, then sshd
# Dev: KurrXd

: ${APP_LANG:="id"}
: ${ROOT_PASSWORD:="Kurr123@"}

msg() {
    if [ "$APP_LANG" = "en" ]; then echo "$1"; else echo "$2"; fi
}

echo "root:$ROOT_PASSWORD" | chpasswd
msg "Root password set — ssh root@<host> -p <port>" \
    "Password root siap — ssh root@<host> -p <port>"
echo "XD VPS  |  user: root  |  password: $ROOT_PASSWORD"

STATE=/var/lib/xd
mkdir -p "$STATE"
[ -f "$STATE/deploy-start" ] || date +%s > "$STATE/deploy-start"

: ${SSH_USERNAME:=""}
: ${SSH_PASSWORD:=""}
if [ -n "$SSH_USERNAME" ] && [ -n "$SSH_PASSWORD" ]; then
    if id "$SSH_USERNAME" &>/dev/null; then
        msg "User $SSH_USERNAME already exists" "User $SSH_USERNAME sudah ada"
    else
        useradd -ms /bin/bash "$SSH_USERNAME"
        echo "$SSH_USERNAME:$SSH_PASSWORD" | chpasswd
        usermod -aG sudo "$SSH_USERNAME"
        msg "User $SSH_USERNAME created (sudo)" "User $SSH_USERNAME dibuat (sudo)"
    fi
elif [ -n "$SSH_USERNAME" ] || [ -n "$SSH_PASSWORD" ]; then
    msg "SSH_USERNAME and SSH_PASSWORD must be set together" \
        "SSH_USERNAME dan SSH_PASSWORD harus diisi berdua"
fi

: ${AUTHORIZED_KEYS:=""}
if [ -n "$AUTHORIZED_KEYS" ]; then
    mkdir -p /root/.ssh
    echo "$AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    msg "Authorized keys set" "Authorized keys terpasang"
fi

start_9router() {
    export DATA_DIR=/root/.9router
    export PORT=20128
    export HOSTNAME=0.0.0.0
    export INITIAL_PASSWORD="$ROOT_PASSWORD"
    export REQUIRE_API_KEY=true
    export NODE_ENV=production
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
        export BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
        export NEXT_PUBLIC_BASE_URL="$BASE_URL"
        export AUTH_COOKIE_SECURE=true
    fi
    mkdir -p "$DATA_DIR"
    nohup 9router --no-browser --skip-update >/var/log/9router.log 2>&1 &
    msg "9router UI :20128 — login password = root password" \
        "9router UI :20128 — password login = password root"
}

: ${GITHUB_TOKEN:=""}
: ${GITHUB_REPO:=""}
mkdir -p /root/src
if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" > "$STATE/github-token"
    chmod 600 "$STATE/github-token"
    export GITHUB_TOKEN GITHUB_REPO
    repo=$(/usr/local/bin/src-sync --init 2>/dev/null)
    msg "restore from GitHub once (launch only)..." \
        "restore dari GitHub sekali (saat launch)..."
    /usr/local/bin/src-sync --restore 2>&1 | while IFS= read -r l; do msg "$l" "$l"; done
    msg "backup ON — launch restore then auto-push ⇄ $repo" \
        "backup ON — restore saat launch, lalu auto-backup ⇄ $repo"
else
    msg "No GITHUB_TOKEN — backup off" "GITHUB_TOKEN kosong — backup mati"
fi

start_9router

if [ -n "$GITHUB_TOKEN" ]; then
    nohup /usr/local/bin/src-sync --watch >/var/log/src-sync.log 2>&1 &
fi

msg "Starting SSH server..." "Menyalakan SSH server..."
ssh-keygen -A 2>/dev/null || true
exec /usr/sbin/sshd -D
