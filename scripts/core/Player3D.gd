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
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

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

func _apply_movement(_delta):
	# Convert 2D input to 3D isometric movement
	# For isometric view, we map:
	# Input X -> World X
	# Input Y -> World Z (depth)
	movement_vector = Vector3(input_vector.x, 0, input_vector.y) * SPEED
	
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
	
	# Get mouse direction in world space
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("⚠️ No camera found for mouse direction")
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	# For isometric camera, we need to adjust the mouse direction mapping
	# Convert screen coordinates to world coordinates properly for isometric view
	
	# Get viewport center for relative positioning
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size * 0.5
	var mouse_offset = mouse_pos - screen_center
	
	# For isometric camera (45° rotated), map screen X/Y to world X/Z
	# Screen horizontal = World X + Z diagonal
	# Screen vertical = World X - Z diagonal  
	var world_offset = Vector3.ZERO
	
	# Apply isometric transformation - screen coordinates to world coordinates
	# Inverted Z to match Godot's coordinate system
	world_offset.x = (mouse_offset.x - mouse_offset.y) * 0.005  # Right/Left
	world_offset.z = -(mouse_offset.x + mouse_offset.y) * 0.005  # Forward/Back
	
	# Calculate attack direction from player position
	var attack_direction = world_offset.normalized()
	if world_offset.length() < 50.0:  # Very small movement, use forward
		attack_direction = -transform.basis.z
	
	# Attack position slightly in front of player
	var attack_position = global_position + attack_direction * 1.0
	
	if combat_system.has_method("perform_attack"):
		var success = combat_system.perform_attack(self, attack_position, attack_direction)
		if success:
			print("⚔️ Khenti attacks toward mouse!")

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

# Combat methods for integration with systems
func take_damage(amount: int, damage_type: String = "physical"):
	# Check invulnerability (from dash or damage immunity)
	if is_invulnerable:
		print("🛡️ Khenti is invulnerable - damage blocked!")
		return
	
	var final_damage = amount
	
	# Apply shield reduction (Sprint 5: Divine Shield)
	if shield_active:
		final_damage = int(amount * (1.0 - shield_damage_reduction))
		var blocked_damage = amount - final_damage
		print("🛡️ Divine shield blocks %d damage! (%d → %d)" % [blocked_damage, amount, final_damage])
	
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