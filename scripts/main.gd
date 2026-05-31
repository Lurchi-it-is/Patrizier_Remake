extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const SimulationState = preload("res://scripts/simulation/simulation_state.gd")
const CombatResolver = preload("res://scripts/simulation/combat_resolver.gd")
const MapView = preload("res://scripts/ui/map_view.gd")

var catalog: Dictionary = {}
var simulation
var combat_preview: Dictionary = {}

var day_label: Label
var market_label: RichTextLabel
var combat_label: RichTextLabel
var map_view

func _ready() -> void:
	var loader := CatalogLoader.new()
	catalog = loader.load_all()
	simulation = SimulationState.new(catalog)
	simulation.advance_days(1)
	combat_preview = _resolve_demo_combat()

	_build_layout()
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

	var header := _build_header()
	root.add_child(header)

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
	map_panel.add_child(map_view)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(360, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation", 12)
	body.add_child(sidebar)

	sidebar.add_child(_build_status_panel())
	sidebar.add_child(_build_market_panel())
	sidebar.add_child(_build_combat_panel())

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
	subtitle.text = "Phase 0.2: sichtbarer Prototyp fuer Karte, Markt und Piratenrisiko"
	subtitle.add_theme_font_size_override("font_size", 15)
	title_box.add_child(subtitle)

	var version := Label.new()
	version.text = "0.2.1-foundation"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 14)
	header.add_child(version)

	return header

func _build_status_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Simulation"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	day_label = Label.new()
	content.add_child(day_label)

	var stats := Label.new()
	stats.text = "Waren: %d\nStaedte: %d\nSchiffstypen: %d\nPiratenzonen: %d" % [
		catalog.get("goods", []).size(),
		catalog.get("cities", []).size(),
		catalog.get("ship_types", []).size(),
		catalog.get("pirate_zones", []).size()
	]
	content.add_child(stats)

	var advance := Button.new()
	advance.text = "Naechster Tag"
	advance.pressed.connect(_on_advance_day_pressed)
	content.add_child(advance)

	return panel

func _build_market_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Marktpreise"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	market_label = RichTextLabel.new()
	market_label.bbcode_enabled = true
	market_label.fit_content = true
	market_label.custom_minimum_size = Vector2(320, 120)
	content.add_child(market_label)

	return panel

func _build_combat_panel() -> Control:
	var panel := PanelContainer.new()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "Piratenbegegnung"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	combat_label = RichTextLabel.new()
	combat_label.bbcode_enabled = true
	combat_label.fit_content = true
	combat_label.custom_minimum_size = Vector2(320, 120)
	content.add_child(combat_label)

	var resolve := Button.new()
	resolve.text = "Begegnung auswerten"
	resolve.pressed.connect(_on_resolve_combat_pressed)
	content.add_child(resolve)

	return panel

func _refresh_ui() -> void:
	day_label.text = "Simulationstag: %d" % simulation.day
	market_label.text = _market_preview()
	combat_label.text = _combat_preview()
	map_view.set_simulation_day(simulation.day)

func _market_preview() -> String:
	var lines: Array[String] = []
	for city_id in simulation.city_state.keys():
		var city: Dictionary = simulation.city_state[city_id]
		var grain_price: int = simulation.get_price(city_id, "grain")
		var salt_price: int = simulation.get_price(city_id, "salt")
		var herring_price: int = simulation.get_price(city_id, "herring")
		lines.append("[b]%s[/b]\nGetreide %d | Salz %d | Hering %d" % [
			city.get("name", city_id),
			grain_price,
			salt_price,
			herring_price
		])
	return "\n\n".join(lines)

func _combat_preview() -> String:
	return "Route: Hamburg -> Luebeck -> Visby\nStatus: %s\nSchaden: %.1f\nFrachtverlust: %.1f%%\nKopfgeld: %d" % [
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
	simulation.advance_days(1)
	_refresh_ui()

func _on_resolve_combat_pressed() -> void:
	combat_preview = _resolve_demo_combat()
	_refresh_ui()
