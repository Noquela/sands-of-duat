extends Control
class_name BoonSelectionUI

signal boon_selected(boon_data: Dictionary)
signal boon_selection_closed

@export_group("UI Settings")
@export var card_size: Vector2 = Vector2(200, 300)
@export var card_spacing: float = 50.0
@export var animation_duration: float = 0.5

@export_group("God Settings")
@export var god_portraits = {
	BoonSystem.BoonGod.RA: "res://art/gods/ra_portrait.png",
	BoonSystem.BoonGod.THOTH: "res://art/gods/thoth_portrait.png", 
	BoonSystem.BoonGod.BASTET: "res://art/gods/bastet_portrait.png",
	BoonSystem.BoonGod.SET: "res://art/gods/set_portrait.png"
}

# UI Components
var background_panel: Panel
var god_portrait: TextureRect
var god_name_label: Label
var god_quote_label: Label
var boon_container: HBoxContainer
var boon_cards: Array[Control] = []
var skip_button: Button

# Data
var current_boons: Array[Dictionary] = []
var current_god: BoonSystem.BoonGod
var boon_system: BoonSystem

# God encounter quotes (like Hades)
var god_quotes = {
	BoonSystem.BoonGod.RA: [
		"The sun's radiance shall guide your path, young prince.",
		"Let my divine light burn away the shadows that bind you.",
		"The power of the eternal sun is yours to wield."
	],
	BoonSystem.BoonGod.THOTH: [
		"Knowledge is the greatest weapon, Khenti-Ka-Nefer.",
		"The wisdom of ages flows through these sacred gifts.",
		"Let ancient secrets empower your journey home."
	],
	BoonSystem.BoonGod.BASTET: [
		"Swift as the desert cat, graceful as the Nile.",
		"My protection shall shield you from harm's way.",
		"The feline spirit awakens within you, young one."
	],
	BoonSystem.BoonGod.SET: [
		"Chaos serves those who embrace its power...",
		"Let disorder be your ally in this cursed realm.",
		"The storm of transformation awaits your choice."
	]
}

func _ready():
	setup_ui()
	find_boon_system()
	hide()

func setup_ui():
	# Create full-screen background overlay
	background_panel = Panel.new()
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)  # Semi-transparent black
	background_panel.add_theme_stylebox_override("panel", style_box)
	add_child(background_panel)
	
	# Create main content container - CENTERED
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	main_vbox.anchor_left = 0.5
	main_vbox.anchor_right = 0.5
	main_vbox.anchor_top = 0.5
	main_vbox.anchor_bottom = 0.5
	main_vbox.offset_left = -400  # Half of width (800/2)
	main_vbox.offset_right = 400
	main_vbox.offset_top = -300   # Half of height (600/2) 
	main_vbox.offset_bottom = 300
	main_vbox.custom_minimum_size = Vector2(800, 600)
	background_panel.add_child(main_vbox)
	
	# God portrait and info
	setup_god_info_section(main_vbox)
	
	# Boon selection cards
	setup_boon_cards_section(main_vbox)
	
	# Skip button
	setup_skip_button(main_vbox)

func setup_god_info_section(parent: Control):
	var god_info_vbox = VBoxContainer.new()
	god_info_vbox.custom_minimum_size.y = 150
	parent.add_child(god_info_vbox)
	
	# God portrait
	god_portrait = TextureRect.new()
	god_portrait.custom_minimum_size = Vector2(100, 100)
	god_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	god_info_vbox.add_child(god_portrait)
	
	# God name
	god_name_label = Label.new()
	god_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	god_name_label.add_theme_font_size_override("font_size", 24)
	god_name_label.add_theme_color_override("font_color", Color.GOLD)
	god_info_vbox.add_child(god_name_label)
	
	# God quote
	god_quote_label = Label.new()
	god_quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	god_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	god_quote_label.custom_minimum_size.x = 600
	god_quote_label.add_theme_font_size_override("font_size", 16)
	god_quote_label.add_theme_color_override("font_color", Color.WHITE)
	god_info_vbox.add_child(god_quote_label)

func setup_boon_cards_section(parent: Control):
	# Container for boon cards
	boon_container = HBoxContainer.new()
	boon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	boon_container.add_theme_constant_override("separation", int(card_spacing))
	parent.add_child(boon_container)

func setup_skip_button(parent: Control):
	skip_button = Button.new()
	skip_button.text = "Continue Without Blessing"
	skip_button.custom_minimum_size = Vector2(200, 40)
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Style the skip button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	button_style.border_color = Color.WHITE
	button_style.set_border_width_all(2)
	skip_button.add_theme_stylebox_override("normal", button_style)
	
	parent.add_child(skip_button)

func find_boon_system():
	boon_system = get_tree().get_first_node_in_group("boon_system")
	if not boon_system:
		print("Warning: BoonSystem not found for BoonSelectionUI")

func show_god_encounter(god: BoonSystem.BoonGod, boon_choices: Array[Dictionary]):
	print("show_god_encounter called with god: ", god, " and ", boon_choices.size(), " boon choices")
	if not boon_system:
		print("Error: No BoonSystem available")
		return
	
	current_god = god
	current_boons = boon_choices
	print("God encounter data set - current_god: ", current_god, ", boons: ", current_boons.size())
	
	# Update god info
	update_god_display()
	
	# Create boon cards
	create_boon_cards()
	
	# Show UI with animation
	show_with_animation()

func update_god_display():
	# Set god portrait (placeholder for now)
	god_name_label.text = boon_system.get_god_name(current_god)
	
	# Set random quote for this god
	var quotes = god_quotes.get(current_god, ["..."])
	god_quote_label.text = "\"" + quotes[randi() % quotes.size()] + "\""

func create_boon_cards():
	# Clear existing cards
	clear_boon_cards()
	
	# Create card for each boon choice
	for i in range(current_boons.size()):
		var boon_data = current_boons[i]
		var card = create_boon_card(boon_data, i)
		boon_container.add_child(card)
		boon_cards.append(card)

func clear_boon_cards():
	for card in boon_cards:
		if is_instance_valid(card):
			card.queue_free()
	boon_cards.clear()

func create_boon_card(boon_data: Dictionary, index: int) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = card_size
	card.name = "BoonCard_" + str(index)
	
	# Style the card based on rarity
	style_boon_card(card, boon_data.rarity)
	
	# Create card content
	var card_vbox = VBoxContainer.new()
	card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_vbox.add_theme_constant_override("separation", 10)
	card.add_child(card_vbox)
	
	# Boon icon (placeholder)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_vbox.add_child(icon)
	
	# Boon name
	var name_label = Label.new()
	name_label.text = boon_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", get_rarity_color(boon_data.rarity))
	card_vbox.add_child(name_label)
	
	# Boon description
	var desc_label = Label.new()
	desc_label.text = boon_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 12)
	card_vbox.add_child(desc_label)
	
	# Rarity indicator
	var rarity_label = Label.new()
	rarity_label.text = boon_system.get_rarity_name(boon_data.rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 10)
	rarity_label.add_theme_color_override("font_color", get_rarity_color(boon_data.rarity))
	card_vbox.add_child(rarity_label)
	
	# Make card clickable
	var button = Button.new()
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.pressed.connect(_on_boon_card_pressed.bind(index))
	card.add_child(button)
	
	# Add hover effects
	setup_card_hover_effects(card, button)
	
	return card

func style_boon_card(card: Panel, rarity: BoonSystem.BoonRarity):
	var style_box = StyleBoxFlat.new()
	
	# Base card styling
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style_box.border_color = get_rarity_color(rarity)
	style_box.set_border_width_all(3)
	style_box.set_corner_radius_all(10)
	
	# Add glow effect for higher rarities
	if rarity >= BoonSystem.BoonRarity.EPIC:
		style_box.shadow_color = get_rarity_color(rarity)
		style_box.shadow_color.a = 0.5
		style_box.shadow_size = 5
	
	card.add_theme_stylebox_override("panel", style_box)

func setup_card_hover_effects(card: Panel, button: Button):
	# Mouse enter/exit effects
	button.mouse_entered.connect(_on_card_hover_enter.bind(card))
	button.mouse_exited.connect(_on_card_hover_exit.bind(card))

func _on_card_hover_enter(card: Panel):
	# Scale up slightly on hover
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.1)

func _on_card_hover_exit(card: Panel):
	# Scale back to normal
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)

func get_rarity_color(rarity: BoonSystem.BoonRarity) -> Color:
	if boon_system:
		return boon_system.get_rarity_color(rarity)
	
	# Fallback colors
	match rarity:
		BoonSystem.BoonRarity.COMMON:
			return Color.WHITE
		BoonSystem.BoonRarity.RARE:
			return Color.CYAN
		BoonSystem.BoonRarity.EPIC:
			return Color.MAGENTA
		BoonSystem.BoonRarity.LEGENDARY:
			return Color.GOLD
		_:
			return Color.GRAY

func show_with_animation():
	print("show_with_animation called")
	
	# Make sure UI is fully visible first
	modulate.a = 1.0
	scale = Vector2(1.0, 1.0)
	show()
	
	print("UI made visible, visible:", visible)
	print("UI modulate:", modulate)
	print("UI position:", position)
	print("UI size:", size)
	
	# DON'T pause the game for now - this is causing the freeze
	# get_tree().paused = true

func hide_with_animation():
	print("hide_with_animation called")
	# Just hide for now
	hide()
	
	# Don't unpause since we didn't pause
	# get_tree().paused = false
	
	boon_selection_closed.emit()

func _on_boon_card_pressed(card_index: int):
	if card_index < current_boons.size():
		var selected_boon = current_boons[card_index]
		print("Player selected boon: ", selected_boon.name)
		
		# Apply the boon
		if boon_system:
			boon_system.apply_boon(selected_boon)
		
		boon_selected.emit(selected_boon)
		hide_with_animation()

func _on_skip_pressed():
	print("Player skipped boon selection")
	hide_with_animation()

# Public API for room system integration
func trigger_god_encounter() -> bool:
	if not boon_system:
		return false
	
	# This is now called directly when RewardSystem determines it should be a boon
	var random_god = BoonSystem.BoonGod.values()[randi() % BoonSystem.BoonGod.size()]
	var boon_choices = boon_system.generate_boon_choices()
	
	if boon_choices.size() > 0:
		show_god_encounter(random_god, boon_choices)
		return true
	
	return false

func force_god_encounter(god: BoonSystem.BoonGod):
	print("force_god_encounter called with god: ", god)
	if not boon_system:
		print("Error: BoonSystem not found in force_god_encounter")
		return
	
	print("BoonSystem found, generating boon choices...")
	var boon_choices = boon_system.generate_boon_choices()
	print("Generated ", boon_choices.size(), " boon choices")
	if boon_choices.size() > 0:
		show_god_encounter(god, boon_choices)
	else:
		print("Error: No boon choices generated")