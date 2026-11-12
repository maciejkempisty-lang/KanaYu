extends "res://scripts/editor/path_model.gd"
const Triggers = preload("res://scripts/triggers.gd")
func _init(target: String = "") -> void:
	path = Triggers.default_path() if target.is_empty() else target
	var loaded = Triggers.read_data(path)
	if loaded == null: loaded = Triggers.read_data(path+".bak")
	if loaded == null: loaded = Triggers.read_data(Triggers.DATA_PATH)
	data = loaded
	digest = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	saved = JSON.stringify(data)

func save() -> bool:
	finish_change()
	if not Triggers.save_triggers(data,path,digest): return false
	digest=FileAccess.get_sha256(path); saved=JSON.stringify(data)
	return true

func move_point(position: Vector2) -> void:
	var p := position.clamp(Vector2.ZERO,Vector2(1024,1536)).snapped(Vector2.ONE)
	data.routes[selected_route].points[0]=[p.x,p.y]
