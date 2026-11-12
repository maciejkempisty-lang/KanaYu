extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures += 1; push_error(message)
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/"+name+".png")
func run() -> void:
	var world = load("res://scenes/village.tscn").instantiate()
	world.journal_path = "/private/tmp/kigi-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(world)
	root.size = Vector2i(390,844)
	await process_frame
	world.hero.position = Vector2(444,679)
	world._process(0)
	world.camera.reset_smoothing()
	await capture("school-zoom-390")
	world.interact()
	await create_timer(0.5).timeout
	check(is_instance_valid(world.school),"School opens natively")
	var interior=world.school
	interior.open_activity("activities")
	await process_frame
	var school = interior.activity
	await capture("school-menu-390")
	school.start_lesson()
	school.play_voice()
	check(school.voice.playing,"Local pronunciation plays")
	await create_timer(2.0).timeout
	await capture("lesson-exposure-390")
	for i in 5: school.advance()
	check(school.model.task().kind=="reading","Reading reached after five exposures")
	await capture("lesson-reading-390")
	var position: Vector2 = world.hero.position
	world.automated = true
	world.automatic_direction = Vector2.RIGHT
	world._process(1)
	check(world.hero.position==position,"Walking paused in lesson")
	school.input.text = "wrong"
	school.submit()
	check(school.model.feedback,"Answer saved before feedback")
	await capture("lesson-feedback-390")
	var guard := 0
	while not school.model.finished and guard<100:
		guard += 1
		if school.model.task().kind!="exposure" and not school.model.feedback:
			school.model.response = school.model.item().reading
			school.model.submit()
		school.advance()
	check(school.model.finished and school.store.lantern_unlocked(),"Native full lesson reward")
	await capture("lesson-complete-390")
	root.size = Vector2i(768,1024)
	school.menu()
	await process_frame
	interior.open_activity("activities")
	await process_frame
	school=interior.activity
	await capture("school-menu-768")
	school.start_lesson([school.store.catalog.kana[0]],"minigame",true)
	school.model.drawing = [[[0.2,0.3,0],[0.7,0.3,200]],[[0.5,0.2,300],[0.5,0.8,700]]]
	school.render_task()
	await capture("lesson-writing-768")
	school.model.lock_drawing()
	school.render_task()
	await capture("lesson-writing-compare-768")
	school.submit(false,true)
	check(school.model.feedback,"Writing self-assessment saved")
	school.close()
	await process_frame
	check(interior.activity==null,"Returns to same classroom")
	interior.door_cooldown=0; interior.request_exit()
	await create_timer(0.5).timeout
	check(world.school==null,"Returns to same village")
	world.automatic_direction = Vector2.ZERO
	root.size = Vector2i(390,844)
	world.hero.position = Vector2(415,1250)
	world._process(0)
	world.camera.reset_smoothing()
	await capture("tree-zoom-390")
	print("NATIVE SCHOOL UI: ", "PASS" if failures==0 else "FAIL")
	quit(failures)
