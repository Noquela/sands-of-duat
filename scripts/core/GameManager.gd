# GameManager.gd
# Central game manager for Sands of Duat
# Connects all systems together following ROADMAP integration requirements

extends Node

# System references
var room_system: Node
var combat_system: Node
var dash_system: Node
var portal_manager: Node

# Room tracking
var enemies_in_current_room: Array[Node] = []
var room_enemies_total: int = 0

func _ready():
	print("🎮 GameManager: Connecting all systems...")
	
	# Get system references
	room_system = get_node("/root/RoomSystem")
	combat_system = get_node("/root/CombatSystem")
	dash_system = get_node("/root/DashSystem")
	portal_manager = get_node("/root/PortalManager")
	
	# Connect room system signals
	if room_system:
		room_system.room_entered.connect(_on_room_entered)
		room_system.room_generated.connect(_on_room_generated)
		print("🔗 GameManager connected to RoomSystem")
	
	# Connect portal manager signals
	if portal_manager:
		portal_manager.portal_selected.connect(_on_portal_selected)
		print("🔗 GameManager connected to PortalManager")
	
	# Setup initial room
	_setup_current_room()

func _setup_current_room():
	"""Setup current room with enemy tracking"""
	# Clear previous room state
	enemies_in_current_room.clear()
	room_enemies_total = 0
	
	# Find all enemies in scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	enemies_in_current_room = enemies
	room_enemies_total = enemies.size()
	
	print("🎯 Current room setup: %d enemies found" % room_enemies_total)
	
	# Connect to each enemy's death signal (disconnect first to avoid duplicates)
	for enemy in enemies:
		if enemy.has_signal("enemy_died"):
			# Disconnect first if already connected
			if enemy.enemy_died.is_connected(_on_enemy_died):
				enemy.enemy_died.disconnect(_on_enemy_died)
			
			enemy.enemy_died.connect(_on_enemy_died)
			print("🔗 Connected to enemy: %s" % enemy.name)

func _on_room_entered(room_type: String, room_data: Dictionary):
	"""Handle room entry"""
	print("🚪 GameManager: Player entered %s room" % room_type)
	
	# Wait a bit more for enemies to spawn in new room
	await get_tree().create_timer(0.5).timeout
	_setup_current_room()

func _on_room_generated(room_data: Dictionary):
	"""Handle new room generation"""
	print("🏛️ GameManager: Room generated - %s" % room_data.template.name)

func _on_portal_selected(door_index: int):
	"""Handle portal selection by player"""
	print("🚪 GameManager: Player selected portal %d" % door_index)

func _on_enemy_died(enemy: Node3D):
	"""Handle enemy death - check if room should be cleared"""
	print("💀 GameManager: Enemy died - %s" % enemy.name)
	
	# Remove from current room list
	enemies_in_current_room.erase(enemy)
	
	# Check if room is cleared
	var remaining_enemies = 0
	for remaining_enemy in enemies_in_current_room:
		if is_instance_valid(remaining_enemy):
			remaining_enemies += 1
	
	print("👻 Enemies remaining: %d/%d" % [remaining_enemies, room_enemies_total])
	
	# If no enemies left, clear the room
	if remaining_enemies == 0:
		_clear_current_room()

func _clear_current_room():
	"""Mark current room as cleared and show doors"""
	print("✅ GameManager: Room cleared! Doors unlocked")
	
	if room_system:
		room_system.clear_current_room()
	
	# Show door selection UI
	_show_door_selection_ui()

func _show_door_selection_ui():
	"""Display door options to player"""
	if not room_system:
		return
	
	var available_doors = room_system.available_doors
	
	print("🚪 3D Portals Spawned! Options Available:")
	for i in available_doors.size():
		var door = available_doors[i]
		print("  Portal %d: %s %s" % [i + 1, door.symbol, door.reward_description])
	
	print("Walk into a portal and press E to enter, or use F1-F3 hotkeys")

# Testing function for Sprint 6 validation
func validate_sprint_6():
	"""Test Sprint 6 integration"""
	print("🏛️ SPRINT 6 VALIDATION:")
	print("====================")
	
	if room_system:
		print("✅ RoomSystem connected")
		print("  Current room: %s" % room_system.get_room_progress())
		print("  Room cleared: %s" % room_system.is_room_cleared())
		print("  Available doors: %d" % room_system.available_doors.size())
	else:
		print("❌ RoomSystem not found")
	
	print("  Enemies in room: %d" % enemies_in_current_room.size())
	print("  Total enemies: %d" % room_enemies_total)
	
	# Test minimap
	var minimap = get_node_or_null("../UI/MiniMap")
	if minimap:
		print("✅ MiniMap found in scene")
	else:
		print("❌ MiniMap not found")
	
	# Test portal system
	if portal_manager:
		print("✅ PortalManager connected")
		print("  Active portals: %d" % portal_manager.get_portal_count())
		print("  Portals active: %s" % portal_manager.are_portals_active())
	else:
		print("❌ PortalManager not found")
	
	print("====================")

func _input(event):
	"""Handle debug inputs"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_P:  # Test portals key
				_test_spawn_portals()

func _test_spawn_portals():
	"""Test function to spawn portals manually"""
	if portal_manager:
		print("🚪 GameManager: Testing portal spawn...")
		portal_manager.force_spawn_test_portals()
	else:
		print("❌ PortalManager not available for testing")