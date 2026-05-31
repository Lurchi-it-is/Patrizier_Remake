extends Control

signal editor_city_clicked(city_id: String)

const SOURCE_MAP_SIZE := Vector2(1600.0, 900.0)
const HANSE_REGION_MAP: Texture2D = preload("res://assets/maps/hanse_region_1600x900.png")
const HANSE_NAVIGATION_DATA := "res://assets/maps/hanse_navigation_1600x900.json"
const MIN_ZOOM := 1.0
const MAX_ZOOM := 5.0
const ZOOM_STEP := 1.18

var cities: Array = []
var navigation_routes: Dictionary = {}
var navigation_city_harbors: Dictionary = {}
var editor_cities: Array = []
var placed_editor_city_ids: Array[String] = []
var selected_editor_city_id: String = ""
var pirate_zones: Array = []
var simulation_day: int = 1
var show_game_layer: bool = true
var show_editor_layer: bool = false
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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_zoom_at(mouse_event.position, ZOOM_STEP)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_zoom_at(mouse_event.position, 1.0 / ZOOM_STEP)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.double_click:
				_reset_zoom()
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
		if is_panning and map_zoom > MIN_ZOOM:
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
	queue_redraw()

func set_map_editor_selection(city_id: String, placed_city_ids: Array[String]) -> void:
	selected_editor_city_id = city_id
	placed_editor_city_ids = placed_city_ids.duplicate()
	queue_redraw()

func set_simulation_day(day: int) -> void:
	simulation_day = day
	queue_redraw()

func set_layers(is_game_layer_visible: bool, is_editor_layer_visible: bool) -> void:
	show_game_layer = is_game_layer_visible
	show_editor_layer = is_editor_layer_visible
	queue_redraw()

func _draw() -> void:
	draw_set_transform(map_offset, 0.0, Vector2(map_zoom, map_zoom))
	_draw_map_background()
	_draw_pirate_zones()
	if show_game_layer:
		_draw_routes()
		_draw_cities()
	if show_editor_layer:
		_draw_editor_cities()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_legend()
	_draw_hovered_city_name()

func _draw_map_background() -> void:
	draw_texture_rect(HANSE_REGION_MAP, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.03, 0.10), true)

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
			route_points = [_city_position(route[index]), _city_position(route[index + 1])]
		for point_index in range(route_points.size() - 1):
			draw_line(route_points[point_index], route_points[point_index + 1], Color(0.08, 0.06, 0.03, 0.58), 5.5)
			draw_line(route_points[point_index], route_points[point_index + 1], Color(0.95, 0.78, 0.36, 0.86), 3.0)

	var ship_position := _interpolate_route(route)
	draw_circle(ship_position, 9.0, Color(0.96, 0.96, 0.88))
	draw_line(ship_position + Vector2(-10, 8), ship_position + Vector2(12, 8), Color(0.96, 0.96, 0.88), 3.0)

func _draw_cities() -> void:
	var font := get_theme_default_font()
	for city_entry in cities:
		var city: Dictionary = city_entry
		var pos := _scale_position(city.get("position", {}))
		draw_circle(pos + Vector2(2.0, 2.0), 14.0, Color(0.02, 0.02, 0.02, 0.45))
		draw_circle(pos, 13.0, Color(0.96, 0.82, 0.48))
		draw_circle(pos, 7.0, Color(0.18, 0.12, 0.05))
		draw_arc(pos, 15.0, 0.0, TAU, 48, Color(0.98, 0.94, 0.72, 0.72), 1.4)
		draw_string(font, pos + Vector2(18, 6), String(city.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.95, 0.95, 0.90))

func _draw_editor_cities() -> void:
	var font := get_theme_default_font()
	for city_entry in editor_cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		if not placed_editor_city_ids.has(city_id):
			continue

		var pos := _scale_position(city.get("position", {}))
		var is_selected := city_id == selected_editor_city_id
		var radius := 5.5 if is_selected else 4.0
		var color := _editor_city_color(String(city.get("kind", "")))

		draw_circle(pos + Vector2(1.4, 1.6), radius + 1.2, Color(0.02, 0.02, 0.02, 0.42))
		draw_circle(pos, radius + 1.0, Color(0.97, 0.94, 0.82, 0.90))
		draw_circle(pos, radius, color)
		draw_arc(pos, radius + 2.5, 0.0, TAU, 48, Color(0.98, 0.96, 0.86, 0.72 if is_selected else 0.24), 1.2)

		if is_selected:
			draw_arc(pos, radius + 5.0, 0.0, TAU, 48, Color(0.98, 0.96, 0.86, 0.42), 1.0)

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

func _draw_legend() -> void:
	var font := get_theme_default_font()
	var text := "Hauptgame-Karte | Tag %d | Feste Staedte: %d | Rot: Piratenrisiko" % [
		simulation_day,
		cities.size()
	]
	if show_editor_layer:
		text = "Map Editor | Zoom: %d%% | Editorpunkte: %d / %d | Rot: Piratenrisiko" % [
			int(round(map_zoom * 100.0)),
			placed_editor_city_ids.size(),
			editor_cities.size()
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
		for city_entry in cities:
			var city: Dictionary = city_entry
			var pos := _screen_position_from_map(_scale_position(city.get("position", {})))
			if screen_position.distance_to(pos) <= 18.0:
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
		var radius := 12.0 if city_id == selected_editor_city_id else 10.0
		if screen_position.distance_to(pos) <= radius:
			return city_id

	return ""

func _screen_position_from_map(map_position: Vector2) -> Vector2:
	return map_position * map_zoom + map_offset

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
	for city_entry in cities:
		var city: Dictionary = city_entry
		if city.get("id", "") == city_id:
			return _scale_position(city.get("position", {}))
	return size * 0.5

func _navigation_points_between(from_city_id: String, to_city_id: String) -> Array[Vector2]:
	var key := "%s__%s" % [from_city_id, to_city_id]
	var is_reversed := false
	if not navigation_routes.has(key):
		key = "%s__%s" % [to_city_id, from_city_id]
		is_reversed = true
	if not navigation_routes.has(key):
		return []

	var route: Dictionary = navigation_routes[key]
	var source_points: Array = route.get("points", []).duplicate(true)
	if is_reversed:
		source_points.reverse()

	var points: Array[Vector2] = []
	for point_entry in source_points:
		var point: Dictionary = point_entry
		points.append(_scale_position(point))
	return points

func _scale_position(position: Dictionary) -> Vector2:
	return Vector2(
		float(position.get("x", 0.0)) / SOURCE_MAP_SIZE.x * size.x,
		float(position.get("y", 0.0)) / SOURCE_MAP_SIZE.y * size.y
	)

func _interpolate_route(route: Array) -> Vector2:
	if route.size() < 2:
		return size * 0.5

	var segment_index: int = simulation_day % (route.size() - 1)
	var progress: float = float(simulation_day % 5) / 4.0
	var route_points := _navigation_points_between(route[segment_index], route[segment_index + 1])
	if route_points.size() < 2:
		return _city_position(route[segment_index]).lerp(_city_position(route[segment_index + 1]), progress)
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
