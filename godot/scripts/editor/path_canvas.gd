extends Control
signal edited
signal selection_changed
var model
var map_size := Vector2(1024,1536)
var path_tool := ""
var new_start = null
var zoom := 0.5
var pan := Vector2.ZERO
var dragging := false
var panning := false
var touch_id := -1
var drag_offset := Vector2.ZERO
var background := preload("res://assets/map-v2/map-master-2560x3840.png")

func _ready() -> void:
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	resized.connect(fit_map)
	fit_map.call_deferred()

func fit_map() -> void:
	zoom = minf((size.x-30)/map_size.x,(size.y-30)/map_size.y)
	zoom = maxf(zoom,0.1)
	pan = (size-map_size*zoom)/2
	queue_redraw()

func to_world(p: Vector2) -> Vector2: return (p-pan)/zoom
func to_screen(p: Vector2) -> Vector2: return p*zoom+pan

func zoom_at(screen: Vector2, factor: float) -> void:
	var fixed := to_world(screen)
	zoom = clampf(zoom*factor,0.1,4.0)
	pan = screen-fixed*zoom
	queue_redraw()

func points_for(route: int) -> Array:
	if model.has_method("edit_points"): return model.edit_points(route)
	return model.data.routes[route].points

func pick(screen: Vector2) -> Vector2i:
	var hit := Vector2i(-1,-1)
	var best := 14.0
	# Give the current path priority at shared junctions.
	var order := [model.selected_route]
	for r in model.data.routes.size():
		if r!=model.selected_route: order.append(r)
	for r in order:
		var points: Array = points_for(r)
		for i in points.size():
			var distance := to_screen(Vector2(points[i][0],points[i][1])).distance_to(screen)
			if distance<best:
				best = distance; hit = Vector2i(r,i)
	return hit

func begin_drag(screen: Vector2) -> void:
	var hit := pick(screen)
	if hit.x<0:
		panning = true
		return
	model.selected_route = hit.x
	model.selected_point = hit.y
	var point: Array = points_for(hit.x)[hit.y]
	drag_offset = Vector2(point[0],point[1])-to_world(screen)
	model.begin_change()
	dragging = true
	selection_changed.emit()
	queue_redraw()

func finish_drag() -> void:
	if dragging:
		model.finish_change()
		edited.emit()
	dragging = false
	panning = false
	touch_id = -1

func insert_near(screen: Vector2) -> void:
	var world := to_world(screen)
	var best := 18.0/zoom
	var hit := Vector2i(-1,-1)
	var at := world
	for r in ([model.selected_route] if path_tool=="point" else range(model.data.routes.size())):
		var points: Array = points_for(r)
		for i in range(points.size()-1):
			var p := Geometry2D.get_closest_point_to_segment(world,Vector2(points[i][0],points[i][1]),Vector2(points[i+1][0],points[i+1][1]))
			if p.distance_to(world)<best: best=p.distance_to(world); hit=Vector2i(r,i); at=p
	if hit.x>=0:
		model.insert_point(hit.x,hit.y,at)
		selection_changed.emit(); edited.emit(); queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not path_tool.is_empty() and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var p := to_world(event.position).clamp(Vector2.ZERO,Vector2(1024,1536)).snapped(Vector2.ONE)
		if path_tool=="create":
			if new_start==null: new_start=p
			elif new_start.distance_to(p)>=1:
				model.add_route(new_start,p); new_start=null; path_tool="append"
		elif path_tool=="append": model.append_point(p)
		else: insert_near(event.position)
		selection_changed.emit(); edited.emit(); queue_redraw(); accept_event(); return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom_at(event.position,1.15)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom_at(event.position,1/1.15)
		elif event.button_index in [MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]: panning=event.pressed
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.double_click and event.pressed: finish_drag(); insert_near(event.position)
			elif event.pressed: begin_drag(event.position)
			else: finish_drag()
		accept_event()
	elif event is InputEventMouseMotion:
		if dragging: model.move_point(to_world(event.position)+drag_offset); edited.emit(); queue_redraw()
		elif panning: pan+=event.relative; queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and touch_id==-1: touch_id=event.index; begin_drag(event.position)
		elif not event.pressed and event.index==touch_id: finish_drag()
		accept_event()
	elif event is InputEventScreenDrag and event.index==touch_id:
		if dragging: model.move_point(to_world(event.position)+drag_offset); edited.emit(); queue_redraw()
		elif panning: pan+=event.relative; queue_redraw()
		accept_event()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and model!=null: finish_drag()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("1e302b"))
	if model==null: return
	draw_texture_rect(background,Rect2(pan,map_size*zoom),false)
	for r in model.data.routes.size():
		var route: Dictionary = model.data.routes[r]
		var points := PackedVector2Array()
		for p in route.points: points.append(to_screen(Vector2(p[0],p[1])))
		var selected: bool = r==model.selected_route
		var tint := Color(1,0.7,0.2,0.32) if selected else Color(0.2,0.9,0.85,0.20)
		draw_polyline(points,tint,route.radius*2*zoom,true)
		for p in points: draw_circle(p,route.radius*zoom,tint)
		draw_polyline(points,Color("ffcc73") if selected else Color("a4eee5"),2,true)
		for i in points.size():
			var active: bool = selected and i==model.selected_point
			draw_circle(points[i],8 if active else 5,Color("fdf5da") if selected else Color("80d6cd"))
			draw_circle(points[i],3,Color("375d4b"))
			if selected: draw_string(ThemeDB.fallback_font,points[i]+Vector2(10,-8),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
	if new_start!=null: draw_circle(to_screen(new_start),7,Color.YELLOW)
	for block in model.data.blocks:
		var rect := Rect2(to_screen(Vector2(block[0],block[1])),Vector2(block[2],block[3])*zoom)
		draw_rect(rect,Color(0.95,0.17,0.15,0.5)); draw_rect(rect,Color("ffd6b9"),false,1)
