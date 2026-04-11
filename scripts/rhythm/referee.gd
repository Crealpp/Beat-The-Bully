# Mantiene el estado de la partida (HP, score, combo) y detecta fin de nivel.
# Data-driven: toda la sintonía se hace mediante los Resources ScoreRules y HealthRules
# asignados desde el Inspector, siguiendo OCP y DIP.
class_name Referee
extends Node

signal score_updated(score: int)
signal player_hp_updated(hp: int, max_hp: int)
signal combo_updated(combo: int, max_combo: int)
# true = jugador sobrevivió, false = jugador cayó
signal level_ended(player_won: bool)

@export var score_rules: ScoreRules
@export var health_rules: HealthRules

var _player_hp: int = 0
var _score: int = 0
var _combo: int = 0
var _max_combo: int = 0
var _level_over: bool = false


func _ready() -> void:
	if health_rules == null:
		push_error("Referee: falta asignar 'health_rules' (HealthRules) en el Inspector.")
		return
	if score_rules == null:
		push_error("Referee: falta asignar 'score_rules' (ScoreRules) en el Inspector.")
		return
	_player_hp = health_rules.max_player_hp
	_emit_all()


# Callback conectado a Judge.note_result.
func on_note_result(_player_action: String, _expected_action: String, timing: String, success: bool) -> void:
	if _level_over:
		return
	if success and timing == "Perfect":
		_apply_hit(score_rules.perfect_points, health_rules.perfect_heal)
	elif success and timing == "Good":
		_apply_hit(score_rules.good_points, health_rules.good_heal)
	else:
		_apply_miss()
	_emit_all()
	_check_defeat()


# Lo llama Battle cuando la canción termina y el jugador sigue vivo.
func declare_survival() -> void:
	if _level_over:
		return
	_level_over = true
	level_ended.emit(true)


# ── Métodos privados ───────────────────────────────────────

func _apply_hit(base_points: int, heal: int) -> void:
	_combo += 1
	if _combo > _max_combo:
		_max_combo = _combo
	var gained: int = base_points + _combo * score_rules.combo_bonus_per_hit
	_score = max(_score + gained, score_rules.min_score)
	if heal > 0:
		_player_hp = min(_player_hp + heal, health_rules.max_player_hp)


func _apply_miss() -> void:
	_combo = 0
	_score = max(_score + score_rules.miss_points, score_rules.min_score)
	_player_hp = max(_player_hp - health_rules.miss_damage, 0)


func _emit_all() -> void:
	score_updated.emit(_score)
	player_hp_updated.emit(_player_hp, health_rules.max_player_hp)
	combo_updated.emit(_combo, _max_combo)


func _check_defeat() -> void:
	if _player_hp <= 0 and not _level_over:
		_level_over = true
		level_ended.emit(false)
