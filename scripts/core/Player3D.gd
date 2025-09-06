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

# Combat system reference
var combat_system: Node

func _ready():
	print("⚔️ Khenti awakens in the Duat...")
	print("🎮 Player Controller: Sprint 3 - Combat Ready")
	
	# Get combat system reference
	combat_system = get_node("/root/CombatSystem")
	if not combat_system:
		print("⚠️ Combat system not found!")
	
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
	# Handle gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Get input
	_handle_input()
	
	# Apply movement
	_apply_movement(delta)
	
	# Rotate character to face movement direction
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

func _apply_movement(delta):
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
	
	var attack_position = global_position + transform.basis.z * -1.0  # Attack in front
	var attack_direction = -transform.basis.z
	
	if combat_system.has_method("perform_attack"):
		var success = combat_system.perform_attack(self, attack_position, attack_direction)
		if success:
			print("⚔️ Khenti attacks!")

# Combat methods for integration with systems
func take_damage(amount: int, damage_type: String = "physical"):
	if health_system and health_system.has_method("take_damage"):
		health_system.take_damage(amount, damage_type)
	else:
		print("💔 Player took %d %s damage (no health system)" % [amount, damage_type])

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