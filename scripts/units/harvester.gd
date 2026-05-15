extends Unit
## Harvester: drives to the nearest ore tile, mines until full,
## returns to the closest friendly refinery and deposits credits.

enum HState { SEEK_ORE, MINING, RETURN, DEPOSIT }

const CAPACITY := 500
const ORE_PER_TICK := 25
const MINE_INTERVAL := 0.4
const DEPOSIT_RATE := 250  # credits per second while unloading

var _cargo := 0
var _hstate: int = HState.SEEK_ORE
var _mine_timer := 0.0
var _target_ore: Vector2i = Vector2i(-1, -1)
var _refinery = null


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	# Harvesters never fight; run their own economy loop.
	match _hstate:
		HState.SEEK_ORE:
			_do_seek_ore()
		HState.MINING:
			_do_mining(delta)
		HState.RETURN:
			_do_return()
		HState.DEPOSIT:
			_do_deposit(delta)


func _nearest_ore() -> Vector2i:
	if GameState.map == null:
		return Vector2i(-1, -1)
	return GameState.map.nearest_ore_cell(global_position)


func _nearest_refinery():
	var best = null
	var best_d := INF
	for b in GameState.buildings[team]:
		if not is_instance_valid(b) or not b.is_alive():
			continue
		if not b.data.is_refinery:
			continue
		var d := global_position.distance_to(b.global_position)
		if d < best_d:
			best_d = d
			best = b
	return best


func _arrived_at(p: Vector2, tol := 12.0) -> bool:
	return global_position.distance_to(p) <= tol


func _do_seek_ore() -> void:
	if _cargo >= CAPACITY:
		_hstate = HState.RETURN
		return
	if _target_ore.x < 0 or not GameState.map.has_ore(_target_ore):
		_target_ore = _nearest_ore()
		if _target_ore.x < 0:
			_follow_path()  # idle drift; no ore left
			return
		_recompute_path(GameState.grid.cell_to_world_center(_target_ore))
	var ore_pos := GameState.grid.cell_to_world_center(_target_ore)
	if _arrived_at(ore_pos, Grid.CELL):
		_hstate = HState.MINING
	else:
		_follow_path()


func _do_mining(delta: float) -> void:
	if _cargo >= CAPACITY or not GameState.map.has_ore(_target_ore):
		_hstate = HState.RETURN if _cargo > 0 else HState.SEEK_ORE
		_target_ore = Vector2i(-1, -1)
		return
	_mine_timer -= delta
	if _mine_timer <= 0.0:
		_mine_timer = MINE_INTERVAL
		var got: int = GameState.map.extract_ore(_target_ore, ORE_PER_TICK)
		_cargo += got
		queue_redraw()
		if got == 0:
			_target_ore = Vector2i(-1, -1)
			_hstate = HState.SEEK_ORE


func _do_return() -> void:
	if _refinery == null or not is_instance_valid(_refinery) \
			or not _refinery.is_alive():
		_refinery = _nearest_refinery()
		if _refinery == null:
			return
		_recompute_path(_refinery.global_position)
	if _path.is_empty():
		_recompute_path(_refinery.global_position)
	if _arrived_at(_refinery.global_position, Grid.CELL * 2.0):
		_hstate = HState.DEPOSIT
	else:
		_follow_path()


func _do_deposit(delta: float) -> void:
	var amount: int = min(_cargo, int(ceil(DEPOSIT_RATE * delta)))
	if amount <= 0:
		amount = _cargo
	GameState.add_credits(team, amount)
	_cargo -= amount
	queue_redraw()
	if _cargo <= 0:
		_cargo = 0
		_hstate = HState.SEEK_ORE
		_target_ore = Vector2i(-1, -1)


func _draw() -> void:
	var col := _team_color()
	var r := data.radius
	draw_rect(Rect2(-r, -r * 0.8, r * 2.0, r * 1.6), col.darkened(0.15))
	# Cargo fill indicator.
	var frac := clampf(float(_cargo) / float(CAPACITY), 0.0, 1.0)
	draw_rect(Rect2(-r * 0.7, -r * 0.4, r * 1.4 * frac, r * 0.8),
		Color(0.95, 0.8, 0.3))
	if selected:
		draw_arc(Vector2.ZERO, r + 5.0, 0.0, TAU, 24,
			Color(0.2, 1.0, 0.3), 2.0)
	if health < data.max_health:
		var w := r * 2.0
		var hf := clampf(float(health) / float(data.max_health), 0.0, 1.0)
		draw_rect(Rect2(-w * 0.5, -r - 8.0, w, 3.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w * 0.5, -r - 8.0, w * hf, 3.0),
			Color(0.3, 0.9, 0.3))
