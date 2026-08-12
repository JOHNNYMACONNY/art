# Echoes in the Scrapheap

Playable browser vertical slice based on FB-13 / HS-7 Chronicles canon.

## Run

```bash
python3 -m http.server 4173
```

Open http://localhost:4173.

## Controls

- `WASD`: move / drive
- Mouse: aim
- Click: fire / advance dialogue
- `E`: interact, enter/exit vehicle, advance dialogue
- `Q`: FB-13 resonance thrum
- `R`: HS-7 memory echo / activate Silent Core
- `Esc`: pause
- `F5`: save
- `N`: new game while paused

## Included

- Compact Gears District sandbox
- On-foot movement and shooting
- Four driveable vehicles
- Civilians, police pursuit, wanted cooldown
- FB-13 thrum and HS-7 wavicle mechanics
- Three linked missions using JMac, Mayor Burn, Lira, Sister Kael, Echotel, and Silent Core lore
- Dialogue, checkpoints, local save/continue, end state
- Original procedural pixel graphics; no third-party game assets

## Design source

Canon references live in `/Users/bobbyinthelobby/life-ops/02_projects/fb13-hs7-chronicles/docs/`.

Implementation intentionally uses browser Canvas with no build step because Godot is not installed in this environment. This gives a working web release now. Porting to canonical Godot 4.4 remains possible later.
