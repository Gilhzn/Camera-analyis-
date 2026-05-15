class_name Map
extends Node2D
## Procedural top-down terrain: grass, impassable rock, harvestable ore.
## Drawn programmatically (no external tilesets).

enum Tile { GRASS, ROCK }

const ORE_START := 600  # ore value per ore cell

var cols: int
var rows: int
var _tiles := {}              # Vector2i -> Tile
var _ore := {}                # Vector2i -> int (remaining ore)


func generate(_cols: int, _rows: int, seed_val: int) -> void:
	cols = _cols
	rows = _rows
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	z_index = 0

	for x in range(cols):
		for y in range(rows):
			_tiles[Vector2i(x, y)] = Tile.GRASS

	# Scatter rock clusters (avoid the outer ring and base corners).
	var rock_clusters := int(cols * rows / 220)
	for i in range(rock_clusters):
		var cx := rng.randi_range(6, cols - 7)
		var cy := rng.randi_range(6, rows - 7)
		var rad := rng.randi_range(1, 3)
		for dx in range(-rad, rad + 1):
			for dy in range(-rad, rad + 1):
				if Vector2(dx, dy).length() <= rad:
					var c := Vector2i(cx + dx, cy + dy)
					if _in(c) and not _near_bases(c):
						_tiles[c] = Tile.ROCK

	# Two ore fields near each starting corner.
	_make_ore_field(Vector2i(int(cols * 0.22), int(rows * 0.5)), 5, rng)
	_make_ore_field(Vector2i(int(cols * 0.78), int(rows * 0.5)), 5, rng)
	_make_ore_field(Vector2i(int(cols * 0.5), int(rows * 0.25)), 4, rng)
	_make_ore_field(Vector2i(int(cols * 0.5), int(rows * 0.75)), 4, rng)


func _in(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


func _near_bases(c: Vector2i) -> bool:
	# Keep both start corners clear of rock.
	var p_start := Vector2i(6, int(rows * 0.5))
	var e_start := Vector2i(cols - 7, int(rows * 0.5))
	return Vector2(c - p_start).length() < 6.0 \
		or Vector2(c - e_start).length() < 6.0


func _make_ore_field(center: Vector2i, radius: int,
		rng: RandomNumberGenerator) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var c := center + Vector2i(dx, dy)
			if not _in(c) or _tiles[c] == Tile.ROCK:
				continue
			if Vector2(dx, dy).length() <= radius + rng.randf() * 1.5:
				_ore[c] = ORE_START


# --- Queries used by harvesters / pathfinder -----------------------------

func is_rock(c: Vector2i) -> bool:
	return _tiles.get(c, Tile.GRASS) == Tile.ROCK


func has_ore(c: Vector2i) -> bool:
	return _ore.get(c, 0) > 0


func extract_ore(c: Vector2i, amount: int) -> int:
	var have: int = _ore.get(c, 0)
	if have <= 0:
		return 0
	var taken: int = min(have, amount)
	_ore[c] = have - taken
	if _ore[c] <= 0:
		_ore.erase(c)
	queue_redraw()
	return taken


func nearest_ore_cell(from_world: Vector2) -> Vector2i:
	var from_cell: Vector2i = GameState.grid.world_to_cell(from_world)
	var best := Vector2i(-1, -1)
	var best_d := INF
	for c in _ore.keys():
		var d := Vector2(c - from_cell).length()
		if d < best_d:
			best_d = d
			best = c
	return best


func apply_to_pathfinder() -> void:
	for c in _tiles.keys():
		if _tiles[c] == Tile.ROCK:
			GameState.pathfinder.set_solid(c, true)
			GameState.grid.set_occupied(c, true)


# --- Rendering -----------------------------------------------------------

func _draw() -> void:
	var cs := Grid.CELL
	# Base grass backdrop in one rect.
	draw_rect(Rect2(0, 0, cols * cs, rows * cs), Color(0.18, 0.27, 0.16))
	# Subtle grid + features.
	for c in _tiles.keys():
		if _tiles[c] == Tile.ROCK:
			draw_rect(Rect2(c.x * cs, c.y * cs, cs, cs),
				Color(0.32, 0.30, 0.28))
	for c in _ore.keys():
		var frac := clampf(float(_ore[c]) / float(ORE_START), 0.2, 1.0)
		draw_rect(Rect2(c.x * cs + 2, c.y * cs + 2, cs - 4, cs - 4),
			Color(0.85, 0.7, 0.25, frac))
