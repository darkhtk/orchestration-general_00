# Claude Orchestration

**[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md) | [ไทย](README.th.md) | [Tiếng Việt](README.vi.md)**

Mehrere Claude-CLI-Agenten arbeiten gemeinsam an der Spieleentwicklung durch dateibasierte asynchrone Kommunikation.

Eine einzige Bat-Datei richtet alles ein. Agenten nehmen selbststaendig Aufgaben an, implementieren Features, reviewen Code und verwalten das Projektboard -- alles koordiniert ueber Markdown-Dateien.

## Funktionsweise

```
orchestrate.bat  (Doppelklick)
    |
    |-- Abhaengigkeitspruefung (Git, Claude CLI)
    |-- Spielprojekt-Ordner auswaehlen (moderner Dialog)
    |-- Engine automatisch erkennen (Unity / Godot / Unreal)
    |-- Interaktive Einrichtung:
    |       Git-Remote, Commit-Richtlinie, Entwicklungsrichtung,
    |       Agentenmodus, Review-Stufe, Dokumentenscan
    |-- Projektkonfiguration + Agenten-Prompts generieren
    |-- Agenten in separaten Terminals starten
    v
  4 Agenten laufen parallel und kommunizieren ueber orchestration/
```

## Agenten

| Agent | Rolle | Aufgabe |
|-------|-------|---------|
| **Supervisor** | Orchestrator | Asset-Erstellung, Codequalitaetspruefungen, Fehlerbehebung, Aufgabenverwaltung |
| **Developer** | Entwickler | Implementiert Spiellogik, schreibt Tests, committet Code |
| **Client** | Reviewer | Multi-Persona-QA-Reviews, Qualitaetsfeedback |
| **Coordinator** | Manager | Board-Synchronisation, Backlog-Auffuellung, Spezifikationen schreiben, Agentenueberwachung |

## Voraussetzungen

| Programm | Erforderlich | Installation |
|-----------|-------------|-------------|
| Git for Windows | Ja | https://git-scm.com/download/win |
| Node.js 18+ | Ja | https://nodejs.org |
| Claude CLI | Ja | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | Empfohlen | Unter Windows 10/11 vorinstalliert |

## Schnellstart

```bash
# 1. Klonen
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. Doppelklick auf orchestrate.bat
#    - Waehlt Ihren Spielprojekt-Ordner aus
#    - Erkennt automatisch Engine, Verzeichnisse, vorhandene Dokumente
#    - Stellt Einrichtungsfragen (Richtung, Agentenmodus usw.)
#    - Startet die Agenten

# Oder ueber die Kommandozeile:
orchestrate.bat "C:\Pfad\zu\Ihrem\Spiel"
```

## Einrichtungsoptionen

Die interaktive Einrichtung fragt:

| Option | Auswahlmoeglichkeiten | Standard |
|--------|----------------------|----------|
| **Vorhandene Dokumente** | Projektdokumente scannen, die Agenten in der ersten Schleife lesen | Ja |
| **Git** | Repository initialisieren, Remote-URL setzen | Automatische Erkennung |
| **Commit/Push-Richtlinie** | task / review / batch / manual | task |
| **Entwicklungsrichtung** | stabilize / feature / polish / content / custom | feature |
| **Agentenmodus** | full (4) / lean (2) / solo (1) | full |
| **Review-Stufe** | strict / standard / minimal | standard |

## Was erstellt wird

Wenn Sie orchestrate.bat auf einem Spielprojekt ausfuehren, wird Folgendes erstellt:

```
ihr-spielprojekt/
  orchestration/
    project.config.md        # Alle Einstellungen (Agenten lesen dies bei jeder Schleife)
    BOARD.md                 # Kanban-Board (Backlog > In Bearbeitung > Im Review > Fertig)
    BACKLOG_RESERVE.md       # Aufgabenpool, aus dem Entwickler Aufgaben entnehmen
    agents/                  # Agentenrollendefinitionen
    prompts/                 # Agenten-Start-Prompts
    templates/               # Dokumentvorlagen (Aufgabe, Review, Spezifikation usw.)
    tasks/                   # Aufgabenspezifikationen (TASK-001.md, ...)
    reviews/                 # Review-Ergebnisse (REVIEW-001-v1.md, ...)
    decisions/               # Supervisor-Entscheidungen
    discussions/             # Agentendiskussionen (asynchrone Debatten)
      concluded/             # Abgeschlossene Diskussionen
    specs/                   # Feature-Spezifikationen (SPEC-R-001.md, ...)
    logs/                    # Schleifen-Logs pro Agent
    .run_SUPERVISOR.sh       # Agenten-Runner-Skripte
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## Arbeitsablauf

```
Backlog --> In Bearbeitung --> Im Review --> Fertig
                ^                  |
                '-- Abgelehnt <----'
```

1. **Supervisor/Coordinator** erstellen Aufgaben in BACKLOG_RESERVE
2. **Developer** nimmt die oberste Aufgabe an und implementiert sie
3. Developer verschiebt die Aufgabe nach Im Review
4. **Client** fuehrt Multi-Persona-Review durch (4 Reviewer-Personas)
5. GENEHMIGT -> Fertig / NACHARBEIT -> Abgelehnt -> Developer korrigiert

## Agentenmodi

### Full (4 Agenten)
Alle Agenten aktiv. Vollstaendiger Review-Zyklus, Board-Verwaltung, Asset-Erstellung.

### Lean (2 Agenten)
Nur Developer + Supervisor. Kein dedizierter Reviewer oder Coordinator. Supervisor uebernimmt Reviews und Board-Synchronisation.

### Solo (1 Agent)
Ein einzelner Developer-Agent mit allen Rollen zusammengefuehrt. Selbst-Review, selbstverwaltetes Board. Gut fuer kleine Projekte oder Einzelentwicklung.

## Fortsetzen

Wenn Sie orchestrate.bat auf einem Projekt ausfuehren, das bereits `orchestration/` enthaelt, erkennt es die vorhandene Einrichtung:

```
  Vorhandene Orchestrierung erkannt!
  Modus: full    Richtung: stabilize

  1) Fortsetzen    - Nur Agenten starten (Einrichtung ueberspringen)
  2) Neu konfigurieren - Einrichtung erneut ausfuehren
  3) Abbrechen
```

## Weitere Werkzeuge

| Datei | Funktion |
|-------|----------|
| `add-feature.bat` | Feature in Klartext beschreiben -> generiert automatisch Aufgaben + Spezifikationen |
| `monitor.bat` | Unity/Godot-Editor-Logs auf Laufzeitfehler ueberwachen, automatisch Bug-Aufgaben erstellen |

## Wichtige Mechanismen

### FREEZE
Fuegen Sie einen FREEZE-Hinweis oben in BOARD.md ein -> alle Agenten stoppen sofort. Entfernen Sie ihn, um fortzufahren.

### Diskussionen
Agenten koennen asynchrone Debatten in `discussions/` eroeffnen. Verwendet fuer Designentscheidungen, Prioritaetsaenderungen, Protokollverbesserungen. Alle Agenten antworten in ihrem Abschnitt, dann schliesst der Supervisor ab.

### Selbstfortschritt
Developer kann automatisch durch Aufgaben fortschreiten, ohne auf den Supervisor zu warten. QA-/Balance-Aufgaben ueberspringen das Review vollstaendig. Neue Systemaufgaben erfordern immer ein Client-Review.

## Unterstuetzte Engines

| Engine | Automatische Erkennung | Fehlerprotokoll | Beispielkonfiguration |
|--------|----------------------|-----------------|----------------------|
| Unity | `.meta`-Dateien, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## Dateien im Ueberblick

```
orchestrate.bat          # Haupteinstiegspunkt (Einrichtung + Start)
add-feature.bat          # Feature per Textbeschreibung hinzufuegen
monitor.bat              # Laufzeitfehler-Ueberwachung
pick-folder.ps1          # Moderner Ordnerauswahl-Dialog (IFileDialog COM)
auto-setup.sh            # Engine-Erkennung, Konfigurationsgenerierung, interaktive Einrichtung
init.sh                  # Verzeichnisstruktur erstellen
launch.sh                # Plattformuebergreifender Agenten-Launcher
extract-features.sh      # Codebasis analysieren -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> Aufgaben + Spezifikationen
add-feature.sh           # Natuerliche Sprache -> Aufgaben + Spezifikationen
monitor.sh               # Editor.log-Ueberwachung + Fehlerbericht
project.config.md        # Leere Konfigurationsvorlage
framework/
  agents/                # Agentenrollendefinitionen (4 Dateien)
  prompts/               # Agenten-Schleifen-Prompts (4 Dateien)
  templates/             # Dokumentvorlagen (7 Dateien)
sample-config/           # Beispielkonfigurationen fuer Unity/Godot
```

## Lizenz

MIT
