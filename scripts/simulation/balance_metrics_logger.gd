extends RefCounted

const DEFAULT_LOG_PATH := "user://balance_metrics.jsonl"

var log_path: String = DEFAULT_LOG_PATH
var session_id: String = ""

func _init(path: String = DEFAULT_LOG_PATH) -> void:
	log_path = path
	session_id = Time.get_datetime_string_from_system(false, true)
	_reset_log()

func log_event(event_type: String, day: int, simulation_time_days: float, payload: Dictionary) -> void:
	log_events([_event_data(event_type, day, simulation_time_days, payload)])

func log_events(events: Array) -> void:
	if events.is_empty():
		return

	var file: FileAccess = FileAccess.open(log_path, FileAccess.READ_WRITE)
	if file == null:
		push_warning("Could not open balance metrics log: %s" % log_path)
		return

	file.seek_end()
	for event_entry in events:
		var event: Dictionary = event_entry
		file.store_line(JSON.stringify(event))
	file.close()

func _event_data(event_type: String, day: int, simulation_time_days: float, payload: Dictionary) -> Dictionary:
	return {
		"session_id": session_id,
		"event_type": event_type,
		"day": day,
		"simulation_time_days": simulation_time_days,
		"payload": payload,
	}

func log_daily_city_metrics(day: int, simulation_time_days: float, simulation, goods: Array) -> void:
	var events: Array = []
	for city_id in simulation.city_state.keys():
		var city: Dictionary = simulation.city_state[city_id]
		var daily_consumption: Dictionary = simulation.get_daily_consumption(String(city_id))
		for good_entry in goods:
			var good: Dictionary = good_entry
			var good_id: String = String(good.get("id", ""))
			events.append(_event_data("city_good_daily", day, simulation_time_days, {
				"city_id": String(city_id),
				"city_name": String(city.get("name", city_id)),
				"good_id": good_id,
				"stock": simulation.get_stock(String(city_id), good_id),
				"target_stock": simulation.get_target_stock(String(city_id), good_id),
				"price": simulation.get_price(String(city_id), good_id),
				"production": float(city.get("production", {}).get(good_id, 0.0)),
				"consumption": float(daily_consumption.get(good_id, 0.0)),
			}))
	log_events(events)

func _reset_log() -> void:
	var file: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not reset balance metrics log: %s" % log_path)
		return

	file.store_line(JSON.stringify({
		"session_id": session_id,
		"event_type": "session_start",
		"day": 0,
		"simulation_time_days": 0.0,
		"payload": {
			"log_path": log_path,
			"schema": "jsonl",
			"purpose": "AI trader and city economy balancing metrics",
		},
	}))
	file.close()
