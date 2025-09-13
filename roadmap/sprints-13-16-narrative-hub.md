# 🏛️ FASE 2: NARRATIVE INTEGRATION - Sprints 13-16

## 📖 **VISÃO GERAL DA FASE**

**Objetivo Central:** Estabelecer o hub world, meta-progressão e sistemas narrativos que transformam Sands of Duat de um clone mecânico do Hades em uma experiência narrativa única egípcia.

**Filosofia:** Cada morte no Duat agora deve ter significado narrativo profundo. O Pool of Memories não é apenas um hub - é onde Khenti reconstrói sua identidade e relacionamentos através das memórias recuperadas.

**Success Criteria desta Fase:**
- Pool of Memories operacional com 8+ NPCs únicos
- Sistema de meta-progressão com 25+ upgrades permanentes  
- Diálogos dinâmicos baseados em run history e escolhas morais
- Segundo bioma (Rio de Fogo) completamente jogável
- Boss Sekhmet com narrativa multi-fase integrada

---

## 🏊‍♂️ **SPRINT 13: POOL OF MEMORIES HUB**

### **🎯 Objetivos Principais**
1. **Hub World Architecture:** Pool of Memories como centro narrativo
2. **NPC System:** 8 personagens principais com diálogos dinâmicos  
3. **Memory Collection:** Sistema de coleta e ativação de memórias
4. **Hub Navigation:** Movimentação fluida entre áreas temáticas
5. **Visual Identity:** Ambiente aquático/onírico consistente com mitologia

### **🏗️ Sistemas a Implementar**

#### **A. Pool of Memories Scene**
```gdscript
# HubManager.gd - Sistema central do hub
extends Node
class_name HubManager

signal memory_activated(memory_id: String)
signal npc_interaction_started(npc_name: String)
signal hub_area_changed(area_name: String)

@export var memory_pools: Array[MemoryPool] = []
@export var npcs: Array[HubNPC] = []
@export var hub_areas: Array[HubArea] = []

var unlocked_memories: Dictionary = {}
var npc_relationship_levels: Dictionary = {}
var current_run_context: Dictionary = {}

func _ready():
    GameManager.player_died.connect(_on_player_death)
    GameManager.run_completed.connect(_on_run_completed)
    _initialize_hub_areas()
    _spawn_npcs()

func _on_player_death():
    # Collect memories from completed run
    var new_memories = GameManager.get_run_memories()
    _process_new_memories(new_memories)
    _update_npc_relationships()
    
func _initialize_hub_areas():
    # 5 áreas temáticas do Pool of Memories
    var areas = [
        "Memory Pools", "Judgment Scales", "Anubis Shrine", 
        "Divine Council", "Departure Gates"
    ]
    for area_name in areas:
        var area = _create_hub_area(area_name)
        hub_areas.append(area)
```

#### **B. Memory System**
```gdscript
# MemorySystem.gd - Coleta e ativação de memórias
extends Node
class_name MemorySystem

enum MemoryType {
    COMBAT_EXCELLENCE,    # Combates sem dano
    MORAL_CHOICE,         # Decisões éticas importantes  
    DIVINE_ENCOUNTER,     # Interações com deuses
    BROTHER_REVELATION,   # Pistas sobre Khaemwaset
    NEFERTARI_BOND,      # Momentos com amada
    ROYAL_DUTY,          # Responsabilidades como príncipe
    DEATH_INSIGHT,       # Compreensão sobre própria morte
    JUSTICE_RESOLVE      # Determinação de vingança
}

@export var memory_database: Dictionary = {}
var collected_memories: Array[Memory] = []
var active_memory_buffs: Dictionary = {}

class Memory:
    var id: String
    var type: MemoryType
    var title: String
    var description: String
    var unlock_condition: String
    var gameplay_buff: Dictionary
    var dialogue_triggers: Array[String]
    var relationship_impacts: Dictionary
    
func collect_memory(memory_id: String, context: Dictionary):
    if memory_id in memory_database:
        var memory = memory_database[memory_id]
        collected_memories.append(memory)
        _apply_memory_effects(memory, context)
        _trigger_hub_responses(memory)
        
func _apply_memory_effects(memory: Memory, context: Dictionary):
    # Permanent upgrades baseados na memória
    match memory.type:
        MemoryType.COMBAT_EXCELLENCE:
            GameManager.permanent_stats.damage_multiplier += 0.05
        MemoryType.DIVINE_ENCOUNTER:
            GameManager.boon_chances.rare_chance += 0.1
        MemoryType.MORAL_CHOICE:
            GameManager.dialogue_options.moral_choices += 1
```

#### **C. NPC Dialogue System**
```gdscript
# HubNPC.gd - NPCs dinâmicos do hub
extends Area3D
class_name HubNPC

@export var npc_name: String
@export var base_dialogue_tree: DialogueTree
@export var relationship_level: int = 0
@export var memory_responses: Dictionary = {}
@export var run_context_responses: Dictionary = {}

var current_dialogue: DialogueNode
var available_topics: Array[String] = []

signal dialogue_completed(npc_name: String, choices_made: Array)

func interact():
    var dialogue_context = _build_dialogue_context()
    current_dialogue = _select_appropriate_dialogue(dialogue_context)
    DialogueUI.start_dialogue(current_dialogue, self)

func _build_dialogue_context() -> Dictionary:
    return {
        "relationship_level": relationship_level,
        "recent_memories": GameManager.get_recent_memories(5),
        "last_run_performance": GameManager.get_last_run_stats(),
        "moral_alignment": GameManager.player_moral_score,
        "story_progress": GameManager.story_milestones_reached,
        "deaths_count": GameManager.total_deaths,
        "weapons_mastered": GameManager.weapons_mastered,
        "gods_encountered": GameManager.gods_met
    }

func _select_appropriate_dialogue(context: Dictionary) -> DialogueNode:
    # AI dinâmica baseada no contexto do player
    var dialogue_options = []
    
    # Memórias recentes influenciam diálogo
    for memory in context.recent_memories:
        if memory.id in memory_responses:
            dialogue_options.append(memory_responses[memory.id])
    
    # Performance da run influencia tom
    if context.last_run_performance.rooms_cleared > 10:
        dialogue_options.append("impressed_by_progress")
    elif context.deaths_count > 50:
        dialogue_options.append("concerned_about_struggle")
    
    return _weighted_dialogue_selection(dialogue_options, context)
```

### **👥 NPCs do Pool of Memories**

1. **Anubis** - Guidance & Judgment
   - Explica mecânicas de morte/ressurreição
   - Oferece insights sobre justiça vs vingança
   - Upgrades relacionados a avaliação moral

2. **Ma'at** - Balance & Truth  
   - Responde baseada em escolhas morais do player
   - Sistema de balança: ações boas vs vinganças
   - Unlock de aspectos de arma baseado em alinhamento

3. **Nefertari (Memory Echo)** - Love & Motivation
   - Memórias românticas que fortalecem resolve
   - Diálogos emocionais sobre vida perdida
   - Buffs de motivação para runs difíceis

4. **Khaemwaset (Shadow)** - Guilt & Brotherly Bond
   - Aparece como memória distorcida do irmão
   - Diálogos sobre traição e razões do assassinato
   - Evolui conforme player descobre verdades

5. **Thoth** - Knowledge & Strategy
   - Análise estratégica de runs passadas
   - Unlock de combinações avançadas de boons
   - Database de inimigos e weaknesses descobertas

6. **Isis** - Magic & Healing
   - Upgrades de regeneração entre rooms
   - Ensina sobre magia egípcia e boons divinos
   - Motherly guidance durante momentos difíceis

7. **Ptah** - Creation & Craftsmanship  
   - Upgrades de armas e aspectos únicos
   - Memórias sobre criação e construção do Egito
   - Melhorias permanentes de equipamento

8. **Sobek** - Strength & Protection
   - Buffs de defesa e resistência
   - Memórias de batalhas passadas como príncipe
   - Treinamento de combate avançado

### **🔧 Integração Técnica Obrigatória**

```gdscript
# GameManager integration - Hub workflow
func transition_to_hub():
    # Called after every death
    var run_data = _compile_run_data()
    SceneManager.change_scene("res://scenes/hub/PoolOfMemories.tscn")
    
    # Wait for hub load
    await SceneManager.scene_loaded
    
    # Initialize hub with run context
    HubManager.initialize_post_run(run_data)
    
    # Activate relevant NPCs based on context
    HubManager.activate_contextual_npcs(run_data)
    
    # Show memory collection UI if new memories
    if run_data.new_memories.size() > 0:
        MemoryCollectionUI.show_memories(run_data.new_memories)

func start_new_run_from_hub():
    # Player chose to start new run
    var selected_loadout = HubManager.get_selected_loadout()
    var active_memory_buffs = MemorySystem.get_active_buffs()
    
    # Apply permanent upgrades
    GameManager.apply_hub_upgrades(active_memory_buffs)
    
    # Transition to first biome
    SceneManager.change_scene("res://scenes/biomes/SandsOfDuat.tscn")
```

---

## 📈 **SPRINT 14: META-PROGRESSION SYSTEM**

### **🎯 Objetivos Principais**
1. **Memory Upgrades:** 25+ upgrades permanentes baseados em memórias
2. **Progression Trees:** 5 árvores temáticas de crescimento
3. **Keepsake System:** Itens que alteram gameplay permanentemente  
4. **Milestone Rewards:** Achievements que desbloqueiam conteúdo
5. **Difficulty Scaling:** Heat system que aumenta challenge e rewards

### **🏗️ Sistema de Meta-Progressão**

#### **A. Memory Upgrade Trees**
```gdscript
# MetaProgressionSystem.gd
extends Node
class_name MetaProgressionSystem

enum ProgressionTree {
    ROYAL_HERITAGE,      # Upgrades de liderança e comando
    DIVINE_FAVOR,        # Boons e interações com deuses  
    COMBAT_MASTERY,      # Técnicas de combate avançadas
    SPIRITUAL_INSIGHT,   # Compreensão do Duat e morte
    BONDS_OF_LOVE       # Conexão com Nefertari e motivação
}

var upgrade_trees: Dictionary = {}
var spent_memory_points: Dictionary = {}
var unlocked_upgrades: Array[String] = []

func _ready():
    _initialize_upgrade_trees()
    
func _initialize_upgrade_trees():
    upgrade_trees[ProgressionTree.ROYAL_HERITAGE] = [
        {
            "id": "royal_authority",
            "name": "Autoridade Real",
            "description": "Inimigos têm 10% chance de hesitar antes de atacar",
            "cost": 3,
            "requirements": [],
            "effect": {"enemy_hesitation_chance": 0.1}
        },
        {
            "id": "strategic_mind", 
            "name": "Mente Estratégica",
            "description": "Vê próxima room no minimap",
            "cost": 5,
            "requirements": ["royal_authority"],
            "effect": {"minimap_preview": true}
        },
        {
            "id": "pharaoh_presence",
            "name": "Presença de Faraó", 
            "description": "Área de efeito de ataques +15%",
            "cost": 8,
            "requirements": ["strategic_mind"],
            "effect": {"aoe_radius_multiplier": 1.15}
        }
    ]
    
    upgrade_trees[ProgressionTree.DIVINE_FAVOR] = [
        {
            "id": "divine_recognition",
            "name": "Reconhecimento Divino",
            "description": "Primeira oferenda em runs sempre é Rare+",
            "cost": 4,
            "requirements": [],
            "effect": {"first_boon_rarity_boost": true}
        },
        {
            "id": "blessed_journey",
            "name": "Jornada Abençoada", 
            "description": "Começa runs com boon aleatório",
            "cost": 7,
            "requirements": ["divine_recognition"],
            "effect": {"starting_boon": true}
        }
    ]
```

#### **B. Keepsake System** 
```gdscript
# KeepsakeSystem.gd - Itens únicos que alteram gameplay
extends Node
class_name KeepsakeSystem

class Keepsake:
    var id: String
    var name: String
    var description: String
    var source_npc: String
    var unlock_condition: String
    var gameplay_effects: Dictionary
    var upgrade_levels: Array[Dictionary]
    var current_level: int = 0

var available_keepsakes: Dictionary = {}
var equipped_keepsake: Keepsake = null

func _initialize_keepsakes():
    # Anubis Keepsake
    available_keepsakes["anubis_scale"] = Keepsake.new()
    var anubis_scale = available_keepsakes["anubis_scale"]
    anubis_scale.id = "anubis_scale"
    anubis_scale.name = "Balança de Anubis"
    anubis_scale.description = "Primeiras 3 rooms: próximo boon é do Anubis"
    anubis_scale.source_npc = "Anubis"
    anubis_scale.unlock_condition = "Complete 5 runs with moral choices"
    anubis_scale.gameplay_effects = {"force_anubis_boons": 3}
    anubis_scale.upgrade_levels = [
        {"level": 1, "effect": "4 rooms garantidas"},
        {"level": 2, "effect": "5 rooms garantidas + boons são Rare+"},
        {"level": 3, "effect": "6 rooms + chance de Legendary Anubis"}
    ]
    
    # Nefertari Keepsake  
    available_keepsakes["nefertari_lotus"] = Keepsake.new()
    var lotus = available_keepsakes["nefertari_lotus"]
    lotus.id = "nefertari_lotus"
    lotus.name = "Lótus de Nefertari"
    lotus.description = "Regenera vida ao entrar em new room se HP < 50%"
    lotus.source_npc = "Nefertari"
    lotus.unlock_condition = "Unlock 10 romantic memories"
    lotus.gameplay_effects = {"auto_heal_threshold": 0.5, "heal_amount": 20}
    lotus.upgrade_levels = [
        {"level": 1, "effect": "Heal 25 HP"},
        {"level": 2, "effect": "Heal 30 HP + remove 1 status effect"},
        {"level": 3, "effect": "Heal 35 HP + temporary damage boost"}
    ]

func equip_keepsake(keepsake_id: String):
    if keepsake_id in available_keepsakes:
        equipped_keepsake = available_keepsakes[keepsake_id]
        _apply_keepsake_effects()
        
func upgrade_keepsake(keepsake_id: String):
    var keepsake = available_keepsakes[keepsake_id]
    if keepsake.current_level < keepsake.upgrade_levels.size():
        keepsake.current_level += 1
        # Keepsakes upgrade through use, not currency
```

#### **C. Heat System (Difficulty Scaling)**
```gdscript
# HeatSystem.gd - Challenge modifiers for advanced players
extends Node
class_name HeatSystem

var active_heat_modifiers: Dictionary = {}
var total_heat_level: int = 0
var max_heat_unlocked: int = 0

enum HeatModifier {
    EXTREME_MEASURES,    # Bosses têm nova fase
    JURY_SUMMONS,       # +1 Elite enemy por room  
    TIGHT_DEADLINE,     # Tempo limite por room
    BENEFITS_PACKAGE,   # Enemies têm 1 boon aleatório
    MIDDLE_MANAGEMENT,  # Mid-bosses em algumas rooms
    UNDERWORLD_CUSTOMS, # -1 slot de boon ativo
    FORCED_OVERTIME,    # Enemies +25% attack speed
    HEIGHTENED_SECURITY,# +1 enemy por encounter
    ROUTINE_INSPECTION, # Weapon switches randomly
    DAMAGE_CONTROL     # -50% healing effectiveness
}

func apply_heat_modifier(modifier: HeatModifier, level: int):
    active_heat_modifiers[modifier] = level
    total_heat_level += level
    _update_gameplay_modifiers()
    
func _update_gameplay_modifiers():
    GameManager.difficulty_modifiers.clear()
    
    for modifier in active_heat_modifiers:
        var level = active_heat_modifiers[modifier]
        match modifier:
            HeatModifier.EXTREME_MEASURES:
                GameManager.difficulty_modifiers["boss_extra_phase"] = true
            HeatModifier.JURY_SUMMONS:
                GameManager.difficulty_modifiers["extra_elites"] = level
            HeatModifier.TIGHT_DEADLINE:
                GameManager.difficulty_modifiers["room_time_limit"] = 180 - (level * 30)
            HeatModifier.BENEFITS_PACKAGE:
                GameManager.difficulty_modifiers["enemy_boons"] = true

func get_heat_reward_multiplier() -> float:
    # Maior heat = mais memory points e melhores drops
    return 1.0 + (total_heat_level * 0.1)
```

### **📊 Success Metrics Sprint 14**
- [ ] 25+ upgrades permanentes implementados e balanceados
- [ ] 8+ keepsakes únicos, cada um alterando gameplay significativamente  
- [ ] Heat system com 10 modifiers diferentes funcionando
- [ ] UI de progressão intuitiva e visualmente atrativa
- [ ] Integração com sistema de save/load completa
- [ ] Performance: <2ms para aplicar todos os upgrades permanentes

---

## 💬 **SPRINT 15: DIALOGUE & NARRATIVE SYSTEM**

### **🎯 Objetivos Principais**
1. **Dynamic Dialogue:** Sistema de diálogos que reage a contexto da run
2. **Relationship System:** Levels de relacionamento com cada NPC
3. **Moral Choice Tracking:** Decisões éticas influenciam história  
4. **Voice Acting Integration:** Suporte para áudio brasileiro PT-BR
5. **Narrative Persistence:** Choices across runs impactam story arcs

### **🏗️ Sistema de Diálogo Avançado**

#### **A. DialogueSystem Core**
```gdscript
# DialogueSystem.gd - Sistema principal de diálogos
extends Node
class_name DialogueSystem

signal dialogue_started(npc_name: String)
signal dialogue_ended(npc_name: String, choices_made: Array)
signal relationship_changed(npc_name: String, old_level: int, new_level: int)

var current_conversation: Conversation = null
var dialogue_history: Array[DialogueEntry] = []
var relationship_tracker: RelationshipTracker = null

class Conversation:
    var npc_name: String
    var nodes: Dictionary = {}
    var current_node_id: String
    var context: Dictionary
    var available_choices: Array[DialogueChoice]
    
class DialogueEntry:
    var timestamp: String
    var npc_name: String
    var dialogue_text: String
    var player_choice: String
    var relationship_impact: int
    var moral_weight: float

func start_conversation(npc_name: String, context: Dictionary):
    current_conversation = _build_conversation(npc_name, context)
    dialogue_started.emit(npc_name)
    _show_dialogue_ui()
    
func _build_conversation(npc_name: String, context: Dictionary) -> Conversation:
    var conversation = Conversation.new()
    conversation.npc_name = npc_name
    conversation.context = context
    
    # Contextual dialogue selection based on:
    var selection_factors = {
        "recent_deaths": context.get("deaths_in_last_3_runs", 0),
        "moral_alignment": GameManager.player_moral_score,
        "relationship_level": relationship_tracker.get_level(npc_name),
        "story_progress": GameManager.story_milestones_reached,
        "recent_achievements": context.get("recent_achievements", []),
        "equipped_weapon": GameManager.player.current_weapon.type,
        "last_run_performance": context.get("last_run_stats", {}),
        "memories_collected": context.get("new_memories", [])
    }
    
    conversation.nodes = _generate_contextual_nodes(npc_name, selection_factors)
    return conversation
```

#### **B. Contextual Dialogue Generation**
```gdscript
# ContextualDialogue.gd - AI dinâmica de diálogos
extends Node
class_name ContextualDialogue

func generate_anubis_dialogue(context: Dictionary) -> Dictionary:
    var nodes = {}
    var moral_score = context.moral_alignment
    
    # Opening varia baseado em moral choices
    if moral_score > 0.7:
        nodes["opening"] = {
            "text": "Vejo que suas ações no Duat refletem a justiça verdadeira, Khenti-Ka-Nefer. Ma'at sorri com sua honra.",
            "choices": [
                {"text": "Busco apenas fazer o correto.", "moral": 0.1, "relationship": 2},
                {"text": "A justiça é mais importante que vingança.", "moral": 0.2, "relationship": 3}
            ]
        }
    elif moral_score < -0.5:
        nodes["opening"] = {
            "text": "Sua sede de vingança está nublando seu julgamento, príncipe. Cuidado para não se perder na escuridão.",
            "choices": [
                {"text": "Meu irmão merece sofrer.", "moral": -0.1, "relationship": -1},
                {"text": "Talvez você tenha razão...", "moral": 0.1, "relationship": 1},
                {"text": "Não aceito sermões.", "moral": -0.2, "relationship": -2}
            ]
        }
    else:
        nodes["opening"] = {
            "text": "Vejo conflito em seu ka, Khenti. A balança de seu coração oscila entre justiça e vingança.",
            "choices": [
                {"text": "Como posso encontrar equilíbrio?", "moral": 0.05, "relationship": 2},
                {"text": "Não tenho certeza do que é certo.", "moral": 0, "relationship": 1}
            ]
        }
    
    # Dialogue continua baseado na performance recente
    if context.get("deaths_in_last_3_runs", 0) > 2:
        nodes["struggle_recognition"] = {
            "text": "Percebo que sua jornada tem sido árdua. Lembre-se: cada morte no Duat ensina uma lição.",
            "choices": [
                {"text": "Por que sofro tanto?", "unlocks": "anubis_guidance_quest"},
                {"text": "Preciso ficar mais forte.", "grants": "anubis_training_buff"}
            ]
        }
    
    return nodes

func generate_nefertari_dialogue(context: Dictionary) -> Dictionary:
    var nodes = {}
    var relationship = context.get("relationship_level", 0)
    
    # Relacionamento evolui diálogos românticos
    if relationship < 3:
        nodes["opening"] = {
            "text": "Khenti... mesmo em forma espiritual, meu coração se aquece ao vê-lo.",
            "choices": [
                {"text": "Nefertari, senti tanto sua falta.", "relationship": 1, "unlocks": "romantic_memory_1"},
                {"text": "Preciso me vingar de Khaemwaset primeiro.", "relationship": -1, "moral": -0.1}
            ]
        }
    elif relationship >= 5:
        nodes["opening"] = {
            "text": "Meu amado... vejo determinação renovada em seus olhos. Nossa conexão transcende até a morte.",
            "choices": [
                {"text": "Você é minha razão de lutar.", "relationship": 1, "grants": "love_motivation_buff"},
                {"text": "Juntos venceremos qualquer coisa.", "relationship": 2, "unlocks": "true_love_power"}
            ]
        }
    
    return nodes
```

#### **C. Relationship System**  
```gdscript
# RelationshipTracker.gd - Sistema de relacionamentos dinâmicos
extends Node
class_name RelationshipTracker

var relationships: Dictionary = {}
var relationship_history: Dictionary = {}

class Relationship:
    var npc_name: String
    var current_level: int = 0
    var experience_points: int = 0
    var max_level: int = 10
    var unlock_thresholds: Array[int] = [0, 50, 120, 200, 300, 450, 620, 800, 1000, 1250, 1500]
    var special_unlocks: Dictionary = {}
    var dialogue_modifiers: Dictionary = {}

func initialize_relationship(npc_name: String):
    var relationship = Relationship.new()
    relationship.npc_name = npc_name
    
    # Cada NPC tem thresholds e unlocks únicos
    match npc_name:
        "Anubis":
            relationship.special_unlocks = {
                2: "anubis_keepsake",
                4: "divine_judgment_boon", 
                6: "anubis_champion_title",
                8: "scales_of_truth_weapon_aspect",
                10: "anubis_final_revelation"
            }
        "Nefertari":
            relationship.special_unlocks = {
                3: "nefertari_keepsake",
                5: "lovers_bond_buff",
                7: "nefertari_memory_quest",
                9: "eternal_love_ending_path",
                10: "resurrection_together_ending"
            }
    
    relationships[npc_name] = relationship

func add_relationship_experience(npc_name: String, points: int, reason: String):
    if not npc_name in relationships:
        initialize_relationship(npc_name)
    
    var relationship = relationships[npc_name]
    var old_level = relationship.current_level
    relationship.experience_points += points
    
    # Check for level up
    _check_level_progression(relationship)
    
    # Record interaction
    if not npc_name in relationship_history:
        relationship_history[npc_name] = []
    
    relationship_history[npc_name].append({
        "timestamp": Time.get_datetime_string_from_system(),
        "reason": reason,
        "points": points,
        "old_level": old_level,
        "new_level": relationship.current_level
    })
    
    if relationship.current_level > old_level:
        _handle_relationship_level_up(npc_name, relationship, old_level)

func _handle_relationship_level_up(npc_name: String, relationship: Relationship, old_level: int):
    relationship_changed.emit(npc_name, old_level, relationship.current_level)
    
    # Check special unlocks
    var new_level = relationship.current_level
    if new_level in relationship.special_unlocks:
        var unlock_id = relationship.special_unlocks[new_level]
        _process_special_unlock(npc_name, unlock_id)
        
        # Show unlock notification
        NotificationUI.show_relationship_unlock(npc_name, new_level, unlock_id)

func _process_special_unlock(npc_name: String, unlock_id: String):
    match unlock_id:
        "anubis_keepsake":
            KeepsakeSystem.unlock_keepsake("anubis_scale")
        "divine_judgment_boon":
            BoonSystem.unlock_legendary_boon("anubis_divine_judgment")
        "lovers_bond_buff":
            MetaProgressionSystem.unlock_permanent_buff("nefertari_love_strength")
        "resurrection_together_ending":
            GameManager.unlock_story_path("true_love_resurrection")
```

### **🎭 Narrative Persistence System**
```gdscript
# NarrativePersistence.gd - Choices across runs impact story
extends Node
class_name NarrativePersistence

var story_branches: Dictionary = {}
var moral_decision_history: Array[MoralChoice] = []
var narrative_flags: Dictionary = {}
var active_story_arcs: Array[StoryArc] = []

class MoralChoice:
    var choice_id: String
    var context: String
    var option_selected: String
    var moral_weight: float
    var consequences: Array[String]
    var run_number: int
    
class StoryArc:
    var arc_id: String
    var title: String
    var description: String
    var progression_stage: int
    var required_choices: Array[String]
    var unlocked_content: Array[String]
    var completion_reward: String

func record_moral_choice(choice_id: String, context: String, selected_option: String, moral_weight: float):
    var choice = MoralChoice.new()
    choice.choice_id = choice_id
    choice.context = context
    choice.option_selected = selected_option
    choice.moral_weight = moral_weight
    choice.run_number = GameManager.total_runs
    
    moral_decision_history.append(choice)
    _check_story_arc_progression(choice)
    
func _check_story_arc_progression(choice: MoralChoice):
    for arc in active_story_arcs:
        if choice.choice_id in arc.required_choices:
            arc.progression_stage += 1
            _evaluate_arc_completion(arc)

func get_moral_alignment() -> float:
    var total_weight = 0.0
    var total_choices = 0
    
    for choice in moral_decision_history:
        total_weight += choice.moral_weight
        total_choices += 1
    
    return total_weight / max(1, total_choices)
```

---

## 🔥 **SPRINT 16: SECOND BIOME - RIO DE FOGO**

### **🎯 Objetivos Principais**
1. **New Biome:** Rio de Fogo com 8 rooms temáticas diferentes
2. **Fire Mechanics:** Lava damage, flame spread, fire immunity boons
3. **Sekhmet Boss:** Boss multi-fase com narrativa integrada
4. **Environmental Hazards:** Puzzles e obstacles únicos do fogo
5. **Fire Boons:** 12+ novos boons temáticos de Sekhmet

### **🏗️ Rio de Fogo Implementation**

#### **A. Biome Architecture**
```gdscript
# RioDefogoManager.gd - Fire biome controller
extends BiomeManager
class_name RioDefogoManager

var fire_intensity: float = 1.0
var ambient_heat_damage: float = 0.0
var fire_spread_rate: float = 0.5
var lava_level: float = 0.0

@export var room_templates: Array[PackedScene] = []
@export var fire_hazards: Array[FireHazard] = []
@export var sekhmet_shrine_rooms: Array[PackedScene] = []

func _ready():
    super._ready()
    _initialize_fire_mechanics()
    _setup_environmental_audio()

func _initialize_fire_mechanics():
    # Fire mechanics different from desert
    GameManager.environmental_modifiers = {
        "ambient_heat": true,
        "fire_spread": true,
        "lava_rising": false,  # Special rooms only
        "smoke_vision_reduction": true,
        "fire_immunity_valuable": true
    }
    
    # Override base damage calculations
    GameManager.damage_calculator_override = _fire_biome_damage_calc

func _fire_biome_damage_calc(base_damage: float, source: String, context: Dictionary) -> float:
    var modified_damage = base_damage
    
    # Fire-based attacks deal more damage here
    if "fire" in source.to_lower():
        modified_damage *= 1.3
        
    # Ice/water attacks less effective  
    if "ice" in source.to_lower() or "water" in source.to_lower():
        modified_damage *= 0.7
        
    return modified_damage

func generate_room() -> RoomData:
    var room_data = super.generate_room()
    
    # Add fire-specific elements to every room
    room_data.environmental_hazards.append("ambient_heat")
    
    # 30% chance of lava pools
    if randf() < 0.3:
        room_data.environmental_hazards.append("lava_pools")
        
    # 20% chance of fire geysers
    if randf() < 0.2:
        room_data.environmental_hazards.append("fire_geysers")
        
    # 15% chance of smoke clouds that reduce visibility
    if randf() < 0.15:
        room_data.environmental_hazards.append("smoke_clouds")
        
    return room_data
```

#### **B. Fire Environmental Hazards**
```gdscript
# FireHazard.gd - Hazards únicos do Rio de Fogo
extends Area3D
class_name FireHazard

enum FireHazardType {
    LAVA_POOL,
    FIRE_GEYSER,
    FLAME_WALL,
    SMOKE_CLOUD,
    HEAT_WAVE,
    MOLTEN_SPIKE,
    FIRE_TORNADO,
    EMBER_RAIN
}

@export var hazard_type: FireHazardType
@export var damage_per_second: float = 15.0
@export var activation_interval: float = 3.0
@export var warning_time: float = 1.0

var is_active: bool = false
var affected_bodies: Array[Node3D] = []

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    _setup_hazard_behavior()

func _setup_hazard_behavior():
    match hazard_type:
        FireHazardType.LAVA_POOL:
            # Constant damage, no warning
            is_active = true
            damage_per_second = 25.0
            
        FireHazardType.FIRE_GEYSER:
            # Erupts every 3 seconds with 1s warning
            _setup_geyser_pattern()
            
        FireHazardType.FLAME_WALL:
            # Moves across room slowly
            _setup_flame_wall_movement()
            
        FireHazardType.SMOKE_CLOUD:
            # Reduces visibility, minor damage
            damage_per_second = 5.0
            _setup_visibility_reduction()
            
        FireHazardType.FIRE_TORNADO:
            # Rare, moves randomly, high damage
            damage_per_second = 40.0  
            _setup_tornado_movement()

func _setup_geyser_pattern():
    var timer = Timer.new()
    add_child(timer)
    timer.timeout.connect(_geyser_warning)
    timer.wait_time = activation_interval
    timer.autostart = true

func _geyser_warning():
    # Visual/audio warning
    _show_warning_effect()
    
    # Activate after warning time
    var warning_timer = Timer.new()
    add_child(warning_timer)
    warning_timer.timeout.connect(_geyser_activate)
    warning_timer.wait_time = warning_time
    warning_timer.start()

func _geyser_activate():
    is_active = true
    _show_activation_effect()
    
    # Deal damage to anyone in area
    for body in affected_bodies:
        if body.has_method("take_fire_damage"):
            body.take_fire_damage(damage_per_second * 2.0, "fire_geyser")
    
    # Deactivate after brief period
    var deactivate_timer = Timer.new()
    add_child(deactivate_timer)
    deactivate_timer.timeout.connect(_geyser_deactivate)
    deactivate_timer.wait_time = 0.5
    deactivate_timer.start()

func _on_body_entered(body: Node3D):
    if body.has_method("take_fire_damage"):
        affected_bodies.append(body)
        
        # Immediate effect for constant hazards
        if is_active and hazard_type == FireHazardType.LAVA_POOL:
            _start_continuous_damage(body)

func _start_continuous_damage(body: Node3D):
    if body.has_method("take_fire_damage"):
        var damage_timer = Timer.new()
        add_child(damage_timer)
        damage_timer.timeout.connect(_apply_damage.bind(body))
        damage_timer.wait_time = 1.0  # Damage every second
        damage_timer.start()
        
        # Store timer reference for cleanup
        body.set_meta("fire_damage_timer", damage_timer)

func _apply_damage(body: Node3D):
    if body in affected_bodies and body.has_method("take_fire_damage"):
        body.take_fire_damage(damage_per_second, str(hazard_type))
```

#### **C. Sekhmet Boss Battle**
```gdscript
# SekhmetBoss.gd - Multi-phase fire goddess boss
extends Boss
class_name SekhmetBoss

enum SekhmetPhase {
    LIONESS_FURY,    # Phase 1: Aggressive melee
    SOLAR_DISC,      # Phase 2: Ranged fire attacks  
    HEALING_ASPECT,  # Phase 3: Healing/purification theme
    DIVINE_WRATH     # Phase 4: Combined powers (Heat 5+ only)
}

var current_phase: SekhmetPhase = SekhmetPhase.LIONESS_FURY
var phase_health_thresholds: Array[float] = [0.8, 0.6, 0.4, 0.2]
var fire_immunity_attacks: Array[String] = []

@export var lioness_attacks: Array[AttackPattern] = []
@export var solar_attacks: Array[AttackPattern] = []
@export var healing_abilities: Array[HealingPattern] = []
@export var divine_wrath_combos: Array[ComboPattern] = []

func _ready():
    super._ready()
    boss_name = "Sekhmet"
    base_health = 2500.0
    _setup_phase_transitions()
    _initialize_dialogue_system()

func _setup_phase_transitions():
    health_changed.connect(_check_phase_transition)
    
func _check_phase_transition():
    var health_percentage = current_health / max_health
    
    for i in range(phase_health_thresholds.size()):
        var threshold = phase_health_thresholds[i]
        if health_percentage <= threshold and current_phase == i:
            _transition_to_phase(SekhmetPhase.values()[i + 1])
            break

func _transition_to_phase(new_phase: SekhmetPhase):
    current_phase = new_phase
    _play_phase_transition_dialogue()
    _setup_phase_mechanics(new_phase)
    
func _play_phase_transition_dialogue():
    match current_phase:
        SekhmetPhase.LIONESS_FURY:
            dialogue_system.play_dialogue("sekhmet_phase1_intro")
        SekhmetPhase.SOLAR_DISC:
            dialogue_system.play_dialogue("sekhmet_phase2_solar")
        SekhmetPhase.HEALING_ASPECT:
            dialogue_system.play_dialogue("sekhmet_phase3_healing")
        SekhmetPhase.DIVINE_WRATH:
            dialogue_system.play_dialogue("sekhmet_phase4_wrath")

func _setup_phase_mechanics(phase: SekhmetPhase):
    match phase:
        SekhmetPhase.LIONESS_FURY:
            # Fast, aggressive melee attacks
            movement_speed = 8.0
            attack_cooldown = 1.2
            active_attacks = lioness_attacks
            
        SekhmetPhase.SOLAR_DISC:
            # Ranged fire projectiles, area denial
            movement_speed = 4.0  
            attack_cooldown = 2.0
            active_attacks = solar_attacks
            _enable_fire_area_attacks()
            
        SekhmetPhase.HEALING_ASPECT:
            # Self-healing + supportive attacks
            movement_speed = 3.0
            attack_cooldown = 2.5
            _enable_healing_mechanics()
            active_attacks = healing_abilities
            
        SekhmetPhase.DIVINE_WRATH:
            # All powers combined
            movement_speed = 6.0
            attack_cooldown = 1.0  
            active_attacks = divine_wrath_combos
            _enable_all_mechanics()

func execute_attack():
    match current_phase:
        SekhmetPhase.LIONESS_FURY:
            _execute_lioness_attack()
        SekhmetPhase.SOLAR_DISC:
            _execute_solar_attack()
        SekhmetPhase.HEALING_ASPECT:
            _execute_healing_attack()
        SekhmetPhase.DIVINE_WRATH:
            _execute_divine_combo()

func _execute_lioness_attack():
    # Choose from lioness attack patterns
    var attacks = ["claw_swipe", "pounce_attack", "roar_stun", "fury_combo"]
    var selected_attack = attacks[randi() % attacks.size()]
    
    match selected_attack:
        "claw_swipe":
            _perform_claw_swipe()
        "pounce_attack":
            _perform_pounce()
        "roar_stun":
            _perform_stunning_roar()
        "fury_combo":
            _perform_fury_combo()

func _execute_solar_attack():
    var attacks = ["fire_beam", "solar_disc_throw", "flame_pillars", "heat_wave"]
    var selected_attack = attacks[randi() % attacks.size()]
    
    match selected_attack:
        "fire_beam":
            _perform_continuous_fire_beam()
        "solar_disc_throw":
            _perform_disc_boomerang()
        "flame_pillars":
            _summon_flame_pillars()
        "heat_wave":
            _perform_area_heat_wave()
```

### **🎁 Sekhmet Boon System**
```gdscript  
# SekhmetBoons.gd - Fire/healing themed boons
extends Node
class_name SekhmetBoons

func get_sekhmet_boons() -> Array[Dictionary]:
    return [
        {
            "id": "lioness_fury",
            "name": "Fúria da Leoa",
            "description": "Ataques críticos aplicam Burn (20 dano/seg por 4s)",
            "rarity": "Common",
            "effect": {"crit_burn_damage": 20, "crit_burn_duration": 4}
        },
        {
            "id": "solar_blessing",
            "name": "Bênção Solar", 
            "description": "Regenera 2 HP por inimigo eliminado com fogo",
            "rarity": "Common",
            "effect": {"fire_kill_heal": 2}
        },
        {
            "id": "flame_aura",
            "name": "Aura Flamejante",
            "description": "Inimigos próximos recebem 8 dano/seg",
            "rarity": "Rare", 
            "effect": {"flame_aura_damage": 8, "flame_aura_radius": 3.0}
        },
        {
            "id": "purifying_fire",
            "name": "Fogo Purificador",
            "description": "Ataques com fogo removem debuffs negativos",
            "rarity": "Rare",
            "effect": {"fire_purify": true}
        },
        {
            "id": "healing_flames",
            "name": "Chamas Curativas",
            "description": "Cada 5º ataque cura 15 HP em vez de dar dano",
            "rarity": "Epic",
            "effect": {"heal_every_nth_attack": 5, "heal_amount": 15}
        },
        {
            "id": "sekhmet_wrath",
            "name": "Cólera de Sekhmet",
            "description": "Legendary: HP baixo = ataques incendeiam toda área",
            "rarity": "Legendary",
            "requirements": ["lioness_fury", "flame_aura"],
            "effect": {"low_hp_area_fire": true, "trigger_threshold": 0.3}
        }
    ]
```

---

## ✅ **INTEGRATION CHECKLIST - SPRINTS 13-16**

### **Sprint 13: Pool of Memories Hub**
- [ ] **Hub scene loads correctly** from death transition
- [ ] **8 NPCs spawn** with unique dialogue trees
- [ ] **Memory collection UI** shows new memories from runs
- [ ] **Hub areas navigable** with smooth transitions
- [ ] **Save/load integration** preserves hub state
- [ ] **Performance test:** Hub loads in <3 seconds
- [ ] **UI responsive** to controller and keyboard input

### **Sprint 14: Meta-Progression**  
- [ ] **25+ upgrades implemented** and properly balanced
- [ ] **Memory point currency** earned from runs
- [ ] **Keepsake system functional** with 8+ unique items
- [ ] **Heat system active** with 10 difficulty modifiers
- [ ] **Progression trees unlock** based on story milestones
- [ ] **UI tooltips accurate** for all upgrade effects
- [ ] **Integration test:** All upgrades work in MainGameScene

### **Sprint 15: Dialogue & Narrative**
- [ ] **Dynamic dialogue responds** to run context
- [ ] **Relationship system tracks** NPC interactions
- [ ] **Moral choices recorded** across multiple runs
- [ ] **Dialogue UI polished** with smooth transitions
- [ ] **Voice acting support** implemented (placeholder audio)
- [ ] **Story persistence** maintains narrative state
- [ ] **Performance:** Dialogue loads in <1 second

### **Sprint 16: Rio de Fogo**
- [ ] **Second biome accessible** from first biome completion
- [ ] **Fire mechanics functional** (lava damage, heat effects)
- [ ] **8 unique fire rooms** with varied layouts
- [ ] **Sekhmet boss battle** with 4 phases working
- [ ] **12+ fire boons** implemented and balanced
- [ ] **Environmental hazards** pose meaningful challenge
- [ ] **Integration test:** Full run through both biomes works

### **Cross-Sprint Integration Requirements**
- [ ] **GameManager integration:** All systems report to central manager
- [ ] **Save system complete:** All progression persists between sessions
- [ ] **UI consistency:** All new UIs match established style
- [ ] **Performance target:** 60 FPS with all systems active
- [ ] **Audio integration:** Music and SFX for all new content
- [ ] **Controller support:** All interactions work with gamepad

---

## 🎯 **SUCCESS CRITERIA - PHASE 2 COMPLETE**

**Narrative Integration Achieved When:**
- Player death has emotional weight through hub NPCs
- Relationships with NPCs evolve based on player choices
- Meta-progression feels meaningful, not just numbers
- Second biome offers distinctly different challenge
- Moral choices create branching narrative paths

**Technical Excellence Markers:**
- Zero loading screens between hub areas
- All dialogue loads instantly with context
- 60 FPS maintained with fire effects active
- Save/load preserves all relationship states
- Heat system scales difficulty smoothly

**Player Experience Goals:**
- "Every run teaches me more about Khenti's story"
- "My relationship with NPCs feels meaningful"
- "The heat system gives me control over difficulty"
- "Fire biome feels completely different from desert"
- "I care about the moral choices I make"

---

*"In the Pool of Memories, Khenti begins to remember not just who he was, but who he chooses to become."*

**Phase 2 Complete → Ready for Content Expansion (Sprints 17-20)**