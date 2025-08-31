extends Node
## Sistema de Habilidades Especiais - Sprint 5
## Framework para habilidades com cooldowns, mana e combos

signal ability_used(ability_name, cooldown)
signal ability_ready(ability_name)
signal mana_changed(current_mana, max_mana)
signal combo_performed(combo_name)

# Referência ao player
@onready var player: CharacterBody3D = get_parent()

# Sistema de energia/mana
var max_mana: float = 100.0
var current_mana: float = 100.0
var mana_regen_rate: float = 15.0  # Por segundo
var mana_regen_delay: float = 2.0   # Delay após usar habilidade
var mana_regen_timer: float = 0.0

# Habilidades disponíveis
var abilities: Dictionary = {}
var ability_queue: Array[String] = []  # Input buffering

# Sistema de combo
var last_ability_time: float = 0.0
var combo_window: float = 1.5
var current_combo: Array[String] = []

func _ready():
	print("⚔️ Ability System initialized - Sprint 5")
	
	# Register default abilities
	register_default_abilities()
	
	print("✨ Abilities registered: ", abilities.keys())

func _process(delta):
	"""Update ability system"""
	update_mana_regen(delta)
	update_ability_cooldowns(delta)
	process_ability_queue()
	update_combo_system(delta)
	handle_ability_input()

func register_default_abilities():
	"""Register Sprint 5 special abilities"""
	
	# Ability 1: Area Slam (AOE damage)
	register_ability("area_slam", {
		"name": "Divine Slam",
		"description": "AOE divine energy slam",
		"mana_cost": 25.0,
		"cooldown": 4.0,
		"damage": 40.0,
		"radius": 4.0,
		"input_action": "ability_1"
	})
	
	# Ability 2: Projectile Shot (ranged attack)
	register_ability("projectile_shot", {
		"name": "Sacred Bolt",
		"description": "Fires divine energy projectile",
		"mana_cost": 20.0,
		"cooldown": 3.0,
		"damage": 35.0,
		"range": 12.0,
		"input_action": "ability_2"
	})
	
	# Ability 3: Shield Block (damage reduction)
	register_ability("shield_block", {
		"name": "Divine Ward",
		"description": "Temporary damage reduction shield",
		"mana_cost": 30.0,
		"cooldown": 6.0,
		"damage_reduction": 0.5,  # 50% reduction
		"duration": 3.0,
		"input_action": "ability_3"
	})

func register_ability(ability_id: String, config: Dictionary):
	"""Register a new ability"""
	var ability = {
		"id": ability_id,
		"name": config.get("name", "Unknown"),
		"description": config.get("description", ""),
		"mana_cost": config.get("mana_cost", 0.0),
		"cooldown": config.get("cooldown", 1.0),
		"damage": config.get("damage", 0.0),
		"current_cooldown": 0.0,
		"input_action": config.get("input_action", ""),
		"config": config
	}
	
	abilities[ability_id] = ability
	print("📋 Registered ability: ", ability.name)

func update_mana_regen(delta):
	"""Update mana regeneration"""
	if mana_regen_timer > 0:
		mana_regen_timer -= delta
		return
	
	if current_mana < max_mana:
		var old_mana = current_mana
		current_mana = min(max_mana, current_mana + mana_regen_rate * delta)
		
		if old_mana != current_mana:
			mana_changed.emit(current_mana, max_mana)

func update_ability_cooldowns(delta):
	"""Update all ability cooldowns"""
	for ability_id in abilities:
		var ability = abilities[ability_id]
		if ability.current_cooldown > 0:
			ability.current_cooldown -= delta
			if ability.current_cooldown <= 0:
				ability.current_cooldown = 0
				ability_ready.emit(ability_id)

func handle_ability_input():
	"""Handle ability input with buffering"""
	for ability_id in abilities:
		var ability = abilities[ability_id]
		var input_action = ability.input_action
		
		if input_action != "" and Input.is_action_just_pressed(input_action):
			queue_ability(ability_id)

func queue_ability(ability_id: String):
	"""Queue ability for execution (input buffering)"""
	if ability_id in abilities:
		ability_queue.append(ability_id)
		print("📝 Ability queued: ", abilities[ability_id].name)

func process_ability_queue():
	"""Process queued abilities"""
	if ability_queue.is_empty():
		return
	
	var ability_id = ability_queue[0]
	if can_use_ability(ability_id):
		ability_queue.pop_front()
		use_ability(ability_id)
	elif abilities[ability_id].current_cooldown > 0:
		# Remove from queue if on cooldown
		ability_queue.pop_front()
		print("⏰ Ability on cooldown: ", abilities[ability_id].name)

func can_use_ability(ability_id: String) -> bool:
	"""Check if ability can be used"""
	if not ability_id in abilities:
		return false
	
	var ability = abilities[ability_id]
	return (ability.current_cooldown <= 0 and 
			current_mana >= ability.mana_cost and
			player.current_health > 0)

func use_ability(ability_id: String):
	"""Execute ability"""
	if not can_use_ability(ability_id):
		return false
	
	var ability = abilities[ability_id]
	
	# Consume mana
	current_mana = max(0, current_mana - ability.mana_cost)
	mana_changed.emit(current_mana, max_mana)
	
	# Start cooldown
	ability.current_cooldown = ability.cooldown
	
	# Reset mana regen
	mana_regen_timer = mana_regen_delay
	
	# Add to combo tracking
	add_to_combo(ability_id)
	
	# Execute specific ability
	execute_ability_effect(ability_id, ability)
	
	# Emit signals
	ability_used.emit(ability_id, ability.cooldown)
	
	print("⚡ Used ability: ", ability.name, " (Mana: ", current_mana, "/", max_mana, ")")
	return true

func execute_ability_effect(ability_id: String, ability: Dictionary):
	"""Execute the actual ability effect"""
	match ability_id:
		"area_slam":
			perform_area_slam(ability)
		"projectile_shot":
			perform_projectile_shot(ability)
		"shield_block":
			perform_shield_block(ability)
		_:
			print("⚠️ Unknown ability: ", ability_id)

func perform_area_slam(ability: Dictionary):
	"""Area Slam: AOE divine damage"""
	print("💥 Divine Slam activated!")
	
	# Create AOE area
	var slam_area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = ability.config.radius
	collision.shape = shape
	slam_area.add_child(collision)
	
	# Position at player location
	slam_area.global_position = player.global_position
	get_tree().current_scene.add_child(slam_area)
	
	# Connect to detect enemies
	slam_area.body_entered.connect(_on_slam_hit)
	
	# Visual effect
	create_slam_vfx(ability.config.radius)
	
	# Store damage for callback
	slam_area.set_meta("damage", ability.damage)
	
	# Remove area after brief duration
	await get_tree().create_timer(0.3).timeout
	if slam_area and is_instance_valid(slam_area):
		slam_area.queue_free()

func _on_slam_hit(body):
	"""Handle area slam hits"""
	if body.is_in_group("enemies"):
		var area = body.get_parent() if body.get_parent().has_meta("damage") else null
		var damage = area.get_meta("damage") if area else 40.0
		
		if body.has_method("take_damage"):
			body.take_damage(damage, player)
			print("💥 Area Slam hit ", body.name, " for ", damage, " damage!")

func perform_projectile_shot(ability: Dictionary):
	"""Projectile Shot: Ranged divine bolt"""
	print("🔮 Sacred Bolt fired!")
	
	# Create projectile
	var projectile = preload("res://scripts/enemies/Projectile.gd").new()
	var projectile_body = RigidBody3D.new()
	projectile_body.set_script(projectile)
	
	# Setup projectile visual
	var mesh_inst = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	mesh_inst.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GOLD
	material.emission_enabled = true
	material.emission = Color.YELLOW
	mesh_inst.material_override = material
	
	projectile_body.add_child(mesh_inst)
	
	# Setup collision
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.2
	collision.shape = shape
	projectile_body.add_child(collision)
	
	# Position and launch
	projectile_body.global_position = player.global_position + Vector3.UP * 1.5
	
	# Get direction (toward mouse cursor or forward)
	var direction = get_projectile_direction()
	projectile_body.velocity = direction * 15.0  # Fast projectile
	
	# Set damage
	projectile_body.set_damage(ability.damage)
	
	get_tree().current_scene.add_child(projectile_body)

func get_projectile_direction() -> Vector3:
	"""Get direction for projectile (toward mouse or forward)"""
	# For now, shoot forward. Could be enhanced with mouse targeting
	return -player.transform.basis.z

func perform_shield_block(ability: Dictionary):
	"""Shield Block: Temporary damage reduction"""
	print("🛡️ Divine Ward activated!")
	
	# Apply shield effect to player
	if player.has_method("apply_shield"):
		player.apply_shield(ability.config.damage_reduction, ability.config.duration)
	else:
		# Fallback: create temporary shield effect
		create_shield_effect(ability.config.damage_reduction, ability.config.duration)
	
	# Visual feedback
	create_shield_vfx(ability.config.duration)

func create_shield_effect(damage_reduction: float, duration: float):
	"""Create temporary shield effect"""
	# This would integrate with the player's damage system
	# For now, just print the effect
	print("🛡️ Shield active: ", damage_reduction * 100, "% damage reduction for ", duration, "s")
	
	# TODO: Integrate with player's take_damage method

func create_slam_vfx(radius: float):
	"""Create area slam visual effects"""
	print("💥 Slam VFX - Radius: ", radius)
	# TODO: Add particle effects, ground crack decals, etc.

func create_shield_vfx(duration: float):
	"""Create shield visual effects"""
	print("🛡️ Shield VFX - Duration: ", duration)
	# TODO: Add glowing shield around player

func update_combo_system(delta):
	"""Update combo tracking"""
	if last_ability_time > 0:
		last_ability_time -= delta
		if last_ability_time <= 0:
			if current_combo.size() > 1:
				check_combo_completion()
			current_combo.clear()

func add_to_combo(ability_id: String):
	"""Add ability to current combo"""
	current_combo.append(ability_id)
	last_ability_time = combo_window
	
	# Check for immediate combo triggers
	check_combo_completion()

func check_combo_completion():
	"""Check if current combo matches any known combos"""
	var combo_string = "-".join(current_combo)
	
	# Define combo patterns
	var known_combos = {
		"area_slam-projectile_shot": "Divine Devastation",
		"shield_block-area_slam": "Protected Slam",
		"projectile_shot-area_slam-shield_block": "Trinity Combo"
	}
	
	if combo_string in known_combos:
		var combo_name = known_combos[combo_string]
		combo_performed.emit(combo_name)
		print("🔥 COMBO: ", combo_name, " - ", combo_string)

func get_ability_info(ability_id: String) -> Dictionary:
	"""Get ability information for UI"""
	if not ability_id in abilities:
		return {}
	
	var ability = abilities[ability_id]
	return {
		"name": ability.name,
		"description": ability.description,
		"mana_cost": ability.mana_cost,
		"cooldown": ability.cooldown,
		"current_cooldown": ability.current_cooldown,
		"ready": can_use_ability(ability_id)
	}

func get_mana_info() -> Dictionary:
	"""Get mana information for UI"""
	return {
		"current": current_mana,
		"max": max_mana,
		"percentage": current_mana / max_mana,
		"regenerating": mana_regen_timer <= 0
	}