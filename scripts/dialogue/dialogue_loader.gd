# Lee un archivo JSON con líneas de diálogo y lo convierte en una DialogueData.
#
# Formato esperado del JSON:
# {
#   "version": 1,
#   "dialogues": {
#     "intro": {
#       "lines": [
#         { "speaker": "Matón", "text": "¿Crees que puedes ganarme?" },
#         { "speaker": "Matón", "text": "¡Prepárate!" }
#       ]
#     },
#     "cartel": {
#       "lines": [ { "text": "Feria Gamer 2026" } ]
#     }
#   }
# }
#
# - `speaker` es opcional. Si falta, la DialogueBox oculta la etiqueta de nombre
#   (caso "objeto interactuable" sin emisor humano).
# - Cada clave de `dialogues` es un `dialogue_id` que el Interactable pide por
#   nombre al DialogueRunner.
#
# Uso:
#   var data := DialogueLoader.load_json("res://assets/dialogues/bully_01.json")
#   _runner.play(data, "intro")
class_name DialogueLoader
extends RefCounted


## Línea individual de diálogo — puro dato.
class DialogueLine:
	var speaker: String = ""
	var text: String = ""


## Resultado de parsear un JSON de diálogo. Contiene múltiples diálogos
## identificados por id (`intro`, `victory`, `defeat`, ...).
class DialogueData:
	var version: int = 1
	## Dictionary[String, Array[DialogueLine]] — clave: dialogue_id.
	var dialogues: Dictionary = {}

	## Devuelve la lista de líneas para un id, o `[]` si no existe.
	func get_lines(dialogue_id: String) -> Array[DialogueLine]:
		if not dialogues.has(dialogue_id):
			return []
		return dialogues[dialogue_id]

	func has_dialogue(dialogue_id: String) -> bool:
		return dialogues.has(dialogue_id)


## Carga y parsea un archivo JSON de diálogos.
## Devuelve DialogueData vacío si ocurre algún error (nunca null) para que el
## caller pueda seguir operando sin crashear.
static func load_json(path: String) -> DialogueData:
	var result := DialogueData.new()

	if not FileAccess.file_exists(path):
		push_error("DialogueLoader: archivo no encontrado: %s" % path)
		return result

	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DialogueLoader: archivo vacío: %s" % path)
		return result

	var json := JSON.new()
	var parse_error: int = json.parse(text)
	if parse_error != OK:
		push_error("DialogueLoader: error al parsear %s (línea %d): %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		return result

	var data: Dictionary = json.data
	result.version = int(data.get("version", 1))

	var raw_dialogues: Dictionary = data.get("dialogues", {})
	for dialogue_id in raw_dialogues.keys():
		var raw_entry: Dictionary = raw_dialogues[dialogue_id]
		var raw_lines: Array = raw_entry.get("lines", [])
		var parsed: Array[DialogueLine] = []
		for raw in raw_lines:
			var line := DialogueLine.new()
			line.speaker = str(raw.get("speaker", ""))
			line.text = str(raw.get("text", ""))
			parsed.append(line)
		result.dialogues[str(dialogue_id)] = parsed

	return result
