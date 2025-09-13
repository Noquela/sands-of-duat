# EnemyManager.gd - Central enemy management system
# SPRINT 9: Enemy Expansion & AI Enhancement
# CRITICAL: All enemy systems MUST integrate through GameManager

extends Node
class_name EnemyManager

signal enemy_spawned(enemy: Node, enemy_type: String)
signal enemy_died(enemy: Node, enemy_type: String)
signal room_cleared()
signal coordinated_attack_triggered(attack_type: String)

# Enemy type registry
var enemy_types: Dictionary = {}
var active_enemies: Array[Node] = []
var enemy_spawns_remaining: int = 0
var is_room_cleared: bool = false

# Coordinated AI system
var ai_coordinator: Node
var spawn_manager: Node

# Performance tracking
var max_enemies_per_room: int = 12  # Performance target
var current_enemy_count: int = 0
var performance_monitor: bool = true

func _ready():
    # CRITICAL: Register with GameManager - use get_node to find it
    var game_manager = get_node_or_null("/root/GameManager")
    if not game_manager:
        # Try alternative paths
        game_manager = get_tree().get_first_node_in_group("game_manager")
        if not game_manager:
            push_warning("EnemyManager: GameManager não encontrado - continuando sem integração")
            # Don't return, continue with initialization
    
    # Initialize subsystems
    var ai_coordinator_script = load("res://scripts/enemies/EnemyAICoordinator.gd")
    var spawn_manager_script = load("res://scripts/enemies/EnemySpawnManager.gd")
    
    ai_coordinator = ai_coordinator_script.new()
    spawn_manager = spawn_manager_script.new()
    
    add_child(ai_coordinator)
    add_child(spawn_manager)
    
    # Setup enemy type registry
    _initialize_enemy_types()
    
    # Connect to GameManager
    if game_manager:
        if game_manager.has_method("register_system"):
            game_manager.register_system(self)
        _connect_to_game_signals(game_manager)
    
    print("🔥 EnemyManager: Sistema iniciado com %d tipos de inimigos" % enemy_types.size())

func _connect_to_game_signals(game_manager: Node):
    # OBRIGATÓRIO: Connect to relevant GameManager signals
    if game_manager.has_signal("room_entered"):
        game_manager.room_entered.connect(_on_room_entered)
    
    # TODO: Connect room_cleared signal when needed
    # if game_manager.has_signal("room_cleared"):
    #     game_manager.room_cleared.connect(_on_room_cleared)
    
    # Connect to combat system
    if game_manager.has_method("get") and game_manager.get("combat_system"):
        var combat_system = game_manager.get("combat_system")
        if combat_system and combat_system.has_signal("damage_dealt"):
            combat_system.damage_dealt.connect(_on_damage_dealt_to_enemy)

func _initialize_enemy_types():
    """Initialize all 11 enemy types (3 existing + 8 new)"""
    
    # Existing enemies (from Sprints 1-8)
    enemy_types["basic_warrior"] = {
        "scene_path": "res://scenes/enemies/BasicEnemy.tscn",
        "spawn_weight": 100,
        "ai_role": "melee_aggressive",
        "coordination_priority": "low"
    }
    
    # NEW ENEMIES - SPRINT 9 (8 additions)
    
    # 1. Pharaoh Mage (Caster Teleportante)
    enemy_types["pharaoh_mage"] = {
        "scene_path": "res://scenes/enemies/PharaohMage.tscn",
        "spawn_weight": 15,
        "ai_role": "caster_teleport",
        "coordination_priority": "high",
        "abilities": ["dark_bolt", "teleport_strike", "summon_minions"],
        "spawn_conditions": ["room_size_large", "player_level_3+"]
    }
    
    # 2. Anubis Guard (Tank Protetor) 
    enemy_types["anubis_guard"] = {
        "scene_path": "res://scenes/enemies/AnubisGuard.tscn",
        "spawn_weight": 25,
        "ai_role": "tank_protector", 
        "coordination_priority": "high",
        "abilities": ["shield_wall", "protective_aura", "taunt_roar"],
        "synergy_with": ["pharaoh_mage", "tomb_archer"]
    }
    
    # 3. Scarab Swarm (Fast Flanker)
    enemy_types["scarab_swarm"] = {
        "scene_path": "res://scenes/enemies/ScarabSwarm.tscn",
        "spawn_weight": 40,
        "ai_role": "fast_flanker",
        "coordination_priority": "medium", 
        "abilities": ["swarm_rush", "poison_bite", "split_on_death"],
        "pack_size": 3  # Always spawns in groups
    }
    
    # 4. Tomb Archer (Ranged Support)
    enemy_types["tomb_archer"] = {
        "scene_path": "res://scenes/enemies/TombArcher.tscn", 
        "spawn_weight": 30,
        "ai_role": "ranged_support",
        "coordination_priority": "medium",
        "abilities": ["precision_shot", "volley_rain", "explosive_arrow"],
        "positioning": "high_ground_preferred"
    }
    
    # 5. Shadow Stalker (Stealth Assassin)
    enemy_types["shadow_stalker"] = {
        "scene_path": "res://scenes/enemies/ShadowStalker.tscn",
        "spawn_weight": 20,
        "ai_role": "stealth_assassin", 
        "coordination_priority": "high",
        "abilities": ["shadow_cloak", "backstab", "shadow_step"],
        "spawn_conditions": ["player_alone", "room_has_shadows"]
    }
    
    # 6. Desert Elemental (Area Control)
    enemy_types["desert_elemental"] = {
        "scene_path": "res://scenes/enemies/DesertElemental.tscn",
        "spawn_weight": 15,
        "ai_role": "area_controller",
        "coordination_priority": "high", 
        "abilities": ["sand_trap", "dust_storm", "earth_spike"],
        "territory_size": 5.0  # Controls 5m radius
    }
    
    # 7. Cursed Priest (Debuffer Support)
    enemy_types["cursed_priest"] = {
        "scene_path": "res://scenes/enemies/CursedPriest.tscn",
        "spawn_weight": 12,
        "ai_role": "debuffer_support",
        "coordination_priority": "high",
        "abilities": ["weakness_curse", "heal_allies", "dispel_boons"],
        "support_radius": 8.0
    }
    
    # 8. Bone Construct (Heavy Bruiser)
    enemy_types["bone_construct"] = {
        "scene_path": "res://scenes/enemies/BoneConstruct.tscn", 
        "spawn_weight": 20,
        "ai_role": "heavy_bruiser",
        "coordination_priority": "medium",
        "abilities": ["bone_slam", "regenerate", "rage_mode"], 
        "size_category": "large"
    }

func spawn_enemy(enemy_type: String, position: Vector3, level: int = 1) -> Node:
    """Spawn a single enemy of specified type"""
    
    if not enemy_type in enemy_types:
        push_error("Enemy type não encontrado: " + enemy_type)
        return null
    
    # Performance check
    if current_enemy_count >= max_enemies_per_room:
        push_warning("Max enemy count reached, skipping spawn")
        return null
    
    var enemy_data = enemy_types[enemy_type]
    var enemy_scene = load(enemy_data.scene_path)
    
    if not enemy_scene:
        push_error("Failed to load enemy scene: " + enemy_data.scene_path)
        return null
    
    var enemy = enemy_scene.instantiate()
    enemy.global_position = position
    enemy.name = enemy_type + "_" + str(current_enemy_count)
    
    # Add to scene
    get_tree().current_scene.add_child(enemy)
    enemy.add_to_group("enemies")
    
    # Configure enemy
    _configure_enemy(enemy, enemy_type, enemy_data, level)
    
    # Register with systems
    active_enemies.append(enemy)
    current_enemy_count += 1
    
    # Connect death signal
    if enemy.has_signal("enemy_died"):
        enemy.enemy_died.connect(_on_enemy_died)
    
    # Register with AI coordinator
    ai_coordinator.register_enemy(enemy, enemy_data)
    
    # Emit signal
    enemy_spawned.emit(enemy, enemy_type)
    
    print("👹 Spawned %s at %s (Total: %d)" % [enemy_type, position, current_enemy_count])
    
    return enemy

func _configure_enemy(enemy: Node, type: String, data: Dictionary, level: int):
    """Configure enemy with type-specific properties"""
    
    # Set level scaling
    if enemy.has_method("set_level"):
        enemy.set_level(level)
    
    # Set AI role
    if enemy.has_method("set_ai_role"):
        enemy.set_ai_role(data.ai_role)
    
    # Set coordination priority  
    if enemy.has_method("set_coordination_priority"):
        enemy.set_coordination_priority(data.coordination_priority)
    
    # Configure abilities
    if "abilities" in data and enemy.has_method("set_abilities"):
        enemy.set_abilities(data.abilities)
    
    # Special configurations per type
    match type:
        "scarab_swarm":
            if "pack_size" in data:
                _spawn_pack_members(enemy, data.pack_size - 1, type, level)
        
        "desert_elemental":
            if "territory_size" in data:
                enemy.set_territory_radius(data.territory_size)
        
        "cursed_priest":
            if "support_radius" in data:
                enemy.set_support_radius(data.support_radius)

func _spawn_pack_members(leader: Node, count: int, type: String, level: int):
    """Spawn additional pack members for swarm enemies"""
    
    var leader_pos = leader.global_position
    
    for i in range(count):
        var offset = Vector3(
            randf_range(-2.0, 2.0),
            0.0, 
            randf_range(-2.0, 2.0)
        )
        
        var pack_member = spawn_enemy(type, leader_pos + offset, level)
        if pack_member and pack_member.has_method("set_pack_leader"):
            pack_member.set_pack_leader(leader)

func _on_enemy_died(enemy: Node):
    """Handle enemy death"""
    
    if enemy in active_enemies:
        active_enemies.erase(enemy)
        current_enemy_count -= 1
        
        # Get enemy type
        var enemy_type = _get_enemy_type_from_node(enemy)
        
        # Unregister from AI coordinator
        ai_coordinator.unregister_enemy(enemy)
        
        # Emit signal
        enemy_died.emit(enemy, enemy_type)
        
        print("💀 Enemy died: %s (Remaining: %d)" % [enemy_type, current_enemy_count])
        
        # Check if room is cleared
        if current_enemy_count <= 0 and enemy_spawns_remaining <= 0:
            _trigger_room_cleared()

func _trigger_room_cleared():
    """Trigger room cleared state"""
    if not is_room_cleared:
        is_room_cleared = true
        room_cleared.emit()
        
        # Notify GameManager
        var game_manager = get_node_or_null("/root/GameManager")
        if game_manager and game_manager.has_method("_on_room_cleared"):
            game_manager._on_room_cleared()
        
        print("🏆 Room cleared! All enemies defeated")

func _on_room_entered(room_type: String, room_data: Dictionary):
    """Handle room entry - setup enemies for new room"""
    
    # Reset room state
    _reset_room_state()
    
    # Generate enemy layout for room
    spawn_manager.generate_room_enemies(room_type, room_data, self)

func _reset_room_state():
    """Reset state for new room"""
    
    # Clear previous enemies
    for enemy in active_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    
    active_enemies.clear()
    current_enemy_count = 0
    enemy_spawns_remaining = 0
    is_room_cleared = false
    
    # Reset AI coordinator
    ai_coordinator.reset_for_new_room()

func _get_enemy_type_from_node(enemy: Node) -> String:
    """Get enemy type from node name"""
    var name_parts = enemy.name.split("_")
    if name_parts.size() >= 2:
        # Remove the number suffix
        name_parts.pop_back()
        return "_".join(name_parts)
    
    return "unknown"

func _on_damage_dealt_to_enemy(damage: float, target: Node, source: Node):
    """Handle damage dealt to enemies for AI coordination"""
    
    if target in active_enemies:
        # Notify AI coordinator about damage for reaction
        ai_coordinator.notify_enemy_damaged(target, damage, source)

# OBRIGATÓRIO: Performance validation
func get_performance_metrics() -> Dictionary:
    return {
        "system_name": "EnemyManager",
        "active_enemies": current_enemy_count,
        "max_enemies": max_enemies_per_room,
        "memory_usage": _calculate_memory_usage(),
        "ai_coordinator_active": ai_coordinator != null,
        "spawn_manager_active": spawn_manager != null,
        "performance_warning": current_enemy_count > max_enemies_per_room * 0.8
    }

func _calculate_memory_usage() -> int:
    var base_memory = 1024  # Base system memory in bytes
    var per_enemy_memory = 256  # Estimated memory per enemy
    
    return base_memory + (current_enemy_count * per_enemy_memory)

# Method for GameManager integration
func _managed_update(delta: float):
    """Called by GameManager each frame for performance tracking"""
    if performance_monitor and current_enemy_count > max_enemies_per_room * 0.9:
        push_warning("EnemyManager: Approaching max enemy limit")