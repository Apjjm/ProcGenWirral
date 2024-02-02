extends Node

export(Array, AudioStream) var preload_audio = []

var _terraform_forms = []
var _preloaded = []

func _enter_tree():
	request_ready()

func _ready():
	if SceneManager.current_scene is Battle:
		var battle = SceneManager.current_scene
		if !battle.sprite_loader:
			yield (battle, "ready")

		print("[TerraformSpritesPreloader] Preloading terraform sprites")
		_terraform_forms = get_valid_forms(10, battle.rand)
		battle.sprite_loader.register_extra_forms(_terraform_forms)

func next_terraform_form() -> MonsterForm:
	var next = _terraform_forms.pop_front()
	_terraform_forms.push_back(next)
	return next

func get_valid_forms(count: int, rng: Random) -> Array:
	var result = []
	for form in MonsterForms.basic_forms.values():
		if form.require_dlc == "" || DLC.has_dlc(form.require_dlc):
			result.push_back(form)
	
	rng.shuffle(result)
	if result.size() > count:
		result.resize(count)

	return result
