extends "res://menus/BaseMenu.gd"
const TapeStorageButton = preload("res://menus/tape_storage/TapeStorageButton.tscn")

onready var title_label = find_node("TitleLabel")
onready var empty_label = find_node("EmptyLabel")
onready var tape_buttons= find_node("TapeButtons")
onready var tape_ui = find_node("TapeUI")

var all_tapes_from:Array
var all_tapes_to:Array
var tape_from:MonsterTape
var tape_to:MonsterTape
var selecting_from:bool

func _ready():
	if Debug.dev_mode && SceneManager.current_scene == self:
		SaveState.tape_collection._console_debug_tapes()
	
	self.all_tapes_from = SaveState.tape_collection.tapes_by_name
	self.all_tapes_to = SaveState.party.get_tapes()
	self.tape_from = null
	self.tape_to = null
	self.selecting_from = true

	tape_ui.visible = false
	tape_ui.tape = null
	update_ui()

func grab_focus():
	tape_buttons.grab_focus()

func update_ui():
	if not title_label:
		return
	
	if self.selecting_from:
		title_label.text = "AP7_DUNGEON_MENU_RERECORD_TITLE_FROM"
		setup_tape_buttons(self.all_tapes_from, self.tape_from)
	else:
		title_label.text = "AP7_DUNGEON_MENU_RERECORD_TITLE_TO"
		setup_tape_buttons(self.all_tapes_to, self.tape_to)

func setup_tape_buttons(tapes:Array, current_tape: MonsterTape):	
	for child in tape_buttons.get_children():
		tape_buttons.remove_child(child)
		child.queue_free()
	
	var current_button = null
	for tape in tapes:		
		var button = TapeStorageButton.instance()
		button.tape = tape
		tape_buttons.add_child(button)
		button.connect("focus_entered", self, "_on_tape_focused", [tape])
		button.connect("pressed", self, "_on_tape_pressed", [tape])
		if tape == current_tape:
			current_button = button
	
	empty_label.visible = tape_buttons.get_child_count() == 0
	if current_button:
		_on_tape_focused(current_tape)
		tape_buttons.initial_focus = tape_buttons.get_path_to(current_button)
	else:
		_on_tape_focused(null)
		tape_buttons.initial_focus = NodePath()

	tape_buttons.setup_focus()

func _on_tape_focused(tape:MonsterTape):
	if not tape_ui:
		return 
	
	tape_ui.visible = tape != null
	tape_ui.tape = tape

func _on_tape_pressed(tape:MonsterTape):
	if self.selecting_from:
		self.tape_from = tape
		self.selecting_from = false
		update_ui()
	else:
		self.tape_to = tape
		
		var message = Loc.trf("AP7_DUNGEON_MENU_RERECORD_CONFIRM", { 
			tape_from = self.tape_from.get_name(), 
			tape_to = self.tape_to.get_name() 
		})
		if not yield (MenuHelper.confirm(message, 1, 1), "completed"):
			return 
		
		_rerecord()
		choose_option(true)

func _unhandled_input(event):
	if not MenuHelper.is_in_top_menu(self):
		return
	
	if event.is_action_pressed("ui_cancel"):
		if self.selecting_from:
			cancel()
		else:
			self.selecting_from = true
			update_ui()

func _rerecord():
	if self.tape_from != null && self.tape_to != null:
		for i in range(self.tape_to.get_max_stickers()):
			var sticker = self.tape_to.peel_sticker(i)
			if sticker != null:
				SaveState.inventory.add_item(sticker)

		SaveState.party.remove_tape(self.tape_to)
		SaveState.party.add_tape(self.tape_from)
		SaveState.tape_collection.remove_tape(self.tape_from)
