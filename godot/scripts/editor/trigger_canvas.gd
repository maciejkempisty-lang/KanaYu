extends "res://scripts/editor/path_canvas.gd"
func insert_near(_screen: Vector2) -> void: pass
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("1e302b"))
	if model==null: return
	draw_texture_rect(background,Rect2(pan,Vector2(1024,1536)*zoom),false)
	for i in model.data.routes.size():
		var item: Dictionary=model.data.routes[i]
		var center := to_screen(Vector2(item.points[0][0],item.points[0][1]))
		var color := Color("ffcc73") if i==model.selected_route else Color("69dafa")
		draw_circle(center,item.radius*zoom,Color(color,0.2))
		draw_arc(center,item.radius*zoom,0,TAU,80,color,2,true)
		draw_circle(center,7,color)
		draw_string(ThemeDB.fallback_font,center+Vector2(12,-12),item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
