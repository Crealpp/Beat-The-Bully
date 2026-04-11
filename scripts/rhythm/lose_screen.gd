# Overlay mostrado cuando el jugador pierde una batalla.
# SRP: solo presenta la pantalla y enruta los botones; no conoce el estado de juego.
class_name LoseScreen
extends CanvasLayer

@export var menu_scene_path: String = "res://assets/Scenes/main_menu.tscn"
@export var retry_button_path: NodePath = NodePath("Root/Panel/VBox/RetryButton")
@export var menu_button_path: NodePath = NodePath("Root/Panel/VBox/MenuButton")

@onready var _retry_button: Button = get_node_or_null(retry_button_path) as Button
@onready var _menu_button: Button = get_node_or_null(menu_button_path) as Button


func _ready() -> void:
	visible = false
	if _retry_button != null:
		_retry_button.pressed.connect(_on_retry_pressed)
	if _menu_button != null:
		_menu_button.pressed.connect(_on_menu_pressed)


func show_screen() -> void:
	visible = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
