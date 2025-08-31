extends Node
## Sistema de Salas Procedural - Sprint 6
## Geração de salas conectadas com 4 tipos diferentes

signal room_generated(room_data)
signal room_entered(room_type, room_id)
signal room_cleared(room_id)
signal boss_room_unlocked

# Referência ao GameManager
var game_manager: Node

# Tipos de salas
enum RoomType {
	COMBAT,
	ELITE, 
	TREASURE,
	BOSS
}

# Estados das salas
enum RoomState {
	LOCKED,
	AVAILABLE,
	CURRENT,
	CLEARED
}

# Estrutura de dados das salas
class RoomData:
	var id: String
	var type: RoomType
	var state: RoomState = RoomState.LOCKED
	var position: Vector2i  # Grid position
	var connections: Array[String] = []  # Connected room IDs
	var layout_id: int = 0
	var enemies: Array[Dictionary] = []
	var rewards: Array[Dictionary] = []
	var scene_path: String = ""
	
	func _init(room_id: String, room_type: RoomType, grid_pos: Vector2i):
		id = room_id
		type = room_type
		position = grid_pos

# Sistema de geração
var current_floor: int = 1
var rooms: Dictionary = {}  # String -> RoomData
var current_room_id: String = ""
var room_grid: Array[Array] = []  # 2D grid for room placement

# Configurações de geração
const GRID_SIZE = Vector2i(7, 5)  # 7x5 grid para layouts
const MIN_COMBAT_ROOMS = 8
const MAX_COMBAT_ROOMS = 12
const ELITE_ROOMS = 2
const TREASURE_ROOMS = 2
const BOSS_ROOMS = 1

# Layouts de salas por tipo (15 por tipo conforme ROADMAP)
var room_layouts: Dictionary = {
	RoomType.COMBAT: [],
	RoomType.ELITE: [],
	RoomType.TREASURE: [],
	RoomType.BOSS: []
}

func _ready():
	print("🏛️ Room System initialized - Sprint 6")
	
	# Get GameManager reference
	if get_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	
	# Initialize room layouts
	setup_room_layouts()
	
	# Connect signals
	connect_signals()
	
	print("🏠 Room layouts loaded - Ready for procedural generation")

func setup_room_layouts():
	"""Setup 15 basic layouts per room type"""
	# Combat Room Layouts
	for i in range(15):
		room_layouts[RoomType.COMBAT].append({
			"layout_id": i,
			"name": "Combat Layout " + str(i + 1),
			"enemy_spawns": generate_combat_spawns(i),
			"size": Vector2(20, 20),
			"entrance_pos": Vector2(10, 2),
			"exit_pos": Vector2(10, 18)
		})
	
	# Elite Room Layouts
	for i in range(15):
		room_layouts[RoomType.ELITE].append({
			"layout_id": i,
			"name": "Elite Layout " + str(i + 1),
			"enemy_spawns": generate_elite_spawns(i),
			"size": Vector2(25, 25),
			"entrance_pos": Vector2(12, 2),
			"exit_pos": Vector2(12, 23),
			"arena_center": Vector2(12, 12)
		})
	
	# Treasure Room Layouts
	for i in range(15):
		room_layouts[RoomType.TREASURE].append({
			"layout_id": i,
			"name": "Treasure Layout " + str(i + 1),
			"treasure_spawns": generate_treasure_spawns(i),
			"size": Vector2(15, 15),
			"entrance_pos": Vector2(7, 2),
			"exit_pos": Vector2(7, 13)
		})
	
	# Boss Room Layouts
	for i in range(15):
		room_layouts[RoomType.BOSS].append({
			"layout_id": i,
			"name": "Boss Layout " + str(i + 1),
			"boss_spawn": generate_boss_spawns(i),
			"size": Vector2(30, 30),
			"entrance_pos": Vector2(15, 2),
			"arena_center": Vector2(15, 15),
			"pillars": generate_boss_pillars(i)
		})

func generate_combat_spawns(_layout_id: int) -> Array:
	"""Generate enemy spawn points for combat rooms"""
	var spawns = []
	
	# Reduzido para performance: apenas 1 inimigo por sala
	var enemy_count = 1  # Fixo em 1 para melhor performance
	for i in range(enemy_count):
		spawns.append({
			"position": Vector2(8 + i * 4, 10),
			"enemy_type": "basic"
		})
	
	return spawns

func generate_elite_spawns(_layout_id: int) -> Array:
	"""Generate elite enemy spawns"""
	var spawns = []
	
	# Apenas 1 elite para melhor performance
	spawns.append({
		"position": Vector2(12, 12),
		"enemy_type": "elite",
		"is_elite": true
	})
	
	return spawns

func generate_treasure_spawns(layout_id: int) -> Array:
	"""Generate treasure chest positions"""
	var spawns = []
	
	# Main treasure always in center
	spawns.append({
		"position": Vector2(7, 7),
		"treasure_type": "chest_main",
		"rarity": "rare"
	})
	
	# Optional smaller treasures
	if layout_id % 3 == 0:
		spawns.append({
			"position": Vector2(4, 7),
			"treasure_type": "chest_small",
			"rarity": "common"
		})
		spawns.append({
			"position": Vector2(10, 7),
			"treasure_type": "chest_small",
			"rarity": "common"
		})
	
	return spawns

func generate_boss_spawns(layout_id: int) -> Dictionary:
	"""Generate boss spawn data"""
	return {
		"position": Vector2(15, 15),
		"boss_type": "floor_" + str(current_floor) + "_boss",
		"phase_positions": [
			Vector2(15, 15),  # Phase 1
			Vector2(10, 10),  # Phase 2
			Vector2(20, 20)   # Phase 3
		]
	}

func generate_boss_pillars(layout_id: int) -> Array:
	"""Generate destructible pillars for boss room"""
	var pillars = []
	
	# 4 corner pillars always
	pillars.append({"position": Vector2(8, 8), "destructible": true})
	pillars.append({"position": Vector2(22, 8), "destructible": true})
	pillars.append({"position": Vector2(8, 22), "destructible": true})
	pillars.append({"position": Vector2(22, 22), "destructible": true})
	
	# Additional pillars based on layout
	if layout_id % 2 == 0:
		pillars.append({"position": Vector2(15, 8), "destructible": false})
		pillars.append({"position": Vector2(15, 22), "destructible": false})
	
	return pillars

func generate_floor(floor_number: int) -> Dictionary:
	"""Generate a complete floor with connected rooms"""
	print("🏗️ Generating Floor ", floor_number)
	
	current_floor = floor_number
	rooms.clear()
	
	# Initialize grid
	room_grid.clear()
	for x in range(GRID_SIZE.x):
		room_grid.append([])
		for y in range(GRID_SIZE.y):
			room_grid[x].append(null)
	
	# Generate room layout
	var room_count = generate_room_structure()
	
	# Assign room types
	assign_room_types()
	
	# Create connections
	create_room_connections()
	
	# Set starting room
	var start_room = find_starting_room()
	if start_room:
		current_room_id = start_room.id
		start_room.state = RoomState.CURRENT
	
	print("✅ Floor ", floor_number, " generated with ", room_count, " rooms")
	
	return {
		"floor": floor_number,
		"rooms": rooms,
		"current_room": current_room_id,
		"total_rooms": room_count
	}

func generate_room_structure() -> int:
	"""Generate the basic room structure on grid"""
	var room_count = 0
	
	# Start with center bottom (entrance)
	var start_pos = Vector2i(GRID_SIZE.x / 2, 0)
	var room_id = "room_" + str(room_count)
	var room_data = RoomData.new(room_id, RoomType.COMBAT, start_pos)
	rooms[room_id] = room_data
	room_grid[start_pos.x][start_pos.y] = room_data
	room_count += 1
	
	# Generate main path upward with branches
	var current_pos = start_pos
	var path_positions = [current_pos]
	
	# Main vertical path
	for y in range(1, GRID_SIZE.y - 1):
		current_pos = Vector2i(start_pos.x, y)
		room_id = "room_" + str(room_count)
		room_data = RoomData.new(room_id, RoomType.COMBAT, current_pos)
		rooms[room_id] = room_data
		room_grid[current_pos.x][current_pos.y] = room_data
		path_positions.append(current_pos)
		room_count += 1
	
	# Boss room at top
	var boss_pos = Vector2i(start_pos.x, GRID_SIZE.y - 1)
	room_id = "room_boss"
	room_data = RoomData.new(room_id, RoomType.BOSS, boss_pos)
	rooms[room_id] = room_data
	room_grid[boss_pos.x][boss_pos.y] = room_data
	path_positions.append(boss_pos)
	room_count += 1
	
	# Add side branches
	for pos in path_positions:
		if pos.y > 0 and pos.y < GRID_SIZE.y - 1:  # Not at top/bottom
			# Chance for left branch
			if randf() < 0.4 and pos.x > 0:
				var branch_pos = Vector2i(pos.x - 1, pos.y)
				if not room_grid[branch_pos.x][branch_pos.y]:
					room_id = "room_" + str(room_count)
					room_data = RoomData.new(room_id, RoomType.COMBAT, branch_pos)
					rooms[room_id] = room_data
					room_grid[branch_pos.x][branch_pos.y] = room_data
					room_count += 1
			
			# Chance for right branch
			if randf() < 0.4 and pos.x < GRID_SIZE.x - 1:
				var branch_pos = Vector2i(pos.x + 1, pos.y)
				if not room_grid[branch_pos.x][branch_pos.y]:
					room_id = "room_" + str(room_count)
					room_data = RoomData.new(room_id, RoomType.COMBAT, branch_pos)
					rooms[room_id] = room_data
					room_grid[branch_pos.x][branch_pos.y] = room_data
					room_count += 1
	
	return room_count

func assign_room_types():
	"""Assign types to generated rooms"""
	var room_list = rooms.values()
	var combat_rooms = []
	var boss_room = null
	
	# Find boss room and separate combat rooms
	for room in room_list:
		if room.type == RoomType.BOSS:
			boss_room = room
		else:
			combat_rooms.append(room)
	
	# Shuffle combat rooms for random assignment
	combat_rooms.shuffle()
	
	# Assign elite rooms (furthest from start)
	var elite_count = 0
	for i in range(combat_rooms.size() - 1, -1, -1):
		if elite_count < ELITE_ROOMS:
			combat_rooms[i].type = RoomType.ELITE
			elite_count += 1
			combat_rooms.remove_at(i)
		if elite_count >= ELITE_ROOMS:
			break
	
	# Assign treasure rooms (random selection)
	var treasure_count = 0
	for i in range(combat_rooms.size() - 1, -1, -1):
		if treasure_count < TREASURE_ROOMS and randf() < 0.3:
			combat_rooms[i].type = RoomType.TREASURE
			treasure_count += 1
			combat_rooms.remove_at(i)
		if treasure_count >= TREASURE_ROOMS:
			break
	
	# Remaining are combat rooms
	print("🎯 Room types assigned - Combat: ", combat_rooms.size(), 
		  " Elite: ", elite_count, " Treasure: ", treasure_count, " Boss: 1")

func create_room_connections():
	"""Create connections between adjacent rooms"""
	for room_id in rooms:
		var room = rooms[room_id]
		var pos = room.position
		
		# Check all 4 directions
		var directions = [
			Vector2i(0, -1),  # Up
			Vector2i(0, 1),   # Down
			Vector2i(-1, 0),  # Left
			Vector2i(1, 0)    # Right
		]
		
		for dir in directions:
			var check_pos = pos + dir
			if is_valid_grid_pos(check_pos):
				var adjacent_room = room_grid[check_pos.x][check_pos.y]
				if adjacent_room:
					room.connections.append(adjacent_room.id)
	
	print("🔗 Room connections created")

func is_valid_grid_pos(pos: Vector2i) -> bool:
	"""Check if grid position is valid"""
	return pos.x >= 0 and pos.x < GRID_SIZE.x and pos.y >= 0 and pos.y < GRID_SIZE.y

func find_starting_room() -> RoomData:
	"""Find the starting room (bottom center)"""
	var start_pos = Vector2i(GRID_SIZE.x / 2, 0)
	if is_valid_grid_pos(start_pos):
		return room_grid[start_pos.x][start_pos.y]
	return null

func connect_signals():
	"""Connect important signals"""
	room_entered.connect(_on_room_entered)
	room_cleared.connect(_on_room_cleared)

func _on_room_entered(room_type: RoomType, room_id: String):
	"""Handle room entry"""
	print("🚪 Entered room: ", room_id, " (Type: ", RoomType.keys()[room_type], ")")
	current_room_id = room_id
	
	# Update room states
	if room_id in rooms:
		rooms[room_id].state = RoomState.CURRENT

func _on_room_cleared(room_id: String):
	"""Handle room completion"""
	if room_id in rooms:
		var room = rooms[room_id]
		room.state = RoomState.CLEARED
		
		# Unlock connected rooms
		for connected_id in room.connections:
			if connected_id in rooms:
				var connected_room = rooms[connected_id]
				if connected_room.state == RoomState.LOCKED:
					connected_room.state = RoomState.AVAILABLE
		
		print("✅ Room cleared: ", room_id, " - Connected rooms unlocked")

func get_current_room() -> RoomData:
	"""Get current room data"""
	if current_room_id in rooms:
		return rooms[current_room_id]
	return null

func get_room_layout(room_id: String) -> Dictionary:
	"""Get layout data for a specific room"""
	if room_id in rooms:
		var room = rooms[room_id]
		return room_layouts[room.type][room.layout_id % 15]
	return {}

func get_available_exits() -> Array:
	"""Get available room exits from current room"""
	var current_room = get_current_room()
	if not current_room:
		return []
	
	var available_exits = []
	for connected_id in current_room.connections:
		if connected_id in rooms:
			var connected_room = rooms[connected_id]
			if connected_room.state != RoomState.LOCKED:
				available_exits.append(connected_id)
	
	return available_exits

func get_room_info() -> Dictionary:
	"""Get room system information for UI/debug"""
	var current_room = get_current_room()
	
	return {
		"current_floor": current_floor,
		"total_rooms": rooms.size(),
		"current_room_id": current_room_id,
		"current_room_type": RoomType.keys()[current_room.type] if current_room else "None",
		"available_exits": get_available_exits(),
		"rooms_cleared": get_cleared_room_count(),
		"boss_unlocked": is_boss_room_available()
	}

func get_cleared_room_count() -> int:
	"""Count cleared rooms"""
	var count = 0
	for room_id in rooms:
		if rooms[room_id].state == RoomState.CLEARED:
			count += 1
	return count

func is_boss_room_available() -> bool:
	"""Check if boss room is unlocked"""
	for room_id in rooms:
		var room = rooms[room_id]
		if room.type == RoomType.BOSS:
			return room.state != RoomState.LOCKED
	return false
