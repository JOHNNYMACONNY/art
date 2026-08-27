# Gears Verification Debt Checkpoint

**State:** READY_FOR_IMPLEMENTATION  
**Baseline:** `main@a8a30cb2fead23f1d242debbaa8b225f7da2bdbc`  
**Purpose:** retire accumulated rendered-visual debt and collect bounded same-host structural render-cost evidence without adding product content.

## Problem

The Gears visual proof, production block, Mayor Burn garage, Silent Core site and FB-13 thrum event are code-verified and publicly exported, but fresh exact-build retained-camera visual evidence has not yet been successfully published for inspection. Current structural render-cost evidence is also missing.

The repository already proves Ubuntu/Xvfb can render Godot screenshots. Direct Actions workflow mutation remains unavailable through the connected GitHub token (`GITHUB_CONTROL_FORBIDDEN`, HTTP 403).

PR #70 proved a first editor-export-plugin approach could keep CI green, but post-merge inspection found that the headless CLI export did not actually publish the verification files. That false-green result is explicitly rejected as verification evidence.

The historical V7 timing baseline was measured as a 120-frame native Apple M4 / Metal Forward+ run. Repeating that workload inside Ubuntu/Xvfb llvmpipe exceeds the existing workflow's fixed 180-second desktop-regression timeout even after substantial sample reduction. This checkpoint therefore must not represent llvmpipe as a hardware-equivalent native timing qualification.

## Repaired strategy

Do not create or mutate an Actions workflow.

Use a step the existing `Godot Web Playtest` workflow already executes immediately before Web export: `desktop_interaction_cancel_test.gd`.

Only when `GITHUB_ACTIONS=true`, that retained regression must:

1. launch the exact checked-out isolated Web project under `xvfb-run` using the same Godot executable and `res://tests/gears_verification_capture_runner.gd`;
2. have that dedicated runner set the capture activation environment in the **same Godot process before scene instantiation**, then instantiate the real `ScrapTestBlock` scene;
3. require the embedded normal-scene capture driver to succeed and produce a SHA-stamped report;
4. require the isolated Web export preset to contain `GEARS_VERIFICATION_PAYLOAD_V2` and exact `SOURCE_SHA` before normal export proceeds.

The capture driver is a dormant node in the real playable scene. Outside explicit verification activation it immediately frees itself and owns no runtime gameplay behavior. The dedicated runner removes reliance on project-main launch semantics or child-process flag propagation: it sets activation before creating the real scene and has a bounded watchdog if the driver does not terminate.

The capture child must then use normal Godot Web-export surfaces for publication:

- build a 3x3 contact sheet from nine fresh rendered frames;
- set that contact sheet as the **isolated Web project** boot-splash image, causing the standard Web exporter to emit it as loose public `index.png`;
- inject an HTML comment plus `<script type="application/json">` report into `html/head_include`;
- stamp both publication surfaces to exact `SOURCE_SHA`.

The isolated Web-project splash mutation is CI-only and must not change repository gameplay presentation or checked-in project settings.

The previous editor export plugin must remain disabled. No Actions-file change is allowed or required.

## Exact visual evidence set

The capture harness must run the real playable scene and retain the production `ChinatownCamera3D` 32-degree elevated 3/4 camera.

Fresh rendered source frames, in contact-sheet order:

1. `01_quiet_traversal.png` — representative primary-road traversal;
2. `02_courier_bike.png` — Courier Bike readability in the district;
3. `03_pursuit.png` — actual active Pursuer state with Bike/player readable together;
4. `04_shortcut_intersection.png` — industrial intersection + alternate-route decision;
5. `05_burn_garage.png` — Mayor Burn garage/frontage readability;
6. `06_silent_core.png` — Silent Core infrastructure pocket readability;
7. `07_day.png` — approved practical day hierarchy;
8. `08_dusk.png` — approved restrained dusk hierarchy;
9. `09_fb13_thrum.png` — FB-13 mechanism-resonance pulse at the industrial frontage.

Each source capture must be a fresh rendered PNG from the exact checked-out build and exceed the bounded non-empty evidence threshold. The public contact sheet must preserve this 3x3 order and be emitted by the normal Web exporter as `index.png`.

## Performance / render-cost evidence

Generate and publish a report containing:

- exact `SOURCE_SHA` from CI;
- Godot version, renderer/method, viewport size and OS;
- capture filenames, dimensions and byte sizes;
- one full-current structural snapshot containing draw calls, primitives and objects;
- one same-run retained-yard control with `GearsStyleProof` and `GearsDistrictSlice01B` hidden, measured from the same camera position and same CI host;
- full-vs-control draw/primitives/object deltas;
- one current and one control frame-time smoke measurement associated with those rendered snapshots, explicitly labeled **advisory only**;
- historical V7 desktop baseline context (`68` draw calls, `59,410` primitives, `75` objects, `16.46 ms` average, `17.20 ms` P95) explicitly labeled Apple M4/Forward+ and therefore not hardware-equivalent to Linux/Xvfb GL Compatibility.

The same-run draw/primitives/object delta is the primary incremental-cost signal for this CI checkpoint. Single-frame llvmpipe timing may identify an order-of-magnitude failure but must not be represented as an average/P95 qualification.

Full native desktop average/P95 timing remains verification debt until it can run on an appropriate native rendering surface. This checkpoint narrows the debt by resolving actual rendered visual evidence and structural same-host cost while leaving native timing qualification explicit.

For easy external inspection, `index.html` must contain:

- marker `GEARS_VERIFICATION_PAYLOAD_V2`;
- exact source SHA;
- bounded current/control frame-time smoke values;
- draw/primitives/object deltas;
- full JSON report in an `application/json` script element.

## Fail-closed contract

The existing Web export must fail before export if:

- Xvfb/Godot runner or capture fails;
- runner watchdog expires;
- report generation fails;
- report SHA differs from `SOURCE_SHA`;
- any required capture is missing/empty;
- contact-sheet generation fails;
- isolated project/preset publication mutation fails;
- repaired payload marker or source SHA cannot be re-read from `export_presets.cfg`.

A green export without inspectable post-publication evidence is **not** verification PASS.

## Review contract

After exact-head CI succeeds and the repair PR is reviewed/merged:

1. verify `playtest-web/PLAYTEST_BUILD.txt` equals the merged SHA;
2. verify raw public `playtest-web/index.png` is the 3x3 verification contact sheet rather than the default Godot splash;
3. verify raw public `playtest-web/index.html` contains `GEARS_VERIFICATION_PAYLOAD_V2`, the same SHA and readable report JSON;
4. perform fresh visual review of all nine contact-sheet cells for retained-camera readability, route hierarchy, silhouettes, signage/landmark clarity, restrained day/dusk treatment, Silent Core readability and FB-13 pulse legibility;
5. evaluate full-current vs retained-control draw/primitives/object cost and bounded timing-smoke context;
6. any material visual/structural-performance finding routes to REPAIR; only no finding plus current public evidence resolves those portions of verification debt.

Human listening quality for FB-13 remains a separate audio-perceptual question unless a genuine listening-capable surface becomes available. Native desktop average/P95 timing also remains a separate qualification item unless an appropriate native rendering surface becomes available.

## Non-goals

- no new acreage or content;
- no visual redesign during evidence collection;
- no gameplay, mission, camera, input, pursuit or vehicle behavior change;
- no replacement for black-box browser interaction testing;
- no claim that CI/Xvfb audio proves human listening quality;
- no claim that llvmpipe single-frame timing equals native desktop avg/P95 performance;
- no Actions workflow mutation;
- no silent conversion of CI success into perceptual PASS.
