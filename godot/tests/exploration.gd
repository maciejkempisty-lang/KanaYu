extends SceneTree
const Terrain = preload("res://scripts/terrain.gd")
var failures := 0
var world: Node2D

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	world = load("res://scenes/village.tscn").instantiate()
	world.journal_path = "/private/tmp/kigi-exploration-%d.json" % Time.get_ticks_usec()
	root.add_child(world)
	world.automated = true
	await process_frame
	# All directional sheets load, walking is driven by displacement, not held input.
	for direction in world.visual.DIRECTIONS:
		check(world.visual.sprite.sprite_frames.get_frame_count(direction)==25,"Idle frames: "+direction)
		check(world.visual.sprite.sprite_frames.get_frame_count("walk_"+direction)==25,"Walk frames: "+direction)
		check(world.visual.sprite.sprite_frames.get_frame_texture("walk_"+direction,0).atlas!=null,"Walk texture: "+direction)
	world.automatic_direction = Vector2.RIGHT
	world._process(0.1)
	check(world.visual.sprite.animation=="walk_right","Walking uses real displacement")
	world.automatic_direction = Vector2.ZERO
	world._process(0.1)
	check(world.visual.sprite.animation=="right","Idle preserves facing after stop")
	world.automatic_direction = Vector2.LEFT
	for i in 30: world._process(0.1)
	check(not str(world.visual.sprite.animation).begins_with("walk_"),"Blocked movement returns to idle")
	world.automatic_direction = Vector2.ZERO
	world.hero.position = Vector2(415,1250)
	# Every route center must remain navigable with the real footprint, including joins.
	for route in Terrain.ROUTES:
		for i in range(route.size()-1):
			var a := Vector2(route[i][0],route[i][1])
			var b := Vector2(route[i+1][0],route[i+1][1])
			var p := a
			for step in 200:
				if p.distance_to(b)<0.1: break
				p = Terrain.move(p,(b-p).limit_length(2))
			check(p.distance_to(b)<0.1,"Blocked route: %s -> %s stopped at %s" % [a,b,p])
	for point in [Vector2(780,750),Vector2(400,560),Vector2(500,390),Vector2(280,1140),Vector2(732,1170),Vector2(830,700)]:
		check(not Terrain.can_stand(point),"Obstacle open: %s" % point)
	check(Terrain.move(Vector2(415,1250),Vector2(-1000,0)).x>390,"Tunnelling through mailbox")
	check(absf(70.0*world.camera.zoom.y/844.0-0.1493)<0.01,"Phone scale")
	# Touch ownership, release and focus-loss reset must not leave the avatar walking.
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.position = Vector2(80,90)
	touch.pressed = true
	world.stick._gui_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = Vector2(128,90)
	world.stick._gui_input(drag)
	check(world.stick.vector.x > 0.99, "Touch drag missing")
	touch.pressed = false
	world.stick._gui_input(touch)
	check(world.stick.vector == Vector2.ZERO, "Touch release stuck")
	world.stick.update_vector(Vector2(40,0))
	world.stick._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(world.stick.vector == Vector2.ZERO, "Focus-loss stuck")
	# Exercise the same live controller, not teleport between route checkpoints.
	# Follow the current saved paths; the editor can legitimately move old checkpoints.
	for route in Terrain.ROUTES:
		world.hero.position = Vector2(route[0][0],route[0][1])
		for target in route:
			var destination := Vector2(target[0],target[1])
			for frame in 500:
				if world.hero.position.distance_to(destination)<1: break
				world.automatic_direction = (destination-world.hero.position).normalized()
				world._process(1.0/120.0)
			check(world.hero.position.distance_to(destination)<1,"Live controller failed: %s" % destination)
	for foreground in world.foregrounds:
		var polygon: Polygon2D = foreground.node
		check(polygon.texture.get_size()==Vector2(2560,3840),"Foreground uses detailed map")
		for i in polygon.polygon.size():
			check(polygon.uv[i].is_equal_approx(polygon.polygon[i]*2.5),"Foreground UV matches map density")
	world.automatic_direction = Vector2.ZERO
	for screen in [Vector2i(390,844),Vector2i(768,1024),Vector2i(1024,768)]:
		root.size = screen
		world._resize()
		var half_view: Vector2 = Vector2(screen)/world.camera.zoom/2.0
		for corner in [Vector2(0,0),Vector2(1024,1536)]:
			world.camera.position = corner
			world.camera.reset_smoothing()
			world.camera.force_update_scroll()
			var center: Vector2 = world.camera.get_screen_center_position()
			check(center.x >= half_view.x-1 and center.y >= half_view.y-1, "Camera exposes top/left")
			check(center.x <= 1024-half_view.x+1 and center.y <= 1536-half_view.y+1, "Camera exposes bottom/right")
	print("EXPLORATION TESTS: ", "PASS" if failures==0 else "FAIL (%d)" % failures)
	if "--capture" in OS.get_cmdline_user_args():
		for size in [Vector2i(390,844),Vector2i(768,1024)]:
			root.size = size
			await process_frame
			for place in {"tree":Vector2(415,1250),"school":Vector2(444,679),"bridge":Vector2(730,884),"workshop":Vector2(551,310),"canopy":Vector2(365,889)}:
				var positions = {"tree":Vector2(415,1250),"school":Vector2(444,679),"bridge":Vector2(730,884),"workshop":Vector2(551,310),"canopy":Vector2(365,889)}
				world.hero.position = positions[place]
				world.visual.sprite.play("down")
				world._process(0)
				world.camera.reset_smoothing()
				await process_frame
				await RenderingServer.frame_post_draw
				var path := "res://captures/%s-%d.png" % [place,size.x]
				root.get_texture().get_image().save_png(path)
				print("CAPTURE ",path)
	quit(failures)
