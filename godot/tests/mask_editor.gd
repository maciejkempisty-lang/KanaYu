extends SceneTree
const Masks = preload("res://scripts/masks.gd")
const Model = preload("res://scripts/editor/mask_model.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var path := "/private/tmp/kigi-masks-%d.json" % Time.get_ticks_usec()
	var source = Masks.read_data(Masks.DATA_PATH)
	check(source!=null,"Existing masks validate")
	if source==null: quit(1); return
	check(Masks.save_masks(source,path,""),"Seed temporary masks")
	var model := Model.new(path)
	var stale := Model.new(path)
	model.selected_point=0
	model.begin_change(); model.move_point(Vector2(600,808)); model.finish_change()
	check(model.data.routes[0].points[0]==[600.0,808.0],"Move mask vertex")
	model.undo(); check(model.data==source,"Undo vertex")
	model.redo(); check(model.dirty(),"Redo vertex")
	model.editing_region=true; model.selected_point=0
	model.begin_change(); model.move_point(Vector2(601,801)); model.finish_change()
	check(model.data.routes[0].region[0]==[601.0,801.0],"Move activation region separately")
	check(model.save(),"Save masks: "+Masks.last_error)
	check(not stale.save(),"Concurrent edits cannot overwrite")
	check(FileAccess.file_exists(path+".bak"),"Backup created")
	var reopened := Model.new(path)
	check(reopened.data==model.data,"Reload preserves both outlines")
	var invalid := model.data.duplicate(true)
	invalid.routes[0].points=[[0,0],[100,100],[0,100],[100,0]]
	check(not Masks.save_masks(invalid,path,FileAccess.get_sha256(path)),"Reject self intersection")
	check(Masks.read_data(path)==model.data,"Invalid save preserves file")
	root.size=Vector2i(1200,900)
	var editor=preload("res://scripts/editor/mask_editor.gd").new()
	editor.target_path=path
	root.add_child(editor)
	await process_frame
	await process_frame
	var canvas=editor.canvas
	canvas.zoom_at(canvas.size/2,1.5)
	var point=canvas.to_screen(Vector2(600,808))
	var press := InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=point
	canvas._gui_input(press)
	var motion := InputEventMouseMotion.new(); motion.position=point+Vector2(2,0)*canvas.zoom
	canvas._gui_input(motion)
	press.pressed=false; canvas._gui_input(press)
	check(editor.model.data.routes[0].points[0]==[602.0,808.0],"Actual mouse drag uses world transform")
	editor.model.undo(); editor.refresh()
	var count: int=editor.model.edit_points(0).size()
	var points: Array=editor.model.edit_points(0)
	var a: Array=points[-1]; var b: Array=points[0]
	canvas.insert_near(canvas.to_screen((Vector2(a[0],a[1])+Vector2(b[0],b[1]))/2))
	check(editor.model.edit_points(0).size()==count+1,"Insert on closing edge")
	editor.model.delete_point(); check(editor.model.edit_points(0).size()==count,"Delete inserted point")
	check(editor.save_changes(),"Save from editor")
	editor.model.selected_point=0; editor.model.begin_change(); editor.model.move_point(Vector2(599,808)); editor.model.finish_change()
	editor.request_close(); check(editor.close_dialog.visible,"Unsaved close requires decision")
	editor.close_dialog.hide(); editor.model.undo(); editor.refresh()
	if "--capture" in OS.get_cmdline_user_args():
		canvas.zoom=1.7; canvas.pan=canvas.size/2-Vector2(690,855)*canvas.zoom; canvas.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/mask-editor.png")
		canvas.preview=true; canvas.preview_position=Vector2(730,884); canvas.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/mask-preview.png")
	var mask_count: int=editor.model.data.routes.size()
	editor.new_mask_button.pressed.emit()
	press.pressed=true; press.position=canvas.to_screen(Vector2(500,900))
	canvas._gui_input(press); press.pressed=false; canvas._gui_input(press)
	check(editor.model.data.routes.size()==mask_count+1,"New mask button and map click create mask")
	check(editor.selector.item_count==mask_count+1,"Selector includes new mask")
	check(Model.Masks.validate(editor.model.data).is_empty(),"New mask has valid outlines")
	editor.add_point_button.pressed.emit()
	press.pressed=true; press.position=canvas.to_screen(Vector2(500,860))
	canvas._gui_input(press); press.pressed=false; canvas._gui_input(press)
	check(editor.model.edit_points(editor.model.selected_route).size()==5,"Add point button inserts on selected outline")
	editor.model.editing_region=true
	press.pressed=true; press.position=canvas.to_screen(Vector2(500,900))
	canvas._gui_input(press); press.pressed=false; canvas._gui_input(press)
	check(editor.model.edit_points(editor.model.selected_route).size()==5,"Add point also edits activation region")
	check(editor.save_changes(),"Save added mask and vertices")
	check(Model.new(path).data.routes.size()==mask_count+1,"New mask survives reload")
	editor.delete_mask_button.pressed.emit()
	check(editor.model.data.routes.size()==mask_count,"Delete whole mask")
	editor.model.undo(); editor.refresh()
	check(editor.model.data.routes.size()==mask_count+1,"Undo restores deleted mask")
	editor.model.redo(); editor.refresh()
	check(editor.model.data.routes.size()==mask_count,"Redo removes mask")
	while not editor.model.data.routes.is_empty(): editor.delete_mask_button.pressed.emit()
	check(editor.add_point_button.disabled and editor.delete_mask_button.disabled,"Empty editor disables invalid actions")
	check(editor.save_changes(),"Save empty mask list")
	check(Model.new(path).data.routes.is_empty(),"Reload empty list does not resurrect masks")
	editor.model.undo(); editor.refresh()
	check(editor.model.data.routes.size()==1,"Undo last mask deletion")
	editor.model.redo(); editor.refresh()
	editor.new_mask_button.pressed.emit()
	press.pressed=true; press.position=canvas.to_screen(Vector2(1,1))
	canvas._gui_input(press); press.pressed=false; canvas._gui_input(press)
	check(editor.model.data.routes.size()==1,"Create after deleting all masks")
	check(Model.Masks.validate(editor.model.data).is_empty(),"New mask at map boundary stays inside map")
	editor.finish_close(); await process_frame
	var world=load("res://scenes/village.tscn").instantiate()
	world.journal_path=path+"-journal.json"; root.add_child(world)
	world.automated=true
	await process_frame
	check(world.foregrounds.size()==source.routes.size(),"Game loads persistent masks")
	# User-edited regions need not contain the original bridge checkpoint.
	if not world.foregrounds.is_empty():
		var region: PackedVector2Array=world.foregrounds[0].region
		var triangles := Geometry2D.triangulate_polygon(region)
		world.hero.position=(region[triangles[0]]+region[triangles[1]]+region[triangles[2]])/3
		world._process(0)
		check(world.foregrounds[0].node.visible,"Mask activates inside saved region")
		world.hero.position=Vector2(-100,-100); world._process(0)
		check(not world.foregrounds[0].node.visible,"Mask disables outside saved region")
	world.open_path_editor(); world.path_editor.open_masks()
	await process_frame
	check(world.path_editor.gallery.layer==30,"Masks open above path editor")
	world.path_editor.gallery.request_close(); await process_frame
	check(world.path_editor.gallery==null,"Return to path editor")
	world.path_editor.request_close(); await process_frame
	check(world.path_editor==null,"Return to game")
	world.queue_free()
	await process_frame
	await process_frame
	print("MASK EDITOR: ","PASS" if failures==0 else "FAIL (%d)" % failures)
	quit(failures)
