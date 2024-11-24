extends Reference

const FloorInfo = preload("FloorInfo.gd")

var info : Dictionary # Backed by a dictionary because this needs to live in a save

func _init(info: Dictionary):
	self.info = info

func set_initial_seed(s: String):
	self.info["initial_seed"] = s

func set_level_multiplier(v: float):
	self.info["level_multiplier"] = v

func set_wild_enemies(b: bool):
	self.info["wild_enemies"] = b

func set_exp_boost(v: float):
	self.info["exp_boost"] = v

func add_normal_floor(f: FloorInfo):
	if !self.info.has("floors"):
		self.info["floors"] = []
	
	self.info["floors"].push_back(f.info)

func add_secret_floor(k: String, f: FloorInfo):
	if !self.info.has("secret"):
		self.info["secret"] = {}

	self.info["secret"][k] = f.info

func move_to_secret_floor(k: String) -> FloorInfo:
	if has_secret_floor(k):
		var f = self.info["secret"][k]
		self.info["current"] = f
		return FloorInfo.new(f)

	return null

func move_to_next_normal_floor() -> FloorInfo:
	if has_next_normal_floor():
		var f = self.info["floors"].pop_front()
		self.info["current"] = f
		return FloorInfo.new(f)

	return null

func move_to_last_normal_floor() -> FloorInfo:
	var f = null
	while has_next_normal_floor():
		f = self.info["floors"].pop_front()

	if f != null:
		self.info["current"] = f
		return FloorInfo.new(f)
	
	return null

func has_next_normal_floor() -> bool:
	return self.info.has("floors") && self.info["floors"].size() > 0

func has_secret_floor(k: String) -> bool:
	return self.info.has("secret") && self.info["secret"].has(k)

func has_current_floor() -> bool:
	return self.info.has("current") && self.info["current"] != null

func get_current_floor() -> FloorInfo:
	return FloorInfo.new(self.info["current"]) if has_current_floor() else null

func get_current_floor_or_default() -> FloorInfo:
	return FloorInfo.new(self.info["current"]) if has_current_floor() else FloorInfo.new({})

func get_next_normal_floor() -> FloorInfo:
	return FloorInfo.new(self.info["floors"][0]) if has_next_normal_floor() else null
	
func get_next_normal_floor_without_tag(tag: String) -> FloorInfo:
	if self.info.has("floors"):
		for f in self.info["floors"]:
			var fi = FloorInfo.new(f)
			if !fi.has_tag(tag):
				return fi

	return null

func get_floors_with_tag(tag: String) -> Array:
	var result = []
	if self.info.has("floors"):
		for f in self.info["floors"]:
			var fi = FloorInfo.new(f)
			if fi.has_tag(tag):
				result.push_back(fi)

	return result

func get_floors() -> Array:
	var result = []
	if self.info.has("floors"):
		for f in self.info["floors"]:
			result.push_back(FloorInfo.new(f))

	return result

func get_initial_seed() -> String:
	return self.info["initial_seed"] if self.info.has("initial_seed") else -1

func get_level_multiplier() -> float:
	return self.info["level_multiplier"] if self.info.has("level_multiplier") else 1.5

func get_wild_enemies():
	return self.info["wild_enemies"] if self.info.has("wild_enemies") else false

func get_exp_boost() -> float:
	return self.info["exp_boost"] if self.info.has("exp_boost") else 1.0

func print_stats() -> void:
	var floors = self.info["floors"] if self.info.has("floors") else []
	var secrets = self.info["secret"].keys() if self.info.has("secret") else []
	var multiplier = self.info["level_multiplier"] if self.info.has("level_multiplier") else "-"
	var wild = self.info["wild_enemies"] if self.info.has("wild_enemies") else "-"
	var boost = self.info["exp_boost"] if self.info.has("exp_boost") else "-"
	print("[DungeonInfo] Seed: ", get_initial_seed(), " Floors: ", floors.size(), " Secrets: ", secrets, " Multiplier: ", multiplier, " Wild: ", wild, "Boost: ", boost)

func print_spoilers() -> void:
	print("[DungeonInfo] SPOILERS - Seed: ", get_initial_seed())
	for fi in get_floors():
		print(" - ", fi.floor_number(), " Tags: ", fi.tags(), " Seed: ", fi.floor_seed())
	
	var secrets = self.info["secret"].keys() if self.info.has("secret") else []
	for s in secrets:
		var fi = FloorInfo.new(self.info["secret"][s])
		print(" - ", s, "(", fi.floor_number(), ") Tags: ", fi.tags(), " Seed: ", fi.floor_seed())
