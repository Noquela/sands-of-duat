extends Control
## Sistema de Minimap - Sprint 6
## Visualização da estrutura de salas e navegação

signal room_selected(room_id)

# Referências
var room_system: Node
var room_manager: Node

# Configurações visuais
const ROOM_SIZE = Vector2(24, 24)
const ROOM_SPACING = Vector2(4, 4)
const MINIMAP_SCALE = 0.8

# Cores das salas por tipo
var room_colors = {
	0: Color.GRAY,        # COMBAT
	1: Color.ORANGE,      # ELITE  
	2: Color.GOLD,        # TREASURE
	3: Color.RED          # BOSS
}

# Cores por estado
var state_colors = {
	0: Color(0.3, 0.3, 0.3),    # LOCKED - Dark gray
	1: Color(0.7, 0.7, 0.7),    # AVAILABLE - Light gray
	2: Color(0.2, 0.8, 0.2),    # CURRENT - Bright green
	3: Color(0.5, 0.5, 0.5)     # CLEARED - Medium gray
}

# UI Elements
var room_buttons: Dictionary = {}  # String -> Button
var connection_lines: Array[Line2D] = []
var minimap_panel: Panel
var room_container: Control

# Estado
var is_visible: bool = false

func _ready():
	print("🗺️ Minimap System initialized - Sprint 6")
	
	# Get references
	room_system = get_node("/root/RoomSystem")
	room_manager = get_node("/root/RoomManager")
	
	# Setup UI
	setup_minimap_ui()
	
	# Connect signals
	connect_signals()
	
	# Initial update
	if room_system:
		update_minimap()
	
	print("🗺️ Minimap ready for room navigation")

func setup_minimap_ui():
	"""Setup minimap UI elements"""
	# Main panel
	minimap_panel = Panel.new()
	minimap_panel.name = "MinimapPanel"
	minimap_panel.size = Vector2(300, 250)
	minimap_panel.position = Vector2(10, 10)  # Top-left corner
	
	# Panel styling
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.8)  # Semi-transparent black
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color.GOLD
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	minimap_panel.add_theme_stylebox_override("panel", panel_style)
	
	add_child(minimap_panel)
	
	# Title label
	var title = Label.new()
	title.text = "DUAT MAP"
	title.position = Vector2(10, 5)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.GOLD)
	minimap_panel.add_child(title)
	
	# Room container
	room_container = Control.new()
	room_container.name = "RoomContainer"
	room_container.position = Vector2(10, 30)
	room_container.size = Vector2(280, 210)
	minimap_panel.add_child(room_container)
	
	# Toggle button
	var toggle_button = Button.new()
	toggle_button.text = "MAP"
	toggle_button.size = Vector2(50, 25)
	toggle_button.position = Vector2(get_viewport().size.x - 60, 10)
	toggle_button.pressed.connect(toggle_minimap)
	add_child(toggle_button)
	
	# Start hidden
	minimap_panel.visible = false

func connect_signals():
	"""Connect room system signals"""
	if room_system:
		room_system.room_generated.connect(_on_room_generated)
		room_system.room_entered.connect(_on_room_entered)
		room_system.room_cleared.connect(_on_room_cleared)
	
	if room_manager:
		room_manager.room_transition_completed.connect(_on_room_transition_completed)

func toggle_minimap():
	"""Toggle minimap visibility"""
	is_visible = !is_visible
	minimap_panel.visible = is_visible
	
	if is_visible:
		update_minimap()

func update_minimap():
	"""Update minimap display"""
	if not room_system or not room_system.rooms:
		return
	
	clear_minimap()
	create_room_grid()
	draw_connections()
	
	print("🗺️ Minimap updated with ", room_system.rooms.size(), " rooms")

func clear_minimap():
	"""Clear existing minimap elements"""
	for button in room_buttons.values():
		if is_instance_valid(button):
			button.queue_free()
	room_buttons.clear()
	
	for line in connection_lines:
		if is_instance_valid(line):
			line.queue_free()
	connection_lines.clear()

func create_room_grid():
	"""Create room buttons in grid layout"""
	var grid_size = Vector2i(7, 5)  # Same as RoomSystem.GRID_SIZE
	var start_pos = Vector2(20, 20)
	
	# Calculate grid bounds for centering
	var used_positions = []
	for room_id in room_system.rooms:
		var room_data = room_system.rooms[room_id]
		used_positions.append(room_data.position)
	
	if used_positions.is_empty():
		return
	
	# Find grid bounds
	var min_x = used_positions[0].x
	var max_x = used_positions[0].x
	var min_y = used_positions[0].y
	var max_y = used_positions[0].y
	
	for pos in used_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	
	# Calculate offset for centering
	var grid_width = (max_x - min_x + 1) * (ROOM_SIZE.x + ROOM_SPACING.x)
	var grid_height = (max_y - min_y + 1) * (ROOM_SIZE.y + ROOM_SPACING.y)
	var offset = Vector2(
		(room_container.size.x - grid_width) / 2,
		(room_container.size.y - grid_height) / 2
	)
	
	# Create room buttons
	for room_id in room_system.rooms:
		var room_data = room_system.rooms[room_id]
		var room_button = create_room_button(room_data, min_x, min_y, offset)
		
		room_container.add_child(room_button)
		room_buttons[room_id] = room_button

func create_room_button(room_data, min_x: int, min_y: int, offset: Vector2) -> Button:
	"""Create button for single room"""
	var button = Button.new()
	button.name = "Room_" + room_data.id
	button.size = ROOM_SIZE * MINIMAP_SCALE
	
	# Calculate position
	var grid_pos = Vector2(
		(room_data.position.x - min_x) * (ROOM_SIZE.x + ROOM_SPACING.x),
		(room_data.position.y - min_y) * (ROOM_SIZE.y + ROOM_SPACING.y)
	)
	button.position = offset + grid_pos
	
	# Button styling based on room type and state
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = get_room_display_color(room_data)
	button_style.corner_radius_top_left = 3
	button_style.corner_radius_top_right = 3
	button_style.corner_radius_bottom_left = 3
	button_style.corner_radius_bottom_right = 3
	
	# Border for current room
	if room_data.state == 2:  # CURRENT
		button_style.border_width_left = 2
		button_style.border_width_right = 2
		button_style.border_width_top = 2
		button_style.border_width_bottom = 2
		button_style.border_color = Color.WHITE
	
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", button_style)
	button.add_theme_stylebox_override("pressed", button_style)
	
	# Button text (room type indicator)
	var type_symbols = ["C", "E", "T", "B"]  # Combat, Elite, Treasure, Boss
	button.text = type_symbols[room_data.type]
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	# Connect signal
	button.pressed.connect(_on_room_button_pressed.bind(room_data.id))
	
	# Tooltip
	var tooltip_text = get_room_tooltip(room_data)
	button.tooltip_text = tooltip_text
	
	return button

func get_room_display_color(room_data) -> Color:
	"""Get display color for room based on type and state"""
	var base_color = room_colors.get(room_data.type, Color.GRAY)
	var state_modifier = state_colors.get(room_data.state, Color.GRAY)
	
	# Blend base color with state
	match room_data.state:
		0:  # LOCKED
			return base_color.darkened(0.6)
		1:  # AVAILABLE
			return base_color
		2:  # CURRENT
			return base_color.lightened(0.3)
		3:  # CLEARED
			return base_color.darkened(0.3)
		_:
			return base_color

func get_room_tooltip(room_data) -> String:
	"""Generate tooltip text for room"""
	var type_names = ["Combat", "Elite", "Treasure", "Boss"]
	var state_names = ["Locked", "Available", "Current", "Cleared"]
	
	var tooltip = type_names[room_data.type] + " Room\\n"
	tooltip += "Status: " + state_names[room_data.state] + "\\n"
	tooltip += "Connections: " + str(room_data.connections.size())
	
	return tooltip

func draw_connections():
	"""Draw lines between connected rooms"""
	for room_id in room_system.rooms:
		var room_data = room_system.rooms[room_id]
		var room_button = room_buttons.get(room_id)
		
		if not room_button:
			continue
		
		var start_pos = room_button.position + room_button.size / 2
		
		for connected_id in room_data.connections:
			var connected_button = room_buttons.get(connected_id)
			if not connected_button:
				continue
			
			var end_pos = connected_button.position + connected_button.size / 2
			
			# Only draw line in one direction to avoid duplicates
			if room_id < connected_id:
				var line = create_connection_line(start_pos, end_pos, room_data, room_system.rooms[connected_id])
				room_container.add_child(line)
				connection_lines.append(line)

func create_connection_line(start_pos: Vector2, end_pos: Vector2, room_a, room_b) -> Line2D:
	"""Create line between two connected rooms"""
	var line = Line2D.new()
	line.add_point(start_pos)
	line.add_point(end_pos)
	line.width = 2
	
	# Line color based on connection status
	if room_a.state >= 1 and room_b.state >= 1:  # Both available or better
		line.default_color = Color(0.7, 0.7, 0.7, 0.8)
	else:
		line.default_color = Color(0.3, 0.3, 0.3, 0.5)  # Locked connection
	
	return line

func _on_room_button_pressed(room_id: String):
	"""Handle room button press"""
	var room_data = room_system.rooms.get(room_id)
	if not room_data:
		return
	
	print("🗺️ Room selected on minimap: ", room_id)
	
	# Emit signal for other systems
	room_selected.emit(room_id)
	
	# If room is available and not current, suggest transition
	if room_data.state == 1:  # AVAILABLE
		print("💡 Room is available for transition: ", room_id)
		# Could show confirmation dialog here
	elif room_data.state == 0:  # LOCKED
		print("🔒 Room is locked: ", room_id)
	elif room_data.state == 2:  # CURRENT
		print("📍 Already in this room: ", room_id)
	elif room_data.state == 3:  # CLEARED
		print("✅ Room already cleared: ", room_id)

func _on_room_generated(room_data):
	"""Handle new room generation"""
	if is_visible:
		update_minimap()

func _on_room_entered(room_type, room_id: String):
	"""Handle room entry"""
	if is_visible:
		update_room_state(room_id)

func _on_room_cleared(room_id: String):
	"""Handle room cleared"""
	if is_visible:
		update_room_state(room_id)

func _on_room_transition_completed(room_id: String):
	"""Handle room transition completion"""
	if is_visible:
		update_minimap()

func update_room_state(room_id: String):
	"""Update single room display"""
	var room_button = room_buttons.get(room_id)
	if not room_button:
		return
	
	var room_data = room_system.rooms.get(room_id)
	if not room_data:
		return
	
	# Update button color
	var button_style = room_button.get_theme_stylebox("normal") as StyleBoxFlat
	if button_style:
		button_style.bg_color = get_room_display_color(room_data)
		
		# Update border for current room
		if room_data.state == 2:  # CURRENT
			button_style.border_width_left = 2
			button_style.border_width_right = 2
			button_style.border_width_top = 2
			button_style.border_width_bottom = 2
			button_style.border_color = Color.WHITE
		else:
			button_style.border_width_left = 0
			button_style.border_width_right = 0
			button_style.border_width_top = 0
			button_style.border_width_bottom = 0
	
	# Update tooltip
	room_button.tooltip_text = get_room_tooltip(room_data)

func get_minimap_info() -> Dictionary:
	"""Get minimap system information"""
	return {
		"is_visible": is_visible,
		"rooms_displayed": room_buttons.size(),
		"connections_drawn": connection_lines.size(),
		"current_room": room_system.current_room_id if room_system else ""
	}
