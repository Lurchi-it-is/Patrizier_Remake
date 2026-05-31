extends RefCounted

const TradePrice = preload("res://scripts/simulation/trade_price.gd")

var day: int = 0
var goods_by_id: Dictionary = {}
var population_groups_by_id: Dictionary = {}
var city_state: Dictionary = {}

func _init(catalog: Dictionary) -> void:
	for good_entry in catalog.get("goods", []):
		var good: Dictionary = good_entry
		goods_by_id[good["id"]] = good

	for group_entry in catalog.get("population_groups", []):
		var group: Dictionary = group_entry
		population_groups_by_id[group["id"]] = group

	for city_entry in catalog.get("cities", []):
		var city: Dictionary = city_entry
		var state: Dictionary = city.duplicate(true)
		city_state[state["id"]] = state

func advance_days(days: int) -> void:
	for _i in range(max(days, 0)):
		day += 1
		_advance_one_day()

func get_price(city_id: String, good_id: String) -> int:
	if not city_state.has(city_id) or not goods_by_id.has(good_id):
		return 0

	var city: Dictionary = city_state[city_id]
	var good: Dictionary = goods_by_id[good_id]
	var stock: float = float(city.get("stock", {}).get(good_id, 0))
	var target: float = float(city.get("target_stock", {}).get(good_id, 1))
	return TradePrice.calculate(int(good.get("base_price", 1)), stock, target)

func _advance_one_day() -> void:
	for city_id in city_state.keys():
		var city: Dictionary = city_state[city_id]
		_apply_production(city)
		_apply_consumption(city)

func _apply_production(city: Dictionary) -> void:
	var stock: Dictionary = city.get("stock", {})
	for good_id in city.get("production", {}).keys():
		stock[good_id] = float(stock.get(good_id, 0)) + float(city["production"][good_id])
	city["stock"] = stock

func _apply_consumption(city: Dictionary) -> void:
	var stock: Dictionary = city.get("stock", {})
	var consumption := _combined_daily_consumption(city)
	for good_id in consumption.keys():
		stock[good_id] = max(0.0, float(stock.get(good_id, 0)) - float(consumption[good_id]))
	city["stock"] = stock

func get_daily_consumption(city_id: String) -> Dictionary:
	if not city_state.has(city_id):
		return {}

	return _combined_daily_consumption(city_state[city_id])

func _combined_daily_consumption(city: Dictionary) -> Dictionary:
	var combined: Dictionary = {}
	for good_id in city.get("consumption", {}).keys():
		combined[good_id] = float(city["consumption"][good_id])

	var population_groups: Dictionary = city.get("population_groups", {})
	for group_id in population_groups.keys():
		if not population_groups_by_id.has(group_id):
			continue

		var group: Dictionary = population_groups_by_id[group_id]
		var group_population := float(population_groups[group_id])
		var needs: Dictionary = group.get("daily_consumption_per_1000", {})
		for good_id in needs.keys():
			combined[good_id] = float(combined.get(good_id, 0.0)) + group_population / 1000.0 * float(needs[good_id])

	return combined
