# Open World Expansion 01F — Gears District Clutter & Vehicle Fleet Specification

**Status:** APPROVED / TDD_GATE_ACTIVE  
**Baseline:** `main@eb501f3`  
**Engine:** Godot 4.7.1 Stable  
**Creative Reference:** `docs/visual_direction/WORLD_IDENTITY_SPEC.md`, `docs/visual_direction/references/blind_eval_storefront.png`

## 1. Scope & Deliverables

### A. Clutter Expansion Props
1. **Traffic Barriers (`prop_traffic_barrier.tscn`)**:
   - Heavy modular industrial concrete/steel barriers with hazard chevron striping (`#FF5500` / `#1A1C20`).
   - Standard collision bounds (width ~2.0m, height ~0.9m, depth ~0.6m).
   - Dedicated standalone texture asset.
2. **Street Food & Scrap Vendor Stall (`prop_street_vendor.tscn`)**:
   - Scrap-satire street vendor ("SYNTH-PORK // RECYCLED PROTEIN NOODLE CART" / "BIO-SLURRY // 40% ORGANIC").
   - Improvised corrugated canopy, steaming stock pot / scrap bin, generator unit.
   - Standard collision bounds (width ~2.2m, height ~2.4m, depth ~1.6m).
3. **Security Checkpoint (`prop_security_checkpoint.tscn`)**:
   - Corporate civic enforcement post ("QUOTA SURCHARGE CHECKPOINT // SCAN OR SURRENDER").
   - Guard kiosk housing, overhead camera mount, automated barrier arm.
   - Standard collision bounds and interactable/clearance zone.

### B. Vehicle Fleet Expansion
1. **Muscle Coupe (`muscle_coupe.tscn`)**:
   - Low-slung, aggressive 1970s/80s scavenged American muscle silhouette.
   - Pitted matte charcoal steel, rusted hood cowl, exposed intake blower, wide rear tires.
   - Collision envelope (width 1.8m, height 1.25m, length 4.4m).
2. **Scrap Hauler Truck (`scrap_hauler.tscn`)**:
   - Promoted from blocky placeholder to fully modeled & textured industrial flatbed hauler.
   - Reinforced cab grill, hazard side-stripes, hydraulic tailgate, scrap storage bay.
   - Collision envelope (width 1.8m, height 1.4m, length 3.8m).
3. **Security Patrol Interceptor (`security_interceptor.tscn`)**:
   - Heavily armored civic debt enforcement cruiser replacing primitive pursuer box.
   - Push bumper, roof-mounted strobe light bar, side corporate pursuit stencil ("CIVIC RECOVERY // PROTECT & INVOICE").
   - Collision envelope (width 1.8m, height 1.35m, length 4.2m).

### C. Mission Loop Tie-in
- Instance props and vehicles into `gears_district_slice_01b.tscn` and `scrap_test_block.tscn`.
- Checkpoints delineate road access, traffic barriers channel pursuit routes, vendor cart anchors pedestrian alley.
- Interceptor model binds to `PursuerPrototype` visual root.
- Retain 100% pass across all existing contract tests (`run_storefront_contract.gd`, `run_clankers_contract.gd`, `mission_scrap_job_runtime_test.gd`).
