class_name QuestEditor
extends Control

const DEFAULT_SAVE_PATH: String = "res://resources/data/quests.json"

@onready var _quest_list: ItemList = $MarginContainer/HSplitContainer/LeftPanel/QuestList
@onready var _new_button: Button = $MarginContainer/HSplitContainer/LeftPanel/LeftButtons/NewButton
@onready var _delete_button: Button = $MarginContainer/HSplitContainer/LeftPanel/LeftButtons/DeleteButton
@onready var _duplicate_button: Button = $MarginContainer/HSplitContainer/LeftPanel/LeftButtons/DuplicateButton
@onready var _up_button: Button = $MarginContainer/HSplitContainer/LeftPanel/OrderButtons/UpButton
@onready var _down_button: Button = $MarginContainer/HSplitContainer/LeftPanel/OrderButtons/DownButton
@onready var _load_button: Button = $MarginContainer/HSplitContainer/LeftPanel/FileButtons/LoadButton
@onready var _save_button: Button = $MarginContainer/HSplitContainer/LeftPanel/FileButtons/SaveButton

@onready var _id_edit: LineEdit = $MarginContainer/HSplitContainer/RightPanel/FormGrid/IdEdit
@onready var _title_edit: LineEdit = $MarginContainer/HSplitContainer/RightPanel/FormGrid/TitleEdit
@onready var _visibility_option: OptionButton = $MarginContainer/HSplitContainer/RightPanel/FormGrid/VisibilityOption
@onready var _progress_option: OptionButton = $MarginContainer/HSplitContainer/RightPanel/FormGrid/ProgressOption
@onready var _description_edit: TextEdit = $MarginContainer/HSplitContainer/RightPanel/DescriptionEdit
@onready var _prereq_list: ItemList = $MarginContainer/HSplitContainer/RightPanel/PrereqList
@onready var _validate_button: Button = $MarginContainer/HSplitContainer/RightPanel/ValidateRow/ValidateButton
@onready var _error_label: Label = $MarginContainer/HSplitContainer/RightPanel/ValidateRow/ErrorLabel

@onready var _save_dialog: FileDialog = $SaveDialog
@onready var _load_dialog: FileDialog = $LoadDialog
@onready var _confirm_delete_dialog: ConfirmationDialog = $ConfirmDeleteDialog

var _quests: Array[Quest] = []
var _selected_idx: int = -1
var _syncing_ui: bool = false
var _save_path: String = DEFAULT_SAVE_PATH


func _ready() -> void:
	_populate_state_options()
	_connect_ui()
	_new_button.grab_focus()
	_refresh_all()


func _connect_ui() -> void:
	_quest_list.item_selected.connect(_on_quest_selected)
	_quest_list.empty_clicked.connect(_on_quest_list_empty_clicked)

	_new_button.pressed.connect(_on_new_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_duplicate_button.pressed.connect(_on_duplicate_pressed)
	_up_button.pressed.connect(_on_up_pressed)
	_down_button.pressed.connect(_on_down_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_save_button.pressed.connect(_on_save_pressed)

	_id_edit.text_changed.connect(_on_id_changed)
	_title_edit.text_changed.connect(_on_title_changed)
	_visibility_option.item_selected.connect(_on_visibility_selected)
	_progress_option.item_selected.connect(_on_progress_selected)
	_description_edit.text_changed.connect(_on_description_changed)
	_prereq_list.multi_selected.connect(_on_prereq_multi_selected)
	_validate_button.pressed.connect(_on_validate_pressed)

	_save_dialog.file_selected.connect(_on_save_file_selected)
	_load_dialog.file_selected.connect(_on_load_file_selected)
	_confirm_delete_dialog.confirmed.connect(_confirm_delete_selected)


func _populate_state_options() -> void:
	_visibility_option.clear()
	_progress_option.clear()
	for i in range(Quest.QuestVisibility.size()):
		var label: String = str(Quest.QuestVisibility.keys()[i]).capitalize()
		_visibility_option.add_item(label, i)
	for i in range(Quest.QuestState.size()):
		var label: String = str(Quest.QuestState.keys()[i]).capitalize()
		_progress_option.add_item(label, i)


func _refresh_all() -> void:
	_refresh_quest_list()
	_refresh_form()
	_refresh_buttons_state()
	_error_label.text = ""


func _refresh_quest_list() -> void:
	_quest_list.clear()
	for i in range(_quests.size()):
		var q: Quest = _quests[i]
		var id_text: String = q.id if not q.id.is_empty() else "(sin_id_%d)" % i
		var title_text: String = q.title if not q.title.is_empty() else "Sin titulo"
		_quest_list.add_item("%d. %s - %s" % [i + 1, id_text, title_text])

	if _selected_idx >= 0 and _selected_idx < _quests.size():
		_quest_list.select(_selected_idx)
	else:
		_selected_idx = -1


func _refresh_form() -> void:
	_syncing_ui = true
	var has_selection: bool = _selected_idx >= 0 and _selected_idx < _quests.size()

	_id_edit.editable = has_selection
	_title_edit.editable = has_selection
	_visibility_option.disabled = not has_selection
	_progress_option.disabled = not has_selection
	_description_edit.editable = has_selection
	_prereq_list.mouse_filter = Control.MOUSE_FILTER_STOP if has_selection else Control.MOUSE_FILTER_IGNORE
	_prereq_list.focus_mode = Control.FOCUS_ALL if has_selection else Control.FOCUS_NONE

	if not has_selection:
		_id_edit.text = ""
		_title_edit.text = ""
		_description_edit.text = ""
		_visibility_option.select(Quest.QuestVisibility.OCULTA)
		_progress_option.select(Quest.QuestState.ACTIVADA)
		_prereq_list.clear()
		_prereq_list.deselect_all()
		_syncing_ui = false
		return

	var q: Quest = _quests[_selected_idx]
	_id_edit.text = q.id
	_title_edit.text = q.title
	_description_edit.text = q.description
	_visibility_option.select(q.visibility_state)
	_progress_option.select(q.progress_state)
	_refresh_prereq_list()
	_syncing_ui = false


func _refresh_prereq_list() -> void:
	_prereq_list.clear()
	if _selected_idx < 0 or _selected_idx >= _quests.size():
		return

	var selected_quest: Quest = _quests[_selected_idx]
	for i in range(_quests.size()):
		if i == _selected_idx:
			continue
		var q: Quest = _quests[i]
		var id_text: String = q.id if not q.id.is_empty() else "(sin id)"
		var title_text: String = q.title if not q.title.is_empty() else "Sin titulo"
		_prereq_list.add_item("%s - %s" % [id_text, title_text])
		var item_index: int = _prereq_list.item_count - 1
		_prereq_list.set_item_metadata(item_index, q.id)
		if selected_quest.requires_ids.has(q.id):
			_prereq_list.select(item_index, false)


func _refresh_buttons_state() -> void:
	var has_selection: bool = _selected_idx >= 0 and _selected_idx < _quests.size()
	_delete_button.disabled = not has_selection
	_duplicate_button.disabled = not has_selection
	_up_button.disabled = not has_selection or _selected_idx <= 0
	_down_button.disabled = not has_selection or _selected_idx >= _quests.size() - 1


func _on_quest_selected(index: int) -> void:
	_selected_idx = index
	_refresh_form()
	_refresh_buttons_state()


func _on_quest_list_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
	_selected_idx = -1
	_refresh_form()
	_refresh_buttons_state()


func _on_new_pressed() -> void:
	var q := Quest.new()
	q.id = _build_default_id()
	q.title = "Nueva mision"
	q.visibility_state = Quest.QuestVisibility.OCULTA
	q.progress_state = Quest.QuestState.ACTIVADA
	_quests.append(q)
	_selected_idx = _quests.size() - 1
	_refresh_all()


func _on_delete_pressed() -> void:
	if _selected_idx < 0 or _selected_idx >= _quests.size():
		return
	_confirm_delete_dialog.popup_centered()


func _confirm_delete_selected() -> void:
	if _selected_idx < 0 or _selected_idx >= _quests.size():
		return
	var removed: Quest = _quests[_selected_idx]
	_quests.remove_at(_selected_idx)
	for q in _quests:
		q.requires_ids.erase(removed.id)
	_selected_idx = mini(_selected_idx, _quests.size() - 1)
	_refresh_all()


func _on_duplicate_pressed() -> void:
	if _selected_idx < 0 or _selected_idx >= _quests.size():
		return
	var src: Quest = _quests[_selected_idx]
	var copy := Quest.new()
	copy.id = _build_default_id(src.id + "_copy")
	copy.title = src.title
	copy.description = src.description
	copy.visibility_state = src.visibility_state
	copy.progress_state = src.progress_state
	copy.requires_ids = src.requires_ids.duplicate()
	_quests.insert(_selected_idx + 1, copy)
	_selected_idx += 1
	_refresh_all()


func _on_up_pressed() -> void:
	if _selected_idx <= 0:
		return
	var tmp: Quest = _quests[_selected_idx - 1]
	_quests[_selected_idx - 1] = _quests[_selected_idx]
	_quests[_selected_idx] = tmp
	_selected_idx -= 1
	_refresh_all()


func _on_down_pressed() -> void:
	if _selected_idx < 0 or _selected_idx >= _quests.size() - 1:
		return
	var tmp: Quest = _quests[_selected_idx + 1]
	_quests[_selected_idx + 1] = _quests[_selected_idx]
	_quests[_selected_idx] = tmp
	_selected_idx += 1
	_refresh_all()


func _on_load_pressed() -> void:
	_load_dialog.popup_centered_ratio(0.7)


func _on_save_pressed() -> void:
	_save_dialog.current_file = _save_path.get_file()
	_save_dialog.current_path = _save_path
	_save_dialog.popup_centered_ratio(0.7)


func _on_save_file_selected(path: String) -> void:
	_save_to_json(path)


func _on_load_file_selected(path: String) -> void:
	_load_from_json(path)


func _on_id_changed(new_text: String) -> void:
	if _syncing_ui or _selected_idx < 0:
		return
	_quests[_selected_idx].id = new_text.strip_edges()
	_refresh_quest_list()


func _on_title_changed(new_text: String) -> void:
	if _syncing_ui or _selected_idx < 0:
		return
	_quests[_selected_idx].title = new_text
	_refresh_quest_list()


func _on_visibility_selected(index: int) -> void:
	if _syncing_ui or _selected_idx < 0:
		return
	_quests[_selected_idx].visibility_state = index


func _on_progress_selected(index: int) -> void:
	if _syncing_ui or _selected_idx < 0:
		return
	_quests[_selected_idx].progress_state = index


func _on_description_changed() -> void:
	if _syncing_ui or _selected_idx < 0:
		return
	_quests[_selected_idx].description = _description_edit.text


func _on_prereq_multi_selected(_index: int, _selected: bool) -> void:
	if _syncing_ui or _selected_idx < 0:
		return
	_sync_prereqs_from_list()


func _sync_prereqs_from_list() -> void:
	var q: Quest = _quests[_selected_idx]
	q.requires_ids.clear()
	for i in range(_prereq_list.item_count):
		if not _prereq_list.is_selected(i):
			continue
		var req_id: String = str(_prereq_list.get_item_metadata(i)).strip_edges()
		if req_id.is_empty() or req_id == q.id:
			continue
		if not q.requires_ids.has(req_id):
			q.requires_ids.append(req_id)


func _on_validate_pressed() -> void:
	var issues: Array[String] = _validate_quests()
	if issues.is_empty():
		_error_label.text = "OK: sin errores"
	else:
		_error_label.text = " | ".join(issues)


func _save_to_json(path: String) -> void:
	var issues: Array[String] = _validate_quests()
	if not issues.is_empty():
		_error_label.text = "No se guardo: " + " | ".join(issues)
		return

	var data: Dictionary = {"quests": []}
	var out: Array = []
	for q in _quests:
		out.append({
			"id": q.id,
			"title": q.title,
			"description": q.description,
			"visibility_state": q.visibility_state,
			"progress_state": q.progress_state,
			"requires_ids": q.requires_ids,
		})
	data["quests"] = out

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_error_label.text = "No se pudo guardar en %s" % path
		return
	file.store_string(JSON.stringify(data, "\t"))
	_save_path = path
	_error_label.text = "Guardado en %s" % path


func _load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		_error_label.text = "No existe %s" % path
		return
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		_error_label.text = "Archivo vacio"
		return

	var json := JSON.new()
	if json.parse(text) != OK:
		_error_label.text = "JSON invalido"
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		_error_label.text = "Formato invalido"
		return

	var root: Dictionary = json.data
	var quests_raw: Variant = root.get("quests", [])
	if typeof(quests_raw) != TYPE_ARRAY:
		_error_label.text = "El campo quests debe ser array"
		return

	_quests.clear()
	for item in quests_raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var raw: Dictionary = item
		var q := Quest.new()
		q.id = str(raw.get("id", "")).strip_edges()
		q.title = str(raw.get("title", ""))
		q.description = str(raw.get("description", ""))
		q.visibility_state = int(raw.get("visibility_state", Quest.QuestVisibility.OCULTA))
		q.progress_state = int(raw.get("progress_state", Quest.QuestState.ACTIVADA))

		q.requires_ids.clear()
		var reqs_variant: Variant = raw.get("requires_ids", [])
		if typeof(reqs_variant) == TYPE_ARRAY:
			for req in reqs_variant:
				q.requires_ids.append(str(req).strip_edges())

		_quests.append(q)

	_selected_idx = -1
	_save_path = path
	_refresh_all()
	_error_label.text = "Cargado %d quests" % _quests.size()


func _validate_quests() -> Array[String]:
	var issues: Array[String] = []
	var id_to_index: Dictionary = {}

	for i in range(_quests.size()):
		var id: String = _quests[i].id.strip_edges()
		if id.is_empty():
			issues.append("Quest %d sin ID" % (i + 1))
			continue
		if id_to_index.has(id):
			issues.append("ID duplicado: %s" % id)
		else:
			id_to_index[id] = i

	for q in _quests:
		for req_id in q.requires_ids:
			if req_id == q.id:
				issues.append("%s no puede requerirse a si misma" % q.id)
			elif not id_to_index.has(req_id):
				issues.append("%s requiere ID inexistente: %s" % [q.id, req_id])

	if issues.is_empty() and _has_cycle(id_to_index):
		issues.append("Hay un ciclo en dependencias")

	return issues


func _has_cycle(id_to_index: Dictionary) -> bool:
	var color: Dictionary = {}
	for q in _quests:
		color[q.id] = 0

	for q in _quests:
		if _dfs_cycle(q.id, color, id_to_index):
			return true
	return false


func _dfs_cycle(node_id: String, color: Dictionary, id_to_index: Dictionary) -> bool:
	if not color.has(node_id):
		return false
	if color[node_id] == 1:
		return true
	if color[node_id] == 2:
		return false

	color[node_id] = 1
	var idx: int = id_to_index[node_id]
	for req_id in _quests[idx].requires_ids:
		if _dfs_cycle(req_id, color, id_to_index):
			return true
	color[node_id] = 2
	return false


func _build_default_id(base: String = "quest") -> String:
	var candidate: String = base
	var i: int = 1
	while _id_exists(candidate):
		candidate = "%s_%d" % [base, i]
		i += 1
	return candidate


func _id_exists(id: String) -> bool:
	for q in _quests:
		if q.id == id:
			return true
	return false
