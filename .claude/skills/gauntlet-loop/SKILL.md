---
name: gauntlet-loop
description: Turns any goal into one short, paste-ready "gauntlet loop" prompt integrated with Matt Pocock skill pipeline - enforces concrete quality bar, task ticket scoping, TDD red-green implementation, subagent builder/critic blind evaluation, and code-review standards verification. Works for builds, writing, code, research, or game design. Triggers on "/gauntlet-loop", "gauntlet loop", "gauntlet this", "make a gauntlet prompt", "loop until it beats X".
---

# Gauntlet Loop (Pocock-Integrated)

The user gives a goal. You generate ONE short prompt integrating Matt Pocock's pipeline with the Gauntlet builder-critic loop.

## Architecture

```
[Pocock Layer: Scope & Bounds]
  WAYFINDER -> TO-SPEC -> TO-TICKETS
               |
               v
  [Gauntlet Layer: Inner Grind]
    BUILDER (TDD) -> CRITIC (Blind A/B vs Bar) -> LOOP UNTIL WIN
               |
               v
[Pocock Layer: Verification]
  CODE-REVIEW (Standards + Spec + 100% Green Contracts)
```

## Flow

1. **Read the goal.** Restate internally. Verify active Pocock ticket or spec boundary.
2. **Set the bar.** If user supplied reference, use it. If not, offer **2 or 3 candidate bars** (named, fetchable, comparable) and stop. Wait for pick.
3. **Write the prompt.** One block, paste-ready, integrating Pocock TDD contracts and Gauntlet blind review.
4. **Offer to run it.** One flat line: "I can run this here."

## Prompt Template (Pocock + Gauntlet)

```
Execute [GOAL] under active Pocock ticket boundary.

The bar is [BAR]. Fetch the real reference first and compare directly, not against memory or description.

Inner loop:
1. Builder subagent writes failing test contract first (Pocock TDD Red).
2. Builder implements minimal GDScript / code to satisfy contract (Pocock TDD Green).
3. Critic subagent (fresh context, labels stripped) inspects actual output against the bar blind.
4. Critic names single biggest quality gap and decides winner: ours vs bar.

The critic must be harsh. Praise is forbidden. If ours does not win, loop back to Builder.

Outer exit gate:
Loop exits ONLY when Critic picks ours blind AND code-review verifies 100% green test contracts with zero regression against retained baselines.

Keep live progress updating. Fan out subagents.
```

## Rules

- **Bake the bar in**: Named, fetchable, comparable (e.g. real Chinatown Wars frame capture, URL, repo).
- **Pocock TDD enforcement**: Builder must not edit production code without red-green contract.
- **Pocock Code-Review gate**: Winning the visual/taste comparison is half the battle; code must also pass Pocock standards and repo test suites.
- **Never exit on round count**: Exit only on blind win + all test contracts passing.
