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
		_normalize_stock_values(state)
		state["production_remainder"] = {}
		state["consumption_remainder"] = {}
		city_state[state["id"]] = state

func advance_days(days: int) -> void:
	for _i in range(max(days, 0)):
		day += 1
		_advance_one_day()

func get_price(city_id: String, good_id: String) -> int:
	return get_buy_price(city_id, good_id)

func get_buy_price(city_id: String, good_id: String) -> int:
	if not city_state.has(city_id) or not goods_by_id.has(good_id):
		return 0

	var city: Dictionary = city_state[city_id]
	var good: Dictionary = goods_by_id[good_id]
	var stock: float = float(city.get("stock", {}).get(good_id, 0))
	var target: float = float(city.get("target_stock", {}).get(good_id, 1))
	var consumption: float = float(_combined_daily_consumption(city).get(good_id, 0.0))
	return TradePrice.calculate_buy_price(int(good.get("base_price", 1)), stock, target, consumption, String(good.get("category", "")))

func get_sell_price(city_id: String, good_id: String) -> int:
	if not city_state.has(city_id) or not goods_by_id.has(good_id):
		return 0

	var city: Dictionary = city_state[city_id]
	var good: Dictionary = goods_by_id[good_id]
	var stock: float = float(city.get("stock", {}).get(good_id, 0))
	var target: float = float(city.get("target_stock", {}).get(good_id, 1))
	var consumption: float = float(_combined_daily_consumption(city).get(good_id, 0.0))
	return TradePrice.calculate_sell_price(int(good.get("base_price", 1)), stock, target, consumption, String(good.get("category", "")))

func get_stock(city_id: String, good_id: String) -> int:
	if not city_state.has(city_id):
		return 0

	var city: Dictionary = city_state[city_id]
	return _whole_units(city.get("stock", {}).get(good_id, 0))

func get_target_stock(city_id: String, good_id: String) -> int:
	if not city_state.has(city_id):
		return 0

	var city: Dictionary = city_state[city_id]
	return _whole_units(city.get("target_stock", {}).get(good_id, 0))

func quote_buy_from_city(city_id: String, good_id: String, requested_amount: float) -> Dictionary:
	if not city_state.has(city_id) or not goods_by_id.has(good_id) or requested_amount <= 0.0:
		return {"amount": 0, "unit_price": 0, "total_price": 0.0}

	var city: Dictionary = city_state[city_id]
	var good: Dictionary = goods_by_id[good_id]
	var stock: Dictionary = city.get("stock", {})
	var available: int = _whole_units(stock.get(good_id, 0))
	var requested_units: int = _whole_units(requested_amount)
	var amount: int = mini(requested_units, available)
	if amount <= 0:
		return {"amount": 0, "unit_price": get_buy_price(city_id, good_id), "total_price": 0.0}

	var target: float = float(city.get("target_stock", {}).get(good_id, 1))
	var consumption: float = float(_combined_daily_consumption(city).get(good_id, 0.0))
	var price_result: Dictionary = TradePrice.calculate_average_buy(
		int(good.get("base_price", 1)),
		float(available),
		target,
		amount,
		consumption,
		String(good.get("category", ""))
	)
	return {"amount": amount, "unit_price": int(price_result.get("unit_price", 0)), "total_price": float(price_result.get("total_price", 0.0))}

func buy_from_city(city_id: String, good_id: String, requested_amount: float) -> Dictionary:
	if not city_state.has(city_id) or not goods_by_id.has(good_id) or requested_amount <= 0.0:
		return {"amount": 0, "unit_price": 0, "total_price": 0.0}

	var quote: Dictionary = quote_buy_from_city(city_id, good_id, requested_amount)
	var amount: int = int(quote.get("amount", 0))
	if amount <= 0:
		return quote

	var city: Dictionary = city_state[city_id]
	var stock: Dictionary = city.get("stock", {})
	var available: int = _whole_units(stock.get(good_id, 0))
	stock[good_id] = maxi(0, available - amount)
	city["stock"] = stock
	return quote

func quote_sell_to_city(city_id: String, good_id: String, amount: float) -> Dictionary:
	if not city_state.has(city_id) or not goods_by_id.has(good_id) or amount <= 0.0:
		return {"amount": 0, "unit_price": 0, "total_price": 0.0}

	var city: Dictionary = city_state[city_id]
	var good: Dictionary = goods_by_id[good_id]
	var stock: Dictionary = city.get("stock", {})
	var sold_units: int = _whole_units(amount)
	if sold_units <= 0:
		return {"amount": 0, "unit_price": get_sell_price(city_id, good_id), "total_price": 0.0}

	var current_stock: int = _whole_units(stock.get(good_id, 0))
	var target: float = float(city.get("target_stock", {}).get(good_id, 1))
	var consumption: float = float(_combined_daily_consumption(city).get(good_id, 0.0))
	var price_result: Dictionary = TradePrice.calculate_average_sell(
		int(good.get("base_price", 1)),
		float(current_stock),
		target,
		sold_units,
		consumption,
		String(good.get("category", ""))
	)
	return {"amount": sold_units, "unit_price": int(price_result.get("unit_price", 0)), "total_price": float(price_result.get("total_price", 0.0))}

func sell_to_city(city_id: String, good_id: String, amount: float) -> Dictionary:
	if not city_state.has(city_id) or not goods_by_id.has(good_id) or amount <= 0.0:
		return {"amount": 0, "unit_price": 0, "total_price": 0.0}

	var quote: Dictionary = quote_sell_to_city(city_id, good_id, amount)
	var sold_units: int = int(quote.get("amount", 0))
	if sold_units <= 0:
		return quote

	var city: Dictionary = city_state[city_id]
	var stock: Dictionary = city.get("stock", {})
	var current_stock: int = _whole_units(stock.get(good_id, 0))
	stock[good_id] = current_stock + sold_units
	city["stock"] = stock
	return quote

func city_ids() -> Array[String]:
	var ids: Array[String] = []
	for city_id in city_state.keys():
		ids.append(String(city_id))
	return ids

func _advance_one_day() -> void:
	for city_id in city_state.keys():
		var city: Dictionary = city_state[city_id]
		_apply_production(city)
		_apply_consumption(city)

func _apply_production(city: Dictionary) -> void:
	var stock: Dictionary = city.get("stock", {})
	var remainder: Dictionary = city.get("production_remainder", {})
	for good_id in city.get("production", {}).keys():
		var daily_amount: float = float(city["production"][good_id])
		var total_amount: float = float(remainder.get(good_id, 0.0)) + max(0.0, daily_amount)
		var produced_units: int = _whole_units(total_amount)
		remainder[good_id] = total_amount - float(produced_units)
		stock[good_id] = _whole_units(stock.get(good_id, 0)) + produced_units
	city["stock"] = stock
	city["production_remainder"] = remainder

func _apply_consumption(city: Dictionary) -> void:
	var stock: Dictionary = city.get("stock", {})
	var remainder: Dictionary = city.get("consumption_remainder", {})
	var consumption: Dictionary = _combined_daily_consumption(city)
	for good_id in consumption.keys():
		var total_amount: float = float(remainder.get(good_id, 0.0)) + max(0.0, float(consumption[good_id]))
		var requested_units: int = _whole_units(total_amount)
		remainder[good_id] = total_amount - float(requested_units)
		stock[good_id] = maxi(0, _whole_units(stock.get(good_id, 0)) - requested_units)
	city["stock"] = stock
	city["consumption_remainder"] = remainder

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
		var group_population: float = float(population_groups[group_id])
		var needs: Dictionary = group.get("daily_consumption_per_1000", {})
		for good_id in needs.keys():
			combined[good_id] = float(combined.get(good_id, 0.0)) + group_population / 1000.0 * float(needs[good_id])

	return combined

func _normalize_stock_values(city: Dictionary) -> void:
	var stock: Dictionary = city.get("stock", {})
	for good_id in stock.keys():
		stock[good_id] = _whole_units(stock[good_id])
	city["stock"] = stock

func _whole_units(value: Variant) -> int:
	return max(0, floori(float(value)))
