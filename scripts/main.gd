extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const SimulationState = preload("res://scripts/simulation/simulation_state.gd")
const CombatResolver = preload("res://scripts/simulation/combat_resolver.gd")
const MapView = preload("res://scripts/ui/map_view.gd")

var catalog: Dictionary = {}
var simulation
var combat_preview: Dictionary = {}

var day_label: Label
var market_label: RichTextLabel
var combat_label: RichTextLabel
var map_view
var city_checkbox_list: VBoxContainer
var editor_info_label: RichTextLabel
var city_checkboxes: Dictionary = {}
var selected_editor_city_id: String = ""
var placed_editor_city_ids: Array[String] = []

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()
	simulation = SimulationState.new(catalog)
	simulation.advance_days(1)
	combat_preview = _resolve_demo_combat()

	_build_layout()
	_refresh_ui()

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

	var header := _build_header()
	root.add_child(header)

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
	map_panel.add_child(map_view)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(360, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation", 12)
	body.add_child(sidebar)

	sidebar.add_child(_build_map_editor_panel())
	sidebar.add_child(_build_status_panel())
	sidebar.add_child(_build_market_panel())
	sidebar.add_child(_build_combat_panel())

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 12)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "Hanseatische Warenwirtschaftssimulation"
	title.add_theme_font_size_override("font_size", 30)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Phase 0.2: sichtbarer Prototyp fuer Karte, Karteneditor, Markt und Piratenrisiko"
	subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(subtitle)

	var version := Label.new()
	version.text = "0.2.6-foundation"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 14)
	header.add_child(version)

	return header

func _build_status_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Simulation"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	day_label = Label.new()
	content.add_child(day_label)

	var stats := Label.new()
	stats.text = "Waren: %d\nSim-Staedte: %d\nHanseorte: %d\nSchiffstypen: %d\nPiratenzonen: %d" % [
		catalog.get("goods", []).size(),
		catalog.get("cities", []).size(),
		catalog.get("hanse_cities", []).size(),
		catalog.get("ship_types", []).size(),
		catalog.get("pirate_zones", []).size()
	]
	content.add_child(stats)

	var advance := Button.new()
	advance.text = "Naechster Tag"
	advance.pressed.connect(_on_advance_day_pressed)
	content.add_child(advance)

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

	_refresh_map_editor()

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
	list_scroll.custom_minimum_size = Vector2(320, 190)
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	editor_info_label.custom_minimum_size = Vector2(320, 98)
	content.add_child(editor_info_label)

	_populate_city_checkboxes()

	return panel

func _build_market_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Marktpreise"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	market_label = RichTextLabel.new()
	market_label.bbcode_enabled = true
	market_label.fit_content = true
	market_label.custom_minimum_size = Vector2(320, 120)
	content.add_child(market_label)

	return panel

func _build_combat_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Piratenbegegnung"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	combat_label = RichTextLabel.new()
	combat_label.bbcode_enabled = true
	combat_label.fit_content = true
	combat_label.custom_minimum_size = Vector2(320, 120)
	content.add_child(combat_label)

	var resolve := Button.new()
	resolve.text = "Begegnung auswerten"
	resolve.pressed.connect(_on_resolve_combat_pressed)
	content.add_child(resolve)

	return panel

func _refresh_ui() -> void:
	day_label.text = "Simulationstag: %d" % simulation.day
	market_label.text = _market_preview()
	combat_label.text = _combat_preview()
	map_view.set_simulation_day(simulation.day)

func _market_preview() -> String:
	var lines: Array[String] = []
	for city_id in simulation.city_state.keys():
		var city: Dictionary = simulation.city_state[city_id]
		var grain_price: int = simulation.get_price(city_id, "grain")
		var salt_price: int = simulation.get_price(city_id, "salt")
		var herring_price: int = simulation.get_price(city_id, "herring")
		lines.append("[b]%s[/b]\nGetreide %d | Salz %d | Hering %d" % [
			city.get("name", city_id),
			grain_price,
			salt_price,
			herring_price
		])
	return "\n\n".join(lines)

func _combat_preview() -> String:
	return "Route: Hamburg -> Luebeck -> Visby\nStatus: %s\nSchaden: %.1f\nFrachtverlust: %.1f%%\nKopfgeld: %d" % [
		combat_preview.get("outcome", "unknown"),
		combat_preview.get("damage", 0.0),
		combat_preview.get("cargo_loss_ratio", 0.0) * 100.0,
		combat_preview.get("bounty", 0)
	]

func _resolve_demo_combat() -> Dictionary:
	var day_factor: float = 0.03 * float(simulation.day % 7)
	return CombatResolver.resolve({
		"ship_attack": 8,
		"ship_defense": 7,
		"crew": 18,
		"morale": 0.72,
		"pirate_attack": 6 + day_factor,
		"pirate_crew": 14,
		"weather_risk": 0.15 + day_factor,
		"cargo_value": 620 + simulation.day * 15
	})

func _on_advance_day_pressed() -> void:
	simulation.advance_days(1)
	_refresh_ui()

func _on_resolve_combat_pressed() -> void:
	combat_preview = _resolve_demo_combat()
	_refresh_ui()

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
