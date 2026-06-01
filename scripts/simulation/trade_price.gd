extends RefCounted

const DEFAULT_PROFILE := {
	"min_multiplier": 0.82,
	"max_multiplier": 1.55,
	"surplus_ratio": 3.2,
	"shortage_curve": 1.15,
	"surplus_curve": 1.2,
	"spread": 0.05,
}

const CATEGORY_PROFILES := {
	"food": {
		"min_multiplier": 0.84,
		"max_multiplier": 1.45,
		"surplus_ratio": 3.1,
		"shortage_curve": 1.2,
		"surplus_curve": 1.25,
		"spread": 0.03,
	},
	"preservation": {
		"min_multiplier": 0.82,
		"max_multiplier": 1.55,
		"surplus_ratio": 3.2,
		"shortage_curve": 1.15,
		"surplus_curve": 1.2,
		"spread": 0.04,
	},
	"construction": {
		"min_multiplier": 0.84,
		"max_multiplier": 1.4,
		"surplus_ratio": 3.2,
		"shortage_curve": 1.2,
		"surplus_curve": 1.25,
		"spread": 0.035,
	},
	"shipbuilding": {
		"min_multiplier": 0.82,
		"max_multiplier": 1.48,
		"surplus_ratio": 3.2,
		"shortage_curve": 1.16,
		"surplus_curve": 1.2,
		"spread": 0.04,
	},
	"raw_material": {
		"min_multiplier": 0.8,
		"max_multiplier": 1.55,
		"surplus_ratio": 3.3,
		"shortage_curve": 1.12,
		"surplus_curve": 1.15,
		"spread": 0.045,
	},
	"metal": {
		"min_multiplier": 0.8,
		"max_multiplier": 1.6,
		"surplus_ratio": 3.3,
		"shortage_curve": 1.1,
		"surplus_curve": 1.15,
		"spread": 0.05,
	},
	"luxury": {
		"min_multiplier": 0.76,
		"max_multiplier": 1.85,
		"surplus_ratio": 3.8,
		"shortage_curve": 1.0,
		"surplus_curve": 1.05,
		"spread": 0.075,
	},
}

static func calculate(base_price: int, stock: float, target_stock: float, daily_consumption: float = 0.0, category: String = "") -> int:
	return calculate_buy_price(base_price, stock, target_stock, daily_consumption, category)

static func calculate_market_price(base_price: int, stock: float, target_stock: float, daily_consumption: float = 0.0, category: String = "") -> int:
	if target_stock <= 0.0:
		return max(base_price, 1)

	var profile := _profile_for(category)
	var stock_ratio: float = _effective_stock_ratio(stock, target_stock, daily_consumption)
	var multiplier: float = 1.0
	if stock_ratio < 1.0:
		var scarcity: float = pow(1.0 - clampf(stock_ratio, 0.0, 1.0), float(profile.get("shortage_curve", 0.72)))
		multiplier = lerpf(1.0, float(profile.get("max_multiplier", 2.05)), scarcity)
	else:
		var surplus_span: float = max(0.1, float(profile.get("surplus_ratio", 2.8)) - 1.0)
		var surplus: float = pow(clampf((stock_ratio - 1.0) / surplus_span, 0.0, 1.0), float(profile.get("surplus_curve", 0.9)))
		multiplier = lerpf(1.0, float(profile.get("min_multiplier", 0.68)), surplus)

	var price: int = roundi(float(base_price) * multiplier)
	return max(price, 1)

static func calculate_buy_price(base_price: int, stock: float, target_stock: float, daily_consumption: float = 0.0, category: String = "") -> int:
	var market_price: int = calculate_market_price(base_price, stock, target_stock, daily_consumption, category)
	var spread: float = float(_profile_for(category).get("spread", 0.09))
	return max(1, roundi(float(market_price) * (1.0 + spread)))

static func calculate_sell_price(base_price: int, stock: float, target_stock: float, daily_consumption: float = 0.0, category: String = "") -> int:
	var market_price: int = calculate_market_price(base_price, stock, target_stock, daily_consumption, category)
	var spread: float = float(_profile_for(category).get("spread", 0.09))
	return max(1, roundi(float(market_price) * (1.0 - spread)))

static func calculate_average_buy(base_price: int, stock: float, target_stock: float, amount: int, daily_consumption: float = 0.0, category: String = "") -> Dictionary:
	return _average_transaction_price(base_price, stock, target_stock, amount, -1.0, true, daily_consumption, category)

static func calculate_average_sell(base_price: int, stock: float, target_stock: float, amount: int, daily_consumption: float = 0.0, category: String = "") -> Dictionary:
	return _average_transaction_price(base_price, stock, target_stock, amount, 1.0, false, daily_consumption, category)

static func _average_transaction_price(base_price: int, stock: float, target_stock: float, amount: int, stock_step: float, is_buy: bool, daily_consumption: float, category: String) -> Dictionary:
	if amount <= 0:
		var fallback_price: int = calculate_buy_price(base_price, stock, target_stock, daily_consumption, category) if is_buy else calculate_sell_price(base_price, stock, target_stock, daily_consumption, category)
		return {"unit_price": fallback_price, "total_price": 0.0}

	var total_price: int = 0
	for index in range(amount):
		var current_stock: float = max(0.0, stock + stock_step * float(index))
		total_price += calculate_buy_price(base_price, current_stock, target_stock, daily_consumption, category) if is_buy else calculate_sell_price(base_price, current_stock, target_stock, daily_consumption, category)

	return {
		"unit_price": max(1, roundi(float(total_price) / float(amount))),
		"total_price": float(total_price),
	}

static func _effective_stock_ratio(stock: float, target_stock: float, daily_consumption: float) -> float:
	if target_stock <= 0.0:
		return 1.0

	var reserve_consumption: float = max(0.01, target_stock / 30.0)
	var effective_consumption: float = max(daily_consumption, reserve_consumption)
	var target_days: float = max(1.0, target_stock / effective_consumption)
	var stock_days: float = max(0.0, stock) / effective_consumption
	return clampf(min(stock / target_stock, stock_days / target_days), 0.0, 4.0)

static func _profile_for(category: String) -> Dictionary:
	if CATEGORY_PROFILES.has(category):
		return CATEGORY_PROFILES[category]
	return DEFAULT_PROFILE
