# Pantalla de derrota — escena raíz independiente.
# Se carga vía change_scene_to_file desde Battle al perder. SRP: solo presenta
# y enruta los botones. Las rutas son @export para que cualquier batalla pueda
# decidir adónde volver desde el Inspector.
#
# Tres caminos:
#  - Reintentar    → recarga la batalla. No limpia el pending del Gamemanager
#                    (al ganar/perder de nuevo, se vuelve a setear).
#  - Volver al mapa → usa `Gamemanager.return_scene_path` (seteado por el
#                    Interactable antes de lanzar la batalla). Preserva
#                    `pending_dialogue_result = "lose"` para que el Map
#                    reanude el diálogo de derrota del NPC.
#  - Menú          → limpia pending y vuelve al main menu.
class_name LoseScreen
extends Control

@export_file("*.tscn") var battle_scene_path: String = "res://scenes/rhythm/Battle.tscn"
@export_file("*.tscn") var menu_scene_path: String = "res://scenes/menu/main_menu.tscn"
@export_file("*.tscn") var fallback_map_scene_path: String = "res://scenes/map/Map.tscn"
@export var retry_button_path: NodePath = NodePath("Panel/VBox/RetryButton")
@export var map_button_path: NodePath = NodePath("Panel/VBox/MapButton")
@export var menu_button_path: NodePath = NodePath("Panel/VBox/MenuButton")

@onready var _retry_button: Button = get_node_or_null(retry_button_path) as Button
@onready var _map_button: Button = get_node_or_null(map_button_path) as Button
@onready var _menu_button: Button = get_node_or_null(menu_button_path) as Button


func _ready() -> void:
	if _retry_button != null:
		_retry_button.pressed.connect(_on_retry_pressed)
	if _map_button != null:
		_map_button.pressed.connect(_on_map_pressed)
	if _menu_button != null:
		_menu_button.pressed.connect(_on_menu_pressed)


func _on_retry_pressed() -> void:
	# Al reintentar no tiene sentido reanudar un diálogo de derrota viejo.
	Gamemanager.pending_dialogue_result = ""
	get_tree().change_scene_to_file(battle_scene_path)


func _on_map_pressed() -> void:
	var target := Gamemanager.return_scene_path
	if target.is_empty():
		target = fallback_map_scene_path
	get_tree().change_scene_to_file(target)


func _on_menu_pressed() -> void:
	Gamemanager.clear_pending_dialogue()
	get_tree().change_scene_to_file(menu_scene_path)
