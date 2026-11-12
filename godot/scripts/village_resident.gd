extends Node2D

const DialogueBubble = preload("res://scripts/ui/station_bubble.gd")
const IDLE := [
	"iso_idle_right_right", "iso_idle_southeast_right", "iso_idle_down_right",
	"Idle Southwest", "Idle Left", "Idle Northwest", "iso_idle_up_right",
	"iso_idle_northeast_right",
]
const WAVE := [
	"Wave Right", "Wave Southeast", "Wave Down", "Wave Southwest",
	"Wave Left", "Wave Northwest", "Wave Up", "Wave Northeast",
]

@export_dir var atlas_root := ""
@export_file("*.json") var dialogue_path := ""
@export var greeting_prompt := ""
@export var talk_range := 110.0
@export var wave_range := 150.0
@export var world_height := 66.0
var facing := 2
var sprite := AnimatedSprite2D.new()
var metrics: Dictionary
var dialogue_bubble: DialogueBubble
var lines: Dictionary
var page := -1
var greeted := false

func _ready() -> void:
	lines = JSON.parse_string(FileAccess.get_file_as_string(dialogue_path))
	metrics = JSON.parse_string(FileAccess.get_file_as_string(atlas_root.path_join("metrics.json")))
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation in IDLE + WAVE:
		add_atlas(frames, animation)
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	look_at_player(global_position, false)

func add_atlas(frames: SpriteFrames, animation: String) -> void:
	var folder := atlas_root.path_join(animation) + "/"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "atlas.json"))
	var sheet: Texture2D = load(folder + "spritesheet.png")
	var keys: Array = data.frames.keys()
	keys.sort_custom(func(a, b): return int(a) < int(b))
	var duration := 0.0
	for key in keys:
		duration += float(data.frames[key].duration)
	frames.add_animation(animation)
	frames.set_animation_loop(animation, true)
	frames.set_animation_speed(animation, duration / float(data.meta.duration_s))
	for key in keys:
		var rect: Dictionary = data.frames[key]
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(rect.x, rect.y, rect.w, rect.h)
		frame.filter_clip = true
		frames.add_frame(animation, frame, float(rect.duration))

func look_at_player(player_position: Vector2, waving: bool) -> void:
	var direction := player_position - global_position
	if direction.length_squared() > 0.01:
		facing = posmod(roundi(direction.angle() / (PI / 4.0)), IDLE.size())
	var animation: String = WAVE[facing] if waving else IDLE[facing]
	if sprite.animation == animation:
		return
	var bounds: Dictionary = metrics[animation]
	var ratio := world_height / float(bounds.height)
	sprite.scale = Vector2.ONE * ratio
	sprite.position = Vector2(128.0 - float(bounds.center_x), 128.0 - float(bounds.feet_y)) * ratio
	sprite.play(animation)


func attach_dialogue(hud: Control, advance: Callable) -> void:
	var bubble := DialogueBubble.new()
	bubble.settings.width = 260
	bubble.settings.font_size = 18
	bubble.activated.connect(advance)
	hud.add_child(bubble)
	dialogue_bubble = bubble

func update_dialogue(player_position: Vector2, available: bool) -> bool:
	var distance := global_position.distance_to(player_position)
	look_at_player(player_position, available and not greeted and page < 0 and distance <= wave_range)
	if not available or (page < 0 and distance > talk_range):
		dialogue_bubble.hide()
		return false
	var text := greeting_prompt
	var action_name := "Porozmawiaj"
	if page >= 0:
		var pages := dialogue_pages()
		text = pages[page]
		action_name = "Dalej" if page + 1 < pages.size() else "Zakończ rozmowę"
	return show_dialogue(text, action_name)

func dialogue_pages() -> Array:
	return lines.returning if greeted else lines.greeting

func advance_dialogue() -> void:
	page += 1
	if page >= dialogue_pages().size():
		page = -1
		greeted = true

func show_dialogue(text: String, action_name: String) -> bool:
	var viewport_size := get_viewport_rect().size
	var head := get_global_transform_with_canvas() * Vector2(0, -world_height)
	if not Rect2(Vector2.ZERO, viewport_size).has_point(head):
		dialogue_bubble.hide()
		return false
	dialogue_bubble.set_message(text, action_name)
	dialogue_bubble.arrange(viewport_size, 8.0, head)
	return dialogue_bubble.visible
