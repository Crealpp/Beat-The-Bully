class_name Quest
extends Resource

## Quest data and state container.
## Uses one enum for both visibility and progress state as requested.

signal quest_updated(quest: Quest)

enum QuestState {
	DESACTIVADA,
	OCULTA,
	VISIBLE,
	ACTIVADA,
	EN_CURSO,
	COMPLETADA,
}

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var requires_ids: Array[String] = []

@export var visibility_state: QuestState = QuestState.OCULTA
@export var progress_state: QuestState = QuestState.DESACTIVADA


func set_visibility_state(new_state: QuestState) -> void:
	if visibility_state == new_state:
		return
	visibility_state = new_state
	quest_updated.emit(self)


func set_progress_state(new_state: QuestState) -> void:
	if progress_state == new_state:
		return
	progress_state = new_state
	quest_updated.emit(self)


func show() -> void:
	set_visibility_state(QuestState.VISIBLE)


func hide() -> void:
	set_visibility_state(QuestState.OCULTA)


func activate() -> void:
	set_progress_state(QuestState.ACTIVADA)


func start() -> void:
	set_progress_state(QuestState.EN_CURSO)


func complete() -> void:
	set_progress_state(QuestState.COMPLETADA)


func reset_states() -> void:
	set_visibility_state(QuestState.OCULTA)
	set_progress_state(QuestState.DESACTIVADA)