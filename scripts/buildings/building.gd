class_name Building
extends Node2D
## Base building. Occupies a tile footprint, may produce power, train
## units, accept harvester deposits, or auto-attack (turret).

var data: BuildingData
var team: int
var origin_cell: Vector2i        # top-left footprint cell
var health: int
var constructing := true         # true until build animation finishes
var build_progress := 0.0        # 0..1 while constructing

var rally_point := Vector2.ZERO
var _attack_timer := 0.0


func setup(building_data: BuildingData, building_team: int,
		cell: Vector2i, instant := false) -> void:
	data = building_data
	team = building_team
	origin_cell = cell
	health = building_data.max_health
	constructing = not instant
	build_progress = 1.0 if instant else 0.0
	z_index = 3


func _ready() -> void:
	global_position = _center_world()
	rally_point = global_position + Vector2(0, data.size.y * Grid.CELL)
	_occupy(true)
	GameState.register_building(self)
	add_to_group("buildings")
	if constructing:
		var t := get_tree().create_timer(maxf(0.1, data.build_time))
		t.timeout.connect(_finish_construction)
	else:
		call_deferred("_on_built")


func _finish_construction() -> void:
	constructing = false
	build_progress = 1.0
	queue_redraw()
	_on_built()


func _on_built() -> void:
	# A new refinery comes with one free harvester (classic RTS economy).
	if data.is_refinery and Production:
		Production.instantiate_unit(team, "harvester", rally_point)


func _center_world() -> Vector2:
	return Vector2(
		origin_cell.x * Grid.CELL + data.size.x * Grid.CELL * 0.5,
		origin_cell.y * Grid.CELL + data.size.y * Grid.CELL * 0.5)


func _occupy(value: bool) -> void:
	if GameState.grid:
		for c in GameState.grid.footprint_cells(origin_cell, data.size):
			GameState.grid.set_occupied(c, value)
	if GameState.pathfinder:
		GameState.pathfinder.set_footprint_solid(
			origin_cell, data.size, value)


func is_alive() -> bool:
	return health > 0


func take_damage(amount: int, _attacker = null) -> void:
	if not is_alive():
		return
	health -= amount
	queue_redraw()
	if health <= 0:
		_die()


func _die() -> void:
	_occupy(false)
	GameState.unregister_building(self)
	queue_free()


func _process(delta: float) -> void:
	if constructing:
		build_progress = clampf(
			build_progress + delta / maxf(0.1, data.build_time), 0.0, 1.0)
		queue_redraw()
		return
	if data.attack_damage > 0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
		_turret_logic()


func _turret_logic() -> void:
	if _attack_timer > 0.0:
		return
	var best = null
	var best_d := data.attack_range
	for e in GameState.units[GameState.enemy_of(team)]:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var d := global_position.distance_to(e.global_position)
		if d <= best_d:
			best_d = d
			best = e
	if best != null:
		Combat.fire(self, best, data.attack_damage)
		_attack_timer = data.attack_cooldown


# --- Rendering -----------------------------------------------------------

func _draw() -> void:
	var w := data.size.x * Grid.CELL
	var h := data.size.y * Grid.CELL
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)
	var base := data.color
	if team == GameState.Team.ENEMY:
		base = base.lerp(Color(0.9, 0.3, 0.25), 0.45)
	if constructing:
		draw_rect(rect, base.darkened(0.5))
		draw_rect(Rect2(rect.position,
			Vector2(w * build_progress, h)), base)
	else:
		draw_rect(rect, base)
		draw_rect(rect, base.darkened(0.4), false, 2.0)
	# Faction marker.
	draw_circle(Vector2.ZERO, 5.0,
		Color(0.35, 0.55, 0.95) if team == GameState.Team.PLAYER
		else Color(0.95, 0.4, 0.35))
	# Health bar.
	if health < data.max_health:
		var frac := clampf(float(health) / float(data.max_health),
			0.0, 1.0)
		var by := -h * 0.5 - 8.0
		draw_rect(Rect2(-w * 0.5, by, w, 4.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w * 0.5, by, w * frac, 4.0),
			Color(0.3, 0.9, 0.3))
