extends Control

const TOP := 78.0
const Bubble = preload("res://scripts/ui/station_bubble.gd")
var frame := Control.new()
var bubble := Bubble.new()
var artwork := Sprite2D.new()
var layout := {}
var station_id := ""
var hero = preload("res://scripts/hero_visual.gd").new()
var view_size := Vector2(390, 844)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	add_child(frame)
	artwork.centered = false
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.add_child(artwork)
	var title := Label.new()
	title.text = "KIGI / Szkoła Yuu"
	title.position = Vector2(16, 18)
	title.mouse_filter = MOUSE_FILTER_IGNORE
	frame.add_child(title)
	frame.add_child(hero)
	frame.add_child(bubble)
	bubble.start.mouse_filter = MOUSE_FILTER_IGNORE
	bubble.start.focus_mode = FOCUS_NONE
	resized.connect(update_preview)

func update_preview() -> void:
	if not is_node_ready() or not visible or layout.is_empty():
		return
	var factor := maxf(0.01, minf((size.x - 20) / view_size.x, (size.y - 16) / view_size.y))
	frame.size = view_size
	frame.scale = Vector2.ONE * factor
	frame.position = (size - view_size * factor) / 2
	for station in layout.stations:
		if station.id == station_id:
			show_station(Vector2(station.point[0], station.point[1]))
			return

func show_station(source_point: Vector2) -> void:
	var units_per_pixel: float = layout.world_units_per_pixel
	var world_size := Vector2(layout.source_size[0], layout.source_size[1]) * units_per_pixel
	var zoom := maxf(1.8, maxf(view_size.x / world_size.x, view_size.y / world_size.y))
	var feet := source_point * units_per_pixel
	var head_world := feet - Vector2(0, hero.world_height)
	var half := view_size / (2.0 * zoom)
	var center := feet - Vector2(0, 30)
	center = center.clamp(half, (world_size - half).max(half))
	var origin := view_size / 2.0 - center * zoom
	artwork.position = origin
	artwork.scale = Vector2.ONE * units_per_pixel * zoom
	hero.position = origin + feet * zoom
	hero.scale = Vector2.ONE * zoom
	bubble.set_station(station_id, true)
	if Bubble.WORDS.has(station_id):
		bubble.arrange(view_size, TOP, origin + head_world * zoom)
