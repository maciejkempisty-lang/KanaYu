extends "res://scripts/editor/path_model.gd"
const Masks = preload("res://scripts/masks.gd")
var editing_region := false
func _init(target: String = "") -> void:
	path = Masks.default_path() if target.is_empty() else target
	var loaded = Masks.read_data(path)
	if loaded == null: loaded = Masks.read_data(path+".bak")
	if loaded == null: loaded = Masks.read_data(Masks.DATA_PATH)
	data = loaded
	digest = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	saved = JSON.stringify(data)
	normalize_selection()
func edit_points(route: int) -> Array:
	if route<0 or route>=data.routes.size(): return []
	return data.routes[route].region if editing_region else data.routes[route].points
func move_point(position: Vector2) -> void:
	if selected_point<0: return
	var p := position.clamp(Vector2.ZERO,Vector2(1024,1536)).snapped(Vector2.ONE)
	edit_points(selected_route)[selected_point]=[p.x,p.y]
func insert_point(route: int, segment: int, position: Vector2) -> void:
	begin_change()
	selected_route=route; selected_point=segment+1
	var p := position.clamp(Vector2.ZERO,Vector2(1024,1536))
	edit_points(route).insert(selected_point,[p.x,p.y])
	finish_change()
func delete_point() -> void:
	if selected_point<0 or edit_points(selected_route).size()<=3: return
	begin_change(); edit_points(selected_route).remove_at(selected_point)
	selected_point=-1; finish_change()
func save() -> bool:
	finish_change()
	if not Masks.save_masks(data,path,digest): return false
	digest=FileAccess.get_sha256(path); saved=JSON.stringify(data)
	return true

func add_mask(position: Vector2) -> void:
	if data.routes.size()>=100: return
	begin_change()
	var center := position.clamp(Vector2(50,50),Vector2(974,1456)).snapped(Vector2.ONE)
	var names := []
	for mask in data.routes: names.append(mask.name)
	var number := 1
	while "Maska %d" % number in names: number+=1
	data.routes.append({"name":"Maska %d" % number,
		"points":[[center.x-40,center.y-40],[center.x+40,center.y-40],[center.x+40,center.y+40],[center.x-40,center.y+40]],
		"region":[[center.x-50,center.y],[center.x+50,center.y],[center.x+50,center.y+80],[center.x-50,center.y+80]]})
	selected_route=data.routes.size()-1; selected_point=-1
	finish_change()

func delete_mask() -> void:
	if selected_route<0 or data.routes.is_empty(): return
	begin_change(); data.routes.remove_at(selected_route); finish_change()
	normalize_selection()

func normalize_selection() -> void:
	selected_route=clampi(selected_route,0,data.routes.size()-1) if not data.routes.is_empty() else -1
	selected_point=-1

func undo() -> void:
	super.undo(); normalize_selection()

func redo() -> void:
	super.redo(); normalize_selection()
