# RoomSystem.gd
# Procedural Room Generation System for Sands of Duat
# Sprint 6: Room System - Chamber generation with Egyptian theming

extends Node

signal room_generated(room_data: Dictionary)
signal room_entered(room_type: String, room_data: Dictionary)
signal room_cleared(completion_time: float, performance: Dictionary)
signal door_selected(reward_type: String, door_data: Dictionary)

# Room types following Hades structure
enum RoomType {
	COMBAT,     # Regular enemy encounters
	ELITE,      # Stronger enemies, better rewards
	TREASURE,   # Boon selection, currency
	BOSS,       # Major boss encounters
	HUB,        # Safe areas, Pool of Memories
	SPECIAL     # Chaos gates, Erebus gates equivalent
}

# Room layouts and templates
var room_templates: Dictionary = {}
var current_room: Dictionary = {}
var room_history: Array[Dictionary] = []

# Generation parameters
var rooms_per_biome: int = 12
var current_room_index: int = 0

# Room connections and doors
var available_doors: Array[Dictionary] = []
var selected_door_index: int = -1

func _ready():
	print("🏛️ RoomSystem: Sprint 6 Initialized")
	_setup_room_templates()
	_generate_room_sequence()

func _setup_room_templates():
	"""Setup Egyptian-themed room templates for each type"""
	
	# COMBAT ROOM TEMPLATES (8 layouts)
	room_templates[RoomType.COMBAT] = [
		{
			"name": "Burial Chamber",
			"size": Vector2(20, 20),
			"spawn_points": [
				Vector3(5, 0, 5), Vector3(-5, 0, 5), 
				Vector3(5, 0, -5), Vector3(-5, 0, -5)
			],
			"enemy_count": 3,
			"exits": ["north", "south"],
			"props": ["sarcophagus", "canopic_jars", "hieroglyph_wall"]
		},
		{
			"name": "Temple Courtyard", 
			"size": Vector2(25, 25),
			"spawn_points": [
				Vector3(8, 0, 8), Vector3(-8, 0, 8),
				Vector3(8, 0, -8), Vector3(-8, 0, -8),
				Vector3(0, 0, 0)
			],
			"enemy_count": 4,
			"exits": ["north", "south", "east"],
			"props": ["obelisk", "sphinx_statue", "sand_dunes"]
		},
		{
			"name": "Narrow Passage",
			"size": Vector2(15, 30),
			"spawn_points": [
				Vector3(0, 0, 10), Vector3(0, 0, 0), Vector3(0, 0, -10)
			],
			"enemy_count": 2,
			"exits": ["north", "south"],
			"props": ["torch_holders", "wall_paintings"]
		},
		{
			"name": "Pillared Hall",
			"size": Vector2(30, 20),
			"spawn_points": [
				Vector3(10, 0, 5), Vector3(-10, 0, 5),
				Vector3(10, 0, -5), Vector3(-10, 0, -5)
			],
			"enemy_count": 4,
			"exits": ["north", "south", "east", "west"],
			"props": ["stone_pillars", "braziers", "egypt_carpet"]
		}
	]
	
	# ELITE ROOM TEMPLATES (4 layouts)
	room_templates[RoomType.ELITE] = [
		{
			"name": "Guardian's Chamber",
			"size": Vector2(25, 25),
			"spawn_points": [Vector3(0, 0, -8)],  # Single elite spawn
			"enemy_count": 1,
			"exits": ["south"],
			"props": ["golden_throne", "treasure_chest", "divine_statue"],
			"special_mechanics": ["elite_buff_aura"]
		},
		{
			"name": "High Priest Sanctum",
			"size": Vector2(20, 30),
			"spawn_points": [Vector3(0, 0, 0)],
			"enemy_count": 1,
			"exits": ["north", "south"],
			"props": ["ritual_circle", "ancient_texts", "golden_brazier"],
			"special_mechanics": ["magic_resistance"]
		}
	]
	
	# TREASURE ROOM TEMPLATES (3 layouts)
	room_templates[RoomType.TREASURE] = [
		{
			"name": "Pharaoh's Treasury",
			"size": Vector2(20, 20),
			"spawn_points": [],  # No enemies
			"enemy_count": 0,
			"exits": ["south"],
			"props": ["treasure_pile", "golden_scarabs", "gem_pedestals"],
			"rewards": ["boon_selection", "ankh_fragments", "heart_piece"]
		},
		{
			"name": "Sacred Library",
			"size": Vector2(25, 15),
			"spawn_points": [],
			"enemy_count": 0,
			"exits": ["north", "south"],
			"props": ["papyrus_scrolls", "knowledge_crystal", "scribe_desk"],
			"rewards": ["ability_upgrade", "divine_knowledge"]
		}
	]
	
	# BOSS ROOM TEMPLATES (2 layouts)
	room_templates[RoomType.BOSS] = [
		{
			"name": "Judgment Arena",
			"size": Vector2(40, 40),
			"spawn_points": [Vector3(0, 0, -15)],  # Boss spawn
			"enemy_count": 1,
			"exits": ["north"],  # Only exit after victory
			"props": ["scales_of_maat", "divine_pillars", "celestial_ceiling"],
			"boss_type": "ammit",
			"phases": 3
		}
	]
	
	print("🏛️ Loaded room templates:")
	print("  Combat: %d layouts" % room_templates[RoomType.COMBAT].size())
	print("  Elite: %d layouts" % room_templates[RoomType.ELITE].size())
	print("  Treasure: %d layouts" % room_templates[RoomType.TREASURE].size())
	print("  Boss: %d layouts" % room_templates[RoomType.BOSS].size())

func _generate_room_sequence():
	"""Generate sequence of rooms for current biome"""
	room_history.clear()
	current_room_index = 0
	
	# Biome 1: Cavernas dos Esquecidos - Room pattern
	var room_sequence = [
		RoomType.COMBAT,    # Room 1
		RoomType.COMBAT,    # Room 2  
		RoomType.TREASURE,  # Room 3 - First reward
		RoomType.COMBAT,    # Room 4
		RoomType.ELITE,     # Room 5 - Elite encounter
		RoomType.COMBAT,    # Room 6
		RoomType.TREASURE,  # Room 7 - Second reward
		RoomType.COMBAT,    # Room 8
		RoomType.COMBAT,    # Room 9
		RoomType.TREASURE,  # Room 10 - Final reward
		RoomType.BOSS       # Room 11 - Biome boss
	]
	
	print("🗺️ Room sequence generated: %d rooms" % room_sequence.size())
	
	# Generate first room
	generate_room(room_sequence[0])

func generate_room(room_type: RoomType, force_template: int = -1) -> Dictionary:
	"""Generate a specific room and set it as current"""
	var templates = room_templates.get(room_type, [])
	if templates.is_empty():
		print("⚠️ No templates found for room type: %s" % RoomType.keys()[room_type])
		return {}
	
	# Select template (random or forced)
	var template_index = force_template if force_template >= 0 else randi() % templates.size()
	var template = templates[template_index].duplicate(true)
	
	# Create room data with current information
	var room_data = {
		"type": room_type,
		"template": template,
		"index": current_room_index,
		"biome": "cavernas_dos_esquecidos",  # Current biome
		"cleared": false,
		"enemies_spawned": false,
		"rewards_collected": false,
		"entry_time": Time.get_unix_time_from_system()
	}
	
	current_room = room_data
	room_history.append(room_data)
	
	# Generate door options for next room
	_generate_door_options()
	
	print("🚪 Generated room: %s (%s)" % [template.name, RoomType.keys()[room_type]])
	print("  Size: %s, Enemies: %d, Exits: %s" % [
		template.size, template.enemy_count, template.exits
	])
	
	# Emit signal for other systems
	room_generated.emit(room_data)
	
	return room_data

func _generate_door_options():
	"""Generate 2-3 door options leading to next rooms"""
	available_doors.clear()
	
	# Determine next room possibilities based on current progress
	var possible_next_rooms = _get_possible_next_rooms()
	
	# Generate 2-3 doors with different rewards/room types
	var door_count = min(3, possible_next_rooms.size())
	for i in door_count:
		var next_room_type = possible_next_rooms[i % possible_next_rooms.size()]
		var reward_preview = _get_reward_preview(next_room_type)
		
		var door_data = {
			"index": i,
			"room_type": next_room_type,
			"reward_type": reward_preview.type,
			"reward_description": reward_preview.description,
			"symbol": reward_preview.symbol,
			"position": Vector3(i * 5 - 5, 0, -10)  # Spread doors horizontally
		}
		
		available_doors.append(door_data)
	
	print("🚪 Generated %d door options:" % available_doors.size())
	for door in available_doors:
		print("  Door %d: %s → %s" % [door.index, door.symbol, door.reward_description])

func _get_possible_next_rooms() -> Array[RoomType]:
	"""Determine what room types can come next"""
	var next_rooms: Array[RoomType] = []
	
	# Logic based on current room index and biome progression
	match current_room_index:
		0, 1, 3, 5, 7, 8:  # Combat positions
			next_rooms = [RoomType.COMBAT, RoomType.TREASURE]
		2, 4, 6, 9:  # After treasures/elites
			next_rooms = [RoomType.COMBAT, RoomType.ELITE]
		10:  # Before boss
			next_rooms = [RoomType.BOSS]
		_:  # Default options
			next_rooms = [RoomType.COMBAT, RoomType.TREASURE, RoomType.ELITE]
	
	return next_rooms

func _get_reward_preview(room_type: RoomType) -> Dictionary:
	"""Get preview information for door symbols"""
	match room_type:
		RoomType.COMBAT:
			return {
				"type": "combat",
				"description": "Enemy Encounter",
				"symbol": "⚔️"
			}
		RoomType.ELITE:
			return {
				"type": "elite",
				"description": "Elite Encounter",
				"symbol": "👑"
			}
		RoomType.TREASURE:
			return {
				"type": "boon",
				"description": "Divine Blessing",
				"symbol": "🏺"
			}
		RoomType.BOSS:
			return {
				"type": "boss",
				"description": "Boss Battle",
				"symbol": "💀"
			}
		_:
			return {
				"type": "unknown",
				"description": "Unknown",
				"symbol": "❓"
			}

func enter_room():
	"""Called when player enters the current room"""
	if current_room.is_empty():
		return
	
	current_room.entered_time = Time.get_unix_time_from_system()
	
	print("🚶 Entered room: %s" % current_room.template.name)
	
	# Spawn enemies if combat room
	if current_room.type in [RoomType.COMBAT, RoomType.ELITE, RoomType.BOSS]:
		_spawn_room_enemies()
	
	# Emit signal
	room_entered.emit(RoomType.keys()[current_room.type], current_room)

func select_door(door_index: int):
	"""Player selects a door to proceed to next room"""
	if door_index < 0 or door_index >= available_doors.size():
		print("⚠️ Invalid door selection: %d" % door_index)
		return
	
	var selected_door = available_doors[door_index]
	selected_door_index = door_index
	
	print("🚪 Selected door %d: %s" % [door_index, selected_door.reward_description])
	
	# Emit signal for UI/rewards
	door_selected.emit(selected_door.reward_type, selected_door)
	
	# Generate next room
	current_room_index += 1
	generate_room(selected_door.room_type)
	
	# Auto-enter next room (for now)
	enter_room()

func _spawn_room_enemies():
	"""Spawn enemies based on room template"""
	if current_room.enemies_spawned:
		return
	
	var template = current_room.template
	var enemy_spawner = get_node_or_null("/root/EnemySpawner")
	
	if not enemy_spawner:
		print("⚠️ EnemySpawner not found - creating placeholder enemies")
		return
	
	# Spawn enemies at designated spawn points
	for i in template.enemy_count:
		if i < template.spawn_points.size():
			var spawn_pos = template.spawn_points[i]
			# TODO: Call enemy spawner when implemented
			print("👻 Would spawn enemy at %s" % spawn_pos)
	
	current_room.enemies_spawned = true

func clear_current_room():
	"""Mark current room as cleared (all enemies defeated)"""
	if current_room.is_empty() or current_room.cleared:
		return
	
	current_room.cleared = true
	current_room.clear_time = Time.get_unix_time_from_system()
	
	var completion_time = current_room.clear_time - current_room.get("entered_time", current_room.clear_time)
	
	print("✅ Room cleared: %s (%.1fs)" % [current_room.template.name, completion_time])
	
	# Show doors for next room
	_show_exit_doors()
	
	# Emit signal
	var performance = {
		"completion_time": completion_time,
		"enemies_defeated": current_room.template.enemy_count
	}
	room_cleared.emit(completion_time, performance)

func _show_exit_doors():
	"""Make exit doors visible and interactable"""
	print("🚪 Exit doors now available:")
	for door in available_doors:
		print("  Press %d: %s" % [door.index + 1, door.reward_description])

# Quick access functions
func get_current_room() -> Dictionary:
	return current_room

func get_room_progress() -> String:
	return "Room %d/%d (%s)" % [current_room_index + 1, rooms_per_biome, current_room.get("template", {}).get("name", "Unknown")]

func is_room_cleared() -> bool:
	return current_room.get("cleared", false)