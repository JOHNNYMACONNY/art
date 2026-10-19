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

- **Recorded-first audio production / issue #196** — output is audible in native windowed Godot and Web according to direct owner confirmation on 2026-10-19; issue #31 CLOSED (technical and audibility gate). Current highest-value audio frontier is *actual approved recordings and integrated, calibrated gameplay mix*, not device/audio-output diagnosis.
- **Product orchestration / #55** — keep live issue, canon, public-release and continuity routing aligned with repository truth.

### NEXT

- **Audio Production 02 / #196 — five-family recorded-first vertical slice**: obtain and audition actual redistributable source files (footsteps, metal contact, tuner/static, electric bike, pursuit warning), document legal rights for raw public Git distribution and SHA-256 provenance, edit and measure the assets using the already merged `code/audio_intake/audio_loudness.py`, integrate incrementally with procedural fallback and native/Web playback checks.
- **Existing mix behavior**: PR #200 / issue #199 shipped continuous pursuit ambient-wind attenuation on main; do not duplicate radio-duck ownership or introduce speculative full RAGE-style architecture. Listen to simultaneous quiet → moving/radio → pursuit → release and adjust only with evidence.
- **Audio quality gate still open**: “both work” proves owner-reported audibility, not five separately enumerated probe-cue passes, relative loudness, license verification or all 49 final sound replacements. #196 remains open.
- **Retained audio sources**: no raw GTA/Rockstar assets or unapproved Freesound/media samples committed; use permitted CC0 or documented redistribution rights. Follow Release Integrity 01, existing audio semantics/reset, saves and Web bundling contracts.
- After the first real-sound slice, reevaluate against Lira authored presence, Heat 2+ police escalation, human combat, and density rather than expanding every sound slot by default.

### DEFERRED

- More Gears acreage until next bounded gameplay slice exercises existing geography.
- PR #44 camera-occlusion experiment was superseded. PR #201 CTW Feel 03 camera-occlusion cutaway is merged and public-verified at runnable SHA `c489bd06d5ed92119e6e05d16cf12fa57d93038c`; preserve current heading-follow camera and occlusion contracts.
- Experimental nonlinear touch steering; linear steering remains default until physical-device qualification.
- Broad fresh-player perceptual studies unless a current decision genuinely requires them.

### HUMAN_GATE

- Physical touch A/B before changing touch steering default.
- Native/Web audio audibility has owner-reported PASS (#31 closed); human listening is still required for individual recorded samples, relative loudness, masking and actual mix quality under #196.
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
- Productions 01–20 — merged and verified through Production 20 Sister Kael Silent Core Presence / Choice-Reactive Witness. Exact gameplay/world P20 baseline: `e4029fd06bfafc3fdc8ac158b7c39a17372a8d34`.
- Release Integrity 01 / #191 / PR #193 — merged, exact-main verified and public verified; immutable release-integrity baseline `7561204c90db207f8b65a01585c0f9ea15d55047`. Current public/audio remains procedure-safe with optional fail-closed local debug reference override.
- Audio Runtime 01 / #31 — CLOSED after owner stated native windowed and Web audio both work on 2026-10-19. This resolves global audibility, **not** subjective sound-design/mix quality.
- Audio intake PR #198 — MERGED, SHA `0c82bae1b1e1f51a5e2d2ec4f578c8730defe7cf`; first six source candidates are not yet auditioned/ingested.
- Audio Mix PR #200 — MERGED, SHA `95cd32a230432fd7b359adb42af8b3a12cbe02b6`; live pursuit pressure now ducks ambient wind without altering radio gain owner. #199 CLOSED.
- CTW Feel 03 camera PR #201 — MERGED, public runnable SHA `c489bd06d5ed92119e6e05d16cf12fa57d93038c`.

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