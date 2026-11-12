extends Control
signal changed
var strokes: Array = []
var reference: Array = []
var writable := false
var animate_reference := false
var replay_drawing := false
var active_pointer := -1
var began := 0
var phase := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0,240)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if animate_reference or replay_drawing:
		phase = fmod(phase+delta,5.0)
		queue_redraw()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: active_pointer = -1

func _gui_input(event: InputEvent) -> void:
	if not writable: return
	if event is InputEventScreenTouch:
		if event.pressed and active_pointer==-1:
			active_pointer = event.index
			_begin(event.position)
		elif not event.pressed and active_pointer==event.index: active_pointer = -1
		accept_event()
	elif event is InputEventScreenDrag and event.index==active_pointer:
		_point(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and active_pointer==-1:
			active_pointer = -2
			_begin(event.position)
		elif not event.pressed and active_pointer==-2: active_pointer = -1
		accept_event()
	elif event is InputEventMouseMotion and active_pointer==-2:
		_point(event.position)
		accept_event()

func square() -> Rect2:
	var side := minf(size.x,size.y)
	return Rect2((size-Vector2.ONE*side)/2,Vector2.ONE*side)

func _begin(p: Vector2) -> void:
	if strokes.is_empty(): began = Time.get_ticks_msec()
	strokes.append([])
	_point(p)

func _point(p: Vector2) -> void:
	var rect := square()
	var uv := (p-rect.position)/rect.size
	strokes[-1].append([clampf(uv.x,0,1),clampf(uv.y,0,1),Time.get_ticks_msec()-began])
	changed.emit()
	queue_redraw()

func _draw_paths(paths: Array, color: Color, progress: float) -> void:
	var rect := square()
	var count := 0
	for stroke in paths: count += stroke.size()
	var remaining := int(count*progress)
	for stroke in paths:
		var points := PackedVector2Array()
		for p in stroke:
			if remaining<=0: break
			points.append(rect.position+Vector2(p[0],p[1])*rect.size)
			remaining -= 1
		if points.size()>1: draw_polyline(points,color,5.0,true)
		elif points.size()==1: draw_circle(points[0],2.5,color)

func _draw() -> void:
	var rect := square()
	draw_style_box(_paper(),rect)
	draw_line(rect.position+Vector2(rect.size.x/2,0),rect.position+Vector2(rect.size.x/2,rect.size.y),Color("d9decd"))
	draw_line(rect.position+Vector2(0,rect.size.y/2),rect.position+Vector2(rect.size.x,rect.size.y/2),Color("d9decd"))
	_draw_paths(reference,Color("8b9d84") if not strokes.is_empty() else Color("294b3e"),minf(phase/3.8,1) if animate_reference else 1.0)
	_draw_paths(strokes,Color("925c39"),minf(phase/3.8,1) if replay_drawing else 1.0)

func _paper() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("faf5e6")
	box.set_corner_radius_all(16)
	return box
