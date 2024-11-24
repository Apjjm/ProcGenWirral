extends "res://menus/BaseMenu.gd"

const DungeonData = preload("../../globals/DungeonData.gd")
const PlayerData = preload("../../globals/PlayerData.gd")

var _inputs
var _length_list
var _wild_areas_list
var _enemy_scaling_list
var _wild_enemies_list
var _exp_scaling_list
var _seed_input

func _ready():
	self._inputs = get_node("./Scroller/OverscanMarginContainer/MarginContainer/Vbox/MainInfoContainer/VBoxContainer/Inputs")
	self._length_list = self._inputs.get_node("LengthList")
	self._wild_areas_list = self._inputs.get_node("WildAreasList")
	self._enemy_scaling_list = self._inputs.get_node("EnemyScalingList")
	self._wild_enemies_list = self._inputs.get_node("WildEnemiesList")
	self._exp_scaling_list = self._inputs.get_node("ExpScalingList")
	self._seed_input = self._inputs.get_node("SeedInput")
	self._on_ResetButton_pressed()
	self._inputs.grab_focus()

func grab_focus():
	self._inputs.grab_focus()

func _random_seed():
	var alphabet = ["0","1","2","3","4","5","6","7","8","9","0","A","B","C","D","E","F"]
	var result = ""
	for _i in range(8):
		result += alphabet[randi() % alphabet.size()]

	return result

func _on_ResetButton_pressed():
	self._seed_input.text = _random_seed()
	self._length_list.selected_index = 1
	self._enemy_scaling_list.selected_index = 1
	self._wild_areas_list.selected_index = 0
	self._wild_enemies_list.selected_index = 0
	self._exp_scaling_list.selected_index = 1

func _on_SaveButton_pressed():
	var args = DungeonData.GenerateArgs.new()
	args.seed_value = self._seed_input.text if self._seed_input.text != "" else _random_seed()

	if self._length_list.selected_value == "3x3":
		args.num_areas = 3
		args.rooms_per_area = 3
	elif self._length_list.selected_value == "4x3":
		args.num_areas = 4
		args.rooms_per_area = 3
	elif self._length_list.selected_value == "4x4":
		args.num_areas = 4
		args.rooms_per_area = 4
	elif self._length_list.selected_value == "4x5":
		args.num_areas = 4
		args.rooms_per_area = 5

	args.enemy_scaling = self._enemy_scaling_list.selected_value
	args.exp_boost = self._exp_scaling_list.selected_value
	args.wild_areas = self._wild_areas_list.selected_value
	args.wild_enemies = self._wild_enemies_list.selected_value

	PlayerData.get_global().push_dungeon_player(args.seed_value)
	DungeonData.get_global().generate_dungeon(args)

	choose_option(args)
