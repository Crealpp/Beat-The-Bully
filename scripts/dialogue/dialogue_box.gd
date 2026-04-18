# Vista pura de diálogo: muestra una DialogueLine (speaker + text) y emite
# `advance_requested` cuando el jugador pide avanzar (ui_accept).
#
# Responsabilidad única: pintar. No conoce JSON, ni NPCs, ni batallas.
# La sintonía visual es toda editable desde el Inspector.
class_name DialogueBox
extends Control

## Se emite cuando el jugador presiona `ui_accept` mientras la caja está visible.
signal advance_requested

@export var speaker_label_path: NodePath = NodePath("Panel/Margin/VBox/SpeakerLabel")
@export var text_label_path: NodePath = NodePath("Panel/Margin/VBox/TextLabel")
@export var hint_label_path: NodePath = NodePath("Panel/Margin/VBox/HintLabel")

@onready var _speaker_label: Label = get_node_or_null(speaker_label_path) as Label
@onready var _text_label: Label = get_node_or_null(text_label_path) as Label
@onready var _hint_label: Label = get_node_or_null(hint_label_path) as Label


func _ready() -> void:
	hide_box()
	set_process_unhandled_input(true)


func show_line(line: DialogueLoader.DialogueLine) -> void:
	visible = true
	if _speaker_label != null:
		if line.speaker.is_empty():
			_speaker_label.visible = false
			_speaker_label.text = ""
		else:
			_speaker_label.visible = true
			_speaker_label.text = line.speaker
	if _text_label != null:
		_text_label.text = line.text


func hide_box() -> void:
	visible = false


# Solo escuchamos input cuando la caja está visible. Usamos `ui_accept`
# (Space/Enter) para avanzar — la tecla `Interact` (E) queda reservada para
# iniciar la interacción, así un solo frame no abre y avanza a la vez.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		advance_requested.emit()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
