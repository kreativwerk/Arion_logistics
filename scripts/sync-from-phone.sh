#!/usr/bin/env bash
# Hält den lokalen Checkout automatisch mit dem Claude-Branch auf GitHub synchron.
#
# Ablauf:
#   1. Auf dem Handy in Claude Code Änderungen beschreiben -> Claude committet & pusht.
#   2. Dieses Skript läuft auf dem Rechner, holt alle N Sekunden den Branch
#      und führt einen Fast-Forward-Pull aus.
#   3. Läuft `flutter run` mit --pid-file, wird nach jedem Pull ein Hot Reload
#      (SIGUSR1) ausgelöst. Bei Änderungen an pubspec.yaml ein Hot Restart (SIGUSR2).
#
# Nutzung (macOS / Linux):
#   scripts/sync-from-phone.sh                       # Standard-Branch, alle 20 s
#   scripts/sync-from-phone.sh claude/mein-branch 10 # anderer Branch, alle 10 s
#
# Flutter dazu so starten (zweites Terminal):
#   cd flutter_app/kpi_admin
#   flutter run -d chrome --pid-file /tmp/codriver_flutter.pid

set -u

BRANCH="${1:-claude/mobile-app-sync-b6d675}"
INTERVAL="${2:-20}"
PID_FILE="${FLUTTER_PID_FILE:-/tmp/codriver_flutter.pid}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

# Auf den Ziel-Branch wechseln (lokal anlegen, falls nötig).
if [ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ]; then
  if ! git diff --quiet || ! git diff --cached --quiet; then
    log "Lokale, nicht committete Änderungen gefunden. Bitte erst committen oder stashen."
    exit 1
  fi
  git fetch origin "$BRANCH" || exit 1
  git checkout -B "$BRANCH" "origin/$BRANCH" || exit 1
fi

log "Synchronisiere '$BRANCH' alle ${INTERVAL}s. Beenden mit Ctrl+C."

while true; do
  if git fetch --quiet origin "$BRANCH"; then
    LOCAL="$(git rev-parse HEAD)"
    REMOTE="$(git rev-parse "origin/$BRANCH")"
    if [ "$LOCAL" != "$REMOTE" ]; then
      CHANGED="$(git diff --name-only "$LOCAL" "$REMOTE")"
      if git pull --ff-only --quiet origin "$BRANCH"; then
        log "Neue Änderungen übernommen ($(git log --oneline -1))."
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
          if printf '%s\n' "$CHANGED" | grep -q 'pubspec\.yaml$'; then
            kill -USR2 "$(cat "$PID_FILE")" && log "Hot Restart ausgelöst (pubspec geändert)."
          else
            kill -USR1 "$(cat "$PID_FILE")" && log "Hot Reload ausgelöst."
          fi
        fi
      else
        log "Pull nicht möglich (kein Fast-Forward). Bitte manuell prüfen: git status"
      fi
    fi
  else
    log "Fetch fehlgeschlagen (Netzwerk?). Versuche es erneut."
  fi
  sleep "$INTERVAL"
done
