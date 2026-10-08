with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    text = f.read()

# Let's fix the tab vs space issue for the appended functions.
# The original file used spaces. 
import re

# We will just split off the functions we appended, and replace tabs with 4 spaces in them.
parts = text.split('func _get_team_faction(team: String) -> String:')
if len(parts) > 1:
    fixed_funcs = 'func _get_team_faction(team: String) -> String:' + parts[1]
    fixed_funcs = fixed_funcs.replace('\t', '    ')
    text = parts[0] + fixed_funcs
    
with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(text)
