extends Control

const SOURCE_MAP_SIZE := Vector2(1600.0, 900.0)
const HANSE_REGION_MAP: Texture2D = preload("res://assets/maps/hanse_region_1600x900.png")

var cities: Array = []
var editor_cities: Array = []
var placed_editor_city_ids: Array[String] = []
var selected_editor_city_id: String = ""
var pirate_zones: Array = []
var simulation_day: int = 1
var show_game_layer: bool = true
var show_editor_layer: bool = false

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(760, 520)

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
	_draw_map_background()
	_draw_pirate_zones()
	if show_game_layer:
		_draw_routes()
		_draw_cities()
	if show_editor_layer:
		_draw_editor_cities()
	_draw_legend()

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
		var from_pos := _city_position(route[index])
		var to_pos := _city_position(route[index + 1])
		draw_line(from_pos, to_pos, Color(0.08, 0.06, 0.03, 0.58), 5.5)
		draw_line(from_pos, to_pos, Color(0.95, 0.78, 0.36, 0.86), 3.0)

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
			draw_string(font, pos + Vector2(11, -8), String(city.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.98, 0.96, 0.86, 0.92))

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
		text = "Map Editor | Editorpunkte: %d / %d | Rot: Piratenrisiko" % [
			placed_editor_city_ids.size(),
			editor_cities.size()
		]
	var legend_width := 560.0 if show_editor_layer else 590.0
	draw_rect(Rect2(Vector2(18, 18), Vector2(legend_width, 34)), Color(0.02, 0.03, 0.04, 0.55), true)
	draw_string(font, Vector2(30, 41), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.93, 0.94, 0.90))

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
	return _city_position(route[segment_index]).lerp(_city_position(route[segment_index + 1]), progress)
