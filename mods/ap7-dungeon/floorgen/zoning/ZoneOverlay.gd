extends Reference

const PlotLayout = preload("../plotting/PlotLayout.gd")

var zones : Array = []
var zone_resources : Array = []

func _init(layout: PlotLayout, zone_resources: Array):
	self.zones = []
	self.zones.resize(layout.plots.size())
	self.zones.fill("")
	self.zone_resources = zone_resources

func has_zone(plot_id: int) -> bool:
	return self.zones[plot_id] != ""

func set_zone(plot_id: int, zone: String):
	self.zones[plot_id] = zone

func get_zone(plot_id: int) -> String:
	return self.zones[plot_id]

func in_zone_class(plot_id, zones: Array):
	return self.zones[plot_id] in zones

func clear_zone(plot_id: int):
	self.zones[plot_id] = ""

func get_resources(zone: String):
	for z in self.zone_resources:
		if zone in z.zones:
			return z
	
	return null

func get_resources_by_music(music: AudioStream):
	for z in self.zone_resources:
		if music == z.music_vox || music == z.music_novox:
			return z

	return null

func get_resources_by_plot(plot_id: int):
	var zone = self.zones[plot_id] if plot_id >= 0 && plot_id < self.zones.size() else ""
	return get_resources(zone)