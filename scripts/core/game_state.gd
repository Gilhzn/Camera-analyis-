extends Node
## Global game state singleton (autoload "GameState").
## Tracks credits, power, registries of units/buildings per team,
## and resolves win / lose conditions.

enum Team { PLAYER, ENEMY }

signal credits_changed(team: int, amount: int)
signal power_changed(team: int)
signal game_over(winner: int)
signal selection_changed()

const START_CREDITS := 2000

var credits := { Team.PLAYER: START_CREDITS, Team.ENEMY: START_CREDITS }

# Live node registries.
var units := { Team.PLAYER: [], Team.ENEMY: [] }
var buildings := { Team.PLAYER: [], Team.ENEMY: [] }

# Currently selected player units (Array of Unit).
var selected: Array = []

# World references, wired by Main on startup.
var grid: RefCounted = null          # Grid
var pathfinder: RefCounted = null    # Pathfinder
var world: Node2D = null             # container that owns units/buildings
var map = null                       # Map node
var fog = null                       # FogOfWar node

var _over := false


func reset() -> void:
	credits = { Team.PLAYER: START_CREDITS, Team.ENEMY: START_CREDITS }
	units = { Team.PLAYER: [], Team.ENEMY: [] }
	buildings = { Team.PLAYER: [], Team.ENEMY: [] }
	selected = []
	_over = false


# --- Economy -------------------------------------------------------------

func add_credits(team: int, amount: int) -> void:
	credits[team] = max(0, credits[team] + amount)
	credits_changed.emit(team, credits[team])


func can_afford(team: int, amount: int) -> bool:
	return credits[team] >= amount


func spend_credits(team: int, amount: int) -> bool:
	if credits[team] < amount:
		return false
	credits[team] -= amount
	credits_changed.emit(team, credits[team])
	return true


# --- Power ---------------------------------------------------------------

func get_power(team: int) -> Dictionary:
	var output := 0
	var draw := 0
	for b in buildings[team]:
		if not is_instance_valid(b) or not b.is_alive():
			continue
		output += b.data.power_output
		draw += b.data.power_draw
	return { "output": output, "draw": draw }


func power_ratio(team: int) -> float:
	var p := get_power(team)
	if p.draw <= 0:
		return 1.0
	return clampf(float(p.output) / float(p.draw), 0.0, 1.0)


func is_low_power(team: int) -> bool:
	var p := get_power(team)
	return p.draw > p.output


# --- Registries ----------------------------------------------------------

func register_unit(u) -> void:
	if not units[u.team].has(u):
		units[u.team].append(u)


func unregister_unit(u) -> void:
	units[u.team].erase(u)
	selected.erase(u)
	selection_changed.emit()


func register_building(b) -> void:
	if not buildings[b.team].has(b):
		buildings[b.team].append(b)
	power_changed.emit(b.team)


func unregister_building(b) -> void:
	buildings[b.team].erase(b)
	power_changed.emit(b.team)
	_check_game_over()


func has_building_type(team: int, building_id: String) -> bool:
	for b in buildings[team]:
		if is_instance_valid(b) and b.is_alive() and b.data.id == building_id:
			return true
	return false


func get_hq(team: int):
	for b in buildings[team]:
		if is_instance_valid(b) and b.is_alive() and b.data.is_hq:
			return b
	return null


# --- Selection -----------------------------------------------------------

func clear_selection() -> void:
	for u in selected:
		if is_instance_valid(u):
			u.set_selected(false)
	selected.clear()
	selection_changed.emit()


func select_unit(u, additive := false) -> void:
	if not additive:
		clear_selection()
	if is_instance_valid(u) and not selected.has(u):
		selected.append(u)
		u.set_selected(true)
	selection_changed.emit()


func select_all_player_combat() -> void:
	clear_selection()
	for u in units[Team.PLAYER]:
		if is_instance_valid(u) and u.is_alive() and not u.is_harvester:
			selected.append(u)
			u.set_selected(true)
	selection_changed.emit()


# --- Win / Lose ----------------------------------------------------------

func _check_game_over() -> void:
	if _over:
		return
	var player_hq = get_hq(Team.PLAYER)
	var enemy_hq = get_hq(Team.ENEMY)
	if player_hq == null:
		_over = true
		game_over.emit(Team.ENEMY)
	elif enemy_hq == null:
		_over = true
		game_over.emit(Team.PLAYER)


func enemy_of(team: int) -> int:
	return Team.ENEMY if team == Team.PLAYER else Team.PLAYER
