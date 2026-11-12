extends SceneTree
const Hero = preload("res://scripts/hero_visual.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var hero := Hero.new()
	root.add_child(hero)
	var vectors := [Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1),Vector2.UP,Vector2(1,-1)]
	for i in 8:
		var name: String = Hero.DIRECTIONS[i]
		hero.face(vectors[i]*83)
		check(hero.sprite.animation=="walk_"+name,"Walk direction "+name)
		var frame: AtlasTexture = hero.sprite.sprite_frames.get_frame_texture(hero.sprite.animation,0)
		var expected: String = "v2/walk_%s.png" % name
		check(frame.atlas.resource_path.ends_with(expected),"Verified art source "+name)
		hero.face(Vector2.ZERO)
		check(hero.sprite.animation==name,"Stop keeps "+name)
	print("DIRECTIONS: ","PASS (8 walk + 8 idle mappings and actual atlas sources)" if failures==0 else "FAIL")
	quit(failures)
