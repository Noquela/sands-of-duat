extends Node3D
class_name RoomSystem

signal room_entered(room_data: Dictionary)
signal room_exited(room_data: Dictionary)
signal room_completed(room_data: Dictionary)

enum RoomType {
	COMBAT,
	ELITE,
	TREASURE,
	BOSS
}

enum RoomState {
	INACTIVE,
	ACTIVE,
	COMPLETED,
	LOCKED
}

@export_group("Room Settings")
@export var room_size: Vector3 = Vector3(20, 6, 20)
@export var corridor_width: float = 4.0
@export var door_size: Vector3 = Vector3(2, 3, 0.5)

@export_group("Generation Settings")
@export var rooms_per_floor: int = 8
@export var boss_room_position: int = 7  # Always last room
@export var treasure_room_chance: float = 0.3
@export var elite_room_chance: float = 0.2

# Room management
var current_room: Dictionary
var room_database: Array[Dictionary] = []
var room_instances: Array[Node3D] = []
var room_connections: Dictionary = {}

# Player reference
var player: Node3D

# Room layouts storage
var room_layouts = {
	RoomType.COMBAT: [],
	RoomType.ELITE: [],
	RoomType.TREASURE: [],
	RoomType.BOSS: []
}

func _ready():
	# Add to group for easy finding
	add_to_group("room_system")
	
	setup_room_system()
	initialize_room_layouts()
	
	# Wait a frame for player to be ready
	call_deferred("find_player_and_start")

func find_player_and_start():
	player = get_tree().get_first_node_in_group("player")
	
	# Start player in room 0
	if player:
		transition_to_room(0)

func setup_room_system():
	# Initialize room database
	generate_room_sequence()
	
	# Don't auto-create rooms - let them be created on demand
	print("Room system initialized with ", room_database.size(), " rooms planned")

func initialize_room_layouts():
	# Initialize combat room layouts
	for i in range(15):
		room_layouts[RoomType.COMBAT].append(generate_combat_layout(i))
	
	# Initialize elite room layouts
	for i in range(15):
		room_layouts[RoomType.ELITE].append(generate_elite_layout(i))
	
	# Initialize treasure room layouts
	for i in range(15):
		room_layouts[RoomType.TREASURE].append(generate_treasure_layout(i))
	
	# Initialize boss room layouts
	for i in range(15):
		room_layouts[RoomType.BOSS].append(generate_boss_layout(i))
	
	print("Room layouts initialized: ", room_layouts[RoomType.COMBAT].size(), " per type")

func generate_room_sequence():
	room_database.clear()
	
	# Generate room types for this floor
	for i in range(rooms_per_floor):
		var room_data = {
			"id": i,
			"type": determine_room_type(i),
			"state": RoomState.INACTIVE,
			"layout_id": randi() % 15,
			"connections": [],
			"spawn_points": [],
			"reward_points": [],
			"position": Vector3(i * (room_size.x + corridor_width), 0, 0),
			"enemies_alive": 0,
			"is_cleared": false
		}
		
		# Set connections (linear for now - can be made more complex)
		if i > 0:
			room_data.connections.append(i - 1)
		if i < rooms_per_floor - 1:
			room_data.connections.append(i + 1)
		
		room_database.append(room_data)
		print("Generated room ", i, " - Type: ", get_room_type_name(room_data.type))

func determine_room_type(room_index: int) -> RoomType:
	# Boss room is always last
	if room_index == boss_room_position:
		return RoomType.BOSS
	
	# First room is always combat
	if room_index == 0:
		return RoomType.COMBAT
	
	# Random chance for special rooms
	var rand = randf()
	if rand < treasure_room_chance:
		return RoomType.TREASURE
	elif rand < treasure_room_chance + elite_room_chance:
		return RoomType.ELITE
	else:
		return RoomType.COMBAT

func create_room(room_id: int) -> Node3D:
	if room_id >= room_database.size():
		print("Error: Room ID ", room_id, " not found in database")
		return null
	
	var room_data = room_database[room_id]
	var room_instance = Node3D.new()
	room_instance.name = "Room_" + str(room_id)
	room_instance.position = room_data.position
	
	# Mark as temporary so it doesn't get saved
	room_instance.set_owner(null)
	
	# Build room geometry
	build_room_geometry(room_instance, room_data)
	
	# Add room to scene root instead of RoomSystem
	get_tree().current_scene.add_child(room_instance)
	room_instances.append(room_instance)
	
	print("Created room ", room_id, " at ", room_data.position)
	return room_instance

func build_room_geometry(room_instance: Node3D, room_data: Dictionary):
	# Create floor
	create_room_floor(room_instance, room_data)
	
	# Create walls
	create_room_walls(room_instance, room_data)
	
	# Create doors
	create_room_doors(room_instance, room_data)
	
	# Add spawn points and rewards based on room type
	setup_room_content(room_instance, room_data)

func create_room_floor(room_instance: Node3D, _room_data: Dictionary):
	var floor_body = StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 4  # Environment layer
	
	var floor_mesh = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(room_size.x, room_size.z)
	floor_mesh.mesh = plane_mesh
	
	var floor_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(room_size.x, 0.2, room_size.z)
	floor_collision.shape = box_shape
	floor_collision.position.y = -0.1
	
	floor_body.add_child(floor_mesh)
	floor_body.add_child(floor_collision)
	room_instance.add_child(floor_body)

func create_room_walls(room_instance: Node3D, _room_data: Dictionary):
	# Create 4 walls around the room
	var wall_positions = [
		Vector3(0, room_size.y/2, room_size.z/2),      # North
		Vector3(0, room_size.y/2, -room_size.z/2),     # South  
		Vector3(room_size.x/2, room_size.y/2, 0),      # East
		Vector3(-room_size.x/2, room_size.y/2, 0)      # West
	]
	
	var wall_scales = [
		Vector3(room_size.x, room_size.y, 0.5),        # North
		Vector3(room_size.x, room_size.y, 0.5),        # South
		Vector3(0.5, room_size.y, room_size.z),        # East
		Vector3(0.5, room_size.y, room_size.z)         # West
	]
	
	for i in range(4):
		var wall_body = StaticBody3D.new()
		wall_body.name = "Wall_" + str(i)
		wall_body.collision_layer = 4
		wall_body.position = wall_positions[i]
		
		var wall_mesh = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = wall_scales[i]
		wall_mesh.mesh = box_mesh
		
		var wall_collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = wall_scales[i]
		wall_collision.shape = box_shape
		
		wall_body.add_child(wall_mesh)
		wall_body.add_child(wall_collision)
		room_instance.add_child(wall_body)

func create_room_doors(room_instance: Node3D, room_data: Dictionary):
	# Create doors based on connections
	for connection_id in room_data.connections:
		var door_direction = get_door_direction(room_data.id, connection_id)
		create_door(room_instance, door_direction, connection_id)

func get_door_direction(from_room: int, to_room: int) -> Vector3:
	# For linear room layout, determine direction
	if to_room > from_room:
		return Vector3(room_size.x/2, 1.5, 0)  # East door
	else:
		return Vector3(-room_size.x/2, 1.5, 0)  # West door

func create_door(room_instance: Node3D, door_position: Vector3, target_room_id: int):
	var door_area = Area3D.new()
	door_area.name = "Door_to_" + str(target_room_id)
	door_area.position = door_position
	
	var door_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = door_size
	door_collision.shape = box_shape
	
	var door_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = door_size
	door_mesh.mesh = box_mesh
	
	# Set door material (different color)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	door_mesh.set_surface_override_material(0, material)
	
	door_area.add_child(door_collision)
	door_area.add_child(door_mesh)
	room_instance.add_child(door_area)
	
	# Connect door signal
	door_area.body_entered.connect(_on_door_entered.bind(target_room_id))

func setup_room_content(_room_instance: Node3D, room_data: Dictionary):
	var layout = get_room_layout(room_data.type, room_data.layout_id)
	
	# Add spawn points
	room_data.spawn_points = layout.spawn_points.duplicate()
	
	# Add reward points  
	room_data.reward_points = layout.reward_points.duplicate()
	
	# Spawn points stored in room_data for enemy spawning
	# No visual markers needed

# Spawn markers removed - no debug visuals needed

func get_room_layout(room_type: RoomType, layout_id: int) -> Dictionary:
	return room_layouts[room_type][layout_id % room_layouts[room_type].size()]

# Room layout generators
func generate_combat_layout(layout_id: int) -> Dictionary:
	var layout = {
		"id": layout_id,
		"spawn_points": [],
		"reward_points": [],
		"special_features": []
	}
	
	# Generate 2-4 spawn points in combat rooms
	var spawn_count = 2 + (layout_id % 3)
	for i in range(spawn_count):
		var angle = (i * TAU) / spawn_count
		var radius = 6.0 + (i * 2.0)
		layout.spawn_points.append(Vector3(
			cos(angle) * radius,
			0.5,
			sin(angle) * radius
		))
	
	# Add reward point in center
	layout.reward_points.append(Vector3(0, 0.5, 0))
	
	return layout

func generate_elite_layout(layout_id: int) -> Dictionary:
	var layout = {
		"id": layout_id,
		"spawn_points": [],
		"reward_points": [],
		"special_features": ["elite_arena"]
	}
	
	# Single elite enemy in center
	layout.spawn_points.append(Vector3(0, 0.5, 5))
	
	# Better reward position
	layout.reward_points.append(Vector3(0, 0.5, -3))
	
	return layout

func generate_treasure_layout(layout_id: int) -> Dictionary:
	var layout = {
		"id": layout_id,
		"spawn_points": [],
		"reward_points": [],
		"special_features": ["treasure_chest", "bonus_rewards"]
	}
	
	# No enemies, just treasure
	layout.reward_points.append(Vector3(0, 0.5, 0))
	layout.reward_points.append(Vector3(3, 0.5, 3))
	layout.reward_points.append(Vector3(-3, 0.5, 3))
	
	return layout

func generate_boss_layout(layout_id: int) -> Dictionary:
	var layout = {
		"id": layout_id,
		"spawn_points": [],
		"reward_points": [],
		"special_features": ["boss_arena", "pillars", "altar"]
	}
	
	# Boss spawn point
	layout.spawn_points.append(Vector3(0, 0.5, 8))
	
	# Boss reward
	layout.reward_points.append(Vector3(0, 0.5, 0))
	
	return layout

# Room transition system
func _on_door_entered(body: Node3D, target_room_id: int):
	if body.is_in_group("player"):
		transition_to_room(target_room_id)

func transition_to_room(room_id: int):
	if room_id >= room_database.size():
		print("Error: Cannot transition to room ", room_id)
		return
	
	# Create first room if transitioning to room 0 for the first time
	if room_id == 0 and current_room.is_empty():
		create_room(0)
	
	# Check if room exists, create if not
	if room_id >= room_instances.size() or room_instances[room_id] == null:
		create_room(room_id)
	
	# Update current room
	var old_room = current_room
	current_room = room_database[room_id]
	current_room.state = RoomState.ACTIVE
	
	# Move player to new room
	if player:
		player.global_position = current_room.position + Vector3(0, 1, -5)
	
	# Emit signals
	if not old_room.is_empty():
		room_exited.emit(old_room)
	room_entered.emit(current_room)
	
	print("Transitioned to room ", room_id, " - Type: ", get_room_type_name(current_room.type))
	
	# Trigger god encounter chance (like Hades)
	if not old_room.is_empty() and room_id > 0:  # Don't trigger on first room
		trigger_god_encounter_chance()

func get_room_type_name(room_type: RoomType) -> String:
	match room_type:
		RoomType.COMBAT:
			return "Combat"
		RoomType.ELITE:
			return "Elite"
		RoomType.TREASURE:
			return "Treasure"
		RoomType.BOSS:
			return "Boss"
		_:
			return "Unknown"

# Public API
func get_current_room() -> Dictionary:
	return current_room

func get_room_count() -> int:
	return room_database.size()

func get_completed_rooms() -> int:
	var completed = 0
	for room in room_database:
		if room.state == RoomState.COMPLETED:
			completed += 1
	return completed

func mark_room_completed(room_id: int):
	if room_id < room_database.size():
		room_database[room_id].state = RoomState.COMPLETED
		room_database[room_id].is_cleared = true
		room_completed.emit(room_database[room_id])
		print("Room ", room_id, " marked as completed")

func get_room_info() -> Dictionary:
	return {
		"current_room": current_room,
		"total_rooms": get_room_count(),
		"completed_rooms": get_completed_rooms(),
		"room_database": room_database
	}

# Reward system integration (Hades-like)
func trigger_god_encounter_chance():
	var reward_system = get_tree().get_first_node_in_group("reward_system")
	if not reward_system:
		print("RewardSystem not found")
		return
	
	# Generate reward based on Hades mechanics
	var reward = reward_system.generate_room_reward()
	
	if reward.type == reward_system.RewardType.BOON:
		# Trigger boon encounter
		trigger_boon_encounter()
	else:
		# Show other reward
		trigger_other_reward(reward)

func trigger_boon_encounter():
	var boon_ui = get_tree().get_first_node_in_group("boon_selection_ui")
	if not boon_ui:
		# Find in scene tree
		var ui_layer = get_tree().current_scene.get_node("UI")
		if ui_layer and ui_layer.has_node("BoonSelectionUI"):
			boon_ui = ui_layer.get_node("BoonSelectionUI")
	
	if boon_ui and boon_ui.has_method("trigger_god_encounter"):
		var encounter_triggered = boon_ui.trigger_god_encounter()
		if encounter_triggered:
			print("God encounter triggered in room ", current_room.id)
	else:
		print("BoonSelectionUI not found for god encounter")

func trigger_other_reward(reward_data: Dictionary):
	var reward_ui = get_tree().get_first_node_in_group("reward_selection_ui")
	if not reward_ui:
		# Find in scene tree
		var ui_layer = get_tree().current_scene.get_node("UI")
		if ui_layer and ui_layer.has_node("RewardSelectionUI"):
			reward_ui = ui_layer.get_node("RewardSelectionUI")
	
	if reward_ui and reward_ui.has_method("show_reward"):
		reward_ui.show_reward(reward_data)
		print("Other reward triggered: ", reward_data.name, " in room ", current_room.id)
	else:
		print("RewardSelectionUI not found - auto-applying reward: ", reward_data.name)
		# Auto-apply if no UI
		var reward_system = get_tree().get_first_node_in_group("reward_system")
		if reward_system:
			reward_system.apply_reward(reward_data)