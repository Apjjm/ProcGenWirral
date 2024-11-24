extends Spatial

const FloorInfo = preload("../FloorInfo.gd")
const DungeonData = preload("../globals/DungeonData.gd")

var prop_rng : Random
var loot_rng : Random
var enemy_rng : Random

export var subseed = "rng"

static func find_rng_root(node: Node) -> Node:
	return node.find_parent("RNG_ROOT_*")

func _enter_tree():
	var dd = DungeonData.get_global()
	var di = dd.get_current_dungeon() if dd != null else null
	var fi = di.get_current_floor() if di != null else DungeonData.get_fallback_floor()
	var rng = Random.new(fi.floor_seed())
	self.prop_rng = rng.get_child(subseed + ".prop")
	self.loot_rng = rng.get_child(subseed + ".loot")
	self.enemy_rng = rng.get_child(subseed + ".enemy")
	self.name = "RNG_ROOT_" + str(get_index())

