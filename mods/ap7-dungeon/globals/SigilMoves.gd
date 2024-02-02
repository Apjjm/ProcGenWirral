extends Node

var all_sigils = []
var rare_sigils = []
var common_sigils = []
var _setup = false

static func get_global() -> Node:
	var node = DLC.get_node("./Ap7Dungeon/SigilMoves")
	if !node._setup:
		node.setup()
		node._setup = true

	return node

func _init():
	name = "SigilMoves"

func setup():
	print(["[SigilMoves] Setup"])
	for move in Datatables.load("res://mods/ap7-dungeon/items/moves").table.values():
		if "sigil_rare" in move.tags:
			all_sigils.push_back(move)
			rare_sigils.push_back(move)
		elif "sigil" in move.tags:
			all_sigils.push_back(move)
			common_sigils.push_back(move)