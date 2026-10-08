with open('d:/Game Dev/UBB_v2/gen_pirates.gd', 'r') as f:
    text = f.read()

text = text.replace('card.card_icon = itex', 'card.card_art = itex\n        card.spawn_count = u["squad"]')

with open('d:/Game Dev/UBB_v2/gen_pirates.gd', 'w') as f:
    f.write(text)
