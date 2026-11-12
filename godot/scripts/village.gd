extends Node2D
signal location_entered(location_id: String)
const Terrain = preload("res://scripts/terrain.gd")
const HeroVisual = preload("res://scripts/hero_visual.gd")
const Residents = preload("res://scenes/village_residents.tscn")
const VillageResident = preload("res://scripts/village_resident.gd")
const Masks = preload("res://scripts/masks.gd")
const PathEditor = preload("res://scripts/editor/path_editor.gd")
var path_editor = null
var path_editor_window: Window
const TouchStick = preload("res://scripts/touch_stick.gd")
@export_range(1.0,5.0,0.05) var camera_zoom := 1.8
@export_range(1.0,20.0,0.5) var camera_follow_speed := 7.0
@export var movement_speed := 83.0
@export var journal_path := "user://learning-journal.json"
const LearningStore = preload("res://scripts/learning/store.gd")
const School = preload("res://scripts/learning/school.gd")
var learning_store
var school = null
var transitioning := false
var entry_position := Vector2.ZERO
var fade_layer: CanvasLayer
var fade_rect: ColorRect
@export var show_walkable := false
var hero := Node2D.new()
var talking_residents: Array[VillageResident] = []
var speaking_resident: VillageResident
var nearby_resident: VillageResident
var visual := HeroVisual.new()
var camera := Camera2D.new()
var stick := TouchStick.new()
var action := Button.new()
var location_label := Label.new()
var dialog := AcceptDialog.new()
var current_location := ""
var automated := false
var automatic_direction := Vector2.ZERO
var foregrounds: Array[Dictionary] = []
const Triggers = preload("res://scripts/triggers.gd")
@export var triggers_path := ""
var trigger_data := {}
const PLACES = {"post":Vector2(415,1250),"school":Vector2(444,679),"workshop":Vector2(551,310)}
const NAMES = {"post":"Poczta pod drzewem","school":"Szkoła Yuu","workshop":"Pracownia lampionów"}

func _ready() -> void:
	add_to_group("editable_scene")
	Terrain.load_paths()
	reload_triggers()
	learning_store = LearningStore.new(journal_path)
	learning_store.initialize()
	get_tree().auto_accept_quit = false
	if OS.has_feature("mobile"):
		# Logical portrait reference handles high-DPI phones; wider devices expand.
		get_window().content_scale_size = Vector2i(390,844)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var background := Sprite2D.new()
	background.texture = preload("res://assets/map-v2/map-master-2560x3840.png")
	background.centered = false
	background.scale = Vector2.ONE / 2.5
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background)
	# Residents and the hero share a draw order based on their ground anchors.
	var residents := Residents.instantiate()
	add_child(residents)
	for resident in residents.get_children():
		if resident is VillageResident:
			talking_residents.append(resident)
	hero.position = Terrain.nearest_walkable(Vector2(185, 1510))
	visual.facing = "northeast"
	residents.add_child(hero)
	hero.add_child(visual)
	add_child(camera)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1024
	camera.limit_bottom = 1536
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_follow_speed
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	camera.position = hero.position-Vector2(0,30)
	_resize()
	camera.reset_smoothing()
	get_viewport().size_changed.connect(_resize)
	# Reproject original pixels over the avatar. Each mask has an explicit ground
	# region; a lower terrace must never sort in front of an upper terrace by Y alone.
	reload_masks()
	_build_ui()
	queue_redraw()

func reload_masks() -> void:
	var data = Masks.read_data(Masks.default_path())
	if data == null: data = Masks.read_data(Masks.default_path()+".bak")
	if data == null: return
	for item in foregrounds: item.node.queue_free()
	foregrounds.clear()
	for mask in data.routes:
		var points := []
		var region := PackedVector2Array()
		for p in mask.points: points.append(Vector2(p[0],p[1]))
		for p in mask.region: region.append(Vector2(p[0],p[1]))
		foreground(points,region)

func foreground(points: Array, ground_region: PackedVector2Array) -> void:
	var layer := Polygon2D.new()
	layer.polygon = PackedVector2Array(points)
	var uv := PackedVector2Array()
	for point in points: uv.append(point * 2.5)
	layer.uv = uv
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.texture = preload("res://assets/map-v2/map-master-2560x3840.png")
	layer.z_index = 5
	add_child(layer)
	foregrounds.append({"node":layer,"region":ground_region})

func _resize() -> void:
	# Fixed pixel/world scale across phone and tablet, expanding the visible world.
	var view := get_viewport_rect().size
	var z := maxf(camera_zoom,maxf(view.x/1024.0,view.y/1536.0))
	camera.zoom = Vector2.ONE*z

func _build_ui() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	var header := PanelContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 16
	header.offset_right = -16
	header.offset_top = 18
	header.offset_bottom = 78
	root.add_child(header)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("273e32e8")
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	header.add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	header.add_child(column)
	var title := Label.new()
	title.text = "KIGI  /  Ścieżki wioski"
	title.add_theme_font_size_override("font_size",20)
	column.add_child(title)
	column.add_child(location_label)
	location_label.add_theme_font_size_override("font_size",14)
	stick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stick.offset_top = -190
	stick.offset_right = 165
	root.add_child(stick)
	action.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	action.offset_left = -205
	action.offset_right = -18
	action.offset_top = -119
	action.offset_bottom = -63
	action.add_theme_stylebox_override("normal",style)
	action.pressed.connect(interact)
	root.add_child(action)
	for resident in talking_residents:
		resident.attach_dialogue(root, advance_resident_dialogue.bind(resident))
	var hint := Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -35
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "WASD / drążek · E: wejście · \\: ścieżki"
	hint.add_theme_font_size_override("font_size",12)
	hint.add_theme_color_override("font_shadow_color",Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x",1)
	hint.add_theme_constant_override("shadow_offset_y",1)
	root.add_child(hint)
	root.add_child(dialog)
	dialog.title = "Kigi"
	dialog.confirmed.connect(func(): stick.reset())

func _process(delta: float) -> void:
	var direction := automatic_direction if automated else keyboard_direction()+stick.vector
	if transitioning or dialog.visible or is_instance_valid(school) or is_instance_valid(path_editor) or speaking_resident != null: direction = Vector2.ZERO
	direction = direction.limit_length()
	var previous_position := hero.position
	hero.position = Terrain.move(hero.position,direction*movement_speed*delta)
	visual.face((hero.position-previous_position)/delta if delta>0 else Vector2.ZERO)
	camera.position = hero.position-Vector2(0,30)
	for layer in foregrounds:
		layer.node.visible = Geometry2D.is_point_in_polygon(hero.position,layer.region)
	current_location = ""
	current_location = Triggers.location_at(trigger_data,hero.position)
	action.visible = not current_location.is_empty()
	if action.visible: action.text = "Wejdź do szkoły" if current_location=="school" else "Obejrzyj miejsce"
	update_residents()
	location_label.text = trigger_names().get(current_location, "Górny taras" if hero.position.y < 420 else ("Środkowy taras" if hero.position.y < 810 else "Dolny taras"))

func keyboard_direction() -> Vector2:
	return Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))

func _unhandled_key_input(event: InputEvent) -> void:
	if transitioning or is_instance_valid(school) or is_instance_valid(path_editor): return
	if event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E:
			interact()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE and speaking_resident != null:
			speaking_resident.page = -1
			speaking_resident = null
			stick.reset()
			update_residents()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_BACKSLASH: open_path_editor()
		if event.keycode == KEY_F3:
			show_walkable = not show_walkable
			queue_redraw()

func interact() -> void:
	if transitioning or dialog.visible or is_instance_valid(school) or is_instance_valid(path_editor):
		return
	if speaking_resident != null:
		advance_resident_dialogue(speaking_resident)
		return
	if current_location.is_empty():
		if nearby_resident != null:
			advance_resident_dialogue(nearby_resident)
		return
	stick.reset()
	location_entered.emit(current_location)
	if current_location == "school":
		enter_school()
		return
	else:
		dialog.dialog_text = "Poczta pod Starym Drzewem\nMiejsce przygotowane na kolejną wizytę." if current_location == "post" else "Pracownia Różnych Świateł\nMiejsce przygotowane na kolejną wizytę."
	dialog.popup_centered(Vector2i(mini(350,int(get_viewport_rect().size.x)-28),190))

func _draw() -> void:
	if learning_store != null and learning_store.lantern_unlocked():
		draw_line(Vector2(500,575),Vector2(500,587),Color("68573b"),2)
		draw_circle(Vector2(500,597),11,Color("f1ba58"))
		draw_circle(Vector2(500,597),6,Color("ffe6a4"))
	if not show_walkable: return
	for r in Terrain.ROUTES.size():
		var points := PackedVector2Array()
		for p in Terrain.ROUTES[r]: points.append(Vector2(p[0],p[1]))
		draw_polyline(points,Color(0.2,0.9,0.8,0.3),Terrain.WIDTHS[r]*2,true)
		# Rounded corridor joins match the distance-to-segment movement rule.
		for point in points: draw_circle(point,Terrain.WIDTHS[r],Color(0.2,0.9,0.8,0.18))
		draw_polyline(points,Color(1,0.85,0.3,0.8),1.0,true)
		for i in points.size():
			draw_circle(points[i],3,Color("ffe58b"))
			draw_string(ThemeDB.fallback_font,points[i]+Vector2(5,-5),"%d.%d" % [r,i],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("152e24"))
	for obstacle in Terrain.BLOCKS:
		draw_rect(obstacle,Color(0.9,0.16,0.12,0.5))
		draw_rect(obstacle,Color(1,0.8,0.7),false,1.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		refresh_world_files.call_deferred()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var host=get_node_or_null("/root/WorldEditor")
		if host!=null and is_instance_valid(host.editor):
			host.editor.request_close()
			return
		if is_instance_valid(path_editor):
			path_editor.pending_quit = true
			path_editor.request_close()
			return
		if host != null and host.dock_active:
			return
		request_game_quit()

func request_game_quit() -> void:
	if learning_store == null or learning_store.end_session("app_closed"):
		get_tree().quit()
	else:
		dialog.dialog_text = learning_store.error
		dialog.popup_centered(Vector2i(330,180))

func editor_context() -> Dictionary:
	return {} if transitioning or is_instance_valid(school) else {"kind":"village","title":"Wioska"}

func editor_opened(value) -> void:
	stick.reset(); path_editor=value

func editor_closed() -> void:
	path_editor=null; path_editor_window=null
	reload_masks(); reload_triggers()
	hero.position=Terrain.nearest_walkable(hero.position)
	stick.reset(); queue_redraw()

func open_path_editor() -> void:
	get_node("/root/WorldEditor").open_for(self)

func reload_triggers() -> void:
	var path := Triggers.default_path() if triggers_path.is_empty() else triggers_path
	var loaded = Triggers.read_data(path)
	if loaded==null: loaded=Triggers.read_data(path+".bak")
	if loaded==null: loaded=Triggers.read_data(Triggers.DATA_PATH)
	if loaded!=null: trigger_data=loaded

func trigger_names() -> Dictionary:
	var result := {}
	for item in trigger_data.routes: result[item.id]=item.name
	return result

func fade_to(alpha: float) -> void:
	if not is_instance_valid(fade_layer):
		fade_layer=CanvasLayer.new(); fade_layer.layer=100
		get_parent().add_child(fade_layer)
		fade_rect=ColorRect.new(); fade_rect.color=Color.BLACK
		fade_rect.modulate.a=0
		fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fade_layer.add_child(fade_rect)
	fade_layer.show()
	var tween=create_tween()
	tween.tween_property(fade_rect,"modulate:a",alpha,0.18)
	await tween.finished
	if alpha==0: fade_layer.hide()

func village_visible(value: bool) -> void:
	visible=value
	for child in get_children():
		if child is CanvasLayer: child.visible=value
	camera.enabled=value
	set_process(value)
	set_process_unhandled_key_input(value)

func enter_school() -> void:
	if transitioning or is_instance_valid(school): return
	transitioning=true; entry_position=hero.position; stick.reset()
	await fade_to(1)
	village_visible(false)
	school=preload("res://scenes/school_interior.tscn").instantiate()
	school.store=learning_store
	school.camera_zoom=camera_zoom; school.camera_follow_speed=camera_follow_speed; school.movement_speed=movement_speed
	school.closed.connect(leave_school)
	get_parent().add_child(school)
	await fade_to(0)
	school.transition_locked=false
	transitioning=false

func leave_school() -> void:
	if transitioning: return
	transitioning=true
	await fade_to(1)
	if is_instance_valid(school):
		school.camera.enabled=false
		school.queue_free()
	school=null
	hero.position=Terrain.nearest_walkable(entry_position)
	visual.facing="down"; visual.face(Vector2.ZERO)
	stick.reset(); village_visible(true)
	camera.make_current(); camera.position=hero.position-Vector2(0,30); camera.reset_smoothing()
	queue_redraw()
	await fade_to(0)
	transitioning=false

func _exit_tree() -> void:
	if is_instance_valid(school): school.queue_free()
	if is_instance_valid(fade_layer): fade_layer.queue_free()

func refresh_world_files() -> void:
	if not is_inside_tree() or learning_store==null or transitioning or is_instance_valid(school) or is_instance_valid(path_editor): return
	reload_masks(); reload_triggers()
	if Terrain.load_paths():
		hero.position=Terrain.nearest_walkable(hero.position)
		queue_redraw()


func update_residents() -> void:
	nearby_resident = null
	var available := not transitioning and not dialog.visible and not is_instance_valid(school) and not is_instance_valid(path_editor)
	for resident in talking_residents:
		var can_show := available and (speaking_resident == null or speaking_resident == resident)
		if resident.update_dialogue(hero.global_position, can_show):
			nearby_resident = resident
	if speaking_resident != null:
		action.hide()

func advance_resident_dialogue(resident: VillageResident) -> void:
	if transitioning or dialog.visible or is_instance_valid(school) or is_instance_valid(path_editor):
		return
	if speaking_resident != null and speaking_resident != resident:
		return
	if resident.page < 0 and not resident.dialogue_bubble.is_visible_in_tree():
		return
	stick.reset()
	resident.advance_dialogue()
	speaking_resident = resident if resident.page >= 0 else null
	update_residents()
