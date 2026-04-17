# Pantalla de derrota — escena raíz independiente.
# Se carga vía change_scene_to_file desde Battle al perder. SRP: solo presenta
# y enruta los botones. Las rutas son @export para que cualquier batalla pueda
# decidir adónde volver desde el Inspector.
class_name LoseScreen
extends Control

@export_file("*.tscn") var battle_scene_path: String = "res://scenes/rhythm/Battle.tscn"
@export_file("*.tscn") var menu_scene_path: String = "res://assets/Scenes/main_menu.tscn"
@export var retry_button_path: NodePath = NodePath("Panel/VBox/RetryButton")
@export var menu_button_path: NodePath = NodePath("Panel/VBox/MenuButton")

@onready var _retry_button: Button = get_node_or_null(retry_button_path) as Button
@onready var _menu_button: Button = get_node_or_null(menu_button_path) as Button


func _ready() -> void:
	if _retry_button != null:
		_retry_button.pressed.connect(_on_retry_pressed)
	if _menu_button != null:
		_menu_button.pressed.connect(_on_menu_pressed)


func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file(battle_scene_path)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene_path)
