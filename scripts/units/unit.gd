class_name Unit
extends Node2D
## Base combat unit. Geometry-drawn. Moves along A* paths,
## auto-engages enemies, can be commanded to move/attack.

enum State { IDLE, MOVE, ATTACK_MOVE, DEAD }

var data: UnitData
var team: int
var is_harvester := false

var health: int
var state: int = State.IDLE
var selected := false

var _path: PackedVector2Array = PackedVector2Array()
var _path_index := 0
var _attack_timer := 0.0
var _repath_timer := 0.0

# Target the unit was explicitly ordered to attack (Node2D or null).
var _command_target = null
# Final destination of a move order.
var _dest := Vector2.ZERO


func setup(unit_data: UnitData, unit_team: int) -> void:
	data = unit_data
	team = unit_team
	is_harvester = unit_data.is_harvester
	health = unit_data.max_health
	z_index = 5


func _ready() -> void:
	GameState.register_unit(self)
	add_to_group("units")


func is_alive() -> bool:
	return state != State.DEAD and health > 0


# --- Commands ------------------------------------------------------------

func command_move(target: Vector2) -> void:
	_command_target = null
	_dest = target
	state = State.MOVE
	_recompute_path(target)


func command_attack(enemy) -> void:
	_command_target = enemy
	state = State.ATTACK_MOVE


func stop() -> void:
	_command_target = null
	_path = PackedVector2Array()
	state = State.IDLE


func _recompute_path(target: Vector2) -> void:
	if GameState.pathfinder == null:
		_path = PackedVector2Array([target])
	else:
		_path = GameState.pathfinder.find_path(global_position, target)
	_path_index = 0


# --- Combat --------------------------------------------------------------

func take_damage(amount: int, _attacker = null) -> void:
	if not is_alive():
		return
	health -= amount
	queue_redraw()
	if health <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	GameState.unregister_unit(self)
	queue_free()


func _find_enemy_in_sight():
	if data.attack_damage <= 0:
		return null
	var best = null
	var best_d := INF
	var sight_px := float(data.sight) * Grid.CELL + data.attack_range
	var foes = GameState.units[GameState.enemy_of(team)] + GameState.buildings[GameState.enemy_of(team)]
	for e in foes:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d and d <= sight_px:
			best_d = d
			best = e
	return best


func _try_attack(target) -> void:
	var d := global_position.distance_to(target.global_position)
	if d > data.attack_range:
		# Close in.
		_repath_timer -= get_physics_process_delta_time()
		if _path.is_empty() or _repath_timer <= 0.0:
			_recompute_path(target.global_position)
			_repath_timer = 0.5
		_follow_path()
		return
	# In range: hold and fire.
	_path = PackedVector2Array()
	if _attack_timer <= 0.0:
		Combat.fire(self, target, data.attack_damage)
		_attack_timer = data.attack_cooldown


# --- Movement ------------------------------------------------------------

func _follow_path() -> void:
	if _path_index >= _path.size():
		if state == State.MOVE:
			state = State.IDLE
		return
	var target: Vector2 = _path[_path_index]
	var to := target - global_position
	var step := data.speed * get_physics_process_delta_time()
	if to.length() <= step:
		global_position = target
		_path_index += 1
	else:
		global_position += to.normalized() * step
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	_attack_timer = max(0.0, _attack_timer - delta)

	match state:
		State.IDLE:
			var foe = _find_enemy_in_sight()
			if foe != null:
				_command_target = foe
				state = State.ATTACK_MOVE
		State.MOVE:
			_follow_path()
		State.ATTACK_MOVE:
			if _command_target == null or not is_instance_valid(_command_target) \
					or not _command_target.is_alive():
				_command_target = _find_enemy_in_sight()
				if _command_target == null:
					state = State.IDLE
					return
			_try_attack(_command_target)


# --- Rendering -----------------------------------------------------------

func _team_color() -> Color:
	return Color(0.35, 0.55, 0.95) if team == GameState.Team.PLAYER \
		else Color(0.9, 0.35, 0.3)


func _draw() -> void:
	var col := _team_color()
	if data.armor_class == "vehicle":
		var r := data.radius
		draw_rect(Rect2(-r, -r * 0.7, r * 2.0, r * 1.4), col)
		draw_rect(Rect2(-r * 0.4, -r * 0.3, r * 1.4, r * 0.6),
			col.darkened(0.3))
	else:
		draw_circle(Vector2.ZERO, data.radius, col)
	if selected:
		draw_arc(Vector2.ZERO, data.radius + 5.0, 0.0, TAU, 24,
			Color(0.2, 1.0, 0.3), 2.0)
	# Health bar.
	if health < data.max_health:
		var w := data.radius * 2.0
		var frac := clampf(float(health) / float(data.max_health), 0.0, 1.0)
		var y := -data.radius - 8.0
		draw_rect(Rect2(-w * 0.5, y, w, 3.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w * 0.5, y, w * frac, 3.0),
			Color(0.3, 0.9, 0.3))


func set_selected(v: bool) -> void:
	selected = v
	queue_redraw()
