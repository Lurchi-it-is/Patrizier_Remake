extends RefCounted

const DATA_FILES := {
	"goods": "res://data/goods.json",
	"population_groups": "res://data/population_groups.json",
	"cities": "res://data/cities.json",
	"hanse_cities": "res://data/hanse_cities.json",
	"ship_types": "res://data/ship_types.json",
	"pirate_zones": "res://data/pirate_zones.json"
}

func load_all() -> Dictionary:
	var catalog: Dictionary = {}
	for key in DATA_FILES.keys():
		catalog[key] = _load_json_array(DATA_FILES[key])
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
