extends Node3D
class_name WeaponSystem

signal weapon_switched(new_weapon: Resource)

var current_weapon: Resource
var combat_system: Node3D

func _ready():
	# Load default weapon - Was Scepter of Ra
	load_weapon("was_scepter")
	# Small delay to ensure parent is ready
	await get_tree().process_frame
	update_weapon_visuals("was_scepter")

func load_weapon(weapon_id: String):
	var weapon_data = load_weapon_data(weapon_id)
	if weapon_data:
		current_weapon = weapon_data
		update_combat_stats()
		weapon_switched.emit(current_weapon)

func load_weapon_data(weapon_id: String) -> Resource:
	match weapon_id:
		"was_scepter":
			var WeaponDataClass = preload("res://data/weapons/WeaponData.gd")
			var weapon = WeaponDataClass.new()
			weapon.name = "Was Scepter of Ra"
			weapon.damage = 25.0
			weapon.attack_range = 3.0
			weapon.attack_speed = 1.0
			weapon.crit_chance = 0.05
			weapon.crit_multiplier = 1.5
			weapon.weapon_type = 0  # STAFF
			return weapon
		"khopesh":
			var KhopeshDataClass = preload("res://data/weapons/KhopeshData.gd")
			return KhopeshDataClass.new()
		"egyptian_bow":
			var EgyptianBowDataClass = preload("res://data/weapons/EgyptianBowData.gd")
			return EgyptianBowDataClass.new()
		_:
			print("Unknown weapon: ", weapon_id)
			return null

func update_combat_stats():
	if not current_weapon or not combat_system:
		return
	
	combat_system.attack_damage = current_weapon.damage
	combat_system.attack_range = current_weapon.attack_range
	combat_system.attack_cooldown = 1.0 / current_weapon.attack_speed

func switch_weapon(weapon_id: String):
	load_weapon(weapon_id)
	update_weapon_visuals(weapon_id)
	print("Switched to: ", current_weapon.name)

func update_weapon_visuals(weapon_id: String):
	var player = get_parent()
	if not player:
		return
	
	var weapon_holder = player.get_node_or_null("WeaponHolder")
	if not weapon_holder:
		print("WeaponHolder not found on player")
		return
	
	# Hide all weapons
	weapon_holder.get_node("WasScepter").visible = false
	weapon_holder.get_node("Khopesh").visible = false
	weapon_holder.get_node("EgyptianBow").visible = false
	
	# Show current weapon
	match weapon_id:
		"was_scepter":
			weapon_holder.get_node("WasScepter").visible = true
		"khopesh":
			weapon_holder.get_node("Khopesh").visible = true
		"egyptian_bow":
			weapon_holder.get_node("EgyptianBow").visible = true

func get_current_weapon() -> Resource:
	return current_weapon