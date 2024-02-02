extends Reference

var treasures: Array = []
var key_items: Array = []

class Treasure:
	extends Reference

	var id : int
	var plot: int
	var item : Resource
	var quantity : int
	var scene: PackedScene
	var loot_seed: int

func add_treasure() -> Treasure:
	var t = Treasure.new()
	t.id = self.treasures.size()
	self.treasures.push_back(t)
	return t

func add_key_item() -> Treasure:
	var t = Treasure.new()
	t.id = self.key_items.size()
	self.key_items.push_back(t)
	return t

func get_treasure(id: int) -> Treasure:
	return self.treasures[id]

func get_key_item(id: int) -> Treasure:
	return self.key_items[id]

func get_treasures() -> Array:
	return self.treasures

func get_key_items() -> Array:
	return self.key_items
