extends Node
## Global entry point; scene providers supply their own data, never village defaults.
var dock_active := false
var editor = null
var window: Window
var target: Node
var previous_mode: int
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
func _input(event: InputEvent) -> void:
	if dock_active: return
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode!=KEY_BACKSLASH: return
	if is_instance_valid(editor):
		editor.request_close(); get_viewport().set_input_as_handled(); return
	var provider := active_provider()
	if provider != null:
		open_for(provider)
		get_viewport().set_input_as_handled()

func active_provider(viewport: Viewport = null) -> Node:
	var providers := get_tree().get_nodes_in_group("editable_scene")
	providers.reverse()
	for provider in providers:
		if viewport != null and provider.get_viewport() != viewport: continue
		var scene: Node=provider.editor_target() if provider.has_method("editor_target") else provider
		if scene is CanvasItem and not scene.is_visible_in_tree(): continue
		if provider.has_method("editor_context") and not provider.editor_context().is_empty():
			return provider
	return null

func create_editor(context: Dictionary) -> CanvasLayer:
	if context.get("kind") == "village":
		return preload("res://scripts/editor/path_editor.gd").new()
	var scene_editor = preload("res://scripts/editor/scene_editor.gd").new()
	scene_editor.layout_path = context.layout_path
	scene_editor.scene_title = context.get("title", "Scena")
	return scene_editor

func open_for(provider: Node) -> void:
	if dock_active: return
	if is_instance_valid(editor):
		if is_instance_valid(window): window.grab_focus()
		return
	var context: Dictionary=provider.editor_context()
	if context.is_empty(): return
	target=provider.editor_target() if provider.has_method("editor_target") else provider
	editor = create_editor(context)
	previous_mode=target.process_mode
	target.process_mode=Node.PROCESS_MODE_DISABLED
	if target.has_method("editor_opened"): target.editor_opened(editor)
	editor.closed.connect(func(): finish(provider))
	if not OS.has_feature("mobile"):
		window=Window.new(); window.hide(); window.force_native=true
		window.title="Kigi · Edytor · "+str(context.get("title",target.name))
		window.size=Vector2i(1200,900); window.min_size=Vector2i(800,600)
		window.close_requested.connect(func():
			if is_instance_valid(editor): editor.request_close())
		add_child(window); window.add_child(editor); window.popup_centered()
	else: add_child(editor)
func finish(provider: Node) -> void:
	if is_instance_valid(window): window.hide(); window.queue_free()
	window=null; editor=null
	if is_instance_valid(target): target.process_mode=previous_mode
	if is_instance_valid(provider) and provider.has_method("editor_closed"): provider.editor_closed()
	target=null
