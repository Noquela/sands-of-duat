extends Control
class_name MiniMap

signal room_selected(room_id: int)

@export_group("Minimap Settings")
@export var minimap_size: Vector2 = Vector2(200, 150)
@export var room_icon_size: Vector2 = Vector2(20, 15)
@export var connection_width: float = 3.0

@export_group("Colors")
@export var inactive_room_color: Color = Color.GRAY
@export var active_room_color: Color = Color.WHITE
@export var completed_room_color: Color = Color.GREEN
@export var boss_room_color: Color = Color.RED
@export var elite_room_color: Color = Color.ORANGE
@export var treasure_room_color: Color = Color.YELLOW
@export var connection_color: Color = Color.DIM_GRAY

# References
var room_system: RoomSystem
var room_icons: Array[Control] = []
var connection_lines: Array[Line2D] = []

# UI Elements
var minimap_panel: Panel
var minimap_container: Control

func _ready():
	setup_minimap_ui()
	find_room_system()
	
	# Connect to room system signals
	if room_system:
		room_system.room_entered.connect(_on_room_entered)
		room_system.room_completed.connect(_on_room_completed)

func setup_minimap_ui():
	# Create minimap panel background
	minimap_panel = Panel.new()
	minimap_panel.size = minimap_size + Vector2(20, 20)  # Add padding
	minimap_panel.position = Vector2(get_viewport().get_visible_rect().size.x - minimap_panel.size.x - 10, 10)
	
	# Style the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)
	style_box.border_color = Color.WHITE
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(5)
	minimap_panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(minimap_panel)
	
	# Create container for room icons
	minimap_container = Control.new()
	minimap_container.size = minimap_size
	minimap_container.position = Vector2(10, 10)  # Padding offset
	minimap_panel.add_child(minimap_container)
	
	print("Minimap UI setup complete")

func find_room_system():
	# Find room system in scene
	room_system = get_tree().get_first_node_in_group("room_system")
	if not room_system:
		# Look for RoomSystem node
		var nodes = get_tree().get_nodes_in_group("room_system")
		if nodes.size() > 0:
			room_system = nodes[0]
		else:
			# Search by class name
			room_system = find_node_by_class(get_tree().current_scene, "RoomSystem")
	
	if room_system:
		print("Found room system: ", room_system.name)
		update_minimap()
	else:
		print("Warning: RoomSystem not found for minimap")

func find_node_by_class(node: Node, class_name: String) -> Node:
	if node.get_script() and node.get_script().get_global_name() == class_name:
		return node
	
	for child in node.get_children():
		var result = find_node_by_class(child, class_name)
		if result:
			return result
	
	return null

func update_minimap():
	if not room_system:
		return
	
	# Clear existing icons and connections
	clear_minimap()
	
	# Get room database
	var room_database = room_system.room_database
	if room_database.is_empty():
		print("No rooms to display on minimap")
		return
	
	# Calculate minimap layout
	var layout = calculate_minimap_layout(room_database)
	
	# Create connection lines first (so they appear behind icons)
	create_connection_lines(room_database, layout)
	
	# Create room icons
	create_room_icons(room_database, layout)
	
	print("Minimap updated with ", room_database.size(), " rooms")

func clear_minimap():
	# Remove existing room icons
	for icon in room_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	room_icons.clear()
	
	# Remove existing connection lines
	for line in connection_lines:
		if is_instance_valid(line):
			line.queue_free()
	connection_lines.clear()

func calculate_minimap_layout(room_database: Array) -> Dictionary:
	# For linear room layout, arrange rooms horizontally
	var layout = {}
	var room_spacing = minimap_size.x / max(room_database.size(), 1)
	var y_center = minimap_size.y / 2
	
	for i in range(room_database.size()):
		var room = room_database[i]
		layout[room.id] = Vector2(
			i * room_spacing + room_icon_size.x / 2,
			y_center
		)
	
	return layout

func create_connection_lines(room_database: Array, layout: Dictionary):
	for room in room_database:
		for connection_id in room.connections:
			if connection_id > room.id:  # Only draw each connection once
				create_connection_line(layout[room.id], layout[connection_id])

func create_connection_line(from_pos: Vector2, to_pos: Vector2):
	var line = Line2D.new()
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = connection_width
	line.default_color = connection_color
	
	minimap_container.add_child(line)
	connection_lines.append(line)

func create_room_icons(room_database: Array, layout: Dictionary):
	for room in room_database:
		var icon = create_room_icon(room, layout[room.id])
		room_icons.append(icon)

func create_room_icon(room_data: Dictionary, position: Vector2) -> Control:
	var icon = Panel.new()
	icon.size = room_icon_size
	icon.position = position - room_icon_size / 2
	icon.name = "RoomIcon_" + str(room_data.id)
	
	# Style based on room type and state
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = get_room_color(room_data)
	style_box.border_color = Color.WHITE
	style_box.set_border_width_all(1)
	style_box.set_corner_radius_all(3)
	icon.add_theme_stylebox_override("panel", style_box)
	
	# Add room number label
	var label = Label.new()
	label.text = str(room_data.id + 1)  # Display 1-based indexing
	label.size = room_icon_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	icon.add_child(label)
	
	# Make clickable
	icon.mouse_entered.connect(_on_room_icon_hovered.bind(room_data))
	icon.gui_input.connect(_on_room_icon_input.bind(room_data))
	
	minimap_container.add_child(icon)
	return icon

func get_room_color(room_data: Dictionary) -> Color:
	# Color by state first
	match room_data.state:
		RoomSystem.RoomState.COMPLETED:
			return completed_room_color
		RoomSystem.RoomState.ACTIVE:
			return active_room_color
		RoomSystem.RoomState.LOCKED:
			return inactive_room_color.darkened(0.5)
	
	# Color by type if not completed/active
	match room_data.type:
		RoomSystem.RoomType.BOSS:
			return boss_room_color
		RoomSystem.RoomType.ELITE:
			return elite_room_color
		RoomSystem.RoomType.TREASURE:
			return treasure_room_color
		RoomSystem.RoomType.COMBAT:
			return inactive_room_color
		_:
			return inactive_room_color

func _on_room_icon_hovered(room_data: Dictionary):
	# Show tooltip or highlight effect
	print("Hovering over room ", room_data.id, " - ", room_system.get_room_type_name(room_data.type))

func _on_room_icon_input(event: InputEvent, room_data: Dictionary):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		room_selected.emit(room_data.id)
		print("Selected room ", room_data.id)

func _on_room_entered(room_data: Dictionary):
	# Update minimap when player enters new room
	update_room_icon_state(room_data.id)

func _on_room_completed(room_data: Dictionary):
	# Update minimap when room is completed
	update_room_icon_state(room_data.id)

func update_room_icon_state(room_id: int):
	if room_id < room_icons.size() and is_instance_valid(room_icons[room_id]):
		var icon = room_icons[room_id]
		var room_data = room_system.room_database[room_id]
		
		# Update icon color
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = get_room_color(room_data)
		style_box.border_color = Color.WHITE
		style_box.set_border_width_all(1)
		style_box.set_corner_radius_all(3)
		icon.add_theme_stylebox_override("panel", style_box)

# Public API
func refresh_minimap():
	update_minimap()

func set_visible_rooms_only(visible_rooms: Array[int]):
	# Hide/show specific room icons (for fog of war)
	for i in range(room_icons.size()):
		if is_instance_valid(room_icons[i]):
			room_icons[i].visible = i in visible_rooms

func highlight_room(room_id: int, highlight_color: Color = Color.WHITE):
	if room_id < room_icons.size() and is_instance_valid(room_icons[room_id]):
		var icon = room_icons[room_id]
		var style_box = icon.get_theme_stylebox("panel")
		if style_box:
			style_box.border_color = highlight_color
			style_box.set_border_width_all(3)