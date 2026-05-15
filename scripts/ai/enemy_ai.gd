extends Node
## Basic skirmish opponent. On a slow tick it keeps power positive,
## secures economy, trains a strike force, then attack-moves the player HQ.

var TEAM := GameState.Team.ENEMY
const TICK := 1.5

var _t := 0.0
var _attack_wave := 4          # units to gather before attacking
var _attacking := false


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = TICK
	if GameState.get_hq(TEAM) == null:
		return
	_economy_step()
	_military_step()


func _count_units(uid: String) -> int:
	var n := 0
	for u in GameState.units[TEAM]:
		if is_instance_valid(u) and u.is_alive() and u.data.id == uid:
			n += 1
	return n


func _army_size() -> int:
	var n := 0
	for u in GameState.units[TEAM]:
		if is_instance_valid(u) and u.is_alive() and not u.is_harvester:
			n += 1
	return n


# --- Construction --------------------------------------------------------

func _need(building_id: String) -> bool:
	return not GameState.has_building_type(TEAM, building_id)


func _build(building_id: String) -> void:
	var bd: BuildingData = Database.get_building(building_id)
	if bd == null or not GameState.can_afford(TEAM, bd.cost):
		return
	for req in bd.requires:
		if not GameState.has_building_type(TEAM, req):
			return
	var cell := _find_build_cell(bd.size)
	if cell.x < 0:
		return
	if not GameState.spend_credits(TEAM, bd.cost):
		return
	var b := Building.new()
	b.setup(bd, TEAM, cell, false)
	GameState.world.add_child(b)


func _find_build_cell(size: Vector2i) -> Vector2i:
	var hq = GameState.get_hq(TEAM)
	if hq == null:
		return Vector2i(-1, -1)
	var hc: Vector2i = GameState.grid.world_to_cell(hq.global_position)
	for ring in range(2, 14):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if abs(dx) != ring and abs(dy) != ring:
					continue
				var c := hc + Vector2i(dx, dy)
				if GameState.grid.area_free(c, size):
					return c
	return Vector2i(-1, -1)


func _economy_step() -> void:
	if GameState.is_low_power(TEAM) or _need("power_plant"):
		_build("power_plant")
		return
	if _need("refinery"):
		_build("refinery")
		return
	if _need("barracks"):
		_build("barracks")
		return
	if _need("war_factory"):
		_build("war_factory")
		return
	# Keep at least 2 harvesters running.
	if _count_units("harvester") < 2 \
			and Production.queue_count(TEAM, "harvester") == 0:
		Production.train(TEAM, "harvester")
		return
	# Static defense once economy is up.
	if not GameState.has_building_type(TEAM, "gun_turret") \
			and GameState.can_afford(TEAM, 700):
		_build("gun_turret")


# --- Military ------------------------------------------------------------

func _military_step() -> void:
	# Train a mixed force when funds allow.
	if GameState.has_building_type(TEAM, "war_factory") \
			and GameState.can_afford(TEAM, 900) \
			and Production.queue_count(TEAM, "tank") < 2:
		Production.train(TEAM, "tank")
	elif GameState.has_building_type(TEAM, "barracks") \
			and GameState.can_afford(TEAM, 100) \
			and Production.queue_count(TEAM, "rifleman") < 3:
		Production.train(TEAM, "rifleman")

	var army := _army_size()
	if not _attacking and army >= _attack_wave:
		_launch_attack()
	elif _attacking and army == 0:
		_attacking = false
		_attack_wave = min(10, _attack_wave + 2)


func _launch_attack() -> void:
	var target = GameState.get_hq(GameState.Team.PLAYER)
	if target == null:
		return
	_attacking = true
	for u in GameState.units[TEAM]:
		if is_instance_valid(u) and u.is_alive() and not u.is_harvester:
			u.command_attack(target)
