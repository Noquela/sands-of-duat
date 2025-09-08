# RewardSystem.gd
# Manages all reward types and door previews - Hades-inspired
# Sprint 7: Sistema de Recompensas Completo

extends Node

# Egyptian reward types based on Hades analysis
enum RewardType {
	ANKH_FRAGMENTS,    # Obols equivalent - 15-25 per room
	HEART_PIECES,      # Centaur Hearts - +25 HP permanent
	POWER_FRAGMENTS,   # Pom of Power - Upgrade existing boons
	DIVINE_HAMMER,     # Daedalus Hammer - Weapon modifications
	CHAOS_TOKENS,      # Darkness - Meta-progression currency
	SOUL_ESSENCE,      # Nectar - Relationship building
	BOON_REWARD,       # Divine blessings from gods
	SPECIAL_EVENT      # Chaos gates, hidden chambers
}

# Reward symbols for door previews (Egyptian themed)
var reward_symbols = {
	RewardType.ANKH_FRAGMENTS: "𓋹",     # Ankh symbol
	RewardType.HEART_PIECES: "𓄿",       # Heart hieroglyph
	RewardType.POWER_FRAGMENTS: "⚡",    # Divine power
	RewardType.DIVINE_HAMMER: "🔨",      # Crafting symbol
	RewardType.CHAOS_TOKENS: "🧿",       # Eye of Horus
	RewardType.SOUL_ESSENCE: "💀",       # Soul symbol
	RewardType.BOON_REWARD: "🏺",        # Divine blessing
	RewardType.SPECIAL_EVENT: "🔮"       # Mystery
}

# Reward names in Portuguese for UI
var reward_names = {
	RewardType.ANKH_FRAGMENTS: "Fragmentos de Ankh",
	RewardType.HEART_PIECES: "Coração Divino",
	RewardType.POWER_FRAGMENTS: "Fragmento de Poder",
	RewardType.DIVINE_HAMMER: "Martelo Divino",
	RewardType.CHAOS_TOKENS: "Símbolo do Caos",
	RewardType.SOUL_ESSENCE: "Essência da Alma",
	RewardType.BOON_REWARD: "Bênção Divina",
	RewardType.SPECIAL_EVENT: "Evento Especial"
}

# Probability weights based on Hades analysis
var reward_probabilities = {
	RewardType.BOON_REWARD: 25,        # 25% boon rooms
	RewardType.ANKH_FRAGMENTS: 30,     # 30% currency
	RewardType.HEART_PIECES: 20,       # 20% health upgrades
	RewardType.POWER_FRAGMENTS: 10,    # 10% boon upgrades
	RewardType.DIVINE_HAMMER: 8,       # 8% weapon mods
	RewardType.CHAOS_TOKENS: 5,        # 5% meta currency
	RewardType.SOUL_ESSENCE: 1,        # 1% relationship items
	RewardType.SPECIAL_EVENT: 1        # 1% special events
}

# Current run rewards tracking
var current_run_rewards: Dictionary = {}
var total_rewards_collected: Dictionary = {}

# Anti-frustration system
var consecutive_non_boon_rooms: int = 0
var max_consecutive_non_boon: int = 3

# References
var boon_system: Node
var player: Node

signal reward_collected(reward_type: RewardType, amount: int, data: Dictionary)
signal reward_door_generated(reward_type: RewardType, room_index: int)

func _ready():
	print("🏺 RewardSystem: Initializing Egyptian reward system...")
	
	# Initialize reward tracking
	_initialize_reward_tracking()
	
	# Get system references
	boon_system = get_node("/root/BoonSystem") if get_node_or_null("/root/BoonSystem") else null
	player = get_tree().get_first_node_in_group("player") if get_tree() else null
	
	print("🏺 RewardSystem: Egyptian rewards ready!")

func _initialize_reward_tracking():
	"""Initialize reward counters for new run"""
	for reward_type in RewardType.values():
		current_run_rewards[reward_type] = 0
		if not total_rewards_collected.has(reward_type):
			total_rewards_collected[reward_type] = 0

func generate_room_reward(room_data: Dictionary) -> Dictionary:
	"""Generate reward for a room based on type and balancing"""
	var room_type_raw = room_data.get("type", 0)  # Default to 0 (COMBAT enum)
	var room_difficulty = room_data.get("difficulty", 1.0)
	
	# Convert room type to string if it's an integer (enum value)
	var room_type: String
	if room_type_raw is int:
		# Convert RoomSystem.RoomType enum to string
		match room_type_raw:
			0: room_type = "combat"      # RoomType.COMBAT
			1: room_type = "elite"       # RoomType.ELITE  
			2: room_type = "treasure"    # RoomType.TREASURE
			3: room_type = "boss"        # RoomType.BOSS
			_: room_type = "combat"      # Default fallback
	else:
		room_type = str(room_type_raw)
	
	# Generate reward type based on probabilities and anti-frustration
	var reward_type = _select_reward_type(room_type)
	var reward_data = _generate_reward_data(reward_type, room_difficulty)
	
	print("🏺 RewardSystem: Generated %s for %s room" % [reward_names[reward_type], room_type])
	
	# Emit signal for door preview
	reward_door_generated.emit(reward_type, room_data.get("index", 0))
	
	return {
		"type": reward_type,
		"symbol": reward_symbols[reward_type],
		"name": reward_names[reward_type],
		"description": _get_reward_description(reward_type, reward_data),
		"data": reward_data
	}

func _select_reward_type(room_type: String) -> RewardType:
	"""Select reward type based on probabilities and anti-frustration system"""
	
	# Anti-frustration: Force boon room if too many consecutive non-boons
	if consecutive_non_boon_rooms >= max_consecutive_non_boon:
		consecutive_non_boon_rooms = 0
		return RewardType.BOON_REWARD
	
	# Special room type handling
	match room_type:
		"treasure":
			# Treasure rooms more likely to have valuable rewards
			return _weighted_random_selection({
				RewardType.HEART_PIECES: 40,
				RewardType.DIVINE_HAMMER: 30,
				RewardType.CHAOS_TOKENS: 20,
				RewardType.SOUL_ESSENCE: 10
			})
		"elite":
			# Elite rooms guarantee good rewards
			return _weighted_random_selection({
				RewardType.BOON_REWARD: 50,
				RewardType.HEART_PIECES: 30,
				RewardType.DIVINE_HAMMER: 20
			})
		"boss":
			# Boss always gives major reward
			return RewardType.HEART_PIECES
		_:
			# Normal room - use standard probabilities
			return _weighted_random_selection(reward_probabilities)

func _weighted_random_selection(weights: Dictionary) -> RewardType:
	"""Select reward type using weighted random selection"""
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

func _generate_reward_data(reward_type: RewardType, difficulty: float) -> Dictionary:
	"""Generate specific reward data based on type and difficulty"""
	var data = {}
	
	match reward_type:
		RewardType.ANKH_FRAGMENTS:
			# Scale with difficulty: 15-25 base, +0-10 from difficulty
			var base_amount = randi_range(15, 25)
			var bonus_amount = int(difficulty * randi_range(0, 10))
			data["amount"] = base_amount + bonus_amount
			
		RewardType.HEART_PIECES:
			# Always +25 HP, but difficulty affects if it's a large or small heart
			data["health_bonus"] = 25
			data["is_large"] = difficulty >= 2.0  # Large heart for elite rooms
			
		RewardType.POWER_FRAGMENTS:
			# 1-2 fragments, more likely 2 on higher difficulty
			data["amount"] = 2 if difficulty >= 1.5 and randf() < 0.7 else 1
			
		RewardType.DIVINE_HAMMER:
			# Single hammer, but difficulty affects available modifications
			data["hammer_tier"] = 1 if difficulty < 1.5 else 2
			data["available_mods"] = 3 if difficulty >= 2.0 else 2
			
		RewardType.CHAOS_TOKENS:
			# Meta-progression currency, rare
			data["amount"] = randi_range(3, 8) + int(difficulty * 2)
			
		RewardType.SOUL_ESSENCE:
			# Very rare, always single piece
			data["amount"] = 1
			data["god_affinity"] = ["Ra", "Bastet", "Thoth", "Anubis"].pick_random()
			
		RewardType.BOON_REWARD:
			# Divine blessing - handled by BoonSystem
			data["rarity_boost"] = difficulty >= 2.0  # Elite rooms boost rarity
			
		RewardType.SPECIAL_EVENT:
			# Special events
			data["event_type"] = ["chaos_gate", "hidden_chamber", "shop"].pick_random()
	
	return data

func _get_reward_description(reward_type: RewardType, data: Dictionary) -> String:
	"""Generate user-friendly description of reward"""
	match reward_type:
		RewardType.ANKH_FRAGMENTS:
			return "%d Fragmentos de Ankh" % data.get("amount", 15)
		RewardType.HEART_PIECES:
			var size = "Grande " if data.get("is_large", false) else ""
			return "%sCoração Divino (+%d Vida)" % [size, data.get("health_bonus", 25)]
		RewardType.POWER_FRAGMENTS:
			var count = data.get("amount", 1)
			return "%d Fragmento%s de Poder" % [count, "s" if count > 1 else ""]
		RewardType.DIVINE_HAMMER:
			var tier = data.get("hammer_tier", 1)
			return "Martelo Divino (Tier %d)" % tier
		RewardType.CHAOS_TOKENS:
			return "%d Símbolos do Caos" % data.get("amount", 5)
		RewardType.SOUL_ESSENCE:
			var god = data.get("god_affinity", "Divindade")
			return "Essência de %s" % god
		RewardType.BOON_REWARD:
			var boost = " (Raridade Aumentada)" if data.get("rarity_boost", false) else ""
			return "Bênção Divina%s" % boost
		RewardType.SPECIAL_EVENT:
			var event = data.get("event_type", "especial")
			return "Evento %s" % event.capitalize()
	
	return "Recompensa Misteriosa"

func collect_reward(reward_data: Dictionary):
	"""Process reward collection and apply effects"""
	var reward_type = reward_data.get("type", RewardType.ANKH_FRAGMENTS)
	var data = reward_data.get("data", {})
	
	print("🏺 RewardSystem: Collecting %s" % reward_names[reward_type])
	
	# Update tracking
	current_run_rewards[reward_type] += 1
	total_rewards_collected[reward_type] += 1
	
	# Update consecutive boon tracking
	if reward_type == RewardType.BOON_REWARD:
		consecutive_non_boon_rooms = 0
	else:
		consecutive_non_boon_rooms += 1
	
	# Apply reward effects
	_apply_reward_effects(reward_type, data)
	
	# Emit collection signal
	var amount = data.get("amount", 1)
	reward_collected.emit(reward_type, amount, data)
	
	print("✅ RewardSystem: %s collected successfully!" % reward_names[reward_type])

func _apply_reward_effects(reward_type: RewardType, data: Dictionary):
	"""Apply the actual effects of collecting the reward"""
	match reward_type:
		RewardType.ANKH_FRAGMENTS:
			# Add currency to player
			var amount = data.get("amount", 15)
			if player and player.has_method("add_currency"):
				player.add_currency("ankh_fragments", amount)
			
		RewardType.HEART_PIECES:
			# Increase max health
			var health_bonus = data.get("health_bonus", 25)
			if player and player.has_method("increase_max_health"):
				player.increase_max_health(health_bonus)
			
		RewardType.POWER_FRAGMENTS:
			# Store for boon upgrade use
			var amount = data.get("amount", 1)
			if player and player.has_method("add_currency"):
				player.add_currency("power_fragments", amount)
			
		RewardType.DIVINE_HAMMER:
			# Mark hammer as available for weapon modification
			if player and player.has_method("add_divine_hammer"):
				player.add_divine_hammer(data.get("hammer_tier", 1))
			
		RewardType.CHAOS_TOKENS:
			# Add meta-progression currency
			var amount = data.get("amount", 5)
			if player and player.has_method("add_currency"):
				player.add_currency("chaos_tokens", amount)
			
		RewardType.SOUL_ESSENCE:
			# Add relationship building resource
			var god = data.get("god_affinity", "unknown")
			if player and player.has_method("add_soul_essence"):
				player.add_soul_essence(god, 1)
			
		RewardType.BOON_REWARD:
			# Trigger boon selection
			if boon_system and boon_system.has_method("offer_boon_selection"):
				var rarity_boost = data.get("rarity_boost", false)
				boon_system.offer_boon_selection(rarity_boost)
			
		RewardType.SPECIAL_EVENT:
			# Handle special events
			var event_type = data.get("event_type", "chaos_gate")
			_handle_special_event(event_type)

func _handle_special_event(event_type: String):
	"""Handle special event rewards"""
	match event_type:
		"chaos_gate":
			print("🔮 RewardSystem: Opening Chaos Gate...")
		"hidden_chamber":
			print("🔮 RewardSystem: Revealing Hidden Chamber...")
		"shop":
			print("🔮 RewardSystem: Opening Khnum's Forge...")

# Debug and utility functions
func get_current_run_stats() -> Dictionary:
	"""Get current run reward statistics"""
	return current_run_rewards.duplicate()

func get_total_stats() -> Dictionary:
	"""Get total lifetime reward statistics"""
	return total_rewards_collected.duplicate()

func reset_run_tracking():
	"""Reset tracking for new run"""
	current_run_rewards.clear()
	consecutive_non_boon_rooms = 0
	_initialize_reward_tracking()
	print("🏺 RewardSystem: Run tracking reset")

# Save/load support
func get_save_data() -> Dictionary:
	return {
		"total_rewards": total_rewards_collected,
		"consecutive_non_boon": consecutive_non_boon_rooms
	}

func load_save_data(data: Dictionary):
	total_rewards_collected = data.get("total_rewards", {})
	consecutive_non_boon_rooms = data.get("consecutive_non_boon", 0)
	_initialize_reward_tracking()
	print("🏺 RewardSystem: Save data loaded")