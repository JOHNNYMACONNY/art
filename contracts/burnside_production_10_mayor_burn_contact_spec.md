# Burnside Production 10 — Mayor Burn Known Contact / Garage Armor Restock

Authority: issue #152, product anchor #55, Burnside production contract #118,
Factions & Reputation contract #107, and Production 09 player survivability.

## Player-facing chain

`COMPLETE CIVIC REPOSSESSION -> BURN KNOWS YOU -> RETURN ON FOOT -> ARMOR STASH -> RESTOCK`

Wanted remains authoritative:

`CONTACT / SEARCH -> BURN SERVICE LOCKED`

## Durable relationship authority

One versioned MayorBurnContactProgressStore owns exactly one relationship state:

- UNESTABLISHED
- KNOWN

Civic Repossession completion marks KNOWN exactly once. The state survives Replay
and reload. Unsupported/newer or malformed data fails safe and is never silently
overwritten.

No generalized reputation, faction matrix, points, morality, decay, or social graph.

## Garage service

One root-level MayorBurnContactServiceRuntime is mounted through the retained
Gears District composition seam at MissionDestinationSocket.

Restock is eligible only when:
- Contact is KNOWN;
- Runner is on foot;
- Runner Armor is below PlayerRunner.MAX_ARMOR;
- Wanted heat is 0 and state is CLEAR;
- Runner is inside the existing 2.6m Burn Garage service radius.

Success:
- Armor becomes exactly MAX_ARMOR through PlayerRunner authority;
- Health is unchanged;
- no currency or inventory is created;
- a full-Armor repeat is rejected.

Presentation:
- nearby: BURN // ARMOR STASH
- eligible in radius: RESTOCK ARMOR // ACTION
- Wanted active: WANTED // BURN WON'T OPEN
- full Armor / unknown / mounted: inactive and quiet

Vehicle repair remains separate Production 07 authority.
