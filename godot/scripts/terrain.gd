extends RefCounted
## The game and visual editor share this single persisted terrain definition.
const DATA_PATH = "res://assets/world/paths.json"
const USER_PATH = "user://paths.json"
static var ROUTES: Array = []
static var WIDTHS: Array = []
static var BLOCKS: Array = []
static var names: Array = []
static var last_error := ""
static var loaded_path := DATA_PATH

static func _static_init() -> void:
	load_paths()

static func default_path() -> String:
	return USER_PATH if FileAccess.file_exists(USER_PATH) or not OS.has_feature("editor") else DATA_PATH

static func validate(data) -> String:
	if not data is Dictionary or data.get("schema")!="kigi-paths/1": return "Nieprawidłowy format ścieżek."
	if not data.get("routes") is Array or data.routes.is_empty() or data.routes.size()>100: return "Mapa musi zawierać od 1 do 100 ścieżek."
	if not data.get("blocks") is Array: return "Brakuje listy przeszkód."
	for route in data.routes:
		if not route is Dictionary or not route.get("name") is String: return "Brakuje nazwy ścieżki."
		if not (route.get("radius") is float or route.get("radius") is int): return "Nieprawidłowa szerokość."
		if not is_finite(route.radius) or route.radius<8 or route.radius>120: return "Szerokość musi wynosić 16–240."
		if not route.get("points") is Array or route.points.size()<2 or route.points.size()>300: return "Ścieżka musi mieć od 2 do 300 punktów."
		for p in route.points:
			if not p is Array or p.size()!=2: return "Nieprawidłowy punkt."
			for v in p:
				if not (v is int or v is float) or not is_finite(v): return "Nieprawidłowe współrzędne."
			if p[0]<0 or p[0]>1024 or p[1]<0 or p[1]>1536: return "Punkt poza mapą."
	for b in data.blocks:
		if not b is Array or b.size()!=4: return "Nieprawidłowa przeszkoda."
		for v in b:
			if not (v is int or v is float) or not is_finite(v): return "Nieprawidłowa przeszkoda."
		if b[2]<=0 or b[3]<=0: return "Przeszkoda musi mieć dodatni rozmiar."
	return ""

static func read_data(path: String):
	if not FileAccess.file_exists(path): return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return null
	if not validate(parser.data).is_empty(): return null
	return parser.data

static func load_paths(path: String = "") -> bool:
	if path.is_empty(): path = default_path()
	var data = read_data(path)
	last_error = ""
	if data == null:
		data = read_data(path+".bak")
		if data == null:
			last_error = "Nie można wczytać ścieżek: "+path
			return false
		last_error = "Wczytano kopię bezpieczeństwa ścieżek."
	apply_data(data)
	loaded_path = path
	return true

static func snapshot() -> Dictionary:
	var routes := []
	for i in ROUTES.size(): routes.append({"name":names[i],"radius":WIDTHS[i],"points":ROUTES[i].duplicate(true)})
	var blocks := []
	for b in BLOCKS: blocks.append([b.position.x,b.position.y,b.size.x,b.size.y])
	return {"schema":"kigi-paths/1","routes":routes,"blocks":blocks}

static func apply_data(data: Dictionary) -> void:
	ROUTES = []; WIDTHS = []; BLOCKS = []; names = []
	for r in data.routes:
		ROUTES.append(r.points.duplicate(true)); WIDTHS.append(float(r.radius)); names.append(r.name)
	for b in data.blocks: BLOCKS.append(Rect2(b[0],b[1],b[2],b[3]))

static func save_paths(data: Dictionary, path: String, expected_digest: String) -> bool:
	last_error = validate(data)
	if not last_error.is_empty(): return false
	var current := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	if current!=expected_digest:
		last_error = "Plik zmienił się w innym oknie. Zamknij edytor i wczytaj go ponownie."
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		last_error = "Nie udało się otworzyć pliku do zapisu. Zmiany pozostają w edytorze."
		return false
	file.store_string(JSON.stringify(data,"  ")+"\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error!=OK or read_data(path+".tmp")==null:
		last_error = "Nie udało się zweryfikować zapisu."
		return false
	if read_data(path)!=null and DirAccess.copy_absolute(path,path+".bak")!=OK:
		last_error = "Nie udało się utworzyć kopii bezpieczeństwa."
		return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:
		last_error = "Nie udało się zatwierdzić zapisu."
		return false
	apply_data(data)
	loaded_path = path
	return true

static func nearest_walkable(p: Vector2) -> Vector2:
	if can_stand(p): return p
	var best := p
	var distance := INF
	for route in ROUTES:
		for i in range(route.size()-1):
			var a := Vector2(route[i][0],route[i][1])
			var b := Vector2(route[i+1][0],route[i+1][1])
			var steps := maxi(1,ceili(a.distance_to(b)/4))
			for step in range(steps+1):
				var q := a.lerp(b,float(step)/steps)
				if q.distance_squared_to(p)<distance and can_stand(q):
					best = q; distance = q.distance_squared_to(p)
	return best

static func point_open(p: Vector2) -> bool:
	for obstacle in BLOCKS:
		if obstacle.has_point(p): return false
	for r in ROUTES.size():
		var route: Array = ROUTES[r]
		for i in range(route.size()-1):
			var a := Vector2(route[i][0],route[i][1])
			var b := Vector2(route[i+1][0],route[i+1][1])
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b)) < WIDTHS[r]: return true
	return false

static func can_stand(p: Vector2) -> bool:
	# Footprint stays on the ground; sprite canopy is allowed to overlap walls.
	for offset in [Vector2.ZERO,Vector2(5,0),Vector2(-5,0),Vector2(0,3),Vector2(0,-3)]:
		if not point_open(p+offset): return false
	return true

static func move(start: Vector2, displacement: Vector2) -> Vector2:
	var p := start
	# Substeps prevent tunnelling through thin rock/water boundaries at low FPS.
	var steps := maxi(1,ceili(displacement.length()/2.0))
	var step := displacement/steps
	for i in steps:
		if can_stand(p+step): p += step
		elif can_stand(p+Vector2(step.x,0)): p.x += step.x
		elif can_stand(p+Vector2(0,step.y)): p.y += step.y
	return p
