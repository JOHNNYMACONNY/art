# Burnside Production 16 — The City That Forgot / Memory Disclosure Choice

**Status:** JIT DESIGN LOCKED / IMPLEMENTATION CONTRACT  
**Issue:** #175  
**Baseline:** current docs-only main `984fec069a5a2d7fbed3992f4845a5f9006ff3fd`  
**Exact gameplay/public predecessor:** P15 `9708686f5f5a8cd9f606b238186aca9f3e999cc1`

## Player-facing purpose

Mission 03 currently ends with Sister Kael telling Runner to decide what deserves daylight, but the player cannot actually decide. P16 fulfills that authored promise with one bounded physical choice at the existing Silent Core.

`COMPLETE MISSION 03 ESCAPE -> RETURN TO CORE -> CHOOSE RELEASE OR SEAL -> LOCAL WORLD FEEDBACK -> EXISTING CIVIC AUTHORITY REACTS IF RELEASED`

## Locked choices

### RELEASE
- select a physical `RELEASE // PUBLIC RELAY` target;
- mark aftermath `RELEASED`;
- attempt exactly one existing civic Report at the Silent Core;
- live reporting may produce retained Heat 1 / Contact;
- P02 Field Hacking may suppress the Report without undoing RELEASED;
- repeat Action cannot report again.

### SEAL
- select a physical `SEAL // LOCAL VAULT` target;
- mark aftermath `SEALED`;
- create no civic Report;
- repeat Action cannot change the decision.

Neither outcome is scored as morally correct.

## State

Retain Mission 03 phase `COMPLETE` after legitimate escape. Add independent session-local aftermath state:
- `UNDECIDED`
- `RELEASED`
- `SEALED`

Full Replay restores UNDECIDED. No save migration.

## Authority

Mission 03 runtime owns only relay activation, Action consumption, exactly-once choice, local presentation, Sister Kael copy and one request into retained civic-report authority.

Retained authorities remain unchanged:
- P01 Burnside Wanted: Report -> Heat / Contact / Search / Evasion;
- P02 Field Hacking: report suppression;
- P08: HS-7 physical carried presence;
- retained Silent Core: Mission 03 Echo activation.

No generalized choice/dialogue/reputation framework.

## Presentation

At the existing Silent Core site, create two small bounded relay interactables:
- worn off-white/charcoal civic hardware;
- sparse cyan signal;
- restrained amber decision accent;
- world labels, not a menu.

Before Mission 03 COMPLETE they are dormant. After completion they become interactable. After selection the chosen relay resolves and the other powers down.

## Canon

This deliberately commits only that the already-authored recovered civic deletion-order fragment can be released through local civic infrastructure or retained locally. It does not define the erased event, add factions/government structure, or establish large-scale downstream politics.

## Audio

No Audio mutation. No new assets/events/registries.

## Required verification

1. retained Mission 03 escape still reaches COMPLETE;
2. completion copy points back to the Core;
3. relays unavailable before COMPLETE;
4. both become available after COMPLETE via retained target arbitration / Action;
5. RELEASE is exactly-once and requests one civic Report;
6. live RELEASE composes with P01;
7. jammed RELEASE remains RELEASED with no new Heat;
8. SEAL requests no civic Report;
9. selecting one disables the other;
10. Full Replay restores UNDECIDED and dormant relays;
11. P08 HS-7 presence and Mission 03 Echo ordering remain intact;
12. retained P01/P02 and P15 regressions remain green;
13. Web export/public packaging remain compatible;
14. rendered production proof covers dormant, ready, RELEASED and SEALED states.

## Non-goals

No branching-dialogue framework, dialogue wheel, morality meter, reputation/Standing, Heat 2–5, persistent police database, generalized civic-memory ledger, durable choice save, Cash work, new geography, companion abilities, Audio changes, or PR #44 camera work.
