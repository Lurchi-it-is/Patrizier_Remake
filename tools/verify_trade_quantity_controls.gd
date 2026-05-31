extends SceneTree

func _initialize() -> void:
	var scene := load("res://scenes/main_game.tscn")
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame

	var city_id := "luebeck"
	var good_id := "grain"

	game._show_trade_window(city_id)
	await process_frame
	var visible_text := _collect_visible_text(game.trade_popup)
	for forbidden_text in ["Nachfrage", "Information", "Handel abschliessen"]:
		if visible_text.contains(forbidden_text):
			push_error("Trade window still contains removed text: %s." % forbidden_text)
			quit(1)
			return

	var trade_grid := _find_first_grid(game.trade_popup)
	if trade_grid == null or trade_grid.columns != 7:
		push_error("Expected trade table to use 7 columns after removing demand.")
		quit(1)
		return

	game.selected_trade_quantity = 5
	var cargo_before: int = game._player_cargo_amount(good_id)
	game._on_player_buy_good(city_id, good_id)
	var cargo_after: int = game._player_cargo_amount(good_id)
	if cargo_after - cargo_before != 5:
		push_error("Expected 5 bought units, got %d." % (cargo_after - cargo_before))
		quit(1)
		return

	game.selected_trade_quantity = 10
	cargo_before = game._player_cargo_amount(good_id)
	game._on_player_buy_good(city_id, good_id)
	cargo_after = game._player_cargo_amount(good_id)
	if cargo_after - cargo_before != 10:
		push_error("Expected 10 bought units, got %d." % (cargo_after - cargo_before))
		quit(1)
		return

	game.selected_trade_quantity = 0
	game._on_player_sell_good(city_id, good_id)
	if game._player_cargo_amount(good_id) != 0:
		push_error("Expected Max sell to empty selected cargo.")
		quit(1)
		return

	quit(0)

func _collect_visible_text(node: Node) -> String:
	var texts: Array[String] = []
	_collect_visible_text_recursive(node, texts)
	return "\n".join(texts)

func _collect_visible_text_recursive(node: Node, texts: Array[String]) -> void:
	if node is Label:
		texts.append((node as Label).text)
	elif node is Button:
		texts.append((node as Button).text)
	elif node is RichTextLabel:
		texts.append((node as RichTextLabel).text)

	for child in node.get_children():
		_collect_visible_text_recursive(child, texts)

func _find_first_grid(node: Node) -> GridContainer:
	if node is GridContainer:
		return node
	for child in node.get_children():
		var grid := _find_first_grid(child)
		if grid != null:
			return grid
	return null
