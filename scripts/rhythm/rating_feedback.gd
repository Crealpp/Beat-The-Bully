# Popup visual de la calificación de una nota (Perfect / Good / Miss).
# Funciona en modo texto por defecto y soporta texturas opcionales por rating
# que pueden asignarse desde el Inspector. Sigue SRP: solo se encarga de mostrar
# la calificación, no toca puntaje ni vida.
class_name RatingFeedback
extends Node

@export_group("Textos por rating")
@export var perfect_text: String = "PERFECT"
@export var good_text: String = "GOOD"
@export var miss_text: String = "MISS"

@export_group("Colores por rating")
@export var perfect_color: Color = Color(1, 0.95, 0.2)
@export var good_color: Color = Color(0.4, 1, 0.4)
@export var miss_color: Color = Color(1, 0.3, 0.3)

@export_group("Texturas opcionales")
@export var perfect_texture: Texture2D
@export var good_texture: Texture2D
@export var miss_texture: Texture2D

@export_group("Animación")
@export var display_seconds: float = 0.55
@export var pop_scale: float = 1.4

@export_group("Nodos UI")
@export var label_path: NodePath
@export var texture_rect_path: NodePath

var _label: Label
var _texture_rect: TextureRect
var _root: CanvasItem
var _hide_token: int = 0


func _ready() -> void:
	_label = get_node_or_null(label_path) as Label
	_texture_rect = get_node_or_null(texture_rect_path) as TextureRect
	if _label != null:
		_label.visible = false
		_label.pivot_offset = _label.size / 2.0
	if _texture_rect != null:
		_texture_rect.visible = false
		_texture_rect.pivot_offset = _texture_rect.size / 2.0


# Conectado a Judge.note_result.
func on_note_result(_player_action: String, _expected_action: String, timing: String, success: bool) -> void:
	var rating: String = timing if success else "Miss"
	_show_rating(rating)


func _show_rating(rating: String) -> void:
	var color: Color
	var text: String
	var tex: Texture2D
	match rating:
		"Perfect":
			color = perfect_color
			text = perfect_text
			tex = perfect_texture
		"Good":
			color = good_color
			text = good_text
			tex = good_texture
		_:
			color = miss_color
			text = miss_text
			tex = miss_texture

	if tex != null and _texture_rect != null:
		_texture_rect.texture = tex
		_texture_rect.modulate = color
		_root = _texture_rect
		if _label != null:
			_label.visible = false
	elif _label != null:
		_label.text = text
		_label.modulate = color
		_root = _label
		if _texture_rect != null:
			_texture_rect.visible = false
	else:
		return

	_root.visible = true
	_root.pivot_offset = (_root as Control).size / 2.0
	_root.scale = Vector2(pop_scale, pop_scale)
	var tween: Tween = create_tween()
	tween.tween_property(_root, "scale", Vector2.ONE, 0.18)

	_hide_token += 1
	var token: int = _hide_token
	await get_tree().create_timer(display_seconds).timeout
	if token == _hide_token and _root != null:
		_root.visible = false
