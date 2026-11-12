extends CanvasLayer
signal closed
signal saved
signal quit_requested
const Model = preload("res://scripts/editor/mask_model.gd")
const Canvas = preload("res://scripts/editor/mask_canvas.gd")
@export var standalone := false
var target_path := ""
var model
var canvas := Canvas.new()
var selector := OptionButton.new()
var status := Label.new()
var point_label := Label.new()
var undo_button: Button
var redo_button: Button
var delete_button: Button
var save_button: Button
var add_point_button: Button
var delete_mask_button: Button
var new_mask_button: Button
var preview_button: CheckButton
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
	title.text = "KIGI / EDYTOR MASEK"
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
	new_mask_button=button(tools,"Nowa maska",func(): set_tool("create"))
	delete_mask_button=button(tools,"Usuń maskę",func(): canvas.finish_drag(); model.delete_mask(); canvas.tool_mode=""; refresh())
	add_point_button=button(tools,"Dodaj punkt",func(): set_tool("point"))
	var mode := OptionButton.new()
	mode.add_item("Obrys maski (złoty)"); mode.add_item("Obszar aktywacji (niebieski)")
	mode.item_selected.connect(func(index):
		canvas.finish_drag(); canvas.tool_mode=""; model.editing_region=index==1; model.selected_point=-1; refresh())
	tools.add_child(mode)
	preview_button = CheckButton.new(); preview_button.text="Podgląd bohatera"
	preview_button.toggled.connect(func(value): canvas.finish_drag(); canvas.preview=value; canvas.tool_mode=""; refresh())
	tools.add_child(preview_button)
	button(tools,"−",func(): canvas.zoom_at(canvas.size/2,1/1.2))
	button(tools,"+",func(): canvas.zoom_at(canvas.size/2,1.2))
	button(tools,"Cała mapa",canvas.fit_map)
	undo_button=button(tools,"Cofnij",func(): model.undo(); refresh())
	redo_button=button(tools,"Ponów",func(): model.redo(); refresh())
	delete_button=button(tools,"Usuń punkt",func(): model.delete_point(); refresh())
	save_button=button(tools,"Zapisz",save_changes)
	button(tools,"Sprawdź obrysy",func():
		var error: String=Model.Masks.validate(model.data)
		status.text="Obrysy są poprawne." if error.is_empty() else error)
	button(tools,"Zapisz i wróć",func():
		if save_changes(): finish_close())
	button(tools,"Zamknij",request_close)
	var help := Label.new()
	help.text="Nowa maska: kliknij obiekt • Dodaj punkt: kliknij krawędź • Przeciągnij punkt • puste tło: przesuń mapę • kółko: zoom • dwuklik na krawędzi: dodaj punkt • Podgląd: kliknij lub przeciągnij bohatera"
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
	close_dialog.dialog_text="Zmiany masek nie zostały zapisane."
	close_dialog.ok_button_text="Odrzuć i zamknij"
	close_dialog.cancel_button_text="Wróć do edycji"
	close_dialog.confirmed.connect(finish_close)
	if standalone: get_tree().auto_accept_quit=false
	status.text="Złoty: wycinany fragment grafiki. Niebieski: obszar stóp bohatera włączający maskę. Podgląd uwzględnia wszystkie maski."
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
	var has_mask: bool=not model.data.routes.is_empty()
	selector.disabled=not has_mask
	if has_mask: selector.select(model.selected_route)
	delete_mask_button.disabled=not has_mask
	add_point_button.disabled=not has_mask or canvas.preview
	new_mask_button.disabled=model.data.routes.size()>=100
	add_point_button.text="Dodaj punkt ✓" if canvas.tool_mode=="point" else "Dodaj punkt"
	new_mask_button.text="Kliknij na mapie…" if canvas.tool_mode=="create" else "Nowa maska"
	syncing=false
	point_label.text=("● Niezapisane zmiany" if model.dirty() else "Zapis aktualny")+"  |  "+(model.data.routes[model.selected_route].name if has_mask else "Brak masek — wybierz Nowa maska")
	if model.selected_point>=0:
		var p: Array=model.edit_points(model.selected_route)[model.selected_point]
		point_label.text+="  |  punkt %d: %.0f, %.0f" % [model.selected_point,p[0],p[1]]
	undo_button.disabled=model.undo_stack.is_empty()
	redo_button.disabled=model.redo_stack.is_empty()
	delete_button.disabled=not has_mask or model.selected_point<0 or model.edit_points(model.selected_route).size()<=3
	canvas.queue_redraw()

func save_changes() -> bool:
	canvas.finish_drag()
	if not model.save(): status.text=Model.Masks.last_error; return false
	status.text="Zapisano maski. Zostaną wczytane po powrocie do gry." if model.path.begins_with("res://") else "Zapisano maski na tym urządzeniu."
	refresh()
	saved.emit()
	return true

func request_close() -> void:
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

func set_tool(tool: String) -> void:
	canvas.finish_drag()
	var next := "" if canvas.tool_mode==tool else tool
	preview_button.button_pressed=false
	canvas.preview=false; canvas.tool_mode=next
	status.text="Kliknij na mapie: powstanie nowa maska z obszarem aktywacji. Dopasuj oba obrysy." if next=="create" else "Klikaj krawędzie wybranego obrysu, aby dodawać punkty. Ponownie naciśnij Dodaj punkt, aby zakończyć."
	refresh()
