extends Node2D
## Single source of truth for world input (reliable: no event-routing
## conflicts). One finger = tap (select/command) or drag (pan camera).
## Two fingers = pinch zoom. Mouse wheel zooms on desktop.
## Also drives building placement mode.

const TAP_MOVE_THRESHOLD := 14.0   # px of travel still counted as a tap
const TAP_TIME := 0.35             # seconds
const MIN_ZOOM := 0.5
const MAX_ZOOM := 2.2

var camera: Camera2D
var hud                            # HUD reference for placement coordination

# Active touch points: index -> { "pos": Vector2, "start": Vector2,
#                                  "time": float, "moved": bool }
var _touches := {}
var _pinch_dist := 0.0

# Placement mode.
var _placing := false
var _place_building_id := ""
var _ghost_cell := Vector2i.ZERO


func _ready() -> void:
	set_process(true)


# --- Placement API (called by HUD) --------------------------------------

func begin_placement(building_id: String) -> void:
	_placing = true
	_place_building_id = building_id

func cancel_placement() -> void:
	_placing = false
	_place_building_id = ""
	queue_redraw()

func is_placing() -> bool:
	return _placing


# --- Input ---------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(event.position, 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(event.position, 1.1)


func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = {
			"pos": e.position,
			"start": e.position,
			"time": Time.get_ticks_msec() / 1000.0,
			"moved": false,
		}
		if _touches.size() == 2:
			_pinch_dist = _current_pinch_distance()
	else:
		var t = _touches.get(e.index)
		_touches.erase(e.index)
		if t == null:
			return
		var held := Time.get_ticks_msec() / 1000.0 - t.time
		if not t.moved and held <= TAP_TIME and _touches.is_empty():
			_handle_tap(e.position)


func _on_drag(e: InputEventScreenDrag) -> void:
	var t = _touches.get(e.index)
	if t != null:
		t.pos = e.position
		if t.start.distance_to(e.position) > TAP_MOVE_THRESHOLD:
			t.moved = true

	if _touches.size() >= 2:
		_handle_pinch()
	elif _touches.size() == 1 and not _placing:
		# One-finger pan (only once it has moved beyond tap threshold).
		if t != null and t.moved:
			_pan(-e.relative / camera.zoom)


func _current_pinch_distance() -> float:
	var pts := _touches.values()
	if pts.size() < 2:
		return 0.0
	return pts[0].pos.distance_to(pts[1].pos)


func _handle_pinch() -> void:
	var d := _current_pinch_distance()
	if _pinch_dist > 0.0 and d > 0.0:
		var ratio := _pinch_dist / d
		var center := (_touches.values()[0].pos
			+ _touches.values()[1].pos) * 0.5
		_zoom_at(center, ratio)
	_pinch_dist = d


# --- Camera --------------------------------------------------------------

func _pan(delta_world: Vector2) -> void:
	camera.position += delta_world
	_clamp_camera()


func _zoom_at(_screen_pos: Vector2, factor: float) -> void:
	var z := camera.zoom.x / factor
	z = clampf(z, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(z, z)
	_clamp_camera()


func _clamp_camera() -> void:
	if GameState.grid == null:
		return
	var ws := GameState.grid.world_size()
	camera.position.x = clampf(camera.position.x, 0.0, ws.x)
	camera.position.y = clampf(camera.position.y, 0.0, ws.y)


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	# Camera centered; visible world size = viewport / zoom (Godot 4).
	var vp := get_viewport().get_visible_rect().size
	return camera.position + (screen_pos - vp * 0.5) / camera.zoom


# --- Tap resolution ------------------------------------------------------

func _handle_tap(screen_pos: Vector2) -> void:
	var world := _screen_to_world(screen_pos)

	if _placing:
		_try_place(world)
		return

	# 1. Tap an enemy with combat units selected -> attack.
	var enemy = _entity_at(world, GameState.Team.ENEMY)
	if enemy != null and not GameState.selected.is_empty():
		for u in GameState.selected:
			if is_instance_valid(u):
				u.command_attack(enemy)
		return

	# 2. Tap a friendly unit -> select it.
	var friendly = _unit_at(world, GameState.Team.PLAYER)
	if friendly != null:
		GameState.select_unit(friendly)
		return

	# 3. Tap ground with a selection -> move there.
	if not GameState.selected.is_empty():
		var i := 0
		for u in GameState.selected:
			if is_instance_valid(u):
				var off := Vector2(
					(i % 3) * 26 - 26, (i / 3) * 26 - 26)
				u.command_move(world + off)
				i += 1
		return

	# 4. Empty tap -> clear selection.
	GameState.clear_selection()


func _unit_at(world: Vector2, team: int):
	var best = null
	var best_d := INF
	for u in GameState.units[team]:
		if not is_instance_valid(u) or not u.is_alive():
			continue
		var d := world.distance_to(u.global_position)
		if d <= u.data.radius + 12.0 and d < best_d:
			best_d = d
			best = u
	return best


func _building_at(world: Vector2, team: int):
	for b in GameState.buildings[team]:
		if not is_instance_valid(b) or not b.is_alive():
			continue
		var half := Vector2(b.data.size) * Grid.CELL * 0.5
		var r := Rect2(b.global_position - half, half * 2.0)
		if r.has_point(world):
			return b
	return null


func _entity_at(world: Vector2, team: int):
	var u = _unit_at(world, team)
	if u != null:
		return u
	return _building_at(world, team)


# --- Building placement --------------------------------------------------

func _process(_delta: float) -> void:
	if _placing:
		var mp := get_viewport().get_mouse_position()
		if not _touches.is_empty():
			mp = _touches.values()[0].pos
		var w := _screen_to_world(mp)
		_ghost_cell = GameState.grid.world_to_cell(w)
		queue_redraw()


func _placement_valid(bd: BuildingData, cell: Vector2i) -> bool:
	if not GameState.grid.area_free(cell, bd.size):
		return false
	# Must be near an existing player building (base adjacency).
	var center := Vector2(
		cell.x * Grid.CELL + bd.size.x * Grid.CELL * 0.5,
		cell.y * Grid.CELL + bd.size.y * Grid.CELL * 0.5)
	for b in GameState.buildings[GameState.Team.PLAYER]:
		if is_instance_valid(b) and b.is_alive():
			if center.distance_to(b.global_position) < 6.0 * Grid.CELL:
				return true
	return false


func _try_place(world: Vector2) -> void:
	var bd: BuildingData = Database.get_building(_place_building_id)
	if bd == null:
		cancel_placement()
		return
	var cell := GameState.grid.world_to_cell(world)
	if not _placement_valid(bd, cell):
		return  # invalid: keep placement mode active
	if not GameState.spend_credits(GameState.Team.PLAYER, bd.cost):
		cancel_placement()
		return
	var b := Building.new()
	b.setup(bd, GameState.Team.PLAYER, cell, false)
	GameState.world.add_child(b)
	cancel_placement()


func _draw() -> void:
	if not _placing:
		return
	var bd: BuildingData = Database.get_building(_place_building_id)
	if bd == null:
		return
	var ok := _placement_valid(bd, _ghost_cell)
	var col := Color(0.3, 1.0, 0.4, 0.4) if ok \
		else Color(1.0, 0.3, 0.3, 0.4)
	var pos := Vector2(_ghost_cell) * Grid.CELL
	draw_rect(Rect2(pos, Vector2(bd.size) * Grid.CELL), col)
