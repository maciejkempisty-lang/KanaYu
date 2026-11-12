extends "res://scripts/editor/path_model.gd"
const Layout=preload("res://scripts/editor/scene_layout_data.gd")
var mode := "floor"
var source: String
var map_size: Vector2
func _init(layout_source: String) -> void:
	source=layout_source; path=Layout.target_path(source)
	var loaded=Layout.load_layout(source)
	data=loaded if loaded!=null else {}
	if data.is_empty(): return
	map_size=Vector2(data.source_size[0],data.source_size[1])
	digest=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	saved=JSON.stringify(clean_data()); sync_routes()
func clean_data() -> Dictionary:
	var result:=data.duplicate(true); result.erase("routes"); return result
func dirty() -> bool: return JSON.stringify(clean_data())!=saved
func sync_routes() -> void:
	data.routes=[]
	match mode:
		"floor": data.routes.append({"name":"Wolna podłoga","points":data.floor})
		"obstacles":
			for item in data.obstacles: data.routes.append({"name":item.id,"points":item.polygon})
		"masks", "regions":
			for i in data.foregrounds.size(): data.routes.append({"name":"Maska %d" % (i+1),"points":data.foregrounds[i].polygon if mode=="masks" else data.foregrounds[i].region})
		"triggers":
			for item in data.stations: data.routes.append({"name":item.name,"points":[item.point]})
		"spawn": data.routes.append({"name":"Punkt pojawienia","points":[data.spawn]})
	selected_route=clampi(selected_route,0,data.routes.size()-1) if not data.routes.is_empty() else -1
	selected_point=-1
func set_mode(value: String) -> void:
	finish_change(); mode=value; selected_route=0; sync_routes()
func edit_points(route: int) -> Array:
	return [] if route<0 else data.routes[route].points
func move_point(position: Vector2) -> void:
	if selected_point<0: return
	var p:=position.clamp(Vector2.ZERO,map_size).snapped(Vector2.ONE)
	# Mutate coordinates to preserve aliases to the source layout.
	var point: Array=edit_points(selected_route)[selected_point]
	point[0]=p.x; point[1]=p.y
func insert_point(route: int, segment: int, position: Vector2) -> void:
	if mode in ["triggers","spawn"] or route<0: return
	var points:=edit_points(route)
	if points.size()>=300: return
	begin_change(); selected_route=route; selected_point=segment+1
	var p:=position.clamp(Vector2.ZERO,map_size)
	points.insert(selected_point,[p.x,p.y]); finish_change()
func delete_point() -> void:
	if selected_point<0 or mode in ["triggers","spawn"] or edit_points(selected_route).size()<=3: return
	begin_change(); edit_points(selected_route).remove_at(selected_point); selected_point=-1; finish_change()
func undo() -> void:
	super.undo(); sync_routes()
func redo() -> void:
	super.redo(); sync_routes()
func set_radius(value: float) -> void:
	if mode!="triggers" or selected_route<0: return
	begin_change(); data.stations[selected_route].radius_world=value; finish_change()
func add_object(center: Vector2) -> void:
	if mode not in ["obstacles","masks","regions"]: return
	var p:=center.clamp(Vector2(45,45),map_size-Vector2(45,45))
	var points := [[p.x-40,p.y-40],[p.x+40,p.y-40],[p.x+40,p.y+40],[p.x-40,p.y+40]]
	begin_change()
	if mode=="obstacles":
		data.obstacles.append({"id":"Przeszkoda %d" % Time.get_ticks_msec(),"polygon":points}); selected_route=data.obstacles.size()-1
	else:
		data.foregrounds.append({"polygon":points,"region":points.duplicate(true)}); selected_route=data.foregrounds.size()-1
	finish_change(); sync_routes()
func delete_object() -> void:
	if selected_route<0 or mode not in ["obstacles","masks","regions"]: return
	begin_change()
	if mode=="obstacles": data.obstacles.remove_at(selected_route)
	else: data.foregrounds.remove_at(selected_route)
	finish_change(); sync_routes()
func save() -> bool:
	finish_change()
	if not Layout.save_layout(clean_data(),path,digest): return false
	digest=FileAccess.get_sha256(path); saved=JSON.stringify(clean_data()); return true


func set_bubble_settings(station_id: String, changes: Dictionary) -> void:
	var settings := Layout.BubbleSettings.from_layout(data, 20, station_id)
	var updated := settings.duplicate()
	updated.merge(changes, true)
	if updated == settings:
		return
	begin_change()
	var station_settings: Dictionary = data.get("station_bubbles", {})
	var overrides: Dictionary = station_settings.get(station_id, {}).duplicate()
	overrides.merge(changes, true)
	station_settings[station_id] = overrides
	data.station_bubbles = station_settings
	finish_change()
