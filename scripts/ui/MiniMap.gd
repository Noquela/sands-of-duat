# MiniMap.gd
# Minimap System for Sands of Duat room navigation
# Sprint 6: Room System - Visual navigation aid

extends Control

# Minimap display settings
var map_scale: float = 0.1
var room_size: Vector2 = Vector2(40, 40)
var connection_width: float = 4.0

# Room type constants (copied from RoomSystem)
enum RoomType {
	COMBAT,     # Regular enemy encounters
	ELITE,      # Stronger enemies, better rewards
	TREASURE,   # Boon selection, currency
	BOSS,       # Major boss encounters
	HUB,        # Safe areas, Pool of Memories
	SPECIAL     # Chaos gates, Erebus gates equivalent
}

# Colors for different room types
var room_colors = {
	RoomType.COMBAT: Color.GRAY,
	RoomType.ELITE: Color.PURPLE,
	RoomType.TREASURE: Color.GOLD,
	RoomType.BOSS: Color.RED,
	RoomType.HUB: Color.BLUE
}

# Room states
var room_state_colors = {
	"current": Color.WHITE,
	"cleared": Color.GREEN,
	"available": Color.LIGHT_GRAY,
	"locked": Color.DARK_GRAY
}

# Room tracking
var room_system: Node  # Reference to RoomSystem autoload
var room_positions: Dictionary = {}
var current_room_index: int = 0

# Canvas drawing handled by Control's _draw method

func _ready():
	print("🗺️ MiniMap initialized - Navigation ready")
	
	# Set minimap size and position (top-right corner)
	custom_minimum_size = Vector2(300, 200)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -320
	offset_top = 20
	
	# Connect to room system when available
	_connect_to_room_system()

func _connect_to_room_system():
	"""Connect to room system signals"""
	# Wait for room system to be ready
	await get_tree().create_timer(0.1).timeout
	
	room_system = get_node_or_null("/root/RoomSystem")
	if not room_system:
		# Try to find it as a child of current scene
		var current_scene = get_tree().current_scene
		room_system = current_scene.get_node_or_null("RoomSystem")
	
	if room_system:
		room_system.room_generated.connect(_on_room_generated)
		room_system.room_entered.connect(_on_room_entered)
		room_system.room_cleared.connect(_on_room_cleared)
		print("🔗 MiniMap connected to RoomSystem")
		
		# Initialize with current room if available
		var current_room = room_system.get_current_room()
		if not current_room.is_empty():
			_update_minimap()
	else:
		print("⚠️ RoomSystem not found for minimap")

func _draw():
	"""Custom drawing for minimap"""
	_draw_background()
	_draw_rooms()
	_draw_connections()
	_draw_player_indicator()
	_draw_compass()

func _draw_background():
	"""Draw minimap background"""
	var bg_rect = Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(bg_rect, Color.WHITE, false, 2.0)
	
	# Draw title
	var font = ThemeDB.fallback_font
	var title_pos = Vector2(10, 25)
	draw_string(font, title_pos, "DUAT MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GOLD)

func _draw_rooms():
	"""Draw all discovered rooms"""
	for room_index in room_positions.keys():
		var room_pos = room_positions[room_index]
		var room_data = _get_room_data(room_index)
		
		if room_data.is_empty():
			continue
		
		# Determine room color based on type and state
		var room_color = _get_room_color(room_data, room_index)
		
		# Draw room rectangle
		var room_rect = Rect2(room_pos - room_size * 0.5, room_size)
		draw_rect(room_rect, room_color)
		draw_rect(room_rect, Color.WHITE, false, 2.0)
		
		# Draw room symbol
		_draw_room_symbol(room_data, room_pos)
		
		# Draw room index
		var font = ThemeDB.fallback_font
		var text_pos = room_pos - Vector2(5, -5)
		draw_string(font, text_pos, str(room_index + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

func _draw_connections():
	"""Draw connections between rooms"""
	# For now, draw simple linear connections
	for i in range(room_positions.size() - 1):
		if room_positions.has(i) and room_positions.has(i + 1):
			var start_pos = room_positions[i]
			var end_pos = room_positions[i + 1]
			
			# Connection color based on accessibility
			var connection_color = Color.GRAY if i <= current_room_index else Color.DARK_GRAY
			
			draw_line(start_pos, end_pos, connection_color, connection_width)

func _draw_player_indicator():
	"""Draw player position indicator"""
	if room_positions.has(current_room_index):
		var player_pos = room_positions[current_room_index]
		
		# Animated player dot (pulsing effect)
		var pulse = sin(Time.get_unix_time_from_system() * 5.0) * 0.3 + 0.7
		var player_color = Color.CYAN * pulse
		var radius = 8.0 + pulse * 3.0
		
		draw_circle(player_pos, radius, player_color)
		draw_circle(player_pos, radius, Color.WHITE, false, 2.0)

func _draw_compass():
	"""Draw compass rose in corner"""
	var compass_pos = Vector2(size.x - 40, 50)
	var compass_size = 20
	
	# North arrow
	var north_points = [
		compass_pos + Vector2(0, -compass_size),
		compass_pos + Vector2(-5, -10),
		compass_pos + Vector2(5, -10)
	]
	draw_colored_polygon(north_points, Color.RED)
	
	# Draw N label
	var font = ThemeDB.fallback_font
	draw_string(font, compass_pos + Vector2(-5, -compass_size - 5), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)

func _draw_room_symbol(room_data: Dictionary, position: Vector2):
	"""Draw symbol representing room type"""
	var room_type = room_data.get("type", RoomType.COMBAT)
	var symbol = ""
	var symbol_color = Color.WHITE
	
	match room_type:
		RoomType.COMBAT:
			symbol = "⚔"
			symbol_color = Color.WHITE
		RoomType.ELITE:
			symbol = "👑"
			symbol_color = Color.YELLOW
		RoomType.TREASURE:
			symbol = "🏺"
			symbol_color = Color.GOLD
		RoomType.BOSS:
			symbol = "💀"
			symbol_color = Color.RED
		_:
			symbol = "?"
			symbol_color = Color.GRAY
	
	# Draw symbol (using font rendering for now)
	var font = ThemeDB.fallback_font
	var symbol_pos = position - Vector2(8, -8)
	draw_string(font, symbol_pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, symbol_color)

func _get_room_color(room_data: Dictionary, room_index: int) -> Color:
	"""Get color for room based on type and state"""
	var base_color = room_colors.get(room_data.get("type", RoomType.COMBAT), Color.GRAY)
	
	# Modify based on room state
	if room_index == current_room_index:
		return room_state_colors["current"]
	elif room_data.get("cleared", false):
		return room_state_colors["cleared"]
	elif room_index < current_room_index:
		return room_state_colors["cleared"]
	elif room_index <= current_room_index + 1:
		return room_state_colors["available"]
	else:
		return room_state_colors["locked"]

func _get_room_data(room_index: int) -> Dictionary:
	"""Get room data by index"""
	if not room_system or room_index >= room_system.room_history.size():
		return {}
	
	return room_system.room_history[room_index] if room_index < room_system.room_history.size() else {}

func _update_minimap():
	"""Update minimap display with current room data"""
	if not room_system:
		return
	
	_generate_room_positions()
	queue_redraw()

func _generate_room_positions():
	"""Generate positions for rooms on minimap"""
	room_positions.clear()
	
	# For Sprint 6, use simple linear layout
	# Later versions can use more complex branching layouts
	var start_pos = Vector2(60, size.y * 0.5)
	var room_spacing = Vector2(60, 0)
	
	var room_count = room_system.room_history.size()
	for i in room_count:
		room_positions[i] = start_pos + room_spacing * i
	
	# Add next room position if not at the end
	if room_count < 11:  # Total rooms in biome
		room_positions[room_count] = start_pos + room_spacing * room_count

# Signal handlers
func _on_room_generated(room_data: Dictionary):
	"""Handle new room generation"""
	print("🗺️ MiniMap: New room generated - %s" % room_data.template.name)
	_update_minimap()

func _on_room_entered(room_type: String, room_data: Dictionary):
	"""Handle room entry"""
	current_room_index = room_data.index
	print("🗺️ MiniMap: Entered room %d - %s" % [current_room_index + 1, room_type])
	_update_minimap()

func _on_room_cleared(completion_time: float, performance: Dictionary):
	"""Handle room cleared"""
	print("🗺️ MiniMap: Room %d cleared" % (current_room_index + 1))
	_update_minimap()

# Utility functions
func toggle_visibility():
	"""Toggle minimap visibility"""
	visible = not visible
	print("🗺️ MiniMap %s" % ("shown" if visible else "hidden"))

func get_room_progress() -> String:
	"""Get current room progress string"""
	if room_system:
		return room_system.get_room_progress()
	return "Room ?/? (Unknown)"