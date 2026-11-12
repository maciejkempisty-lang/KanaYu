extends Node
## Add this child to a new world scene; use the shared layout schema.
@export_file("*.json") var layout_path := ""
@export var scene_title := "Mapa"
func _ready() -> void: add_to_group("editable_scene")
func editor_target() -> Node: return get_parent()
func editor_context() -> Dictionary:
	return {} if layout_path.is_empty() or get_parent().get("transition_locked")==true else {"kind":"layout","layout_path":layout_path,"title":scene_title}
func editor_opened(_editor) -> void:
	if get_parent().has_method("reset_editor_input"): get_parent().reset_editor_input()
func editor_closed() -> void:
	if get_parent().has_method("reload_scene_layout"): get_parent().reload_scene_layout()
