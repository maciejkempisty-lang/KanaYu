extends Node2D
## All 16 v2 source atlases verified. Coordinates, frame order and timing come from JSON.
@export var world_height := 70.0
@export_range(0.25,2.0,0.05) var walk_speed_scale := 1.0
const DIRECTIONS = ["right","southeast","down","southwest","left","northwest","up","northeast"]
const ROOT = "res://assets/hero/v2/"
var facing := "down"
var sprite := AnimatedSprite2D.new()
var metrics: Dictionary = {}

func _ready() -> void:
	metrics = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"metrics.json"))
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in DIRECTIONS:
		add_atlas(frames,direction,"idle_"+direction)
		add_atlas(frames,"walk_"+direction,"walk_"+direction)
	sprite.sprite_frames = frames
	add_child(sprite)
	face(Vector2.ZERO)
	queue_redraw()

func add_atlas(frames: SpriteFrames, animation: String, resource: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+resource+".json"))
	var sheet: Texture2D = load(ROOT+resource+".png")
	var keys: Array = data.frames.keys()
	keys.sort_custom(func(a,b): return int(a)<int(b))
	var duration := 0.0
	for key in keys: duration += float(data.frames[key].duration)
	frames.add_animation(animation)
	frames.set_animation_speed(animation,duration/float(data.meta.duration_s))
	for key in keys:
		var rect: Dictionary = data.frames[key]
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(rect.x,rect.y,rect.w,rect.h)
		frames.add_frame(animation,frame,float(rect.duration))

func face(velocity: Vector2) -> void:
	var walking := velocity.length() > 0.1
	if walking:
		var sector := posmod(roundi(velocity.angle()/(PI/4.0)),8)
		facing = DIRECTIONS[sector]
	var animation: String = "walk_"+facing if walking else facing
	var source: String = ("walk_" if walking else "idle_")+facing
	var bounds: Dictionary = metrics[source]
	# A fixed calibration per animation avoids trimming each frame (which would erase gait).
	var scale_factor := world_height/float(bounds.height)
	sprite.scale = Vector2.ONE*scale_factor
	sprite.position = Vector2(128-float(bounds.center_x),128-float(bounds.feet_y))*scale_factor
	sprite.speed_scale = walk_speed_scale if walking else 1.0
	sprite.play(animation)

func _draw() -> void:
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.35))
	draw_circle(Vector2.ZERO,12,Color(0.12,0.19,0.12,0.22))
