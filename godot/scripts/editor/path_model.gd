extends RefCounted
const Terrain = preload("res://scripts/terrain.gd")
var data: Dictionary
var path: String
var digest := ""
var saved := ""
var undo_stack: Array = []
var redo_stack: Array = []
var before_change := {}
var selected_route := 0
var selected_point := -1

func _init(target: String = "") -> void:
	path = Terrain.default_path() if target.is_empty() else target
	var loaded = Terrain.read_data(path)
	data = Terrain.snapshot() if loaded == null else loaded
	digest = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	saved = JSON.stringify(data)

func dirty() -> bool: return JSON.stringify(data)!=saved

func begin_change() -> void:
	if before_change.is_empty(): before_change = data.duplicate(true)

func finish_change() -> void:
	if before_change.is_empty(): return
	if JSON.stringify(before_change)!=JSON.stringify(data):
		undo_stack.append(before_change)
		if undo_stack.size()>100: undo_stack.pop_front()
		redo_stack.clear()
	before_change = {}

func undo() -> void:
	finish_change()
	if undo_stack.is_empty(): return
	redo_stack.append(data.duplicate(true))
	data = undo_stack.pop_back()
	selected_route=mini(selected_route,data.routes.size()-1)
	selected_point = -1

func redo() -> void:
	if redo_stack.is_empty(): return
	undo_stack.append(data.duplicate(true))
	data = redo_stack.pop_back()
	selected_route=mini(selected_route,data.routes.size()-1)
	selected_point = -1

func move_point(position: Vector2) -> void:
	if selected_point<0: return
	var points: Array = data.routes[selected_route].points
	var previous := Vector2(points[selected_point][0],points[selected_point][1])
	var next := Vector2(clampf(position.x,0,1024),clampf(position.y,0,1536)).snapped(Vector2.ONE)
	# Shared junctions move as a group; editing one branch cannot silently split it.
	for route in data.routes:
		for i in route.points.size():
			if Vector2(route.points[i][0],route.points[i][1]).distance_to(previous)<0.01:
				route.points[i] = [next.x,next.y]

func set_width(full_width: float) -> void:
	begin_change()
	data.routes[selected_route].radius = clampf(full_width/2,8,120)
	finish_change()

func insert_point(route: int, segment: int, position: Vector2) -> void:
	begin_change()
	selected_route = route
	selected_point = segment+1
	data.routes[route].points.insert(selected_point,[clampf(position.x,0,1024),clampf(position.y,0,1536)])
	finish_change()

func delete_point() -> void:
	if selected_point<0 or data.routes[selected_route].points.size()<=2: return
	begin_change()
	data.routes[selected_route].points.remove_at(selected_point)
	selected_point = -1
	finish_change()

func save() -> bool:
	finish_change()
	if not Terrain.save_paths(data,path,digest): return false
	digest = FileAccess.get_sha256(path)
	saved = JSON.stringify(data)
	return true

func check_passages() -> String:
	var prior := Terrain.snapshot()
	Terrain.apply_data(data)
	var warnings := []
	for r in data.routes.size():
		var route: Dictionary = data.routes[r]
		var blocked := false
		for i in range(route.points.size()-1):
			var a := Vector2(route.points[i][0],route.points[i][1])
			var b := Vector2(route.points[i+1][0],route.points[i+1][1])
			var steps := maxi(1,ceili(a.distance_to(b)/3))
			for n in range(steps+1):
				if not Terrain.can_stand(a.lerp(b,float(n)/steps)): blocked = true; break
		if blocked: warnings.append("Przeszkoda na środku: "+route.name)
	# Geometric connectivity across sampled centerlines, including crossing segments.
	var connected := {0:true}
	for pass_index in data.routes.size():
		for a in data.routes.size():
			if not connected.has(a): continue
			for b in data.routes.size():
				if connected.has(b): continue
				if routes_join(a,b): connected[b] = true
	for r in data.routes.size():
		if not connected.has(r): warnings.append("Odłączona ścieżka: "+data.routes[r].name)
	for place in {"Poczta":Vector2(415,1250),"Szkoła":Vector2(444,679),"Pracownia":Vector2(551,310)}:
		var target: Vector2 = {"Poczta":Vector2(415,1250),"Szkoła":Vector2(444,679),"Pracownia":Vector2(551,310)}[place]
		if Terrain.nearest_walkable(target).distance_to(target)>30: warnings.append("Brak dojścia w pobliże: "+place)
	Terrain.apply_data(prior)
	return "Środki ścieżek są drożne, a pasy połączone. Po zapisie sprawdź teren, chodząc postacią." if warnings.is_empty() else "\n".join(warnings)

func routes_join(a: int, b: int) -> bool:
	var first: Array = data.routes[a].points
	var second: Array = data.routes[b].points
	for i in range(first.size()-1):
		for j in range(second.size()-1):
			var p := Vector2(first[i][0],first[i][1])
			var q := Vector2(first[i+1][0],first[i+1][1])
			var r := Vector2(second[j][0],second[j][1])
			var s := Vector2(second[j+1][0],second[j+1][1])
			var closest := Geometry2D.get_closest_points_between_segments(p,q,r,s)
			if closest[0].distance_to(closest[1])<data.routes[a].radius+data.routes[b].radius-12 and Terrain.can_stand((closest[0]+closest[1])/2): return true
	return false

func add_route(a: Vector2, b: Vector2) -> void:
	if data.routes.size()>=100 or a.distance_to(b)<1: return
	begin_change()
	var number := 1
	var names := []
	for route in data.routes: names.append(route.name)
	while "Ścieżka %d" % number in names: number+=1
	data.routes.append({"name":"Ścieżka %d" % number,"radius":24.0,"points":[[a.x,a.y],[b.x,b.y]]})
	selected_route=data.routes.size()-1; selected_point=1
	finish_change()

func append_point(p: Vector2) -> void:
	var points: Array=data.routes[selected_route].points
	if points.size()>=300: return
	var at := 0 if selected_point==0 else points.size()
	begin_change(); points.insert(at,[p.x,p.y]); selected_point=at; finish_change()

func rename_route(value: String) -> void:
	if value.strip_edges().is_empty(): return
	begin_change(); data.routes[selected_route].name=value.strip_edges(); finish_change()
