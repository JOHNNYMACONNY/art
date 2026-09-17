# GTA San Andreas Audio Architecture & Codebase Sound Mapping

## Executive Summary
This document establishes the definitive, primary-source structural mapping of the **Grand Theft Auto: San Andreas (GTA:SA)** sound system and specifies how every audio subsystem maps to our game engine (`JOHNNYMACONNY/art`).

---

## 1. Primary Archive Structure

The GTA:SA audio system is partitioned into three core subdirectories:

```
audio/
├── CONFIG/                 # Lookup tables, bank allocations, event triggers
│   ├── BankLkup.dat        # Binary offset & size table for all SFX banks (12 bytes/bank)
│   ├── BankSlot.dat        # Dynamic memory slot allocation limits per bank
│   ├── EventVol.dat        # Default playback attenuation per audio event
│   ├── PakFiles.dat        # Master list of SFX pak files
│   ├── StrmPaks.dat        # Stream lookup table
│   └── TrakLkup.dat        # Radio track offset & cue tables
├── SFX/                    # Sound Effect PAK archives (Mono/Stereo 16-bit PCM)
│   ├── GENRL               # 144 Sound Banks: Vehicles, Weapons, UI, Collisions, Sirens
│   ├── FEET                # Footstep impact sounds categorized by surface material
│   ├── PAIN_A              # Player & NPC physical exertion, damage grunts, breathing
│   ├── SCRIPT              # Scripted mission triggers, alarms, ambient set-piece SFX
│   └── SPC_EA .. SPC_PA    # Pedestrian speech banks (Civilians, Police Dispatch, Workers)
└── streams/                # Continuous streaming audio (Radio stations, Ambience, Cutscenes)
    ├── AA, HC, MH, CO, DS  # Radio stations (Radio Los Santos, Radio X, K-DST, SF-UR, etc.)
    ├── MR, CR, CH, NJ, RE  # CSR 103.9, Bounce FM, K-Rose, K-Jah, Master Sounds
    ├── RG                  # WCTR Talk Radio
    ├── ADVERTS             # Commercials & station breaks
    ├── AMBIENCE            # Continuous background environmental beds
    └── BEATS               # Rhythm tracks & mini-game music
```

---

## 2. GENRL Bank Taxonomy & Precise Sound Mappings

`GENRL` contains **144 specialized sound banks** (indexed 000 through 143 in `BankLkup.dat`).

### A. Vehicle Propulsion & Engines
* **Motorcycles (High-RPM / Sport — PCJ-600, NRG-500, BF-400):**
  * `Bank 118` (Deceleration / Engine Overrun / Coast)
  * `Bank 119` (Acceleration / Dynamic Throttle Roar)
* **Dirt Bikes & Light Off-Road (Sanchez, Quadbike):**
  * `Bank 041` (Single-cylinder 4-stroke thrum / idle / rev)
  * `Bank 042` (Exhaust pop / transmission overrun)
* **Bicycles & Lightweight Wheels (Mountain Bike, BMX):**
  * `Bank 012` & `Bank 013` (Chain pedal clicks, freewheel hub clicking, coaster brake pad friction)
* **Heavy Utility & Industrial Trucks (Dumper, Linerunner, Flatbed -> Scrap Hauler):**
  * `Bank 043` & `Bank 044` (Heavy low-RPM diesel throb, air brake purge, turbo spool)
* **Civilian Sedans & Cruisers:**
  * `Bank 001`, `Bank 002`, `Bank 010`, `Bank 011`, `Bank 019`, `Bank 020`

### B. Vehicle Handling, Tires, Collisions & Damage
* **Bank 138 (45 sounds — Vehicle Mechanics & Foley):**
  * `Sound 0-5`: Door opening, door slamming, latch release.
  * `Sound 10-15`: Suspension compression, spring rebound over potholes/curbs.
  * `Sound 20-25`: Low-speed tire roll, gravel scuff, pavement slide.
  * `Sound 28-32`: High-friction tire screech (Brake lock & Handbrake power-slide).
  * `Sound 35-42`: Metal crumple, body panel glance, chassis bottom-out, glass shatter.

### C. Weapons, Alarms, Sirens & Route Gates
* **Bank 039 (72 sounds — Combat, Sirens & Heavy Infrastructure):**
  * `Sound 0-10`: Heavy metallic gate slamming, hydraulic industrial lock, solenoid clicks.
  * `Sound 15-20`: Police cruiser wailing siren, yelp siren, emergency advisory horn.
  * `Sound 30-45`: Spark arcs, electrical transformer buzz, circuit breaker pop.
  * `Sound 50-70`: Impact thuds, concussive pressure waves.

### D. Industrial Machinery, Relays & Electronics
* **Bank 027 (24 sounds — Mechanical & Electrical Tools):**
  * Prying metal panels, crowbar lever tension, wire clipping, mechanical gear clicks.

### E. Frontend UI, HUD & Game State Audio
* **Bank 143 (89 sounds — UI Semantic Layer):**
  * `Sound 4`: Invalid action / rejection buzz (`ui.reject`).
  * `Sound 17`: Mode switch / toggle switch click (`ui.mode_switch`).
  * `Sound 44`: Menu back / cancel cue (`ui.nav_back`).
  * `Sound 47`: Radio station tuner step (`ui.radio_station_step`).
  * `Sound 73`: Replay / retry commitment latch (`ui.replay_retry_confirm`).
  * `Sound 76`: Crisp cursor navigation tick (`ui.nav_move`).
  * `Sound 77`: Positive relay confirmation latch (`ui.nav_confirm`).

---

## 3. Surface Foley Architecture (`FEET` PAK)

Footsteps in GTA:SA are dynamically selected based on physics material queries:

| Material ID | Surface Type | Acoustic Characteristics | Target In-Game Terrain |
|---|---|---|---|
| `SURF_CONCRETE` | Asphalt / Pavement | Hard, dry, high-frequency heel-toe strike | Main district streets, parking lots |
| `SURF_DIRT` | Compacted Soil | Muffled, mid-frequency sand/dust scuff | Scrap yard service roads |
| `SURF_GRAVEL` | Loose Scrap & Pebbles | Granular crunch with secondary pebble scatter | Rusted metal piles, scrap heaps |
| `SURF_METAL` | Iron Plates / Grates | Resonant hollow clank with metallic ping | Catwalks, dumpster roofs, container floors |
| `SURF_WATER` | Puddles / Sludge | Wet splash with liquid release tail | Drainage culverts, oil slicked asphalt |

---

## 4. Radio Station Stream Architecture (`streams/`)

GTA:SA streams are stored in multi-megabyte container files in `audio/streams/`. Each station contains:
1. **Full Music Tracks:** 3 to 5-minute continuous mastered music stems.
2. **DJ Voiceover Introductions (`DJ_INTRO`):** Spoken over the first 4-8 seconds of the track intro without vocals.
3. **DJ Voiceover Outros (`DJ_OUTRO`):** Spoken over the fading track outro.
4. **Station Sweepers & Identifiers (`STATION_ID`):** 1-2 second transition stingers between tracks.
5. **Commercials & News Breaks (`ADVERTS` / `WORLD_NEWS`):** Contextual satire and police reports played every 3-4 songs.

### Implementation Standard for Our Game:
* **Dedicated Music Bus:** Radio streams on `&"Radio"` with independent volume control, separate from `&"Vehicle"` and `&"Master"`.
* **Ducking Rules:**
  * Active Pursuit Siren (`MixState.PURSUIT_PRESSURE`) ducks Radio by `-12 dB` to `-24 dB`.
  * Radio Interference (`MixState.ECHO_WINDOW`) applies high-pass filter + carrier static.
  * Idle / Traversing maintains full radio groove balance under engine roar.

---

## 5. Master Asset Allocation Matrix for Codebase

| System / Gameplay Event | Target GTA:SA Source Bank | Slot ID in `AudioRegistry` | In-Game Target File |
|---|---|---|---|
| **Courier Bike Idle Purr** | `GENRL:BANK_41:SOUND_0` | `vehicle.engine_idle` | `res://audio/vehicle/loop_vehicle_engine_idle.wav` |
| **Courier Bike Throttle Roar** | `GENRL:BANK_119:SOUND_1` | `vehicle.engine_rev` | `res://audio/vehicle/loop_vehicle_engine_rev.wav` |
| **Courier Bike Overrun / Coast** | `GENRL:BANK_118:SOUND_0` | `vehicle.engine_coast` | `res://audio/vehicle/loop_vehicle_engine_coast.wav` |
| **Bike Brake Skid** | `GENRL:BANK_138:SOUND_28` | `vehicle.brake_screech` | `res://audio/vehicle/sfx_vehicle_brake_screech.wav` |
| **Chassis Wall Glance** | `GENRL:BANK_138:SOUND_35` | `vehicle.collision_glance` | `res://audio/vehicle/sfx_vehicle_collision_glance.wav` |
| **Head-On Impact** | `GENRL:BANK_138:SOUND_40` | `vehicle.collision_hard` | `res://audio/vehicle/sfx_vehicle_collision_hard.wav` |
| **Bike Mount / Ignition** | `GENRL:BANK_138:SOUND_2` | `player.bike_mount` | `res://audio/player/sfx_player_bike_mount.wav` |
| **Bike Dismount** | `GENRL:BANK_138:SOUND_4` | `player.bike_dismount` | `res://audio/player/sfx_player_bike_dismount.wav` |
| **Signal Gate Slam** | `GENRL:BANK_039:SOUND_0` | `interaction.gate_triggered` | `res://audio/interaction/sfx_interaction_gate_slam.wav` |
| **Wire Spark Arc** | `GENRL:BANK_039:SOUND_32` | `interaction.wire_spark` | `res://audio/interaction/sfx_interaction_wire_spark.wav` |
| **Panel Pry / Peel** | `GENRL:BANK_027:SOUND_6` | `interaction.panel_peel` | `res://audio/interaction/sfx_interaction_panel_peel.wav` |
| **Core Extract Pull** | `GENRL:BANK_027:SOUND_14` | `interaction.core_extracted` | `res://audio/interaction/sfx_interaction_core_extracted.wav` |
| **Pursuer Siren Alarm** | `GENRL:BANK_039:SOUND_16` | `pursuit.siren_alarm` | `res://audio/pursuit/loop_pursuit_siren_alarm.wav` |
| **Pursuit Alert Stinger** | `SCRIPT:BANK_002:SOUND_4` | `pursuit.disturbance_alert` | `res://audio/pursuit/sfx_pursuit_disturbance_alert.wav` |
| **UI Menu & Navigation** | `GENRL:BANK_143:SOUND_76..77`| `ui.nav_move`, `ui.nav_confirm` | `res://audio/ui/sfx_ui_nav_move.wav`, `sfx_ui_nav_confirm.wav` |
| **UI Action Rejection** | `GENRL:BANK_143:SOUND_4` | `ui.reject` | `res://audio/ui/sfx_ui_reject.wav` |
| **Footsteps (Asphalt)** | `FEET:BANK_001:SOUND_0..3` | `player.footstep` | `res://audio/player/sfx_player_footstep.wav` |

