extends "res://scripts/enemies/BaseEnemy.gd"
class_name MummyArcher

func _ready():
	# Configure stats for Mummy Archer
	max_health = 80.0
	move_speed = 2.0
	attack_damage = 15.0
	attack_range = 6.0  # Ranged attack
	attack_cooldown = 2.0
	detection_radius = 10.0  # Better sight for archer
	attack_telegraph_time = 0.8  # Longer telegraph for bow
	
	# Call parent setup
	super._ready()
	
	# Set name for debugging
	name = "MummyArcher"

func perform_attack():
	# Mummy Archer fires an ancient arrow
	print("Mummy Archer draws bow and fires!")
	
	# Fire projectile instead of melee attack
	fire_ancient_arrow()

func fire_ancient_arrow():
	if not player_target or not is_instance_valid(player_target):
		return
	
	# Calculate direction to player
	var attack_origin = global_position + Vector3(0, 1.5, 0)
	var direction = (player_target.global_position + Vector3(0, 1, 0) - attack_origin).normalized()
	
	# Create arrow projectile (reuse the existing Arrow scene)
	var ArrowScene = preload("res://scenes/combat/Arrow.tscn")
	var arrow = ArrowScene.instantiate()
	
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = attack_origin
	arrow.setup(direction, attack_damage, self)
	
	print("Mummy fired ancient arrow for ", attack_damage, " damage")
	
	# Start cooldown
	can_attack = false
	get_tree().create_timer(attack_cooldown).timeout.connect(_on_attack_cooldown_finished)