extends CharacterBody3D
## Inimigo básico para teste do sistema de combate
## Representa um guerreiro esqueleto das Cavernas dos Esquecidos

signal enemy_died(enemy)
signal enemy_took_damage(enemy, damage)

# Stats básicos
var max_health: float = 50.0
var current_health: float = 50.0
var movement_speed: float = 3.0
var attack_damage: float = 15.0
var detection_range: float = 8.0
var attack_range: float = 1.5

# Estados da IA
enum EnemyState {
	IDLE,
	PATROLLING,
	CHASING,
	ATTACKING,
	STUNNED,
	DEAD
}

var current_state: EnemyState = EnemyState.IDLE
var target_player: CharacterBody3D = null

# Movimento e pathfinding
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var patrol_wait_timer: float = 0.0
var chase_timer: float = 0.0

# Combate
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0
var stun_timer: float = 0.0

# Referências
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea

const GRAVITY = 9.8

func _ready():
	print("💀 Basic Enemy spawned - Skeleton Warrior")
	
	# Setup visual
	setup_enemy_visual()
	
	# Setup detection areas
	setup_detection_areas()
	
	# Find player reference
	find_player_reference()
	
	# Setup patrol route
	setup_patrol_route()
	
	# Add to enemies group
	add_to_group("enemies")
	
	# Configure collision layers (Enemy layer = 2)
	collision_layer = 2  # Enemies are on layer 2
	collision_mask = 1 | 4  # Collide with Player (1) and Environment (4)

func setup_enemy_visual():
	"""Configura visual básico do inimigo"""
	# Create basic enemy mesh (red cube for now)
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 1.6, 0.8)
	mesh_instance.mesh = box_mesh
	
	# Dark red material for enemies
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.DARK_RED
	material.metallic = 0.1
	material.roughness = 0.8
	mesh_instance.material_override = material
	
	# Collision shape
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 1.6, 0.8)
	collision_shape.shape = box_shape
	
	print("👹 Enemy visual configured - Skeleton Warrior")

func setup_detection_areas():
	"""Configura áreas de detecção e ataque"""
	# Detection area
	if detection_area:
		var detection_shape = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = detection_range
		detection_shape.shape = sphere_shape
		detection_area.add_child(detection_shape)
		
		detection_area.body_entered.connect(_on_player_entered_detection)
		detection_area.body_exited.connect(_on_player_exited_detection)
		
		# Configure layers
		detection_area.collision_layer = 0
		detection_area.collision_mask = 1  # Player layer
	
	# Attack area
	if attack_area:
		var attack_shape = CollisionShape3D.new()
		var attack_sphere = SphereShape3D.new()
		attack_sphere.radius = attack_range
		attack_shape.shape = attack_sphere
		attack_area.add_child(attack_shape)
		
		attack_area.body_entered.connect(_on_player_entered_attack_range)
		attack_area.body_exited.connect(_on_player_exited_attack_range)
		
		# Configure layers
		attack_area.collision_layer = 0
		attack_area.collision_mask = 1  # Player layer

func find_player_reference():
	"""Encontra referência ao player"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		target_player = player
		print("🎯 Enemy found player target: ", player.name)

func setup_patrol_route():
	"""Define rota de patrulha básica"""
	var base_pos = global_position
	patrol_points = [
		base_pos,
		base_pos + Vector3(5, 0, 0),
		base_pos + Vector3(5, 0, 5),
		base_pos + Vector3(0, 0, 5)
	]
	
	print("🚶 Patrol route setup with ", patrol_points.size(), " points")

func _physics_process(delta):
	"""Main AI loop"""
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Update timers
	update_timers(delta)
	
	# State machine
	match current_state:
		EnemyState.IDLE:
			handle_idle_state(delta)
		EnemyState.PATROLLING:
			handle_patrol_state(delta)
		EnemyState.CHASING:
			handle_chase_state(delta)
		EnemyState.ATTACKING:
			handle_attack_state(delta)
		EnemyState.STUNNED:
			handle_stun_state(delta)
		EnemyState.DEAD:
			handle_death_state(delta)
	
	# Apply movement
	move_and_slide()

func update_timers(delta):
	"""Atualiza timers do inimigo"""
	if patrol_wait_timer > 0:
		patrol_wait_timer -= delta
	
	if chase_timer > 0:
		chase_timer -= delta
	
	if attack_timer > 0:
		attack_timer -= delta
	
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0 and current_state == EnemyState.STUNNED:
			change_state(EnemyState.IDLE)

func handle_idle_state(_delta):
	"""Estado idle - parado ou começando patrulha"""
	velocity.x = 0
	velocity.z = 0
	
	if patrol_wait_timer <= 0:
		change_state(EnemyState.PATROLLING)

func handle_patrol_state(_delta):
	"""Estado de patrulha"""
	if patrol_points.is_empty():
		change_state(EnemyState.IDLE)
		return
	
	var target_point = patrol_points[current_patrol_index]
	var direction = (target_point - global_position).normalized()
	direction.y = 0  # Keep on ground
	
	# Move towards patrol point
	velocity.x = direction.x * movement_speed * 0.5  # Slower patrol
	velocity.z = direction.z * movement_speed * 0.5
	
	# Check if reached patrol point
	if global_position.distance_to(target_point) < 0.5:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		patrol_wait_timer = randf_range(1.0, 2.0)
		change_state(EnemyState.IDLE)
	
	# Face movement direction (reduce frequency)
	if direction.length() > 0 and randf() < 0.1:  # Only 10% of frames
		look_at(global_position + direction, Vector3.UP)

func handle_chase_state(_delta):
	"""Estado de perseguição do player"""
	if not target_player:
		change_state(EnemyState.IDLE)
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	direction.y = 0
	
	# Move towards player
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	
	# Face player (reduce frequency)
	if direction.length() > 0 and randf() < 0.2:  # Only 20% of frames
		look_at(target_player.global_position, Vector3.UP)
	
	# Check distance to player
	var distance = global_position.distance_to(target_player.global_position)
	
	if distance > detection_range * 1.5:  # Lost player
		change_state(EnemyState.IDLE)
		chase_timer = 0
	elif distance <= attack_range:  # In attack range
		change_state(EnemyState.ATTACKING)

func handle_attack_state(_delta):
	"""Estado de ataque"""
	velocity.x = 0
	velocity.z = 0
	
	if not target_player:
		change_state(EnemyState.IDLE)
		return
	
	# Face player
	var direction = (target_player.global_position - global_position).normalized()
	if direction.length() > 0:
		look_at(target_player.global_position, Vector3.UP)
	
	# Attack if cooldown is ready
	if attack_timer <= 0:
		perform_attack()
		attack_timer = attack_cooldown
	
	# Check if player moved out of range
	var distance = global_position.distance_to(target_player.global_position)
	if distance > attack_range * 1.2:
		change_state(EnemyState.CHASING)

func handle_stun_state(_delta):
	"""Estado de stun após tomar dano"""
	velocity.x = 0
	velocity.z = 0
	
	# Visual feedback for stun
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			material.albedo_color = Color.WHITE.lerp(Color.RED, 0.5)

func handle_death_state(_delta):
	"""Estado de morte"""
	velocity.x = 0
	velocity.z = 0
	
	# TODO: Add death animation in Sprint 8
	# For now, just make it red and smaller
	mesh_instance.modulate = Color.DARK_RED
	mesh_instance.scale = Vector3(0.8, 0.3, 0.8)

func change_state(new_state: EnemyState):
	"""Muda estado do inimigo"""
	current_state = new_state
	
	# Reset visual effects when leaving stun
	if current_state != EnemyState.STUNNED and mesh_instance:
		if mesh_instance.material_override:
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				material.albedo_color = Color.DARK_RED

func perform_attack():
	"""Executa ataque no player"""
	if not target_player:
		return
	
	print("👹 Enemy attacks player!")
	
	# Check if player is still in range
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= attack_range:
		# Apply damage to player
		if target_player.has_method("take_damage"):
			target_player.take_damage(attack_damage, self)
		
		print("💥 Enemy hit player for ", attack_damage, " damage")

func take_damage(amount: float, _source: Node = null):
	"""Recebe dano"""
	current_health = max(current_health - amount, 0)
	
	print("💔 Enemy took ", amount, " damage - Health: ", current_health, "/", max_health)
	
	# Emit signal
	enemy_took_damage.emit(self, amount)
	
	# Stun on damage
	if current_health > 0:
		stun_timer = 0.3
		change_state(EnemyState.STUNNED)
	else:
		die()

func die():
	"""Morte do inimigo"""
	print("☠️ Enemy died!")
	
	change_state(EnemyState.DEAD)
	
	# Disable collision
	collision_shape.disabled = true
	set_physics_process(false)
	
	# TODO: Drop loot in Sprint 11
	# TODO: Add death effects in Sprint 8
	
	# Emit signal
	enemy_died.emit(self)
	
	# Remove after delay
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _on_player_entered_detection(body: Node):
	"""Player entrou na área de detecção"""
	if body == target_player and current_state != EnemyState.DEAD:
		print("👀 Enemy detected player!")
		chase_timer = 5.0  # Chase for 5 seconds
		change_state(EnemyState.CHASING)

func _on_player_exited_detection(body: Node):
	"""Player saiu da área de detecção"""
	if body == target_player:
		print("❓ Enemy lost sight of player")

func _on_player_entered_attack_range(body: Node):
	"""Player entrou no alcance de ataque"""
	if body == target_player and current_state == EnemyState.CHASING:
		change_state(EnemyState.ATTACKING)

func _on_player_exited_attack_range(body: Node):
	"""Player saiu do alcance de ataque"""
	if body == target_player and current_state == EnemyState.ATTACKING:
		change_state(EnemyState.CHASING)

func get_enemy_info() -> Dictionary:
	"""Retorna informações do inimigo para debug"""
	return {
		"health": current_health,
		"max_health": max_health,
		"state": EnemyState.keys()[current_state],
		"distance_to_player": global_position.distance_to(target_player.global_position) if target_player else 0,
		"attack_cooldown": attack_timer,
		"position": global_position
	}
