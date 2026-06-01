extends RefCounted

const DATA_FILES := {
	"goods": "res://data/goods.json",
	"population_groups": "res://data/population_groups.json",
	"cities": "res://data/cities.json",
	"hanse_cities": "res://data/hanse_cities.json",
	"ship_types": "res://data/ship_types.json",
	"pirate_zones": "res://data/pirate_zones.json"
}
const CUSTOM_MAP_OVERRIDE_PATH := "user://custom_map_city_values.json"
const CITY_POSITIONS_OVERRIDE_PATH := "user://hanse_city_positions.json"

func load_all() -> Dictionary:
	var catalog: Dictionary = {}
	for key in DATA_FILES.keys():
		catalog[key] = _load_json_array(DATA_FILES[key])
	_apply_custom_map_override(catalog)
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

func _apply_custom_map_override(catalog: Dictionary) -> void:
	if not FileAccess.file_exists(CUSTOM_MAP_OVERRIDE_PATH):
		catalog["deleted_city_ids"] = []
		return

	var text := FileAccess.get_file_as_string(CUSTOM_MAP_OVERRIDE_PATH)
	if text.is_empty():
		catalog["deleted_city_ids"] = []
		return

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Custom map override must contain a JSON object: %s" % CUSTOM_MAP_OVERRIDE_PATH)
		catalog["deleted_city_ids"] = []
		return

	var data: Dictionary = parsed
	var deleted_city_ids := _string_array_from_variant(data.get("deleted_city_ids", []))
	catalog["deleted_city_ids"] = deleted_city_ids
	_filter_deleted_hanse_cities(catalog, deleted_city_ids)

	var active_city_entries: Array = data.get("cities", [])
	if active_city_entries.is_empty():
		return

	var base_cities_by_id := _city_array_by_id(catalog.get("cities", []))
	var hanse_cities_by_id := _city_array_by_id(catalog.get("hanse_cities", []))
	var active_cities: Array[Dictionary] = []
	var custom_city_fields_by_id: Dictionary = {}
	for city_entry in active_city_entries:
		if typeof(city_entry) != TYPE_DICTIONARY:
			continue

		var custom_city: Dictionary = city_entry
		var city_id := String(custom_city.get("id", ""))
		if city_id.is_empty() or deleted_city_ids.has(city_id):
			continue

		var merged_city: Dictionary = {}
		if base_cities_by_id.has(city_id):
			merged_city = Dictionary(base_cities_by_id[city_id]).duplicate(true)
		elif hanse_cities_by_id.has(city_id):
			merged_city = Dictionary(hanse_cities_by_id[city_id]).duplicate(true)
		_merge_custom_city_fields(merged_city, custom_city)
		active_cities.append(merged_city)
		custom_city_fields_by_id[city_id] = custom_city

	if not active_cities.is_empty():
		catalog["cities"] = active_cities
		_apply_custom_city_fields_to_hanse_cities(catalog, custom_city_fields_by_id)

func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		var text := String(entry)
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result

func _filter_deleted_hanse_cities(catalog: Dictionary, deleted_city_ids: Array[String]) -> void:
	if deleted_city_ids.is_empty():
		return

	var filtered: Array = []
	for city_entry in catalog.get("hanse_cities", []):
		var city: Dictionary = city_entry
		if not deleted_city_ids.has(String(city.get("id", ""))):
			filtered.append(city)
	catalog["hanse_cities"] = filtered

func _city_array_by_id(city_array: Array) -> Dictionary:
	var cities_by_id: Dictionary = {}
	for city_entry in city_array:
		if typeof(city_entry) != TYPE_DICTIONARY:
			continue

		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		if not city_id.is_empty():
			cities_by_id[city_id] = city
	return cities_by_id

func _merge_custom_city_fields(target_city: Dictionary, custom_city: Dictionary) -> void:
	for key in ["id", "name", "region", "kind", "position", "population", "population_groups", "production", "consumption", "stock", "target_stock"]:
		if custom_city.has(key):
			target_city[key] = custom_city[key]

func _apply_custom_city_fields_to_hanse_cities(catalog: Dictionary, custom_city_fields_by_id: Dictionary) -> void:
	var hanse_cities: Array = catalog.get("hanse_cities", [])
	for index in range(hanse_cities.size()):
		var city: Dictionary = hanse_cities[index]
		var city_id := String(city.get("id", ""))
		if not custom_city_fields_by_id.has(city_id):
			continue

		var custom_city: Dictionary = custom_city_fields_by_id[city_id]
		for key in ["name", "region", "kind", "position"]:
			if custom_city.has(key):
				city[key] = custom_city[key]
		hanse_cities[index] = city
	catalog["hanse_cities"] = hanse_cities

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
