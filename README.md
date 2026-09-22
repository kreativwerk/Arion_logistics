# DSP KPI

Admin and driver dashboard for DSP KPIs, with a PDF parsing service and Firebase backend.

## Repo layout

- `flutter_app/kpi_admin/`: Flutter admin/driver application
- `parser_service/`: Python PDF parsing service
- `firebase/functions/`: Firebase Cloud Functions (TypeScript)
- `firebase/*.rules`: Firestore/Storage rules and indexes
- `*.pdf`: Sample scorecard/POD quality inputs

## Requirements

- Flutter (latest stable) + Dart
- Node.js 22 (for Firebase Functions)
- Python 3.10+
- Firebase project configured (see `flutter_app/kpi_admin/lib/firebase_options.dart`)

## Getting started

### Flutter app

```sh
cd flutter_app/kpi_admin
flutter pub get
flutter run -d chrome
```

### Web production deploy (no offline cache)

```sh
cd flutter_app/kpi_admin
flutter build web --release --pwa-strategy=none
cd ../../firebase
firebase deploy --only hosting
```

### Parser service

```sh
cd parser_service
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

### Firebase functions

```sh
cd firebase/functions
npm install
npm run build
```

## Vom Handy aus entwickeln (Claude Code Web → Rechner)

Änderungen werden in Claude Code (Web/App) beschrieben, Claude committet und pusht sie auf
den Branch `claude/mobile-app-sync-b6d675`. Auf dem Rechner zieht ein Sync-Skript den Branch
automatisch und löst in der laufenden App ein Hot Reload aus.

Einmalig auf dem Rechner, zwei Terminals:

```sh
# Terminal 1: App mit PID-Datei starten (nötig für automatisches Hot Reload)
cd flutter_app/kpi_admin
flutter run -d chrome --pid-file /tmp/codriver_flutter.pid

# Terminal 2: Sync-Schleife starten (macOS/Linux)
scripts/sync-from-phone.sh
```

Windows (PowerShell): `.\scripts\sync-from-phone.ps1`, nach jedem Pull im Flutter-Terminal `r` drücken.

Parameter: `scripts/sync-from-phone.sh <branch> <intervall-sekunden>` (Standard: obiger Branch, 20 s).
Das Skript macht nur Fast-Forward-Pulls. Lokale Änderungen vorher committen, sonst wird der
Branch-Wechsel verweigert. Ist der Branch in `main` gemerged, das Skript mit dem neuen Claude-Branch starten.

## Feedback-Tickets automatisch beantworten (Claude-Routine)

Neue Feedback-Tickets werden stündlich von einer Claude-Code-Routine gelesen, wenn möglich
umgesetzt (Push auf den Claude-Branch) und mit einer kurzen Antwort in einfacher Sprache
versehen. Die Antwort erscheint in der App auf der Feedback-Seite unter dem Ticket
("Antwort vom Team"). Entwickler können Antworten dort auch selbst schreiben oder ändern.

Technik: zwei HTTPS-Functions (`feedbackAgentList`, `feedbackAgentReply`), geschützt durch
einen geheimen Schlüssel im Header `x-agent-key`. Der Antwort-Endpunkt kann nur den
Antworttext und den Status (offen/erledigt) eines Tickets setzen.

Einmalige Einrichtung:

```sh
# 1. Schlüssel erzeugen (mind. 32 Zeichen) und als Secret hinterlegen
openssl rand -hex 32
cd firebase
firebase functions:secrets:set FEEDBACK_AGENT_KEY      # Wert einfügen

# 2. Functions bauen und deployen
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions:feedbackAgentList,functions:feedbackAgentReply
```

3. Denselben Schlüssel in der Claude-Code-Umgebung als Umgebungsvariable `FEEDBACK_AGENT_KEY`
   eintragen (claude.ai/code → Environments → Umgebung bearbeiten → Environment variables).

4. Die Routine in claude.ai/code anlegen; Name, Zeitplan und vollständiger Prompt stehen in
   `docs/feedback_routine_prompt.md`.

Die Routine ruft dann `https://us-central1-gaurav-arion-001-3d94a.cloudfunctions.net/feedbackAgentList`
auf. Ohne gesetzte Variable beendet sich die Routine ohne Aktion. Manuell testen:

```sh
curl -H "x-agent-key: $FEEDBACK_AGENT_KEY" \
  https://us-central1-gaurav-arion-001-3d94a.cloudfunctions.net/feedbackAgentList
```

## Notes

- The parser service ingests DSP scorecard and POD quality PDFs and writes structured data for the app to consume.
- Sample PDFs in the repo root can be used to validate parser behavior.
