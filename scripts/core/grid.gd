class_name Grid
extends RefCounted
## Tile grid helper: converts between world space and integer cell space,
## and tracks static occupancy (buildings / rock) for placement checks.

const CELL := 32

var cols: int
var rows: int
# occupancy[Vector2i] = true when a building or impassable tile blocks the cell.
var _occupied := {}


func _init(_cols: int, _rows: int) -> void:
	cols = _cols
	rows = _rows


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)


func world_size() -> Vector2:
	return Vector2(cols * CELL, rows * CELL)


func set_occupied(cell: Vector2i, value: bool) -> void:
	if value:
		_occupied[cell] = true
	else:
		_occupied.erase(cell)


func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)


func footprint_cells(origin: Vector2i, size: Vector2i) -> Array:
	var cells := []
	for x in range(size.x):
		for y in range(size.y):
			cells.append(origin + Vector2i(x, y))
	return cells


func area_free(origin: Vector2i, size: Vector2i) -> bool:
	for c in footprint_cells(origin, size):
		if not in_bounds(c) or is_occupied(c):
			return false
	return true
