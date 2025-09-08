# Player3D.gd
# 3D Isometric Player Controller for Sands of Duat
# Khenti - Egyptian Prince Protagonist
# Sprint 5: Player Controller + Special Abilities

extends CharacterBody3D

# Preload ability system class
const AbilitySystem = preload("res://scripts/systems/AbilitySystem.gd")

# Movement specs from roadmap
const SPEED = 5.0
const GRAVITY = 20.0

# Input handling
var input_vector: Vector2
var movement_vector: Vector3

# References
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_system: Node = $HealthSystem

# System references
var combat_system: Node
var dash_system: Node
var ability_system: AbilitySystem
var status_effect_system: Node
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

# Combat feedback system
var screen_shake_strength: float = 0.0
var screen_shake_duration: float = 0.0
var hit_freeze_duration: float = 0.0
var hit_freeze_timer: float = 0.0

# Shield system (for Divine Shield ability)
var shield_active: bool = false
var shield_damage_reduction: float = 0.0
var shield_duration: float = 0.0

func _ready():
	print("⚔️ Khenti awakens in the Duat...")
	print("🎮 Player Controller: Sprint 4 - Dash System Ready")
	
	# Add to player group for combat system to find
	add_to_group("player")
	
	# Get system references
	combat_system = get_node("/root/CombatSystem")
	if not combat_system:
		print("⚠️ Combat system not found!")
	
	dash_system = get_node("/root/DashSystem")
	if not dash_system:
		print("⚠️ Dash system not found!")
	else:
		print("🏃 Dash system connected")
	
	status_effect_system = get_node("/root/StatusEffectSystem")
	if not status_effect_system:
		print("⚠️ Status effect system not found!")
	else:
		print("⚡ Status effect system connected")
	
	# Setup ability system
	ability_system = AbilitySystem.new()
	add_child(ability_system)
	ability_system.name = "AbilitySystem"
	print("⚡ Ability system initialized")
	
	# Setup health system
	if health_system:
		health_system.max_health = 100
		health_system.current_health = 100
		health_system.health_depleted.connect(_on_player_death)
		print("❤️ Player health initialized: 100/100")
	
	# Setup placeholder mesh if none exists
	if not mesh_instance.mesh:
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(1, 2, 1)
		mesh_instance.mesh = box_mesh
		
		# Apply Egyptian material if available
		var egyptian_material = load("res://assets/materials/egyptian_default.tres")
		if egyptian_material:
			mesh_instance.material_override = egyptian_material
			print("🏺 Egyptian material applied")

func _physics_process(delta):
	# Handle invulnerability timer
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false
	
	# Handle hit freeze (for impact feedback)
	if hit_freeze_timer > 0:
		hit_freeze_timer -= delta
		if hit_freeze_timer <= 0:
			Engine.time_scale = 1.0  # Resume normal time
		else:
			Engine.time_scale = 0.1  # Slow motion effect
			return  # Skip normal physics during hit freeze
	
	# Handle screen shake
	if screen_shake_duration > 0:
		screen_shake_duration -= delta
		_apply_screen_shake()
	
	# Handle gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Get input
	_handle_input()
	
	# Handle dash movement first (overrides normal movement)
	if dash_system and dash_system.is_dashing:
		var dash_velocity = dash_system.get_dash_velocity()
		velocity.x = dash_velocity.x
		velocity.z = dash_velocity.z
	else:
		# Apply normal movement
		_apply_movement(delta)
	
	# Rotate character to face movement direction (except during dash)
	if not (dash_system and dash_system.is_dashing):
		_rotate_to_movement()
	
	# Move character
	move_and_slide()

func _handle_input():
	# Get WASD input
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	# Normalize diagonal movement
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	
	# Handle attack input
	if Input.is_action_just_pressed("attack"):
		_perform_attack()
	
	# Handle dash input
	if Input.is_action_just_pressed("dash"):
		_perform_dash()
	
	# Handle special ability inputs (Sprint 5)
	if Input.is_action_just_pressed("ability_1"):
		_use_ability("area_slam")
	if Input.is_action_just_pressed("ability_2"):
		_use_ability("divine_projectile")
	if Input.is_action_just_pressed("ability_3"):
		_use_ability("divine_shield")
	
	# Handle room system inputs (Sprint 6)
	if Input.is_action_just_pressed("door_1"):
		_select_door(0)
	if Input.is_action_just_pressed("door_2"):
		_select_door(1)
	if Input.is_action_just_pressed("door_3"):
		_select_door(2)
	if Input.is_action_just_pressed("toggle_minimap"):
		_toggle_minimap()
	if Input.is_action_just_pressed("validate_sprint_6"):
		_validate_sprint_6()
	
	# Test boon selection (Sprint 7)
	if Input.is_action_just_pressed("test_boon_selection"):
		_test_boon_selection()

func _apply_movement(_delta):
	# Convert 2D input to 3D isometric movement
	# For isometric view, we map:
	# Input X -> World X
	# Input Y -> World Z (depth)
	
	# Apply movement speed modifier from status effects
	var speed_multiplier = get_movement_speed_multiplier()
	var effective_speed = SPEED * speed_multiplier
	
	movement_vector = Vector3(input_vector.x, 0, input_vector.y) * effective_speed
	
	# Apply to velocity (keeping Y for gravity)
	velocity.x = movement_vector.x
	velocity.z = movement_vector.z

func _rotate_to_movement():
	# Smooth rotation towards movement direction
	if movement_vector.length() > 0.1:
		var target_rotation = atan2(-movement_vector.x, -movement_vector.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * get_physics_process_delta_time())

func _perform_attack():
	if not combat_system:
		print("⚠️ No combat system available for attack")
		return
	
	# Get mouse direction in world space using proper raycasting
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("⚠️ No camera found for mouse direction")
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Use camera to project mouse position to world coordinates
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	# Create a raycast to find the ground intersection
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4  # Ground layer only
	
	var result = space_state.intersect_ray(query)
	
	var attack_target: Vector3
	var attack_direction: Vector3
	
	if result:
		# Mouse is pointing at ground - attack toward that point
		attack_target = result.position
		attack_direction = (attack_target - global_position).normalized()
	else:
		# No ground intersection - use projected direction on player's Y level
		var ground_intersection = Vector3(
			from.x + camera.project_ray_normal(mouse_pos).x * (from.y - global_position.y) / -camera.project_ray_normal(mouse_pos).y,
			global_position.y,
			from.z + camera.project_ray_normal(mouse_pos).z * (from.y - global_position.y) / -camera.project_ray_normal(mouse_pos).y
		)
		attack_target = ground_intersection
		attack_direction = (attack_target - global_position).normalized()
	
	# Attack position slightly in front of player
	var attack_position = global_position + attack_direction * 1.0
	
	if combat_system.has_method("perform_attack"):
		var success = combat_system.perform_attack(self, attack_position, attack_direction)
		if success:
			print("⚔️ Khenti attacks toward mouse at: %s!" % attack_target)

func _perform_dash():
	if not dash_system:
		print("⚠️ No dash system available")
		return
	
	if dash_system.has_method("attempt_dash"):
		var success = dash_system.attempt_dash(self, input_vector)
		if success:
			print("🏃 Khenti dashes!")

func _use_ability(ability_name: String):
	"""Use special ability (Sprint 5)"""
	if not ability_system:
		print("⚠️ No ability system available")
		return
	
	var success = ability_system.use_ability(ability_name, self)
	if success:
		print("⚡ Khenti uses %s!" % ability_name)
	else:
		print("❌ Cannot use %s (cooldown or energy)" % ability_name)

func apply_shield(damage_reduction: float, duration: float):
	"""Apply divine shield effect"""
	shield_active = true
	shield_damage_reduction = damage_reduction
	shield_duration = duration
	
	print("🛡️ Divine shield activated! %.0f%% damage reduction for %.1fs" % [damage_reduction * 100, duration])
	
	# Start shield duration timer
	var shield_timer = get_tree().create_timer(duration)
	shield_timer.timeout.connect(_remove_shield)

func _remove_shield():
	"""Remove divine shield effect when it expires"""
	shield_active = false
	shield_damage_reduction = 0.0
	shield_duration = 0.0
	print("🛡️ Divine shield expired")

func _select_door(door_index: int):
	"""Select door to next room (Sprint 6)"""
	var room_system = get_node_or_null("/root/RoomSystem")
	if not room_system:
		print("⚠️ No room system available")
		return
	
	if room_system.is_room_cleared():
		room_system.select_door(door_index)
		print("🚪 Khenti selects door %d" % (door_index + 1))
	else:
		print("⚠️ Clear the room first before selecting a door!")

func _toggle_minimap():
	"""Toggle minimap visibility (Sprint 6)"""
	var minimap = get_node_or_null("../UI/MiniMap")
	if minimap and minimap.has_method("toggle_visibility"):
		minimap.toggle_visibility()
	else:
		print("⚠️ Minimap not found")

func _validate_sprint_6():
	"""Validate Sprint 6 integration (F6 key)"""
	var game_manager = get_node_or_null("..")
	if game_manager and game_manager.has_method("validate_sprint_6"):
		game_manager.validate_sprint_6()
	else:
		print("⚠️ GameManager not found")

func _test_boon_selection():
	"""Test boon selection UI directly (F7 key)"""
	print("🏺 Player: Testing boon selection UI...")
	
	var boon_system = get_node_or_null("/root/BoonSystem")
	if not boon_system:
		print("⚠️ BoonSystem not found!")
		return
	
	if boon_system.has_method("offer_boon_selection"):
		boon_system.offer_boon_selection(false)
		print("🏺 Test boon selection triggered!")
	else:
		print("⚠️ BoonSystem doesn't have offer_boon_selection method!")

# Combat methods for integration with systems
func take_damage(amount: int, damage_type: String = "physical"):
	# Check invulnerability (from dash or damage immunity)
	if is_invulnerable:
		print("🛡️ Khenti is invulnerable - damage blocked!")
		return
	
	var final_damage = amount
	
	# Apply status effect damage modifiers
	if status_effect_system and status_effect_system.has_method("get_damage_taken_multiplier"):
		final_damage = int(final_damage * status_effect_system.get_damage_taken_multiplier(self))
	
	# Apply shield reduction (Sprint 5: Divine Shield)
	if shield_active:
		final_damage = int(final_damage * (1.0 - shield_damage_reduction))
		var blocked_damage = amount - final_damage
		print("🛡️ Divine shield blocks %d damage! (%d → %d)" % [blocked_damage, amount, final_damage])
	
	# Apply screen shake and hit freeze for impact feedback
	_trigger_hit_feedback(final_damage)
	
	if health_system and health_system.has_method("take_damage"):
		health_system.take_damage(final_damage, damage_type)
	else:
		print("💔 Player took %d %s damage (no health system)" % [final_damage, damage_type])

func set_invulnerable(duration: float):
	is_invulnerable = true
	invulnerability_timer = duration
	print("🛡️ Khenti gains %.1fs invulnerability" % duration)

func get_health() -> int:
	return health_system.get_health() if health_system else 100

func get_max_health() -> int:
	return health_system.get_max_health() if health_system else 100

func get_attack_power() -> int:
	return 0  # Base player has no attack bonus (weapons will add this later)

func _on_player_death():
	print("💀 Khenti has fallen in the Duat...")
	# Handle player death - respawn, game over, etc.
	# For Sprint 3, just print message
	
# Combat polish methods (Sprint 8)
func _trigger_hit_feedback(damage: float):
	"""Trigger screen shake and hit freeze based on damage"""
	# Screen shake intensity scales with damage
	var shake_intensity = min(damage * 0.02, 0.8)  # Cap at 0.8 for extreme hits
	var shake_time = min(damage * 0.01, 0.3)       # Cap at 0.3 seconds
	
	screen_shake_strength = shake_intensity
	screen_shake_duration = shake_time
	
	# Hit freeze for big hits (over 25 damage)
	if damage > 25:
		hit_freeze_timer = 0.1  # 0.1 second freeze
		Engine.time_scale = 0.1
	
	print("💥 Hit feedback: shake=%.2f, freeze=%s" % [shake_intensity, str(damage > 25)])

func _apply_screen_shake():
	"""Apply screen shake effect to camera"""
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	# Generate random shake offset
	var shake_offset = Vector3(
		randf_range(-screen_shake_strength, screen_shake_strength),
		randf_range(-screen_shake_strength, screen_shake_strength),
		0
	)
	
	# Apply to camera position (store original first if needed)
	if not camera.has_meta("original_position"):
		camera.set_meta("original_position", camera.position)
	
	var original_pos = camera.get_meta("original_position")
	camera.position = original_pos + shake_offset
	
	# Reset position when shake ends
	if screen_shake_duration <= 0:
		camera.position = original_pos
		camera.remove_meta("original_position")

func trigger_screen_shake(intensity: float, duration: float):
	"""Public method for other systems to trigger screen shake"""
	screen_shake_strength = intensity
	screen_shake_duration = duration

func add_status_effect(effect_type, duration: float, intensity: float = 1.0):
	"""Apply status effect to player"""
	if status_effect_system and status_effect_system.has_method("apply_status_effect"):
		status_effect_system.apply_status_effect(self, effect_type, duration, intensity)

func get_damage_multiplier() -> float:
	"""Get damage multiplier from status effects and buffs"""
	var multiplier = 1.0
	
	# Add base attack power multiplier
	var base_power = get_attack_power()
	if base_power > 0:
		multiplier += base_power * 0.01  # 1% per attack power point
	
	# Apply status effect modifiers
	if status_effect_system and status_effect_system.has_method("get_damage_multiplier"):
		multiplier *= status_effect_system.get_damage_multiplier(self)
	
	return multiplier

func get_movement_speed_multiplier() -> float:
	"""Get movement speed multiplier from status effects"""
	if status_effect_system and status_effect_system.has_method("get_movement_multiplier"):
		return status_effect_system.get_movement_multiplier(self)
	return 1.0

# Debug info
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F2:
				print("🏺 Player Status:")
				print("   Position: " + str(global_position))
				print("   Velocity: " + str(velocity))
				print("   Input: " + str(input_vector))
				print("   Health: %d/%d" % [get_health(), get_max_health()])
				print("   On Floor: " + str(is_on_floor()))
				print("   Damage Multiplier: %.2f" % get_damage_multiplier())
				print("   Speed Multiplier: %.2f" % get_movement_speed_multiplier())
			KEY_F3:
				# Test status effects
				print("🧪 Testing status effects...")
				if status_effect_system:
					status_effect_system.apply_burn(self, 5.0, 1.0)
					status_effect_system.apply_chill(self, 3.0)
				else:
					print("⚠️ No status effect system available")
			KEY_F4:
				# Test screen shake
				print("📱 Testing screen shake...")
				trigger_screen_shake(0.5, 1.0)