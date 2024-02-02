extends Node

const RoomRootNode = preload("../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("RandomParcelRngRoot.gd")

export(Array, NodePath) var npcs = []

func _ready():
	var sprite_colors = {
		body_color_1 = 12, 
		body_color_2 = 14, 
		eye_color = 12, 
		face_accessory_color = 12, 
		favorite_color = 12, 
		hair_accessory_color = 13, 
		hair_color = 12, 
		legs_color = 12, 
		shoe_color = 12, 
		skin_color = 14
	}

	var rr = RoomRootNode.find_room_root(self)
	if rr == null:
		rr = RandomParcelRngRoot.find_rng_root(self)

	for p in npcs:
		var npc = get_node(p)
		npc.randomize_sprite(rr.prop_rng)
		npc.sprite_colors = sprite_colors
		npc.refresh_sprite()