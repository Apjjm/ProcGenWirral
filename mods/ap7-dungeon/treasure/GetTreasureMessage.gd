extends Control

export var timeout : float = 3.0

onready var animation : AnimationPlayer = $AnimationPlayer
onready var audio : AudioStreamPlayer = $AudioStreamPlayer
onready var icon_texture : TextureRect = $MarginContainer/VBoxContainer/PanelContainer2/MarginContainer2/HBoxContainer/IconTexture
onready var item_label : RichTextLabel = $MarginContainer/VBoxContainer/PanelContainer2/MarginContainer2/HBoxContainer/ItemLabel
onready var item_amount : Label = $MarginContainer/VBoxContainer/PanelContainer2/MarginContainer3/CountLabel

const default_jingle = preload("res://sfx/ui/item_get.ogg")
const rare_jingle = preload("res://sfx/ui/key_item_get.ogg")

var _closed = false
var _time_shown = 0
signal confirmed()

func run_oneshot_menu(loot: BaseItem, quantity: int, rare: bool):
	MenuHelper.add_child(self)
	yield (self._run_menu(loot, quantity, rare), "completed")
	self.queue_free()

func _exit_tree():
	MusicSystem.mute = false

func _run_menu(loot: BaseItem, quantity: int, rare: bool):

	self.animation.play_backwards("get_item")
	self.animation.seek(0, true)
	yield (Co.next_frame(), "completed")

	self._closed = false
	self._time_shown = 0

	icon_texture.texture = loot.icon
	item_label.bbcode_text = Loc.tr(loot.name)
	item_amount.text = Loc.trf("ITEM_COUNT", [quantity])
	item_amount.visible = quantity != 1
	
	if loot.get_rarity() != BaseItem.Rarity.RARITY_COMMON:
		var color = BaseItem.get_rarity_color(loot.get_rarity())
		item_label.add_color_override("default_color", color)
		item_amount.add_color_override("font_color", color)

	self.animation.play("get_item")
	yield (play_jingle(rare), "completed")
	if !self._closed:
		yield (self, "confirmed")

	self.animation.play_backwards("get_item", -2.0)
	yield (self.animation, "animation_finished")

func _unhandled_input(event):
	if !self.visible || self._closed || GlobalUI.is_input_blocked() || !MenuHelper.is_in_top_menu(self):
		return 
	if event.is_action_pressed("ui_cancel") || event.is_action_pressed("ui_accept")  || event.is_action_pressed("interact") \
		|| event.is_action("move_up") || event.is_action("move_down") \
		|| event.is_action("move_left") || event.is_action("move_right") \
		|| event.is_action_pressed("dash") || event.is_action_pressed("jump"):
		self._closed = true
		emit_signal("confirmed")
		get_tree().set_input_as_handled()

func play_jingle(rare: bool):
	MusicSystem.mute = true
	self.audio.stream = self.rare_jingle if rare else self.default_jingle
	self.audio.play()
	yield (Co.safe_wait_for_audio(self, self.audio), "completed")
	MusicSystem.mute = false
