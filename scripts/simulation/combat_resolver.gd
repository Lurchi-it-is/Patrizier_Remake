extends RefCounted

static func resolve(input: Dictionary) -> Dictionary:
	var ship_attack := float(input.get("ship_attack", 1))
	var ship_defense := float(input.get("ship_defense", 1))
	var crew := float(input.get("crew", 1))
	var morale := clamp(float(input.get("morale", 0.5)), 0.05, 1.5)
	var pirate_attack := float(input.get("pirate_attack", 1))
	var pirate_crew := float(input.get("pirate_crew", 1))
	var weather_risk := clamp(float(input.get("weather_risk", 0.0)), 0.0, 1.0)
	var cargo_value := int(input.get("cargo_value", 0))

	var player_power := (ship_attack + ship_defense * 0.65 + crew * 0.22) * morale
	var pirate_power := (pirate_attack + pirate_crew * 0.25) * (1.0 + weather_risk * 0.35)
	var ratio := player_power / max(pirate_power, 0.1)

	if ratio >= 1.35:
		return {
			"outcome": "pirates_defeated",
			"damage": clamp(18.0 / ratio, 3.0, 18.0),
			"cargo_loss_ratio": 0.0,
			"bounty": roundi(pirate_power * 12.0)
		}
	if ratio >= 0.85:
		return {
			"outcome": "escaped",
			"damage": clamp(30.0 / max(ratio, 0.1), 18.0, 42.0),
			"cargo_loss_ratio": 0.1,
			"bounty": 0
		}

	return {
		"outcome": "cargo_plundered",
		"damage": clamp(55.0 / max(ratio, 0.1), 45.0, 95.0),
		"cargo_loss_ratio": clamp(0.25 + weather_risk * 0.2 + cargo_value / 10000.0, 0.25, 0.8),
		"bounty": 0
	}
