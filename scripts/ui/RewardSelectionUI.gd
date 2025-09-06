extends Control
class_name RewardSelectionUI

signal reward_collected(reward_data: Dictionary)
signal reward_selection_closed

@export var display_duration: float = 3.0

# UI Components
var background_panel: Panel
var reward_container: VBoxContainer
var reward_icon: TextureRect
var reward_name_label: Label
var reward_description_label: Label
var collect_button: Button

# Current reward data
var current_reward: Dictionary

func _ready():
	setup_ui()
	hide()

func setup_ui():
	# Create full-screen background overlay
	background_panel = Panel.new()
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	background_panel.add_theme_stylebox_override("panel", style_box)
	add_child(background_panel)
	
	# Create main reward container - CENTERED
	reward_container = VBoxContainer.new()
	reward_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	reward_container.anchor_left = 0.5
	reward_container.anchor_right = 0.5
	reward_container.anchor_top = 0.5
	reward_container.anchor_bottom = 0.5
	reward_container.offset_left = -200  # Half of width (400/2)
	reward_container.offset_right = 200
	reward_container.offset_top = -150   # Half of height (300/2) 
	reward_container.offset_bottom = 150
	reward_container.custom_minimum_size = Vector2(400, 300)
	reward_container.add_theme_constant_override("separation", 20)
	background_panel.add_child(reward_container)
	
	# Reward icon (placeholder)
	reward_icon = TextureRect.new()
	reward_icon.custom_minimum_size = Vector2(80, 80)
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_container.add_child(reward_icon)
	
	# Reward name
	reward_name_label = Label.new()
	reward_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_name_label.add_theme_font_size_override("font_size", 24)
	reward_name_label.add_theme_color_override("font_color", Color.GOLD)
	reward_container.add_child(reward_name_label)
	
	# Reward description
	reward_description_label = Label.new()
	reward_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_description_label.custom_minimum_size.x = 350
	reward_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_description_label.add_theme_font_size_override("font_size", 16)
	reward_description_label.add_theme_color_override("font_color", Color.WHITE)
	reward_container.add_child(reward_description_label)
	
	# Collect button
	collect_button = Button.new()
	collect_button.text = "Collect Reward"
	collect_button.custom_minimum_size = Vector2(200, 50)
	collect_button.pressed.connect(_on_collect_pressed)
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.4, 0.7, 0.9)
	button_style.border_color = Color.GOLD
	button_style.set_border_width_all(2)
	button_style.set_corner_radius_all(5)
	collect_button.add_theme_stylebox_override("normal", button_style)
	
	reward_container.add_child(collect_button)

func show_reward(reward_data: Dictionary):
	current_reward = reward_data
	
	# Update UI elements
	reward_name_label.text = reward_data.name
	reward_description_label.text = reward_data.description
	
	# Set color theme based on reward type
	if reward_data.has("color"):
		reward_name_label.add_theme_color_override("font_color", reward_data.color)
	
	# Show with animation
	show_with_animation()
	
	# Auto-hide after duration (or wait for button press)
	get_tree().create_timer(display_duration).timeout.connect(_on_auto_collect)

func show_with_animation():
	print("Showing reward UI: ", current_reward.name)
	
	# Make sure UI is fully visible
	modulate.a = 1.0
	scale = Vector2(1.0, 1.0)
	show()
	
	# Simple fade-in effect
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_with_animation():
	print("Hiding reward UI")
	
	# Simple fade-out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	hide()
	reward_selection_closed.emit()

func _on_collect_pressed():
	if not current_reward.is_empty():
		# Apply the reward
		var reward_system = get_tree().get_first_node_in_group("reward_system")
		if reward_system:
			reward_system.apply_reward(current_reward)
		
		reward_collected.emit(current_reward)
		hide_with_animation()

func _on_auto_collect():
	# Auto-collect if user doesn't press button
	if visible:
		_on_collect_pressed()