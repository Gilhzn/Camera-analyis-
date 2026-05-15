extends Node
## Unit training manager. One sequential queue per team.
## Building construction is handled separately via placement mode.

const LOW_POWER_FACTOR := 0.4

# queue[team] = Array of { "id": String, "time_left": float, "total": float }
var queue := { GameState.Team.PLAYER: [], GameState.Team.ENEMY: [] }

signal queue_changed(team: int)


func can_train(team: int, unit_id: String) -> Dictionary:
	var ud: UnitData = Database.get_unit(unit_id)
	if ud == null:
		return { "ok": false, "reason": "unknown" }
	if not GameState.has_building_type(team, ud.produced_by):
		return { "ok": false, "reason": "no_producer" }
	if not GameState.can_afford(team, ud.cost):
		return { "ok": false, "reason": "credits" }
	return { "ok": true, "reason": "" }


func train(team: int, unit_id: String) -> bool:
	var check := can_train(team, unit_id)
	if not check.ok:
		return false
	var ud: UnitData = Database.get_unit(unit_id)
	if not GameState.spend_credits(team, ud.cost):
		return false
	queue[team].append({
		"id": unit_id,
		"time_left": ud.build_time,
		"total": ud.build_time,
	})
	queue_changed.emit(team)
	return true


func queue_count(team: int, unit_id: String) -> int:
	var n := 0
	for item in queue[team]:
		if item.id == unit_id:
			n += 1
	return n


func _process(delta: float) -> void:
	for team in [GameState.Team.PLAYER, GameState.Team.ENEMY]:
		_tick_team(team, delta)


func _tick_team(team: int, delta: float) -> void:
	var q: Array = queue[team]
	if q.is_empty():
		return
	var item = q[0]
	var factor := 1.0
	if GameState.is_low_power(team):
		factor = LOW_POWER_FACTOR
	item.time_left -= delta * factor
	if item.time_left <= 0.0:
		q.pop_front()
		_spawn(team, item.id)
		queue_changed.emit(team)


## Creates a fully-registered unit at a world position (no cost / queue).
func instantiate_unit(team: int, unit_id: String, at_world: Vector2) -> Unit:
	var ud: UnitData = Database.get_unit(unit_id)
	if ud == null:
		return null
	var u: Unit
	if ud.is_harvester:
		u = load("res://scripts/units/harvester.gd").new()
	else:
		u = Unit.new()
	u.setup(ud, team)
	GameState.world.add_child(u)
	var cell: Vector2i = GameState.grid.world_to_cell(at_world)
	u.global_position = GameState.grid.cell_to_world_center(cell)
	return u


func _spawn(team: int, unit_id: String) -> void:
	var ud: UnitData = Database.get_unit(unit_id)
	var producer = _find_producer(team, ud.produced_by)
	if producer == null:
		# Producer destroyed mid-build: refund.
		GameState.add_credits(team, ud.cost)
		return
	var u := instantiate_unit(team, unit_id, producer.rally_point)
	if u != null and not ud.is_harvester:
		u.command_move(producer.rally_point)


func _find_producer(team: int, building_id: String):
	for b in GameState.buildings[team]:
		if is_instance_valid(b) and b.is_alive() \
				and not b.constructing and b.data.id == building_id:
			return b
	return null
