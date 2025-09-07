# PortalManager.gd
# Manages 3D portal spawning and room transitions
# Sprint 6: Visual door selection system

extends Node

# Preload portal scene
const RoomPortal = preload("res://scenes/portals/RoomPortal.tscn")

# Portal colors for different door types
var portal_colors = {
	"⚔️": Color.RED,        # Combat - Red
	"👑": Color.PURPLE,     # Elite - Purple  
	"🏺": Color.GOLD,       # Treasure - Gold
	"💀": Color.BLACK,      # Boss - Black
	"🔮": Color.CYAN,       # Special - Cyan
	"🚪": Color.BLUE        # Default - Blue
}

# Portal positioning - Hades style at room walls
var room_size: Vector2 = Vector2(20, 20)  # Default room size
var portal_wall_offset: float = 2.0  # Distance from room edge
var portal_height: float = 0.0

# Active portals
var active_portals: Array[Node] = []
var room_system: Node
var game_manager: Node

signal portal_selected(door_index: int)

func _ready():
	print("🚪 PortalManager: Initializing portal system...")
	
	# Get system references
	room_system = get_node("/root/RoomSystem")
	if not room_system:
		print("⚠️ PortalManager: RoomSystem not found!")
		return
	
	# Connect to room clearing signal
	if room_system.has_signal("room_cleared"):
		room_system.room_cleared.connect(_on_room_cleared)
		print("🔗 PortalManager connected to RoomSystem")
	
	print("🚪 PortalManager: Ready to spawn portals!")

func _on_room_cleared(completion_time: float, performance: Dictionary):
	"""Spawn portals when room is cleared"""
	print("🚪 PortalManager: Room cleared! Spawning portals...")
	
	# Clear any existing portals
	_clear_active_portals()
	
	# Get available doors from RoomSystem
	if not room_system or not room_system.has_method("get_available_doors"):
		print("⚠️ PortalManager: Cannot get doors from RoomSystem!")
		return
	
	var available_doors = room_system.get_available_doors()
	if available_doors.is_empty():
		print("⚠️ PortalManager: No doors available!")
		return
	
	print("🚪 Spawning %d portals..." % available_doors.size())
	
	# Spawn portals around the room
	for i in available_doors.size():
		var door_data = available_doors[i]
		_spawn_portal(i, door_data)
	
	print("✅ PortalManager: %d portals spawned successfully!" % active_portals.size())

func _spawn_portal(door_index: int, door_data: Dictionary):
	"""Spawn a single portal at room wall - Hades style"""
	
	# Get current room data for size
	var current_room = room_system.get_current_room()
	var room_template = current_room.get("template", {})
	room_size = room_template.get("size", Vector2(20, 20))
	
	# Calculate wall positions based on room size
	var half_height = room_size.y / 2.0
	
	# Position portals side by side on the north wall
	var doors_count = room_system.get_available_doors().size()
	
	# Calculate spacing between portals
	var portal_spacing = 4.0  # Distance between portals
	var start_offset = -(doors_count - 1) * portal_spacing / 2.0
	
	# All portals at the exact edge of the room (north side)
	var spawn_pos = Vector3(
		start_offset + door_index * portal_spacing,
		portal_height,
		-half_height + portal_wall_offset  # At room boundary
	)
	
	# Create portal instance
	var portal = RoomPortal.instantiate()
	if not portal:
		print("⚠️ Failed to instantiate portal %d!" % door_index)
		return
	
	# Add to scene first
	get_tree().current_scene.add_child(portal)
	
	# Now set position (after being in scene tree)
	portal.global_position = spawn_pos
	
	# Setup portal data
	var symbol = door_data.get("symbol", "🚪")
	var description = door_data.get("reward_description", "Unknown")
	var color = portal_colors.get(symbol, Color.BLUE)
	
	portal.set_door_data(door_index, symbol, description, color)
	
	# Connect portal activation signal
	portal.portal_activated.connect(_on_portal_activated)
	
	active_portals.append(portal)
	
	# Activate the portal
	portal.set_active(true)
	
	print("🚪 Portal %d spawned: %s %s at %s" % [door_index, symbol, description, spawn_pos])

func _on_portal_activated(door_index: int):
	"""Handle portal activation by player"""
	print("🚪 PortalManager: Portal %d activated!" % door_index)
	
	# Emit signal for other systems
	portal_selected.emit(door_index)
	
	# Tell RoomSystem to select this door
	if room_system and room_system.has_method("select_door"):
		room_system.select_door(door_index)
		print("🚪 Room transition initiated via portal %d" % door_index)
	
	# Clear portals after selection
	_clear_active_portals()

func _clear_active_portals():
	"""Remove all active portals from the scene"""
	print("🚪 PortalManager: Clearing %d active portals..." % active_portals.size())
	
	for portal in active_portals:
		if is_instance_valid(portal):
			portal.set_active(false)
			portal.queue_free()
	
	active_portals.clear()
	print("🚪 PortalManager: All portals cleared")

func get_portal_count() -> int:
	return active_portals.size()

func get_active_portals() -> Array:
	return active_portals.duplicate()

func are_portals_active() -> bool:
	return not active_portals.is_empty()

# Debug function
func force_spawn_test_portals():
	"""Spawn test portals for debugging"""
	print("🚪 PortalManager: Spawning test portals...")
	
	var test_doors = [
		{"symbol": "⚔️", "reward_description": "Enemy Encounter"},
		{"symbol": "🏺", "reward_description": "Divine Blessing"},
		{"symbol": "👑", "reward_description": "Elite Challenge"}
	]
	
	_clear_active_portals()
	
	for i in test_doors.size():
		_spawn_portal(i, test_doors[i])
	
	print("🚪 Test portals spawned!")
