class_name BuildingData
extends RefCounted
## Static definition for a building type. Original designs (no third-party IP).

var id: String
var display_name: String
var cost: int
var build_time: float
var max_health: int
var size: Vector2i              # footprint in tiles
var sight: int
var power_output: int
var power_draw: int
var is_hq: bool = false
var is_refinery: bool = false
var produces_units: Array = []  # unit ids this building can train
var requires: Array = []        # building ids required before it can be built
var attack_damage: int = 0
var attack_range: float = 0.0
var attack_cooldown: float = 1.0
var color: Color = Color(0.6, 0.6, 0.65)


static func make(d: Dictionary) -> BuildingData:
	var b := BuildingData.new()
	b.id = d.get("id", "building")
	b.display_name = d.get("display_name", "Building")
	b.cost = d.get("cost", 300)
	b.build_time = d.get("build_time", 6.0)
	b.max_health = d.get("max_health", 600)
	b.size = d.get("size", Vector2i(2, 2))
	b.sight = d.get("sight", 5)
	b.power_output = d.get("power_output", 0)
	b.power_draw = d.get("power_draw", 0)
	b.is_hq = d.get("is_hq", false)
	b.is_refinery = d.get("is_refinery", false)
	b.produces_units = d.get("produces_units", [])
	b.requires = d.get("requires", [])
	b.attack_damage = d.get("attack_damage", 0)
	b.attack_range = d.get("attack_range", 0.0)
	b.attack_cooldown = d.get("attack_cooldown", 1.0)
	b.color = d.get("color", Color(0.6, 0.6, 0.65))
	return b
