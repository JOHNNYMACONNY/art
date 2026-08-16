---
name: echos-in-the-scrap
description: Project instruction layer for Echos in the Scrap (Godot 4.x / GDScript 3D golden slice).
---

# ECHOS IN THE SCRAP — AGENT SPECIFICATION

GAME=ECHOS_IN_THE_SCRAP

ENGINE
Godot 4.x
GDScript
3D
mobile-first
desktop supported
web secondary/prototyping where useful

PLAYER_EXPERIENCE
FUN > FEEL > CLARITY > FEATURE_COUNT
controls and camera are foundational
audio is first-class gameplay/identity
stable frame pacing > excessive visual complexity

REFERENCE_LANGUAGE
GTA Chinatown Wars = reference for:
- elevated 3/4 readability
- compact action-game camera
- strong silhouettes
- immediate movement
- handheld/touch control philosophy
- tactile contextual interactions

DO_NOT_COPY
- GTA assets
- characters
- map designs
- UI artwork
- logos
- typography
- missions
- proprietary content

ECHOS_IDENTITY
- industrial scrap-world
- rust/corroded machinery
- analog/electrical atmosphere
- FB-13 / HS-7 identity where verified canon permits
- aggressive sound feedback
- original silhouettes
- original interface
- original worldbuilding

CAMERA_TARGET
fixed elevated 3/4
low-FOV perspective
approx initial tuning:
FOV ~32deg
pitch ~58deg downward
yaw ~45deg
velocity look-ahead
damped response
parameters tunable from evidence

MOVEMENT_TARGET
screen-relative analog movement
floating left-thumb joystick
immediate response
clean stop
normalized diagonals
8-way visual facing acceptable
movement itself remains analog

ACTION_TARGET
one large contextual right-thumb action
interaction magnetism selects target
magnetism does NOT move/teleport player
clear highlight before action

FIRST_INTERACTION
Corroded Panel Extraction:
approach
-> highlight
-> action
-> peel panel
-> expose core
-> extract
-> sparks/audio/haptic/visual payoff

target duration ~1-2 sec
gesture forgiving
no precision-thumb requirement

AUDIO
not polish
verify in runtime/playback
minimum prototype:
- industrial ambience
- locomotion feedback
- target/core hum
- metal peel/grind
- electrical sparks
- extraction transient
- completion signature

PROTOTYPE_SCOPE
one scrap-yard test block
one player placeholder
one interactable
camera
movement
touch controls
interaction
audio
basic FX

OUT_OF_SCOPE_INITIAL
missions
combat
vehicles
inventory
progression
procedural generation
networking
external AI
new save architecture
large content systems

CANON
Never convert placeholder implementation names into canon.
Use:
CANON
IMPLEMENTED
PROPOSED
EXPERIMENTAL
UNKNOWN
when distinction matters.

AGENT_EXECUTION
STATE
-> VERIFY
-> HIGHEST_VALUE_GAP
-> PLAN
-> EXECUTE
-> RUN
-> OBSERVE
-> FIX
-> VERIFY_RESULT
-> REPORT

Never claim success from compilation alone.
