extends Control

const Village = preload("res://scenes/village.tscn")
const PathEditor = preload("res://scripts/editor/path_editor.gd")
const PROFILES := [Vector2i(390, 844), Vector2i(768, 1024)]

var village
var editor
var provider: Node
var editor_context := {}
var game_view: SubViewport
var editor_view: SubViewport
var game_container: SubViewportContainer
var game_area: Control
var heading: Label
var editor_closed_by_user := false
var dock_active := false

func _ready() -> void:
	village = Village.instantiate()
	if not OS.is_debug_build() or OS.has_feature("mobile") or DisplayServer.get_name() == "headless":
		add_child(village)
		return

	dock_active = true
	WorldEditor.dock_active = true
	get_window().mode = Window.MODE_FULLSCREEN

	var split := HSplitContainer.new()
	add_child(split)
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(left)
	var editor_bar := HBoxContainer.new()
	left.add_child(editor_bar)
	heading = Label.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.clip_text = true
	editor_bar.add_child(heading)
	var reopen := Button.new()
	reopen.text = "Otwórz edytor"
	reopen.pressed.connect(func(): editor_closed_by_user = false)
	editor_bar.add_child(reopen)

	var dock := SubViewportContainer.new()
	dock.stretch = true
	dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(dock)
	editor_view = SubViewport.new()
	editor_view.world_2d = World2D.new()
	dock.add_child(editor_view)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var game_bar := HBoxContainer.new()
	right.add_child(game_bar)
	var label := Label.new()
	label.text = "Podgląd gry"
	game_bar.add_child(label)
	var formats := OptionButton.new()
	formats.add_item("Telefon · 390 × 844")
	formats.add_item("Tablet · 768 × 1024")
	formats.item_selected.connect(set_profile)
	game_bar.add_child(formats)

	game_area = Control.new()
	game_area.clip_contents = true
	game_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(game_area)
	game_container = SubViewportContainer.new()
	game_area.add_child(game_container)
	game_view = SubViewport.new()
	game_view.world_2d = World2D.new()
	game_container.add_child(game_view)
	game_area.resized.connect(fit_game)
	set_profile(0)
	game_view.add_child(village)

func set_profile(index: int) -> void:
	game_view.size = PROFILES[index]
	fit_game()

func fit_game() -> void:
	var logical_size := Vector2(game_view.size)
	var fit := minf(game_area.size.x / logical_size.x, game_area.size.y / logical_size.y)
	var factor := clampf(fit, 0.01, 1.0)
	game_container.size = logical_size
	game_container.scale = Vector2.ONE * factor
	game_container.position = (game_area.size - logical_size * factor) / 2.0

func _process(_delta: float) -> void:
	if not dock_active:
		return
	var active := WorldEditor.active_provider(game_view)
	if active == null:
		return
	if active == provider and is_instance_valid(editor):
		heading.text = "Edytor · " + str(editor_context.get("title", "Mapa"))
		return
	if has_pending_editor():
		heading.text = "Edytor · " + str(editor_context.get("title", "Mapa")) + " · zakończ edycję, aby przełączyć scenę"
		return
	if editor_closed_by_user:
		heading.text = "Edytor zamknięty"
		return
	if is_instance_valid(editor):
		editor_view.remove_child(editor)
		editor.queue_free()
	provider = active
	editor_context = active.editor_context()
	editor = WorldEditor.create_editor(editor_context)
	editor.saved.connect(apply_editor_save)
	editor.closed.connect(func():
		editor = null
		editor_closed_by_user = true)
	editor_view.add_child(editor)

func has_pending_editor() -> bool:
	if not is_instance_valid(editor):
		return false
	if editor is PathEditor and is_instance_valid(editor.gallery):
		return true
	return editor.model != null and editor.model.dirty()

func apply_editor_save() -> void:
	if editor_context.get("kind") == "village":
		village.editor_closed()
		return
	var active := WorldEditor.active_provider(game_view)
	if active != null and active.editor_context().get("layout_path") == editor_context.get("layout_path"):
		active.editor_closed()

func _input(event: InputEvent) -> void:
	if not dock_active or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F11:
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST or not dock_active:
		return
	if has_pending_editor():
		editor.request_close()
	else:
		village.request_game_quit()

func _exit_tree() -> void:
	if dock_active:
		WorldEditor.dock_active = false
