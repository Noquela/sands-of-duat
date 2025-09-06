extends Node3D
class_name JudgmentHall

signal moral_choice_made(choice_type: String, choice_value: bool)
signal ammit_boss_triggered()
signal truth_dialogue_started(npc_name: String)
signal judgment_complete(player_verdict: String)
signal feather_collected(feather_count: int)

@export_group("Judgment Hall Settings")
@export var hall_length: float = 120.0
@export var hall_width: float = 60.0  
@export var column_height: float = 15.0
@export var moral_choice_count: int = 7

# Visual Palette - Judgment Theme
@export_group("Visual Palette")
@export var royal_gold: Color = Color(1.0, 0.8, 0.2, 1.0)      # Dourado real
@export var marble_white: Color = Color(0.95, 0.95, 0.98, 1.0)  # Mármore branco
@export var emerald_green: Color = Color(0.1, 0.7, 0.4, 1.0)    # Verde esmeralda

# Node references
@onready var environment: Node3D = $Environment
@onready var architecture: Node3D = $Architecture
@onready var moral_chambers: Node3D = $MoralChambers
@onready var enemy_spawner: Node3D = $EnemySpawner
@onready var judgment_ui: Control = $JudgmentUI
@onready var divine_lighting: Node3D = $DivineLighting

# Systems
var biome_generator: Node
var player: Node3D
var judgment_system: Node
var truth_dialogue_system: Node

# Judgment Hall state
var is_active: bool = false
var moral_choices_made: Dictionary = {}
var truth_score: int = 0
var lie_score: int = 0
var feathers_collected: int = 0
var current_chamber_index: int = 0

# Ma'at Scale system
var maat_chambers: Array[Node3D] = []
var scale_of_maat: Node3D
var player_moral_alignment: String = "neutral"  # "truth", "lies", "neutral"
var judgment_consequences: Dictionary = {}

# Architecture elements
var massive_columns: Array[MeshInstance3D] = []
var hieroglyph_walls: Array[MeshInstance3D] = []
var judgment_throne: Node3D

func _ready():
	setup_judgment_hall()
	find_system_references()
	create_hall_architecture()
	initialize_moral_systems()

func setup_judgment_hall():
	add_to_group("judgment_hall_biome")
	add_to_group("biomes")
	print("Salão do Julgamento initialized - Where truth and falsehood face divine justice")

func find_system_references():
	biome_generator = get_tree().get_first_node_in_group("biome_generator")
	player = get_tree().get_first_node_in_group("player")
	judgment_system = get_tree().get_first_node_in_group("judgment_system")

func create_hall_architecture():
	# Create the grand judgment hall
	create_main_hall_structure()
	
	# Add massive columns
	create_massive_columns()
	
	# Create hieroglyph walls
	create_hieroglyph_walls()
	
	# Build judgment throne (Ammit's domain)
	create_judgment_throne()
	
	# Add divine lighting
	create_divine_lighting()

func create_main_hall_structure():
	# Main hall floor - polished marble
	var hall_floor = MeshInstance3D.new()
	hall_floor.name = "JudgmentHallFloor"
	architecture.add_child(hall_floor)
	
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(hall_width, 0.5, hall_length)
	hall_floor.mesh = floor_mesh
	hall_floor.position = Vector3(0, -0.25, 0)
	
	# Marble floor material
	var marble_material = StandardMaterial3D.new()
	marble_material.albedo_color = marble_white
	marble_material.metallic = 0.1
	marble_material.roughness = 0.05  # Very smooth, reflective
	marble_material.emission_enabled = true
	marble_material.emission = royal_gold * 0.1  # Subtle golden glow
	hall_floor.material_override = marble_material
	
	# Hall ceiling with Egyptian patterns
	create_ornate_ceiling()
	
	# Side walls with judgment scenes
	create_judgment_murals()

func create_ornate_ceiling():
	var ceiling = MeshInstance3D.new()
	ceiling.name = "HallCeiling"
	architecture.add_child(ceiling)
	
	var ceiling_mesh = BoxMesh.new()
	ceiling_mesh.size = Vector3(hall_width, 1.0, hall_length)
	ceiling.mesh = ceiling_mesh
	ceiling.position = Vector3(0, column_height + 0.5, 0)
	
	# Ornate ceiling material with Egyptian motifs
	var ceiling_material = StandardMaterial3D.new()
	ceiling_material.albedo_color = royal_gold
	ceiling_material.emission_enabled = true
	ceiling_material.emission = royal_gold * 0.3
	ceiling_material.metallic = 0.8
	ceiling_material.roughness = 0.2
	ceiling.material_override = ceiling_material

func create_judgment_murals():
	# Left wall - scenes of truth and judgment
	create_mural_wall(Vector3(-hall_width * 0.5, column_height * 0.5, 0), "truth_scenes")
	
	# Right wall - scenes of consequences and Ma'at
	create_mural_wall(Vector3(hall_width * 0.5, column_height * 0.5, 0), "maat_scenes")

func create_mural_wall(position: Vector3, mural_type: String):
	var wall = MeshInstance3D.new()
	wall.name = "JudgmentMural_" + mural_type
	architecture.add_child(wall)
	
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(2.0, column_height, hall_length * 0.8)
	wall.mesh = wall_mesh
	wall.position = position
	
	# Mural material with hieroglyphs
	var mural_material = StandardMaterial3D.new()
	mural_material.albedo_color = Color(0.9, 0.85, 0.7, 1.0)  # Aged stone
	mural_material.emission_enabled = true
	mural_material.emission = emerald_green * 0.2  # Mystical green glow
	mural_material.roughness = 0.6
	wall.material_override = mural_material
	
	hieroglyph_walls.append(wall)

func create_massive_columns():
	# Create 8 massive columns along the hall
	var column_positions = []
	
	# 4 columns on each side
	for i in range(4):
		var z_pos = -hall_length * 0.3 + (i * hall_length * 0.2)
		column_positions.append(Vector3(-hall_width * 0.3, column_height * 0.5, z_pos))  # Left side
		column_positions.append(Vector3(hall_width * 0.3, column_height * 0.5, z_pos))   # Right side
	
	for pos in column_positions:
		create_egyptian_column(pos)

func create_egyptian_column(position: Vector3):
	var column = MeshInstance3D.new()
	column.name = "JudgmentColumn"
	architecture.add_child(column)
	
	# Column shaft
	var column_mesh = CylinderMesh.new()
	column_mesh.radius_top = 1.8
	column_mesh.radius_bottom = 2.0
	column_mesh.height = column_height
	column.mesh = column_mesh
	column.position = position
	
	# Column material - royal gold with marble details
	var column_material = StandardMaterial3D.new()
	column_material.albedo_color = royal_gold
	column_material.emission_enabled = true
	column_material.emission = royal_gold * 0.4
	column_material.metallic = 0.7
	column_material.roughness = 0.3
	column.material_override = column_material
	
	# Column capital (Egyptian lotus design)
	create_column_capital(column, position)
	
	massive_columns.append(column)

func create_column_capital(parent_column: MeshInstance3D, base_position: Vector3):
	var capital = MeshInstance3D.new()
	capital.name = "ColumnCapital"
	parent_column.add_child(capital)
	
	var capital_mesh = CylinderMesh.new()
	capital_mesh.radius_top = 2.5
	capital_mesh.radius_bottom = 1.8
	capital_mesh.height = 1.5
	capital.mesh = capital_mesh
	capital.position = Vector3(0, column_height * 0.5 + 0.75, 0)
	
	# Capital material - ornate gold
	var capital_material = StandardMaterial3D.new()
	capital_material.albedo_color = royal_gold * 1.1
	capital_material.emission_enabled = true
	capital_material.emission = royal_gold * 0.5
	capital_material.metallic = 0.9
	capital_material.roughness = 0.1
	capital.material_override = capital_material

func create_judgment_throne():
	# Ammit's judgment throne at the far end
	judgment_throne = StaticBody3D.new()
	judgment_throne.name = "AmmitJudgmentThrone"
	judgment_throne.position = Vector3(0, 2, hall_length * 0.4)
	architecture.add_child(judgment_throne)
	
	# Throne base
	var throne_base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(8, 3, 6)
	throne_base.mesh = base_mesh
	throne_base.position = Vector3(0, 1.5, 0)
	judgment_throne.add_child(throne_base)
	
	# Throne material - dark marble with gold inlay
	var throne_material = StandardMaterial3D.new()
	throne_material.albedo_color = Color(0.2, 0.2, 0.25, 1.0)
	throne_material.emission_enabled = true
	throne_material.emission = royal_gold * 0.3
	throne_material.metallic = 0.6
	throne_material.roughness = 0.1
	throne_base.material_override = throne_material
	
	# Throne back (high Egyptian throne style)
	var throne_back = MeshInstance3D.new()
	var back_mesh = BoxMesh.new()
	back_mesh.size = Vector3(8, 8, 1)
	throne_back.mesh = back_mesh
	throne_back.position = Vector3(0, 4, -2.5)
	judgment_throne.add_child(throne_back)
	throne_back.material_override = throne_material
	
	# Add ankh symbols and divine imagery
	create_throne_decorations()

func create_throne_decorations():
	# Egyptian symbols around the throne
	var symbol_positions = [
		Vector3(-3, 5, -2),   # Left ankh
		Vector3(3, 5, -2),    # Right ankh
		Vector3(0, 7, -2)     # Central was scepter
	]
	
	for i in range(symbol_positions.size()):
		create_divine_symbol(symbol_positions[i], i)

func create_divine_symbol(position: Vector3, symbol_type: int):
	var symbol = MeshInstance3D.new()
	symbol.name = "DivineSymbol_" + str(symbol_type)
	judgment_throne.add_child(symbol)
	
	match symbol_type:
		0, 1:  # Ankh symbols
			var ankh_mesh = CylinderMesh.new()
			ankh_mesh.radius_top = 0.3
			ankh_mesh.radius_bottom = 0.3
			ankh_mesh.height = 2.0
			symbol.mesh = ankh_mesh
		2:     # Was scepter
			var scepter_mesh = CylinderMesh.new()
			scepter_mesh.radius_top = 0.2
			scepter_mesh.radius_bottom = 0.2
			scepter_mesh.height = 3.0
			symbol.mesh = scepter_mesh
	
	symbol.position = position
	
	# Divine symbol material
	var symbol_material = StandardMaterial3D.new()
	symbol_material.albedo_color = royal_gold
	symbol_material.emission_enabled = true
	symbol_material.emission = royal_gold * 0.8
	symbol_material.metallic = 1.0
	symbol_material.roughness = 0.0
	symbol.material_override = symbol_material

func create_divine_lighting():
	# Main divine light from above
	var divine_light = DirectionalLight3D.new()
	divine_light.name = "DivineJudgmentLight"
	divine_light.position = Vector3(0, 20, 0)
	divine_light.rotation_degrees = Vector3(-90, 0, 0)
	divine_light.light_energy = 1.5
	divine_light.light_color = royal_gold
	divine_lighting.add_child(divine_light)
	
	# Column accent lights
	for i in range(massive_columns.size()):
		var column_light = SpotLight3D.new()
		column_light.position = massive_columns[i].position + Vector3(0, 2, 0)
		column_light.rotation_degrees = Vector3(-45, 0, 0)
		column_light.light_energy = 0.8
		column_light.light_color = emerald_green
		column_light.spot_range = 12.0
		column_light.spot_angle = 30.0
		divine_lighting.add_child(column_light)
	
	# Throne spotlight (Ammit's domain)
	var throne_light = SpotLight3D.new()
	throne_light.position = judgment_throne.position + Vector3(0, 15, 0)
	throne_light.rotation_degrees = Vector3(-90, 0, 0)
	throne_light.light_energy = 2.5
	throne_light.light_color = Color(0.8, 0.2, 0.2, 1.0)  # Ominous red for Ammit
	throne_light.spot_range = 20.0
	throne_light.spot_angle = 45.0
	divine_lighting.add_child(throne_light)

func initialize_moral_systems():
	# Create Scale of Ma'at chambers
	create_maat_scale_chambers()
	
	# Initialize truth dialogue system
	setup_truth_dialogue_system()
	
	# Place Feather of Truth collectibles
	place_feather_collectibles()
	
	# Setup moral choice consequences
	initialize_judgment_consequences()

func create_maat_scale_chambers():
	# Create 7 moral choice chambers along the hall
	for i in range(moral_choice_count):
		var chamber_position = Vector3(
			0,
			1,
			-hall_length * 0.3 + (i * hall_length * 0.8 / (moral_choice_count - 1))
		)
		create_maat_chamber(chamber_position, i)

func create_maat_chamber(position: Vector3, chamber_index: int):
	var chamber = StaticBody3D.new()
	chamber.name = "MaatChamber_" + str(chamber_index)
	chamber.position = position
	moral_chambers.add_child(chamber)
	
	# Chamber platform
	var platform = MeshInstance3D.new()
	var platform_mesh = CylinderMesh.new()
	platform_mesh.radius_top = 4.0
	platform_mesh.radius_bottom = 4.0
	platform_mesh.height = 0.5
	platform.mesh = platform_mesh
	chamber.add_child(platform)
	
	# Platform material - marble with gold inlay
	var platform_material = StandardMaterial3D.new()
	platform_material.albedo_color = marble_white
	platform_material.emission_enabled = true
	platform_material.emission = emerald_green * 0.3
	platform_material.metallic = 0.3
	platform_material.roughness = 0.1
	platform.material_override = platform_material
	
	# Scale of Ma'at centerpiece
	create_scale_of_maat(chamber, chamber_index)
	
	# Interaction area
	var interaction_area = Area3D.new()
	var area_collision = CollisionShape3D.new()
	var area_shape = CylinderShape3D.new()
	area_shape.radius = 5.0
	area_shape.height = 4.0
	area_collision.shape = area_shape
	interaction_area.add_child(area_collision)
	chamber.add_child(interaction_area)
	
	# Store chamber metadata
	chamber.set_meta("chamber_index", chamber_index)
	chamber.set_meta("moral_choice_type", get_chamber_choice_type(chamber_index))
	chamber.add_to_group("maat_chambers")
	
	# Connect interaction
	interaction_area.body_entered.connect(_on_maat_chamber_entered.bind(chamber))
	
	maat_chambers.append(chamber)

func create_scale_of_maat(parent_chamber: StaticBody3D, chamber_index: int):
	var scale = Node3D.new()
	scale.name = "ScaleOfMaat"
	parent_chamber.add_child(scale)
	scale.position = Vector3(0, 2, 0)
	
	# Scale base (pedestal)
	var base = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.radius_top = 0.8
	base_mesh.radius_bottom = 1.0
	base_mesh.height = 2.0
	base.mesh = base_mesh
	scale.add_child(base)
	
	# Scale beam (horizontal)
	var beam = MeshInstance3D.new()
	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(4.0, 0.2, 0.2)
	beam.mesh = beam_mesh
	beam.position = Vector3(0, 1.2, 0)
	scale.add_child(beam)
	
	# Left scale plate (Truth)
	var left_plate = create_scale_plate(Vector3(-1.8, 1.0, 0), "truth")
	scale.add_child(left_plate)
	
	# Right scale plate (Lies/Deception)
	var right_plate = create_scale_plate(Vector3(1.8, 1.0, 0), "lies")
	scale.add_child(right_plate)
	
	# Scale materials - divine gold
	var scale_material = StandardMaterial3D.new()
	scale_material.albedo_color = royal_gold
	scale_material.emission_enabled = true
	scale_material.emission = royal_gold * 0.6
	scale_material.metallic = 0.9
	scale_material.roughness = 0.1
	
	base.material_override = scale_material
	beam.material_override = scale_material

func create_scale_plate(position: Vector3, plate_type: String) -> MeshInstance3D:
	var plate = MeshInstance3D.new()
	plate.name = "ScalePlate_" + plate_type
	
	var plate_mesh = CylinderMesh.new()
	plate_mesh.radius_top = 0.8
	plate_mesh.radius_bottom = 0.8
	plate_mesh.height = 0.1
	plate.mesh = plate_mesh
	plate.position = position
	
	# Plate material based on type
	var plate_material = StandardMaterial3D.new()
	if plate_type == "truth":
		plate_material.albedo_color = emerald_green
		plate_material.emission = emerald_green * 0.5
	else:  # lies
		plate_material.albedo_color = Color(0.6, 0.2, 0.8, 1.0)  # Dark purple
		plate_material.emission = Color(0.6, 0.2, 0.8, 1.0) * 0.5
	
	plate_material.emission_enabled = true
	plate_material.metallic = 0.7
	plate_material.roughness = 0.2
	plate.material_override = plate_material
	
	return plate

func get_chamber_choice_type(chamber_index: int) -> String:
	# Different moral choice types for variety
	var choice_types = [
		"mercy_vs_justice",      # 0: Spare enemy vs Execute
		"truth_vs_protection",   # 1: Tell truth vs Protect feelings
		"personal_vs_greater",   # 2: Personal gain vs Greater good
		"tradition_vs_progress", # 3: Old ways vs New ways
		"risk_vs_safety",        # 4: Bold action vs Safe choice
		"individual_vs_group",   # 5: Help one vs Help many
		"present_vs_future"      # 6: Immediate benefit vs Future investment
	]
	
	return choice_types[chamber_index % choice_types.size()]

func setup_truth_dialogue_system():
	# Create truth dialogue NPCs throughout the hall
	var npc_positions = [
		Vector3(-15, 1, -30),  # Truth Scholar
		Vector3(15, 1, 0),     # Divine Oracle
		Vector3(0, 1, 30)      # Ma'at Priestess
	]
	
	var npc_names = ["Truth Scholar Thoth", "Divine Oracle Seshat", "Ma'at Priestess Isfet"]
	var npc_roles = ["truth_seeker", "divine_oracle", "judgment_priestess"]
	
	for i in range(npc_positions.size()):
		create_truth_dialogue_npc(npc_positions[i], npc_names[i], npc_roles[i])

func create_truth_dialogue_npc(position: Vector3, npc_name: String, npc_role: String):
	var npc = StaticBody3D.new()
	npc.name = npc_name.replace(" ", "")
	npc.position = position
	environment.add_child(npc)
	
	# NPC visual representation (Egyptian figure)
	var npc_mesh = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.8
	mesh.height = 2.5
	npc_mesh.mesh = mesh
	npc_mesh.position = Vector3(0, 1.25, 0)
	npc.add_child(npc_mesh)
	
	# NPC material - divine beings
	var npc_material = StandardMaterial3D.new()
	match npc_role:
		"truth_seeker":
			npc_material.albedo_color = emerald_green
			npc_material.emission = emerald_green * 0.4
		"divine_oracle":
			npc_material.albedo_color = royal_gold
			npc_material.emission = royal_gold * 0.4
		"judgment_priestess":
			npc_material.albedo_color = marble_white
			npc_material.emission = Color(0.8, 0.8, 1.0, 1.0) * 0.3
	
	npc_material.emission_enabled = true
	npc_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	npc_material.albedo_color.a = 0.8  # Semi-transparent divine beings
	npc_mesh.material_override = npc_material
	
	# Interaction area
	var interaction_area = Area3D.new()
	var area_collision = CollisionShape3D.new()
	var area_shape = SphereShape3D.new()
	area_shape.radius = 3.0
	area_collision.shape = area_shape
	interaction_area.add_child(area_collision)
	npc.add_child(interaction_area)
	
	# Store NPC metadata
	npc.set_meta("npc_name", npc_name)
	npc.set_meta("npc_role", npc_role)
	npc.add_to_group("truth_dialogue_npcs")
	
	# Connect interaction
	interaction_area.body_entered.connect(_on_truth_npc_approached.bind(npc))

func place_feather_collectibles():
	# Place 12 Feathers of Truth throughout the hall
	var feather_positions = []
	
	# Hidden around columns
	for i in range(6):
		var column_pos = massive_columns[i % massive_columns.size()].position
		feather_positions.append(column_pos + Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3)))
	
	# Near moral choice chambers
	for i in range(6):
		var chamber_pos = maat_chambers[i % maat_chambers.size()].position
		feather_positions.append(chamber_pos + Vector3(randf_range(-6, 6), 2, randf_range(-2, 2)))
	
	for i in range(feather_positions.size()):
		create_feather_of_truth(feather_positions[i], i)

func create_feather_of_truth(position: Vector3, feather_id: int):
	var feather = Area3D.new()
	feather.name = "FeatherOfTruth_" + str(feather_id)
	feather.position = position
	environment.add_child(feather)
	
	# Feather visual (ethereal floating feather)
	var feather_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()  # Simplified feather shape
	mesh.size = Vector3(0.3, 0.1, 1.2)
	feather_mesh.mesh = mesh
	feather.add_child(feather_mesh)
	
	# Feather material - Ma'at's white feather with divine glow
	var feather_material = StandardMaterial3D.new()
	feather_material.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	feather_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	feather_material.emission_enabled = true
	feather_material.emission = Color(1.0, 1.0, 1.0, 1.0)
	feather_material.grow_amount = 0.1  # Soft glow
	feather_mesh.material_override = feather_material
	
	# Gentle floating animation
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(feather, "position:y", position.y + 0.3, 2.0)
	float_tween.tween_property(feather, "position:y", position.y - 0.3, 2.0)
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, 1.0)
	collision.shape = shape
	feather.add_child(collision)
	
	# Collection signal
	feather.body_entered.connect(_on_feather_collected.bind(feather, feather_id))
	
	feather.add_to_group("feathers_of_truth")

func initialize_judgment_consequences():
	# Define how moral choices affect the environment and gameplay
	judgment_consequences = {
		"truth_alignment": {
			"environment_change": "golden_glow_increase",
			"enemy_behavior": "truth_seekers_allied",
			"boss_dialogue": "ammit_respects_honesty",
			"stat_bonus": {"wisdom": 2, "divine_favor": 3}
		},
		"lie_alignment": {
			"environment_change": "shadows_darken",
			"enemy_behavior": "judgment_guards_hostile",
			"boss_dialogue": "ammit_sees_deception",  
			"stat_bonus": {"cunning": 2, "stealth": 3}
		},
		"neutral_alignment": {
			"environment_change": "balance_maintained",
			"enemy_behavior": "normal_encounters",
			"boss_dialogue": "ammit_tests_resolve",
			"stat_bonus": {"balance": 2, "adaptability": 3}
		}
	}

# Moral choice mechanics
func trigger_moral_choice(chamber_index: int):
	var chamber = maat_chambers[chamber_index]
	var choice_type = chamber.get_meta("moral_choice_type")
	
	# Show moral choice UI
	show_moral_choice_ui(choice_type, chamber_index)
	
	print("Moral choice presented: ", choice_type, " at chamber ", chamber_index)

func show_moral_choice_ui(choice_type: String, chamber_index: int):
	# Create moral choice dialogue
	var choice_data = get_moral_choice_data(choice_type)
	
	# This would integrate with actual UI system
	print("MORAL CHOICE: ", choice_data.title)
	print("Choice A (Truth): ", choice_data.option_truth)
	print("Choice B (Lies): ", choice_data.option_lies)
	
	# For now, simulate choice (in actual game, player would choose)
	# make_moral_choice(choice_type, true, chamber_index)  # Choose truth

func get_moral_choice_data(choice_type: String) -> Dictionary:
	var choice_database = {
		"mercy_vs_justice": {
			"title": "A defeated enemy pleads for mercy before Ma'at's scale",
			"option_truth": "Show mercy - all deserve a chance at redemption",
			"option_lies": "Execute them - justice demands punishment",
			"consequences": "Mercy grants wisdom, Justice grants strength"
		},
		"truth_vs_protection": {
			"title": "A spirit asks about their mortal life's failures",
			"option_truth": "Tell the harsh truth about their mistakes",
			"option_lies": "Comfort them with gentle lies",
			"consequences": "Truth brings enlightenment, Protection brings loyalty"
		},
		"personal_vs_greater": {
			"title": "Ancient treasure vs helping trapped souls",
			"option_truth": "Help the souls escape their eternal prison",
			"option_lies": "Take the treasure for personal power",
			"consequences": "Greater good grants divine favor, Personal gain grants material power"
		}
		# ... more choice types
	}
	
	return choice_database.get(choice_type, {
		"title": "Unknown choice",
		"option_truth": "Choose truth",
		"option_lies": "Choose deception",
		"consequences": "Unknown effects"
	})

func make_moral_choice(choice_type: String, chose_truth: bool, chamber_index: int):
	# Record the choice
	moral_choices_made[chamber_index] = {
		"type": choice_type,
		"choice": "truth" if chose_truth else "lies",
		"timestamp": Time.get_time_dict_from_system()
	}
	
	# Update scores
	if chose_truth:
		truth_score += 1
	else:
		lie_score += 1
	
	# Update moral alignment
	update_moral_alignment()
	
	# Apply immediate consequences
	apply_choice_consequences(choice_type, chose_truth, chamber_index)
	
	# Visual feedback
	animate_scale_response(chamber_index, chose_truth)
	
	moral_choice_made.emit(choice_type, chose_truth)

func update_moral_alignment():
	if truth_score > lie_score + 2:
		player_moral_alignment = "truth"
	elif lie_score > truth_score + 2:
		player_moral_alignment = "lies"
	else:
		player_moral_alignment = "neutral"
	
	# Apply environmental changes based on alignment
	apply_moral_environmental_changes()

func apply_choice_consequences(choice_type: String, chose_truth: bool, chamber_index: int):
	# Stat bonuses/penalties
	if player:
		match choice_type:
			"mercy_vs_justice":
				if chose_truth:  # Mercy
					boost_player_stat("wisdom", 1)
				else:  # Justice
					boost_player_stat("strength", 1)
			"truth_vs_protection":
				if chose_truth:  # Harsh truth
					boost_player_stat("divine_favor", 2)
				else:  # Gentle lies
					boost_player_stat("social_bond", 1)
	
	# Environmental changes
	var chamber = maat_chambers[chamber_index]
	if chose_truth:
		enhance_chamber_truth_glow(chamber)
	else:
		darken_chamber_with_shadows(chamber)

func boost_player_stat(stat_name: String, amount: int):
	if player and player.has_method("modify_stat"):
		player.modify_stat(stat_name, amount)
		print("Player ", stat_name, " increased by ", amount)

func enhance_chamber_truth_glow(chamber: Node3D):
	# Add golden glow to chamber
	var glow_light = OmniLight3D.new()
	glow_light.name = "TruthGlow"
	glow_light.position = Vector3(0, 3, 0)
	glow_light.light_energy = 1.5
	glow_light.light_color = royal_gold
	glow_light.omni_range = 8.0
	chamber.add_child(glow_light)

func darken_chamber_with_shadows(chamber: Node3D):
	# Add shadow/purple glow to chamber
	var shadow_light = OmniLight3D.new()
	shadow_light.name = "ShadowGlow"
	shadow_light.position = Vector3(0, 3, 0)
	shadow_light.light_energy = 0.8
	shadow_light.light_color = Color(0.6, 0.2, 0.8, 1.0)
	shadow_light.omni_range = 8.0
	chamber.add_child(shadow_light)

func animate_scale_response(chamber_index: int, chose_truth: bool):
	var chamber = maat_chambers[chamber_index]
	var scale = chamber.get_node("ScaleOfMaat")
	
	# Animate scale tilting based on choice
	var tilt_direction = -15.0 if chose_truth else 15.0  # Truth tilts left, lies tilt right
	
	var scale_tween = create_tween()
	scale_tween.tween_property(scale, "rotation_degrees:z", tilt_direction, 1.0)
	scale_tween.tween_property(scale, "rotation_degrees:z", 0.0, 1.0)  # Return to balance

func apply_moral_environmental_changes():
	match player_moral_alignment:
		"truth":
			# Golden glow increases throughout hall
			if divine_lighting.get_node("DivineJudgmentLight"):
				divine_lighting.get_node("DivineJudgmentLight").light_energy = 2.0
				divine_lighting.get_node("DivineJudgmentLight").light_color = royal_gold * 1.2
		"lies":
			# Shadows deepen, purple overtones
			if divine_lighting.get_node("DivineJudgmentLight"):
				divine_lighting.get_node("DivineJudgmentLight").light_energy = 1.0
				divine_lighting.get_node("DivineJudgmentLight").light_color = Color(0.7, 0.4, 0.8, 1.0)
		"neutral":
			# Balanced lighting maintained
			pass

# Truth dialogue battle system
func start_truth_dialogue_battle(npc_name: String):
	truth_dialogue_started.emit(npc_name)
	
	# Show truth vs lie dialogue options
	print("Truth Dialogue Battle with ", npc_name, " begins!")
	
	# This would integrate with dialogue system
	# show_dialogue_battle_ui(npc_name)

# Signal handlers
func _on_maat_chamber_entered(chamber: StaticBody3D, body: Node3D):
	if body != player:
		return
	
	var chamber_index = chamber.get_meta("chamber_index")
	if chamber_index in moral_choices_made:
		return  # Already made choice here
	
	current_chamber_index = chamber_index
	trigger_moral_choice(chamber_index)

func _on_truth_npc_approached(npc: StaticBody3D, body: Node3D):
	if body != player:
		return
	
	var npc_name = npc.get_meta("npc_name")
	start_truth_dialogue_battle(npc_name)

func _on_feather_collected(feather: Area3D, feather_id: int, body: Node3D):
	if body != player:
		return
	
	feathers_collected += 1
	feather_collected.emit(feathers_collected)
	
	# Visual collection effect
	create_feather_collection_effect(feather.position)
	
	feather.queue_free()
	print("Feather of Truth collected! Total: ", feathers_collected, "/12")

func create_feather_collection_effect(position: Vector3):
	var effect = MeshInstance3D.new()
	get_parent().add_child(effect)
	effect.position = position
	
	var effect_mesh = SphereMesh.new()
	effect_mesh.radius = 1.0
	effect.mesh = effect_mesh
	
	var effect_material = StandardMaterial3D.new()
	effect_material.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	effect_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect_material.emission_enabled = true
	effect_material.emission = Color(1.0, 1.0, 1.0, 1.0)
	effect.material_override = effect_material
	
	# Fade out effect
	var effect_tween = create_tween()
	effect_tween.parallel().tween_property(effect, "scale", Vector3.ZERO, 1.0)
	effect_tween.parallel().tween_property(effect, "modulate:a", 0.0, 1.0)
	effect_tween.tween_callback(effect.queue_free)

# Boss trigger
func trigger_ammit_encounter():
	if feathers_collected >= 8:  # Need most feathers to face Ammit
		ammit_boss_triggered.emit()
		print("Ammit, Soul Devourer, awakens for final judgment!")
		return true
	else:
		print("Collect more Feathers of Truth before facing Ammit. (", feathers_collected, "/12)")
		return false

func complete_judgment_trial():
	# Determine final verdict based on choices
	var final_verdict = determine_final_verdict()
	judgment_complete.emit(final_verdict)
	
	print("Judgment Trial Complete! Final Verdict: ", final_verdict)
	apply_final_judgment_rewards(final_verdict)

func determine_final_verdict() -> String:
	var truth_percentage = float(truth_score) / float(truth_score + lie_score) * 100.0
	
	if truth_percentage >= 70.0:
		return "Pure Heart - Ma'at's Blessing"
	elif truth_percentage >= 40.0:
		return "Balanced Soul - Wisdom's Path"
	else:
		return "Shadowed Heart - Redemption Needed"

func apply_final_judgment_rewards(verdict: String):
	# Apply permanent rewards based on judgment
	match verdict:
		"Pure Heart - Ma'at's Blessing":
			# Best rewards - divine favor, stat bonuses
			if player:
				boost_player_stat("divine_favor", 5)
				boost_player_stat("wisdom", 3)
		"Balanced Soul - Wisdom's Path":
			# Balanced rewards
			if player:
				boost_player_stat("wisdom", 2)
				boost_player_stat("balance", 2)
		"Shadowed Heart - Redemption Needed":
			# Challenge rewards - power through struggle
			if player:
				boost_player_stat("cunning", 3)
				boost_player_stat("resilience", 2)

# Public API
func get_judgment_hall_info() -> Dictionary:
	return {
		"name": "Salão do Julgamento",
		"theme": "Moral Choices and Divine Justice",
		"moral_alignment": player_moral_alignment,
		"truth_score": truth_score,
		"lie_score": lie_score,
		"feathers_collected": feathers_collected,
		"max_feathers": 12,
		"choices_made": moral_choices_made.size(),
		"total_chambers": moral_choice_count,
		"ready_for_ammit": feathers_collected >= 8
	}

func activate_biome():
	is_active = true
	print("Salão do Julgamento activated - Where truth and falsehood face divine justice")

func deactivate_biome():
	is_active = false

func get_current_moral_alignment() -> String:
	return player_moral_alignment

func force_moral_choice(chamber_index: int, chose_truth: bool):
	make_moral_choice(get_chamber_choice_type(chamber_index), chose_truth, chamber_index)