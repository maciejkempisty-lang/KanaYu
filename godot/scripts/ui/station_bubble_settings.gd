extends RefCounted

const DEFAULTS := {"width": 390, "font_size": 20}
const LIMITS := {"width": Vector2(180, 640), "x_percent": Vector2(0, 100), "top_offset": Vector2(0, 240), "font_size": Vector2(16, 28)}

static func from_layout(layout: Dictionary, default_font_size: int = 20, station_id: String = "") -> Dictionary:
	var settings := DEFAULTS.duplicate()
	settings.font_size = default_font_size
	settings.merge(layout.get("station_bubble", {}), true)
	settings.merge(layout.get("station_bubbles", {}).get(station_id, {}), true)
	settings.erase("x_percent")
	settings.erase("top_offset")
	return settings

static func is_valid(settings: Variant) -> bool:
	if not settings is Dictionary:
		return false
	for key in settings:
		var value: Variant = settings[key]
		if not LIMITS.has(key) or not (value is int or value is float) or not is_finite(value):
			return false
		var limits: Vector2 = LIMITS[key]
		if value < limits.x or value > limits.y:
			return false
	return true
