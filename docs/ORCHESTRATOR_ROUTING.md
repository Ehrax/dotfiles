# Orchestrator routing

Dieses Dokument beschreibt, welches Modell welches Harness direkt verwenden darf
und wann ein anderer Harness über einen kleinen Bridge-Agent gestartet werden
muss. Es ist eine Routing- und Capability-Dokumentation, kein verbindlicher
Implementierungsprozess.

Die Orchestratoren sollen die verfügbaren Möglichkeiten kennen und gute
Entscheidungen treffen. Sie sollen nicht künstlich jeden Task in dieselbe lange
Pipeline zwingen. PRDs und Slice-Zuschnitte kommen normalerweise aus
`wayfinder` oder aus dem jeweiligen Projektkontext; der Orchestrator übernimmt
vor allem die Auswahl von Harness, Modell und Effort.

## Die drei Ebenen

Bei jeder Delegation sind drei Rollen auseinanderzuhalten:

| Ebene | Frage |
|---|---|
| Parent / Orchestrator | Welches Modell steuert die aktuelle Aufgabe? |
| Harness | Über welches Agentensystem wird gearbeitet? |
| Worker / Reviewer | Welches Modell führt den konkreten Auftrag aus? |

Beispiel:

```text
Fable (Parent im Claude-Harness)
  -> Sonnet-low-Sub-Agent (Bridge im Claude-Harness)
      -> codex-review als CLI (Codex-Harness)
          -> Review-Report zurück an Fable
```

Der Sonnet-Agent ist hier nicht der eigentliche Reviewer. Er ist nur der
Claude-seitige Adapter, der den Codex-Prozess startet, dessen Ergebnis liest
und an Fable zurückgibt.

## Grundregel: direkt im eigenen Harness, Bridge beim Harness-Wechsel

```text
Eigenes Harness
  -> direkt delegieren

Anderes Harness
  -> über den vorgesehenen Bridge-/Sub-Agent-Weg starten
```

Ein Bridge-Agent ist nicht für jede Delegation erforderlich. Wenn ein Modell
ein Tool oder einen Prozess direkt über sein eigenes Harness starten kann, soll
es das direkt tun. Ein Bridge-Agent wird nur benötigt, wenn die Aufgabe in ein
anderes Agentensystem wechseln muss oder die lokale Harness-Grenze das direkte
Aufrufen verhindert.

## Claude-/Fable-Seite

Fable läuft im Claude-Harness und kann dort direkt Claude-Sub-Agents oder
Workflows verwenden. Fable hat außerdem eigene Agenten- und Internet-Tools.

Typische Pfade:

```text
Fable
  -> Claude/Sonnet-Sub-Agent
      -> direkt im Claude-Harness
```

Wenn Fable Codex-Fähigkeiten benötigt, etwa einen Codex-Review oder Codex
Computer Use, läuft der Wechsel über einen günstigen Claude-Sub-Agenten:

```text
Fable
  -> Sonnet-low-Sub-Agent
      -> Codex CLI / Codex Review / Codex Computer Use als Script
          -> Ergebnis zurück an Fable
```

Der Wrapper muss auf das Ende des Codex-Aufrufs warten, den erzeugten Report
lesen und nur das relevante Ergebnis an Fable zurückgeben. Der Codex-Prozess
darf nicht als verwaister Hintergrundprozess zurückgelassen werden.

Beispiele:

```text
Fable möchte einen Implementierungsslice prüfen:
  -> Sonnet-low startet codex-review als CLI
  -> Codex liefert Findings
  -> Sonnet-low extrahiert den Report
  -> Fable entscheidet, was davon relevant ist
```

```text
Fable möchte die laufende App mit Computer Use untersuchen:
  -> Sonnet-low startet den freigegebenen Codex-Computer-Use-Aufruf
  -> Codex untersucht die App
  -> Ergebnis geht an Fable zurück
```

Fable muss nicht automatisch Claude über einen zusätzlichen Bridge-Weg
starten: Claude ist bereits das eigene Harness. Claude wird daher direkt
verwendet; Codex wird über den Claude-seitigen Adapter geholt.

## Codex-/Sol-/Terra-Seite

Sol oder Terra laufen im Codex-Harness. Sie können Codex-Threads, Codex-Modelle,
Sub-Agents, Browser und Computer Use direkt einsetzen. Sie dürfen nicht aus
sich selbst heraus einfach nochmals `codex-cli` als externe Codex-Instanz
starten.

Typische direkte Pfade:

```text
Sol/Terra
  -> Codex-Thread
  -> Luna-/Terra-/Sol-Worker
  -> Codex Browser oder Computer Use
```

Wenn ein Codex-Orchestrator das Claude-Harness benötigt, wird ein günstiger
Codex-Thread als Bridge verwendet:

```text
Sol/Terra
  -> Luna-low-Codex-Thread
      -> Claude-Skill / Claude CLI
          -> Ergebnis zurück an Sol/Terra
```

Das ist ein optionaler Capability-Wechsel, kein Standardpfad. Für viele UI-,
Copy- oder Workflow-Aufgaben kann Codex zunächst selbst Sol, Terra, Fable oder
Opus routen. Ob Claude wirklich einen Vorteil bringt, soll anhand von kleinen
Vergleichs-Slices evaluiert werden.

## Modellwahl und Effort

Jede Projekt-`AGENTS.md` enthält die konkrete Routing-Tabelle. Diese Tabelle ist
die Quelle der Wahrheit für Modellstärken und Kosten. Der Orchestrator muss
nicht alle Modellentscheidungen in diesem Dokument wiederholen, sondern für
den jeweiligen Task mindestens bestimmen:

```text
Parent-Modell
-> erforderliches Harness
-> direkt oder Bridge
-> Worker-/Reviewer-Modell
-> Effort
```

Effort ist taskabhängig. Ein günstiger Worker mit gutem Brief kann für
mechanische Arbeit genügen; ein unabhängiger Review oder eine schwierige
Architekturfrage kann mehr Effort rechtfertigen. Harte oder risikoreiche
Aufgaben werden bewusst explizit an ein stärkeres Modell geroutet, statt jeden
Task standardmäßig teuer zu machen.

Für UI-Arbeit ist insbesondere offen, wie gut Sol und Terra im Vergleich zu
Fable oder Opus geworden sind. Diese Entscheidung sollte nicht vorausgesetzt,
sondern über vergleichbare Slices mit Blick auf Qualität, Korrekturschleifen,
Tests und Tokenverbrauch evaluiert werden.

## Verfügbare Validierung

Validierung ist eine Capability, kein starrer Ablauf. Je nach Slice können
folgende Ebenen relevant sein:

- Unit Tests, typischerweise aus TDD heraus
- Integration Tests
- Acceptance Tests
- Browser-Tests
- Computer Use gegen die laufende App
- unabhängiger Codex-Review
- optional eine zusätzliche Meinung eines anderen Modells

Der Orchestrator soll die passende Kombination auswählen und fehlende
Validierung als Risiko benennen. Er muss nicht jeden Slice durch alle Ebenen
schleusen.

## Routing-Beispiele

### Fable: Codex-Review

```text
Fable (Claude-Harness)
  -> Sonnet-low-Bridge
      -> codex-review CLI mit dem in AGENTS.md gewählten Codex-Modell/Effort
          -> Report
  -> Fable verifiziert die Findings und entscheidet über Fixes
```

### Fable: Computer Use

```text
Fable
  -> Sonnet-low-Bridge
      -> Codex Computer Use als Script
          -> Beobachtung / Ergebnis zurück an Fable
```

### Sol: eigener Codex-Thread

```text
Sol (Codex-Harness)
  -> direkter Codex-Thread
      -> Luna-low für einen mechanischen Slice
      -> Terra oder Sol für anspruchsvollere Logik
```

### Sol: zusätzliche Claude-Fähigkeit

```text
Sol
  -> Luna-low-Codex-Thread
      -> Claude-Skill
          -> Claude bearbeitet den eng abgegrenzten Auftrag
              -> Report zurück an Sol
```

### Optionale finale Mehrfachmeinung

```text
Parent-Orchestrator
  -> normaler eigener Review-Pfad
  -> nur bei explizitem Bedarf: zusätzlicher Review mit anderem Modell
```

Eine zusätzliche externe Meinung ist damit eine bewusste Entscheidung des
Users oder des Briefs und kein automatisch eingebauter Schritt. So bleiben
Tokenverbrauch und Laufzeit kontrollierbar.

## Was dieses Dokument bewusst nicht festlegt

- keine feste PRD- oder Slice-Methodik
- keine immer gleiche TDD-Reihenfolge
- keine Pflicht, jedes verfügbare Modell zu verwenden
- keine automatische Claude-Nutzung durch Codex
- keine automatische Codex-Nutzung durch Fable außerhalb der erlaubten
  Bridge-/Harness-Regeln
- keine endgültige Aussage darüber, welches Modell UI am besten beherrscht

Diese Punkte sind später geeignete Kandidaten für einen gezielten Eval- und
Challenge-Schritt.
