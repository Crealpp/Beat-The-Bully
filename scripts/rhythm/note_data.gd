# Recurso de datos que representa una nota en el chart del nivel.
class_name NoteData
extends Resource

@export var beat: int = 0
# Valores válidos: "note_left", "note_down", "note_up", "note_right"
@export var action: String = ""
