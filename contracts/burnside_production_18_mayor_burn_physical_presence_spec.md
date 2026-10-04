# Burnside Production 18 — Mayor Burn Physical Garage Presence / Known-Contact Encounter

Authority: issue #182, product anchor #55, Burnside production contract #118, retained Production 10 Mayor Burn contact authority, retained Wanted authority, and Productions 07/11/14 Garage service authorities.

## Player-facing chain

`COMPLETE CIVIC REPOSSESSION -> BURN BECOMES KNOWN -> RETURN TO BURN GARAGE ON FOOT -> SEE BURN PHYSICALLY -> ACTION -> SHORT FACE-TO-FACE EXCHANGE -> EXISTING GARAGE SERVICES REMAIN AUTHORITATIVE -> LEAVE`

Wanted case:

`APPROACH BURN WITH ACTIVE WANTED -> BURN REFUSES THE MOMENT -> EVADE -> RETURN CLEAR`

## Canon addition

Mayor Burn is physically present at his existing Garage as a salvage-yard operator/contact. This does not establish whether “Mayor” is an elected civic title.

Visual direction: older working-yard authority silhouette; worn industrial coat/coverall language; charcoal / industrial off-white; restrained hazard amber; practical asymmetry; grease/wear; small municipal-surplus detail; no real-person likeness; no third-party character dependency; no politician caricature.

Character tone: dry, practical, municipal-salvage crime-fiction humor.

Locked clear-state exchange:

- BURN: “You brought me a city truck with the seal still warm.”
- RUNNER: “You wanted the truck.”
- BURN: “I wanted to see if you came back. Armor’s in the bay. Keep the city outside.”

Wanted refusal:

- BURN: “Not with half the city looking over your shoulder. Lose them.”

## Authority boundaries

- Burn is physically visible before KNOWN.
- Contact conversation is actionable only when retained `MayorBurnContactProgressStore` reports KNOWN.
- P18 creates no second relationship authority and no save migration.
- Wanted remains sole authority for CLEAR / CONTACT / SEARCH; P18 never mutates or clears Heat.
- Existing Armor restock, Garage repair, Courier Bike claim, and Scrap Bash Bar customization remain separate authorities.
- Ordinary Action owns the encounter through retained active-target arbitration.
- FIRE / Tool / Strike / vehicle controls do not synthesize Burn interaction.
- Leaving the bounded interaction radius cancels local presentation.
- Full Replay resets transient encounter presentation only; durable KNOWN remains intact.

## Presentation

One pointer-transparent local character-moment surface is mounted under the retained safe-area UI. It identifies the current speaker, presents the locked exchange deterministically, cancels cleanly, and yields back to ordinary HUD/service ownership.

No generalized dialogue framework, branching tree, dialogue wheel, morality meter, standing matrix, relationship points, NPC schedule, pathfinding framework, generalized NPC framework, combat AI, human health/death, new weapons, Heat 2–5, witness framework, new geography, new Garage service, save migration, voice pipeline, or PR #44 camera work.
