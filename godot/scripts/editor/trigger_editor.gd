extends CanvasLayer
signal closed
signal saved
signal quit_requested
const Model = preload("res://scripts/editor/trigger_model.gd")
const Canvas = preload("res://scripts/editor/trigger_canvas.gd")
@export var standalone := false
var target_path := ""
var model
var canvas := Canvas.new()
var selector := OptionButton.new()
var width_input := SpinBox.new()
var status := Label.new()
var point_label := Label.new()
var undo_button: Button
var redo_button: Button
var delete_button: Button
var save_button: Button
var name_input := LineEdit.new()
var close_dialog := ConfirmationDialog.new()
var pending_quit := false
var syncing := false
var gallery = null

func _ready() -> void:
	layer = 30
	model = Model.new(target_path)
	canvas.model = model
	var root := PanelContainer.new()
	var theme := Theme.new()
	var font := FontVariation.new()
	font.base_font=preload("res://assets/Nunito.ttf")
	font.variation_embolden=0.4
	theme.default_font=font
	root.theme=theme
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("253e34")
	style.content_margin_left = 12; style.content_margin_right = 12
	style.content_margin_top = 10; style.content_margin_bottom = 10
	root.add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	root.add_child(column)
	var title := Label.new()
	title.text = "KIGI / MIEJSCA INTERAKCJI"
	title.add_theme_font_size_override("font_size",22)
	column.add_child(title)
	var tools := HFlowContainer.new()
	tools.add_theme_constant_override("h_separation",8)
	tools.add_theme_constant_override("v_separation",6)
	column.add_child(tools)
	selector.custom_minimum_size = Vector2(215,38)
	for route in model.data.routes: selector.add_item(route.name)
	selector.item_selected.connect(func(index): model.selected_route=index; model.selected_point=-1; refresh())
	tools.add_child(selector)
	name_input.custom_minimum_size=Vector2(170,38)
	name_input.placeholder_text="Nazwa miejsca"
	name_input.text_submitted.connect(func(value): model.rename_route(value); refresh())
	name_input.focus_exited.connect(func(): model.rename_route(name_input.text); refresh())
	tools.add_child(name_input)
	var width_box := HBoxContainer.new()
	tools.add_child(width_box)
	var label := Label.new(); label.text="Średnica: "; width_box.add_child(label)
	width_input.min_value=16; width_input.max_value=240; width_input.step=1
	width_input.custom_minimum_size=Vector2(90,38)
	width_input.value_changed.connect(func(value):
		if not syncing: model.set_width(value); refresh())
	width_box.add_child(width_input)
	button(tools,"−",func(): canvas.zoom_at(canvas.size/2,1/1.2))
	button(tools,"+",func(): canvas.zoom_at(canvas.size/2,1.2))
	button(tools,"Cała mapa",canvas.fit_map)
	undo_button=button(tools,"Cofnij",func(): model.undo(); refresh())
	redo_button=button(tools,"Ponów",func(): model.redo(); refresh())
	save_button=button(tools,"Zapisz",save_changes)
	button(tools,"Zapisz i wróć",func():
		if save_changes(): finish_close())
	button(tools,"Zamknij",request_close)
	var help := Label.new()
	help.text="Przeciągnij środek koła • Średnica: zasięg interakcji • kółko: zoom • Ctrl/Cmd+Z: cofnij"
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size",13)
	column.add_child(help)
	point_label.add_theme_font_size_override("font_size",14)
	column.add_child(point_label)
	canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size.y=160
	column.add_child(canvas)
	canvas.edited.connect(refresh)
	canvas.selection_changed.connect(refresh)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size",14)
	column.add_child(status)
	root.add_child(close_dialog)
	close_dialog.title="Niezapisane zmiany"
	close_dialog.dialog_text="Zmiany miejsc interakcji nie zostały zapisane."
	close_dialog.ok_button_text="Odrzuć i zamknij"
	close_dialog.cancel_button_text="Wróć do edycji"
	close_dialog.confirmed.connect(finish_close)
	if standalone: get_tree().auto_accept_quit=false
	status.text="Koło wyznacza miejsce pojawienia się przycisku interakcji. Szkoła nadal otwiera lekcje. Przy nakładaniu kół wybierane jest najbliższe miejsce."
	refresh()

func button(parent: Control,text: String,action: Callable) -> Button:
	var node := Button.new()
	node.text=text; node.custom_minimum_size.y=38
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func refresh() -> void:
	syncing=true
	selector.clear()
	for route in model.data.routes: selector.add_item(route.name)
	selector.select(model.selected_route)
	if not name_input.has_focus(): name_input.text=model.data.routes[model.selected_route].name
	width_input.value=model.data.routes[model.selected_route].radius*2
	syncing=false
	point_label.text=("● Niezapisane zmiany" if model.dirty() else "Zapis aktualny")+"  |  "+model.data.routes[model.selected_route].name
	if model.selected_point>=0:
		var p: Array=model.data.routes[model.selected_route].points[model.selected_point]
		point_label.text+="  |  punkt %d: %.0f, %.0f" % [model.selected_point,p[0],p[1]]
	undo_button.disabled=model.undo_stack.is_empty()
	redo_button.disabled=model.redo_stack.is_empty()
	canvas.queue_redraw()

func save_changes() -> bool:
	canvas.finish_drag()
	if not model.save(): status.text=Model.Triggers.last_error; return false
	status.text="Zapisano triggery. Wróć do gry, aby je zastosować." if model.path.begins_with("res://") else "Zapisano triggery na urządzeniu."
	refresh()
	saved.emit()
	return true

func request_close() -> void:
	if is_instance_valid(gallery):
		if gallery.has_method("request_close"): gallery.request_close()
		return
	canvas.finish_drag()
	if model.dirty(): close_dialog.popup_centered(Vector2i(340,160))
	else: finish_close()

func finish_close() -> void:
	closed.emit()
	if pending_quit: quit_requested.emit()
	if standalone: get_tree().quit()
	else: queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(gallery): return
	if not event is InputEventKey or not event.pressed or event.echo: return
	var shortcut: bool=event.ctrl_pressed or event.meta_pressed
	if shortcut and event.keycode==KEY_S: save_changes()
	elif shortcut and event.keycode==KEY_Z:
		if event.shift_pressed: model.redo()
		else: model.undo()
		refresh()
	elif event.keycode in [KEY_ESCAPE,KEY_BACKSLASH]: request_close()
	else: return
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if standalone and what==NOTIFICATION_WM_CLOSE_REQUEST: pending_quit=true; request_close()
