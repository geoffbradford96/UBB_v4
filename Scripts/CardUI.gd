extends Control

signal card_clicked(card_ui_node)

@export var card_data: Resource

@onready var cost_label = $CostLabel
@onready var name_label = $NameLabel
@onready var background = $Background
@onready var hp_label = $HPLabel
@onready var type_label = $TypeLabel

var is_selected: bool = false
var art_rect: TextureRect = null

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("card_clicked", self)

func set_selected(selected: bool):
	is_selected = selected
	if is_selected:
		position.y = -20
		background.color = Color(0.2, 0.5, 0.2)
	else:
		position.y = 0
		if card_data and "is_spell" in card_data and card_data.is_spell:
			background.color = Color(0.4, 0.1, 0.1)
		elif card_data and "card_type" in card_data and card_data.card_type == "Commander":
			background.color = Color(0.5, 0.4, 0.1)
		elif card_data and "card_type" in card_data and card_data.card_type == "Vehicle":
			background.color = Color(0.2, 0.3, 0.4)
		else:
			background.color = Color(0.15, 0.15, 0.15)

func _ready():
	art_rect = get_node_or_null("CardArt")
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
	if card_data:
		set_card_data(card_data)

func set_card_data(data: Resource):
	if not data: return
	card_data = data
	cost_label.text = str(data.cost)
	name_label.text = data.card_name
	
	if art_rect and "card_art" in data and data.card_art != null:
		art_rect.texture = data.card_art
		art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var desc_label = get_node_or_null("DescLabel")
	if desc_label and "description" in data:
		desc_label.text = data.description
		
	if "max_hp" in data:
		hp_label.text = "HP: " + str(data.max_hp)
		
	if "is_melee" in data:
		type_label.text = "Melee" if data.is_melee else "Ranged"
		
	if data.is_spell:
		background.color = Color(0.4, 0.1, 0.1)
		hp_label.text = ""
		type_label.text = "Spell"
	elif "card_type" in data and data.card_type == "Commander":
		background.color = Color(0.5, 0.4, 0.1)
		type_label.text = "Com"
	elif "card_type" in data and data.card_type == "Vehicle":
		background.color = Color(0.2, 0.3, 0.4)
		type_label.text = "Veh"
	else:
		background.color = Color(0.15, 0.15, 0.15)
