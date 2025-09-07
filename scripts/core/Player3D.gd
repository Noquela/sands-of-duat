# Player3D.gd
# 3D Isometric Player Controller for Sands of Duat
# Khenti - Egyptian Prince Protagonist
# Sprint 2: Player Controller Base

extends CharacterBody3D

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
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

func _ready():
	print("⚔️ Khenti awakens in the Duat...")
	print("🎮 Player Controller: Sprint 4 - Dash System Ready")
	
	# Get system references
	combat_system = get_node("/root/CombatSystem")
	if not combat_system:
		print("⚠️ Combat system not found!")
	
	dash_system = get_node("/root/DashSystem")
	if not dash_system:
		print("⚠️ Dash system not found!")
	else:
		print("🏃 Dash system connected")
	
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
	
	# Convert mouse position to world space on the ground plane
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# Find intersection with ground plane (Y = 0)
	var ground_y = global_position.y  # Use player's Y level
	var ray_direction = (to - from).normalized()
	
	var attack_direction: Vector3
	var attack_position: Vector3
	
	if abs(ray_direction.y) < 0.001:  # Ray is nearly parallel to ground
		print("⚠️ Mouse ray parallel to ground, using forward direction")
		attack_direction = -transform.basis.z
		attack_position = global_position + attack_direction * 1.0
		
		if combat_system.has_method("perform_attack"):
			var success = combat_system.perform_attack(self, attack_position, attack_direction)
			if success:
				print("⚔️ Khenti attacks forward!")
		return
	
	# Calculate intersection point with ground plane
	var t = (ground_y - from.y) / ray_direction.y
	var ground_point = from + ray_direction * t
	
	# Calculate attack direction from player to ground point
	attack_direction = (ground_point - global_position).normalized()
	attack_direction.y = 0  # Keep attack horizontal
	
	# Attack position slightly in front of player
	attack_position = global_position + attack_direction * 1.0
	
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

# Combat methods for integration with systems
func take_damage(amount: int, damage_type: String = "physical"):
	# Check invulnerability (from dash or damage immunity)
	if is_invulnerable:
		print("🛡️ Khenti is invulnerable - damage blocked!")
		return
	
	if health_system and health_system.has_method("take_damage"):
		health_system.take_damage(amount, damage_type)
	else:
		print("💔 Player took %d %s damage (no health system)" % [amount, damage_type])

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