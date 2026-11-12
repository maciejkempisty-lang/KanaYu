extends SceneTree
const Store=preload("res://scripts/learning/store.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func capture(room, label: String) -> void:
	room._process(0); room.camera.reset_smoothing(); room.camera.force_update_scroll()
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/interior-"+label+".png")
func run() -> void:
	root.size=Vector2i(390,844)
	var world=load("res://scenes/village.tscn").instantiate()
	world.journal_path="/private/tmp/kigi-interior-%d.json" % Time.get_ticks_usec()
	root.add_child(world); world.automated=true
	await process_frame
	world.hero.position=Vector2(444,679); world._process(0)
	var before: Vector2=world.hero.position
	world.interact()
	await create_timer(0.6).timeout
	var room=world.school
	check(is_instance_valid(room),"Enter school scene")
	if not is_instance_valid(room): quit(1); return
	room.automated=true
	check(room.store==world.learning_store,"Shared learning store")
	check(room.visual.facing=="up","Enter facing into classroom")
	check(room.space.can_stand(room.hero.position),"Spawn on free floor")
	check(room.camera.zoom==world.camera.zoom,"Matching phone hero scale")
	check(not world.visible and not world.is_processing(),"Village hidden and frozen")
	if "--capture" in OS.get_cmdline_user_args(): await capture(room,"entrance-390")
	# Flood actual floor with the same five-point footprint and collision-safe moves.
	var origin: Vector2=room.hero.position
	var frontier: Array[Vector2]=[origin]
	var came := {origin:origin}
	var cursor := 0
	while cursor<frontier.size():
		var p: Vector2=frontier[cursor]; cursor+=1
		for delta in [Vector2(4,0),Vector2(-4,0),Vector2(0,4),Vector2(0,-4)]:
			var q: Vector2=p+delta
			if came.has(q) or not room.space.can_stand(q): continue
			if room.space.move(p,delta).distance_to(q)>0.1: continue
			came[q]=p; frontier.append(q)
	for station in room.space.stations:
		check(room.space.can_stand(station.point),"Station has free approach: "+station.id)
		var nearest: Vector2=origin
		for p in frontier:
			if p.distance_to(station.point)<nearest.distance_to(station.point): nearest=p
		check(nearest.distance_to(station.point)<5,"Reachable floor: "+station.id+" gap="+str(nearest.distance_to(station.point)))
		var path: Array[Vector2]=[nearest]
		while path[-1]!=origin: path.append(came[path[-1]])
		path.reverse(); room.hero.position=origin
		for point in path:
			for i in 20:
				if room.hero.position.distance_to(point)<0.6: break
				room.automatic_direction=(point-room.hero.position).normalized(); room._process(1.0/120)
			check(room.hero.position.distance_to(point)<0.7,"Real movement follows free floor")
		room.automatic_direction=Vector2.ZERO; room._process(0)
		check(room.current_station==station.id,"Correct station trigger: "+station.id+" got "+room.current_station)
		if station.id=="exit": continue
		var position: Vector2=room.hero.position
		room.interact(); await process_frame
		check(is_instance_valid(room.activity),"Station opens screen: "+station.id)
		if not is_instance_valid(room.activity): continue
		var expected: String={"first":"lesson","reading":"unavailable","writing":"unavailable","measurement":"unavailable","notebook":"notebook","journal":"journal"}[station.id]
		# First exposures may create cards, but they are not yet due.
		check(room.activity.page==expected,"Correct activity: "+station.id+" got "+room.activity.page)
		room.automatic_direction=Vector2.RIGHT; room._process(1)
		check(room.hero.position==position,"Movement blocked during activity")
		room.automatic_direction=Vector2.ZERO
		if station.id=="first":
			var guard := 0
			while not room.activity.model.finished and guard<100:
				guard+=1
				if room.activity.model.task().kind!="exposure" and not room.activity.model.feedback:
					room.activity.model.response=room.activity.model.item().reading
					room.activity.model.submit()
				room.activity.advance()
			check(room.store.lantern_unlocked(),"Completed lesson retains original reward")
			room.activity.menu()
		else: room.activity.close()
		await process_frame
		check(room.hero.position==position and room.activity==null,"Return to same station")
	# Source texture remains byte-for-byte delivery; bounds remain filled on phone/tablet.
	for screen in [Vector2i(390,844),Vector2i(768,1024),Vector2i(1024,768)]:
		root.size=screen; await process_frame; room.resize_view()
		var half: Vector2=Vector2(screen)/room.camera.zoom/2
		for corner in [Vector2.ZERO,room.space.size]:
			room.camera.position=corner; room.camera.reset_smoothing(); room.camera.force_update_scroll()
			var center: Vector2=room.camera.get_screen_center_position()
			check(center.x>=half.x-1 and center.y>=half.y-1 and center.x<=room.space.size.x-half.x+1 and center.y<=room.space.size.y-half.y+1,"Camera respects artwork bounds")
		if "--capture" in OS.get_cmdline_user_args() and screen.x!=1024:
			for item in {"entrance":room.space.point(room.space.data.spawn),"boards":room.space.point([715,795]),"writing":room.space.point([880,780])}:
				room.hero.position={"entrance":room.space.point(room.space.data.spawn),"boards":room.space.point([715,795]),"writing":room.space.point([880,780])}[item]
				room.visual.facing="up"; room.visual.face(Vector2.ZERO)
				await capture(room,item+"-"+str(screen.x))
	room.open_activity("activities"); await process_frame
	check(room.activity.page=="menu","Accessible activity list")
	room.activity.close(); await process_frame
	for cycle in 3:
		room.door_cooldown=0; room.request_exit()
		await create_timer(0.5).timeout
		check(world.school==null and world.visible,"Return to village")
		check(world.hero.position==before and world.visual.facing=="down","Return at door facing out")
		await create_timer(0.1).timeout
		check(world.school==null,"No automatic re-entry")
		world._process(0); world.interact(); await create_timer(0.5).timeout
		room=world.school; room.automated=true
		check(room.store==world.learning_store,"Store preserved across repeated trips")
	# Exercise nonempty scheduled queues using real isolated stores and the original model.
	var main_store=room.store
	for kind in ["reading","writing","measurement"]:
		var clock_state := {"now":1800000000.0}
		var scheduled=Store.new(world.journal_path+"-"+kind)
		scheduled.clock=func(): return clock_state.now
		scheduled.initialize()
		var kana: Dictionary=scheduled.catalog.kana[0]
		if kind=="measurement": scheduled.expose(kana)
		elif kind=="writing":
			var drawing := [[[0.1,0.2,0],[0.4,0.5,100]]]
			scheduled.commit_drawing(kana,"school-writing",drawing,clock_state.now,"minigame")
			scheduled.answer(kana,{"strokes":drawing},clock_state.now,{"skill":"kana_writing","mode":"drawing","grading":"self","self_correct":true,"attempt_id":"school-writing"})
		else: scheduled.answer(kana,kana.reading,clock_state.now)
		clock_state.now+=(7 if kind=="measurement" else 31)*86400
		scheduled.ensure_session()
		room.store=scheduled; room.open_activity(kind); await process_frame
		check(room.activity.page=="lesson","Due station starts exercise: "+kind)
		if room.activity.page=="lesson":
			check(room.activity.model.task().kind==("writing" if kind=="writing" else "reading"),"Station selects correct skill: "+kind)
			check(room.activity.model.task().source==("measurement" if kind=="measurement" else "scheduled_review"),"Station preserves scheduling rules: "+kind)
		room.activity.close(); await process_frame
	room.store=main_store
	# Existing touch ownership and collision footprint are reused in this scene.
	var touch := InputEventScreenTouch.new(); touch.index=3; touch.position=Vector2(50,80); touch.pressed=true
	room.stick._gui_input(touch)
	var drag := InputEventScreenDrag.new(); drag.index=3; drag.position=Vector2(100,80)
	room.stick._gui_input(drag); check(room.stick.vector.x>0.9,"Interior touch joystick responds")
	touch.pressed=false; room.stick._gui_input(touch); check(room.stick.vector==Vector2.ZERO,"Interior touch releases")
	for item in room.foregrounds:
		var triangle := Geometry2D.triangulate_polygon(item.region)
		room.hero.position=(item.region[triangle[0]]+item.region[triangle[1]]+item.region[triangle[2]])/3
		room.update_state(); check(item.node.visible,"Foreground activates in its own ground region")
		room.hero.position=Vector2(-100,-100); room.update_state(); check(not item.node.visible,"Foreground disables outside ground region")
	var stored_events: int=world.learning_store.events.size()
	check(stored_events>0,"Exercises kept their journal")
	var reloaded=Store.new(world.journal_path); reloaded.initialize()
	check(reloaded.events.size()>=stored_events and reloaded.lantern_unlocked() and reloaded.introduced.size()==10,"Journal reload preserves progress")
	world.queue_free(); await process_frame; await process_frame
	print("SCHOOL INTERIOR: ","PASS" if failures==0 else "FAIL (%d)" % failures)
	quit(failures)
