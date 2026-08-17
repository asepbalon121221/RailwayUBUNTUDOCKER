#!/bin/bash
# XD VPS — full backup ⇄ GitHub (9router DB + /root files)
# Dev: KurrXd
#
#   src-sync            push now
#   src-sync --watch    loop every SYNC_INTERVAL (default 180)
#   src-sync --restore  pull + apply onto the VPS
#   src-sync --init     create/link private repo
#   src-sync --status
set -u

SRC=/root/src
NINE=/root/.9router
STATE=/var/lib/xd
MARK="$STATE/src-repo"
API=https://api.github.com
XD_CONFIG="${XD_CONFIG:-/etc/xd/config.json}"
cfg() {
  [ -f "$XD_CONFIG" ] || return 0
  jq -r "$1 | if . == null then empty else tostring end" "$XD_CONFIG" 2>/dev/null
}
TOKEN="${GITHUB_TOKEN:-}"
[ -z "$TOKEN" ] && TOKEN="$(cfg .github_token)"
[ -z "$TOKEN" ] && [ -f /var/lib/xd/github-token ] \
    && TOKEN="$(cat /var/lib/xd/github-token 2>/dev/null)"
INTERVAL="${SYNC_INTERVAL:-}"
[ -z "$INTERVAL" ] && INTERVAL="$(cfg .sync_interval)"
INTERVAL="${INTERVAL:-180}"
GITHUB_REPO="${GITHUB_REPO:-}"
[ -z "$GITHUB_REPO" ] && GITHUB_REPO="$(cfg .github_repo)"
GITHUB_SYNC_EMAIL="${GITHUB_SYNC_EMAIL:-}"
[ -z "$GITHUB_SYNC_EMAIL" ] && GITHUB_SYNC_EMAIL="$(cfg .github_sync_email)"
GITHUB_SYNC_NAME="${GITHUB_SYNC_NAME:-}"
[ -z "$GITHUB_SYNC_NAME" ] && GITHUB_SYNC_NAME="$(cfg .github_sync_name)"
REPO_OWNER=""
REPO_NAME=""

die()  { echo "src-sync: $*" >&2; exit 1; }
need() { [ -n "$TOKEN" ] || die "GITHUB_TOKEN not set — cannot backup"; }

git_ident() {
  git config --global user.email "${GITHUB_SYNC_EMAIL:-sync@xdvps.local}" 2>/dev/null
  git config --global user.name  "${GITHUB_SYNC_NAME:-XD VPS Sync}" 2>/dev/null
  git config --global init.defaultBranch main 2>/dev/null
  git config --global push.autoSetupRemote true 2>/dev/null
}

auto_name() {
  local id="${RAILWAY_PROJECT_ID:-}"
  [ -z "$id" ] && id="$(hostname)"
  echo "$id" | tr -c 'A-Za-z0-9' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40 \
    | sed 's/-*$//' | sed 's/^/xd-vps-src-/'
}

# GITHUB_REPO: empty | name | owner/name | https://github.com/owner/name.git
repo_spec() {
  local spec
  spec="$(echo "${GITHUB_REPO:-}" | tr -d '[:space:]')"
  spec="${spec%.git}"
  spec="${spec#https://github.com/}"
  spec="${spec#http://github.com/}"
  spec="${spec#github.com/}"
  echo "$spec"
}

gh_user() {
  curl -s --max-time 12 -H "Authorization: Bearer $TOKEN" "$API/user" \
    | jq -r '.login // empty' 2>/dev/null
}

repo_exists() {
  local u="$1" n="$2"
  curl -s --max-time 12 -H "Authorization: Bearer $TOKEN" "$API/repos/$u/$n" \
    | jq -r '.id // empty' 2>/dev/null
}

create_repo() {
  local n="$1"
  curl -s --max-time 20 -X POST "$API/user/repos" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "{\"name\":\"$n\",\"private\":true,\"description\":\"XD VPS full backup — 9router DB + files\",\"auto_init\":false}" \
    | jq -r '.id // empty' 2>/dev/null
}

remote_url() { echo "https://$TOKEN@github.com/$1/$2.git"; }

# Sets REPO_OWNER REPO_NAME. Empty GITHUB_REPO → auto xd-vps-src-<id> (create later).
resolve_repo() {
  local spec u
  spec="$(repo_spec)"
  if [ -z "$spec" ] && [ -f "$MARK" ]; then
    spec="$(cat "$MARK")"
    spec="${spec#https://github.com/}"
  fi
  if [ -n "$spec" ]; then
    case "$spec" in
      */*) REPO_OWNER="${spec%%/*}"; REPO_NAME="${spec##*/}" ;;
      *)
        u=$(gh_user); [ -n "$u" ] || return 1
        REPO_OWNER="$u"; REPO_NAME="$spec"
        ;;
    esac
  else
    u=$(gh_user); [ -n "$u" ] || return 1
    REPO_OWNER="$u"
    REPO_NAME="$(auto_name)"
  fi
  mkdir -p "$STATE"
  echo "$REPO_OWNER/$REPO_NAME" > "$MARK"
}

print_repo() {
  local spec
  spec="$(repo_spec)"
  if [ -z "$spec" ]; then
    echo "AUTO:$(auto_name)"
    return 0
  fi
  case "$spec" in
    */*) echo "$spec" ;;
    *) echo "NAME:$spec" ;;
  esac
}

write_gitignore() {
  cat > "$SRC/.gitignore" <<'EOF'
node_modules/
**/.git/
__pycache__/
*.pyc
.cache/
*.log
9router/logs/
EOF
}

# Snapshot live VPS into the git staging tree (does not touch user files in place).
snapshot() {
  mkdir -p "$SRC/9router" "$SRC/files"
  write_gitignore
  if [ -d "$NINE" ]; then
    rsync -a --delete --max-size=90m \
      --exclude 'logs/' --exclude 'db/data.sqlite-wal' --exclude 'db/data.sqlite-shm' \
      "$NINE"/ "$SRC/9router/" 2>/dev/null || true
    if [ -f "$NINE/db/data.sqlite" ] && command -v sqlite3 >/dev/null 2>&1; then
      mkdir -p "$SRC/9router/db"
      sqlite3 "$NINE/db/data.sqlite" ".backup '$SRC/9router/db/data.sqlite'" 2>/dev/null || true
    fi
  fi
  rsync -a --delete --max-size=90m \
    --exclude 'src/' \
    --exclude '.9router/' \
    --exclude '.cache/' \
    --exclude '.npm/' \
    --exclude '.local/' \
    --exclude '.ssh/' \
    --exclude 'node_modules/' \
    /root/ "$SRC/files/" 2>/dev/null || true
}

# Apply staged backup onto the live VPS. Call BEFORE starting 9router.
apply_restore() {
  if [ -d "$SRC/9router" ] && [ -n "$(ls -A "$SRC/9router" 2>/dev/null)" ]; then
    mkdir -p "$NINE"
    rsync -a "$SRC/9router"/ "$NINE"/ 2>/dev/null || true
  fi
  if [ -d "$SRC/files" ] && [ -n "$(ls -A "$SRC/files" 2>/dev/null)" ]; then
    rsync -a "$SRC/files"/ /root/ --exclude src 2>/dev/null || true
  fi
}

do_init() {
  need; git_ident; mkdir -p "$SRC"
  resolve_repo || die "cannot resolve repo (set GITHUB_TOKEN / GITHUB_REPO)"
  local me; me=$(gh_user)
  if [ -z "$(repo_exists "$REPO_OWNER" "$REPO_NAME")" ]; then
    if [ -n "$(repo_spec)" ] && [ "$REPO_OWNER" != "$me" ]; then
      die "repo $REPO_OWNER/$REPO_NAME not found — token cannot access it"
    fi
    create_repo "$REPO_NAME" >/dev/null && echo "created repo $REPO_OWNER/$REPO_NAME" \
      || die "failed to create repo $REPO_OWNER/$REPO_NAME (token scope = repo)"
  else
    echo "repo $REPO_OWNER/$REPO_NAME already exists"
  fi
  if [ ! -d "$SRC/.git" ]; then git -C "$SRC" init -q; fi
  git -C "$SRC" remote set-url origin "$(remote_url "$REPO_OWNER" "$REPO_NAME")" 2>/dev/null \
    || git -C "$SRC" remote add origin "$(remote_url "$REPO_OWNER" "$REPO_NAME")"
  write_gitignore
  echo "$REPO_OWNER/$REPO_NAME"
}

do_restore() {
  need; git_ident
  resolve_repo || die "cannot resolve repo"
  [ -z "$(repo_exists "$REPO_OWNER" "$REPO_NAME")" ] \
    && { echo "no repo $REPO_OWNER/$REPO_NAME yet — skip restore, will create on first backup"; return 0; }
  if [ -d "$SRC/.git" ]; then
    git -C "$SRC" remote set-url origin "$(remote_url "$REPO_OWNER" "$REPO_NAME")"
    git -C "$SRC" pull --ff-only 2>/dev/null || true
  elif [ -z "$(ls -A "$SRC" 2>/dev/null)" ]; then
    git clone "$(remote_url "$REPO_OWNER" "$REPO_NAME")" "$SRC" 2>&1 | tail -2
  else
    mv "$SRC" "${SRC}.local"
    git clone "$(remote_url "$REPO_OWNER" "$REPO_NAME")" "$SRC" 2>&1 | tail -2
    cp -a "${SRC}.local"/. "$SRC"/ 2>/dev/null; rm -rf "${SRC}.local"
  fi
  apply_restore
}

do_push() {
  need
  [ -d "$SRC/.git" ] || do_init >/dev/null
  git_ident
  snapshot
  git -C "$SRC" add -A
  git -C "$SRC" diff --cached --quiet && { echo "backup: nothing to sync"; return 0; }
  git -C "$SRC" commit -q -m "auto-backup $(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null
  git -C "$SRC" pull --rebase --autostash 2>/dev/null || true
  git -C "$SRC" push -u origin HEAD 2>&1 | tail -3
}

do_watch() {
  need
  echo "src-sync: watching 9router DB + /root every ${INTERVAL}s"
  while true; do do_push >/dev/null 2>&1; sleep "$INTERVAL"; done
}

do_status() {
  need
  resolve_repo || die "cannot resolve repo"
  echo "Backup: 9router DB + /root files (restore at launch, then push-only)"
  echo "Stage:  $SRC"
  echo "Repo:   $REPO_OWNER/$REPO_NAME"
  echo "Remote: $(git -C "$SRC" remote get-url origin 2>/dev/null || echo '(not linked)')"
  echo "Last:   $(git -C "$SRC" log -1 --format='%h %cr %s' 2>/dev/null || echo '(no commits)')"
}

case "${1:-push}" in
  --init)    do_init ;;
  --restore|restore) do_restore ;;
  --watch)   do_watch ;;
  --status)  do_status ;;
  --print-repo) print_repo ;;
  push|--push|backup) do_push ;;
  *) echo "usage: src-sync [backup|restore|--init|--restore|--watch|--status|--print-repo|push]"; exit 1 ;;
esac
