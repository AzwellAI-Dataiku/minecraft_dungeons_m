class_name MissionData
extends Resource

## A pickable mission shown in the camp's mission board.
## Difficulty 1/2/3 = I/II/III in MCD parlance.

@export var id:                StringName  = &""
@export var display_name:      String      = "Mission"
@export var description:       String      = ""
@export var difficulty:        int         = 1
@export var recommended_pl:    int         = 5
@export var theme:             StringName  = &"crypt"   # &"crypt" or &"desert"
@export var room_count:        int         = 8
@export var seed_offset:       int         = 0
@export var emerald_reward:    int         = 30
@export var xp_reward:         int         = 100

func get_difficulty_label() -> String:
	match difficulty:
		1: return "I"
		2: return "II"
		3: return "III"
	return "?"

func get_difficulty_color() -> Color:
	match difficulty:
		1: return Color(0.6, 1.0, 0.6)
		2: return Color(1.0, 0.85, 0.4)
		3: return Color(1.0, 0.4, 0.4)
	return Color.WHITE
