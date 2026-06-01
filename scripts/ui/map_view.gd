extends Control

signal editor_city_clicked(city_id: String)
signal editor_city_position_changed(city_id: String, position: Dictionary)
signal map_right_clicked(source_position: Dictionary, city_id: String, is_water: bool)
signal navigation_waterway_changed(summary: Dictionary)

const SOURCE_MAP_SIZE := Vector2(1600.0, 900.0)
const HANSE_REGION_MAP: Texture2D = preload("res://assets/maps/hanse_region_1600x900.png")
const HANSE_NAVIGATION_DATA := "res://assets/maps/hanse_navigation_1600x900.json"
const CUSTOM_MAP_BACKGROUND_PATH := "user://custom_map_background.png"
const CUSTOM_NAVIGATION_WATERWAYS_PATH := "user://custom_navigation_waterways.json"
const SHIP_DIRECTION_TEXTURES := [
	preload("res://assets/ships/directions/hanse_cog_dir_00_e.png"),
	preload("res://assets/ships/directions/hanse_cog_dir_01_se.png"),
	preload("res://assets/ships/directions/hanse_cog_dir_02_s.png"),
	preload("res://assets/ships/directions/hanse_cog_dir_03_sw.png"),
	preload("res://assets/ships/directions/hanse_cog_dir_04_w.png"),
	preload("res://assets/ships/directions/hanse_cog_dir_05_nw.png"),
	preload("res://assets/ships/directions/hanse_cog_dir_06_n.png"),
	preload("res://assets/ships/directions/hanse_cog_dir_07_ne.png"),
]
const MIN_ZOOM := 1.0
const MAX_ZOOM := 5.0
const ZOOM_STEP := 1.18
const PLAYER_SHIP_ICON_SIZE := Vector2(54.0, 54.0)
const AI_SHIP_ICON_SIZE := Vector2(38.0, 38.0)
const GAME_CITY_MARKER_RADIUS := 8.0
const EDITOR_CITY_MARKER_RADIUS := 4.0
const EDITOR_SELECTED_CITY_MARKER_RADIUS := 5.5

var cities: Array = []
var navigation_routes: Dictionary = {}
var navigation_city_harbors: Dictionary = {}
var navigation_grid_rows: Array = []
var navigation_sea_grid_rows: Array = []
var navigation_grid_width: int = 0
var navigation_grid_height: int = 0
var navigation_grid_cell_size: int = 4
var manual_navigation_added_cells: Dictionary = {}
var manual_navigation_removed_cells: Dictionary = {}
var water_pathfinder: AStarGrid2D
var dynamic_city_route_cache: Dictionary = {}
var route_ships: Array = []
var editor_cities: Array = []
var placed_editor_city_ids: Array[String] = []
var selected_editor_city_id: String = ""
var is_editor_position_edit_enabled: bool = false
var dragged_editor_city_id: String = ""
var pirate_zones: Array = []
var simulation_day: int = 1
var show_game_layer: bool = true
var show_editor_layer: bool = false
var show_route_lines: bool = true
var show_navigation_debug: bool = false
var is_navigation_waterway_edit_enabled: bool = false
var navigation_waterway_edit_mode: String = "add"
var navigation_waterway_brush_radius: int = 2
var is_painting_navigation_waterway: bool = false
var map_texture: Texture2D = HANSE_REGION_MAP
var map_zoom: float = 1.0
var map_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var hovered_city_name: String = ""
var hover_screen_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(760, 520)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_load_navigation_data()
	if FileAccess.file_exists(CUSTOM_MAP_BACKGROUND_PATH):
		set_map_texture_from_path(CUSTOM_MAP_BACKGROUND_PATH)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_zoom_at(mouse_event.position, ZOOM_STEP)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_zoom_at(mouse_event.position, 1.0 / ZOOM_STEP)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_emit_game_right_click(mouse_event.position)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.double_click:
				_reset_zoom()
				accept_event()
				return
			if show_editor_layer and is_navigation_waterway_edit_enabled:
				if mouse_event.pressed:
					is_painting_navigation_waterway = true
					_paint_navigation_waterway_at_screen_position(mouse_event.position)
				else:
					is_painting_navigation_waterway = false
				accept_event()
				return
			if show_editor_layer and is_editor_position_edit_enabled:
				if mouse_event.pressed:
					var clicked_editor_city_id := _editor_city_id_at_screen_position(mouse_event.position)
					if clicked_editor_city_id.is_empty():
						clicked_editor_city_id = selected_editor_city_id
					if not clicked_editor_city_id.is_empty():
						dragged_editor_city_id = clicked_editor_city_id
						editor_city_clicked.emit(clicked_editor_city_id)
						_move_editor_city_to_screen_position(clicked_editor_city_id, mouse_event.position)
					accept_event()
					return
				dragged_editor_city_id = ""
				accept_event()
				return
			if mouse_event.pressed:
				var clicked_city_id := _editor_city_id_at_screen_position(mouse_event.position)
				if not clicked_city_id.is_empty():
					editor_city_clicked.emit(clicked_city_id)
					_update_hovered_city(mouse_event.position)
					accept_event()
					return
			is_panning = mouse_event.pressed
			accept_event()
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if is_painting_navigation_waterway and is_navigation_waterway_edit_enabled:
			_paint_navigation_waterway_at_screen_position(motion_event.position)
			_update_hovered_city(motion_event.position)
			accept_event()
		elif not dragged_editor_city_id.is_empty():
			_move_editor_city_to_screen_position(dragged_editor_city_id, motion_event.position)
			_update_hovered_city(motion_event.position)
			accept_event()
		elif is_panning and map_zoom > MIN_ZOOM:
			map_offset += motion_event.relative
			_clamp_map_offset()
			_update_hovered_city(motion_event.position)
			queue_redraw()
			accept_event()
		else:
			_update_hovered_city(motion_event.position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_clamp_map_offset()
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		hovered_city_name = ""
		queue_redraw()

func set_catalog(catalog: Dictionary) -> void:
	cities = catalog.get("cities", [])
	editor_cities = catalog.get("hanse_cities", [])
	pirate_zones = catalog.get("pirate_zones", [])
	dynamic_city_route_cache.clear()
	queue_redraw()

func set_map_editor_selection(city_id: String, placed_city_ids: Array[String]) -> void:
	selected_editor_city_id = city_id
	placed_editor_city_ids = placed_city_ids.duplicate()
	queue_redraw()

func set_editor_position_edit_enabled(is_enabled: bool) -> void:
	is_editor_position_edit_enabled = is_enabled
	if not is_editor_position_edit_enabled:
		dragged_editor_city_id = ""
	queue_redraw()

func set_editor_city_position(city_id: String, position: Dictionary) -> void:
	_set_editor_city_position(city_id, position, false)

func set_simulation_day(day: int) -> void:
	simulation_day = day
	queue_redraw()

func set_route_ships(ships: Array) -> void:
	route_ships = ships.duplicate(true)
	queue_redraw()

func set_layers(is_game_layer_visible: bool, is_editor_layer_visible: bool) -> void:
	show_game_layer = is_game_layer_visible
	show_editor_layer = is_editor_layer_visible
	queue_redraw()

func set_route_lines_visible(is_visible: bool) -> void:
	show_route_lines = is_visible
	queue_redraw()

func set_navigation_debug_visible(is_visible: bool) -> void:
	show_navigation_debug = is_visible
	queue_redraw()

func set_navigation_waterway_edit_enabled(is_enabled: bool) -> void:
	is_navigation_waterway_edit_enabled = is_enabled
	if not is_navigation_waterway_edit_enabled:
		is_painting_navigation_waterway = false
	show_navigation_debug = show_navigation_debug or is_enabled
	queue_redraw()

func set_navigation_waterway_edit_mode(mode: String) -> void:
	if mode == "remove":
		navigation_waterway_edit_mode = "remove"
	else:
		navigation_waterway_edit_mode = "add"

func set_navigation_waterway_brush_radius(radius_cells: int) -> void:
	navigation_waterway_brush_radius = clampi(radius_cells, 1, 8)

func save_manual_navigation_waterways() -> bool:
	var added_cells := _sorted_manual_navigation_cells(manual_navigation_added_cells)
	var removed_cells := _sorted_manual_navigation_cells(manual_navigation_removed_cells)
	var file := FileAccess.open(CUSTOM_NAVIGATION_WATERWAYS_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify({
		"version": 1,
		"source_size": {"x": int(SOURCE_MAP_SIZE.x), "y": int(SOURCE_MAP_SIZE.y)},
		"grid": {
			"cell_size": navigation_grid_cell_size,
			"width": navigation_grid_width,
			"height": navigation_grid_height
		},
		"added_cells": added_cells,
		"removed_cells": removed_cells
	}, "\t"))
	file.close()
	return true

func reset_manual_navigation_waterways() -> void:
	manual_navigation_added_cells.clear()
	manual_navigation_removed_cells.clear()
	_rebuild_navigation_grid()
	if FileAccess.file_exists(CUSTOM_NAVIGATION_WATERWAYS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CUSTOM_NAVIGATION_WATERWAYS_PATH))
	navigation_waterway_changed.emit(_manual_navigation_summary())

func set_map_texture_from_path(path: String) -> bool:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_warning("Could not load map image: %s" % path)
		return false

	map_texture = ImageTexture.create_from_image(image)
	queue_redraw()
	return true

func reset_map_texture() -> void:
	map_texture = HANSE_REGION_MAP
	queue_redraw()

func _draw() -> void:
	draw_set_transform(map_offset, 0.0, Vector2(map_zoom, map_zoom))
	_draw_map_background()
	if show_navigation_debug:
		_draw_navigation_debug_overlay()
	_draw_pirate_zones()
	if show_game_layer:
		if show_route_lines:
			_draw_routes()
		_draw_cities()
		_draw_route_ships()
	if show_editor_layer:
		_draw_editor_cities()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_city_names_overlay()
	_draw_legend()
	_draw_hovered_city_name()

func _draw_map_background() -> void:
	draw_texture_rect(map_texture, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.03, 0.10), true)

func _draw_navigation_debug_overlay() -> void:
	_draw_navigation_water_mask()
	_draw_selected_editor_debug_routes()

func _draw_navigation_water_mask() -> void:
	if navigation_grid_rows.is_empty() or navigation_grid_width <= 0 or navigation_grid_height <= 0:
		return

	var cell_size := Vector2(size.x / float(navigation_grid_width), size.y / float(navigation_grid_height))
	var sea_color := Color(0.10, 0.62, 0.96, 0.20)
	var access_color := Color(0.20, 0.95, 1.0, 0.34)
	var manual_color := Color(0.15, 1.0, 0.45, 0.45)
	for y in range(navigation_grid_rows.size()):
		var row := String(navigation_grid_rows[y])
		for x in range(min(row.length(), navigation_grid_width)):
			if row.substr(x, 1) == "1":
				var color := manual_color if manual_navigation_added_cells.has(_cell_key(Vector2i(x, y))) else sea_color if _is_sea_cell(x, y) else access_color
				draw_rect(Rect2(Vector2(float(x) * cell_size.x, float(y) * cell_size.y), cell_size), color, true)
			elif manual_navigation_removed_cells.has(_cell_key(Vector2i(x, y))):
				draw_rect(Rect2(Vector2(float(x) * cell_size.x, float(y) * cell_size.y), cell_size), Color(1.0, 0.18, 0.10, 0.36), true)

func _draw_selected_editor_debug_routes() -> void:
	if selected_editor_city_id.is_empty():
		return

	var target_ids: Array[String] = []
	if placed_editor_city_ids.size() > 1:
		target_ids = placed_editor_city_ids
	else:
		for city_entry in editor_cities:
			var city: Dictionary = city_entry
			target_ids.append(String(city.get("id", "")))

	for city_id in target_ids:
		if city_id.is_empty() or city_id == selected_editor_city_id:
			continue
		var route_points := _navigation_points_between(selected_editor_city_id, city_id)
		for point_index in range(route_points.size() - 1):
			draw_line(route_points[point_index], route_points[point_index + 1], Color(0.20, 0.95, 1.0, 0.50), 1.6)

func _draw_pirate_zones() -> void:
	var zone_points := [
		Vector2(size.x * 0.50, size.y * 0.48),
		Vector2(size.x * 0.62, size.y * 0.38),
		Vector2(size.x * 0.76, size.y * 0.30)
	]
	for index in range(min(pirate_zones.size(), zone_points.size())):
		var zone: Dictionary = pirate_zones[index]
		var risk: float = float(zone.get("risk", 0.0))
		var center: Vector2 = zone_points[index]
		if zone.has("position"):
			center = _scale_position(zone.get("position", {}))
		var radius: float = float(zone.get("radius", 46.0 + risk * 90.0)) * min(size.x / SOURCE_MAP_SIZE.x, size.y / SOURCE_MAP_SIZE.y)
		draw_circle(center, radius, Color(0.64, 0.12, 0.08, 0.18))
		draw_arc(center, radius, 0.0, TAU, 48, Color(0.90, 0.25, 0.16, 0.70), 2.0)

func _draw_routes() -> void:
	var route := _main_route()
	if route.size() < 2:
		return

	for index in range(route.size() - 1):
		var route_points := _navigation_points_between(route[index], route[index + 1])
		if route_points.size() < 2:
			continue
		for point_index in range(route_points.size() - 1):
			draw_line(route_points[point_index], route_points[point_index + 1], Color(0.08, 0.06, 0.03, 0.58), 5.5)
			draw_line(route_points[point_index], route_points[point_index + 1], Color(0.95, 0.78, 0.36, 0.86), 3.0)

	if not route_ships.is_empty():
		return

	var ship_position := _interpolate_demo_route(route)
	_draw_ship_icon(ship_position, AI_SHIP_ICON_SIZE, Color(1.0, 1.0, 1.0, 0.96), -0.2)

func _draw_route_ships() -> void:
	var font := get_theme_default_font()
	_draw_city_ship_markers()
	for ship_entry in route_ships:
		var ship: Dictionary = ship_entry
		if _ship_is_docked(ship):
			continue

		var ship_data := _ship_map_position_and_heading(ship)
		var ship_position: Vector2 = ship_data.get("position", size * 0.5)
		var ship_heading: float = float(ship_data.get("heading", -0.2))
		var ship_color: Color = ship.get("color", Color(0.96, 0.96, 0.88))
		var icon_size := PLAYER_SHIP_ICON_SIZE if bool(ship.get("is_player", false)) else AI_SHIP_ICON_SIZE
		_draw_ship_icon(ship_position, icon_size, ship_color, ship_heading)

		var ship_name := String(ship.get("name", ""))
		if not ship_name.is_empty():
			draw_string(font, ship_position + Vector2(icon_size.x * 0.34, -icon_size.y * 0.34), ship_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, ship_color)

func _draw_city_ship_markers() -> void:
	var docked_by_city := _docked_ships_by_city()
	for city_id in docked_by_city.keys():
		var docked_ships: Array = docked_by_city[city_id]
		if docked_ships.is_empty():
			continue

		var base_position := _city_position(String(city_id))
		var marker_position := base_position + _screen_vector(14.0, -11.0)
		var plank_from := base_position + _screen_vector(6.0, -3.5)
		var plank_to := marker_position + _screen_vector(-5.5, 3.2)
		draw_line(plank_from, plank_to, Color(0.17, 0.10, 0.055, 0.82), _screen_units(2.4))
		draw_line(plank_from, plank_to, Color(0.55, 0.36, 0.16, 0.66), _screen_units(1.0))
		draw_circle(marker_position + _screen_vector(1.2, 1.7), _screen_units(6.8), Color(0.02, 0.025, 0.022, 0.45))
		draw_circle(marker_position, _screen_units(6.4), Color(0.035, 0.16, 0.18, 0.94))
		draw_arc(marker_position, _screen_units(7.4), 0.0, TAU, 32, Color(0.73, 0.54, 0.24, 0.88), _screen_units(1.1))
		_draw_anchor_glyph(marker_position, _screen_units(1.0))
		if docked_ships.size() > 1:
			var count_font := get_theme_default_font()
			draw_circle(marker_position + _screen_vector(7.2, -5.3), _screen_units(4.0), Color(0.62, 0.12, 0.10, 0.95))
			draw_string(count_font, marker_position + _screen_vector(4.8, -2.6), "%d" % docked_ships.size(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _screen_font_size(8), Color(0.96, 0.89, 0.66))

func _draw_anchor_glyph(center: Vector2, scale: float) -> void:
	var glyph_color := Color(0.92, 0.82, 0.56, 0.96)
	draw_arc(center + Vector2(0.0, -3.6) * scale, 1.5 * scale, 0.0, TAU, 18, glyph_color, 0.85 * scale)
	draw_line(center + Vector2(0.0, -2.1) * scale, center + Vector2(0.0, 3.0) * scale, glyph_color, 1.0 * scale)
	draw_line(center + Vector2(-3.1, -0.4) * scale, center + Vector2(3.1, -0.4) * scale, glyph_color, 0.9 * scale)
	draw_arc(center + Vector2(0.0, 0.4) * scale, 4.0 * scale, 0.25 * PI, 0.75 * PI, 24, glyph_color, 1.0 * scale)
	draw_line(center + Vector2(-2.8, 3.2) * scale, center + Vector2(-4.3, 1.4) * scale, glyph_color, 0.9 * scale)
	draw_line(center + Vector2(2.8, 3.2) * scale, center + Vector2(4.3, 1.4) * scale, glyph_color, 0.9 * scale)

func _docked_ships_by_city() -> Dictionary:
	var docked_by_city: Dictionary = {}
	for ship_entry in route_ships:
		var ship: Dictionary = ship_entry
		if not _ship_is_docked(ship):
			continue

		var city_id := String(ship.get("current_city", ""))
		if city_id.is_empty():
			continue

		if not docked_by_city.has(city_id):
			docked_by_city[city_id] = []
		var docked_ships: Array = docked_by_city[city_id]
		docked_ships.append(ship)
		docked_by_city[city_id] = docked_ships
	return docked_by_city

func _ship_is_docked(ship: Dictionary) -> bool:
	return not bool(ship.get("is_travelling", false)) and not String(ship.get("current_city", "")).is_empty()

func _draw_ship_icon(ship_position: Vector2, icon_size: Vector2, modulate: Color, heading: float) -> void:
	var texture: Texture2D = _ship_direction_texture(heading)
	var icon_rect := Rect2(ship_position - icon_size * 0.5, icon_size)
	draw_texture_rect(texture, Rect2(icon_rect.position + Vector2(2.0, 3.0), icon_size), false, Color(0.0, 0.0, 0.0, 0.30))
	draw_texture_rect(texture, icon_rect, false, modulate)

func _ship_direction_texture(heading: float) -> Texture2D:
	var slice := TAU / float(SHIP_DIRECTION_TEXTURES.size())
	var mirrored_heading := PI - heading
	var index := posmod(roundi(mirrored_heading / slice), SHIP_DIRECTION_TEXTURES.size())
	return SHIP_DIRECTION_TEXTURES[index]

func _draw_cities() -> void:
	for city_entry in cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		var pos := _scale_position(get_city_harbor_position(city_id))
		draw_circle(pos + _screen_vector(1.4, 1.4), _screen_units(GAME_CITY_MARKER_RADIUS + 1.2), Color(0.02, 0.02, 0.02, 0.45))
		draw_circle(pos, _screen_units(GAME_CITY_MARKER_RADIUS), Color(0.78, 0.18, 0.14))
		draw_circle(pos, _screen_units(3.6), Color(0.96, 0.82, 0.48))
		draw_arc(pos, _screen_units(GAME_CITY_MARKER_RADIUS + 1.8), 0.0, TAU, 40, Color(0.98, 0.94, 0.72, 0.66), _screen_units(1.1))

func _draw_editor_cities() -> void:
	var font := get_theme_default_font()
	for city_entry in editor_cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		if not placed_editor_city_ids.has(city_id):
			continue

		var pos := _scale_position(city.get("position", {}))
		var is_selected := city_id == selected_editor_city_id
		var radius := EDITOR_SELECTED_CITY_MARKER_RADIUS if is_selected else EDITOR_CITY_MARKER_RADIUS
		var color := _editor_city_color(String(city.get("kind", "")))

		draw_circle(pos + _screen_vector(1.4, 1.6), _screen_units(radius + 1.2), Color(0.02, 0.02, 0.02, 0.42))
		draw_circle(pos, _screen_units(radius + 1.0), Color(0.97, 0.94, 0.82, 0.90))
		draw_circle(pos, _screen_units(radius), color)
		draw_arc(pos, _screen_units(radius + 2.5), 0.0, TAU, 48, Color(0.98, 0.96, 0.86, 0.72 if is_selected else 0.24), _screen_units(1.2))

		if is_selected:
			draw_arc(pos, _screen_units(radius + 4.0), 0.0, TAU, 48, Color(0.98, 0.96, 0.86, 0.42), _screen_units(0.9))

func _editor_city_color(kind: String) -> Color:
	match kind:
		"core":
			return Color(0.98, 0.78, 0.25)
		"kontor":
			return Color(0.94, 0.48, 0.22)
		"member":
			return Color(0.84, 0.74, 0.48)
		"trade":
			return Color(0.68, 0.80, 0.58)
		_:
			return Color(0.92, 0.90, 0.78)

func _screen_units(value: float) -> float:
	return value / max(map_zoom, 0.001)

func _screen_vector(x: float, y: float) -> Vector2:
	return Vector2(_screen_units(x), _screen_units(y))

func _screen_font_size(size_px: int) -> int:
	return max(1, roundi(float(size_px) / max(map_zoom, 0.001)))

func _draw_city_names_overlay() -> void:
	if show_game_layer:
		for city_entry in cities:
			var city: Dictionary = city_entry
			var city_id := String(city.get("id", ""))
			var label_position := _screen_position_from_map(_scale_position(get_city_harbor_position(city_id))) + Vector2(12, 5)
			_draw_map_label(String(city.get("name", "")), label_position, 13)

	if show_editor_layer:
		for city_entry in editor_cities:
			var city: Dictionary = city_entry
			var city_id := String(city.get("id", ""))
			if not placed_editor_city_ids.has(city_id):
				continue

			var label_position := _screen_position_from_map(_scale_position(city.get("position", {}))) + Vector2(10, 4)
			var is_selected := city_id == selected_editor_city_id
			_draw_map_label(String(city.get("name", "")), label_position, 12 if is_selected else 11)

func _draw_map_label(text: String, position: Vector2, font_size: int) -> void:
	if text.is_empty():
		return

	var font := get_theme_default_font()
	var shadow_color := Color(0.06, 0.045, 0.025, 0.88)
	var glow_color := Color(0.73, 0.54, 0.24, 0.32)
	draw_string(font, position + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow_color)
	draw_string(font, position + Vector2(-1.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow_color)
	draw_string(font, position + Vector2(0.0, -1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow_color)
	draw_string(font, position + Vector2(0.5, 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, glow_color)
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.96, 0.91, 0.74))

func _draw_legend() -> void:
	var font := get_theme_default_font()
	var text := "Hauptgame-Karte | Tag %d | Feste Staedte: %d | Rot: Piratenrisiko" % [
		simulation_day,
		cities.size()
	]
	if show_editor_layer:
		text = "Map Editor | Zoom: %d%% | Editorpunkte: %d / %d | %s" % [
			int(round(map_zoom * 100.0)),
			placed_editor_city_ids.size(),
			editor_cities.size(),
			"Positionsmodus" if is_editor_position_edit_enabled else "Auswahlmodus"
		]
	var legend_width := 650.0 if show_editor_layer else 590.0
	draw_rect(Rect2(Vector2(18, 18), Vector2(legend_width, 34)), Color(0.02, 0.03, 0.04, 0.55), true)
	draw_string(font, Vector2(30, 41), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.93, 0.94, 0.90))

func _draw_hovered_city_name() -> void:
	if hovered_city_name.is_empty():
		return

	var font := get_theme_default_font()
	var font_size := 15
	var padding := Vector2(9, 6)
	var text_size := font.get_string_size(hovered_city_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var panel_size := text_size + padding * 2.0
	var panel_position := hover_screen_position + Vector2(14, -panel_size.y - 10)
	panel_position.x = clamp(panel_position.x, 8.0, max(8.0, size.x - panel_size.x - 8.0))
	panel_position.y = clamp(panel_position.y, 58.0, max(58.0, size.y - panel_size.y - 8.0))

	draw_rect(Rect2(panel_position, panel_size), Color(0.02, 0.03, 0.04, 0.78), true)
	draw_rect(Rect2(panel_position, panel_size), Color(0.95, 0.90, 0.72, 0.55), false, 1.0)
	draw_string(font, panel_position + Vector2(padding.x, padding.y + font_size), hovered_city_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.98, 0.96, 0.86))

func _zoom_at(screen_position: Vector2, factor: float) -> void:
	var old_zoom: float = map_zoom
	var next_zoom: float = clampf(map_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(old_zoom, next_zoom):
		return

	var map_position_before_zoom: Vector2 = (screen_position - map_offset) / old_zoom
	map_zoom = next_zoom
	map_offset = screen_position - map_position_before_zoom * map_zoom
	_clamp_map_offset()
	_update_hovered_city(screen_position)
	queue_redraw()

func _reset_zoom() -> void:
	map_zoom = MIN_ZOOM
	map_offset = Vector2.ZERO
	is_panning = false
	hovered_city_name = ""
	queue_redraw()

func _clamp_map_offset() -> void:
	if map_zoom <= MIN_ZOOM:
		map_zoom = MIN_ZOOM
		map_offset = Vector2.ZERO
		return

	var scaled_size: Vector2 = size * map_zoom
	var min_offset: Vector2 = size - scaled_size
	map_offset.x = clamp(map_offset.x, min_offset.x, 0.0)
	map_offset.y = clamp(map_offset.y, min_offset.y, 0.0)

func _update_hovered_city(screen_position: Vector2) -> void:
	var city_name := _city_name_at_screen_position(screen_position)
	if city_name == hovered_city_name and hover_screen_position == screen_position:
		return

	hovered_city_name = city_name
	hover_screen_position = screen_position
	queue_redraw()

func _city_name_at_screen_position(screen_position: Vector2) -> String:
	if show_editor_layer:
		for city_entry in editor_cities:
			var city: Dictionary = city_entry
			var city_id: String = _editor_city_id_at_screen_position(screen_position)
			if not city_id.is_empty() and city_id == String(city.get("id", "")):
				return String(city.get("name", ""))

	if show_game_layer:
		var game_city_id := _game_city_id_at_screen_position(screen_position)
		if not game_city_id.is_empty():
			for city_entry in cities:
				var city: Dictionary = city_entry
				if String(city.get("id", "")) == game_city_id:
					return String(city.get("name", ""))

	return ""

func _editor_city_id_at_screen_position(screen_position: Vector2) -> String:
	if not show_editor_layer:
		return ""

	for city_entry in editor_cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		if not placed_editor_city_ids.has(city_id):
			continue

		var pos := _screen_position_from_map(_scale_position(city.get("position", {})))
		var base_radius := EDITOR_SELECTED_CITY_MARKER_RADIUS if city_id == selected_editor_city_id else EDITOR_CITY_MARKER_RADIUS
		var radius: float = max(7.0, base_radius + 2.5)
		if screen_position.distance_to(pos) <= radius:
			return city_id

	return ""

func _screen_position_from_map(map_position: Vector2) -> Vector2:
	return map_position * map_zoom + map_offset

func _source_position_from_screen(screen_position: Vector2) -> Dictionary:
	var map_position: Vector2 = (screen_position - map_offset) / max(map_zoom, 0.001)
	return {
		"x": clampf(map_position.x / max(size.x, 1.0) * SOURCE_MAP_SIZE.x, 0.0, SOURCE_MAP_SIZE.x),
		"y": clampf(map_position.y / max(size.y, 1.0) * SOURCE_MAP_SIZE.y, 0.0, SOURCE_MAP_SIZE.y),
	}

func _move_editor_city_to_screen_position(city_id: String, screen_position: Vector2) -> void:
	var source_position := _navigable_source_position(_source_position_from_screen(screen_position))
	var rounded_position := {
		"x": int(round(float(source_position.get("x", 0.0)))),
		"y": int(round(float(source_position.get("y", 0.0))))
	}
	_set_editor_city_position(city_id, rounded_position, true)

func _set_editor_city_position(city_id: String, position: Dictionary, should_emit: bool) -> void:
	if city_id.is_empty():
		return

	for index in range(editor_cities.size()):
		var city: Dictionary = editor_cities[index]
		if String(city.get("id", "")) != city_id:
			continue

		city["position"] = {
			"x": int(position.get("x", 0)),
			"y": int(position.get("y", 0))
		}
		editor_cities[index] = city
		dynamic_city_route_cache.clear()
		break

	if should_emit:
		editor_city_position_changed.emit(city_id, {
			"x": int(position.get("x", 0)),
			"y": int(position.get("y", 0))
		})
	queue_redraw()

func _emit_game_right_click(screen_position: Vector2) -> void:
	if not show_game_layer:
		return

	var source_position := _source_position_from_screen(screen_position)
	var city_id := _game_city_id_at_screen_position(screen_position)
	var is_water := _is_source_water_position(source_position)
	map_right_clicked.emit(source_position, city_id, is_water)

func _game_city_id_at_screen_position(screen_position: Vector2) -> String:
	if not show_game_layer:
		return ""

	for city_entry in cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		var pos := _screen_position_from_map(_scale_position(get_city_harbor_position(city_id)))
		var radius: float = max(10.0, GAME_CITY_MARKER_RADIUS + 3.0)
		if screen_position.distance_to(pos) <= radius:
			return city_id

	return ""

func _load_navigation_data() -> void:
	var text := FileAccess.get_file_as_string(HANSE_NAVIGATION_DATA)
	if text.is_empty():
		push_warning("Navigation data not found: %s" % HANSE_NAVIGATION_DATA)
		return

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Navigation data must contain a JSON object: %s" % HANSE_NAVIGATION_DATA)
		return

	var data: Dictionary = parsed
	navigation_routes = data.get("routes", {})
	navigation_city_harbors = data.get("city_harbors", {})
	var grid: Dictionary = data.get("grid", {})
	navigation_sea_grid_rows = grid.get("sea_rows", grid.get("rows", []))
	navigation_grid_width = int(grid.get("width", 0))
	navigation_grid_height = int(grid.get("height", 0))
	navigation_grid_cell_size = int(grid.get("cell_size", 4))
	_load_manual_navigation_waterways()
	_rebuild_navigation_grid()

func _rebuild_navigation_grid() -> void:
	navigation_grid_rows = _build_runtime_navigation_rows(navigation_sea_grid_rows)
	_build_water_pathfinder()
	dynamic_city_route_cache.clear()
	queue_redraw()

func _build_runtime_navigation_rows(sea_rows: Array) -> Array:
	var rows := sea_rows.duplicate()
	for city_id in navigation_city_harbors.keys():
		var harbor: Dictionary = navigation_city_harbors[city_id]
		var access_points: Array = harbor.get("sea_access_points", [])
		for index in range(access_points.size() - 1):
			_mark_navigation_line(rows, access_points[index], access_points[index + 1], 2)
		_mark_navigation_circle(rows, harbor.get("harbor_anchor", harbor.get("sea_gate", {})), 2)
		_mark_navigation_circle(rows, harbor.get("sea_gate", harbor.get("harbor_anchor", {})), 2)
	_apply_manual_navigation_overrides(rows)
	return rows

func _apply_manual_navigation_overrides(rows: Array) -> void:
	for cell_key in manual_navigation_added_cells.keys():
		_set_navigation_cell(rows, _cell_from_key(String(cell_key)), true)
	for cell_key in manual_navigation_removed_cells.keys():
		_set_navigation_cell(rows, _cell_from_key(String(cell_key)), false)

func _mark_navigation_line(rows: Array, from_position: Dictionary, to_position: Dictionary, radius_cells: int) -> void:
	if rows.is_empty():
		return

	var from_cell := _grid_cell_from_source_position(from_position)
	var to_cell := _grid_cell_from_source_position(to_position)
	var delta := to_cell - from_cell
	var steps: int = maxi(1, maxi(absi(delta.x), absi(delta.y)))
	for step in range(steps + 1):
		var progress := float(step) / float(steps)
		var cell := Vector2i(
			roundi(lerpf(float(from_cell.x), float(to_cell.x), progress)),
			roundi(lerpf(float(from_cell.y), float(to_cell.y), progress))
		)
		_mark_navigation_cell_circle(rows, cell, radius_cells)

func _mark_navigation_circle(rows: Array, position: Dictionary, radius_cells: int) -> void:
	if rows.is_empty():
		return
	_mark_navigation_cell_circle(rows, _grid_cell_from_source_position(position), radius_cells)

func _mark_navigation_cell_circle(rows: Array, center: Vector2i, radius_cells: int) -> void:
	for y in range(maxi(0, center.y - radius_cells), mini(rows.size(), center.y + radius_cells + 1)):
		var row := String(rows[y])
		for x in range(maxi(0, center.x - radius_cells), mini(row.length(), center.x + radius_cells + 1)):
			if center.distance_to(Vector2i(x, y)) <= float(radius_cells):
				row = row.substr(0, x) + "1" + row.substr(x + 1)
		rows[y] = row

func _set_navigation_cell(rows: Array, cell: Vector2i, is_water: bool) -> void:
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= navigation_grid_width:
		return

	var row := String(rows[cell.y])
	if cell.x >= row.length():
		return
	var value := "1" if is_water else "0"
	row = row.substr(0, cell.x) + value + row.substr(cell.x + 1)
	rows[cell.y] = row

func _build_water_pathfinder() -> void:
	if navigation_grid_rows.is_empty() or navigation_grid_width <= 0 or navigation_grid_height <= 0:
		water_pathfinder = null
		return

	water_pathfinder = AStarGrid2D.new()
	water_pathfinder.region = Rect2i(0, 0, navigation_grid_width, navigation_grid_height)
	water_pathfinder.cell_size = Vector2.ONE
	water_pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	water_pathfinder.update()

	for y in range(navigation_grid_height):
		var row := String(navigation_grid_rows[y])
		for x in range(navigation_grid_width):
			if x >= row.length() or row.substr(x, 1) != "1":
				water_pathfinder.set_point_solid(Vector2i(x, y), true)

func _main_route() -> Array[String]:
	var preferred_route: Array[String] = ["bremen", "hamburg", "luebeck", "visby", "danzig"]
	var loaded_city_ids: Dictionary = {}
	for city_entry in cities:
		var city: Dictionary = city_entry
		loaded_city_ids[String(city.get("id", ""))] = true

	var route: Array[String] = []
	for city_id in preferred_route:
		if loaded_city_ids.has(city_id):
			route.append(city_id)
	return route

func _city_position(city_id: String) -> Vector2:
	return _scale_position(_city_source_position(city_id))

func _navigation_points_between(from_city_id: String, to_city_id: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for point_entry in get_city_route_source_points(from_city_id, to_city_id):
		var point: Dictionary = point_entry
		points.append(_scale_position(point))
	return points

func get_city_harbor_position(city_id: String) -> Dictionary:
	return _navigable_source_position(_city_source_position(city_id))

func _city_source_position(city_id: String) -> Dictionary:
	for city_entry in cities:
		var city: Dictionary = city_entry
		if String(city.get("id", "")) == city_id:
			return _normalized_source_position(city.get("position", {}))

	for city_entry in editor_cities:
		var city: Dictionary = city_entry
		if String(city.get("id", "")) == city_id:
			return _normalized_source_position(city.get("position", {}))

	if navigation_city_harbors.has(city_id):
		var harbor: Dictionary = navigation_city_harbors[city_id]
		return _normalized_source_position(harbor.get("harbor_anchor", harbor.get("sea_gate", {})))

	return {
		"x": SOURCE_MAP_SIZE.x * 0.5,
		"y": SOURCE_MAP_SIZE.y * 0.5
	}

func _normalized_source_position(position: Dictionary) -> Dictionary:
	return {
		"x": clampf(float(position.get("x", SOURCE_MAP_SIZE.x * 0.5)), 0.0, SOURCE_MAP_SIZE.x),
		"y": clampf(float(position.get("y", SOURCE_MAP_SIZE.y * 0.5)), 0.0, SOURCE_MAP_SIZE.y)
	}

func _navigable_source_position(position: Dictionary) -> Dictionary:
	var normalized_position := _normalized_source_position(position)
	if navigation_grid_rows.is_empty() or _is_source_water_position(normalized_position):
		return normalized_position

	var water_cell := _nearest_water_cell(_grid_cell_from_source_position(normalized_position))
	if water_cell.x < 0:
		return normalized_position
	return _source_position_from_grid_cell(water_cell)

func _route_points_with_current_endpoints(source_points: Array, from_city_id: String, to_city_id: String) -> Array:
	var points := source_points.duplicate(true)
	var start_position := get_city_harbor_position(from_city_id)
	var target_position := get_city_harbor_position(to_city_id)
	if points.is_empty():
		return [start_position, target_position]

	points[0] = start_position
	if points.size() == 1:
		points.append(target_position)
	else:
		points[points.size() - 1] = target_position
	return points

func get_city_route_source_points(from_city_id: String, to_city_id: String) -> Array:
	if from_city_id.is_empty() or to_city_id.is_empty():
		return []

	var cache_key := _dynamic_city_route_cache_key(from_city_id, to_city_id)
	if dynamic_city_route_cache.has(cache_key):
		return dynamic_city_route_cache[cache_key].duplicate(true)

	var start_position := get_city_harbor_position(from_city_id)
	var target_position := get_city_harbor_position(to_city_id)
	var source_points := get_navigation_path_between_source_points(start_position, target_position)

	dynamic_city_route_cache[cache_key] = source_points.duplicate(true)
	return source_points

func _dynamic_city_route_cache_key(from_city_id: String, to_city_id: String) -> String:
	var start_position := get_city_harbor_position(from_city_id)
	var target_position := get_city_harbor_position(to_city_id)
	return "%s:%d,%d__%s:%d,%d" % [
		from_city_id,
		roundi(float(start_position.get("x", 0.0))),
		roundi(float(start_position.get("y", 0.0))),
		to_city_id,
		roundi(float(target_position.get("x", 0.0))),
		roundi(float(target_position.get("y", 0.0)))
	]

func _precomputed_city_route_source_points(from_city_id: String, to_city_id: String) -> Array:
	var key := "%s__%s" % [from_city_id, to_city_id]
	var is_reversed := false
	if not navigation_routes.has(key):
		key = "%s__%s" % [to_city_id, from_city_id]
		is_reversed = true
	if not navigation_routes.has(key):
		return [get_city_harbor_position(from_city_id), get_city_harbor_position(to_city_id)]

	var route: Dictionary = navigation_routes[key]
	var source_points: Array = route.get("points", []).duplicate(true)
	if is_reversed:
		source_points.reverse()
	return _route_points_with_current_endpoints(source_points, from_city_id, to_city_id)

func _water_path_from_route_waypoints(source_points: Array) -> Array:
	if source_points.size() < 2 or navigation_grid_rows.is_empty():
		return source_points

	var water_points: Array = []
	for index in range(source_points.size() - 1):
		var segment := get_navigation_path_between_source_points(source_points[index], source_points[index + 1])
		if segment.is_empty():
			return source_points
		if water_points.is_empty():
			water_points.append_array(segment)
		else:
			water_points.append_array(segment.slice(1))
	return _simplify_source_points(water_points)

func _simplify_source_points(source_points: Array) -> Array:
	if source_points.size() <= 2:
		return source_points

	var simplified: Array = [source_points[0]]
	var last_direction := _source_point_direction(source_points[0], source_points[1])
	for index in range(1, source_points.size() - 1):
		var next_direction := _source_point_direction(source_points[index], source_points[index + 1])
		if next_direction != last_direction:
			simplified.append(source_points[index])
			last_direction = next_direction
	simplified.append(source_points[source_points.size() - 1])
	return simplified

func _source_point_direction(from_position: Dictionary, to_position: Dictionary) -> Vector2i:
	return Vector2i(
		clampi(roundi(float(to_position.get("x", 0.0)) - float(from_position.get("x", 0.0))), -1, 1),
		clampi(roundi(float(to_position.get("y", 0.0)) - float(from_position.get("y", 0.0))), -1, 1)
	)

func get_navigation_path_between_source_points(from_position: Dictionary, to_position: Dictionary) -> Array:
	if navigation_grid_rows.is_empty():
		return [from_position, to_position]

	var start_cell := _nearest_water_cell(_grid_cell_from_source_position(from_position))
	var target_cell := _nearest_water_cell(_grid_cell_from_source_position(to_position))
	if start_cell.x < 0 or target_cell.x < 0:
		return []

	var path_cells := _find_water_path(start_cell, target_cell)
	if path_cells.is_empty():
		return []

	var points: Array = []
	points.append(_source_position_from_grid_cell(start_cell))
	var stride: int = max(1, path_cells.size() / 42)
	for index in range(0, path_cells.size(), stride):
		points.append(_source_position_from_grid_cell(path_cells[index]))
	points.append(_source_position_from_grid_cell(target_cell))
	return points

func is_source_water_position(position: Dictionary) -> bool:
	return _is_source_water_position(position)

func manual_navigation_summary() -> Dictionary:
	return _manual_navigation_summary()

func get_route_distance_px(from_city_id: String, to_city_id: String) -> float:
	var source_points := get_city_route_source_points(from_city_id, to_city_id)
	if source_points.is_empty():
		return 1000000.0
	return _source_path_distance(source_points)

func _source_path_distance(source_points: Array) -> float:
	var distance := 0.0
	for index in range(source_points.size() - 1):
		var from_position: Dictionary = source_points[index]
		var to_position: Dictionary = source_points[index + 1]
		var from_point := Vector2(float(from_position.get("x", 0.0)), float(from_position.get("y", 0.0)))
		var to_point := Vector2(float(to_position.get("x", 0.0)), float(to_position.get("y", 0.0)))
		distance += from_point.distance_to(to_point)
	return distance

func _scale_position(position: Dictionary) -> Vector2:
	return Vector2(
		float(position.get("x", 0.0)) / SOURCE_MAP_SIZE.x * size.x,
		float(position.get("y", 0.0)) / SOURCE_MAP_SIZE.y * size.y
	)

func _ship_route_points(ship: Dictionary) -> Array[Vector2]:
	if ship.has("path_points"):
		var route_points: Array[Vector2] = []
		for point_entry in ship.get("path_points", []):
			var point: Dictionary = point_entry
			route_points.append(_scale_position(point))
		if route_points.size() >= 1:
			return route_points

	if ship.has("position"):
		var position: Dictionary = ship.get("position", {})
		return [_scale_position(position)]

	var from_city_id := String(ship.get("from", ""))
	var to_city_id := String(ship.get("to", ""))
	var route_points := _navigation_points_between(from_city_id, to_city_id)
	if route_points.size() < 2:
		return [_city_position(from_city_id)]
	return route_points

func _ship_map_position_and_heading(ship: Dictionary) -> Dictionary:
	var progress := clampf(float(ship.get("progress", 0.0)), 0.0, 1.0)
	var route_points: Array[Vector2] = _ship_route_points(ship)
	var position := _interpolate_polyline(route_points, progress)
	var direction := _polyline_direction(route_points, progress)
	return {
		"position": position,
		"heading": direction.angle(),
	}

func _is_source_water_position(position: Dictionary) -> bool:
	var cell := _grid_cell_from_source_position(position)
	return _is_water_cell(cell.x, cell.y)

func _paint_navigation_waterway_at_screen_position(screen_position: Vector2) -> void:
	if navigation_grid_rows.is_empty():
		return

	var source_position := _source_position_from_screen(screen_position)
	var center_cell := _grid_cell_from_source_position(source_position)
	var changed := false
	for y in range(maxi(0, center_cell.y - navigation_waterway_brush_radius), mini(navigation_grid_height, center_cell.y + navigation_waterway_brush_radius + 1)):
		for x in range(maxi(0, center_cell.x - navigation_waterway_brush_radius), mini(navigation_grid_width, center_cell.x + navigation_waterway_brush_radius + 1)):
			var cell := Vector2i(x, y)
			if center_cell.distance_to(cell) > float(navigation_waterway_brush_radius):
				continue
			changed = _set_manual_navigation_cell(cell, navigation_waterway_edit_mode == "add") or changed

	if changed:
		_rebuild_navigation_grid()
		navigation_waterway_changed.emit(_manual_navigation_summary())

func _set_manual_navigation_cell(cell: Vector2i, is_water: bool) -> bool:
	var key := _cell_key(cell)
	if is_water:
		if manual_navigation_removed_cells.erase(key):
			return true
		if _is_base_runtime_water_cell(cell):
			return false
		if manual_navigation_added_cells.has(key):
			return false
		manual_navigation_added_cells[key] = true
		return true

	if manual_navigation_added_cells.erase(key):
		return true
	if not _is_base_runtime_water_cell(cell):
		return false
	if manual_navigation_removed_cells.has(key):
		return false
	manual_navigation_removed_cells[key] = true
	return true

func _is_base_runtime_water_cell(cell: Vector2i) -> bool:
	if _is_sea_cell(cell.x, cell.y):
		return true
	for city_id in navigation_city_harbors.keys():
		var harbor: Dictionary = navigation_city_harbors[city_id]
		var access_points: Array = harbor.get("sea_access_points", [])
		for index in range(access_points.size() - 1):
			if _cell_near_navigation_segment(cell, _grid_cell_from_source_position(access_points[index]), _grid_cell_from_source_position(access_points[index + 1]), 2):
				return true
		if cell.distance_to(_grid_cell_from_source_position(harbor.get("harbor_anchor", harbor.get("sea_gate", {})))) <= 2.0:
			return true
		if cell.distance_to(_grid_cell_from_source_position(harbor.get("sea_gate", harbor.get("harbor_anchor", {})))) <= 2.0:
			return true
	return false

func _cell_near_navigation_segment(cell: Vector2i, from_cell: Vector2i, to_cell: Vector2i, radius_cells: int) -> bool:
	var delta := to_cell - from_cell
	var steps: int = maxi(1, maxi(absi(delta.x), absi(delta.y)))
	for step in range(steps + 1):
		var progress := float(step) / float(steps)
		var line_cell := Vector2i(
			roundi(lerpf(float(from_cell.x), float(to_cell.x), progress)),
			roundi(lerpf(float(from_cell.y), float(to_cell.y), progress))
		)
		if cell.distance_to(line_cell) <= float(radius_cells):
			return true
	return false

func _grid_cell_from_source_position(position: Dictionary) -> Vector2i:
	if navigation_grid_cell_size <= 0:
		return Vector2i(-1, -1)
	return Vector2i(
		clampi(floori(float(position.get("x", 0.0)) / float(navigation_grid_cell_size)), 0, max(0, navigation_grid_width - 1)),
		clampi(floori(float(position.get("y", 0.0)) / float(navigation_grid_cell_size)), 0, max(0, navigation_grid_height - 1))
	)

func _source_position_from_grid_cell(cell: Vector2i) -> Dictionary:
	return {
		"x": float(cell.x * navigation_grid_cell_size) + float(navigation_grid_cell_size) * 0.5,
		"y": float(cell.y * navigation_grid_cell_size) + float(navigation_grid_cell_size) * 0.5,
	}

func _is_water_cell(cell_x: int, cell_y: int) -> bool:
	if cell_y < 0 or cell_y >= navigation_grid_rows.size() or cell_x < 0 or cell_x >= navigation_grid_width:
		return false

	var row := String(navigation_grid_rows[cell_y])
	if cell_x >= row.length():
		return false
	return row.substr(cell_x, 1) == "1"

func _is_sea_cell(cell_x: int, cell_y: int) -> bool:
	if cell_y < 0 or cell_y >= navigation_sea_grid_rows.size() or cell_x < 0 or cell_x >= navigation_grid_width:
		return false

	var row := String(navigation_sea_grid_rows[cell_y])
	if cell_x >= row.length():
		return false
	return row.substr(cell_x, 1) == "1"

func _nearest_water_cell(origin: Vector2i) -> Vector2i:
	if _is_water_cell(origin.x, origin.y):
		return origin

	var max_radius := 28
	for radius in range(1, max_radius + 1):
		for y_offset in range(-radius, radius + 1):
			for x_offset in range(-radius, radius + 1):
				if abs(x_offset) != radius and abs(y_offset) != radius:
					continue
				var candidate := Vector2i(origin.x + x_offset, origin.y + y_offset)
				if _is_water_cell(candidate.x, candidate.y):
					return candidate

	return Vector2i(-1, -1)

func _find_water_path(start_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	if start_cell == target_cell:
		return [start_cell]

	if water_pathfinder != null:
		var id_path: Array[Vector2i] = water_pathfinder.get_id_path(start_cell, target_cell)
		if not id_path.is_empty():
			return id_path

	var open: Array[int] = [_cell_id(start_cell)]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {_cell_id(start_cell): 0.0}
	var f_score: Dictionary = {_cell_id(start_cell): start_cell.distance_to(target_cell)}
	var closed: Dictionary = {}
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]

	while not open.is_empty():
		open.sort_custom(func(a: int, b: int) -> bool: return float(f_score.get(a, 1000000000.0)) < float(f_score.get(b, 1000000000.0)))
		var current_id: int = open.pop_front()
		var current_cell: Vector2i = _cell_from_id(current_id)
		if current_cell == target_cell:
			return _reconstruct_path(came_from, current_id)

		closed[current_id] = true
		for direction in directions:
			var neighbor: Vector2i = current_cell + direction
			if not _is_water_cell(neighbor.x, neighbor.y):
				continue

			var neighbor_id: int = _cell_id(neighbor)
			if closed.has(neighbor_id):
				continue

			var step_cost: float = 1.4142 if direction.x != 0 and direction.y != 0 else 1.0
			var tentative_g: float = float(g_score.get(current_id, 1000000000.0)) + step_cost
			if tentative_g >= float(g_score.get(neighbor_id, 1000000000.0)):
				continue

			came_from[neighbor_id] = current_id
			g_score[neighbor_id] = tentative_g
			f_score[neighbor_id] = tentative_g + neighbor.distance_to(target_cell)
			if not open.has(neighbor_id):
				open.append(neighbor_id)

	return []

func _reconstruct_path(came_from: Dictionary, current_id: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = [_cell_from_id(current_id)]
	while came_from.has(current_id):
		current_id = int(came_from[current_id])
		path.append(_cell_from_id(current_id))
	path.reverse()
	return path

func _cell_id(cell: Vector2i) -> int:
	return cell.y * navigation_grid_width + cell.x

func _cell_from_id(cell_id: int) -> Vector2i:
	return Vector2i(cell_id % navigation_grid_width, floori(float(cell_id) / float(max(1, navigation_grid_width))))

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _cell_from_key(cell_key: String) -> Vector2i:
	var parts := cell_key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))

func _load_manual_navigation_waterways() -> void:
	manual_navigation_added_cells.clear()
	manual_navigation_removed_cells.clear()
	if not FileAccess.file_exists(CUSTOM_NAVIGATION_WATERWAYS_PATH):
		return

	var text := FileAccess.get_file_as_string(CUSTOM_NAVIGATION_WATERWAYS_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Manual navigation waterway overrides must contain a JSON object: %s" % CUSTOM_NAVIGATION_WATERWAYS_PATH)
		return

	var data: Dictionary = parsed
	var grid: Dictionary = data.get("grid", {})
	if int(grid.get("width", navigation_grid_width)) != navigation_grid_width or int(grid.get("height", navigation_grid_height)) != navigation_grid_height or int(grid.get("cell_size", navigation_grid_cell_size)) != navigation_grid_cell_size:
		push_warning("Manual navigation waterway overrides do not match the current navigation grid: %s" % CUSTOM_NAVIGATION_WATERWAYS_PATH)
		return

	for cell_entry in data.get("added_cells", []):
		var cell := _cell_from_serialized_entry(cell_entry)
		if cell.x >= 0:
			manual_navigation_added_cells[_cell_key(cell)] = true
	for cell_entry in data.get("removed_cells", []):
		var cell := _cell_from_serialized_entry(cell_entry)
		if cell.x >= 0:
			manual_navigation_removed_cells[_cell_key(cell)] = true

func _cell_from_serialized_entry(cell_entry: Variant) -> Vector2i:
	if typeof(cell_entry) == TYPE_DICTIONARY:
		var cell: Dictionary = cell_entry
		return Vector2i(int(cell.get("x", -1)), int(cell.get("y", -1)))
	if typeof(cell_entry) == TYPE_STRING:
		return _cell_from_key(String(cell_entry))
	return Vector2i(-1, -1)

func _sorted_manual_navigation_cells(cells: Dictionary) -> Array:
	var keys: Array = cells.keys()
	keys.sort_custom(func(a: String, b: String) -> bool:
		var cell_a := _cell_from_key(a)
		var cell_b := _cell_from_key(b)
		if cell_a.y == cell_b.y:
			return cell_a.x < cell_b.x
		return cell_a.y < cell_b.y
	)

	var serialized: Array[Dictionary] = []
	for key in keys:
		var cell := _cell_from_key(String(key))
		if cell.x >= 0:
			serialized.append({"x": cell.x, "y": cell.y})
	return serialized

func _manual_navigation_summary() -> Dictionary:
	return {
		"added_cells": manual_navigation_added_cells.size(),
		"removed_cells": manual_navigation_removed_cells.size(),
		"pathfinding_ready": water_pathfinder != null
	}

func _interpolate_demo_route(route: Array) -> Vector2:
	if route.size() < 2:
		return size * 0.5

	var segment_index: int = simulation_day % (route.size() - 1)
	var progress: float = float(simulation_day % 5) / 4.0
	var route_points := _navigation_points_between(route[segment_index], route[segment_index + 1])
	if route_points.size() < 2:
		return _city_position(route[segment_index])
	return _interpolate_polyline(route_points, progress)

func _interpolate_polyline(points: Array[Vector2], progress: float) -> Vector2:
	if points.size() < 2:
		return points[0] if not points.is_empty() else size * 0.5

	var total_length := 0.0
	for index in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	if total_length <= 0.0:
		return points[0]

	var target_length := clampf(progress, 0.0, 1.0) * total_length
	var traversed := 0.0
	for index in range(points.size() - 1):
		var segment_length := points[index].distance_to(points[index + 1])
		if traversed + segment_length >= target_length:
			var local_progress: float = (target_length - traversed) / max(segment_length, 0.001)
			return points[index].lerp(points[index + 1], local_progress)
		traversed += segment_length

	return points[points.size() - 1]

func _polyline_direction(points: Array[Vector2], progress: float) -> Vector2:
	if points.size() < 2:
		return Vector2(1.0, -0.25).normalized()

	var total_length := 0.0
	for index in range(points.size() - 1):
		total_length += points[index].distance_to(points[index + 1])
	if total_length <= 0.0:
		return Vector2(1.0, -0.25).normalized()

	var target_length := clampf(progress, 0.0, 1.0) * total_length
	var traversed := 0.0
	for index in range(points.size() - 1):
		var segment := points[index + 1] - points[index]
		var segment_length := segment.length()
		if segment_length <= 0.0:
			continue
		if traversed + segment_length >= target_length:
			return segment / segment_length
		traversed += segment_length

	var fallback_segment := points[points.size() - 1] - points[points.size() - 2]
	if fallback_segment.length() <= 0.0:
		return Vector2(1.0, -0.25).normalized()
	return fallback_segment.normalized()
