extends Node2D
signal closed
const Space=preload("res://scripts/school_space.gd")
const Hero=preload("res://scripts/hero_visual.gd")
const Stick=preload("res://scripts/touch_stick.gd")
const BubbleSettings = preload("res://scripts/ui/station_bubble_settings.gd")
const Learning=preload("res://scripts/learning/school.gd")
var store
@export_file("*.json") var layout_path := "res://assets/school/layout.json"
var background: Sprite2D
var space=Space.new()
var hero := Node2D.new()
var visual=Hero.new()
var camera := Camera2D.new()
var stick=Stick.new()
const StationBubble = preload("res://scripts/ui/station_bubble.gd")
var bubble = StationBubble.new()
@export_range(16,28,1) var popup_font_size := 20
var header: PanelContainer
var status := Label.new()
var hud := CanvasLayer.new()
var activity = null
var current_station := ""
var movement_speed := 83.0
var camera_zoom := 1.8
var camera_follow_speed := 7.0
var transition_locked := true
var door_cooldown := 0.7
var automated := false
var automatic_direction := Vector2.ZERO
var foregrounds: Array=[]
var show_geometry := false
func _ready() -> void:
	space=Space.new(layout_path)
	var editing=preload("res://scripts/editor/editable_scene.gd").new()
	editing.layout_path=layout_path; editing.scene_title="Szkoła"; add_child(editing)
	if store==null:
		store=preload("res://scripts/learning/store.gd").new("user://learning-journal.json")
		store.initialize()
		transition_locked=false
	background = Sprite2D.new()
	background.texture=load(space.data.texture)
	background.centered=false; background.scale=Vector2.ONE*space.scale_factor
	background.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background)
	hero.position=space.point(space.data.spawn)
	add_child(hero); hero.add_child(visual)
	visual.facing="up"; visual.face(Vector2.ZERO)
	add_child(camera)
	camera.limit_left=0; camera.limit_top=0
	camera.limit_right=int(space.size.x); camera.limit_bottom=int(space.size.y)
	camera.position_smoothing_enabled=true; camera.position_smoothing_speed=camera_follow_speed
	camera.process_callback=Camera2D.CAMERA2D_PROCESS_IDLE
	camera.position=hero.position-Vector2(0,30)
	resize_view(); camera.make_current(); camera.reset_smoothing()
	get_viewport().size_changed.connect(resize_view)
	build_foregrounds()
	build_ui()
	update_state()
func resize_view() -> void:
	var view := get_viewport_rect().size
	camera.zoom=Vector2.ONE*maxf(camera_zoom,maxf(view.x/space.size.x,view.y/space.size.y))
func build_ui() -> void:
	add_child(hud)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE; hud.add_child(root)
	var style := StyleBoxFlat.new(); style.bg_color=Color("273e32e8"); style.set_corner_radius_all(14)
	style.content_margin_left=12; style.content_margin_right=12; style.content_margin_top=8; style.content_margin_bottom=8
	var panel := PanelContainer.new(); header=panel; panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left=12; panel.offset_right=-12; panel.offset_top=14
	panel.add_theme_stylebox_override("panel",style); root.add_child(panel)
	var column := VBoxContainer.new(); panel.add_child(column)
	var row := HBoxContainer.new(); column.add_child(row)
	var title := Label.new(); title.text="KIGI / Szkoła Yuu"; title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(title)
	var list := Button.new(); list.text="Aktywności"; list.custom_minimum_size.y=44
	list.pressed.connect(func(): open_activity("activities")); row.add_child(list)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status.add_theme_font_size_override("font_size",14); column.add_child(status)
	stick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT); stick.offset_top=-190; stick.offset_right=165; root.add_child(stick)
	bubble.activated.connect(interact); root.add_child(bubble)
	var hint := Label.new(); hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); hint.offset_top=-34
	hint.text="WASD / drążek · E: użyj · \\: edytor"
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_font_size_override("font_size",12)
	hint.add_theme_color_override("font_shadow_color",Color.BLACK); hint.add_theme_constant_override("shadow_offset_x",1); hint.add_theme_constant_override("shadow_offset_y",1)
	root.add_child(hint)
func keyboard_direction() -> Vector2:
	return Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
func _process(delta: float) -> void:
	door_cooldown=maxf(0,door_cooldown-delta)
	var direction: Vector2=automatic_direction if automated else keyboard_direction()+stick.vector
	if transition_locked or is_instance_valid(activity): direction=Vector2.ZERO
	var previous := hero.position
	hero.position=space.move(hero.position,direction.limit_length()*movement_speed*delta)
	visual.face((hero.position-previous)/delta if delta>0 else Vector2.ZERO)
	camera.position=hero.position-Vector2(0,30)
	update_state()
	position_bubble()
func update_state() -> void:
	for item in foregrounds: item.node.visible=Geometry2D.is_point_in_polygon(hero.position,item.region)
	current_station=space.station_at(hero.position)
	var show_popup: bool=not current_station.is_empty() and not is_instance_valid(activity) and not transition_locked
	bubble.set_station(current_station,station_available(current_station))
	bubble.visible=show_popup
	status.visible=not show_popup
	var detail := "Podejdź do stanowiska lub wybierz Aktywności."
	match current_station:
		"reading": detail="Czytanie na dziś: %d" % store.due_for("kana_reading").size()
		"writing": detail="Pisanie na dziś: %d" % store.due_for("kana_writing").size()
		"measurement": detail="Sprawdzenie po przerwie: %d" % store.measurements_due().size()
		"exit": detail="Drzwi prowadzą z powrotem do wioski."
	status.text="Poznane znaki: %d / 10 · %s" % [store.introduced.size(),detail]
func interact() -> void:
	if transition_locked or is_instance_valid(activity) or current_station.is_empty() or not station_available(current_station): return
	if current_station=="exit": request_exit()
	else: open_activity(current_station)
func open_activity(id: String) -> void:
	if transition_locked or is_instance_valid(activity): return
	stick.reset()
	activity=Learning.new(); activity.store=store; activity.room_mode=true; activity.initial_activity=id
	activity.closed.connect(func(): activity=null; stick.reset(); update_state())
	add_child(activity)
func request_exit() -> void:
	if transition_locked or is_instance_valid(activity) or door_cooldown>0: return
	transition_locked=true; stick.reset()
	if closed.get_connections().is_empty(): get_tree().change_scene_to_file("res://scenes/village.tscn")
	else: closed.emit()
func _unhandled_key_input(event: InputEvent) -> void:
	if transition_locked or is_instance_valid(activity) or not event.is_pressed() or event.is_echo(): return
	if event.keycode==KEY_E: interact(); get_viewport().set_input_as_handled()
	elif event.keycode==KEY_ESCAPE: request_exit(); get_viewport().set_input_as_handled()
	elif event.keycode==KEY_F3: show_geometry=not show_geometry; queue_redraw()
func _draw() -> void:
	if not show_geometry: return
	draw_colored_polygon(space.floor,Color(0.2,0.9,0.8,0.2))
	for obstacle in space.obstacles: draw_colored_polygon(obstacle,Color(0.9,0.2,0.2,0.4))
	for station in space.stations: draw_circle(station.point,station.radius,Color(1,0.9,0.3,0.2))

func build_foregrounds() -> void:
	for item in space.data.foregrounds:
		var node := Polygon2D.new()
		node.polygon=space.polygon(item.polygon)
		var uv := PackedVector2Array()
		for p in item.polygon: uv.append(Vector2(p[0],p[1]))
		node.uv=uv; node.texture=background.texture; node.z_index=5
		node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(node)
		foregrounds.append({"node":node,"region":space.polygon(item.region)})

func reset_editor_input() -> void:
	stick.reset(); automatic_direction=Vector2.ZERO

func reload_scene_layout() -> void:
	reset_editor_input()
	space=Space.new(layout_path)
	background.texture=load(space.data.texture); background.scale=Vector2.ONE*space.scale_factor
	for item in foregrounds: item.node.hide(); item.node.queue_free()
	foregrounds.clear(); build_foregrounds()
	hero.position=space.nearest_walkable(hero.position)
	camera.limit_right=int(space.size.x); camera.limit_bottom=int(space.size.y)
	resize_view(); camera.position=hero.position-Vector2(0,30); camera.reset_smoothing()
	update_state(); queue_redraw()

func station_available(id: String) -> bool:
	match id:
		"reading": return not store.due_for("kana_reading").is_empty()
		"writing": return not store.due_for("kana_writing").is_empty()
		"measurement": return not store.measurements_due().is_empty()
		"exit": return door_cooldown<=0
	return id in ["first","notebook","journal"]

func position_bubble() -> void:
	if not bubble.visible: return
	bubble.settings = BubbleSettings.from_layout(space.data, popup_font_size, current_station)
	var view:=get_viewport_rect().size
	var screen_head := get_global_transform_with_canvas() * (hero.position - Vector2(0, visual.world_height))
	bubble.arrange(view, header.get_global_rect().end.y + 4.0, screen_head)
