extends Control

const SOURCE_MAP_SIZE := Vector2(1600.0, 900.0)

var cities: Array = []
var pirate_zones: Array = []
var simulation_day: int = 1

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(760, 520)

func set_catalog(catalog: Dictionary) -> void:
	cities = catalog.get("cities", [])
	pirate_zones = catalog.get("pirate_zones", [])
	queue_redraw()

func set_simulation_day(day: int) -> void:
	simulation_day = day
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.18, 0.23), true)
	_draw_sea_grid()
	_draw_land_mass()
	_draw_pirate_zones()
	_draw_routes()
	_draw_cities()
	_draw_legend()

func _draw_sea_grid() -> void:
	var grid_color := Color(0.22, 0.38, 0.43, 0.24)
	for x in range(80, int(size.x), 80):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(80, int(size.y), 80):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

func _draw_land_mass() -> void:
	var land := Color(0.23, 0.29, 0.20)
	var coast := Color(0.46, 0.58, 0.38)
	var north := PackedVector2Array([
		Vector2(0, size.y * 0.12),
		Vector2(size.x * 0.26, size.y * 0.08),
		Vector2(size.x * 0.42, size.y * 0.18),
		Vector2(size.x * 0.36, size.y * 0.34),
		Vector2(size.x * 0.12, size.y * 0.30),
		Vector2(0, size.y * 0.38)
	])
	var south := PackedVector2Array([
		Vector2(0, size.y * 0.78),
		Vector2(size.x * 0.34, size.y * 0.70),
		Vector2(size.x * 0.56, size.y * 0.76),
		Vector2(size.x, size.y * 0.64),
		Vector2(size.x, size.y),
		Vector2(0, size.y)
	])
	draw_colored_polygon(north, land)
	draw_polyline(north, coast, 3.0, true)
	draw_colored_polygon(south, land)
	draw_polyline(south, coast, 3.0, true)

func _draw_pirate_zones() -> void:
	var zone_points := [
		Vector2(size.x * 0.50, size.y * 0.48),
		Vector2(size.x * 0.62, size.y * 0.38),
		Vector2(size.x * 0.76, size.y * 0.30)
	]
	for index in range(min(pirate_zones.size(), zone_points.size())):
		var risk: float = float(pirate_zones[index].get("risk", 0.0))
		var radius: float = 46.0 + risk * 90.0
		draw_circle(zone_points[index], radius, Color(0.64, 0.12, 0.08, 0.18))
		draw_arc(zone_points[index], radius, 0.0, TAU, 48, Color(0.90, 0.25, 0.16, 0.70), 2.0)

func _draw_routes() -> void:
	var route := ["hamburg", "luebeck", "visby"]
	for index in range(route.size() - 1):
		var from_pos := _city_position(route[index])
		var to_pos := _city_position(route[index + 1])
		draw_line(from_pos, to_pos, Color(0.95, 0.78, 0.36), 4.0)
		draw_line(from_pos, to_pos, Color(0.10, 0.08, 0.04, 0.50), 1.0)

	var ship_position := _interpolate_route(route)
	draw_circle(ship_position, 9.0, Color(0.96, 0.96, 0.88))
	draw_line(ship_position + Vector2(-10, 8), ship_position + Vector2(12, 8), Color(0.96, 0.96, 0.88), 3.0)

func _draw_cities() -> void:
	var font := get_theme_default_font()
	for city_entry in cities:
		var city: Dictionary = city_entry
		var pos := _scale_position(city.get("position", {}))
		draw_circle(pos, 13.0, Color(0.96, 0.82, 0.48))
		draw_circle(pos, 7.0, Color(0.18, 0.12, 0.05))
		draw_string(font, pos + Vector2(18, 6), String(city.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.95, 0.95, 0.90))

func _draw_legend() -> void:
	var font := get_theme_default_font()
	var text := "Nord- und Ostsee-Prototyp | Tag %d | Gelb: Handelsroute | Rot: Piratenrisiko" % simulation_day
	draw_rect(Rect2(Vector2(18, 18), Vector2(560, 34)), Color(0.02, 0.03, 0.04, 0.55), true)
	draw_string(font, Vector2(30, 41), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.93, 0.94, 0.90))

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
