extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const SimulationState = preload("res://scripts/simulation/simulation_state.gd")
const CombatResolver = preload("res://scripts/simulation/combat_resolver.gd")
const MapView = preload("res://scripts/ui/map_view.gd")

const DEMO_ROUTE: Array[String] = ["bremen", "hamburg", "luebeck", "visby", "danzig"]
const BASE_SHIP_PIXELS_PER_DAY := 80.0
const SPEED_OPTIONS := [
	{"label": "Stop", "days_per_second": 0.0},
	{"label": "1x", "days_per_second": 0.18},
	{"label": "5x", "days_per_second": 0.90},
	{"label": "20x", "days_per_second": 3.60},
	{"label": "Fast Forward", "days_per_second": 10.0},
]

var catalog: Dictionary = {}
var simulation
var combat_preview: Dictionary = {}
var simulation_time_days: float = 0.0
var current_speed_index: int = 1
var demo_ships: Array = []
var ship_type_by_id: Dictionary = {}

var day_label: Label
var clock_label: Label
var speed_select: OptionButton
var travel_label: RichTextLabel
var market_label: RichTextLabel
var combat_label: RichTextLabel
var map_view

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()
	_index_ship_types()
	simulation = SimulationState.new(catalog)
	_initialize_demo_ships()
	combat_preview = _resolve_demo_combat()

	_build_layout()
	_refresh_ui()
	set_process(true)

func _process(delta: float) -> void:
	var days_delta: float = float(SPEED_OPTIONS[current_speed_index]["days_per_second"]) * delta
	if days_delta <= 0.0:
		return

	simulation_time_days += days_delta
	_advance_demo_ships(days_delta)

	var full_days: int = int(floor(simulation_time_days)) - simulation.day
	if full_days > 0:
		simulation.advance_days(full_days)
		combat_preview = _resolve_demo_combat()

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
	map_view.set_layers(true, false)
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
	subtitle.text = "Phase 0.2: Hauptgame-Prototyp mit festen Staedten, Markt und Piratenrisiko"
	subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(subtitle)

	var version := Label.new()
	version.text = String(ProjectSettings.get_setting("application/config/version", ""))
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

	clock_label = Label.new()
	content.add_child(clock_label)

	var stats := Label.new()
	stats.text = "Waren: %d\nFeste Spielstaedte: %d\nSchiffstypen: %d\nPiratenzonen: %d" % [
		catalog.get("goods", []).size(),
		catalog.get("cities", []).size(),
		catalog.get("ship_types", []).size(),
		catalog.get("pirate_zones", []).size()
	]
	content.add_child(stats)

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	content.add_child(speed_row)

	var speed_label := Label.new()
	speed_label.text = "Geschwindigkeit"
	speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_row.add_child(speed_label)

	speed_select = OptionButton.new()
	for index in range(SPEED_OPTIONS.size()):
		speed_select.add_item(String(SPEED_OPTIONS[index]["label"]), index)
	speed_select.selected = current_speed_index
	speed_select.item_selected.connect(_on_speed_selected)
	speed_row.add_child(speed_select)

	travel_label = RichTextLabel.new()
	travel_label.bbcode_enabled = true
	travel_label.fit_content = true
	travel_label.custom_minimum_size = Vector2(320, 92)
	content.add_child(travel_label)

	var advance := Button.new()
	advance.text = "Tag +1"
	advance.pressed.connect(_on_advance_day_pressed)
	content.add_child(advance)

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
	clock_label.text = "Simulationszeit: Tag %.2f" % simulation_time_days
	travel_label.text = _travel_preview()
	market_label.text = _market_preview()
	combat_label.text = _combat_preview()
	map_view.set_simulation_day(simulation.day)
	map_view.set_route_ships(_map_ship_entries())

func _market_preview() -> String:
	var lines: Array[String] = []
	for city_id in simulation.city_state.keys():
		var city: Dictionary = simulation.city_state[city_id]
		lines.append("[b]%s[/b]\n%s" % [
			city.get("name", city_id),
			_market_goods_preview(city_id)
		])
	return "\n\n".join(lines)

func _market_goods_preview(city_id: String) -> String:
	var entries: Array[String] = []
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		entries.append("%s %d" % [
			_good_label(good),
			simulation.get_price(city_id, good_id)
		])
	return " | ".join(entries)

func _good_label(good: Dictionary) -> String:
	var good_id := String(good.get("id", ""))
	var unit: Dictionary = good.get("unit", {})
	var abbreviation := String(unit.get("abbreviation", ""))
	if abbreviation.is_empty():
		return String(good.get("name", good_id))
	return "%s/%s" % [String(good.get("name", good_id)), abbreviation]

func _combat_preview() -> String:
	return "Route: Bremen -> Hamburg -> Luebeck -> Visby -> Danzig\nStatus: %s\nSchaden: %.1f\nFrachtverlust: %.1f%%\nKopfgeld: %d" % [
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
	simulation_time_days = max(simulation_time_days, float(simulation.day)) + 1.0
	_advance_demo_ships(1.0)
	simulation.advance_days(1)
	combat_preview = _resolve_demo_combat()
	_refresh_ui()

func _on_resolve_combat_pressed() -> void:
	combat_preview = _resolve_demo_combat()
	_refresh_ui()

func _on_speed_selected(index: int) -> void:
	current_speed_index = clampi(index, 0, SPEED_OPTIONS.size() - 1)
	_refresh_ui()

func _index_ship_types() -> void:
	ship_type_by_id.clear()
	for ship_type_entry in catalog.get("ship_types", []):
		var ship_type: Dictionary = ship_type_entry
		ship_type_by_id[String(ship_type.get("id", ""))] = ship_type

func _initialize_demo_ships() -> void:
	demo_ships = [
		{"name": "Hanse 1", "ship_type": "kogge", "route_index": 0, "elapsed_days": 0.0},
		{"name": "Hanse 2", "ship_type": "kogge", "route_index": 2, "elapsed_days": 0.0},
		{"name": "Hanse 3", "ship_type": "kogge", "route_index": 3, "elapsed_days": 0.0},
	]

func _advance_demo_ships(days_delta: float) -> void:
	for ship_entry in demo_ships:
		var ship: Dictionary = ship_entry
		var remaining_days: float = days_delta
		while remaining_days > 0.0:
			var travel_days: float = _ship_segment_travel_days(ship)
			if travel_days <= 0.0:
				_advance_ship_segment(ship)
				break

			var elapsed: float = float(ship.get("elapsed_days", 0.0))
			var segment_remaining: float = travel_days - elapsed
			if remaining_days < segment_remaining:
				ship["elapsed_days"] = elapsed + remaining_days
				break

			remaining_days -= segment_remaining
			ship["elapsed_days"] = 0.0
			_advance_ship_segment(ship)

func _advance_ship_segment(ship: Dictionary) -> void:
	var route_index: int = int(ship.get("route_index", 0))
	route_index = (route_index + 1) % (DEMO_ROUTE.size() - 1)
	ship["route_index"] = route_index

func _ship_segment_travel_days(ship: Dictionary) -> float:
	var from_city_id: String = _ship_from_city(ship)
	var to_city_id: String = _ship_to_city(ship)
	var distance_px: float = map_view.get_route_distance_px(from_city_id, to_city_id) if map_view != null else 0.0
	var speed: float = _ship_speed(ship)
	if speed <= 0.0:
		return 0.0
	return max(0.1, distance_px / (BASE_SHIP_PIXELS_PER_DAY * speed))

func _ship_speed(ship: Dictionary) -> float:
	var ship_type_id: String = String(ship.get("ship_type", "kogge"))
	var ship_type: Dictionary = ship_type_by_id.get(ship_type_id, {})
	return float(ship_type.get("speed", 1.0))

func _ship_from_city(ship: Dictionary) -> String:
	var route_index: int = clampi(int(ship.get("route_index", 0)), 0, DEMO_ROUTE.size() - 2)
	return DEMO_ROUTE[route_index]

func _ship_to_city(ship: Dictionary) -> String:
	var route_index: int = clampi(int(ship.get("route_index", 0)), 0, DEMO_ROUTE.size() - 2)
	return DEMO_ROUTE[route_index + 1]

func _ship_progress(ship: Dictionary) -> float:
	var travel_days: float = _ship_segment_travel_days(ship)
	if travel_days <= 0.0:
		return 1.0
	return clampf(float(ship.get("elapsed_days", 0.0)) / travel_days, 0.0, 1.0)

func _map_ship_entries() -> Array:
	var ships: Array = []
	for ship_entry in demo_ships:
		var ship: Dictionary = ship_entry
		ships.append({
			"name": String(ship.get("name", "")),
			"from": _ship_from_city(ship),
			"to": _ship_to_city(ship),
			"progress": _ship_progress(ship),
		})
	return ships

func _travel_preview() -> String:
	var lines: Array[String] = ["[b]Schiffsreisen[/b]"]
	for ship_entry in demo_ships:
		var ship: Dictionary = ship_entry
		var from_city_id: String = _ship_from_city(ship)
		var to_city_id: String = _ship_to_city(ship)
		var travel_days: float = _ship_segment_travel_days(ship)
		var remaining_days: float = max(0.0, travel_days - float(ship.get("elapsed_days", 0.0)))
		lines.append("%s: %s -> %s | %.1f Tage Rest" % [
			String(ship.get("name", "")),
			_city_name(from_city_id),
			_city_name(to_city_id),
			remaining_days
		])
	return "\n".join(lines)

func _city_name(city_id: String) -> String:
	for city_entry in catalog.get("cities", []):
		var city: Dictionary = city_entry
		if String(city.get("id", "")) == city_id:
			return String(city.get("name", city_id))
	return city_id
