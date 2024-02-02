extends Node

const ITEM_BLOCKLIST = [
	preload("res://data/items/tape_basic.tres"),
	preload("res://data/items/jelly.tres"),
]
const ITEM_STATUP = [
	preload("res://data/items/olive_up.tres"),
	preload("res://data/items/upgrape.tres"),
]
const ITEM_RESOURCES = [
	preload("res://data/items/pulp.tres"),
	preload("res://data/items/wheat.tres"),
	preload("res://data/items/plastic.tres"),
	preload("res://data/items/metal.tres"),
	preload("res://data/items/wood.tres"),
	preload("res://data/items/fused_material.tres")
]

const SigilMoves = preload("SigilMoves.gd")

var _setup = false
var tape_common : Array
var tape_rare : Array
var resource_common : Array
var resource_rare : Array
var heal_common : Array
var heal_rare : Array
var battle_common : Array
var battle_rare : Array
var stat_up : Array
var move_active : Array
var move_passive : Array
var move_sigil : Array

class ItemEntry:
	var item : BaseItem
	var multiple : bool
	var move : BattleMove

	func _init(item: BaseItem, multiple: bool = false, move: BattleMove = null):
		self.item = item
		self.move = move
		self.multiple = multiple

	func roll_item(rarity: int, rng: Random):
		if self.move:
			return ItemFactory.create_sticker(self.move, rng, rarity)
		else:
			return self.item

static func get_global() -> Node:
	var node = DLC.get_node("./Ap7Dungeon/TreasureTable")
	if !node._setup:
		node.setup()
		node._setup = true

	return node

func _init():
	name = "TreasureTable"

func setup():
	print(["[TreasureTable] Setup"])
	_populate_items()
	_populate_moves()
	assert(self.tape_common.size() > 0)
	assert(self.tape_rare.size() > 0)
	assert(self.resource_common.size() > 0)
	assert(self.resource_rare.size() > 0)
	assert(self.heal_common.size() > 0)
	assert(self.heal_rare.size() > 0)
	assert(self.battle_common.size() > 0)
	assert(self.battle_rare.size() > 0)
	assert(self.stat_up.size() > 0)
	assert(self.move_active.size() > 0)
	assert(self.move_passive.size() > 0)
	assert(self.move_sigil.size() > 0)

func _populate_items():
	for item in Datatables.load("res://data/items/").table.values():
		# Workaround: some items are stickers but aren't really in the stickers category...
		if item in ITEM_BLOCKLIST || "battle_move" in item && item.battle_move != null:
			continue

		if item.category == "resources" && item in ITEM_RESOURCES:
			if item.value < 100:
				self.resource_common.push_back(ItemEntry.new(item, true))
			else:
				self.resource_rare.push_back(ItemEntry.new(item, true))

		elif item.category == "tapes":
			if item.value < 10000:
				self.tape_common.push_back(ItemEntry.new(item))
			else:
				self.tape_rare.push_back(ItemEntry.new(item))

		elif item.category == "consumables":
			if item.stack_limit_category == "cure":
				self.battle_common.push_back(ItemEntry.new(item))
			elif item.stack_limit_category == "reodorant":
				self.battle_common.push_back(ItemEntry.new(item))
			elif item.stack_limit_category == "coffee":
				self.battle_rare.push_back(ItemEntry.new(item))	
			elif item.stack_limit_category == "smoke_bomb":
				self.battle_rare.push_back(ItemEntry.new(item))	
			elif item.stack_limit_category == "pear_fusilli":
				self.heal_common.push_back(ItemEntry.new(item))
			elif item.stack_limit_category == "rewind":
				if item.value < 1000:
					self.heal_common.push_back(ItemEntry.new(item))
				else:
					self.heal_rare.push_back(ItemEntry.new(item))				
			elif item.stack_limit_category == "respool":
				self.heal_rare.push_back(ItemEntry.new(item))
			elif item in ITEM_STATUP:
				self.stat_up.push_back(ItemEntry.new(item))

func _populate_moves():
	for move in BattleMoves.sellable_stickers:
		if "passive" in move.tags:
			move_passive.push_back(ItemEntry.new(null, false, move))
		else:
			move_active.push_back(ItemEntry.new(null, false, move))

	for move in SigilMoves.get_global().common_sigils:
		move_sigil.push_back(ItemEntry.new(null, false, move))
