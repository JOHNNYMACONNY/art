# Burnside Production 09 — Player Health / Armor / Soft Failure

Authority: issue #149 and the resolved Combat & Tool Promise Contract #115.

## Scope

Production 09 adds one bounded player-survivability tracer to the retained Burnside golden slice.

- PlayerRunner owns Health and Armor.
- Health is bounded to 0–100.
- Armor is bounded to 0–50 and absorbs incoming damage before Health.
- A short hit-immunity window prevents one physical contact from applying damage every frame.
- Health partially recovers only after immediate danger has cleared.
- Armor never passively recovers.
- Health reaching zero triggers Soft Failure: the immediate danger ends, the player returns to the retained recovery geography, and durable/horizontal progression remains intact.

## Initial tuning

- Max Health: 100
- Max Armor: 50
- Initial Armor: 25
- Pursuer interception damage: 35
- Hit immunity: 0.55 seconds
- Safe recovery delay: 3.0 seconds
- Safe recovery rate: 12 Health/second
- Passive recovery cap: 65 Health
- Soft Failure recovery Health: 60
- Soft Failure recovery Armor: 0

These are tracer tuning values, not RPG progression stats.

## Ownership

PlayerRunner is the sole vitals authority. The root controller may:
- supply whether the current world state is safe for passive Health recovery;
- route existing pursuit interception into PlayerRunner damage;
- orchestrate Soft Failure recovery geography and existing pursuit/audio/UI cleanup.

The root controller must not duplicate Health/Armor arithmetic.

## Soft Failure invariant

Soft Failure must not call the broad full-slice reset. It must preserve representative horizontal state including surveyed route knowledge and current authored mission progression.

## HUD

One compact VitalsHUD lives under TouchControlsUI/SafeAreaRoot. It is pointer-transparent and presents Health and Armor without adding a new input owner.

## Non-goals

No firearms, generalized enemy damage AI, medical inventory, armor rarity, equipment levels, body-part damage, bleeding, perks, or RPG stat framework.
