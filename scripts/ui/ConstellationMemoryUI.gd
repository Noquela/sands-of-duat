extends Control
class_name ConstellationMemoryUI

signal upgrade_purchased(upgrade_id: String)
signal category_filter_changed(category: String)

@export_group("Constellation Settings")
@export var constellation_radius: float = 300.0
@export var node_size: float = 40.0
@export var connection_color: Color = Color.GOLD
@export var available_color: Color = Color.WHITE
@export var purchased_color: Color = Color.GREEN
@export var locked_color: Color = Color.GRAY

# UI Structure
var constellation_center: Vector2
var upgrade_nodes: Dictionary = {}  # upgrade_id -> ConstellationNode
var connection_lines: Array[Line2D] = []
var selected_upgrade: String = ""

# Data
var memory_system: MemorySystem
var current_filter: String = "all"
var node_positions: Dictionary = {}

# UI Components  
var currency_panel: Panel
var tooltip_panel: Panel
var filter_buttons: HBoxContainer

func _ready():
	setup_constellation_ui()
	find_memory_system()
	create_constellation_layout()

func setup_constellation_ui():
	name = "ConstellationMemoryUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	constellation_center = size * 0.5
	
	# Create currency display at top
	create_currency_display()
	
	# Create category filters
	create_category_filters()
	
	# Create tooltip panel
	create_tooltip_panel()

func find_memory_system():
	memory_system = get_tree().get_first_node_in_group("memory_system")
	if memory_system:
		memory_system.memory_fragments_changed.connect(_on_currency_changed)
		memory_system.memory_upgrade_purchased.connect(_on_upgrade_purchased)

func create_currency_display():
	currency_panel = Panel.new()
	currency_panel.position = Vector2(20, 20)
	currency_panel.size = Vector2(800, 80)
	add_child(currency_panel)
	
	# Background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.8)
	bg_style.border_color = Color.GOLD
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = 10
	bg_style.corner_radius_top_right = 10
	bg_style.corner_radius_bottom_left = 10
	bg_style.corner_radius_bottom_right = 10
	currency_panel.add_theme_stylebox_override("panel", bg_style)
	
	# Currency layout
	var currency_hbox = HBoxContainer.new()
	currency_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	currency_hbox.add_theme_constant_override("separation", 40)
	currency_panel.add_child(currency_hbox)
	
	# Add currency labels
	add_currency_label(currency_hbox, "Memory Fragments", "memory_fragments")
	add_currency_label(currency_hbox, "Ankh Fragments", "ankh_fragments")  
	add_currency_label(currency_hbox, "Golden Scarabs", "golden_scarabs")
	add_currency_label(currency_hbox, "Heart Pieces", "heart_pieces")

func add_currency_label(parent: HBoxContainer, currency_name: String, currency_key: String):
	var vbox = VBoxContainer.new()
	parent.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = currency_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.GOLD)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	var amount_label = Label.new()
	amount_label.name = currency_key + "_label"
	amount_label.text = "0"
	amount_label.add_theme_font_size_override("font_size", 24)
	amount_label.add_theme_color_override("font_color", Color.WHITE)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(amount_label)

func create_category_filters():
	filter_buttons = HBoxContainer.new()
	filter_buttons.position = Vector2(20, 120)
	filter_buttons.size = Vector2(800, 50)
	filter_buttons.add_theme_constant_override("separation", 10)
	add_child(filter_buttons)
	
	var categories = ["all", "health", "damage", "speed", "boons", "wealth", "special", "weapons", "status"]
	var category_names = {
		"all": "All Memories",
		"health": "Vitality", 
		"damage": "Combat",
		"speed": "Mobility",
		"boons": "Divine", 
		"wealth": "Prosperity",
		"special": "Mystical",
		"weapons": "Arsenal",
		"status": "Resilience"
	}
	
	for category in categories:
		var button = Button.new()
		button.text = category_names.get(category, category.capitalize())
		button.custom_minimum_size = Vector2(85, 40)
		button.pressed.connect(_on_filter_pressed.bind(category))
		filter_buttons.add_child(button)

func create_tooltip_panel():
	tooltip_panel = Panel.new()
	tooltip_panel.visible = false
	tooltip_panel.size = Vector2(300, 200)
	tooltip_panel.z_index = 100
	add_child(tooltip_panel)
	
	# Tooltip background
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	tooltip_style.border_color = Color.GOLD
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_bottom = 2
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)

func create_constellation_layout():
	if not memory_system:
		return
	
	# Clear existing nodes and lines
	clear_constellation()
	
	# Get all upgrades
	var all_upgrades = []
	for upgrade_id in memory_system.memory_upgrades:
		if should_show_upgrade(upgrade_id):
			all_upgrades.append(upgrade_id)
	
	# Calculate positions for each upgrade in constellation pattern
	calculate_constellation_positions(all_upgrades)
	
	# Create connection lines first (so they appear behind nodes)
	create_connection_lines(all_upgrades)
	
	# Create upgrade nodes
	create_upgrade_nodes(all_upgrades)

func should_show_upgrade(upgrade_id: String) -> bool:
	if current_filter == "all":
		return true
	
	var upgrade_info = memory_system.get_upgrade_info(upgrade_id)
	return upgrade_info.get("category", "") == current_filter

func calculate_constellation_positions(upgrades: Array):
	node_positions.clear()
	
	# Organize upgrades by category for better constellation layout
	var categories = {}
	for upgrade_id in upgrades:
		var upgrade_info = memory_system.get_upgrade_info(upgrade_id)
		var category = upgrade_info.get("category", "unknown")
		if not categories.has(category):
			categories[category] = []
		categories[category].append(upgrade_id)
	
	# Position categories in circle, upgrades in smaller circles within
	var category_keys = categories.keys()
	var category_count = category_keys.size()
	
	for i in range(category_count):
		var category = category_keys[i]
		var category_angle = (i * 2 * PI) / category_count
		var category_center = constellation_center + Vector2(
			cos(category_angle) * constellation_radius * 0.6,
			sin(category_angle) * constellation_radius * 0.6
		)
		
		var category_upgrades = categories[category]
		var upgrade_count = category_upgrades.size()
		
		for j in range(upgrade_count):
			var upgrade_id = category_upgrades[j]
			var upgrade_angle = (j * 2 * PI) / upgrade_count
			var upgrade_radius = min(80.0, 40.0 + upgrade_count * 8)
			
			var position = category_center + Vector2(
				cos(upgrade_angle) * upgrade_radius,
				sin(upgrade_angle) * upgrade_radius
			)
			
			node_positions[upgrade_id] = position

func create_connection_lines(upgrades: Array):
	# Clear existing lines
	for line in connection_lines:
		if is_instance_valid(line):
			line.queue_free()
	connection_lines.clear()
	
	# Create dependency lines between upgrades
	for upgrade_id in upgrades:
		var upgrade_info = memory_system.get_upgrade_info(upgrade_id)
		var prerequisites = upgrade_info.get("prerequisites", [])
		
		for prereq in prerequisites:
			if node_positions.has(prereq) and node_positions.has(upgrade_id):
				create_connection_line(prereq, upgrade_id)

func create_connection_line(from_id: String, to_id: String):
	var line = Line2D.new()
	line.add_point(node_positions[from_id])
	line.add_point(node_positions[to_id])
	line.width = 3.0
	line.default_color = connection_color
	line.z_index = -1
	add_child(line)
	connection_lines.append(line)

func create_upgrade_nodes(upgrades: Array):
	# Clear existing nodes
	for node in upgrade_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	upgrade_nodes.clear()
	
	# Create constellation nodes for each upgrade
	for upgrade_id in upgrades:
		create_constellation_node(upgrade_id)

func create_constellation_node(upgrade_id: String):
	var upgrade_info = memory_system.get_upgrade_info(upgrade_id)
	var position = node_positions.get(upgrade_id, constellation_center)
	
	# Create node button
	var node_button = Button.new()
	node_button.name = "Node_" + upgrade_id
	node_button.size = Vector2(node_size, node_size)
	node_button.position = position - Vector2(node_size * 0.5, node_size * 0.5)
	
	# Style based on upgrade state
	setup_node_appearance(node_button, upgrade_info)
	
	# Connect signals
	node_button.pressed.connect(_on_node_pressed.bind(upgrade_id))
	node_button.mouse_entered.connect(_on_node_hover.bind(upgrade_id))
	node_button.mouse_exited.connect(_on_node_unhover)
	
	add_child(node_button)
	upgrade_nodes[upgrade_id] = node_button
	
	# Add star glow effect for available upgrades
	if upgrade_info.get("can_purchase", false):
		add_star_glow_effect(node_button)

func setup_node_appearance(button: Button, upgrade_info: Dictionary):
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = node_size * 0.5
	style.corner_radius_top_right = node_size * 0.5  
	style.corner_radius_bottom_left = node_size * 0.5
	style.corner_radius_bottom_right = node_size * 0.5
	
	# Color based on state
	if upgrade_info.get("purchased", false):
		style.bg_color = purchased_color
		style.border_color = Color.GREEN
	elif upgrade_info.get("can_purchase", false):
		style.bg_color = available_color
		style.border_color = Color.GOLD
	else:
		style.bg_color = locked_color
		style.border_color = Color.DARK_GRAY
	
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	
	# Node text (tier or first letter)
	var tier = upgrade_info.get("tier", 1)
	button.text = str(tier)
	button.add_theme_font_size_override("font_size", 18)

func add_star_glow_effect(button: Button):
	# Create glowing particle effect for available upgrades
	var glow_timer = Timer.new()
	glow_timer.wait_time = 0.1
	glow_timer.timeout.connect(_pulse_node_glow.bind(button))
	glow_timer.autostart = true
	button.add_child(glow_timer)

func _pulse_node_glow(button: Button):
	if not is_instance_valid(button):
		return
	
	var time = Time.get_time_dict_from_system()
	var pulse = sin(time.second * 2 + time.millisecond * 0.001) * 0.5 + 0.5
	button.modulate = Color.WHITE.lerp(Color.YELLOW, pulse * 0.3)

func clear_constellation():
	for node in upgrade_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	upgrade_nodes.clear()
	
	for line in connection_lines:
		if is_instance_valid(line):
			line.queue_free()
	connection_lines.clear()
	
	node_positions.clear()

func show_upgrade_tooltip(upgrade_id: String, mouse_position: Vector2):
	if not memory_system:
		return
	
	var upgrade_info = memory_system.get_upgrade_info(upgrade_id)
	selected_upgrade = upgrade_id
	
	# Position tooltip near mouse
	tooltip_panel.position = mouse_position + Vector2(20, 20)
	tooltip_panel.visible = true
	
	# Clear existing tooltip content
	for child in tooltip_panel.get_children():
		child.queue_free()
	
	# Create tooltip content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	tooltip_panel.add_child(vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = upgrade_info.get("name", "Unknown")
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title_label)
	
	# Description
	var desc_label = RichTextLabel.new()
	desc_label.text = upgrade_info.get("description", "")
	desc_label.fit_content = true
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)
	
	# Cost
	var cost_label = Label.new()
	cost_label.text = "Cost: " + str(upgrade_info.get("cost", 0)) + " Memory Fragments"
	cost_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(cost_label)
	
	# Purchase button if available
	if upgrade_info.get("can_purchase", false):
		var purchase_button = Button.new()
		purchase_button.text = "Purchase Memory"
		purchase_button.pressed.connect(_on_purchase_pressed.bind(upgrade_id))
		vbox.add_child(purchase_button)

func hide_tooltip():
	tooltip_panel.visible = false
	selected_upgrade = ""

func refresh_constellation():
	create_constellation_layout()
	update_currency_display()

func update_currency_display():
	if not memory_system:
		return
	
	var currencies = memory_system.get_currency_totals()
	
	for currency_key in currencies:
		var label = currency_panel.get_node_or_null(currency_key + "_label")
		if label:
			label.text = str(currencies[currency_key])

# Signal handlers
func _on_filter_pressed(category: String):
	current_filter = category
	category_filter_changed.emit(category)
	refresh_constellation()

func _on_node_pressed(upgrade_id: String):
	upgrade_selected.emit(upgrade_id)

func _on_node_hover(upgrade_id: String):
	show_upgrade_tooltip(upgrade_id, get_global_mouse_position())

func _on_node_unhover():
	hide_tooltip()

func _on_purchase_pressed(upgrade_id: String):
	if memory_system and memory_system.purchase_upgrade(upgrade_id):
		upgrade_purchased.emit(upgrade_id)
		refresh_constellation()

func _on_currency_changed(_new_amount: int):
	update_currency_display()
	refresh_constellation()

func _on_upgrade_purchased(upgrade_id: String, _cost: int):
	refresh_constellation()

# Public API
func open_constellation_view():
	visible = true
	refresh_constellation()

func close_constellation_view():
	visible = false
	hide_tooltip()

func set_category_filter(category: String):
	current_filter = category
	refresh_constellation()