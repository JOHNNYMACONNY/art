# Echos in the Scrap: V7 Playtest Handoff Document

**Project**: Echos in the Scrap  
**Repository**: [JOHNNYMACONNY/art](https://github.com/JOHNNYMACONNY/art)  
**Current Commit**: `9972adfa4ecafe7b66ef6c7805601d6b77fe7e37`  
**Playable Baseline Commit**: `904a80a23a54e4a43fc046d04bb52a04f9196a8b`  
**ChatGPT Relay Tab**: `https://chatgpt.com/g/g-p-699d1f9e9c188191a392e1cc0783af99-fb-13-hs-7/c/6a815c99-1368-83e8-9414-5e17cdc83b27`  

---

## 1. Executive Summary & Objective

The codebase has completed all V1 through V6.1 development, physical safety sweeps, physical shortcut corridor geometry, touch UI signal reconnections, authoritative `reset_slice()` dismount cleanup, state-driven audio mix arc, 100% green automated assertion suites, and exported 6 visual screenshots.

**CURRENT PHASE**: **V7 Baseline Playtest Cohort Collection**  
**OBJECTIVE**: Execute 5 uncoached playtest sessions (`P01` through `P05`) using isolated subagents acting as fresh players interacting with the Godot game instance. Log quantitative telemetry, exit questionnaire responses, and aggregate failure taxonomies without altering game code until all 5 sessions finish.

---

## 2. Key Repository Files & References

- **Game Scene**: [`godot/scenes/prototype/scrap_test_block.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/prototype/scrap_test_block.tscn)
- **Controller Script**: [`godot/scripts/prototype/scrap_test_block.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/prototype/scrap_test_block.gd)
- **Touch UI Script**: [`godot/scripts/input/touch_controls.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/input/touch_controls.gd)
- **Vehicle Controller**: [`godot/scripts/vehicles/courier_bike.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/vehicles/courier_bike.gd)
- **Signal Tuner**: [`godot/scripts/interactions/signal_tuner.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/interactions/signal_tuner.gd)
- **Corroded Panel**: [`godot/scripts/interactions/corroded_panel.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/interactions/corroded_panel.gd)
- **Audio Engine**: [`godot/scripts/audio/audio_manager.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/audio/audio_manager.gd)
- **V7 Validation Protocol**: [`.scratch/v7-playtest-validation/V7_PLAYTEST_VALIDATION_PROTOCOL.md`](file:///Users/bobbyinthelobby/{art/.scratch/v7-playtest-validation/V7_PLAYTEST_VALIDATION_PROTOCOL.md)
- **Session Templates**: [`.scratch/v7-playtest-validation/sessions/P01.md`](file:///Users/bobbyinthelobby/{art/.scratch/v7-playtest-validation/sessions/P01.md) through [`P05.md`](file:///Users/bobbyinthelobby/{art/.scratch/v7-playtest-validation/sessions/P05.md)
- **Aggregate Report**: [`.scratch/v7-playtest-validation/V7_BASELINE_PLAYTEST_REPORT.md`](file:///Users/bobbyinthelobby/{art/.scratch/v7-playtest-validation/V7_BASELINE_PLAYTEST_REPORT.md)

---

## 3. Verification & Execution Commands

- **Parse Syntax Check**:
  ```bash
  godot --headless --path godot/ --check-only
  ```
- **Run Complete V1–V6 Automated Assertion Suites**:
  ```bash
  godot --path godot/ -- ++ --run-v1-assertions && godot --path godot/ -- ++ --run-v2-assertions && godot --path godot/ -- ++ --run-v3-assertions && godot --path godot/ -- ++ --run-v4-assertions && godot --path godot/ -- ++ --run-v5-assertions && godot --path godot/ -- ++ --run-v6-assertions
  ```
- **Export Visual Screenshots**:
  ```bash
  godot --path godot/ -- ++ --export-v6-visuals
  ```

---

## 4. Subagent Playtest Execution Protocol

For each playtest session `P01` to `P05`:

1. **Spawn Subagent as Fresh Tester**:
   - Launch an isolated subagent using `invoke_subagent`.
   - Instruct subagent to interact with Godot scene without prior knowledge of game mechanics or objective.
2. **Telemetry Logging**:
   - Record `TIME_TO_FIRST_MOVE`, `TIME_TO_NOTICE_TUNER`, `TUNING_ATTEMPTS`, `PANEL_CAUSALITY_UNDERSTOOD`, `DANGER_UNDERSTOOD`, `BIKE_MOUNTED`, `ROUTE_SWITCH_USED`, `INTERCEPTIONS`, and `REPLAY_USED_VOLUNTARILY`.
   - Maintain strict separation between `OBSERVED:`, `PLAYER_SAID:`, and `INFERENCE:`.
3. **Exit Questionnaire**:
   - Ask the 9 standard exit questions from section 5 of `V7_PLAYTEST_VALIDATION_PROTOCOL.md`.
4. **Save & Commit Log**:
   - Write output to `.scratch/v7-playtest-validation/sessions/P0X.md`.
   - Commit session file to git.
5. **Post-P05 Aggregation**:
   - Calculate `VALUE_SCORE` across all failures:
     $$\text{VALUE\_SCORE} = \frac{\text{frequency} \times \text{severity} \times \text{experience\_impact} \times \text{identity\_importance}}{\text{implementation\_cost\_and\_risk}}$$
   - Update `.scratch/v7-playtest-validation/V7_BASELINE_PLAYTEST_REPORT.md`.
   - Relay raw data and ranking report to ChatGPT via Chrome tab.

---

## 5. ChatGPT Relay Protocol

To relay messages to ChatGPT in Chrome:
- Ensure Chrome is running with active tab: `https://chatgpt.com/g/g-p-699d1f9e9c188191a392e1cc0783af99-fb-13-hs-7/c/6a815c99-1368-83e8-9414-5e17cdc83b27`
- Use `pbcopy` + `osascript` (focus `#prompt-textarea`, paste clipboard `keystroke "v" using command down`, and press Return `key code 36`).
- Read response from `.markdown-content` / `[data-message-author-role="assistant"]`.
