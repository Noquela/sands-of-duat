extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Preload combat classes
const CombatSystemClass = preload("res://scripts/combat/CombatSystem.gd")
const WeaponSystemClass = preload("res://scripts/combat/WeaponSystem.gd") 
const HealthSystemClass = preload("res://scripts/combat/HealthSystem.gd")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Combat components
var combat_system: CombatSystemClass
var weapon_system: WeaponSystemClass
var health_system: HealthSystemClass

func _ready():
	add_to_group("player")
	setup_combat_systems()

func setup_combat_systems():
	# Create combat system
	combat_system = CombatSystemClass.new()
	add_child(combat_system)
	
	# Create weapon system
	weapon_system = WeaponSystemClass.new()
	add_child(weapon_system)
	weapon_system.combat_system = combat_system
	
	# Create health system
	health_system = HealthSystemClass.new()
	health_system.max_health = 100.0
	health_system.can_regenerate = true
	health_system.regeneration_rate = 5.0
	add_child(health_system)

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement(delta)
	handle_combat()
	move_and_slide()

func handle_combat():
	if Input.is_action_just_pressed("attack"):
		combat_system.try_attack(self)

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_movement(delta):
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	
	# Fix isometric movement mapping
	var direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		# Correct mapping for isometric camera - flip Y input
		direction.x = input_dir.y + input_dir.x   # W should go up (positive direction)
		direction.z = input_dir.y - input_dir.x   # Adjust Z accordingly
		direction = direction.normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 3 * delta)
		velocity.z = move_toward(velocity.z, 0, SPEED * 3 * delta)
	
	# Weapon switching inputs
	if Input.is_action_just_pressed("switch_weapon_1"):
		weapon_system.switch_weapon("was_scepter")
	elif Input.is_action_just_pressed("switch_weapon_2"):
		weapon_system.switch_weapon("khopesh")
	elif Input.is_action_just_pressed("switch_weapon_3"):
		weapon_system.switch_weapon("egyptian_bow")