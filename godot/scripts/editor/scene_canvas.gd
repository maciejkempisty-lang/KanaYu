extends "res://scripts/editor/mask_canvas.gd"
var creating := false
var adding_point := false
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		if creating:
			model.add_object(to_world(event.position)); creating=false
			edited.emit(); selection_changed.emit(); queue_redraw(); accept_event(); return
		if adding_point:
			insert_near(event.position); accept_event(); return
		if preview:
			preview_position=to_world(event.position).clamp(Vector2.ZERO,map_size)
			queue_redraw(); accept_event(); return
	if preview and event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		preview_position=to_world(event.position).clamp(Vector2.ZERO,map_size)
		queue_redraw(); accept_event(); return
	super._gui_input(event)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("1e302b"))
	if model==null: return
	draw_texture_rect(background,Rect2(pan,map_size*zoom),false)
	hero.visible=preview; hero.position=to_screen(preview_position)
	hero.scale=Vector2.ONE*zoom/model.data.world_units_per_pixel
	overlay.queue_redraw()
	if preview: return
	for r in model.data.routes.size():
		var points:=polygon_for(model.data.routes[r].points)
		var color:=Color("ffcc73") if r==model.selected_route else Color("69dafa")
		if points.size()>2:
			if not Geometry2D.triangulate_polygon(points).is_empty(): draw_colored_polygon(points,Color(color,0.18))
			var line:=points.duplicate(); line.append(points[0]); draw_polyline(line,color,2,true)
		if model.mode=="triggers":
			var radius: float=model.data.stations[r].radius_world/model.data.world_units_per_pixel*zoom
			draw_circle(points[0],radius,Color(color,0.15)); draw_arc(points[0],radius,0,TAU,64,color,2,true)
		for i in points.size():
			draw_circle(points[i],7 if r==model.selected_route and i==model.selected_point else 5,color)
			if r==model.selected_route: draw_string(ThemeDB.fallback_font,points[i]+Vector2(8,-8),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
func draw_foreground() -> void:
	if not preview or model==null: return
	for item in model.data.foregrounds:
		if not Geometry2D.is_point_in_polygon(preview_position,polygon_for(item.region,false)): continue
		var points:=polygon_for(item.polygon)
		if Geometry2D.triangulate_polygon(points).is_empty(): continue
		var uv:=PackedVector2Array()
		for p in item.polygon: uv.append(Vector2(p[0],p[1])/map_size)
		overlay.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,background)
