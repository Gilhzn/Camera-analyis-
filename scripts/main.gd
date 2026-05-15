extends Node2D
## Bootstraps the whole skirmish in code so only one tiny .tscn exists.
## Builds grid/pathfinder/map/fog, camera, input, HUD, AI, and the
## starting bases, then hands off to the gameplay systems.

const COLS := 70
const ROWS := 46

var world: Node2D
var camera: Camera2D
var input_ctrl
var hud
var ai


func _ready() -> void:
	randomize()
	GameState.reset()
	# Autoloads persist across scene reload; clear the training queues.
	Production.queue = {
		GameState.Team.PLAYER: [],
		GameState.Team.ENEMY: [],
	}

	# Core spatial systems.
	GameState.grid = Grid.new(COLS, ROWS)
	GameState.pathfinder = Pathfinder.new()
	GameState.pathfinder.setup(GameState.grid)

	# World container (owns everything that lives in the battlefield).
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	GameState.world = world

	# Terrain.
	var map := Map.new()
	map.name = "Map"
	world.add_child(map)
	map.generate(COLS, ROWS, randi())
	map.apply_to_pathfinder()
	GameState.map = map

	# Camera.
	camera = Camera2D.new()
	camera.zoom = Vector2(1.0, 1.0)
	camera.position = Vector2(8 * Grid.CELL, ROWS * Grid.CELL * 0.5)
	add_child(camera)
	camera.make_current()

	# Fog of war (drawn above the world, below the HUD).
	var fog := FogOfWar.new()
	fog.name = "Fog"
	world.add_child(fog)
	fog.init_fog(COLS, ROWS)
	GameState.fog = fog

	# Input controller.
	input_ctrl = load("res://scripts/input/input_controller.gd").new()
	input_ctrl.name = "Input"
	input_ctrl.z_index = 60  # placement ghost above fog (z=50)
	input_ctrl.camera = camera
	world.add_child(input_ctrl)

	# HUD.
	hud = load("res://scripts/ui/hud.gd").new()
	hud.name = "HUD"
	hud.input_ctrl = input_ctrl
	hud.camera = camera
	add_child(hud)
	input_ctrl.hud = hud

	# Enemy AI.
	ai = load("res://scripts/ai/enemy_ai.gd").new()
	ai.name = "EnemyAI"
	add_child(ai)

	_spawn_starting_bases()


func _spawn_starting_bases() -> void:
	# Player base: left side. Enemy base: right side.
	var p_cell := Vector2i(6, int(ROWS * 0.5) - 1)
	var e_cell := Vector2i(COLS - 9, int(ROWS * 0.5) - 1)
	_spawn_building("construction_yard", GameState.Team.PLAYER, p_cell)
	_spawn_building("construction_yard", GameState.Team.ENEMY, e_cell)
	# Give each side an initial power plant so production isn't stalled.
	_spawn_building("power_plant", GameState.Team.PLAYER,
		p_cell + Vector2i(4, 0))
	_spawn_building("power_plant", GameState.Team.ENEMY,
		e_cell + Vector2i(-3, 0))


func _spawn_building(id: String, team: int, cell: Vector2i) -> void:
	var bd: BuildingData = Database.get_building(id)
	if bd == null:
		return
	var b := Building.new()
	b.setup(bd, team, cell, true)  # instant = pre-built at game start
	world.add_child(b)
