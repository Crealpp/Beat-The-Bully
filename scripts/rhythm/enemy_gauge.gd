# Barra de vida escénica del enemigo.
# Se vacía linealmente con el progreso de la canción para garantizar que,
# si el jugador sobrevive al chart, el enemigo cae exactamente al final.
# Responsabilidad única (SRP): solo rastrea y emite la vida del enemigo.
class_name EnemyGauge
extends Node

signal enemy_hp_updated(hp: float, max_hp: float)

## HP máximo del enemigo (valor visual; no afecta la condición real de victoria).
@export var max_hp: float = 100.0

var _current_hp: float


func _ready() -> void:
	_current_hp = max_hp
	enemy_hp_updated.emit(_current_hp, max_hp)


## Llamado por Battle con el progreso de la canción normalizado (0.0 – 1.0).
func update_song_progress(progress: float) -> void:
	var clamped: float = clamp(progress, 0.0, 1.0)
	_current_hp = max_hp * (1.0 - clamped)
	enemy_hp_updated.emit(_current_hp, max_hp)


func is_defeated() -> bool:
	return _current_hp <= 0.0
