# Burnside Production 19 — Wanted Pursuer Sidearm Suppression / Contact-Break Composition

Issue: #184

Status: `JIT_DESIGN_LOCKED__IMPLEMENTATION_PENDING`

## Player-facing goal

Make the retained Production-17 sidearm compose with the retained Heat-1 physical pursuer without creating Health/death or bypassing Wanted observation.

Target loop:

`HEAT 1 + CONTACT -> PURSUER CLOSES -> SIDEARM HIT -> BRIEF HESITATION -> PLAYER USES COVER/ROUTE -> RETAINED LOS LOGIC DECIDES CONTACT OR SEARCH`

The firearm creates opportunity only. It never awards evasion.

## Verified starting seams

- `PursuerPrototype.max_speed = 15.5 m/s`.
- Runner on-foot `move_speed = 8.5 m/s`.
- P05 Scrapper stagger is `0.30 s` with `3.3 m/s` shove and explicit physical displacement.
- P17 FIRE cooldown is `0.32 s`.
- Wanted Contact loss requires `0.8 s` of physical LOS loss.
- P17 performs one ray per accepted shot and currently grants firearm damage only to retained `utility_crawlers`.
- `PursuerPrototype` already owns bounded local physical response seams and belongs to group `pursuers`.
- `BurnsideWantedRuntime` remains the only owner of CONTACT -> SEARCH through `has_direct_observation()` and `lose_contact()`.

## Locked P19 response

A valid sidearm ray that physically reaches the active pursuer may request:

`PursuerPrototype.apply_sidearm_suppression() -> bool`

Accepted only while the pursuer is active in `CHASING` or `DETOURING`.

Locked tuning:

- suppression duration: **0.18 s**
- chase translation during suppression: **35% of retained current_speed**
- no displacement impulse
- no `current_speed` reset
- no target-node change
- no chase/detour state change
- interception timer is cleared while suppression is active
- one brief visible body/siren hit reaction
- P05 Scrapper stagger supersedes/rejects overlapping P19 suppression
- reset/de-escalation/EMP/vehicle stun deterministically clear P19 local state

Why these values:

At retained max chase speed, perfect repeated FIRE at the 0.32 s cooldown produces an approximate average pursuer translation speed of:

`((15.5 * 0.35 * 0.18) + (15.5 * 0.14)) / 0.32 ~= 9.8 m/s`

That remains faster than the Runner's 8.5 m/s, so repeated shots cannot win a straight open-road foot chase. The 0.18 s hesitation is also far shorter than the retained 0.8 s Contact-loss grace, so P19 cannot synthesize SEARCH by timing alone.

The player must use actual geometry to break observation.

## Scrapper distinction

Scrapper remains:

- close-range
- 0.30 s
- physical shove/displacement
- stronger immediate body-space control

Sidearm becomes:

- ranged
- noisy through retained P17 consequence
- 0.18 s movement hesitation
- no displacement
- weaker body-space control
- route-entry opportunity only

## Ballistic dispatch boundary

P17's one retained ray remains authoritative.

Resolution order stays closed and bounded:

1. retained `utility_crawlers` may receive existing P17 `take_hit(1,...)`;
2. otherwise, an ancestor in group `pursuers` with `apply_sidearm_suppression` may receive the P19 request;
3. otherwise ordinary impact/miss feedback only.

No generalized damage interface, target registry, weapon framework, NPC Health, or combat bus is introduced.

Environment collision continues to occlude the ray normally.

## Wanted authority invariants

P19 may not:

- clear or modify Heat;
- call `WantedAuthority`;
- call `lose_contact()`, `reacquire()`, `observe_contact()`, or `advance_search()`;
- write CONTACT / SEARCH;
- move or rewrite the search anchor;
- clear or replace `target_node` as a knowledge shortcut;
- synthesize evasion.

Required proof:

- sidearm suppression with clear LOS remains CONTACT;
- genuine Commercial Frontage LOS loss for the retained grace produces SEARCH through `BurnsideWantedRuntime`;
- genuine observation reacquisition restores CONTACT through retained Wanted logic.

## Input / consequence invariants

Retain P17 ownership unchanged:

- desktop/mobile FIRE use the existing `weapon_action_pressed` route;
- synthetic touch/mouse duplication protections remain P17-owned;
- Action / Tool / Strike remain separate;
- one accepted FIRE still performs exactly one ballistic query;
- P17 local gunfire consequence remains intact;
- no Audio event or registry change.

## Reset / compatibility

Full Replay and pursuer reset must clear P19 transient suppression.

No save state and no migration.

Retain compatibility with:

- P01 Wanted / Contact-Search;
- P02 Field Hacking / Report;
- P03 Missions;
- P04 work-zone consequence;
- P05 Scrapper;
- P14 Garage services/customization;
- P17 sidearm;
- P18 Mayor Burn encounter;
- FB-13 / HS-7 presence;
- desktop/mobile input contracts;
- Web export/public packaging.

## Non-goals

No generalized human combat, NPC Health/death, executions, weapon roster, ammo/reload, inventory, enemy firearms, Heat 2-5, generalized witnesses, cover system, new geography, save migration, unrelated Audio, or PR #44 work.

## Completion gate

`RED -> GREEN -> exact-head focused + retained verification -> rendered/runtime proof -> frozen review -> merge -> exact-main verification -> public source-stamp verification -> continuity -> close #184`
