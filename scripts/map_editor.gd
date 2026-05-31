extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const MapView = preload("res://scripts/ui/map_view.gd")

var catalog: Dictionary = {}
var map_view
var city_checkbox_list: VBoxContainer
var editor_info_label: RichTextLabel
var city_checkboxes: Dictionary = {}
var selected_editor_city_id: String = ""
var placed_editor_city_ids: Array[String] = []

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()

	_build_layout()
	_refresh_map_editor()

func _build_layout() -> void:
	var background := ColorRect.new()
	background.color = Color(0.075, 0.086, 0.095)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_top = 22
	root.offset_right = -28
	root.offset_bottom = -22
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	root.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(map_panel)

	map_view = MapView.new()
	map_view.set_catalog(catalog)
	map_view.set_layers(false, true)
	map_panel.add_child(map_view)

	var sidebar_scroll := ScrollContainer.new()
	sidebar_scroll.custom_minimum_size = Vector2(380, 0)
	sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sidebar_scroll)

	var sidebar := VBoxContainer.new()
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation", 12)
	sidebar_scroll.add_child(sidebar)

	sidebar.add_child(_build_map_editor_panel())

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 12)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "Hanse Map Editor"
	title.add_theme_font_size_override("font_size", 30)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Eigenstaendiges Tool fuer Custom-Karten"
	subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(subtitle)

	var version := Label.new()
	version.text = "0.2.8-separated-executables"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 14)
	header.add_child(version)

	return header

func _build_map_editor_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Karteneditor"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(320, 520)
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(list_scroll)

	city_checkbox_list = VBoxContainer.new()
	city_checkbox_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city_checkbox_list.add_theme_constant_override("separation", 2)
	list_scroll.add_child(city_checkbox_list)

	var bulk_controls := HBoxContainer.new()
	bulk_controls.add_theme_constant_override("separation", 8)
	content.add_child(bulk_controls)

	var select_all := Button.new()
	select_all.text = "Alle"
	select_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_all.pressed.connect(_on_select_all_editor_cities_pressed)
	bulk_controls.add_child(select_all)

	var clear := Button.new()
	clear.text = "Keine"
	clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear.pressed.connect(_on_clear_editor_cities_pressed)
	bulk_controls.add_child(clear)

	editor_info_label = RichTextLabel.new()
	editor_info_label.bbcode_enabled = true
	editor_info_label.fit_content = true
	editor_info_label.custom_minimum_size = Vector2(320, 120)
	content.add_child(editor_info_label)

	_populate_city_checkboxes()

	return panel

func _populate_city_checkboxes() -> void:
	var hanse_cities: Array = catalog.get("hanse_cities", [])
	city_checkboxes.clear()

	if hanse_cities.is_empty():
		editor_info_label.text = "Keine historischen Hanseorte geladen."
		return

	for city_entry in hanse_cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		var checkbox := CheckBox.new()
		checkbox.text = "%s - %s" % [city.get("name", ""), _editor_city_kind_label(String(city.get("kind", "")))]
		checkbox.focus_mode = Control.FOCUS_NONE
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		checkbox.toggled.connect(_on_editor_city_toggled.bind(city_id))
		city_checkbox_list.add_child(checkbox)
		city_checkboxes[city_id] = checkbox

func _add_editor_city_point(city_id: String) -> void:
	if city_id.is_empty() or placed_editor_city_ids.has(city_id):
		return
	placed_editor_city_ids.append(city_id)

func _refresh_map_editor() -> void:
	if map_view != null:
		map_view.set_map_editor_selection(selected_editor_city_id, placed_editor_city_ids)

	var city := _editor_city_by_id(selected_editor_city_id)
	if city.is_empty():
		editor_info_label.text = "Ausgewaehlt: %d / %d" % [
			placed_editor_city_ids.size(),
			catalog.get("hanse_cities", []).size()
		]
		return

	var position: Dictionary = city.get("position", {})
	editor_info_label.text = "[b]%s[/b]\n%s | %.4f, %.4f\nKartenpunkt: %d / %d\nAusgewaehlt: %d / %d" % [
		city.get("name", ""),
		city.get("region", ""),
		float(city.get("lat", 0.0)),
		float(city.get("lon", 0.0)),
		int(position.get("x", 0)),
		int(position.get("y", 0)),
		placed_editor_city_ids.size(),
		catalog.get("hanse_cities", []).size()
	]

func _editor_city_by_id(city_id: String) -> Dictionary:
	for city_entry in catalog.get("hanse_cities", []):
		var city: Dictionary = city_entry
		if city.get("id", "") == city_id:
			return city
	return {}

func _editor_city_kind_label(kind: String) -> String:
	match kind:
		"core":
			return "Kernstadt"
		"kontor":
			return "Kontor"
		"member":
			return "Hansestadt"
		"trade":
			return "Handelsort"
		_:
			return "Ort"

func _on_editor_city_toggled(is_checked: bool, city_id: String) -> void:
	selected_editor_city_id = city_id
	if is_checked:
		_add_editor_city_point(city_id)
	else:
		placed_editor_city_ids.erase(city_id)
	_refresh_map_editor()

func _on_clear_editor_cities_pressed() -> void:
	placed_editor_city_ids.clear()
	for checkbox in city_checkboxes.values():
		checkbox.set_pressed_no_signal(false)
	selected_editor_city_id = ""
	_refresh_map_editor()

func _on_select_all_editor_cities_pressed() -> void:
	placed_editor_city_ids.clear()
	for city_entry in catalog.get("hanse_cities", []):
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		_add_editor_city_point(city_id)
		if city_checkboxes.has(city_id):
			city_checkboxes[city_id].set_pressed_no_signal(true)
	if not placed_editor_city_ids.is_empty():
		selected_editor_city_id = placed_editor_city_ids[0]
	_refresh_map_editor()
