extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const SimulationState = preload("res://scripts/simulation/simulation_state.gd")
const CombatResolver = preload("res://scripts/simulation/combat_resolver.gd")
const BalanceMetricsLogger = preload("res://scripts/simulation/balance_metrics_logger.gd")
const MapView = preload("res://scripts/ui/map_view.gd")

const DEMO_ROUTE: Array[String] = ["bremen", "hamburg", "luebeck", "visby", "danzig"]
const TRADE_WINDOW_FRAME_PATH := "res://assets/ui/hanse_trade_window_frame.png"
const BASE_SHIP_PIXELS_PER_DAY := 80.0
const AI_TRADER_COUNT := 5
const AI_SHIP_TYPE_ID := "kogge"
const PLAYER_START_CITY_ID := "luebeck"
const PLAYER_SHIP_TYPE_ID := "kogge"
const PLAYER_START_CAPITAL := 2500.0
const TRADE_COLOR_GOLD := Color(0.86, 0.64, 0.28)
const TRADE_COLOR_TEXT := Color(0.95, 0.86, 0.66)
const TRADE_COLOR_MUTED := Color(0.68, 0.60, 0.45)
const TRADE_COLOR_WOOD := Color(0.16, 0.09, 0.035)
const TRADE_COLOR_DARK := Color(0.055, 0.052, 0.035)
const TRADE_COLOR_DARK_GREEN := Color(0.035, 0.12, 0.105)
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
var player_capital: float = PLAYER_START_CAPITAL
var trade_city_id: String = ""
var trade_feedback_text: String = ""
var selected_trade_good_id: String = ""
var selected_trade_quantity: int = 1
var trade_window_frame_texture: Texture2D
var ship_type_by_id: Dictionary = {}
var rng := RandomNumberGenerator.new()

var speed_select: OptionButton
var fast_forward_button: Button
var player_capital_label: Label
var player_location_label: Label
var player_ship_label: Label
var player_cargo_label: RichTextLabel
var trade_popup: Control
var trade_window_panel: Control
var trade_content: VBoxContainer
var map_view

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()
	_index_ship_types()
	_load_trade_textures()
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_resize_trade_window()

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

	sidebar.add_child(_build_player_overview_panel())
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
	subtitle.text = "Phase 0.2: Hauptgame-Prototyp mit Spielerhandel und Schiffsrouten"
	subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(subtitle)

	var version := Label.new()
	version.text = String(ProjectSettings.get_setting("application/config/version", ""))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 14)
	header.add_child(version)

	return header

func _build_player_overview_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Spieleruebersicht"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	player_capital_label = Label.new()
	player_capital_label.add_theme_font_size_override("font_size", 18)
	content.add_child(player_capital_label)

	player_location_label = Label.new()
	player_location_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(player_location_label)

	player_ship_label = Label.new()
	player_ship_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(player_ship_label)

	player_cargo_label = RichTextLabel.new()
	player_cargo_label.bbcode_enabled = true
	player_cargo_label.fit_content = true
	player_cargo_label.custom_minimum_size = Vector2(320, 160)
	content.add_child(player_cargo_label)

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
	speed_select.item_selected.connect(Callable(self, "_on_speed_selected"))
	speed_row.add_child(speed_select)

	fast_forward_button = Button.new()
	fast_forward_button.text = "Bis Ziel vorspulen"
	fast_forward_button.pressed.connect(Callable(self, "_on_fast_forward_to_destination_pressed"))
	content.add_child(fast_forward_button)

	var advance := Button.new()
	advance.text = "Tag +1"
	advance.pressed.connect(Callable(self, "_on_advance_day_pressed"))
	content.add_child(advance)

	return panel

func _build_trade_popup() -> Control:
	trade_popup = Control.new()
	trade_popup.name = "TradeWindowLayer"
	trade_popup.visible = false
	trade_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trade_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(trade_popup)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	trade_popup.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "TradeWindow"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(1500, 820)
	panel.add_theme_stylebox_override("panel", _trade_texture_style_box(trade_window_frame_texture, 105, 6, _trade_style_box(TRADE_COLOR_WOOD, TRADE_COLOR_GOLD, 3, 6)))
	trade_window_panel = panel
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_top", 58)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(margin)

	trade_content = VBoxContainer.new()
	trade_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trade_content.add_theme_constant_override("separation", 8)
	margin.add_child(trade_content)
	return trade_popup

func _refresh_ui() -> void:
	_refresh_player_overview()
	if fast_forward_button != null:
		fast_forward_button.disabled = not bool(player_ship.get("is_travelling", false))
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
	trade_feedback_text = ""
	_resize_trade_window()
	_refresh_trade_popup(city_id)
	trade_popup.visible = true
	trade_popup.move_to_front()

func _resize_trade_window() -> void:
	if trade_window_panel == null:
		return
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1600, 900)
	trade_window_panel.custom_minimum_size = Vector2(
		clampf(viewport_size.x * 0.94, 1280.0, 1560.0),
		clampf(viewport_size.y * 0.90, 680.0, 820.0)
	)

func _refresh_trade_popup(city_id: String) -> void:
	if trade_content == null:
		return
	if selected_trade_good_id.is_empty():
		selected_trade_good_id = _first_good_id()

	for child in trade_content.get_children():
		trade_content.remove_child(child)
		child.queue_free()

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	trade_content.add_child(title_row)

	var crest := Label.new()
	crest.text = "[*]"
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crest.custom_minimum_size = Vector2(58, 46)
	crest.add_theme_color_override("font_color", TRADE_COLOR_GOLD)
	crest.add_theme_font_size_override("font_size", 26)
	title_row.add_child(crest)

	var title := Label.new()
	title.text = _city_name(city_id)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TRADE_COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 22)
	title_row.add_child(title)

	var close_top := Button.new()
	close_top.text = "X"
	close_top.custom_minimum_size = Vector2(58, 46)
	_style_trade_button(close_top, Color(0.34, 0.12, 0.055))
	close_top.gui_input.connect(_on_trade_close_button_gui_input)
	title_row.add_child(close_top)

	if not trade_feedback_text.is_empty():
		var feedback := Label.new()
		feedback.text = trade_feedback_text
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_color_override("font_color", TRADE_COLOR_GOLD)
		trade_content.add_child(feedback)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	trade_content.add_child(body)

	body.add_child(_build_trade_city_panel(city_id))
	body.add_child(_build_trade_goods_panel(city_id))
	body.add_child(_build_trade_good_details_panel(city_id))
	trade_content.add_child(_build_trade_footer(city_id))

func _build_trade_city_panel(city_id: String) -> Control:
	var panel := _trade_panel_container(Vector2(230, 0))
	var content := _trade_panel_content(panel, 10)
	content.add_child(_trade_section_header("Stadtdaten"))
	content.add_child(_trade_stat_row("Einwohner", _format_int(_city_population(city_id))))
	content.add_child(_trade_stat_row("Wohlstand", _city_wealth_label(city_id)))
	content.add_child(_trade_stat_row("Ruf", "Angesehen"))
	content.add_child(_trade_stat_row("Steuersatz", "12%"))
	content.add_child(_trade_stat_row("Hafenstatus", "Sehr gut"))
	content.add_child(_trade_stat_row("Versorgung", _city_supply_label(city_id)))
	return panel

func _build_trade_goods_panel(city_id: String) -> Control:
	var panel := _trade_panel_container(Vector2(620, 0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content := _trade_panel_content(panel, 0)

	var table_scroll := ScrollContainer.new()
	table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(table_scroll)

	var grid := GridContainer.new()
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	table_scroll.add_child(grid)

	for heading_text in ["Ware", "Stadt", "Preis", "Schiff", "Schnitt", "Kauf", "Verkauf"]:
		grid.add_child(_trade_header_cell(heading_text))

	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		var is_selected := good_id == selected_trade_good_id
		grid.add_child(_trade_value_cell(_good_label(good), 168.0, HORIZONTAL_ALIGNMENT_LEFT, is_selected))
		grid.add_child(_trade_value_cell("%d" % simulation.get_stock(city_id, good_id), 64.0, HORIZONTAL_ALIGNMENT_RIGHT, is_selected))
		grid.add_child(_trade_value_cell("%d" % simulation.get_price(city_id, good_id), 58.0, HORIZONTAL_ALIGNMENT_RIGHT, is_selected))
		grid.add_child(_trade_value_cell("%d" % _player_cargo_amount(good_id), 58.0, HORIZONTAL_ALIGNMENT_RIGHT, is_selected))
		grid.add_child(_trade_value_cell(_player_average_price_text(good_id), 72.0, HORIZONTAL_ALIGNMENT_RIGHT, is_selected))

		var buy := Button.new()
		buy.text = "Kaufen"
		buy.custom_minimum_size = Vector2(76, 32)
		buy.disabled = _player_max_buyable_amount(city_id, good_id) <= 0
		buy.set_meta("city_id", city_id)
		buy.set_meta("good_id", good_id)
		_style_trade_button(buy, Color(0.13, 0.28, 0.10))
		buy.gui_input.connect(_on_player_buy_button_gui_input.bind(buy))
		grid.add_child(buy)

		var sell := Button.new()
		sell.text = "Verk."
		sell.custom_minimum_size = Vector2(76, 32)
		sell.disabled = _player_cargo_amount(good_id) <= 0
		sell.set_meta("city_id", city_id)
		sell.set_meta("good_id", good_id)
		_style_trade_button(sell, Color(0.34, 0.12, 0.055))
		sell.gui_input.connect(_on_player_sell_button_gui_input.bind(sell))
		grid.add_child(sell)
	return panel

func _build_trade_good_details_panel(city_id: String) -> Control:
	var panel := _trade_panel_container(Vector2(280, 0))
	var content := _trade_panel_content(panel, 10)
	content.add_child(_trade_section_header("Ausgewaehlte Ware"))

	var good := _good_by_id(selected_trade_good_id)
	var good_id := String(good.get("id", selected_trade_good_id))
	var title := Label.new()
	title.text = String(good.get("name", good_id))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TRADE_COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)

	content.add_child(_trade_stat_row("Einheit", String(good.get("unit", {}).get("abbreviation", ""))))
	content.add_child(_trade_stat_row("Stadtbestand", "%d" % simulation.get_stock(city_id, good_id)))
	content.add_child(_trade_stat_row("Eigene Ladung", "%d" % _player_cargo_amount(good_id)))
	content.add_child(_trade_stat_row("Durchschnitt", _player_average_price_text(good_id)))
	content.add_child(_trade_stat_row("Aktive Menge", _selected_trade_quantity_text()))
	content.add_child(_trade_section_header("Menge"))
	content.add_child(_build_trade_quantity_controls())

	var price_box := HBoxContainer.new()
	price_box.add_theme_constant_override("separation", 8)
	content.add_child(price_box)
	price_box.add_child(_trade_price_card("Einkauf", "%d" % simulation.get_price(city_id, good_id), Color(0.36, 0.12, 0.08)))
	price_box.add_child(_trade_price_card("Verkauf", "%d" % simulation.get_price(city_id, good_id), Color(0.13, 0.25, 0.12)))
	return panel

func _build_trade_footer(city_id: String) -> Control:
	var panel := _trade_panel_container(Vector2(0, 74))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	row.add_child(_trade_footer_stat("Stadtbestand", "%d Einheiten" % _city_total_stock(city_id)))
	row.add_child(_trade_footer_stat("Schiffsladung", "%d / %d" % [_player_cargo_load(), _player_cargo_capacity()]))
	row.add_child(_trade_footer_stat("Bargeld", "%s Silbermark" % _format_money(player_capital)))
	row.add_child(_trade_footer_stat("Letzte Aktion", trade_feedback_text if not trade_feedback_text.is_empty() else "-"))
	return panel

func _build_trade_quantity_controls() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for option in [1, 5, 10, 0]:
		var button := Button.new()
		button.text = "Max" if int(option) == 0 else "%dx" % int(option)
		button.custom_minimum_size = Vector2(56, 34)
		button.set_meta("quantity", int(option))
		var color := Color(0.18, 0.13, 0.055) if int(option) != selected_trade_quantity else Color(0.28, 0.19, 0.06)
		_style_trade_button(button, color)
		button.gui_input.connect(_on_trade_quantity_button_gui_input.bind(button))
		row.add_child(button)
	return row

func _trade_header_cell(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _trade_style_box(TRADE_COLOR_DARK_GREEN, Color(0.23, 0.18, 0.09), 1, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TRADE_COLOR_GOLD)
	label.add_theme_font_size_override("font_size", 13)
	label.custom_minimum_size = Vector2(48, 24)
	margin.add_child(label)
	return panel

func _trade_value_cell(text: String, width: float, alignment: HorizontalAlignment, is_selected: bool = false, color: Color = TRADE_COLOR_TEXT) -> Control:
	var panel := PanelContainer.new()
	var bg := Color(0.13, 0.11, 0.065) if is_selected else TRADE_COLOR_DARK
	panel.add_theme_stylebox_override("panel", _trade_style_box(bg, Color(0.22, 0.18, 0.10), 1, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	margin.add_child(label)
	return panel

func _trade_panel_container(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _trade_style_box(Color(0.075, 0.065, 0.04), Color(0.38, 0.28, 0.12), 2, 4))
	return panel

func _trade_panel_content(panel: PanelContainer, separation: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", separation)
	margin.add_child(content)
	return content

func _trade_section_header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TRADE_COLOR_GOLD)
	label.add_theme_font_size_override("font_size", 18)
	return label

func _trade_stat_row(label_text: String, value_text: String, value_color: Color = TRADE_COLOR_TEXT) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", TRADE_COLOR_TEXT)
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", value_color)
	row.add_child(value)
	return row

func _trade_footer_stat(label_text: String, value_text: String) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(170, 58)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", TRADE_COLOR_GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", TRADE_COLOR_TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value)
	return box

func _trade_price_card(label_text: String, value_text: String, bg_color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _trade_style_box(bg_color, TRADE_COLOR_GOLD, 1, 3))
	var content := _trade_panel_content(panel, 3)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TRADE_COLOR_GOLD)
	content.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_color_override("font_color", TRADE_COLOR_TEXT)
	value.add_theme_font_size_override("font_size", 24)
	content.add_child(value)
	return panel

func _style_trade_button(button: Button, bg_color: Color) -> void:
	button.add_theme_color_override("font_color", TRADE_COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", TRADE_COLOR_MUTED)
	button.add_theme_stylebox_override("normal", _trade_style_box(bg_color, TRADE_COLOR_GOLD, 2, 4))
	button.add_theme_stylebox_override("hover", _trade_style_box(bg_color.lightened(0.12), TRADE_COLOR_GOLD, 2, 4))
	button.add_theme_stylebox_override("pressed", _trade_style_box(bg_color.darkened(0.16), TRADE_COLOR_GOLD, 2, 4))
	button.add_theme_stylebox_override("disabled", _trade_style_box(Color(0.08, 0.07, 0.05), Color(0.22, 0.18, 0.10), 1, 4))

func _trade_style_box(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style

func _load_trade_textures() -> void:
	trade_window_frame_texture = _load_texture_from_file(TRADE_WINDOW_FRAME_PATH)

func _load_texture_from_file(path: String) -> Texture2D:
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		push_warning("Could not load UI texture: %s" % path)
		return null
	return texture

func _trade_texture_style_box(texture: Texture2D, margin: int, content_margin: int, fallback: StyleBox) -> StyleBox:
	if texture == null:
		return fallback

	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	style.draw_center = true
	return style

func _on_trade_close_button_gui_input(event: InputEvent) -> void:
	if _is_left_mouse_release(event):
		call_deferred("_hide_trade_window")

func _on_trade_quantity_button_gui_input(event: InputEvent, button: Button) -> void:
	if _is_left_mouse_release(event):
		selected_trade_quantity = int(button.get_meta("quantity", 1))
		call_deferred("_refresh_trade_window_after_action")

func _on_player_buy_button_pressed(button: Button) -> void:
	selected_trade_good_id = String(button.get_meta("good_id", ""))
	_on_player_buy_good(
		String(button.get_meta("city_id", "")),
		String(button.get_meta("good_id", ""))
	)

func _on_player_buy_button_gui_input(event: InputEvent, button: Button) -> void:
	if _is_left_mouse_release(event) and not button.disabled:
		call_deferred("_on_player_buy_button_pressed", button)

func _on_player_sell_button_pressed(button: Button) -> void:
	selected_trade_good_id = String(button.get_meta("good_id", ""))
	_on_player_sell_good(
		String(button.get_meta("city_id", "")),
		String(button.get_meta("good_id", ""))
	)

func _on_player_sell_button_gui_input(event: InputEvent, button: Button) -> void:
	if _is_left_mouse_release(event) and not button.disabled:
		call_deferred("_on_player_sell_button_pressed", button)

func _is_left_mouse_release(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed

func _hide_trade_window() -> void:
	if trade_popup != null:
		trade_popup.hide()

func _on_player_buy_good(city_id: String, good_id: String) -> void:
	var requested_amount: int = _player_buyable_amount(city_id, good_id)
	if requested_amount <= 0:
		trade_feedback_text = "Kauf nicht moeglich: zu wenig Kapital, kein Lagerbestand oder kein Frachtraum."
		_refresh_ui()
		return

	var purchase: Dictionary = simulation.buy_from_city(city_id, good_id, requested_amount)
	var amount: int = int(purchase.get("amount", 0))
	if amount <= 0:
		return

	var cargo: Dictionary = player_ship.get("cargo", {})
	var entry: Dictionary = cargo.get(good_id, {"amount": 0, "avg_price": 0.0})
	var old_amount: int = int(entry.get("amount", 0))
	var old_avg_price: float = float(entry.get("avg_price", 0.0))
	var new_amount: int = old_amount + amount
	entry["amount"] = new_amount
	entry["avg_price"] = (old_avg_price * float(old_amount) + float(purchase.get("unit_price", 0)) * float(amount)) / max(float(new_amount), 1.0)
	cargo[good_id] = entry
	player_ship["cargo"] = cargo
	player_capital = max(0.0, player_capital - float(purchase.get("total_price", 0.0)))
	trade_feedback_text = "Gekauft: %d %s fuer %s Silbermark." % [
		amount,
		_good_name_by_id(good_id),
		_format_money(float(purchase.get("total_price", 0.0)))
	]
	_refresh_ui()
	_refresh_trade_window_after_action()

func _on_player_sell_good(city_id: String, good_id: String) -> void:
	var cargo: Dictionary = player_ship.get("cargo", {})
	if not cargo.has(good_id):
		return

	var entry: Dictionary = cargo[good_id]
	var amount: int = _trade_limited_amount(int(entry.get("amount", 0)))
	if amount <= 0:
		return

	var sale: Dictionary = simulation.sell_to_city(city_id, good_id, amount)
	var sold_amount: int = int(sale.get("amount", 0))
	entry["amount"] = maxi(0, int(entry.get("amount", 0)) - sold_amount)
	if int(entry.get("amount", 0)) <= 0:
		cargo.erase(good_id)
	else:
		cargo[good_id] = entry
	player_ship["cargo"] = cargo
	player_capital += float(sale.get("total_price", 0.0))
	trade_feedback_text = "Verkauft: %d %s fuer %s Silbermark." % [
		sold_amount,
		_good_name_by_id(good_id),
		_format_money(float(sale.get("total_price", 0.0)))
	]
	_refresh_ui()
	_refresh_trade_window_after_action()

func _refresh_trade_window_after_action() -> void:
	if trade_popup != null and trade_popup.visible and not trade_city_id.is_empty():
		call_deferred("_refresh_trade_popup", trade_city_id)

func _player_cargo_amount(good_id: String) -> int:
	var cargo: Dictionary = player_ship.get("cargo", {})
	if not cargo.has(good_id):
		return 0
	var entry: Dictionary = cargo[good_id]
	return int(entry.get("amount", 0))

func _player_cargo_load() -> int:
	var cargo: Dictionary = player_ship.get("cargo", {})
	var amount := 0
	for good_id in cargo.keys():
		var entry: Dictionary = cargo[good_id]
		amount += int(entry.get("amount", 0))
	return amount

func _player_cargo_capacity() -> int:
	var ship_type: Dictionary = ship_type_by_id.get(PLAYER_SHIP_TYPE_ID, {})
	return int(ship_type.get("cargo_capacity", 100))

func _player_cargo_remaining() -> int:
	return maxi(0, _player_cargo_capacity() - _player_cargo_load())

func _player_buyable_amount(city_id: String, good_id: String) -> int:
	return _trade_limited_amount(_player_max_buyable_amount(city_id, good_id))

func _player_max_buyable_amount(city_id: String, good_id: String) -> int:
	var unit_price: int = simulation.get_price(city_id, good_id)
	if unit_price <= 0:
		return 0

	var affordable_amount: int = floori(player_capital / float(unit_price))
	return mini(mini(_player_cargo_remaining(), simulation.get_stock(city_id, good_id)), affordable_amount)

func _trade_limited_amount(max_amount: int) -> int:
	if max_amount <= 0:
		return 0
	if selected_trade_quantity <= 0:
		return max_amount
	return mini(selected_trade_quantity, max_amount)

func _selected_trade_quantity_text() -> String:
	if selected_trade_quantity <= 0:
		return "Max"
	return "%dx" % selected_trade_quantity

func _player_average_price_text(good_id: String) -> String:
	var cargo: Dictionary = player_ship.get("cargo", {})
	if not cargo.has(good_id):
		return "-"

	var entry: Dictionary = cargo[good_id]
	var amount: int = int(entry.get("amount", 0))
	if amount <= 0:
		return "-"

	return _format_money(float(entry.get("avg_price", 0.0)))

func _trade_window_cargo_summary() -> String:
	var lines: Array[String] = [
		"[b]Schiffsbestand[/b] %d / %d Schiffspfund" % [_player_cargo_load(), _player_cargo_capacity()]
	]
	var cargo: Dictionary = player_ship.get("cargo", {})
	if cargo.is_empty():
		lines.append("Leer")
		return "\n".join(lines)

	for good_id in cargo.keys():
		var entry: Dictionary = cargo[good_id]
		lines.append("%s: %d | Durchschnitt %s" % [
			_good_name_by_id(String(good_id)),
			int(entry.get("amount", 0)),
			_format_money(float(entry.get("avg_price", 0.0)))
		])
	return "\n".join(lines)

func _ship_type_name(ship_type_id: String) -> String:
	var ship_type: Dictionary = ship_type_by_id.get(ship_type_id, {})
	return String(ship_type.get("name", ship_type_id))

func _refresh_player_overview() -> void:
	if player_capital_label != null:
		player_capital_label.text = "Kapital: %s Silbermark" % _format_money(player_capital)
	if player_location_label != null:
		player_location_label.text = "Position: %s | Tag %.2f" % [_player_location_text(), simulation_time_days]
	if player_ship_label != null:
		player_ship_label.text = "Schiff: %s | Ladung %d / %d Schiffspfund" % [
			_ship_type_name(PLAYER_SHIP_TYPE_ID),
			_player_cargo_load(),
			_player_cargo_capacity()
		]
	if player_cargo_label != null:
		player_cargo_label.text = _player_cargo_preview()

func _player_location_text() -> String:
	if player_ship.is_empty():
		return "kein Spielerschiff"

	if bool(player_ship.get("is_travelling", false)):
		var target_city_id := String(player_ship.get("target_city", ""))
		var target_label := _city_name(target_city_id) if not target_city_id.is_empty() else "Wasserziel"
		return "unterwegs nach %s, %.1f Tage Rest" % [target_label, _player_remaining_travel_days()]

	var city_id := String(player_ship.get("current_city", ""))
	if city_id.is_empty():
		return "auf See"
	return _city_name(city_id)

func _player_cargo_preview() -> String:
	if player_ship.is_empty():
		return "[b]Ladung[/b]\nKein aktives Schiff."

	var cargo: Dictionary = player_ship.get("cargo", {})
	if cargo.is_empty():
		return "[b]Ladung[/b]\nLeer"

	var lines: Array[String] = ["[b]Ladung[/b]"]
	for good_id in cargo.keys():
		var entry: Dictionary = cargo[good_id]
		lines.append("%s: %d | Durchschnitt %s" % [
			_good_name_by_id(String(good_id)),
			int(entry.get("amount", 0)),
			_format_money(float(entry.get("avg_price", 0.0)))
		])
	return "\n".join(lines)

func _good_name_by_id(good_id: String) -> String:
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		if String(good.get("id", "")) == good_id:
			return String(good.get("name", good_id))
	return good_id

func _good_by_id(good_id: String) -> Dictionary:
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		if String(good.get("id", "")) == good_id:
			return good
	return catalog.get("goods", [])[0] if not catalog.get("goods", []).is_empty() else {}

func _first_good_id() -> String:
	if catalog.get("goods", []).is_empty():
		return ""
	var good: Dictionary = catalog.get("goods", [])[0]
	return String(good.get("id", ""))

func _city_population(city_id: String) -> int:
	for city_entry in catalog.get("cities", []):
		var city: Dictionary = city_entry
		if String(city.get("id", "")) == city_id:
			return int(city.get("population", 0))
	return 0

func _city_total_stock(city_id: String) -> int:
	var total := 0
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		total += simulation.get_stock(city_id, String(good.get("id", "")))
	return total

func _city_wealth_label(city_id: String) -> String:
	var total_stock := _city_total_stock(city_id)
	if total_stock >= 1500:
		return "Reich"
	if total_stock >= 950:
		return "Solide"
	return "Knapp"

func _city_supply_label(city_id: String) -> String:
	var low_count := 0
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		if _stock_ratio(city_id, good_id) < 0.75:
			low_count += 1
	if low_count <= 2:
		return "Gut"
	if low_count <= 5:
		return "Angespannt"
	return "Kritisch"

func _trade_demand_label(city_id: String, good_id: String) -> String:
	var ratio := _stock_ratio(city_id, good_id)
	if ratio >= 1.25:
		return "Ueberschuss"
	if ratio >= 0.9:
		return "Ausgeglichen"
	if ratio >= 0.65:
		return "Knapp"
	return "Sehr hoch"

func _trade_demand_color(city_id: String, good_id: String) -> Color:
	var ratio := _stock_ratio(city_id, good_id)
	if ratio >= 1.25:
		return Color(0.48, 0.82, 0.28)
	if ratio >= 0.9:
		return TRADE_COLOR_GOLD
	if ratio >= 0.65:
		return Color(0.95, 0.48, 0.20)
	return Color(0.95, 0.24, 0.16)

func _stock_ratio(city_id: String, good_id: String) -> float:
	return float(simulation.get_stock(city_id, good_id)) / max(1.0, float(simulation.get_target_stock(city_id, good_id)))

func _format_int(value: int) -> String:
	var text := str(value)
	var result := ""
	var counter := 0
	for index in range(text.length() - 1, -1, -1):
		if counter > 0 and counter % 3 == 0:
			result = "." + result
		result = text.substr(index, 1) + result
		counter += 1
	return result

func _format_money(value: float) -> String:
	return "%d" % roundi(value)

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
			"color": Color(1.0, 1.0, 1.0, 1.0),
			"is_player": true,
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
		return "%s: unterwegs nach %s | %.1f Tage Rest | Ladung %d / %d" % [
			String(player_ship.get("name", "Spieler")),
			target_label,
			_player_remaining_travel_days(),
			_player_cargo_load(),
			_player_cargo_capacity()
		]

	var city_id := String(player_ship.get("current_city", ""))
	var location := _city_name(city_id) if not city_id.is_empty() else "auf See"
	return "%s: %s | Ladung %d / %d" % [
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
		var available: int = simulation.get_stock(from_city_id, good_id)
		var share: float = max(0.1, float(opportunity["score"])) / max(0.1, total_score)
		var requested: float = min(available, desired_load * share * rng.randf_range(0.65, 1.35))
		var purchase: Dictionary = simulation.buy_from_city(from_city_id, good_id, requested)
		var amount: int = int(purchase.get("amount", 0))
		if amount <= 0:
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
		var available: int = simulation.get_stock(from_city_id, good_id)
		if available <= 0:
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
		var amount: int = int(entry.get("amount", 0))
		if amount <= 0:
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
		var cargo_amount: int = 0
		for good_id in cargo.keys():
			var entry: Dictionary = cargo[good_id]
			cargo_amount += int(entry.get("amount", 0))

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
