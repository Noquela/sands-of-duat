extends Node
class_name RewardSystem

signal reward_selected(reward_data: Dictionary)
signal reward_selection_closed

enum RewardType {
	BOON,           # Bênçãos dos deuses
	ANKH_FRAGMENTS, # Moeda da run (Obols)
	HEART_PIECES,   # +25 HP permanente (Centaur Hearts)
	POWER_FRAGMENTS,# Upgrade boons existentes (Pom of Power)
	DIVINE_HAMMER,  # Modificações de arma (Daedalus Hammer)
	CHAOS_TOKENS,   # Meta-progressão (Darkness/Gems)
	SOUL_ESSENCE    # Para keepsakes (Nectar)
}

# Egyptian-themed reward names and descriptions
var reward_data = {
	RewardType.ANKH_FRAGMENTS: {
		"name": "Ankh Fragments",
		"description": "Ancient currency of the Duat",
		"icon": "res://art/icons/ankh_fragments.png",
		"color": Color.GOLD,
		"amounts": [25, 50, 100, 150]  # Random amounts
	},
	RewardType.HEART_PIECES: {
		"name": "Heart Pieces", 
		"description": "Fragments of vital essence (+25 HP)",
		"icon": "res://art/icons/heart_piece.png",
		"color": Color.CRIMSON,
		"amounts": [25]  # Always +25 HP
	},
	RewardType.POWER_FRAGMENTS: {
		"name": "Power Fragments",
		"description": "Enhance existing boons (+1 level)",
		"icon": "res://art/icons/power_fragment.png", 
		"color": Color.PURPLE,
		"amounts": [1, 2]  # 1-2 levels
	},
	RewardType.DIVINE_HAMMER: {
		"name": "Divine Hammer",
		"description": "Modify weapon with divine power",
		"icon": "res://art/icons/divine_hammer.png",
		"color": Color.ORANGE,
		"amounts": [1]  # One weapon mod
	},
	RewardType.CHAOS_TOKENS: {
		"name": "Chaos Tokens",
		"description": "Fragments of Set's chaotic power",
		"icon": "res://art/icons/chaos_token.png",
		"color": Color.DARK_GRAY,
		"amounts": [10, 15, 20, 30]
	},
	RewardType.SOUL_ESSENCE: {
		"name": "Soul Essence",
		"description": "Pure essence for divine keepsakes",
		"icon": "res://art/icons/soul_essence.png",
		"color": Color.CYAN,
		"amounts": [1, 2]
	}
}

# Room system reference
var room_system: RoomSystem
var player: Node3D

func _ready():
	add_to_group("reward_system")
	room_system = get_tree().get_first_node_in_group("room_system") 
	player = get_tree().get_first_node_in_group("player")

# Generate reward for a room transition
func generate_room_reward() -> Dictionary:
	var current_room_id = 0
	if room_system and room_system.current_room.has("id"):
		current_room_id = room_system.current_room.id
	
	# Hades-like probability system
	var boon_chance = get_boon_chance(current_room_id)
	
	if randf() < boon_chance:
		# Trigger boon encounter
		return generate_boon_reward()
	else:
		# Generate other reward
		return generate_other_reward(current_room_id)

func get_boon_chance(room_id: int) -> float:
	if room_id <= 2:
		return 0.40  # Early rooms favor boons
	elif room_id >= 6:
		return 0.15  # Late rooms favor resources  
	else:
		return 0.25  # Mid game balanced

func generate_boon_reward() -> Dictionary:
	return {
		"type": RewardType.BOON,
		"name": "Divine Encounter",
		"description": "Meet an Egyptian god",
		"icon": "res://art/icons/boon_encounter.png",
		"color": Color.GOLD
	}

func generate_other_reward(room_id: int) -> Dictionary:
	# Weight rewards based on game progression
	var reward_weights = get_reward_weights(room_id)
	var selected_type = weighted_random_selection(reward_weights)
	
	var reward_info = reward_data[selected_type]
	var amount = reward_info.amounts[randi() % reward_info.amounts.size()]
	
	return {
		"type": selected_type,
		"name": reward_info.name,
		"description": reward_info.description + " (+" + str(amount) + ")",
		"icon": reward_info.icon,
		"color": reward_info.color,
		"amount": amount
	}

func get_reward_weights(room_id: int) -> Dictionary:
	# Early game: favor HP and currency
	if room_id <= 2:
		return {
			RewardType.ANKH_FRAGMENTS: 30,
			RewardType.HEART_PIECES: 25,
			RewardType.POWER_FRAGMENTS: 10,
			RewardType.DIVINE_HAMMER: 5,
			RewardType.CHAOS_TOKENS: 15,
			RewardType.SOUL_ESSENCE: 15
		}
	# Mid game: balanced
	elif room_id <= 5:
		return {
			RewardType.ANKH_FRAGMENTS: 25,
			RewardType.HEART_PIECES: 20,
			RewardType.POWER_FRAGMENTS: 20,
			RewardType.DIVINE_HAMMER: 15,
			RewardType.CHAOS_TOKENS: 10,
			RewardType.SOUL_ESSENCE: 10
		}
	# Late game: favor upgrades and meta-progression
	else:
		return {
			RewardType.ANKH_FRAGMENTS: 15,
			RewardType.HEART_PIECES: 15,
			RewardType.POWER_FRAGMENTS: 25,
			RewardType.DIVINE_HAMMER: 20,
			RewardType.CHAOS_TOKENS: 15,
			RewardType.SOUL_ESSENCE: 10
		}

func weighted_random_selection(weights: Dictionary) -> RewardType:
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for reward_type in weights.keys():
		current_weight += weights[reward_type]
		if random_value < current_weight:
			return reward_type
	
	# Fallback
	return RewardType.ANKH_FRAGMENTS

# Apply reward to player
func apply_reward(reward_data: Dictionary):
	match reward_data.type:
		RewardType.ANKH_FRAGMENTS:
			apply_ankh_fragments(reward_data.amount)
		RewardType.HEART_PIECES:
			apply_heart_pieces(reward_data.amount)
		RewardType.POWER_FRAGMENTS:
			apply_power_fragments(reward_data.amount)
		RewardType.DIVINE_HAMMER:
			apply_divine_hammer()
		RewardType.CHAOS_TOKENS:
			apply_chaos_tokens(reward_data.amount)
		RewardType.SOUL_ESSENCE:
			apply_soul_essence(reward_data.amount)
		RewardType.BOON:
			# Handled by BoonSelectionUI
			pass

func apply_ankh_fragments(amount: int):
	if player:
		if not player.has_meta("ankh_fragments"):
			player.set_meta("ankh_fragments", 0)
		
		var current = player.get_meta("ankh_fragments", 0)
		player.set_meta("ankh_fragments", current + amount)
		print("Gained ", amount, " Ankh Fragments! Total: ", current + amount)

func apply_heart_pieces(amount: int):
	if player and player.has_method("get_child"):
		var health_system = player.get_node("HealthSystem")
		if health_system:
			health_system.max_health += amount
			health_system.current_health += amount  # Also heal
			print("Gained ", amount, " max HP! New max: ", health_system.max_health)

func apply_power_fragments(amount: int):
	# TODO: Upgrade existing boons
	print("Gained ", amount, " Power Fragments! (Boon upgrade system not implemented yet)")

func apply_divine_hammer():
	# TODO: Weapon modification system
	print("Gained Divine Hammer! (Weapon mod system not implemented yet)")

func apply_chaos_tokens(amount: int):
	if player:
		if not player.has_meta("chaos_tokens"):
			player.set_meta("chaos_tokens", 0)
		
		var current = player.get_meta("chaos_tokens", 0)
		player.set_meta("chaos_tokens", current + amount)
		print("Gained ", amount, " Chaos Tokens! Total: ", current + amount)

func apply_soul_essence(amount: int):
	if player:
		if not player.has_meta("soul_essence"):
			player.set_meta("soul_essence", 0)
		
		var current = player.get_meta("soul_essence", 0)
		player.set_meta("soul_essence", current + amount)
		print("Gained ", amount, " Soul Essence! Total: ", current + amount)

# Get current player resources
func get_player_resources() -> Dictionary:
	if not player:
		return {}
	
	return {
		"ankh_fragments": player.get_meta("ankh_fragments", 0),
		"chaos_tokens": player.get_meta("chaos_tokens", 0),
		"soul_essence": player.get_meta("soul_essence", 0)
	}