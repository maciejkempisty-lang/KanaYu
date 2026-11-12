extends RefCounted
const BubbleSettings = preload("res://scripts/ui/station_bubble_settings.gd")
static var last_error := ""
static func target_path(source: String) -> String:
	var local := "user://scene-"+source.md5_text()+".json"
	return local if FileAccess.file_exists(local) or not OS.has_feature("editor") else source
static func load_layout(source: String):
	var path := target_path(source)
	var data=read_data(path)
	if data==null: data=read_data(path+".bak")
	if data==null and path!=source: data=read_data(source)
	return data
static func point_ok(p, size: Vector2) -> bool:
	if not p is Array or p.size()!=2: return false
	for v in p:
		if not (v is int or v is float) or not is_finite(v): return false
	return p[0]>=0 and p[1]>=0 and p[0]<=size.x and p[1]<=size.y
static func poly_ok(points, size: Vector2) -> bool:
	if not points is Array or points.size()<3 or points.size()>300: return false
	var poly := PackedVector2Array()
	for p in points:
		if not point_ok(p,size): return false
		poly.append(Vector2(p[0],p[1]))
	if Geometry2D.triangulate_polygon(poly).is_empty(): return false
	for i in poly.size():
		if poly[i].distance_to(poly[(i+1)%poly.size()])<0.1: return false
		for j in range(i+1,poly.size()):
			if j==i+1 or (i==0 and j==poly.size()-1): continue
			if Geometry2D.segment_intersects_segment(poly[i],poly[(i+1)%poly.size()],poly[j],poly[(j+1)%poly.size()])!=null: return false
	return true
static func validate(data) -> String:
	if not data is Dictionary or data.get("schema") not in ["kigi-school-layout/1","kigi-scene-layout/1"]: return "Nieprawidłowy format sceny."
	if data.has("station_bubble") and not BubbleSettings.is_valid(data.station_bubble): return "Nieprawidłowe ustawienia dymka."
	if data.has("station_bubbles"):
		if not data.station_bubbles is Dictionary:
			return "Nieprawidłowa lista dymków stanowisk."
		for station_id in data.station_bubbles:
			if not BubbleSettings.is_valid(data.station_bubbles[station_id]):
				return "Nieprawidłowe ustawienia dymka stanowiska: " + station_id
	if not point_ok(data.get("source_size"),Vector2(16384,16384)): return "Nieprawidłowy rozmiar grafiki."
	var size := Vector2(data.source_size[0],data.source_size[1])
	if size.x<=0 or size.y<=0: return "Pusty rozmiar grafiki."
	var scale_value=data.get("world_units_per_pixel")
	if not (scale_value is float or scale_value is int) or not is_finite(scale_value) or scale_value<=0: return "Nieprawidłowa skala świata."
	if not data.get("texture") is String or not ResourceLoader.exists(data.texture): return "Brakuje tła sceny."
	if not poly_ok(data.get("floor"),size): return "Nieprawidłowy obrys podłogi (minimum 3 punkty, bez przecięć)."
	if not point_ok(data.get("spawn"),size): return "Punkt startu poza mapą."
	for key in ["obstacles","foregrounds","stations"]:
		if not data.get(key) is Array or data[key].size()>300: return "Nieprawidłowa lista: "+key
	for item in data.obstacles:
		if not item is Dictionary or not item.get("id") is String or not poly_ok(item.get("polygon"),size): return "Nieprawidłowa przeszkoda."
	for item in data.foregrounds:
		if not item is Dictionary or not poly_ok(item.get("polygon"),size) or not poly_ok(item.get("region"),size): return "Nieprawidłowa maska lub jej obszar aktywacji."
	var ids := []
	for item in data.stations:
		if not item is Dictionary or not item.get("id") is String or item.id in ids or not item.get("name") is String or not point_ok(item.get("point"),size): return "Nieprawidłowy trigger."
		ids.append(item.id)
		var radius=item.get("radius_world")
		if not (radius is int or radius is float) or not is_finite(radius) or radius<=0 or radius>300: return "Nieprawidłowy zasięg triggera."
	var floor_poly:=PackedVector2Array()
	for p in data.floor: floor_poly.append(Vector2(p[0],p[1]))
	var spawn:=Vector2(data.spawn[0],data.spawn[1])
	for offset in [Vector2.ZERO,Vector2(5,0),Vector2(-5,0),Vector2(0,3),Vector2(0,-3)]:
		var q: Vector2=spawn+offset/scale_value
		if not Geometry2D.is_point_in_polygon(q,floor_poly): return "Punkt pojawienia musi leżeć na wolnej podłodze."
		for item in data.obstacles:
			var poly:=PackedVector2Array()
			for p in item.polygon: poly.append(Vector2(p[0],p[1]))
			if Geometry2D.is_point_in_polygon(q,poly): return "Przeszkoda blokuje punkt pojawienia bohatera."
	return ""

static func read_data(path: String):
	if not FileAccess.file_exists(path): return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return null
	if not validate(parser.data).is_empty(): return null
	return parser.data

static func save_layout(data: Dictionary, path: String, expected_digest: String) -> bool:
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

