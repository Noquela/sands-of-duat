# Sands of Duat - Development Roadmap

> **Conceito:** Khenti, um príncipe egípcio assassinado, luta para escapar do Duat (submundo egípcio) e retornar ao mundo dos vivos para vingar sua morte. Um ARPG roguelike isométrico 3D inspirado em Hades, mas com mitologia egípcia única.

> **Objetivo Técnico:** Criar usando Godot 4.x + pipeline de IA automatizada. Claude Code fará 100% do desenvolvimento de código, você fornecerá assets via RTX 5070.

## Stack Tecnológico

### Core Engine
- **Godot 4.3+** (3D com rendering estilizado)
- **GDScript** (linguagem principal)
- **Blender** (opcional, para refinamento)

### Pipeline de IA (RTX 5070) - 100% GRATUITA
- **Flux Dev** (concept art) - Open source
- **InstantMesh** (modelos 3D) - Open source
- **ComfyUI** (interface) - Gratuita
- **Mixamo** (animações) - Adobe gratuito

### Automação
- **Python scripts** (pipeline de assets)
- **Godot CLI** (import automático) 
- **Git** (versionamento)
- **Blender** (refinamento opcional)

---

# SANDS OF DUAT - GAME DESIGN CORE

## Protagonista: Khenti-Ka-Nefer

**Background:** Príncipe herdeiro do Alto Egito, assassinado aos 23 anos durante cerimônia religiosa por seu irmão Ankhef-Sekhmet em conspiração com sacerdotes corruptos liderados por Set.

**Motivação:** Escapar do Duat para retornar ao mundo dos vivos e restaurar justiça, salvando Nefertari (sua amada) forçada a casar com seu irmão traidor.

**Poderes Únicos:**
- **Soul Sight**: Vê através de ilusões e magias
- **Divine Curse**: Não pode morrer permanentemente no Duat  
- **Ancient Wisdom**: Compreende línguas e símbolos antigos
- **Royal Combat Training**: Mestre em armas e táticas

## Panteão Divino & Aliados

### **Thoth - O Escriba** (Mentor)
- **Personalidade**: Intelectual, cauteloso, conflituoso sobre ajudar
- **Oferece**: Boons de magia, conhecimento sobre artefatos
- **Localização**: Biblioteca do Duat

### **Bastet - A Protetora** (Aliada)  
- **Personalidade**: Maternal mas feroz, honra coragem
- **Oferece**: Boons defensivos, healing, speed
- **Localização**: Jardins de Papiro

### **Khnum - O Criador** (Ferreiro)
- **Personalidade**: Pragmático, focado em craft  
- **Oferece**: Weapon upgrades, equipment enhancement
- **Localização**: Forjas Divinas

## Antagonistas Principais

### **Osiris - Juiz dos Mortos** (Boss Final)
- **Papel**: Defensor inflexível da ordem natural vida/morte
- **Boss Fight**: Múltiplas formas, julgamento cósmico

### **Set - O Caos** (Villain Oculto)
- **Revelação**: Manipulador original da conspiração
- **Objetivo**: Usar Khenti para quebrar ordem divina

### **Ammit - A Devoradora** (Boss Recorrente)
- **Papel**: Executora de Osiris, persegue Khenti
- **Mecânica**: Boss fight que se repete, fica mais difícil

## Estrutura do Duat (3 Biomas + Final)

### **1. Cavernas dos Esquecidos** (Tutorial/Bioma 1)
- **Tema**: Melancólico, almas perdidas
- **Boss**: Khaemwaset (Sumo Sacerdote Corrupto)
- **Inimigos**: Shades, Forgotten Warriors, Crystal Golems

### **2. Rio de Fogo** (Bioma 2)  
- **Tema**: Purificação através da dor
- **Boss**: Sekhmet (Lioness of Destruction)
- **Inimigos**: Fire Serpents, Molten Guards, Flame Spirits

### **3. Salão do Julgamento** (Bioma 3)
- **Tema**: Justiça divina, verdade vs mentira
- **Boss**: Ammit (Soul Devourer)
- **Mecânica**: Escolhas morais afetam combat

### **4. Trono de Osiris** (Final Area)
- **Boss**: Osiris (Lord of the Dead)
- **Mecânica**: Consequências de todas escolhas morais

## Sistema de Boons por Divindades

### **Bênçãos de Ra** (Damage/Fire)
- Chama Dourada, Luz Purificadora, Eclipse Solar
- Lança do Amanhecer, Coroa de Fogo

### **Proteção de Bastet** (Defense/Speed)  
- Reflexos Felinos, Salto da Gata, Garras Afiadas
- Caça Noturna, Mãe Protetora

### **Sabedoria de Thoth** (Magic/Utility)
- Língua Antiga, Escrita Sagrada, Olho que Vê Tudo
- Conhecimento Proibido, Palavra de Poder

### **Julgamento de Anubis** (Death/Reaper)
- Pesagem do Coração, Guia dos Mortos, Balança da Verdade
- Veredito Final, Múmia Real

## 4 Endings Baseados em Escolhas

### **A: Vingança** (Path of Rage)
- Khenti mata conspiradores, alma corrompida
- Torna-se tirano pior que irmão

### **B: Justiça** (Path of Truth)  
- Exposição da conspiração, julgamento justo
- Reino próspero, mas Nefertari perdida

### **C: Redenção** (Path of Wisdom)
- Aceita morte, torna-se guardian do Duat
- Protege futuras almas injustiçadas  

### **D: Transcendência** (Hidden Path)
- Reforma sistema do próprio Duat
- Morte/vida não são mais absolutos

## 5 Armas Egípcias Únicas

### **Was Scepter of Ra** (Inicial)
- Controle sobre luz e fogo
- Evolui com aspectos divinos

### **Khopesh** (Sword)
- Balanced, combo-focused
- Aspectos: Pharaoh's Blade, Executioner's Edge

### **Spear of Ra** (Polearm)
- Range, thrust attacks  
- Aspectos solares e divinos

### **Bow of the Winds** (Ranged)
- Charged shots, elemental arrows

### **Staff of Thoth** (Magic)
- AOE abilities, conhecimento arcano

---

# Fase 1: Setup e Foundation (Semanas 1-4)

## Sprint 1: Setup Completo (Semana 1)

### Objetivos
Preparar ambiente completo de desenvolvimento

### Para Você (Setup da IA)
1. **Instalar ComfyUI + Flux Dev**
2. **Configurar TripoSR local**
3. **Testar pipeline de geração**
4. **Criar primeiro asset de teste**

### Para Claude Code (Sessão 1)
```
"Crie um projeto Godot 4.3 novo com:

Estrutura de pastas:
- scenes/ (Player, Enemies, Rooms, UI)
- scripts/ (core, combat, ai, systems)
- assets/ (characters, environment, audio)
- data/ (boons, weapons, enemies)

Setup inicial:
- Projeto 3D configurado
- Configurações de rendering para cel-shade
- Git repository inicializado
- Primeira cena de teste vazia

Entregável: Projeto que compila e roda vazio a 60fps"
```

### Deliverables Sprint 1
- [ ] Projeto Godot funcionando
- [ ] Pipeline IA testada com 1 modelo
- [ ] Estrutura de pastas completa
- [ ] Git configurado

## Sprint 2: Player Controller Base (Semana 2)

### Para Claude Code (Sessão 2)
```
"Implemente player controller 3D isométrico:

Player3D.gd:
- CharacterBody3D com movimento WASD
- Câmera fixa isométrica (45°, distância 12 unidades)
- Movimento suave sem snap-to-grid
- Rotação do personagem para direção do movimento
- Input handling responsivo

Specs técnicas:
- Velocidade: 5.0 unidades/segundo
- Gravidade aplicada
- Collision detection com paredes
- Smooth camera follow com lag mínimo

Use placeholder box mesh enquanto não temos modelo real.
Comente todo o código detalhadamente."
```

### Para Você (Assets)
Gerar primeiro modelo do player:
```python
# Rodar script - Gerar Khenti
python tools/generate_player.py --name "khenti" --style "egyptian_prince_warrior"
# Características: jovem atlético, túnica real azul/dourada, olhos dourados, kohl preto
```

### Deliverables Sprint 2
- [ ] Player se move suavemente em 8 direções
- [ ] Câmera isométrica fixa funcional
- [ ] Primeiro modelo 3D integrado
- [ ] 60fps garantido

## Sprint 3: Sistema de Combate Base (Semana 3)

### Para Claude Code (Sessão 3)
```
"Implemente sistema de combate básico:

CombatSystem.gd:
- Ataques com botão esquerdo mouse
- Hit detection com raycast 3D
- Damage numbers flutuantes
- Hitstop de 0.1s quando acerta
- Combo de 3 ataques básicos

WeaponSystem.gd:
- Sistema de armas switchable
- Stats por arma (damage, range, speed)
- Animações diferentes por arma

HealthSystem.gd:
- Sistema de vida para todos os caracteres
- Morte com animação
- Regeneração de vida

Target: Combate responsivo como Hades, com feedback tátil forte."
```

### Para Você (Assets)
Gerar armas e efeitos egípcios:
```python
# Armas egípcias básicas
python tools/generate_weapons.py --types "khopesh,was_scepter,egyptian_bow" --theme "egyptian"

# VFX com tema egípcio
python tools/generate_vfx.py --effects "hit_impact,damage_numbers,death_explosion,divine_light" --theme "egyptian"
```

### Deliverables Sprint 3
- [ ] Combate funcional com 3 armas
- [ ] Hit detection 100% confiável
- [ ] Feedback visual/audio implementado
- [ ] Sistema de vida robusto

## Sprint 4: Inimigos Básicos + IA (Semana 4)

### Para Claude Code (Sessão 4)
```
"Crie sistema de inimigos com IA:

BaseEnemy.gd:
- CharacterBody3D base para todos inimigos
- Estados: Idle, Chase, Attack, Stagger, Death
- Pathfinding 3D com NavigationAgent3D
- Sistema de vida integrado

EnemyTypes (Egípcios):
1. Shade of the Lost (melee, 100hp, speed 3.0) - Almas perdidas no Duat
2. Mummy Archer (ranged, 80hp, speed 2.0) - Guardas antigos do submundo  
3. Sand Djinn (magic, 120hp, speed 4.0) - Espíritos do deserto

AI Behaviors:
- Detecta player em radius 8.0
- Segue player com pathfinding
- Ataca quando em range
- Telegraph ataques (0.5s warning)
- Knockback quando morrer

EnemySpawner.gd:
- Spawna inimigos em waves
- Máximo 8 inimigos simultâneos
- Balance progressivo

Performance: 60fps com 8+ inimigos ativos"
```

### Para Você (Assets)
Gerar roster de inimigos:
```python
# 10 tipos de inimigos básicos
python tools/generate_enemies.py --count 10 --theme "egyptian_underworld"
```

### Deliverables Sprint 4
- [ ] 3 tipos de inimigos funcionais
- [ ] IA que sente desafiadora mas justa
- [ ] Pathfinding funciona sem travamentos
- [ ] Sistema de spawning balanceado

---

# Fase 2: Core Gameplay Loop (Semanas 5-12)

## Sprint 5: Dash + Habilidades Especiais (Semana 5)

### Para Claude Code (Sessão 5)
```
"Implemente sistema de habilidades avançado:

DashSystem.gd:
- Dash com distância fixa (6 unidades)
- I-frames durante dash (0.3s)
- Cooldown de 2s
- VFX trail durante dash
- Cancela animações de ataque

AbilitySystem.gd:
- Framework para habilidades especiais
- Cooldown system visual
- Mana/energy system
- Input buffering para combos

Special Abilities:
1. Area Slam (AOE damage)
2. Projectile Shot (ranged attack)
3. Shield Block (damage reduction)

Target: Combate tático como Hades, com timing importante."
```

### Deliverables Sprint 5
- [ ] Dash responsivo com i-frames
- [ ] 3 habilidades especiais únicas
- [ ] Sistema de cooldowns funcional
- [ ] Combo system satisfatório

## Sprint 6: Sistema de Salas (Semana 6)

### Para Claude Code (Sessão 6)
```
"Crie sistema de salas procedural:

RoomSystem.gd:
- Geração de salas conectadas
- 4 tipos: Combat, Elite, Treasure, Boss
- Sistema de portas/transições
- Minimap básico

RoomLayouts:
- 15 layouts básicos por tipo
- Spawn points para inimigos
- Posicionamento de rewards
- Conexões válidas entre salas

RoomManager.gd:
- Carregamento dinâmico de salas
- Cleanup automático
- Estado persistente
- Save/load de progresso

Performance: Transição instantânea entre salas"
```

### Para Você (Assets)
Gerar ambientes modulares:
```python
# Tileset modular para salas
python tools/generate_environment.py --theme "egyptian_tomb" --pieces 30
```

### Deliverables Sprint 6
- [ ] 15+ layouts únicos de salas
- [ ] Transições suaves entre áreas
- [ ] Minimap funcional
- [ ] Save system básico

## Sprint 7: Sistema de Boons (Semana 7)

### Para Claude Code (Sessão 7)
```
"Implemente sistema de boons como Hades:

BoonSystem.gd:
- Data structure para boons (JSON/Resources)
- Sistema de raridades (Common/Rare/Epic/Legendary)
- Boon selection UI (3 opções)
- Sistema de stacking

20 Boons Iniciais Temáticos:

**Bênçãos de Ra** (Fire/Light):
- Chama Dourada: +10/20/30% fire damage
- Luz Solar: Ataques cegam inimigos
- Eclipse: AOE burst quando low HP

**Proteção de Bastet** (Defense/Speed):  
- Reflexos Felinos: +15/25/40% dodge chance
- Salto da Gata: +20/40/60 dash distance
- Garras Afiadas: Counter-attack damage

**Sabedoria de Thoth** (Magic/Utility):
- Língua Antiga: +5/10/15% boon rarity  
- Escrita Sagrada: Spell cooldown -20/30/40%
- Olho Místico: Reveal hidden content

**Julgamento de Anubis** (Death/Reaper):
- Pesagem do Coração: Execute <25% HP enemies
- Balança da Verdade: +damage baseado em enemy "guilt"
- Guia dos Mortos: Heal quando enemy dies

BoonRNG.gd:
- Weighted random selection
- Prevent duplicate offerings
- Synergy detection
- Quality scaling with run progress

UI:
- Tooltip system detalhado
- Preview de stats
- Visual feedback de raridade"
```

### Deliverables Sprint 7
- [ ] 20 boons funcionais
- [ ] UI de seleção polida
- [ ] Sistema de raridades balanceado
- [ ] Synergias básicas implementadas

## Sprint 8: Enemy Expansion (Semana 8)

### Para Claude Code (Sessão 8)
```
"Expanda roster de inimigos:

8 Novos Tipos:
1. Pharaoh Mage (teleport, projectiles)
2. Scarab Swarm (fast, weak, numbers)
3. Stone Golem (slow, tanky, smash)
4. Shadow Wraith (phase through walls)
5. Cobra Striker (fast dash attacks)
6. Jackal Hunter (pack coordination)
7. Mummy Brute (heavy melee, slow)
8. Sand Tornado (area control)

AI Improvements:
- Group coordination (pack tactics)
- Player prediction (lead shots)
- Terrain usage (walls, corners)
- Attack telegraphs unique per type
- Elite variants (+50% stats, new abilities)

EnemyManager.gd:
- Spawn balancing by room type
- Difficulty scaling per run
- Performance optimization
- Combat arena management

Target: Cada inimigo força player a jogar diferente"
```

### Para Você (Assets)
```python
# Expandir roster
python tools/generate_enemies.py --batch_size 8 --variations 2
```

### Deliverables Sprint 8
- [ ] 8+ tipos únicos de inimigos
- [ ] IA coordenada e desafiadora
- [ ] Elite variants implementadas
- [ ] Balanceamento inicial calibrado

## Sprint 9: Weapon System Completo (Semana 9)

### Para Claude Code (Sessão 9)
```
"Sistema de armas completo:

5 Armas Egípcias Principais:
1. Was Scepter of Ra (starting weapon) - Divine authority, light/fire
2. Khopesh of Pharaohs - Balanced, royal combat combos  
3. Spear of Ra - Range, solar thrust attacks
4. Staff of Thoth - Magic, knowledge-based AOE
5. Bow of the Winds - Ranged, elemental charged shots

WeaponAbilities.gd:
- Special ability unique per weapon
- Weapon mastery system
- Upgrade paths per weapon
- Boon interactions specific to weapons

WeaponData structure:
- Base damage, attack speed, range
- Special ability cooldown
- Crit multiplier
- Boon compatibility tags

Animation integration:
- Different animation sets per weapon
- Smooth weapon switching
- Attack canceling into dash
- Combo timing per weapon type

Balance: Cada arma viável end-game"
```

### Deliverables Sprint 9
- [ ] 5 armas completamente únicas
- [ ] Sistema de mastery funcional
- [ ] Balanceamento entre armas
- [ ] Animações fluidas

## Sprint 10: Boss Básico (Semana 10)

### Para Claude Code (Sessão 10)
```
"Primeiro boss battle: Khaemwaset (Sumo Sacerdote Corrupto)

Khaemwaset.gd:
- 3 fases de combate
- Boss que revela parte da conspiração
- Padrões de ataque baseados em magia sombria
- 1200 HP total (400 por fase)

Fase 1 (100% → 66% HP): Magia Defensiva
- Barreiras de energia escura
- Invocação de shades menores
- Ataques de projétil sombrio

Fase 2 (66% → 33% HP): Revelação da Traição
- Flashbacks da conspiração durante luta
- Set corruption visível
- Ataques mais agressivos

Fase 3 (33% → 0% HP): Desespero
- Transformação parcial em sombra
- Ataques área massivos
- Revelação de como sair do Duat

Target: 4-6 minutos, narrativamente significativo"
```

### Para Você (Assets)
```python
# Boss + arena egípcios
python tools/generate_boss.py --name "khaemwaset_corrupted_priest" --style "egyptian_dark_magic"
python tools/generate_arena.py --theme "corrupted_egyptian_temple"
```

### Deliverables Sprint 10
- [ ] Boss fight completo e funcional
- [ ] 3 fases distintas e desafiadoras
- [ ] Arena design que suporta mecânicas
- [ ] Victory/defeat flow implementado

## Sprint 11: Boon Expansion (Semana 11)

### Para Claude Code (Sessão 11)
```
"Expandir sistema de boons para 50+:

Categorias de Boons:

ATTACK (15 boons):
- Raw damage multipliers
- Critical hit modifications
- Attack speed bonuses
- Combo extensions
- Weapon-specific buffs

DEFENSE (10 boons):
- Health increases
- Damage reduction
- Block/parry improvements
- Regeneration effects
- Immunity effects

MOBILITY (10 boons):
- Movement speed
- Dash improvements
- Wall-phasing abilities
- Teleportation effects
- Air mobility

UTILITY (15 boons):
- Currency bonuses
- Experience multipliers
- Resource regeneration
- Luck improvements
- Quality of life

Synergy System:
- Tag-based compatibility
- Multiplicative effects quando aplicável
- Visual indicators para synergias
- Tooltip mostra interações

Advanced Features:
- Curse system (negative tradeoffs)
- Legendary boons (game-changing)
- Set bonuses (3+ related boons)
- Boon evolution (upgrade existing)"
```

### Deliverables Sprint 11
- [ ] 50+ boons únicos e testados
- [ ] Sistema de synergias funcionando
- [ ] Legendary boons implementadas
- [ ] Balance pass completo

## Sprint 12: Meta Progression (Semana 12)

### Para Claude Code (Sessão 12)
```
"Sistema de meta-progressão: Pool of Memories

PoolOfMemories.gd (hub area):
- Câmara oculta no primeiro bioma
- Khenti recupera memórias perdidas
- Visual: Pool reflexivo que mostra passado
- NPCs: Ecos de pessoas importantes

MemoryUpgrades.gd (upgrade system):
- Gastar "Memory Fragments" para upgrades permanentes
- Categorias: Royal Training, Personal Life, Divine Knowledge
- 30+ opções de upgrade baseadas em passado de Khenti
- Unlock gates baseados em progresso narrativo

Currency System Egípcio:
- Ankh Fragments (common) - Fragmentos de vida
- Golden Scarabs (rare) - Proteção divina  
- Heart Pieces (boss) - Essência emocional
- Memory Shards (meta) - Lembranças importantes

WeaponAspects.gd:
- Aspectos divinos para cada arma
- Was Scepter: Ra, Khnum, Ptah, Set (hidden/corrupted)
- Khopesh: Pharaoh's Blade, Executioner's Edge, Defender's Curve
- Unlock através de story progression + currency

Target: Meta-progression que reforça narrativa pessoal"
```

### Deliverables Sprint 12
- [ ] Hub area navegável
- [ ] Sistema de upgrades permanentes
- [ ] 4 tipos de currency funcionais
- [ ] Save/load 100% confiável

---

# Fase 3: Content & Polish (Semanas 13-24)

## Sprint 13-16: Biome Expansion (Semanas 13-16)

### Para Claude Code (Sessões 13-16)

**Sprint 13: Biome 2 - Rio de Fogo**
```
"Segundo bioma: Rio de Fogo (Purificação)

FireRiver biome:
- Paleta visual: Vermelhos, laranjas, dourado incandescente  
- 20 layouts únicos com lava flows
- Inimigos: Fire Serpents, Molten Guards, Flame Spirits
- Boss: Sekhmet (Lioness of Destruction)
- Hazards: Lava pools, fire geysers, collapsing bridges

Environmental Systems:
- Lava mechanics (damage over time)
- Fire immunity temporary pickups
- Phoenix platforms (respawning after destruction)
- Heat wave effects (screen distortion)
- Forjas de Khnum (weapon upgrade stations)"
```

**Sprint 14: Biome 3 - Salão do Julgamento**
```
"Terceiro biome: Salão do Julgamento (Moral Choices)

JudgmentHall biome:
- Paleta: Dourado real, mármore branco, verde esmeralda
- Arquitetura: Colunas massivas, hieróglifos brilhantes
- Boss: Ammit (Soul Devourer)
- Inimigos: Judgment Guards, Truth Seekers, Divine Sentinels

Moral Choice Mechanics:
- Scale of Ma'at rooms (choices affect stats)
- Truth vs Lie dialogue battles
- Feather of Truth collectibles
- Judgment consequences visible in environment"
```

**Sprint 15-16: Content Polish**
```
"Polish pass em todos biomes:
- Lighting pass completo
- Audio integration
- Performance optimization
- Visual effects polish
- Gameplay balancing"
```

### Para Você (Assets)
- **Semana 13**: Gerar 30+ assets Rio de Fogo theme (lava, fire spirits, egyptian fire temple)
- **Semana 14**: Gerar 30+ assets Salão do Julgamento (marble halls, scales of maat, judgment symbols)  
- **Semana 15-16**: Polish visual dos 3 biomas + lighting pass egípcio

## Sprint 17-20: Advanced Systems (Semanas 17-20)

### Para Claude Code (Sessões 17-20)

**Sprint 17: Advanced Combat**
```
"Mecânicas avançadas:

ParrySystem.gd:
- Perfect parry timing (0.2s window)
- Parry counter-attacks
- Parry-specific boons

ComboSystem.gd:
- Weapon-specific combos
- Air combos
- Combo finishers
- Combo meter system

StatusEffects.gd:
- Burn, freeze, poison, slow
- Visual feedback por effect
- Resistance system
- Cleansing abilities"
```

**Sprint 18: Boss Battle Advanced - Sekhmet**
```
"Segundo boss: Sekhmet (Lioness of Destruction)

Sekhmet.gd:
- Fierce lioness goddess of war
- Fire/rage-based attacks
- Arena: Rio de Fogo com plataformas móveis
- 3 phases + enraged final form

Fase 1: Stalking Predator
- Leap attacks across lava platforms
- Fire breath streams
- Summon flame cubs

Fase 2: Divine Fury  
- Arena fills with more lava
- Roar attacks (AOE stun)
- Fire tornado mechanics

Fase 3: Protective Mother
- Sekhmet reveals she's testing Khenti's worthiness
- Cooperative final phase
- Unlocks fire immunity boon tree

Narrative: Sekhmet becomes reluctant ally after boss fight"
```

**Sprint 19: Progression Systems**
```
"Sistemas de progressão avançados:

AspectSystem.gd:
- Weapon aspects (variants)
- Hidden aspects unlocks
- Aspect-specific boons
- Visual customization

RunHistory.gd:
- Detailed run statistics
- Personal best tracking
- Failure analysis
- Improvement suggestions

AchievementSystem.gd:
- 50+ achievements
- Hidden achievements
- Progress tracking
- Reward integration"
```

**Sprint 20: Audio & Juice**
```
"Polish pass de feedback:

AudioManager.gd:
- Dynamic music system
- Adaptive audio layers
- Spatial audio 3D
- Audio ducking system

JuiceSystem.gd:
- Screen shake (configurable)
- Hit pause improvements
- Particle system integration
- UI animation polish
- Satisfying SFX timing"
```

## Sprint 21-24: Final Polish & Content (Semanas 21-24)

### Para Claude Code (Sessões 21-24)

**Sprint 21: UI/UX Polish**
```
"Interface polish completo:

MainMenu.gd:
- Animated main menu
- Settings management
- Save file selection
- Achievement gallery

InGameUI.gd:
- Health/mana bars animados
- Boon slots visual
- Minimap improvements
- Damage number optimization

PauseMenu.gd:
- In-run statistics
- Boon review panel
- Quick restart option
- Settings access"
```

**Sprint 22: Narrative Integration**
```
"Sistema de narrativa:

DialogueSystem.gd:
- Character interactions
- Story progression tracking
- Branching dialogue options
- Voice line integration

LoreSystem.gd:
- Collectible lore items
- Codex/journal system
- World building integration
- Optional story content"
```

**Sprint 23: Final Boss & Endings - Osiris**
```
"Boss final: Osiris, Lord of the Dead

Osiris.gd:
- 4 phases representing different aspects
- Uses all mechanics from previous bosses
- Arena: Trono de Osiris (cosmic scale)
- Multiple victory conditions based on player choices

Fase 1: Judge of the Dead (Traditional)
- Weighing heart mechanics
- Truth/lie dialogue during combat
- Scale of Ma'at attacks

Fase 2: Defender of Order
- Environmental control
- Reality-warping attacks
- Tests all player skills

Fase 3: Corrupted by Set (Plot Twist)
- Set's influence revealed
- Osiris becomes more aggressive
- Player can choose to purify or defeat

Fase 4: Resolution (4 Different Endings)
- Vengança: Dark victory, corrupted power
- Justiça: Balanced resolution, sacrifice required  
- Redenção: Heroic sacrifice, becomes guardian
- Transcendência: Reform the system itself

EndingManager.gd:
- Tracks all moral choices throughout game
- Calculates ending based on player path
- Different victory sequences per ending
- Unlocks New Game+ with carried benefits"
```

**Sprint 24: Performance & Release**
```
"Otimização final:

Performance.gd:
- GPU optimization
- Memory management
- Loading time improvements
- Settings auto-detection

Quality assurance:
- Bug fixing pass
- Balance final pass
- Accessibility features
- Platform testing"
```

---

# Templates para Claude Code

## Template de Sessão Efetiva

```
CONTEXTO: Estou criando um Hades clone em Godot 4.x. Você já implementou [sistemas existentes]. Agora preciso de [nova funcionalidade].

ESPECIFICAÇÕES TÉCNICAS:
- Target: 60 FPS em RTX 5070
- Estilo: 3D isométrico cel-shade
- Performance: Máximo X enemies simultâneos
- Compatibilidade: Godot 4.3+

REQUISITOS ESPECÍFICOS:
[Lista detalhada do que deve ser implementado]

RESTRIÇÕES:
- Manter código modular e bem comentado
- Performance não pode degradar
- Compatível com sistemas existentes
- Seguir padrões de código estabelecidos

DELIVERABLES:
[Lista específica do que deve funcionar no final]

TESTING:
Como testar se está funcionando corretamente
```

## Script de Automação Completa

```python
# master_pipeline.py - Gera assets para jogo completo

class HadesPipeline:
    def __init__(self):
        self.assets_generated = 0
        self.total_target = 200  # Assets totais do jogo
        
    def generate_full_game(self):
        """Gera todos assets necessários"""
        
        # Characters (20)
        self.generate_characters()
        
        # Weapons (15) 
        self.generate_weapons()
        
        # Enemies (40)
        self.generate_enemies()
        
        # Environment (100)
        self.generate_environments()
        
        # VFX (25)
        self.generate_effects()
        
        print(f"Game assets completos: {self.assets_generated}/{self.total_target}")
        
    def generate_characters(self):
        characters = [
            {"name": "khenti", "desc": "egyptian prince protagonist"},
            {"name": "thoth", "desc": "ibis-headed god of wisdom"},
            {"name": "bastet", "desc": "cat goddess protector"},
            {"name": "osiris", "desc": "green-skinned lord of dead"},
            {"name": "set", "desc": "chaos god with red skin"},
            {"name": "sekhmet", "desc": "lioness goddess of war"},
            {"name": "ammit", "desc": "crocodile-lion-hippo devourer"},
            # ... todos os NPCs egípcios
        ]
        
        for char in characters:
            self.create_character_complete(char)
            self.assets_generated += 1

# RODAR UMA VEZ NO INÍCIO:
# python master_pipeline.py
# (Gera 200+ assets em 2-3 horas)
```

---

# Métricas de Sucesso

## Performance Targets
- **60 FPS** constante em combate
- **Loading times** < 2s entre salas
- **Memory usage** < 4GB
- **Battery life** 2+ horas em laptop

## Gameplay Metrics
- **Run duration**: 15-25 minutos
- **Death feel fair**: 90%+ deaths "my fault"
- **Boon diversity**: 100+ unique combinations
- **Replay value**: 20+ runs para unlock tudo

## Development Velocity
- **1 bioma** = 4 sprints
- **1 boss** = 2 sprints  
- **20 boons** = 1 sprint
- **Asset generation** = 50+ assets/hora

---

# Checklist Final

## Antes de Começar
- [ ] Godot 4.3+ instalado
- [ ] ComfyUI + Flux funcionando
- [ ] TripoSR configurado
- [ ] Git repository criado
- [ ] Python pipeline testado

## Durante Desenvolvimento
- [ ] Testar cada sprint antes do próximo
- [ ] Manter backups regulares
- [ ] Performance profiling semanal
- [ ] Feedback loop Claude ↔ Assets

## Para Release
- [ ] 3 biomas completos
- [ ] 3 bosses únicos
- [ ] 50+ boons balanceados
- [ ] 5 armas viáveis
- [ ] Meta-progression satisfatória

---

---

# Audio Design Roadmap

## Fase 1: Audio Foundation (Sprints 5-8)

### Sprint 5: Audio Manager & Basic SFX
```
"Implemente sistema de audio robusto:

AudioManager.gd (Singleton):
- Audio bus management (Master, SFX, Music, Voice)
- Dynamic volume controls
- Audio pooling para performance
- 3D spatial audio para combat
- Audio ducking system

BasicSFXLibrary:
- Hit sounds (metal, flesh, magic) - 15 variations
- Movement (footsteps, dash, land) - 10 variations  
- UI sounds (click, hover, transition) - 8 variations
- Ambient (wind, fire, water) - 12 loops

SFXPlayer.gd:
- One-shot audio com pitch variation
- Distance-based volume falloff
- Audio occlusion básica
- Performance optimization (max 32 voices)

Target: Audio responsivo < 10ms latency"
```

### Sprint 8: Dynamic Music System
```
"Sistema de música adaptive:

MusicManager.gd:
- Layer-based music system
- Smooth transitions combat ↔ exploration
- Boss music com intensity layers
- Biome-specific themes

Music Tracks Needed:
- Exploration_Base.ogg (loop, 2 min)
- Combat_Low.ogg (builds tension)
- Combat_High.ogg (full intensity)
- Boss_Intro.ogg (dramatic entry)
- Boss_Battle.ogg (loop, high energy)
- Victory.ogg (triumph theme)
- Defeat.ogg (somber respawn)

AudioCrossfade.gd:
- Fade durations: 2s exploration, 0.5s combat
- Tempo matching between tracks
- Volume automation curves

Egyptian Instruments:
Use samples: oud, ney, tabla, sistrum, harp"
```

### Sprint 15: Voice & Narrative Audio
```
"Sistema de voice acting:

VoiceSystem.gd:
- Character voice line triggering
- Subtitle system com timing
- Voice interruption handling
- Language localization ready

Voice Line Categories:
- Combat barks (effort, hit, victory) - 20 per character
- Story dialogue (main quest) - 200+ lines
- Flavor text (boon pickup, discovery) - 100+ lines
- Tutorial/hint voices - 30 lines

AudioLocalizer.gd:
- Multi-language voice support
- Subtitle synchronization
- Cultural audio adaptation
- Accessibility features (visual sound indicators)"
```

---

# UI/UX Design Roadmap

## Fase 1: Core Interface (Sprints 3-6)

### Sprint 3: HUD & Combat Feedback
```
"Interface de combate responsiva:

CombatHUD.gd:
- Health bar (smooth animation, pulse em low health)
- Mana/energy bar (color coding per type)
- Ability cooldowns (radial progress, visual ready state)
- Combo counter (stylized, fades after combo ends)
- Damage numbers (floating, color coded, physics)

Visual Hierarchy:
- Health: Top priority, sempre visível
- Abilities: Secondary, contextual visibility
- Numbers: Temporary, não obstrutivo
- Minimap: Tertiary, toggleable

Performance UI:
- Max 60 UI elements simultâneos
- Object pooling para damage numbers
- Efficient text rendering
- 60fps maintained durante combat intensity

Egyptian UI Theme:
- Papyrus textures para backgrounds
- Hieroglyph symbols como icons
- Gold accent colors
- Sandstone frame elements"
```

### Sprint 6: Menu Systems
```
"Sistema de menus completo:

MainMenu.gd:
- Animated title screen
- Save file selection (3 slots)
- Settings access
- Achievement gallery
- Smooth transitions

PauseMenu.gd:
- Pause sem quebrar game feel
- Quick settings access
- Run statistics display
- Boon review panel
- Resume/restart/quit options

SettingsMenu.gd:
- Graphics settings (resolution, quality presets)
- Audio settings (master, sfx, music, voice)
- Input remapping
- Accessibility options
- Apply/revert system

Navigation:
- Controller + keyboard navigation
- Breadcrumb system
- Consistent back/cancel behavior
- Visual feedback para hover/selection"
```

### Sprint 11: Boon Selection Interface
```
"UI de seleção de boons (core do jogo):

BoonSelectionUI.gd:
- 3 boons presented elegantly
- Detailed tooltips com stats preview
- Rarity visual indication (border, glow, particles)
- Synergy highlighting (shows interactions)
- Comparison com current build

BoonTooltip.gd:
- Current stats vs improved stats
- Synergy explanations
- Flavor text integration
- Dynamic positioning (never off-screen)

Visual Polish:
- Card-based layout
- Smooth hover animations  
- Egyptian iconography por boon type
- Color coding consistent throughout
- Satisfying selection feedback (particles, sound)

UX Flow:
- Clear visual hierarchy (rarity → power → synergy)
- Quick decision making (5-10 seconds typical)
- Regret prevention (confirmation for major choices)
- Skip option for speed runners"
```

## Fase 2: Advanced UX (Sprints 12-20)

### Sprint 12: Meta Progression Interface
```
"Pool of Memories interface:

MetaProgressionUI.gd:
- Skill tree visualization (constellation style)
- Currency display (Memory Fragments)
- Preview upgrade effects
- Unlock requirements clear
- Progress tracking visual

UpgradeTree.gd:
- Node-based layout (Egyptian constellation theme)
- Dependency lines between upgrades
- Hover previews para each node
- Purchase confirmation
- Visual progression feedback

Investment Strategy:
- Show stat improvements numerically
- Compare builds/loadouts
- Suggest next upgrades
- Calculate efficiency ratios

Visual Design:
- Stars/constellation metaphor
- Golden lines connecting nodes
- Glowing effects para available upgrades
- Dimmed/locked appearance para unavailable"
```

### Sprint 18: Advanced Combat UI
```
"Interface polida para combat avançado:

CombatUI_Advanced.gd:
- Boss health bars (segmented por phases)
- Status effect indicators (visual + timer)
- Combo meter com visual feedback
- Threat indicators (off-screen enemies)
- Environmental hazard warnings

BossEncounterUI.gd:
- Dramatic boss introductions
- Phase transition indicators
- Weakness/vulnerability hints
- Epic moment highlighting
- Victory celebration sequence

StatusEffectDisplay.gd:
- Icon-based status tracking
- Stack counter para stackable effects
- Duration bars
- Priority ordering (harmful first)
- Color coding by effect type"
```

---

# Balance & Analytics Roadmap  

## Fase 1: Data Collection (Sprints 4-12)

### Sprint 4: Core Metrics Framework
```
"Sistema de analytics integrado:

AnalyticsManager.gd:
- Player action tracking
- Performance metrics collection
- Death/failure analysis
- Progression speed monitoring
- Session length tracking

Core Metrics:
- Deaths per room type
- Most used abilities
- Boon selection patterns
- Average run duration
- Quit points analysis

DataCollector.gd:
- Non-intrusive data gathering
- Local storage (privacy-first)
- Export capabilities para analysis
- Real-time dashboard básico

Privacy:
- Opt-in analytics only
- No personal data collection
- Clear data usage explanation
- Easy opt-out mechanism"
```

### Sprint 8: Balance Testing Framework
```
"Automated balance testing:

BalanceTester.gd:
- Simulated player runs
- DPS calculations
- Survivability testing
- Build viability analysis
- Edge case detection

TestScenarios:
- Glass cannon builds (high damage, low health)
- Tank builds (high health, low damage)
- Speed builds (mobility focused)
- Magic builds (ability focused)
- Hybrid builds (balanced approach)

AutoBalance.gd:
- Detect overpowered combinations
- Suggest balance adjustments
- A/B test different values
- Statistical significance testing

Performance:
- Run 1000 simulated games
- Identify balance outliers
- Generate balance reports
- Suggest specific number changes"
```

## Fase 2: Advanced Balance (Sprints 13-24)

### Sprint 15: Player Behavior Analysis
```
"Analytics avançadas:

PlayerBehaviorTracker.gd:
- Heatmaps de movement
- Combat pattern analysis
- Learning curve measurement
- Frustration point detection
- Skill ceiling analysis

BehaviorInsights:
- Where players get stuck
- Which abilities are underused
- Optimal vs actual play patterns
- Decision making patterns
- Retention correlation factors

AdaptiveDifficulty.gd:
- Dynamic difficulty adjustment
- Invisible assistance para struggling players
- Challenge scaling para experts
- Confidence building mechanics
- Flow state maintenance"
```

### Sprint 20: Economy & Progression Balance
```
"Sistema econômico balanceado:

EconomyManager.gd:
- Currency earning rates
- Upgrade cost curves
- Progression gate timing
- Resource scarcity management
- Player spending patterns

ProgressionAnalytics:
- Time to unlock each weapon
- Upgrade purchase priorities
- Grinding vs skill progression
- Satisfaction correlation
- Retention impact

AutoEconomyBalance.gd:
- Detect currency imbalances
- Adjust earning rates dynamically
- Prevent grinding requirements
- Maintain meaningful choices
- Scale with player skill level"
```

---

# Implementation Strategy

## Como Integrar aos Sprints Existentes

### **Audio Integration:**
- Sprint 5: Basic SFX com combat system
- Sprint 8: Dynamic music com enemy expansion  
- Sprint 15: Voice lines com narrative system

### **UI Integration:**
- Sprint 3: Combat HUD com combat system
- Sprint 6: Menu systems com room system
- Sprint 11: Boon UI com boon expansion

### **Balance Integration:**
- Sprint 4: Metrics framework com enemy AI
- Sprint 8: Balance testing com boon system
- Sprint 15: Advanced analytics com boss battles

## Template para Prompts de Claude

### **Audio Session Example:**
```
"CONTEXTO: Sands of Duat, Sprint 8. Já temos combat system, enemies, e room system funcionando.

AGORA IMPLEMENTAR: Dynamic Music System conforme Audio Roadmap.

SPECS:
- Layer-based music (exploration + combat layers)
- Smooth transitions (2s fade para exploration, 0.5s para combat)
- Biome-specific themes
- Boss music com intensity scaling

DELIVERABLES:
- MusicManager.gd funcional
- 3 music tracks integrados
- Transition system suave
- Performance optimizada

TESTING: Music deve responder a combat state em <0.5s"
```

**Bottom Line:** Este roadmap entrega um Hades clone profissional em 6 meses, com Claude Code fazendo todo o desenvolvimento e sua RTX 5070 gerando assets automaticamente. Cada sprint tem deliverables claros e testáveis.

---

# Quick Start Guide

## Para Começar Imediatamente

1. **Configure sua pipeline de IA primeiro**
2. **Use este comando para sua primeira sessão:**
   ```
   "Siga exatamente o Sprint 1 do ROADMAP.md para Sands of Duat. Crie projeto Godot 4.3 com estrutura completa para ARPG 3D isométrico egípcio."
   ```
3. **Mantenha este documento aberto durante desenvolvimento**
4. **Use os templates fornecidos para cada sessão**

## Arquivos de Apoio a Criar (Pipeline Egípcia)
- `tools/generate_player.py` - Khenti e variações visuais
- `tools/generate_gods.py` - Thoth, Bastet, Osiris, Set, etc
- `tools/generate_enemies.py` - Inimigos do Duat egípcio
- `tools/generate_weapons.py` - Was scepter, khopesh, armas divinas
- `tools/generate_environment.py` - Ambientes do submundo egípcio
- `tools/generate_bosses.py` - Khaemwaset, Sekhmet, Ammit, Osiris
- `tools/master_pipeline.py` - Pipeline completa temática

## Lore Integration nos Assets
Todos os assets gerados devem seguir:
- **Autenticidade egípcia**: Hieróglifos, símbolos, cores tradicionais
- **Narrativa visual**: Assets contam história da conspiração
- **Degradação moral**: Ambientes mostram corrupção de Set
- **Simbolismo divino**: Cada deity tem visual signature única

**Ready to start building Sands of Duat? Use Sprint 1!**

---

# NARRATIVE DESIGN COMPLETE ✓

O roadmap agora integra completamente a narrativa de **Sands of Duat** com todos os elementos técnicos. Khenti's journey através do Duat egípcio está mapeada em 24 sprints, com cada sistema de gameplay reforçando a história pessoal do príncipe assassinado lutando pela justiça. O jogo entregará 4 endings únicos baseados nas escolhas morais do player, com mitologia egípcia autêntica integrada em todos os aspectos do desenvolvimento.