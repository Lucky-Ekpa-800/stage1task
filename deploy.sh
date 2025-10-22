#!/usr/bin/env bash
# deploy_updated.sh — HNG DevOps Stage 1 automated deploy script
set -euo pipefail

########################################
# Setup / logging
########################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/deploy_${TIMESTAMP}.log"

log()   { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%S%z)" "$*" | tee -a "$LOG_FILE"; }
info()  { log "INFO: $*"; }
error() { log "ERROR: $*"; }
succ()  { log "SUCCESS: $*"; }
die()   { error "$*"; exit "${2:-1}"; }

trap 'error "Unexpected error at line $LINENO. See $LOG_FILE"; exit 2' ERR
trap 'log "Interrupted"; exit 130' INT

########################################
# Args
########################################
CLEANUP_MODE=0
for a in "$@"; do
  case "$a" in
    --cleanup) CLEANUP_MODE=1 ;;
    -h|--help) echo "Usage: $0 [--cleanup]"; exit 0 ;;
  esac
done

########################################
# Interactive input
########################################
read_input() {
  : "${GIT_URL:=$(printf '' ; read -p 'Git repository URL (https://...): ' REPLY && printf '%s' "$REPLY")}"
  : "${PAT:=$(printf '' ; read -s -p 'Personal Access Token (press Enter if public): ' REPLY && printf '%s' "$REPLY" && echo)}"
  : "${BRANCH:=$(printf '' ; read -p "Branch [main]: " REPLY && printf '%s' "${REPLY:-main}")}"
  : "${REMOTE_USER:=$(printf '' ; read -p 'Remote SSH username: ' REPLY && printf '%s' "$REPLY")}"
  : "${REMOTE_HOST:=$(printf '' ; read -p 'Remote server IP/hostname: ' REPLY && printf '%s' "$REPLY")}"
  : "${SSH_KEY:=$(printf '' ; read -p 'SSH key path (e.g. ~/.ssh/id_rsa): ' REPLY && printf '%s' "$REPLY")}"
  : "${CONTAINER_PORT:=$(printf '' ; read -p 'Application internal container port (e.g. 3000): ' REPLY && printf '%s' "$REPLY")}"
  : "${REMOTE_PROJECT_DIR:=$(printf '' ; read -p 'Remote project directory (optional, leave blank for default): ' REPLY && printf '%s' "$REPLY")}"

  if [ -z "$GIT_URL" ] || [ -z "$REMOTE_USER" ] || [ -z "$REMOTE_HOST" ] || [ -z "$SSH_KEY" ] || [ -z "$CONTAINER_PORT" ]; then
    die "Missing required input (git url, remote user/host, ssh key, or container port)."
  fi

  REPO_NAME="$(basename -s .git "$GIT_URL")"
  if [ -z "$REMOTE_PROJECT_DIR" ]; then
    REMOTE_PROJECT_DIR="/home/${REMOTE_USER}/${REPO_NAME}"
  fi
}

########################################
# Local prereqs
########################################
check_local_prereqs() {
  for c in git ssh curl; do
    command -v "$c" >/dev/null 2>&1 || die "$c is required locally"
  done
  info "Local prerequisites satisfied"
}

########################################
# Prepare local repo
########################################
prepare_local_repo() {
  info "Preparing local repo for $GIT_URL (branch: $BRANCH)"
  if [ -n "$PAT" ] && printf '%s' "$GIT_URL" | grep -qE '^https?://'; then
    AUTH_GIT_URL="$(printf '%s' "$GIT_URL" | sed -E "s#https?://#https://${PAT}@#")"
  else
    AUTH_GIT_URL="$GIT_URL"
  fi

  if [ -d "$SCRIPT_DIR/$REPO_NAME/.git" ]; then
    info "Repo exists locally — pulling latest"
    (cd "$SCRIPT_DIR/$REPO_NAME" && git fetch --all --prune >>"$LOG_FILE" 2>&1 && git checkout "$BRANCH" >>"$LOG_FILE" 2>&1 && git pull origin "$BRANCH" >>"$LOG_FILE" 2>&1) || die "Git pull failed"
  else
    info "Cloning $AUTH_GIT_URL ..."
    (cd "$SCRIPT_DIR" && git clone --branch "$BRANCH" "$AUTH_GIT_URL" >>"$LOG_FILE" 2>&1) || die "Git clone failed"
  fi

  cd "$SCRIPT_DIR/$REPO_NAME"
  if [ ! -f "docker-compose.yml" ] && [ ! -f "Dockerfile" ]; then
    info "No Dockerfile/docker-compose.yml detected — creating default Dockerfile"
    cat > Dockerfile <<'DOCKER'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production || npm install --production || true
COPY . .
EXPOSE 3000
CMD ["npm","start"]
DOCKER
    succ "Default Dockerfile created"
  else
    succ "Dockerfile/docker-compose.yml exists"
  fi
}

########################################
# SSH check
########################################
check_ssh_connectivity() {
  info "Checking SSH to ${REMOTE_USER}@${REMOTE_HOST}"
  ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "echo connected" >/dev/null 2>&1 || die "SSH connectivity failed"
  succ "SSH connectivity OK"
}

########################################
# Transfer project (Windows-friendly rsync/scp)
########################################
transfer_project() {
  info "Transferring project to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PROJECT_DIR}"
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
      "mkdir -p '${REMOTE_PROJECT_DIR}' && chown ${REMOTE_USER}:${REMOTE_USER} '${REMOTE_PROJECT_DIR}'" \
      || die "Failed to create remote directory"

  # Convert local path for Windows Git Bash
  LOCAL_PATH="$SCRIPT_DIR/$REPO_NAME"
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    LOCAL_PATH="$(cygpath -w "$LOCAL_PATH")"
  fi

  if command -v rsync >/dev/null 2>&1; then
    info "Using rsync to transfer files"
    rsync -avz --delete -e "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no" "$LOCAL_PATH/" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PROJECT_DIR}/" >>"$LOG_FILE" 2>&1 || die "rsync failed"
  else
    info "rsync not found — falling back to scp"
    scp -i "$SSH_KEY" -r "$LOCAL_PATH/" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PROJECT_DIR}/" >>"$LOG_FILE" 2>&1 || die "scp failed"
  fi

  succ "Project files transferred"
}

########################################
# Main
########################################
main() {
  if [ "$CLEANUP_MODE" -eq 1 ]; then
    read_input
    check_local_prereqs
    check_ssh_connectivity
    info "Cleanup mode placeholder — implement cleanup here if needed"
    exit 0
  fi

  read_input
  check_local_prereqs
  prepare_local_repo
  check_ssh_connectivity
  transfer_project

  succ "Deployment steps completed (Docker/Nginx steps to be added)"
  info "Logs: $LOG_FILE"
}

main "$@"

