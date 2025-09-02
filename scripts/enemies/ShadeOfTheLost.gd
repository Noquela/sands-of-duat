extends "res://scripts/enemies/BaseEnemy.gd"
class_name ShadeOfTheLost

func _ready():
	# Configure stats for Shade of the Lost
	max_health = 100.0
	move_speed = 3.0
	attack_damage = 20.0
	attack_range = 2.0
	attack_cooldown = 1.2
	detection_radius = 8.0
	attack_telegraph_time = 0.5
	
	# Call parent setup
	super._ready()
	
	# Set name for debugging
	name = "ShadeOfTheLost"

func perform_attack():
	# Shade has a quick melee swipe attack
	print("Shade performs soul swipe attack!")
	
	# Call parent attack logic
	super.perform_attack()
	
	# Add soul swipe visual effect here later
	spawn_soul_swipe_effect()

func spawn_soul_swipe_effect():
	# Create dark energy swipe effect
	# This will be enhanced with proper VFX later
	print("Dark energy swirls around the Shade's claws")