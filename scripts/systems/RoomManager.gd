extends Node
## Gerenciador de Salas - Sprint 6
## Carregamento dinâmico, cleanup automático e persistência

signal room_loaded(room_id)
signal room_transition_started(from_room, to_room)
signal room_transition_completed(room_id)
signal room_cleanup_completed(room_id)

# Referências
@onready var room_system: Node = get_node("/root/RoomSystem")
var game_manager: Node
var scene_manager: Node

# Estado atual
var current_room_scene: Node = null
var current_room_id: String = ""
var is_transitioning: bool = false
var transition_progress: float = 0.0

# Cache de cenas carregadas
var loaded_room_scenes: Dictionary = {}
const MAX_CACHED_ROOMS = 3  # Máximo de salas em cache

# Configurações de transição
const TRANSITION_DURATION = 0.5
var transition_timer: float = 0.0

# Sistema de spawn de inimigos
var spawned_enemies: Array[Node] = []
var spawned_objects: Array[Node] = []

# Player reference
var player: Node = null

func _ready():
	print("🏠 Room Manager initialized - Sprint 6")
	
	# Get references
	if get_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	if get_node("/root/SceneManager"):
		scene_manager = get_node("/root/SceneManager")
	
	# Connect signals
	connect_signals()
	
	# Find player
	await get_tree().process_frame
	find_player_reference()
	
	print("🎭 Room Manager ready for dynamic loading")

func connect_signals():
	"""Connect room system signals"""
	if room_system:
		room_system.room_entered.connect(_on_room_entered)
		room_system.room_cleared.connect(_on_room_cleared)

func find_player_reference():
	"""Find player in scene tree"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("🎯 Player reference found for room transitions")

func _process(delta):
	"""Update room transition"""
	if is_transitioning:
		update_transition(delta)

func update_transition(delta):
	"""Handle room transition animation"""
	transition_timer += delta
	transition_progress = transition_timer / TRANSITION_DURATION
	
	if transition_progress >= 1.0:
		complete_transition()

func load_room(room_id: String) -> bool:
	"""Load room scene dynamically"""
	if is_transitioning:
		print("⚠️ Cannot load room during transition")
		return false
	
	var room_data = room_system.rooms.get(room_id)
	if not room_data:
		print("❌ Room not found: ", room_id)
		return false
	
	print("🔄 Loading room: ", room_id)
	
	# Check cache first
	if room_id in loaded_room_scenes:
		print("📦 Room loaded from cache: ", room_id)
		return activate_cached_room(room_id)
	
	# Generate room scene
	var room_scene = create_room_scene(room_data)
	if not room_scene:
		print("❌ Failed to create room scene: ", room_id)
		return false
	
	# Cache room scene
	loaded_room_scenes[room_id] = room_scene
	manage_room_cache()
	
	# Activate room
	return activate_room_scene(room_scene, room_id)

func create_room_scene(room_data) -> Node3D:
	"""Create room scene from room data"""
	var room_scene = Node3D.new()
	room_scene.name = "Room_" + room_data.id
	
	# Get layout data
	var layout = room_system.get_room_layout(room_data.id)
	if layout.is_empty():
		print("⚠️ No layout found for room: ", room_data.id)
		layout = {"size": Vector2(20, 20), "entrance_pos": Vector2(10, 2), "exit_pos": Vector2(10, 18)}
	
	# Create room structure
	create_room_floor(room_scene, layout)
	create_room_walls(room_scene, layout)
	create_room_doors(room_scene, layout, room_data)
	
	# Spawn content based on room type
	match room_data.type:
		room_system.RoomType.COMBAT:
			spawn_combat_content(room_scene, layout, room_data)
		room_system.RoomType.ELITE:
			spawn_elite_content(room_scene, layout, room_data)
		room_system.RoomType.TREASURE:
			spawn_treasure_content(room_scene, layout, room_data)
		room_system.RoomType.BOSS:
			spawn_boss_content(room_scene, layout, room_data)
	
	print("🏗️ Room scene created: ", room_data.id, " (Type: ", room_system.RoomType.keys()[room_data.type], ")")
	return room_scene

func create_room_floor(room_scene: Node3D, layout: Dictionary):
	"""Create room floor"""
	var floor = StaticBody3D.new()
	floor.name = "Floor"
	
	var size = layout.get("size", Vector2(20, 20))
	# Posiciona o chão no centro da sala
	floor.position = Vector3(size.x/2, 0, size.y/2)
	
	# Floor mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(size.x, 0.2, size.y)
	mesh_instance.mesh = box_mesh
	
	# Floor material - more visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.8, 0.4)  # Bright sandy color
	material.roughness = 0.8
	material.metallic = 0.1
	mesh_instance.material_override = material
	
	# Floor collision
	var collision = CollisionShape3D.new()
	var collision_shape = BoxShape3D.new()
	collision_shape.size = box_mesh.size
	collision.shape = collision_shape
	
	floor.add_child(mesh_instance)
	floor.add_child(collision)
	
	# Add floor to environment group for projectile collision
	floor.add_to_group("environment")
	
	room_scene.add_child(floor)

func create_room_walls(room_scene: Node3D, layout: Dictionary):
	"""Create room walls"""
	var walls = Node3D.new()
	walls.name = "Walls"
	
	var size = layout.get("size", Vector2(20, 20))
	var wall_height = 4.0
	var wall_thickness = 0.5
	
	# Wall positions and sizes (corrigidas para ficar nas bordas da sala)
	var wall_data = [
		{"pos": Vector3(-wall_thickness/2, wall_height/2, size.y/2), "size": Vector3(wall_thickness, wall_height, size.y)},  # Left wall
		{"pos": Vector3(size.x + wall_thickness/2, wall_height/2, size.y/2), "size": Vector3(wall_thickness, wall_height, size.y)},  # Right wall
		{"pos": Vector3(size.x/2, wall_height/2, -wall_thickness/2), "size": Vector3(size.x, wall_height, wall_thickness)},  # Back wall
		{"pos": Vector3(size.x/2, wall_height/2, size.y + wall_thickness/2), "size": Vector3(size.x, wall_height, wall_thickness)}   # Front wall
	]
	
	for i in range(wall_data.size()):
		var wall = create_wall(wall_data[i].pos, wall_data[i].size, i)
		walls.add_child(wall)
	
	room_scene.add_child(walls)

func create_wall(position: Vector3, size: Vector3, wall_id: int) -> StaticBody3D:
	"""Create individual wall"""
	var wall = StaticBody3D.new()
	wall.name = "Wall_" + str(wall_id)
	wall.position = position
	
	# Wall mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	
	# Wall material - more visible
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.5, 0.3)  # Darker stone color
	material.roughness = 0.9
	material.metallic = 0.0
	mesh_instance.material_override = material
	
	# Wall collision
	var collision = CollisionShape3D.new()
	var collision_shape = BoxShape3D.new()
	collision_shape.size = size
	collision.shape = collision_shape
	
	wall.add_child(mesh_instance)
	wall.add_child(collision)
	
	# Add to walls group for projectile collision
	wall.add_to_group("walls")
	
	return wall

func create_room_doors(room_scene: Node3D, layout: Dictionary, room_data):
	"""Create doors/exits"""
	var doors = Node3D.new()
	doors.name = "Doors"
	
	# Entrance door
	var entrance_pos = layout.get("entrance_pos", Vector2(10, 2))
	var entrance_door = create_door(Vector3(entrance_pos.x, 0, entrance_pos.y), "entrance")
	doors.add_child(entrance_door)
	
	# Exit doors based on connections
	for connected_room_id in room_data.connections:
		var connected_room = room_system.rooms.get(connected_room_id)
		if connected_room:
			var door_pos = calculate_door_position(room_data, connected_room)
			var exit_door = create_door(door_pos, connected_room_id)
			doors.add_child(exit_door)
	
	room_scene.add_child(doors)

func calculate_door_position(from_room, to_room) -> Vector3:
	"""Calculate door position based on room connection"""
	var diff = to_room.position - from_room.position
	var base_pos = Vector3(10, 0, 10)  # Center of room
	
	if diff.x > 0:  # Right - porta na parede direita
		base_pos.x = 19
		base_pos.z = 10
	elif diff.x < 0:  # Left - porta na parede esquerda
		base_pos.x = 1
		base_pos.z = 10
	elif diff.y > 0:  # Up - porta na parede de cima
		base_pos.x = 10
		base_pos.z = 19
	elif diff.y < 0:  # Down - porta na parede de baixo
		base_pos.x = 10
		base_pos.z = 1
	
	return base_pos

func create_door(position: Vector3, door_id: String) -> Area3D:
	"""Create door/transition area"""
	var door = Area3D.new()
	door.name = "Door_" + door_id
	door.position = position
	
	# Door collision for detection
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, 3, 0.5)
	collision.shape = shape
	door.add_child(collision)
	
	# Door visual
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2, 3, 0.1)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.3, 0.2)  # Dark wood
	mesh_instance.material_override = material
	door.add_child(mesh_instance)
	
	# Connect door signal
	door.body_entered.connect(func(body): _on_door_entered(door_id, body))
	
	# Store door metadata
	door.set_meta("target_room", door_id)
	
	return door

func spawn_combat_content(room_scene: Node3D, layout: Dictionary, _room_data):
	"""Spawn enemies for combat room"""
	var spawns = layout.get("enemy_spawns", [])
	
	for spawn_data in spawns:
		# Add visual marker for spawn point
		var marker = create_spawn_marker(spawn_data.position)
		room_scene.add_child(marker)
		
		# Spawn enemy (se habilitado)
		var enemy = spawn_enemy(spawn_data)
		if enemy:
			enemy.position = Vector3(spawn_data.position.x, 1, spawn_data.position.y)
			room_scene.add_child(enemy)
			spawned_enemies.append(enemy)
			print("🗡️ Enemy spawned at: ", enemy.position)
	
	print("⚔️ Combat room spawned with ", spawns.size(), " enemies (optimized)")

func spawn_elite_content(room_scene: Node3D, layout: Dictionary, _room_data):
	"""Spawn elite enemies"""
	var spawns = layout.get("enemy_spawns", [])
	
	for spawn_data in spawns:
		# Add visual marker for spawn point
		var marker = create_spawn_marker(spawn_data.position)
		room_scene.add_child(marker)
		
		# Spawn enemy (se habilitado)
		var enemy = spawn_enemy(spawn_data)
		if enemy:
			enemy.position = Vector3(spawn_data.position.x, 1, spawn_data.position.y)
			room_scene.add_child(enemy)
			spawned_enemies.append(enemy)
			print("🗡️ Enemy spawned at: ", enemy.position)
			
			# Mark elite enemies
			if spawn_data.get("is_elite", false):
				enemy.set_meta("is_elite", true)
	
	print("👑 Elite room spawned with ", spawns.size(), " enemies (optimized)")

func spawn_treasure_content(room_scene: Node3D, layout: Dictionary, room_data):
	"""Spawn treasure chests"""
	var spawns = layout.get("treasure_spawns", [])
	
	for spawn_data in spawns:
		var chest = create_treasure_chest(spawn_data)
		if chest:
			chest.position = Vector3(spawn_data.position.x, 0.5, spawn_data.position.y)
			room_scene.add_child(chest)
			spawned_objects.append(chest)
	
	print("💰 Treasure room spawned with ", spawns.size(), " chests")

func spawn_boss_content(room_scene: Node3D, layout: Dictionary, room_data):
	"""Spawn boss and room elements"""
	var boss_data = layout.get("boss_spawn", {})
	
	if not boss_data.is_empty():
		var boss = spawn_boss_enemy(boss_data)
		if boss:
			boss.position = Vector3(boss_data.position.x, 0, boss_data.position.y)
			room_scene.add_child(boss)
			spawned_enemies.append(boss)
			boss.set_meta("is_boss", true)
	
	# Spawn pillars
	var pillars = layout.get("pillars", [])
	for pillar_data in pillars:
		var pillar = create_pillar(pillar_data)
		if pillar:
			pillar.position = Vector3(pillar_data.position.x, 1, pillar_data.position.y)
			room_scene.add_child(pillar)
			spawned_objects.append(pillar)
	
	print("🐉 Boss room spawned with boss and ", pillars.size(), " pillars")

func create_spawn_marker(position: Vector2) -> MeshInstance3D:
	"""Create visual marker for spawn points"""
	var marker = MeshInstance3D.new()
	marker.name = "SpawnMarker"
	# Corrigir posição relativa à sala
	marker.position = Vector3(position.x, 1.0, position.y)
	
	# Cylinder mesh for marker
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 0.2
	cylinder_mesh.top_radius = 0.8
	cylinder_mesh.bottom_radius = 0.8
	marker.mesh = cylinder_mesh
	
	# Red material for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color(1, 0.2, 0.2)
	marker.material_override = material
	
	return marker

func spawn_enemy(spawn_data: Dictionary) -> CharacterBody3D:
	"""Spawn a single enemy"""
	# Load enemy scene (placeholder for now)
	var enemy_scene = preload("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Configure enemy based on spawn_data
	enemy.add_to_group("enemies")
	
	return enemy

func spawn_boss_enemy(boss_data: Dictionary) -> CharacterBody3D:
	"""Spawn boss enemy"""
	# For now, use basic enemy as placeholder
	var enemy = spawn_enemy({"enemy_type": "boss"})
	if enemy:
		# Scale up for boss
		enemy.scale = Vector3(2, 2, 2)
		if enemy.has_method("set_boss_stats"):
			enemy.set_boss_stats()
	
	return enemy

func create_treasure_chest(chest_data: Dictionary) -> StaticBody3D:
	"""Create treasure chest"""
	var chest = StaticBody3D.new()
	chest.name = "TreasureChest"
	
	# Chest mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 0.8, 1)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GOLDENROD
	material.metallic = 0.8
	mesh_instance.material_override = material
	
	chest.add_child(mesh_instance)
	
	# Interaction area
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 1.5)
	collision.shape = shape
	area.add_child(collision)
	chest.add_child(area)
	
	area.body_entered.connect(_on_chest_interacted.bind(chest_data))
	
	return chest

func create_pillar(pillar_data: Dictionary) -> StaticBody3D:
	"""Create pillar for boss room"""
	var pillar = StaticBody3D.new()
	pillar.name = "Pillar"
	
	# Pillar mesh
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.5
	cylinder_mesh.bottom_radius = 0.5
	cylinder_mesh.height = 3.0
	mesh_instance.mesh = cylinder_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.5, 0.4)  # Stone
	mesh_instance.material_override = material
	
	# Pillar collision
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = 3.0
	shape.top_radius = 0.5
	shape.bottom_radius = 0.5
	collision.shape = shape
	
	pillar.add_child(mesh_instance)
	pillar.add_child(collision)
	
	# Mark destructible pillars
	if pillar_data.get("destructible", false):
		pillar.set_meta("destructible", true)
	
	return pillar

func activate_cached_room(room_id: String) -> bool:
	"""Activate room from cache"""
	var room_scene = loaded_room_scenes.get(room_id)
	if not room_scene:
		return false
	
	return activate_room_scene(room_scene, room_id)

func activate_room_scene(room_scene: Node3D, room_id: String) -> bool:
	"""Activate room scene"""
	# Cleanup current room first
	if current_room_scene:
		cleanup_current_room()
	
	# Add new room to scene tree
	get_tree().current_scene.add_child(room_scene)
	current_room_scene = room_scene
	current_room_id = room_id
	
	# Position player at entrance
	position_player_at_entrance(room_id)
	
	# Emit signals
	room_loaded.emit(room_id)
	
	print("✅ Room activated: ", room_id)
	return true

func position_player_at_entrance(room_id: String):
	"""Position player at room entrance"""
	if not player:
		return
	
	var layout = room_system.get_room_layout(room_id)
	var entrance_pos = layout.get("entrance_pos", Vector2(10, 2))
	var room_size = layout.get("size", Vector2(20, 20))
	
	# Ensure player is within room bounds and on floor
	var safe_x = clamp(entrance_pos.x, 2, room_size.x - 2)
	var safe_y = clamp(entrance_pos.y, 2, room_size.y - 2) 
	
	# Position player above floor level (Y=2.0 to be above floor)
	player.global_position = Vector3(safe_x, 2.0, safe_y)
	
	print("👑 Player positioned at entrance: (", safe_x, ", 2.0, ", safe_y, ")")
	print("🏠 Room size: ", room_size)

func transition_to_room(target_room_id: String):
	"""Start room transition"""
	if is_transitioning:
		return
	
	var room_data = room_system.rooms.get(target_room_id)
	if not room_data:
		print("❌ Target room not found: ", target_room_id)
		return
	
	if room_data.state == room_system.RoomState.LOCKED:
		print("🔒 Room is locked: ", target_room_id)
		return
	
	print("🚪 Starting transition to room: ", target_room_id)
	
	is_transitioning = true
	transition_timer = 0.0
	transition_progress = 0.0
	
	room_transition_started.emit(current_room_id, target_room_id)
	
	# Add frame delays to prevent GPU spike
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Load target room
	if load_room(target_room_id):
		# Notify room system
		room_system._on_room_entered(room_data.type, target_room_id)
	else:
		print("❌ Failed to load target room: ", target_room_id)
		is_transitioning = false

func complete_transition():
	"""Complete room transition"""
	is_transitioning = false
	transition_timer = 0.0
	transition_progress = 0.0
	
	room_transition_completed.emit(current_room_id)
	print("✅ Room transition completed: ", current_room_id)

func cleanup_current_room():
	"""Cleanup current room resources (otimizado)"""
	if current_room_scene and is_instance_valid(current_room_scene):
		# Cleanup em lotes para reduzir pico de GPU
		if not spawned_enemies.is_empty():
			var batch_size = 3  # Processa apenas 3 por vez
			var count = 0
			for enemy in spawned_enemies:
				if is_instance_valid(enemy):
					enemy.queue_free()
				count += 1
				if count >= batch_size:
					await get_tree().process_frame  # Pausa para próximo frame
					count = 0
		
		# Mesmo para objetos
		if not spawned_objects.is_empty():
			var batch_size = 5
			var count = 0
			for obj in spawned_objects:
				if is_instance_valid(obj):
					obj.queue_free()
				count += 1
				if count >= batch_size:
					await get_tree().process_frame
					count = 0
		
		spawned_enemies.clear()
		spawned_objects.clear()
		
		# Remove room scene com delay
		await get_tree().process_frame
		if current_room_id not in loaded_room_scenes:
			current_room_scene.queue_free()
		else:
			current_room_scene.get_parent().remove_child(current_room_scene)
		
		room_cleanup_completed.emit(current_room_id)
		print("🧹 Room cleanup completed (optimized): ", current_room_id)

func manage_room_cache():
	"""Manage room cache size"""
	if loaded_room_scenes.size() <= MAX_CACHED_ROOMS:
		return
	
	# Remove oldest cached room (simple FIFO for now)
	var oldest_room_id = loaded_room_scenes.keys()[0]
	var oldest_scene = loaded_room_scenes[oldest_room_id]
	
	if oldest_scene and is_instance_valid(oldest_scene):
		oldest_scene.queue_free()
	
	loaded_room_scenes.erase(oldest_room_id)
	print("🗑️ Removed cached room: ", oldest_room_id)

func _on_door_entered(target_room_id: String, body: Node):
	"""Handle door interaction"""
	if body.is_in_group("player") and not is_transitioning:
		transition_to_room(target_room_id)

func _on_chest_interacted(chest_data: Dictionary, body: Node):
	"""Handle treasure chest interaction"""
	if body.is_in_group("player"):
		print("💰 Chest opened: ", chest_data.get("treasure_type", "unknown"))
		# TODO: Add treasure to player inventory

func _on_room_entered(room_type, room_id: String):
	"""Handle room entered event"""
	print("🏠 Room Manager: Room entered - ", room_id)

func _on_room_cleared(room_id: String):
	"""Handle room cleared event"""
	print("✅ Room Manager: Room cleared - ", room_id)

func get_room_manager_info() -> Dictionary:
	"""Get room manager information"""
	return {
		"current_room_id": current_room_id,
		"is_transitioning": is_transitioning,
		"transition_progress": transition_progress,
		"cached_rooms": loaded_room_scenes.keys(),
		"spawned_enemies": spawned_enemies.size(),
		"spawned_objects": spawned_objects.size()
	}
