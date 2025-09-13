# Sands of Duat - Roadmap Master Guide

## 🎯 **VISÃO GERAL DO JOGO**

**Sands of Duat** é um ARPG roguelike isométrico 3D inspirado em Hades, mas com mitologia egípcia única. 

**Protagonista:** Khenti-Ka-Nefer, príncipe egípcio de 23 anos assassinado pelo próprio irmão durante uma cerimônia religiosa. Ele luta para escapar do Duat (submundo egípcio) e retornar ao mundo dos vivos para vingar sua morte e salvar sua amada Nefertari.

**Desenvolvimento:** 100% do código por Claude Code + assets gerados por RTX 5070 via IA (pipeline gratuito).

---

## 📊 **STATUS ATUAL DO PROJETO**

**✅ SPRINTS 1-8 COMPLETOS:**
- Project foundation & GameManager architecture
- Player movement & isometric camera  
- Combat system (3 weapons: Was Scepter, Khopesh, Staff)
- Basic enemy AI (3+ types)
- Dash system with i-frames
- Room procedural generation (11 scenes)
- Boon system (20 boons, 4 Egyptian gods)
- Status effects & combat polish

**🎯 ATUAL:** Sprint 9 - Enemy Expansion & AI Enhancement

---

## 📁 **ESTRUTURA DO ROADMAP POR SPRINTS**

### **🚀 FASE 1: CORE MVP (Sprints 9-12)**
**Objetivo:** Completar fundações antes de expandir conteúdo

- **`sprints-09-12-core-mvp.md`** - Foundation Completion
  - Sprint 9: Enemy Expansion (8 novos tipos + AI coordenada)  
  - Sprint 10: Weapon System Complete (5 armas + aspectos)
  - Sprint 11: Advanced Boon System (50+ boons, duo/legendary)
  - Sprint 12: First Boss Battle (Khaemwaset narrativo completo)

### **🏛️ FASE 2: NARRATIVE INTEGRATION (Sprints 13-16)**  
**Objetivo:** Hub world, meta-progressão, sistemas narrativos

- **`sprints-13-16-narrative-hub.md`** - Story Systems Foundation
  - Sprint 13: Hub World (Pool of Memories + NPCs)
  - Sprint 14: Meta-Progression (Memory upgrades + permanente)
  - Sprint 15: Dialogue & Narrative (Sistema de relacionamentos)
  - Sprint 16: Second Biome (Rio de Fogo + Sekhmet boss)

### **⚔️ FASE 3: CONTENT EXPANSION (Sprints 17-20)**
**Objetivo:** Variedade de conteúdo e mecânicas avançadas

- **`sprints-17-20-content-depth.md`** - Advanced Mechanics  
  - Sprint 17: Combat Juice & Feedback (Polish Hades-level)
  - Sprint 18: Advanced Systems (Weapon aspects + Heat system)
  - Sprint 19: Third Biome (Salão do Julgamento + Ammit)
  - Sprint 20: Boss Integration (Multi-phase + narrativa)

### **✨ FASE 4: POLISH & COMPLETION (Sprints 21-24)**
**Objetivo:** Polish final, ending, systems de qualidade

- **`sprints-21-24-final-polish.md`** - Release Preparation
  - Sprint 21: UI/UX Complete (Menus + interface polish)
  - Sprint 22: Narrative Complete (Full dialogue + lore)  
  - Sprint 23: Final Boss & Endings (Osiris + 4 endings)
  - Sprint 24: Performance & Release (Otimização + QA)

---

## 🛠️ **ARQUIVOS DE APOIO TÉCNICO**

### **`integration-templates.md`** - Templates Claude Code
- Templates de sessão com integração obrigatória
- Checklists de testing para cada sprint
- Failure conditions e success metrics

### **`asset-pipeline.md`** - Pipeline de Assets Egípcios  
- Scripts Python para geração automatizada
- Integração Mixamo para animações AAA
- Diretrizes de arte e consistência cultural

### **`technical-specs.md`** - Especificações Técnicas
- Performance targets (60 FPS, loading times)
- Balance formulas (damage, progression curves)
- Architecture patterns (GameManager, signals)

---

## 🎯 **FILOSOFIA DE DESENVOLVIMENTO**

### **Prioridades de Design:**
1. **Narrative First:** Cada sistema reforça a história de Khenti
2. **Research-Based:** Baseado em análise profunda do Hades original  
3. **Integration Mandatory:** Todo sistema DEVE conectar ao GameManager
4. **Egyptian Authenticity:** Mitologia e cultura egípcia respeitada

### **Success Factors:**
- **60 FPS constante** em combate com 8+ inimigos
- **Death feels meaningful** - não apenas reset mecânico
- **100+ viable builds** através de synergias de boons
- **4 different endings** baseados em escolhas morais do player

### **Critical Success Rules:**
- **Never skip integration:** Sistemas isolados = Sprint failure
- **Test in MainGameScene:** Features que só funcionam em test scenes não contam
- **UI real-time updates:** Interface deve responder em <1 frame
- **Performance non-negotiable:** 60fps é requirement absoluto

---

## 📋 **COMO USAR ESTE ROADMAP**

### **Para Development Sessions:**
1. **Leia o arquivo de fase relevante** (sprints-XX-XX-nome.md)
2. **Use templates em integration-templates.md**
3. **Siga specs técnicas detalhadas de cada sprint**
4. **Teste sempre no MainGameScene, nunca em isolation**

### **Para Asset Generation:**
1. **Consulte asset-pipeline.md** para scripts específicos
2. **Execute pipeline temática egípcia** conforme especificado
3. **Mantenha consistência visual e cultural**

### **Para Tracking Progress:**
- **Cada fase tem checklists detalhados** por sprint
- **Marque sprints como completos** apenas após integration testing
- **Use dependencies mapping** para ordem correta de implementação

---

## 🏆 **OBJETIVOS FINAIS**

**MVP (Sprint 12):** Hades clone jogável com 1 bioma completo, 5 armas, 50+ boons, boss battle, meta-progression básica.

**Full Game (Sprint 24):** ARPG polido com 3 biomas + final, 4 endings, narrativa completa, sistema de relacionamentos, 100+ horas de conteúdo.

**Egyptian Authenticity:** Cada elemento visual, narrativo e mecânico honra a mitologia e cultura egípcia autêntica.

---

## 🚦 **QUICK START GUIDE**

**Para continuar development agora:**
1. Abra `sprints-09-12-core-mvp.md` 
2. Vá direto para Sprint 9: Enemy Expansion
3. Use template de integração obrigatória
4. Implemente 8 novos tipos de inimigos com AI coordenada

**Para entender sistemas específicos:**
- Combat & Weapons → Ver Sprint 10 em sprints-09-12-core-mvp.md
- Boons & Progression → Ver Sprint 11 em sprints-09-12-core-mvp.md  
- Narrative & Hub → Ver Sprint 13 em sprints-13-16-narrative-hub.md

---

*"Every death in the Duat brings Khenti closer to the truth of his assassination and the power needed for justice."*

**Ready to continue development? Start with `sprints-09-12-core-mvp.md`!**