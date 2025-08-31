extends "res://scripts/enemies/BasicEnemy.gd"
## Mummy Archer - Guarda antigo do submundo egípcio
## Inimigo ranged que mantém distância e atira projéteis

# Configurações específicas do arqueiro
var projectile_scene: PackedScene = null
var projectile_speed: float = 8.0
var optimal_distance: float = 6.0  # Distância preferida do player
var min_distance: float = 3.0      # Distância mínima (recua se player muito perto)
var last_shot_position: Vector3

func _ready():
	# Override stats para Mummy Archer
	max_health = 80.0
	current_health = 80.0
	movement_speed = 2.0  # Mais lento
	attack_damage = 18.0
	detection_range = 12.0  # Detecta de longe (arqueiro)
	attack_range = 8.0      # Range de tiro longo
	attack_cooldown = 2.0   # Mais lento para recarregar
	
	print("🏹 Mummy Archer spawned - Ancient Guardian")
	
	# Setup visual específico
	setup_mummy_visual()
	
	# Setup detection areas com novos valores
	setup_detection_areas()
	
	# Find player reference
	find_player_reference()
	
	# Setup patrol route
	setup_patrol_route()
	
	# Add to enemies group
	add_to_group("enemies")
	add_to_group("archers")

func setup_mummy_visual():
	"""Configura visual da Múmia Arqueiro"""
	# Visual mais alto e fino (arqueiro)
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.6, 1.8, 0.6)  # Mais alto e fino
	mesh_instance.mesh = box_mesh
	
	# Material de múmia (bege/marrom)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4, 1.0)  # Cor de múmia
	material.metallic = 0.0
	material.roughness = 0.9
	mesh_instance.material_override = material
	
	# Collision shape
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.6, 1.8, 0.6)
	collision_shape.shape = box_shape
	
	print("🏹 Mummy Archer visual configured - Ancient Guardian")

func handle_chase_state(_delta):
	"""Estado específico do arqueiro - mantém distância ótima"""
	if not target_player:
		change_state(EnemyState.IDLE)
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	var direction = (target_player.global_position - global_position).normalized()
	direction.y = 0
	
	# Face player sempre
	if direction.length() > 0:
		look_at(target_player.global_position, Vector3.UP)
	
	# Comportamento baseado na distância
	if distance < min_distance:
		# Muito perto - recuar
		velocity.x = -direction.x * movement_speed * 1.5  # Recua mais rápido
		velocity.z = -direction.z * movement_speed * 1.5
		print("🏹 Mummy Archer backing away from player")
		
	elif distance > optimal_distance and distance < attack_range:
		# Tentar manter distância ótima
		var move_closer = distance > optimal_distance + 1.0
		if move_closer:
			velocity.x = direction.x * movement_speed * 0.8  # Move devagar para posição
			velocity.z = direction.z * movement_speed * 0.8
		else:
			velocity.x = 0
			velocity.z = 0
			
	elif distance <= attack_range and distance >= min_distance:
		# Na distância de tiro - ficar parado e atirar
		velocity.x = 0
		velocity.z = 0
		change_state(EnemyState.ATTACKING)
		
	else:
		# Muito longe - se aproximar
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	
	# Lost player
	if distance > detection_range * 1.5:
		change_state(EnemyState.IDLE)
		chase_timer = 0

func handle_attack_state(_delta):
	"""Estado de ataque - tiro com arco"""
	velocity.x = 0
	velocity.z = 0
	
	if not target_player:
		change_state(EnemyState.IDLE)
		return
	
	# Face player
	var direction = (target_player.global_position - global_position).normalized()
	if direction.length() > 0:
		look_at(target_player.global_position, Vector3.UP)
	
	var distance = global_position.distance_to(target_player.global_position)
	
	# Se player ficou muito perto, volta para chase para recuar
	if distance < min_distance:
		change_state(EnemyState.CHASING)
		return
	
	# Se muito longe, volta para chase
	if distance > attack_range:
		change_state(EnemyState.CHASING)
		return
	
	# Attack if cooldown ready
	if attack_timer <= 0:
		perform_ranged_attack()
		attack_timer = attack_cooldown

func perform_attack():
	"""Override para não usar ataque melee"""
	perform_ranged_attack()

func perform_ranged_attack():
	"""Ataque à distância - dispara projétil"""
	if not target_player:
		return
	
	print("🏹 Mummy Archer shoots arrow!")
	
	# Telegraph attack (warning visual)
	show_attack_telegraph()
	
	# Wait for telegraph
	await get_tree().create_timer(0.5).timeout
	
	# Check if player still in range after telegraph
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= attack_range and current_state == EnemyState.ATTACKING:
		fire_projectile()

func show_attack_telegraph():
	"""Mostra telegraph do ataque (0.5s warning)"""
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			# Flash vermelho para indicar ataque iminente
			var original_color = material.albedo_color
			material.albedo_color = Color.RED
			
			# Restaurar cor original após telegraph
			await get_tree().create_timer(0.5).timeout
			if material:
				material.albedo_color = original_color

func fire_projectile():
	"""Dispara projétil na direção do player"""
	var projectile = create_projectile()
	
	# Posição inicial (em frente ao arqueiro)
	var forward_dir = -global_transform.basis.z
	projectile.global_position = global_position + forward_dir * 1.0 + Vector3.UP * 1.0
	
	# Direção para o player (com predição básica)
	var target_pos = target_player.global_position
	if target_player.velocity.length() > 0:
		# Predição simples: onde o player estará em 0.5s
		target_pos += target_player.velocity * 0.5
	
	var direction = (target_pos - projectile.global_position).normalized()
	projectile.velocity = direction * projectile_speed
	
	get_parent().add_child(projectile)
	print("🏹 Arrow fired towards player!")

func create_projectile():
	"""Cria projétil básico"""
	var projectile = RigidBody3D.new()
	
	# Visual do projétil (cube pequeno marrom)
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.1, 0.1, 0.4)  # Formato de flecha
	mesh_inst.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.1)  # Marrom
	mesh_inst.material_override = material
	
	projectile.add_child(mesh_inst)
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.1, 0.1, 0.4)
	collision.shape = shape
	projectile.add_child(collision)
	
	# Physics
	projectile.gravity_scale = 0.2  # Pouca gravidade
	projectile.set_script(preload("res://scripts/enemies/Projectile.gd"))
	
	# Set projectile damage after script is attached
	projectile.set_damage(attack_damage)
	
	return projectile