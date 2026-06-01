extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const MapView = preload("res://scripts/ui/map_view.gd")
const CITY_VALUES_EXPORT_PATH := "user://custom_map_city_values.json"
const CITY_POSITIONS_EXPORT_PATH := "user://hanse_city_positions.json"
const MAP_BACKGROUND_OVERRIDE_PATH := "user://custom_map_background.png"
const NAVIGATION_WATERWAYS_OVERRIDE_PATH := "user://custom_navigation_waterways.json"
const EDITOR_VERSION := "0.2.73-crisp-map-city-labels"
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
var position_edit_toggle: CheckButton
var position_status_label: Label
var population_spinbox: SpinBox
var population_group_total_label: Label
var export_status_label: Label
var debug_status_label: Label
var map_background_status_label: Label
var map_file_dialog: FileDialog
var navigation_debug_toggle: CheckButton
var waterway_edit_toggle: CheckButton
var waterway_mode_option: OptionButton
var waterway_brush_spinbox: SpinBox
var waterway_status_label: Label
var city_position_autosave_timer: Timer
var city_checkboxes: Dictionary = {}
var city_value_controls: Dictionary = {}
var population_group_controls: Dictionary = {}
var city_base_values: Dictionary = {}
var selected_editor_city_id: String = ""
var placed_editor_city_ids: Array[String] = []
var deleted_editor_city_ids: Array[String] = []
var is_refreshing_value_controls: bool = false

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()
	deleted_editor_city_ids = _string_array_from_variant(catalog.get("deleted_city_ids", []))
	_initialize_city_base_values()
	_initialize_active_editor_city_ids()

	_build_layout()
	_build_city_position_autosave_timer()
	_build_map_file_dialog()
	_refresh_map_editor()

func _build_city_position_autosave_timer() -> void:
	city_position_autosave_timer = Timer.new()
	city_position_autosave_timer.one_shot = true
	city_position_autosave_timer.wait_time = 0.35
	city_position_autosave_timer.timeout.connect(_on_city_position_autosave_timeout)
	add_child(city_position_autosave_timer)

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
	map_view.editor_city_position_changed.connect(_on_map_editor_city_position_changed)
	map_view.navigation_waterway_changed.connect(_on_navigation_waterway_changed)
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
	content.add_child(_build_debug_map_controls())
	content.add_child(HSeparator.new())
	content.add_child(_build_position_editor_controls())
	content.add_child(HSeparator.new())
	content.add_child(_build_city_values_panel())
	content.add_child(HSeparator.new())
	content.add_child(_build_export_controls())

	_populate_city_checkboxes()

	return panel

func _build_debug_map_controls() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)

	var heading := Label.new()
	heading.text = "Debug und Karte"
	heading.add_theme_font_size_override("font_size", 18)
	box.add_child(heading)

	navigation_debug_toggle = CheckButton.new()
	navigation_debug_toggle.text = "Debugmodus"
	navigation_debug_toggle.toggled.connect(_on_navigation_debug_toggled)
	box.add_child(navigation_debug_toggle)

	debug_status_label = Label.new()
	debug_status_label.text = "Debug aus."
	debug_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(debug_status_label)

	var map_buttons := HBoxContainer.new()
	map_buttons.add_theme_constant_override("separation", 8)
	box.add_child(map_buttons)

	var load_map := Button.new()
	load_map.text = "Karte laden"
	load_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_map.pressed.connect(_on_load_map_background_pressed)
	map_buttons.add_child(load_map)

	var reset_map := Button.new()
	reset_map.text = "Standardkarte"
	reset_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_map.pressed.connect(_on_reset_map_background_pressed)
	map_buttons.add_child(reset_map)

	map_background_status_label = Label.new()
	map_background_status_label.text = "Aktuelle Karte: Standardkarte" if not FileAccess.file_exists(MAP_BACKGROUND_OVERRIDE_PATH) else "Aktuelle Karte: user://custom_map_background.png"
	map_background_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(map_background_status_label)

	box.add_child(HSeparator.new())

	waterway_edit_toggle = CheckButton.new()
	waterway_edit_toggle.text = "Wasserwege bearbeiten"
	waterway_edit_toggle.toggled.connect(_on_waterway_edit_toggled)
	box.add_child(waterway_edit_toggle)

	var waterway_mode_row := HBoxContainer.new()
	waterway_mode_row.add_theme_constant_override("separation", 8)
	box.add_child(waterway_mode_row)

	waterway_mode_option = OptionButton.new()
	waterway_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	waterway_mode_option.add_item("Wasser zeichnen", 0)
	waterway_mode_option.add_item("Wasser entfernen", 1)
	waterway_mode_option.item_selected.connect(_on_waterway_mode_selected)
	waterway_mode_row.add_child(waterway_mode_option)

	waterway_brush_spinbox = SpinBox.new()
	waterway_brush_spinbox.min_value = 1
	waterway_brush_spinbox.max_value = 8
	waterway_brush_spinbox.step = 1
	waterway_brush_spinbox.value = 2
	waterway_brush_spinbox.custom_minimum_size = Vector2(82, 0)
	waterway_brush_spinbox.value_changed.connect(_on_waterway_brush_changed)
	waterway_mode_row.add_child(waterway_brush_spinbox)

	var waterway_buttons := HBoxContainer.new()
	waterway_buttons.add_theme_constant_override("separation", 8)
	box.add_child(waterway_buttons)

	var save_waterways := Button.new()
	save_waterways.text = "Wasserwege speichern"
	save_waterways.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_waterways.pressed.connect(_on_save_waterways_pressed)
	waterway_buttons.add_child(save_waterways)

	var reset_waterways := Button.new()
	reset_waterways.text = "Zuruecksetzen"
	reset_waterways.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_waterways.pressed.connect(_on_reset_waterways_pressed)
	waterway_buttons.add_child(reset_waterways)

	waterway_status_label = Label.new()
	waterway_status_label.text = _waterway_status_text({})
	waterway_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(waterway_status_label)

	return box

func _build_map_file_dialog() -> void:
	map_file_dialog = FileDialog.new()
	map_file_dialog.title = "Kartenbild waehlen"
	map_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	map_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	map_file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Bilddateien"])
	map_file_dialog.file_selected.connect(_on_map_background_file_selected)
	add_child(map_file_dialog)

func _build_position_editor_controls() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)

	var heading := Label.new()
	heading.text = "Stadtpositionen"
	heading.add_theme_font_size_override("font_size", 18)
	box.add_child(heading)

	position_edit_toggle = CheckButton.new()
	position_edit_toggle.text = "Positionen bearbeiten"
	position_edit_toggle.toggled.connect(_on_position_edit_toggled)
	box.add_child(position_edit_toggle)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	var save_positions := Button.new()
	save_positions.text = "Positionen speichern"
	save_positions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_positions.pressed.connect(_on_save_city_positions_pressed)
	buttons.add_child(save_positions)

	var show_all := Button.new()
	show_all.text = "Alle anzeigen"
	show_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	show_all.pressed.connect(_on_select_all_editor_cities_pressed)
	buttons.add_child(show_all)

	position_status_label = Label.new()
	position_status_label.text = "Stadt waehlen, Positionsmodus aktivieren, Marker ziehen oder auf die Zielstelle klicken."
	position_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(position_status_label)

	return box

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
	save_button.text = "Hauptkarte speichern"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_on_save_custom_map_pressed)
	export_box.add_child(save_button)

	export_status_label = Label.new()
	export_status_label.text = "Speichert die aktive Hauptspielkarte inklusive aktiver Staedte."
	export_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	export_box.add_child(export_status_label)

	return export_box

func _populate_city_checkboxes() -> void:
	var hanse_cities: Array = catalog.get("hanse_cities", [])
	for child in city_checkbox_list.get_children():
		child.queue_free()
	city_checkboxes.clear()

	if hanse_cities.is_empty():
		editor_info_label.text = "Keine historischen Hanseorte geladen."
		return

	for city_entry in hanse_cities:
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 4)
		city_checkbox_list.add_child(row)

		var checkbox := CheckBox.new()
		checkbox.text = "%s - %s" % [city.get("name", ""), _editor_city_kind_label(String(city.get("kind", "")))]
		checkbox.focus_mode = Control.FOCUS_NONE
		checkbox.custom_minimum_size = Vector2(0, 24)
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		checkbox.add_theme_font_size_override("font_size", 12)
		checkbox.add_theme_color_override("font_color", Color(0.74, 0.77, 0.72))
		checkbox.add_theme_color_override("font_hover_color", Color(0.90, 0.88, 0.78))
		checkbox.add_theme_color_override("font_pressed_color", Color(0.96, 0.90, 0.62))
		checkbox.add_theme_constant_override("h_separation", 4)
		checkbox.toggled.connect(_on_editor_city_toggled.bind(city_id))
		checkbox.set_pressed_no_signal(placed_editor_city_ids.has(city_id))
		row.add_child(checkbox)
		city_checkboxes[city_id] = checkbox

		var delete_button := Button.new()
		delete_button.text = "x"
		delete_button.tooltip_text = "Stadt loeschen"
		delete_button.focus_mode = Control.FOCUS_NONE
		delete_button.custom_minimum_size = Vector2(26, 24)
		delete_button.add_theme_font_size_override("font_size", 12)
		delete_button.add_theme_color_override("font_color", Color(0.70, 0.52, 0.48))
		delete_button.add_theme_color_override("font_hover_color", Color(0.95, 0.68, 0.58))
		delete_button.add_theme_stylebox_override("normal", _compact_city_button_style(Color(0.12, 0.12, 0.11, 0.18), Color(0.34, 0.30, 0.26, 0.30)))
		delete_button.add_theme_stylebox_override("hover", _compact_city_button_style(Color(0.18, 0.11, 0.10, 0.34), Color(0.54, 0.35, 0.30, 0.55)))
		delete_button.add_theme_stylebox_override("pressed", _compact_city_button_style(Color(0.24, 0.12, 0.10, 0.45), Color(0.70, 0.42, 0.34, 0.70)))
		delete_button.pressed.connect(_on_delete_editor_city_pressed.bind(city_id))
		row.add_child(delete_button)

func _compact_city_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

func _add_editor_city_point(city_id: String) -> void:
	if city_id.is_empty() or placed_editor_city_ids.has(city_id):
		return
	placed_editor_city_ids.append(city_id)

func _initialize_active_editor_city_ids() -> void:
	placed_editor_city_ids.clear()
	for city_entry in catalog.get("cities", []):
		var city: Dictionary = city_entry
		var city_id := String(city.get("id", ""))
		if city_id.is_empty() or _editor_city_by_id(city_id).is_empty():
			continue
		_add_editor_city_point(city_id)

	if placed_editor_city_ids.is_empty():
		for city_entry in catalog.get("hanse_cities", []):
			var city: Dictionary = city_entry
			_add_editor_city_point(String(city.get("id", "")))
			if placed_editor_city_ids.size() >= 5:
				break

	if not placed_editor_city_ids.is_empty():
		selected_editor_city_id = placed_editor_city_ids[0]

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
	var water_text := "Wasser"
	if map_view != null and not map_view.is_source_water_position(position):
		water_text = "Land"
	var values := _city_base_values_for(selected_editor_city_id)
	editor_info_label.text = "[b]%s[/b]\n%s | %.4f, %.4f\nKartenpunkt: %d / %d | %s\nEinwohner: %d\nEinwohnergruppen: %s\nErzeugung/Zufluss: %s\nVerbrauch/Tag: %s\nAusgewaehlt: %d / %d" % [
		city.get("name", ""),
		city.get("region", ""),
		float(city.get("lat", 0.0)),
		float(city.get("lon", 0.0)),
		int(position.get("x", 0)),
		int(position.get("y", 0)),
		water_text,
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

func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		var text := String(entry)
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result

func _remove_city_from_catalog_array(array_key: String, city_id: String) -> void:
	var source_cities: Array = catalog.get(array_key, [])
	var filtered_cities: Array = []
	for city_entry in source_cities:
		var city: Dictionary = city_entry
		if String(city.get("id", "")) != city_id:
			filtered_cities.append(city)
	catalog[array_key] = filtered_cities

func _first_placed_city_id() -> String:
	for city_id in placed_editor_city_ids:
		if not _editor_city_by_id(city_id).is_empty():
			return city_id
	return ""

func _sync_map_editor_catalog() -> void:
	if map_view != null:
		map_view.set_catalog(catalog)

func _on_navigation_debug_toggled(is_enabled: bool) -> void:
	if map_view != null:
		map_view.set_navigation_debug_visible(is_enabled)
	if debug_status_label != null:
		debug_status_label.text = "Debug an: Wasserwege und Routen zur ausgewaehlten Stadt sichtbar. Pro Stadt gibt es nur den beweglichen Wasser-Stadtmarker." if is_enabled else "Debug aus."

func _on_waterway_edit_toggled(is_enabled: bool) -> void:
	if map_view != null:
		map_view.set_navigation_waterway_edit_enabled(is_enabled)
		if is_enabled:
			map_view.set_navigation_debug_visible(true)
			if navigation_debug_toggle != null:
				navigation_debug_toggle.set_pressed_no_signal(true)
	if waterway_status_label != null:
		var summary: Dictionary = map_view.manual_navigation_summary() if map_view != null else {}
		waterway_status_label.text = _waterway_status_text(summary) if not is_enabled else "%s Linke Maustaste zeichnet direkt auf der Karte." % _waterway_status_text(summary)
	if debug_status_label != null and is_enabled:
		debug_status_label.text = "Debug an: Wasserwege koennen jetzt direkt auf der Karte bearbeitet werden."

func _on_waterway_mode_selected(index: int) -> void:
	if map_view == null:
		return
	map_view.set_navigation_waterway_edit_mode("remove" if index == 1 else "add")
	if waterway_status_label != null:
		waterway_status_label.text = _waterway_status_text(map_view.manual_navigation_summary())

func _on_waterway_brush_changed(value: float) -> void:
	if map_view != null:
		map_view.set_navigation_waterway_brush_radius(int(value))

func _on_navigation_waterway_changed(summary: Dictionary) -> void:
	if waterway_status_label != null:
		waterway_status_label.text = _waterway_status_text(summary)

func _on_save_waterways_pressed() -> void:
	if map_view == null:
		return
	if map_view.save_manual_navigation_waterways():
		waterway_status_label.text = "%s Gespeichert: %s" % [
			_waterway_status_text(map_view.manual_navigation_summary()),
			ProjectSettings.globalize_path(NAVIGATION_WATERWAYS_OVERRIDE_PATH)
		]
	else:
		waterway_status_label.text = "Wasserwege konnten nicht gespeichert werden: %s" % FileAccess.get_open_error()

func _on_reset_waterways_pressed() -> void:
	if map_view == null:
		return
	map_view.reset_manual_navigation_waterways()
	waterway_status_label.text = "Manuelle Wasserwege zurueckgesetzt."

func _waterway_status_text(summary: Dictionary) -> String:
	var added := int(summary.get("added_cells", 0))
	var removed := int(summary.get("removed_cells", 0))
	var save_hint := " gespeichert" if FileAccess.file_exists(NAVIGATION_WATERWAYS_OVERRIDE_PATH) else ""
	return "Manuelle Wasserwege%s: +%d / -%d Rasterzellen. Pinselgroesse rechts." % [save_hint, added, removed]

func _on_load_map_background_pressed() -> void:
	if map_file_dialog != null:
		map_file_dialog.popup_centered_ratio(0.72)

func _on_map_background_file_selected(path: String) -> void:
	var image := Image.new()
	var load_error := image.load(path)
	if load_error != OK:
		if map_background_status_label != null:
			map_background_status_label.text = "Karte konnte nicht geladen werden: %s" % path
		return

	var save_error := image.save_png(MAP_BACKGROUND_OVERRIDE_PATH)
	if save_error != OK:
		if map_background_status_label != null:
			map_background_status_label.text = "Karte konnte nicht gespeichert werden: %s" % ProjectSettings.globalize_path(MAP_BACKGROUND_OVERRIDE_PATH)
		return

	if map_view != null and not map_view.set_map_texture_from_path(MAP_BACKGROUND_OVERRIDE_PATH):
		if map_background_status_label != null:
			map_background_status_label.text = "Karte wurde gespeichert, aber die Vorschau konnte nicht geladen werden."
		return

	if map_background_status_label != null:
		map_background_status_label.text = "Aktuelle Karte: %s" % ProjectSettings.globalize_path(MAP_BACKGROUND_OVERRIDE_PATH)

func _on_reset_map_background_pressed() -> void:
	if map_view != null:
		map_view.reset_map_texture()

	if FileAccess.file_exists(MAP_BACKGROUND_OVERRIDE_PATH):
		var absolute_path := ProjectSettings.globalize_path(MAP_BACKGROUND_OVERRIDE_PATH)
		DirAccess.remove_absolute(absolute_path)

	if map_background_status_label != null:
		map_background_status_label.text = "Aktuelle Karte: Standardkarte"

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
		"mode": "main_game_default_map",
		"map_background": MAP_BACKGROUND_OVERRIDE_PATH if FileAccess.file_exists(MAP_BACKGROUND_OVERRIDE_PATH) else "",
		"navigation_waterways": NAVIGATION_WATERWAYS_OVERRIDE_PATH if FileAccess.file_exists(NAVIGATION_WATERWAYS_OVERRIDE_PATH) else "",
		"deleted_city_ids": deleted_editor_city_ids,
		"cities": exported_cities
	}

func _on_editor_city_toggled(is_checked: bool, city_id: String) -> void:
	if _editor_city_by_id(city_id).is_empty():
		return

	selected_editor_city_id = city_id
	if is_checked:
		_add_editor_city_point(city_id)
	else:
		placed_editor_city_ids.erase(city_id)
	_refresh_map_editor()

func _on_delete_editor_city_pressed(city_id: String) -> void:
	var city := _editor_city_by_id(city_id)
	if city.is_empty():
		return

	var city_name := String(city.get("name", city_id))
	_remove_city_from_catalog_array("hanse_cities", city_id)
	_remove_city_from_catalog_array("cities", city_id)
	placed_editor_city_ids.erase(city_id)
	if not deleted_editor_city_ids.has(city_id):
		deleted_editor_city_ids.append(city_id)
	city_base_values.erase(city_id)

	if selected_editor_city_id == city_id:
		selected_editor_city_id = _first_placed_city_id()

	_populate_city_checkboxes()
	for placed_city_id in placed_editor_city_ids:
		if city_checkboxes.has(placed_city_id):
			city_checkboxes[placed_city_id].set_pressed_no_signal(true)

	_sync_map_editor_catalog()
	if export_status_label != null:
		export_status_label.text = "Geloescht: %s" % city_name
	if position_status_label != null:
		position_status_label.text = "Stadt entfernt: %s" % city_name
	_refresh_map_editor()
	_save_default_main_map(false)

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

func _on_position_edit_toggled(is_enabled: bool) -> void:
	if map_view != null:
		map_view.set_editor_position_edit_enabled(is_enabled)
	if not is_enabled and city_position_autosave_timer != null and not city_position_autosave_timer.is_stopped():
		city_position_autosave_timer.stop()
		_save_city_positions(false)
	if position_status_label != null:
		position_status_label.text = "Positionsmodus aktiv." if is_enabled else "Positionsmodus aus."

func _on_map_editor_city_position_changed(city_id: String, position: Dictionary) -> void:
	_set_city_position(city_id, position)
	selected_editor_city_id = city_id
	_add_editor_city_point(city_id)
	if city_checkboxes.has(city_id):
		var checkbox: CheckBox = city_checkboxes[city_id]
		checkbox.set_pressed_no_signal(true)

	if position_status_label != null:
		position_status_label.text = "%s: %d / %d | Auf Wasserpunkt gesetzt, Pathing wird angepasst." % [
			String(_editor_city_by_id(city_id).get("name", city_id)),
			int(position.get("x", 0)),
			int(position.get("y", 0))
		]
	_schedule_city_position_autosave()
	_refresh_map_editor()

func _schedule_city_position_autosave() -> void:
	if city_position_autosave_timer == null:
		_save_city_positions(false)
		return
	city_position_autosave_timer.start()

func _on_city_position_autosave_timeout() -> void:
	_save_city_positions(false)

func _set_city_position(city_id: String, position: Dictionary) -> void:
	var normalized_position := {
		"x": int(position.get("x", 0)),
		"y": int(position.get("y", 0))
	}
	for key in ["hanse_cities", "cities"]:
		var city_array: Array = catalog.get(key, [])
		for index in range(city_array.size()):
			var city: Dictionary = city_array[index]
			if String(city.get("id", "")) != city_id:
				continue
			city["position"] = normalized_position
			city_array[index] = city
			break
		catalog[key] = city_array

	if map_view != null:
		map_view.set_editor_city_position(city_id, normalized_position)

func _on_save_city_positions_pressed() -> void:
	_save_city_positions(true)

func _save_city_positions(show_success_status: bool) -> bool:
	var positions: Array[Dictionary] = []
	for city_entry in catalog.get("hanse_cities", []):
		var city: Dictionary = city_entry
		positions.append({
			"id": String(city.get("id", "")),
			"name": String(city.get("name", "")),
			"position": city.get("position", {})
		})

	var file := FileAccess.open(CITY_POSITIONS_EXPORT_PATH, FileAccess.WRITE)
	if file == null:
		position_status_label.text = "Speichern fehlgeschlagen: %s" % FileAccess.get_open_error()
		return false

	file.store_string(JSON.stringify({
		"version": EDITOR_VERSION,
		"positions": positions
	}, "\t"))
	file.close()
	if show_success_status:
		position_status_label.text = "Gespeichert: %s" % ProjectSettings.globalize_path(CITY_POSITIONS_EXPORT_PATH)
	else:
		position_status_label.text = "Position automatisch gespeichert. Schiffe nutzen den befahrbaren Hafenpunkt."
	return true

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

	if _save_default_main_map(true):
		_save_city_positions(false)

func _save_default_main_map(show_success_status: bool) -> bool:
	var file := FileAccess.open(CITY_VALUES_EXPORT_PATH, FileAccess.WRITE)
	if file == null:
		if export_status_label != null:
			export_status_label.text = "Speichern fehlgeschlagen: %s" % FileAccess.get_open_error()
		return false

	file.store_string(JSON.stringify(_build_custom_map_export_data(), "\t"))
	file.close()
	if export_status_label != null:
		if show_success_status:
			export_status_label.text = "Hauptkarte gespeichert: %s" % ProjectSettings.globalize_path(CITY_VALUES_EXPORT_PATH)
		else:
			export_status_label.text = "Hauptkarte automatisch aktualisiert: %s" % ProjectSettings.globalize_path(CITY_VALUES_EXPORT_PATH)
	return true
