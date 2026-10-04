# Burnside Production 17 — Gears Retrofit Sidearm / Gunfire Consequence Tracer

**Status:** JIT DESIGN LOCKED / IMPLEMENTATION CONTRACT  
**Issue:** #179  
**Baseline:** docs-only `main@fb1a23b95383bebbd181b573234058bea1a76e46`  
**Exact runnable/gameplay/public predecessor:** P16 `b96f81264144386bd3fc3a1c77d330b7af3af531`

## Player-facing purpose

Burnside already proves pursuit, physical tools, Health / Armor / Soft Failure, Wanted, local civic reaction and multiple forms of authored consequence, but it still lacks the canonical Street-Combat verb promised by #118: **shooting**.

P17 adds exactly one open-posture firearm archetype and composes it with the systems already in the Gears.

`FIND SIDEARM -> TAKE -> MOVE + FIRE -> PHYSICAL IMPACT -> LOCAL ALARM -> CIVIC REPORT IF LIVE -> HEAT / CONTACT -> IMPROVISE / ESCAPE`

## Sidearm acquisition

Create one session-local physical retrofit sidearm pickup at the existing Service Alley / contraband-stash geography.

- acquisition uses retained active-target arbitration and ordinary Action;
- pickup is current-run only;
- Full Replay restores pickup and clears sidearm possession;
- no durable ownership or save migration;
- no weapon inventory, slots, weapon wheel or loadout UI;
- the environmental placement does not establish Mayor Burn as a routine weapons supplier.

## Input ownership

Add one explicit `weapon_action_pressed` / FIRE path.

Desktop:
- left mouse fires only while on foot, sidearm held, no gesture overlay owns mouse input and retained interaction input is not locked;
- emulated browser mouse events from touch are rejected.

Touch:
- one `FireButton` inside retained `SafeAreaRoot/RightTouchArea`;
- visible/enabled only when the sidearm can actually fire on foot;
- must not overlap retained Action / Tool controls under supported safe-area layouts.

Retained ownership:
- `E` = Action;
- `F` = Scrapper Tool;
- `J/Space` = Strike;
- vehicle controls unchanged;
- FIRE must never synthesize Action, Tool or Strike.

## Fire model

Open posture, no aim mode.

On accepted FIRE:
1. validate held / on-foot / unlocked / no gesture owner / cooldown clear;
2. capture player origin and current horizontal facing;
3. resolve exactly one immediate hitscan query;
4. show bounded muzzle/trace/impact feedback;
5. enter a short cooldown.

Initial tuning target:
- range: `22 m`;
- cooldown: `0.32 s`;
- one accepted shot = one ballistic query.

No ADS, lock-on, mandatory cover, combat stance or combat camera.

## Physical impact authority

P17 does not create NPC Health.

For the first physics collider:
- walk ancestors until a node with the retained `take_hit(damage, hit_pos, impulse_dir)` seam is found;
- apply exactly `1` bounded ballistic hit;
- otherwise treat the collision as a non-damageable physical impact.

Required proof target: retained `UtilityCrawler`.
- first shot: existing durability 2 -> 1;
- second shot: existing durability 1 -> 0 and retained crawler lifecycle resolves `DISABLED`;
- P17 does not duplicate crawler durability, reward, debris, collision, Audio or reset authority.

The armored Security Interceptor is not a firearm-damage target in P17.

## Gunfire consequence

Add one explicit concrete seam to `GearsWorkZoneIncident`:

`trigger_gunfire_incident(observed_position: Vector3) -> bool`

This is not a generalized witness/crime event bus.

For the first accepted gunfire incident while the work-zone incident is `ROUTINE`:
1. current retained Gears Worker and Utility Crawler receive local ALARMED behavior where their current physical state allows it;
2. local reaction remains even if city communication fails;
3. if retained Heat is already > 0, do not request a redundant Report;
4. otherwise request exactly one Report through `BurnsideWantedRuntime.request_civic_report(...)`;
5. P02 Field Hacking may suppress that Report;
6. repeated shots during the same active incident do not spam Reports.

P17 gunfire consequence is bounded to the existing Gears incident geography; no universal witness system.

## Wanted / Field Hacking boundaries

- `BurnsideWantedRuntime` / `WantedAuthority` remain sole Wanted knowledge authority;
- P17 never sets/clears Heat directly;
- existing Heat / Contact / Search / Recognition cannot be erased by firearm behavior;
- P02 suppresses communication, not local reaction.

## Audio

P17 may add exactly one narrow semantic firearm event, `SIDEARM_FIRE` (or equivalent explicit name), to retained Audio routing.

Metal impact may use an already-correct retained SPARK/impact semantic where applicable.

Do not repurpose vehicle collision semantics as gunfire.

Automated event/routing verification is not perceptual Audio proof. Perceptual PASS requires actual playback/listening evidence.

## Presentation

Use a recognizable but salvaged near-future handgun silhouette:
- worn charcoal / off-white metal;
- practical asymmetry;
- one restrained amber/cyan retrofit element;
- no pristine tacticool / military-fetish styling;
- no laser pistol.

Required production-camera reads:
- pickup is findable;
- held sidearm is readable;
- FIRE appears only when valid;
- accepted shot produces muzzle/trace/impact feedback;
- crawler visibly reacts to first hit and disables on second;
- local work-zone actors visibly alarm;
- Wanted HUD composes with live reporting.

## Reset / failure

Full Replay:
- clears sidearm possession;
- restores pickup;
- clears P17 cooldown / feedback;
- retained work-zone / crawler / Wanted reset paths remain authoritative.

Soft Failure should preserve current-run possession unless exact reset behavior proves a conflict; P17 must not invoke broad Full Replay from Soft Failure.

## Required verification

1. no sidearm fire before acquisition;
2. Action acquires sidearm exactly once;
3. acquisition does not emit FIRE / Tool / Strike;
4. FIRE input is independent of retained Action / Tool / Strike / vehicle controls;
5. browser-emulated touch cannot create duplicate mouse fire;
6. mounted / locked / gesture-owned / unavailable states reject FIRE;
7. accepted FIRE captures one origin/facing and performs exactly one ray;
8. cooldown rejects spam without fake feedback;
9. first Utility Crawler hit decrements retained durability once;
10. second Utility Crawler hit reaches retained DISABLED lifecycle;
11. no P17 duplicate crawler-health/state authority;
12. non-damageable geometry gives impact feedback without fake damage;
13. first bounded gunfire incident locally alarms retained actors;
14. clear + live reporting requests exactly one civic Report and may create P01 Heat 1 / Contact;
15. clear + pre-jammed reporting retains local reaction with no new Heat;
16. pre-existing Wanted is preserved and creates no redundant Report;
17. repeated shots during active incident do not Report-spam;
18. Full Replay restores P17 local state without corrupting retained systems;
19. P05 Scrapper Tool behavior/input remains intact;
20. P09 Health / Armor / Soft Failure remains intact;
21. P15 checkpoint recognition remains compatible;
22. P16 memory-disclosure choice remains compatible;
23. Web export / public packaging remain compatible;
24. rendered proof covers pickup, held state, first hit, crawler disable, live-report consequence and jammed-report composition;
25. firearm Audio routing is technically verified; any perceptual claim is explicitly tied to playback evidence.

## Non-goals

No weapon roster, weapon wheel, inventory/equipment framework, durable weapon save, ammo economy, reload simulation, human NPC Health/death, hostile pedestrian combat AI, generalized hostile AI, armed companion behavior, firearm damage to Security Interceptor, Heat 2–5, generalized witnesses/surveillance, universal crime bus, ADS/cover/lock-on, stat/recoil progression, rarity/attachments, explosives, new geography or PR #44 camera work.
