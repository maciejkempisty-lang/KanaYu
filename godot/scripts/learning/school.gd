extends CanvasLayer
signal closed
const Model = preload("res://scripts/learning/lesson_model.gd")
const DrawingPad = preload("res://scripts/learning/drawing_pad.gd")
var store
var room_mode := false
var initial_activity := ""
var model
var root := Control.new()
var column := VBoxContainer.new()
var scroll := ScrollContainer.new()
var voice := AudioStreamPlayer.new()
var input: LineEdit
var status_label: Label
var stroke_data: Dictionary
var page := "menu"
var notice := ""
var file_dialog := FileDialog.new()
var leave_dialog := ConfirmationDialog.new()
var file_action := ""
var saved_focus := ""

func _ready() -> void:
	layer = 10
	var theme := Theme.new()
	var font := FontVariation.new()
	font.base_font = preload("res://assets/Nunito.ttf")
	font.variation_embolden = 0.4
	theme.default_font = font
	root.theme = theme
	stroke_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/content/stroke-points.json"))
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("e7eddd")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,20)
	root.add_child(margin)
	var center := HBoxContainer.new()
	margin.add_child(center)
	var left := Control.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(left)
	scroll.custom_minimum_size.x = minf(520,get_viewport().get_visible_rect().size.x-40)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(scroll)
	var right := Control.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(right)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",13)
	scroll.add_child(column)
	get_viewport().size_changed.connect(func(): scroll.custom_minimum_size.x=minf(520,get_viewport().get_visible_rect().size.x-40))
	add_child(voice)
	root.add_child(file_dialog)
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; Dziennik KanaYu"])
	file_dialog.file_selected.connect(_file_selected)
	root.add_child(leave_dialog)
	leave_dialog.title = "Przerwa na herbatę?"
	leave_dialog.dialog_text = "Zapisane próby zostają w dzienniku.\nPrzerwana lekcja rozpocznie się od początku."
	leave_dialog.ok_button_text = "Wróć do szkoły"
	leave_dialog.cancel_button_text = "Zostaję"
	leave_dialog.confirmed.connect(menu)
	if initial_activity.is_empty(): menu()
	else: open_activity(initial_activity)

func _process(_delta: float) -> void:
	# Leave enough scroll room above the native mobile keyboard.
	var keyboard := DisplayServer.virtual_keyboard_get_height() if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) else 0
	var scale_y := get_viewport().get_screen_transform().get_scale().y
	var bottom := -float(keyboard)/maxf(scale_y,1)
	if scroll.get_parent().get_parent().offset_bottom!=bottom:
		scroll.get_parent().get_parent().offset_bottom = bottom
		if input != null and keyboard>0: scroll.ensure_control_visible.call_deferred(input)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if page=="lesson": leave_dialog.popup_centered(Vector2i(330,180))
		elif page!="menu": menu()
		else: close()
		get_viewport().set_input_as_handled()

func clear() -> void:
	voice.stop()
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	input = null
	scroll.scroll_vertical = 0

func label(text: String, font_size: int = 18, kana: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",Color("284638"))
	if kana: node.add_theme_font_override("font",preload("res://assets/KleeOne-Regular.ttf"))
	column.add_child(node)
	return node

func button(text: String, action: Callable, enabled: bool = true) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 48
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",17)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("325642")
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	node.add_theme_stylebox_override("normal",style)
	var hover := style.duplicate()
	hover.bg_color = Color("4b7258")
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("pressed",hover)
	node.add_theme_color_override("font_color",Color("fff8e5"))
	node.add_theme_color_override("font_disabled_color",Color("5a6658"))
	node.disabled = not enabled
	node.pressed.connect(action)
	column.add_child(node)
	return node

func menu() -> void:
	if room_mode: close(); return
	activities()

func activities() -> void:
	page = "menu"
	clear()
	label("KIGI / SZKOŁA YUU",14)
	label("Małe kroki,\nnowe dźwięki.",30)
	label("Poznane znaki: %d / 10" % store.introduced.size())
	if store.lantern_unlocked(): label("Twój pierwszy lampion już świeci.",18)
	if not store.error.is_empty(): label(store.error,16)
	if not notice.is_empty(): label(notice,16)
	if not store.recovery_notice.is_empty(): label(store.recovery_notice,16)
	button("Pierwsze światło · lekcja 10 znaków",func(): start_lesson())
	var reading: Array = store.due_for("kana_reading")
	var writing: Array = store.due_for("kana_writing")
	var measurements: Array = store.measurements_due()
	button("Czytanie na dzisiaj · %d" % reading.size(),func(): start_lesson(reading,"scheduled_review"),not reading.is_empty())
	button("Pisanie na dzisiaj · %d" % writing.size(),func(): start_lesson(writing,"scheduled_review",true),not writing.is_empty())
	button("Sprawdź po przerwie · %d" % measurements.size(),func(): start_lesson(measurements,"measurement"),not measurements.is_empty())
	button("Moje znaki i dodatkowe ćwiczenia",notebook)
	button("Dziennik i przenoszenie postępów",journal)
	button("Wróć do sali" if room_mode else "Wróć do wioski",close)

func start_lesson(items: Array = [], source: String = "lesson", writing: bool = false) -> void:
	model = Model.new(store)
	model.start(items,source,writing)
	page = "lesson"
	render_task()

func render_task() -> void:
	clear()
	button("‹ Szkoła",func(): leave_dialog.popup_centered(Vector2i(330,180)))
	if model.finished:
		label("Pierwsze światło" if model.full_lesson else "Dobra robota",30)
		label("Zapisano %d odpowiedzi. Samodzielnie poprawne: %d." % [model.attempted,model.correct])
		label("Lampion jest pamiątką ukończenia. Utrwalenie przychodzi z kolejnymi spotkaniami." if model.full_lesson else "Wyniki i terminy powtórek zapisano w dzienniku.")
		button("Wróć do szkoły",menu)
		return
	label("%s  ·  %d / %d" % ["Pierwsze światło" if model.full_lesson else "Spokojna powtórka",model.index+1,model.tasks.size()],14)
	var bar := ProgressBar.new()
	bar.max_value = model.tasks.size()
	bar.value = model.index
	bar.show_percentage = false
	column.add_child(bar)
	if not model.entered:
		label(store.error)
		button("Spróbuj ponownie",func(): model.enter(); render_task())
		return
	var k: Dictionary = model.item()
	var kind: String = model.task().kind
	if kind=="exposure":
		label("Poznaj znak",28)
		var animation = pad([],stroke_data[k.id])
		animation.animate_reference = true
		label(k.reading,32)
		label(k.note,17)
		for variant in k.get("variants",[]):
			if variant.has("note"): label(variant.note,14)
		button("Posłuchaj wymowy",play_voice)
		button("Dalej",advance)
	elif kind=="writing":
		label("Napisz „%s” z pamięci." % k.reading,26)
		if not model.locked:
			var drawing = pad(model.drawing,[])
			drawing.writable = true
			drawing.changed.connect(func(): store.touch())
			button("Wyczyść",func(): model.drawing.clear(); drawing.queue_redraw())
			button("Zatwierdź i porównaj",func():
				if model.drawing.is_empty(): return
				model.lock_drawing(); render_task())
			button("Nie pamiętam",func():
				if model.lock_drawing(): model.submit(true,false)
				render_task())
		else:
			pad(model.drawing,stroke_data[k.id])
			label("Twój zapis nałożony na wzorzec",14)
			label("Twoje kreski: %d · wzorzec: %d. Liczba kresek nie jest oceną." % [model.drawing.size(),stroke_data[k.id].size()],14)
			button("Odtwórz moje kreski",func(): replay_pad(false))
			button("Odtwórz wzorzec",func(): replay_pad(true))
			for variant in k.get("variants",[]):
				if variant.has("note"): label(variant.note,14)
			if not model.feedback:
				button("Poprawnie — samoocena",func(): submit(false,true))
				button("Błąd lub nie pamiętam",func(): submit(false,false))
			else: feedback()
	else:
		label("Jeszcze jedno spotkanie" if model.task().source=="corrective" else "Jak to czytamy?",26)
		var glyph := label(k.char,92 if kind=="reading" else 68,true)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not model.feedback:
			label("Wpisz odczyt w rōmaji",16)
			input = LineEdit.new()
			input.name = "Answer"
			input.text = model.response
			input.custom_minimum_size.y = 54
			input.add_theme_font_size_override("font_size",24)
			var paper := StyleBoxFlat.new()
			paper.bg_color = Color("fff9e9")
			paper.set_corner_radius_all(12)
			paper.content_margin_left = 14
			input.add_theme_stylebox_override("normal",paper)
			input.add_theme_color_override("font_color",Color("284638"))
			input.add_theme_color_override("caret_color",Color("284638"))
			input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD
			input.text_changed.connect(func(value): model.response=value; store.touch())
			input.text_submitted.connect(func(_value): submit())
			column.add_child(input)
			if not k.mnemonic.is_empty() and model.task().source!="measurement":
				if model.support.is_empty():
					button("Wskazówka",func(): model.support.append({"type":"mnemonic","timestamp":store.stamp(store.clock.call())}); render_task())
				else: label(k.mnemonic)
			button("Sprawdź",submit)
			button("Nie wiem jeszcze",func(): submit(true))
		else: feedback()
	if not store.error.is_empty(): label(store.error,16)

func pad(strokes: Array, reference: Array):
	var node := DrawingPad.new()
	node.strokes = strokes
	node.reference = reference
	column.add_child(node)
	return node

func replay_pad(reference: bool) -> void:
	var view := AcceptDialog.new()
	view.title = "Wzorzec" if reference else "Twoje kreski"
	var node := DrawingPad.new()
	node.custom_minimum_size = Vector2(260,260)
	if reference:
		node.reference = stroke_data[model.item().id]
		node.animate_reference = true
	else:
		node.strokes = model.drawing
		node.replay_drawing = true
	view.add_child(node)
	root.add_child(view)
	view.popup_centered(Vector2i(290,330))
	view.confirmed.connect(view.queue_free)
	view.canceled.connect(view.queue_free)

func submit(dont_know: bool = false, self_correct: bool = false) -> void:
	if input != null: model.response = input.text; input.release_focus()
	model.submit(dont_know,self_correct)
	render_task()

func advance() -> void:
	model.next()
	render_task()

func feedback() -> void:
	var good: bool = model.result.first_attempt_result=="correct"
	label(("Tak, właśnie tak!" if model.support.is_empty() else "Z pomocą też się uczymy.") if good else "Nie musisz pamiętać od razu.",23)
	label("%s → %s" % [model.item().char,model.item().reading],28,true)
	if model.task().kind=="word": label(model.item().note)
	if model.task().kind=="writing": label("Zapisano samoocenę. Gra nie rozpoznaje pisma.",15)
	elif model.task().source=="corrective": label("To ćwiczenie po podpowiedzi. Wynik zapisano osobno.",15)
	elif model.result.fsrs_decision.reason=="recent_exposure": label("Znak był już pokazany w tej sesji. Próba nie zmienia terminu powtórki ani statusu.",15)
	else: label("Odpowiedź zapisana. Kolejne spotkania pomogą ją utrwalić.",15)
	if not good:
		for other in store.catalog.kana:
			if other.id!=model.item().id and other.accepted.has(store.Catalog.normalize(model.response)):
				label("Dla porównania: %s czytamy „%s”." % [other.char,other.reading],18,true)
	button("Posłuchaj wymowy",play_voice)
	button("Zakończ" if model.index==model.tasks.size()-1 else "Dalej",advance)

func play_voice() -> void:
	var path: String = "res://assets/"+model.item().audio
	if ResourceLoader.exists(path):
		voice.stream = load(path)
		voice.play()

func notebook() -> void:
	page = "notebook"
	clear()
	button("‹ Szkoła",menu)
	label("Moje znaki",30)
	var known: Array = store.introduced_kana()
	button("Dodatkowe czytanie",func(): start_lesson(known,"minigame"),not known.is_empty())
	button("Pisanie z pamięci",func(): start_lesson(known,"minigame",true),not known.is_empty())
	for k in store.catalog.kana:
		# Unknown kana stay hidden; notebook never creates an unlogged exposure.
		if not store.introduced.has(k.id): label("Niepoznany znak",16); continue
		label("%s · %s\n%s" % [k.reading,store.status(k.id),store.status(k.id,"kana_writing")],18)
		var key: String = k.id+"|kana_reading"
		if store.cards.has(key): label("Powtórka czytania: "+Time.get_datetime_string_from_unix_time(int(store.cards[key].due)).replace("T"," ")+" UTC",13)

func journal() -> void:
	page = "journal"
	clear()
	button("‹ Szkoła",menu)
	label("Dziennik",30)
	label("Próby, wskazówki i terminy pozostają na tym urządzeniu.",16)
	if not notice.is_empty(): label(notice,15)
	if not store.error.is_empty(): label(store.error,15)
	button("Eksportuj postępy",func(): choose_file("export"))
	button("Importuj postępy KanaYu",func(): choose_file("import"))
	var count := 0
	for i in range(store.events.size()-1,-1,-1):
		var e: Dictionary = store.events[i]
		if e.type not in ["attempt","corrective"]: continue
		# No kana/answers in journal preview: avoids an unlogged answer exposure.
		var result_name: String = {"correct":"poprawnie","incorrect":"błąd","dont_know":"nie wiem"}.get(e.first_attempt_result,"")
		label("%s\n%s · %s" % [e.timestamp.substr(0,16).replace("T"," "),"Pisanie" if e.skill=="kana_writing" else "Czytanie",result_name],15)
		count += 1
		if count==20: break
	if count==0: label("Tu pojawią się Twoje pierwsze próby.")

func choose_file(action: String) -> void:
	file_action = action
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if action=="export" else FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title = "Eksport postępów" if action=="export" else "Import postępów KanaYu"
	if action=="export": file_dialog.current_file = "kanayu-postepy.json"
	file_dialog.popup_centered_ratio(0.9)

func _file_selected(path: String) -> void:
	if file_action=="export":
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file == null: notice = "Nie udało się zapisać eksportu."
		else:
			file.store_string(store.export_json()); file.flush()
			notice = "Eksport zapisany." if file.get_error()==OK else "Nie udało się zapisać eksportu."
	else:
		var file := FileAccess.open(path,FileAccess.READ)
		if file == null or file.get_length()>64*1024*1024: notice = "Nie można odczytać tego pliku."
		else: notice = "Postępy połączone. Powtórny import nie dubluje wpisów." if store.import_json(file.get_as_text()) else store.error
	journal()

func close() -> void:
	voice.stop()
	closed.emit()
	queue_free()

func open_activity(id: String) -> void:
	match id:
		"first": start_lesson()
		"notebook": notebook()
		"journal": journal()
		"activities": activities()
		"reading", "writing", "measurement":
			var items: Array=store.measurements_due() if id=="measurement" else store.due_for("kana_writing" if id=="writing" else "kana_reading")
			if items.is_empty():
				page="unavailable"; clear()
				label("Na dziś wszystko gotowe",28)
				label("Nie ma teraz zaplanowanych zadań w tym miejscu. Wróć, gdy nadejdzie czas kolejnej powtórki.")
				button("Wróć do sali" if room_mode else "Wróć do szkoły",menu)
			else: start_lesson(items,"measurement" if id=="measurement" else "scheduled_review",id=="writing")
