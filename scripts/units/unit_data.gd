class_name UnitData
extends RefCounted
## Static definition for a unit type. Original designs (no third-party IP).

var id: String
var display_name: String
var cost: int
var build_time: float          # seconds at full power
var max_health: int
var speed: float               # pixels / second
var radius: float              # draw + footprint radius
var sight: int                 # tiles
var attack_damage: int
var attack_range: float        # pixels
var attack_cooldown: float     # seconds
var armor_class: String        # "infantry" | "vehicle"
var is_harvester: bool = false
var produced_by: String        # building id that trains it


static func make(d: Dictionary) -> UnitData:
	var u := UnitData.new()
	u.id = d.get("id", "unit")
	u.display_name = d.get("display_name", "Unit")
	u.cost = d.get("cost", 100)
	u.build_time = d.get("build_time", 5.0)
	u.max_health = d.get("max_health", 100)
	u.speed = d.get("speed", 90.0)
	u.radius = d.get("radius", 9.0)
	u.sight = d.get("sight", 6)
	u.attack_damage = d.get("attack_damage", 0)
	u.attack_range = d.get("attack_range", 0.0)
	u.attack_cooldown = d.get("attack_cooldown", 1.0)
	u.armor_class = d.get("armor_class", "infantry")
	u.is_harvester = d.get("is_harvester", false)
	u.produced_by = d.get("produced_by", "")
	return u
