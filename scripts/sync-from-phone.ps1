# Windows-Variante: hält den lokalen Checkout mit dem Claude-Branch synchron.
# Nutzung (PowerShell):
#   .\scripts\sync-from-phone.ps1
#   .\scripts\sync-from-phone.ps1 -Branch claude/mein-branch -IntervalSeconds 10
# Hinweis: Hot Reload per Signal gibt es unter Windows nicht; im Flutter-Terminal
# nach dem Pull einfach "r" drücken.

param(
  [string]$Branch = "claude/mobile-app-sync-b6d675",
  [int]$IntervalSeconds = 20
)

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Log($msg) { Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg) }

$current = (git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne $Branch) {
  git diff --quiet; $clean1 = $LASTEXITCODE -eq 0
  git diff --cached --quiet; $clean2 = $LASTEXITCODE -eq 0
  if (-not ($clean1 -and $clean2)) {
    Log "Lokale, nicht committete Änderungen gefunden. Bitte erst committen oder stashen."
    exit 1
  }
  git fetch origin $Branch
  git checkout -B $Branch "origin/$Branch"
}

Log "Synchronisiere '$Branch' alle ${IntervalSeconds}s. Beenden mit Ctrl+C."

while ($true) {
  git fetch --quiet origin $Branch
  if ($LASTEXITCODE -eq 0) {
    $local = (git rev-parse HEAD).Trim()
    $remote = (git rev-parse "origin/$Branch").Trim()
    if ($local -ne $remote) {
      git pull --ff-only --quiet origin $Branch
      if ($LASTEXITCODE -eq 0) {
        Log ("Neue Änderungen übernommen (" + (git log --oneline -1) + "). Im Flutter-Terminal 'r' drücken.")
      } else {
        Log "Pull nicht möglich (kein Fast-Forward). Bitte manuell prüfen: git status"
      }
    }
  } else {
    Log "Fetch fehlgeschlagen (Netzwerk?). Versuche es erneut."
  }
  Start-Sleep -Seconds $IntervalSeconds
}
