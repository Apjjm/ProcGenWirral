extends Reference

var info : Dictionary # Backed by a dictionary because this needs to live in a save

func _init(info: Dictionary):
	self.info = info

func floor_number() -> int:
	return self.info["number"] if self.info.has("number") else 1

func subfloor_number() -> int:
	return self.info["sub_number"] if self.info.has("sub_number") else 1

func area_number() -> int:
	return self.info["area_number"] if self.info.has("area_number") else int(floor_number() / 4)

func tags() -> Array:
	var t = []
	if self.info.has("tags"): # Defensive copy
		t.append_array(self.info["tags"])
	return t

func has_tag(tag: String) -> bool:
	return self.info.has("tags") && (tag in self.info["tags"])

func floor_seed() -> int:
	return self.info["floor_seed"] if self.info.has("floor_seed") else randi()

func floor_scene() -> String:
	return self.info["scene"] if self.info.has("scene") else ""

func secret_floor_key() -> String:
	return self.info["secret"] if self.info.has("secret") else ""

func warp_to() -> void:
	print("[FloorInfo] Warp to floor: ", self.info["number"], " tags: ", self.info["tags"], " seed: ", self.info["floor_seed"], " scene: ", self.info["scene"])
	var scene_args = { "disable_preservation": true, "disable_reentering": true, "ap7_floor_next": true }
	WorldSystem.warp(self.info["scene"], null, "Start", scene_args)

func set_area_number(area_number: int):
	self.info["area_number"] = area_number

func set_number(number: int):
	self.info["number"] = number

func set_subfloor_number(number: int):
	self.info["sub_number"] = number

func set_tags(tags: Array):
	self.info["tags"] = tags

func add_tag(tag: String):
	if !self.info.has("tags"):
		self.info["tags"] = []

	self.info["tags"].push_back(tag)

func set_floor_scene(scene: String):
	self.info["scene"] = scene

func set_floor_seed(s: int):
	self.info["floor_seed"] = s

func set_secret_floor_key(k: String):
	self.info["secret"] = k