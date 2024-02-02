extends "ZoningPass.gd"

export(int, 0, 99) var plaza_size_1 = 6
export(int, 0, 99) var plaza_size_2 = 4

export(Array, String) var shop_zones = [ "shop_book", "shop_vinyl", "shop_clothes" ]
export(Array, String) var plaza_zones = [ "plaza" ]
export(Array, String) var maint_zones = [ "maint" ]
export(Array, String) var exit_zones = [ "exit" ]

func generate_zones(layout: PlotLayout, rng: Random) -> ZoneOverlay:
	var overlay = ZoneOverlay.new(layout, self.zone_resources)

	# Highest priority is to allocate the special exit zone! So do that!
	for plot in layout.plots:
		if plot.is_exit():
			overlay.set_zone(plot.id, rng.choice(self.exit_zones))
		elif plot.is_secret():
			overlay.set_zone(plot.id, rng.choice(self.shop_zones))

	# We want to give priority to the big areas for outdoor plazas, and then have shops sprouting off from them where possible
	if _place_plazas(overlay, layout, self.plaza_size_1, rng):
		_place_shops_next_to_plazas(overlay, layout, rng)

	if _place_plazas(overlay, layout, self.plaza_size_2, rng):
		_place_shops_next_to_plazas(overlay, layout, rng)

	# The rest of the zones are just maintainance
	for plot in layout.plots:
		if !overlay.has_zone(plot.id):
			overlay.set_zone(plot.id, rng.choice(self.maint_zones))

	print("[ZoningPassMall] Allocated zones for rooms")
	return overlay

func _place_plazas(overlay: ZoneOverlay, layout: PlotLayout, min_size: int, rng: Random) -> bool:
	var plaza_placed = false
	for plot in layout.plots:
		if !overlay.has_zone(plot.id) && plot.definition.size >= min_size:
			overlay.set_zone(plot.id, rng.choice(self.plaza_zones))
			plaza_placed = true
	return plaza_placed

func _place_shops_next_to_plazas(overlay: ZoneOverlay, layout: PlotLayout, rng: Random):
	for door in layout.doors:
		var p1 = door.id1
		var p2 = door.id2
		if !overlay.has_zone(p1) && overlay.in_zone_class(p2, self.plaza_zones):
			overlay.set_zone(p1, rng.choice(self.shop_zones))
		elif !overlay.has_zone(p2) && overlay.in_zone_class(p1, self.plaza_zones):
			overlay.set_zone(p2, rng.choice(self.shop_zones))
