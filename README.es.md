# Claude Orchestration

**[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md) | [ไทย](README.th.md) | [Tiếng Việt](README.vi.md)**

Varios agentes de Claude CLI colaborando en el desarrollo de juegos a traves de comunicacion asincrona basada en archivos.

Un solo archivo bat configura todo. Los agentes toman tareas de forma autonoma, implementan funcionalidades, revisan codigo y gestionan el tablero del proyecto — todo coordinado mediante archivos markdown.

## Como Funciona

```
orchestrate.bat  (doble clic)
    |
    |-- Verificacion de dependencias (Git, Claude CLI)
    |-- Seleccionar carpeta del proyecto de juego (dialogo moderno)
    |-- Auto-deteccion del motor (Unity / Godot / Unreal)
    |-- Configuracion interactiva:
    |       Remoto Git, politica de commits, direccion de desarrollo,
    |       modo de agentes, nivel de revision, escaneo de documentos
    |-- Generar configuracion del proyecto + prompts de agentes
    |-- Lanzar agentes en terminales separadas
    v
  4 agentes ejecutandose en paralelo, comunicandose via orchestration/
```

## Agentes

| Agente | Rol | Que hace |
|--------|-----|----------|
| **Supervisor** | Orquestador | Creacion de assets, auditorias de calidad de codigo, correccion de errores, gestion de tareas |
| **Developer** | Constructor | Implementa logica del juego, escribe pruebas, hace commits del codigo |
| **Client** | Revisor | Revisiones QA multi-persona, retroalimentacion de calidad |
| **Coordinator** | Gestor | Sincronizacion del tablero, reposicion del backlog, redaccion de especificaciones, monitoreo de agentes |

## Requisitos

| Programa | Requerido | Instalacion |
|----------|-----------|-------------|
| Git for Windows | Si | https://git-scm.com/download/win |
| Node.js 18+ | Si | https://nodejs.org |
| Claude CLI | Si | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | Recomendado | Preinstalado en Windows 10/11 |

## Inicio Rapido

```bash
# 1. Clonar
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. Doble clic en orchestrate.bat
#    - Selecciona la carpeta de tu proyecto de juego
#    - Auto-detecta motor, directorios, documentos existentes
#    - Hace preguntas de configuracion (direccion, modo de agentes, etc.)
#    - Lanza los agentes

# O desde la linea de comandos:
orchestrate.bat "C:\ruta\a\tu\juego"
```

## Opciones de Configuracion

La configuracion interactiva pregunta:

| Opcion | Opciones | Por defecto |
|--------|----------|-------------|
| **Documentos existentes** | Escanear documentos del proyecto para que los agentes lean en el primer ciclo | Si |
| **Git** | Inicializar repositorio, configurar URL remota | Auto-deteccion |
| **Politica de commit/push** | task / review / batch / manual | task |
| **Direccion de desarrollo** | stabilize / feature / polish / content / custom | feature |
| **Modo de agentes** | full (4) / lean (2) / solo (1) | full |
| **Nivel de revision** | strict / standard / minimal | standard |

## Que Se Crea

Cuando ejecutas orchestrate.bat en un proyecto de juego, se crea:

```
tu-proyecto-de-juego/
  orchestration/
    project.config.md        # Todas las configuraciones (los agentes leen esto en cada ciclo)
    BOARD.md                 # Tablero Kanban (Backlog > En Progreso > En Revision > Hecho)
    BACKLOG_RESERVE.md       # Pool de tareas para que los desarrolladores elijan
    agents/                  # Definiciones de roles de agentes
    prompts/                 # Prompts de lanzamiento de agentes
    templates/               # Plantillas de documentos (tarea, revision, especificacion, etc.)
    tasks/                   # Especificaciones de tareas (TASK-001.md, ...)
    reviews/                 # Resultados de revisiones (REVIEW-001-v1.md, ...)
    decisions/               # Decisiones del supervisor
    discussions/             # Discusiones de agentes (debates asincronos)
      concluded/             # Discusiones resueltas
    specs/                   # Especificaciones de funcionalidades (SPEC-R-001.md, ...)
    logs/                    # Logs de ciclo por agente
    .run_SUPERVISOR.sh       # Scripts de ejecucion de agentes
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## Flujo de Trabajo

```
Backlog --> En Progreso --> En Revision --> Hecho
                ^               |
                '-- Rechazado <-'
```

1. **Supervisor/Coordinator** crean tareas en BACKLOG_RESERVE
2. **Developer** toma la tarea principal, la implementa
3. Developer mueve la tarea a En Revision
4. **Client** realiza revision multi-persona (4 personas revisoras)
5. APPROVE -> Hecho / NEEDS_WORK -> Rechazado -> Developer corrige

## Modos de Agentes

### Full (4 agentes)
Todos los agentes activos. Ciclo completo de revision, gestion de tablero, creacion de assets.

### Lean (2 agentes)
Solo Developer + Supervisor. Sin revisor ni coordinador dedicados. El Supervisor maneja las revisiones y la sincronizacion del tablero.

### Solo (1 agente)
Un unico agente Developer con todos los roles fusionados. Auto-revision, tablero autogestionado. Ideal para proyectos pequenos o desarrollo individual.

## Reanudar

Si ejecutas orchestrate.bat en un proyecto que ya tiene `orchestration/`, detecta la configuracion existente:

```
  Orquestacion existente detectada!
  Modo: full    Direccion: stabilize

  1) Reanudar     - solo lanzar agentes (omitir configuracion)
  2) Reconfigurar - ejecutar configuracion de nuevo
  3) Cancelar
```

## Otras Herramientas

| Archivo | Que hace |
|---------|----------|
| `add-feature.bat` | Describe una funcionalidad en texto plano -> auto-genera tareas + especificaciones |
| `monitor.bat` | Monitorea logs del editor Unity/Godot para errores en tiempo de ejecucion, crea tareas de errores automaticamente |

## Mecanismos Clave

### FREEZE
Agrega un aviso FREEZE al inicio de BOARD.md -> todos los agentes se detienen inmediatamente. Eliminalo para reanudar.

### Discusiones
Los agentes pueden abrir debates asincronos en `discussions/`. Se usan para decisiones de diseno, cambios de prioridad, mejoras de protocolo. Todos los agentes responden en su seccion, luego el supervisor concluye.

### Auto-progresion
Developer puede avanzar automaticamente entre tareas sin esperar al supervisor. Las tareas de QA/balance omiten la revision por completo. Las nuevas tareas del sistema siempre requieren revision del Client.

## Motores Soportados

| Motor | Auto-deteccion | Log de errores | Configuracion de ejemplo |
|-------|----------------|----------------|--------------------------|
| Unity | Archivos `.meta`, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## Vista General de Archivos

```
orchestrate.bat          # Punto de entrada principal (configuracion + lanzamiento)
add-feature.bat          # Agregar funcionalidad por descripcion de texto
monitor.bat              # Monitoreo de errores en tiempo de ejecucion
pick-folder.ps1          # Dialogo moderno de seleccion de carpeta (IFileDialog COM)
auto-setup.sh            # Deteccion de motor, generacion de configuracion, configuracion interactiva
init.sh                  # Creacion de estructura de directorios
launch.sh                # Lanzador de agentes multiplataforma
extract-features.sh      # Analizar codebase -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> tareas + especificaciones
add-feature.sh           # Lenguaje natural -> tareas + especificaciones
monitor.sh               # Monitor de Editor.log + reportador de errores
project.config.md        # Plantilla de configuracion en blanco
framework/
  agents/                # Definiciones de roles de agentes (4 archivos)
  prompts/               # Prompts de ciclo de agentes (4 archivos)
  templates/             # Plantillas de documentos (7 archivos)
sample-config/           # Configuraciones de ejemplo para Unity/Godot
```

## Licencia

MIT
