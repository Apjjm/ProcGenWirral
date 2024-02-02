extends "../reward/RewardMenuItemAction.gd"

const RoomRootNode = preload("../../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("../../parcels/RandomParcelRngRoot.gd")

func get_rng():
	var rr = RoomRootNode.find_room_root(self)
	if rr == null:
		rr = RandomParcelRngRoot.find_rng_root(self)

	return rr.prop_rng if rr != null else Random.new()

func refresh() -> void:
	if self.requirement == "":
		self.requirement = "AP7_DUNGEON_MENU_SHRINE_COST_NONE"

	for c in get_children():
		if c.has_method("get_requirement"):
			self.requirement = c.get_requirement()
