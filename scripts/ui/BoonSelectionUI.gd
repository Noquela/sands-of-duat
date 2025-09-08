# BoonSelectionUI.gd  
# Elegant boon selection interface - Hades-inspired
# Sprint 7: Sistema de Recompensas Completo

extends Control

# UI components
@onready var background_overlay: ColorRect
@onready var title_label: Label
@onready var boon_container: HBoxContainer
@onready var instructions_label: Label

# Boon cards are created dynamically - no preloaded scene needed

# Current boon options
var current_boons: Array[Dictionary] = []
var selected_card: Control = null

# Egyptian visual theme
var egyptian_gold = Color(1.0, 0.8, 0.0)
var papyrus_beige = Color(0.96, 0.87, 0.7)
var hieroglyph_dark = Color(0.2, 0.15, 0.1)

# References
var boon_system: Node

signal boon_choice_made(boon_data: Dictionary)

func _ready():
	print("🏺 BoonSelectionUI: Initializing divine blessing interface...")
	
	# Add to group for easy finding
	add_to_group("boon_ui")
	
	# Get references
	boon_system = get_node("/root/BoonSystem") if get_node_or_null("/root/BoonSystem") else null
	
	# Connect to boon system
	if boon_system:
		boon_system.boon_offered.connect(_on_boons_offered)
		print("🔗 BoonSelectionUI connected to BoonSystem")
	
	# Setup UI components
	_setup_ui_components()
	
	# Initially hidden
	hide()
	
	print("🏺 BoonSelectionUI: Egyptian blessing interface ready!")

func _setup_ui_components():
	"""Setup and configure UI elements"""
	
	# Set this Control to full screen first
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create background overlay
	background_overlay = ColorRect.new()
	background_overlay.color = Color(0, 0, 0, 0.8)  # Semi-transparent black
	background_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_overlay)
	
	# Create centered container that will hold everything
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	# Main content panel
	var main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(900, 700)
	center_container.add_child(main_panel)
	
	# Style the main panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.03, 0.01, 0.95)  # Dark Egyptian background
	panel_style.border_color = egyptian_gold
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	main_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Create main layout inside panel
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("margin_left", 40)
	main_vbox.add_theme_constant_override("margin_right", 40)
	main_vbox.add_theme_constant_override("margin_top", 40)
	main_vbox.add_theme_constant_override("margin_bottom", 40)
	main_panel.add_child(main_vbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "BÊNÇÃOS DIVINAS DO EGITO"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", egyptian_gold)
	title_label.add_theme_font_size_override("font_size", 32)
	main_vbox.add_child(title_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 30
	main_vbox.add_child(spacer1)
	
	# Boon cards container
	boon_container = HBoxContainer.new()
	boon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	boon_container.add_theme_constant_override("separation", 30)
	main_vbox.add_child(boon_container)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 20
	main_vbox.add_child(spacer2)
	
	# Instructions
	instructions_label = Label.new()
	instructions_label.text = "Escolha uma bênção divina para fortalecer Khenti"
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.add_theme_color_override("font_color", papyrus_beige)
	instructions_label.add_theme_font_size_override("font_size", 18)
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(instructions_label)
	
	print("🏺 BoonSelectionUI: Centered UI structure created")

func _on_boons_offered(boon_options: Array):
	"""Handle boon options from BoonSystem"""
	print("🏺 BoonSelectionUI: Received %d boon options" % boon_options.size())
	
	current_boons = boon_options
	_display_boon_selection()
	
	# Show UI and pause game - with debug info
	print("🏺 BoonSelectionUI: Making UI visible...")
	show()
	visible = true  # Ensure visibility
	modulate = Color.WHITE  # Ensure not transparent
	
	print("🏺 BoonSelectionUI: UI visible=%s, modulate=%s" % [visible, modulate])
	print("🏺 BoonSelectionUI: UI position=%s, size=%s" % [position, size])
	print("🏺 BoonSelectionUI: UI process_mode=%d" % process_mode)
	
	# Set process mode to always process (ignores pause)
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("🏺 BoonSelectionUI: Set process mode to ALWAYS")
	
	get_tree().paused = true
	print("🏺 BoonSelectionUI: Game paused for boon selection")

func _display_boon_selection():
	"""Display the boon cards for selection"""
	
	# Clear existing cards
	for child in boon_container.get_children():
		child.queue_free()
	
	# Create cards for each boon option
	for i in range(current_boons.size()):
		var boon_data = current_boons[i]
		var card = _create_boon_card(boon_data, i)
		boon_container.add_child(card)
	
	print("🏺 BoonSelectionUI: %d boon cards created" % current_boons.size())

func _create_boon_card(boon_data: Dictionary, index: int) -> Control:
	"""Create a visual card for a boon option"""
	
	# Main card container
	var card = Panel.new()
	card.custom_minimum_size = Vector2(240, 350)
	card.add_theme_stylebox_override("panel", _create_card_style(boon_data.rarity))
	
	# Enable mouse input
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Make clickable - create a lambda to handle the correct parameter order
	card.gui_input.connect(func(event: InputEvent): _on_card_clicked(index, event))
	card.mouse_entered.connect(_on_card_hovered.bind(card, boon_data))
	card.mouse_exited.connect(_on_card_unhovered.bind(card))
	
	# Card content container with proper margins
	var content_vbox = VBoxContainer.new()
	content_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_vbox.add_theme_constant_override("margin_left", 20)
	content_vbox.add_theme_constant_override("margin_right", 20)
	content_vbox.add_theme_constant_override("margin_top", 20)
	content_vbox.add_theme_constant_override("margin_bottom", 20)
	content_vbox.add_theme_constant_override("separation", 8)
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through to card
	card.add_child(content_vbox)
	
	# God name
	var god_label = Label.new()
	god_label.text = boon_data.god_name
	god_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	god_label.add_theme_color_override("font_color", egyptian_gold)
	god_label.add_theme_font_size_override("font_size", 16)
	god_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(god_label)
	
	# Divider line
	var divider = ColorRect.new()
	divider.color = egyptian_gold
	divider.custom_minimum_size.y = 2
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(divider)
	
	# Boon name
	var name_label = Label.new()
	name_label.text = boon_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(name_label)
	
	# Rarity indicator
	var rarity_label = Label.new()
	rarity_label.text = boon_data.rarity_data.name
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", boon_data.rarity_data.color)
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(rarity_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(spacer)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = boon_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_color_override("font_color", papyrus_beige)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(desc_label)
	
	# Values display
	var values_label = Label.new()
	values_label.text = _format_boon_values(boon_data)
	values_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	values_label.add_theme_color_override("font_color", Color.CYAN)
	values_label.add_theme_font_size_override("font_size", 11)
	values_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	values_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(values_label)
	
	# Key binding hint
	var key_hint = Label.new()
	key_hint.text = "Pressione %d" % (index + 1)
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	key_hint.add_theme_font_size_override("font_size", 10)
	key_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(key_hint)
	
	return card

func _create_card_style(rarity: int) -> StyleBox:
	"""Create card style based on rarity"""
	var style = StyleBoxFlat.new()
	
	# Base colors - darker Egyptian theme
	style.bg_color = Color(0.08, 0.04, 0.02, 0.95)  # Dark papyrus with transparency
	style.border_width_left = 4
	style.border_width_right = 4  
	style.border_width_top = 4
	style.border_width_bottom = 4
	
	# Rarity-specific border colors and glow
	match rarity:
		BoonSystem.BoonRarity.COMMON:
			style.border_color = Color(0.9, 0.9, 0.9, 1.0)  # Light gray
		BoonSystem.BoonRarity.RARE:
			style.border_color = Color(0.3, 0.6, 1.0, 1.0)  # Blue
		BoonSystem.BoonRarity.EPIC:
			style.border_color = Color(0.8, 0.4, 1.0, 1.0)  # Purple
		BoonSystem.BoonRarity.LEGENDARY:
			style.border_color = Color(1.0, 0.8, 0.0, 1.0)  # Gold
		_:
			style.border_color = Color.WHITE
	
	# Rounded corners for modern look
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	
	# Add shadow effect
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	style.shadow_offset = Vector2(4, 4)
	
	return style

func _format_boon_values(boon_data: Dictionary) -> String:
	"""Format boon values for display"""
	var values = boon_data.get("values", {})
	var formatted_parts: Array[String] = []
	
	for key in values.keys():
		var value = values[key]
		var formatted_key = key.replace("_", " ").capitalize()
		
		# Format based on common value types
		if key.ends_with("_percent"):
			formatted_parts.append("%s: +%d%%" % [formatted_key.replace(" Percent", ""), value])
		elif key.ends_with("_chance"):
			formatted_parts.append("%s: %d%%" % [formatted_key.replace(" Chance", ""), value])
		elif key.ends_with("_damage"):
			formatted_parts.append("%s: %d" % [formatted_key, value])
		elif key.ends_with("_duration"):
			formatted_parts.append("%s: %.1fs" % [formatted_key, value])
		else:
			formatted_parts.append("%s: %s" % [formatted_key, str(value)])
	
	return "\n".join(formatted_parts)

func _on_card_clicked(index: int, event: InputEvent):
	"""Handle card click"""
	print("🏺 BoonSelectionUI: Card clicked! Index=%d, Event=%s" % [index, event])
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🏺 BoonSelectionUI: Valid left click detected")
		_select_boon(index)

func _on_card_hovered(card: Control, boon_data: Dictionary):
	"""Handle card hover effect"""
	print("🏺 BoonSelectionUI: Mouse entered card: %s from %s" % [boon_data.name, boon_data.god_name])
	var tween = create_tween()
	tween.parallel().tween_property(card, "scale", Vector2(1.08, 1.08), 0.15)
	tween.parallel().tween_property(card, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.15)

func _on_card_unhovered(card: Control):
	"""Handle card unhover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_property(card, "modulate", Color.WHITE, 0.15)

func _select_boon(index: int):
	"""Player selects a boon"""
	if index < 0 or index >= current_boons.size():
		print("⚠️ BoonSelectionUI: Invalid boon index: %d" % index)
		return
	
	var selected_boon = current_boons[index]
	print("🏺 BoonSelectionUI: Player selected %s" % selected_boon.name)
	
	# Apply selection
	if boon_system:
		boon_system.select_boon(selected_boon)
	
	# Emit signal
	boon_choice_made.emit(selected_boon)
	
	# Hide UI and resume game
	_close_selection()

func _close_selection():
	"""Close the boon selection interface"""
	print("🏺 BoonSelectionUI: Closing selection interface")
	
	# Clear current data
	current_boons.clear()
	selected_card = null
	
	# Hide UI
	hide()
	
	# Resume game
	get_tree().paused = false
	print("🏺 BoonSelectionUI: Game resumed")

func _input(event):
	"""Handle input for quick selection"""
	if not visible:
		return
	
	# Number keys for quick selection
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if current_boons.size() > 0:
					_select_boon(0)
			KEY_2:
				if current_boons.size() > 1:
					_select_boon(1)
			KEY_3:
				if current_boons.size() > 2:
					_select_boon(2)
			KEY_ESCAPE:
				# Skip boon selection (if allowed)
				print("🏺 BoonSelectionUI: Boon selection skipped")
				_close_selection()

# Debug function
func test_boon_selection():
	"""Test the UI with dummy boons"""
	var test_boons = [
		{
			"name": "Chama Dourada",
			"description": "Seus ataques causam dano de fogo adicional",
			"god_name": "Rá",
			"rarity": BoonSystem.BoonRarity.COMMON,
			"rarity_data": {"name": "Comum", "color": Color.WHITE},
			"values": {"fire_damage_percent": 15}
		},
		{
			"name": "Reflexos Felinos", 
			"description": "Chance aumentada de esquivar ataques",
			"god_name": "Bastet",
			"rarity": BoonSystem.BoonRarity.RARE,
			"rarity_data": {"name": "Rara", "color": Color.BLUE},
			"values": {"dodge_chance_percent": 35}
		},
		{
			"name": "Pesagem do Coração",
			"description": "Executa inimigos com vida baixa",
			"god_name": "Anubis", 
			"rarity": BoonSystem.BoonRarity.EPIC,
			"rarity_data": {"name": "Épica", "color": Color.PURPLE},
			"values": {"execution_threshold_percent": 40}
		}
	]
	
	_on_boons_offered(test_boons)
	print("🏺 BoonSelectionUI: Test selection displayed")