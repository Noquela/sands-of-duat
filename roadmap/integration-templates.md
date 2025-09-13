# 🔧 INTEGRATION TEMPLATES - Claude Code Sessions

## 📋 **OVERVIEW**

Este arquivo contém templates específicos para Claude Code que garantem integração adequada entre sprints e sistemas. Cada template inclui checklists obrigatórios, código de teste e critérios de aceitação.

**REGRA CRÍTICA:** Nenhum sprint é considerado completo sem seguir os templates de integração correspondentes.

---

## 🎯 **TEMPLATE GERAL - Início de Sessão Claude Code**

### **Pre-Session Checklist**
```markdown
- [ ] Leia o roadmap/README.md para contexto geral do projeto
- [ ] Identifique o sprint atual em desenvolvimento
- [ ] Verifique o arquivo de sprint específico (ex: sprints-09-12-core-mvp.md)
- [ ] Execute `godot --version` para confirmar Godot 4.4.1+
- [ ] Execute `git status` para verificar estado do repositório
- [ ] Execute `dir scenes` para verificar estrutura de scenes existentes
```

### **Padrão de Integração Obrigatório**
```gdscript
# SEMPRE adicione ao final de qualquer novo sistema:
extends Node
class_name [SystemName]

# Integration checkpoint
func _ready():
    if not GameManager:
        push_error("[SystemName]: GameManager não encontrado - integração falhou")
        return
    
    # Register with GameManager
    GameManager.register_system(self)
    
    # Connect to required signals
    _connect_to_game_signals()
    
    # Validate dependencies
    _validate_system_dependencies()

func _connect_to_game_signals():
    # OBRIGATÓRIO: Connect to relevant GameManager signals
    pass

func _validate_system_dependencies():
    # OBRIGATÓRIO: Validate all required dependencies exist
    pass
```

### **Performance Validation Required**
```gdscript
# SEMPRE adicione método de performance check:
func get_performance_metrics() -> Dictionary:
    return {
        "system_name": name,
        "memory_usage": _get_memory_usage(),
        "cpu_time": _get_cpu_time(),
        "active_objects": _get_active_object_count(),
        "last_update_time": _get_last_update_time()
    }
```

---

## ⚔️ **TEMPLATE: COMBAT SYSTEM INTEGRATION**

### **Pre-Desenvolvimento**
```bash
# Execute SEMPRE antes de trabalhar em combat:
cd "C:\Users\Bruno\Documents\Sand of Duat"
godot --headless --script-mode res://scripts/tests/ValidateCombatSystems.gd
```

### **Combat System Checklist**
```markdown
- [ ] Sistema integra com GameManager.damage_calculator
- [ ] Arma atual obtida via GameManager.get_current_weapon()
- [ ] Dano aplicado via GameManager.apply_damage(target, amount, source)
- [ ] Eventos de combate emitem signals para CombatJuiceManager
- [ ] Sistema responde a GameManager.player_died
- [ ] Performance teste: 60 FPS com 8+ inimigos simultâneos
```

### **Template de Weapon System**
```gdscript
# Template obrigatório para novas armas
extends Weapon
class_name [WeaponName]

@export var base_damage: float = 50.0
@export var attack_speed: float = 1.0
@export var special_cooldown: float = 3.0

func _ready():
    super._ready()
    # CRITICAL: Validate weapon integration
    if not GameManager.weapon_system:
        push_error("WeaponSystem não encontrado")
        return
    
    # Register weapon
    GameManager.weapon_system.register_weapon(self)

func perform_attack(target: Node3D) -> bool:
    if not can_attack():
        return false
    
    # OBRIGATÓRIO: Use GameManager damage system
    var damage = GameManager.calculate_damage(base_damage, self)
    var damage_dealt = GameManager.apply_damage(target, damage, self)
    
    # OBRIGATÓRIO: Trigger juice effects
    CombatJuiceManager.trigger_hit_effects(damage_dealt, global_position, false)
    
    return true

func perform_special_attack() -> bool:
    if not can_special_attack():
        return false
    
    # Implementation specific to weapon type
    _execute_special_attack()
    
    # OBRIGATÓRIO: Reset cooldown via GameManager
    GameManager.set_special_cooldown(special_cooldown)
    
    return true

# OBRIGATÓRIO: Performance validation
func _validate_performance():
    assert(attack_speed >= 0.5, "Attack speed too fast - performance risk")
    assert(base_damage <= 200.0, "Base damage too high - balance risk")
```

---

## 🎭 **TEMPLATE: NPC & DIALOGUE INTEGRATION**

### **Dialogue System Checklist**
```markdown
- [ ] NPC integra com RelationshipTracker
- [ ] Diálogos reagem a GameManager.get_moral_alignment()
- [ ] Choices afetam NarrativePersistence.moral_decision_history
- [ ] Sistema suporta contextual dialogue baseado em run history
- [ ] Performance: Dialogue loading <1 segundo
```

### **Template de NPC**
```gdscript
extends Area3D
class_name HubNPC

@export var npc_id: String
@export var base_relationship: int = 0
@export var dialogue_tree_resource: Resource

signal interaction_started(npc_id: String)
signal relationship_changed(npc_id: String, new_level: int)

func _ready():
    # CRITICAL: Validate NPC integration
    if not RelationshipTracker:
        push_error("RelationshipTracker não encontrado")
        return
    
    if not DialogueSystem:
        push_error("DialogueSystem não encontrado") 
        return
    
    # Initialize relationship
    RelationshipTracker.initialize_relationship(npc_id)
    
    # Connect signals
    body_entered.connect(_on_player_entered)
    DialogueSystem.dialogue_completed.connect(_on_dialogue_completed)

func _on_player_entered(body: Node3D):
    if body.is_in_group("player"):
        interaction_started.emit(npc_id)
        _start_contextual_dialogue()

func _start_contextual_dialogue():
    var context = _build_dialogue_context()
    DialogueSystem.start_dialogue(npc_id, context)

func _build_dialogue_context() -> Dictionary:
    # OBRIGATÓRIO: Use GameManager para contexto
    return {
        "moral_alignment": GameManager.get_moral_alignment(),
        "relationship_level": RelationshipTracker.get_level(npc_id),
        "story_progress": GameManager.story_milestones_reached,
        "recent_run_stats": GameManager.get_last_run_stats(),
        "deaths_count": GameManager.total_deaths,
        "weapons_mastered": GameManager.weapons_mastered
    }

func _on_dialogue_completed(dialogue_id: String, choices_made: Array):
    if dialogue_id.begins_with(npc_id):
        _process_dialogue_consequences(choices_made)

func _process_dialogue_consequences(choices: Array):
    for choice in choices:
        if "relationship_change" in choice:
            var change = choice.relationship_change
            RelationshipTracker.modify_relationship(npc_id, change)
            relationship_changed.emit(npc_id, RelationshipTracker.get_level(npc_id))
        
        if "moral_impact" in choice:
            GameManager.modify_moral_alignment(choice.moral_impact)
        
        if "unlock_content" in choice:
            GameManager.unlock_content(choice.unlock_content)
```

---

## 🏛️ **TEMPLATE: BIOME & ROOM INTEGRATION**

### **Biome System Checklist**
```markdown
- [ ] Biome herda de BiomeManager base
- [ ] Room generation usa RoomData consistency
- [ ] Environmental effects integram com GameManager.environmental_modifiers
- [ ] Transições entre rooms mantém player state
- [ ] Performance: Room generation <500ms
- [ ] Integration: Funciona com save/load system
```

### **Template de Biome**
```gdscript
extends BiomeManager
class_name [BiomeName]Manager

@export var biome_id: String
@export var room_templates: Array[PackedScene] = []
@export var special_mechanics: Dictionary = {}

func _ready():
    super._ready()
    
    # CRITICAL: Validate biome integration
    if not SceneManager:
        push_error("SceneManager não encontrado")
        return
    
    # Register biome
    GameManager.register_biome(biome_id, self)
    
    # Setup biome-specific mechanics
    _initialize_biome_mechanics()

func _initialize_biome_mechanics():
    # OBRIGATÓRIO: Configure environmental modifiers
    GameManager.environmental_modifiers.clear()
    GameManager.environmental_modifiers.merge(special_mechanics)
    
    # Setup biome-specific audio
    AudioManager.set_biome_ambience(biome_id)
    
    # Configure enemy spawn rules
    EnemyManager.set_biome_spawn_rules(biome_id, _get_spawn_rules())

func generate_room() -> RoomData:
    var room_data = RoomData.new()
    room_data.biome_id = biome_id
    
    # OBRIGATÓRIO: Use consistent room structure
    room_data.room_type = _determine_room_type()
    room_data.difficulty_level = GameManager.get_current_difficulty()
    room_data.environmental_modifiers = special_mechanics.duplicate()
    
    # Generate enemies based on difficulty
    room_data.enemy_spawns = _generate_enemy_spawns(room_data.difficulty_level)
    
    # Add biome-specific rewards
    room_data.reward_pools = _get_biome_reward_pools()
    
    return room_data

func _determine_room_type() -> String:
    var room_types = ["combat", "elite", "treasure", "shop", "story"]
    var weights = _get_room_type_weights()
    
    return GameManager.weighted_random_choice(room_types, weights)

# OBRIGATÓRIO: Performance monitoring
func _validate_room_performance(room_data: RoomData) -> bool:
    var enemy_count = room_data.enemy_spawns.size()
    var hazard_count = room_data.environmental_hazards.size()
    
    # Performance limits
    if enemy_count > 12:
        push_warning("Room has too many enemies: " + str(enemy_count))
        return false
    
    if hazard_count > 5:
        push_warning("Room has too many hazards: " + str(hazard_count))
        return false
    
    return true
```

---

## 🔄 **TEMPLATE: SAVE/LOAD INTEGRATION**

### **Save System Checklist**
```markdown
- [ ] Sistema implementa SaveableResource interface
- [ ] Todos os estados persistentes incluídos em save_data
- [ ] Load system restaura exatamente o estado anterior
- [ ] Save operation nunca falha silenciosamente
- [ ] Backward compatibility mantida entre versões
```

### **Template de Saveable System**
```gdscript
extends Node
class_name [SystemName]
implements SaveableResource

var save_version: String = "1.0"

func get_save_data() -> Dictionary:
    # OBRIGATÓRIO: Include version for compatibility
    var save_data = {
        "save_version": save_version,
        "system_id": name
    }
    
    # Add all persistent state
    save_data.merge(_collect_persistent_state())
    
    return save_data

func load_save_data(data: Dictionary) -> bool:
    # CRÍTICO: Validate data before loading
    if not _validate_save_data(data):
        push_error("Invalid save data for " + name)
        return false
    
    # Handle version compatibility
    if not _handle_version_compatibility(data):
        push_error("Save version compatibility failed")
        return false
    
    # Load persistent state
    _restore_persistent_state(data)
    
    # Validate loaded state
    if not _validate_loaded_state():
        push_error("Loaded state validation failed")
        return false
    
    return true

func _collect_persistent_state() -> Dictionary:
    # IMPLEMENTAR: Collect all state that needs persistence
    return {}

func _restore_persistent_state(data: Dictionary):
    # IMPLEMENTAR: Restore all persistent state
    pass

func _validate_save_data(data: Dictionary) -> bool:
    # OBRIGATÓRIO: Validate save data structure
    if not "save_version" in data:
        return false
    
    if not "system_id" in data:
        return false
    
    return true

func _handle_version_compatibility(data: Dictionary) -> bool:
    var data_version = data.save_version
    
    # Handle version differences
    match data_version:
        "1.0":
            return true  # Current version
        _:
            push_warning("Unknown save version: " + data_version)
            return false

func _validate_loaded_state() -> bool:
    # OBRIGATÓRIO: Validate that loaded state is consistent
    return true
```

---

## 🎵 **TEMPLATE: AUDIO SYSTEM INTEGRATION**

### **Audio Integration Checklist**
```markdown
- [ ] Sistema usa AudioManager para todos os sons
- [ ] Audio pools configurados para performance
- [ ] Sistema suporta volume settings do player
- [ ] Sounds positioned corretamente em 3D space
- [ ] Performance: <50ms para play qualquer som
```

### **Template de Audio Integration**
```gdscript
extends Node
class_name [AudioSystemName]

var audio_sources: Array[AudioStreamPlayer3D] = []
var audio_pools: Dictionary = {}

func _ready():
    # CRÍTICO: Validate audio integration
    if not AudioManager:
        push_error("AudioManager não encontrado")
        return
    
    # Setup audio pools for performance
    _initialize_audio_pools()
    
    # Connect to audio settings changes
    AudioManager.volume_changed.connect(_on_volume_changed)

func _initialize_audio_pools():
    # OBRIGATÓRIO: Use pooling for frequently played sounds
    audio_pools["combat_sounds"] = AudioPool.new(10)
    audio_pools["ui_sounds"] = AudioPool.new(5)
    audio_pools["ambient_sounds"] = AudioPool.new(3)

func play_sound(sound_id: String, position: Vector3 = Vector3.ZERO) -> bool:
    # OBRIGATÓRIO: Use AudioManager
    return AudioManager.play_sound(sound_id, position)

func play_sound_pooled(sound_id: String, pool_name: String, position: Vector3 = Vector3.ZERO) -> bool:
    if not pool_name in audio_pools:
        push_error("Audio pool não encontrado: " + pool_name)
        return false
    
    var audio_source = audio_pools[pool_name].get_source()
    if not audio_source:
        return false
    
    audio_source.stream = AudioManager.get_audio_resource(sound_id)
    audio_source.global_position = position
    audio_source.play()
    
    return true

func _on_volume_changed(volume_type: String, new_volume: float):
    # OBRIGATÓRIO: Respond to volume changes
    match volume_type:
        "master":
            _update_all_audio_volumes(new_volume)
        "effects":
            _update_effects_volume(new_volume)
        "music":
            _update_music_volume(new_volume)
```

---

## 📊 **TEMPLATE: PERFORMANCE TESTING**

### **Performance Test Template**
```gdscript
# performance_test.gd - EXECUTAR após cada implementação
extends SceneTree

func _init():
    run_performance_tests()
    quit()

func run_performance_tests():
    print("=== PERFORMANCE TESTS ===")
    
    # Test 1: Combat with multiple enemies
    test_combat_performance()
    
    # Test 2: UI responsiveness
    test_ui_performance()
    
    # Test 3: Memory usage
    test_memory_performance()
    
    # Test 4: Save/Load speed
    test_save_load_performance()
    
    print("=== TESTS COMPLETE ===")

func test_combat_performance():
    print("Testing combat performance...")
    
    var start_time = Time.get_time_dict_from_system()
    
    # Simulate intense combat
    for i in range(100):
        GameManager.apply_damage(null, 50.0, "test")
        CombatJuiceManager.trigger_hit_effects(50.0, Vector3.ZERO, false)
    
    var end_time = Time.get_time_dict_from_system()
    var duration_ms = (end_time.minute * 60000 + end_time.second * 1000 + end_time.millisecond) - (start_time.minute * 60000 + start_time.second * 1000 + start_time.millisecond)
    
    print("Combat test: ", duration_ms, "ms")
    
    if duration_ms > 100:
        push_error("PERFORMANCE FAIL: Combat too slow")
    else:
        print("Combat performance: PASS")

func test_ui_performance():
    print("Testing UI performance...")
    
    # Test UI response time
    var ui_node = Control.new()
    
    var start_time = Time.get_time_dict_from_system()
    
    # Simulate UI updates
    for i in range(60):  # 60 frames worth
        ui_node.queue_redraw()
    
    var end_time = Time.get_time_dict_from_system()
    var duration_ms = (end_time.minute * 60000 + end_time.second * 1000 + end_time.millisecond) - (start_time.minute * 60000 + start_time.second * 1000 + start_time.millisecond)
    
    print("UI test: ", duration_ms, "ms")
    
    if duration_ms > 16:  # Should be <16ms for 60fps
        push_error("PERFORMANCE FAIL: UI too slow")
    else:
        print("UI performance: PASS")
    
    ui_node.free()
```

---

## 🔍 **TEMPLATE: DEBUG & TESTING**

### **Debug Integration Template**
```gdscript
# debug_integration.gd - INCLUIR em todos os sistemas principais
extends Node
class_name DebugIntegration

var debug_enabled: bool = false
var performance_monitor: PerformanceMonitor

func _ready():
    # OBRIGATÓRIO: Setup debug only in debug builds
    if OS.is_debug_build():
        _setup_debug_features()

func _setup_debug_features():
    debug_enabled = true
    performance_monitor = PerformanceMonitor.new()
    add_child(performance_monitor)
    
    # Debug input handling
    Input.key_pressed.connect(_handle_debug_input)

func _handle_debug_input(event: InputEvent):
    if not debug_enabled:
        return
    
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F1:
                _toggle_debug_overlay()
            KEY_F2:
                _dump_system_state()
            KEY_F3:
                _force_performance_test()

func _toggle_debug_overlay():
    # Show/hide debug information
    pass

func _dump_system_state():
    var state = {
        "system_name": name,
        "performance_metrics": performance_monitor.get_metrics(),
        "memory_usage": OS.get_static_memory_usage_by_type(),
        "active_nodes": get_tree().get_node_count()
    }
    
    print("=== SYSTEM STATE DUMP ===")
    print(JSON.stringify(state, "\t"))
    print("=== END DUMP ===")

func _force_performance_test():
    # Run performance test immediately
    performance_monitor.run_stress_test()
```

---

## 🚨 **FAILURE CONDITIONS - Sprint Auto-Rejection**

### **Automatic Sprint Failure Triggers**
```markdown
CRITICAL: Um sprint será AUTOMATICAMENTE rejeitado se:

- [ ] Qualquer sistema não integra com GameManager
- [ ] Performance drops below 45 FPS in any scenario
- [ ] Memory leaks detected (>50MB growth in 10 minutes)
- [ ] Save/Load system fails any test case
- [ ] UI response time >100ms for any interaction
- [ ] Any system crashes during normal operation
- [ ] Integration tests fail >20% of test cases
```

### **Pre-Sprint Validation Script**
```bash
#!/bin/bash
# validate_sprint_ready.sh - EXECUTAR antes de marcar sprint como completo

echo "=== SPRINT VALIDATION ==="

# Test 1: Run game and verify no crashes
godot --headless --quit-after 30 res://scenes/MainGameScene.tscn
if [ $? -ne 0 ]; then
    echo "FAIL: Game crashes during startup"
    exit 1
fi

# Test 2: Run performance tests
godot --headless --script res://scripts/performance_test.gd
if [ $? -ne 0 ]; then
    echo "FAIL: Performance tests failed"
    exit 1
fi

# Test 3: Run integration tests
godot --headless --script res://scripts/integration_test.gd
if [ $? -ne 0 ]; then
    echo "FAIL: Integration tests failed"
    exit 1
fi

echo "=== ALL VALIDATIONS PASSED ==="
echo "Sprint ready for completion"
```

---

## 📁 **TEMPLATE FILES LOCATION**

```
roadmap/templates/
├── combat_system_template.gd
├── npc_dialogue_template.gd  
├── biome_manager_template.gd
├── saveable_resource_template.gd
├── audio_integration_template.gd
├── performance_test_template.gd
├── debug_integration_template.gd
└── validation_scripts/
    ├── validate_sprint_ready.sh
    ├── performance_stress_test.gd
    └── integration_smoke_test.gd
```

---

## 🎯 **SPRINT COMPLETION CRITERIA**

### **Para Marcar Sprint como Completo:**

1. **Todos os templates aplicados** aos sistemas desenvolvidos
2. **Performance validation passed** (60 FPS target met)
3. **Integration tests passed** (95% success rate minimum)
4. **Memory validation passed** (no leaks detected)
5. **Save/Load tests passed** (100% reliability)
6. **Debug integration complete** (proper error handling)
7. **Documentation updated** (código comentado adequadamente)

### **Final Integration Checkpoint:**
```gdscript
# EXECUTAR antes de commit final do sprint
extends EditorScript

func _run():
    print("=== SPRINT COMPLETION VALIDATION ===")
    
    var validation_results = {}
    
    validation_results["performance"] = _validate_performance()
    validation_results["integration"] = _validate_integration()
    validation_results["memory"] = _validate_memory()
    validation_results["save_load"] = _validate_save_load()
    
    var all_passed = true
    for category in validation_results:
        if not validation_results[category]:
            all_passed = false
            print("FAIL: ", category)
        else:
            print("PASS: ", category)
    
    if all_passed:
        print("✅ SPRINT READY FOR COMPLETION")
    else:
        print("❌ SPRINT NOT READY - FIX ISSUES FIRST")
    
    print("=== VALIDATION COMPLETE ===")
```

---

*"Seguindo estes templates religiosamente, cada sprint será uma fundação sólida para o próximo, construindo Sands of Duat como uma obra de arte técnica e narrativa."*

**🔧 INTEGRATION TEMPLATES COMPLETE - READY FOR SYSTEMATIC DEVELOPMENT 🔧**