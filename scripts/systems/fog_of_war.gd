class_name FogOfWar
extends Node2D
## Lightweight tile fog: UNSEEN (black) -> EXPLORED (dim) -> VISIBLE (clear).
## Recomputed on a timer from player units' & buildings' sight radius.

enum Vis { UNSEEN, EXPLORED, VISIBLE }

const UPDATE_INTERVAL := 0.25

var cols: int
var rows: int
var _state := {}                 # Vector2i -> Vis
var _timer := 0.0


func init_fog(_cols: int, _rows: int) -> void:
	cols = _cols
	rows = _rows
	z_index = 50
	for x in range(cols):
		for y in range(rows):
			_state[Vector2i(x, y)] = Vis.UNSEEN


func is_visible_cell(c: Vector2i) -> bool:
	return _state.get(c, Vis.UNSEEN) == Vis.VISIBLE


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = UPDATE_INTERVAL
	_recompute()


func _recompute() -> void:
	# Demote everything currently visible to explored.
	for c in _state.keys():
		if _state[c] == Vis.VISIBLE:
			_state[c] = Vis.EXPLORED

	var sources := []
	for u in GameState.units[GameState.Team.PLAYER]:
		if is_instance_valid(u) and u.is_alive():
			sources.append([u.global_position, u.data.sight])
	for b in GameState.buildings[GameState.Team.PLAYER]:
		if is_instance_valid(b) and b.is_alive():
			sources.append([b.global_position, b.data.sight])

	for s in sources:
		var center: Vector2i = GameState.grid.world_to_cell(s[0])
		var r: int = s[1]
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if dx * dx + dy * dy > r * r:
					continue
				var c := center + Vector2i(dx, dy)
				if c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows:
					_state[c] = Vis.VISIBLE
	queue_redraw()


func _draw() -> void:
	var cs := Grid.CELL
	for c in _state.keys():
		match _state[c]:
			Vis.UNSEEN:
				draw_rect(Rect2(c.x * cs, c.y * cs, cs, cs),
					Color(0, 0, 0, 0.92))
			Vis.EXPLORED:
				draw_rect(Rect2(c.x * cs, c.y * cs, cs, cs),
					Color(0, 0, 0, 0.45))
