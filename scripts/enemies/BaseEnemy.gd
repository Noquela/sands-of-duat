extends CharacterBody3D
class_name BaseEnemy

enum State {
	IDLE,
	CHASE,
	ATTACK,
	STAGGER,
	DEATH
}

signal enemy_died(enemy: BaseEnemy)
signal enemy_dealt_damage(target: Node3D, damage: float)

@export_group("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 3.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.5

@export_group("Detection")
@export var detection_radius: float = 8.0
@export var attack_telegraph_time: float = 0.5

@export_group("AI")
@export var pathfinding_update_interval: float = 0.2

# Core systems
const HealthSystemClass = preload("res://scripts/combat/HealthSystem.gd")
var health_system: HealthSystemClass
var navigation_agent: NavigationAgent3D

# State management
var current_state: State = State.IDLE
var state_timer: float = 0.0

# AI variables
var player_target: Node3D
var last_known_player_pos: Vector3
var pathfinding_timer: float = 0.0
var can_attack: bool = true
var is_attacking: bool = false

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	setup_enemy()
	setup_navigation()
	setup_health()
	
	# Add to enemies group
	add_to_group("enemies")

func setup_enemy():
	# Find player in scene
	player_target = get_tree().get_first_node_in_group("player")
	
	# Setup physics
	collision_layer = 2  # Enemies layer
	collision_mask = 5   # Player + Environment (1 + 4)

func setup_navigation():
	# Create NavigationAgent3D
	navigation_agent = NavigationAgent3D.new()
	add_child(navigation_agent)
	
	# Configure navigation
	navigation_agent.target_desired_distance = attack_range
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.navigation_finished.connect(_on_navigation_finished)

func setup_health():
	# Create health system
	health_system = HealthSystemClass.new()
	health_system.max_health = max_health
	add_child(health_system)
	
	# Connect signals
	health_system.health_depleted.connect(_on_death)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Update state machine
	update_state_machine(delta)
	
	# Move character
	move_and_slide()

func update_state_machine(delta):
	state_timer += delta
	
	match current_state:
		State.IDLE:
			handle_idle_state(delta)
		State.CHASE:
			handle_chase_state(delta)
		State.ATTACK:
			handle_attack_state(delta)
		State.STAGGER:
			handle_stagger_state(delta)
		State.DEATH:
			handle_death_state(delta)

func handle_idle_state(delta):
	# Look for player
	if can_see_player():
		print(name, " spotted player! Entering chase state")
		change_state(State.CHASE)
		return
	
	# Debug: Check if we can find player at all
	if player_target and is_instance_valid(player_target):
		var dist = global_position.distance_to(player_target.global_position)
		if dist <= detection_radius * 2:  # Double detection radius for debug
			print(name, " player in extended range but not chasing. Distance: ", dist)
	
	# Idle movement (optional - can add patrol later)
	velocity.x = move_toward(velocity.x, 0, move_speed * delta)
	velocity.z = move_toward(velocity.z, 0, move_speed * delta)

func handle_chase_state(delta):
	if not player_target or not is_instance_valid(player_target):
		change_state(State.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	# Check if in attack range
	if distance_to_player <= attack_range and can_attack:
		change_state(State.ATTACK)
		return
	
	# Check if lost player
	if distance_to_player > detection_radius * 1.5:
		change_state(State.IDLE)
		return
	
	# Update pathfinding
	pathfinding_timer += delta
	if pathfinding_timer >= pathfinding_update_interval:
		pathfinding_timer = 0.0
		print(name, " chasing player at distance: ", distance_to_player)
	
	# Move towards target
	move_towards_target(delta)

func handle_attack_state(_delta):
	# Stop movement during attack
	velocity.x = 0
	velocity.z = 0
	
	if state_timer >= attack_telegraph_time:
		# Perform attack
		perform_attack()
		change_state(State.CHASE)

func handle_stagger_state(_delta):
	# Stagger duration
	if state_timer >= 0.3:
		change_state(State.CHASE)

func handle_death_state(_delta):
	# Death handled by health system
	pass

func move_towards_target(delta):
	if not player_target or not is_instance_valid(player_target):
		return
	
	# Use direct movement toward player instead of navigation mesh
	var current_position = global_position
	var target_position = player_target.global_position
	var direction = (target_position - current_position).normalized()
	
	# Apply movement
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Face movement direction
	if direction != Vector3.ZERO:
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)
		
	print(name, " moving toward player. Direction: ", direction)

func can_see_player() -> bool:
	if not player_target or not is_instance_valid(player_target):
		return false
	
	var distance = global_position.distance_to(player_target.global_position)
	return distance <= detection_radius

func perform_attack():
	if not player_target or not is_instance_valid(player_target):
		return
	
	# Check if player still in range
	var distance = global_position.distance_to(player_target.global_position)
	if distance > attack_range:
		return
	
	# Deal damage to player
	if player_target.has_method("take_damage"):
		player_target.take_damage(attack_damage)
		enemy_dealt_damage.emit(player_target, attack_damage)
		print(name, " dealt ", attack_damage, " damage to player")
	
	# Start attack cooldown
	can_attack = false
	get_tree().create_timer(attack_cooldown).timeout.connect(_on_attack_cooldown_finished)

func take_damage(damage: float):
	if current_state == State.DEATH:
		return
	
	if health_system:
		health_system.take_damage(damage)
		
		# Enter stagger state briefly
		if current_state != State.ATTACK:
			change_state(State.STAGGER)

func change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0

func _on_death():
	change_state(State.DEATH)
	enemy_died.emit(self)
	print(name, " died!")
	
	# Add death effect here later
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_attack_cooldown_finished():
	can_attack = true

func _on_navigation_finished():
	# Navigation completed - can be used for specific behaviors
	pass