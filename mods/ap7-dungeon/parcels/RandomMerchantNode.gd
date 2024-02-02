extends Spatial

const RoomRootNode = preload("../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("RandomParcelRngRoot.gd")
const HumanNpc = preload("res://world/npc/HumanNPC.gd")

export(Array, Resource) var possible_items = []
export(int,1,10) var item_cout = 8
export(int,0,10) var item_stock = 1
export(float) var value_percentage = 1.0
export(String) var merchant_key = "items"
export(bool) var include_all_stickers = false
export(String) var filter_stickers_by_tag = ""

var _realised = false

func _ready():
	if self._realised:
		return

	var rr = RoomRootNode.find_room_root(self)
	if rr == null:
		rr = RandomParcelRngRoot.find_rng_root(self)


	
	var choices = []
	choices.append_array(self.possible_items)
	if self.include_all_stickers:
		if filter_stickers_by_tag != "":
			choices.append_array(BattleMoves.get_sellable_stickers_for_tag(filter_stickers_by_tag))
		else:
			choices.append_array(BattleMoves.sellable_stickers)

	var npc = _find_npc()
	var exchange = _find_exchange_action(npc)
	_add_exchanges(exchange, choices, rr.prop_rng.get_child(self.merchant_key))
	npc.randomize_sprite(rr.prop_rng)

func _find_npc():
	for c in get_children():
		if c is HumanNpc:
			return c

func _find_exchange_action(node: Node):
	for c in node.get_children():
		if c is ExchangeMenuAction:
			return c
		elif c.get_child_count() > 0:
			var exchange = _find_exchange_action(c)
			if exchange != null:
				return exchange
	return null

func _add_exchanges(action: ExchangeMenuAction, items: Array, rng: Random):	
	var exchange_stat = SaveState.stats.get_stat("exchange_purchased")
	action.exchanges = [] # We can't just clear it! It's an exported array and godot shares these!

	rng.shuffle(items)
	for i in range(self.item_cout):
		var exchange_key = "ap7_dungeon_shop_" + merchant_key + "_" + str(i)
		exchange_stat.set_count(exchange_key, 0)

		var exchange = InflatingExchange.new()
		exchange.item = ItemFactory.generate_item(items.pop_back())
		exchange.name = exchange.item.get_name()
		exchange.description = exchange.item.get_description()
		exchange.rarity = exchange.item.get_rarity()
		exchange.icon = exchange.item.icon
		exchange.currency = exchange.item.recycle_to
		exchange.price_initial = int(exchange.item.value * value_percentage / exchange.currency.value)
		exchange.stat_key = exchange_key
		if self.item_stock > 0:
			exchange.max_allowed_initial = self.item_stock
			exchange.max_allowed_limit = self.item_stock
			exchange.max_amount = self.item_stock
		exchange.amount = 1
		action.exchanges.push_back(exchange)
