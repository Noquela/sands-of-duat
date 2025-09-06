extends Control
class_name PoolOfMemoriesUI

signal upgrade_selected(upgrade_id: String)
signal category_changed(category: String)
signal exit_pool()

# UI Elements - Constellation Style
@onready var constellation_container: Control = $ConstellationView
@onready var currency_display: HBoxContainer = $CurrencyBar
@onready var upgrade_tooltip: Panel = $UpgradeTooltip
@onready var constellation_lines: Control = $ConstellationView/ConnectionLines
@onready var category_tabs: TabContainer = $VBox/Content/CategoryTabs
@onready var upgrade_grid: GridContainer = $VBox/Content/CategoryTabs/Health/ScrollContainer/UpgradeGrid
@onready var upgrade_info_panel: Panel = $VBox/Content/InfoPanel
@onready var upgrade_name_label: Label = $VBox/Content/InfoPanel/VBox/NameLabel
@onready var upgrade_description_label: RichTextLabel = $VBox/Content/InfoPanel/VBox/DescriptionLabel
@onready var upgrade_cost_label: Label = $VBox/Content/InfoPanel/VBox/CostLabel
@onready var purchase_button: Button = $VBox/Content/InfoPanel/VBox/PurchaseButton
@onready var exit_button: Button = $VBox/Footer/ExitButton

# References
var memory_system: MemorySystem
var selected_upgrade_id: String = ""
var current_category: String = "health"

# UI Colors
var color_available: Color = Color.WHITE
var color_purchased: Color = Color.GREEN
var color_locked: Color = Color.GRAY
var color_unaffordable: Color = Color.RED

func _ready():
	setup_pool_ui()
	find_memory_system()
	connect_signals()

func setup_pool_ui():
	# Initialize UI structure
	create_ui_elements()
	setup_categories()

func create_ui_elements():
	# Create main VBox structure
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Header with fragments display
	var header = HBoxContainer.new()
	main_vbox.add_child(header)
	
	var title_label = Label.new()
	title_label.text = "Pool of Memories"
	title_label.add_theme_font_size_override("font_size", 32)
	header.add_child(title_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	memory_fragments_label = Label.new()
	memory_fragments_label.text = "Memory Fragments: 0"
	memory_fragments_label.add_theme_font_size_override("font_size", 20)
	header.add_child(memory_fragments_label)
	
	# Content area with tabs and info panel
	var content_container = HBoxContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_container)
	
	# Category tabs
	category_tabs = TabContainer.new()
	category_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_tabs.custom_minimum_size.x = 600
	content_container.add_child(category_tabs)
	
	# Info panel
	upgrade_info_panel = Panel.new()
	upgrade_info_panel.custom_minimum_size.x = 300
	content_container.add_child(upgrade_info_panel)
	
	var info_vbox = VBoxContainer.new()
	upgrade_info_panel.add_child(info_vbox)
	info_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_vbox.add_theme_constant_override("separation", 10)
	
	upgrade_name_label = Label.new()
	upgrade_name_label.add_theme_font_size_override("font_size", 24)
	upgrade_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(upgrade_name_label)
	
	upgrade_description_label = RichTextLabel.new()
	upgrade_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_description_label.fit_content = true
	info_vbox.add_child(upgrade_description_label)
	
	upgrade_cost_label = Label.new()
	upgrade_cost_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(upgrade_cost_label)
	
	purchase_button = Button.new()
	purchase_button.text = "Purchase Upgrade"
	purchase_button.custom_minimum_size.y = 50
	info_vbox.add_child(purchase_button)
	
	# Footer with exit button
	var footer = HBoxContainer.new()
	main_vbox.add_child(footer)
	
	var footer_spacer = Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	
	exit_button = Button.new()
	exit_button.text = "Return to Expedition"
	exit_button.custom_minimum_size = Vector2(200, 50)
	footer.add_child(exit_button)

func setup_categories():
	var categories = ["health", "damage", "speed", "boons", "wealth", "special", "weapons", "status"]
	var category_names = {
		"health": "Vitality",
		"damage": "Combat",
		"speed": "Mobility", 
		"boons": "Divine",
		"wealth": "Riches",
		"special": "Mystical",
		"weapons": "Arsenal",
		"status": "Resilience"
	}
	
	for category in categories:
		var tab_name = category_names.get(category, category.capitalize())
		var scroll_container = ScrollContainer.new()
		scroll_container.name = category.capitalize()
		category_tabs.add_child(scroll_container)
		category_tabs.set_tab_title(category_tabs.get_tab_count() - 1, tab_name)
		
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		scroll_container.add_child(grid)

func find_memory_system():
	memory_system = get_tree().get_first_node_in_group("memory_system")
	if memory_system:
		refresh_ui()
	else:
		print("Warning: Memory System not found!")

func connect_signals():
	if memory_system:
		memory_system.memory_fragments_changed.connect(_on_fragments_changed)
		memory_system.memory_upgrade_purchased.connect(_on_upgrade_purchased)
	
	category_tabs.tab_changed.connect(_on_category_changed)
	purchase_button.pressed.connect(_on_purchase_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func refresh_ui():
	if not memory_system:
		return
	
	update_fragments_display()
	update_all_categories()

func update_fragments_display():
	if memory_system and memory_fragments_label:
		memory_fragments_label.text = "Memory Fragments: " + str(memory_system.get_memory_fragments())

func update_all_categories():
	var categories = ["health", "damage", "speed", "boons", "wealth", "special", "weapons", "status"]
	for category in categories:
		update_category_upgrades(category)

func update_category_upgrades(category: String):
	var tab_index = get_category_tab_index(category)
	if tab_index == -1:
		return
	
	var tab_node = category_tabs.get_tab_control(tab_index)
	var grid = tab_node.get_child(0).get_child(0) # ScrollContainer -> GridContainer
	
	# Clear existing upgrade buttons
	for child in grid.get_children():
		child.queue_free()
	
	# Get upgrades for this category
	var category_upgrades = memory_system.get_upgrades_by_category(category)
	
	# Create upgrade buttons
	for upgrade_id in category_upgrades:
		var upgrade_info = memory_system.get_upgrade_info(upgrade_id)
		create_upgrade_button(grid, upgrade_id, upgrade_info)

func get_category_tab_index(category: String) -> int:
	var category_names = {
		"health": "Vitality",
		"damage": "Combat", 
		"speed": "Mobility",
		"boons": "Divine",
		"wealth": "Riches",
		"special": "Mystical",
		"weapons": "Arsenal",
		"status": "Resilience"
	}
	
	var tab_name = category_names.get(category, category.capitalize())
	for i in category_tabs.get_tab_count():
		if category_tabs.get_tab_title(i) == tab_name:
			return i
	return -1

func create_upgrade_button(parent: GridContainer, upgrade_id: String, upgrade_info: Dictionary):
	var button = Button.new()
	button.name = upgrade_id
	button.text = upgrade_info.name + "\n" + str(upgrade_info.cost) + " fragments"
	button.custom_minimum_size = Vector2(250, 80)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Set button appearance based on state
	if upgrade_info.purchased:
		button.modulate = color_purchased
		button.text += "\n[OWNED]"
		button.disabled = true
	elif not upgrade_info.can_purchase:
		if upgrade_info.can_afford:
			button.modulate = color_locked
			button.text += "\n[LOCKED]"
		else:
			button.modulate = color_unaffordable
			button.text += "\n[NEED " + str(upgrade_info.cost) + "]"
		button.disabled = true
	else:
		button.modulate = color_available
	
	# Connect button signal
	button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id))
	button.mouse_entered.connect(_on_upgrade_hover.bind(upgrade_id))
	
	parent.add_child(button)

func show_upgrade_info(upgrade_id: String):
	if not memory_system:
		return
	
	var upgrade_info = memory_system.get_upgrade_info(upgrade_id)
	if upgrade_info.is_empty():
		return
	
	selected_upgrade_id = upgrade_id
	
	upgrade_name_label.text = upgrade_info.name
	upgrade_description_label.text = upgrade_info.description
	upgrade_cost_label.text = "Cost: " + str(upgrade_info.cost) + " Memory Fragments"
	
	# Update purchase button
	if upgrade_info.purchased:
		purchase_button.text = "Already Owned"
		purchase_button.disabled = true
	elif not upgrade_info.can_purchase:
		if upgrade_info.can_afford:
			purchase_button.text = "Requirements Not Met"
		else:
			purchase_button.text = "Not Enough Fragments"
		purchase_button.disabled = true
	else:
		purchase_button.text = "Purchase Upgrade"
		purchase_button.disabled = false

func _on_fragments_changed(new_amount: int):
	update_fragments_display()
	update_all_categories()

func _on_upgrade_purchased(upgrade_id: String, cost: int):
	print("Upgrade purchased: ", upgrade_id)
	refresh_ui()

func _on_category_changed(tab_index: int):
	var categories = ["health", "damage", "speed", "boons", "wealth", "special", "weapons", "status"]
	if tab_index < categories.size():
		current_category = categories[tab_index]
		category_changed.emit(current_category)

func _on_upgrade_button_pressed(upgrade_id: String):
	upgrade_selected.emit(upgrade_id)
	show_upgrade_info(upgrade_id)

func _on_upgrade_hover(upgrade_id: String):
	show_upgrade_info(upgrade_id)

func _on_purchase_pressed():
	if selected_upgrade_id.is_empty() or not memory_system:
		return
	
	if memory_system.purchase_upgrade(selected_upgrade_id):
		print("Successfully purchased upgrade: ", selected_upgrade_id)
	else:
		print("Failed to purchase upgrade: ", selected_upgrade_id)

func _on_exit_pressed():
	exit_pool.emit()

# Public API
func open_pool():
	show()
	refresh_ui()

func close_pool():
	hide()

func set_initial_category(category: String):
	var tab_index = get_category_tab_index(category)
	if tab_index != -1:
		category_tabs.current_tab = tab_index
		current_category = category