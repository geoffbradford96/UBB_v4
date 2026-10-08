import sys

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'r') as f:
    lines = f.readlines()
    
out = []
in_ready = True
for i, line in enumerate(lines):
    if line.strip().startswith('var intro_canvas = CanvasLayer.new()'):
        in_ready = False
        out.append(line)
        continue
        
    if not in_ready:
        out.append(line)
        
prefix = """extends Node

# --- UI Connection ---
@onready var ui = $InGameUI

# --- Economy System ---
var max_requisition: float = 10.0
var current_requisition: float = 0.0
var requisition_rate: float = 1.0

var koth_timer: Timer
var koth_points = {"SideA": 0, "SideB": 0, "SideC": 0, "SideD": 0}

func _ready():
\tvar teams = ["SideA", "SideB", "SideC", "SideD"]
\tvar total_players = GameState.match_player_count
\t
\tif GameState.current_mode == "AI_VS_AI":
\t\tif ui: ui.visible = false
\t\tfor i in range(total_players):
\t\t\tvar bot = BotAI.new()
\t\t\tbot.my_team = teams[i]
\t\t\tbot.enemy_team = "Targetable"
\t\t\tadd_child(bot)
\t\t\t
\telif GameState.current_mode == "LOCAL":
\t\tfor i in range(1, total_players):
\t\t\tvar bot = BotAI.new()
\t\t\tbot.my_team = teams[i]
\t\t\tbot.enemy_team = "Targetable"
\t\t\tadd_child(bot)
\t\t\t
\tif GameState.game_mode == "KOTH":
\t\tkoth_timer = Timer.new()
\t\tkoth_timer.wait_time = 1.0
\t\tkoth_timer.autostart = true
\t\tkoth_timer.connect("timeout", Callable(self, "_on_koth_tick"))
\t\tadd_child(koth_timer)

\t# Dynamic Intro Countdown
"""

with open('d:/Game Dev/UBB_v2/Scripts/ArenaManager.gd', 'w') as f:
    f.write(prefix + "".join(out))
