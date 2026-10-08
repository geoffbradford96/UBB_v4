with open('d:/Game Dev/UBB_v2/Scripts/Hero.gd', 'r') as f:
    text = f.read()

text = text.replace('speed * 1.5', 'SPEED * 1.5')
text = text.replace('speed * 0.5', 'SPEED * 0.5')

with open('d:/Game Dev/UBB_v2/Scripts/Hero.gd', 'w') as f:
    f.write(text)
