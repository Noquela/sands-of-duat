# Sprints 9-12: CORE MVP Foundation
**FASE 1** | **Objetivo:** Completar sistemas fundamentais antes de expandir conteúdo

---

## 🎯 **OVERVIEW DA FASE 1**

Esta fase completa o **Core MVP** do jogo. Ao final do Sprint 12, você terá um Hades clone completamente jogável com:
- **11 tipos de inimigos** com AI coordenada
- **5 armas egípcias** com aspectos únicos  
- **50+ boons** com synergias e legendaries
- **1 boss fight completo** narrativamente integrado
- **Sistema de meta-progressão** funcional

**Status Atual:** Sprint 8 completo, iniciando Sprint 9

---

# 🚀 **SPRINT 9: ENEMY EXPANSION & AI ENHANCEMENT**
**Duration:** 1 semana | **Priority:** CRITICAL - Precisa de variedade antes de mais sistemas

## **Objetivos:**
Expandir roster de inimigos de 3 para 11 tipos com AI coordenada que força diferentes estratégias do player.

### **🔥 NOVOS TIPOS DE INIMIGOS (8 adições)**

#### **1. Pharaoh Mage (Caster Teleportante)**
```gdscript
# PharaohMage.gd
enemy_stats = {
    "max_hp": 120,
    "movement_speed": 2.5,
    "damage": 35,
    "role": "ranged_caster",
    "ai_archetype": "enforcer"  # Forces tactical thinking
}
```

**Abilities:**
- **Teleport:** 3-4 unit range, 5s cooldown, leaves shadow at old position
- **Magic Projectiles:** 3-shot spread, slight homing, 25 damage each
- **Shield Barrier:** Creates temporary cover for 8s, blocks projectiles
- **Summon Shade:** Spawns weaker enemy when below 50% HP

**AI Pattern:**
```gdscript
func update_ai_state():
    match current_state:
        AIState.DETECT:
            if player_distance < 8.0:
                cast_teleport_away()
                set_state(AIState.ATTACK_PREP)
        
        AIState.ATTACK_PREP:
            if has_line_of_sight() and teleport_cooldown_ready():
                set_state(AIState.CASTING)
            else:
                find_better_position()
        
        AIState.CASTING:
            cast_magic_projectiles()
            start_retreat_timer(3.0)
```

**Counter-play:** Player must close distance quickly or use projectile deflection. Teleport has 0.5s telegraph.

#### **2. Scarab Swarm (Overwhelming Numbers)**
```gdscript
# ScarabSwarm.gd - Spawns 4-6 individual scarabs
scarab_individual = {
    "max_hp": 25,
    "movement_speed": 4.0, 
    "damage": 15,
    "role": "swarm_unit",
    "ai_archetype": "smasher"
}
```

**Swarm Mechanics:**
- **Group Movement:** Move in formation, maintain 1-unit spacing
- **Coordinate Rush:** All swarm members attack simultaneously 
- **Death Burst:** Each scarab explodes for 10 AOE damage on death
- **Regenerative Spawn:** Spawner creates new scarab every 12s

**AI Coordination:**
```gdscript
func swarm_ai_update():
    # Circle player at medium range
    var circle_position = player.position + Vector3.from_angle(assigned_angle) * 4.0
    move_toward(circle_position)
    
    # Coordinate attack on swarm leader signal
    if swarm_leader.attack_signal and distance_to_player < 2.5:
        dash_attack_player()
        other_swarm_members.trigger_simultaneous_attack()
```

**Counter-play:** AOE abilities extremely effective. Environmental hazards can clear entire swarm.

#### **3. Stone Golem (Tank/Area Control)**
```gdscript
enemy_stats = {
    "max_hp": 300,
    "movement_speed": 1.5,
    "damage": 60,
    "armor": 50,  # Yellow health bar
    "role": "tank_controller"
}
```

**Abilities:**
- **Ground Pound:** 6-unit radius AOE, 2s telegraph, 80 damage + stun
- **Rock Throw:** Long-range projectile, arc trajectory, 45 damage
- **Armor Phases:** Immune to damage during certain attack animations
- **Earthquake:** Room-wide ground shake, affects player movement

**Phase System:**
```gdscript
func handle_armor_phases():
    match current_attack:
        AttackType.GROUND_POUND:
            # Vulnerable during wind-up (1.5s)
            armor_active = false
            if attack_progress > 0.75:
                armor_active = true  # Immune during impact
        
        AttackType.ROCK_THROW:
            armor_active = true  # Always armored during ranged
```

#### **4. Shadow Wraith (Mobility/Harassment)**
```gdscript
enemy_stats = {
    "max_hp": 80,
    "movement_speed": 3.5,
    "damage": 30,
    "phase_ability": true
}
```

**Unique Mechanics:**
- **Wall Phasing:** Can move through walls for 2s, 8s cooldown
- **Shadow Dash:** 5-unit instant movement, leaves damage trail
- **Invisibility:** Becomes invisible for 3s when health < 30%
- **Phase Strike:** Attack from inside wall, emerges for hit

**AI Harassment Pattern:**
```gdscript
func wraith_ai():
    if player_can_see_me() and health_percentage > 0.5:
        # Phase through wall to flank
        var wall_position = find_nearest_wall()
        phase_through_wall(wall_position)
        
    elif behind_player():
        # Strike from behind
        shadow_dash_attack()
        phase_away_immediately()
```

#### **5. Cobra Striker (Hit & Run Specialist)**
```gdscript
enemy_stats = {
    "max_hp": 90,
    "movement_speed": 4.5,
    "damage": 40,
    "critical_chance": 0.3,
    "role": "assassin"
}
```

**Abilities:**
- **Lightning Dash:** 8-unit instant dash attack, hard to dodge
- **Poison Spit:** Ranged attack applies poison DOT (10 DPS for 5s)
- **Coil Dodge:** Perfect dodge with counter-attack if player attacks during coil
- **Venom Strike:** Critical hits apply stronger poison + slow

#### **6. Jackal Hunter (Pack Coordination)**
```gdscript
enemy_stats = {
    "max_hp": 100,
    "movement_speed": 3.0,
    "damage": 35,
    "pack_bonus": true  # +25% stats when near other jackals
}
```

**Pack Mechanics:**
- **Howl Buff:** All jackals in range gain +50% damage for 10s
- **Flanking Maneuvers:** Coordinate to attack from opposite sides
- **Alpha Leadership:** One jackal becomes pack leader (+100% HP)
- **Pack Hunt:** Simultaneous dash attacks from multiple angles

**Advanced AI Coordination:**
```gdscript
func jackal_pack_ai():
    var nearby_jackals = get_jackals_in_range(8.0)
    
    if nearby_jackals.size() >= 2:
        # Coordinate flanking attack
        coordinate_flanking_positions()
        wait_for_pack_attack_signal()
    else:
        # Solo jackal - more defensive, waits for pack
        retreat_to_pack_formation()
```

#### **7. Mummy Brute (Heavy Melee)**
```gdscript
enemy_stats = {
    "max_hp": 200,
    "movement_speed": 2.0,
    "damage": 75,
    "regeneration": 5,  # HP per second
    "role": "bruiser"
}
```

**Abilities:**
- **Heavy Swing:** Slow but devastating attack, 1.5s telegraph
- **Grab & Throw:** If player too close, grabs and throws for 50 damage
- **Bandage Regeneration:** Heals 25 HP over 5s when not taking damage
- **Desperate Fury:** +100% attack speed when below 25% HP

#### **8. Sand Tornado (Area Denial)**
```gdscript
enemy_stats = {
    "max_hp": 150,
    "movement_speed": 2.5,  # Variable based on tornado intensity
    "damage": 20,  # Continuous while in tornado
    "role": "area_controller"
}
```

**Environmental Control:**
- **Dust Cloud:** Reduces vision in 4-unit radius
- **Suction Pull:** Draws player toward center (resistable)
- **Debris Throw:** Launches environmental objects at player
- **Tornado Path:** Follows predictable but dangerous movement pattern

### **🧠 AI COORDINATION SYSTEMS**

#### **Attack Token System (Prevents Spam)**
```gdscript
# AIDirector.gd
class_name AIDirector extends Node

var max_attacking_enemies = 2
var attack_tokens = ["token_1", "token_2"] 
var token_holders = {}

func request_attack_token(enemy: BaseEnemy) -> bool:
    for token in attack_tokens:
        if not token_holders.has(token):
            token_holders[token] = enemy
            enemy.attack_token_granted.emit(token)
            return true
    return false

func release_attack_token(token: String):
    if token_holders.has(token):
        token_holders.erase(token)
```

#### **Formation Positioning**
```gdscript
# FormationManager.gd
func maintain_enemy_spacing():
    var all_enemies = get_active_enemies()
    
    for enemy in all_enemies:
        var nearby_enemies = get_enemies_in_range(enemy.position, 3.0)
        if nearby_enemies.size() > 0:
            var repulsion_force = calculate_repulsion(enemy, nearby_enemies)
            enemy.apply_formation_force(repulsion_force)
```

#### **Player Prediction System**
```gdscript
# PredictiveAI.gd
func predict_player_position(prediction_time: float = 0.3) -> Vector3:
    var velocity = player.get_velocity()
    var acceleration = player.get_acceleration()
    
    # Simple prediction with acceleration consideration
    return player.position + (velocity * prediction_time) + (acceleration * prediction_time * prediction_time * 0.5)

func lead_projectile_shot():
    var predicted_pos = predict_player_position(projectile_travel_time)
    fire_projectile_at(predicted_pos)
```

### **🏅 ELITE VARIANTS SYSTEM**

每个敌人类型都有精英版本：

```gdscript
# EliteVariant.gd
func create_elite_variant(base_enemy: BaseEnemy) -> EliteEnemy:
    var elite = base_enemy.duplicate()
    
    # Visual changes
    elite.add_golden_aura_effect()
    elite.scale *= 1.2  # Slightly larger
    
    # Stat increases
    elite.max_hp *= 1.5
    elite.damage *= 1.3
    elite.movement_speed *= 1.1
    
    # Add unique elite ability
    elite.add_elite_ability(get_elite_ability_for_type(base_enemy.enemy_type))
    
    # Better rewards
    elite.reward_multiplier = 2.5
    
    return elite
```

**Elite Abilities by Type:**
- **Elite Pharaoh Mage:** Chain Lightning between teleports
- **Elite Scarab Swarm:** Spawns explosive scarabs on death
- **Elite Stone Golem:** Creates stone barriers during combat
- **Elite Shadow Wraith:** Can phase other enemies through walls
- **Elite Cobra Striker:** Poison spreads to nearby enemies on critical
- **Elite Jackal Hunter:** Howl summons additional jackals
- **Elite Mummy Brute:** Bandages entangle player temporarily
- **Elite Sand Tornado:** Creates multiple smaller tornadoes

### **⚡ PERFORMANCE OPTIMIZATION**

#### **Enemy LOD System**
```gdscript
# EnemyLODManager.gd
func update_enemy_lod():
    for enemy in active_enemies:
        var distance = player.global_position.distance_to(enemy.global_position)
        
        if distance > 15.0:
            # Distant enemies: simplified AI, lower update rate
            enemy.set_ai_update_rate(0.5)  # Update every 0.5s instead of every frame
            enemy.disable_complex_behaviors()
        elif distance > 8.0:
            # Medium distance: standard AI
            enemy.set_ai_update_rate(0.1)  
            enemy.enable_all_behaviors()
        else:
            # Close enemies: full AI complexity
            enemy.set_ai_update_rate(0.016)  # Every frame (60fps)
            enemy.enable_complex_behaviors()
```

#### **Object Pooling**
```gdscript
# EnemyPool.gd
class_name EnemyPool extends Node

var enemy_pools = {}
var max_pool_size = 20

func get_enemy(enemy_type: String) -> BaseEnemy:
    if not enemy_pools.has(enemy_type):
        enemy_pools[enemy_type] = []
    
    var pool = enemy_pools[enemy_type]
    if pool.size() > 0:
        return pool.pop_back()
    else:
        return create_new_enemy(enemy_type)

func return_enemy(enemy: BaseEnemy):
    enemy.reset_for_reuse()
    var pool = enemy_pools[enemy.enemy_type]
    if pool.size() < max_pool_size:
        pool.append(enemy)
    else:
        enemy.queue_free()
```

### **🔗 INTEGRATION REQUIREMENTS**

#### **GameManager Integration**
```gdscript
# In GameManager.gd
func setup_enemy_integration():
    # Connect spawner to manager
    enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
    enemy_spawner.wave_completed.connect(_on_wave_completed)
    enemy_spawner.elite_spawned.connect(_on_elite_spawned)
    
    # Connect AI director
    ai_director.attack_pattern_changed.connect(_on_attack_pattern_changed)
    
    print("✅ Enemy system integrated with main game loop")

func _on_enemy_spawned(enemy: BaseEnemy):
    # Connect individual enemy to GameManager
    enemy.died.connect(_on_enemy_died)
    enemy.player_damaged.connect(_on_player_damaged_by_enemy)
    enemy.elite_ability_used.connect(camera_controller.add_shake.bind(5.0))
```

#### **UI Integration**
```gdscript
# Update enemy counter, elite indicators, etc.
func _on_enemy_spawned(enemy: BaseEnemy):
    ui_hud.update_enemy_counter(get_active_enemy_count())
    if enemy.is_elite:
        ui_hud.show_elite_warning(enemy.position)
```

### **📋 TESTING CHECKLIST**

#### **Individual Enemy Tests:**
- [ ] All 8 new enemy types spawn without errors
- [ ] Each enemy uses their unique abilities effectively
- [ ] Elite variants have distinct behaviors and visual differences
- [ ] AI responds appropriately to player actions

#### **System Integration Tests:**
- [ ] Attack token system prevents overwhelming spam
- [ ] Formation AI maintains proper spacing
- [ ] Player prediction makes enemies challenging but fair
- [ ] Elite spawning respects room difficulty ratings

#### **Performance Tests:**
- [ ] 60 FPS maintained with 8+ enemies active
- [ ] LOD system reduces performance impact appropriately
- [ ] Object pooling prevents memory leaks
- [ ] No AI stuttering or frame drops during complex coordination

#### **Balance Tests:**
- [ ] Each enemy type requires different player tactics
- [ ] No single enemy type dominates difficulty curve
- [ ] Elite enemies feel challenging but not unfair
- [ ] Room variety significantly improved with new enemy types

### **🎯 SUCCESS METRICS**

**Completion Criteria:**
- **8 unique enemy behaviors** successfully implemented
- **AI coordination** prevents attack spam and creates varied encounters
- **Elite system** provides meaningful difficulty scaling
- **Performance targets** maintained (60fps with 8+ enemies)
- **Player strategy diversity** - different enemies require different approaches

**Integration Success:**
- All enemies integrate seamlessly with existing combat system
- Enemy deaths properly trigger GameManager events
- UI updates reflect enemy state changes in real-time
- Save/load system handles new enemy data correctly

---

# ⚔️ **SPRINT 10: WEAPON SYSTEM COMPLETE** 
**Duration:** 1 semana | **Priority:** HIGH - Precisa de todas armas antes de aspectos

## **Objetivos:**
Completar sistema de 5 armas egípcias com movesets únicos, especiais abilities, e sistema de weapon switching fluido.

### **🗡️ IMPLEMENTAÇÃO DAS ARMAS RESTANTES**

#### **Spear of Ra (Range + Solar Power)**
```gdscript
# SpearOfRa.gd
extends BaseWeapon
class_name SpearOfRa

var weapon_data = {
    "name": "Spear of Ra",
    "base_damage": 45,
    "attack_speed": 0.8,
    "range": 6.0,
    "special_cooldown": 8.0,
    "combo_count": 2,
    "weapon_type": "polearm",
    "damage_type": "solar",
    "tags": ["solar", "piercing", "reach", "divine"]
}
```

**Moveset Implementation:**
```gdscript
func perform_light_attack():
    # Forward thrust with extended reach
    var thrust_range = 6.0
    var hit_targets = detect_enemies_in_line(thrust_range)
    
    for target in hit_targets:
        deal_damage(target, weapon_data.base_damage)
        apply_solar_burn(target, 3.0)  # 3 second burn DOT
    
    trigger_animation("thrust_forward")
    create_solar_trail_vfx()

func perform_heavy_attack():
    # Wide sweep hitting multiple enemies
    var sweep_arc = 120.0  # degrees
    var sweep_range = 4.5
    var hit_targets = detect_enemies_in_arc(sweep_range, sweep_arc)
    
    for target in hit_targets:
        deal_damage(target, weapon_data.base_damage * 1.4)
        apply_knockback(target, 3.0)
    
    trigger_animation("wide_sweep")
    create_solar_wave_vfx()
```

**Special Ability: Solar Lance**
```gdscript
func use_special_ability():
    if not can_use_special():
        return
    
    # Charged projectile with piercing
    var charge_time = 1.5  # Hold to charge
    var lance_projectile = create_solar_lance()
    
    lance_projectile.damage = weapon_data.base_damage * 2.0
    lance_projectile.pierce_count = 999  # Pierces all enemies
    lance_projectile.speed = 15.0
    lance_projectile.burn_trail = true
    
    fire_projectile(lance_projectile, get_aim_direction())
    start_special_cooldown()
    
    # Creates solar burn trail behind projectile
    create_persistent_solar_trail(5.0)  # 5 second duration
```

#### **Staff of Thoth (Magic/AOE Focus)**
```gdscript
# StaffOfThoth.gd
var weapon_data = {
    "name": "Staff of Thoth",
    "base_damage": 35,
    "attack_speed": 1.2,
    "range": 4.0,
    "special_cooldown": 10.0,
    "mana_cost": 25,
    "weapon_type": "staff",
    "damage_type": "magic",
    "tags": ["magic", "aoe", "wisdom", "mana"]
}
```

**智能魔法系统:**
```gdscript
func perform_light_attack():
    # Magic-enhanced staff strike
    var hit_targets = detect_enemies_in_range(weapon_data.range)
    
    if hit_targets.size() > 0:
        var primary_target = hit_targets[0]
        deal_damage(primary_target, weapon_data.base_damage)
        
        # Magic spreads to nearby enemies
        var nearby_enemies = get_enemies_near(primary_target.position, 2.5)
        for enemy in nearby_enemies:
            if enemy != primary_target:
                deal_damage(enemy, weapon_data.base_damage * 0.6)
    
    trigger_animation("magic_strike")
    restore_mana(5)  # Each hit restores mana

func perform_heavy_attack():
    # Spell weaving combo
    if combo_count == 0:
        cast_magic_missile()
    elif combo_count == 1:
        cast_arcane_wave()
    elif combo_count == 2:
        cast_wisdom_blast()  # Finisher
        reset_combo()
```

**Special Ability: Knowledge Blast**
```gdscript
func use_special_ability():
    if current_mana < weapon_data.mana_cost:
        return
    
    # Smart-targeting AOE that prioritizes threats
    var all_enemies = get_all_enemies()
    var target_priorities = []
    
    for enemy in all_enemies:
        var priority = calculate_threat_level(enemy)
        target_priorities.append({"enemy": enemy, "threat": priority})
    
    # Sort by threat and target up to 5 highest threats
    target_priorities.sort_custom(func(a, b): return a.threat > b.threat)
    var targets = target_priorities.slice(0, 5)
    
    for target_data in targets:
        var enemy = target_data.enemy
        var blast_damage = weapon_data.base_damage * 2.5
        
        # Damage increases based on number of enemies hit
        blast_damage += (targets.size() - 1) * 15
        
        deal_damage(enemy, blast_damage)
        restore_mana(15)  # Mana restoration per hit
    
    current_mana -= weapon_data.mana_cost
    start_special_cooldown()

func calculate_threat_level(enemy: BaseEnemy) -> float:
    var threat = 0.0
    threat += enemy.current_hp * 0.1  # Higher HP = higher threat
    threat += enemy.damage * 2.0     # High damage enemies prioritized
    threat += (1.0 / max(enemy.distance_to_player(), 1.0)) * 50  # Closer = more threat
    return threat
```

#### **Bow of the Winds (Ranged/Charged System)**
```gdscript
# BowOfTheWinds.gd
var weapon_data = {
    "name": "Bow of the Winds",
    "base_damage": 50,
    "attack_speed": "variable",  # Charge-based
    "range": 10.0,
    "special_cooldown": 6.0,
    "weapon_type": "bow",
    "damage_type": "wind",
    "tags": ["ranged", "wind", "charged", "elemental"]
}

var charge_time = 0.0
var max_charge_time = 2.0
```

**Charge System Implementation:**
```gdscript
func handle_attack_input():
    if Input.is_action_pressed("primary_attack"):
        # Charging
        charge_time += get_process_delta_time()
        charge_time = min(charge_time, max_charge_time)
        update_charge_visual_indicator()
        
    elif Input.is_action_just_released("primary_attack"):
        # Release charged shot
        fire_charged_arrow()
        charge_time = 0.0

func fire_charged_arrow():
    var charge_percentage = charge_time / max_charge_time
    var arrow = create_wind_arrow()
    
    # Damage scales with charge
    if charge_percentage < 0.3:
        # Quick shot - 75% damage
        arrow.damage = weapon_data.base_damage * 0.75
        arrow.speed = 20.0
        arrow.effects = ["light_wind"]
    elif charge_percentage < 0.8:
        # Full charge - 125% damage  
        arrow.damage = weapon_data.base_damage * 1.25
        arrow.speed = 25.0
        arrow.effects = ["wind_trail", "knockback"]
    else:
        # Perfect charge - 200% damage
        arrow.damage = weapon_data.base_damage * 2.0
        arrow.speed = 30.0
        arrow.effects = ["piercing", "wind_explosion", "slow_enemies"]
        create_perfect_charge_vfx()
    
    fire_projectile(arrow, get_aim_direction())
```

**Special Ability: Wind Arrow Storm**
```gdscript
func use_special_ability():
    # Fires 5 arrows in spread pattern
    var arrow_count = 5
    var spread_angle = 30.0  # degrees
    var base_direction = get_aim_direction()
    
    for i in range(arrow_count):
        var angle_offset = (i - arrow_count/2) * (spread_angle / arrow_count)
        var arrow_direction = base_direction.rotated(deg_to_rad(angle_offset))
        
        var wind_arrow = create_wind_arrow()
        wind_arrow.damage = weapon_data.base_damage * 0.8  # Slightly less per arrow
        wind_arrow.pierce_count = 2
        wind_arrow.wind_current_duration = 4.0  # Creates wind currents
        
        fire_projectile(wind_arrow, arrow_direction)
    
    start_special_cooldown()
```

### **🔄 WEAPON SWITCHING SYSTEM**

#### **Seamless Switching Implementation**
```gdscript
# WeaponManager.gd
class_name WeaponManager extends Node

signal weapon_switched(old_weapon, new_weapon)
signal weapon_mastery_gained(weapon, level)

var current_weapon: BaseWeapon
var available_weapons: Array[BaseWeapon] = []
var weapon_history: Array[int] = []  # Last 3 weapons for quick switching
var switching_enabled = true

func switch_weapon(weapon_index: int, force_switch = false):
    if not can_switch_weapon() and not force_switch:
        return false
    
    if weapon_index >= available_weapons.size():
        return false
    
    var old_weapon = current_weapon
    var new_weapon = available_weapons[weapon_index]
    
    # Handle switching restrictions
    if player.is_in_combat and not player.can_cancel_action():
        # Queue switch for next opportunity
        queue_weapon_switch(weapon_index)
        return false
    
    # Perform switch
    if old_weapon:
        old_weapon.on_unequip()
        old_weapon.hide()
    
    current_weapon = new_weapon
    current_weapon.on_equip()
    current_weapon.show()
    
    # Update weapon history for quick toggle
    update_weapon_history(weapon_index)
    
    # Notify systems
    weapon_switched.emit(old_weapon, new_weapon)
    GameManager.weapon_switched.emit(new_weapon)
    
    # Transfer some boons between weapons
    transfer_compatible_boons(old_weapon, new_weapon)
    
    return true

func can_switch_weapon() -> bool:
    return switching_enabled and not player.is_dead and not player.is_stunned

func quick_toggle_weapon():
    # Toggle between current and previous weapon
    if weapon_history.size() >= 2:
        var previous_weapon_index = weapon_history[1]
        switch_weapon(previous_weapon_index, true)
```

#### **Combat Integration**
```gdscript
# Player.gd weapon switching during combat
func handle_weapon_switch_input():
    if Input.is_action_just_pressed("weapon_1"):
        weapon_manager.switch_weapon(0)
    elif Input.is_action_just_pressed("weapon_2"):
        weapon_manager.switch_weapon(1)
    # ... etc
    
    # Quick toggle (TAB key)
    if Input.is_action_just_pressed("quick_weapon_toggle"):
        weapon_manager.quick_toggle_weapon()

func _on_dash_started():
    # Weapon switching costs dash to prevent spam
    if weapon_manager.has_queued_switch():
        weapon_manager.execute_queued_switch()
        # Consume dash cooldown for weapon switching
```

### **🏅 WEAPON MASTERY SYSTEM**

#### **Experience & Progression**
```gdscript
# WeaponMastery.gd
class_name WeaponMastery extends Node

var weapon_experience = {}
var weapon_levels = {}
var mastery_bonuses = {}

const EXP_PER_LEVEL = [0, 100, 250, 500, 1000, 2000]  # Cumulative
const MAX_WEAPON_LEVEL = 5

func gain_weapon_exp(weapon_id: String, exp_amount: int, source: String = "combat"):
    if not weapon_experience.has(weapon_id):
        weapon_experience[weapon_id] = 0
        weapon_levels[weapon_id] = 0
    
    weapon_experience[weapon_id] += exp_amount
    
    # Check for level up
    var current_level = weapon_levels[weapon_id]
    if current_level < MAX_WEAPON_LEVEL:
        var required_exp = EXP_PER_LEVEL[current_level + 1]
        if weapon_experience[weapon_id] >= required_exp:
            level_up_weapon(weapon_id)

func level_up_weapon(weapon_id: String):
    weapon_levels[weapon_id] += 1
    var new_level = weapon_levels[weapon_id]
    
    # Apply mastery bonus
    apply_mastery_bonus(weapon_id, new_level)
    
    # Notify player
    GameManager.weapon_mastery_gained.emit(weapon_id, new_level)
    show_mastery_unlock_notification(weapon_id, new_level)
```

**Mastery Bonuses per Weapon:**
```gdscript
func apply_mastery_bonus(weapon_id: String, level: int):
    var weapon = WeaponManager.get_weapon_by_id(weapon_id)
    
    match level:
        1: 
            weapon.damage_multiplier += 0.05  # +5% damage
        2:
            weapon.attack_speed_multiplier += 0.10  # +10% attack speed
        3:
            unlock_combo_extension(weapon_id)  # Unique combo per weapon
        4:
            weapon.critical_chance += 0.15  # +15% crit chance
        5:
            unlock_master_technique(weapon_id)  # Ultimate technique
```

**Master Techniques (Level 5 Unlocks):**
- **Was Scepter:** "Divine Authority" - Special creates solar nova
- **Khopesh:** "Pharaoh's Judgment" - Execute enemies below 40% HP
- **Spear of Ra:** "Solar Dominance" - All attacks pierce and burn
- **Staff of Thoth:** "Arcane Mastery" - Spells cost no mana for 10s
- **Bow of Winds:** "Perfect Storm" - All arrows automatically perfect charged

### **🎯 BALANCE PASS**

#### **DPS Normalization**
```gdscript
# WeaponBalance.gd
func calculate_theoretical_dps():
    var dps_targets = {
        "was_scepter": 85.0,    # Fast, consistent
        "khopesh": 80.0,        # Balanced baseline
        "spear_ra": 75.0,       # Range advantage compensates
        "staff_thoth": 70.0,    # AOE advantage compensates  
        "bow_winds": 90.0       # Skill-based higher ceiling
    }
    
    for weapon_id in available_weapons:
        var weapon = get_weapon(weapon_id)
        var actual_dps = calculate_weapon_dps(weapon)
        var target_dps = dps_targets[weapon_id]
        
        if abs(actual_dps - target_dps) > 5.0:
            suggest_balance_adjustment(weapon_id, actual_dps, target_dps)
```

#### **Situational Advantages**
- **Was Scepter:** Best for quick encounters, elite enemies
- **Khopesh:** Most versatile, good combo potential
- **Spear of Ra:** Excels vs groups, ranged safety
- **Staff of Thoth:** Dominant vs swarms, mana builds
- **Bow of Winds:** Skill-based, highest single-target potential

### **🔗 INTEGRATION REQUIREMENTS**

#### **Boon System Integration**
```gdscript
# BoonSystem.gd integration
func apply_boon_to_weapon(boon: BoonData, weapon: BaseWeapon):
    # Check weapon tags for compatibility
    for tag in weapon.tags:
        if boon.compatible_tags.has(tag):
            weapon.apply_boon_effect(boon)
            break

# Weapon-specific boon interactions
func get_weapon_specific_boons(weapon: BaseWeapon) -> Array:
    var compatible_boons = []
    for boon in all_available_boons:
        if boon.weapon_requirements.is_empty() or boon.weapon_requirements.has(weapon.weapon_type):
            compatible_boons.append(boon)
    return compatible_boons
```

#### **Animation System Integration**
```gdscript
# AnimationController.gd
func setup_weapon_animations(weapon: BaseWeapon):
    var animation_set = load("res://animations/weapons/" + weapon.weapon_id + "_animations.res")
    
    animation_player.add_animation_library(weapon.weapon_id, animation_set)
    
    # Setup smooth transitions between weapons
    var transition_time = 0.2
    animation_tree.set("parameters/weapon_transition/transition_time", transition_time)
```

### **📋 TESTING CHECKLIST**

#### **Individual Weapon Tests:**
- [ ] Spear of Ra: Range attacks work, solar effects apply
- [ ] Staff of Thoth: AOE magic functions, mana system integrated
- [ ] Bow of Winds: Charge system responsive, wind effects visible
- [ ] All weapons: Special abilities trigger correctly
- [ ] All weapons: Combo system flows naturally

#### **System Integration:**
- [ ] Weapon switching works during combat
- [ ] Mastery system saves/loads properly
- [ ] Boon compatibility system functions
- [ ] Animation transitions are smooth
- [ ] UI updates reflect weapon changes immediately

#### **Balance Testing:**
- [ ] All weapons achieve similar DPS over extended play
- [ ] Each weapon has clear situational advantages
- [ ] Master techniques feel impactful but not overpowered
- [ ] Weapon progression feels rewarding

### **🎯 SUCCESS METRICS**

- **5 unique weapons** with distinct playstyles implemented
- **Weapon switching** feels smooth and responsive
- **Mastery system** provides long-term progression goals
- **Balance parity** - no weapon dominates meta
- **Build diversity** - each weapon supports multiple viable builds

---

# 🌟 **SPRINT 11: ADVANCED BOON SYSTEM**
**Duration:** 1 semana | **Priority:** CRITICAL - Core progression depth

## **Objetivos:**
Expandir sistema de boons de 20 para 50+ com duo/legendary variants, synergias complexas e sistema de evolução.

### **🎲 EXPANSÃO DAS CATEGORIAS DE BOONS**

#### **ATTACK Boons (15 total)**
```gdscript
# AttackBoons.gd
var attack_boons = {
    # Damage Multipliers
    "divine_strength": {
        "name": "Divine Strength",
        "god": "ra",
        "rarity_effects": {
            "common": {"damage_multiplier": 0.25},
            "rare": {"damage_multiplier": 0.40},
            "epic": {"damage_multiplier": 0.60}
        },
        "description": "Your attacks deal more damage",
        "tags": ["damage", "solar", "basic"]
    },
    
    # Critical Hit Focus
    "solar_precision": {
        "name": "Solar Precision", 
        "god": "ra",
        "rarity_effects": {
            "common": {"critical_chance": 0.15, "critical_damage": 0.5},
            "rare": {"critical_chance": 0.25, "critical_damage": 0.8},
            "epic": {"critical_chance": 0.35, "critical_damage": 1.2}
        },
        "tags": ["critical", "solar", "precision"]
    },
    
    # Attack Speed
    "blessed_swiftness": {
        "name": "Blessed Swiftness",
        "god": "bastet",
        "rarity_effects": {
            "common": {"attack_speed_multiplier": 0.20},
            "rare": {"attack_speed_multiplier": 0.35}, 
            "epic": {"attack_speed_multiplier": 0.50}
        },
        "tags": ["speed", "agility", "cat"]
    },
    
    # Weapon-Specific
    "khopesh_mastery": {
        "name": "Khopesh Mastery",
        "god": "anubis",
        "weapon_requirement": "khopesh",
        "rarity_effects": {
            "common": {"combo_extension": 1, "finisher_damage": 0.5},
            "rare": {"combo_extension": 2, "finisher_damage": 0.8},
            "epic": {"combo_extension": 3, "finisher_damage": 1.2}
        },
        "tags": ["weapon_specific", "death", "execution"]
    }
}
```

#### **DEFENSE Boons (12 total)**
```gdscript
var defense_boons = {
    # Health Increases
    "divine_vitality": {
        "name": "Divine Vitality",
        "god": "bastet", 
        "rarity_effects": {
            "common": {"max_hp_increase": 25},
            "rare": {"max_hp_increase": 40},
            "epic": {"max_hp_increase": 60}
        },
        "tags": ["health", "protection", "vitality"]
    },
    
    # Damage Reduction
    "stone_skin": {
        "name": "Stone Skin",
        "god": "khnum",
        "rarity_effects": {
            "common": {"damage_reduction": 0.10},
            "rare": {"damage_reduction": 0.15}, 
            "epic": {"damage_reduction": 0.25}
        },
        "tags": ["armor", "reduction", "earth"]
    },
    
    # Death Defiance System
    "nine_lives": {
        "name": "Nine Lives",
        "god": "bastet",
        "rarity_effects": {
            "rare": {"death_defiances": 1},
            "epic": {"death_defiances": 2}
        },
        "tags": ["death_defiance", "cat", "resurrection"],
        "minimum_rarity": "rare"
    }
}
```

#### **MOBILITY Boons (10 total)**
```gdscript
var mobility_boons = {
    # Movement Speed  
    "wind_walker": {
        "name": "Wind Walker",
        "god": "shu", # God of air
        "rarity_effects": {
            "common": {"movement_speed_multiplier": 0.25},
            "rare": {"movement_speed_multiplier": 0.40},
            "epic": {"movement_speed_multiplier": 0.60}
        },
        "tags": ["speed", "movement", "wind"]
    },
    
    # Dash Enhancements
    "shadow_step": {
        "name": "Shadow Step",
        "god": "anubis",
        "rarity_effects": {
            "common": {"dash_charges": 1, "dash_distance": 1.0},
            "rare": {"dash_charges": 2, "dash_distance": 2.0},
            "epic": {"dash_charges": 3, "dash_distance": 3.0}
        },
        "tags": ["dash", "shadow", "death"]
    },
    
    # Wall Phasing
    "spirit_form": {
        "name": "Spirit Form", 
        "god": "osiris",
        "rarity_effects": {
            "epic": {"wall_phase_enabled": true, "phase_duration": 2.0}
        },
        "tags": ["phase", "spirit", "ethereal"],
        "minimum_rarity": "epic"
    }
}
```

### **🔥 DUO BOON SYSTEM**

#### **God Combination Matrix**
```gdscript
# DuoBoons.gd
class_name DuoBoons extends Node

var duo_combinations = {
    # Ra + Bastet: Solar Shield
    "solar_shield": {
        "name": "Solar Shield",
        "gods": ["ra", "bastet"],
        "prerequisites": {
            "ra": ["divine_strength", "solar_precision", "burning_attacks"],
            "bastet": ["blessed_swiftness", "divine_vitality", "cat_reflexes"] 
        },
        "effects": {
            "dash_fire_trail": true,
            "post_dash_invincibility": 2.0,
            "fire_trail_damage": 30
        },
        "description": "Dash creates fire trail and grants brief invincibility"
    },
    
    # Thoth + Anubis: Judgment of Wisdom
    "judgment_wisdom": {
        "name": "Judgment of Wisdom",
        "gods": ["thoth", "anubis"],
        "prerequisites": {
            "thoth": ["arcane_knowledge", "mana_efficiency", "spell_power"],
            "anubis": ["death_mark", "soul_harvest", "judgment_strike"]
        },
        "effects": {
            "execute_threshold": 0.30,  # 30% HP execute
            "mana_restore_on_execute": 50,
            "wisdom_mark": true  # Reveals enemy weaknesses
        }
    },
    
    # Ra + Anubis: Solar Execution
    "solar_execution": {
        "name": "Solar Execution", 
        "gods": ["ra", "anubis"],
        "prerequisites": {
            "ra": ["divine_strength", "solar_flare"],
            "anubis": ["death_mark", "execute_power"]
        },
        "effects": {
            "fire_execute_threshold": 0.25,
            "execute_explosion": true,
            "solar_spread_damage": 75
        }
    }
}

func check_duo_availability(player_boons: Array) -> Array:
    var available_duos = []
    
    for duo_id in duo_combinations:
        var duo = duo_combinations[duo_id]
        
        # Check if player has prerequisite boons from both gods
        var god1_met = false
        var god2_met = false
        
        for god in duo.gods:
            var prerequisites = duo.prerequisites[god]
            var player_god_boons = get_player_boons_by_god(player_boons, god)
            
            for prereq in prerequisites:
                if player_god_boons.has(prereq):
                    if god == duo.gods[0]:
                        god1_met = true
                    else:
                        god2_met = true
                    break
        
        if god1_met and god2_met:
            available_duos.append(duo_id)
    
    return available_duos
```

### **⭐ LEGENDARY BOON SYSTEM**

#### **Ultimate Power Boons**
```gdscript
# LegendaryBoons.gd
var legendary_boons = {
    # Ra's Eclipse - Ultimate Solar Power
    "ras_eclipse": {
        "name": "Eclipse of Ra",
        "god": "ra",
        "prerequisites": ["divine_strength", "solar_flare", "burning_attacks", "solar_precision"],
        "rarity": "legendary",
        "trigger_condition": "player_health < 0.25",
        "effects": {
            "eclipse_damage": 500,  # % of weapon damage
            "eclipse_radius": 15.0,  # Covers entire room
            "eclipse_duration": 3.0,
            "eclipse_cooldown": 60.0
        },
        "description": "When near death, unleash a solar eclipse that devastates all enemies",
        "activation_text": "The sun bows to your divine will!"
    },
    
    # Bastet's Nine Lives
    "bastets_nine_lives": {
        "name": "Bastet's Nine Lives",
        "god": "bastet",
        "prerequisites": ["divine_vitality", "cat_reflexes", "nine_lives", "protective_aura"],
        "effects": {
            "death_defiances": 3,  # Normally max is 1
            "revival_invincibility": 5.0,
            "revival_damage_boost": 1.5,
            "perfect_dodge_window": 0.5  # Brief perfect dodge after revival
        },
        "description": "Death cannot claim you - rise with the fury of the divine cat"
    },
    
    # Thoth's Omniscience
    "thoths_omniscience": {
        "name": "Thoth's Omniscience", 
        "god": "thoth",
        "prerequisites": ["arcane_knowledge", "wisdom_sight", "mana_mastery", "spell_synergy"],
        "effects": {
            "reveal_all_secrets": true,
            "optimal_boon_suggestions": true, 
            "synergy_preview": true,
            "hidden_room_detection": true,
            "enemy_weakness_display": true
        },
        "description": "See all - know all - the secrets of the Duat are revealed"
    },
    
    # Anubis's Final Judgment  
    "anubis_final_judgment": {
        "name": "Final Judgment of Anubis",
        "god": "anubis",
        "prerequisites": ["death_mark", "soul_harvest", "execute_power", "judgment_strike"],
        "effects": {
            "random_execute_chance": 0.15,  # 15% chance any attack executes
            "execute_damage_bonus": 2,  # +2 permanent damage per execution
            "judgment_aura": true,  # Nearby enemies take DOT
            "soul_collection": true  # Executions grant special currency
        },
        "description": "Your judgment is absolute - death comes for all who oppose you"
    }
}
```

### **📈 BOON EVOLUTION SYSTEM**

#### **Divine Essence Upgrade System**
```gdscript
# BoonEvolution.gd
class_name BoonEvolution extends Node

const MAX_BOON_LEVEL = 5
const EVOLUTION_COSTS = [0, 10, 25, 50, 100, 200]  # Divine Essence cost per level

var player_boons = {}  # boon_id -> {level, effects}

func evolve_boon(boon_id: String, player_currency: Dictionary) -> bool:
    if not player_boons.has(boon_id):
        return false
    
    var current_level = player_boons[boon_id].level
    if current_level >= MAX_BOON_LEVEL:
        return false
    
    var cost = EVOLUTION_COSTS[current_level + 1]
    if player_currency.divine_essence < cost:
        return false
    
    # Apply evolution
    player_boons[boon_id].level += 1
    update_boon_effects(boon_id)
    
    # Consume currency
    player_currency.divine_essence -= cost
    
    # Visual feedback
    show_evolution_effect(boon_id, current_level + 1)
    GameManager.boon_evolved.emit(boon_id, current_level + 1)
    
    return true

func update_boon_effects(boon_id: String):
    var boon = player_boons[boon_id]
    var base_boon_data = BoonDatabase.get_boon(boon_id)
    var level = boon.level
    
    # Apply scaling based on level
    for effect_name in base_boon_data.effects:
        var base_value = base_boon_data.effects[effect_name]
        var evolved_value = base_value * (1.0 + (level - 1) * 0.3)  # 30% increase per level
        
        boon.effects[effect_name] = evolved_value
        
    # Special effects at certain levels
    match level:
        3:
            add_special_evolution_effect(boon_id, "mid_tier")
        5:
            add_special_evolution_effect(boon_id, "master_tier")
```

### **🔗 SYNERGY SYSTEM ADVANCED**

#### **Complex Interaction Detection**
```gdscript
# BoonSynergyEngine.gd
class_name BoonSynergyEngine extends Node

var synergy_rules = {
    # Tag-based synergies
    "divine_convergence": {
        "required_tags": ["solar", "death", "wisdom", "protection"],
        "min_boons": 4,  # Need boons from all 4 domains
        "effects": {
            "all_damage_multiplier": 0.5,  # 50% more damage
            "divine_aura": true,  # Constant regeneration + immunity
            "god_mode_duration": 10.0  # Brief periods of invincibility
        },
        "description": "The gods unite their power through you"
    },
    
    # Weapon-specific synergies
    "khopesh_execution_mastery": {
        "required_weapon": "khopesh",
        "required_boons": ["khopesh_mastery", "execute_power", "critical_strikes"],
        "effects": {
            "execute_threshold": 0.5,  # Execute at 50% HP instead of 30%
            "execute_chain": true,  # Executions can chain to nearby enemies
            "royal_authority": 2.0  # +200% damage vs elite enemies
        }
    },
    
    # Status effect combinations
    "suffering_amplification": {
        "required_statuses": ["burn", "weak", "doom"],
        "effects": {
            "status_damage_multiplier": 2.0,
            "status_spread": true,  # Status effects spread to nearby enemies
            "despair_aura": 0.5  # Enemies move 50% slower when suffering
        }
    }
}

func detect_active_synergies(player_boons: Array, player_weapon: BaseWeapon) -> Array:
    var active_synergies = []
    
    for synergy_id in synergy_rules:
        var synergy = synergy_rules[synergy_id]
        
        if meets_synergy_requirements(synergy, player_boons, player_weapon):
            active_synergies.append({
                "id": synergy_id,
                "effects": synergy.effects,
                "description": synergy.description
            })
            
    return active_synergies

func apply_synergy_effects(synergies: Array):
    for synergy in synergies:
        for effect_name in synergy.effects:
            var effect_value = synergy.effects[effect_name]
            GameManager.apply_synergy_effect(effect_name, effect_value)
```

### **🎯 ANTI-FRUSTRATION SYSTEMS**

#### **Smart Boon Offering**
```gdscript
# BoonOfferingAI.gd
class_name BoonOfferingAI extends Node

var rooms_since_last_boon = 0
var player_build_analysis = {}

func generate_boon_offering(room_context: Dictionary) -> Array:
    var available_boons = get_all_available_boons()
    
    # Anti-frustration: Force boon room if too long without one
    if rooms_since_last_boon >= 3:
        force_boon_offering = true
        rooms_since_last_boon = 0
    
    # Analyze player's current build
    analyze_player_build()
    
    # Filter out anti-synergy boons
    available_boons = filter_anti_synergy_boons(available_boons)
    
    # Boost synergy boons for current build
    available_boons = boost_synergy_boons(available_boons)
    
    # Ensure rarity distribution
    var offering = select_balanced_offering(available_boons, 3)
    
    return offering

func analyze_player_build():
    var player_boons = GameManager.get_player_boons()
    var dominant_gods = {}
    var build_focus = ""
    
    # Count boons per god
    for boon in player_boons:
        var god = boon.god
        if not dominant_gods.has(god):
            dominant_gods[god] = 0
        dominant_gods[god] += 1
    
    # Determine build focus
    var max_god_count = 0
    for god in dominant_gods:
        if dominant_gods[god] > max_god_count:
            max_god_count = dominant_gods[god]
            build_focus = god
    
    player_build_analysis = {
        "dominant_god": build_focus,
        "god_distribution": dominant_gods,
        "build_archetype": determine_build_archetype(player_boons),
        "missing_synergies": find_missing_synergies(player_boons)
    }

func boost_synergy_boons(available_boons: Array) -> Array:
    for boon in available_boons:
        # Boost boons that would complete synergies
        for missing_synergy in player_build_analysis.missing_synergies:
            if would_complete_synergy(boon, missing_synergy):
                boon.offering_weight *= 3.0  # 3x more likely to appear
        
        # Boost boons from dominant god
        if boon.god == player_build_analysis.dominant_god:
            boon.offering_weight *= 2.0
    
    return available_boons
```

### **🔗 INTEGRATION REQUIREMENTS**

#### **UI Integration**
```gdscript
# BoonSelectionUI.gd
func display_boon_selection(boon_options: Array):
    for i in range(boon_options.size()):
        var boon = boon_options[i]
        var boon_card = boon_selection_cards[i]
        
        # Update card display
        boon_card.set_boon_icon(boon.icon)
        boon_card.set_boon_name(boon.name)
        boon_card.set_boon_description(boon.description)
        boon_card.set_rarity_border(boon.rarity)
        
        # Show synergy indicators
        var synergies = BoonSynergyEngine.get_potential_synergies(boon)
        if synergies.size() > 0:
            boon_card.show_synergy_indicator(synergies)
            
        # Show evolution possibility
        if can_evolve_boon(boon):
            boon_card.show_evolution_indicator()

func _on_boon_selected(boon_index: int):
    var selected_boon = current_boon_options[boon_index]
    
    # Apply boon to player
    GameManager.apply_boon(selected_boon)
    
    # Check for new synergies
    var new_synergies = BoonSynergyEngine.detect_new_synergies(selected_boon)
    if new_synergies.size() > 0:
        show_synergy_activation_effect(new_synergies)
    
    # Close selection UI
    close_boon_selection()
```

### **📋 TESTING CHECKLIST**

#### **Individual Boon Tests:**
- [ ] All 50+ boons have correct effects and scaling
- [ ] Rarity system provides meaningful power increases
- [ ] Weapon-specific boons only appear for correct weapons
- [ ] Status effect boons integrate properly with combat

#### **Advanced System Tests:**
- [ ] Duo boons only appear when prerequisites are met
- [ ] Legendary boons trigger correctly and feel impactful
- [ ] Evolution system scales appropriately across levels
- [ ] Synergy detection works for complex combinations

#### **Balance Tests:**
- [ ] No single boon dominates all builds
- [ ] 100+ viable build combinations possible
- [ ] Anti-frustration systems prevent bad luck streaks
- [ ] Build diversity encourages experimentation

#### **Integration Tests:**
- [ ] UI properly displays all boon information
- [ ] Save/load handles evolved and legendary boons
- [ ] Performance remains stable with complex synergies active
- [ ] Synergy effects stack correctly without breaking balance

### **🎯 SUCCESS METRICS**

**Completion Criteria:**
- **50+ unique boons** with meaningful effects
- **15+ duo boons** with complex prerequisites
- **4+ legendary boons** that feel game-changing
- **Complex synergy system** enabling 100+ viable builds

**Player Experience Goals:**
- **Build diversity:** No dominant meta builds
- **Discovery excitement:** Finding new synergies feels rewarding
- **Progressive power:** Clear sense of getting stronger
- **Strategic depth:** Meaningful choices at every boon selection

---

# 👑 **SPRINT 12: FIRST BOSS COMPLETE**
**Duration:** 1 semana | **Priority:** CRITICAL - Precisa de victory condition

## **Objetivos:**
Implementar Khaemwaset boss battle completo com narrativa integrada, mecânicas multi-fase, e flow de victory/defeat robusto.

### **🏺 BOSS DESIGN: KHAEMWASET (CORRUPTED HIGH PRIEST)**

#### **Narrative Context**
```gdscript
# KhaemwasetBoss.gd
var boss_narrative_data = {
    "name": "Khaemwaset the Fallen",
    "title": "High Priest of the Corrupted Order", 
    "backstory": "Former mentor and spiritual advisor to Khenti's family. Corrupted by Set's promises of eternal life for Egypt.",
    "relationship_to_player": "Paternal figure turned betrayer",
    "conspiracy_role": "Orchestrated the religious ceremony assassination",
    "moral_dilemma": "Execute in vengeance vs. show mercy for justice",
    "revelation": "First to reveal Set's influence and Nefertari's fate"
}
```

**Character Motivation:**
- Genuinely believed Set's promises would save Egypt from decline
- Sacrificed Khenti for "the greater good" of the kingdom
- Now tormented by guilt but too deep in corruption to turn back
- Serves as mirror to player - what happens when good intentions corrupt

#### **Combat Statistics**
```gdscript
var boss_stats = {
    "total_hp": 1200,
    "phase_hp_distribution": [400, 400, 400],  # 3 phases
    "size_category": "large",  # 2x normal enemy collision
    "movement_speed": 2.0,
    "damage_output": 45,  # Base damage per attack
    "status_immunities": ["weak", "charm"],  # Cannot be weakened or controlled
    "armor_type": "magical",  # Resistant to physical, vulnerable to divine
    "arena_bounds": {"width": 40, "height": 40}  # Large boss arena
}
```

### **🌟 PHASE-BASED COMBAT SYSTEM**

#### **PHASE 1 (100% → 66% HP): "The Faithful Servant"**
*Khaemwaset still believes he serves the divine will*

**Visual Design:**
- Pristine high priest robes with golden trim
- Staff of office glowing with traditional divine light
- Confident posture, righteous demeanor
- Egyptian hieroglyphs float around him

**Attack Patterns:**
```gdscript
func phase_1_ai():
    match current_attack_pattern:
        "shadow_barrier":
            create_protective_dome()
            summon_lesser_shades(3)
            wait_for_barrier_destruction()
            
        "divine_projectiles":
            var projectile_count = 5
            fire_homing_projectiles(projectile_count, 25)  # damage per projectile
            
        "teleport_strike":
            if player_distance < 4.0:
                teleport_behind_player()
                staff_swing_attack(60)  # Higher damage melee
                
        "righteous_speech":
            # Mid-combat dialogue
            trigger_dialogue("divine_justification")
            create_divine_light_distraction()
```

**Arena Mechanics (Phase 1):**
- **Ancient Braziers (4):** Can be lit to dispel shadow barriers faster
- **Hieroglyph Panels (6):** Activation reveals boss weak points
- **Stone Pillars (8):** Provide cover from projectiles
- **Divine Seal (Center):** Glows brighter as boss takes damage

**Dialogue Integration:**
```gdscript
var phase_1_dialogue = {
    "combat_start": "Khenti... my boy. You should have remained at peace in death.",
    "first_hit": "I taught you to fight, remember? But this knowledge serves divine purpose now.",
    "barrier_broken": "You always were too clever for your own good...",
    "low_health": "The gods demanded sacrifice! Egypt's survival required it!"
}
```

#### **PHASE 2 (66% → 33% HP): "The Corrupted Truth"**
*Set's influence becomes visible, boss more aggressive*

**Visual Transformation:**
- Eyes begin glowing red (Set's corruption)
- Staff warps into twisted, dark version
- Robes become tattered, shadowy tendrils emerge
- Floating hieroglyphs turn into chaotic symbols

**New Attack Patterns:**
```gdscript
func phase_2_ai():
    # Enhanced aggression and new abilities
    match current_attack_pattern:
        "corruption_wave":
            # Arena-wide attack requiring cover
            charge_corruption_wave(2.0)  # 2 second telegraph
            release_room_spanning_attack(80)  # High damage
            
        "sets_whispers":
            attempt_player_charm(5.0)  # 5 second charm duration
            if charm_successful:
                reverse_player_controls()
            else:
                player_gains_resistance_buff()
                
        "chaos_rifts":
            var rift_count = 3
            for i in range(rift_count):
                create_chaos_rift(get_random_arena_position())
                spawn_chaos_minions_from_rift(2)  # 2 enemies per rift
                
        "truth_bombardment":
            # Rapid succession attacks while exposing conspiracy
            continuous_projectile_barrage(10.0)  # 10 seconds of attacks
            trigger_dialogue("conspiracy_revelation")
```

**Environmental Changes:**
- Some pillars crack and become less reliable cover
- Braziers flicker and require re-lighting more often
- New shadow pools appear that slow player movement
- Arena lighting becomes more dramatic and chaotic

**Conspiracy Revelation Dialogue:**
```gdscript
var phase_2_dialogue = {
    "transformation": "Set... Set promised us eternal glory! Egypt would never fall!",
    "chaos_rifts": "Your brother... he was so eager to please the Chaos God...",
    "corruption_wave": "I see the truth now - we were all puppets in Set's game!",
    "near_death": "Nefertari... she still lives, but not for long... Set has plans..."
}
```

#### **PHASE 3 (33% → 0% HP): "Desperate Revelation"**
*Final truth revealed, boss becomes erratic and dangerous*

**Final Transformation:**
- Fully corrupted appearance, more shadow than flesh
- Attacks become desperate and unpredictable
- Arena begins to crumble and change
- Set's presence becomes almost tangible

**Finale Mechanics:**
```gdscript
func phase_3_ai():
    # Erratic patterns, environmental destruction
    if health_percentage < 0.15:
        # Berserk mode - final 15% of health
        damage_multiplier = 1.5
        attack_speed_multiplier = 1.3
        enable_environmental_destruction()
        
    # Truth revelation attacks
    match current_attack_pattern:
        "desperate_flurry":
            # Breaks normal attack rules - can interrupt player actions
            rapid_fire_attacks(15)  # 15 quick attacks
            
        "arena_collapse":
            destroy_random_pillars(2)
            create_falling_debris_hazards()
            
        "final_truth":
            # Major conspiracy exposition during combat
            trigger_extended_dialogue("full_conspiracy_truth")
            power_boost_during_speech()
```

**Player Choice Integration:**
During Phase 3, player actions and choices throughout the run affect the final confrontation:
- **Merciful Path:** Can attempt to purify Khaemwaset's corruption
- **Justice Path:** Formal trial-by-combat with specific mechanics
- **Vengeance Path:** Pure combat with corruption-based power boosts

### **⚖️ MORAL CHOICE SYSTEM**

#### **Choice Consequences**
```gdscript
# MoralChoiceManager.gd
enum MoralPath {
    MERCY,
    JUSTICE, 
    VENGEANCE,
    UNDECIDED
}

var player_moral_score = {
    "mercy": 0,
    "justice": 0,
    "vengeance": 0
}

func evaluate_final_choice() -> MoralPath:
    # Based on player's actions throughout the game
    var highest_score = 0
    var dominant_path = MoralPath.UNDECIDED
    
    for path in player_moral_score:
        if player_moral_score[path] > highest_score:
            highest_score = player_moral_score[path]
            dominant_path = MoralPath[path.to_upper()]
    
    return dominant_path

func apply_choice_consequences(choice: MoralPath):
    match choice:
        MoralPath.MERCY:
            # Spare Khaemwaset, learn about saving Nefertari
            unlock_narrative_path("redemption")
            grant_boon("divine_mercy")
            khaemwaset_becomes_ally()
            
        MoralPath.JUSTICE:
            # Formal judgment, boss accepts fate with dignity
            unlock_narrative_path("balance")
            grant_divine_essence(50)
            gain_respect_of_gods()
            
        MoralPath.VENGEANCE:
            # Execute in anger, gain dark power
            unlock_narrative_path("corruption")
            grant_boon("righteous_fury")
            increase_corruption_level(1)
```

### **🎭 DIALOGUE SYSTEM INTEGRATION**

#### **Dynamic Combat Dialogue**
```gdscript
# BossDialogue.gd
class_name BossDialogue extends Node

var dialogue_database = {
    "phase_transitions": {
        "phase_1_to_2": [
            "The gods forgive me... but Set's power is absolute!",
            "*Eyes begin to glow red with corruption*",
            "I can feel his influence even here in the Duat!"
        ],
        "phase_2_to_3": [
            "You don't understand! Without the sacrifice, Egypt would have fallen!",
            "*Robes tear as shadow tendrils emerge*", 
            "Your brother promised Set would make Egypt eternal!"
        ]
    },
    
    "player_weapon_reactions": {
        "was_scepter": "The Scepter of Ra... you carry the sun god's authority even in death.",
        "khopesh": "A pharaoh's blade... how fitting that you would claim royal weapons.",
        "staff_thoth": "Thoth's own staff... the god of wisdom judges us both today."
    },
    
    "player_performance": {
        "perfect_dodge": "Still as quick as when I trained you...",
        "low_health": "Death has made you stronger, hasn't it?",
        "high_damage": "I taught you well... perhaps too well."
    }
}

func trigger_context_dialogue(context: String, additional_data: Dictionary = {}):
    var dialogue_options = dialogue_database.get(context, [])
    
    if dialogue_options.size() > 0:
        var selected_dialogue = dialogue_options[randi() % dialogue_options.size()]
        
        # Process dynamic elements
        selected_dialogue = process_dialogue_variables(selected_dialogue, additional_data)
        
        # Display with appropriate timing
        display_boss_dialogue(selected_dialogue)
```

### **🏆 VICTORY REWARDS & PROGRESSION**

#### **Immediate Victory Rewards**
```gdscript
# BossVictoryRewards.gd
func distribute_victory_rewards(moral_choice: MoralPath):
    var base_rewards = {
        "ankh_fragments": 500,  # Major currency boost
        "heart_piece": 1,       # +25 max HP permanent
        "divine_essence": 3,    # For weapon/boon upgrades
        "memory_fragments": 100 # Meta-progression currency
    }
    
    # Modify based on player choice
    match moral_choice:
        MoralPath.MERCY:
            base_rewards.memory_fragments += 50  # Bonus for difficult choice
            unlock_special_boon("divine_mercy")
            
        MoralPath.JUSTICE:
            base_rewards.divine_essence += 2     # Extra upgrade currency
            unlock_weapon_aspect("balanced_judgment")
            
        MoralPath.VENGEANCE:
            base_rewards.ankh_fragments += 200   # More immediate power
            unlock_weapon_aspect("righteous_fury")
    
    # Apply rewards
    for reward_type in base_rewards:
        GameManager.add_currency(reward_type, base_rewards[reward_type])
    
    # Trigger achievement checks
    check_boss_achievements()
```

#### **Story Progression Unlocks**
```gdscript
func unlock_story_progression():
    # Major story beats unlocked
    var story_unlocks = [
        "pool_of_memories_access",    # Hub world becomes available
        "nefertari_echo_npc",        # Love interest appears in hub
        "second_biome_pathway",       # Rio de Fogo access
        "conspiracy_revelation_1"     # First major plot point
    ]
    
    for unlock in story_unlocks:
        GameManager.unlock_story_element(unlock)
    
    # Weapon unlock based on choice
    var new_weapon = determine_weapon_unlock()
    GameManager.unlock_weapon(new_weapon)
```

### **💀 DEATH & RETRY SYSTEM**

#### **Adaptive Difficulty**
```gdscript
# BossAdaptiveDifficulty.gd
var death_count = 0
var learning_assists = {
    "attack_telegraphs": false,
    "pattern_hints": false,
    "damage_reduction": 0.0,
    "extra_health": 0
}

func on_boss_death():
    death_count += 1
    
    # Gradual assistance after multiple deaths
    match death_count:
        3:
            learning_assists.attack_telegraphs = true
            show_hint("Boss attacks now have longer telegraphs")
            
        5:
            learning_assists.pattern_hints = true  
            show_hint("Attack pattern indicators now visible")
            
        8:
            learning_assists.damage_reduction = 0.15  # 15% less damage taken
            show_hint("Divine protection reduces damage taken")
            
        12:
            learning_assists.extra_health = 50  # +50 HP for boss fight only
            show_hint("Ancient vitality strengthens you")

func reset_assists_on_victory():
    # Remove assists for future runs to maintain challenge
    death_count = 0
    learning_assists = {"attack_telegraphs": false, "pattern_hints": false, "damage_reduction": 0.0, "extra_health": 0}
```

#### **Checkpoint System**
```gdscript
func setup_boss_checkpoints():
    # Save progress at phase transitions
    var checkpoints = {
        "phase_1_start": {"hp": 1200, "phase": 1},
        "phase_2_start": {"hp": 800, "phase": 2}, 
        "phase_3_start": {"hp": 400, "phase": 3}
    }
    
    # Player can choose to restart from checkpoint after 3+ deaths
    if death_count >= 3:
        offer_checkpoint_restart()
```

### **🔗 INTEGRATION REQUIREMENTS**

#### **GameManager Integration**
```gdscript
# In GameManager.gd
func setup_boss_integration():
    # Connect boss to all game systems
    current_boss.phase_changed.connect(_on_boss_phase_changed)
    current_boss.dialogue_triggered.connect(_on_boss_dialogue)
    current_boss.moral_choice_available.connect(_show_moral_choice_ui)
    current_boss.defeated.connect(_on_boss_defeated)
    
    # Connect to camera system
    current_boss.dramatic_moment.connect(camera_controller.boss_focus)
    current_boss.arena_destruction.connect(camera_controller.shake.bind(10.0))
    
    print("✅ Boss battle integrated with main game loop")

func _on_boss_defeated(moral_choice: MoralPath):
    # Handle victory flow
    distribute_boss_rewards(moral_choice)
    unlock_story_progression()
    save_moral_choice(moral_choice)
    transition_to_victory_screen()
```

#### **UI Integration**
```gdscript
# BossUI.gd
func setup_boss_interface():
    # Multi-segment health bar
    boss_health_bar.setup_segments(3)  # 3 phases
    boss_health_bar.set_boss_name("Khaemwaset the Fallen")
    
    # Phase indicators
    phase_indicator.setup_phases(["Faithful", "Corrupted", "Desperate"])
    
    # Moral choice UI
    moral_choice_panel.setup_choices([
        {"text": "Show Mercy", "icon": "mercy", "color": Color.BLUE},
        {"text": "Demand Justice", "icon": "justice", "color": Color.GOLD}, 
        {"text": "Take Vengeance", "icon": "vengeance", "color": Color.RED}
    ])
```

### **📋 TESTING CHECKLIST**

#### **Combat Mechanics:**
- [ ] All three phases have distinct attack patterns
- [ ] Phase transitions are smooth and dramatic
- [ ] Arena mechanics work correctly in all phases  
- [ ] Boss can be defeated with all weapon types
- [ ] Adaptive difficulty assists function properly

#### **Narrative Integration:**
- [ ] Dialogue triggers at correct moments during combat
- [ ] Moral choices affect boss behavior and rewards
- [ ] Story revelations are clear and impactful
- [ ] Character relationships reflect boss interaction

#### **Technical Integration:**
- [ ] Boss integrates with GameManager without conflicts
- [ ] Victory/defeat flows work correctly
- [ ] Save/load handles boss state properly
- [ ] Performance maintains 60fps during complex attacks
- [ ] UI updates reflect boss state changes in real-time

### **🎯 SUCCESS METRICS**

**Combat Experience:**
- **Fight Duration:** 4-6 minutes average (challenging but not tedious)
- **Death Rate:** 60-70% failure rate on first attempt (difficult but learnable)
- **Learning Curve:** Clear improvement visible after 3-5 attempts
- **Replay Value:** Fight remains engaging on subsequent runs

**Narrative Impact:**
- **Story Comprehension:** Players understand basic conspiracy plot
- **Emotional Investment:** Boss feels like meaningful character, not just obstacle
- **Moral Choice Distribution:** Roughly 50/30/20% split (mercy/justice/vengeance)  
- **Consequence Understanding:** Players see choice impacts in hub world

**Technical Performance:**
- **Zero game-breaking bugs** during boss encounter
- **Smooth transitions** between all phases
- **Consistent 60fps** during most complex attack patterns
- **Complete integration** with existing game systems

---

## 🎯 **PHASE 1 SUMMARY: CORE MVP COMPLETE**

By end of Sprint 12, you will have:

### **✅ Complete Foundation Systems:**
- **11 enemy types** with coordinated AI
- **5 Egyptian weapons** with unique movesets and mastery
- **50+ boons** with synergies, duo/legendary variants
- **1 complete boss fight** with narrative integration

### **🎮 Playable Game Loop:**
- Start run → Fight through procedural rooms → Collect boons → Face boss → Make moral choice → Progress story

### **📊 Success Criteria Met:**
- **60 FPS performance** maintained with full systems
- **Death feels meaningful** through narrative integration
- **100+ viable builds** through boon variety
- **Story progression** tied to gameplay choices

### **🚀 Ready for Phase 2:**
Phase 1 delivers a **complete, playable Hades clone** with Egyptian theming. Phase 2 will add the hub world, meta-progression, and second biome to create the full game experience.

**This is your MVP - everything after this is enhancement and content expansion.**