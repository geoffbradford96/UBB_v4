extends Control

@onready var bg = $Background
@onready var title_label = $Title
@onready var trim_top = $GoldTrimTop
@onready var trim_bot = $GoldTrimBottom
var all_cards = []
var deck_commander = null
var deck_units = []

@onready var main_body = $MainBody
var card_ui_scene = preload("res://Scenes/CardUI.tscn")

var left_grid: GridContainer
var right_commander_slot: CenterContainer
var right_deck_grid: GridContainer
var count_label: Label
var profile_dropdown: OptionButton
var current_tab: int = 0

func _ready():
	load_all_cards()
	build_ui()
	load_profile(GameState.editing_profile)

func load_all_cards():
	var dir = DirAccess.open("res://Data/Cards")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				var clean_name = file_name.trim_suffix(".remap")
				var res = load("res://Data/Cards/" + clean_name)
				if res is CardData:
					all_cards.append(res)
			file_name = dir.get_next()

func build_ui():
	# Top Bar for Profile Selection
	var top_bar = HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 40)
	var label = Label.new()
	label.text = "Editing Profile: "
	top_bar.add_child(label)
	
	profile_dropdown = OptionButton.new()
	profile_dropdown.add_item("Player1")
	profile_dropdown.add_item("Guest1")
	profile_dropdown.add_item("Guest2")
	profile_dropdown.add_item("Guest3")
	
	# Select correct dropdown item based on GameState
	for i in range(profile_dropdown.item_count):
		if profile_dropdown.get_item_text(i) == GameState.editing_profile:
			profile_dropdown.select(i)
			break
			
	profile_dropdown.connect("item_selected", Callable(self, "_on_profile_selected"))
	top_bar.add_child(profile_dropdown)
	
	# Insert top bar at the very top of the scene (before MainBody if possible, or inside it)
	add_child(top_bar)
	move_child(top_bar, 0)
	
	var left_panel = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_body.add_child(left_panel)
	
	var left_vbox = VBoxContainer.new()
	left_panel.add_child(left_vbox)
	
	var tab_bar = TabBar.new()
	tab_bar.add_tab("Dominion of Sol")
	tab_bar.add_tab("The Void Swarm")
	tab_bar.add_tab("The Rimworlders")
	tab_bar.add_tab("Pirate Kingdoms")
	tab_bar.add_tab("The Reach")
	tab_bar.connect("tab_changed", Callable(self, "_on_tab_changed"))
	left_vbox.add_child(tab_bar)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(scroll)
	
	left_grid = GridContainer.new()
	left_grid.columns = 4
	scroll.add_child(left_grid)
	
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(400, 0)
	main_body.add_child(right_panel)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_vbox)
	
	var deck_title = Label.new()
	deck_title.text = "-- Your Army --"
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(deck_title)
	
	var cmdr_label = Label.new()
	cmdr_label.text = "Commander (1/1)"
	right_vbox.add_child(cmdr_label)
	
	right_commander_slot = CenterContainer.new()
	right_commander_slot.custom_minimum_size = Vector2(0, 220)
	right_vbox.add_child(right_commander_slot)
	
	count_label = Label.new()
	count_label.text = "Units & Spells (0/5)"
	right_vbox.add_child(count_label)
	
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_scroll)
	
	right_deck_grid = GridContainer.new()
	right_deck_grid.columns = 2
	right_deck_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_deck_grid)
	
	var save_btn = Button.new()
	save_btn.text = "Save & Return to Hub"
	save_btn.custom_minimum_size = Vector2(0, 60)
	save_btn.add_theme_font_size_override("font_size", 24)
	save_btn.connect("pressed", Callable(self, "_on_back_pressed"))
	right_vbox.add_child(save_btn)

func _on_profile_selected(index: int):
	# Save current deck before switching
	_save_current_profile_to_state()
	GameState.editing_profile = profile_dropdown.get_item_text(index)
	load_profile(GameState.editing_profile)

func load_profile(profile_name: String):
	deck_commander = null
	deck_units.clear()
	var saved_deck = GameState.player_decks[profile_name]
	for c_name in saved_deck:
		var res = load("res://Data/Cards/" + c_name + ".tres")
		if res:
			if res.card_type == "Commander":
				deck_commander = res
			else:
				deck_units.append(res)
				
	_on_tab_changed(current_tab) # refresh collection to apply P1 restrictions
	refresh_ui()

func _on_tab_changed(tab_idx: int):
	current_tab = tab_idx
	
	var faction_names = ["Dominion of Sol", "The Void Swarm", "The Rimworlders", "Pirate Kingdoms", "The Reach"]
	if tab_idx >= 0 and tab_idx < faction_names.size():
		if title_label: title_label.text = faction_names[tab_idx] + " - Army Gathering"
	
	if bg and trim_top and trim_bot:
		if tab_idx == 0: # Dominion
			bg.color = Color(0.05, 0.2, 0.4)
			trim_top.color = Color(0.8, 0.7, 0.2)
			trim_bot.color = Color(0.8, 0.7, 0.2)
		elif tab_idx == 1: # Void
			bg.color = Color(0.15, 0.0, 0.3)
			trim_top.color = Color(0.8, 0.1, 0.9)
			trim_bot.color = Color(0.8, 0.1, 0.9)
		elif tab_idx == 2: # Rimworlders
			bg.color = Color(0.1, 0.3, 0.1)
			trim_top.color = Color(0.2, 0.9, 0.4)
			trim_bot.color = Color(0.2, 0.9, 0.4)
		elif tab_idx == 3: # Pirates
			bg.color = Color(0.3, 0.15, 0.05)
			trim_top.color = Color(0.9, 0.4, 0.1)
			trim_bot.color = Color(0.9, 0.4, 0.1)
		elif tab_idx == 4: # Reach
			bg.color = Color(0.05, 0.15, 0.2)
			trim_top.color = Color(0.1, 0.8, 0.9)
			trim_bot.color = Color(0.1, 0.8, 0.9)
			
	for c in left_grid.get_children():
		left_grid.remove_child(c)
		c.queue_free()
		
	# Determine if we need to restrict cards based on P1
	var restricted_card_names = []
	if GameState.editing_profile != "Player1":
		restricted_card_names = GameState.player_decks["Player1"]
		

	for card_data in all_cards:
		var is_void = "Void" in card_data.card_name
		var is_rimworlder = "Rimworlder" in card_data.card_name or "Sky" in card_data.card_name or "Stone" in card_data.card_name or "Giant" in card_data.card_name or "Great" in card_data.card_name
		var is_pirate = "Scrap" in card_data.card_name
		var is_reach = "Reach" in card_data.card_name
		var is_dominion = not is_void and not is_rimworlder and not is_pirate and not is_reach
		
		if (tab_idx == 0 and is_dominion) or (tab_idx == 1 and is_void) or (tab_idx == 2 and is_rimworlder) or (tab_idx == 3 and is_pirate) or (tab_idx == 4 and is_reach):

			# If this is a Guest profile, block cards that Player1 is using
			var raw_name = card_data.card_name.replace(" ", "") + "Card"
			if restricted_card_names.has(raw_name):
				continue # Skip adding this card to the Guest's collection grid!
				
			var c = card_ui_scene.instantiate()
			c.card_data = card_data
			c.connect("card_clicked", Callable(self, "_on_collection_card_clicked"))
			left_grid.add_child(c)

func _on_collection_card_clicked(card_ui):
	var data = card_ui.card_data
	if data.card_type == "Commander":
		deck_commander = data
	else:
		if deck_units.size() < 5 and not deck_units.has(data):
			deck_units.append(data)
	refresh_ui()

func _on_deck_card_clicked(card_ui):
	var data = card_ui.card_data
	if data.card_type == "Commander":
		deck_commander = null
	else:
		deck_units.erase(data)
	refresh_ui()

func refresh_ui():
	for c in right_commander_slot.get_children():
		right_commander_slot.remove_child(c)
		c.queue_free()
	for c in right_deck_grid.get_children():
		right_deck_grid.remove_child(c)
		c.queue_free()
		
	if deck_commander:
		var c = card_ui_scene.instantiate()
		c.card_data = deck_commander
		c.connect("card_clicked", Callable(self, "_on_deck_card_clicked"))
		right_commander_slot.add_child(c)
		
	for u in deck_units:
		var c = card_ui_scene.instantiate()
		c.card_data = u
		c.connect("card_clicked", Callable(self, "_on_deck_card_clicked"))
		right_deck_grid.add_child(c)
		
	count_label.text = "Units, Spells, Vehicles (" + str(deck_units.size()) + "/5)"

func _save_current_profile_to_state():
	var new_deck = []
	if deck_commander:
		new_deck.append(deck_commander.card_name.replace(" ", "") + "Card")
	for u in deck_units:
		new_deck.append(u.card_name.replace(" ", "") + "Card")
	GameState.player_decks[GameState.editing_profile] = new_deck
	GameState.save_decks()

func _on_back_pressed():
	if deck_commander == null or deck_units.size() < 5:
		print("Cannot save! You must have exactly 1 Commander and 5 Units/Spells.")
		count_label.text = "ERROR: Need 1 Cmdr and 5 Units!"
		return
		
	_save_current_profile_to_state()
	
	if GameState.current_mode == "ONLINE_HOST" or GameState.current_mode == "ONLINE_JOIN":
		get_tree().change_scene_to_file("res://Scenes/MultiplayerMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ModeHub.tscn")
