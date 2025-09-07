# AbilitySystem.gd
# Special Abilities Framework for Sands of Duat
# Sprint 5: Dash + Special Abilities System
# Implements cooldown system, mana/energy, and input buffering

extends Node
class_name AbilitySystem

signal ability_used(ability_name: String, cooldown_duration: float)
signal ability_ready(ability_name: String)
signal energy_changed(current: float, max: float)

# Energy system
var max_energy: float = 100.0
var current_energy: float = 100.0
var energy_regen_rate: float = 15.0  # Energy per second

# Ability definitions
var abilities: Dictionary = {}
var ability_cooldowns: Dictionary = {}

# Input buffering
var input_buffer: Array = []
var buffer_window: float = 0.2  # Buffer window in seconds

func _ready():
	print("⚡ AbilitySystem initialized - Special abilities ready")
	_setup_default_abilities()
	set_process(true)

func _process(delta):
	# Update energy regeneration
	_regenerate_energy(delta)
	
	# Update ability cooldowns
	_update_cooldowns(delta)
	
	# Process input buffer
	_process_input_buffer(delta)

func _setup_default_abilities():
	"""Setup the 3 core special abilities from Sprint 5"""
	
	# 1. Area Slam (AOE damage)
	register_ability("area_slam", {
		"energy_cost": 30.0,
		"cooldown": 8.0,
		"damage": 80.0,
		"radius": 4.0,
		"description": "Slam ground with divine power, damaging all nearby enemies"
	})
	
	# 2. Projectile Shot (ranged attack) 
	register_ability("divine_projectile", {
		"energy_cost": 20.0,
		"cooldown": 5.0,
		"damage": 60.0,
		"speed": 15.0,
		"range": 12.0,
		"description": "Launch ankh-shaped projectile of divine energy"
	})
	
	# 3. Shield Block (damage reduction)
	register_ability("divine_shield", {
		"energy_cost": 25.0,
		"cooldown": 12.0,
		"duration": 4.0,
		"damage_reduction": 0.7,
		"description": "Channel divine protection, reducing incoming damage"
	})
	
	print("🔮 Loaded 3 special abilities: Area Slam, Divine Projectile, Divine Shield")

func register_ability(ability_name: String, ability_data: Dictionary):
	"""Register a new ability with the system"""
	abilities[ability_name] = ability_data
	ability_cooldowns[ability_name] = 0.0

func can_use_ability(ability_name: String) -> bool:
	"""Check if ability can be used (cooldown + energy)"""
	if not abilities.has(ability_name):
		return false
	
	var ability = abilities[ability_name]
	var on_cooldown = ability_cooldowns[ability_name] > 0.0
	var has_energy = current_energy >= ability.get("energy_cost", 0.0)
	
	return not on_cooldown and has_energy

func use_ability(ability_name: String, caster: Node = null) -> bool:
	"""Attempt to use an ability"""
	if not can_use_ability(ability_name):
		print("❌ Cannot use ability: %s (cooldown or energy)" % ability_name)
		return false
	
	var ability = abilities[ability_name]
	
	# Consume energy
	var energy_cost = ability.get("energy_cost", 0.0)
	current_energy -= energy_cost
	current_energy = max(0.0, current_energy)
	
	# Start cooldown
	var cooldown = ability.get("cooldown", 0.0)
	ability_cooldowns[ability_name] = cooldown
	
	# Execute ability effect
	_execute_ability(ability_name, ability, caster)
	
	# Emit signals
	ability_used.emit(ability_name, cooldown)
	energy_changed.emit(current_energy, max_energy)
	
	print("⚡ Used ability: %s (Energy: %.1f/%.1f)" % [ability_name, current_energy, max_energy])
	return true

func _execute_ability(ability_name: String, ability_data: Dictionary, caster: Node):
	"""Execute the actual ability effect"""
	match ability_name:
		"area_slam":
			_execute_area_slam(ability_data, caster)
		"divine_projectile":
			_execute_divine_projectile(ability_data, caster)
		"divine_shield":
			_execute_divine_shield(ability_data, caster)
		_:
			print("⚠️ Unknown ability: %s" % ability_name)

func _execute_area_slam(ability: Dictionary, caster: Node):
	"""Execute Area Slam ability"""
	if not caster:
		return
	
	var damage = ability.get("damage", 80.0)
	var radius = ability.get("radius", 4.0)
	
	print("💥 AREA SLAM! Damage: %.1f, Radius: %.1f" % [damage, radius])
	
	# Find all enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	var slam_position = caster.global_position
	
	var hit_count = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = slam_position.distance_to(enemy.global_position)
			if distance <= radius:
				# Apply damage
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, "area_slam")
					hit_count += 1
	
	# Visual/audio feedback would go here
	_create_area_slam_effect(slam_position, radius)
	
	print("⚔️ Area Slam hit %d enemies" % hit_count)

func _execute_divine_projectile(ability: Dictionary, caster: Node):
	"""Execute Divine Projectile ability"""
	if not caster:
		return
	
	# Get mouse position for targeting
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	
	if not camera:
		print("⚠️ No camera found for projectile targeting")
		return
	
	# Calculate direction from player to mouse position
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	# Create projectile
	var projectile_scene = preload("res://scenes/effects/DivineProjectile.tscn")
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		
		# Set projectile properties
		projectile.global_position = caster.global_position + Vector3(0, 1, 0)
		projectile.setup_projectile(to - from, ability.get("damage", 60.0), ability.get("speed", 15.0))
		
		print("🏺 Divine projectile launched!")
	else:
		print("⚠️ Divine projectile scene not found - using fallback")
		_create_fallback_projectile(caster, to - from, ability)

func _execute_divine_shield(ability: Dictionary, caster: Node):
	"""Execute Divine Shield ability"""
	if not caster:
		return
	
	var duration = ability.get("duration", 4.0)
	var damage_reduction = ability.get("damage_reduction", 0.7)
	
	print("🛡️ DIVINE SHIELD! Reduction: %.0f%%, Duration: %.1fs" % [damage_reduction * 100, duration])
	
	# Apply shield effect to caster
	if caster.has_method("apply_shield"):
		caster.apply_shield(damage_reduction, duration)
	else:
		# Fallback - apply to health system if available
		var health_system = caster.get_node_or_null("HealthSystem")
		if health_system and health_system.has_method("apply_damage_reduction"):
			health_system.apply_damage_reduction(damage_reduction, duration)
	
	# Visual effect
	_create_shield_effect(caster, duration)

func buffer_ability_input(ability_name: String, timestamp: float):
	"""Add ability input to buffer for combo system"""
	input_buffer.append({
		"ability": ability_name,
		"timestamp": timestamp
	})
	
	# Limit buffer size
	if input_buffer.size() > 5:
		input_buffer.pop_front()

func _process_input_buffer(_delta: float):
	"""Process buffered inputs and execute valid combos"""
	var current_time = Time.get_unix_time_from_system()
	
	# Remove expired inputs
	input_buffer = input_buffer.filter(func(input): return current_time - input.timestamp <= buffer_window)

func _regenerate_energy(delta: float):
	"""Regenerate energy over time"""
	if current_energy < max_energy:
		current_energy += energy_regen_rate * delta
		current_energy = min(max_energy, current_energy)
		energy_changed.emit(current_energy, max_energy)

func _update_cooldowns(delta: float):
	"""Update ability cooldowns"""
	for ability_name in ability_cooldowns.keys():
		if ability_cooldowns[ability_name] > 0.0:
			ability_cooldowns[ability_name] -= delta
			
			# Emit ready signal when cooldown finishes
			if ability_cooldowns[ability_name] <= 0.0:
				ability_cooldowns[ability_name] = 0.0
				ability_ready.emit(ability_name)

func get_ability_cooldown(ability_name: String) -> float:
	"""Get current cooldown for ability"""
	return ability_cooldowns.get(ability_name, 0.0)

func get_energy_percentage() -> float:
	"""Get energy as percentage (0.0 to 1.0)"""
	return current_energy / max_energy if max_energy > 0 else 0.0

# Visual effect helpers (placeholder implementations)
func _create_area_slam_effect(position: Vector3, radius: float):
	"""Create visual effect for area slam"""
	# TODO: Create proper particle effect
	print("💥 Creating area slam effect at %s with radius %.1f" % [position, radius])

func _create_fallback_projectile(caster: Node, direction: Vector3, ability: Dictionary):
	"""Fallback projectile when scene is not available"""
	print("🏺 Fallback projectile: damage %.1f in direction %s" % [ability.get("damage", 60.0), direction.normalized()])
	
	# Simple raycast projectile as fallback
	var space_state = caster.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		caster.global_position + Vector3(0, 1, 0),
		caster.global_position + direction.normalized() * ability.get("range", 12.0)
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		var hit_body = result.get("collider")
		if hit_body and hit_body.is_in_group("enemies"):
			if hit_body.has_method("take_damage"):
				hit_body.take_damage(ability.get("damage", 60.0), "divine_projectile")
				print("🎯 Projectile hit %s!" % hit_body.name)

func _create_shield_effect(caster: Node, duration: float):
	"""Create visual effect for shield"""
	# TODO: Create proper shield particle effect
	print("🛡️ Creating shield effect on %s for %.1fs" % [caster.name, duration])