class_name StatusEffects
extends Node

## 🌟 STATUS EFFECTS SYSTEM - SANDS OF DUAT
## Sistema avançado de status effects com temas egípcios e resistências
##
## Features:
## - Egyptian-themed status effects (burn, freeze, poison, slow, divine blessing)
## - Visual feedback específico por efeito
## - Sistema de resistência e imunidade
## - Cleansing abilities com poderes divinos
## - Stacking effects e interactions

signal status_effect_applied(effect_name: String, duration: float, stacks: int)
signal status_effect_removed(effect_name: String, reason: String)
signal status_effect_expired(effect_name: String)
signal cleansing_performed(effects_removed: Array)
signal immunity_granted(effect_type: String, duration: float)

@export var tick_interval: float = 1.0  # Status effects update interval
@export var max_effect_stacks: int = 10  # Maximum stacks per effect
@export var enable_visual_feedback: bool = true
@export var enable_cultural_effects: bool = true

# Egyptian status effect types
enum EgyptianStatusType {
	# Damage over time
	BURN_OF_RA,          # Solar fire damage
	POISON_OF_SERPENT,   # Apep's venom
	CURSE_OF_SET,        # Chaos god's curse
	
	# Debuffs
	SAND_SLOW,           # Desert sand hindrance
	BLINDNESS_OF_STORM,  # Sandstorm blindness
	WEAKNESS_OF_TOMB,    # Ancient tomb weakness
	FEAR_OF_UNDERWORLD,  # Duat terror
	
	# Control effects
	FROZEN_IN_TIME,      # Temporal freeze
	STUNNED_BY_DIVINE,   # Divine authority stun
	CHARMED_BY_ISIS,     # Isis enchantment
	
	# Buffs (positive effects)
	BLESSING_OF_MAAT,    # Justice blessing
	PROTECTION_OF_BASTET, # Cat goddess protection
	WISDOM_OF_THOTH,     # Increased magic
	STRENGTH_OF_KHNUM,   # Enhanced crafting/combat
	
	# Special effects
	MARKED_FOR_DEATH,    # Anubis death mark
	DIVINE_FAVOR,        # Gods' blessing
	PHARAOH_AUTHORITY,   # Royal command aura
	REGENERATION_ANKH    # Life force restoration
}

# Status effect data structure
class StatusEffect:
	var effect_type: EgyptianStatusType
	var effect_name: String
	var remaining_duration: float
	var tick_damage: float = 0.0
	var stat_modifiers: Dictionary = {}
	var visual_effect: String = ""
	var audio_cue: String = ""
	var stacks: int = 1
	var max_stacks: int = 1
	var is_beneficial: bool = false
	var dispellable: bool = true
	var cultural_description: String = ""
	var immunity_after_removal: float = 0.0
	
	func _init(type: EgyptianStatusType, name: String, duration: float):
		effect_type = type
		effect_name = name
		remaining_duration = duration

# Active status effects
var active_effects: Dictionary = {}  # effect_type -> StatusEffect
var immunities: Dictionary = {}      # effect_type -> remaining_immunity_time
var resistances: Dictionary = {}     # effect_type -> resistance_percentage (0.0-1.0)

# Visual and audio systems
var status_vfx: StatusVisualEffects
var status_audio: StatusAudioSystem

# Effect tick timer
var tick_timer: Timer

func _ready():
	print("🌟 StatusEffects system initialized")
	setup_status_system()
	create_egyptian_status_effects()
	setup_default_resistances()

func setup_status_system():
	"""Inicializa sistema de status effects"""
	
	# Setup tick timer
	tick_timer = Timer.new()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_status_tick)
	tick_timer.autostart = true
	add_child(tick_timer)
	
	# Setup visual effects
	status_vfx = StatusVisualEffects.new()
	status_vfx.name = "StatusVisualEffects"
	add_child(status_vfx)
	
	# Setup audio system
	status_audio = StatusAudioSystem.new()
	status_audio.name = "StatusAudioSystem" 
	add_child(status_audio)
	
	print("✅ Status effects system setup complete")

func create_egyptian_status_effects():
	"""Cria definições dos status effects egípcios"""
	
	# This method defines the templates for each status effect
	# The actual effects are created when applied
	print("✅ Egyptian status effect templates loaded")

func setup_default_resistances():
	"""Configura resistências padrão"""
	
	# Example resistances (could be loaded from character data)
	resistances[EgyptianStatusType.BURN_OF_RA] = 0.1      # 10% fire resistance
	resistances[EgyptianStatusType.POISON_OF_SERPENT] = 0.0 # No poison resistance
	resistances[EgyptianStatusType.FROZEN_IN_TIME] = 0.3   # 30% freeze resistance
	
	print("✅ Default resistances configured")

func apply_status_effect(effect_type: EgyptianStatusType, duration: float, caster: Node = null, potency: float = 1.0) -> bool:
	"""Aplica status effect"""
	
	# Check immunity
	if immunities.has(effect_type) and immunities[effect_type] > 0:
		print("🛡️ Immune to ", EgyptianStatusType.keys()[effect_type])
		return false
	
	# Apply resistance
	var effective_duration = duration
	if resistances.has(effect_type):
		effective_duration *= (1.0 - resistances[effect_type])
	
	if effective_duration <= 0:
		return false
	
	# Create or update effect
	var effect = create_status_effect(effect_type, effective_duration, potency)
	
	if active_effects.has(effect_type):
		# Stack or refresh existing effect
		handle_existing_effect(effect)
	else:
		# Apply new effect
		active_effects[effect_type] = effect
		apply_effect_modifiers(effect)
	
	# Visual and audio feedback
	if enable_visual_feedback:
		status_vfx.show_status_applied(effect)
		status_audio.play_status_sound(effect)
	
	status_effect_applied.emit(effect.effect_name, effective_duration, effect.stacks)
	
	print("🌟 Applied status: ", effect.effect_name, " (", "%.1f" % effective_duration, "s, ", effect.stacks, " stacks)")
	return true

func create_status_effect(effect_type: EgyptianStatusType, duration: float, potency: float) -> StatusEffect:
	"""Cria instância de status effect"""
	
	match effect_type:
		EgyptianStatusType.BURN_OF_RA:
			return create_burn_of_ra(duration, potency)
		EgyptianStatusType.POISON_OF_SERPENT:
			return create_poison_of_serpent(duration, potency)
		EgyptianStatusType.CURSE_OF_SET:
			return create_curse_of_set(duration, potency)
		EgyptianStatusType.SAND_SLOW:
			return create_sand_slow(duration, potency)
		EgyptianStatusType.BLINDNESS_OF_STORM:
			return create_blindness_of_storm(duration, potency)
		EgyptianStatusType.WEAKNESS_OF_TOMB:
			return create_weakness_of_tomb(duration, potency)
		EgyptianStatusType.FEAR_OF_UNDERWORLD:
			return create_fear_of_underworld(duration, potency)
		EgyptianStatusType.FROZEN_IN_TIME:
			return create_frozen_in_time(duration, potency)
		EgyptianStatusType.STUNNED_BY_DIVINE:
			return create_stunned_by_divine(duration, potency)
		EgyptianStatusType.CHARMED_BY_ISIS:
			return create_charmed_by_isis(duration, potency)
		EgyptianStatusType.BLESSING_OF_MAAT:
			return create_blessing_of_maat(duration, potency)
		EgyptianStatusType.PROTECTION_OF_BASTET:
			return create_protection_of_bastet(duration, potency)
		EgyptianStatusType.WISDOM_OF_THOTH:
			return create_wisdom_of_thoth(duration, potency)
		EgyptianStatusType.STRENGTH_OF_KHNUM:
			return create_strength_of_khnum(duration, potency)
		EgyptianStatusType.MARKED_FOR_DEATH:
			return create_marked_for_death(duration, potency)
		EgyptianStatusType.DIVINE_FAVOR:
			return create_divine_favor(duration, potency)
		EgyptianStatusType.PHARAOH_AUTHORITY:
			return create_pharaoh_authority(duration, potency)
		EgyptianStatusType.REGENERATION_ANKH:
			return create_regeneration_ankh(duration, potency)
		_:
			return create_generic_status_effect(effect_type, duration, potency)

# Status effect creation methods

func create_burn_of_ra(duration: float, potency: float) -> StatusEffect:
	"""Cria efeito de queimadura solar de Ra"""
	var effect = StatusEffect.new(EgyptianStatusType.BURN_OF_RA, "Burn of Ra", duration)
	effect.tick_damage = 20.0 * potency
	effect.visual_effect = "solar_flames"
	effect.audio_cue = "fire_crackling"
	effect.max_stacks = 5
	effect.cultural_description = "The scorching flames of Ra burn through flesh and soul"
	return effect

func create_poison_of_serpent(duration: float, potency: float) -> StatusEffect:
	"""Cria efeito de veneno da serpente Apep"""
	var effect = StatusEffect.new(EgyptianStatusType.POISON_OF_SERPENT, "Poison of Serpent", duration)
	effect.tick_damage = 15.0 * potency
	effect.stat_modifiers["speed_multiplier"] = 0.8  # 20% speed reduction
	effect.visual_effect = "green_poison_mist"
	effect.audio_cue = "serpent_hiss"
	effect.max_stacks = 3
	effect.cultural_description = "Apep's venom courses through the veins, weakening body and spirit"
	return effect

func create_curse_of_set(duration: float, potency: float) -> StatusEffect:
	"""Cria maldição do caos de Set"""
	var effect = StatusEffect.new(EgyptianStatusType.CURSE_OF_SET, "Curse of Set", duration)
	effect.tick_damage = 10.0 * potency
	effect.stat_modifiers["damage_multiplier"] = 0.7  # 30% damage reduction
	effect.stat_modifiers["accuracy_multiplier"] = 0.8  # 20% accuracy reduction
	effect.visual_effect = "chaotic_red_aura"
	effect.audio_cue = "dark_whispers"
	effect.max_stacks = 1
	effect.dispellable = false  # Set's curse is hard to remove
	effect.cultural_description = "Set's chaotic power disrupts order and weakens resolve"
	return effect

func create_sand_slow(duration: float, potency: float) -> StatusEffect:
	"""Cria lentidão da areia do deserto"""
	var effect = StatusEffect.new(EgyptianStatusType.SAND_SLOW, "Sand Slow", duration)
	effect.stat_modifiers["speed_multiplier"] = 0.5 * (1.0 - potency * 0.3)
	effect.visual_effect = "swirling_sand"
	effect.audio_cue = "sand_shifting"
	effect.max_stacks = 3
	effect.cultural_description = "Desert sands cling to the body, hindering movement"
	return effect

func create_blindness_of_storm(duration: float, potency: float) -> StatusEffect:
	"""Cria cegueira da tempestade de areia"""
	var effect = StatusEffect.new(EgyptianStatusType.BLINDNESS_OF_STORM, "Blindness of Storm", duration)
	effect.stat_modifiers["accuracy_multiplier"] = 0.2  # 80% accuracy reduction
	effect.stat_modifiers["vision_range"] = 0.3  # 70% vision reduction
	effect.visual_effect = "sand_blindness"
	effect.audio_cue = "howling_wind"
	effect.max_stacks = 1
	effect.cultural_description = "Sandstorm blinds the eyes like the fury of the desert"
	return effect

func create_weakness_of_tomb(duration: float, potency: float) -> StatusEffect:
	"""Cria fraqueza da tumba antiga"""
	var effect = StatusEffect.new(EgyptianStatusType.WEAKNESS_OF_TOMB, "Weakness of Tomb", duration)
	effect.stat_modifiers["damage_multiplier"] = 0.6  # 40% damage reduction
	effect.stat_modifiers["defense_multiplier"] = 0.7  # 30% defense reduction
	effect.visual_effect = "ancient_curse_aura"
	effect.audio_cue = "tomb_echoes"
	effect.max_stacks = 2
	effect.cultural_description = "Ancient tomb energy saps strength from the living"
	return effect

func create_fear_of_underworld(duration: float, potency: float) -> StatusEffect:
	"""Cria medo do submundo"""
	var effect = StatusEffect.new(EgyptianStatusType.FEAR_OF_UNDERWORLD, "Fear of Underworld", duration)
	effect.stat_modifiers["damage_multiplier"] = 0.8  # 20% damage reduction
	effect.stat_modifiers["move_control"] = false  # Can't control movement properly
	effect.visual_effect = "fear_darkness"
	effect.audio_cue = "underworld_whispers"
	effect.max_stacks = 1
	effect.cultural_description = "The terror of Duat overwhelms the mind"
	return effect

func create_frozen_in_time(duration: float, potency: float) -> StatusEffect:
	"""Cria congelamento temporal"""
	var effect = StatusEffect.new(EgyptianStatusType.FROZEN_IN_TIME, "Frozen in Time", duration)
	effect.stat_modifiers["speed_multiplier"] = 0.0  # Complete immobility
	effect.stat_modifiers["action_disabled"] = true
	effect.visual_effect = "temporal_freeze"
	effect.audio_cue = "time_stop"
	effect.max_stacks = 1
	effect.cultural_description = "Time itself stops around the victim"
	return effect

func create_stunned_by_divine(duration: float, potency: float) -> StatusEffect:
	"""Cria atordoamento divino"""
	var effect = StatusEffect.new(EgyptianStatusType.STUNNED_BY_DIVINE, "Stunned by Divine", duration)
	effect.stat_modifiers["action_disabled"] = true
	effect.stat_modifiers["movement_disabled"] = true
	effect.visual_effect = "divine_light_stun"
	effect.audio_cue = "divine_thunder"
	effect.max_stacks = 1
	effect.cultural_description = "Divine authority renders the target powerless"
	return effect

func create_charmed_by_isis(duration: float, potency: float) -> StatusEffect:
	"""Cria encantamento de Isis"""
	var effect = StatusEffect.new(EgyptianStatusType.CHARMED_BY_ISIS, "Charmed by Isis", duration)
	effect.stat_modifiers["ally_target"] = true  # Target fights for allies
	effect.visual_effect = "golden_charm_aura"
	effect.audio_cue = "isis_blessing"
	effect.max_stacks = 1
	effect.cultural_description = "Isis' magic turns enemy into temporary ally"
	return effect

func create_blessing_of_maat(duration: float, potency: float) -> StatusEffect:
	"""Cria bênção da justiça de Maat"""
	var effect = StatusEffect.new(EgyptianStatusType.BLESSING_OF_MAAT, "Blessing of Maat", duration)
	effect.stat_modifiers["damage_multiplier"] = 1.3 + (potency * 0.2)
	effect.stat_modifiers["accuracy_multiplier"] = 1.2
	effect.visual_effect = "feather_justice_aura"
	effect.audio_cue = "maat_blessing"
	effect.is_beneficial = true
	effect.max_stacks = 3
	effect.cultural_description = "Maat's justice empowers righteous actions"
	return effect

func create_protection_of_bastet(duration: float, potency: float) -> StatusEffect:
	"""Cria proteção de Bastet"""
	var effect = StatusEffect.new(EgyptianStatusType.PROTECTION_OF_BASTET, "Protection of Bastet", duration)
	effect.stat_modifiers["defense_multiplier"] = 1.5 + (potency * 0.3)
	effect.stat_modifiers["speed_multiplier"] = 1.2  # Cat-like agility
	effect.visual_effect = "cat_goddess_aura"
	effect.audio_cue = "bastet_purr"
	effect.is_beneficial = true
	effect.max_stacks = 2
	effect.cultural_description = "Bastet's protection grants feline grace and defense"
	return effect

func create_wisdom_of_thoth(duration: float, potency: float) -> StatusEffect:
	"""Cria sabedoria de Thoth"""
	var effect = StatusEffect.new(EgyptianStatusType.WISDOM_OF_THOTH, "Wisdom of Thoth", duration)
	effect.stat_modifiers["magic_damage_multiplier"] = 1.4 + (potency * 0.3)
	effect.stat_modifiers["mana_regeneration"] = 1.5
	effect.visual_effect = "wisdom_glyph_aura"
	effect.audio_cue = "thoth_wisdom"
	effect.is_beneficial = true
	effect.max_stacks = 2
	effect.cultural_description = "Thoth's wisdom enhances magical abilities"
	return effect

func create_strength_of_khnum(duration: float, potency: float) -> StatusEffect:
	"""Cria força de Khnum"""
	var effect = StatusEffect.new(EgyptianStatusType.STRENGTH_OF_KHNUM, "Strength of Khnum", duration)
	effect.stat_modifiers["damage_multiplier"] = 1.5 + (potency * 0.4)
	effect.stat_modifiers["knockback_resistance"] = 0.8
	effect.visual_effect = "crafted_strength_aura"
	effect.audio_cue = "khnum_hammer"
	effect.is_beneficial = true
	effect.max_stacks = 2
	effect.cultural_description = "Khnum's craftsmanship strengthens body and weapons"
	return effect

func create_marked_for_death(duration: float, potency: float) -> StatusEffect:
	"""Cria marca da morte de Anubis"""
	var effect = StatusEffect.new(EgyptianStatusType.MARKED_FOR_DEATH, "Marked for Death", duration)
	effect.stat_modifiers["incoming_damage_multiplier"] = 1.5 + (potency * 0.3)
	effect.stat_modifiers["healing_effectiveness"] = 0.5  # 50% healing reduction
	effect.visual_effect = "death_mark_symbol"
	effect.audio_cue = "anubis_judgment"
	effect.max_stacks = 1
	effect.dispellable = false
	effect.cultural_description = "Anubis has marked this soul for judgment"
	return effect

func create_divine_favor(duration: float, potency: float) -> StatusEffect:
	"""Cria favor divino"""
	var effect = StatusEffect.new(EgyptianStatusType.DIVINE_FAVOR, "Divine Favor", duration)
	effect.stat_modifiers["all_stats_multiplier"] = 1.2 + (potency * 0.1)
	effect.stat_modifiers["critical_chance"] = 0.25
	effect.visual_effect = "divine_golden_aura"
	effect.audio_cue = "divine_blessing"
	effect.is_beneficial = true
	effect.max_stacks = 1
	effect.cultural_description = "The gods smile upon this mortal"
	return effect

func create_pharaoh_authority(duration: float, potency: float) -> StatusEffect:
	"""Cria autoridade do faraó"""
	var effect = StatusEffect.new(EgyptianStatusType.PHARAOH_AUTHORITY, "Pharaoh Authority", duration)
	effect.stat_modifiers["command_aura"] = true  # Affects nearby allies
	effect.stat_modifiers["damage_multiplier"] = 1.3
	effect.stat_modifiers["fear_immunity"] = true
	effect.visual_effect = "royal_authority_aura"
	effect.audio_cue = "pharaoh_decree"
	effect.is_beneficial = true
	effect.max_stacks = 1
	effect.cultural_description = "Royal blood flows with divine authority"
	return effect

func create_regeneration_ankh(duration: float, potency: float) -> StatusEffect:
	"""Cria regeneração do ankh"""
	var effect = StatusEffect.new(EgyptianStatusType.REGENERATION_ANKH, "Regeneration Ankh", duration)
	effect.tick_damage = -25.0 * potency  # Negative damage = healing
	effect.visual_effect = "ankh_life_glow"
	effect.audio_cue = "life_restoration"
	effect.is_beneficial = true
	effect.max_stacks = 3
	effect.cultural_description = "The ankh's power restores life force continuously"
	return effect

func create_generic_status_effect(effect_type: EgyptianStatusType, duration: float, potency: float) -> StatusEffect:
	"""Cria status effect genérico"""
	var name = EgyptianStatusType.keys()[effect_type].replace("_", " ").capitalize()
	var effect = StatusEffect.new(effect_type, name, duration)
	effect.cultural_description = "A mysterious Egyptian force affects the target"
	return effect

func handle_existing_effect(new_effect: StatusEffect):
	"""Gerencia efeito já existente"""
	
	var existing = active_effects[new_effect.effect_type]
	
	if existing.max_stacks > 1:
		# Stack the effect
		existing.stacks = min(existing.stacks + 1, existing.max_stacks)
		existing.remaining_duration = max(existing.remaining_duration, new_effect.remaining_duration)
		
		# Update modifiers for stacking
		update_stacking_modifiers(existing)
		
		print("📈 Stacked effect: ", existing.effect_name, " (", existing.stacks, " stacks)")
	else:
		# Refresh duration
		existing.remaining_duration = max(existing.remaining_duration, new_effect.remaining_duration)
		print("🔄 Refreshed effect: ", existing.effect_name)

func update_stacking_modifiers(effect: StatusEffect):
	"""Atualiza modificadores para efeitos empilháveis"""
	
	# Remove old modifiers
	remove_effect_modifiers(effect, false)
	
	# Apply new modifiers with stack multipliers
	for modifier_key in effect.stat_modifiers.keys():
		var base_value = effect.stat_modifiers[modifier_key]
		var stacked_value = calculate_stacked_modifier(base_value, effect.stacks)
		apply_stat_modifier(modifier_key, stacked_value)

func calculate_stacked_modifier(base_value: Variant, stacks: int) -> Variant:
	"""Calcula valor do modificador empilhável"""
	
	if base_value is float:
		# Multiplicative stacking for multipliers
		if base_value > 1.0:
			return 1.0 + ((base_value - 1.0) * stacks)
		elif base_value < 1.0:
			return max(0.1, base_value * stacks)  # Don't go below 10%
		else:
			return base_value
	else:
		return base_value

func apply_effect_modifiers(effect: StatusEffect):
	"""Aplica modificadores do efeito"""
	
	for modifier_key in effect.stat_modifiers.keys():
		var modifier_value = effect.stat_modifiers[modifier_key]
		apply_stat_modifier(modifier_key, modifier_value)

func remove_effect_modifiers(effect: StatusEffect, full_removal: bool = true):
	"""Remove modificadores do efeito"""
	
	for modifier_key in effect.stat_modifiers.keys():
		if full_removal:
			remove_stat_modifier(modifier_key)

func apply_stat_modifier(modifier_key: String, value: Variant):
	"""Aplica modificador de estatística"""
	
	var target = get_parent()
	if not target:
		return
	
	match modifier_key:
		"speed_multiplier":
			if target.has_method("set_speed_multiplier"):
				target.set_speed_multiplier(value)
		"damage_multiplier":
			if target.has_method("set_damage_multiplier"):
				target.set_damage_multiplier(value)
		"defense_multiplier":
			if target.has_method("set_defense_multiplier"):
				target.set_defense_multiplier(value)
		"accuracy_multiplier":
			if target.has_method("set_accuracy_multiplier"):
				target.set_accuracy_multiplier(value)
		"action_disabled":
			if target.has_method("set_action_disabled"):
				target.set_action_disabled(value)
		"movement_disabled":
			if target.has_method("set_movement_disabled"):
				target.set_movement_disabled(value)
		"all_stats_multiplier":
			apply_all_stats_multiplier(value)

func remove_stat_modifier(modifier_key: String):
	"""Remove modificador de estatística"""
	
	var target = get_parent()
	if not target:
		return
	
	match modifier_key:
		"speed_multiplier":
			if target.has_method("reset_speed_multiplier"):
				target.reset_speed_multiplier()
		"damage_multiplier":
			if target.has_method("reset_damage_multiplier"):
				target.reset_damage_multiplier()
		"defense_multiplier":
			if target.has_method("reset_defense_multiplier"):
				target.reset_defense_multiplier()
		"accuracy_multiplier":
			if target.has_method("reset_accuracy_multiplier"):
				target.reset_accuracy_multiplier()
		"action_disabled":
			if target.has_method("set_action_disabled"):
				target.set_action_disabled(false)
		"movement_disabled":
			if target.has_method("set_movement_disabled"):
				target.set_movement_disabled(false)

func apply_all_stats_multiplier(multiplier: float):
	"""Aplica multiplicador a todas as estatísticas"""
	
	apply_stat_modifier("speed_multiplier", multiplier)
	apply_stat_modifier("damage_multiplier", multiplier)
	apply_stat_modifier("defense_multiplier", multiplier)

func _on_status_tick():
	"""Callback para tick dos status effects"""
	
	var effects_to_remove = []
	
	# Process all active effects
	for effect_type in active_effects.keys():
		var effect = active_effects[effect_type]
		
		# Apply tick damage/healing
		if effect.tick_damage != 0:
			apply_tick_damage(effect)
		
		# Reduce duration
		effect.remaining_duration -= tick_interval
		
		# Check if expired
		if effect.remaining_duration <= 0:
			effects_to_remove.append(effect_type)
	
	# Remove expired effects
	for effect_type in effects_to_remove:
		remove_status_effect(effect_type, "expired")
	
	# Update immunities
	update_immunities()

func apply_tick_damage(effect: StatusEffect):
	"""Aplica dano/cura por tick"""
	
	var target = get_parent()
	if not target:
		return
	
	var tick_amount = effect.tick_damage * effect.stacks
	
	if tick_amount > 0:  # Damage
		if target.has_method("take_damage"):
			target.take_damage(tick_amount, "status_effect")
			print("💀 Status damage: ", "%.1f" % tick_amount, " from ", effect.effect_name)
	else:  # Healing
		if target.has_method("heal"):
			target.heal(abs(tick_amount))
			print("💚 Status healing: ", "%.1f" % abs(tick_amount), " from ", effect.effect_name)

func update_immunities():
	"""Atualiza imunidades temporárias"""
	
	var immunities_to_remove = []
	
	for effect_type in immunities.keys():
		immunities[effect_type] -= tick_interval
		
		if immunities[effect_type] <= 0:
			immunities_to_remove.append(effect_type)
	
	for effect_type in immunities_to_remove:
		immunities.erase(effect_type)

func remove_status_effect(effect_type: EgyptianStatusType, reason: String = "manual") -> bool:
	"""Remove status effect"""
	
	if not active_effects.has(effect_type):
		return false
	
	var effect = active_effects[effect_type]
	
	# Check if dispellable
	if reason == "cleanse" and not effect.dispellable:
		print("🛡️ Cannot cleanse ", effect.effect_name, " - not dispellable")
		return false
	
	print("🚫 Removing status: ", effect.effect_name, " (", reason, ")")
	
	# Remove modifiers
	remove_effect_modifiers(effect)
	
	# Grant temporary immunity if specified
	if effect.immunity_after_removal > 0:
		grant_immunity(effect_type, effect.immunity_after_removal)
	
	# Visual feedback
	if enable_visual_feedback:
		status_vfx.show_status_removed(effect)
	
	# Remove from active effects
	active_effects.erase(effect_type)
	
	# Emit signals
	if reason == "expired":
		status_effect_expired.emit(effect.effect_name)
	else:
		status_effect_removed.emit(effect.effect_name, reason)
	
	return true

func cleanse_status_effects(effect_types: Array = [], cleanse_all: bool = false) -> Array:
	"""Limpa status effects específicos ou todos"""
	
	var effects_removed = []
	
	if cleanse_all:
		# Remove all dispellable debuffs
		for effect_type in active_effects.keys():
			var effect = active_effects[effect_type]
			if effect.dispellable and not effect.is_beneficial:
				if remove_status_effect(effect_type, "cleanse"):
					effects_removed.append(effect.effect_name)
	else:
		# Remove specific effects
		for effect_type in effect_types:
			if remove_status_effect(effect_type, "cleanse"):
				var effect_name = active_effects[effect_type].effect_name if active_effects.has(effect_type) else EgyptianStatusType.keys()[effect_type]
				effects_removed.append(effect_name)
	
	if effects_removed.size() > 0:
		print("✨ Cleansed effects: ", effects_removed)
		cleansing_performed.emit(effects_removed)
		
		# Divine cleansing sound
		status_audio.play_cleansing_sound()
	
	return effects_removed

func grant_immunity(effect_type: EgyptianStatusType, duration: float):
	"""Concede imunidade temporária"""
	
	immunities[effect_type] = duration
	
	var effect_name = EgyptianStatusType.keys()[effect_type]
	print("🛡️ Immunity granted: ", effect_name, " (", "%.1f" % duration, "s)")
	
	immunity_granted.emit(effect_name, duration)

func has_status_effect(effect_type: EgyptianStatusType) -> bool:
	"""Verifica se tem status effect específico"""
	
	return active_effects.has(effect_type)

func get_status_effect_stacks(effect_type: EgyptianStatusType) -> int:
	"""Retorna número de stacks do efeito"""
	
	if active_effects.has(effect_type):
		return active_effects[effect_type].stacks
	
	return 0

func get_status_effect_remaining_duration(effect_type: EgyptianStatusType) -> float:
	"""Retorna duração restante do efeito"""
	
	if active_effects.has(effect_type):
		return active_effects[effect_type].remaining_duration
	
	return 0.0

# Egyptian cleansing abilities

func divine_cleansing():
	"""Limpeza divina - remove todos os debuffs"""
	
	print("✨ DIVINE CLEANSING activated!")
	cleanse_status_effects([], true)
	
	# Grant temporary immunity to all negative effects
	for effect_type in EgyptianStatusType.values():
		var template_effect = create_status_effect(effect_type, 1.0, 1.0)
		if not template_effect.is_beneficial:
			grant_immunity(effect_type, 5.0)

func maat_purification():
	"""Purificação de Maat - remove efeitos injustos"""
	
	var injust_effects = [
		EgyptianStatusType.CURSE_OF_SET,
		EgyptianStatusType.MARKED_FOR_DEATH,
		EgyptianStatusType.FEAR_OF_UNDERWORLD
	]
	
	cleanse_status_effects(injust_effects)
	
	# Apply justice blessing
	apply_status_effect(EgyptianStatusType.BLESSING_OF_MAAT, 10.0, null, 1.5)

func bastet_protection_cleanse():
	"""Limpeza protetiva de Bastet"""
	
	var protective_cleanse = [
		EgyptianStatusType.POISON_OF_SERPENT,
		EgyptianStatusType.WEAKNESS_OF_TOMB,
		EgyptianStatusType.BLINDNESS_OF_STORM
	]
	
	cleanse_status_effects(protective_cleanse)
	
	# Apply protection
	apply_status_effect(EgyptianStatusType.PROTECTION_OF_BASTET, 8.0, null, 1.0)

# Visual Effects System
class StatusVisualEffects extends Node2D:
	"""Sistema de efeitos visuais para status"""
	
	func show_status_applied(effect: StatusEffect):
		print("✨ VFX: Applied ", effect.effect_name, " - ", effect.visual_effect)
	
	func show_status_removed(effect: StatusEffect):
		print("🚫 VFX: Removed ", effect.effect_name)

# Audio System
class StatusAudioSystem extends AudioStreamPlayer2D:
	"""Sistema de áudio para status effects"""
	
	func play_status_sound(effect: StatusEffect):
		print("🔊 Audio: ", effect.effect_name, " - ", effect.audio_cue)
	
	func play_cleansing_sound():
		print("🔊 Audio: Divine cleansing sound")

# Public interface

func get_active_status_effects() -> Dictionary:
	"""Retorna status effects ativos"""
	
	var active_list = {}
	for effect_type in active_effects.keys():
		var effect = active_effects[effect_type]
		active_list[effect.effect_name] = {
			"duration": effect.remaining_duration,
			"stacks": effect.stacks,
			"is_beneficial": effect.is_beneficial
		}
	
	return active_list

func get_immunity_list() -> Array:
	"""Retorna lista de imunidades ativas"""
	
	var immunity_list = []
	for effect_type in immunities.keys():
		var effect_name = EgyptianStatusType.keys()[effect_type]
		immunity_list.append({
			"effect": effect_name,
			"remaining": immunities[effect_type]
		})
	
	return immunity_list

func set_resistance(effect_type: EgyptianStatusType, resistance_percent: float):
	"""Define resistência a status effect"""
	
	resistances[effect_type] = clamp(resistance_percent, 0.0, 1.0)

# Debug functions

func debug_apply_all_effects():
	"""Debug: aplica todos os status effects"""
	
	for effect_type in EgyptianStatusType.values():
		apply_status_effect(effect_type, 10.0, null, 1.0)
		await get_tree().create_timer(0.5).timeout

func debug_show_active_effects():
	"""Debug: mostra efeitos ativos"""
	
	print("\n🌟 ACTIVE STATUS EFFECTS")
	print("========================")
	
	if active_effects.is_empty():
		print("No active effects")
		return
	
	for effect_type in active_effects.keys():
		var effect = active_effects[effect_type]
		print(effect.effect_name, ":")
		print("  Duration: ", "%.1f" % effect.remaining_duration, "s")
		print("  Stacks: ", effect.stacks)
		print("  Beneficial: ", effect.is_beneficial)
		print("  Description: ", effect.cultural_description)

func debug_test_cleansing():
	"""Debug: testa sistema de limpeza"""
	
	# Apply some debuffs
	apply_status_effect(EgyptianStatusType.POISON_OF_SERPENT, 10.0)
	apply_status_effect(EgyptianStatusType.CURSE_OF_SET, 15.0)
	apply_status_effect(EgyptianStatusType.WEAKNESS_OF_TOMB, 8.0)
	
	await get_tree().create_timer(2.0).timeout
	
	# Test cleansing
	divine_cleansing()