with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'r') as f:
    text = f.read()

text = text.replace('var is_rimworlder = "Rimworlder" in clean_name or "Sky" in clean_name or "Stone" in clean_name or "Giant" in clean_name', 'var is_rimworlder = "Rimworlder" in clean_name or "Sky" in clean_name or "Stone" in clean_name or "Giant" in clean_name or "GreatBeastSpeaker" in clean_name')

with open('d:/Game Dev/UBB_v2/Scripts/BotAI.gd', 'w') as f:
    f.write(text)

with open('d:/Game Dev/UBB_v2/Scripts/ArmyGathering.gd', 'r') as f:
    text2 = f.read()
    
text2 = text2.replace('var is_rimworlder = "Rimworlder" in card_data.card_name or "Sky" in card_data.card_name or "Stone" in card_data.card_name or "Giant" in card_data.card_name', 'var is_rimworlder = "Rimworlder" in card_data.card_name or "Sky" in card_data.card_name or "Stone" in card_data.card_name or "Giant" in card_data.card_name or "Great" in card_data.card_name')

with open('d:/Game Dev/UBB_v2/Scripts/ArmyGathering.gd', 'w') as f:
    f.write(text2)
