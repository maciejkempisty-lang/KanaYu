extends RefCounted
const DATA_PATH = "res://assets/world/masks.json"
const USER_PATH = "user://masks.json"
static var last_error := ""
static func default_path() -> String:
	return USER_PATH if FileAccess.file_exists(USER_PATH) or not OS.has_feature("editor") else DATA_PATH

static func validate(data) -> String:
	if not data is Dictionary or data.get("schema") != "kigi-masks/1": return "Nieprawidłowy format masek."
	if not data.get("routes") is Array or data.routes.size()>100: return "Dozwolone 0–100 masek."
	for mask in data.routes:
		if not mask is Dictionary or not mask.get("name") is String: return "Brakuje nazwy maski."
		for key in ["points","region"]:
			if not mask.get(key) is Array or mask[key].size()<3 or mask[key].size()>300: return "Obrys musi mieć 3–300 punktów."
			var polygon := PackedVector2Array()
			for p in mask[key]:
				if not p is Array or p.size()!=2: return "Nieprawidłowy punkt."
				for v in p:
					if not (v is int or v is float) or not is_finite(v): return "Nieprawidłowa współrzędna."
				if p[0]<0 or p[0]>1024 or p[1]<0 or p[1]>1536: return "Punkt poza mapą."
				polygon.append(Vector2(p[0],p[1]))
			if Geometry2D.triangulate_polygon(polygon).is_empty(): return "Nieprawidłowy obrys: punkty leżą na linii lub krawędzie się przecinają."
			for i in polygon.size():
				if polygon[i].distance_to(polygon[(i+1)%polygon.size()])<0.1: return "Sąsiednie punkty nakładają się."
				for j in range(i+1,polygon.size()):
					if j==i+1 or (i==0 and j==polygon.size()-1): continue
					if Geometry2D.segment_intersects_segment(polygon[i],polygon[(i+1)%polygon.size()],polygon[j],polygon[(j+1)%polygon.size()])!=null: return "Krawędzie obrysu nie mogą się przecinać."
	return ""

static func read_data(path: String):
	if not FileAccess.file_exists(path): return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return null
	if not validate(parser.data).is_empty(): return null
	return parser.data

static func save_masks(data: Dictionary, path: String, expected_digest: String) -> bool:
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

