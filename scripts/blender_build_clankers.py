#!/usr/bin/env python3
"""
scripts/blender_build_clankers.py
Builds the 3D models for the Clankers:
1. Scrap Worker Bot (1.9m humanoid clanker) -> godot/models/scrap_worker.glb
2. Utility Crawler Bot (0.6m wheeled clanker) -> godot/models/utility_crawler.glb
Saves source project to models_source/clankers.blend.
Matches clankers_concept_sheet.png exactly.
"""

import bpy
import bmesh
from mathutils import Vector, Euler, Matrix
import os
import math

UV_BOXES = {
    'torso_front':   (41/2048.0, 573/2048.0, 1.0 - 778/2048.0, 1.0 - 41/2048.0),
    'torso_back':    (614/2048.0, 1146/2048.0, 1.0 - 778/2048.0, 1.0 - 41/2048.0),
    'warning_plate': (1188/2048.0, 1597/2048.0, 1.0 - 410/2048.0, 1.0 - 41/2048.0),
    'sensor_optics': (1638/2048.0, 2007/2048.0, 1.0 - 410/2048.0, 1.0 - 41/2048.0),
    'optic_amber':   (1668/2048.0, 1828/2048.0, 1.0 - 231/2048.0, 1.0 - 71/2048.0),
    'optic_cyan':    (1838/2048.0, 1958/2048.0, 1.0 - 221/2048.0, 1.0 - 101/2048.0),
    'yellow_arm':    (41/2048.0, 573/2048.0, 1.0 - 1393/2048.0, 1.0 - 819/2048.0),
    'piston_steel':  (614/2048.0, 1146/2048.0, 1.0 - 1393/2048.0, 1.0 - 819/2048.0),
    'crawler_body':  (1188/2048.0, 2007/2048.0, 1.0 - 1188/2048.0, 1.0 - 451/2048.0),
    'battery_core':  (41/2048.0, 983/2048.0, 1.0 - 2007/2048.0, 1.0 - 1434/2048.0),
    'tread_rubber':  (1024/2048.0, 2007/2048.0, 1.0 - 2007/2048.0, 1.0 - 1434/2048.0),
    'dark_metal':    (20/2048.0, 35/2048.0, 1.0 - 35/2048.0, 1.0 - 20/2048.0),
}

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_clanker_material(name, atlas_path, emission_color=(0,0,0,1), emission_energy=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new('ShaderNodeOutputMaterial')
    node_out.location = (400, 0)

    node_bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    node_bsdf.location = (100, 0)
    node_bsdf.inputs['Roughness'].default_value = 0.65

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

def add_box_bm(bm, size, pos, rot=(0,0,0), uv_key='piston_steel', primary_face='all', mat_idx=0):
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
        elif primary_face == 'top_and_sides' and (norm.z > 0.8 or abs(norm.x) > 0.8 or norm.y < -0.8):
            use_key = True

        for loop in face.loops:
            v_co = loop.vert.co
            if use_key:
                if norm.y < -0.8:
                    nx = v_co.x + 0.5
                    nz = v_co.z + 0.5
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
                elif norm.y > 0.8:
                    nx = 0.5 - v_co.x
                    nz = v_co.z + 0.5
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
                elif norm.z > 0.8:
                    nx = v_co.x + 0.5
                    ny = v_co.y + 0.5
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))
                elif norm.x > 0.8:
                    ny = v_co.y + 0.5
                    nz = v_co.z + 0.5
                    loop[uv_layer].uv = (u1 + ny * (u2 - u1), v1 + nz * (v2 - v1))
                elif norm.x < -0.8:
                    ny = 0.5 - v_co.y
                    nz = v_co.z + 0.5
                    loop[uv_layer].uv = (u1 + ny * (u2 - u1), v1 + nz * (v2 - v1))
                else:
                    loop[uv_layer].uv = dark_uv
            else:
                loop[uv_layer].uv = dark_uv

    S = Matrix.Scale(size[0], 4, (1, 0, 0)) @ Matrix.Scale(size[1], 4, (0, 1, 0)) @ Matrix.Scale(size[2], 4, (0, 0, 1))
    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    M = T @ R @ S
    bmesh.ops.transform(bm, matrix=M, verts=new_verts)

def add_tapered_box_bm(bm, w_top, w_bot, depth, height, pos, rot=(0,0,0), uv_key='piston_steel', primary_face='all', mat_idx=0):
    u1, u2, v1, v2 = UV_BOXES.get(uv_key, (0, 1, 0, 1))
    du1, du2, dv1, dv2 = UV_BOXES['dark_metal']
    dark_uv = ((du1 + du2) * 0.5, (dv1 + dv2) * 0.5)

    ht = height * 0.5
    dp = depth * 0.5
    wt = w_top * 0.5
    wb = w_bot * 0.5

    # 8 vertices
    coords = [
        (-wt, -dp,  ht), # 0: top front left
        ( wt, -dp,  ht), # 1: top front right
        ( wt,  dp,  ht), # 2: top back right
        (-wt,  dp,  ht), # 3: top back left
        (-wb, -dp, -ht), # 4: bot front left
        ( wb, -dp, -ht), # 5: bot front right
        ( wb,  dp, -ht), # 6: bot back right
        (-wb,  dp, -ht), # 7: bot back left
    ]

    verts = [bm.verts.new(c) for c in coords]
    bm.verts.ensure_lookup_table()

    # 6 quad faces
    face_indices = [
        (0, 4, 5, 1), # front
        (2, 6, 7, 3), # back
        (3, 2, 1, 0), # top
        (4, 7, 6, 5), # bottom
        (3, 7, 4, 0), # left
        (1, 5, 6, 2), # right
    ]

    new_faces = []
    for idxs in face_indices:
        f = bm.faces.new([verts[i] for i in idxs])
        new_faces.append(f)
    bm.faces.ensure_lookup_table()

    uv_layer = bm.loops.layers.uv.verify()
    for face in new_faces:
        face.material_index = mat_idx
        norm = face.normal
        use_key = False
        if primary_face == 'all':
            use_key = True
        elif primary_face == 'front' and norm.y < -0.7:
            use_key = True
        elif primary_face == 'back' and norm.y > 0.7:
            use_key = True
        elif primary_face == 'top' and norm.z > 0.7:
            use_key = True

        for loop in face.loops:
            v_co = loop.vert.co
            if use_key:
                if norm.y < -0.7: # Front
                    nx = (v_co.x + wt) / max(w_top, 0.001)
                    nz = (v_co.z + ht) / max(height, 0.001)
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
                elif norm.y > 0.7: # Back
                    nx = (wt - v_co.x) / max(w_top, 0.001)
                    nz = (v_co.z + ht) / max(height, 0.001)
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
                elif norm.z > 0.7: # Top
                    nx = (v_co.x + wt) / max(w_top, 0.001)
                    ny = (v_co.y + dp) / max(depth, 0.001)
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))
                else:
                    loop[uv_layer].uv = dark_uv
            else:
                loop[uv_layer].uv = dark_uv

    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    M = T @ R
    bmesh.ops.transform(bm, matrix=M, verts=verts)

def add_cylinder_bm(bm, radius1, radius2, depth, pos, rot=(0,0,0), segs=16, uv_key='piston_steel', is_optic=False, mat_idx=0):
    u1, u2, v1, v2 = UV_BOXES.get(uv_key, (0, 1, 0, 1))
    du1, du2, dv1, dv2 = UV_BOXES['dark_metal']
    dark_uv = ((du1 + du2) * 0.5, (dv1 + dv2) * 0.5)

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
            if norm.z > 0.8:
                if is_optic:
                    nx = (v_co.x / max(radius1, 0.001)) * 0.5 + 0.5
                    ny = (v_co.y / max(radius1, 0.001)) * 0.5 + 0.5
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))
                else:
                    loop[uv_layer].uv = dark_uv
            elif norm.z < -0.8:
                loop[uv_layer].uv = dark_uv
            else:
                angle = math.atan2(v_co.y, v_co.x)
                nu = (angle / (2.0 * math.pi)) + 0.5
                nv = (v_co.z / depth) + 0.5
                nu = min(max(nu, 0.0), 1.0)
                nv = min(max(nv, 0.0), 1.0)
                if is_optic:
                    loop[uv_layer].uv = dark_uv
                else:
                    loop[uv_layer].uv = (u1 + nu * (u2 - u1), v1 + nv * (v2 - v1))

    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    M = T @ R
    bmesh.ops.transform(bm, matrix=M, verts=new_verts)

def add_crawler_wheel_bm(bm, center, is_left):
    wx, wy, wz = center
    # 1. Main rubber tire carcass
    add_cylinder_bm(bm, 0.20, 0.20, 0.18, center, rot=(0, math.pi/2, 0), segs=16, uv_key='tread_rubber')

    # 2. 10 chunky knobby tread lugs around perimeter (breaking 3D silhouette)
    num_lugs = 10
    lug_w = 0.075
    lug_h = 0.045
    lug_d = 0.030
    for i in range(num_lugs):
        ang = i * (2.0 * math.pi / num_lugs)
        stagger_x = (wx - 0.045) if (i % 2 == 0) else (wx + 0.045)
        ly = wy + math.sin(ang) * 0.212
        lz = wz + math.cos(ang) * 0.212
        add_box_bm(bm, (lug_w, lug_h, lug_d), (stagger_x, ly, lz), rot=(ang, 0, 0), uv_key='tread_rubber')

    # 3. Recessed wheel rim & central steel hub with 6 rim bolts
    rim_x = wx + (0.095 if is_left else -0.095)
    add_cylinder_bm(bm, 0.12, 0.12, 0.025, (rim_x, wy, wz), rot=(0, math.pi/2, 0), segs=14, uv_key='crawler_body')
    add_cylinder_bm(bm, 0.055, 0.055, 0.035, (rim_x, wy, wz), rot=(0, math.pi/2, 0), segs=10, uv_key='piston_steel')
    for bi in range(6):
        bang = bi * (2.0 * math.pi / 6.0)
        bx = rim_x + (0.012 if is_left else -0.012)
        by = wy + math.sin(bang) * 0.085
        bz = wz + math.cos(bang) * 0.085
        add_cylinder_bm(bm, 0.012, 0.012, 0.015, (bx, by, bz), rot=(0, math.pi/2, 0), segs=6, uv_key='piston_steel')

def build_scrap_worker(atlas_path, out_glb):
    reset_scene()
    mat_main = create_clanker_material("Mat_ClankerMain", atlas_path)
    mat_optic = create_clanker_material("Mat_ClankerOptic", atlas_path, emission_color=(1.0, 0.7, 0.0, 1.0), emission_energy=2.0)

    bm = bmesh.new()

    # 1. Industrial Tapered Torso (Aggressive V-taper: broad 0.58m shoulders tapering to 0.36m waist)
    # Upper chest tapered box
    add_tapered_box_bm(bm, w_top=0.58, w_bot=0.46, depth=0.34, height=0.32, pos=(0, 0, 1.34), uv_key='piston_steel')
    # Tapered lower waist bay
    add_tapered_box_bm(bm, w_top=0.46, w_bot=0.36, depth=0.28, height=0.24, pos=(0, 0, 1.06), uv_key='piston_steel')
    # Hunched armored collar cowl over neck
    add_box_bm(bm, (0.50, 0.32, 0.12), (0, -0.02, 1.54), uv_key='yellow_arm')

    # Front chest plate: tapered V-plate angled forward 10°, stamped relief with 'UNIT-404 // SCRAP SORT'
    add_tapered_box_bm(bm, w_top=0.52, w_bot=0.38, depth=0.05, height=0.38, pos=(0, -0.18, 1.33), rot=(-0.17, 0, 0), uv_key='torso_front', primary_face='front')
    # Chest plate border rivets/trim
    add_box_bm(bm, (0.54, 0.03, 0.04), (0, -0.19, 1.52), rot=(-0.17, 0, 0), uv_key='yellow_arm')
    add_box_bm(bm, (0.40, 0.03, 0.04), (0, -0.17, 1.14), rot=(-0.17, 0, 0), uv_key='yellow_arm')

    # Rear plate: tapered back armor with 'ASSET OF BURNSIDE SALVAGE' + hazard stripes
    add_tapered_box_bm(bm, w_top=0.52, w_bot=0.38, depth=0.05, height=0.42, pos=(0, 0.18, 1.30), uv_key='torso_back', primary_face='back')

    # Twin heavy exhaust stacks: 0.055m diameter, 20° angled backward rake, dual mounting clamps
    for ex_side, ex_x in [("L", 0.18), ("R", -0.18)]:
        add_cylinder_bm(bm, 0.055, 0.055, 0.50, (ex_x, 0.24, 1.58), rot=(-0.35, 0, 0), segs=12, uv_key='piston_steel')
        # Dual clamp bands
        add_cylinder_bm(bm, 0.068, 0.068, 0.04, (ex_x, 0.20, 1.46), rot=(-0.35, 0, 0), segs=12, uv_key='yellow_arm')
        add_cylinder_bm(bm, 0.068, 0.068, 0.04, (ex_x, 0.26, 1.62), rot=(-0.35, 0, 0), segs=12, uv_key='yellow_arm')
    # Horizontal tie bracket connecting exhaust stacks
    add_box_bm(bm, (0.36, 0.04, 0.03), (0, 0.20, 1.46), uv_key='piston_steel')

    # 2. Sensor Head Turret (+35% scale, shifted forward +0.12m)
    # Head block: 0.36m x 0.30m x 0.26m
    add_box_bm(bm, (0.36, 0.30, 0.26), (0, -0.12, 1.64), uv_key='piston_steel')
    # Heavy extruded amber searchlight bezel (breaks silhouette)
    add_cylinder_bm(bm, 0.080, 0.068, 0.08, (-0.085, -0.29, 1.64), rot=(math.pi/2, 0, 0), segs=16, uv_key='optic_amber', is_optic=True, mat_idx=1)
    # Protective wire guard bar over amber lens
    add_cylinder_bm(bm, 0.008, 0.008, 0.18, (-0.085, -0.34, 1.64), rot=(0, math.pi/2, 0), segs=6, uv_key='piston_steel')
    # Secondary cyan optic bezel
    add_cylinder_bm(bm, 0.055, 0.045, 0.07, (0.095, -0.28, 1.64), rot=(math.pi/2, 0, 0), segs=16, uv_key='optic_cyan', is_optic=True, mat_idx=1)
    # Radio whip antenna
    add_cylinder_bm(bm, 0.012, 0.006, 0.38, (0.13, -0.04, 1.94), rot=(0.12, 0, 0), segs=8, uv_key='piston_steel')

    # 3. Asymmetrical Arms
    # LEFT ARM: Heavy Yellow Crane Repair Boom with '04' decal & articulated vise jaws
    # Pauldron
    add_box_bm(bm, (0.20, 0.24, 0.20), (0.36, 0, 1.44), uv_key='yellow_arm')
    add_box_bm(bm, (0.18, 0.22, 0.08), (0.36, 0, 1.54), uv_key='yellow_arm')
    # Yellow upper arm crane boom
    add_box_bm(bm, (0.15, 0.16, 0.30), (0.38, -0.02, 1.20), uv_key='yellow_arm')
    # Forearm with hazard stripes
    add_box_bm(bm, (0.16, 0.18, 0.34), (0.40, -0.08, 0.90), rot=(-0.25, 0, 0), uv_key='yellow_arm')
    # Articulated two-prong vise clamp jaws with teeth
    add_box_bm(bm, (0.05, 0.16, 0.15), (0.36, -0.16, 0.68), rot=(-0.45, 0, 0), uv_key='piston_steel')
    add_box_bm(bm, (0.05, 0.16, 0.15), (0.43, -0.16, 0.68), rot=(-0.45, 0, 0), uv_key='piston_steel')
    add_box_bm(bm, (0.04, 0.06, 0.08), (0.395, -0.23, 0.60), rot=(-0.20, 0, 0), uv_key='yellow_arm')

    # RIGHT ARM: Cast-Iron & Steel Hydraulic Piston Arm with Scissor Gripper
    # Cast shoulder knuckle
    add_box_bm(bm, (0.18, 0.20, 0.18), (-0.35, 0, 1.44), uv_key='piston_steel')
    # Dual hydraulic cylinders
    add_cylinder_bm(bm, 0.038, 0.038, 0.28, (-0.32, -0.02, 1.20), segs=12, uv_key='piston_steel')
    add_cylinder_bm(bm, 0.038, 0.038, 0.28, (-0.39, -0.02, 1.20), segs=12, uv_key='piston_steel')
    # Polished chrome piston rods
    add_cylinder_bm(bm, 0.022, 0.022, 0.24, (-0.32, -0.04, 1.04), segs=10, uv_key='piston_steel')
    add_cylinder_bm(bm, 0.022, 0.022, 0.24, (-0.39, -0.04, 1.04), segs=10, uv_key='piston_steel')
    # Forearm cast sleeve
    add_box_bm(bm, (0.15, 0.16, 0.32), (-0.36, -0.06, 0.90), rot=(-0.25, 0, 0), uv_key='piston_steel')
    # Scissor claw gripper jaws
    add_box_bm(bm, (0.045, 0.14, 0.14), (-0.34, -0.15, 0.68), rot=(-0.35, 0, 0), uv_key='piston_steel')
    add_box_bm(bm, (0.045, 0.14, 0.14), (-0.39, -0.15, 0.68), rot=(-0.35, 0, 0), uv_key='piston_steel')

    # 4. Pelvis & Heavy Leg Assemblies
    add_box_bm(bm, (0.36, 0.28, 0.18), (0, 0, 0.88), uv_key='piston_steel')
    # Warning plate badge
    add_box_bm(bm, (0.20, 0.04, 0.14), (0, -0.15, 0.88), uv_key='warning_plate', primary_face='front')

    for side, sx in [("L", 0.17), ("R", -0.17)]:
        # Thigh structural column + external chrome hydraulic strut
        add_box_bm(bm, (0.13, 0.15, 0.34), (sx, 0, 0.68), uv_key='piston_steel')
        add_cylinder_bm(bm, 0.026, 0.026, 0.32, (sx, 0.08, 0.68), segs=8, uv_key='piston_steel')
        # Chamfered yellow knee shield armor
        add_box_bm(bm, (0.16, 0.12, 0.16), (sx, -0.10, 0.52), rot=(0.18, 0, 0), uv_key='yellow_arm')
        # Flared lower shin column + rear stabilizer shock
        add_box_bm(bm, (0.14, 0.16, 0.36), (sx, 0, 0.30), uv_key='piston_steel')

        # Articulated industrial boot (Clear ankle cuff, steel heel block, arch cutout daylight, reinforced yellow toe cap)
        # Ankle mechanical joint cuff cylinder
        add_cylinder_bm(bm, 0.075, 0.075, 0.14, (sx, 0.0, 0.16), rot=(0, math.pi/2, 0), segs=12, uv_key='piston_steel')
        # Distinct steel heel block (0.16 wide x 0.11 long x 0.09 high)
        add_box_bm(bm, (0.16, 0.11, 0.09), (sx, 0.08, 0.06), uv_key='piston_steel')
        # Steel heel spur plate (kicker plate on rear)
        add_box_bm(bm, (0.17, 0.03, 0.08), (sx, 0.14, 0.06), uv_key='piston_steel')
        # Front sole / ball of foot block (0.16 wide x 0.11 long x 0.08 high) - leaves 0.07m open arch daylight between y=-0.035 and y=+0.025
        add_box_bm(bm, (0.16, 0.11, 0.08), (sx, -0.09, 0.055), uv_key='piston_steel')
        # Reinforced yellow toe cap (angled)
        add_box_bm(bm, (0.17, 0.10, 0.09), (sx, -0.18, 0.06), rot=(0.20, 0, 0), uv_key='yellow_arm')
        # 3D sole tread lugs under heel
        add_box_bm(bm, (0.16, 0.04, 0.025), (sx, 0.10, 0.012), uv_key='dark_metal')
        add_box_bm(bm, (0.16, 0.04, 0.025), (sx, 0.05, 0.012), uv_key='dark_metal')
        # 3D sole tread lugs under toe ball (leaving arch gap clear)
        add_box_bm(bm, (0.16, 0.04, 0.025), (sx, -0.07, 0.012), uv_key='dark_metal')
        add_box_bm(bm, (0.16, 0.04, 0.025), (sx, -0.15, 0.012), uv_key='dark_metal')

    mesh = bpy.data.meshes.new("ScrapWorker_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    worker_obj = bpy.data.objects.new("ScrapWorker_Mesh", mesh)
    bpy.context.collection.objects.link(worker_obj)
    worker_obj.data.materials.append(mat_main)
    worker_obj.data.materials.append(mat_optic)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Overhauled Scrap Worker GLB:", out_glb)


def build_utility_crawler(atlas_path, out_glb):
    reset_scene()
    mat_main = create_clanker_material("Mat_CrawlerMain", atlas_path)
    mat_optic = create_clanker_material("Mat_CrawlerOptic", atlas_path, emission_color=(0.0, 0.95, 1.0, 1.0), emission_energy=2.0)

    bm = bmesh.new()

    # 1. Main Welded Chassis & Fenders (Aggressive wide-track stance)
    # Main chassis: 0.68m wide x 0.94m long x 0.24m height
    add_box_bm(bm, (0.68, 0.94, 0.24), (0, 0, 0.28), uv_key='crawler_body', primary_face='top_and_sides')
    # Underbelly steel skid pan
    add_box_bm(bm, (0.58, 0.88, 0.08), (0, 0, 0.13), uv_key='piston_steel')
    # Front steel bull-bar bumper
    add_cylinder_bm(bm, 0.035, 0.035, 0.72, (0, -0.52, 0.22), rot=(0, math.pi/2, 0), segs=10, uv_key='piston_steel')
    add_cylinder_bm(bm, 0.025, 0.025, 0.20, (0.34, -0.46, 0.28), rot=(0.4, 0, 0), segs=8, uv_key='piston_steel')
    add_cylinder_bm(bm, 0.025, 0.025, 0.20, (-0.34, -0.46, 0.28), rot=(0.4, 0, 0), segs=8, uv_key='piston_steel')

    # Wheel arch fenders over all 4 wheels
    for wx, wy in [(0.42, -0.34), (-0.42, -0.34), (0.42, 0.34), (-0.42, 0.34)]:
        add_box_bm(bm, (0.18, 0.38, 0.06), (wx, wy, 0.40), uv_key='crawler_body')

    # 2. Four Chunky Knobby Off-Road Tires with Extruded 3D Tread Lugs
    for wx, wy in [(0.44, -0.34), (-0.44, -0.34), (0.44, 0.34), (-0.44, 0.34)]:
        is_left = wx > 0
        add_crawler_wheel_bm(bm, (wx, wy, 0.21), is_left)

    # 3. Front Heavy Motorized Winch & Extended Tow Hook
    # Winch drum
    add_cylinder_bm(bm, 0.065, 0.065, 0.28, (0, -0.56, 0.25), rot=(0, math.pi/2, 0), segs=12, uv_key='piston_steel')
    # Braided cable wrapping
    add_cylinder_bm(bm, 0.055, 0.055, 0.22, (0, -0.56, 0.25), rot=(0, math.pi/2, 0), segs=12, uv_key='piston_steel')
    # Winch motor housing
    add_box_bm(bm, (0.10, 0.14, 0.14), (0.18, -0.56, 0.25), uv_key='crawler_body')
    # Heavy forged 3D tow hook extended forward
    add_box_bm(bm, (0.06, 0.12, 0.12), (0, -0.68, 0.18), rot=(0.3, 0, 0), uv_key='crawler_body')

    # 4. Domed Cyclops Turret & Protective Tubular Roll-Cage
    # Turret base
    add_box_bm(bm, (0.38, 0.38, 0.22), (0, -0.16, 0.46), uv_key='crawler_body')
    # Massive searchlight optic bezel (extruding forward)
    add_cylinder_bm(bm, 0.130, 0.110, 0.15, (0, -0.38, 0.46), rot=(math.pi/2, 0, 0), segs=18, uv_key='optic_cyan', is_optic=True, mat_idx=1)
    # Roll-cage tubes protecting optic dome
    add_cylinder_bm(bm, 0.016, 0.016, 0.44, (-0.16, -0.28, 0.58), rot=(0.55, 0, 0), segs=8, uv_key='piston_steel')
    add_cylinder_bm(bm, 0.016, 0.016, 0.44, (0.16, -0.28, 0.58), rot=(0.55, 0, 0), segs=8, uv_key='piston_steel')
    add_cylinder_bm(bm, 0.014, 0.014, 0.32, (0, -0.40, 0.60), rot=(0, math.pi/2, 0), segs=6, uv_key='piston_steel')

    # 5. Rear Recessed Battery Core Dock with Retaining Cage
    # Battery tray
    add_box_bm(bm, (0.48, 0.42, 0.18), (0, 0.24, 0.44), uv_key='crawler_body')
    # Glowing modular battery core
    add_box_bm(bm, (0.38, 0.32, 0.16), (0, 0.24, 0.50), uv_key='battery_core', primary_face='top', mat_idx=1)
    # Cage retaining rails around battery
    for cx in (-0.21, 0.21):
        add_cylinder_bm(bm, 0.014, 0.014, 0.22, (cx, 0.06, 0.52), segs=6, uv_key='piston_steel')
        add_cylinder_bm(bm, 0.014, 0.014, 0.22, (cx, 0.42, 0.52), segs=6, uv_key='piston_steel')
        add_cylinder_bm(bm, 0.012, 0.012, 0.36, (cx, 0.24, 0.62), rot=(math.pi/2, 0, 0), segs=6, uv_key='piston_steel')

    # 6. Amber Hazard Strobe on Heavy Mast
    add_cylinder_bm(bm, 0.016, 0.016, 0.34, (0.24, 0.36, 0.58), segs=8, uv_key='piston_steel')
    add_cylinder_bm(bm, 0.055, 0.045, 0.10, (0.24, 0.36, 0.74), segs=14, uv_key='optic_amber', is_optic=True, mat_idx=1)

    mesh = bpy.data.meshes.new("UtilityCrawler_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    crawler_obj = bpy.data.objects.new("UtilityCrawler_Mesh", mesh)
    bpy.context.collection.objects.link(crawler_obj)
    crawler_obj.data.materials.append(mat_main)
    crawler_obj.data.materials.append(mat_optic)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Overhauled Utility Crawler GLB:", out_glb)


def main():
    atlas_path = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter/tex_clankers_atlas.png"
    worker_glb = "/Users/bobbyinthelobby/{art/godot/models/scrap_worker.glb"
    crawler_glb = "/Users/bobbyinthelobby/{art/godot/models/utility_crawler.glb"
    blend_path = "/Users/bobbyinthelobby/{art/models_source/clankers.blend"

    build_scrap_worker(atlas_path, worker_glb)
    build_utility_crawler(atlas_path, crawler_glb)

    os.makedirs(os.path.dirname(blend_path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print("Saved source blend:", blend_path)

if __name__ == '__main__':
    main()
