# Mission / Narrative 01 — First Complete Scrap-Job Crime Loop

**Status:** implementation target  
**Baseline:** `7627601089f1872d906452e90da2db3dd533784f`  
**Product intent:** turn the existing golden-slice playground into one authored, replayable crime job without introducing a general-purpose mission framework.

## Player fantasy

Lira sends the runner to steal a customs salvage core that the yard has already marked for municipal recycling. The runner takes the Courier Bike, crosses the yard, spoofs the tuner, pulls the core, survives the resulting pursuit, chooses whether to spend the Signal Gate shortcut, and gets a concrete payoff once contact is broken.

Tone is economical crime satire: short lines, sharp contrast between criminal pragmatism and bureaucratic language, dry consequences communicated through gameplay. No imitation of a living writer.

## Authored flow

`briefing/contact -> get bike -> vehicle traversal -> tuner spoof -> core extraction -> pursuit complication -> route decision -> escape/failure -> payoff/aftermath`

The job reuses the retained Courier Bike, Signal Tuner, Corroded Panel, Memory Echo, pursuit, Signal Gate, fast retry, radio/audio, camera and interaction systems. It must not reopen retained camera/steering/audio-foundation work.

## Acceptance criteria

1. A visible mission HUD identifies the job, current objective and current contact line during normal play.
2. On cold start the player receives a concise Lira briefing and an objective to take the Courier Bike.
3. Mounting the Courier Bike advances the objective to traverse to the tuner mast; arriving near the tuner advances it to the spoof interaction.
4. Locking the tuner advances the objective to steal the customs core; extracting the core advances the job into escape pressure without bypassing the existing Memory Echo sequence.
5. When the existing pursuer becomes active, the job presents a route decision: Signal Gate shortcut or long road.
6. Triggering the Signal Gate records the shortcut route and updates the escape objective. Escaping without the gate records the long-road route.
7. Interception puts the job in a failed/retry state and preserves the existing fast pursuit retry flow. When the retained pursuit retry restarts, the job returns to the route-decision/escape phase rather than replaying solved setup.
8. Successful pursuit de-escalation completes the job and shows an explicit payoff plus a short aftermath line.
9. A deterministic contract test covers the authored state machine, including shortcut completion, long-road completion, interception/retry, wrong-order rejection and objective/payoff text.
10. The existing canonical Godot Web Playtest compatibility matrix remains green on the exact PR head.

## Non-goals

- No inventory, economy, mission database, quest journal, cutscene system, branching dialogue framework or general mission graph.
- No new vehicle, pursuer, camera, steering or audio subsystem.
- No physical-listening or owner-play perceptual gate for this code-first authored job unless a concrete perceptual defect is observed.
- No closure of Audio Runtime #31 or the administratively open Feel/Audio tickets.

## Verification

- New mission-state contract test runs headlessly in CI.
- Existing Web export + exact-head compatibility matrix remain required.
- Interactive browser verification should be attempted only against an exact-commit public/deployed build with browser-control capability; missing browser control is reported as a coverage limitation, not converted into PASS.
