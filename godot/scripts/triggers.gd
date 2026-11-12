extends RefCounted
const DATA_PATH = "res://assets/world/triggers.json"
const USER_PATH = "user://triggers.json"
static var last_error := ""
static func default_path() -> String:
	return USER_PATH if FileAccess.file_exists(USER_PATH) or not OS.has_feature("editor") else DATA_PATH

static func validate(data) -> String:
	if not data is Dictionary or data.get("schema")!="kigi-triggers/1": return "Nieprawidłowy format triggerów."
	if not data.get("routes") is Array or data.routes.size()!=3: return "Wymagane trzy miejsca interakcji."
	var ids := []
	for item in data.routes:
		if not item is Dictionary or item.get("id") not in ["school","post","workshop"] or item.id in ids: return "Nieprawidłowe miejsce interakcji."
		ids.append(item.id)
		if not item.get("name") is String or item.name.strip_edges().is_empty(): return "Podaj nazwę miejsca."
		if not (item.get("radius") is float or item.get("radius") is int): return "Nieprawidłowy zasięg."
		if not is_finite(item.radius) or item.radius<8 or item.radius>120: return "Promień musi wynosić 8–120."
		if not item.get("points") is Array or item.points.size()!=1: return "Wymagany środek triggera."
		var p = item.points[0]
		if not p is Array or p.size()!=2: return "Nieprawidłowy środek."
		for v in p:
			if not (v is float or v is int) or not is_finite(v): return "Nieprawidłowa współrzędna."
		if p[0]<0 or p[0]>1024 or p[1]<0 or p[1]>1536: return "Środek poza mapą."
	return ""

static func location_at(data: Dictionary, position: Vector2) -> String:
	var result := ""
	var closest := INF
	for item in data.routes:
		var distance := position.distance_to(Vector2(item.points[0][0],item.points[0][1]))
		if distance<item.radius and distance<closest: closest=distance; result=item.id
	return result

static func read_data(path: String):
	if not FileAccess.file_exists(path): return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return null
	if not validate(parser.data).is_empty(): return null
	return parser.data

static func save_triggers(data: Dictionary, path: String, expected_digest: String) -> bool:
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
	return true

