extends RefCounted

const TradePrice = preload("res://scripts/simulation/trade_price.gd")

var day: int = 0
var goods_by_id: Dictionary = {}
var city_state: Dictionary = {}

func _init(catalog: Dictionary) -> void:
	for good in catalog.get("goods", []):
		goods_by_id[good["id"]] = good

	for city in catalog.get("cities", []):
		var state := city.duplicate(true)
		city_state[state["id"]] = state

func advance_days(days: int) -> void:
	for _i in range(max(days, 0)):
		day += 1
		_advance_one_day()

func get_price(city_id: String, good_id: String) -> int:
	if not city_state.has(city_id) or not goods_by_id.has(good_id):
		return 0

	var city := city_state[city_id]
	var good := goods_by_id[good_id]
	var stock := float(city.get("stock", {}).get(good_id, 0))
	var target := float(city.get("target_stock", {}).get(good_id, 1))
	return TradePrice.calculate(int(good.get("base_price", 1)), stock, target)

func _advance_one_day() -> void:
	for city_id in city_state.keys():
		var city := city_state[city_id]
		_apply_production(city)
		_apply_consumption(city)

func _apply_production(city: Dictionary) -> void:
	var stock: Dictionary = city.get("stock", {})
	for good_id in city.get("production", {}).keys():
		stock[good_id] = float(stock.get(good_id, 0)) + float(city["production"][good_id])
	city["stock"] = stock

func _apply_consumption(city: Dictionary) -> void:
	var stock: Dictionary = city.get("stock", {})
	for good_id in city.get("consumption", {}).keys():
		stock[good_id] = max(0.0, float(stock.get(good_id, 0)) - float(city["consumption"][good_id]))
	city["stock"] = stock
