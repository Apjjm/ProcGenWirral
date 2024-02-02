extends Spatial

const TreasureChest = preload("../monsters/DungeonMonsterCharacterConfig.gd")
const GeneratedFloor = preload("GeneratedFloor.gd")

var treasure_id: int = -1
var key_item_id: int = -1
var floor_data: GeneratedFloor

## After realisation
var loot_rng : Random

static func find_treasure_root(node: Node) -> Node:
	return node.find_parent("DF_TREASURE_ROOT_*")

func realise():
	var is_key = key_item_id >= 0
	var treasure = floor_data.treasure.get_key_item(key_item_id) if is_key else floor_data.treasure.get_treasure(treasure_id)
	self.loot_rng = Random.new(treasure.loot_seed)
	
	var location = _pick_location_in_room(self.loot_rng)
	location = _pick_location_in_world(self.loot_rng) if (location == null && is_key) else location
	if location == null:
		if is_key:
			print("[TreasureRootNode] No space left for key item ", self.key_item_id, " dropping it.")
		else:
			print("[TreasureRootNode] No space left for treasure ", self.treasure_id, " dropping it.")
		self.queue_free()
		return
	
	#if is_key:
	#	print("Key item: ", location.global_translation)

	location.allocate_treasure()

	var chest = treasure.scene.instance()
	chest.item = treasure.item
	chest.quantity = treasure.quantity
	add_child(chest)
	chest.global_transform = location.global_transform

func _pick_location_in_room(rng: Random) -> Spatial:
	var available = []
	for poi in get_parent().points_of_interest:
		if poi.can_be_treasure() && !poi.is_allocated():
			available.push_back(poi)
	
	return rng.choice(available)

func _pick_location_in_world(rng: Random) -> Spatial:
	var available = []
	for c in get_parent().get_parent().get_children():
		if !c.name.begins_with("DF_ROOM_ROOT_"):
			continue

		for poi in c.points_of_interest:
			if poi.can_be_treasure() && !poi.is_allocated():
				available.push_back(poi)

	return rng.choice(available)