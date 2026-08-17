#!/bin/bash
# XD VPS — boot: load config.json, set root password, start 9router + sshd
# Dev: KurrXd
# Edit config.json in the repo (not Railway Variables). Env vars override if set.

XD_CONFIG="${XD_CONFIG:-/etc/xd/config.json}"

cfg() {
    [ -f "$XD_CONFIG" ] || return 0
    jq -r "$1 | if . == null then empty else tostring end" "$XD_CONFIG" 2>/dev/null
}

# Env wins if non-empty; else config.json; else default.
pick() {
    local env_name="$1" path="$2" def="${3:-}"
    local v
    eval "v=\${$env_name-}"
    [ -n "$v" ] && { printf '%s' "$v"; return; }
    v="$(cfg "$path")"
    [ -n "$v" ] && { printf '%s' "$v"; return; }
    printf '%s' "$def"
}

APP_LANG="$(pick APP_LANG .app_lang id)"
ROOT_PASSWORD="$(pick ROOT_PASSWORD .root_password Kurr123@)"
SSH_USERNAME="$(pick SSH_USERNAME .ssh_username)"
SSH_PASSWORD="$(pick SSH_PASSWORD .ssh_password)"
AUTHORIZED_KEYS="$(pick AUTHORIZED_KEYS .authorized_keys)"
GITHUB_TOKEN="$(pick GITHUB_TOKEN .github_token)"
GITHUB_REPO="$(pick GITHUB_REPO .github_repo)"
SYNC_INTERVAL="$(pick SYNC_INTERVAL .sync_interval 180)"
export APP_LANG ROOT_PASSWORD GITHUB_TOKEN GITHUB_REPO SYNC_INTERVAL
export GITHUB_SYNC_EMAIL="$(pick GITHUB_SYNC_EMAIL .github_sync_email sync@xdvps.local)"
export GITHUB_SYNC_NAME="$(pick GITHUB_SYNC_NAME .github_sync_name 'XD VPS Sync')"

NINE_ON="$(cfg .ninerouter.enabled)"; : "${NINE_ON:=true}"
NINE_PORT="$(cfg .ninerouter.port)"; : "${NINE_PORT:=20128}"
NINE_HOST="$(cfg .ninerouter.hostname)"; : "${NINE_HOST:=0.0.0.0}"
NINE_DIR="$(cfg .ninerouter.data_dir)"; : "${NINE_DIR:=/root/.9router}"
NINE_KEY="$(cfg .ninerouter.require_api_key)"; : "${NINE_KEY:=true}"

msg() {
    if [ "$APP_LANG" = "en" ]; then echo "$1"; else echo "$2"; fi
}

echo "root:$ROOT_PASSWORD" | chpasswd
msg "Root password set — ssh root@<host> -p <port>" \
    "Password root siap — ssh root@<host> -p <port>"
echo "XD VPS  |  user: root  |  password: $ROOT_PASSWORD"
echo "config  |  $XD_CONFIG"

STATE=/var/lib/xd
mkdir -p "$STATE"
[ -f "$STATE/deploy-start" ] || date +%s > "$STATE/deploy-start"

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

if [ -n "$AUTHORIZED_KEYS" ]; then
    mkdir -p /root/.ssh
    echo "$AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    msg "Authorized keys set" "Authorized keys terpasang"
fi

start_9router() {
    [ "$NINE_ON" = "true" ] || [ "$NINE_ON" = "1" ] || return 0
    export DATA_DIR="$NINE_DIR"
    export PORT="$NINE_PORT"
    export HOSTNAME="$NINE_HOST"
    export INITIAL_PASSWORD="$ROOT_PASSWORD"
    export REQUIRE_API_KEY="$NINE_KEY"
    export NODE_ENV=production
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
        export BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
        export NEXT_PUBLIC_BASE_URL="$BASE_URL"
        export AUTH_COOKIE_SECURE=true
    fi
    mkdir -p "$DATA_DIR"
    nohup 9router --no-browser --skip-update >/var/log/9router.log 2>&1 &
    msg "9router UI :$NINE_PORT — login password = root password" \
        "9router UI :$NINE_PORT — password login = password root"
}

mkdir -p /root/src
if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" > "$STATE/github-token"
    chmod 600 "$STATE/github-token"
    repo=$(/usr/local/bin/src-sync --init 2>/dev/null)
    msg "restore from GitHub once (launch only)..." \
        "restore dari GitHub sekali (saat launch)..."
    /usr/local/bin/src-sync --restore 2>&1 | while IFS= read -r l; do msg "$l" "$l"; done
    msg "backup ON — launch restore then auto-push ⇄ $repo" \
        "backup ON — restore saat launch, lalu auto-backup ⇄ $repo"
else
    msg "No GitHub token in config.json — backup off" \
        "github_token kosong di config.json — backup mati"
fi

start_9router

if [ -n "$GITHUB_TOKEN" ]; then
    nohup /usr/local/bin/src-sync --watch >/var/log/src-sync.log 2>&1 &
fi

msg "Starting SSH server..." "Menyalakan SSH server..."
ssh-keygen -A 2>/dev/null || true
exec /usr/sbin/sshd -D
