extends "ZoningPass.gd"

const LayoutGrid = preload("../plotting/LayoutGrid.gd")

export(Array, String) var road_zones = [ "road" ]
export(Array, String) var house_zones = [ "housea", "houseb" ]
export(Array, String) var dock_zones = [ "dock" ]
export(Array, String) var exit_zones = [ "exit" ]

func generate_zones(layout : PlotLayout, rng : Random) -> ZoneOverlay:
	var overlay = ZoneOverlay.new(layout, self.zone_resources)
	
	# Big areas are roadways
	for plot in layout.plots:
		if plot.definition.width > 3 || plot.definition.height > 3 || (plot.definition.shape_id == "2x2"):
			overlay.set_zone(plot.id, rng.choice(self.road_zones))
	
	# Docks should run along the bottom of the map and not have other areas underneath them
	var by_columns = layout.find_plots_by_column()
	for col in by_columns:
		var p1 = col[col.size() - 1] if col.size() > 0 else -1
		if p1 >= 0 && !overlay.has_zone(p1) && !layout.plots[p1].is_exit():
			if is_last_in_all_columns(p1, by_columns):
				overlay.set_zone(p1, rng.choice(self.dock_zones))

	# Stuff adjacent to a main area should be a house - this is like the mall with shops & plazas
	for door in layout.doors:
		var p1 = door.id1
		var p2 = door.id2
		if !overlay.has_zone(p1) && overlay.in_zone_class(p2, self.road_zones):
			overlay.set_zone(p1, rng.choice(self.house_zones))
		elif !overlay.has_zone(p2) && overlay.in_zone_class(p1, self.road_zones):
			overlay.set_zone(p2, rng.choice(self.house_zones))

	# Try and place some smaller roadways
	for plot in layout.plots:
		if !overlay.has_zone(plot.id):
			if plot.definition.width > 2 || plot.definition.height > 2 || (plot.definition.width == 2 && plot.definition.height == 2):
				overlay.set_zone(plot.id, rng.choice(self.road_zones))
	
	# Handle leftovers and force exit. Leftovers are small, so should probably be houses
	for plot in layout.plots:
		if plot.is_exit():
			overlay.set_zone(plot.id, rng.choice(self.exit_zones))
		elif plot.is_secret():
			overlay.set_zone(plot.id, rng.choice(self.house_zones))
		elif !overlay.has_zone(plot.id):
			overlay.set_zone(plot.id, rng.choice(self.house_zones))

	print("[ZoningPassTown] Allocated zones for rooms")
	return overlay

func is_last_in_all_columns(plot: int, by_columns: Array) -> bool:
	for col in by_columns:
		if col.size() > 0 && col[col.size() - 1] != plot && plot in col:
			return false

	return true