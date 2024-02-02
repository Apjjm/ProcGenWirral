extends MessageDialogAction

const RoomRootNode = preload("../../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("../../parcels/RandomParcelRngRoot.gd")

export(BaseItem.Rarity) var rarity = BaseItem.Rarity.RARITY_RARE
var _rng : Random = null

func _ready():
	var rr = RoomRootNode.find_room_root(self)
	if rr == null:
		rr = RandomParcelRngRoot.find_rng_root(self)

	if rr != null:
		self._rng = rr.prop_rng.get_child("TakeRandomStickerAction")
	else:
		print("[TakeRandomStickerAction] no root found, using unseeded fallback")
		self._rng = Random.new()

func _run():
	var nodes = []
	for item_node in SaveState.inventory.get_category("stickers").get_children():
		if item_node.item.discardable && self.rarity == item_node.item.get_rarity():
			nodes.push_back(item_node)

	var node = self._rng.choice(nodes)
	if node != null:
		print("[TakeRandomStickerAction] consuming sticker: ", node.item.get_name())
		node.consume(1)
		
		self.blackboard["sticker"] = node.item.get_name()
		self.substitute_blackboard_keys.push_back("sticker")
		return ._run()
	
	return false
