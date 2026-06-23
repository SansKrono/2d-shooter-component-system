# Item & Mastery Synergy System - Phase 1 Implementation

## Summary

Completed Phase 1 of the synergy-based item system from ITEM_AND_MASTERY_DESIGN_PLAN.md. The core detection and resource framework is in place, ready for Phase 2 effect integration.

## What's Implemented

### 1. Extended Relic System
**File:** `resources/relic.gd`
- Added `tags: Array[String]` — descriptive metadata (tech, magic, chaos, precision, offensive, defensive, spreading, utility, corruption)
- Added `rarity: String` — item tiers (common, uncommon, rare, legendary)
- Maintains backward compatibility with existing effect system

### 2. Tagged All 8 Relics
All existing relics now have tags and rarity assigned. Examples:
- **aetheric_kernel** — [magic, offensive, chaos] rarity=rare
- **seeking_algorithm** — [tech, precision, utility] rarity=uncommon
- **biotic_capacitor** — [defensive, utility] rarity=common

### 3. ItemSynergy Resource Class
**File:** `resources/item_synergy.gd`
- Stores synergy pattern (required tags, min count)
- Stores metadata (name, description, build identity, visual effect)
- Implements `matches_inventory(items: Array[Relic])` for pattern matching

### 4. Core Synergy Library (8 Resources)
**Directory:** `resources/synergies/`

**Hacker Archetype:**
- Hacker's Precision (2 tech+precision) — +25% accuracy, pierce +1
- Surgical Strikes (3+ precision) — +50% precision damage
- Tech Specialist (3+ tech) — +20% fire rate

**Mage Archetype:**
- Chaos Overload (2 magic+chaos) — +30% variance, split on impact
- Corruption Mastery (3+ magic) — +40% damage

**Cyborg Archetype:**
- Hybrid Balance (1 tech + 1 magic) — +15% damage

**Universal:**
- Scatter Mastery (3+ spreading) — +25% bullet spread
- Fortress (2+ defensive) — +30% damage reduction

### 5. SynergyManager Singleton
**File:** `systems/SynergyManager.gd`
- Loads all synergies from `res://resources/synergies/` on startup
- Tracks active synergies per player
- Updates on inventory change via `update_synergies(items: Array[Relic])`
- Emits signals: `synergy_activated(synergy)`, `synergy_deactivated(synergy)`
- Registered as autoload in `project.godot`

### 6. SynergyDetectionSystem (ECS)
**File:** `systems/SynergyDetectionSystem.gd`
- Extends System (ECS architecture)
- Queries entities with C_RelicInventory component
- Hooks into C_RelicInventory's `relic_added` signal
- Calls SynergyManager.update_synergies() on changes

### 7. Test Framework
**Files:**
- `tests/test_synergy_system.gd` — Script to verify synergy detection
- `tests/synergy_test.tscn` — Test scene

**Test Coverage:**
- Synergy loading from directory
- Pattern matching (required tags, min count)
- Activation/deactivation on inventory change

## Architecture

```
Relic
├─ tags: ["tech", "precision", ...]
└─ rarity: "uncommon"

ItemSynergy
├─ required_tags: ["tech", "precision"]
├─ min_items_with_tags: 2
└─ name: "Hacker's Precision"

Player (Entity)
└─ C_RelicInventory
   ├─ relics: [Relic, Relic, ...]
   └─ signal relic_added(relic)

SynergyManager (Singleton)
├─ all_synergies: [ItemSynergy, ...]
├─ active_synergies: [ItemSynergy, ...]
└─ update_synergies(items: [Relic])

SynergyDetectionSystem (ECS)
├─ Queries: C_RelicInventory
└─ Listens: relic_added → updates manager
```

## How It Works

1. **Player collects relic** → C_RelicInventory.add_relic() → signal relic_added
2. **SynergyDetectionSystem catches signal** → calls SynergyManager.update_synergies()
3. **SynergyManager checks all synergies** → tests matches_inventory() for each
4. **Newly matching synergies emit activated** → UI can show popups, effects
5. **No longer matching synergies emit deactivated** → UI can fade visuals

## Next Steps (Phase 2)

### Effects System
- Create effect resource classes (DamageMultiplierEffect, PierceEffect, etc.)
- Attach to ItemSynergy.synergy_effects
- SynergyManager applies effects to player entity on activation

### UI/Feedback
- Popup when first synergy activates
- Visual aura (colored glow) during active synergy
- Tooltip in inventory showing active synergies + bonuses

### Integration
- Hook StatRecalculationSystem to read active_synergies and apply multipliers
- Ensure effects compose correctly (no double-multiplying damage)
- Playtest all three archetypes for balance

### Testing
- Run tests/synergy_test.tscn to verify core logic
- Manually test: add relics to player, verify synergies activate
- Verify signals fire at correct times

## Files Modified

- `resources/relic.gd` — extended with tags, rarity
- `resources/relics/*.tres` — 8 relics tagged and rarity assigned
- `project.godot` — added SynergyManager autoload

## Files Created

- `resources/item_synergy.gd` — synergy resource class
- `resources/synergies/` — directory with 8 synergy .tres files
- `systems/SynergyManager.gd` — synergy manager singleton
- `systems/SynergyDetectionSystem.gd` — ECS system for detection
- `tests/test_synergy_system.gd` — test script
- `tests/synergy_test.tscn` — test scene

## Testing

To verify Phase 1 works:
1. Open `tests/synergy_test.tscn` in Godot 4.7
2. Run scene (F5)
3. Check console output for synergy detection results

Expected output:
```
=== Synergy System Test ===
Loaded relics: ...
Synergies loaded: 8
  - Hacker's Precision (["tech", "precision"], min: 2)
  - ...
=== Testing Synergy Detection ===
Empty inventory → 0 active synergies
1 magic+chaos → 0 active synergies
1 magic+chaos + 1 tech+precision → X active synergies
  ✓ Hybrid Balance
```

## Known Limitations

- Synergy effects are placeholders (not yet applied to stats)
- No UI feedback yet (popups, visual auras)
- No integration with StatRecalculationSystem
- No build archetype hints to player

These will be addressed in Phase 2.
