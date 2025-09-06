# BaseEnemy.gd
# Base Enemy Class for Sands of Duat
# Sprint 3: Basic enemy AI and combat integration

extends CharacterBody3D

signal enemy_died(enemy: Node3D)
signal player_detected(player: Node3D)
signal attack_performed(target: Node3D)

# Enemy stats from roadmap
@export var enemy_name: String = "Shade of the Lost"
@export var max_health: int = 50
@export var movement_speed: float = 2.0
@export var attack_damage: int = 15
@export var attack_range: float = 1.5
@export var detection_range: float = 8.0
@export var attack_cooldown: float = 1.0

# AI state
enum EnemyState {
	IDLE,
	PATROLLING,
	CHASING,
	ATTACKING,
	DEAD
}

var current_state: EnemyState = EnemyState.IDLE
var target_player: Node3D = null
var last_known_player_position: Vector3
var attack_timer: float = 0.0
var state_timer: float = 0.0

# Movement
const GRAVITY = 20.0
var patrol_center: Vector3
var patrol_radius: float = 5.0
var patrol_target: Vector3

# Components
@onready var health_system: Node = $HealthSystem
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea

func _ready():
	add_to_group("enemies")
	patrol_center = global_position
	patrol_target = _get_random_patrol_point()
	
	print("👻 Enemy spawned: %s (HP: %d, Speed: %.1f)" % [enemy_name, max_health, movement_speed])
	
	# Setup health system
	if health_system:
		health_system.max_health = max_health
		health_system.current_health = max_health
		health_system.health_depleted.connect(_on_death)
	
	# Setup detection
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)

func _physics_process(delta):
	if current_state == EnemyState.DEAD:
		return
	
	# Handle gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# Update state timer
	state_timer += delta
	
	# AI state machine
	_update_ai_state(delta)
	
	# Apply movement
	move_and_slide()

func _update_ai_state(delta):
	match current_state:
		EnemyState.IDLE:
			_state_idle(delta)
		EnemyState.PATROLLING:
			_state_patrolling(delta)
		EnemyState.CHASING:
			_state_chasing(delta)
		EnemyState.ATTACKING:
			_state_attacking(delta)

func _state_idle(delta):
	velocity.x = 0
	velocity.z = 0
	
	# Switch to patrolling after some time
	if state_timer > 2.0:
		_change_state(EnemyState.PATROLLING)

func _state_patrolling(delta):
	# Move towards patrol target
	var direction = (patrol_target - global_position).normalized()
	velocity.x = direction.x * movement_speed * 0.5  # Slower when patrolling
	velocity.z = direction.z * movement_speed * 0.5
	
	# Rotate towards movement
	if direction.length() > 0.1:
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)
	
	# Check if reached patrol target
	if global_position.distance_to(patrol_target) < 1.0:
		patrol_target = _get_random_patrol_point()
		_change_state(EnemyState.IDLE)

func _state_chasing(delta):
	if not target_player or not is_instance_valid(target_player):
		_change_state(EnemyState.IDLE)
		return
	
	# Move towards player
	var direction = (target_player.global_position - global_position).normalized()
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	
	# Rotate towards player
	var target_rotation = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, 8.0 * delta)
	
	# Check if player is in attack range
	var distance_to_player = global_position.distance_to(target_player.global_position)
	if distance_to_player <= attack_range and attack_timer <= 0:
		_change_state(EnemyState.ATTACKING)
	
	# Lose player if too far
	if distance_to_player > detection_range * 1.5:
		print("👻 %s lost sight of player" % enemy_name)
		target_player = null
		_change_state(EnemyState.PATROLLING)

func _state_attacking(delta):
	# Stop movement during attack
	velocity.x = 0
	velocity.z = 0
	
	if attack_timer <= 0 and target_player:
		_perform_attack()
		attack_timer = attack_cooldown
		
		# Return to chasing after attack
		_change_state(EnemyState.CHASING)

func _perform_attack():
	if not target_player:
		return
	
	print("👻 %s attacks!" % enemy_name)
	
	# Get combat system
	var combat_system = get_node("/root/CombatSystem")
	if combat_system and combat_system.has_method("deal_damage_to_player"):
		combat_system.deal_damage_to_player(target_player, attack_damage, "physical")
	
	attack_performed.emit(target_player)

func _change_state(new_state: EnemyState):
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		EnemyState.IDLE:
			pass
		EnemyState.PATROLLING:
			patrol_target = _get_random_patrol_point()
		EnemyState.CHASING:
			if target_player:
				print("👻 %s chasing player!" % enemy_name)
		EnemyState.ATTACKING:
			print("👻 %s preparing to attack!" % enemy_name)

func _get_random_patrol_point() -> Vector3:
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	return patrol_center + Vector3(cos(angle) * distance, 0, sin(angle) * distance)

func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		target_player = body
		last_known_player_position = body.global_position
		player_detected.emit(body)
		_change_state(EnemyState.CHASING)
		print("👻 %s detected player!" % enemy_name)

func _on_detection_area_exited(body):
	if body == target_player and current_state != EnemyState.ATTACKING:
		# Don't immediately lose player, keep last known position
		pass

func _on_attack_area_entered(body):
	if body == target_player and current_state == EnemyState.CHASING:
		_change_state(EnemyState.ATTACKING)

# Damage handling
func take_damage(amount: int, damage_type: String = "physical"):
	if current_state == EnemyState.DEAD:
		return
	
	if health_system:
		health_system.take_damage(amount, damage_type)
	else:
		# Fallback damage handling
		max_health -= amount
		if max_health <= 0:
			_on_death()

func _on_death():
	print("💀 %s defeated!" % enemy_name)
	current_state = EnemyState.DEAD
	enemy_died.emit(self)
	
	# Disable collision and AI
	set_physics_process(false)
	if collision_shape:
		collision_shape.disabled = true
	
	# Play death animation/effect (placeholder)
	_play_death_effect()
	
	# Remove after delay
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _play_death_effect():
	# Simple fade out effect
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "transparency", 1.0, 1.0)

# Getters for other systems
func get_health() -> int:
	return health_system.get_health() if health_system else max_health

func get_max_health() -> int:
	return health_system.get_max_health() if health_system else max_health

func get_defense() -> int:
	return 0  # Base enemies have no defense

func is_alive() -> bool:
	return current_state != EnemyState.DEAD

# Debug info
func get_enemy_info() -> Dictionary:
	return {
		"name": enemy_name,
		"state": EnemyState.keys()[current_state],
		"health": get_health(),
		"target": target_player.name if target_player else "None",
		"attack_ready": attack_timer <= 0
	}