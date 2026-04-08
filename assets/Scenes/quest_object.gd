extends Node2D

@export_file("*.tscn") var battle_scene_path: String = "res://scenes/rhythm/Battle.tscn"
const INTERACT_ACTION := "Interact"
var player_in_range := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed(INTERACT_ACTION):
		get_tree().change_scene_to_file(battle_scene_path)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
