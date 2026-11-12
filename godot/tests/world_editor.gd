extends SceneTree
const Terrain=preload("res://scripts/terrain.gd")
const Triggers=preload("res://scripts/triggers.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func click(canvas, p: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true; event.position=canvas.to_screen(p)
	canvas._gui_input(event); event.pressed=false; canvas._gui_input(event)
func run() -> void:
	root.size=Vector2i(1200,900)
	var path := "/private/tmp/kigi-world-editor-%d.json" % Time.get_ticks_usec()
	var original := Terrain.snapshot()
	check(Terrain.save_paths(original,path,""),"Seed temporary paths")
	var editor=preload("res://scripts/editor/path_editor.gd").new()
	editor.target_path=path; root.add_child(editor)
	await process_frame; await process_frame
	var count: int=editor.model.data.routes.size()
	editor.new_path_button.pressed.emit()
	click(editor.canvas,Vector2(500,1000)); click(editor.canvas,Vector2(600,1000)); click(editor.canvas,Vector2(650,1100))
	check(editor.model.data.routes.size()==count+1,"Create path by clicks")
	check(editor.model.data.routes[-1].points.size()==3,"Continue drawing")
	editor.append_button.pressed.emit()
	editor.add_point_button.pressed.emit(); click(editor.canvas,Vector2(550,1000))
	check(editor.model.data.routes[-1].points.size()==4,"Insert point into selected segment")
	editor.set_path_tool("point")
	editor.width_input.value=60
	editor.name_input.text_submitted.emit("Nowa alejka")
	check(editor.model.data.routes[-1].name=="Nowa alejka","Rename path")
	check(editor.save_changes(),"Save path")
	check(Terrain.can_stand(Vector2(550,1000)),"Saved path changes movement corridors")
	var reopen=preload("res://scripts/editor/path_model.gd").new(path)
	check(reopen.data.routes[-1].radius==30 and reopen.data.routes[-1].points.size()==4,"Reload path geometry and width")
	for i in 6: editor.model.undo(); editor.refresh()
	check(editor.model.selected_route<editor.model.data.routes.size(),"Undo creation keeps valid selection")
	editor.open_triggers(); await process_frame
	check(is_instance_valid(editor.gallery),"Trigger editor opens in same window")
	editor.gallery.request_close(); await process_frame
	editor.finish_close(); await process_frame
	Terrain.apply_data(original)
	var trigger_path := path+"-triggers.json"
	check(Triggers.save_triggers(Triggers.read_data(Triggers.DATA_PATH),trigger_path,""),"Seed triggers")
	var trigger=preload("res://scripts/editor/trigger_editor.gd").new()
	trigger.target_path=trigger_path; root.add_child(trigger)
	await process_frame; await process_frame
	trigger.model.selected_route=1; trigger.refresh()
	var a=trigger.canvas.to_screen(Vector2(444,679))
	var event := InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true; event.position=a
	trigger.canvas._gui_input(event)
	var motion := InputEventMouseMotion.new(); motion.position=trigger.canvas.to_screen(Vector2(550,727))
	trigger.canvas._gui_input(motion); event.pressed=false; trigger.canvas._gui_input(event)
	trigger.width_input.value=40
	check(trigger.model.data.routes[1].points[0]==[550.0,727.0],"Drag school trigger")
	check(trigger.save_changes(),"Save school trigger")
	check(Triggers.location_at(trigger.model.data,Vector2(550,727))=="school","New center active")
	check(Triggers.location_at(trigger.model.data,Vector2(575,727))=="","Outside edited radius inactive")
	var other=preload("res://scripts/editor/trigger_model.gd").new(trigger_path)
	trigger.model.set_width(42); check(trigger.save_changes(),"Save changed radius")
	check(not other.save(),"Reject stale trigger overwrite")
	trigger.model.undo(); trigger.refresh(); check(trigger.save_changes(),"Undo radius and save")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/trigger-editor.png")
	trigger.finish_close(); await process_frame
	var world=load("res://scenes/village.tscn").instantiate()
	world.triggers_path=trigger_path; world.journal_path=path+"-journal.json"
	root.add_child(world); world.automated=true
	await process_frame
	world.hero.position=Vector2(444,679); world._process(0)
	check(world.current_location!="school","Old school center no longer active")
	world.hero.position=Vector2(550,727); world._process(0)
	check(world.current_location=="school","Game loads moved school trigger")
	world.interact(); await create_timer(0.5).timeout
	check(is_instance_valid(world.school),"Moved trigger opens school interior")
	world.school.open_activity("first"); await process_frame
	check(world.school.activity.page=="lesson","Interior opens native lessons")
	world.queue_free(); await process_frame; await process_frame
	print("WORLD EDITOR: ","PASS" if failures==0 else "FAIL (%d)" % failures)
	quit(failures)
