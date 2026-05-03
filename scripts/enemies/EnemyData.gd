class_name EnemyData
extends Resource

enum AttackType { MELEE, RANGED, CHARGE }

@export var id:                  StringName  = &""
@export var display_name:        String      = "Enemy"
@export var max_health:          float       = 30.0
@export var move_speed:          float       = 3.5
@export var attack_type:         AttackType  = AttackType.MELEE
@export var attack_damage:       float       = 8.0
@export var attack_range:        float       = 1.8   # trigger range for WINDUP
@export var attack_duration:     float       = 0.22  # hitbox-active / charge time
@export var attack_cooldown:     float       = 1.2   # RECOVERING duration
@export var windup_duration:     float       = 0.38  # telegraph before ATTACK
@export var preferred_range:     float       = 6.0   # ranged enemy stand-off distance
@export var charge_speed:        float       = 13.0  # CHARGE-type burst speed
@export var detection_range:     float       = 12.0
@export var lose_interest_range: float       = 20.0
@export var knockback_force:     float       = 3.5
@export var xp_reward:           int         = 10
@export var power_level:         int         = 1
@export var mesh_color:          Color       = Color(0.7, 0.2, 0.2)
@export var projectile_scene:    PackedScene              # ranged only
@export var loot_table:          LootTable                # optional — nil = no drop
