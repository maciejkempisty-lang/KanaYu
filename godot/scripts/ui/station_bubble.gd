extends Control
signal activated
const ART=preload("res://assets/ui/kigi-speech-bubble-play.png")
const WORDS={
	"first":["Na tej tablicy poznam pierwsze znaki.","Rozpocznij lekcję"],
	"reading":["Tutaj poćwiczę czytanie.","Ćwicz czytanie"],
	"writing":["Tu mogę poćwiczyć pisanie.","Ćwicz pisanie"],
	"measurement":["Sprawdzę, co pamiętam po przerwie.","Sprawdź pamięć"],
	"notebook":["Tutaj są moje poznane znaki.","Otwórz notes"],
	"journal":["Tu znajdę zapis swoich prób.","Otwórz dziennik"],
	"exit":["Wrócę do wioski.","Wyjdź"]}
var message:=Label.new()
var start:=Button.new()
const Settings = preload("res://scripts/ui/station_bubble_settings.gd")
var settings := Settings.DEFAULTS.duplicate()
var enabled := false
var station := ""
var head:=Vector2.ZERO
var art_size:=Vector2(360,240)
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	message.mouse_filter=Control.MOUSE_FILTER_IGNORE
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_override("font",preload("res://assets/Nunito.ttf"))
	message.add_theme_color_override("font_color",Color("343e25"))
	add_child(message)
	start.focus_mode=Control.FOCUS_ALL
	for state in ["normal","hover","pressed","disabled"]: start.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var focus:=StyleBoxFlat.new(); focus.bg_color=Color(0,0,0,0)
	focus.border_color=Color("284638"); focus.set_border_width_all(3); focus.set_corner_radius_all(28)
	start.add_theme_stylebox_override("focus",focus)
	start.pressed.connect(func():
		if enabled: activated.emit())
	add_child(start)
	hide()
func set_station(id: String, available: bool) -> void:
	station=id; enabled=available
	if not WORDS.has(id): hide(); return
	var text: String=WORDS[id][0]
	if not available:
		match id:
			"reading": text="Na dziś nie mam powtórek czytania."
			"writing": text="Na dziś nie mam powtórek pisania."
			"measurement": text="Wrócę tu po dłuższej przerwie."
			"exit": text="Za chwilę mogę wrócić do wioski."
	set_message(text, WORDS[id][1], available)

func set_message(text: String, action_name: String, available: bool = true) -> void:
	enabled = available
	message.text = text
	start.disabled = not available
	start.accessibility_name = action_name
	start.accessibility_description = text + (" Naciśnij E lub aktywuj przycisk." if available else " Teraz niedostępne.")
	start.tooltip_text = action_name + (" · E" if available else " · teraz niedostępne.")
	queue_redraw()
func arrange(view: Vector2, top: float, screen_head: Vector2) -> void:
	const EDGE := 8.0
	const HEAD_GAP := 8.0
	var tip := Vector2(clampf(screen_head.x, EDGE, maxf(EDGE, view.x - EDGE)), screen_head.y - HEAD_GAP)
	var width_limit := maxf(1, view.x - 2.0 * EDGE)
	var height_based_width := maxf(Settings.LIMITS.width.x, (tip.y - top - 12.0) / 0.56)
	art_size.x = minf(settings.width, minf(width_limit, height_based_width))
	message.add_theme_font_size_override("font_size", int(settings.font_size))
	message.position = Vector2(art_size.x * 0.14, 0)
	message.size = Vector2(art_size.x * 0.61, 1)
	art_size.y = maxf(art_size.x * 2.0 / 3.0, (message.get_minimum_size().y + 12.0) / 0.44)
	size = art_size
	var body_height := art_size.y * 0.84
	var bottom_limit := minf(tip.y - 12.0, view.y - EDGE)
	if top + body_height > bottom_limit:
		hide()
		return
	position = Vector2(
		clampf(tip.x - art_size.x * 0.29, EDGE, maxf(EDGE, view.x - EDGE - art_size.x)),
		clampf(tip.y - art_size.y * 0.975, top, bottom_limit - body_height)
	)
	message.position.y = art_size.y * 0.25
	message.size.y = art_size.y * 0.44
	var hit := Vector2(maxf(48, art_size.x * 0.13), maxf(48, art_size.y * 0.18))
	start.position = art_size * Vector2(0.81, 0.67) - hit / 2
	start.size = hit
	head = tip - position
	show()
	queue_redraw()

func _draw() -> void:
	if not visible: return
	# Keep the painted body and icon intact. Only the transparent tail strip is
	# stretched/sheared so its painted tip follows the head after edge clamping.
	var split:=art_size.y*0.84
	var upper:=PackedVector2Array([Vector2.ZERO,Vector2(art_size.x,0),Vector2(art_size.x,split),Vector2(0,split)])
	draw_polygon(upper,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2(1,0.84),Vector2(0,0.84)]),ART)
	var fraction: float=(0.975-0.84)/(1.0-0.84)
	var bottom_y: float=split+maxf(12,head.y-split)/fraction
	var shift: float=(head.x-art_size.x*0.29)/fraction
	var lower:=PackedVector2Array([Vector2(0,split),Vector2(art_size.x,split),Vector2(art_size.x+shift,bottom_y),Vector2(shift,bottom_y)])
	draw_polygon(lower,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,0.84),Vector2(1,0.84),Vector2.ONE,Vector2(0,1)]),ART)
	if not enabled:
		var center:=art_size*Vector2(0.81,0.67)
		draw_circle(center,art_size.x*0.048,Color(0.78,0.74,0.65,0.82))
		draw_line(center-Vector2(10,-10),center+Vector2(10,-10),Color("6c6b5b"),2,true)


