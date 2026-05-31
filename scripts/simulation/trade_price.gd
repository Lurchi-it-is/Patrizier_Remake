extends RefCounted

static func calculate(base_price: int, stock: float, target_stock: float) -> int:
	if target_stock <= 0.0:
		return max(base_price, 1)

	var stock_ratio := clamp(stock / target_stock, 0.05, 3.0)
	var scarcity_multiplier := pow(1.0 / stock_ratio, 0.72)
	var price := roundi(base_price * clamp(scarcity_multiplier, 0.45, 2.75))
	return max(price, 1)
