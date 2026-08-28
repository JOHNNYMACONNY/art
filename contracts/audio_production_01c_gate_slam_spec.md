# Audio Production 01C — Signal Gate Slam

**State:** SOURCE_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@92c35122c23919f7bef00b0352084a7b7e4b725c`  
**Semantic slot:** `interaction.gate_triggered`  
**Runtime event:** `AudioManager.SoundEvent.GATE_SLAM`

## Objective

Replace the Signal Gate's procedural downward sweep with one production transient selected from the local GTA San Andreas audio library, while preserving the existing gate timing, 3D source position, transient voice budget, pursuit behavior, and procedural fallback.

This is one bounded production-audio replacement. It does not authorize another slot, loop, ambience layer, vehicle layer, pursuit siren, radio asset, or audio framework redesign.

## Selected source

Human audition selected exactly:

`GTA_SA:GENRL:BANK_42:SOUND_0`

Audition evidence:

- native duration: `0.5538 s`;
- native sample rate: `18,000 Hz`;
- mono 16-bit linear PCM extraction;
- heavy industrial container/barrier-drop character with pre-hinge mechanical texture and metallic impact;
- human listening PASS on Mac/mobile speakers and five-pulse repetition test;
- no audible extraction artifact, truncation, pitch/speed error, or boundary pop;
- no production gain change required;
- preserve native 18 kHz rate;
- apply only a minimal ~1.5 ms boundary taper for production safety;
- no other processing required.

Candidate B/C/D remain audition evidence only and must not enter the production tree.

## Existing behavior retained

- `SignalGateInteractable` owns gate state and its 0.3 s physical barrier swing.
- `ScrapTestBlock._on_signal_gate_triggered()` emits `GATE_SLAM` at `signal_gate.global_position`.
- `AudioManager` remains lifecycle, voice-budget, and fallback owner.
- Current fallback remains the existing procedural `240 Hz -> 60 Hz`, `0.45 s` sweep.
- Gate collision timing, sweep safety, pursuer detour, evasion logic, camera, HUD, radio reactions, and mission state do not change.

## Source boundary

Production candidate selection uses only the locally stored GTA San Andreas audio library already indexed by Audio Intake 01A.

Do not copy archive containers or unselected candidates into Git. Audition/extraction staging remains ignored/local.

## Production asset contract

Canonical destination:

`res://audio/interaction/sfx_interaction_gate_slam.wav`

The curated production asset must:

- derive from exactly `GTA_SA:GENRL:BANK_42:SOUND_0`;
- be mono `AudioStreamWAV` suitable for `AudioStreamPlayer3D`;
- use 16-bit PCM;
- preserve native `18,000 Hz` sample rate;
- retain the natural envelope at approximately `0.5538 s`;
- receive no gain normalization or speculative EQ/compression/reverb;
- use only the approved minimal boundary taper;
- stay comfortably below the 15 MB per-slice intake ceiling.

`AudioRegistry` is the canonical source of production path and provenance. Do not duplicate the path as an independent constant in `AudioManager`.

## Runtime contract

1. `interaction.gate_triggered` remains `DIEGETIC_3D`, `CRITICAL_THREAT`, transient, non-looping.
2. The slot records the production asset path and exact source provenance `GTA_SA:GENRL:BANK_42:SOUND_0` and no longer requires replacement.
3. `AudioManager.event_to_slot_id(GATE_SLAM)` returns `interaction.gate_triggered`.
4. `AudioManager` resolves the production stream through `AudioRegistry`.
5. `GATE_SLAM` production playback uses the existing transient voice budget and the position supplied by `ScrapTestBlock` — the actual `signal_gate.global_position`.
6. If the production stream is absent/unloaded, the current procedural sweep remains reachable and behaviorally unchanged.
7. No second audio slot is migrated in 01C.

## Automated verification

Exact-head verification must prove:

- slot metadata and exact canonical path/provenance;
- production WAV is mono 16-bit PCM at 18,000 Hz and approximately 0.5538 s;
- `GATE_SLAM -> interaction.gate_triggered` semantic mapping;
- production stream resolution;
- production playback through `AudioStreamPlayer3D` at an arbitrary supplied test position;
- procedural fallback reachability;
- gate interaction/collision/detour contracts remain green;
- Audio Runtime retention remains green;
- semantic slot manifest remains internally consistent;
- full repository compatibility required by CI remains green.

## Human in-game verification

On the exact clean candidate SHA, trigger the real gate during pursuit and judge:

- route-switch confirmation and physical weight;
- sync with the barrier's 0.3 s swing;
- localization at the gate rather than at the player/camera;
- mix against bike/vehicle sound;
- mix against active pursuit/siren pressure;
- no clipping, pop, pitch/speed error, or abrupt truncation;
- repeated retry fatigue;
- production sample is materially preferable to the procedural fallback.

## Completion

01C reaches PASS only after the selected GTA source is integrated, exact-head automated verification passes, exact-head human in-game listening passes, fresh Standards/Spec review passes, the PR is merged, and exact-main verification is green.
