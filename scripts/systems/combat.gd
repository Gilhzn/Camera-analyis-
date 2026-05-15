class_name Combat
extends RefCounted
## Stateless helper that spawns a projectile from attacker toward target.

static func fire(attacker: Node2D, target: Node2D, damage: int) -> void:
	if not is_instance_valid(target):
		return
	var world: Node2D = GameState.world
	if world == null:
		return
	var p := Projectile.new()
	p.setup(attacker.global_position, target, damage)
	world.add_child(p)


class Projectile:
	extends Node2D

	var _target
	var _damage: int
	var _speed := 420.0

	func setup(from: Vector2, target, damage: int) -> void:
		global_position = from
		_target = target
		_damage = damage
		z_index = 8

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(_target) or not _target.is_alive():
			queue_free()
			return
		var to: Vector2 = _target.global_position - global_position
		var step := _speed * delta
		if to.length() <= step + 6.0:
			_target.take_damage(_damage, self)
			queue_free()
			return
		global_position += to.normalized() * step
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.4))
