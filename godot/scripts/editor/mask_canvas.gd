extends "res://scripts/editor/path_canvas.gd"
var preview := false
var tool_mode := ""
var preview_position := Vector2(730,884)
var hero = preload("res://scripts/hero_visual.gd").new()
var overlay := Node2D.new()
func _ready() -> void:
	super._ready()
	add_child(hero)
	add_child(overlay)
	overlay.draw.connect(draw_foreground)
	hero.visible=false
func _gui_input(event: InputEvent) -> void:
	if not tool_mode.is_empty() and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		if tool_mode=="create":
			model.add_mask(to_world(event.position)); tool_mode=""
		else: insert_near(event.position)
		selection_changed.emit(); edited.emit(); queue_redraw(); accept_event(); return
	if preview and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		preview_position=to_world(event.position).clamp(Vector2.ZERO,Vector2(1024,1536))
		queue_redraw(); accept_event(); return
	if preview and event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		preview_position=to_world(event.position).clamp(Vector2.ZERO,Vector2(1024,1536))
		queue_redraw(); accept_event(); return
	super._gui_input(event)
func insert_near(screen: Vector2) -> void:
	var world := to_world(screen)
	var best := 18.0/zoom
	var hit := Vector2i(-1,-1)
	var at := world
	for r in [model.selected_route]:
		if r<0: continue
		var points := points_for(r)
		for i in points.size():
			var next: Array=points[(i+1)%points.size()]
			var p := Geometry2D.get_closest_point_to_segment(world,Vector2(points[i][0],points[i][1]),Vector2(next[0],next[1]))
			if p.distance_to(world)<best: best=p.distance_to(world); hit=Vector2i(r,i); at=p
	if hit.x>=0:
		model.insert_point(hit.x,hit.y,at)
		selection_changed.emit(); edited.emit(); queue_redraw()
func polygon_for(points: Array, screen := true) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points: result.append(to_screen(Vector2(p[0],p[1])) if screen else Vector2(p[0],p[1]))
	return result
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("1e302b"))
	if model==null: return
	draw_texture_rect(background,Rect2(pan,Vector2(1024,1536)*zoom),false)
	hero.visible=preview
	hero.position=to_screen(preview_position); hero.scale=Vector2.ONE*zoom
	overlay.queue_redraw()
	if preview: return
	for r in model.data.routes.size():
		for key in ["points","region"]:
			var points := polygon_for(model.data.routes[r][key])
			var active: bool=r==model.selected_route and (key=="region")==model.editing_region
			var color := Color("ffcc73") if key=="points" else Color("69dafa")
			if not Geometry2D.triangulate_polygon(points).is_empty(): draw_colored_polygon(points,Color(color,0.18 if active else 0.06))
			var line := points.duplicate(); line.append(points[0])
			draw_polyline(line,color,3 if active else 1,true)
			if active:
				for i in points.size():
					draw_circle(points[i],8 if i==model.selected_point else 5,color)
					draw_string(ThemeDB.fallback_font,points[i]+Vector2(10,-8),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
func draw_foreground() -> void:
	if not preview or model==null: return
	for mask in model.data.routes:
		if not Geometry2D.is_point_in_polygon(preview_position,polygon_for(mask.region,false)): continue
		var points := polygon_for(mask.points)
		if Geometry2D.triangulate_polygon(points).is_empty(): continue
		var uv := PackedVector2Array()
		for p in mask.points: uv.append(Vector2(p[0]/1024.0,p[1]/1536.0))
		overlay.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,background)

func pick(screen: Vector2) -> Vector2i:
	if model.data.routes.is_empty(): return Vector2i(-1,-1)
	return super.pick(screen)
