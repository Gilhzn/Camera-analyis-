extends Node
## Autoload "Database": registry of all unit and building definitions.
## All names and stats are original to this project.

var units := {}
var buildings := {}


func _ready() -> void:
	_build_units()
	_build_buildings()


func _build_units() -> void:
	_add_unit({
		"id": "rifleman",
		"display_name": "Rifleman",
		"cost": 100,
		"build_time": 4.0,
		"max_health": 90,
		"speed": 95.0,
		"radius": 8.0,
		"sight": 6,
		"attack_damage": 12,
		"attack_range": 110.0,
		"attack_cooldown": 0.8,
		"armor_class": "infantry",
		"produced_by": "barracks",
	})
	_add_unit({
		"id": "tank",
		"display_name": "Battle Tank",
		"cost": 600,
		"build_time": 9.0,
		"max_health": 420,
		"speed": 70.0,
		"radius": 13.0,
		"sight": 7,
		"attack_damage": 45,
		"attack_range": 150.0,
		"attack_cooldown": 1.4,
		"armor_class": "vehicle",
		"produced_by": "war_factory",
	})
	_add_unit({
		"id": "harvester",
		"display_name": "Harvester",
		"cost": 700,
		"build_time": 10.0,
		"max_health": 500,
		"speed": 60.0,
		"radius": 13.0,
		"sight": 5,
		"attack_damage": 0,
		"attack_range": 0.0,
		"attack_cooldown": 1.0,
		"armor_class": "vehicle",
		"is_harvester": true,
		"produced_by": "war_factory",
	})


func _build_buildings() -> void:
	_add_building({
		"id": "construction_yard",
		"display_name": "Construction Yard",
		"cost": 0,
		"build_time": 0.0,
		"max_health": 1500,
		"size": Vector2i(3, 3),
		"sight": 8,
		"power_output": 20,
		"is_hq": true,
		"color": Color(0.45, 0.55, 0.8),
	})
	_add_building({
		"id": "power_plant",
		"display_name": "Power Plant",
		"cost": 300,
		"build_time": 6.0,
		"max_health": 600,
		"size": Vector2i(2, 2),
		"sight": 4,
		"power_output": 100,
		"requires": ["construction_yard"],
		"color": Color(0.85, 0.7, 0.3),
	})
	_add_building({
		"id": "refinery",
		"display_name": "Ore Refinery",
		"cost": 1500,
		"build_time": 10.0,
		"max_health": 900,
		"size": Vector2i(3, 3),
		"sight": 5,
		"power_draw": 30,
		"is_refinery": true,
		"requires": ["power_plant"],
		"color": Color(0.5, 0.8, 0.55),
	})
	_add_building({
		"id": "barracks",
		"display_name": "Barracks",
		"cost": 400,
		"build_time": 7.0,
		"max_health": 700,
		"size": Vector2i(2, 2),
		"sight": 5,
		"power_draw": 20,
		"produces_units": ["rifleman"],
		"requires": ["power_plant"],
		"color": Color(0.7, 0.5, 0.4),
	})
	_add_building({
		"id": "war_factory",
		"display_name": "War Factory",
		"cost": 2000,
		"build_time": 12.0,
		"max_health": 1000,
		"size": Vector2i(3, 3),
		"sight": 5,
		"power_draw": 40,
		"produces_units": ["tank", "harvester"],
		"requires": ["refinery"],
		"color": Color(0.55, 0.55, 0.6),
	})
	_add_building({
		"id": "gun_turret",
		"display_name": "Gun Turret",
		"cost": 600,
		"build_time": 6.0,
		"max_health": 500,
		"size": Vector2i(1, 1),
		"sight": 7,
		"power_draw": 25,
		"requires": ["barracks"],
		"attack_damage": 30,
		"attack_range": 190.0,
		"attack_cooldown": 1.0,
		"color": Color(0.6, 0.4, 0.45),
	})


func _add_unit(d: Dictionary) -> void:
	units[d.id] = UnitData.make(d)


func _add_building(d: Dictionary) -> void:
	buildings[d.id] = BuildingData.make(d)


func get_unit(id: String) -> UnitData:
	return units.get(id)


func get_building(id: String) -> BuildingData:
	return buildings.get(id)
