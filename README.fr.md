# Claude Orchestration

**[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md)**

Plusieurs agents Claude CLI collaborant au developpement de jeux via une communication asynchrone basee sur des fichiers.

Un seul fichier bat configure tout. Les agents prennent en charge les taches de maniere autonome, implementent des fonctionnalites, revisent le code et gerent le tableau de projet -- le tout coordonne via des fichiers markdown.

## Comment ca fonctionne

```
orchestrate.bat  (double-cliquer)
    |
    |-- Verification des dependances (Git, Claude CLI)
    |-- Selection du dossier de projet de jeu (boite de dialogue moderne)
    |-- Detection automatique du moteur (Unity / Godot / Unreal)
    |-- Configuration interactive :
    |       Remote Git, politique de commit, direction de dev,
    |       mode agent, niveau de revue, scan de docs
    |-- Generation de la config projet + prompts des agents
    |-- Lancement des agents dans des terminaux separes
    v
  4 agents en parallele, communiquant via orchestration/
```

## Agents

| Agent | Role | Ce qu'il fait |
|-------|------|---------------|
| **Supervisor** | Orchestrateur | Creation d'assets, audits de qualite du code, corrections de bugs, gestion des taches |
| **Developer** | Constructeur | Implemente la logique de jeu, ecrit des tests, commit le code |
| **Client** | Reviseur | Revues QA multi-persona, retours sur la qualite |
| **Coordinator** | Gestionnaire | Synchronisation du tableau, reapprovisionnement du backlog, redaction de specs, surveillance des agents |

## Prerequis

| Programme | Requis | Installation |
|-----------|--------|--------------|
| Git for Windows | Oui | https://git-scm.com/download/win |
| Node.js 18+ | Oui | https://nodejs.org |
| Claude CLI | Oui | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | Recommande | Pre-installe sur Windows 10/11 |

## Demarrage rapide

```bash
# 1. Cloner
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. Double-cliquer sur orchestrate.bat
#    - Selectionne votre dossier de projet de jeu
#    - Detecte automatiquement le moteur, les repertoires, les docs existants
#    - Pose les questions de configuration (direction, mode agent, etc.)
#    - Lance les agents

# Ou depuis la ligne de commande :
orchestrate.bat "C:\path\to\your\game"
```

## Options de configuration

La configuration interactive demande :

| Option | Choix | Par defaut |
|--------|-------|------------|
| **Docs existants** | Scanner les docs du projet pour que les agents les lisent au premier cycle | Oui |
| **Git** | Initialiser le depot, definir l'URL remote | Detection automatique |
| **Politique de commit/push** | task / review / batch / manual | task |
| **Direction de dev** | stabilize / feature / polish / content / custom | feature |
| **Mode agent** | full (4) / lean (2) / solo (1) | full |
| **Niveau de revue** | strict / standard / minimal | standard |

## Ce qui est cree

Lorsque vous executez orchestrate.bat sur un projet de jeu, il cree :

```
votre-projet-de-jeu/
  orchestration/
    project.config.md        # Tous les parametres (les agents lisent ceci a chaque cycle)
    BOARD.md                 # Tableau Kanban (Backlog > En cours > En revue > Termine)
    BACKLOG_RESERVE.md       # Reserve de taches que les developpeurs peuvent prendre
    agents/                  # Definitions des roles des agents
    prompts/                 # Prompts de lancement des agents
    templates/               # Modeles de documents (tache, revue, spec, etc.)
    tasks/                   # Specifications de taches (TASK-001.md, ...)
    reviews/                 # Resultats de revues (REVIEW-001-v1.md, ...)
    decisions/               # Decisions du superviseur
    discussions/             # Discussions entre agents (debats asynchrones)
      concluded/             # Discussions resolues
    specs/                   # Specifications de fonctionnalites (SPEC-R-001.md, ...)
    logs/                    # Journaux de cycle par agent
    .run_SUPERVISOR.sh       # Scripts d'execution des agents
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## Flux de travail

```
Backlog --> En cours --> En revue --> Termine
                ^            |
                '-- Rejete <-'
```

1. **Supervisor/Coordinator** creent des taches dans BACKLOG_RESERVE
2. **Developer** prend la tache prioritaire et l'implemente
3. Le Developer deplace la tache vers En revue
4. **Client** effectue une revue multi-persona (4 personas de reviseurs)
5. APPROUVE -> Termine / A_RETRAVAILLER -> Rejete -> Le Developer corrige

## Modes agent

### Full (4 agents)
Tous les agents actifs. Cycle de revue complet, gestion du tableau, creation d'assets.

### Lean (2 agents)
Developer + Supervisor uniquement. Pas de reviseur ni de coordinateur dedies. Le Supervisor gere les revues et la synchronisation du tableau.

### Solo (1 agent)
Un seul agent Developer avec tous les roles fusionnes. Auto-revue, tableau autogere. Adapte aux petits projets ou au developpement en solo.

## Reprise

Si vous executez orchestrate.bat sur un projet qui possede deja `orchestration/`, il detecte la configuration existante :

```
  Configuration existante detectee !
  Mode : full    Direction : stabilize

  1) Reprendre     - lancer les agents uniquement (passer la configuration)
  2) Reconfigurer  - relancer la configuration
  3) Annuler
```

## Autres outils

| Fichier | Ce qu'il fait |
|---------|---------------|
| `add-feature.bat` | Decrire une fonctionnalite en texte libre -> genere automatiquement des taches + specs |
| `monitor.bat` | Surveiller les logs de l'editeur Unity/Godot pour les erreurs d'execution, creer automatiquement des taches de bug |

## Mecanismes cles

### FREEZE
Ajouter un avis FREEZE en haut de BOARD.md -> tous les agents s'arretent immediatement. Le retirer pour reprendre.

### Discussions
Les agents peuvent ouvrir des debats asynchrones dans `discussions/`. Utilise pour les decisions de conception, les changements de priorite, les ameliorations de protocole. Tous les agents repondent dans leur section, puis le superviseur conclut.

### Auto-progression
Le Developer peut avancer automatiquement a travers les taches sans attendre le superviseur. Les taches QA/equilibrage sautent entierement la revue. Les nouvelles taches systeme necessitent toujours une revue du Client.

## Moteurs supportes

| Moteur | Detection automatique | Journal d'erreurs | Exemple de config |
|--------|----------------------|-------------------|-------------------|
| Unity | Fichiers `.meta`, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## Apercu des fichiers

```
orchestrate.bat          # Point d'entree principal (configuration + lancement)
add-feature.bat          # Ajouter une fonctionnalite par description textuelle
monitor.bat              # Surveillance des erreurs d'execution
pick-folder.ps1          # Boite de dialogue moderne de selection de dossier (COM IFileDialog)
auto-setup.sh            # Detection du moteur, generation de config, configuration interactive
init.sh                  # Creation de la structure de repertoires
launch.sh                # Lanceur d'agents multiplateforme
extract-features.sh      # Analyser le codebase -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> taches + specs
add-feature.sh           # Langage naturel -> taches + specs
monitor.sh               # Surveillance de Editor.log + rapporteur d'erreurs
project.config.md        # Modele de config vierge
framework/
  agents/                # Definitions des roles des agents (4 fichiers)
  prompts/               # Prompts de cycle des agents (4 fichiers)
  templates/             # Modeles de documents (7 fichiers)
sample-config/           # Exemples de configs pour Unity/Godot
```

## Licence

MIT
