# START HERE — FB-13 / HS-7 Project Wayfinder

This is the live **project-level routing document**. It does not replace implementation truth, visual canon, ticket specs, or verification evidence.

## Truth order

1. **Repo + runnable behavior** — implementation truth.
2. **Approved canon / project sources** — creative truth.
3. **Live provider/tool state** — external truth.
4. Tickets, docs, chats and handoffs are routing/history unless verified against the above.

Always refresh current `main`, open PRs/issues and relevant CI/runtime evidence before repo-sensitive work. Do not treat the SHA recorded in an older document as current merely because the document is authoritative for another purpose.

## Current routing

### ACTIVE

- **Audio Production** — active in parallel. Treat its runtime, registries, production audio assets/tests and shared-scene changes as a conflict surface unless the active audio branch proves otherwise.
- **Project orchestration** — keep issue state, wayfinders and just-in-time tickets aligned with repo truth.

### NEXT

- **Production 20 / #188 — Sister Kael Silent Core Presence / Choice-Reactive Witness — JIT design pending.** P19 closed the immediate sidearm <-> physical Wanted pursuer composition gap without expanding combat breadth.
- Reverify the retained P16 RELEASE/SEAL authority, Mission-03/Silent-Core staging, HS-7 presence, target arbitration and reset seams before implementation. Investigate one bounded physical Sister Kael presence that witnesses/reacts to the existing P16 choice instead of creating a new dialogue or outcome authority.
- Preserve P16 as sole RELEASE/SEAL writer, P01/P02 civic authority, P08 HS-7 presence, P18 Mayor Burn, P19 pursuer suppression, saves, missions, companions and unrelated Audio. Do not grow P20 into generalized dialogue/NPC systems, relationship meters, hostile-human combat, Heat 2–5, new geography or voice work.

### DEFERRED

- More Gears acreage until next bounded gameplay slice exercises existing geography.
- PR #44 camera-occlusion experiment; retained camera follow is the production baseline.
- Experimental nonlinear touch steering; linear steering remains default until physical-device qualification.
- Broad fresh-player perceptual studies unless a current decision genuinely requires them.

### HUMAN_GATE

- Physical touch A/B before changing touch steering default.
- Human listening/perceptual audio checks when actual playback quality is the question.
- Real mobile performance until measured on real hardware.

These gates do not automatically block unrelated code-first work.

### HISTORICAL

- `WAYFINDER_MAP.md` — architecture/history map, not live status.
- Visual Direction / Concept Art gate — complete.
- Issue #60 / Open World Expansion 01A — complete.
- Open World Expansion 01B / PR #64 — first contiguous Gears production block, merged.
- Open World Expansion 01C / PR #65 — Mayor Burn garage integration, merged.
- Open World Expansion 01D / PR #66 — Silent Core infrastructure integration, merged.
- World Event 01 / PR #68 — bounded FB-13 infrastructure-thrum use of existing geography, merged.
- Issue #89 / Open World Expansion 01E — Gears retained-camera readability & performance checkpoint, complete (`VISUAL_PERF_CHECKPOINT_PASS`).
- Productions 01–19 — merged and verified through Production 19 Wanted Pursuer Sidearm Suppression / Contact-Break Composition. Exact runnable/gameplay/public P19 baseline: `d8ec7918e8980029f0ed9821e109cc0c65cbb42c`; current public Web publication uses GitHub Pages Actions artifacts and the live source stamp matches that exact SHA. P19 introduced no Audio scope; P17 firearm audio routing remains technically verified while perceptual listening quality remains unverified.

Do not recreate completed 01A–01D work because an older roadmap still describes it as future work.

## Authority router

| Need | Start here | Then read |
|---|---|---|
| Current product continuity | `HANDOFF.md` | live PR/issue/CI state |
| Product sequencing / priorities | Issue #55 | current just-in-time ticket |
| Visual/world work | `docs/visual_direction/README.md` | narrow approved category authority + current ticket |
| Reference provenance | `docs/visual_direction/REFERENCE_ATLAS.md` | approved visual authority; references never override canon |
| Historical architecture | `WAYFINDER_MAP.md` | only when history/architecture context is needed |
| Audio production | active audio ticket/PR + current runtime | do not infer status from this wayfinder |
| Gameplay implementation | current ticket/spec + actual Godot code | relevant verification contracts |

## Visual/world baseline

Approved direction: **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**.

Humanoid bots are an **approved supporting visual family**, not mandatory population filler.

The current yard already connects to a real Gears production block with a primary industrial route, alternate service alley/rejoin, commercial and industrial frontage, Mayor Burn's authored garage destination, and a reachable Silent Core infrastructure pocket.

Prefer useful density and authored use of existing geography over empty acreage.

## Execution loop

`STATE -> VERIFY -> HIGHEST_VALUE_GAP -> PLAN -> EXECUTE -> VERIFY_RESULT -> UPDATE -> REPORT -> NEXT`

For implementation work, use the existing repo discipline:

`SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen Standards+Spec REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY`

Rules:

- create/refine only the just-in-time ticket that is actually current;
- preserve unrelated/concurrent work;
- do not reopen retained camera/controls/vehicle/pursuit/mission/audio ownership without a concrete observed weakness;
- no giant speculative backlog;
- no silent canon changes;
- code-first verification is the normal production gate; add physical/perceptual play only when it answers a real unresolved question;
- attempted work is not completed work; report exact evidence and blockers.

## Updating this file

Update only when **routing changes**: ACTIVE/NEXT/DEFERRED/HUMAN_GATE/HISTORICAL classification, authority paths, or the project-level execution entrypoint.

Do not turn this into a changelog, giant roadmap, canon document, or duplicate of `HANDOFF.md`.