extends RefCounted

const DATA_FILES := {
	"goods": "res://data/goods.json",
	"population_groups": "res://data/population_groups.json",
	"cities": "res://data/cities.json",
	"hanse_cities": "res://data/hanse_cities.json",
	"ship_types": "res://data/ship_types.json",
	"pirate_zones": "res://data/pirate_zones.json"
}
const CITY_POSITIONS_OVERRIDE_PATH := "user://hanse_city_positions.json"

func load_all() -> Dictionary:
	var catalog: Dictionary = {}
	for key in DATA_FILES.keys():
		catalog[key] = _load_json_array(DATA_FILES[key])
	_apply_city_position_overrides(catalog)
	return catalog

func _load_json_array(path: String) -> Array:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Could not read data file: %s" % path)
		return []

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Data file must contain a JSON array: %s" % path)
		return []

	return parsed as Array

func _apply_city_position_overrides(catalog: Dictionary) -> void:
	if not FileAccess.file_exists(CITY_POSITIONS_OVERRIDE_PATH):
		return

	var text := FileAccess.get_file_as_string(CITY_POSITIONS_OVERRIDE_PATH)
	if text.is_empty():
		return

	var parsed: Variant = JSON.parse_string(text)
	var entries: Array = []
	if typeof(parsed) == TYPE_ARRAY:
		entries = parsed as Array
	elif typeof(parsed) == TYPE_DICTIONARY:
		var data: Dictionary = parsed
		entries = data.get("positions", data.get("cities", []))

	if entries.is_empty():
		return

	var positions_by_id: Dictionary = {}
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		var city_id := String(entry.get("id", ""))
		var position: Dictionary = entry.get("position", {})
		if city_id.is_empty() or not position.has("x") or not position.has("y"):
			continue

		positions_by_id[city_id] = {
			"x": int(round(float(position.get("x", 0.0)))),
			"y": int(round(float(position.get("y", 0.0))))
		}

	if positions_by_id.is_empty():
		return

	for key in ["hanse_cities", "cities"]:
		_apply_positions_to_city_array(catalog.get(key, []), positions_by_id)

func _apply_positions_to_city_array(city_array: Array, positions_by_id: Dictionary) -> void:
	for index in range(city_array.size()):
		var city: Dictionary = city_array[index]
		var city_id := String(city.get("id", ""))
		if not positions_by_id.has(city_id):
			continue

		city["position"] = positions_by_id[city_id]
		city_array[index] = city
