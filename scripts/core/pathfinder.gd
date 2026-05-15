class_name Pathfinder
extends RefCounted
## Wraps AStarGrid2D for grid-based unit movement.
## Solid cells = rock terrain + building footprints.

var _astar := AStarGrid2D.new()
var _grid: Grid


func setup(grid: Grid) -> void:
	_grid = grid
	_astar.region = Rect2i(0, 0, grid.cols, grid.rows)
	_astar.cell_size = Vector2(Grid.CELL, Grid.CELL)
	# Path points land on tile centers.
	_astar.offset = Vector2(Grid.CELL * 0.5, Grid.CELL * 0.5)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()


func set_solid(cell: Vector2i, value: bool) -> void:
	if _astar.is_in_boundsv(cell):
		_astar.set_point_solid(cell, value)


func set_footprint_solid(origin: Vector2i, size: Vector2i, value: bool) -> void:
	for x in range(size.x):
		for y in range(size.y):
			set_solid(origin + Vector2i(x, y), value)


func _is_solid(cell: Vector2i) -> bool:
	if not _astar.is_in_boundsv(cell):
		return true
	return _astar.is_point_solid(cell)


func _nearest_free(cell: Vector2i) -> Vector2i:
	if not _is_solid(cell):
		return cell
	# Expanding ring search for the closest walkable cell.
	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var c := cell + Vector2i(dx, dy)
				if not _is_solid(c):
					return c
	return cell


## Returns world-space waypoints from one position to another.
func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	if _grid == null:
		return PackedVector2Array()
	var from_cell := _nearest_free(_grid.world_to_cell(from_world))
	var to_cell := _nearest_free(_grid.world_to_cell(to_world))
	if from_cell == to_cell:
		return PackedVector2Array([to_world])
	# allow_partial_path keeps units moving toward unreachable goals.
	return _astar.get_point_path(from_cell, to_cell, true)
