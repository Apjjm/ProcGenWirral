extends "ZoningPass.gd"

const LayoutGrid = preload("../plotting/LayoutGrid.gd")

export(float, 0, 1) var descend_chance = 0.9
export(float, 0, 1) var low_exit_chance = 0.25
export(Vector3) var snow_chance = Vector3(0.3, 0.2, 0.1)

func generate_zones(layout : PlotLayout, rng : Random) -> ZoneOverlay:
	var overlay = ZoneOverlay.new(layout, self.zone_resources)
	
	# Try to assign an ininitial preferred height to as many zones as we can
	var by_columns = layout.find_plots_by_column()
	for col in by_columns:
		var current = "hdd"
		for pid in col:
			if !overlay.has_zone(pid):
				overlay.set_zone(pid, current)
				if rng.rand_float() < self.descend_chance:
					current = "mdd" if current == "hdd" else "ldd"

	# Exit / special zone: Should always be on a reasonably low level, so insert that in now
	var low_exit = rng.rand_float() < self.low_exit_chance
	var exit_zone = "exitl" if low_exit else "exit"
	var adj_zone = as_non_exit_zone(exit_zone)
	var fixed_zones = []
	for plot in layout.plots:
		if plot.is_secret():
			fixed_zones.push_back(plot.id)
			overlay.set_zone(plot.id, "mdd")
		elif plot.is_exit():
			fixed_zones.push_back(plot.id)
			overlay.set_zone(plot.id, exit_zone)
			for door in layout.find_doors(plot.id):
				var pid = door.other_plot(plot.id)
				overlay.set_zone(pid, adj_zone)
				fixed_zones.push_back(pid)

	# The adjacent zone(s) to the exit should _always_ be the same level as the exit, 
	# However, we want to drag areas down in the next pass to make sure there isn't occlusion from the front.
	# So we need pull up areas behind the exit or adjacent zones instead
	for col in by_columns:
		if has_fixed_zone(col, fixed_zones):
			for pid in col:
				if pid in fixed_zones:
					break
				if is_above(adj_zone, overlay.get_zone(pid)):
					overlay.set_zone(pid, adj_zone)
	
	# Do a 2nd pass trying to pull occluding walls down to the appropriate level instead
	for col in by_columns:
		var lowest = ""
		for i in range(col.size()-1, -1, -1):
			var zone = overlay.get_zone(col[i])
			if lowest == "":
				lowest = zone
			elif is_above(lowest, zone):
				lowest = zone
				for j in range(i, col.size()):
					var pid = col[j]
					if is_above(overlay.get_zone(pid), zone) && !(pid in fixed_zones):
						overlay.set_zone(pid, as_non_exit_zone(zone))
			else:
				lowest = zone

	# Final pass, make some of the areas snowy
	for plot in layout.plots:
		if plot.is_normal():
			var zone = as_snow_zone(overlay.get_zone(plot.id), rng)
			overlay.set_zone(plot.id, zone)

	print("[ZoningPassCave] Allocated zones for rooms")
	return overlay

func has_fixed_zone(col, fixed_zones) -> bool:
	for fixed_plot in fixed_zones:
		if fixed_plot in col:
			return true

	return false

func is_above(room1: String, room2: String) -> bool:
	if room1 == "hdd":
		return room2 == "mdd" || room2 == "exit" || room2 == "ldd" || room2 == "exitl"
	elif room1 == "mdd" || room1 == "exit":
		return room2 == "ldd" || room2 == "exitl"
	else:
		return false

func as_non_exit_zone(zone: String) -> String:
	if zone == "exit":
		return "mdd"
	elif zone == "exitl":
		return "ldd"
	else:
		return zone

func as_snow_zone(zone: String, rng: Random) -> String:
	var roll = rng.rand_float()
	if zone == "ldd" && roll < self.snow_chance.z:
		return "ldl"
	elif zone == "mdd" && roll < self.snow_chance.y:
		return "mdl"
	elif zone == "hdd" && roll < self.snow_chance.x:
		return "hdl"
	else:
		return zone
