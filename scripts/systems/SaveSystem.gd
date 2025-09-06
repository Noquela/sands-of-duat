extends Node
class_name SaveSystem

signal save_completed(slot_id: int)
signal load_completed(slot_id: int, save_data: Dictionary)
signal save_failed(error_message: String)

@export_group("Save Settings")
@export var save_directory: String = "user://saves/"
@export var save_file_extension: String = ".save"
@export var max_save_slots: int = 3
@export var auto_save_interval: float = 30.0

# Save data structure
var current_save_data: Dictionary = {}
var auto_save_timer: Timer

# Game state references
var room_system: RoomSystem
var player: Node3D

func _ready():
	setup_save_system()
	setup_auto_save()
	find_game_references()

func setup_save_system():
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(save_directory):
		DirAccess.open("user://").make_dir_recursive(save_directory.trim_prefix("user://"))
		print("Created save directory: ", save_directory)

func setup_auto_save():
	# Create auto-save timer
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	auto_save_timer.autostart = true
	add_child(auto_save_timer)

func find_game_references():
	# Find room system
	room_system = get_tree().get_first_node_in_group("room_system")
	if not room_system:
		room_system = find_node_by_class(get_tree().current_scene, "RoomSystem")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	print("Save system references - RoomSystem: ", room_system != null, " Player: ", player != null)

func find_node_by_class(node: Node, target_class: String) -> Node:
	if node.get_script() and node.get_script().get_global_name() == target_class:
		return node
	
	for child in node.get_children():
		var result = find_node_by_class(child, target_class)
		if result:
			return result
	
	return null

func save_game(slot_id: int, save_name: String = "") -> bool:
	if slot_id < 0 or slot_id >= max_save_slots:
		save_failed.emit("Invalid save slot: " + str(slot_id))
		return false
	
	# Collect save data
	var save_data = collect_save_data(save_name)
	
	# Write to file
	var file_path = get_save_file_path(slot_id)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		save_failed.emit("Failed to create save file: " + file_path)
		return false
	
	# Save as JSON for readability and debugging
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	current_save_data = save_data
	save_completed.emit(slot_id)
	print("Game saved to slot ", slot_id, " - ", save_name)
	
	return true

func load_game(slot_id: int) -> Dictionary:
	if slot_id < 0 or slot_id >= max_save_slots:
		save_failed.emit("Invalid save slot: " + str(slot_id))
		return {}
	
	var file_path = get_save_file_path(slot_id)
	if not FileAccess.file_exists(file_path):
		save_failed.emit("Save file does not exist: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		save_failed.emit("Failed to open save file: " + file_path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		save_failed.emit("Failed to parse save file JSON")
		return {}
	
	var save_data = json.data
	current_save_data = save_data
	
	# Apply save data to game
	apply_save_data(save_data)
	
	load_completed.emit(slot_id, save_data)
	print("Game loaded from slot ", slot_id)
	
	return save_data

func collect_save_data(save_name: String = "") -> Dictionary:
	var save_data = {
		# Meta information
		"version": "1.0",
		"save_name": save_name if save_name != "" else "Auto Save",
		"timestamp": Time.get_unix_time_from_system(),
		"playtime": 0.0,  # TODO: Track actual playtime
		
		# Player data
		"player": collect_player_data(),
		
		# Room system data
		"room_system": collect_room_data(),
		
		# Game progression
		"progression": collect_progression_data(),
		
		# Settings (if needed)
		"settings": {}
	}
	
	return save_data

func collect_player_data() -> Dictionary:
	if not player:
		return {}
	
	var player_data = {
		"position": var_to_str(player.global_position),
		"health": 100.0,  # TODO: Get from health system
		"mana": 100.0,    # TODO: Get from ability system
		"level": 1,
		"experience": 0,
		"equipped_weapon": "was_scepter"  # TODO: Get from weapon system
	}
	
	# Get health from health system
	if player.has_method("get_node") and player.get_node_or_null("HealthSystem"):
		var health_system = player.get_node("HealthSystem")
		if health_system:
			player_data.health = health_system.current_health
	
	# Get mana from ability system
	if player.has_method("get_node") and player.get_node_or_null("AbilitySystem"):
		var ability_system = player.get_node("AbilitySystem")
		if ability_system:
			player_data.mana = ability_system.current_mana
	
	# Get weapon from weapon system
	if player.has_method("get_node") and player.get_node_or_null("WeaponSystem"):
		var weapon_system = player.get_node("WeaponSystem")
		if weapon_system and weapon_system.has_method("get_current_weapon"):
			player_data.equipped_weapon = weapon_system.get_current_weapon()
	
	return player_data

func collect_room_data() -> Dictionary:
	if not room_system:
		return {}
	
	var room_data = {
		"current_room_id": -1,
		"rooms": [],
		"floor": 1
	}
	
	# Get current room
	var current_room = room_system.get_current_room()
	if not current_room.is_empty():
		room_data.current_room_id = current_room.id
	
	# Save all room states
	for room in room_system.room_database:
		room_data.rooms.append({
			"id": room.id,
			"type": room.type,
			"state": room.state,
			"is_cleared": room.is_cleared,
			"layout_id": room.layout_id
		})
	
	return room_data

func collect_progression_data() -> Dictionary:
	return {
		"rooms_completed": room_system.get_completed_rooms() if room_system else 0,
		"total_rooms": room_system.get_room_count() if room_system else 0,
		"current_floor": 1,
		"deaths": 0,
		"boss_defeats": 0,
		"secrets_found": 0
	}

func apply_save_data(save_data: Dictionary):
	# Apply player data
	if save_data.has("player"):
		apply_player_data(save_data.player)
	
	# Apply room data
	if save_data.has("room_system"):
		apply_room_data(save_data.room_system)
	
	print("Save data applied to game")

func apply_player_data(player_data: Dictionary):
	if not player or player_data.is_empty():
		return
	
	# Restore position
	if player_data.has("position"):
		player.global_position = str_to_var(player_data.position)
	
	# Restore health
	if player_data.has("health") and player.has_method("get_node"):
		var health_system = player.get_node_or_null("HealthSystem")
		if health_system:
			health_system.current_health = player_data.health
	
	# Restore mana
	if player_data.has("mana") and player.has_method("get_node"):
		var ability_system = player.get_node_or_null("AbilitySystem")
		if ability_system:
			ability_system.current_mana = player_data.mana
	
	# Restore weapon
	if player_data.has("equipped_weapon") and player.has_method("get_node"):
		var weapon_system = player.get_node_or_null("WeaponSystem")
		if weapon_system and weapon_system.has_method("switch_weapon"):
			weapon_system.switch_weapon(player_data.equipped_weapon)

func apply_room_data(room_data: Dictionary):
	if not room_system or room_data.is_empty():
		return
	
	# Restore room states
	if room_data.has("rooms"):
		for i in range(min(room_data.rooms.size(), room_system.room_database.size())):
			var saved_room = room_data.rooms[i]
			var current_room = room_system.room_database[i]
			
			current_room.state = saved_room.get("state", RoomSystem.RoomState.INACTIVE)
			current_room.is_cleared = saved_room.get("is_cleared", false)
	
	# Restore current room
	if room_data.has("current_room_id") and room_data.current_room_id >= 0:
		room_system.current_room = room_system.room_database[room_data.current_room_id]

func get_save_file_path(slot_id: int) -> String:
	return save_directory + "save_slot_" + str(slot_id) + save_file_extension

func save_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(get_save_file_path(slot_id))

func get_save_info(slot_id: int) -> Dictionary:
	if not save_exists(slot_id):
		return {}
	
	var file_path = get_save_file_path(slot_id)
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		return {}
	
	var save_data = json.data
	return {
		"save_name": save_data.get("save_name", "Unknown"),
		"timestamp": save_data.get("timestamp", 0),
		"playtime": save_data.get("playtime", 0),
		"progression": save_data.get("progression", {}),
		"player_level": save_data.get("player", {}).get("level", 1)
	}

func delete_save(slot_id: int) -> bool:
	var file_path = get_save_file_path(slot_id)
	if FileAccess.file_exists(file_path):
		DirAccess.open("user://").remove(file_path.trim_prefix("user://"))
		print("Deleted save slot ", slot_id)
		return true
	return false

func _on_auto_save_timer_timeout():
	# Auto-save to slot 0 (if player is in a safe location)
	if can_auto_save():
		save_game(0, "Auto Save")

func can_auto_save() -> bool:
	# Only auto-save if player is not in combat or dangerous situation
	if not player or not room_system:
		return false
	
	# Check if current room is completed or safe
	var current_room = room_system.get_current_room()
	if current_room.is_empty():
		return false
	
	return current_room.is_cleared or current_room.type == RoomSystem.RoomType.TREASURE

# Public API
func quick_save() -> bool:
	return save_game(0, "Quick Save")

func quick_load() -> Dictionary:
	return load_game(0)

func get_all_save_info() -> Array[Dictionary]:
	var saves = []
	for i in range(max_save_slots):
		saves.append(get_save_info(i))
	return saves

func export_save(slot_id: int, export_path: String) -> bool:
	var source_path = get_save_file_path(slot_id)
	if not FileAccess.file_exists(source_path):
		return false
	
	var source_file = FileAccess.open(source_path, FileAccess.READ)
	var export_file = FileAccess.open(export_path, FileAccess.WRITE)
	
	if not source_file or not export_file:
		return false
	
	export_file.store_string(source_file.get_as_text())
	source_file.close()
	export_file.close()
	
	print("Save exported to: ", export_path)
	return true