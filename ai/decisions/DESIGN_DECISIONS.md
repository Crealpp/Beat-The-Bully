# 📋 Registro de Decisiones de Diseño

> Este archivo registra las decisiones importantes tomadas durante el desarrollo,
> incluyendo las que fueron asistidas por IA. Sirve como memoria del proyecto.

---

## Formato

```
### [FECHA] — [TÍTULO DE LA DECISIÓN]
**Contexto:** Qué problema o situación motivó la decisión.
**Opciones consideradas:** Lista de alternativas evaluadas.
**Decisión tomada:** Qué se eligió y por qué.
**Consecuencias:** Impacto esperado (positivo y negativo).
**Asistida por IA:** Sí/No — [modelo usado si aplica]
```

---

## Decisiones

### 2026-03-09 — Elección del Motor de Juego
**Contexto:** El proyecto requiere interfaz gráfica obligatoria. El equipo tiene
experiencia limitada en desarrollo de juegos.

**Opciones consideradas:**
- Python + Pygame
- Python + Arcade
- Godot 4.6.1 (GDScript)
- Unity (C#)

**Decisión tomada:** **Godot 4.6.1** con GDScript.

**Razones:**
- Motor gratuito y open source
- GDScript es sintácticamente similar a Python (lenguaje base de la materia)
- Godot tiene excelente soporte para juegos 2D educativos
- Gran comunidad y documentación
- Export a múltiples plataformas sin licencia

**Consecuencias:**
- (+) Curva de aprendizaje menor para el equipo
- (+) Herramientas visuales integradas (editor de escenas, animaciones)
- (-) El lenguaje de la materia es Python; GDScript es similar pero no idéntico
- (-) Requiere aprender el paradigma de escenas/nodos de Godot

**Asistida por IA:** Sí — Claude Sonnet

---

### 2026-03-09 — Estructura del Repositorio
**Contexto:** Necesidad de organizar código, assets, documentación y archivos de IA.

**Decisión tomada:** Estructura separada con carpeta `/ai/` dedicada para contexto,
prompts y decisiones de IA. Documentación técnica en `/docs/`.

**Asistida por IA:** Sí — Claude Sonnet

---

### 2026-03-20 — Rhythm System Architecture (SOLID, signal-driven)
**Context:** The game requires a rhythm engine that syncs music playback, beat tracking,
player input, chart management, and scoring without tight coupling between components.

**Options considered:**
- Single monolithic GameManager script handling all rhythm logic
- Direct function calls between nodes (tight coupling)
- Multiple small classes communicating via Godot signals (decoupled)

**Decision taken:** Split the engine into 7 dedicated classes, each with a single
responsibility (SOLID), communicating mainly through Godot signals.

**Class responsibilities:**
- `NoteData` (Resource) — pure data: beat number + action string
- `PlayerInput` (Node) — only reads input, emits `button_pressed`
- `MusicPlayer` (AudioStreamPlayer) — playback + emits `time_updated` every frame
- `Metronome` (Node) — receives time from MusicPlayer, emits `beat_hit`, evaluates timing
- `Composer` (Node) — manages chart array, emits `note_expected` per beat
- `Judge` (Node) — compares player action vs expected note, emits `note_result`
- `Referee` (Node) — maintains HP/score/combo state, emits UI update signals

**Only direct dependency:** MusicPlayer → Metronome (via `update_time()` method call).
The rest of the wiring is signal-based.

**Consequences:**
- (+) Each class can be tested and replaced independently
- (+) Clear SOLID separation for OOP evaluation
- (+) No autoloads or singletons — all state is local to the node tree
- (-) Signal wiring must be done manually in the scene or a coordinator script
- (-) Slight overhead from per-frame signal emissions (negligible at game scale)

**Files location:** `scripts/rhythm/` (7 files)

**Assisted by AI:** Yes — Claude Sonnet 4.6

---

### 2026-04-10 — Sistema de Vida y Score Data-Driven + Enemy HP Escénico
**Contexto:** El `Referee` tenía HP/score/combo con valores hardcoded y no estaba
conectado al `Judge`, por lo que ninguna nota afectaba el estado del juego. Además
se necesitaba una barra de vida del enemigo que fuese "dramática": debe vaciarse
exactamente al terminar la canción, para que el criterio real de victoria sea la
supervivencia del jugador.

**Opciones consideradas:**
- Mantener los valores dentro de `Referee` como `@export` planos
- Dividir `Referee` en nodos separados (HealthTracker / ScoreTracker / ComboTracker)
- **Resources (`ScoreRules`, `HealthRules`) asignadas al `Referee`** — elegida

**Decisión tomada:**
- Crear `ScoreRules` y `HealthRules` como `Resource` con `@export` por rating.
- Refactor de `Referee`: data-driven, lee todo desde los dos `Resource`. Arreglado
  bug del combo en "Good" (antes reseteaba a 0).
- Nuevo `EnemyGauge` (Node, SRP) que expone `update_song_progress(progress)` y se
  vacía linealmente con el % de canción reproducido.
- `Battle` alimenta al `EnemyGauge` cada frame y llama `Referee.declare_survival()`
  cuando el chart se agota, disparando `level_ended(true)`.
- `BattleHUD` ahora muestra dos `ProgressBar`s (player / enemy) + `ScoreLabel` +
  `ComboLabel` y se suscribe a las signals del Referee y del EnemyGauge.
- Presets por defecto guardados en `assets/rules/default_score_rules.tres` y
  `assets/rules/default_health_rules.tres`. Cambiar dificultad = swap del `.tres`.

**Consecuencias:**
- (+) Open/Closed: se crean nuevos presets (`.tres`) sin tocar código.
- (+) SRP: reglas = datos, Referee = estado, EnemyGauge = barra escénica, HUD = UI.
- (+) DIP: `Referee` depende de los `Resource` exportados, no de literales.
- (+) Victoria coherente con la historia: "sobrevive a la canción y ganas".
- (-) Requiere abrir `Battle.tscn` para reasignar los `Resource` si se mueven.

**Archivos creados:**
`scripts/rhythm/score_rules.gd`, `scripts/rhythm/health_rules.gd`,
`scripts/rhythm/enemy_gauge.gd`, `assets/rules/default_score_rules.tres`,
`assets/rules/default_health_rules.tres`

**Asistida por IA:** Sí — Claude Opus 4.6

---

### 2026-04-10 — Visual Feedback (Rating Popup, Press Flash, Combo Bounce, Lose Screen)
**Contexto:** El HUD ya mostraba HP/score/combo, pero faltaba feedback inmediato:
no se distinguía visualmente cuándo el jugador presionaba un target, no había
indicación clara del rating de cada nota (Perfect/Good/Miss), el combo no
"vivía" visualmente, y no existía pantalla de derrota.

**Decisión tomada:**
- `NoteTarget` ahora expone `idle/press/hit/miss_color` y `flash_seconds` como
  `@export`, y añade `flash_press()`. Las animaciones usan un token monotónico
  para evitar que un flash más largo apague otro más reciente.
- Nueva clase `RatingFeedback` (Node, SRP) que muestra el rating con texto por
  defecto y soporta texturas opcionales por rating (`perfect_texture`,
  `good_texture`, `miss_texture`) asignables desde el Inspector. Conectada a
  `Judge.note_result` desde el HUD. Animación pop con `Tween`.
- `BattleHUD.on_combo_updated` aplica un mini-pop con `Tween` al `ComboLabel`
  (escala configurable: `combo_pop_scale`, `combo_pop_seconds`).
- `BattleHUD.on_player_pressed` se conecta a `PlayerInput.button_pressed` y
  llama `flash_press()` al target del action correspondiente — el target brilla
  aunque no haya una nota válida.
- Nueva clase `LoseScreen` (CanvasLayer) instanciada dentro de `Battle.tscn`.
  Se invoca desde `Battle._on_level_ended(false)`. Pausa el árbol y ofrece
  Reintentar / Volver al menú. Ruta del menú configurable por `@export`.

**Por qué texto + textura opcional:** todavía no existen sprites para los
ratings, pero el flujo no debe bloquearse esperando arte. Cualquier integrante
puede arrastrar un PNG al slot del Inspector y el popup pasa a usar la imagen
sin tocar código.

**Consecuencias:**
- (+) Toda la sintonía visual (colores, duraciones, escalas, textos) vive en
  `@export` — editable sin tocar código (OCP).
- (+) `RatingFeedback` y `LoseScreen` son nodos independientes; el HUD las
  delega vía signal o método (SRP).
- (+) Coherente con el resto del sistema: signal-driven y data-driven.
- (-) `RatingFeedback` instancia un `Tween` por nota — costo despreciable a
  escala de juego de feria.

**Archivos creados:**
`scripts/rhythm/rating_feedback.gd`, `scripts/rhythm/lose_screen.gd`,
`scenes/rhythm/LoseScreen.tscn`

**Archivos modificados:**
`scripts/rhythm/note_target.gd`, `scripts/rhythm/battle_hud.gd`,
`scripts/rhythm/battle.gd`, `scenes/rhythm/BattleHUD.tscn`,
`scenes/rhythm/Battle.tscn`

**Asistida por IA:** Sí — Claude Opus 4.6

---

### 2026-04-10 — HUD WYSIWYG y LoseScreen como escena independiente
**Contexto:** Dos problemas reportados al editar `Battle.tscn`:
1. El `BattleHUD` no se veía bien en el editor 2D porque el `Control` raíz del
   `CanvasLayer` no tenía tamaño explícito → los hijos no eran "framables".
2. El `LoseScreen` estaba instanciado dentro de `Battle.tscn` como overlay,
   por lo que tampoco era cómodo editarlo en aislado.

**Decisión tomada:**
- `BattleHUD.tscn`:
  - Root `Control` con `custom_minimum_size = (1280, 720)` y anchors Full Rect.
  - Todos los hijos pasan a usar anchor presets (`top_left`, `top_right`,
    `top_center`) en lugar de pixeles flotando en cualquier sitio.
  - Nuevo `@export var design_size: Vector2 = Vector2(1280, 720)` en
    `battle_hud.gd`. En `_ready()` el HUD ajusta el Root al viewport real y se
    suscribe a `viewport.size_changed` para reescalar en runtime.
  - Resultado: al abrir `BattleHUD.tscn` en el editor se ve un rectángulo
    1280x720 con el layout listo para arrastrar. En `Battle.tscn`, el HUD se
    auto-encaja al viewport del juego sin importar dónde esté la `Camera2D`.
- `LoseScreen`:
  - Root pasa de `CanvasLayer` a `Control` (escena raíz independiente con
    full-rect + design size).
  - Se elimina la instancia incrustada en `Battle.tscn`.
  - `Battle._on_level_ended(false)` ahora hace
    `get_tree().change_scene_to_file(lose_scene_path)`.
  - `LoseScreen` expone `battle_scene_path` y `menu_scene_path` con
    `@export_file("*.tscn")` — Reintentar / Volver al menú son configurables
    desde el Inspector sin tocar código.

**Por qué escena aparte:** abrir `LoseScreen.tscn` en el editor lo muestra a
1280x720 como vista única; mucho más cómodo para iterar visualmente que un
overlay encimado en el Battle. Además queda reutilizable por cualquier batalla
futura.

**Archivos modificados:**
`scenes/rhythm/BattleHUD.tscn`, `scenes/rhythm/LoseScreen.tscn`,
`scenes/rhythm/Battle.tscn`, `scripts/rhythm/battle_hud.gd`,
`scripts/rhythm/battle.gd`, `scripts/rhythm/lose_screen.gd`

**Asistida por IA:** Sí — Claude Opus 4.6

---

<!-- Agrega nuevas decisiones aquí -->
