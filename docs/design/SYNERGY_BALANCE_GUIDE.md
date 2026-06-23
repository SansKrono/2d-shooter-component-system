# Synergy System - Balance & Testing Guide

## Balance Objectives

Ensure all three archetypes are equally viable and feel distinct:
- **Hacker:** High precision, fast fire rate, accuracy bonuses
- **Mage:** High damage, chaos effects, spreading attacks
- **Cyborg:** Balanced damage, flexibility, hybrid benefits

## Current Synergy Power Levels

### Hacker Path
- **Hacker's Precision** (2 tech+precision): +25% accuracy
- **Surgical Strikes** (3+ precision): +50% damage
- **Tech Specialist** (3+ tech): +20% fire rate

Stacking potential: 25% accuracy + 50% damage + 20% fire rate = strong control build

### Mage Path
- **Chaos Overload** (2 magic+chaos): +40% damage
- **Corruption Mastery** (3+ magic): +40% damage

Stacking potential: +40% + 40% = +96% multiplicative damage (1.4 × 1.4 = 1.96)

### Cyborg Path
- **Hybrid Balance** (1 tech + 1 magic): +15% damage

Stacking potential: Low bonus, encourages mixing

### Universal
- **Scatter Mastery** (3+ spreading): +25% spread
- **Fortress** (2+ defensive): +30% damage reduction

## Testing Checklist

### Synergy Activation
- [ ] Hacker's Precision activates with 2 tech+precision items
- [ ] Surgical Strikes activates with 3+ precision items
- [ ] Tech Specialist activates with 3+ tech items
- [ ] Chaos Overload activates with 2 magic+chaos items
- [ ] Corruption Mastery activates with 3+ magic items
- [ ] Hybrid Balance activates with 1 tech + 1 magic
- [ ] Scatter Mastery activates with 3+ spreading items
- [ ] Fortress activates with 2+ defensive items

### Effect Application
- [ ] Damage multipliers apply to final damage calculation
- [ ] Accuracy bonuses are readable in stat sheet
- [ ] Fire rate changes are visible in gameplay
- [ ] Damage reduction reduces incoming damage

### UI Feedback
- [ ] Popup shows on first synergy activation
- [ ] Popup disappears after 3 seconds
- [ ] Synergy panel shows active synergies
- [ ] Aura color changes based on active synergies
  - [ ] Blue for tech (hacker)
  - [ ] Purple for magic (mage)
  - [ ] Magenta for hybrid (cyborg)

### Gameplay Balance
- [ ] Hacker build feels fast and precise (high fire rate, accuracy)
- [ ] Mage build feels powerful and chaotic (high damage, spreading)
- [ ] Cyborg build feels flexible (mixed benefits, mode switching potential)
- [ ] No single synergy is "must-have"
- [ ] All three archetypes can clear a full run

## Power Scaling

Current damage multipliers (multiplicative):
```
Hacker max: 1.0 × 1.5 (Surgical Strikes) = +50% dmg
Mage max: 1.4 × 1.4 (Chaos + Corruption) = +96% dmg (1.96×)
Cyborg: 1.15 (Hybrid) = +15% dmg
```

**Issue:** Mage is ~2x stronger than Hacker. Consider:
- Option A: Nerf Mage multipliers (1.3 × 1.3 = 1.69)
- Option B: Buff Hacker with additional synergies
- Option C: Make Hacker more valuable through non-damage bonuses (accuracy = precision avoids overkill)

## Recommendations for Tuning

If playtesting reveals imbalance:

1. **If Mage is too strong:** Reduce effect multipliers
   - Chaos Overload: 1.4 → 1.3
   - Corruption Mastery: 1.4 → 1.3

2. **If Hacker is too weak:** Add damage synergy
   - Create new: "Overclocked" (3 tech+precision) → +30% damage

3. **If Cyborg feels useless:** Buff Hybrid Balance
   - Hybrid Balance: 1.15 → 1.25

4. **If defensive items are never picked:** Buff Fortress
   - Fortress: +30% reduction → +40% reduction

## Playtesting Flow

1. Start fresh run, pick items as they spawn
2. Track when synergies activate
3. Notice gameplay changes (damage spikes, speed changes)
4. Play through 3-5 rooms per archetype
5. Note:
   - Does archetype feel powerful?
   - Does it feel distinct from others?
   - Is there one "best" build?
   - Are any items useless?

## Future Extensions

After basic balance is verified:
- Add more synergies (10 → 20 total)
- Create synergy tiers (common/uncommon/rare)
- Add synergy upgrades (Reliquaries that boost existing synergies)
- Implement anti-synergies (items that reduce synergy power)

## Metrics to Track

- **Synergy activation rate:** % of runs where each synergy is found
- **Damage output:** Compare archetype damage over time
- **Player success rate:** % of players clearing final boss per archetype
- **Build diversity:** How many distinct synergy combinations are viable

## Known Unknowns

- Effect of synergies on enemy difficulty scaling
- Interaction with existing hardcoded synergies (polyphemus, soy_milk)
- Balance of stat multipliers with existing items
- Whether +30% damage reduction is noticeable to player
