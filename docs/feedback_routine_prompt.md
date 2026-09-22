# Routine: CoDriver Feedback-Tickets bearbeiten

Anlegen unter claude.ai/code → Routines → "New routine":

- **Name:** CoDriver Feedback-Tickets bearbeiten
- **Zeitplan:** stündlich, 7–21 Uhr (Cron UTC: `0 5-19 * * *`)
- **Modus:** jede Ausführung startet eine neue Session in der Umgebung mit dem Repo
  `kreativwerk/Arion_logistics`; die Umgebung muss die Variable `FEEDBACK_AGENT_KEY` enthalten
  (siehe README, Abschnitt "Feedback-Tickets automatisch beantworten").
- **Prompt:** den Block unten komplett einfügen.

---

Du bearbeitest neue Feedback-Tickets der CoDriver-App (Repo kreativwerk/Arion_logistics, Flutter-App in flutter_app/kpi_admin). Lies zuerst CLAUDE.md und README.md (Abschnitt "Feedback-Tickets automatisch beantworten").

## 1. Tickets holen
Der Schlüssel liegt in der Umgebungsvariable FEEDBACK_AGENT_KEY. Ist sie leer oder nicht gesetzt, beende die Session sofort ohne weitere Aktion und ohne Kommentar.

```
curl -sS -H "x-agent-key: $FEEDBACK_AGENT_KEY" \
  https://us-central1-gaurav-arion-001-3d94a.cloudfunctions.net/feedbackAgentList
```

Antwort ist JSON: `{count, tickets:[{id,title,description,priority,status,createdByRole,platform,hasAttachment,createdAt,...}]}`. Bei count 0 oder HTTP-Fehler (401/500): Session beenden, nichts weiter tun. Gib den Schlüssel niemals in Ausgaben, Commits oder Kommentaren aus.

## 2. Jedes Ticket bearbeiten
Arbeite auf dem Branch claude/mobile-app-sync-b6d675 (`git fetch origin claude/mobile-app-sync-b6d675 && git checkout -B claude/mobile-app-sync-b6d675 origin/claude/mobile-app-sync-b6d675`). Existiert er nicht, lege ihn von main an.

Für jedes Ticket entscheide:
- Bug oder klarer, kleiner Änderungswunsch an der App: umsetzen. Erst die zugehörigen Skills aus CLAUDE.md heranziehen. Danach `flutter analyze` auf die geänderten Dateien laufen lassen (Flutter ggf. per `git clone --depth 1 -b stable https://github.com/flutter/flutter.git` ins Scratchpad holen und den bin-Ordner in den PATH nehmen; danach `git checkout -- analysis_options.yaml pubspec.lock` im App-Ordner, damit `pub get` keine Dateien verändert). Vor jedem Commit den Qualitätscheck und Review laut CLAUDE.md durchführen (Skill gstack, sonst code-review) und Funde beheben. Dann committen und mit `git push -u origin claude/mobile-app-sync-b6d675` pushen. Ein Commit pro Ticket, Ticket-ID in der Commit-Nachricht.
- Große Umbauten, unklare Wünsche, Fragen, Lob oder Dinge außerhalb der App: nicht umsetzen, nur antworten.

## 3. Kurze Antwort schreiben
Zu jedem Ticket eine Antwort in einfacher Sprache: Deutsch, maximal 2 bis 3 kurze Sätze, keine Fachwörter, freundlich, per "du". Inhalt: Was wurde gemacht oder was passiert als Nächstes. Wenn nichts umgesetzt wurde, sag ehrlich warum in einem Satz. Bei umgesetzten Änderungen den Hinweis geben, dass die Änderung mit dem nächsten App-Update kommt.

```
curl -sS -X POST -H "x-agent-key: $FEEDBACK_AGENT_KEY" -H "Content-Type: application/json" \
  https://us-central1-gaurav-arion-001-3d94a.cloudfunctions.net/feedbackAgentReply \
  -d '{"feedbackId":"<id>","reply":"<Antwort>","status":"<open|resolved>"}'
```

status "resolved" nur, wenn das Ticket komplett erledigt ist (Fix gepusht oder Frage vollständig beantwortet). Bei größeren Wünschen, die ein Mensch entscheiden muss: status "open". Antwort 409 bedeutet, ein Mensch hat schon geantwortet: Ticket überspringen.

## 4. Abschluss
Am Ende eine kurze Zusammenfassung in der Session: welche Tickets, was gemacht, welche brauchen eine menschliche Entscheidung. Keine Pull Requests anlegen.
