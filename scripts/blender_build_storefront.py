#!/usr/bin/env python3
"""
scripts/blender_build_storefront.py
Generates production-grade 3D environment assets for the Gears District:
1. Burnside Salvage & Repair Storefront:
   - Deep open workshop interior: 2-post hydraulic vehicle lift, elevated car chassis with exposed V8, tool chest, hoist, oil drums, workbench
   - Rolled-up corrugated door & heavy shutter canister, thick safety bollards with hazard stripes
   - Recessed service door alcove, kickplate, brass handle, neon OPEN sign
   - Fascia signboard with channel frame, 4 large gooseneck barn lamps, corrugated awning with 5 heavy knee braces
   - Rooftop billboard: structural steel angle-iron lattice trusses, catwalk with safety handrails and access ladder, 2 large angled floodlights
   - Right side wall: authentic soot terracotta brick masonry, stencils, large wall gooseneck lamp, electric power meters, disconnect breaker box
   - Roof clutter: industrial cyclone separator on 4-leg frame, louvered AC condenser with top fan cowl & copper lines, tall flanged flue with elbow & guy wires
2. Signal Quota Dispensary Kiosk:
   - Pedestal on concrete anchor base, recessed biometric hand scanner, glowing cyan HUD, keypad, hazard stripes
3. Scrap Dumpster:
   - Trapezoidal bin, forklift pockets, open split lids, cast-iron V8 engine block, curved chrome exhaust headers, transmission bellhousing, alternator, metal shards
4. Surveillance Utility Pole:
   - Tapered octagonal pole, climbing footsteps, transformer with cooling ribs, double cross-arms, 3x surveillance cameras with cyan optics, street signs, FB-HV-04 box, heavy power cables
"""

import os
import math
import bpy
import bmesh
from mathutils import Matrix, Vector, Euler

# 2048x2048 Atlas UV Coordinates (u_min, u_max, v_min, v_max in [0, 1])
# In Blender, (0,0) is bottom-left, (1,1) is top-right
UV_BOXES = {
    'fascia_sign':        (20/2048.0, 1220/2048.0, 1.0 - 320/2048.0, 1.0 - 20/2048.0),
    'hazard_strip':       (20/2048.0, 1220/2048.0, 1.0 - 356/2048.0, 1.0 - 324/2048.0),
    'billboard':          (1240/2048.0, 2028/2048.0, 1.0 - 460/2048.0, 1.0 - 20/2048.0),
    'garage_door':        (20/2048.0, 780/2048.0, 1.0 - 610/2048.0, 1.0 - 360/2048.0),
    'garage_interior':    (20/2048.0, 780/2048.0, 1.0 - 980/2048.0, 1.0 - 610/2048.0),
    'service_door':       (820/2048.0, 1240/2048.0, 1.0 - 980/2048.0, 1.0 - 360/2048.0),
    'neon_open':          (885/2048.0, 1175/2048.0, 1.0 - 905/2048.0, 1.0 - 805/2048.0),
    'wall_stencil':       (1260/2048.0, 1680/2048.0, 1.0 - 1000/2048.0, 1.0 - 480/2048.0),
    'pillar_poster':      (1690/2048.0, 1860/2048.0, 1.0 - 1000/2048.0, 1.0 - 480/2048.0),
    'go13_sign':          (1870/2048.0, 2028/2048.0, 1.0 - 740/2048.0, 1.0 - 480/2048.0),
    'parapet_stencil':    (1870/2048.0, 2028/2048.0, 1.0 - 1000/2048.0, 1.0 - 750/2048.0),
    'quota_kiosk':        (20/2048.0, 720/2048.0, 1.0 - 1600/2048.0, 1.0 - 1020/2048.0),
    'quota_screen':       (60/2048.0, 680/2048.0, 1.0 - 1340/2048.0, 1.0 - 1060/2048.0),
    'dumpster':           (740/2048.0, 1420/2048.0, 1.0 - 1600/2048.0, 1.0 - 1020/2048.0),
    'utility_pole_signs': (1440/2048.0, 2028/2048.0, 1.0 - 1600/2048.0, 1.0 - 1020/2048.0),
    'street_sign_ashford':(1470/2048.0, 1730/2048.0, 1.0 - 1140/2048.0, 1.0 - 1040/2048.0),
    'street_sign_dist13': (1470/2048.0, 1730/2048.0, 1.0 - 1240/2048.0, 1.0 - 1150/2048.0),
    'hv_box':             (1470/2048.0, 1730/2048.0, 1.0 - 1580/2048.0, 1.0 - 1260/2048.0),
    'brick_wall':         (0/2048.0, 680/2048.0, 1.0 - 2048/2048.0, 1.0 - 1620/2048.0),
    'corrugated_metal':   (680/2048.0, 1360/2048.0, 1.0 - 2048/2048.0, 1.0 - 1620/2048.0),
    'scrap_metal':        (1360/2048.0, 1700/2048.0, 1.0 - 2048/2048.0, 1.0 - 1620/2048.0),
    'road_stencil':       (1700/2048.0, 2048/2048.0, 1.0 - 2048/2048.0, 1.0 - 1620/2048.0),
    'dark_metal':         (2002/2048.0, 2046/2048.0, 1.0 - 48/2048.0, 1.0 - 2/2048.0),
    'structural_steel':   (2002/2048.0, 2046/2048.0, 1.0 - 98/2048.0, 1.0 - 52/2048.0),
    'yellow_accent':      (2002/2048.0, 2046/2048.0, 1.0 - 148/2048.0, 1.0 - 102/2048.0),
    'warm_light':         (2002/2048.0, 2046/2048.0, 1.0 - 198/2048.0, 1.0 - 152/2048.0),
    'tar_roof':           (2002/2048.0, 2046/2048.0, 1.0 - 248/2048.0, 1.0 - 202/2048.0),
    'concrete_curb':      (2002/2048.0, 2046/2048.0, 1.0 - 298/2048.0, 1.0 - 252/2048.0),
    'terracotta_brick':   (2002/2048.0, 2046/2048.0, 1.0 - 348/2048.0, 1.0 - 302/2048.0),
    'contact_shadow':     (2002/2048.0, 2046/2048.0, 1.0 - 398/2048.0, 1.0 - 352/2048.0),
    'red_tool_cabinet':   (2002/2048.0, 2046/2048.0, 1.0 - 438/2048.0, 1.0 - 402/2048.0),
    'weathered_cream':    (2002/2048.0, 2046/2048.0, 1.0 - 478/2048.0, 1.0 - 442/2048.0),
    'hazard_stripes':     (20/2048.0, 1220/2048.0, 1.0 - 356/2048.0, 1.0 - 324/2048.0),
}

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_storefront_material(name, atlas_path, emission_color=(0,0,0,1), emission_energy=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new('ShaderNodeOutputMaterial')
    node_out.location = (400, 0)

    node_bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    node_bsdf.location = (100, 0)
    node_bsdf.inputs['Roughness'].default_value = 0.75

    if os.path.exists(atlas_path):
        node_tex = nodes.new('ShaderNodeTexImage')
        node_tex.location = (-250, 0)
        img = bpy.data.images.load(atlas_path)
        node_tex.image = img
        links.new(node_tex.outputs['Color'], node_bsdf.inputs['Base Color'])
        if emission_energy > 0.0:
            node_bsdf.inputs['Emission Color'].default_value = emission_color
            node_bsdf.inputs['Emission Strength'].default_value = emission_energy

    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def add_box_bm(bm, size, pos, rot=(0,0,0), uv_key='brick_wall', primary_face='all', mat_idx=0):
    u1, u2, v1, v2 = UV_BOXES.get(uv_key, (0, 1, 0, 1))
    du1, du2, dv1, dv2 = UV_BOXES['dark_metal']
    dark_uv = ((du1 + du2) * 0.5, (dv1 + dv2) * 0.5)

    res = bmesh.ops.create_cube(bm, size=1.0)
    new_verts = res['verts']
    new_verts_set = set(new_verts)
    new_faces = [f for f in bm.faces if all(v in new_verts_set for v in f.verts)]

    uv_layer = bm.loops.layers.uv.verify()
    for face in new_faces:
        face.material_index = mat_idx
        norm = face.normal
        use_key = False
        if primary_face == 'all':
            use_key = True
        elif primary_face == 'front' and norm.y < -0.8:
            use_key = True
        elif primary_face == 'back' and norm.y > 0.8:
            use_key = True
        elif primary_face == 'top' and norm.z > 0.8:
            use_key = True
        elif primary_face == 'bottom' and norm.z < -0.8:
            use_key = True
        elif primary_face == 'left' and norm.x < -0.8:
            use_key = True
        elif primary_face == 'right' and norm.x > 0.8:
            use_key = True

        for loop in face.loops:
            v_co = loop.vert.co
            if use_key:
                nx = v_co.x + 0.5
                ny = v_co.y + 0.5
                nz = v_co.z + 0.5
                if abs(norm.y) > 0.8:
                    if uv_key == 'brick_wall':
                        loop[uv_layer].uv = (u1 + (nx * size[0] * 0.4) % (u2 - u1), v1 + (nz * size[2] * 0.4) % (v2 - v1))
                    elif norm.y < -0.8:
                        loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
                    else:
                        loop[uv_layer].uv = (u2 - nx * (u2 - u1), v1 + nz * (v2 - v1))
                elif abs(norm.z) > 0.8:
                    if uv_key == 'brick_wall':
                        loop[uv_layer].uv = (u1 + (nx * size[0] * 0.4) % (u2 - u1), v1 + (ny * size[1] * 0.4) % (v2 - v1))
                    else:
                        loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))
                elif abs(norm.x) > 0.8:
                    if uv_key == 'brick_wall':
                        loop[uv_layer].uv = (u1 + (ny * size[1] * 0.4) % (u2 - u1), v1 + (nz * size[2] * 0.4) % (v2 - v1))
                    elif norm.x > 0.8:
                        loop[uv_layer].uv = (u1 + ny * (u2 - u1), v1 + nz * (v2 - v1))
                    else:
                        loop[uv_layer].uv = (u1 + (1.0 - ny) * (u2 - u1), v1 + nz * (v2 - v1))
                else:
                    loop[uv_layer].uv = dark_uv
            else:
                loop[uv_layer].uv = dark_uv

    S = Matrix.Scale(size[0], 4, (1, 0, 0)) @ Matrix.Scale(size[1], 4, (0, 1, 0)) @ Matrix.Scale(size[2], 4, (0, 0, 1))
    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    M = T @ R @ S
    bmesh.ops.transform(bm, matrix=M, verts=new_verts)

def add_cylinder_bm(bm, radius1, radius2, depth, pos, rot=(0,0,0), segs=16, uv_key='structural_steel', is_optic=False, mat_idx=0):
    u1, u2, v1, v2 = UV_BOXES.get(uv_key, (0, 1, 0, 1))
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=radius1, radius2=radius2, depth=depth)
    new_verts = res['verts']
    new_verts_set = set(new_verts)
    new_faces = [f for f in bm.faces if all(v in new_verts_set for v in f.verts)]

    uv_layer = bm.loops.layers.uv.verify()
    for face in new_faces:
        face.material_index = mat_idx
        norm = face.normal
        for loop in face.loops:
            v_co = loop.vert.co
            if is_optic and abs(norm.z) > 0.8:
                nx = v_co.x + 0.5
                ny = v_co.y + 0.5
                loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))
            else:
                loop[uv_layer].uv = ((u1 + u2) * 0.5, (v1 + v2) * 0.5)

    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    M = T @ R
    bmesh.ops.transform(bm, matrix=M, verts=new_verts)

def add_strut_bm(bm, p1, p2, thickness=0.12, uv_key='structural_steel', mat_idx=0):
    v1 = Vector(p1)
    v2 = Vector(p2)
    diff = v2 - v1
    length = diff.length
    if length < 0.001:
        return
    center = (v1 + v2) * 0.5
    direction = diff.normalized()

    up = Vector((0, 0, 1))
    if abs(direction.dot(up)) > 0.99:
        up = Vector((0, 1, 0))
    rot_quat = Vector((0, 0, 1)).rotation_difference(direction)
    euler = rot_quat.to_euler()

    add_box_bm(bm, (thickness, thickness, length), center, rot=(euler.x, euler.y, euler.z), uv_key=uv_key, mat_idx=mat_idx)


# =============================================================================
# 1. BURNSIDE SALVAGE & REPAIR STOREFRONT BUILDING
# =============================================================================
def build_storefront_building(atlas_path, out_glb):
    reset_scene()
    mat_main = create_storefront_material("Mat_StorefrontMain", atlas_path)
    mat_neon = create_storefront_material("Mat_StorefrontNeon", atlas_path, emission_color=(1.0, 0.2, 0.15, 1.0), emission_energy=0.8)

    bm = bmesh.new()

    # Main Building Shell (9.2m wide, 5.4m deep, 4.8m high)
    # Front facade sits at Blender Y = -2.7m (Godot Z = +2.7m)
    # Left pillar (X in [-4.6, -3.8], width 0.8m)
    add_box_bm(bm, (0.8, 5.4, 4.8), (-4.2, 0.0, 2.4), uv_key='brick_wall')
    # Front Left Pillar Propaganda Poster: "A CLEANER // BRIGHTER // STRONGER // GEARS DISTRICT"
    add_box_bm(bm, (0.76, 0.04, 2.70), (-4.2, -2.71, 2.30), uv_key='pillar_poster', primary_face='front')

    # Center divider pillar (X in [0.6, 1.4], width 0.8m) - Soot brick masonry
    add_box_bm(bm, (0.8, 5.4, 4.8), (1.0, 0.0, 2.4), uv_key='brick_wall')
    # Right end pillar (X in [3.6, 4.6], width 1.0m)
    add_box_bm(bm, (1.0, 5.4, 4.8), (4.1, 0.0, 2.4), uv_key='brick_wall')
    # Rear back wall
    add_box_bm(bm, (9.2, 0.6, 4.8), (0.0, 2.4, 2.4), uv_key='brick_wall')
    # Upper lintel wall above doors
    add_box_bm(bm, (9.2, 1.2, 1.4), (0.0, -2.1, 3.9), uv_key='structural_steel')

    # Heavy structural steel vertical column corners (defining comic silhouette)
    for col_x in (-4.62, -3.78, 0.58, 1.42, 3.58, 4.62):
        add_box_bm(bm, (0.12, 0.12, 4.8), (col_x, -2.71, 2.4), uv_key='structural_steel')

    # Concrete roof slab (Dark weathered tar/gravel)
    add_box_bm(bm, (9.4, 5.6, 0.35), (0.0, 0.0, 4.82), uv_key='tar_roof')

    # Roof Parapet Perimeter Walls (H = 0.50m) around roof edge
    add_box_bm(bm, (9.4, 0.32, 0.50), (0.0, -2.66, 5.25), uv_key='structural_steel')
    add_box_bm(bm, (0.32, 5.4, 0.50), (-4.56, 0.0, 5.25), uv_key='structural_steel')
    add_box_bm(bm, (0.32, 5.4, 0.50), (4.56, 0.0, 5.25), uv_key='structural_steel')
    add_box_bm(bm, (9.4, 0.32, 0.50), (0.0, 2.66, 5.25), uv_key='structural_steel')
    # Front Roof Parapet Stencil: "MOVEMENT KEEPS CITIES ALIVE."
    add_box_bm(bm, (2.6, 0.04, 0.36), (3.0, -2.83, 5.25), uv_key='parapet_stencil', primary_face='front')
    # Modular Steel Coping Caps over Parapets
    add_box_bm(bm, (9.6, 0.40, 0.12), (0.0, -2.66, 5.54), uv_key='structural_steel')
    add_box_bm(bm, (0.40, 5.6, 0.12), (-4.56, 0.0, 5.54), uv_key='structural_steel')
    add_box_bm(bm, (0.40, 5.6, 0.12), (4.56, 0.0, 5.54), uv_key='structural_steel')
    add_box_bm(bm, (9.6, 0.40, 0.12), (0.0, 2.66, 5.54), uv_key='structural_steel')

    # =========================================================================
    # RIGHT SIDE ELEVATION: BRICK, WALL STENCILS, CONDUITS, POWER METERS, LAMP
    # =========================================================================
    # Weathered soot terracotta brick panel with stencils (covers full 4.8m height ground-to-coping)
    add_box_bm(bm, (0.05, 5.4, 4.8), (4.62, 0.0, 2.4), uv_key='wall_stencil', primary_face='right')
    # Also add wall stencil to left wall so 32-degree elevated camera (looking from front-left) shows stencil behind dumpster per Panel A
    add_box_bm(bm, (0.05, 5.4, 4.8), (-4.62, 0.0, 2.4), uv_key='wall_stencil', primary_face='left')
    # Large gooseneck industrial barn lamp on right wall illuminating dumpster area
    add_cylinder_bm(bm, 0.045, 0.045, 0.85, (4.90, 0.2, 4.3), rot=(0, 0, 0.45), segs=10, uv_key='structural_steel')
    add_cylinder_bm(bm, 0.34, 0.14, 0.24, (5.20, 0.2, 4.05), rot=(0, 0, 0.6), segs=16, uv_key='structural_steel')
    add_cylinder_bm(bm, 0.10, 0.10, 0.05, (5.20, 0.2, 3.98), rot=(0, 0, 0.6), segs=8, uv_key='warm_light')

    # =========================================================================
    # OPEN GARAGE BAY & WORKSHOP INTERIOR DEPTH (FORWARD STANCE FOR 32° CAMERA)
    # =========================================================================
    # Portal surround with yellow hazard stripes
    add_box_bm(bm, (0.22, 0.40, 3.2), (-3.85, -2.55, 1.6), uv_key='hazard_strip', primary_face='front')
    add_box_bm(bm, (0.22, 0.40, 3.2), (0.65, -2.55, 1.6), uv_key='hazard_strip', primary_face='front')
    add_box_bm(bm, (4.72, 0.40, 0.24), (-1.6, -2.55, 3.2), uv_key='hazard_strip', primary_face='front')

    # Rolled-up Corrugated Door Curtain (Upper 0.40m of bay, leaves 2.8m opening)
    add_box_bm(bm, (4.4, 0.12, 0.40), (-1.6, -2.45, 3.05), uv_key='garage_door', primary_face='front')
    # Heavy cylindrical roll-up shutter drum above door
    add_cylinder_bm(bm, 0.26, 0.26, 4.55, (-1.6, -2.40, 3.35), rot=(0, math.pi/2, 0), segs=16, uv_key='structural_steel')

    # Workshop Interior Backdrop (100% authentic concept art crop showing lift, muscle car, and lights)
    add_box_bm(bm, (4.4, 0.10, 2.8), (-1.6, -1.5, 1.4), uv_key='garage_interior', primary_face='front')
    # Workshop Interior Side Walls
    add_box_bm(bm, (0.10, 1.4, 2.8), (-3.8, -2.1, 1.4), uv_key='structural_steel')
    add_box_bm(bm, (0.10, 1.4, 2.8), (0.6, -2.1, 1.4), uv_key='structural_steel')

    # Two Slender Yellow Safety Bollards flanking garage entrance (matching Panel B)
    for bx in (-3.7, 0.5):
        # Square mounting flange plate with anchor bolts
        add_box_bm(bm, (0.28, 0.28, 0.05), (bx, -2.75, 0.03), uv_key='structural_steel')
        # Bollard post (diameter 0.16m, height 0.85m)
        add_cylinder_bm(bm, 0.08, 0.08, 0.85, (bx, -2.75, 0.45), segs=12, uv_key='yellow_accent')
        # Bollard hazard stripe collar
        add_cylinder_bm(bm, 0.085, 0.085, 0.22, (bx, -2.75, 0.70), segs=12, uv_key='hazard_stripes')

    # =========================================================================
    # RECESSED SERVICE ENTRANCE (Door X in [1.9, 3.1], recessed 0.35m)
    # =========================================================================
    # Recessed door alcove
    add_box_bm(bm, (1.30, 0.12, 2.50), (2.5, -2.35, 1.25), uv_key='service_door', primary_face='front')
    # Heavy steel door lintel and frame
    add_box_bm(bm, (1.50, 0.35, 0.18), (2.5, -2.55, 2.50), uv_key='structural_steel')
    add_box_bm(bm, (0.14, 0.35, 2.50), (1.80, -2.55, 1.25), uv_key='structural_steel')
    add_box_bm(bm, (0.14, 0.35, 2.50), (3.20, -2.55, 1.25), uv_key='structural_steel')
    # Heavy brass door pull handle
    add_box_bm(bm, (0.05, 0.10, 0.50), (3.10, -2.48, 1.15), uv_key='yellow_accent')
    # Kickplate at bottom of door
    add_box_bm(bm, (1.10, 0.05, 0.28), (2.5, -2.38, 0.15), uv_key='structural_steel')
    # Illuminated neon "OPEN" sign box (emissive mat_idx=1, mapped specifically to neon_open)
    add_box_bm(bm, (0.60, 0.18, 0.38), (3.5, -2.68, 1.75), uv_key='neon_open', primary_face='front', mat_idx=1)
    # Conduit from door frame to neon sign
    add_cylinder_bm(bm, 0.025, 0.025, 0.45, (3.25, -2.68, 1.75), rot=(0, math.pi/2, 0), segs=8, uv_key='structural_steel')

    # =========================================================================
    # MAIN FASCIA SIGNBOARD & CORRUGATED AWNING WITH KNEE BRACES
    # =========================================================================
    add_box_bm(bm, (8.8, 0.24, 1.8), (0.0, -2.82, 3.95), uv_key='fascia_sign', primary_face='front')
    # Heavy structural steel perimeter channel frame
    add_box_bm(bm, (9.0, 0.32, 0.12), (0.0, -2.82, 4.88), uv_key='structural_steel')
    add_box_bm(bm, (9.0, 0.32, 0.12), (0.0, -2.82, 3.02), uv_key='structural_steel')
    add_box_bm(bm, (0.12, 0.32, 1.95), (-4.45, -2.82, 3.95), uv_key='structural_steel')
    add_box_bm(bm, (0.12, 0.32, 1.95), (4.45, -2.82, 3.95), uv_key='structural_steel')

    # Forward Corrugated Metal Awning Canopy under fascia sign (extends forward 0.90m)
    add_box_bm(bm, (9.2, 0.90, 0.14), (0.0, -3.25, 2.98), uv_key='corrugated_metal')
    # Awning front hazard chevron fascia strip
    add_box_bm(bm, (9.25, 0.06, 0.16), (0.0, -3.70, 2.98), uv_key='hazard_stripes', primary_face='front')
    # 5 Heavy Triangular steel knee braces supporting awning from lintel
    for kx in (-4.0, -2.0, 0.0, 2.0, 4.0):
        add_strut_bm(bm, (kx, -2.70, 2.20), (kx, -3.65, 2.95), thickness=0.16, uv_key='structural_steel')
        add_box_bm(bm, (0.18, 0.08, 0.80), (kx, -2.68, 2.20), uv_key='structural_steel')
        add_box_bm(bm, (0.16, 0.95, 0.12), (kx, -3.18, 2.95), uv_key='structural_steel')

    # 4 Large Gooseneck Industrial Barn Lamps curving over Fascia Sign
    for lx in (-3.2, -1.0, 1.0, 3.2):
        # Base plate on parapet wall
        add_box_bm(bm, (0.24, 0.24, 0.08), (lx, -2.68, 5.25), uv_key='structural_steel')
        # Arched conduit arm curving over top of sign
        add_cylinder_bm(bm, 0.045, 0.045, 0.95, (lx, -3.15, 5.25), rot=(0.42, 0, 0), segs=10, uv_key='structural_steel')
        # Wide conical lamp shade angled down at sign
        add_cylinder_bm(bm, 0.34, 0.14, 0.24, (lx, -3.48, 4.95), rot=(0.55, 0, 0), segs=16, uv_key='structural_steel')
        # Warm amber bulb
        add_cylinder_bm(bm, 0.10, 0.10, 0.05, (lx, -3.48, 4.85), rot=(0.55, 0, 0), segs=10, uv_key='warm_light')
    # Conduit cable linking gooseneck lamps across parapet
    add_cylinder_bm(bm, 0.03, 0.03, 7.0, (0.0, -2.68, 5.25), rot=(0, math.pi/2, 0), segs=8, uv_key='structural_steel')

    # =========================================================================
    # ROOFTOP BILLBOARD: "LUNG-RENEW 4.0" (FORWARD STANCE, TRUSSES, CATWALK, FLOODLIGHTS)
    # =========================================================================
    bx_center = -0.5
    by_pos = -2.10 # Near front roof edge for maximum camera prominence
    bz_center = 7.10 # Raised slightly so catwalk sits cleanly below display bezel
    b_tilt = -0.06

    # Main billboard display panel (5.4m wide x 2.8m high)
    add_box_bm(bm, (5.4, 0.14, 2.8), (bx_center, by_pos, bz_center), rot=(b_tilt, 0, 0), uv_key='billboard', primary_face='front')
    # Structural steel channel outer frame around billboard
    add_box_bm(bm, (5.60, 0.26, 0.15), (bx_center, by_pos - 0.02, bz_center + 1.48), rot=(b_tilt, 0, 0), uv_key='structural_steel')
    add_box_bm(bm, (5.60, 0.26, 0.15), (bx_center, by_pos + 0.02, bz_center - 1.48), rot=(b_tilt, 0, 0), uv_key='structural_steel')
    add_box_bm(bm, (0.15, 0.26, 3.05), (bx_center - 2.80, by_pos, bz_center), rot=(b_tilt, 0, 0), uv_key='structural_steel')
    add_box_bm(bm, (0.15, 0.26, 3.05), (bx_center + 2.80, by_pos, bz_center), rot=(b_tilt, 0, 0), uv_key='structural_steel')

    # Heavy Structural Steel Angle-Iron Lattice Trusses (4 Vertical Columns)
    col_x_offsets = [-2.4, -0.8, 0.8, 2.4]
    for rel_x in col_x_offsets:
        cx = bx_center + rel_x
        # Upright vertical column from roof slab (Z=4.82) to top of billboard (Z=8.70)
        add_strut_bm(bm, (cx, by_pos + 0.22, 4.82), (cx, by_pos + 0.22, 8.70), thickness=0.14, uv_key='structural_steel')
        # Footplate anchored to concrete roof slab
        add_box_bm(bm, (0.42, 0.42, 0.08), (cx, by_pos + 0.22, 4.85), uv_key='structural_steel')
        # Rear diagonal kicker strut (backstay) anchoring to roof
        add_strut_bm(bm, (cx, by_pos + 0.22, 8.35), (cx, by_pos + 1.85, 4.82), thickness=0.12, uv_key='structural_steel')
        add_box_bm(bm, (0.36, 0.36, 0.08), (cx, by_pos + 1.85, 4.85), uv_key='structural_steel')
        # Mid-height horizontal spreader strut
        add_strut_bm(bm, (cx, by_pos + 0.22, 6.7), (cx, by_pos + 1.05, 4.82), thickness=0.10, uv_key='structural_steel')

    # Horizontal tie girts between truss columns
    for gz in (5.6, 7.0, 8.4):
        add_strut_bm(bm, (bx_center - 2.4, by_pos + 0.22, gz), (bx_center + 2.4, by_pos + 0.22, gz), thickness=0.10, uv_key='structural_steel')

    # Diagonal X-bracing in truss bays
    for i in range(len(col_x_offsets) - 1):
        x_a = bx_center + col_x_offsets[i]
        x_b = bx_center + col_x_offsets[i+1]
        add_strut_bm(bm, (x_a, by_pos + 0.22, 5.6), (x_b, by_pos + 0.22, 7.0), thickness=0.08, uv_key='structural_steel')
        add_strut_bm(bm, (x_b, by_pos + 0.22, 5.6), (x_a, by_pos + 0.22, 7.0), thickness=0.08, uv_key='structural_steel')
        add_strut_bm(bm, (x_a, by_pos + 0.22, 7.0), (x_b, by_pos + 0.22, 8.4), thickness=0.08, uv_key='structural_steel')
        add_strut_bm(bm, (x_b, by_pos + 0.22, 7.0), (x_a, by_pos + 0.22, 8.4), thickness=0.08, uv_key='structural_steel')

    # Maintenance Catwalk Platform at billboard base — positioned below billboard lower bezel (Z <= 5.5)
    add_box_bm(bm, (7.4, 0.90, 0.10), (bx_center, by_pos - 0.45, 5.25), uv_key='structural_steel')
    # Catwalk safety handrail vertical posts (low profile so they don't occlude billboard face)
    for st_x in (-3.2, -1.6, 0.0, 1.6, 3.2):
        add_strut_bm(bm, (bx_center + st_x, by_pos - 0.85, 5.30), (bx_center + st_x, by_pos - 0.85, 5.60), thickness=0.06, uv_key='structural_steel')
    # Horizontal safety handrails (top rail sits at Z=5.60, billboard lower edge is at Z=5.62)
    add_cylinder_bm(bm, 0.025, 0.025, 7.4, (bx_center, by_pos - 0.85, 5.60), rot=(0, math.pi/2, 0), segs=8, uv_key='structural_steel')
    # Catwalk end handrails
    for end_x in (-3.7, 3.7):
        add_strut_bm(bm, (bx_center + end_x, by_pos - 0.05, 5.30), (bx_center + end_x, by_pos - 0.85, 5.30), thickness=0.06, uv_key='structural_steel')
        add_strut_bm(bm, (bx_center + end_x, by_pos - 0.05, 5.60), (bx_center + end_x, by_pos - 0.85, 5.60), thickness=0.06, uv_key='structural_steel')
    # Access ladder reaching from roof deck to catwalk
    lad_x = bx_center + 3.4
    add_strut_bm(bm, (lad_x - 0.22, by_pos - 0.40, 4.82), (lad_x - 0.22, by_pos - 0.40, 5.30), thickness=0.05, uv_key='structural_steel')
    add_strut_bm(bm, (lad_x + 0.22, by_pos - 0.40, 4.82), (lad_x + 0.22, by_pos - 0.40, 5.30), thickness=0.05, uv_key='structural_steel')

    # 2 Hooded Halogen Floodlights on Outrigger Brackets angled up at billboard
    for fx in (-1.8, 0.8):
        add_strut_bm(bm, (bx_center + fx, by_pos - 0.85, 5.25), (bx_center + fx, by_pos - 1.45, 5.05), thickness=0.08, uv_key='structural_steel')
        # Rectangular floodlight lamp housing
        add_box_bm(bm, (0.50, 0.36, 0.24), (bx_center + fx, by_pos - 1.50, 5.08), rot=(0.65, 0, 0), uv_key='structural_steel')
        add_box_bm(bm, (0.42, 0.04, 0.18), (bx_center + fx, by_pos - 1.58, 5.12), rot=(0.65, 0, 0), uv_key='warm_light')

    # =========================================================================
    # ROOFTOP HVAC & INDUSTRIAL CLUTTER (CYCLONE BLOWER, AC CONDENSER, EXHAUST)
    # =========================================================================
    # Industrial Cyclone Dust Collector / Blower Unit (Right roof, X=3.5m, towering to Z=9.4m!)
    cyc_x, cyc_y, cyc_z = 3.5, -1.0, 4.82
    # 4 Angle-iron support legs elevating cyclone above roof
    for leg_dx in (-0.55, 0.55):
        for leg_dy in (-0.55, 0.55):
            add_strut_bm(bm, (cyc_x + leg_dx, cyc_y + leg_dy, cyc_z), (cyc_x + leg_dx * 0.4, cyc_y + leg_dy * 0.4, cyc_z + 1.4), thickness=0.09, uv_key='structural_steel')
    # Cross tie braces between legs
    for tz in (5.2, 5.8):
        add_strut_bm(bm, (cyc_x - 0.55, cyc_y - 0.55, tz), (cyc_x + 0.55, cyc_y - 0.55, tz), thickness=0.06, uv_key='structural_steel')
        add_strut_bm(bm, (cyc_x - 0.55, cyc_y + 0.55, tz), (cyc_x + 0.55, cyc_y + 0.55, tz), thickness=0.06, uv_key='structural_steel')

    # Removable yellow dust collection drum under cyclone
    add_cylinder_bm(bm, 0.32, 0.32, 0.70, (cyc_x, cyc_y, cyc_z + 0.35), segs=14, uv_key='yellow_accent')
    # Tapered inverted cyclone cone
    add_cylinder_bm(bm, 0.22, 0.70, 1.20, (cyc_x, cyc_y, cyc_z + 1.65), segs=16, uv_key='structural_steel')
    # Main cyclone cylinder body
    add_cylinder_bm(bm, 0.70, 0.70, 1.35, (cyc_x, cyc_y, cyc_z + 2.90), segs=16, uv_key='corrugated_metal')
    # Tangential spiral inlet duct winding into cylinder
    add_box_bm(bm, (0.42, 0.95, 0.42), (cyc_x - 0.65, cyc_y, cyc_z + 3.10), rot=(0, 0, 0.25), uv_key='dark_metal')
    # Vertical exhaust stack
    add_cylinder_bm(bm, 0.32, 0.32, 1.30, (cyc_x, cyc_y, cyc_z + 4.25), segs=14, uv_key='structural_steel')
    # Conical rain cowl / cap on top (rises to Z = 9.4m!)
    add_cylinder_bm(bm, 0.55, 0.05, 0.35, (cyc_x, cyc_y, cyc_z + 4.80), segs=14, uv_key='structural_steel')

    # Rectangular Louvered AC Condenser Box & Tall Flue Pipe (Left roof, X=-3.5m)
    add_box_bm(bm, (1.60, 1.40, 1.25), (-3.5, -1.0, 5.52), uv_key='structural_steel')
    # Top circular fan cowl and fan grille
    add_cylinder_bm(bm, 0.55, 0.55, 0.15, (-3.5, -1.0, 6.20), segs=16, uv_key='dark_metal')
    add_cylinder_bm(bm, 0.50, 0.50, 0.04, (-3.5, -1.0, 6.15), segs=12, uv_key='structural_steel')
    # Front/back louvered ventilation panels
    add_box_bm(bm, (1.45, 0.04, 0.90), (-3.5, -1.72, 5.52), uv_key='corrugated_metal', primary_face='front')
    # Dual insulated refrigerant line pipes curving into roof pitch pocket
    add_cylinder_bm(bm, 0.05, 0.05, 0.85, (-3.5, -0.15, 5.35), segs=8, uv_key='dark_metal')
    add_cylinder_bm(bm, 0.04, 0.04, 0.85, (-3.3, -0.15, 5.35), segs=8, uv_key='dark_metal')

    # Tall Flue exhaust chimney stack with elbow & guy wires (Left rear roof, X=-3.8m, rises to Z=8.5m!)
    add_cylinder_bm(bm, 0.24, 0.24, 2.80, (-3.8, 0.6, 6.45), segs=14, uv_key='structural_steel')
    # 45° angled segmented elbow joint at top
    add_cylinder_bm(bm, 0.24, 0.24, 0.70, (-3.8, 0.35, 8.0), rot=(0.55, 0, 0), segs=14, uv_key='structural_steel')
    # Flanged collar rings around chimney
    add_cylinder_bm(bm, 0.28, 0.28, 0.06, (-3.8, 0.6, 6.8), segs=14, uv_key='dark_metal')
    # 3 steel guy wires anchoring chimney to roof deck and parapet
    add_strut_bm(bm, (-3.8, 0.6, 7.5), (-4.4, 0.6, 5.25), thickness=0.04, uv_key='structural_steel')
    add_strut_bm(bm, (-3.8, 0.6, 7.5), (-3.8, 1.8, 5.25), thickness=0.04, uv_key='structural_steel')
    add_strut_bm(bm, (-3.8, 0.6, 7.5), (-3.8, -0.6, 5.25), thickness=0.04, uv_key='structural_steel')

    # Satellite telecom dish on rear corner
    add_cylinder_bm(bm, 0.05, 0.05, 1.8, (3.8, 1.8, 5.7), rot=(0, 0.1, 0), segs=8, uv_key='structural_steel')
    add_cylinder_bm(bm, 0.55, 0.08, 0.18, (3.8, 1.8, 6.6), rot=(0.5, 0.3, 0), segs=16, uv_key='structural_steel')

    mesh = bpy.data.meshes.new("StorefrontBurnside_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("StorefrontBurnside_Mesh", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat_main)
    obj.data.materials.append(mat_neon)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Storefront Building GLB:", out_glb)


# =============================================================================
# 2. SIGNAL QUOTA DISPENSARY KIOSK
# =============================================================================
def build_quota_kiosk(atlas_path, out_glb):
    reset_scene()
    mat_main = create_storefront_material("Mat_KioskMain", atlas_path)
    mat_screen = create_storefront_material("Mat_KioskScreen", atlas_path, emission_color=(0.0, 0.95, 1.0, 1.0), emission_energy=2.4)

    bm = bmesh.new()

    # Concrete foundation anchor pad
    add_box_bm(bm, (0.95, 0.75, 0.12), (0.0, 0.0, 0.06), uv_key='brick_wall')
    # Heavy rectangular pedestal base with yellow/black hazard stripes
    add_box_bm(bm, (0.85, 0.65, 0.25), (0.0, 0.0, 0.245), uv_key='hazard_stripes', primary_face='front')
    # Main kiosk body
    add_box_bm(bm, (0.80, 0.60, 1.45), (0.0, 0.0, 1.095), uv_key='quota_kiosk', primary_face='front')
    # Side panel graphics ("DEBT FUELS PROGRESS // GD-13")
    add_box_bm(bm, (0.05, 0.55, 0.70), (0.41, 0.0, 1.15), uv_key='quota_kiosk', primary_face='right')
    add_box_bm(bm, (0.05, 0.55, 0.70), (-0.41, 0.0, 1.15), uv_key='quota_kiosk', primary_face='left')

    # Hooded sun-visor canopy overhang over the screen
    add_box_bm(bm, (0.84, 0.68, 0.12), (0.0, -0.04, 1.88), uv_key='structural_steel')
    add_box_bm(bm, (0.84, 0.22, 0.14), (0.0, -0.38, 1.84), rot=(-0.25, 0, 0), uv_key='structural_steel')

    # Angled biometric scanner console screen (cyan emission, mat_idx=1)
    add_box_bm(bm, (0.68, 0.06, 0.52), (0.0, -0.32, 1.42), rot=(0.14, 0, 0), uv_key='quota_screen', primary_face='front', mat_idx=1)
    # Lower numeric keypad shelf and card/biometric thumb reader
    add_box_bm(bm, (0.70, 0.25, 0.14), (0.0, -0.38, 1.02), rot=(0.30, 0, 0), uv_key='structural_steel')
    add_cylinder_bm(bm, 0.075, 0.075, 0.025, (0.20, -0.42, 1.08), rot=(0.30, 0, 0), segs=12, uv_key='quota_screen', is_optic=True, mat_idx=1)

    # Overhead status antenna mast and amber strobe beacon
    add_cylinder_bm(bm, 0.025, 0.025, 0.55, (-0.32, 0.15, 2.15), segs=8, uv_key='structural_steel')
    add_cylinder_bm(bm, 0.055, 0.055, 0.12, (-0.32, 0.15, 2.45), segs=10, uv_key='yellow_accent')

    mesh = bpy.data.meshes.new("PropQuotaKiosk_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("PropQuotaKiosk_Mesh", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat_main)
    obj.data.materials.append(mat_screen)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Quota Kiosk GLB:", out_glb)


# =============================================================================
# 3. SCRAP DUMPSTER WITH DETAILED MECHANICAL SALVAGE HEAP
# =============================================================================
def build_scrap_dumpster(atlas_path, out_glb):
    reset_scene()
    mat_main = create_storefront_material("Mat_DumpsterMain", atlas_path)

    bm = bmesh.new()

    # Heavy bottom skid runners
    add_box_bm(bm, (2.2, 0.14, 0.10), (0.0, -0.52, 0.05), uv_key='structural_steel')
    add_box_bm(bm, (2.2, 0.14, 0.10), (0.0, 0.52, 0.05), uv_key='structural_steel')
    # Floor plate
    add_box_bm(bm, (2.2, 1.3, 0.08), (0.0, 0.0, 0.12), uv_key='structural_steel')

    # Front, Back, Left, Right Dumpster Walls with "BURN SALVAGE" and hazard triangle
    add_box_bm(bm, (2.2, 0.08, 1.25), (0.0, -0.62, 0.74), uv_key='dumpster', primary_face='front')
    add_box_bm(bm, (2.2, 0.08, 1.25), (0.0, 0.62, 0.74), uv_key='dumpster', primary_face='back')
    add_box_bm(bm, (0.08, 1.3, 1.25), (-1.08, 0.0, 0.74), uv_key='dumpster', primary_face='left')
    add_box_bm(bm, (0.08, 1.3, 1.25), (1.08, 0.0, 0.74), uv_key='dumpster', primary_face='right')

    # Top perimeter rim stiffener tube
    add_box_bm(bm, (2.3, 0.12, 0.08), (0.0, -0.66, 1.38), uv_key='hazard_stripes', primary_face='front')
    add_box_bm(bm, (2.3, 0.12, 0.08), (0.0, 0.66, 1.38), uv_key='structural_steel')
    add_box_bm(bm, (0.12, 1.4, 0.08), (-1.12, 0.0, 1.38), uv_key='structural_steel')
    add_box_bm(bm, (0.12, 1.4, 0.08), (1.12, 0.0, 1.38), uv_key='structural_steel')

    # Vertical side reinforcement ribs
    for rx in (-0.7, 0.0, 0.7):
        add_box_bm(bm, (0.06, 0.04, 1.22), (rx, -0.67, 0.74), uv_key='structural_steel')
        add_box_bm(bm, (0.06, 0.04, 1.22), (rx, 0.67, 0.74), uv_key='structural_steel')

    # Side forklift lift pockets
    for side_x in (-1.16, 1.16):
        add_box_bm(bm, (0.14, 0.55, 0.16), (side_x, 0.0, 0.85), uv_key='structural_steel')

    # Split hinged lids propped open at angle
    add_box_bm(bm, (1.08, 0.75, 0.04), (-0.55, 0.55, 1.62), rot=(-0.45, 0, 0), uv_key='structural_steel')
    add_box_bm(bm, (1.08, 0.75, 0.04), (0.55, 0.55, 1.55), rot=(-0.35, 0, 0), uv_key='structural_steel')

    # Overflowing 3D Scrap Heap spilling out
    add_box_bm(bm, (2.0, 1.15, 0.55), (0.0, 0.0, 1.18), uv_key='scrap_metal')

    # Cast-iron V8 Engine Block Casting (Dark cast iron steel, NOT yellow!)
    add_box_bm(bm, (0.65, 0.75, 0.42), (-0.45, -0.15, 1.55), rot=(0.25, 0.15, 0.4), uv_key='dark_metal')
    # Cylinder head banks in structural steel
    add_box_bm(bm, (0.60, 0.18, 0.16), (-0.35, -0.32, 1.66), rot=(0.45, 0.15, 0.4), uv_key='structural_steel')
    add_box_bm(bm, (0.60, 0.18, 0.16), (-0.55, 0.02, 1.66), rot=(0.05, 0.15, 0.4), uv_key='structural_steel')

    # Curved Chrome/Dark Exhaust Header Pipes twisting over dumpster lip
    add_cylinder_bm(bm, 0.075, 0.075, 1.30, (-0.25, -0.25, 1.55), rot=(0.4, 0.6, 0.2), segs=12, uv_key='structural_steel')
    add_cylinder_bm(bm, 0.065, 0.065, 1.15, (0.50, 0.10, 1.50), rot=(-0.5, 0.3, -0.4), segs=10, uv_key='dark_metal')

    # Alternator with belt pulley in dark metal / steel
    add_cylinder_bm(bm, 0.18, 0.18, 0.32, (-0.20, 0.30, 1.55), rot=(0.2, 0.1, 0.8), segs=14, uv_key='dark_metal')
    add_cylinder_bm(bm, 0.10, 0.10, 0.12, (-0.20, 0.46, 1.58), rot=(0.2, 0.1, 0.8), segs=12, uv_key='structural_steel')

    # Transmission bellhousing casing
    add_cylinder_bm(bm, 0.30, 0.18, 0.45, (0.15, -0.15, 1.48), rot=(0.3, 0.2, 0.6), segs=14, uv_key='structural_steel')

    # Corrugated metal scrap sheets & angle iron spilling out
    add_box_bm(bm, (0.55, 0.45, 0.05), (-0.75, 0.22, 1.52), rot=(0.5, 0.4, 0.3), uv_key='corrugated_metal')
    add_box_bm(bm, (0.60, 0.35, 0.05), (0.65, -0.22, 1.50), rot=(-0.3, 0.5, 0.4), uv_key='scrap_metal')

    mesh = bpy.data.meshes.new("PropScrapDumpster_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("PropScrapDumpster_Mesh", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat_main)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Scrap Dumpster GLB:", out_glb)


# =============================================================================
# 4. SURVEILLANCE UTILITY POLE
# =============================================================================
def build_utility_pole(atlas_path, out_glb):
    reset_scene()
    mat_main = create_storefront_material("Mat_PoleMain", atlas_path)
    mat_optic = create_storefront_material("Mat_PoleOptic", atlas_path, emission_color=(0.0, 0.95, 1.0, 1.0), emission_energy=2.4)

    bm = bmesh.new()

    # Tapered octagonal steel utility pole (height 6.2m, base r=0.18m, top r=0.12m)
    add_cylinder_bm(bm, 0.18, 0.12, 6.2, (0.0, 0.0, 3.1), segs=14, uv_key='structural_steel')
    # Concrete base footing collar
    add_cylinder_bm(bm, 0.30, 0.30, 0.45, (0.0, 0.0, 0.225), segs=14, uv_key='structural_steel')

    # Climbing footsteps / rungs staggered up pole
    for idx, rz in enumerate(range(12, 54, 5)):
        z_pos = rz * 0.1
        rx = 0.20 if (idx % 2 == 0) else -0.20
        add_box_bm(bm, (0.20, 0.05, 0.04), (rx, 0.0, z_pos), uv_key='structural_steel')

    # Green Street Name Signs: "ASHFORD AVE" and "DISTRICT 13" (Exact aspect ratios matching texture)
    add_box_bm(bm, (1.20, 0.04, 0.32), (0.60, 0.0, 3.2), uv_key='street_sign_ashford', primary_face='front')
    add_box_bm(bm, (0.04, 0.87, 0.30), (0.0, 0.42, 3.0), uv_key='street_sign_dist13', primary_face='left')
    add_cylinder_bm(bm, 0.18, 0.18, 0.14, (0.0, 0.0, 3.1), segs=12, uv_key='structural_steel')

    # High Voltage Breaker Box FB-HV-04 (12.4 kV)
    add_box_bm(bm, (0.52, 0.38, 0.75), (-0.24, 0.0, 1.85), uv_key='hv_box', primary_face='left')
    add_cylinder_bm(bm, 0.035, 0.035, 1.7, (-0.32, 0.10, 0.85), segs=8, uv_key='structural_steel')

    # Cylindrical Transformer Can with cooling ribs at Z = 4.4m
    add_cylinder_bm(bm, 0.32, 0.32, 0.90, (-0.42, 0.15, 4.40), segs=16, uv_key='structural_steel')
    for rib_z in (4.10, 4.30, 4.50, 4.70):
        add_cylinder_bm(bm, 0.34, 0.34, 0.05, (-0.42, 0.15, rib_z), segs=16, uv_key='structural_steel')
    # High-voltage ceramic insulator bushings on top of transformer
    for bx in (-0.52, -0.42, -0.32):
        add_cylinder_bm(bm, 0.045, 0.03, 0.20, (bx, 0.15, 4.95), segs=8, uv_key='yellow_accent')

    # Double Horizontal Cross-Arms with Ceramic Insulator Bells (Z = 5.2m and Z = 5.8m)
    add_box_bm(bm, (2.2, 0.16, 0.16), (0.0, 0.0, 5.2), uv_key='structural_steel')
    add_box_bm(bm, (1.8, 0.14, 0.14), (0.0, 0.0, 5.8), uv_key='structural_steel')
    for ins_x in (-0.95, -0.50, 0.50, 0.95):
        add_cylinder_bm(bm, 0.06, 0.04, 0.18, (ins_x, 0.0, 5.38), segs=8, uv_key='structural_steel')
    for ins_x in (-0.75, 0.75):
        add_cylinder_bm(bm, 0.06, 0.04, 0.18, (ins_x, 0.0, 5.98), segs=8, uv_key='structural_steel')

    # Cluster of 3 Motorized Surveillance Cameras (Z = 4.75m) with glowing cyan optics (mat_idx=1)
    # Camera 1 (Angled forward-right)
    add_box_bm(bm, (0.22, 0.36, 0.18), (0.65, -0.24, 4.80), rot=(0.4, 0, -0.3), uv_key='structural_steel')
    add_cylinder_bm(bm, 0.07, 0.055, 0.12, (0.62, -0.38, 4.75), rot=(math.pi/2 - 0.4, 0, 0.3), segs=12, uv_key='quota_screen', is_optic=True, mat_idx=1)
    # Camera 2 (Angled forward-left)
    add_box_bm(bm, (0.22, 0.36, 0.18), (-0.65, -0.22, 4.80), rot=(0.3, 0, 0.4), uv_key='structural_steel')
    add_cylinder_bm(bm, 0.07, 0.055, 0.12, (-0.62, -0.36, 4.77), rot=(math.pi/2 - 0.3, 0, -0.4), segs=12, uv_key='quota_screen', is_optic=True, mat_idx=1)
    # Camera 3 (Center dome camera looking straight down)
    add_cylinder_bm(bm, 0.12, 0.12, 0.16, (0.0, -0.30, 4.65), rot=(0.5, 0, 0), segs=12, uv_key='structural_steel')
    add_cylinder_bm(bm, 0.08, 0.04, 0.08, (0.0, -0.34, 4.58), rot=(0.5, 0, 0), segs=12, uv_key='quota_screen', is_optic=True, mat_idx=1)

    # Heavy Sagging Industrial Power Cables (thickness 0.045m)
    add_strut_bm(bm, (-0.95, 0.0, 5.38), (-1.65, 1.20, 4.60), thickness=0.045, uv_key='dark_metal')
    add_strut_bm(bm, (-1.65, 1.20, 4.60), (-2.60, 2.60, 4.10), thickness=0.045, uv_key='dark_metal')
    add_strut_bm(bm, (0.95, 0.0, 5.38), (1.65, 1.20, 4.60), thickness=0.045, uv_key='dark_metal')
    add_strut_bm(bm, (1.65, 1.20, 4.60), (2.60, 2.60, 4.10), thickness=0.045, uv_key='dark_metal')
    add_strut_bm(bm, (0.75, 0.0, 5.98), (1.45, 1.00, 5.25), thickness=0.045, uv_key='dark_metal')
    add_strut_bm(bm, (1.45, 1.00, 5.25), (2.40, 2.30, 4.80), thickness=0.045, uv_key='dark_metal')

    mesh = bpy.data.meshes.new("PropUtilityPole_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("PropUtilityPole_Mesh", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat_main)
    obj.data.materials.append(mat_optic)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Utility Pole GLB:", out_glb)


def main():
    atlas_path = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter/tex_storefront_burnside.png"
    sf_glb = "/Users/bobbyinthelobby/{art/godot/models/environment/storefront_burnside.glb"
    kiosk_glb = "/Users/bobbyinthelobby/{art/godot/models/environment/prop_quota_kiosk.glb"
    dumpster_glb = "/Users/bobbyinthelobby/{art/godot/models/environment/prop_scrap_dumpster.glb"
    pole_glb = "/Users/bobbyinthelobby/{art/godot/models/environment/prop_utility_pole.glb"
    blend_path = "/Users/bobbyinthelobby/{art/models_source/storefront_burnside.blend"

    build_storefront_building(atlas_path, sf_glb)
    build_quota_kiosk(atlas_path, kiosk_glb)
    build_scrap_dumpster(atlas_path, dumpster_glb)
    build_utility_pole(atlas_path, pole_glb)

    os.makedirs(os.path.dirname(blend_path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print("Saved source blend:", blend_path)

if __name__ == '__main__':
    main()
