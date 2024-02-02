extends "ShrineRewardBaseAction.gd"

export(Array, Resource) var items = []
export(int) var quantity = -1

func _run():
	var to_give = []
	if quantity < 0:
		to_give.append_array(self.items)
	else:
		var rng = get_rng()
		for _i in range(rng.rand_int(quantity)):
			to_give.push_back(rng.choice(self.items))

	MenuHelper.give_items(to_give)
	return true
