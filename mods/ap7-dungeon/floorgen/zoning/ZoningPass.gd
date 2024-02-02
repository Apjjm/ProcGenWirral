extends Node

const ZoneOverlay = preload("ZoneOverlay.gd")
const PlotLayout = preload("../plotting/PlotLayout.gd")

export(Array) var zone_resources

# Zoning is used to apply a set of constraints to what actual parcels we allocate to each plot
# this is naturally quite tightly coupled to how exactly we want each floor to be set out and the tiles available
# for example, we might only certain tiles in a certain way, so never need variants in the style of other zones
# either way - it's probably easier to just script the zoning rules per actual zone, rather than try and come up
# with some data driven appraoch which will end up being probably as complex as the scripting anyway...
func generate_zones(layout : PlotLayout, _rng : Random) -> ZoneOverlay:
	var overlay = ZoneOverlay.new(layout, self.zone_resources)
	for plot in layout.plots:
		overlay.set_zone(plot.id, "*")

	print("[ZoningPassDefault] Allocated zones for rooms")
	return overlay
