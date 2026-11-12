extends Control
var vector := Vector2.ZERO
var finger := -1
var origin := Vector2.ZERO
var knob := Vector2.ZERO

func center() -> Vector2:
	return Vector2(80,size.y-93)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			origin = event.position
		elif event.index == finger:
			reset()
		accept_event()
	elif event is InputEventScreenDrag and event.index == finger:
		update_vector(event.position-origin)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			finger = -2
			origin = event.position
		else: reset()
	elif event is InputEventMouseMotion and finger == -2:
		update_vector(event.position-origin)

func update_vector(delta: Vector2) -> void:
	knob = delta.limit_length(48)
	vector = knob/48.0 if knob.length()>6 else Vector2.ZERO
	queue_redraw()

func reset() -> void:
	finger = -1
	knob = Vector2.ZERO
	vector = Vector2.ZERO
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset()

func _draw() -> void:
	draw_circle(center(),59,Color(0.12,0.21,0.18,0.55))
	draw_arc(center(),59,0,TAU,64,Color(0.95,0.90,0.72,0.65),2,true)
	draw_circle(center()+knob,24,Color(0.96,0.91,0.74,0.85))
