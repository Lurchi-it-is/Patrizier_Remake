extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const SimulationState = preload("res://scripts/simulation/simulation_state.gd")
const CombatResolver = preload("res://scripts/simulation/combat_resolver.gd")
const BalanceMetricsLogger = preload("res://scripts/simulation/balance_metrics_logger.gd")
const MapView = preload("res://scripts/ui/map_view.gd")

const DEMO_ROUTE: Array[String] = ["bremen", "hamburg", "luebeck", "visby", "danzig"]
const BASE_SHIP_PIXELS_PER_DAY := 80.0
const AI_TRADER_COUNT := 5
const AI_SHIP_TYPE_ID := "kogge"
const PLAYER_START_CITY_ID := "luebeck"
const PLAYER_SHIP_TYPE_ID := "kogge"
const PLAYER_TRADE_AMOUNT := 1.0
const SPEED_OPTIONS := [
	{"label": "Stop", "days_per_second": 0.0},
	{"label": "1x", "days_per_second": 0.04},
	{"label": "5x", "days_per_second": 0.20},
	{"label": "20x", "days_per_second": 0.80},
	{"label": "Fast Forward", "days_per_second": 3.0},
]

var catalog: Dictionary = {}
var simulation
var combat_preview: Dictionary = {}
var metrics_logger
var simulation_time_days: float = 0.0
var current_speed_index: int = 1
var ai_traders: Array = []
var player_ship: Dictionary = {}
var trade_city_id: String = ""
var ship_type_by_id: Dictionary = {}
var rng := RandomNumberGenerator.new()

var day_label: Label
var clock_label: Label
var speed_select: OptionButton
var fast_forward_button: Button
var travel_label: RichTextLabel
var market_label: RichTextLabel
var combat_label: RichTextLabel
var trade_popup: PopupPanel
var trade_content: VBoxContainer
var map_view

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()
	_index_ship_types()
	simulation = SimulationState.new(catalog)
	rng.seed = 1401
	metrics_logger = BalanceMetricsLogger.new()
	combat_preview = _resolve_demo_combat()

	_build_layout()
	_initialize_player_ship()
	_initialize_ai_traders()
	_log_daily_metrics()
	_refresh_ui()
	set_process(true)

func _process(delta: float) -> void:
	var days_delta: float = float(SPEED_OPTIONS[current_speed_index]["days_per_second"]) * delta
	if days_delta <= 0.0:
		return

	_advance_world(days_delta)

func _advance_world(days_delta: float) -> void:
	if days_delta <= 0.0:
		return

	simulation_time_days += days_delta
	_advance_player_ship(days_delta)
	_advance_ai_traders(days_delta)

	var full_days: int = int(floor(simulation_time_days)) - simulation.day
	if full_days > 0:
		simulation.advance_days(full_days)
		_log_daily_metrics()
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
	map_view.set_route_lines_visible(false)
	map_view.map_right_clicked.connect(_on_map_right_clicked)
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
	_build_trade_popup()

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

	fast_forward_button = Button.new()
	fast_forward_button.text = "Bis Ziel vorspulen"
	fast_forward_button.pressed.connect(_on_fast_forward_to_destination_pressed)
	content.add_child(fast_forward_button)

	travel_label = RichTextLabel.new()
	travel_label.bbcode_enabled = true
	travel_label.fit_content = true
	travel_label.custom_minimum_size = Vector2(320, 148)
	content.add_child(travel_label)

	var advance := Button.new()
	advance.text = "Tag +1"
	advance.pressed.connect(_on_advance_day_pressed)
	content.add_child(advance)

	return panel

func _build_trade_popup() -> void:
	trade_popup = PopupPanel.new()
	add_child(trade_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	trade_popup.add_child(margin)

	trade_content = VBoxContainer.new()
	trade_content.add_theme_constant_override("separation", 10)
	margin.add_child(trade_content)

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
	if fast_forward_button != null:
		fast_forward_button.disabled = not bool(player_ship.get("is_travelling", false))
	map_view.set_simulation_day(simulation.day)
	map_view.set_route_ships(_map_ship_entries())
	if trade_popup != null and trade_popup.visible and not trade_city_id.is_empty():
		_refresh_trade_popup(trade_city_id)

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
	_advance_world(1.0)

func _on_fast_forward_to_destination_pressed() -> void:
	var remaining_days := _player_remaining_travel_days()
	if remaining_days <= 0.0:
		return

	_advance_world(remaining_days)

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

func _initialize_player_ship() -> void:
	var start_position: Dictionary = map_view.get_city_harbor_position(PLAYER_START_CITY_ID) if map_view != null else {"x": 0.0, "y": 0.0}
	player_ship = {
		"name": "Spieler",
		"ship_type": PLAYER_SHIP_TYPE_ID,
		"current_city": PLAYER_START_CITY_ID,
		"target_city": "",
		"position": start_position,
		"path_points": [start_position],
		"path_distance_px": 0.0,
		"elapsed_days": 0.0,
		"travel_days": 0.0,
		"is_travelling": false,
		"cargo": {},
	}

func _on_map_right_clicked(source_position: Dictionary, city_id: String, is_water: bool) -> void:
	if player_ship.is_empty():
		return

	if not city_id.is_empty():
		if _player_can_trade_with_city(city_id):
			_show_trade_window(city_id)
			return
		_set_player_city_destination(city_id)
		return

	if is_water:
		_set_player_water_destination(source_position)

func _player_can_trade_with_city(city_id: String) -> bool:
	return not bool(player_ship.get("is_travelling", false)) and String(player_ship.get("current_city", "")) == city_id

func _set_player_city_destination(city_id: String) -> void:
	if map_view == null or city_id.is_empty():
		return

	var target_position: Dictionary = map_view.get_city_harbor_position(city_id)
	var current_city := String(player_ship.get("current_city", ""))
	var path_points: Array = []
	if not bool(player_ship.get("is_travelling", false)) and not current_city.is_empty():
		path_points = map_view.get_city_route_source_points(current_city, city_id)
	else:
		path_points = map_view.get_navigation_path_between_source_points(player_ship.get("position", {}), target_position)

	_start_player_trip(path_points, city_id)

func _set_player_water_destination(source_position: Dictionary) -> void:
	if map_view == null:
		return

	var path_points: Array = map_view.get_navigation_path_between_source_points(player_ship.get("position", {}), source_position)
	_start_player_trip(path_points, "")

func _start_player_trip(path_points: Array, target_city_id: String) -> void:
	if path_points.size() < 2:
		return

	var distance_px := _source_path_distance(path_points)
	if distance_px <= 0.0:
		return

	player_ship["current_city"] = ""
	player_ship["target_city"] = target_city_id
	player_ship["path_points"] = path_points
	player_ship["path_distance_px"] = distance_px
	player_ship["elapsed_days"] = 0.0
	player_ship["travel_days"] = _player_path_travel_days(distance_px)
	player_ship["is_travelling"] = true
	player_ship["position"] = path_points[0]
	_refresh_ui()

func _advance_player_ship(days_delta: float) -> void:
	if not bool(player_ship.get("is_travelling", false)):
		return

	var travel_days: float = float(player_ship.get("travel_days", 0.0))
	if travel_days <= 0.0:
		_arrive_player_ship()
		return

	var elapsed: float = float(player_ship.get("elapsed_days", 0.0)) + days_delta
	if elapsed < travel_days:
		player_ship["elapsed_days"] = elapsed
		player_ship["position"] = _interpolate_source_polyline(player_ship.get("path_points", []), elapsed / travel_days)
		return

	player_ship["elapsed_days"] = travel_days
	player_ship["position"] = _interpolate_source_polyline(player_ship.get("path_points", []), 1.0)
	_arrive_player_ship()

func _arrive_player_ship() -> void:
	var target_city_id := String(player_ship.get("target_city", ""))
	player_ship["current_city"] = target_city_id
	player_ship["target_city"] = ""
	player_ship["is_travelling"] = false
	player_ship["elapsed_days"] = 0.0
	player_ship["travel_days"] = 0.0
	player_ship["path_distance_px"] = 0.0
	player_ship["path_points"] = [player_ship.get("position", {})]

func _player_remaining_travel_days() -> float:
	if not bool(player_ship.get("is_travelling", false)):
		return 0.0
	return max(0.0, float(player_ship.get("travel_days", 0.0)) - float(player_ship.get("elapsed_days", 0.0)))

func _player_progress() -> float:
	var travel_days: float = float(player_ship.get("travel_days", 0.0))
	if travel_days <= 0.0:
		return 1.0
	return clampf(float(player_ship.get("elapsed_days", 0.0)) / travel_days, 0.0, 1.0)

func _player_path_travel_days(distance_px: float) -> float:
	var speed := _ship_speed(player_ship)
	if speed <= 0.0:
		return 0.0
	return max(0.1, distance_px / (BASE_SHIP_PIXELS_PER_DAY * speed))

func _source_path_distance(path_points: Array) -> float:
	var distance := 0.0
	for index in range(path_points.size() - 1):
		var from_position: Dictionary = path_points[index]
		var to_position: Dictionary = path_points[index + 1]
		var from_point := Vector2(float(from_position.get("x", 0.0)), float(from_position.get("y", 0.0)))
		var to_point := Vector2(float(to_position.get("x", 0.0)), float(to_position.get("y", 0.0)))
		distance += from_point.distance_to(to_point)
	return distance

func _interpolate_source_polyline(path_points: Array, progress: float) -> Dictionary:
	if path_points.is_empty():
		return {}
	if path_points.size() < 2:
		return path_points[0]

	var total_length := _source_path_distance(path_points)
	if total_length <= 0.0:
		return path_points[0]

	var target_length := clampf(progress, 0.0, 1.0) * total_length
	var traversed := 0.0
	for index in range(path_points.size() - 1):
		var from_position: Dictionary = path_points[index]
		var to_position: Dictionary = path_points[index + 1]
		var from_point := Vector2(float(from_position.get("x", 0.0)), float(from_position.get("y", 0.0)))
		var to_point := Vector2(float(to_position.get("x", 0.0)), float(to_position.get("y", 0.0)))
		var segment_length := from_point.distance_to(to_point)
		if traversed + segment_length >= target_length:
			var local_progress: float = (target_length - traversed) / max(segment_length, 0.001)
			var point := from_point.lerp(to_point, local_progress)
			return {"x": point.x, "y": point.y}
		traversed += segment_length

	return path_points[path_points.size() - 1]

func _show_trade_window(city_id: String) -> void:
	trade_city_id = city_id
	_refresh_trade_popup(city_id)
	trade_popup.popup_centered(Vector2i(680, 520))

func _refresh_trade_popup(city_id: String) -> void:
	if trade_content == null:
		return

	for child in trade_content.get_children():
		trade_content.remove_child(child)
		child.queue_free()

	var title := Label.new()
	title.text = "Handel in %s" % _city_name(city_id)
	title.add_theme_font_size_override("font_size", 22)
	trade_content.add_child(title)

	var capacity_label := Label.new()
	capacity_label.text = "Schiff: %s | Ladung: %.1f / %.1f Schiffspfund" % [
		_ship_type_name(PLAYER_SHIP_TYPE_ID),
		_player_cargo_load(),
		_player_cargo_capacity()
	]
	trade_content.add_child(capacity_label)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	trade_content.add_child(grid)

	for heading_text in ["Ware", "Bestand", "Preis", "Ladung", "Kaufen", "Verkaufen"]:
		var heading := Label.new()
		heading.text = heading_text
		heading.add_theme_font_size_override("font_size", 14)
		grid.add_child(heading)

	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		grid.add_child(_trade_cell(_good_label(good)))
		grid.add_child(_trade_cell("%.1f" % simulation.get_stock(city_id, good_id)))
		grid.add_child(_trade_cell("%d" % simulation.get_price(city_id, good_id)))
		grid.add_child(_trade_cell("%.1f" % _player_cargo_amount(good_id)))

		var buy := Button.new()
		buy.text = "+1"
		buy.disabled = _player_cargo_remaining() <= 0.0 or simulation.get_stock(city_id, good_id) <= 0.0
		buy.pressed.connect(_on_player_buy_good.bind(city_id, good_id))
		grid.add_child(buy)

		var sell := Button.new()
		sell.text = "-1"
		sell.disabled = _player_cargo_amount(good_id) <= 0.0
		sell.pressed.connect(_on_player_sell_good.bind(city_id, good_id))
		grid.add_child(sell)

	var close := Button.new()
	close.text = "Schliessen"
	close.pressed.connect(func() -> void: trade_popup.hide())
	trade_content.add_child(close)

func _trade_cell(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(74, 0)
	return label

func _on_player_buy_good(city_id: String, good_id: String) -> void:
	var requested_amount: float = min(PLAYER_TRADE_AMOUNT, _player_cargo_remaining())
	if requested_amount <= 0.0:
		return

	var purchase: Dictionary = simulation.buy_from_city(city_id, good_id, requested_amount)
	var amount: float = float(purchase.get("amount", 0.0))
	if amount <= 0.0:
		return

	var cargo: Dictionary = player_ship.get("cargo", {})
	var entry: Dictionary = cargo.get(good_id, {"amount": 0.0, "avg_price": 0.0})
	var old_amount: float = float(entry.get("amount", 0.0))
	var old_avg_price: float = float(entry.get("avg_price", 0.0))
	var new_amount: float = old_amount + amount
	entry["amount"] = new_amount
	entry["avg_price"] = (old_avg_price * old_amount + float(purchase.get("unit_price", 0)) * amount) / max(new_amount, 0.001)
	cargo[good_id] = entry
	player_ship["cargo"] = cargo
	_refresh_ui()

func _on_player_sell_good(city_id: String, good_id: String) -> void:
	var cargo: Dictionary = player_ship.get("cargo", {})
	if not cargo.has(good_id):
		return

	var entry: Dictionary = cargo[good_id]
	var amount: float = min(PLAYER_TRADE_AMOUNT, float(entry.get("amount", 0.0)))
	if amount <= 0.0:
		return

	var sale: Dictionary = simulation.sell_to_city(city_id, good_id, amount)
	var sold_amount: float = float(sale.get("amount", 0.0))
	entry["amount"] = max(0.0, float(entry.get("amount", 0.0)) - sold_amount)
	if float(entry.get("amount", 0.0)) <= 0.001:
		cargo.erase(good_id)
	else:
		cargo[good_id] = entry
	player_ship["cargo"] = cargo
	_refresh_ui()

func _player_cargo_amount(good_id: String) -> float:
	var cargo: Dictionary = player_ship.get("cargo", {})
	if not cargo.has(good_id):
		return 0.0
	var entry: Dictionary = cargo[good_id]
	return float(entry.get("amount", 0.0))

func _player_cargo_load() -> float:
	var cargo: Dictionary = player_ship.get("cargo", {})
	var amount := 0.0
	for good_id in cargo.keys():
		var entry: Dictionary = cargo[good_id]
		amount += float(entry.get("amount", 0.0))
	return amount

func _player_cargo_capacity() -> float:
	var ship_type: Dictionary = ship_type_by_id.get(PLAYER_SHIP_TYPE_ID, {})
	return float(ship_type.get("cargo_capacity", 100.0))

func _player_cargo_remaining() -> float:
	return max(0.0, _player_cargo_capacity() - _player_cargo_load())

func _ship_type_name(ship_type_id: String) -> String:
	var ship_type: Dictionary = ship_type_by_id.get(ship_type_id, {})
	return String(ship_type.get("name", ship_type_id))

func _initialize_ai_traders() -> void:
	var city_ids: Array[String] = simulation.city_ids()
	if city_ids.is_empty():
		return

	ai_traders.clear()
	for index in range(AI_TRADER_COUNT):
		var trader: Dictionary = {
			"id": "ai_trader_%02d" % [index + 1],
			"name": "Haendler %d" % [index + 1],
			"ship_type": AI_SHIP_TYPE_ID,
			"current_city": city_ids[index % city_ids.size()],
			"from": "",
			"to": "",
			"elapsed_days": 0.0,
			"cargo": {},
			"profile": _create_trader_profile(index),
		}
		ai_traders.append(trader)
		_plan_trader_trip(trader)

func _create_trader_profile(index: int) -> Dictionary:
	var base: float = float(index) / max(1.0, float(AI_TRADER_COUNT - 1))
	return {
		"efficiency": clampf(0.45 + base * 0.35 + rng.randf_range(-0.08, 0.08), 0.25, 0.9),
		"risk": clampf(0.35 + rng.randf_range(0.0, 0.5), 0.2, 0.9),
		"patience": clampf(0.35 + rng.randf_range(0.0, 0.5), 0.2, 0.9),
		"supply_focus": clampf(0.35 + rng.randf_range(0.0, 0.5), 0.2, 0.9),
		"regionality": clampf(0.35 + rng.randf_range(0.0, 0.5), 0.2, 0.9),
		"production_focus": clampf(0.35 + rng.randf_range(0.0, 0.5), 0.2, 0.9),
		"target_fill": clampf(0.55 + rng.randf_range(0.0, 0.35), 0.4, 0.95),
	}

func _advance_ai_traders(days_delta: float) -> void:
	for trader_entry in ai_traders:
		var trader: Dictionary = trader_entry
		var remaining_days: float = days_delta
		while remaining_days > 0.0:
			var travel_days: float = _ship_segment_travel_days(trader)
			if travel_days <= 0.0:
				_arrive_trader(trader)
				break

			var elapsed: float = float(trader.get("elapsed_days", 0.0))
			var segment_remaining: float = travel_days - elapsed
			if remaining_days < segment_remaining:
				trader["elapsed_days"] = elapsed + remaining_days
				break

			remaining_days -= segment_remaining
			trader["elapsed_days"] = 0.0
			_arrive_trader(trader)

func _arrive_trader(trader: Dictionary) -> void:
	var destination: String = String(trader.get("to", ""))
	if destination.is_empty():
		return

	trader["current_city"] = destination
	_sell_trader_cargo(trader, destination)
	_plan_trader_trip(trader)

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
	return String(ship.get("from", ship.get("current_city", "")))

func _ship_to_city(ship: Dictionary) -> String:
	return String(ship.get("to", ship.get("current_city", "")))

func _ship_progress(ship: Dictionary) -> float:
	var travel_days: float = _ship_segment_travel_days(ship)
	if travel_days <= 0.0:
		return 1.0
	return clampf(float(ship.get("elapsed_days", 0.0)) / travel_days, 0.0, 1.0)

func _map_ship_entries() -> Array:
	var ships: Array = []
	if not player_ship.is_empty():
		ships.append({
			"name": String(player_ship.get("name", "Spieler")),
			"position": player_ship.get("position", {}),
			"path_points": player_ship.get("path_points", [player_ship.get("position", {})]),
			"progress": _player_progress(),
			"color": Color(0.76, 0.93, 1.0),
		})
	for ship_entry in ai_traders:
		var ship: Dictionary = ship_entry
		ships.append({
			"name": String(ship.get("name", "")),
			"from": _ship_from_city(ship),
			"to": _ship_to_city(ship),
			"progress": _ship_progress(ship),
		})
	return ships

func _travel_preview() -> String:
	var lines: Array[String] = ["[b]Spieler[/b]", _player_status_line(), "", "[b]KI-Haendler[/b]", "Log: user://balance_metrics.jsonl"]
	for ship_entry in ai_traders:
		var ship: Dictionary = ship_entry
		var travel_days: float = _ship_segment_travel_days(ship)
		var remaining_days: float = max(0.0, travel_days - float(ship.get("elapsed_days", 0.0)))
		lines.append("%s: unterwegs | %.1f Tage bis zum naechsten Hafen" % [
			String(ship.get("name", "")),
			remaining_days
		])
	return "\n".join(lines)

func _player_status_line() -> String:
	if player_ship.is_empty():
		return "Kein Spielerschiff"

	if bool(player_ship.get("is_travelling", false)):
		var target_city_id := String(player_ship.get("target_city", ""))
		var target_label := _city_name(target_city_id) if not target_city_id.is_empty() else "Wasserziel"
		return "%s: unterwegs nach %s | %.1f Tage Rest | Ladung %.1f / %.1f" % [
			String(player_ship.get("name", "Spieler")),
			target_label,
			_player_remaining_travel_days(),
			_player_cargo_load(),
			_player_cargo_capacity()
		]

	var city_id := String(player_ship.get("current_city", ""))
	var location := _city_name(city_id) if not city_id.is_empty() else "auf See"
	return "%s: %s | Ladung %.1f / %.1f" % [
		String(player_ship.get("name", "Spieler")),
		location,
		_player_cargo_load(),
		_player_cargo_capacity()
	]

func _plan_trader_trip(trader: Dictionary) -> void:
	var from_city_id: String = String(trader.get("current_city", ""))
	var target_city_id: String = _choose_target_city(trader, from_city_id)
	trader["from"] = from_city_id
	trader["to"] = target_city_id
	trader["elapsed_days"] = 0.0
	_buy_trader_cargo(trader, from_city_id, target_city_id)
	_log_trader_event("trader_depart", trader, {
		"from": from_city_id,
		"to": target_city_id,
		"travel_days": _ship_segment_travel_days(trader),
		"cargo": trader.get("cargo", {}),
	})

func _choose_target_city(trader: Dictionary, from_city_id: String) -> String:
	var candidates: Array[Dictionary] = []
	for city_id in simulation.city_ids():
		if city_id == from_city_id:
			continue

		var score: float = _target_city_score(trader, from_city_id, city_id)
		candidates.append({"city_id": city_id, "score": score})

	if candidates.is_empty():
		return from_city_id

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	var profile: Dictionary = trader.get("profile", {})
	var candidate_count: int = clampi(roundi(3.0 + float(profile.get("efficiency", 0.5)) * 5.0), 2, candidates.size())
	var weighted_candidates: Array = candidates.slice(0, candidate_count)
	return _weighted_city_pick(weighted_candidates)

func _target_city_score(trader: Dictionary, from_city_id: String, target_city_id: String) -> float:
	var score: float = 0.0
	var profile: Dictionary = trader.get("profile", {})
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		var source_price: float = float(simulation.get_price(from_city_id, good_id))
		var target_price: float = float(simulation.get_price(target_city_id, good_id))
		var shortage: float = max(0.0, 1.0 - simulation.get_stock(target_city_id, good_id) / max(1.0, simulation.get_target_stock(target_city_id, good_id)))
		score += max(0.0, target_price - source_price) + shortage * target_price * float(profile.get("supply_focus", 0.5))

	var distance_px: float = map_view.get_route_distance_px(from_city_id, target_city_id) if map_view != null else 200.0
	var distance_penalty: float = max(1.0, distance_px / lerpf(180.0, 420.0, float(profile.get("risk", 0.5))))
	return max(0.1, score / distance_penalty)

func _weighted_city_pick(candidates: Array) -> String:
	var total_weight: float = 0.0
	for candidate in candidates:
		total_weight += max(0.1, float(candidate["score"]))

	var roll: float = rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for candidate in candidates:
		cursor += max(0.1, float(candidate["score"]))
		if roll <= cursor:
			return String(candidate["city_id"])

	return String(candidates[0]["city_id"])

func _buy_trader_cargo(trader: Dictionary, from_city_id: String, target_city_id: String) -> void:
	var profile: Dictionary = trader.get("profile", {})
	var ship_type: Dictionary = ship_type_by_id.get(String(trader.get("ship_type", AI_SHIP_TYPE_ID)), {})
	var capacity: float = float(ship_type.get("cargo_capacity", 100.0))
	var desired_load: float = capacity * float(profile.get("target_fill", 0.7)) * rng.randf_range(0.75, 1.05)
	var cargo: Dictionary = {}
	var opportunities: Array = _cargo_opportunities(from_city_id, target_city_id)
	if opportunities.is_empty():
		trader["cargo"] = cargo
		return

	var max_goods: int = mini(5, opportunities.size())
	var selected_count: int = rng.randi_range(1, max_goods)
	var selected: Array = opportunities.slice(0, selected_count)
	var total_score: float = 0.0
	for opportunity in selected:
		total_score += max(0.1, float(opportunity["score"]))

	for opportunity in selected:
		var good_id := String(opportunity["good_id"])
		var available: float = simulation.get_stock(from_city_id, good_id)
		var share: float = max(0.1, float(opportunity["score"])) / max(0.1, total_score)
		var requested: float = min(available, desired_load * share * rng.randf_range(0.65, 1.35))
		var purchase: Dictionary = simulation.buy_from_city(from_city_id, good_id, requested)
		var amount: float = float(purchase.get("amount", 0.0))
		if amount <= 0.0:
			continue

		cargo[good_id] = {
			"amount": amount,
			"avg_price": float(purchase.get("unit_price", 0)),
		}
		_log_trader_event("trader_buy", trader, {
			"city_id": from_city_id,
			"target_city_id": target_city_id,
			"good_id": good_id,
			"amount": amount,
			"unit_price": int(purchase.get("unit_price", 0)),
			"stock_after": simulation.get_stock(from_city_id, good_id),
		})

	trader["cargo"] = cargo

func _cargo_opportunities(from_city_id: String, target_city_id: String) -> Array:
	var opportunities: Array[Dictionary] = []
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		var available: float = simulation.get_stock(from_city_id, good_id)
		if available <= 0.0:
			continue

		var source_price: float = float(simulation.get_price(from_city_id, good_id))
		var target_price: float = float(simulation.get_price(target_city_id, good_id))
		var target_shortage: float = max(0.0, 1.0 - simulation.get_stock(target_city_id, good_id) / max(1.0, simulation.get_target_stock(target_city_id, good_id)))
		var score: float = max(0.0, target_price - source_price) + target_shortage * target_price * 0.45
		if score <= 0.0 and rng.randf() > 0.18:
			continue

		opportunities.append({"good_id": good_id, "score": max(0.1, score)})

	opportunities.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	return opportunities

func _sell_trader_cargo(trader: Dictionary, city_id: String) -> void:
	var cargo: Dictionary = trader.get("cargo", {})
	var profile: Dictionary = trader.get("profile", {})
	for good_id in cargo.keys():
		var entry: Dictionary = cargo[good_id]
		var amount: float = float(entry.get("amount", 0.0))
		if amount <= 0.0:
			continue

		var avg_price: float = float(entry.get("avg_price", 0.0))
		var current_price: float = float(simulation.get_price(city_id, good_id))
		var desired_margin: float = lerpf(0.03, 0.18, float(profile.get("patience", 0.5)))
		var sell_with_loss_chance: float = lerpf(0.22, 0.04, float(profile.get("patience", 0.5)))
		if current_price < avg_price * (1.0 + desired_margin) and rng.randf() > sell_with_loss_chance:
			continue

		var sale: Dictionary = simulation.sell_to_city(city_id, good_id, amount)
		_log_trader_event("trader_sell", trader, {
			"city_id": city_id,
			"good_id": String(good_id),
			"amount": float(sale.get("amount", 0.0)),
			"unit_price": int(sale.get("unit_price", 0)),
			"avg_buy_price": avg_price,
			"stock_after": simulation.get_stock(city_id, String(good_id)),
		})
		cargo.erase(good_id)

	trader["cargo"] = cargo

func _log_trader_event(event_type: String, trader: Dictionary, payload: Dictionary) -> void:
	if metrics_logger == null:
		return

	var event_payload: Dictionary = payload.duplicate(true)
	event_payload["trader_id"] = String(trader.get("id", ""))
	event_payload["trader_name"] = String(trader.get("name", ""))
	event_payload["ship_type"] = String(trader.get("ship_type", ""))
	event_payload["profile"] = trader.get("profile", {})
	metrics_logger.log_event(event_type, simulation.day, simulation_time_days, event_payload)

func _log_daily_metrics() -> void:
	if metrics_logger == null:
		return

	metrics_logger.log_daily_city_metrics(simulation.day, simulation_time_days, simulation, catalog.get("goods", []))
	for trader_entry in ai_traders:
		var trader: Dictionary = trader_entry
		var cargo: Dictionary = trader.get("cargo", {})
		var cargo_amount: float = 0.0
		for good_id in cargo.keys():
			var entry: Dictionary = cargo[good_id]
			cargo_amount += float(entry.get("amount", 0.0))

		_log_trader_event("trader_daily", trader, {
			"from": _ship_from_city(trader),
			"to": _ship_to_city(trader),
			"progress": _ship_progress(trader),
			"travel_days": _ship_segment_travel_days(trader),
			"elapsed_days": float(trader.get("elapsed_days", 0.0)),
			"cargo_amount": cargo_amount,
			"cargo": cargo,
		})

func _city_name(city_id: String) -> String:
	for city_entry in catalog.get("cities", []):
		var city: Dictionary = city_entry
		if String(city.get("id", "")) == city_id:
			return String(city.get("name", city_id))
	return city_id
