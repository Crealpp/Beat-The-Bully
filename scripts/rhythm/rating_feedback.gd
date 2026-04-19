class_name RatingFeedback
extends Node

@export_group("Texturas")
@export var perfect_texture: Texture2D
@export var good_texture: Texture2D
@export var miss_texture: Texture2D

@export_group("Animación")
@export var display_seconds: float = 0.55
@export var pop_scale: float = 1.25
@export var base_scale: float = 2.5

@export_group("Nodo UI")
@export var texture_rect_path: NodePath

var _texture_rect: TextureRect
var _hide_token: int = 0


func _ready() -> void:
	_texture_rect = get_node(texture_rect_path) as TextureRect
	_texture_rect.visible = false


	_texture_rect.scale = Vector2(base_scale, base_scale)
	_texture_rect.pivot_offset = _texture_rect.size / 2.0


# Conectado a Judge.note_result
func on_note_result(_player_action: String, _expected_action: String, timing: String, success: bool) -> void:
	var rating: String = timing if success else "Miss"
	_show_rating(rating)


func _show_rating(rating: String) -> void:
	# Guard: el HUD podría recibir un `note_result` tardío (auto-miss) justo
	# cuando la escena está cambiando a Lose/Win. En ese caso el nodo ya no
	# está en el árbol y `get_tree()` / `create_tween()` fallan.
	if not is_inside_tree() or _texture_rect == null:
		return

	var tex: Texture2D

	match rating:
		"Perfect":
			tex = perfect_texture
		"Good":
			tex = good_texture
		_:
			tex = miss_texture

	if tex == null:
		return

	_texture_rect.texture = tex
	_texture_rect.visible = true


	_texture_rect.scale = Vector2(base_scale, base_scale)


	var tween: Tween = create_tween()
	_texture_rect.scale = Vector2(base_scale * pop_scale, base_scale * pop_scale)
	tween.tween_property(_texture_rect, "scale", Vector2(base_scale, base_scale), 0.18)

	_hide_token += 1
	var token: int = _hide_token

	await get_tree().create_timer(display_seconds).timeout

	# Tras el await la escena pudo haber cambiado.
	if not is_inside_tree() or _texture_rect == null:
		return
	if token == _hide_token:
		_texture_rect.visible = false
