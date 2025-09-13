# ⚔️ FASE 3: CONTENT EXPANSION - Sprints 17-20

## 🎮 **VISÃO GERAL DA FASE**

**Objetivo Central:** Transformar Sands of Duat de um jogo funcional em uma experiência de combate premium Hades-tier, com profundidade de conteúdo que sustenta 100+ horas de gameplay.

**Filosofia:** Cada sistema deve ter a profundidade e polish de um AAA indie. Combat juice que rivaliza com Hades, weapon aspects que mudam completamente o gameplay, e um terceiro bioma que desafia players experientes.

**Success Criteria desta Fase:**
- Combat feel indistinguível de Hades original em termos de juice/feedback
- 15+ weapon aspects que criam builds completamente diferentes
- Heat system balanceado para challenge extremo (25+ heat)
- Terceiro biome (Salão do Julgamento) com complexidade superior
- Boss Ammit com mecânicas únicas multi-fase
- 150+ viable builds através de synergias de boons

---

## 💥 **SPRINT 17: COMBAT JUICE & FEEDBACK**

### **🎯 Objetivos Principais**
1. **Combat Feel:** Hades-tier feedback em todos os ataques
2. **Visual Effects:** Particle systems premium para cada weapon type
3. **Audio Design:** SFX responsivos e impactantes
4. **Screen Shake:** Calibrado perfeitamente para cada ação
5. **Hitstop/Freeze:** Timing preciso para impacto máximo
6. **Damage Numbers:** Sistema visual claro e satisfatório

### **🏗️ Combat Juice Implementation**

#### **A. Enhanced Feedback System**
```gdscript
# CombatJuiceManager.gd - Sistema central de feedback
extends Node
class_name CombatJuiceManager

@export var screen_shake_intensity: float = 1.0
@export var hitstop_enabled: bool = true
@export var particle_quality: String = "High"

var camera_shake: CameraShake
var hitstop_controller: HitstopController
var particle_manager: ParticleManager
var audio_feedback: AudioFeedbackSystem

func _ready():
    _initialize_feedback_systems()
    _connect_combat_signals()

func _initialize_feedback_systems():
    camera_shake = CameraShake.new()
    hitstop_controller = HitstopController.new()
    particle_manager = ParticleManager.new()
    audio_feedback = AudioFeedbackSystem.new()
    
    add_child(camera_shake)
    add_child(hitstop_controller)
    add_child(particle_manager)
    add_child(audio_feedback)

func _connect_combat_signals():
    # Connect to all combat events
    GameManager.damage_dealt.connect(_on_damage_dealt)
    GameManager.critical_hit.connect(_on_critical_hit)
    GameManager.enemy_killed.connect(_on_enemy_killed)
    GameManager.dash_performed.connect(_on_dash_performed)
    GameManager.special_attack_used.connect(_on_special_attack)
    GameManager.block_successful.connect(_on_successful_block)

func _on_damage_dealt(damage: float, weapon_type: String, hit_position: Vector3, is_critical: bool):
    # Multi-layered feedback for every hit
    _trigger_screen_shake(damage, weapon_type, is_critical)
    _trigger_hitstop(damage, weapon_type, is_critical)
    _spawn_hit_particles(weapon_type, hit_position, is_critical)
    _play_hit_audio(weapon_type, damage, is_critical)
    _show_damage_numbers(damage, hit_position, is_critical)
    
    if is_critical:
        _trigger_critical_feedback(damage, hit_position)

func _trigger_screen_shake(damage: float, weapon_type: String, is_critical: bool):
    var shake_intensity = _calculate_shake_intensity(damage, weapon_type, is_critical)
    var shake_duration = _calculate_shake_duration(weapon_type, is_critical)
    
    camera_shake.add_trauma(shake_intensity, shake_duration)

func _calculate_shake_intensity(damage: float, weapon_type: String, is_critical: bool) -> float:
    var base_intensity = 0.0
    
    # Different weapons have different shake profiles
    match weapon_type:
        "khopesh":
            base_intensity = 0.3  # Sharp, quick shake
        "was_scepter":
            base_intensity = 0.5  # Heavy, authority shake
        "staff":
            base_intensity = 0.2  # Subtle magical shake
        "bow":
            base_intensity = 0.1  # Minimal ranged shake
        "claws":
            base_intensity = 0.4  # Aggressive, primal shake
    
    # Scale with damage
    var damage_multiplier = clamp(damage / 50.0, 0.5, 2.0)
    
    # Critical hits get extra intensity
    var critical_multiplier = 2.0 if is_critical else 1.0
    
    return base_intensity * damage_multiplier * critical_multiplier * screen_shake_intensity

func _trigger_hitstop(damage: float, weapon_type: String, is_critical: bool):
    if not hitstop_enabled:
        return
        
    var freeze_duration = _calculate_hitstop_duration(damage, weapon_type, is_critical)
    hitstop_controller.trigger_hitstop(freeze_duration)

func _calculate_hitstop_duration(damage: float, weapon_type: String, is_critical: bool) -> float:
    var base_duration = 0.0
    
    # Heavy weapons get longer hitstop
    match weapon_type:
        "khopesh":
            base_duration = 0.08
        "was_scepter":
            base_duration = 0.12
        "staff":
            base_duration = 0.06
        "bow":
            base_duration = 0.03
        "claws":
            base_duration = 0.05
    
    # Critical hits get extended hitstop
    if is_critical:
        base_duration *= 1.5
    
    # Scale slightly with damage
    var damage_scale = clamp(damage / 100.0, 0.8, 1.3)
    
    return base_duration * damage_scale
```

#### **B. Advanced Particle System**
```gdscript
# ParticleManager.gd - Premium particle effects
extends Node
class_name ParticleManager

@export var particle_pools: Dictionary = {}
@export var max_particles_per_pool: int = 50

var active_particles: Array[GPUParticles3D] = []
var particle_presets: Dictionary = {}

func _ready():
    _initialize_particle_presets()
    _create_particle_pools()

func _initialize_particle_presets():
    # Khopesh impact particles
    particle_presets["khopesh_hit"] = {
        "texture": "res://effects/particles/sparks.png",
        "count": 25,
        "lifetime": 0.8,
        "direction": Vector3.UP,
        "speed": 8.0,
        "spread": 45.0,
        "size_scale": 1.0,
        "color_ramp": "orange_to_red"
    }
    
    # Was Scepter divine energy
    particle_presets["scepter_hit"] = {
        "texture": "res://effects/particles/divine_energy.png",
        "count": 40,
        "lifetime": 1.2,
        "direction": Vector3.UP,
        "speed": 6.0,
        "spread": 60.0,
        "size_scale": 1.5,
        "color_ramp": "gold_to_white"
    }
    
    # Staff magical sparks
    particle_presets["staff_hit"] = {
        "texture": "res://effects/particles/magic_sparks.png", 
        "count": 30,
        "lifetime": 1.0,
        "direction": Vector3.UP,
        "speed": 10.0,
        "spread": 30.0,
        "size_scale": 0.8,
        "color_ramp": "blue_to_cyan"
    }
    
    # Critical hit burst
    particle_presets["critical_burst"] = {
        "texture": "res://effects/particles/critical_burst.png",
        "count": 60,
        "lifetime": 1.5,
        "direction": Vector3.UP,
        "speed": 12.0,
        "spread": 180.0,  # Full spread
        "size_scale": 2.0,
        "color_ramp": "yellow_to_gold"
    }
    
    # Enemy death explosion  
    particle_presets["enemy_death"] = {
        "texture": "res://effects/particles/soul_fragments.png",
        "count": 80,
        "lifetime": 2.0,
        "direction": Vector3.UP,
        "speed": 15.0,
        "spread": 120.0,
        "size_scale": 1.2,
        "color_ramp": "dark_red_to_black"
    }

func spawn_hit_particles(weapon_type: String, position: Vector3, is_critical: bool):
    var preset_name = weapon_type + "_hit"
    if not preset_name in particle_presets:
        preset_name = "khopesh_hit"  # Fallback
        
    var particles = _get_pooled_particles(preset_name)
    _configure_particles(particles, particle_presets[preset_name])
    particles.global_position = position
    particles.restart()
    
    # Additional critical hit particles
    if is_critical:
        var critical_particles = _get_pooled_particles("critical_burst")
        _configure_particles(critical_particles, particle_presets["critical_burst"])
        critical_particles.global_position = position
        critical_particles.restart()

func _configure_particles(particles: GPUParticles3D, preset: Dictionary):
    var material = particles.process_material as ParticleProcessMaterial
    
    material.direction = preset.direction
    material.initial_velocity_min = preset.speed * 0.8
    material.initial_velocity_max = preset.speed * 1.2
    material.angular_velocity_min = -90.0
    material.angular_velocity_max = 90.0
    material.spread = preset.spread
    
    # Size variation
    material.scale_min = preset.size_scale * 0.7
    material.scale_max = preset.size_scale * 1.3
    
    particles.amount = preset.count
    particles.lifetime = preset.lifetime
    
    # Color based on preset
    _apply_color_ramp(material, preset.color_ramp)

func _apply_color_ramp(material: ParticleProcessMaterial, ramp_name: String):
    var gradient = Gradient.new()
    
    match ramp_name:
        "orange_to_red":
            gradient.add_point(0.0, Color.ORANGE)
            gradient.add_point(0.5, Color.RED)
            gradient.add_point(1.0, Color.DARK_RED)
        "gold_to_white":
            gradient.add_point(0.0, Color.GOLD)
            gradient.add_point(0.7, Color.WHITE)
            gradient.add_point(1.0, Color.TRANSPARENT)
        "blue_to_cyan":
            gradient.add_point(0.0, Color.BLUE)
            gradient.add_point(0.6, Color.CYAN)
            gradient.add_point(1.0, Color.TRANSPARENT)
        "yellow_to_gold":
            gradient.add_point(0.0, Color.YELLOW)
            gradient.add_point(0.4, Color.GOLD)
            gradient.add_point(1.0, Color.ORANGE)
    
    material.color_ramp = gradient
```

#### **C. Dynamic Audio Feedback**
```gdscript
# AudioFeedbackSystem.gd - Responsive audio for all actions
extends Node
class_name AudioFeedbackSystem

var audio_pools: Dictionary = {}
var audio_variations: Dictionary = {}
var dynamic_mix: AudioMixManager

func _ready():
    _initialize_audio_pools()
    _load_audio_variations()
    _setup_dynamic_mixing()

func _initialize_audio_pools():
    # Create audio source pools for different categories
    audio_pools["weapon_hits"] = _create_audio_pool(10)
    audio_pools["critical_hits"] = _create_audio_pool(5)
    audio_pools["enemy_deaths"] = _create_audio_pool(8)
    audio_pools["dash_sounds"] = _create_audio_pool(3)
    audio_pools["block_sounds"] = _create_audio_pool(4)

func _load_audio_variations():
    # Multiple variations prevent repetition
    audio_variations["khopesh_hit"] = [
        "res://audio/weapons/khopesh_hit_01.ogg",
        "res://audio/weapons/khopesh_hit_02.ogg", 
        "res://audio/weapons/khopesh_hit_03.ogg",
        "res://audio/weapons/khopesh_hit_04.ogg"
    ]
    
    audio_variations["scepter_hit"] = [
        "res://audio/weapons/scepter_impact_01.ogg",
        "res://audio/weapons/scepter_impact_02.ogg",
        "res://audio/weapons/scepter_impact_03.ogg"
    ]
    
    audio_variations["critical_hit"] = [
        "res://audio/weapons/critical_01.ogg",
        "res://audio/weapons/critical_02.ogg",
        "res://audio/weapons/critical_03.ogg"
    ]
    
    audio_variations["enemy_death"] = [
        "res://audio/enemies/death_01.ogg",
        "res://audio/enemies/death_02.ogg",
        "res://audio/enemies/death_03.ogg",
        "res://audio/enemies/death_04.ogg",
        "res://audio/enemies/death_05.ogg"
    ]

func play_hit_audio(weapon_type: String, damage: float, is_critical: bool):
    var audio_key = weapon_type + "_hit"
    var audio_source = _get_available_audio_source("weapon_hits")
    
    if audio_source and audio_key in audio_variations:
        var variations = audio_variations[audio_key]
        var selected_audio = variations[randi() % variations.size()]
        
        audio_source.stream = load(selected_audio)
        
        # Dynamic pitch based on damage
        var pitch_variation = 1.0 + (damage / 200.0) * 0.3  # Up to 30% pitch increase
        audio_source.pitch_scale = clamp(pitch_variation, 0.8, 1.4)
        
        # Dynamic volume based on impact
        var volume_db = _calculate_impact_volume(damage, is_critical)
        audio_source.volume_db = volume_db
        
        audio_source.play()
        
        # Critical hits get additional sound layer
        if is_critical:
            _play_critical_audio_layer(audio_source.global_position)

func _play_critical_audio_layer(position: Vector3):
    var crit_source = _get_available_audio_source("critical_hits")
    if crit_source:
        var crit_variations = audio_variations["critical_hit"]
        var selected = crit_variations[randi() % crit_variations.size()]
        
        crit_source.stream = load(selected)
        crit_source.global_position = position
        crit_source.volume_db = -2.0  # Slightly quieter layer
        crit_source.pitch_scale = randf_range(0.9, 1.1)
        crit_source.play()

func _calculate_impact_volume(damage: float, is_critical: bool) -> float:
    var base_volume = -10.0  # dB
    
    # Scale with damage (up to +6dB for high damage)
    var damage_boost = clamp((damage / 100.0) * 6.0, 0.0, 6.0)
    
    # Critical hits get volume boost
    var critical_boost = 3.0 if is_critical else 0.0
    
    return base_volume + damage_boost + critical_boost
```

#### **D. Damage Number System**
```gdscript
# DamageNumbersUI.gd - Visual damage feedback
extends Control
class_name DamageNumbersUI

var damage_number_scene: PackedScene = preload("res://ui/DamageNumber.tscn")
var active_numbers: Array[DamageNumber] = []

func _ready():
    # Connect to damage events
    GameManager.damage_dealt.connect(_show_damage_number)

func _show_damage_number(damage: float, position: Vector3, is_critical: bool, damage_type: String = ""):
    var damage_number = damage_number_scene.instantiate() as DamageNumber
    add_child(damage_number)
    
    # Convert 3D position to screen position
    var camera = get_viewport().get_camera_3d()
    var screen_pos = camera.unproject_position(position)
    
    # Configure damage number appearance
    damage_number.setup_damage_display(damage, screen_pos, is_critical, damage_type)
    
    active_numbers.append(damage_number)
    
    # Clean up when animation finishes
    damage_number.animation_finished.connect(_on_damage_number_finished.bind(damage_number))

func _on_damage_number_finished(damage_number: DamageNumber):
    if damage_number in active_numbers:
        active_numbers.erase(damage_number)
    damage_number.queue_free()

# DamageNumber.gd - Individual damage number component
extends Control
class_name DamageNumber

@onready var label: Label = $Label
@onready var animator: AnimationPlayer = $AnimationPlayer

signal animation_finished()

func setup_damage_display(damage: float, screen_position: Vector2, is_critical: bool, damage_type: String):
    position = screen_position
    
    # Format damage text
    var damage_text = str(int(damage))
    if is_critical:
        damage_text = "CRIT " + damage_text + "!"
    
    label.text = damage_text
    
    # Style based on damage type and critical
    _apply_damage_styling(is_critical, damage_type, damage)
    
    # Animate
    _play_damage_animation(is_critical)

func _apply_damage_styling(is_critical: bool, damage_type: String, damage: float):
    if is_critical:
        label.add_theme_color_override("font_color", Color.GOLD)
        label.add_theme_font_size_override("font_size", 32)
        label.add_theme_shadow_offset_override("shadow_offset", Vector2(2, 2))
    else:
        # Color based on damage amount
        if damage >= 100:
            label.add_theme_color_override("font_color", Color.ORANGE_RED)
            label.add_theme_font_size_override("font_size", 28)
        elif damage >= 50:
            label.add_theme_color_override("font_color", Color.ORANGE)
            label.add_theme_font_size_override("font_size", 24)
        else:
            label.add_theme_color_override("font_color", Color.WHITE)
            label.add_theme_font_size_override("font_size", 20)
    
    # Damage type colors
    match damage_type:
        "fire":
            label.add_theme_color_override("font_color", Color.RED)
        "divine":
            label.add_theme_color_override("font_color", Color.GOLD)
        "magic":
            label.add_theme_color_override("font_color", Color.CYAN)

func _play_damage_animation(is_critical: bool):
    if is_critical:
        animator.play("critical_popup")
    else:
        animator.play("normal_popup")
    
    # Connect animation end
    animator.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_animation_name: String):
    animation_finished.emit()
```

---

## 🗡️ **SPRINT 18: WEAPON ASPECTS & HEAT SYSTEM**

### **🎯 Objetivos Principais**
1. **Weapon Aspects:** 3+ aspects únicos para cada das 5 armas (15 total)
2. **Heat System Expansion:** 25 heat levels com modifiers extremos
3. **Aspect Unlock System:** Progression tied to story/achievements
4. **Build Diversity:** 150+ combinações viáveis de weapon+boons+aspects
5. **Advanced Modifiers:** Heat effects que transformam gameplay completamente

### **🏗️ Weapon Aspects System**

#### **A. Aspect System Architecture**
```gdscript
# WeaponAspectSystem.gd - Sistema completo de aspectos de arma
extends Node
class_name WeaponAspectSystem

var available_aspects: Dictionary = {}
var unlocked_aspects: Array[String] = []
var equipped_aspects: Dictionary = {}

class WeaponAspect:
    var id: String
    var weapon_type: String
    var name: String
    var description: String
    var flavor_text: String
    var unlock_condition: String
    var stat_modifications: Dictionary
    var special_abilities: Array[Dictionary]
    var visual_changes: Dictionary
    var audio_changes: Dictionary

func _ready():
    _initialize_all_aspects()
    _load_player_progress()

func _initialize_all_aspects():
    _initialize_khopesh_aspects()
    _initialize_scepter_aspects()
    _initialize_staff_aspects()
    _initialize_bow_aspects()
    _initialize_claws_aspects()

func _initialize_khopesh_aspects():
    # Aspect of Menes (First Pharaoh)
    var menes_aspect = WeaponAspect.new()
    menes_aspect.id = "khopesh_menes"
    menes_aspect.weapon_type = "khopesh"
    menes_aspect.name = "Aspect de Menés"
    menes_aspect.description = "Ataques especiais criam ondas de areia que atravessam inimigos"
    menes_aspect.flavor_text = "A lâmina do primeiro faraó, unificadora das Duas Terras"
    menes_aspect.unlock_condition = "Complete 15 runs with Khopesh without taking damage in 3 consecutive rooms"
    menes_aspect.stat_modifications = {
        "special_cooldown_reduction": 0.25,
        "special_damage_multiplier": 1.4,
        "movement_speed_bonus": 0.15
    }
    menes_aspect.special_abilities = [
        {
            "id": "sand_wave",
            "name": "Onda de Areia",
            "description": "Special attack cria onda penetrante",
            "effect": "spawn_sand_wave_projectile"
        }
    ]
    available_aspects["khopesh_menes"] = menes_aspect
    
    # Aspect of Ramesses (The Great)
    var ramesses_aspect = WeaponAspect.new()
    ramesses_aspect.id = "khopesh_ramesses"
    ramesses_aspect.weapon_type = "khopesh"
    ramesses_aspect.name = "Aspect de Ramsés"
    ramesses_aspect.description = "Cada 3º ataque convoca espectros de soldados egípcios"
    ramesses_aspect.flavor_text = "O poder do maior dos faraós, comandante de exércitos infinitos"
    ramesses_aspect.unlock_condition = "Defeat 1000 enemies with Khopesh across all runs"
    ramesses_aspect.stat_modifications = {
        "attack_damage_multiplier": 1.2,
        "crit_chance_bonus": 0.1
    }
    ramesses_aspect.special_abilities = [
        {
            "id": "spectral_soldiers",
            "name": "Soldados Espectrais",
            "description": "3º ataque spawn 2 soldados temporários",
            "effect": "summon_spectral_allies"
        }
    ]
    available_aspects["khopesh_ramesses"] = ramesses_aspect
    
    # Aspect of Osiris (Death Judge) 
    var osiris_aspect = WeaponAspect.new()
    osiris_aspect.id = "khopesh_osiris"
    osiris_aspect.weapon_type = "khopesh"
    osiris_aspect.name = "Aspect de Osíris"
    osiris_aspect.description = "Ataques contra inimigos com baixo HP executam instantaneamente"
    osiris_aspect.flavor_text = "A lâmina do julgamento final, que separa dignos dos indignos"
    osiris_aspect.unlock_condition = "Reach maximum relationship with Anubis"
    osiris_aspect.stat_modifications = {
        "execute_threshold": 0.15,  # 15% HP execute
        "damage_vs_low_hp": 2.0
    }
    osiris_aspect.special_abilities = [
        {
            "id": "divine_execution", 
            "name": "Execução Divina",
            "description": "Mata instantaneamente inimigos <15% HP",
            "effect": "enable_execute_mechanic"
        }
    ]
    available_aspects["khopesh_osiris"] = osiris_aspect

func _initialize_scepter_aspects():
    # Aspect of Ra (Sun God)
    var ra_aspect = WeaponAspect.new()
    ra_aspect.id = "scepter_ra"
    ra_aspect.weapon_type = "was_scepter"
    ra_aspect.name = "Aspect de Rá"
    ra_aspect.description = "Ataques especiais lançam raios solares em linha reta"
    ra_aspect.flavor_text = "O cetro do deus Sol, que ilumina e purifica"
    ra_aspect.unlock_condition = "Complete a run using only Was Scepter without any other weapons"
    ra_aspect.stat_modifications = {
        "special_range_multiplier": 2.0,
        "fire_damage_bonus": 0.5,
        "special_piercing": true
    }
    ra_aspect.special_abilities = [
        {
            "id": "solar_beam",
            "name": "Raio Solar",
            "description": "Special attack vira laser perfurante",
            "effect": "convert_special_to_beam"
        }
    ]
    available_aspects["scepter_ra"] = ra_aspect
    
    # Aspect of Ptah (Creator God)
    var ptah_aspect = WeaponAspect.new()
    ptah_aspect.id = "scepter_ptah"
    ptah_aspect.weapon_type = "was_scepter"
    ptah_aspect.name = "Aspect de Ptah"
    ptah_aspect.description = "Ataques constroem estruturas temporárias que bloqueiam projéteis"
    ptah_aspect.flavor_text = "O poder da criação divina, moldando realidade com vontade"
    ptah_aspect.unlock_condition = "Use Was Scepter to block 500 projectiles total"
    ptah_aspect.stat_modifications = {
        "block_efficiency": 1.5,
        "structure_duration": 8.0
    }
    ptah_aspect.special_abilities = [
        {
            "id": "divine_construction",
            "name": "Construção Divina",  
            "description": "Special cria barreira temporária",
            "effect": "spawn_protective_structure"
        }
    ]
    available_aspects["scepter_ptah"] = ptah_aspect

func _initialize_staff_aspects():
    # Aspect of Thoth (Wisdom God)
    var thoth_aspect = WeaponAspect.new()
    thoth_aspect.id = "staff_thoth"
    thoth_aspect.weapon_type = "staff"
    thoth_aspect.name = "Aspect de Thoth"
    thoth_aspect.description = "Todos os boons têm +1 nível efetivo de raridade"
    thoth_aspect.flavor_text = "O cajado da sabedoria infinita, que amplifica todo conhecimento"
    thoth_aspect.unlock_condition = "Collect 100 different boons across all runs"
    thoth_aspect.stat_modifications = {
        "boon_rarity_boost": 1,  # Treat Common as Rare, Rare as Epic, etc
        "magic_damage_multiplier": 1.3
    }
    thoth_aspect.special_abilities = [
        {
            "id": "wisdom_amplification",
            "name": "Amplificação da Sabedoria",
            "description": "Boons são mais poderosos",
            "effect": "boost_all_boon_effectiveness"
        }
    ]
    available_aspects["staff_thoth"] = thoth_aspect
    
    # Aspect of Isis (Magic Goddess)
    var isis_aspect = WeaponAspect.new()
    isis_aspect.id = "staff_isis"
    isis_aspect.weapon_type = "staff"
    isis_aspect.name = "Aspect de Ísis"
    isis_aspect.description = "Ataques especiais curam aliados espectrais e você"
    isis_aspect.flavor_text = "O poder da grande maga, que domina vida e morte"
    isis_aspect.unlock_condition = "Heal 10000 total HP using any healing sources"
    isis_aspect.stat_modifications = {
        "heal_effectiveness": 1.5,
        "special_heal_amount": 40
    }
    isis_aspect.special_abilities = [
        {
            "id": "healing_magic",
            "name": "Magia Curativa",
            "description": "Special heals você e aliados próximos",
            "effect": "area_healing_special"
        }
    ]
    available_aspects["staff_isis"] = isis_aspect

# Continue for bow and claws aspects...
```

#### **B. Advanced Heat System**  
```gdscript
# AdvancedHeatSystem.gd - 25 heat levels com modifiers extremos
extends Node
class_name AdvancedHeatSystem

var heat_modifiers: Dictionary = {}
var active_modifiers: Dictionary = {}
var heat_rewards: Dictionary = {}

func _ready():
    _initialize_heat_modifiers()
    _setup_heat_rewards()

func _initialize_heat_modifiers():
    # Tier 1 Heat (1-5 heat each)
    heat_modifiers["jury_summons"] = {
        "name": "Convocação do Júri",
        "description": "+1 Elite enemy por room que normalmente não tem",
        "heat_cost": 1,
        "max_rank": 3,
        "effect_per_rank": {"extra_elites": 1}
    }
    
    heat_modifiers["tight_deadline"] = {
        "name": "Prazo Apertado", 
        "description": "Rooms têm tempo limite; falhar = dano pesado",
        "heat_cost": 2,
        "max_rank": 5,
        "effect_per_rank": {"room_time_limit": -30}  # 150s, 120s, 90s, 60s, 30s
    }
    
    heat_modifiers["benefits_package"] = {
        "name": "Pacote de Benefícios",
        "description": "Enemies aleatórios spawnam com 1-3 boons",
        "heat_cost": 2,
        "max_rank": 3,
        "effect_per_rank": {"enemy_boon_chance": 0.15}
    }
    
    # Tier 2 Heat (3-7 heat each)
    heat_modifiers["middle_management"] = {
        "name": "Gerência Intermediária",
        "description": "Mini-bosses aparecem em rooms normais",
        "heat_cost": 3,
        "max_rank": 2,
        "effect_per_rank": {"miniboss_spawn_chance": 0.25}
    }
    
    heat_modifiers["underworld_customs"] = {
        "name": "Alfândega do Submundo",
        "description": "Máximo de boons ativos é reduzido",
        "heat_cost": 4,
        "max_rank": 3,
        "effect_per_rank": {"max_boons_reduction": 1}
    }
    
    heat_modifiers["forced_overtime"] = {
        "name": "Horas Extras Forçadas",
        "description": "Todos os enemies atacam mais rápido",
        "heat_cost": 5,
        "max_rank": 3,
        "effect_per_rank": {"enemy_attack_speed": 0.25}
    }
    
    # Tier 3 Heat (5-10 heat each)
    heat_modifiers["heightened_security"] = {
        "name": "Segurança Reforçada",
        "description": "+2 enemies básicos em cada encounter",
        "heat_cost": 5,
        "max_rank": 4,
        "effect_per_rank": {"extra_basic_enemies": 2}
    }
    
    heat_modifiers["routine_inspection"] = {
        "name": "Inspeção de Rotina",
        "description": "Weapon muda aleatoriamente a cada room",
        "heat_cost": 6,
        "max_rank": 1,
        "effect_per_rank": {"forced_weapon_swap": true}
    }
    
    heat_modifiers["damage_control"] = {
        "name": "Controle de Danos",
        "description": "Healing é 50% menos efetivo, max HP reduzido",
        "heat_cost": 7,
        "max_rank": 2,
        "effect_per_rank": {"healing_reduction": 0.25, "max_hp_reduction": 25}
    }
    
    # Tier 4 Heat (8-15 heat each) - Extreme modifiers
    heat_modifiers["extreme_measures"] = {
        "name": "Medidas Extremas",
        "description": "Todos os bosses ganham fase adicional",
        "heat_cost": 10,
        "max_rank": 1,
        "effect_per_rank": {"boss_extra_phases": 1}
    }
    
    heat_modifiers["personal_liability"] = {
        "name": "Responsabilidade Pessoal", 
        "description": "Não pode usar Keepsakes durante a run",
        "heat_cost": 8,
        "max_rank": 1,
        "effect_per_rank": {"keepsakes_disabled": true}
    }
    
    heat_modifiers["lasting_consequences"] = {
        "name": "Consequências Duradouras",
        "description": "Debuffs persistem entre rooms por 2-3 rooms",
        "heat_cost": 9,
        "max_rank": 2,
        "effect_per_rank": {"debuff_persistence": 2}
    }
    
    # Tier 5 Heat (10+ heat each) - Masochistic levels
    heat_modifiers["approval_process"] = {
        "name": "Processo de Aprovação",
        "description": "Deve escolher boons em ordem de raridade (Common → Epic)",
        "heat_cost": 12,
        "max_rank": 1,
        "effect_per_rank": {"forced_boon_order": true}
    }
    
    heat_modifiers["customer_loyalty"] = {
        "name": "Fidelidade do Cliente", 
        "description": "Só pode pegar boons de 1 deus por run",
        "heat_cost": 15,
        "max_rank": 1,
        "effect_per_rank": {"single_god_restriction": true}
    }

func apply_heat_level(target_heat: int):
    var current_heat = _calculate_current_heat()
    
    if target_heat > current_heat:
        _increase_heat_to(target_heat)
    elif target_heat < current_heat:
        _decrease_heat_to(target_heat)
    
    _update_heat_rewards(target_heat)

func _increase_heat_to(target_heat: int):
    var current_heat = _calculate_current_heat()
    var heat_to_add = target_heat - current_heat
    
    # AI suggests best modifiers to reach target heat
    var suggested_modifiers = _suggest_modifier_combination(heat_to_add)
    
    for modifier_id in suggested_modifiers:
        var modifier = heat_modifiers[modifier_id]
        var rank = suggested_modifiers[modifier_id]
        
        if modifier_id in active_modifiers:
            active_modifiers[modifier_id] = min(rank, modifier.max_rank)
        else:
            active_modifiers[modifier_id] = rank

func _suggest_modifier_combination(heat_needed: int) -> Dictionary:
    # AI algorithm to suggest optimal modifier combination
    var suggestions = {}
    var remaining_heat = heat_needed
    
    # Prefer diversity over stacking single modifiers
    var available_modifiers = heat_modifiers.keys()
    available_modifiers.shuffle()
    
    for modifier_id in available_modifiers:
        if remaining_heat <= 0:
            break
            
        var modifier = heat_modifiers[modifier_id]
        var current_rank = active_modifiers.get(modifier_id, 0)
        
        if current_rank < modifier.max_rank:
            var heat_per_rank = modifier.heat_cost
            var max_additional_ranks = min(
                modifier.max_rank - current_rank,
                int(remaining_heat / heat_per_rank)
            )
            
            if max_additional_ranks > 0:
                suggestions[modifier_id] = current_rank + max_additional_ranks
                remaining_heat -= max_additional_ranks * heat_per_rank
    
    return suggestions

func get_heat_reward_multiplier() -> float:
    var total_heat = _calculate_current_heat()
    
    # Exponential rewards for extreme heat
    if total_heat >= 20:
        return 1.0 + (total_heat * 0.15)  # Up to 250%+ at 25 heat
    elif total_heat >= 15:
        return 1.0 + (total_heat * 0.12)
    elif total_heat >= 10:
        return 1.0 + (total_heat * 0.10)
    else:
        return 1.0 + (total_heat * 0.08)
```

---

## 🏛️ **SPRINT 19: THIRD BIOME - SALÃO DO JULGAMENTO**

### **🎯 Objetivos Principais** 
1. **Final Biome:** Salão do Julgamento com 10+ rooms únicas
2. **Judgment Mechanics:** Sistemas de peso moral que afetam gameplay
3. **Ammit Boss:** Boss complexo multi-fase com mecânicas únicas
4. **Divine Trial Rooms:** Puzzle rooms com desafios morais/estratégicos
5. **Endgame Challenge:** Difficulty curve apropriado para players veteranos

### **🏗️ Salão do Julgamento Implementation**

#### **A. Judgment Biome Manager**
```gdscript
# JudgmentHallManager.gd - Final biome with moral weight mechanics
extends BiomeManager
class_name JudgmentHallManager

var player_moral_weight: float = 0.0
var judgment_scales: Array[JudgmentScale] = []
var divine_trials: Array[DivineTrial] = []
var ammit_encounter_ready: bool = false

@export var trial_room_chance: float = 0.3
@export var moral_weight_effects: Dictionary = {}

func _ready():
    super._ready()
    _initialize_judgment_mechanics()
    _calculate_player_moral_weight()

func _initialize_judgment_mechanics():
    # Moral weight affects room generation and enemy behavior
    moral_weight_effects = {
        "heavy_heart": {  # Player made many vengeful choices
            "effect": "more_aggressive_enemies", 
            "enemy_damage_boost": 1.2,
            "trial_difficulty_increase": 0.3
        },
        "light_heart": {  # Player chose justice over vengeance
            "effect": "more_forgiving_trials",
            "trial_skip_chance": 0.2,
            "healing_room_bonus": 1.5
        },
        "balanced_heart": {  # Equal justice and vengeance
            "effect": "standard_judgment",
            "no_modifications": true
        }
    }

func _calculate_player_moral_weight():
    player_moral_weight = GameManager.get_moral_alignment()
    
    # Moral weight determines biome behavior
    if player_moral_weight < -0.3:
        _apply_heavy_heart_effects()
    elif player_moral_weight > 0.3:
        _apply_light_heart_effects()
    else:
        _apply_balanced_heart_effects()

func generate_room() -> RoomData:
    var room_data = super.generate_room()
    
    # 30% chance of Divine Trial rooms
    if randf() < trial_room_chance and divine_trials.size() > 0:
        room_data.room_type = "divine_trial"
        room_data.special_mechanics.append("moral_choice_required")
    
    # All rooms have judgment atmosphere
    room_data.environmental_effects.append("divine_presence")
    room_data.audio_theme = "judgment_hall"
    
    # Moral weight affects room contents
    _modify_room_by_moral_weight(room_data)
    
    return room_data

func _modify_room_by_moral_weight(room_data: RoomData):
    match _get_heart_classification():
        "heavy_heart":
            # More aggressive encounters
            room_data.enemy_count *= 1.2
            room_data.elite_enemy_chance += 0.15
            room_data.environmental_hazards.append("accusatory_whispers")
            
        "light_heart":
            # More supportive encounters
            room_data.healing_fountain_chance += 0.2
            room_data.friendly_spirit_chance = 0.15
            room_data.environmental_effects.append("divine_blessing")
            
        "balanced_heart":
            # Standard encounters with judgment emphasis
            room_data.judgment_scale_chance = 0.4

func _get_heart_classification() -> String:
    if player_moral_weight < -0.3:
        return "heavy_heart"
    elif player_moral_weight > 0.3:
        return "light_heart"
    else:
        return "balanced_heart"
```

#### **B. Divine Trial System**
```gdscript
# DivineTrial.gd - Puzzle rooms with moral/strategic choices
extends Room
class_name DivineTrial

enum TrialType {
    SCALES_OF_JUSTICE,  # Balance moral choices with rewards
    TRIAL_OF_WISDOM,    # Strategic puzzle with multiple solutions
    TEST_OF_MERCY,      # Choice between power and compassion
    JUDGMENT_OF_ACTIONS # Review of player's run history
}

@export var trial_type: TrialType
@export var trial_rewards: Array[Dictionary] = []
@export var trial_consequences: Array[Dictionary] = []

var trial_completed: bool = false
var player_choice_made: String = ""

func _ready():
    super._ready()
    _setup_trial()

func _setup_trial():
    match trial_type:
        TrialType.SCALES_OF_JUSTICE:
            _setup_scales_trial()
        TrialType.TRIAL_OF_WISDOM:
            _setup_wisdom_trial()
        TrialType.TEST_OF_MERCY:
            _setup_mercy_trial()
        TrialType.JUDGMENT_OF_ACTIONS:
            _setup_judgment_review()

func _setup_scales_trial():
    # Player must balance scales with moral choices
    var trial_ui = ScalesTrialUI.new()
    add_child(trial_ui)
    
    var choices = [
        {
            "id": "power_choice",
            "text": "Aceitar poder das trevas para vencer Khaemwaset rapidamente",
            "moral_weight": -0.3,
            "reward": {"dark_boons": 2, "damage_boost": 1.5},
            "consequence": {"moral_degradation": true, "npc_relationships": -2}
        },
        {
            "id": "justice_choice", 
            "text": "Manter integridade e buscar justiça verdadeira",
            "moral_weight": 0.2,
            "reward": {"divine_boons": 1, "moral_strength": 1.2},
            "consequence": {"harder_final_battle": true, "respect_gained": true}
        },
        {
            "id": "balance_choice",
            "text": "Buscar equilíbrio entre justiça e necessidade",
            "moral_weight": 0.0,
            "reward": {"balanced_boons": 1, "tactical_advantage": true},
            "consequence": {"complex_ending_path": true}
        }
    ]
    
    trial_ui.setup_choices(choices)
    trial_ui.choice_made.connect(_on_scales_choice_made)

func _setup_wisdom_trial():
    # Strategic puzzle with multiple valid solutions
    var puzzle = WisdomPuzzle.new()
    add_child(puzzle)
    
    # Different solutions give different rewards
    var puzzle_data = {
        "scenario": "Khaemwaset está cercado por inocentes. Como proceder?",
        "solutions": [
            {
                "id": "direct_assault",
                "name": "Ataque Direto",
                "description": "Confronto direto, arriscando inocentes",
                "difficulty": "Hard",
                "reward": {"combat_boons": 2},
                "moral_cost": -0.15
            },
            {
                "id": "stealth_approach",
                "name": "Abordagem Furtiva",
                "description": "Infiltração para minimizar danos",
                "difficulty": "Very Hard",
                "reward": {"stealth_abilities": true, "precision_bonus": 1.3},
                "moral_gain": 0.1
            },
            {
                "id": "negotiation",
                "name": "Negociação",
                "description": "Tentar conversar antes da violência",
                "difficulty": "Extreme",
                "reward": {"social_resolution": true, "alternative_ending_path": true},
                "moral_gain": 0.2
            }
        ]
    }
    
    puzzle.setup_wisdom_test(puzzle_data)
    puzzle.solution_chosen.connect(_on_wisdom_solution)

func _setup_mercy_trial():
    # Choice between immediate power vs compassionate path
    var mercy_encounter = MercyEncounter.new()
    add_child(mercy_encounter)
    
    # Scenario: Encontra Khaemwaset ferido e vulnerável
    var mercy_scenario = {
        "setup": "Você encontra uma versão ferida de Khaemwaset. Ele está vulnerável.",
        "choices": [
            {
                "id": "execute_immediately",
                "text": "Executar imediatamente - vingança completa",
                "immediate_reward": {"instant_power": 2.0, "vengeance_satisfaction": true},
                "long_term_consequence": {"hollow_victory": true, "dark_ending_only": true},
                "moral_impact": -0.5
            },
            {
                "id": "demand_answers",
                "text": "Exigir respostas sobre o assassinato primeiro", 
                "immediate_reward": {"truth_revealed": true, "story_completion": 0.7},
                "long_term_consequence": {"complex_resolution": true},
                "moral_impact": 0.0
            },
            {
                "id": "show_mercy",
                "text": "Mostrar misericórdia e buscar redenção mútua",
                "immediate_reward": {"divine_favor": 3, "healing_bonus": 1.5},
                "long_term_consequence": {"redemption_ending_unlocked": true},
                "moral_impact": 0.4
            }
        ]
    }
    
    mercy_encounter.setup_mercy_test(mercy_scenario)
    mercy_encounter.mercy_decision_made.connect(_on_mercy_choice)

func _on_scales_choice_made(choice_id: String, choice_data: Dictionary):
    player_choice_made = choice_id
    
    # Apply immediate effects
    GameManager.apply_trial_rewards(choice_data.reward)
    GameManager.apply_trial_consequences(choice_data.consequence)
    GameManager.modify_moral_alignment(choice_data.moral_weight)
    
    # Update NPC relationships based on choice
    _update_relationships_for_choice(choice_id, choice_data)
    
    _complete_trial()

func _update_relationships_for_choice(choice_id: String, choice_data: Dictionary):
    match choice_id:
        "power_choice":
            RelationshipTracker.modify_relationship("Anubis", -3)
            RelationshipTracker.modify_relationship("Ma'at", -5)
            RelationshipTracker.modify_relationship("Nefertari", -2)
        "justice_choice":
            RelationshipTracker.modify_relationship("Anubis", 3)
            RelationshipTracker.modify_relationship("Ma'at", 4)
            RelationshipTracker.modify_relationship("Thoth", 2)
        "balance_choice":
            RelationshipTracker.modify_relationship("Anubis", 1)
            RelationshipTracker.modify_relationship("Ma'at", 1)
            RelationshipTracker.modify_relationship("Ptah", 2)

func _complete_trial():
    trial_completed = true
    
    # Show completion effects
    var completion_ui = TrialCompletionUI.new()
    completion_ui.show_results(player_choice_made, trial_type)
    
    # Open path to continue
    _unlock_room_exit()
    
    # Record trial completion for story tracking
    GameManager.record_divine_trial_completion(trial_type, player_choice_made)
```

#### **C. Ammit Boss Battle**
```gdscript
# AmmitBoss.gd - Complex final boss with unique mechanics
extends Boss
class_name AmmitBoss

enum AmmitPhase {
    DEVOURER_ASPECT,     # Phase 1: Crocodile head attacks
    LIONESS_FURY,        # Phase 2: Lion body attacks  
    HIPPO_STAMPEDE,      # Phase 3: Hippo legs/charging
    DIVINE_JUDGMENT,     # Phase 4: Combined form
    MORAL_RECKONING     # Phase 5: Based on player's moral weight
}

var current_phase: AmmitPhase = AmmitPhase.DEVOURER_ASPECT
var devoured_attacks: Array[String] = []
var moral_judgment_active: bool = false
var player_moral_weight: float = 0.0

@export var crocodile_attacks: Array[AttackPattern] = []
@export var lion_attacks: Array[AttackPattern] = []  
@export var hippo_attacks: Array[AttackPattern] = []
@export var judgment_mechanics: Array[JudgmentMechanic] = []

func _ready():
    super._ready()
    boss_name = "Ammit, a Devoradora de Corações"
    base_health = 4000.0  # Toughest boss
    player_moral_weight = GameManager.get_moral_alignment()
    _setup_moral_dependent_phases()

func _setup_moral_dependent_phases():
    # Final phase changes based on player's moral choices
    if player_moral_weight < -0.4:
        # Heavy heart - Ammit is more aggressive, tries to devour player
        judgment_mechanics.append(_create_devouring_judgment())
    elif player_moral_weight > 0.4:
        # Light heart - Ammit tests player's resolve, not malicious
        judgment_mechanics.append(_create_testing_judgment())
    else:
        # Balanced heart - Standard judgment trial
        judgment_mechanics.append(_create_balanced_judgment())

func _create_devouring_judgment() -> JudgmentMechanic:
    var judgment = JudgmentMechanic.new()
    judgment.type = "devouring"
    judgment.description = "Ammit tenta devorar o coração corrupto do player"
    judgment.mechanics = {
        "heart_devour_attempts": 3,
        "corruption_damage": 50,  # High damage
        "escape_difficulty": "Extreme",
        "redemption_possible": false
    }
    judgment.victory_condition = "Survive all devour attempts through pure skill"
    judgment.defeat_consequence = "True death - no resurrection"
    return judgment

func _create_testing_judgment() -> JudgmentMechanic:
    var judgment = JudgmentMechanic.new()
    judgment.type = "testing"  
    judgment.description = "Ammit testa se player é verdadeiramente justo"
    judgment.mechanics = {
        "moral_trials": 2,
        "compassion_tests": true,
        "damage_reduced": 0.7,  # Less aggressive
        "healing_opportunities": true
    }
    judgment.victory_condition = "Pass moral tests while fighting"
    judgment.defeat_consequence = "Lesson learned, respawn with wisdom"
    return judgment

func execute_attack():
    match current_phase:
        AmmitPhase.DEVOURER_ASPECT:
            _execute_crocodile_attack()
        AmmitPhase.LIONESS_FURY:
            _execute_lion_attack()
        AmmitPhase.HIPPO_STAMPEDE:
            _execute_hippo_attack()
        AmmitPhase.DIVINE_JUDGMENT:
            _execute_combined_attack()
        AmmitPhase.MORAL_RECKONING:
            _execute_moral_judgment()

func _execute_crocodile_attack():
    var attacks = ["snap_bite", "tail_sweep", "water_surge", "devour_attempt"]
    var selected = attacks[randi() % attacks.size()]
    
    match selected:
        "devour_attempt":
            # Unique mechanic: Ammit tries to "eat" player's abilities temporarily
            _perform_ability_devour()
        "snap_bite":
            _perform_targeted_bite()
        "tail_sweep":
            _perform_area_sweep()
        "water_surge":
            _summon_water_hazards()

func _perform_ability_devour():
    # Ammit "devours" one of player's boons temporarily
    var active_boons = GameManager.get_active_boons()
    if active_boons.size() > 0:
        var devoured_boon = active_boons[randi() % active_boons.size()]
        devoured_attacks.append(devoured_boon.id)
        
        # Player loses boon for 30 seconds
        GameManager.temporarily_disable_boon(devoured_boon.id, 30.0)
        
        # Ammit gains version of that boon's power
        _gain_devoured_ability(devoured_boon)
        
        # Visual effect
        _show_devour_effect(devoured_boon.name)

func _execute_moral_judgment():
    # Final phase adapts to player's moral weight
    var judgment = judgment_mechanics[0]
    
    match judgment.type:
        "devouring":
            _execute_devouring_sequence()
        "testing":
            _execute_testing_sequence()
        "balanced":
            _execute_balanced_sequence()

func _execute_devouring_sequence():
    # Aggressive sequence for morally corrupt players
    dialogue_system.play_dialogue("ammit_judgment_corrupt")
    
    # Heart devouring mini-game
    var heart_devour_ui = HeartDevourUI.new()
    add_child(heart_devour_ui)
    
    heart_devour_ui.setup_devour_challenge({
        "attempts_remaining": 3,
        "escape_difficulty": "Extreme",
        "corruption_level": abs(player_moral_weight),
        "damage_per_failure": 50
    })
    
    heart_devour_ui.challenge_completed.connect(_on_heart_devour_result)

func _on_heart_devour_result(survived: bool, attempts_used: int):
    if survived:
        dialogue_system.play_dialogue("ammit_surprised_survival")
        # Player proved their heart isn't completely corrupted
        _transition_to_redemption_phase()
    else:
        # True death sequence
        dialogue_system.play_dialogue("ammit_heart_devoured")
        GameManager.trigger_true_death()  # No respawn

func _transition_to_redemption_phase():
    # Even corrupt players get a chance at redemption
    current_phase = AmmitPhase.MORAL_RECKONING
    
    # Spawn redemption trial
    var redemption_trial = RedemptionTrial.new()
    add_child(redemption_trial)
    
    redemption_trial.setup_final_choice({
        "corrupt_path": "Accept corruption, gain dark power, hollow victory",
        "redemption_path": "Reject corruption, harder fight but true victory possible"
    })
```

---

## 🔧 **SPRINT 20: BOSS INTEGRATION & NARRATIVE CLIMAX**

### **🎯 Objetivos Principais**
1. **Multi-Phase Bosses:** Khaemwaset, Sekhmet e Ammit com fases narrativas
2. **Boss Narrative Integration:** Cada boss revela story elements únicos
3. **Dynamic Boss Behavior:** Bosses reagem ao moral alignment do player
4. **Cinematic Boss Intros:** Sequências épicas pré-battle
5. **Victory Consequences:** Boss defeats impactam story progression

### **🏗️ Integrated Boss System**

#### **A. Narrative Boss Controller**
```gdscript
# NarrativeBossController.gd - Sistema que integra bosses com história
extends Node
class_name NarrativeBossController

var boss_story_states: Dictionary = {}
var player_moral_context: Dictionary = {}
var boss_dialogue_trees: Dictionary = {}

signal boss_narrative_sequence_started(boss_name: String)
signal boss_phase_transition(boss_name: String, old_phase: int, new_phase: int)
signal boss_defeated_with_context(boss_name: String, defeat_context: Dictionary)

func _ready():
    _initialize_boss_narratives()
    _connect_to_bosses()

func _initialize_boss_narratives():
    # Khaemwaset - The Brother Boss
    boss_story_states["Khaemwaset"] = {
        "relationship_history": "brother_assassin",
        "revelation_progression": 0.0,
        "truth_revealed": false,
        "redemption_possible": true,
        "confrontation_type": "personal_betrayal"
    }
    
    # Sekhmet - The Divine Test
    boss_story_states["Sekhmet"] = {
        "relationship_history": "divine_judgment", 
        "test_nature": "warrior_worthiness",
        "fire_trial_passed": false,
        "goddess_approval": 0.0,
        "confrontation_type": "divine_trial"
    }
    
    # Ammit - The Final Judgment
    boss_story_states["Ammit"] = {
        "relationship_history": "ultimate_judge",
        "heart_weight_final": 0.0,
        "moral_reckoning": true,
        "redemption_available": true,
        "confrontation_type": "moral_judgment"
    }

func initiate_boss_encounter(boss_name: String):
    boss_narrative_sequence_started.emit(boss_name)
    
    # Get current story context
    var story_context = _build_story_context_for_boss(boss_name)
    
    # Play narrative intro sequence
    _play_boss_narrative_intro(boss_name, story_context)
    
    # Setup boss behavior based on context
    _configure_boss_for_narrative(boss_name, story_context)

func _build_story_context_for_boss(boss_name: String) -> Dictionary:
    return {
        "player_moral_alignment": GameManager.get_moral_alignment(),
        "story_progress": GameManager.story_milestones_reached,
        "relationships": RelationshipTracker.get_all_relationship_levels(),
        "moral_choices_made": NarrativePersistence.get_moral_choice_summary(),
        "run_performance": GameManager.get_current_run_stats(),
        "previous_boss_outcomes": _get_previous_boss_outcomes(),
        "keepsake_equipped": GameManager.get_equipped_keepsake(),
        "weapon_mastery": GameManager.get_weapon_mastery_levels()
    }

func _play_boss_narrative_intro(boss_name: String, context: Dictionary):
    match boss_name:
        "Khaemwaset":
            _play_khaemwaset_intro(context)
        "Sekhmet": 
            _play_sekhmet_intro(context)
        "Ammit":
            _play_ammit_intro(context)

func _play_khaemwaset_intro(context: Dictionary):
    var moral_alignment = context.player_moral_alignment
    var dialogue_tree = ""
    
    # Different intro based on player's moral journey
    if moral_alignment < -0.3:
        dialogue_tree = "khaemwaset_intro_vengeful"
        # "Brother, I see the darkness has consumed you as it consumed me..."
    elif moral_alignment > 0.3:
        dialogue_tree = "khaemwaset_intro_just"
        # "You've grown wise, brother. Perhaps you can succeed where I failed..."
    else:
        dialogue_tree = "khaemwaset_intro_conflicted"
        # "I see the struggle within you, Khenti. We are more alike than you know..."
    
    # Check if this is first meeting or repeated encounter
    if GameManager.boss_encounter_count["Khaemwaset"] == 0:
        dialogue_tree += "_first_meeting"
    else:
        dialogue_tree += "_return_encounter"
    
    # Play appropriate dialogue
    dialogue_system.play_boss_intro_sequence(dialogue_tree, context)

func _configure_boss_for_narrative(boss_name: String, context: Dictionary):
    var boss_node = get_tree().get_first_node_in_group("current_boss")
    if not boss_node:
        return
    
    match boss_name:
        "Khaemwaset":
            _configure_khaemwaset_narrative(boss_node, context)
        "Sekhmet":
            _configure_sekhmet_narrative(boss_node, context)
        "Ammit":
            _configure_ammit_narrative(boss_node, context)

func _configure_khaemwaset_narrative(boss: KhaemwasetBoss, context: Dictionary):
    # Brother boss changes behavior based on moral alignment
    var moral_alignment = context.player_moral_alignment
    
    if moral_alignment < -0.3:
        # Vengeful player - Khaemwaset is more aggressive, disappointed
        boss.aggression_modifier = 1.3
        boss.dialogue_tone = "disappointed_anger"
        boss.special_attacks.append("shadow_of_corruption")
        boss.redemption_phase_available = false
        
    elif moral_alignment > 0.3:
        # Just player - Khaemwaset is conflicted, holds back initially
        boss.aggression_modifier = 0.8
        boss.dialogue_tone = "conflicted_regret"
        boss.special_attacks.append("echo_of_brotherhood")
        boss.redemption_phase_available = true
        boss.truth_revelation_threshold = 0.6  # Reveals truth earlier
        
    else:
        # Balanced player - Standard behavior with complexity
        boss.aggression_modifier = 1.0
        boss.dialogue_tone = "complex_emotions"
        boss.special_attacks.append("mirror_of_choices")
        boss.redemption_phase_available = true
        boss.truth_revelation_threshold = 0.4

# Continue with Sekhmet and Ammit configurations...
```

#### **B. Khaemwaset Narrative Boss**
```gdscript
# KhaemwasetBoss.gd - Brother boss with deep narrative integration
extends Boss
class_name KhaemwasetBoss

var truth_revelation_progress: float = 0.0
var redemption_phase_active: bool = false
var brother_memories_triggered: Array[String] = []
var final_choice_presented: bool = false

@export var childhood_attacks: Array[AttackPattern] = []  # Phase 1: Childhood memories
@export var corruption_attacks: Array[AttackPattern] = []  # Phase 2: Corrupted prince  
@export var truth_attacks: Array[AttackPattern] = []       # Phase 3: Truth revealed
@export var redemption_attacks: Array[AttackPattern] = []  # Phase 4: Redemption possible

signal truth_revealed(revelation_type: String)
signal redemption_choice_available()
signal brother_bond_memory_triggered(memory_id: String)

func _ready():
    super._ready()
    boss_name = "Khaemwaset"
    base_health = 3500.0
    _setup_brotherhood_mechanics()

func _setup_brotherhood_mechanics():
    # Brother-specific mechanics
    health_changed.connect(_check_truth_revelation)
    player_attack_blocked.connect(_trigger_memory_flash)
    
func _check_truth_revelation():
    var health_percentage = current_health / max_health
    
    # Truth reveals progressively as fight continues
    if health_percentage <= 0.7 and truth_revelation_progress < 0.25:
        _reveal_truth_fragment("assassination_motive")
        truth_revelation_progress = 0.25
        
    elif health_percentage <= 0.5 and truth_revelation_progress < 0.5:
        _reveal_truth_fragment("family_pressure")  
        truth_revelation_progress = 0.5
        
    elif health_percentage <= 0.3 and truth_revelation_progress < 0.75:
        _reveal_truth_fragment("forced_hand")
        truth_revelation_progress = 0.75
        
    elif health_percentage <= 0.15 and truth_revelation_progress < 1.0:
        _reveal_complete_truth()
        truth_revelation_progress = 1.0

func _reveal_truth_fragment(fragment_type: String):
    # Pause combat for story revelation
    _pause_combat_for_story()
    
    match fragment_type:
        "assassination_motive":
            dialogue_system.play_dialogue("khaemwaset_truth_1_motive")
            # "It wasn't jealousy, brother... the priests, they threatened Nefertari..."
            
        "family_pressure":
            dialogue_system.play_dialogue("khaemwaset_truth_2_pressure")
            # "Father's advisors said only one prince could survive the coming war..."
            
        "forced_hand":
            dialogue_system.play_dialogue("khaemwaset_truth_3_forced")
            # "They made me choose: your life or the kingdom's destruction..."
    
    # Show memory flashback
    _play_memory_flashback(fragment_type)
    
    # Resume combat with new context
    _resume_combat_post_revelation()

func _reveal_complete_truth():
    # Final truth: Khaemwaset was manipulated/blackmailed
    _pause_combat_for_story()
    
    dialogue_system.play_dialogue("khaemwaset_complete_truth")
    # Long dialogue revealing full manipulation by dark priests
    
    truth_revealed.emit("brother_was_victim")
    
    # Choice becomes available: Forgive or condemn
    if GameManager.get_moral_alignment() > 0.0:  # Only if player has shown some justice
        _present_final_choice()
    else:
        _continue_to_final_phase()

func _present_final_choice():
    final_choice_presented = true
    redemption_choice_available.emit()
    
    var choice_ui = FinalBrotherChoiceUI.new()
    add_child(choice_ui)
    
    choice_ui.setup_choice({
        "forgive_option": {
            "text": "Perdoo você, meu irmão. Fomos ambos vítimas.",
            "consequence": "redemption_ending_unlocked",
            "moral_gain": 0.3,
            "story_branch": "brotherhood_restored"
        },
        "condemn_option": {
            "text": "A verdade não apaga o que você fez.",
            "consequence": "justice_ending_unlocked", 
            "moral_neutral": true,
            "story_branch": "justice_served"
        },
        "join_option": {  # Only if moral alignment is negative
            "text": "Então vamos destruir quem nos manipulou.", 
            "consequence": "dark_alliance_unlocked",
            "moral_loss": -0.2,
            "story_branch": "brothers_of_vengeance"
        }
    })
    
    choice_ui.choice_made.connect(_handle_final_brother_choice)

func _handle_final_brother_choice(choice_id: String, choice_data: Dictionary):
    GameManager.record_major_story_choice("khaemwaset_fate", choice_id)
    
    match choice_id:
        "forgive_option":
            _execute_forgiveness_sequence()
        "condemn_option":
            _execute_justice_sequence()
        "join_option":
            _execute_alliance_sequence()

func _execute_forgiveness_sequence():
    # Khaemwaset becomes ally for true final boss
    dialogue_system.play_dialogue("khaemwaset_redemption_accepted")
    
    # Transform boss into ally
    _transform_to_ally_mode()
    
    # Unlock special ending path
    GameManager.unlock_story_path("brotherhood_redemption")
    
    # End this encounter, Khaemwaset joins for Ammit fight
    _complete_encounter_as_ally()

func _transform_to_ally_mode():
    # Visual transformation
    _play_redemption_transformation_animation()
    
    # Change from boss to ally
    remove_from_group("enemies")
    add_to_group("allies")
    
    # Give player special boons from brother's gratitude
    var redemption_boons = [
        "brother_bond_strength",    # +20% damage when at low health  
        "shared_royal_heritage",    # Immunity to one lethal hit per room
        "unity_of_purpose"          # Special attacks restore each other's health
    ]
    
    for boon_id in redemption_boons:
        GameManager.grant_special_boon(boon_id, "khaemwaset_redemption")
```

### **📊 Success Metrics Sprint 17-20**

#### **Sprint 17: Combat Juice**
- [ ] **Screen shake calibrated** for each weapon type
- [ ] **Hitstop timing perfect** for impact feel
- [ ] **Particle effects premium** quality for all attacks
- [ ] **Audio feedback responsive** with variations
- [ ] **Damage numbers clear** and satisfying
- [ ] **60 FPS maintained** with all effects active
- [ ] **Combat feel comparison:** Players can't distinguish from Hades

#### **Sprint 18: Weapon Aspects & Heat**
- [ ] **15 weapon aspects** implemented and unique
- [ ] **Heat system scaling** to 25 heat functional
- [ ] **150+ build combinations** viable and tested
- [ ] **Aspect unlock system** tied to achievements
- [ ] **UI for aspects/heat** polished and intuitive
- [ ] **Balance testing:** No aspect dominates all others
- [ ] **Performance:** Aspect switching <1 second

#### **Sprint 19: Third Biome**
- [ ] **Salão do Julgamento** accessible after biome 2
- [ ] **Divine trial rooms** functional with moral choices
- [ ] **Ammit boss battle** with 5 phases working
- [ ] **Moral weight system** affects gameplay significantly  
- [ ] **10+ unique rooms** with judgment theme
- [ ] **Environmental storytelling** clear and impactful
- [ ] **Integration test:** Full 3-biome run works perfectly

#### **Sprint 20: Boss Integration**
- [ ] **All 3 bosses** have narrative integration
- [ ] **Dynamic boss behavior** based on moral alignment
- [ ] **Cinematic intro sequences** for each boss
- [ ] **Multiple victory conditions** for each boss
- [ ] **Story progression** affected by boss outcomes
- [ ] **Voice acting ready:** Placeholder audio for boss dialogue
- [ ] **Performance:** No frame drops during boss cinematics

---

## ✅ **INTEGRATION CHECKLIST - SPRINTS 17-20**

### **Cross-Sprint Dependencies**
- [ ] **Combat juice affects all bosses:** Screen shake, particles, audio
- [ ] **Weapon aspects work in all biomes:** No biome-specific bugs
- [ ] **Heat system scales bosses:** All bosses respect heat modifiers
- [ ] **Boss narratives reference moral choices:** From hub conversations
- [ ] **Performance consistent:** 60 FPS across all new content
- [ ] **Save system complete:** All aspects/heat/choices persist

### **Player Experience Validation**
- [ ] **Combat rivals Hades:** Side-by-side comparison indistinguishable
- [ ] **Build diversity achieved:** 150+ viable combinations verified
- [ ] **Heat provides challenge:** Extreme heat tests skill ceiling
- [ ] **Story emotionally impactful:** Boss defeats feel meaningful
- [ ] **Moral choices matter:** Narrative branches based on decisions
- [ ] **Replayability high:** Multiple paths through all content

---

## 🎯 **SUCCESS CRITERIA - PHASE 3 COMPLETE**

**Content Expansion Achieved When:**
- Combat feel matches or exceeds Hades quality
- Weapon aspects create fundamentally different playstyles  
- Heat system provides scalable challenge for experts
- Third biome offers appropriate endgame difficulty
- Boss battles are narrative climaxes, not just gameplay challenges

**Technical Excellence Markers:**
- 60 FPS locked with all effects and 25 heat active
- Combat response time <16ms for all feedback
- Zero audio stuttering during intense combat
- Boss phase transitions seamless and dramatic
- Save/load preserves all progression perfectly

**Player Experience Goals:**
- "This feels better than Hades combat"
- "Every weapon aspect changes how I play completely"
- "Heat 20+ is genuinely challenging but fair"
- "Boss fights made me emotional about the story"
- "I discovered new build synergies 50 hours in"

---

*"In the depths of the Duat, Khenti-Ka-Nefer becomes not just a warrior, but a force of divine justice whose every action echoes through eternity."*

**Phase 3 Complete → Ready for Final Polish (Sprints 21-24)**