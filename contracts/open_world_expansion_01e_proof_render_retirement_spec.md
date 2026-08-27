# Open World Expansion 01E — Proof Render Retirement

**State:** READY_FOR_IMPLEMENTATION  
**Baseline:** `main@e77eb6c330e984e31f862c8d45b456a205a0f2cc`  
**Predecessors:** Open World Expansion 01B–01D and Gears Verification Debt Checkpoint / PR #71

## Objective

Reduce production render overhead before adding more district content by retiring the completed Issue #60 `GearsStyleProof` composition from normal gameplay rendering while preserving its standalone proof artifact, its executable contract, and the actor/interactable style treatments that current production presentation still receives from the mounted proof controller.

The post-PR #71 exact-main verification report measured the combined Gears additions at `+173` draw calls, `+2,376` primitives and `+173` objects versus the same-host retained-yard control. The proof-only composition is still mounted visibly alongside the real `GearsDistrictSlice01B`; 01E removes that redundant rendered layer rather than adding acreage or redesigning the production slice.

## Production contract

In `godot/scenes/prototype/scrap_test_block.tscn`:

- keep the `GearsStyleProof` instance mounted;
- set the production instance root `visible = false`;
- keep `GearsDistrictSlice01B` mounted and visible;
- do not delete, rename, move or rewrite `godot/scenes/world/gears_style_proof.tscn`;
- do not disable the proof controller script, because its deferred actor/interactable treatment remains the current bounded style-treatment authority;
- do not change the retained 32-degree camera, routes, mission sockets, collisions, vehicles, pursuit, input, HUD, audio, save state, or mission state machines.

The proof root being hidden must suppress proof-only mixed-use/route/gantry/storefront/relay meshes and proof practical lights from normal production rendering while leaving sibling actor treatment meshes/materials visible.

## Verification contract

Exact-head CI must verify in the real playable scene that:

1. `GearsStyleProof` still exists and exposes `get_proof_contract()` and `set_lighting_mode()`;
2. all existing Issue #60 proof composition nodes still exist for standalone/reference inspection;
3. all existing required actor/interactable treatment metadata, contours and bounded identity markings remain present;
4. production `GearsStyleProof.visible == false`;
5. production `GearsDistrictSlice01B.visible == true`;
6. the production district's 01B–01D contract remains green;
7. retained camera and canonical compatibility suites remain green.

The verification capture harness must preserve the production proof visibility state when taking current/control structural snapshots; it must not force the retired proof composition visible after measurement.

## Post-merge evidence

After merge, require the ordinary exact-main verification publication to be current and compare its structural report to the PR #71 baseline:

- baseline Gears delta: `+173 draw calls`, `+2,376 primitives`, `+173 objects`;
- expected direction: draw-call and rendered-object deltas must materially decrease while the nine retained-camera views remain visually coherent;
- do not claim native frame-time improvement from Linux/Xvfb single-frame smoke timing.

If hiding the proof composition causes a material visual-readability regression in the published nine-frame sheet, route to REPAIR rather than retaining the performance change by fiat.

## Non-goals

- no new acreage;
- no new authored location;
- no mesh batching/MultiMesh conversion;
- no material redesign;
- no deletion of Issue #60 evidence;
- no new gameplay or framework authority;
- no claim that this closes native desktop average/P95 timing or human FB-13 listening debt.

## Completion recommendation

If 01E reduces structural render cost without a material visual regression, resume content development using existing geography first. Prefer a bounded authored gameplay/narrative use of the current district before any further acreage expansion.
