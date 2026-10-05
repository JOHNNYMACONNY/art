# Burnside Production 20 — Sister Kael Silent Core Presence / Choice-Reactive Witness

Issue: #188

Status: `JIT_DESIGN_LOCKED__IMPLEMENTATION_PENDING`

## Player-facing goal

Make the retained Mission-03 / P16 Silent Core climax land on a physically present Sister Kael without creating a second choice, dialogue, relationship, save, mission, or civic authority.

Target loop:

`MISSION 03 COMPLETE -> RETURN TO SILENT CORE -> KAEL PHYSICALLY PRESENT -> RETAINED RELEASE / SEAL RELAYS OWN ACTION -> P16 COMMITS OUTCOME -> KAEL AUTOMATICALLY REACTS -> LEAVE`

Kael is a witness to an existing authored decision. She is not an interaction target.

## Verified starting seams

- Mission 03 remains owned by `CityThatForgotRuntime` / `city_that_forgot_mission.gd`.
- P16 remains sole owner of session-local `UNDECIDED / RELEASED / SEALED` aftermath state.
- P16 creates exactly two retained physical Action targets:
  - `MemoryReleaseRelay`
  - `MemorySealRelay`
- relays arm only after Mission 03 is COMPLETE and the retained legacy pursuit controller is CALM.
- RELEASE requests one retained civic Report; SEAL requests none.
- P08 keeps HS-7 physically carried at `Runner/MeshPivot/Torso/HS7CarrySocket`.
- production Silent Core socket:
  `GearsDistrictSlice01B/SilentCoreSite/SilentCoreSocket`
- Silent Core socket sits on the retained site pad; P20 adds no geography.
- P18 proves a bounded original/procedural authored human can be mounted without a generalized NPC framework.
- no current physical Sister Kael runtime exists.

## Locked P20 architecture

Add one bounded `SisterKaelWitnessRuntime` plus one original/procedural `sister_kael.tscn`.

Mount the runtime from the existing Gears District additive production seam.

The runtime may only:

1. read Mission 03 phase and P16 aftermath state;
2. place/show Kael at the existing Silent Core site;
3. automatically present a short reaction after P16 changes the aftermath state;
4. apply a small outcome-specific pose/presentation difference;
5. reset its own transient presentation on Full Replay.

It may not register an interactable, consume Action, emit a choice, mutate Mission 03, mutate P16 aftermath, mutate Wanted, mutate Field Hacking, or write save state.

## Presence timing

- Before Mission 03 `COMPLETE`: Kael actor exists but is hidden.
- Once Mission 03 reaches `COMPLETE`: Kael becomes visible at the existing Silent Core.
- Kael remains visible through `UNDECIDED`, `RELEASED`, or `SEALED` so a RELEASE civic Report cannot make the witness disappear when Wanted changes.
- Full Replay returning Mission 03 to its locked state hides Kael and clears P20 transient presentation.

## Staging

Use the retained Silent Core socket as the only spatial authority.

Locked actor offset from the socket:

`Vector3(0.0, -0.15, -1.60)`

This places Kael behind the Core, clear of the two P16 relays at approximately +/-1.05 m X and +0.35 m Z.

Kael faces toward the relay/player side.

P20 adds no collider and no pathfinding.

## Reaction authority

P20 must not author a second RELEASE / SEAL truth.

On the first observed transition from `UNDECIDED` to either final state:

- set local reaction mode to the observed P16 state;
- read the already-authoritative `city_runtime.mission.contact_line`;
- present that exact retained Sister Kael line in one bounded automatic character-moment panel;
- increment one local presentation-only reaction counter;
- apply the outcome pose.

Locked poses:

- `RELEASED`: head slightly raised, right arm opened from the body.
- `SEALED`: head slightly lowered, arms held closer / guarded.

The panel auto-clears after a short hold, but the outcome pose may remain while Mission 03 stays COMPLETE.

No player input advances or dismisses this reaction.

## Input / target arbitration invariants

- Kael is never added to the root `_interactables` array.
- Kael owns no `InteractableBase`.
- P16 RELEASE / SEAL relays remain the only aftermath Action targets.
- FIRE / Tool / Strike remain independent.
- mobile/desktop Action routing remains unchanged.
- P20 cannot steal active-target selection from either relay.

## Authority invariants

P20 may not call:

- `choose_memory_release()`
- `choose_memory_seal()`
- `request_civic_report()`
- any Wanted state mutation
- any Field-Hacking mutation
- any mission progression mutation

P16 remains sole aftermath writer.
P01/P02 remain sole civic/Wanted authorities.
P08 remains sole HS-7 presence authority.

## Audio / asset policy

P20 adds no Audio event, voice pipeline, registry entry, or committed third-party game audio.

Temporary private reference audio may be used locally by the project owner, but extracted third-party game audio must remain untracked and outside release artifacts. Release-bound audio remains original/procedural/licensed.

## Save / reset

No save state and no migration.

Full Replay clears P20 transient reaction mode/count/panel and hides Kael until Mission 03 reaches COMPLETE again.

## Required verification

1. physical Kael actor exists but is hidden before Mission 03 COMPLETE;
2. actor becomes visible at the exact retained Silent Core staging after COMPLETE;
3. P20 adds no interaction target;
4. P16 relays remain authoritative and selectable;
5. RELEASE resolves through retained P16, then Kael reacts exactly once to `RELEASED`;
6. RELEASE reaction line equals P16's retained Sister Kael `contact_line`;
7. SEAL resolves through retained P16, then Kael reacts exactly once to `SEALED`;
8. SEAL reaction line equals P16's retained Sister Kael `contact_line`;
9. RELEASE and SEAL produce materially different poses;
10. HS-7 remains physically carried;
11. Full Replay clears P20 transient state while retained P16 reset semantics remain unchanged;
12. retained P16/P18/P19/input/companion regressions remain green;
13. Web export/public packaging remains compatible;
14. rendered proof shows pre-choice Kael + relays, RELEASE reaction, and SEAL reaction.

## Non-goals

No generalized dialogue system, branching conversation UI, approval/relationship meter, NPC schedules/pathfinding, human population framework, hostile-human combat, human Health/death, enemy firearms, weapon breadth, Heat 2-5, witness/surveillance framework, new geography, save migration, voice pipeline, committed third-party game audio, or PR #44 camera work.
