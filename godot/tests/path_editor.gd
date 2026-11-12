extends SceneTree
const Terrain = preload("res://scripts/terrain.gd")
const Model = preload("res://scripts/editor/path_model.gd")
var failures := 0
var temp := "/private/tmp/kigi-path-editor-%d.json" % Time.get_ticks_usec()
func check(ok: bool,text: String) -> void:
	if not ok: failures+=1; push_error(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var original := Terrain.snapshot()
	check(Terrain.save_paths(original,temp,""),"Seed temp paths")
	var model := Model.new(temp)
	model.selected_route=0; model.selected_point=13
	model.begin_change(); model.move_point(Vector2(503,795)); model.finish_change()
	check(model.data.routes[1].points[0][0]==503 and model.data.routes[6].points[0][0]==503,"Shared junction moves together")
	check(not Terrain.ROUTES[0][13][0]==503,"Draft does not mutate game")
	model.undo(); check(model.data.routes[0].points[13][0]==498,"Undo restores junction")
	model.redo(); check(model.data.routes[1].points[0][0]==503,"Redo restores junction")
	model.set_width(70)
	check(model.data.routes[0].radius==35,"Full width edits radius")
	check(model.save(),"Save edited data")
	check(Terrain.WIDTHS[0]==35 and Terrain.ROUTES[1][0][0]==503,"Saved data applied to real collisions")
	check(Terrain.load_paths(temp),"Reload saved file")
	check(Terrain.WIDTHS[0]==35,"Restart retains width")
	var reopened := Model.new(temp)
	check(not reopened.dirty() and reopened.data.routes[0].points[13][0]==503,"Editor reopens saved points")
	var before: int=reopened.data.routes[0].points.size()
	reopened.insert_point(0,0,Vector2(220,1450)); check(reopened.data.routes[0].points.size()==before+1,"Insert point")
	reopened.delete_point(); check(reopened.data.routes[0].points.size()==before,"Delete point")
	var clean := Model.new(temp)
	clean.selected_route=4; clean.selected_point=0; clean.delete_point()
	check(clean.data.routes[4].points.size()==2,"Minimum two points")
	check(clean.check_passages().begins_with("Środki"),"Default passages still connected: "+clean.check_passages())
	var invalid: Dictionary=clean.data.duplicate(true)
	invalid.routes[0].points[0]=[-20,0]
	var digest := FileAccess.get_sha256(temp)
	check(not Terrain.save_paths(invalid,temp,digest) and FileAccess.get_sha256(temp)==digest,"Invalid save cannot overwrite")
	clean.set_width(72); check(clean.save(),"Concurrent edit seed")
	model.set_width(74); check(not model.save(),"Stale editor cannot overwrite newer changes")
	check(FileAccess.file_exists(temp+".bak"),"Backup exists")
	Terrain.apply_data(original)
	# Actual native control input uses transformed coordinates (including zoom and pan).
	var editor = preload("res://scripts/editor/path_editor.gd").new()
	editor.target_path=temp
	root.add_child(editor)
	root.size=Vector2i(1100,850)
	await process_frame; await process_frame
	editor.canvas.fit_map()
	editor.model.selected_route=4
	var start: Array=editor.model.data.routes[4].points[1]
	var screen: Vector2=editor.canvas.to_screen(Vector2(start[0],start[1]))
	var press := InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=screen
	editor.canvas._gui_input(press)
	check(editor.canvas.dragging,"Mouse selects actual point")
	var drag := InputEventMouseMotion.new(); drag.position=screen+Vector2(12,0); drag.relative=Vector2(12,0)
	editor.canvas._gui_input(drag)
	press.pressed=false; press.position=drag.position; editor.canvas._gui_input(press)
	check(editor.model.dirty() and editor.model.undo_stack.size()==1,"Drag creates one undo entry")
	check(editor.model.data.routes[4].points[1][0]>start[0],"Drag changes world point")
	editor.model.undo(); editor.refresh()
	editor.width_input.value=42
	check(editor.model.data.routes[4].radius==21,"Width control changes draft")
	check(editor.save_changes(),"UI saves changed width")
	check(Terrain.WIDTHS[4]==21,"Game collision picks up UI save")
	var cursor := Vector2(300,300)
	var fixed: Vector2=editor.canvas.to_world(cursor)
	editor.canvas.zoom_at(cursor,1.5)
	check(editor.canvas.to_world(cursor).distance_to(fixed)<0.01,"Zoom remains under pointer")
	editor.model.set_width(48); editor.request_close()
	check(editor.close_dialog.visible,"Unsaved close requires explicit discard")
	editor.close_dialog.hide()
	editor.model.undo(); editor.refresh()
	if "--capture" in OS.get_cmdline_user_args():
		editor.canvas.fit_map()
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/path-editor.png")
		editor.open_gallery()
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/directions-v2.png")
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/directions-v2-later.png")
	Terrain.apply_data(original)
	editor.queue_free()
	await process_frame
	var world=load("res://scenes/village.tscn").instantiate()
	world.journal_path="/private/tmp/kigi-editor-world-%d.json" % Time.get_ticks_usec()
	root.add_child(world)
	await process_frame
	var key := InputEventKey.new(); key.keycode=KEY_BACKSLASH; key.pressed=true
	world._unhandled_key_input(key)
	check(is_instance_valid(world.path_editor),"Backslash opens editor from village")
	check(is_instance_valid(world.path_editor_window),"Desktop editor opens separate window")
	check(world.path_editor.get_viewport() == world.path_editor_window,"Editor uses its own viewport")
	if DisplayServer.get_name() != "headless":
		check(world.path_editor_window.size.x >= 800 and world.path_editor_window.size.y >= 600,"Editor opens large landscape canvas")
	check(world.path_editor_window.force_native,"Editor escapes embedded phone preview")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		check(world.path_editor.canvas.zoom > 0.3,"Map fills large editor after layout")
		world.path_editor_window.get_texture().get_image().save_png("res://captures/path-editor-window.png")
	var old_position: Vector2=world.hero.position
	world.automated=true; world.automatic_direction=Vector2.RIGHT
	world._process(1)
	check(world.hero.position==old_position,"Editing stops player movement")
	world.path_editor._unhandled_key_input(key)
	await process_frame
	check(world.path_editor==null,"Close returns to game")
	check(world.path_editor_window==null,"Closing editor releases separate window")
	print("PATH EDITOR: ","PASS" if failures==0 else "FAIL (%d)" % failures)
	quit(failures)
