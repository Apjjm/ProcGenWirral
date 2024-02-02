extends ContainerButton

const COLOR_CHOICE_GOOD = Color("35379d")
const COLOR_CHOICE_NEUTRAL = Color("225d31")
const COLOR_CHOICE_BAD = Color("781c0f")

var reward_icon : Resource = preload("res://ui/icons/status_effects/attack_melee_up.png")
var reward_title : String = "REWARD"
var reward_description : String = "Some reward description here"
var reward_requirement : String = "Some reward requirement"
var reward_positive : String = "Some reward description here"
var reward_quality : int = 0

func _ready():
	var title : Label = find_node("TitleLabel")
	var description = find_node("DescriptionLabel")
	var icon = find_node("IconTexture")

	title.text = self.reward_title
	if self.reward_quality > 0:
		title.add_color_override("font_color", COLOR_CHOICE_GOOD)
	elif self.reward_quality < 0:
		title.add_color_override("font_color", COLOR_CHOICE_BAD)
	else:
		title.add_color_override("font_color", COLOR_CHOICE_NEUTRAL)

	if self.reward_requirement != "":
		description.bbcode_text = Loc.tr(self.reward_description) + "\n" + Loc.tr(self.reward_requirement)
	else:
		description.bbcode_text = Loc.tr(self.reward_description)

	icon.texture = self.reward_icon
