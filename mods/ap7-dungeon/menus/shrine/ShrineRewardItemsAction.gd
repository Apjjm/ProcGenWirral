extends "ShrineRewardBaseAction.gd"

export(Array, Resource) var items = []
export(int) var quantity = -1

func _run():
	var to_give = []
	if quantity <= 0:
		for item in self.items:
			to_give.append_array([{ "item": item, "amount": 1 }])
	else:
		var rng = get_rng()
		for _i in range(quantity):
			var item = ItemFactory.generate_item(rng.choice(self.items), rng)
			to_give.append_array([{ "item": item, "amount": 1 }])
	
	MenuHelper.give_items(to_give)
	return true
