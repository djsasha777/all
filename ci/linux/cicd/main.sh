#!/bin/bash
set -euo pipefail

# Загрузка конфига
[ -f /etc/spongo/cicd.conf ] && source /etc/spongo/cicd.conf
SECRETS_FILE="${SECRETS_FILE:-/etc/spongo/secrets.env}"
[ -f "$SECRETS_FILE" ] && source "$SECRETS_FILE"

# Функция SSH (GitHub Action эмуляция)
runSshOnRemote() {
  local host="$1" port="${2:-22}" user="$3" private_key="$4" command="$5"
  echo "🔐 SSH: $user@$host:$port"
  
  local keyfile=$(mktemp)
  echo "$private_key" > "$keyfile"
  chmod 600 "$keyfile"
  
  timeout 30 ssh -i "$keyfile" -p "$port" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$user@$host" "$command"
  rm -f "$keyfile"
}

# Мониторинг режима (для демона)
monitor_mode() {
  echo "👀 Spongo CI/CD daemon started, monitoring repos..."
  while true; do
    for repo in "$REPO_BASE_DIR"/*.git; do
      [ -d "$repo" ] || continue
      # Проверяем изменения (упрощённо)
      if [ -f "$repo/refs/heads/$DEFAULT_BRANCH" ]; then
        echo "$(date): Checked $repo" >> "$LOG_DIR/daemon.log"
      fi
    done
    sleep 10
  done
}

# Главная логика post-receive
main() {
  local REPO_DIR="$1"
  local WORK_TREE="$REPO_BASE_DIR/work_trees/$(basename "$REPO_DIR")"
  local LOG_FILE="$LOG_DIR/$(basename "$REPO_DIR").log"
  
  # Логирование
  exec > >(tee -a "$LOG_FILE") 2>&1
  
  # Чтение git push
  while read oldrev newrev ref; do
    BRANCH=$(basename "$ref")
    REV=$newrev
    break
  done
  
  [ "$BRANCH" = "$DEFAULT_BRANCH" ] || exit 0
  
  export GIT_DIR="$REPO_DIR" WORK_TREE REV BRANCH
  
  mkdir -p "$WORK_TREE"
  git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" checkout -f "$REV"
  
  WORKFLOWS_DIR="$REPO_DIR/.spongo/workflows"
  
  if [ -d "$WORKFLOWS_DIR" ]; then
    for yaml in "$WORKFLOWS_DIR"/*.yaml; do
      [ -f "$yaml" ] || continue
      
      NAME=$(yq e '.name' "$yaml" 2>/dev/null || echo "Unnamed")
      HAS_TRIGGER=$(yq e ".on.push.branches[]? | select(. == \"$BRANCH\")" "$yaml" 2>/dev/null | wc -l)
      
      if [ "$HAS_TRIGGER" -gt 0 ]; then
        echo "🚀 Running: $NAME"
        
        yq e '.jobs | keys | .[]' "$yaml" | while read -r job; do
          echo "  📋 Job: $job"
          
          STEP_INDEX=0
          while true; do
            STEP_RUN=$(yq e ".jobs.$job.steps[$STEP_INDEX].run" "$yaml" 2>/dev/null)
            STEP_USES=$(yq e ".jobs.$job.steps[$STEP_INDEX].uses" "$yaml" 2>/dev/null)
            
            [ -n "$STEP_RUN" ] || [ -n "$STEP_USES" ] || break
            
            if [ -n "$STEP_RUN" ]; then
              echo "    🔧 Run: $(echo "$STEP_RUN" | head -c 80)"
              cd "$WORK_TREE" && bash -c "$STEP_RUN"
            elif [[ "$STEP_USES" == "runSshOnRemote" ]]; then
              echo "    🔐 Action: runSshOnRemote"
              
              HOST=$(yq e ".jobs.$job.steps[$STEP_INDEX].with.host" "$yaml")
              PORT=$(yq e ".jobs.$job.steps[$STEP_INDEX].with.port" "$yaml" || echo "22")
              USER=$(yq e ".jobs.$job.steps[$STEP_INDEX].with.user" "$yaml")
              PRIVATE_KEY=$(yq e ".jobs.$job.steps[$STEP_INDEX].with.private_key" "$yaml")
              COMMAND=$(yq e ".jobs.$job.steps[$STEP_INDEX].with.command" "$yaml")
              
              # Замена secrets
              HOST="${HOST//{{ secrets.HOST }}/$SPONGO_HOST:-}"
              PORT="${PORT//{{ secrets.PORT }}/$SPONGO_PORT:-22}"
              USER="${USER//{{ secrets.USER }}/$SPONGO_USER:-}"
              PRIVATE_KEY="${PRIVATE_KEY//{{ secrets.PRIVATE_KEY }}/$SPONGO_PRIVATE_KEY:-}"
              
              runSshOnRemote "$HOST" "$PORT" "$USER" "$PRIVATE_KEY" "$COMMAND"
            fi
            
            STEP_INDEX=$((STEP_INDEX + 1))
          done
        done
      fi
    done
  fi
  
  echo "✅ Completed: $(date)"
}

# Запуск
if [[ "${1:-}" == "monitor" ]]; then
  monitor_mode
else
  main "$1"
fi
