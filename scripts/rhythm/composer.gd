# Gestiona el chart del nivel y emite cada nota cuando llega su beat.
class_name Composer
extends Node

signal note_expected(note: NoteData)

@export var chart: Array[NoteData] = []

var _next_index: int = 0


func load_chart(data: Array[NoteData]) -> void:
	chart = data
	_next_index = 0


# Retorna y emite la próxima nota si su beat ya llegó; null si no hay ninguna pendiente.
func get_next_note(current_beat: int) -> NoteData:
	if _next_index >= chart.size():
		return null
	var note: NoteData = chart[_next_index]
	if note.beat > current_beat:
		return null
	_next_index += 1
	note_expected.emit(note)
	return note
