extends "ZoningPass.gd"

const LayoutGrid = preload("../plotting/LayoutGrid.gd")

export(Array, String) var lobby_zones = [ "lobby" ]
export(Array, String) var walkway_zones = [ "walkway" ]
export(Array, String) var station_zones = [ "corridoor" ]
export(Array, String) var exit_zones = [ "exit" ]

func generate_zones(layout: PlotLayout, rng : Random) -> ZoneOverlay:
	var overlay = ZoneOverlay.new(layout, self.zone_resources)

	# Big square areas should be the lobby
	for plot in layout.plots:
		if plot.definition.shape_id == "2x2" || plot.definition.shape_id == "3x2" || plot.definition.shape_id == "3x3":
			overlay.set_zone(plot.id, rng.choice(self.lobby_zones))

	# Longer corridoors should be station themed
	var lower_left = 5
	var station_links = []
	station_links.resize(layout.plots.size())
	station_links.fill(0)

	for plot in layout.plots:
		if plot.is_exit():
			overlay.set_zone(plot.id, rng.choice(self.exit_zones))
			add_station_link(layout, overlay, plot.id, station_links)
		elif (plot.definition.size > 3 && !overlay.has_zone(plot.id)) || plot.is_secret():
			if lower_left > 0:
				overlay.set_zone(plot.id, rng.choice(self.station_zones))
				add_station_link(layout, overlay, plot.id, station_links)
				lower_left -= 1

	# After we have placed a station area down, it should ideally form a chain of at least one other station area, so the station feels sprawling.
	for plot in layout.plots:
		if overlay.has_zone(plot.id) && station_links[plot.id] < 3 && !overlay.in_zone_class(plot.id, lobby_zones):
			for door in layout.doors:
				if door.id1 == plot.id && !overlay.has_zone(door.id2):
					overlay.set_zone(door.id2, rng.choice(self.station_zones))
					add_station_link(layout, overlay, plot.id, station_links)
					station_links[plot.id] += 1
				elif door.id2 == plot.id && !overlay.has_zone(door.id1):
					overlay.set_zone(door.id1, rng.choice(self.station_zones))
					add_station_link(layout, overlay, plot.id, station_links)
					station_links[plot.id] += 1

	# The rest of the map is walkways
	for plot in layout.plots:
		if !overlay.has_zone(plot.id):
			overlay.set_zone(plot.id, rng.choice(self.walkway_zones))

	print("[ZoningPassStation] Allocated zones for rooms")
	return overlay

func add_station_link(layout: PlotLayout, overlay: ZoneOverlay, id: int, links: Array):
	for door in layout.doors:
		if door.id1 == id:
			if overlay.has_zone(door.id2) && !overlay.in_zone_class(door.id2, lobby_zones):
				links[door.id2] += 1
		elif door.id2 == id:
			if overlay.has_zone(door.id1) && !overlay.in_zone_class(door.id1, lobby_zones):
				links[door.id1] += 1