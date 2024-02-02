extends "res://menus/BaseMenu.gd"

const RewardMenuItemAction = preload("RewardMenuItemAction.gd")
const RewardButtonScene = preload("RewardButton.tscn")

var title : String
var menu_open_sound : Resource
var reward_items : Array

onready var title_label = find_node("RewardMenuTitleLabel")
onready var button_container = find_node("ButtonContainer")
onready var audio_stream = find_node("AudioStreamPlayer")

func _ready():
	self.title_label.text = self.title

	self.button_container.initial_focus = NodePath("")
	for child in self.button_container.get_children():
		self.button_container.remove_child(child)
		child.queue_free()

	for item in self.reward_items:
		var btn = RewardButtonScene.instance()
		btn.reward_title = item.title
		btn.reward_description = item.description
		btn.reward_requirement = item.requirement
		btn.reward_quality = item.quality
		btn.reward_icon = item.icon
		btn.connect("pressed", self, "_on_button_pressed", [item])
		self.button_container.add_child(btn)
		
		if self.button_container.initial_focus.is_empty():
			self.button_container.initial_focus = self.button_container.get_path_to(btn)

	self.button_container.setup_focus()

func display():
	if self.menu_open_sound != null:
		audio_stream.stop()
		audio_stream.stream = self.menu_open_sound
		audio_stream.play()
	return .display()

func grab_focus():
	self.button_container.grab_focus()

func _on_button_pressed(item: RewardMenuItemAction):
	if item.selected_sound != null:
		audio_stream.stop()
		audio_stream.stream = item.selected_sound
		audio_stream.play()
	choose_option(item)
