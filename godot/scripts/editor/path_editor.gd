extends CanvasLayer
signal closed
signal saved
signal quit_requested
const Model = preload("res://scripts/editor/path_model.gd")
const Canvas = preload("res://scripts/editor/path_canvas.gd")
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
var new_path_button: Button
var add_point_button: Button
var append_button: Button
var close_dialog := ConfirmationDialog.new()
var pending_quit := false
var syncing := false
var gallery = null

func _ready() -> void:
	layer = 20
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
	title.text = "KIGI / EDYTOR ŚCIEŻEK"
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
	name_input.placeholder_text="Nazwa ścieżki"
	name_input.text_submitted.connect(func(value): model.rename_route(value); refresh())
	name_input.focus_exited.connect(func(): model.rename_route(name_input.text); refresh())
	tools.add_child(name_input)
	new_path_button=button(tools,"Nowa ścieżka",func(): set_path_tool("create"))
	add_point_button=button(tools,"Dodaj punkt",func(): set_path_tool("point"))
	append_button=button(tools,"Przedłuż ścieżkę",func(): set_path_tool("append"))
	var width_box := HBoxContainer.new()
	tools.add_child(width_box)
	var label := Label.new(); label.text="Szerokość: "; width_box.add_child(label)
	width_input.min_value=16; width_input.max_value=240; width_input.step=1
	width_input.custom_minimum_size=Vector2(90,38)
	width_input.value_changed.connect(func(value):
		if not syncing: model.set_width(value); refresh())
	width_box.add_child(width_input)
	button(tools,"−",func(): canvas.zoom_at(canvas.size/2,1/1.2))
	button(tools,"+",func(): canvas.zoom_at(canvas.size/2,1.2))
	button(tools,"Cała mapa",canvas.fit_map)
	button(tools,"Animacje",open_gallery)
	button(tools,"Maski",open_masks)
	button(tools,"Triggery",open_triggers)
	undo_button=button(tools,"Cofnij",func(): model.undo(); refresh())
	redo_button=button(tools,"Ponów",func(): model.redo(); refresh())
	delete_button=button(tools,"Usuń punkt",func(): model.delete_point(); refresh())
	save_button=button(tools,"Zapisz",save_changes)
	button(tools,"Sprawdź przejścia",func(): status.text=model.check_passages())
	button(tools,"Zapisz i wróć",func():
		if save_changes(): finish_close())
	button(tools,"Zamknij",request_close)
	var help := Label.new()
	help.text="Przeciągnij punkt • puste tło: przesuń mapę • kółko: zoom • dwuklik na linii: dodaj punkt • Ctrl/Cmd+Z: cofnij"
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
	close_dialog.dialog_text="Zmiany ścieżek nie zostały zapisane."
	close_dialog.ok_button_text="Odrzuć i zamknij"
	close_dialog.cancel_button_text="Wróć do edycji"
	close_dialog.confirmed.connect(finish_close)
	if standalone: get_tree().auto_accept_quit=false
	status.text="Turkus: ścieżki • złoto: wybrana • czerwień: przeszkody. Wspólne skrzyżowania przesuwają się razem."
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
	new_path_button.disabled=model.data.routes.size()>=100
	new_path_button.text="Kliknij dwa punkty…" if canvas.path_tool=="create" else "Nowa ścieżka"
	add_point_button.text="Dodaj punkt ✓" if canvas.path_tool=="point" else "Dodaj punkt"
	append_button.text="Zakończ przedłużanie" if canvas.path_tool=="append" else "Przedłuż ścieżkę"
	width_input.value=model.data.routes[model.selected_route].radius*2
	syncing=false
	point_label.text=("● Niezapisane zmiany" if model.dirty() else "Zapis aktualny")+"  |  "+model.data.routes[model.selected_route].name
	if model.selected_point>=0:
		var p: Array=model.data.routes[model.selected_route].points[model.selected_point]
		point_label.text+="  |  punkt %d: %.0f, %.0f" % [model.selected_point,p[0],p[1]]
	undo_button.disabled=model.undo_stack.is_empty()
	redo_button.disabled=model.redo_stack.is_empty()
	delete_button.disabled=model.selected_point<0 or model.data.routes[model.selected_route].points.size()<=2
	canvas.queue_redraw()

func save_changes() -> bool:
	canvas.finish_drag()
	if not model.save(): status.text=Model.Terrain.last_error; return false
	status.text="Zapisano ścieżki do projektu. Gra korzysta już z nowych przejść." if model.path.begins_with("res://") else "Zapisano ścieżki na tym urządzeniu. Gra korzysta już z nowych przejść."
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
	elif event.keycode==KEY_DELETE or event.keycode==KEY_BACKSPACE: model.delete_point(); refresh()
	elif event.keycode in [KEY_ESCAPE,KEY_BACKSLASH]: request_close()
	else: return
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if standalone and what==NOTIFICATION_WM_CLOSE_REQUEST: pending_quit=true; request_close()

func open_gallery() -> void:
	if is_instance_valid(gallery): return
	gallery=preload("res://scripts/editor/animation_gallery.gd").new()
	gallery.closed.connect(func(): gallery=null)
	add_child(gallery)

func open_masks() -> void:
	if is_instance_valid(gallery): return
	canvas.finish_drag()
	gallery=preload("res://scripts/editor/mask_editor.gd").new()
	gallery.saved.connect(func(): saved.emit())
	gallery.layer=30
	gallery.closed.connect(func(): gallery=null)
	add_child(gallery)

func set_path_tool(tool: String) -> void:
	canvas.finish_drag(); canvas.new_start=null
	canvas.path_tool="" if canvas.path_tool==tool else tool
	status.text="Nowa ścieżka: kliknij początek i drugi punkt, potem kolejne punkty. Przedłuż ścieżkę kończy rysowanie." if tool=="create" else ("Klikaj linię wybranej ścieżki, aby dodawać punkty." if tool=="point" else "Klikaj kolejne punkty. Wybierz pierwszy punkt, aby przedłużać od początku; w innym przypadku przedłużasz koniec.")
	refresh()

func open_triggers() -> void:
	if is_instance_valid(gallery): return
	canvas.finish_drag()
	gallery=preload("res://scripts/editor/trigger_editor.gd").new()
	gallery.saved.connect(func(): saved.emit())
	gallery.closed.connect(func(): gallery=null)
	add_child(gallery)
