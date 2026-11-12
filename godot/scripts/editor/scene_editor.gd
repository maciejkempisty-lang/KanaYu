extends CanvasLayer
signal closed
signal saved
const Model=preload("res://scripts/editor/scene_model.gd")
const Canvas=preload("res://scripts/editor/scene_canvas.gd")
var layout_path := ""
var scene_title := "Scena"
var model
var canvas=Canvas.new()
var selector:=OptionButton.new()
var radius:=SpinBox.new()
var status:=Label.new()
var close_dialog:=ConfirmationDialog.new()
var preview_button:=CheckButton.new()
var add_button: Button
var new_button: Button
var remove_button: Button
var point_button: Button
var undo_button: Button
var redo_button: Button
var syncing := false
var bubble_preview
var bubble_fields := {}
var bubble_station := ""
var bubble_toolbar: HFlowContainer
var map_controls: HFlowContainer
var map_help: Label
var bubble_help: Label
func _ready() -> void:
	layer=30
	model=Model.new(layout_path)
	var panel:=PanelContainer.new(); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(panel)
	var style:=StyleBoxFlat.new(); style.bg_color=Color("253e34")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,12)
	panel.add_theme_stylebox_override("panel",style)
	var theme:=Theme.new(); theme.default_font=preload("res://assets/Nunito.ttf"); panel.theme=theme
	var column:=VBoxContainer.new(); panel.add_child(column)
	var title:=Label.new(); title.text="KIGI / EDYTOR · "+scene_title; title.add_theme_font_size_override("font_size",22); column.add_child(title)
	if model.data.is_empty():
		status.text="Nie można wczytać danych sceny: "+layout_path; column.add_child(status)
		button(column,"Zamknij",finish_close); return
	canvas.model=model; canvas.map_size=model.map_size; canvas.background=load(model.data.texture)
	canvas.preview_position=Vector2(model.data.spawn[0],model.data.spawn[1])
	var tools:=HFlowContainer.new(); column.add_child(tools)
	var mode:=OptionButton.new()
	var modes := ["floor", "obstacles", "masks", "regions", "triggers", "spawn"]
	for label in ["Podłoga / ruch","Przeszkody","Maski","Aktywacja masek","Triggery","Punkt pojawienia"]: mode.add_item(label)
	if model.data.schema == "kigi-school-layout/1" and not model.data.stations.is_empty():
		mode.add_item("Dymek")
		modes.append("bubble")
	mode.item_selected.connect(func(index):
		canvas.finish_drag(); canvas.creating=false; canvas.adding_point=false
		model.set_mode(modes[index]); refresh())
	tools.add_child(mode)
	map_controls = HFlowContainer.new()
	column.add_child(map_controls)
	selector.custom_minimum_size.x=190
	selector.item_selected.connect(func(index): canvas.finish_drag(); model.selected_route=index; model.selected_point=-1; refresh())
	map_controls.add_child(selector)
	new_button=button(map_controls,"Nowy obiekt",func():
		canvas.finish_drag(); preview_button.button_pressed=false; canvas.adding_point=false; canvas.creating=not canvas.creating; refresh())
	remove_button=button(map_controls,"Usuń obiekt",func(): canvas.finish_drag(); model.delete_object(); refresh())
	add_button=button(map_controls,"Dodaj punkt",func():
		canvas.finish_drag(); preview_button.button_pressed=false; canvas.creating=false; canvas.adding_point=not canvas.adding_point; refresh())
	point_button=button(map_controls,"Usuń punkt",func(): model.delete_point(); refresh())
	radius.min_value=1; radius.max_value=300; radius.step=1; radius.prefix="Promień: "; radius.custom_minimum_size.x=150
	radius.value_changed.connect(func(value):
		if not syncing: model.set_radius(value); refresh())
	map_controls.add_child(radius)
	preview_button.text="Podgląd bohatera"; map_controls.add_child(preview_button)
	preview_button.toggled.connect(func(value): canvas.finish_drag(); canvas.preview=value; canvas.creating=false; canvas.adding_point=false; refresh())
	button(map_controls,"−",func(): canvas.zoom_at(canvas.size/2,1/1.2))
	button(map_controls,"+",func(): canvas.zoom_at(canvas.size/2,1.2))
	button(map_controls,"Cała mapa",canvas.fit_map)
	undo_button=button(tools,"Cofnij",func(): model.undo(); refresh())
	redo_button=button(tools,"Ponów",func(): model.redo(); refresh())
	button(tools,"Zapisz",save_changes)
	button(tools,"Zapisz i wróć",func():
		if save_changes(): finish_close())
	button(tools,"Zamknij",request_close)
	if model.data.schema == "kigi-school-layout/1" and not model.data.stations.is_empty():
		build_bubble_controls(column)
	var help:=Label.new(); help.text="Przeciągaj punkty · Dodaj punkt: kliknij krawędź · Nowy obiekt: kliknij mapę · prawy przycisk: przesuń · kółko: zoom"
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(help)
	map_help = help
	canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL; canvas.custom_minimum_size.y=200; column.add_child(canvas)
	canvas.edited.connect(refresh); canvas.selection_changed.connect(refresh)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(status)
	panel.add_child(close_dialog); close_dialog.title="Niezapisane zmiany"
	close_dialog.dialog_text="Odrzucić niezapisane zmiany tej sceny?"
	close_dialog.ok_button_text="Odrzuć"; close_dialog.cancel_button_text="Wróć do edycji"
	close_dialog.confirmed.connect(finish_close)
	refresh()
func button(parent: Node, text: String, action: Callable) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=38; b.pressed.connect(action); parent.add_child(b); return b
func refresh() -> void:
	var editing_bubble: bool = model.mode == "bubble"
	map_controls.visible = not editing_bubble
	map_help.visible = not editing_bubble
	canvas.visible = not editing_bubble
	if bubble_preview != null:
		bubble_toolbar.visible = editing_bubble
		bubble_help.visible = editing_bubble
		bubble_preview.visible = editing_bubble
		if editing_bubble:
			syncing = true
			var settings := Model.Layout.BubbleSettings.from_layout(model.data, 20, bubble_station)
			for key in bubble_fields:
				bubble_fields[key].value = settings[key]
			syncing = false
			bubble_preview.layout = model.data
			bubble_preview.station_id = bubble_station
			bubble_preview.bubble.settings = settings
			bubble_preview.update_preview()
	syncing=true; selector.clear()
	for route in model.data.routes: selector.add_item(route.name)
	if model.selected_route>=0: selector.select(model.selected_route)
	selector.disabled=model.selected_route<0
	radius.visible=model.mode=="triggers"
	if radius.visible and model.selected_route>=0: radius.value=model.data.stations[model.selected_route].radius_world
	syncing=false
	new_button.disabled=model.mode not in ["obstacles","masks","regions"]
	remove_button.disabled=new_button.disabled or model.selected_route<0
	new_button.text="Kliknij mapę…" if canvas.creating else "Nowy obiekt"
	add_button.disabled=model.mode in ["triggers","spawn"] or model.selected_route<0 or canvas.preview
	add_button.text="Dodaj punkt ✓" if canvas.adding_point else "Dodaj punkt"
	point_button.disabled=add_button.disabled or model.selected_point<0 or model.edit_points(model.selected_route).size()<=3
	undo_button.disabled=model.undo_stack.is_empty(); redo_button.disabled=model.redo_stack.is_empty()
	status.text=("● Niezapisane zmiany" if model.dirty() else "Zapis aktualny")+" · "+scene_title+" · Zapis dotyczy tylko tej sceny."
	canvas.queue_redraw()
func save_changes() -> bool:
	canvas.finish_drag()
	if not model.save(): status.text=Model.Layout.last_error; return false
	refresh()
	status.text = "Zapisano ustawienia sceny."
	saved.emit()
	return true
func request_close() -> void:
	if model==null or model.data.is_empty(): finish_close(); return
	canvas.finish_drag()
	if model.dirty(): close_dialog.popup_centered(Vector2i(350,160))
	else: finish_close()
func finish_close() -> void:
	closed.emit(); queue_free()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or model==null or model.data.is_empty(): return
	if event.keycode in [KEY_ESCAPE,KEY_BACKSLASH]: request_close()
	elif (event.ctrl_pressed or event.meta_pressed) and event.keycode==KEY_S: save_changes()
	elif (event.ctrl_pressed or event.meta_pressed) and event.keycode==KEY_Z:
		if event.shift_pressed: model.redo()
		else: model.undo()
		refresh()
	elif event.keycode==KEY_DELETE: model.delete_point(); refresh()
	else: return
	get_viewport().set_input_as_handled()


func build_bubble_controls(column: VBoxContainer) -> void:
	bubble_toolbar = HFlowContainer.new()
	column.add_child(bubble_toolbar)
	bubble_help = Label.new()
	bubble_help.text = "Dymek układa się automatycznie nad głową bohatera."
	bubble_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(bubble_help)
	bubble_preview = preload("res://scripts/editor/bubble_preview.gd").new()
	bubble_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_preview.custom_minimum_size.y = 200
	column.add_child(bubble_preview)
	bubble_preview.artwork.texture = canvas.background
	var stations := OptionButton.new()
	stations.custom_minimum_size.x = 200
	for station in model.data.stations:
		stations.add_item(station.name)
	bubble_station = model.data.stations[0].id
	stations.item_selected.connect(func(index):
		bubble_station = model.data.stations[index].id
		refresh())
	bubble_toolbar.add_child(stations)
	var formats := OptionButton.new()
	formats.add_item("Podgląd telefonu")
	formats.add_item("Podgląd tabletu")
	formats.item_selected.connect(func(index):
		bubble_preview.view_size = Vector2(390, 844) if index == 0 else Vector2(768, 1024)
		bubble_preview.update_preview())
	bubble_toolbar.add_child(formats)
	var labels := {"width": "Szerokość: ", "font_size": "Tekst: "}
	for key in labels:
		var field := SpinBox.new()
		var limits: Vector2 = Model.Layout.BubbleSettings.LIMITS[key]
		field.min_value = limits.x
		field.max_value = limits.y
		field.step = 1
		field.prefix = labels[key]
		field.custom_minimum_size.x = 140
		field.value_changed.connect(change_bubble_field.bind(key))
		bubble_fields[key] = field
		bubble_toolbar.add_child(field)

func change_bubble_field(value: float, key: String) -> void:
	if syncing:
		return
	model.set_bubble_settings(bubble_station, {key: value})
	refresh()
