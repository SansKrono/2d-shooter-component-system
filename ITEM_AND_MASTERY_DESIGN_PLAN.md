# Item & Build Design: Synergy-Based Mastery

## Overview

Transform items from flat stat multipliers into a **synergy-driven system** that creates distinct build identities and rewards mastery through discovery and experimentation. Items are tagged (TECH, MAGIC, CORRUPTION, PRECISION, CHAOS, etc.), and synergy patterns detect when certain combinations are unlocked, triggering emergent effects that change how the game plays.

---

## Current State

**What exists:**
- Relic resources with stat_modifier effects
- StatRecalculationSystem accumulates modifiers
- Hardcoded synergies (polyphemus, soy_milk checks)

**The problem:**
- No discovery or mastery reward — items are just stat numbers
- No build identity — a player with 3 random items has no reason to collect specific ones
- No emergent gameplay — synergies are hardcoded, not declarative
- Isaac-like: chaos of stat stacking, no thematic coherence

---

## New Item Architecture

### Item Tags (Descriptive Metadata)

Every relic gets tagged with its properties:

```
TECH_AUGMENTS = ["cpu_core", "overdrive", "encryption_shard"]
MAGIC_RELICS = ["aetheric_kernel", "void_touch", "corruption_vein"]
MODIFIERS = ["precision", "chaos", "piercing", "spreading"]
ATTRIBUTES = ["offensive", "defensive", "utility"]
```

**Tag examples on a single item:**

Item: "CPU Core"
- Tags: ["tech", "offensive", "precision"]
- Base effect: +15% damage, -10% attack speed

Item: "Aetheric Kernel"
- Tags: ["magic", "offensive", "chaos"]
- Base effect: +20% damage (but 30% chance to miss)

Item: "Overdrive Module"
- Tags: ["tech", "utility", "precision"]
- Base effect: +40% fire rate, enemies take 5% extra damage when hit 3+ times

---

## Synergy Detection System

### Core Concept

A **synergy** is a rule that detects when a player has collected items matching a pattern, then applies emergent effects beyond stat stacking.

### Data Structure

```gdscript
class_name ItemSynergy extends Resource

@export var name: String  # "Hacker's Precision"
@export var description: String
@export var required_tags: Array[String]  # ["tech", "precision"]
@export var min_items_with_tags: int = 2  # need 2+ items with these tags
@export var rarity: String  # "common", "uncommon", "rare"
@export var synergy_effects: Array[Resource]  # custom effect objects
@export var visual_effect: String  # VFX feedback ("blue_glow", "precision_aura", etc)
@export var build_identity: String  # "hacker", "mage", "cyborg"

func matches_inventory(items: Array[Relic]) -> bool:
	# Count items with required_tags
	var matching_count = 0
	for item in items:
		var has_all_tags = true
		for tag in required_tags:
			if not item.tags.has(tag):
				has_all_tags = false
				break
		if has_all_tags:
			matching_count += 1
	return matching_count >= min_items_with_tags
```

### Example Synergy Patterns

**Hacker's Precision (Tier 1)**
```
Required tags: ["tech", "precision"]
Min items: 2
Effects:
  - +25% accuracy
  - Bullets pierce 1 additional enemy
```

**Corruption Cascade (Tier 2)**
```
Required tags: ["magic", "corruption"]
Min items: 3
Effects:
  - Corruption spreads 50% faster
  - Enemies in corruption zones deal 30% less damage
  - Charged magic attacks leave corruption zones
```

**Hybrid Cyborg (Tier 2)**
```
Required tags: ["tech", "magic"]  # one of each
Min items: 2
Effects:
  - Tech attacks gain +15% damage vs tech enemies
  - Magic attacks gain +15% damage vs corrupted enemies
  - Switching modes grants brief invulnerability (0.2s)
```

**Overclock (Tier 3)**
```
Required tags: ["tech", "precision", "offensive"]
Min items: 4
Effects:
  - Fire rate doubled
  - Each shot consumes 5% of max charge
  - Charge meter recharges 50% faster
```

---

## Build Archetypes (Thematic Groupings)

### HACKER (Tech Precision)
**Core identity:** Accuracy, control, piercing attacks

**Synergies:**
- Hacker's Precision (2 tech + precision)
- Surgical Strikes (3+ precision items)
- Bullet Hell Mastery (4+ tech items, 500+ bullets landed in run)

**Recommended items:**
- CPU Core (precision, offensive)
- Overdrive Module (precision, utility)
- Firewall Shard (precision, defensive)
- Encryption Rune (tech, utility)

**Playstyle:**
- High fire rate, low spread
- Precise cursor aiming heavily rewarded
- Bullets pierce at high precision
- Environmental hazards (EMP zones) from tech attacks

### MAGE (Magic Chaos)
**Core identity:** Power, unpredictability, area damage

**Synergies:**
- Corruption Cascade (3 magic + corruption)
- Chaos Unfettered (4+ magic items)
- Void Mastery (2 magic + void relic)

**Recommended items:**
- Aetheric Kernel (magic, offensive, chaos)
- Void Touch (magic, defensive)
- Corruption Vein (magic, utility, corruption)
- Chaos Orb (magic, offensive, chaos)

**Playstyle:**
- Lower fire rate, higher damage per shot
- Spreading corruption affects enemies and environment
- Charged attacks create large areas of effect
- Risk: high damage potential but less control

### CYBORG (Hybrid Balance)
**Core identity:** Adaptability, mode switching, dual benefits

**Synergies:**
- Hybrid Cyborg (1 tech + 1 magic)
- Dual Nature (2 tech + 2 magic)
- Tech-Magic Fusion (1 of each of 3 categories)

**Recommended items:**
- CPU Core (tech)
- Aetheric Kernel (magic)
- Resonance Crystal (both tech and magic tags)
- Adaptive Augment (scales based on other items)

**Playstyle:**
- Switch between tech and magic modes based on situation
- Get benefits from both offensive and defensive tech
- Synergies reward balanced collections
- More skill ceiling (timing mode switches)

---

## Item Rarities & Power Curves

### Common (Tier 1)
Items that enable entry-level synergies. Most players will see these first.

Example: "CPU Core" — +15% damage, +10% accuracy
Enables: Hacker's Precision (if you find one more tech item)

### Uncommon (Tier 2)
Specific items that unlock mid-game synergies or modify playstyle significantly.

Example: "Overdrive Module" — +40% fire rate, enemies take extra damage on 3+ hits
Enables: Hacker's Precision (if you already have one tech item)

### Rare (Tier 3)
Powerful items with strong thematic synergies or game-changing effects.

Example: "Aetheric Kernel" — +20% damage (chaos), leave corruption trails
Enables: Corruption Cascade (if you find 2 more corruption items)

### Legendary (Tier 4)
One-of-a-kind items that are powerful standalone but create build-defining synergies.

Example: "Void Heart" — Enemies defeated in corruption zones drop corruption charges; use charges to cast void bolts
Enables: Void Mastery (instant synergy activation alone or with other void items)

---

## Synergy Activation & Feedback

### How Players Discover Synergies

**Option 1: Automatic discovery**
- When a player collects items matching a synergy pattern, a UI popup announces it: "Synergy unlocked: Hacker's Precision! +25% accuracy, bullets pierce."
- The synergy is immediately active

**Option 2: Hidden synergies**
- Player must manually inspect collected items to see available synergies
- Rewards curious, experimental players
- Good for replayability (players might not notice they have a synergy on first run)

**Recommended: Hybrid**
- First time a synergy activates: automatic popup
- Subsequent times: quiet visual aura (blue glow for tech, purple for magic) and stat tooltip

### Visual Feedback

**Tech synergies:**
- Blue-cyan glow around player
- Sharp, geometric VFX on attacks
- Electric crackle on precision hits

**Magic synergies:**
- Purple-pink aura
- Soft, swirling corruption trails
- Magical shimmer on chaos hits

**Hybrid synergies:**
- Dual-colored effect (blue-purple split)
- Fusion visual: tech and magic effects overlay

---

## Stat Recalculation with Synergies

Current system (pseudocode):
```
final_damage = base_damage + dmg_add
final_damage *= dmg_mult
if (has_polyphemus) final_damage *= 2.0
```

New system:
```
final_damage = base_damage + dmg_add
final_damage *= dmg_mult

# Check all active synergies and apply their effects
for synergy in active_synergies:
	if synergy.has_damage_mult:
		final_damage *= synergy.damage_mult
	if synergy.has_special_rule:
		apply_special_rule(synergy, entity)  # pierce, spread, etc.

# Synergies can also unlock entirely new mechanics
if active_synergy.name == "Corruption Cascade":
	entity.add_component(C_CorruptionSpreader.new())
if active_synergy.name == "Hybrid Cyborg":
	entity.add_component(C_ModeSwitch.new())
```

---

## Example Run: Building the Hacker Archetype

**Starting items (basement):**
- CPU Core: +15% dmg, precision
- (Basement clears, gather coins)

**Floor 2 (caves):**
- Find Overdrive Module: +40% fire rate, precision
- **Synergy activates: "Hacker's Precision"**
- Effect: +25% accuracy, bullets pierce 1 extra enemy
- Playstyle shift: Now arrows pierce and accuracy is high — player starts landing more precise shots

**Floor 3:**
- Find Firewall Shard: +10% defense, precision
- Synergy strengthens: "Hacker's Precision" now applies to 3 items instead of 2
- New secondary synergy check: "Surgical Strikes" (3+ precision) activates
- Effect: Precision shots deal 50% extra damage

**Floor 4:**
- Find Encryption Rune: +20% bullet speed, tech
- "Hacker's Precision" still active
- New check: "Overclock" (4 items with tech + precision + offensive) activates
- Effect: Fire rate doubled, charge meter recharges faster
- Playstyle peak: Player is now a bullet-hell master, firing precise, piercing shots at high speed

---

## Implementation Tasks

### Phase 1: Core System (Essential)

1. **Add tags to all existing relics**
   - Modify `Relic` class to include `tags: Array[String]`
   - Retroactively tag aetheric_kernel, seeking_algorithm, etc.

2. **Create `ItemSynergy` resource class**
   - Stores pattern, effects, build identity
   - Implement `matches_inventory()` method

3. **Create synergy library**
   - Directory: `res://resources/synergies/`
   - Create 8-12 core synergies (2-3 per build archetype)
   - Save as `.tres` files

4. **Modify `StatRecalculationSystem`**
   - Query for active synergies
   - Apply synergy effects after base stat calculation
   - Emit signal when synergy activates (for UI)

5. **Add synergy activation UI**
   - Popup on first activation: "Synergy unlocked: [name]"
   - Visual aura (colored glow) while synergy active
   - Tooltip showing current synergies in inventory screen

### Phase 2: Synergy Effects (Gameplay)

1. **Create synergy effect classes**
   - `DamageMultiplierEffect` — increase damage by X%
   - `PierceEffect` — bullets pierce N enemies
   - `CorruptionSpreadEffect` — enhance corruption spreading
   - `ModeSwapEffect` — unlock mode switching bonus

2. **Implement pierce mechanic**
   - Bullet tracks enemies hit
   - On Nth hit, continue traveling instead of disappearing

3. **Implement spread mechanic**
   - Corruption tiles emit new corruption in radius each frame
   - Scales with synergy intensity

4. **Implement mode swap bonus**
   - Switching modes grants brief invulnerability (0.2s) if cyborg synergy active

### Phase 3: Polish & Discovery

1. **Add build identity hints**
   - When player collects items with mostly the same tags, show subtle hint: "You're building a [Hacker/Mage/Cyborg]!"

2. **Create Codex/Bestiary**
   - Log all synergies player has ever unlocked
   - Show synergies they *could* unlock (preview for discovery)
   - Unlock tooltips: "Collect 2 items with tech + precision tags"

3. **Rebalance items for synergy viability**
   - Ensure no single synergy dominates
   - Ensure all three archetypes are viable
   - Playtest coolness factor

---

## Data Structures

### Updated Relic (Resource)
```gdscript
class_name Relic extends Resource

@export var name: String
@export var description: String
@export var tags: Array[String]  # ["tech", "offensive", "precision"]
@export var effects: Array[Resource]  # stat modifiers
@export var icon: Texture2D
@export var rarity: String  # "common", "uncommon", "rare", "legendary"
```

### SynergyManager (New Singleton)
```gdscript
class_name SynergyManager extends Node

var all_synergies: Array[ItemSynergy] = []
var active_synergies: Array[ItemSynergy] = []

func _ready():
	# Load all .tres synergies from res://resources/synergies/
	all_synergies = load_all_synergies()

func update_synergies(player_items: Array[Relic]):
	var newly_active = []
	for synergy in all_synergies:
		if synergy.matches_inventory(player_items) and synergy not in active_synergies:
			newly_active.append(synergy)
			synergy_unlocked.emit(synergy)  # Signal for UI
	active_synergies.append_array(newly_active)

signal synergy_unlocked(synergy: ItemSynergy)
```

---

## Build Identity Visualization (Future UI)

In the pause menu or inventory screen, show a build preview:

```
CURRENT BUILD: Hacker (68% tech, 0% magic)

Active synergies:
  ✓ Hacker's Precision (2/2 items)
  ✓ Surgical Strikes (3/3 items)
  ◇ Overclock (3/4 items) — need 1 more tech item

Bonus stats from synergies:
  + Accuracy: +25% (Precision) +50% (Strikes) = +75%
  + Pierce: 1 → 2 enemies
  + Damage: +50% at 4 items (Overclock preview)

Playstyle: High-precision bullet hell, piercing shots, fast fire rate
```

---

## Balancing Notes

### Synergy Power Levels

Avoid:
- Any synergy that's 5x more powerful than others
- Synergies that lock out other playstyles
- Synergies that are "must-have" (every build needs them)

Aim for:
- Each synergy adds 15-30% effective power
- Stacking synergies adds 30-60% total (multiplicative)
- No single synergy makes a run "won"
- All three archetypes are equally viable

### Item Drop Rates

Balance so that:
- Players see ~4-6 items per run
- Decent chance of unlocking at least 1 synergy per run
- Rare chance of unlocking 3+ synergies (god run)
- Every item has utility even without synergy

---

## Future Extensions (Not Phase 1)

- **Synergy tiers:** Common synergies (2 items), uncommon (3 items), rare (4+ items)
- **Conditional synergies:** "Hacker's Precision only works with TECH attacks"
- **Anti-synergies:** Items that reduce synergy power when combined (risk/reward)
- **Synergy upgrades:** Reliquaries that enhance existing synergies
- **Build slots:** Player can "lock" a build archetype, items auto-sort by compatibility

---

## Testing Checklist

- [ ] All items have tags defined
- [ ] Synergy detection correctly matches inventory combinations
- [ ] Synergies activate on pickup, not on load
- [ ] Synergy effects apply to stats correctly
- [ ] Popup shows when first synergy unlocks
- [ ] Visual aura appears while synergy active
- [ ] Pierce mechanic works (bullets go through N enemies)
- [ ] All three archetypes feel distinct and viable
- [ ] No single synergy is overpowered
- [ ] Players discover synergies organically (not purely RNG-locked)