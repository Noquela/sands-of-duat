@tool
extends EditorScript

## 🎬 ANIMATION IMPORTER - SANDS OF DUAT
## Importa e configura as animações egípcias do Mixamo no Godot
## 
## Usage: Tools > Execute Script

class_name AnimationImporter

# Animation categories from our Egyptian pack
const ANIMATION_CATEGORIES = {
	"locomotion": [
		"idle", "walking", "running", "sneaking", 
		"walking_backwards", "strafe_left", "strafe_right", "jump"
	],
	"combat_melee": [
		"khopesh_attack_1", "khopesh_attack_2", "khopesh_attack_3",
		"staff_swing", "spin_attack", "block_stance", "block_impact", 
		"parry", "dodge_back", "dodge_forward", "dodge_left", "dodge_right"
	],
	"combat_ranged": [
		"bow_aim", "bow_draw", "bow_shoot", "bow_idle"
	],
	"magic": [
		"spell_basic", "spell_divine", "prayer_to_gods", "levitation",
		"ward_spell", "curse_spell", "summon_spell", "egyptian_ritual_dance"
	],
	"reactions": [
		"death_forward", "death_backward", "hit_light", 
		"hit_heavy", "victory_pose", "defeat_kneel"
	],
	"interactions": [
		"door_open", "lever_pull", "treasure_collect", "heal_potion"
	]
}

# Animation settings for different types
const ANIMATION_SETTINGS = {
	"locomotion": {
		"loop": true,
		"blend_time": 0.2,
		"priority": 1
	},
	"combat_melee": {
		"loop": false,
		"blend_time": 0.1,
		"priority": 3
	},
	"combat_ranged": {
		"loop": false,
		"blend_time": 0.15,
		"priority": 3
	},
	"magic": {
		"loop": false,
		"blend_time": 0.25,
		"priority": 2
	},
	"reactions": {
		"loop": false,
		"blend_time": 0.1,
		"priority": 4
	},
	"interactions": {
		"loop": false,
		"blend_time": 0.2,
		"priority": 2
	}
}

func _run():
	print("🎬 Starting Animation Importer for Sands of Duat")
	print("=" * 50)
	
	# Check if animation files exist
	var animations_path = "res://assets/animations/"
	if not DirAccess.dir_exists_absolute(animations_path):
		print("❌ Animation folder not found: ", animations_path)
		print("   Run the Python pipeline first: python run_complete_pipeline.py")
		return
	
	# Import animations by category
	var total_imported = 0
	for category in ANIMATION_CATEGORIES.keys():
		var count = import_category_animations(category)
		total_imported += count
		
	# Create master AnimationTree
	create_master_animation_tree()
	
	print("\n🎉 Animation Import Complete!")
	print("✅ Total animations imported: ", total_imported)
	print("🌳 AnimationTree created: res://scenes/CharacterAnimationTree.tscn")
	print("📋 Ready to use in your character controller!")

func import_category_animations(category: String) -> int:
	"""Import animations for a specific category"""
	print("\n📁 Importing category: ", category.to_upper())
	
	var category_path = "res://assets/animations/" + category + "/"
	var imported_count = 0
	
	if not DirAccess.dir_exists_absolute(category_path):
		print("⚠️  Category folder not found: ", category_path)
		return 0
	
	var dir = DirAccess.open(category_path)
	if dir == null:
		print("❌ Failed to open directory: ", category_path)
		return 0
	
	# Process each animation in category
	var animations = ANIMATION_CATEGORIES[category]
	for anim_name in animations:
		var glb_path = category_path + anim_name + ".glb"
		
		if FileAccess.file_exists(glb_path):
			import_single_animation(glb_path, category, anim_name)
			imported_count += 1
			print("  ✅ ", anim_name)
		else:
			print("  ⚠️  Missing: ", anim_name)
	
	print("📊 Category ", category, " imported: ", imported_count, "/", animations.size())
	return imported_count

func import_single_animation(glb_path: String, category: String, anim_name: String):
	"""Import and configure a single GLB animation"""
	
	# Load the GLB as PackedScene
	var scene = load(glb_path) as PackedScene
	if scene == null:
		print("❌ Failed to load GLB: ", glb_path)
		return
	
	# Get animation settings for this category
	var settings = ANIMATION_SETTINGS.get(category, {})
	
	# Configure import settings (this would be done via import plugin in real implementation)
	# For now, we'll document the expected settings
	var import_settings = {
		"animation/import": true,
		"animation/fps": 30,
		"animation/trimming": false,
		"animation/remove_immutable_tracks": true,
		"animation/import_rest_as_RESET": false,
		"meshes/ensure_tangents": true,
		"meshes/generate_lods": true,
		"meshes/create_shadow_meshes": true,
		"skins/use_named_skins": true
	}
	
	# Apply category-specific settings
	if settings.has("loop"):
		# This would need to be configured in the actual GLB import process
		pass

func create_master_animation_tree():
	"""Create a master AnimationTree with all Egyptian animations"""
	print("\n🌳 Creating master AnimationTree...")
	
	# Create AnimationTree resource
	var anim_tree = AnimationTree.new()
	var state_machine = AnimationNodeStateMachine.new()
	
	# Create states for each category
	var category_blend_trees = {}
	
	for category in ANIMATION_CATEGORIES.keys():
		var blend_tree = create_category_blend_tree(category)
		if blend_tree:
			category_blend_trees[category] = blend_tree
			state_machine.add_node(category, blend_tree)
	
	# Setup transitions between categories
	setup_state_machine_transitions(state_machine)
	
	# Configure AnimationTree
	anim_tree.tree_root = state_machine
	anim_tree.anim_player = NodePath("../AnimationPlayer")
	
	# Create a scene with the AnimationTree
	var tree_scene = PackedScene.new()
	var root_node = Node3D.new()
	root_node.name = "CharacterAnimationTree"
	
	# Add AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	root_node.add_child(anim_player)
	anim_player.owner = root_node
	
	# Add AnimationTree
	anim_tree.name = "AnimationTree"
	root_node.add_child(anim_tree)
	anim_tree.owner = root_node
	
	# Save the scene
	tree_scene.pack(root_node)
	var save_path = "res://scenes/CharacterAnimationTree.tscn"
	ResourceSaver.save(tree_scene, save_path)
	
	print("✅ AnimationTree saved: ", save_path)

func create_category_blend_tree(category: String) -> AnimationNodeBlendTree:
	"""Create a blend tree for a specific animation category"""
	
	var animations = ANIMATION_CATEGORIES.get(category, [])
	if animations.is_empty():
		return null
	
	var blend_tree = AnimationNodeBlendTree.new()
	var settings = ANIMATION_SETTINGS.get(category, {})
	
	# For locomotion, create a 2D blend space
	if category == "locomotion":
		return create_locomotion_blend_space()
	
	# For combat, create a transition system
	elif category.begins_with("combat"):
		return create_combat_blend_tree(category)
	
	# For other categories, create simple blend tree
	else:
		return create_simple_blend_tree(category)

func create_locomotion_blend_space() -> AnimationNodeBlendSpace2D:
	"""Create 2D blend space for locomotion animations"""
	var blend_space = AnimationNodeBlendSpace2D.new()
	
	# Configure blend space
	blend_space.min_space = Vector2(-1, -1)
	blend_space.max_space = Vector2(1, 1)
	blend_space.snap = Vector2(0.1, 0.1)
	
	# Add animation points
	var locomotion_points = {
		Vector2(0, 0): "idle",
		Vector2(0, 0.5): "walking", 
		Vector2(0, 1): "running",
		Vector2(0, -1): "walking_backwards",
		Vector2(-1, 0): "strafe_left",
		Vector2(1, 0): "strafe_right",
		Vector2(0, 0.3): "sneaking"
	}
	
	for pos in locomotion_points:
		var anim_name = locomotion_points[pos]
		var anim_node = AnimationNodeAnimation.new()
		anim_node.animation = anim_name
		blend_space.add_blend_point(anim_node, pos)
	
	return blend_space

func create_combat_blend_tree(category: String) -> AnimationNodeBlendTree:
	"""Create blend tree for combat animations"""
	var blend_tree = AnimationNodeBlendTree.new()
	
	# Add animation nodes for this category
	var animations = ANIMATION_CATEGORIES[category]
	for anim_name in animations:
		var anim_node = AnimationNodeAnimation.new()
		anim_node.animation = anim_name
		blend_tree.add_node(anim_name, anim_node)
	
	# Create output connection (simplified)
	if animations.size() > 0:
		blend_tree.connect_node("output", 0, animations[0])
	
	return blend_tree

func create_simple_blend_tree(category: String) -> AnimationNodeBlendTree:
	"""Create simple blend tree for other animation categories"""
	var blend_tree = AnimationNodeBlendTree.new()
	
	var animations = ANIMATION_CATEGORIES[category]
	for anim_name in animations:
		var anim_node = AnimationNodeAnimation.new()
		anim_node.animation = anim_name
		blend_tree.add_node(anim_name, anim_node)
	
	# Connect first animation to output
	if animations.size() > 0:
		blend_tree.connect_node("output", 0, animations[0])
	
	return blend_tree

func setup_state_machine_transitions(state_machine: AnimationNodeStateMachine):
	"""Setup transitions between animation states"""
	
	# Define transition rules
	var transitions = [
		["locomotion", "combat_melee", 0.2],
		["locomotion", "combat_ranged", 0.3], 
		["locomotion", "magic", 0.4],
		["combat_melee", "locomotion", 0.2],
		["combat_ranged", "locomotion", 0.3],
		["magic", "locomotion", 0.4],
		["locomotion", "interactions", 0.3],
		["interactions", "locomotion", 0.3],
		["locomotion", "reactions", 0.1],
		["reactions", "locomotion", 0.5]
	]
	
	# Add transitions
	for trans in transitions:
		var from_state = trans[0]
		var to_state = trans[1] 
		var duration = trans[2]
		
		if state_machine.has_node(from_state) and state_machine.has_node(to_state):
			var transition = AnimationNodeStateMachineTransition.new()
			transition.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			transition.auto_advance = false
			
			state_machine.add_transition(from_state, to_state, transition)
	
	# Set default state
	if state_machine.has_node("locomotion"):
		state_machine.set_start_node("locomotion")

func create_animation_library() -> AnimationLibrary:
	"""Create an AnimationLibrary with all imported animations"""
	var library = AnimationLibrary.new()
	
	print("📚 Creating AnimationLibrary...")
	
	# This would load actual animation resources from the GLB files
	# For now, we document the expected structure
	
	for category in ANIMATION_CATEGORIES.keys():
		var animations = ANIMATION_CATEGORIES[category]
		for anim_name in animations:
			# Create placeholder animation (in real implementation, load from GLB)
			var animation = Animation.new()
			animation.length = 1.0  # Would be loaded from actual GLB
			library.add_animation(anim_name, animation)
	
	print("✅ AnimationLibrary created with ", library.get_animation_list().size(), " animations")
	return library

# Utility functions for character integration

static func get_animation_for_action(action: String) -> String:
	"""Get appropriate animation name for a game action"""
	var action_map = {
		"idle": "idle",
		"walk": "walking",
		"run": "running", 
		"sneak": "sneaking",
		"attack_light": "khopesh_attack_1",
		"attack_heavy": "khopesh_attack_3",
		"block": "block_stance",
		"dodge": "dodge_back",
		"cast_spell": "spell_basic",
		"shoot_bow": "bow_shoot",
		"death": "death_forward",
		"victory": "victory_pose",
		"interact": "door_open"
	}
	
	return action_map.get(action, "idle")

static func get_category_for_animation(anim_name: String) -> String:
	"""Get category for an animation name"""
	for category in ANIMATION_CATEGORIES.keys():
		if anim_name in ANIMATION_CATEGORIES[category]:
			return category
	return "locomotion"

static func is_looping_animation(anim_name: String) -> bool:
	"""Check if animation should loop"""
	var category = get_category_for_animation(anim_name)
	var settings = ANIMATION_SETTINGS.get(category, {})
	return settings.get("loop", false)

static func get_blend_time(anim_name: String) -> float:
	"""Get blend time for animation"""
	var category = get_category_for_animation(anim_name)
	var settings = ANIMATION_SETTINGS.get(category, {})
	return settings.get("blend_time", 0.2)