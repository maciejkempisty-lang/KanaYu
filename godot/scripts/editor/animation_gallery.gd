extends CanvasLayer
signal closed
const Hero = preload("res://scripts/hero_visual.gd")
const LABELS = ["E · prawo","SE · dół/prawo","S · dół","SW · dół/lewo","W · lewo","NW · góra/lewo","N · góra","NE · góra/prawo"]
var grid := GridContainer.new()
var heroes: Array = []
var time := 0.0

func _ready() -> void:
	layer=30
	var root := PanelContainer.new()
	var theme := Theme.new()
	var font := FontVariation.new()
	font.base_font=preload("res://assets/Nunito.ttf")
	font.variation_embolden=0.4
	theme.default_font=font
	root.theme=theme
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var box := StyleBoxFlat.new(); box.bg_color=Color("283f35")
	box.content_margin_left=16; box.content_margin_right=16; box.content_margin_top=16; box.content_margin_bottom=16
	root.add_theme_stylebox_override("panel",box)
	var column := VBoxContainer.new(); root.add_child(column)
	var title := Label.new(); title.text="KIGI / 8 KIERUNKÓW · NOWE ATLASY"; column.add_child(title)
	var close_button := Button.new(); close_button.text="Wróć do edytora"; close_button.custom_minimum_size.y=38
	close_button.pressed.connect(close); column.add_child(close_button)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	var vectors := [Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1),Vector2.UP,Vector2(1,-1)]
	for i in 8:
		var cell := Control.new(); cell.custom_minimum_size=Vector2(210,235); cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_child(cell)
		var label := Label.new(); label.text=LABELS[i]; label.position=Vector2(12,5); cell.add_child(label)
		var captions := Label.new(); captions.text="idle                  walk"; captions.position=Vector2(30,205); cell.add_child(captions)
		for walking in [false,true]:
			var hero := Hero.new(); hero.world_height=115; hero.position=Vector2(150 if walking else 55,185); cell.add_child(hero)
			hero.face(vectors[i]*83)
			if not walking: hero.face(Vector2.ZERO)
			heroes.append(hero)
	get_viewport().size_changed.connect(layout)
	layout()

func layout() -> void:
	var width := get_viewport().get_visible_rect().size.x
	grid.columns=4 if width>=900 else (2 if width>=450 else 1)

func close() -> void:
	closed.emit(); queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close(); get_viewport().set_input_as_handled()
