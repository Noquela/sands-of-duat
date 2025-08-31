extends "res://scripts/enemies/BasicEnemy.gd"
## Sand Djinn - Entidade mágica do deserto
## Inimigo mágico que usa teletransporte e ataques de areia

# Configurações específicas do djinn
var teleport_cooldown: float = 4.0
var teleport_timer: float = 0.0
var magic_range: float = 10.0
var sand_storm_duration: float = 2.0
var teleport_range: float = 8.0

func _ready():
	# Override stats para Sand Djinn
	max_health = 120.0
	current_health = 120.0
	movement_speed = 4.0  # Mais rápido
	attack_damage = 25.0  # Forte
	detection_range = 15.0  # Detecta de muito longe
	attack_range = 6.0      # Range mágico médio
	attack_cooldown = 3.0   # Ataques demorados mas poderosos
	
	print("🧞 Sand Djinn spawned - Desert Magic Entity")
	
	# Setup visual específico
	setup_djinn_visual()
	
	# Setup detection areas com novos valores
	setup_detection_areas()
	
	# Find player reference
	find_player_reference()
	
	# Setup patrol route
	setup_patrol_route()
	
	# Add to enemies group
	add_to_group("enemies")
	add_to_group("djinns")

func setup_djinn_visual():
	"""Configura visual do Sand Djinn"""
	# Visual mais alto e imponente (mágico)
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 2.0, 0.8)  # Mais alto e imponente
	mesh_instance.mesh = box_mesh
	
	# Material dourado/sandy
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.7, 0.2, 1.0)  # Dourado do deserto
	material.metallic = 0.3
	material.roughness = 0.6
	material.emission_enabled = true
	material.emission = Color(0.3, 0.2, 0.0)  # Brilho mágico sutil
	mesh_instance.material_override = material
	
	# Collision shape
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 2.0, 0.8)
	collision_shape.shape = box_shape
	
	print("🧞 Sand Djinn visual configured - Magical Desert Entity")

func _physics_process(delta):
	super._physics_process(delta)
	
	# Update teleport timer
	if teleport_timer > 0:
		teleport_timer -= delta

func handle_chase_state(_delta):
	"""Estado específico do djinn - pode teletransportar"""
	if not target_player:
		change_state(EnemyState.IDLE)
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	var direction = (target_player.global_position - global_position).normalized()
	direction.y = 0
	
	# Face player sempre
	if direction.length() > 0:
		look_at(target_player.global_position, Vector3.UP)
	
	# Tentar teletransporte se disponível e player longe
	if teleport_timer <= 0 and distance > attack_range * 1.5:
		attempt_teleport()
		return
	
	# Movimento normal se não pode teletransportar
	if distance > attack_range:
		# Move towards player
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		# In range - prepare to attack
		velocity.x = 0
		velocity.z = 0
		change_state(EnemyState.ATTACKING)
	
	# Lost player
	if distance > detection_range * 2.0:  # Djinn persegue por mais tempo
		change_state(EnemyState.IDLE)
		chase_timer = 0

func attempt_teleport():
	"""Tenta teletransportar para perto do player"""
	if not target_player:
		return
	
	print("🧞 Sand Djinn attempting teleport!")
	
	# Efeito visual pré-teletransporte
	show_teleport_effect()
	
	# Wait for effect
	await get_tree().create_timer(0.8).timeout
	
	# Find teleport position (circular around player)
	var player_pos = target_player.global_position
	var angle = randf() * TAU  # Random angle
	var teleport_distance = randf_range(4.0, teleport_range)
	var teleport_pos = player_pos + Vector3(
		cos(angle) * teleport_distance,
		0,
		sin(angle) * teleport_distance
	)
	
	# Teleport
	global_position = teleport_pos
	teleport_timer = teleport_cooldown
	
	# Efeito visual pós-teletransporte
	show_teleport_arrival()
	
	print("🧞 Sand Djinn teleported near player!")

func show_teleport_effect():
	"""Efeito visual antes do teletransporte"""
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			# Brilho intenso antes de desaparecer
			var original_emission = material.emission
			material.emission = Color(1.0, 0.8, 0.0)  # Brilho dourado intenso
			
			# Fade out
			var tween = create_tween()
			tween.tween_property(material, "albedo_color:a", 0.1, 0.8)
			
			# Restaurar depois
			await get_tree().create_timer(0.8).timeout
			if material:
				material.albedo_color.a = 1.0
				material.emission = original_emission

func show_teleport_arrival():
	"""Efeito visual após teletransporte"""
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			# Flash brilhante ao aparecer
			material.emission = Color(1.0, 0.8, 0.0)
			
			# Volta ao normal
			var tween = create_tween()
			tween.tween_property(material, "emission", Color(0.3, 0.2, 0.0), 1.0)

func handle_attack_state(_delta):
	"""Estado de ataque mágico"""
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
	
	# Se muito longe, volta para chase
	if distance > magic_range:
		change_state(EnemyState.CHASING)
		return
	
	# Attack if cooldown ready
	if attack_timer <= 0:
		perform_magic_attack()
		attack_timer = attack_cooldown

func perform_attack():
	"""Override para ataque mágico"""
	perform_magic_attack()

func perform_magic_attack():
	"""Ataque mágico - tempestade de areia"""
	if not target_player:
		return
	
	print("🧞 Sand Djinn casts Sand Storm!")
	
	# Telegraph attack
	show_magic_telegraph()
	
	# Wait for telegraph
	await get_tree().create_timer(1.0).timeout
	
	# Check if player still in range
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= magic_range and current_state == EnemyState.ATTACKING:
		cast_sand_storm()

func show_magic_telegraph():
	"""Telegraph do ataque mágico (1s warning)"""
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			# Brilho mágico intenso
			var tween = create_tween()
			tween.set_loops(3)  # Pulsa 3 vezes
			tween.tween_property(material, "emission", Color(1.0, 0.5, 0.0), 0.15)
			tween.tween_property(material, "emission", Color(0.3, 0.2, 0.0), 0.15)

func cast_sand_storm():
	"""Lança tempestade de areia em área"""
	# Criar área de dano em volta do player
	var sand_area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 4.0  # Área grande
	collision.shape = shape
	sand_area.add_child(collision)
	
	# Posicionar na posição do player
	sand_area.global_position = target_player.global_position
	
	get_parent().add_child(sand_area)
	
	# Conectar sinal para detectar player
	sand_area.body_entered.connect(_on_sand_storm_hit)
	
	print("🌪️ Sand Storm created at player position!")
	
	# Remover área após duração
	await get_tree().create_timer(sand_storm_duration).timeout
	if sand_area and is_instance_valid(sand_area):
		sand_area.queue_free()

func _on_sand_storm_hit(body):
	"""Callback quando sand storm atinge algo"""
	if body == target_player:
		if target_player.has_method("take_damage"):
			target_player.take_damage(attack_damage, self)
			print("🌪️ Sand Storm hit player for ", attack_damage, " magic damage!")

func die():
	"""Morte mágica do Sand Djinn"""
	print("💀 Sand Djinn dissolved into sand!")
	
	change_state(EnemyState.DEAD)
	
	# Efeito visual: dissolve em partículas douradas
	if mesh_instance:
		var tween = create_tween()
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			# Brilho final antes de dissolver
			material.emission = Color(1.0, 0.8, 0.0)
			tween.parallel().tween_property(material, "albedo_color:a", 0.0, 2.0)
			tween.parallel().tween_property(material, "emission", Color(0, 0, 0), 2.0)
	
	# Disable collision
	collision_shape.disabled = true
	set_physics_process(false)
	
	# Emit signal
	enemy_died.emit(self)
	
	# Remove after effect
	await get_tree().create_timer(2.5).timeout
	queue_free()