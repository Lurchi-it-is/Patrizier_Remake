extends Control

const CatalogLoader = preload("res://scripts/data/catalog_loader.gd")
const SimulationState = preload("res://scripts/simulation/simulation_state.gd")
const CombatResolver = preload("res://scripts/simulation/combat_resolver.gd")

func _ready() -> void:
	var loader := CatalogLoader.new()
	var catalog := loader.load_all()
	var simulation := SimulationState.new(catalog)
	simulation.advance_days(1)

	var combat_preview := CombatResolver.resolve({
		"ship_attack": 8,
		"ship_defense": 7,
		"crew": 18,
		"morale": 0.72,
		"pirate_attack": 6,
		"pirate_crew": 14,
		"weather_risk": 0.15,
		"cargo_value": 620
	})

	_build_layout(catalog, simulation, combat_preview)

func _build_layout(catalog: Dictionary, simulation, combat_preview: Dictionary) -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 32
	root.offset_top = 24
	root.offset_right = -32
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var title := Label.new()
	title.text = "Hanseatische Warenwirtschaftssimulation"
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Phase 0 Fundament: Datenkataloge, Preisbildung, Tages-Tick und Seeschlacht-Auto-Resolver"
	subtitle.add_theme_font_size_override("font_size", 16)
	root.add_child(subtitle)

	var summary := RichTextLabel.new()
	summary.fit_content = true
	summary.bbcode_enabled = true
	summary.text = "[b]Geladene Daten[/b]\nWaren: %d\nStaedte: %d\nSchiffstypen: %d\nPiratenzonen: %d\nSimulationstag: %d" % [
		catalog.get("goods", []).size(),
		catalog.get("cities", []).size(),
		catalog.get("ship_types", []).size(),
		catalog.get("pirate_zones", []).size(),
		simulation.day
	]
	root.add_child(summary)

	var market := RichTextLabel.new()
	market.fit_content = true
	market.bbcode_enabled = true
	market.text = _market_preview(simulation)
	root.add_child(market)

	var combat := RichTextLabel.new()
	combat.fit_content = true
	combat.bbcode_enabled = true
	combat.text = "[b]Seeschlacht-Prototyp[/b]\nErgebnis: %s\nSchaden: %.1f\nFrachtverlust: %.1f%%\nKopfgeld: %d" % [
		combat_preview.get("outcome", "unknown"),
		combat_preview.get("damage", 0.0),
		combat_preview.get("cargo_loss_ratio", 0.0) * 100.0,
		combat_preview.get("bounty", 0)
	]
	root.add_child(combat)

func _market_preview(simulation) -> String:
	var lines: Array[String] = ["[b]Markt-Vorschau[/b]"]
	for city_id in simulation.city_state.keys():
		var city := simulation.city_state[city_id]
		var grain_price := simulation.get_price(city_id, "grain")
		var salt_price := simulation.get_price(city_id, "salt")
		lines.append("%s: Getreide %d, Salz %d" % [city.get("name", city_id), grain_price, salt_price])
	return "\n".join(lines)
