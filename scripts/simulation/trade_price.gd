extends RefCounted

static func calculate(base_price: int, stock: float, target_stock: float) -> int:
	if target_stock <= 0.0:
		return max(base_price, 1)

	var stock_ratio: float = clamp(stock / target_stock, 0.35, 2.25)
	var scarcity_multiplier: float = pow(1.0 / stock_ratio, 0.34)
	var price: int = roundi(base_price * clamp(scarcity_multiplier, 0.78, 1.38))
	return max(price, 1)
