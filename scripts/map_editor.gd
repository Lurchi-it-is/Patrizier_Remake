extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const MapView = preload("res://scripts/ui/map_view.gd")
const CITY_VALUES_EXPORT_PATH := "user://custom_map_city_values.json"
const EDITOR_VERSION := "0.2.47-trade-window-fit"
const POPULATION_GROUP_DISTRIBUTION_BY_KIND := {
	"core": {"poor": 0.40, "craftsmen": 0.35, "burghers": 0.20, "patricians": 0.05},
	"kontor": {"poor": 0.35, "craftsmen": 0.25, "burghers": 0.30, "patricians": 0.10},
	"member": {"poor": 0.48, "craftsmen": 0.35, "burghers": 0.14, "patricians": 0.03},
	"trade": {"poor": 0.55, "craftsmen": 0.30, "burghers": 0.13, "patricians": 0.02}
}
const DEFAULT_CITY_ECONOMY := {
	"london": {"population": 30000, "production": {"grain": 8, "beer": 5, "cloth": 4, "wool": 5, "iron": 1, "wine": 2, "spices": 0.5}, "consumption": {"herring": 3, "salt": 2, "timber": 2, "wine": 1, "spices": 0.2}},
	"hull": {"population": 7000, "production": {"grain": 5, "beer": 2, "wool": 2, "iron": 0.6}, "consumption": {"salt": 1, "herring": 1, "timber": 1, "cloth": 0.3}},
	"boston": {"population": 8000, "production": {"grain": 5, "beer": 2, "wool": 2.5}, "consumption": {"salt": 1, "herring": 1, "timber": 1, "cloth": 0.3}},
	"kings_lynn": {"population": 7000, "production": {"grain": 5, "beer": 2, "wool": 1.5}, "consumption": {"salt": 1, "herring": 1, "timber": 1, "cloth": 0.3}},
	"great_yarmouth": {"population": 8000, "production": {"herring": 8, "wool": 2}, "consumption": {"salt": 6, "grain": 4, "timber": 2, "cloth": 1}},
	"bruegge": {"population": 35000, "production": {"grain": 8, "beer": 5, "cloth": 6, "wine": 3, "spices": 0.6}, "consumption": {"herring": 3, "salt": 2, "timber": 2, "wool": 3, "wax": 0.5, "furs": 0.5}},
	"koeln": {"population": 30000, "production": {"grain": 8, "beer": 7, "cloth": 3, "iron": 2, "wine": 1}, "consumption": {"herring": 3, "stockfish": 1, "salt": 2, "timber": 1, "spices": 0.2}},
	"kampen": {"population": 9000, "production": {"grain": 6, "beer": 3, "cloth": 1}, "consumption": {"salt": 1, "herring": 1, "timber": 1, "wool": 0.5}},
	"stade": {"population": 7000, "production": {"grain": 4, "beer": 2, "timber": 1}, "consumption": {"salt": 3, "herring": 3, "cloth": 1, "iron": 0.5}},
	"wismar": {"population": 8000, "production": {"grain": 3, "herring": 5, "beer": 2, "timber": 1}, "consumption": {"salt": 1, "cloth": 0.5, "iron": 0.3}},
	"rostock": {"population": 10000, "production": {"grain": 5, "herring": 4, "beer": 3, "timber": 1}, "consumption": {"salt": 1, "cloth": 0.5, "pitch_tar": 0.3}},
	"stralsund": {"population": 9000, "production": {"grain": 3, "herring": 7, "timber": 1}, "consumption": {"salt": 1, "cloth": 0.5, "beer": 0.5}},
	"greifswald": {"population": 7000, "production": {"grain": 5, "herring": 3, "beer": 1}, "consumption": {"salt": 1, "timber": 0.5, "cloth": 0.3}},
	"stettin": {"population": 9000, "production": {"grain": 7, "timber": 3, "pitch_tar": 0.7}, "consumption": {"salt": 1, "herring": 1, "cloth": 0.5, "iron": 0.3}},
	"kopenhagen": {"population": 12000, "production": {"herring": 5, "grain": 3, "beer": 3}, "consumption": {"salt": 4, "timber": 2, "cloth": 1, "wine": 0.5}},
	"malmoe": {"population": 9000, "production": {"herring": 7, "grain": 3}, "consumption": {"salt": 5, "timber": 2, "cloth": 1}},
	"skanor_falsterbo": {"population": 4000, "production": {"herring": 10}, "consumption": {"salt": 7, "grain": 3, "timber": 1, "cloth": 1, "beer": 0.5}},
	"helsingborg": {"population": 5000, "production": {"herring": 5, "grain": 2}, "consumption": {"salt": 4, "timber": 1, "cloth": 1}},
	"aalborg": {"population": 6000, "production": {"herring": 4, "grain": 3, "beer": 2}, "consumption": {"salt": 3, "timber": 2, "cloth": 1}},
	"oslo": {"population": 5000, "production": {"timber": 3, "herring": 3, "pitch_tar": 0.6}, "consumption": {"grain": 2, "salt": 1, "cloth": 0.4, "beer": 0.5}},
	"bergen": {"population": 8000, "production": {"stockfish": 9, "timber": 1, "furs": 0.4}, "consumption": {"grain": 3, "salt": 1.5, "cloth": 0.5, "beer": 0.8}},
	"stockholm": {"population": 7000, "production": {"timber": 2, "iron": 0.8, "herring": 2}, "consumption": {"grain": 5, "salt": 3, "cloth": 1, "wine": 0.4}},
	"kalmar": {"population": 7000, "production": {"grain": 3, "herring": 4, "timber": 2}, "consumption": {"salt": 4, "cloth": 1, "beer": 1}},
	"elbing": {"population": 9000, "production": {"grain": 8, "timber": 2, "flax": 1}, "consumption": {"salt": 1, "herring": 1, "cloth": 0.5}},
	"koenigsberg": {"population": 9000, "production": {"grain": 9, "timber": 2, "wax": 0.7}, "consumption": {"salt": 1, "herring": 1, "cloth": 0.5}},
	"memel": {"population": 4000, "production": {"grain": 2, "timber": 3, "herring": 3, "pitch_tar": 0.7}, "consumption": {"salt": 1, "cloth": 0.3}},
	"riga": {"population": 12000, "production": {"grain": 8, "timber": 3, "flax": 2, "wax": 1}, "consumption": {"salt": 1.5, "herring": 1, "cloth": 0.6, "beer": 0.8}},
	"reval": {"population": 8000, "production": {"grain": 3, "timber": 2.5, "herring": 3, "wax": 0.6}, "consumption": {"salt": 1, "cloth": 0.5}},
	"abo": {"population": 6000, "production": {"grain": 2, "herring": 4, "timber": 2, "pitch_tar": 0.6}, "consumption": {"salt": 1, "cloth": 0.4}},
	"viborg": {"population": 5000, "production": {"grain": 2, "timber": 3, "herring": 2, "pitch_tar": 0.6}, "consumption": {"salt": 1, "cloth": 0.4}},
	"narva": {"population": 4000, "production": {"timber": 2.5, "grain": 2.5, "flax": 0.7}, "consumption": {"salt": 1, "herring": 0.5, "cloth": 0.3}},
	"nowgorod": {"population": 20000, "production": {"grain": 5, "furs": 2, "wax": 2, "timber": 3, "flax": 2}, "consumption": {"salt": 2, "herring": 1, "stockfish": 0.5, "cloth": 1, "wine": 0.3, "spices": 0.1}}
}

var catalog: Dictionary = {}
var map_view
var city_checkbox_list: VBoxContainer
var editor_info_label: RichTextLabel
var city_values_panel: VBoxContainer
var selected_city_values_label: Label
var population_spinbox: SpinBox
var population_group_total_label: Label
var export_status_label: Label
var city_checkboxes: Dictionary = {}
var city_value_controls: Dictionary = {}
var population_group_controls: Dictionary = {}
var city_base_values: Dictionary = {}
var selected_editor_city_id: String = ""
var placed_editor_city_ids: Array[String] = []
var is_refreshing_value_controls: bool = false

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()
	_initialize_city_base_values()

	_build_layout()
	_refresh_map_editor()

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
	map_view.set_layers(false, true)
	map_view.editor_city_clicked.connect(_on_map_editor_city_clicked)
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

	sidebar.add_child(_build_map_editor_panel())

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 12)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "Hanse Map Editor"
	title.add_theme_font_size_override("font_size", 30)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Eigenstaendiges Tool fuer Custom-Karten"
	subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(subtitle)

	var version := Label.new()
	version.text = EDITOR_VERSION
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 14)
	header.add_child(version)

	return header

func _build_map_editor_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Karteneditor"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(320, 520)
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(list_scroll)

	city_checkbox_list = VBoxContainer.new()
	city_checkbox_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city_checkbox_list.add_theme_constant_override("separation", 2)
	list_scroll.add_child(city_checkbox_list)

	var bulk_controls := HBoxContainer.new()
	bulk_controls.add_theme_constant_override("separation", 8)
	content.add_child(bulk_controls)

	var select_all := Button.new()
	select_all.text = "Alle"
	select_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_all.pressed.connect(_on_select_all_editor_cities_pressed)
	bulk_controls.add_child(select_all)

	var clear := Button.new()
	clear.text = "Keine"
	clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear.pressed.connect(_on_clear_editor_cities_pressed)
	bulk_controls.add_child(clear)

	editor_info_label = RichTextLabel.new()
	editor_info_label.bbcode_enabled = true
	editor_info_label.fit_content = true
	editor_info_label.custom_minimum_size = Vector2(320, 120)
	content.add_child(editor_info_label)

	content.add_child(HSeparator.new())
	content.add_child(_build_city_values_panel())
	content.add_child(HSeparator.new())
	content.add_child(_build_export_controls())

	_populate_city_checkboxes()

	return panel

func _build_city_values_panel() -> Control:
	city_values_panel = VBoxContainer.new()
	city_values_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city_values_panel.add_theme_constant_override("separation", 8)

	var heading := Label.new()
	heading.text = "Stadt-Grundwerte"
	heading.add_theme_font_size_override("font_size", 18)
	city_values_panel.add_child(heading)

	selected_city_values_label = Label.new()
	selected_city_values_label.text = "Keine Stadt ausgewaehlt"
	selected_city_values_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	city_values_panel.add_child(selected_city_values_label)

	var population_row := HBoxContainer.new()
	population_row.add_theme_constant_override("separation", 8)
	city_values_panel.add_child(population_row)

	var population_label := Label.new()
	population_label.text = "Einwohner"
	population_label.custom_minimum_size = Vector2(118, 0)
	population_row.add_child(population_label)

	population_spinbox = SpinBox.new()
	population_spinbox.min_value = 0
	population_spinbox.max_value = 1000000
	population_spinbox.step = 100
	population_spinbox.rounded = true
	population_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	population_spinbox.value_changed.connect(_on_city_population_changed)
	population_row.add_child(population_spinbox)

	city_values_panel.add_child(_build_population_groups_panel())

	var goods_grid := GridContainer.new()
	goods_grid.columns = 3
	goods_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goods_grid.add_theme_constant_override("h_separation", 8)
	goods_grid.add_theme_constant_override("v_separation", 6)
	city_values_panel.add_child(goods_grid)

	var goods_heading := Label.new()
	goods_heading.text = "Ware"
	goods_grid.add_child(goods_heading)

	var production_heading := Label.new()
	production_heading.text = "Erzeugung/Zufluss"
	goods_grid.add_child(production_heading)

	var consumption_heading := Label.new()
	consumption_heading.text = "Verbrauch/Tag"
	goods_grid.add_child(consumption_heading)

	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))

		var good_label := Label.new()
		good_label.text = _good_label(good)
		good_label.custom_minimum_size = Vector2(90, 0)
		goods_grid.add_child(good_label)

		var production_spinbox := _build_good_value_spinbox()
		production_spinbox.value_changed.connect(_on_city_good_value_changed.bind("production", good_id))
		goods_grid.add_child(production_spinbox)

		var consumption_spinbox := _build_good_value_spinbox()
		consumption_spinbox.step = 0.1
		consumption_spinbox.rounded = false
		consumption_spinbox.editable = false
		goods_grid.add_child(consumption_spinbox)

		city_value_controls[good_id] = {
			"production": production_spinbox,
			"consumption": consumption_spinbox
		}

	return city_values_panel

func _build_population_groups_panel() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)

	var heading := Label.new()
	heading.text = "Einwohnergruppen"
	heading.add_theme_font_size_override("font_size", 16)
	box.add_child(heading)

	var groups_grid := GridContainer.new()
	groups_grid.columns = 2
	groups_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	groups_grid.add_theme_constant_override("h_separation", 8)
	groups_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(groups_grid)

	var group_heading := Label.new()
	group_heading.text = "Gruppe"
	groups_grid.add_child(group_heading)

	var count_heading := Label.new()
	count_heading.text = "Anzahl"
	groups_grid.add_child(count_heading)

	for group_entry in catalog.get("population_groups", []):
		var group: Dictionary = group_entry
		var group_id := String(group.get("id", ""))

		var group_label := Label.new()
		group_label.text = String(group.get("name", group_id))
		group_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		group_label.custom_minimum_size = Vector2(160, 0)
		groups_grid.add_child(group_label)

		var group_spinbox := SpinBox.new()
		group_spinbox.min_value = 0
		group_spinbox.max_value = 1000000
		group_spinbox.step = 100
		group_spinbox.rounded = true
		group_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group_spinbox.value_changed.connect(_on_population_group_changed.bind(group_id))
		groups_grid.add_child(group_spinbox)
		population_group_controls[group_id] = group_spinbox

	population_group_total_label = Label.new()
	population_group_total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(population_group_total_label)

	return box

func _build_good_value_spinbox() -> SpinBox:
	var spinbox := SpinBox.new()
	spinbox.min_value = 0
	spinbox.max_value = 999
	spinbox.step = 0.1
	spinbox.rounded = false
	spinbox.custom_minimum_size = Vector2(94, 0)
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spinbox

func _build_export_controls() -> Control:
	var export_box := VBoxContainer.new()
	export_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_box.add_theme_constant_override("separation", 6)

	var save_button := Button.new()
	save_button.text = "Custom-Karte speichern"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_on_save_custom_map_pressed)
	export_box.add_child(save_button)

	export_status_label = Label.new()
	export_status_label.text = "Speichert ausgewaehlte Staedte mit Grundwerten."
	export_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	export_box.add_child(export_status_label)

	return export_box

func _populate_city_checkboxes() -> void:
	var hanse_cities: Array = catalog.get("hanse_cities", [])
	city_checkboxes.clear()

	if hanse_cities.is_empty():
		editor_info_label.text = "Keine historischen Hanseorte geladen."
		return

	for city_entry in hanse_cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		var checkbox := CheckBox.new()
		checkbox.text = "%s - %s" % [city.get("name", ""), _editor_city_kind_label(String(city.get("kind", "")))]
		checkbox.focus_mode = Control.FOCUS_NONE
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		checkbox.toggled.connect(_on_editor_city_toggled.bind(city_id))
		city_checkbox_list.add_child(checkbox)
		city_checkboxes[city_id] = checkbox

func _add_editor_city_point(city_id: String) -> void:
	if city_id.is_empty() or placed_editor_city_ids.has(city_id):
		return
	placed_editor_city_ids.append(city_id)

func _refresh_map_editor() -> void:
	if map_view != null:
		map_view.set_map_editor_selection(selected_editor_city_id, placed_editor_city_ids)
	_refresh_city_value_controls()

	var city := _editor_city_by_id(selected_editor_city_id)
	if city.is_empty():
		editor_info_label.text = "Ausgewaehlt: %d / %d" % [
			placed_editor_city_ids.size(),
			catalog.get("hanse_cities", []).size()
		]
		return

	var position: Dictionary = city.get("position", {})
	var values := _city_base_values_for(selected_editor_city_id)
	editor_info_label.text = "[b]%s[/b]\n%s | %.4f, %.4f\nKartenpunkt: %d / %d\nEinwohner: %d\nEinwohnergruppen: %s\nErzeugung/Zufluss: %s\nVerbrauch/Tag: %s\nAusgewaehlt: %d / %d" % [
		city.get("name", ""),
		city.get("region", ""),
		float(city.get("lat", 0.0)),
		float(city.get("lon", 0.0)),
		int(position.get("x", 0)),
		int(position.get("y", 0)),
		int(values.get("population", 0)),
		_format_population_groups_summary(values.get("population_groups", {})),
		_format_goods_summary(values.get("production", {})),
		_format_goods_summary(_combined_daily_consumption(values)),
		placed_editor_city_ids.size(),
		catalog.get("hanse_cities", []).size()
	]

func _refresh_city_value_controls() -> void:
	if city_values_panel == null:
		return

	var city := _editor_city_by_id(selected_editor_city_id)
	city_values_panel.visible = not city.is_empty()
	if city.is_empty():
		return

	var values := _city_base_values_for(selected_editor_city_id)
	is_refreshing_value_controls = true
	selected_city_values_label.text = "%s - %s" % [
		city.get("name", ""),
		_editor_city_kind_label(String(city.get("kind", "")))
	]
	population_spinbox.value = int(values.get("population", 0))

	var production: Dictionary = values.get("production", {})
	var combined_consumption := _combined_daily_consumption(values)
	var population_groups: Dictionary = values.get("population_groups", {})
	var population_group_total := 0
	for group_id in population_group_controls.keys():
		var group_control: SpinBox = population_group_controls[group_id]
		var group_count := int(population_groups.get(group_id, 0))
		group_control.value = group_count
		population_group_total += group_count

	population_group_total_label.text = "Summe: %d / %d" % [
		population_group_total,
		int(values.get("population", 0))
	]

	for good_id in city_value_controls.keys():
		var controls: Dictionary = city_value_controls[good_id]
		var production_control: SpinBox = controls["production"]
		var consumption_control: SpinBox = controls["consumption"]
		production_control.value = float(production.get(good_id, 0.0))
		consumption_control.value = float(combined_consumption.get(good_id, 0.0))
	is_refreshing_value_controls = false

func _editor_city_by_id(city_id: String) -> Dictionary:
	for city_entry in catalog.get("hanse_cities", []):
		var city: Dictionary = city_entry
		if city.get("id", "") == city_id:
			return city
	return {}

func _editor_city_kind_label(kind: String) -> String:
	match kind:
		"core":
			return "Kernstadt"
		"kontor":
			return "Kontor"
		"member":
			return "Hansestadt"
		"trade":
			return "Handelsort"
		_:
			return "Ort"

func _initialize_city_base_values() -> void:
	var existing_city_values: Dictionary = {}
	for city_entry in catalog.get("cities", []):
		var city: Dictionary = city_entry
		existing_city_values[String(city.get("id", ""))] = city

	for city_entry in catalog.get("hanse_cities", []):
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		var source: Dictionary = existing_city_values.get(city_id, {})
		var defaults: Dictionary = _default_city_economy_for(city)
		var population := int(source.get("population", defaults.get("population", _default_population_for_kind(String(city.get("kind", ""))))))
		city_base_values[city_id] = {
			"population": population,
			"population_groups": _normalized_population_groups(
				source.get("population_groups", defaults.get("population_groups", _default_population_groups_for(population, String(city.get("kind", ""))))),
				population,
				String(city.get("kind", ""))
			),
			"production": _normalized_goods_values(source.get("production", defaults.get("production", {}))),
			"consumption": _normalized_goods_values(source.get("consumption", defaults.get("consumption", {})))
		}

func _default_city_economy_for(city: Dictionary) -> Dictionary:
	var city_id := String(city.get("id", ""))
	if DEFAULT_CITY_ECONOMY.has(city_id):
		var defaults: Dictionary = DEFAULT_CITY_ECONOMY[city_id]
		return defaults

	return {
		"population": _default_population_for_kind(String(city.get("kind", ""))),
		"production": {},
		"consumption": {"grain": 4, "salt": 2, "herring": 2}
	}

func _default_population_for_kind(kind: String) -> int:
	match kind:
		"core":
			return 12000
		"kontor":
			return 10000
		"member":
			return 8000
		"trade":
			return 5000
		_:
			return 3000

func _default_population_groups_for(population: int, kind: String) -> Dictionary:
	var distribution: Dictionary = POPULATION_GROUP_DISTRIBUTION_BY_KIND.get(kind, POPULATION_GROUP_DISTRIBUTION_BY_KIND["trade"])
	var groups: Dictionary = {}
	var assigned := 0
	var last_group_id := ""
	for group_entry in catalog.get("population_groups", []):
		var group: Dictionary = group_entry
		var group_id := String(group.get("id", ""))
		last_group_id = group_id
		var count := int(round(float(population) * float(distribution.get(group_id, 0.0))))
		groups[group_id] = count
		assigned += count

	if not last_group_id.is_empty():
		groups[last_group_id] = int(groups.get(last_group_id, 0)) + population - assigned

	return groups

func _normalized_population_groups(source_values: Dictionary, population: int, kind: String) -> Dictionary:
	var fallback := _default_population_groups_for(population, kind)
	var groups: Dictionary = {}
	var total := 0
	for group_entry in catalog.get("population_groups", []):
		var group: Dictionary = group_entry
		var group_id := String(group.get("id", ""))
		var count := int(source_values.get(group_id, fallback.get(group_id, 0)))
		groups[group_id] = count
		total += count

	if total != population:
		groups = _default_population_groups_for(population, kind)

	return groups

func _normalized_goods_values(source_values: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		values[good_id] = float(source_values.get(good_id, 0.0))
	return values

func _city_base_values_for(city_id: String) -> Dictionary:
	if not city_base_values.has(city_id):
		city_base_values[city_id] = {
			"population": 0,
			"population_groups": _normalized_population_groups({}, 0, "trade"),
			"production": _normalized_goods_values({}),
			"consumption": _normalized_goods_values({})
		}
	return city_base_values[city_id]

func _combined_daily_consumption(values: Dictionary) -> Dictionary:
	var combined: Dictionary = {}
	var city_consumption: Dictionary = values.get("consumption", {})
	for good_id in city_consumption.keys():
		combined[good_id] = float(city_consumption[good_id])

	var population_groups: Dictionary = values.get("population_groups", {})
	for group_entry in catalog.get("population_groups", []):
		var group: Dictionary = group_entry
		var group_id := String(group.get("id", ""))
		var group_population := float(population_groups.get(group_id, 0))
		var needs: Dictionary = group.get("daily_consumption_per_1000", {})
		for good_id in needs.keys():
			combined[good_id] = float(combined.get(good_id, 0.0)) + group_population / 1000.0 * float(needs[good_id])

	return combined

func _format_goods_summary(values: Dictionary) -> String:
	var entries: Array[String] = []
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		var good_id := String(good.get("id", ""))
		var amount := float(values.get(good_id, 0.0))
		if amount > 0:
			entries.append("%s %s" % [String(good.get("name", good_id)), _format_amount(amount)])

	if entries.is_empty():
		return "keine"
	return ", ".join(entries)

func _good_label(good: Dictionary) -> String:
	var good_id := String(good.get("id", ""))
	var unit: Dictionary = good.get("unit", {})
	var abbreviation := String(unit.get("abbreviation", ""))
	if abbreviation.is_empty():
		return String(good.get("name", good_id))
	return "%s (%s)" % [String(good.get("name", good_id)), abbreviation]

func _format_population_groups_summary(values: Dictionary) -> String:
	var entries: Array[String] = []
	for group_entry in catalog.get("population_groups", []):
		var group: Dictionary = group_entry
		var group_id := String(group.get("id", ""))
		var amount := int(values.get(group_id, 0))
		if amount > 0:
			entries.append("%s %d" % [String(group.get("name", group_id)), amount])

	if entries.is_empty():
		return "keine"
	return ", ".join(entries)

func _format_amount(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return "%d" % int(round(value))
	return "%.1f" % value

func _build_custom_map_export_data() -> Dictionary:
	var exported_cities: Array[Dictionary] = []
	for city_id in placed_editor_city_ids:
		var city := _editor_city_by_id(city_id)
		if city.is_empty():
			continue

		var values := _city_base_values_for(city_id)
		exported_cities.append({
			"id": city_id,
			"name": city.get("name", ""),
			"region": city.get("region", ""),
			"kind": city.get("kind", ""),
			"position": city.get("position", {}),
			"population": int(values.get("population", 0)),
			"population_groups": values.get("population_groups", {}),
			"production": values.get("production", {}),
			"consumption": values.get("consumption", {})
		})

	return {
		"version": EDITOR_VERSION,
		"cities": exported_cities
	}

func _on_editor_city_toggled(is_checked: bool, city_id: String) -> void:
	selected_editor_city_id = city_id
	if is_checked:
		_add_editor_city_point(city_id)
	else:
		placed_editor_city_ids.erase(city_id)
	_refresh_map_editor()

func _on_clear_editor_cities_pressed() -> void:
	placed_editor_city_ids.clear()
	for checkbox in city_checkboxes.values():
		checkbox.set_pressed_no_signal(false)
	selected_editor_city_id = ""
	_refresh_map_editor()

func _on_select_all_editor_cities_pressed() -> void:
	placed_editor_city_ids.clear()
	for city_entry in catalog.get("hanse_cities", []):
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		_add_editor_city_point(city_id)
		if city_checkboxes.has(city_id):
			city_checkboxes[city_id].set_pressed_no_signal(true)
	if not placed_editor_city_ids.is_empty():
		selected_editor_city_id = placed_editor_city_ids[0]
	_refresh_map_editor()

func _on_map_editor_city_clicked(city_id: String) -> void:
	if city_id.is_empty():
		return

	selected_editor_city_id = city_id
	_add_editor_city_point(city_id)
	if city_checkboxes.has(city_id):
		var checkbox: CheckBox = city_checkboxes[city_id]
		checkbox.set_pressed_no_signal(true)
	_refresh_map_editor()

func _on_city_population_changed(value: float) -> void:
	if is_refreshing_value_controls or selected_editor_city_id.is_empty():
		return

	var values := _city_base_values_for(selected_editor_city_id)
	var population := int(value)
	var city := _editor_city_by_id(selected_editor_city_id)
	values["population"] = population
	values["population_groups"] = _default_population_groups_for(population, String(city.get("kind", "trade")))
	city_base_values[selected_editor_city_id] = values
	_refresh_map_editor()

func _on_population_group_changed(value: float, group_id: String) -> void:
	if is_refreshing_value_controls or selected_editor_city_id.is_empty():
		return

	var values := _city_base_values_for(selected_editor_city_id)
	var groups: Dictionary = values.get("population_groups", {})
	groups[group_id] = int(value)
	values["population_groups"] = groups
	values["population"] = _population_group_total(groups)
	city_base_values[selected_editor_city_id] = values
	_refresh_map_editor()

func _population_group_total(groups: Dictionary) -> int:
	var total := 0
	for group_id in groups.keys():
		total += int(groups[group_id])
	return total

func _on_city_good_value_changed(value: float, section_key: String, good_id: String) -> void:
	if is_refreshing_value_controls or selected_editor_city_id.is_empty():
		return

	var values := _city_base_values_for(selected_editor_city_id)
	var section: Dictionary = values.get(section_key, {})
	section[good_id] = float(value)
	values[section_key] = section
	city_base_values[selected_editor_city_id] = values
	_refresh_map_editor()

func _on_save_custom_map_pressed() -> void:
	if placed_editor_city_ids.is_empty():
		export_status_label.text = "Keine Staedte ausgewaehlt."
		return

	var file := FileAccess.open(CITY_VALUES_EXPORT_PATH, FileAccess.WRITE)
	if file == null:
		export_status_label.text = "Speichern fehlgeschlagen: %s" % FileAccess.get_open_error()
		return

	file.store_string(JSON.stringify(_build_custom_map_export_data(), "\t"))
	file.close()
	export_status_label.text = "Gespeichert: %s" % ProjectSettings.globalize_path(CITY_VALUES_EXPORT_PATH)
