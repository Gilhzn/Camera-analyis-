extends CanvasLayer
## Touch HUD: credits + power readout, build menu (structures / units),
## select-all, minimap, and the victory / defeat overlay.

var input_ctrl                  # InputController
var camera: Camera2D

var _credit_label: Label
var _power_label: Label
var _status_label: Label
var _minimap: Control
var _overlay: Control
var _result_label: Label
var _buttons := {}              # id -> Button


func _ready() -> void:
	layer = 10
	_build_ui()
	GameState.credits_changed.connect(_on_credits_changed)
	GameState.power_changed.connect(func(_t): _refresh())
	GameState.game_over.connect(_on_game_over)
	Production.queue_changed.connect(func(_t): _refresh())
	_on_credits_changed(GameState.Team.PLAYER,
		GameState.credits[GameState.Team.PLAYER])


func _process(_delta: float) -> void:
	_refresh()
	if _minimap:
		_minimap.queue_redraw()


# --- Layout --------------------------------------------------------------

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Top resource bar (top-left, fixed size).
	var top := PanelContainer.new()
	_anchor_box(top, 0, 0, 0, 0)
	top.offset_left = 8
	top.offset_top = 8
	top.offset_right = 380
	top.offset_bottom = 50
	root.add_child(top)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	top.add_child(hb)
	_credit_label = _mk_label("Credits: 0")
	_power_label = _mk_label("Power: 0/0")
	hb.add_child(_credit_label)
	hb.add_child(_power_label)

	# Right-side build menu (full height on the right).
	var menu := VBoxContainer.new()
	_anchor_box(menu, 1, 0, 1, 1)
	menu.offset_left = -184
	menu.offset_right = -8
	menu.offset_top = 56
	menu.offset_bottom = -60
	menu.add_theme_constant_override("separation", 4)
	root.add_child(menu)

	menu.add_child(_mk_label("- STRUCTURES -"))
	for bid in ["power_plant", "refinery", "barracks",
			"war_factory", "gun_turret"]:
		menu.add_child(_mk_build_button(bid, true))

	menu.add_child(_mk_label("- UNITS -"))
	for uid in ["rifleman", "tank", "harvester"]:
		menu.add_child(_mk_build_button(uid, false))

	# Bottom-left command buttons.
	var cmd := HBoxContainer.new()
	_anchor_box(cmd, 0, 1, 0, 1)
	cmd.offset_left = 8
	cmd.offset_top = -52
	cmd.offset_bottom = -8
	cmd.add_theme_constant_override("separation", 6)
	root.add_child(cmd)
	var sel_all := Button.new()
	sel_all.text = "Select Army"
	sel_all.custom_minimum_size = Vector2(130, 44)
	sel_all.pressed.connect(GameState.select_all_player_combat)
	cmd.add_child(sel_all)
	var stop_btn := Button.new()
	stop_btn.text = "Stop"
	stop_btn.custom_minimum_size = Vector2(90, 44)
	stop_btn.pressed.connect(_on_stop)
	cmd.add_child(stop_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel Build"
	cancel_btn.custom_minimum_size = Vector2(130, 44)
	cancel_btn.pressed.connect(_on_cancel_build)
	cmd.add_child(cancel_btn)

	# Minimap (bottom-right).
	_minimap = Control.new()
	_anchor_box(_minimap, 1, 1, 1, 1)
	_minimap.mouse_filter = Control.MOUSE_FILTER_STOP
	_minimap.offset_left = -188
	_minimap.offset_top = -188
	_minimap.offset_right = -8
	_minimap.offset_bottom = -8
	_minimap.draw.connect(_draw_minimap)
	_minimap.gui_input.connect(_on_minimap_input)
	root.add_child(_minimap)

	# Status (transient center-top messages).
	_status_label = _mk_label("")
	_anchor_box(_status_label, 0.5, 0, 0.5, 0)
	_status_label.offset_top = 56
	_status_label.offset_left = -220
	_status_label.offset_right = 220
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status_label)

	_build_overlay(root)


## Sets all four anchors then lets the caller set offsets explicitly.
func _anchor_box(c: Control, al: float, at: float,
		ar: float, ab: float) -> void:
	c.anchor_left = al
	c.anchor_top = at
	c.anchor_right = ar
	c.anchor_bottom = ab
	c.mouse_filter = Control.MOUSE_FILTER_PASS


func _mk_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(0.92, 0.95, 0.9))
	l.add_theme_font_size_override("font_size", 16)
	return l


func _mk_build_button(id: String, is_structure: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(168, 36)
	b.pressed.connect(_on_build_pressed.bind(id, is_structure))
	_buttons[id] = b
	return b


func _build_overlay(root: Control) -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	root.add_child(_overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.offset_left = -150
	box.offset_right = 150
	box.offset_top = -80
	box.offset_bottom = 80
	_overlay.add_child(box)
	_result_label = _mk_label("")
	_result_label.add_theme_font_size_override("font_size", 44)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_label)
	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(220, 54)
	again.pressed.connect(_on_play_again)
	box.add_child(again)


func _on_play_again() -> void:
	get_tree().reload_current_scene()


func _on_cancel_build() -> void:
	if input_ctrl:
		input_ctrl.cancel_placement()


# --- Button handlers -----------------------------------------------------

func _on_build_pressed(id: String, is_structure: bool) -> void:
	if is_structure:
		var bd: BuildingData = Database.get_building(id)
		if not _structure_available(bd):
			_flash("Requires: " + ", ".join(bd.requires))
			return
		if not GameState.can_afford(GameState.Team.PLAYER, bd.cost):
			_flash("Not enough credits")
			return
		if input_ctrl:
			input_ctrl.begin_placement(id)
			_flash("Tap a spot near your base to build "
				+ bd.display_name)
	else:
		var res := Production.train(GameState.Team.PLAYER, id)
		if not res:
			var c := Production.can_train(GameState.Team.PLAYER, id)
			match c.reason:
				"no_producer": _flash("Build its production structure first")
				"credits": _flash("Not enough credits")
				_: _flash("Cannot train")


func _structure_available(bd: BuildingData) -> bool:
	for req in bd.requires:
		if not GameState.has_building_type(GameState.Team.PLAYER, req):
			return false
	return true


func _on_stop() -> void:
	for u in GameState.selected:
		if is_instance_valid(u):
			u.stop()


# --- Refresh -------------------------------------------------------------

func _on_credits_changed(team: int, amount: int) -> void:
	if team == GameState.Team.PLAYER:
		_credit_label.text = "Credits: %d" % amount


func _refresh() -> void:
	var p := GameState.get_power(GameState.Team.PLAYER)
	_power_label.text = "Power: %d/%d" % [p.output, p.draw]
	_power_label.add_theme_color_override("font_color",
		Color(1, 0.5, 0.3) if p.draw > p.output
		else Color(0.6, 0.95, 0.6))
	for id in _buttons.keys():
		var btn: Button = _buttons[id]
		var bd := Database.get_building(id)
		if bd != null:
			btn.text = "%s  $%d" % [bd.display_name, bd.cost]
			btn.disabled = not _structure_available(bd)
		else:
			var ud := Database.get_unit(id)
			var q := Production.queue_count(GameState.Team.PLAYER, id)
			btn.text = "%s  $%d%s" % [ud.display_name, ud.cost,
				("  (%d)" % q) if q > 0 else ""]


func _flash(msg: String) -> void:
	_status_label.text = msg
	var tw := create_tween()
	_status_label.modulate.a = 1.0
	tw.tween_interval(2.0)
	tw.tween_property(_status_label, "modulate:a", 0.0, 0.6)


func _on_game_over(winner: int) -> void:
	if winner == GameState.Team.PLAYER:
		_result_label.text = "VICTORY"
		_result_label.add_theme_color_override("font_color",
			Color(0.4, 1.0, 0.5))
	else:
		_result_label.text = "DEFEAT"
		_result_label.add_theme_color_override("font_color",
			Color(1.0, 0.4, 0.4))
	_overlay.visible = true


# --- Minimap -------------------------------------------------------------

func _minimap_scale() -> Vector2:
	var ws: Vector2 = GameState.grid.world_size()
	var sz := _minimap.size
	return Vector2(sz.x / ws.x, sz.y / ws.y)


func _draw_minimap() -> void:
	if GameState.grid == null:
		return
	var sc := _minimap_scale()
	_minimap.draw_rect(Rect2(Vector2.ZERO, _minimap.size),
		Color(0.08, 0.12, 0.08))
	for team in [GameState.Team.PLAYER, GameState.Team.ENEMY]:
		var col := Color(0.4, 0.6, 1.0) if team == GameState.Team.PLAYER \
			else Color(1.0, 0.4, 0.35)
		for b in GameState.buildings[team]:
			if is_instance_valid(b) and b.is_alive():
				_minimap.draw_rect(Rect2(
					b.global_position * sc - Vector2(2, 2),
					Vector2(4, 4)), col)
		for u in GameState.units[team]:
			if is_instance_valid(u) and u.is_alive():
				_minimap.draw_circle(u.global_position * sc, 1.5, col)
	# Camera viewport rectangle.
	if camera:
		var vp := get_viewport().get_visible_rect().size / camera.zoom
		var tl := (camera.position - vp * 0.5) * sc
		_minimap.draw_rect(Rect2(tl, vp * sc),
			Color(1, 1, 1, 0.8), false, 1.0)


func _on_minimap_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed \
			or (event is InputEventMouseButton and event.pressed):
		var local: Vector2 = event.position
		var sc := _minimap_scale()
		camera.position = local / sc
