with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

old_eval = '''	var affordable = []
	for c in hand:
		if current_requisition >= c.cost:
			if c.card_type == "Commander" and has_commander:
				continue
			affordable.append(c)
			
	if affordable.is_empty():
		return
		
	var card_to_play = affordable.pick_random()
	
	var spawn_pos = calculate_optimal_spawn(card_to_play)
	if spawn_pos != null:
		play_card(card_to_play, spawn_pos)'''

new_eval = '''	var valid_hand = []
	for c in hand:
		if c.card_type == "Commander" and has_commander: continue
		valid_hand.append(c)
		
	if valid_hand.is_empty(): return
	
	valid_hand.sort_custom(func(a, b): return a.cost > b.cost)
	
	for c in valid_hand:
		if current_requisition >= c.cost:
			if c == valid_hand[0] or randf() > 0.5:
				var spawn_pos = calculate_optimal_spawn(c)
				if spawn_pos != null:
					play_card(c, spawn_pos)
				return'''

text = text.replace(old_eval, new_eval)

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)

print("Updated BotAI evaluation logic")
