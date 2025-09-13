# GameManager.gd
# Central game manager for Sands of Duat
# Connects all systems together following ROADMAP integration requirements

extends Node

# System references
var room_system: Node
var combat_system: Node
var dash_system: Node
var portal_manager: Node
var reward_system: Node
var boon_system: Node
var synergy_system: Node
var enemy_manager: Node

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
	reward_system = get_node("/root/RewardSystem")
	boon_system = get_node("/root/BoonSystem")
	synergy_system = get_node("/root/BoonSynergySystem")
	
	# Initialize EnemyManager (Sprint 9)
	var enemy_manager_script = load("res://scripts/enemies/EnemyManager.gd")
	enemy_manager = enemy_manager_script.new()
	enemy_manager.name = "EnemyManager"
	add_child(enemy_manager)
	
	# Connect room system signals
	if room_system:
		room_system.room_entered.connect(_on_room_entered)
		room_system.room_generated.connect(_on_room_generated)
		print("🔗 GameManager connected to RoomSystem")
	
	# Connect portal manager signals
	if portal_manager:
		portal_manager.portal_selected.connect(_on_portal_selected)
		print("🔗 GameManager connected to PortalManager")
	
	# Connect reward system signals
	if reward_system:
		reward_system.reward_collected.connect(_on_reward_collected)
		print("🔗 GameManager connected to RewardSystem")
	
	# Connect boon system signals
	if boon_system:
		boon_system.boon_offered.connect(_on_boons_offered)
		boon_system.boon_selected.connect(_on_boon_selected)
		boon_system.boon_applied.connect(_on_boon_applied)
		print("🔗 GameManager connected to BoonSystem")
	
	# Connect synergy system signals
	if synergy_system:
		synergy_system.synergy_activated.connect(_on_synergy_activated)
		synergy_system.synergy_deactivated.connect(_on_synergy_deactivated)
		print("🔗 GameManager connected to BoonSynergySystem")
	
	# Connect enemy manager signals (Sprint 9)
	if enemy_manager:
		enemy_manager.enemy_spawned.connect(_on_enemy_spawned)
		enemy_manager.enemy_died.connect(_on_enemy_died_from_manager)
		enemy_manager.room_cleared.connect(_on_room_cleared_from_enemies)
		print("🔗 GameManager connected to EnemyManager")
	
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
	
	# Generate rewards for cleared room
	_generate_room_rewards()
	
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

# ========== SPRINT 7: REWARD & BOON SYSTEM HANDLERS ==========

func _on_reward_collected(reward_type: int, amount: int, data: Dictionary):
	"""Handle reward collection"""
	print("🏺 GameManager: Reward collected - Type %d, Amount %d" % [reward_type, amount])
	
	# Update UI if needed
	_update_currency_ui()

func _on_boons_offered(boon_options: Array):
	"""Handle boons being offered to player"""
	print("🏺 GameManager: %d boons offered to player" % boon_options.size())
	
	# Show boon selection UI
	_show_boon_selection_ui(boon_options)

func _on_boon_selected(boon_data: Dictionary):
	"""Handle boon selection by player"""
	print("🏺 GameManager: Player selected boon: %s" % boon_data.name)
	
	# Update UI to show new boon
	_update_boon_ui()

func _on_boon_applied(boon_data: Dictionary):
	"""Handle boon being applied to player"""
	print("✨ GameManager: Boon applied: %s from %s" % [boon_data.name, boon_data.god_name])
	
	# Show boon acquisition feedback
	_show_boon_feedback(boon_data)

func _on_synergy_activated(synergy_data: Dictionary):
	"""Handle synergy activation"""
	print("🔮 GameManager: Synergy activated: %s" % synergy_data.name)
	
	# Show synergy activation feedback
	_show_synergy_feedback(synergy_data)

func _on_synergy_deactivated(synergy_data: Dictionary):
	"""Handle synergy deactivation"""
	print("🔮 GameManager: Synergy deactivated: %s" % synergy_data.name)

func _show_boon_selection_ui(boon_options: Array):
	"""Display boon selection interface"""
	# Get boon selection UI from the current scene
	var boon_ui = get_tree().get_first_node_in_group("boon_ui")
	if not boon_ui:
		# Try alternate paths
		boon_ui = get_node_or_null("/root/GameScene/UI/BoonSelectionUI")
		if not boon_ui:
			boon_ui = get_tree().current_scene.get_node_or_null("UI/BoonSelectionUI")
		
	if not boon_ui:
		print("⚠️ GameManager: BoonSelectionUI not found in scene!")
		print("   Searching for UI in current scene tree...")
		_debug_find_boon_ui()
		return
	
	# The UI will handle the display automatically via signal connection
	print("🏺 GameManager: Boon selection UI found and should now be visible")

func _show_boon_feedback(boon_data: Dictionary):
	"""Show feedback when boon is acquired"""
	print("✨ BOON ACQUIRED: %s" % boon_data.name)
	print("   %s" % boon_data.description)
	print("   From: %s (%s)" % [boon_data.god_name, boon_data.rarity_data.name])

func _show_synergy_feedback(synergy_data: Dictionary):
	"""Show feedback when synergy is activated"""
	print("🔮 SYNERGY ACTIVATED: %s" % synergy_data.name)
	print("   %s" % synergy_data.description)

func _update_currency_ui():
	"""Update currency display in UI"""
	# TODO: Update UI currency displays when UI system is implemented
	pass

func _update_boon_ui():
	"""Update boon display in UI"""
	# TODO: Update UI boon displays when UI system is implemented
	pass

# ========== SPRINT 7: INTEGRATION WITH ROOM REWARDS ==========

func _generate_room_rewards():
	"""Generate rewards for current room based on type and difficulty"""
	if not room_system or not reward_system:
		print("⚠️ GameManager: Missing systems for reward generation")
		return
	
	var current_room = room_system.get_current_room()
	if current_room.is_empty():
		print("⚠️ GameManager: No current room data for reward generation")
		return
	
	# Only generate automatic rewards for combat/elite rooms
	# Treasure rooms handle boons separately
	var room_type_key = RoomSystem.RoomType.keys()[current_room.type]
	if room_type_key == "TREASURE":
		print("🏺 GameManager: Treasure room - boons handled separately")
		return
	
	# Generate reward for cleared combat/elite room
	var reward_data = reward_system.generate_room_reward(current_room)
	print("🏺 GameManager: Generated reward: %s" % reward_data.name)
	
	# Apply the reward immediately (or store for collection)
	reward_system.collect_reward(reward_data)

func _debug_find_boon_ui():
	"""Debug function to find BoonSelectionUI in scene tree"""
	var scene = get_tree().current_scene
	print("🔍 Debug: Current scene is: %s" % scene.name)
	
	var ui_node = scene.get_node_or_null("UI")
	if ui_node:
		print("🔍 Debug: Found UI node with %d children" % ui_node.get_child_count())
		for child in ui_node.get_children():
			print("🔍 Debug: UI child: %s" % child.name)
			if "BoonSelectionUI" in child.name:
				print("✅ Debug: Found BoonSelectionUI at %s" % child.get_path())
	else:
		print("❌ Debug: No UI node found in scene")

# ========== SPRINT 9: ENEMY MANAGER INTEGRATION ==========

func _on_enemy_spawned(enemy: Node, enemy_type: String):
	"""Handle enemy spawn from EnemyManager"""
	print("👹 GameManager: Enemy spawned - %s (%s)" % [enemy.name, enemy_type])
	
	# Add to current room tracking
	if not enemy in enemies_in_current_room:
		enemies_in_current_room.append(enemy)
		room_enemies_total += 1
	
	# Connect to individual enemy death
	if enemy.has_signal("enemy_died"):
		if not enemy.enemy_died.is_connected(_on_enemy_died):
			enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died_from_manager(enemy: Node, enemy_type: String):
	"""Handle enemy death from EnemyManager"""
	print("💀 GameManager: Enemy died via EnemyManager - %s (%s)" % [enemy.name, enemy_type])
	
	# Remove from room tracking
	if enemy in enemies_in_current_room:
		enemies_in_current_room.erase(enemy)

func _on_room_cleared_from_enemies():
	"""Handle room cleared signal from EnemyManager"""
	print("✅ GameManager: Room cleared via EnemyManager!")
	
	# Use existing room clear logic
	_clear_current_room()

# Enhanced room entry to integrate with EnemyManager
func register_system(system: Node):
	"""Allow systems to register with GameManager"""
	print("🔗 System registered: %s" % system.name)