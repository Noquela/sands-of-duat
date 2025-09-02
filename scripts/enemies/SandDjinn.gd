extends "res://scripts/enemies/BaseEnemy.gd"
class_name SandDjinn

func _ready():
	# Configure stats for Sand Djinn
	max_health = 120.0
	move_speed = 4.0  # Fast and agile
	attack_damage = 25.0
	attack_range = 4.0  # Magic projectile range
	attack_cooldown = 1.8
	detection_radius = 9.0
	attack_telegraph_time = 0.6
	
	# Call parent setup
	super._ready()
	
	# Set name for debugging
	name = "SandDjinn"

func perform_attack():
	# Sand Djinn casts a sand magic projectile
	print("Sand Djinn conjures desert magic!")
	
	# Cast sand magic projectile
	cast_sand_magic()

func cast_sand_magic():
	if not player_target or not is_instance_valid(player_target):
		return
	
	# Calculate direction to player
	var attack_origin = global_position + Vector3(0, 2, 0)
	var direction = (player_target.global_position + Vector3(0, 1, 0) - attack_origin).normalized()
	
	# Create magic projectile (modified arrow for now)
	var ArrowScene = preload("res://scenes/combat/Arrow.tscn")
	var magic_orb = ArrowScene.instantiate()
	
	get_tree().current_scene.add_child(magic_orb)
	magic_orb.global_position = attack_origin
	magic_orb.setup(direction, attack_damage, self)
	
	# Make it look more magical (yellow/orange color)
	var mesh_instance = magic_orb.get_node("ArrowMesh")
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)  # Golden sand color
		material.emission_enabled = true
		material.emission = Color(1.0, 0.6, 0.0, 1.0)
		mesh_instance.material_override = material
	
	print("Sand Djinn cast sand magic for ", attack_damage, " damage")
	
	# Start cooldown
	can_attack = false
	get_tree().create_timer(attack_cooldown).timeout.connect(_on_attack_cooldown_finished)

func handle_chase_state(delta):
	# Sand Djinn moves more erratically
	super.handle_chase_state(delta)
	
	# Add slight floating/hovering movement
	if player_target and is_instance_valid(player_target):
		# Add some vertical bob for magical floating effect
		var bob = sin(Engine.get_process_frames() * 0.1) * 0.3
		global_position.y += bob * delta