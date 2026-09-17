#!/usr/bin/env python3
"""
scripts/blender_build_expansion.py
Constructs authentic, game-industry-grade 3D models for Gears District Clutter & Vehicle Fleet in Blender 4.3.2
Follows GTA / Open-World Video Game Industry Standard (docs/visual_direction/ASSET_MODELING_AND_TEXTURE_STANDARD.md):
- 4-Part Modular Pipeline:
  1. Multi-material body separation (Mat_Paint, Mat_Glass, Mat_Rubber, Mat_Steel, Mat_Trim, Mat_Strobes).
  2. Automotive panel UV unwrapping (discrete panel UV regions, zero stretching, real seam lines).
  3. Shared vehicle trim sheet (tex_vehicle_trim.png) for headlights, taillights, grilles, license plates, badges.
  4. Pure vector decal layer (tex_*_livery.png) with discrete panel mapping and ZERO baked shadows.
"""

import bpy
import bmesh
from mathutils import Vector, Euler, Matrix
import os
import math

TEXTURE_DIR = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter"
TRIM_PATH = os.path.join(TEXTURE_DIR, "tex_vehicle_trim.png")
COUPE_LIV = os.path.join(TEXTURE_DIR, "tex_coupe_livery.png")
HAULER_LIV = os.path.join(TEXTURE_DIR, "tex_hauler_livery.png")
INTERCEPTOR_LIV = os.path.join(TEXTURE_DIR, "tex_security_interceptor_livery.png")
CORRUGATED_PATH = os.path.join(TEXTURE_DIR, "tex_corrugated_fence.png")
BARREL_PATH = os.path.join(TEXTURE_DIR, "tex_scrap_barrel.png")
RUST_PATH = os.path.join(TEXTURE_DIR, "tex_corroded_panel.png")
GROUND_PATH = os.path.join(TEXTURE_DIR, "tex_ground_scrap_decal.png")

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)

def create_pbr_material(name, diffuse_color=(0.5, 0.5, 0.5, 1.0), roughness=0.5, metallic=0.0,
                        emission_color=(0,0,0,1), emission_strength=0.0, texture_path=None, alpha=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new('ShaderNodeOutputMaterial')
    node_out.location = (400, 0)

    node_bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    node_bsdf.location = (100, 0)
    node_bsdf.inputs['Base Color'].default_value = diffuse_color
    node_bsdf.inputs['Roughness'].default_value = roughness
    node_bsdf.inputs['Metallic'].default_value = metallic

    if alpha < 1.0:
        node_bsdf.inputs['Alpha'].default_value = alpha
        mat.blend_method = 'BLEND'
    else:
        node_bsdf.inputs['Alpha'].default_value = 1.0
        mat.blend_method = 'OPAQUE'

    if texture_path and os.path.exists(texture_path):
        node_tex = nodes.new('ShaderNodeTexImage')
        node_tex.location = (-250, 0)
        img = bpy.data.images.load(texture_path)
        node_tex.image = img
        links.new(node_tex.outputs['Color'], node_bsdf.inputs['Base Color'])

    if emission_strength > 0.0:
        node_bsdf.inputs['Emission Color'].default_value = emission_color
        node_bsdf.inputs['Emission Strength'].default_value = emission_strength

    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def add_marker_socket(name, pos):
    empty = bpy.data.objects.new(name, None)
    empty.empty_display_type = 'PLAIN_AXES'
    empty.empty_display_size = 0.25
    empty.location = pos
    bpy.context.scene.collection.objects.link(empty)
    return empty

def add_standard_steering_wheel(bm, center_pos, tilt_deg=-25.0, mat_idx_rim=6, mat_idx_hub=6, mat_idx_col=6):
    cx, cy, cz = center_pos
    rot_x = Matrix.Rotation(math.radians(tilt_deg), 4, 'X')
    
    # 1. Steering column tube extending down/forward
    col_depth = 0.35
    col = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=12, radius1=0.028, radius2=0.028, depth=col_depth)
    bmesh.ops.translate(bm, vec=(0.0, 0.0, -col_depth * 0.5), verts=col['verts'])
    bmesh.ops.transform(bm, matrix=rot_x, verts=col['verts'])
    bmesh.ops.translate(bm, vec=(cx, cy, cz), verts=col['verts'])
    for f in bm.faces:
        if all(v in col['verts'] for v in f.verts): f.material_index = mat_idx_col

    # 2. Standard Torus Rim: outer diameter 36cm (major radius 0.165m, minor radius 0.015m)
    r_maj = 0.165
    r_min = 0.015
    segs_c = 8
    segs_r = 16
    rim_verts = []
    for i in range(segs_r):
        phi = 2.0 * math.pi * i / segs_r
        rcx, rcy = r_maj * math.cos(phi), r_maj * math.sin(phi)
        rad_x, rad_y = math.cos(phi), math.sin(phi)
        for j in range(segs_c):
            psi = 2.0 * math.pi * j / segs_c
            vx = rcx + r_min * math.cos(psi) * rad_x
            vy = rcy + r_min * math.cos(psi) * rad_y
            vz = r_min * math.sin(psi)
            t_v = (rot_x @ Vector((vx, vz, vy))) + Vector((cx, cy, cz))
            rim_verts.append(bm.verts.new(t_v))
    bm.verts.ensure_lookup_table()
    for i in range(segs_r):
        i_next = (i + 1) % segs_r
        for j in range(segs_c):
            j_next = (j + 1) % segs_c
            f = bm.faces.new((rim_verts[i*segs_c+j], rim_verts[i_next*segs_c+j], rim_verts[i_next*segs_c+j_next], rim_verts[i*segs_c+j_next]))
            f.material_index = mat_idx_rim

    # 3. Center Hub
    hub = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=12, radius1=0.048, radius2=0.048, depth=0.025)
    bmesh.ops.rotate(bm, matrix=Matrix.Rotation(math.radians(90), 3, 'X'), verts=hub['verts'])
    bmesh.ops.transform(bm, matrix=rot_x, verts=hub['verts'])
    bmesh.ops.translate(bm, vec=(cx, cy, cz), verts=hub['verts'])
    for f in bm.faces:
        if all(v in hub['verts'] for v in f.verts): f.material_index = mat_idx_hub

    # 4. 3 Spokes: Left (-X), Right (+X), Bottom (-Z along wheel face)
    for sx, sz in [(-1.0, 0.0), (1.0, 0.0), (0.0, -1.0)]:
        sp = bmesh.ops.create_cube(bm, size=1.0)
        if sz == 0.0:
            bmesh.ops.scale(bm, vec=(0.10, 0.015, 0.025), verts=sp['verts'])
            bmesh.ops.translate(bm, vec=(sx * 0.10, 0.0, 0.0), verts=sp['verts'])
        else:
            bmesh.ops.scale(bm, vec=(0.025, 0.015, 0.10), verts=sp['verts'])
            bmesh.ops.translate(bm, vec=(0.0, 0.0, sz * 0.10), verts=sp['verts'])
        bmesh.ops.transform(bm, matrix=rot_x, verts=sp['verts'])
        bmesh.ops.translate(bm, vec=(cx, cy, cz), verts=sp['verts'])
        for f in bm.faces:
            if all(v in sp['verts'] for v in f.verts): f.material_index = mat_idx_hub


def add_box_geometry(bm, size, pos, rot=(0,0,0), uv_rect=None, mat_idx=0, flip_u=False, default_uv=(0.5, 0.5)):
    res = bmesh.ops.create_cube(bm, size=1.0)
    new_verts = res['verts']
    new_verts_set = set(new_verts)
    new_faces = [f for f in bm.faces if all(v in new_verts_set for v in f.verts)]

    uv_layer = bm.loops.layers.uv.verify()
    if uv_rect is not None:
        u1, v1, u2, v2 = uv_rect
        for face in new_faces:
            face.material_index = mat_idx
            for loop in face.loops:
                v_co = loop.vert.co
                nx = (1.0 - (v_co.x + 0.5)) if flip_u else (v_co.x + 0.5)
                ny = (v_co.y + 0.5)
                nz = (v_co.z + 0.5)
                if abs(face.normal.y) > 0.8:
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
                elif abs(face.normal.x) > 0.8:
                    loop[uv_layer].uv = (u1 + ny * (u2 - u1), v1 + nz * (v2 - v1))
                else:
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))
    else:
        for face in new_faces:
            face.material_index = mat_idx
            for loop in face.loops:
                loop[uv_layer].uv = default_uv

    S = Matrix.Scale(size[0], 4, (1, 0, 0)) @ Matrix.Scale(size[1], 4, (0, 1, 0)) @ Matrix.Scale(size[2], 4, (0, 0, 1))
    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    bmesh.ops.transform(bm, matrix=(T @ R @ S), verts=new_verts)
    return new_faces

def add_cylinder_geometry(bm, radius, height, pos, rot=(0,0,0), segs=16, uv_rect=None, mat_idx=0):
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=radius, radius2=radius, depth=height)
    new_verts = res['verts']
    new_verts_set = set(new_verts)
    new_faces = [f for f in bm.faces if all(v in new_verts_set for v in f.verts)]

    uv_layer = bm.loops.layers.uv.verify()
    if uv_rect is not None:
        u1, v1, u2, v2 = uv_rect
        for face in new_faces:
            face.material_index = mat_idx
            for loop in face.loops:
                v_co = loop.vert.co
                nx = (v_co.x / radius * 0.5 + 0.5) if radius > 0 else 0.5
                nz = (v_co.z / height + 0.5) if height > 0 else 0.5
                loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
    else:
        for face in new_faces:
            face.material_index = mat_idx
            for loop in face.loops:
                loop[uv_layer].uv = (0.5, 0.5)

    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    bmesh.ops.transform(bm, matrix=(T @ R), verts=new_verts)
    return new_faces

def add_sculpted_wheel(bm, center_pos, radius, width, is_dual=False, wheel_style="standard",
                       mat_tire_idx=1, mat_rim_idx=2, mat_hub_idx=3, mat_chassis_idx=0):
    cx, cy, cz = center_pos
    offsets = [-width * 0.58, width * 0.58] if is_dual else [0.0]
    single_width = width * 0.85 if is_dual else width

    R_tire = Euler((0, math.pi / 2, 0), 'XYZ').to_matrix().to_4x4()
    uv_layer = bm.loops.layers.uv.verify()

    # Inner wheel well tub / liner (kept on inner side of wheel so it never pokes out through outer fender)
    inner_x = cx + (-single_width * 0.55 if cx > 0 else single_width * 0.55)
    add_box_geometry(bm, (0.08, radius * 2.1, radius * 2.0), (inner_x, cy, cz + radius * 0.30),
                     mat_idx=mat_chassis_idx, default_uv=(0.5, 0.5))

    for off in offsets:
        wx = cx + off
        T_tire = Matrix.Translation(Vector((wx, cy, cz)))
        mat_tire_xform = T_tire @ R_tire

        # Outer Tire with 3D tread
        res_tire = bmesh.ops.create_cone(
            bm, cap_ends=True, cap_tris=False, segments=20,
            radius1=radius, radius2=radius, depth=single_width
        )
        bmesh.ops.transform(bm, matrix=mat_tire_xform, verts=res_tire['verts'])
        for f in [f for f in bm.faces if all(v in set(res_tire['verts']) for v in f.verts)]:
            f.material_index = mat_tire_idx
            for loop in f.loops:
                loop[uv_layer].uv = (0.5, 0.5)

        # 3D Deep-Dish Rim
        rim_r = radius * (0.64 if wheel_style == "muscle" else (0.58 if wheel_style == "pursuit" else 0.56))
        rim_w = single_width * 0.94
        rim_x = wx + (0.025 if cx > 0 else -0.025)
        T_rim = Matrix.Translation(Vector((rim_x, cy, cz)))
        res_rim = bmesh.ops.create_cone(
            bm, cap_ends=True, cap_tris=False, segments=20,
            radius1=rim_r, radius2=rim_r, depth=rim_w
        )
        bmesh.ops.transform(bm, matrix=(T_rim @ R_tire), verts=res_rim['verts'])
        for f in [f for f in bm.faces if all(v in set(res_rim['verts']) for v in f.verts)]:
            f.material_index = mat_rim_idx
            for loop in f.loops:
                loop[uv_layer].uv = (0.5, 0.5)

        # Brake Rotor & Caliper (inside rim)
        rotor_x = wx + (-single_width * 0.25 if cx > 0 else single_width * 0.25)
        T_rotor = Matrix.Translation(Vector((rotor_x, cy, cz)))
        res_rotor = bmesh.ops.create_cone(
            bm, cap_ends=True, segments=12,
            radius1=rim_r * 0.75, radius2=rim_r * 0.75, depth=0.03
        )
        bmesh.ops.transform(bm, matrix=(T_rotor @ R_tire), verts=res_rotor['verts'])
        for f in [f for f in bm.faces if all(v in set(res_rotor['verts']) for v in f.verts)]:
            f.material_index = mat_rim_idx

        # Hub / Center Cap
        if wheel_style == "pursuit":
            # Chrome Dog-Dish Hubcap on black steel rim
            cap_r = rim_r * 0.48
            cap_w = 0.075
            cap_x = wx + (single_width * 0.52 if cx > 0 else -single_width * 0.52)
            T_cap = Matrix.Translation(Vector((cap_x, cy, cz)))
            res_cap = bmesh.ops.create_cone(
                bm, cap_ends=True, segments=16,
                radius1=cap_r, radius2=cap_r * 0.82, depth=cap_w
            )
            bmesh.ops.transform(bm, matrix=(T_cap @ R_tire), verts=res_cap['verts'])
            for f in [f for f in bm.faces if all(v in set(res_cap['verts']) for v in f.verts)]:
                f.material_index = mat_hub_idx
                for loop in f.loops:
                    loop[uv_layer].uv = (0.5, 0.5)
        elif wheel_style == "muscle":
            # 5-Spoke Mag Wheel with deep dish
            hub_x = wx + (single_width * 0.46 if cx > 0 else -single_width * 0.46)
            T_hub = Matrix.Translation(Vector((hub_x, cy, cz)))
            res_hub = bmesh.ops.create_cone(
                bm, cap_ends=True, segments=12,
                radius1=rim_r * 0.28, radius2=rim_r * 0.28, depth=0.04
            )
            bmesh.ops.transform(bm, matrix=(T_hub @ R_tire), verts=res_hub['verts'])
            for f in [f for f in bm.faces if all(v in set(res_hub['verts']) for v in f.verts)]:
                f.material_index = mat_hub_idx
                for loop in f.loops:
                    loop[uv_layer].uv = (0.5, 0.5)
            for s_i in range(5):
                sang = s_i * (2.0 * math.pi / 5.0)
                smx = hub_x
                smy = cy + math.sin(sang) * (rim_r * 0.46)
                smz = cz + math.cos(sang) * (rim_r * 0.46)
                res_spoke = bmesh.ops.create_cone(
                    bm, cap_ends=True, segments=6, radius1=0.035, radius2=0.045, depth=rim_r * 0.72
                )
                R_spoke = Euler((sang, 0, math.pi / 2), 'XYZ').to_matrix().to_4x4()
                bmesh.ops.transform(bm, matrix=(Matrix.Translation(Vector((smx, smy, smz))) @ R_spoke), verts=res_spoke['verts'])
                for f in [f for f in bm.faces if all(v in set(res_spoke['verts']) for v in f.verts)]:
                    f.material_index = mat_hub_idx
                    for loop in f.loops:
                        loop[uv_layer].uv = (0.5, 0.5)
        else:
            # Heavy Dayton Cast Spoke Hub (Truck style)
            hub_x = wx + (single_width * 0.52 if cx > 0 else -single_width * 0.52)
            T_hub = Matrix.Translation(Vector((hub_x, cy, cz)))
            res_hub = bmesh.ops.create_cone(
                bm, cap_ends=True, cap_tris=False, segments=14,
                radius1=rim_r * 0.40, radius2=rim_r * 0.40, depth=0.08
            )
            bmesh.ops.transform(bm, matrix=(T_hub @ R_tire), verts=res_hub['verts'])
            for f in [f for f in bm.faces if all(v in set(res_hub['verts']) for v in f.verts)]:
                f.material_index = mat_hub_idx
                for loop in f.loops:
                    loop[uv_layer].uv = (0.5, 0.5)

# ==============================================================
# PROPS
# ==============================================================
def build_traffic_barrier(tex_path, out_glb):
    reset_scene()
    bm = bmesh.new()

    profile_xz = [
        (-0.30, 0.00), (-0.28, 0.18), (-0.18, 0.32), (-0.12, 0.70), (-0.08, 0.78),
        ( 0.08, 0.78), ( 0.12, 0.70), ( 0.18, 0.32), ( 0.28, 0.18), ( 0.30, 0.00)
    ]

    uv_layer = bm.loops.layers.uv.verify()
    rings = []
    for y in (-1.0, 1.0):
        v_ring = []
        for x, z in profile_xz:
            v_ring.append(bm.verts.new((x, y, z)))
        rings.append(v_ring)

    for i in range(len(profile_xz) - 1):
        f = bm.faces.new([rings[0][i], rings[0][i+1], rings[1][i+1], rings[1][i]])
        for loop in f.loops:
            v_co = loop.vert.co
            u = (v_co.y + 1.0) / 2.0
            v = v_co.z / 0.80
            loop[uv_layer].uv = (u, v * 0.8)

    bm.faces.new([rings[1][9], rings[1][0], rings[0][0], rings[0][9]])
    f_cap1 = bm.faces.new(rings[0])
    f_cap2 = bm.faces.new(reversed(rings[1]))
    for f_cap in (f_cap1, f_cap2):
        for loop in f_cap.loops:
            loop[uv_layer].uv = ((loop.vert.co.x + 0.30) / 0.60, loop.vert.co.z / 0.80)

    add_cylinder_geometry(bm, 0.038, 1.96, (0.0, 0.0, 0.86), rot=(math.pi/2, 0, 0), uv_rect=(0.1, 0.85, 0.9, 0.95))
    add_box_geometry(bm, (0.66, 0.20, 0.04), (0.0, -0.80, 0.02), uv_rect=(0.0, 0.0, 0.2, 0.2))
    add_box_geometry(bm, (0.66, 0.20, 0.04), (0.0,  0.80, 0.02), uv_rect=(0.0, 0.0, 0.2, 0.2))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("TrafficBarrier_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("TrafficBarrier_Mesh", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mat = create_pbr_material("Mat_TrafficBarrier", texture_path=tex_path)
    obj.data.materials.append(mat)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Sculpted Traffic Barrier GLB:", out_glb)

def build_street_vendor(tex_path, out_glb):
    reset_scene()
    bm = bmesh.new()

    add_box_geometry(bm, (2.20, 1.20, 0.95), (0.0, 0.0, 0.475), uv_rect=(0.02, 0.02, 0.98, 0.50))
    add_box_geometry(bm, (2.36, 1.36, 0.08), (0.0, 0.0, 0.99), uv_rect=(0.02, 0.50, 0.98, 0.65))

    for x in (-1.02, 1.02):
        for y in (-0.52, 0.52):
            add_cylinder_geometry(bm, 0.032, 1.45, (x, y, 1.725), uv_rect=(0.05, 0.85, 0.20, 0.95))

    add_box_geometry(bm, (2.55, 1.65, 0.12), (0.0, 0.0, 2.46), rot=(0.06, 0.0, 0.0), uv_rect=(0.02, 0.65, 0.98, 0.98))
    add_box_geometry(bm, (0.75, 0.60, 0.14), (-0.55, 0.0, 1.10), uv_rect=(0.20, 0.85, 0.50, 0.98))
    add_cylinder_geometry(bm, 0.22, 0.32, (0.55, -0.15, 1.19), uv_rect=(0.50, 0.85, 0.75, 0.98))
    add_box_geometry(bm, (0.35, 0.45, 0.28), (0.55, 0.35, 1.17), uv_rect=(0.75, 0.85, 0.98, 0.98))
    add_box_geometry(bm, (0.95, 0.04, 0.35), (0.0, -0.66, 2.15), uv_rect=(0.05, 0.70, 0.95, 0.85))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("StreetVendor_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("StreetVendor_Mesh", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mat = create_pbr_material("Mat_StreetVendor", texture_path=tex_path)
    obj.data.materials.append(mat)

    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Sculpted Street Vendor GLB:", out_glb)

def build_security_checkpoint(tex_path, out_glb):
    reset_scene()
    bm = bmesh.new()

    for x in (-1.95, 1.95):
        add_box_geometry(bm, (0.65, 0.65, 0.20), (x, 0.0, 0.10), uv_rect=(0.05, 0.05, 0.25, 0.20))
        add_box_geometry(bm, (0.42, 0.42, 3.40), (x, 0.0, 1.80), uv_rect=(0.05, 0.20, 0.25, 0.75))

    # Overhead sign beam: FLIP U so text reads forward from camera!
    add_box_geometry(bm, (4.65, 0.44, 0.52), (0.0, 0.0, 3.40), uv_rect=(0.05, 0.75, 0.95, 0.95), flip_u=True)
    add_box_geometry(bm, (3.20, 0.06, 0.75), (0.0, -0.23, 3.38), uv_rect=(0.05, 0.75, 0.95, 0.95), flip_u=True)

    add_box_geometry(bm, (0.48, 0.38, 0.28), (1.45, -0.32, 2.95), rot=(0.18, 0.0, -0.25), uv_rect=(0.25, 0.05, 0.45, 0.25))
    add_cylinder_geometry(bm, 0.10, 0.25, (1.45, -0.45, 2.90), rot=(0.18, 0.0, -0.25), uv_rect=(0.25, 0.25, 0.45, 0.45))

    add_cylinder_geometry(bm, 0.14, 0.38, (-1.45, -0.28, 2.95), rot=(math.pi/2, 0.0, 0.0), uv_rect=(0.45, 0.05, 0.65, 0.25))
    add_box_geometry(bm, (0.28, 0.28, 0.16), (0.0, -0.25, 3.75), uv_rect=(0.65, 0.05, 0.85, 0.25))

    for x in (-1.95, 1.95):
        add_box_geometry(bm, (0.85, 0.85, 0.85), (x, 0.0, 0.425), uv_rect=(0.05, 0.05, 0.40, 0.40))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("SecurityCheckpoint_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("SecurityCheckpoint_Mesh", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mat = create_pbr_material("Mat_SecurityCheckpoint", texture_path=tex_path)
    obj.data.materials.append(mat)

    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Sculpted Security Checkpoint GLB:", out_glb)

# ==============================================================
# 4. MUSCLE COUPE (V8 SCRAP CHARGER)
# ==============================================================
def build_muscle_coupe(out_glb):
    reset_scene()
    bm = bmesh.new()

    # Materials
    mat_body    = create_pbr_material("Mat_MuscleCoupe_Body", diffuse_color=(0.12, 0.11, 0.10, 1.0), roughness=0.65, metallic=0.10, texture_path=COUPE_LIV)
    mat_glass   = create_pbr_material("Mat_Coupe_Glass",  diffuse_color=(0.08, 0.10, 0.14, 1.0), roughness=0.10, metallic=0.90)
    mat_trim    = create_pbr_material("Mat_Coupe_Trim",   diffuse_color=(1.0, 1.0, 1.0, 1.0), roughness=0.40, metallic=0.50, texture_path=TRIM_PATH)
    mat_tire    = create_pbr_material("Mat_Coupe_Tire",   diffuse_color=(0.08, 0.08, 0.09, 1.0), roughness=0.85, metallic=0.0)
    mat_rim     = create_pbr_material("Mat_Coupe_Rim",    diffuse_color=(0.75, 0.78, 0.82, 1.0), roughness=0.25, metallic=0.85)
    mat_hub     = create_pbr_material("Mat_Coupe_Hub",    diffuse_color=(0.92, 0.92, 0.95, 1.0), roughness=0.18, metallic=0.95)
    mat_chassis = create_pbr_material("Mat_Coupe_Chassis",diffuse_color=(0.10, 0.11, 0.12, 1.0), roughness=0.80, metallic=0.30)
    mat_chrome  = create_pbr_material("Mat_Coupe_Chrome", diffuse_color=(0.85, 0.88, 0.92, 1.0), roughness=0.12, metallic=0.98)

    MAT_BODY, MAT_GLASS, MAT_TRIM, MAT_TIRE, MAT_RIM, MAT_HUB, MAT_CHASSIS, MAT_CHROME = range(8)

    # Discrete Panel UV Regions
    UV_DOOR_R = (0.05, 0.76, 0.95, 0.98) # Right side livery
    UV_DOOR_L = (0.05, 0.52, 0.95, 0.74) # Left side livery
    UV_HOOD   = (0.05, 0.27, 0.46, 0.48) # Hood stripes
    UV_ROOF   = (0.54, 0.27, 0.95, 0.48) # Roof 07 & stripes
    UV_TRUNK  = (0.05, 0.03, 0.46, 0.24) # Trunk stripes
    UV_CHIN   = (0.51, 0.05, 0.97, 0.19) # Chin spoiler text

    # Trim Sheet UVs
    UV_TRIM_LAMPS  = (0.010, 0.760, 0.240, 0.990) # Round Quad Lamps
    UV_TRIM_GRILLE = (0.510, 0.760, 0.990, 0.990) # Billet Grille with V8
    UV_TRIM_TAIL   = (0.010, 0.277, 0.490, 0.490) # LED Taillight Bar
    UV_TRIM_PLATE  = (0.518, 0.326, 0.742, 0.482) # SCRAP-8 Plate

    # 1. Underbody Chassis Floorpan
    add_box_geometry(bm, (1.68, 4.40, 0.12), (0.0, 0.0, 0.20), mat_idx=MAT_CHASSIS)

    # 2. Authentic Body Stations (Coke-Bottle Waistline, Flared Haunches & Real Wheel Arches)
    stations = [
        # y, hw_rocker, z_rocker, hw_belt, z_belt, hw_roof, z_roof, has_roof
        ( 2.40, 0.88, 0.22, 0.90, 0.60, 0.00, 0.60, False), # 0: Front nose edge
        ( 2.22, 0.92, 0.24, 0.93, 0.67, 0.00, 0.67, False), # 1: Grille / front fender nose
        ( 1.85, 0.93, 0.26, 0.95, 0.70, 0.00, 0.70, False), # 2: Forward hood crown
        ( 1.45, 0.96, 0.48, 0.97, 0.73, 0.00, 0.73, False), # 3: Front wheel arch apex (open arch below!)
        ( 1.05, 0.91, 0.24, 0.93, 0.75, 0.00, 0.75, False), # 4: Cowl induction / hood rear
        ( 0.68, 0.84, 0.22, 0.86, 0.76, 0.62, 0.97, True),  # 5: Windshield base — tuck inward
        ( 0.18, 0.80, 0.22, 0.82, 0.78, 0.59, 1.22, True),  # 6: A-pillar / greenhouse peak
        (-0.42, 0.80, 0.22, 0.82, 0.78, 0.56, 1.12, True),  # 7: Roofline begins drop (fastback)
        (-1.02, 0.95, 0.24, 0.97, 0.79, 0.50, 0.88, True),  # 8: Fastback steep drop / rear glass
        (-1.45, 1.04, 0.54, 1.06, 0.82, 0.44, 0.70, True),  # 9: REAR HAUNCH + roofline almost flat
        (-1.95, 0.97, 0.26, 0.99, 0.82, 0.00, 0.82, False), # 10: Trunk deck
        (-2.36, 0.90, 0.23, 0.92, 0.80, 0.00, 0.80, False), # 11: Ducktail spoiler lip
        (-2.46, 0.86, 0.20, 0.88, 0.74, 0.00, 0.74, False), # 12: Rear bumper & valence
    ]

    uv_layer = bm.loops.layers.uv.verify()
    ring_verts = []

    for y, hwr, zr, hwb, zb, hwrf, zrf, has_roof in stations:
        v_ring = []
        v_ring.append(bm.verts.new((0.0, y, zr - 0.04)))           # 0: belly center
        v_ring.append(bm.verts.new((hwr, y, zr)))                  # 1: right rocker
        v_ring.append(bm.verts.new((hwb, y, zb)))                  # 2: right beltline
        rx = hwrf if has_roof else (hwb * 0.65)
        rz = zrf if has_roof else (zb + 0.03)
        v_ring.append(bm.verts.new((rx, y, rz)))                   # 3: right roof rail
        cz = (zrf + 0.03) if has_roof else (zb + 0.05)
        v_ring.append(bm.verts.new((0.0, y, cz)))                  # 4: center roof ridge
        v_ring.append(bm.verts.new((-rx, y, rz)))                  # 5: left roof rail
        v_ring.append(bm.verts.new((-hwb, y, zb)))                 # 6: left beltline
        v_ring.append(bm.verts.new((-hwr, y, zr)))                 # 7: left rocker
        ring_verts.append(v_ring)

    for r in range(len(ring_verts) - 1):
        r1 = ring_verts[r]
        r2 = ring_verts[r+1]

        # Top deck (Roof / Windshield / Hood / Trunk)
        f_top_r = bm.faces.new([r1[3], r1[4], r2[4], r2[3]])
        f_top_l = bm.faces.new([r1[4], r1[5], r2[5], r2[4]])

        is_glass_deck = (r == 5 or r == 8)
        top_mat = MAT_GLASS if is_glass_deck else MAT_BODY

        if r <= 4:
            curr_uv_top = UV_HOOD
            u_min, v_min, u_max, v_max = curr_uv_top
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    co = loop.vert.co
                    nx = (co.x - (-0.95)) / 1.90
                    ny = (co.y - 1.05) / (2.40 - 1.05)
                    loop[uv_layer].uv = (u_min + nx * (u_max - u_min), v_min + ny * (v_max - v_min))
        elif r in (6, 7):
            curr_uv_top = UV_ROOF
            u_min, v_min, u_max, v_max = curr_uv_top
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    co = loop.vert.co
                    nx = (co.x - (-0.60)) / 1.20
                    ny = (co.y - (-0.42)) / (0.18 - (-0.42))
                    loop[uv_layer].uv = (u_min + nx * (u_max - u_min), v_min + ny * (v_max - v_min))
        elif r >= 9:
            curr_uv_top = UV_TRUNK
            u_min, v_min, u_max, v_max = curr_uv_top
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    co = loop.vert.co
                    nx = (co.x - (-0.95)) / 1.90
                    ny = (co.y - (-2.46)) / (-1.45 - (-2.46))
                    loop[uv_layer].uv = (u_min + nx * (u_max - u_min), v_min + ny * (v_max - v_min))
        else:
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    loop[uv_layer].uv = (0.5, 0.5)

        # Upper Side Windows / Greenhouse Pillars
        f_up_r = bm.faces.new([r1[2], r1[3], r2[3], r2[2]])
        f_up_l = bm.faces.new([r1[5], r1[6], r2[6], r2[5]])
        is_side_glass = (r in (5, 6, 7))
        side_glass_mat = MAT_GLASS if is_side_glass else MAT_BODY
        f_up_r.material_index = side_glass_mat
        f_up_l.material_index = side_glass_mat
        for loop in f_up_r.loops:
            loop[uv_layer].uv = (0.5, 0.5)
        for loop in f_up_l.loops:
            loop[uv_layer].uv = (0.5, 0.5)

        # Lower Body Sides (Doors & Fenders) with Discrete Livery Atlases
        f_side_r = bm.faces.new([r1[1], r1[2], r2[2], r2[1]])
        f_side_l = bm.faces.new([r1[6], r1[7], r2[7], r2[6]])
        f_side_r.material_index = MAT_BODY
        f_side_l.material_index = MAT_BODY

        u1_r, v1_r, u2_r, v2_r = UV_DOOR_R
        u1_l, v1_l, u2_l, v2_l = UV_DOOR_L
        for loop in f_side_r.loops:
            co = loop.vert.co
            ny = (co.y - (-2.46)) / (2.40 - (-2.46))
            nz = (co.z - 0.20) / (0.80 - 0.20)
            # Use ny directly (not inverted) — GLTF export flips apparent UV direction
            loop[uv_layer].uv = (u1_r + ny * (u2_r - u1_r), v1_r + nz * (v2_r - v1_r))
        for loop in f_side_l.loops:
            co = loop.vert.co
            ny = (co.y - (-2.46)) / (2.40 - (-2.46))
            nz = (co.z - 0.20) / (0.80 - 0.20)
            # Use (1-ny) — GLTF export flips apparent UV direction on left side too
            loop[uv_layer].uv = (u1_l + (1.0 - ny) * (u2_l - u1_l), v1_l + nz * (v2_l - v1_l))


        # Underbelly panels
        f_bot_r = bm.faces.new([r1[0], r1[1], r2[1], r2[0]])
        f_bot_l = bm.faces.new([r1[7], r1[0], r2[0], r2[7]])
        f_bot_r.material_index = MAT_CHASSIS
        f_bot_l.material_index = MAT_CHASSIS
        for loop in f_bot_r.loops:
            loop[uv_layer].uv = (0.5, 0.5)
        for loop in f_bot_l.loops:
            loop[uv_layer].uv = (0.5, 0.5)

    # 3. Front Fascia: Recessed Billet Grille & Quad Sealed-Beam Headlights
    add_box_geometry(bm, (1.68, 0.12, 0.36), (0.0, 2.38, 0.44), uv_rect=UV_TRIM_GRILLE, mat_idx=MAT_TRIM)
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.42, 0.10, 0.28), (sign * 0.68, 2.39, 0.44), uv_rect=UV_TRIM_LAMPS, mat_idx=MAT_TRIM)

    # 4. Front Bumper & Chin Spoiler Splitter
    add_box_geometry(bm, (1.82, 0.15, 0.12), (0.0, 2.45, 0.32), mat_idx=MAT_CHROME)
    add_box_geometry(bm, (1.88, 0.26, 0.05), (0.0, 2.50, 0.19), uv_rect=UV_CHIN, mat_idx=MAT_BODY)
    for sign in (-1.0, 1.0):
        # Chin spoiler end plates & tie rods
        add_box_geometry(bm, (0.04, 0.28, 0.14), (sign * 0.94, 2.50, 0.24), mat_idx=MAT_CHASSIS)
        add_cylinder_geometry(bm, 0.012, 0.22, (sign * 0.45, 2.46, 0.26), rot=(-0.45, 0, 0), mat_idx=MAT_CHROME)

    # 5. Hood GMC 6-71 Roots Supercharger & Dual Red Butterfly Scoops
    add_box_geometry(bm, (0.42, 0.65, 0.26), (0.0, 1.35, 0.88), mat_idx=MAT_CHROME)
    # Dual red butterfly scoops
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.082, 0.22, (sign * 0.11, 1.62, 0.96), rot=(math.pi/2, 0, 0), mat_idx=MAT_CHROME)
        add_cylinder_geometry(bm, 0.068, 0.04, (sign * 0.11, 1.72, 0.96), rot=(math.pi/2, 0, 0), mat_idx=MAT_TRIM)
    # Blower front drive pulley & belt
    add_cylinder_geometry(bm, 0.078, 0.06, (0.0, 1.70, 0.82), rot=(math.pi/2, 0, 0), mat_idx=MAT_CHROME)
    add_cylinder_geometry(bm, 0.062, 0.06, (0.0, 1.70, 0.66), rot=(math.pi/2, 0, 0), mat_idx=MAT_CHROME)
    add_box_geometry(bm, (0.05, 0.04, 0.18), (0.0, 1.70, 0.74), mat_idx=MAT_TIRE)

    # 6. Low-Poly Interior Cockpit (Dashboard, Steering Wheel, Bucket Seats)
    add_box_geometry(bm, (1.40, 0.45, 0.22), (0.0, 0.50, 0.74), mat_idx=MAT_CHASSIS)
    add_cylinder_geometry(bm, 0.15, 0.03, (-0.38, 0.35, 0.86), rot=(-0.55, 0, 0), mat_idx=MAT_CHROME)
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.44, 0.46, 0.45), (sign * 0.36, -0.05, 0.62), mat_idx=MAT_CHASSIS)
        add_box_geometry(bm, (0.22, 0.12, 0.16), (sign * 0.36, -0.05, 0.92), mat_idx=MAT_CHASSIS)

    # 7. Rear Deck Ducktail Spoiler Blade
    add_box_geometry(bm, (1.80, 0.18, 0.16), (0.0, -2.36, 0.89), rot=(-0.35, 0, 0), mat_idx=MAT_BODY)

    # 8. Rear Tail Fascia & Dual Chrome Exhausts
    add_box_geometry(bm, (1.68, 0.10, 0.24), (0.0, -2.46, 0.66), uv_rect=UV_TRIM_TAIL, mat_idx=MAT_TRIM)
    add_box_geometry(bm, (0.46, 0.04, 0.18), (0.0, -2.48, 0.66), uv_rect=UV_TRIM_PLATE, mat_idx=MAT_TRIM)
    add_box_geometry(bm, (1.82, 0.14, 0.12), (0.0, -2.48, 0.50), mat_idx=MAT_CHROME)
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.048, 0.26, (sign * 0.52, -2.52, 0.32), rot=(math.pi/2, 0, 0), mat_idx=MAT_CHROME)

    # 9. Staggered Muscle Wheels (Meatier Rear Tires, Deep-Dish Alloy Rims)
    add_sculpted_wheel(bm, (-0.84,  1.45, 0.33), 0.33, 0.26, is_dual=False, wheel_style="muscle",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_CHASSIS)
    add_sculpted_wheel(bm, ( 0.84,  1.45, 0.33), 0.33, 0.26, is_dual=False, wheel_style="muscle",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_CHASSIS)
    add_sculpted_wheel(bm, (-0.88, -1.45, 0.38), 0.38, 0.34, is_dual=False, wheel_style="muscle",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_CHASSIS)
    add_sculpted_wheel(bm, ( 0.88, -1.45, 0.38), 0.38, 0.34, is_dual=False, wheel_style="muscle",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_CHASSIS)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("MuscleCoupe_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("MuscleCoupe_Mesh", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for m in [mat_body, mat_glass, mat_trim, mat_tire, mat_rim, mat_hub, mat_chassis, mat_chrome]:
        obj.data.materials.append(m)

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported GTA-Grade Muscle Coupe GLB:", out_glb)

# ==============================================================
# SAFE RECOGNIZABLE SCRAP HELPERS
# ==============================================================
def add_flanged_i_beam(bm, length, width, height, flange_thick, pos, rot=(0,0,0), mat_idx=0):
    M = Matrix.Translation(Vector(pos)) @ Euler(rot, 'XYZ').to_matrix().to_4x4()
    created = set()
    r_top = bmesh.ops.create_cube(bm, size=1.0)
    created.update(r_top['verts'])
    bmesh.ops.scale(bm, vec=(width, length, flange_thick), verts=r_top['verts'])
    bmesh.ops.translate(bm, vec=(0, 0, height/2 - flange_thick/2), verts=r_top['verts'])
    for f in bm.faces:
        if all(v in r_top['verts'] for v in f.verts): f.material_index = mat_idx

    r_bot = bmesh.ops.create_cube(bm, size=1.0)
    created.update(r_bot['verts'])
    bmesh.ops.scale(bm, vec=(width, length, flange_thick), verts=r_bot['verts'])
    bmesh.ops.translate(bm, vec=(0, 0, -height/2 + flange_thick/2), verts=r_bot['verts'])
    for f in bm.faces:
        if all(v in r_bot['verts'] for v in f.verts): f.material_index = mat_idx

    web_h = max(height - flange_thick * 2, 0.02)
    r_web = bmesh.ops.create_cube(bm, size=1.0)
    created.update(r_web['verts'])
    bmesh.ops.scale(bm, vec=(flange_thick, length, web_h), verts=r_web['verts'])
    for f in bm.faces:
        if all(v in r_web['verts'] for v in f.verts): f.material_index = mat_idx

    bmesh.ops.transform(bm, matrix=M, verts=list(created))

def add_v8_engine_block(bm, pos, rot=(0,0,0), mat_block=0, mat_head=0, mat_pulley=0):
    M = Matrix.Translation(Vector(pos)) @ Euler(rot, 'XYZ').to_matrix().to_4x4()
    created = set()
    res_c = bmesh.ops.create_cube(bm, size=1.0)
    created.update(res_c['verts'])
    bmesh.ops.scale(bm, vec=(0.68, 1.00, 0.42), verts=res_c['verts'])
    for f in bm.faces:
        if all(v in res_c['verts'] for v in f.verts): f.material_index = mat_block

    res_l = bmesh.ops.create_cube(bm, size=1.0)
    created.update(res_l['verts'])
    bmesh.ops.scale(bm, vec=(0.36, 0.95, 0.30), verts=res_l['verts'])
    bmesh.ops.rotate(bm, matrix=Matrix.Rotation(math.radians(-45), 3, 'Y'), verts=res_l['verts'])
    bmesh.ops.translate(bm, vec=(-0.24, 0.0, 0.32), verts=res_l['verts'])
    for f in bm.faces:
        if all(v in res_l['verts'] for v in f.verts): f.material_index = mat_head

    res_r = bmesh.ops.create_cube(bm, size=1.0)
    created.update(res_r['verts'])
    bmesh.ops.scale(bm, vec=(0.36, 0.95, 0.30), verts=res_r['verts'])
    bmesh.ops.rotate(bm, matrix=Matrix.Rotation(math.radians(45), 3, 'Y'), verts=res_r['verts'])
    bmesh.ops.translate(bm, vec=(0.24, 0.0, 0.32), verts=res_r['verts'])
    for f in bm.faces:
        if all(v in res_r['verts'] for v in f.verts): f.material_index = mat_head

    res_p = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=12, radius1=0.20, radius2=0.20, depth=0.10)
    created.update(res_p['verts'])
    bmesh.ops.rotate(bm, matrix=Matrix.Rotation(math.radians(90), 3, 'X'), verts=res_p['verts'])
    bmesh.ops.translate(bm, vec=(0.0, 0.54, -0.06), verts=res_p['verts'])
    for f in bm.faces:
        if all(v in res_p['verts'] for v in f.verts): f.material_index = mat_pulley

    bmesh.ops.transform(bm, matrix=M, verts=list(created))

def add_crushed_barrel(bm, pos, rot=(0,0,0), mat_idx=0):
    M = Matrix.Translation(Vector(pos)) @ Euler(rot, 'XYZ').to_matrix().to_4x4()
    created = set()
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=14, radius1=0.34, radius2=0.34, depth=1.00)
    created.update(res['verts'])
    bmesh.ops.scale(bm, vec=(0.58, 1.0, 1.0), verts=res['verts'])
    for f in bm.faces:
        if all(v in res['verts'] for v in f.verts): f.material_index = mat_idx

    for hz in (-0.26, 0.26):
        res_h = bmesh.ops.create_cone(bm, cap_ends=False, cap_tris=False, segments=14, radius1=0.36, radius2=0.36, depth=0.06)
        created.update(res_h['verts'])
        bmesh.ops.scale(bm, vec=(0.60, 1.0, 1.0), verts=res_h['verts'])
        bmesh.ops.translate(bm, vec=(0, 0, hz), verts=res_h['verts'])
        for f in bm.faces:
            if all(v in res_h['verts'] for v in f.verts): f.material_index = mat_idx

    bmesh.ops.transform(bm, matrix=M, verts=list(created))

def add_corrugated_sheet(bm, size, pos, rot=(0,0,0), bend_angle=0.35, mat_idx=0):
    M = Matrix.Translation(Vector(pos)) @ Euler(rot, 'XYZ').to_matrix().to_4x4()
    created = set()
    res1 = bmesh.ops.create_cube(bm, size=1.0)
    created.update(res1['verts'])
    bmesh.ops.scale(bm, vec=(size[0], size[1]*0.55, 0.03), verts=res1['verts'])
    bmesh.ops.translate(bm, vec=(0, -size[1]*0.25, 0), verts=res1['verts'])
    for f in bm.faces:
        if all(v in res1['verts'] for v in f.verts): f.material_index = mat_idx

    res2 = bmesh.ops.create_cube(bm, size=1.0)
    created.update(res2['verts'])
    bmesh.ops.scale(bm, vec=(size[0], size[1]*0.50, 0.03), verts=res2['verts'])
    bmesh.ops.rotate(bm, matrix=Matrix.Rotation(bend_angle, 3, 'X'), verts=res2['verts'])
    bmesh.ops.translate(bm, vec=(0, size[1]*0.25, math.sin(bend_angle)*size[1]*0.25), verts=res2['verts'])
    for f in bm.faces:
        if all(v in res2['verts'] for v in f.verts): f.material_index = mat_idx

    bmesh.ops.transform(bm, matrix=M, verts=list(created))

def add_salvage_wheel_rim(bm, pos, rot=(0,0,0), radius=0.36, width=0.24, mat_idx=0):
    M = Matrix.Translation(Vector(pos)) @ Euler(rot, 'XYZ').to_matrix().to_4x4()
    created = set()
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=16, radius1=radius, radius2=radius, depth=width)
    created.update(res['verts'])
    bmesh.ops.scale(bm, vec=(1.0, 0.80, 1.0), verts=res['verts'])
    for f in bm.faces:
        if all(v in res['verts'] for v in f.verts): f.material_index = mat_idx

    res_h = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=8, radius1=radius*0.48, radius2=radius*0.48, depth=width*1.05)
    created.update(res_h['verts'])
    for f in bm.faces:
        if all(v in res_h['verts'] for v in f.verts): f.material_index = mat_idx

    bmesh.ops.transform(bm, matrix=M, verts=list(created))

# ==============================================================
# 5. SCRAP HAULER (BURNSIDE SCRAP HAULAGE)
# ==============================================================
def build_scrap_hauler(out_glb):
    reset_scene()
    bm = bmesh.new()

    mat_body       = create_pbr_material("Mat_ScrapHauler_Body", diffuse_color=(0.90, 0.68, 0.08, 1.0), roughness=0.55, metallic=0.10, texture_path=HAULER_LIV)
    mat_glass      = create_pbr_material("Mat_Hauler_Glass",     diffuse_color=(0.18, 0.22, 0.28, 1.0), roughness=0.06, metallic=0.10, alpha=0.32)
    mat_trim       = create_pbr_material("Mat_Hauler_Trim",      diffuse_color=(1.0, 1.0, 1.0, 1.0), roughness=0.45, metallic=0.50, texture_path=TRIM_PATH)
    mat_tire       = create_pbr_material("Mat_Hauler_Tire",      diffuse_color=(0.08, 0.08, 0.09, 1.0), roughness=0.85, metallic=0.0)
    mat_rim        = create_pbr_material("Mat_Hauler_Rim",       diffuse_color=(0.28, 0.30, 0.35, 1.0), roughness=0.35, metallic=0.85)
    mat_hub        = create_pbr_material("Mat_Hauler_Hub",       diffuse_color=(0.85, 0.55, 0.15, 1.0), roughness=0.30, metallic=0.80)
    mat_steel      = create_pbr_material("Mat_Hauler_Steel",     diffuse_color=(0.14, 0.15, 0.17, 1.0), roughness=0.70, metallic=0.50)
    mat_chrome     = create_pbr_material("Mat_Hauler_Chrome",    diffuse_color=(0.78, 0.82, 0.86, 1.0), roughness=0.18, metallic=0.95)
    mat_corrugated = create_pbr_material("Mat_Hauler_Corrugated", diffuse_color=(0.72, 0.68, 0.62, 1.0), roughness=0.85, metallic=0.35, texture_path=CORRUGATED_PATH)
    mat_barrel     = create_pbr_material("Mat_Hauler_Barrel",     diffuse_color=(0.65, 0.50, 0.18, 1.0), roughness=0.80, metallic=0.20, texture_path=BARREL_PATH)
    mat_rust       = create_pbr_material("Mat_Hauler_Rust",       diffuse_color=(0.52, 0.24, 0.10, 1.0), roughness=0.95, metallic=0.15, texture_path=RUST_PATH)
    mat_scrap_pile = create_pbr_material("Mat_Hauler_ScrapPile",   diffuse_color=(0.32, 0.30, 0.28, 1.0), roughness=0.92, metallic=0.25, texture_path=GROUND_PATH)
    mat_seat       = create_pbr_material("Mat_Hauler_Seat",      diffuse_color=(0.14, 0.14, 0.16, 1.0), roughness=0.85, metallic=0.0)
    mat_dash       = create_pbr_material("Mat_Hauler_Dash",      diffuse_color=(0.10, 0.10, 0.11, 1.0), roughness=0.75, metallic=0.10)

    (MAT_BODY, MAT_GLASS, MAT_TRIM, MAT_TIRE, MAT_RIM, MAT_HUB,
     MAT_STEEL, MAT_CHROME, MAT_CORRUGATED, MAT_BARREL, MAT_RUST, MAT_SCRAP_PILE,
     MAT_SEAT, MAT_DASH) = range(14)

    # Discrete Panel UV Regions
    UV_BED_R       = (0.05, 0.75, 0.95, 0.98) # Right bed wall livery
    UV_BED_L       = (0.05, 0.49, 0.95, 0.72) # Left bed wall livery
    UV_CAB_DOORS_L = (0.02, 0.24, 0.49, 0.46) # Left cab door "03"
    UV_CAB_DOORS_R = (0.51, 0.24, 0.98, 0.46) # Right cab door "03"
    UV_VISOR       = (0.02, 0.03, 0.49, 0.22) # Visor "BURNSIDE"
    UV_TAILGATE    = (0.51, 0.03, 0.98, 0.22) # Tailgate chevrons & placard

    UV_TRIM_TRUCK_LAMPS  = (0.010, 0.510, 0.490, 0.740) # Dual Sealed Beams
    UV_TRIM_DIAMOND_MESH = (0.510, 0.510, 0.990, 0.740) # Heavy Diamond Mesh
    UV_TRIM_PLATE_DZ03   = (0.762, 0.326, 0.986, 0.482) # DZ-03 Heavy Plate
    UV_TRIM_TAIL         = (0.010, 0.277, 0.490, 0.490) # Taillights
    UV_TRIM_MARKERS      = (0.235, 0.865, 0.265, 0.970) # Amber Marker Lights

    # 1. Heavy C-Channel Steel Chassis Rails running full length
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.24, 7.20, 0.35), (sign * 0.58, -0.40, 0.50), mat_idx=MAT_STEEL)

    # 2. Forward-Control Cab (Lower Body)
    add_box_geometry(bm, (2.34, 1.85, 0.95), (0.0, 2.05, 0.925), mat_idx=MAT_BODY, default_uv=(0.25, 0.35))
    # Cab Door Panels (Discrete L & R UV mapping so text reads forward on both sides!)
    add_box_geometry(bm, (0.04, 1.15, 0.72), (-1.18, 1.95, 0.95), uv_rect=UV_CAB_DOORS_L, mat_idx=MAT_BODY)
    add_box_geometry(bm, (0.04, 1.15, 0.72), ( 1.18, 1.95, 0.95), uv_rect=UV_CAB_DOORS_R, mat_idx=MAT_BODY)

    # Boarding ladder steps & non-slip rungs
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.16, 0.65, 0.10), (sign * 1.16, 2.05, 0.38), mat_idx=MAT_STEEL)
        add_box_geometry(bm, (0.16, 0.65, 0.10), (sign * 1.16, 2.05, 0.54), mat_idx=MAT_STEEL)
        add_cylinder_geometry(bm, 0.018, 0.75, (sign * 1.20, 2.45, 1.25), mat_idx=MAT_CHROME)

    # Front Radiator Grille & Diamond Mesh
    add_box_geometry(bm, (1.45, 0.10, 0.65), (0.0, 2.98, 1.05), uv_rect=UV_TRIM_DIAMOND_MESH, mat_idx=MAT_TRIM)
    # Dual Sealed-Beam Headlights
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.38, 0.10, 0.30), (sign * 0.88, 2.97, 1.05), uv_rect=UV_TRIM_TRUCK_LAMPS, mat_idx=MAT_TRIM)
    # Lower Heavy Steel Bumper & DZ-03 Plate
    add_box_geometry(bm, (2.38, 0.18, 0.26), (0.0, 2.99, 0.55), mat_idx=MAT_STEEL)
    add_box_geometry(bm, (0.50, 0.06, 0.22), (0.0, 3.09, 0.55), uv_rect=UV_TRIM_PLATE_DZ03, mat_idx=MAT_TRIM)

    # Heavy Tubular Steel Bullbar with Cross-Braces (tubular frame keeps diamond mesh & lights visible!)
    add_cylinder_geometry(bm, 0.045, 2.42, (0.0, 3.12, 1.40), rot=(0, math.pi/2, 0), mat_idx=MAT_STEEL)
    add_cylinder_geometry(bm, 0.045, 2.42, (0.0, 3.12, 0.92), rot=(0, math.pi/2, 0), mat_idx=MAT_STEEL)
    add_cylinder_geometry(bm, 0.045, 2.42, (0.0, 3.12, 0.48), rot=(0, math.pi/2, 0), mat_idx=MAT_STEEL)
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.048, 1.05, (sign * 1.12, 3.10, 0.95), mat_idx=MAT_STEEL)
        add_cylinder_geometry(bm, 0.048, 1.05, (sign * 0.58, 3.10, 0.95), mat_idx=MAT_STEEL)
        add_cylinder_geometry(bm, 0.035, 0.95, (sign * 0.85, 3.08, 0.95), rot=(0, 0, sign * 0.45), mat_idx=MAT_STEEL)

    # 3. Forward-Control Cab (Upper Greenhouse & Interior Pod)
    # Hollow Cab Enclosure: Roof Cap, Rear Bulkhead, Floor Deck, Pillars & Headers
    add_box_geometry(bm, (2.28, 1.72, 0.12), (0.0, 2.00, 2.76), mat_idx=MAT_BODY, default_uv=(0.25, 0.35))
    add_box_geometry(bm, (2.26, 0.12, 1.24), (0.0, 1.16, 2.08), mat_idx=MAT_BODY, default_uv=(0.25, 0.35))
    add_box_geometry(bm, (2.24, 1.66, 0.10), (0.0, 2.00, 1.42), mat_idx=MAT_STEEL)

    # Front A-Pillars & Rear B/C-Pillars
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.10, 0.12, 1.26), (sign * 1.08, 2.80, 2.08), mat_idx=MAT_BODY, default_uv=(0.25, 0.35))
        add_box_geometry(bm, (0.10, 0.12, 1.26), (sign * 1.08, 1.22, 2.08), mat_idx=MAT_BODY, default_uv=(0.25, 0.35))

    # Windshield upper/lower frame headers
    add_box_geometry(bm, (2.12, 0.10, 0.10), (0.0, 2.84, 1.48), mat_idx=MAT_STEEL)
    add_box_geometry(bm, (2.12, 0.10, 0.10), (0.0, 2.84, 2.71), mat_idx=MAT_BODY, default_uv=(0.25, 0.35))

    # Forward-Facing Panoramic Windshield (Real 3D Translucent Smoked Glass)
    add_box_geometry(bm, (2.08, 0.04, 1.16), (0.0, 2.84, 2.09), mat_idx=MAT_GLASS)

    # Side Windows (Real 3D Translucent Smoked Glass)
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.04, 1.46, 1.16), (sign * 1.12, 2.00, 2.09), mat_idx=MAT_GLASS)

    # Dual Wiper Blades
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.02, 0.02, 0.44), (sign * 0.52, 2.89, 2.05), rot=(0, 0, sign * 0.25), mat_idx=MAT_STEEL)

    # Commercial Interior Pod: Heavy Dashboard, Engine Doghouse, Dual Air-Ride Seats, Standard Steering Wheel
    # Heavy Dashboard Slab & Driver Instrument Cluster Binnacle
    add_box_geometry(bm, (2.04, 0.44, 0.34), (0.0, 2.58, 1.50), mat_idx=MAT_DASH)
    add_box_geometry(bm, (0.52, 0.28, 0.18), (-0.60, 2.52, 1.70), mat_idx=MAT_DASH)

    # Center Engine Doghouse Console & CB Dispatch Radio
    add_box_geometry(bm, (0.42, 1.10, 0.28), (0.0, 2.05, 1.44), mat_idx=MAT_DASH)
    add_box_geometry(bm, (0.28, 0.32, 0.14), (0.0, 2.30, 1.62), mat_idx=MAT_STEEL)

    # Long Angled Floor Shifter Stick & Knob
    add_cylinder_geometry(bm, 0.018, 0.45, (-0.20, 2.10, 1.66), rot=(0.35, 0, 0.20), mat_idx=MAT_CHROME)
    add_cylinder_geometry(bm, 0.035, 0.06, (-0.23, 2.22, 1.86), mat_idx=MAT_STEEL)

    # Dual Commercial Air-Ride Seats (Driver & Passenger)
    for sign in (-1.0, 1.0):
        sx = sign * 0.60
        add_box_geometry(bm, (0.48, 0.46, 0.12), (sx, 1.80, 1.48), mat_idx=MAT_STEEL) # Suspension pedestal
        add_box_geometry(bm, (0.54, 0.52, 0.12), (sx, 1.80, 1.60), mat_idx=MAT_SEAT)  # Cushion (top at Z=1.66)
        add_box_geometry(bm, (0.50, 0.14, 0.54), (sx, 1.56, 1.90), rot=(0.10, 0, 0), mat_idx=MAT_SEAT) # Backrest
        add_box_geometry(bm, (0.28, 0.10, 0.14), (sx, 1.53, 2.22), mat_idx=MAT_SEAT)  # Headrest

    # Standard Automotive Steering Wheel (36cm outer diameter, torus rim, 3 spokes, hub, 25-deg column)
    add_standard_steering_wheel(bm, (-0.60, 2.10, 2.00), tilt_deg=-25.0, mat_idx_rim=MAT_STEEL, mat_idx_hub=MAT_STEEL, mat_idx_col=MAT_STEEL)

    # West Coast Twin-Arm Side Mirrors
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.022, 0.75, (sign * 1.28, 2.65, 2.12), mat_idx=MAT_CHROME)
        add_box_geometry(bm, (0.06, 0.16, 0.42), (sign * 1.35, 2.65, 2.12), mat_idx=MAT_CHROME)

    # 4. Heavy Sun Visor ("BURNSIDE") with 5 Amber Clearance Lights (flip_u=True so text reads forward from front)
    add_box_geometry(bm, (2.30, 0.32, 0.18), (0.0, 2.92, 2.80), rot=(0.20, 0, 0), uv_rect=UV_VISOR, mat_idx=MAT_BODY, flip_u=True)
    for c_i in range(5):
        cx = -0.70 + c_i * 0.35
        add_box_geometry(bm, (0.08, 0.04, 0.04), (cx, 3.02, 2.82), uv_rect=UV_TRIM_MARKERS, mat_idx=MAT_TRIM)

    # 5. Dual Amber Emergency Roof Beacons & Chrome Trumpet Air Horns
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.12, 0.14, (sign * 0.78, 2.10, 2.89), mat_idx=MAT_TRIM)
        add_cylinder_geometry(bm, 0.045, 0.62, (sign * 0.38, 2.25, 2.88), rot=(math.pi/2, 0, 0), mat_idx=MAT_CHROME)

    # 6. High-Walled Dump Bed with Reinforced Structural Stanchions & Top Flanges
    # Right Wall with Livery
    add_box_geometry(bm, (0.12, 4.60, 1.50), ( 1.18, -1.35, 1.65), uv_rect=UV_BED_R, mat_idx=MAT_BODY)
    # Left Wall with Livery
    add_box_geometry(bm, (0.12, 4.60, 1.50), (-1.18, -1.35, 1.65), uv_rect=UV_BED_L, mat_idx=MAT_BODY)

    # Heavy Top Flange Rails along upper rim of dump bed
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.18, 4.70, 0.14), (sign * 1.20, -1.35, 2.45), mat_idx=MAT_STEEL)

    # Exterior Vertical Structural Ribs (positioned at bed ends and divider so typography is 100% unoccluded!)
    for sign in (-1.0, 1.0):
        for ry in (-3.58, -1.15, 0.85):
            add_box_geometry(bm, (0.08, 0.14, 1.50), (sign * 1.25, ry, 1.65), mat_idx=MAT_STEEL)

    # Bed floor, front bulkhead, and hydraulic ram hoist
    add_box_geometry(bm, (2.36, 4.60, 0.16), (0.0, -1.35, 0.90), mat_idx=MAT_STEEL)
    add_box_geometry(bm, (2.36, 0.14, 1.80), (0.0, 0.95, 1.75), mat_idx=MAT_STEEL)
    add_cylinder_geometry(bm, 0.085, 1.25, (0.0, 1.05, 1.50), rot=(-0.35, 0, 0), mat_idx=MAT_CHROME)

    # 7. Tailgate with Chevron Hazard Barricade & Red Banner
    add_box_geometry(bm, (2.36, 0.16, 1.50), (0.0, -3.68, 1.65), uv_rect=UV_TAILGATE, mat_idx=MAT_BODY)
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.30, 0.08, 0.18), (sign * 0.98, -3.78, 0.98), uv_rect=UV_TRIM_TAIL, mat_idx=MAT_TRIM)
    add_box_geometry(bm, (0.48, 0.06, 0.24), (0.0, -3.78, 0.98), uv_rect=UV_TRIM_PLATE_DZ03, mat_idx=MAT_TRIM)

    # 8. HIGH-POLISH GTA-GRADE RECOGNIZABLE SCRAP HEAP
    # Layer 1: Base Rubble / Gravel Mound (filling bed interior)
    add_box_geometry(bm, (2.16, 4.35, 1.10), (0.0, -1.35, 1.75), mat_idx=MAT_SCRAP_PILE)
    add_box_geometry(bm, (1.95, 2.40, 0.55), (-0.10, -0.65, 2.45), mat_idx=MAT_SCRAP_PILE)
    add_box_geometry(bm, (1.90, 2.20, 0.48), ( 0.10, -2.35, 2.40), mat_idx=MAT_SCRAP_PILE)

    # Layer 2: Recognizable Hero Silhouette Kitbash Elements
    # A. Flanged I-Beam jutting back-upward
    add_flanged_i_beam(bm, length=3.20, width=0.30, height=0.30, flange_thick=0.04,
                       pos=(0.42, -1.30, 2.95), rot=(0.28, -0.32, 0.12), mat_idx=MAT_RUST)

    # B. Second Cut I-Beam cross-member wedged in bed
    add_flanged_i_beam(bm, length=2.20, width=0.26, height=0.26, flange_thick=0.035,
                       pos=(-0.35, -2.30, 2.75), rot=(-0.20, 0.28, 0.65), mat_idx=MAT_STEEL)

    # C. Real V8 Engine Block (cylinder banks, crankcase, pulley) sitting near cab bulkhead
    add_v8_engine_block(bm, pos=(-0.45, -0.45, 2.85), rot=(0.14, 0.08, -0.25),
                        mat_block=MAT_STEEL, mat_head=MAT_RUST, mat_pulley=MAT_CHROME)

    # D. Crushed 55-Gallon Steel Barrels
    # Barrel 1: wedged upright/tilted in rear right corner
    add_crushed_barrel(bm, pos=(0.70, -3.00, 2.45), rot=(0.20, 0.28, -0.35), mat_idx=MAT_BARREL)
    # Barrel 2: horizontal squashed drum resting mid-bed
    add_crushed_barrel(bm, pos=(-0.55, -1.55, 2.65), rot=(math.pi/2 + 0.10, 0.06, 0.38), mat_idx=MAT_BARREL)

    # E. Bent Corrugated Industrial Steel Panels
    # Sheet 1: draped over the left bed wall rail at an angle
    add_corrugated_sheet(bm, size=(1.75, 1.40), pos=(-1.12, -1.80, 2.70),
                         rot=(0.12, 0.38, 0.06), bend_angle=0.45, mat_idx=MAT_CORRUGATED)
    # Sheet 2: propped across the rear load
    add_corrugated_sheet(bm, size=(1.60, 1.25), pos=(0.15, -2.75, 2.78),
                         rot=(-0.28, 0.16, -0.20), bend_angle=0.32, mat_idx=MAT_CORRUGATED)

    # F. Industrial Scrap Exhaust / Conduit Pipes
    add_cylinder_geometry(bm, radius=0.15, height=2.80, pos=(-0.28, -1.45, 2.98),
                          rot=(0.15, 0.48, 0.75), mat_idx=MAT_STEEL)
    add_cylinder_geometry(bm, radius=0.12, height=2.40, pos=(0.16, -1.90, 2.88),
                          rot=(-0.22, -0.38, 0.30), mat_idx=MAT_RUST)

    # G. Bent Salvage Wheel Rim stuck in rubble
    add_salvage_wheel_rim(bm, pos=(0.58, -2.10, 2.72), rot=(0.35, 0.16, -0.52),
                          radius=0.35, width=0.22, mat_idx=MAT_RUST)

    # 9. Twin Vertical Chrome Exhaust Stacks with Curved 45-Degree Turn-Out Tips & Heat Shields
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.075, 2.40, (sign * 1.05, 0.95, 2.15), mat_idx=MAT_CHROME)
        add_cylinder_geometry(bm, 0.075, 0.40, (sign * 1.05, 0.85, 3.35), rot=(0.75, 0, sign * 0.2), mat_idx=MAT_CHROME)
        add_cylinder_geometry(bm, 0.105, 1.50, (sign * 1.05, 0.95, 1.70), mat_idx=MAT_STEEL)

    # 10. Cylindrical Diesel Fuel Tank & Aluminum Battery Box
    add_cylinder_geometry(bm, 0.32, 1.60, (-1.05, 0.15, 0.58), rot=(math.pi/2, 0, 0), mat_idx=MAT_STEEL)
    for fty in (-0.45, 0.75):
        add_cylinder_geometry(bm, 0.33, 0.06, (-1.05, fty, 0.58), rot=(math.pi/2, 0, 0), mat_idx=MAT_CHROME)
    add_box_geometry(bm, (0.52, 1.25, 0.44), (1.05, 0.15, 0.58), mat_idx=MAT_STEEL)

    # 11. 10 Heavy Truck Wheels: Front Steer Pair + Tandem Dual Axles (8 rear tires)
    add_sculpted_wheel(bm, (-1.08,  2.05, 0.48), 0.48, 0.34, is_dual=False, wheel_style="truck",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_STEEL)
    add_sculpted_wheel(bm, ( 1.08,  2.05, 0.48), 0.48, 0.34, is_dual=False, wheel_style="truck",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_STEEL)

    for ry in (-1.65, -2.95):
        add_sculpted_wheel(bm, (-1.10, ry, 0.48), 0.48, 0.30, is_dual=True, wheel_style="truck",
                           mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_STEEL)
        add_sculpted_wheel(bm, ( 1.10, ry, 0.48), 0.48, 0.30, is_dual=True, wheel_style="truck",
                           mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_STEEL)

    # Heavy Rubber Mud Flaps
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.64, 0.04, 0.58), (sign * 1.05, -3.45, 0.48), mat_idx=MAT_TIRE)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("ScrapHauler_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("ScrapHauler_Mesh", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for m in [mat_body, mat_glass, mat_trim, mat_tire, mat_rim, mat_hub,
              mat_steel, mat_chrome, mat_corrugated, mat_barrel, mat_rust, mat_scrap_pile,
              mat_seat, mat_dash]:
        obj.data.materials.append(m)

    # Add Socket Marker Nodes (empty axes nodes for character seating and animation mounts)
    add_marker_socket("Seat_Driver", (-0.60, 1.80, 1.66))
    add_marker_socket("Seat_Passenger", (0.60, 1.80, 1.66))
    add_marker_socket("SteeringWheel_Mount", (-0.60, 2.10, 2.00))
    add_marker_socket("Door_Entry_L", (-1.60, 1.95, 0.0))
    add_marker_socket("Door_Entry_R", (1.60, 1.95, 0.0))

    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        use_selection=True,
        export_format='GLB',
        export_materials='EXPORT',
        export_texcoords=True,
        export_normals=True
    )
    print("Exported GTA-Grade Scrap Hauler GLB with Interior & Sockets:", out_glb)

# ==============================================================
# 6. SECURITY INTERCEPTOR (UNIT-09 INTERCEPTOR)
# ==============================================================
def build_security_interceptor(out_glb):
    reset_scene()
    bm = bmesh.new()

    mat_body   = create_pbr_material("Mat_SecurityInterceptor_Body", diffuse_color=(0.10, 0.11, 0.14, 1.0), roughness=0.30, metallic=0.25, texture_path=INTERCEPTOR_LIV)
    mat_glass  = create_pbr_material("Mat_Police_Glass",  diffuse_color=(0.08, 0.10, 0.14, 1.0), roughness=0.10, metallic=0.90)
    mat_trim   = create_pbr_material("Mat_Police_Trim",   diffuse_color=(1.0, 1.0, 1.0, 1.0), roughness=0.40, metallic=0.50, texture_path=TRIM_PATH)
    mat_tire   = create_pbr_material("Mat_Police_Tire",   diffuse_color=(0.08, 0.08, 0.09, 1.0), roughness=0.85, metallic=0.0)
    mat_rim    = create_pbr_material("Mat_Police_Rim",    diffuse_color=(0.18, 0.19, 0.22, 1.0), roughness=0.40, metallic=0.80)
    mat_hub    = create_pbr_material("Mat_Police_Hub",    diffuse_color=(0.88, 0.90, 0.94, 1.0), roughness=0.15, metallic=0.98)
    mat_bar    = create_pbr_material("Mat_Police_RamBar", diffuse_color=(0.10, 0.10, 0.11, 1.0), roughness=0.60, metallic=0.60)
    mat_red    = create_pbr_material("Mat_Strobe_Red",    diffuse_color=(0.95, 0.08, 0.08, 1.0), roughness=0.20,
                                     emission_color=(1.0, 0.1, 0.1, 1.0), emission_strength=5.5)
    mat_blue   = create_pbr_material("Mat_Strobe_Blue",   diffuse_color=(0.08, 0.35, 0.98, 1.0), roughness=0.20,
                                     emission_color=(0.1, 0.4, 1.0, 1.0), emission_strength=5.5)
    mat_chrome = create_pbr_material("Mat_Police_Chrome", diffuse_color=(0.82, 0.85, 0.90, 1.0), roughness=0.12, metallic=0.98)

    MAT_BODY, MAT_GLASS, MAT_TRIM, MAT_TIRE, MAT_RIM, MAT_HUB, MAT_BAR, MAT_RED, MAT_BLUE, MAT_CHROME = range(10)

    # Discrete Panel UV Regions
    UV_DOOR_R = (0.05, 0.75, 0.95, 0.98) # Right side white doors & chevrons
    UV_DOOR_L = (0.05, 0.49, 0.95, 0.72) # Left side white doors & chevrons
    UV_HOOD   = (0.05, 0.24, 0.46, 0.46) # Hood UNIT-09 wedge
    UV_ROOF   = (0.51, 0.24, 0.95, 0.46) # Roof 09 aerial marking
    UV_TRUNK  = (0.05, 0.03, 0.95, 0.21) # Trunk compliance stencil

    UV_TRIM_PURSUIT_LAMPS = (0.260, 0.760, 0.490, 0.990) # Rectangular pursuit headlights
    UV_TRIM_PURSUIT_GRILLE= (0.510, 0.760, 0.990, 0.990) # Grille
    UV_TRIM_TAIL          = (0.010, 0.277, 0.490, 0.490) # LED taillights
    UV_TRIM_PLATE_UNIT09  = (0.518, 0.141, 0.742, 0.297) # UNIT-09 Debt Plate

    # 1. Underbody Chassis Floorpan
    add_box_geometry(bm, (1.72, 4.60, 0.12), (0.0, 0.0, 0.20), mat_idx=MAT_BAR)

    # 2. 3-Box American Pursuit Sedan Stations
    stations = [
        # y, hw_rocker, z_rocker, hw_belt, z_belt, hw_roof, z_roof, has_roof
        ( 2.42, 0.90, 0.22, 0.91, 0.65, 0.00, 0.65, False), # 0: Front nose edge
        ( 2.15, 0.92, 0.24, 0.93, 0.73, 0.00, 0.73, False), # 1: Hood slope
        ( 1.80, 0.93, 0.26, 0.94, 0.75, 0.00, 0.75, False), # 2: Hood flat
        ( 1.45, 0.95, 0.48, 0.95, 0.76, 0.00, 0.76, False), # 3: Front wheel arch apex
        ( 1.05, 0.92, 0.26, 0.94, 0.76, 0.00, 0.76, False), # 4: Cowl
        ( 0.70, 0.90, 0.24, 0.92, 0.78, 0.64, 0.96, True),  # 5: Windshield base
        ( 0.25, 0.90, 0.24, 0.92, 0.78, 0.60, 1.26, True),  # 6: Front roof
        (-0.35, 0.90, 0.24, 0.92, 0.78, 0.59, 1.27, True),  # 7: Mid roof / B-pillar
        (-0.90, 0.90, 0.24, 0.92, 0.78, 0.58, 1.25, True),  # 8: Rear roof / C-pillar
        (-1.25, 0.92, 0.26, 0.93, 0.79, 0.52, 1.02, True),  # 9: Rear window
        (-1.45, 0.95, 0.48, 0.95, 0.80, 0.46, 0.84, True),  # 10: Rear wheel arch apex
        (-1.85, 0.94, 0.26, 0.94, 0.79, 0.00, 0.79, False), # 11: Trunk deck
        (-2.30, 0.91, 0.24, 0.92, 0.80, 0.00, 0.80, False), # 12: Trunk lid edge
        (-2.48, 0.88, 0.21, 0.88, 0.74, 0.00, 0.74, False), # 13: Rear bumper
    ]

    uv_layer = bm.loops.layers.uv.verify()
    ring_verts = []

    for y, hwr, zr, hwb, zb, hwrf, zrf, has_roof in stations:
        v_ring = []
        v_ring.append(bm.verts.new((0.0, y, zr - 0.04)))
        v_ring.append(bm.verts.new((hwr, y, zr)))
        v_ring.append(bm.verts.new((hwb, y, zb)))
        rx = hwrf if has_roof else (hwb * 0.65)
        rz = zrf if has_roof else (zb + 0.03)
        v_ring.append(bm.verts.new((rx, y, rz)))
        cz = (zrf + 0.03) if has_roof else (zb + 0.05)
        v_ring.append(bm.verts.new((0.0, y, cz)))
        v_ring.append(bm.verts.new((-rx, y, rz)))
        v_ring.append(bm.verts.new((-hwb, y, zb)))
        v_ring.append(bm.verts.new((-hwr, y, zr)))
        ring_verts.append(v_ring)

    for r in range(len(ring_verts) - 1):
        r1 = ring_verts[r]
        r2 = ring_verts[r+1]

        f_top_r = bm.faces.new([r1[3], r1[4], r2[4], r2[3]])
        f_top_l = bm.faces.new([r1[4], r1[5], r2[5], r2[4]])
        is_glass_deck = (r == 5 or r == 9)
        top_mat = MAT_GLASS if is_glass_deck else MAT_BODY

        if r <= 4:
            u_min, v_min, u_max, v_max = UV_HOOD
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    co = loop.vert.co
                    nx = (co.x - (-0.95)) / 1.90
                    ny = (co.y - 1.05) / (2.42 - 1.05)
                    loop[uv_layer].uv = (u_min + nx * (u_max - u_min), v_min + ny * (v_max - v_min))
        elif r in (6, 7, 8):
            u_min, v_min, u_max, v_max = UV_ROOF
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    co = loop.vert.co
                    nx = (co.x - (-0.60)) / 1.20
                    ny = (co.y - (-0.90)) / (0.25 - (-0.90))
                    loop[uv_layer].uv = (u_min + nx * (u_max - u_min), v_min + ny * (v_max - v_min))
        elif r >= 10:
            u_min, v_min, u_max, v_max = UV_TRUNK
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    co = loop.vert.co
                    nx = (co.x - (-0.95)) / 1.90
                    ny = (co.y - (-2.48)) / (-1.45 - (-2.48))
                    loop[uv_layer].uv = (u_min + nx * (u_max - u_min), v_min + ny * (v_max - v_min))
        else:
            for f in (f_top_r, f_top_l):
                f.material_index = top_mat
                for loop in f.loops:
                    loop[uv_layer].uv = (0.5, 0.5)

        # Side Windows / Pillars
        f_up_r = bm.faces.new([r1[2], r1[3], r2[3], r2[2]])
        f_up_l = bm.faces.new([r1[5], r1[6], r2[6], r2[5]])
        is_side_glass = (r in (5, 6, 7, 8))
        side_mat = MAT_GLASS if is_side_glass else MAT_BODY
        f_up_r.material_index = side_mat
        f_up_l.material_index = side_mat
        for loop in f_up_r.loops:
            loop[uv_layer].uv = (0.5, 0.5)
        for loop in f_up_l.loops:
            loop[uv_layer].uv = (0.5, 0.5)

        # Lower Body Sides (Doors & Fenders with Stark White Police Livery)
        f_side_r = bm.faces.new([r1[1], r1[2], r2[2], r2[1]])
        f_side_l = bm.faces.new([r1[6], r1[7], r2[7], r2[6]])
        f_side_r.material_index = MAT_BODY
        f_side_l.material_index = MAT_BODY

        u1_r, v1_r, u2_r, v2_r = UV_DOOR_R
        u1_l, v1_l, u2_l, v2_l = UV_DOOR_L
        for loop in f_side_r.loops:
            co = loop.vert.co
            ny = (co.y - (-2.48)) / (2.42 - (-2.48))
            nz = (co.z - 0.22) / (0.80 - 0.22)
            # ny direct (not inverted) — compensates for GLTF export UV winding reversal
            loop[uv_layer].uv = (u1_r + ny * (u2_r - u1_r), v1_r + nz * (v2_r - v1_r))
        for loop in f_side_l.loops:
            co = loop.vert.co
            ny = (co.y - (-2.48)) / (2.42 - (-2.48))
            nz = (co.z - 0.22) / (0.80 - 0.22)
            # (1-ny) — compensates for GLTF export UV winding reversal on left side
            loop[uv_layer].uv = (u1_l + (1.0 - ny) * (u2_l - u1_l), v1_l + nz * (v2_l - v1_l))


        f_bot_r = bm.faces.new([r1[0], r1[1], r2[1], r2[0]])
        f_bot_l = bm.faces.new([r1[7], r1[0], r2[0], r2[7]])
        f_bot_r.material_index = MAT_BAR
        f_bot_l.material_index = MAT_BAR
        for loop in f_bot_r.loops:
            loop[uv_layer].uv = (0.5, 0.5)
        for loop in f_bot_l.loops:
            loop[uv_layer].uv = (0.5, 0.5)

    # 3. Front Fascia: Rectangular Pursuit Headlights & Honeycomb Grille
    add_box_geometry(bm, (1.68, 0.12, 0.32), (0.0, 2.40, 0.48), uv_rect=UV_TRIM_PURSUIT_GRILLE, mat_idx=MAT_TRIM)
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.42, 0.10, 0.26), (sign * 0.68, 2.41, 0.48), uv_rect=UV_TRIM_PURSUIT_LAMPS, mat_idx=MAT_TRIM)

    # 4. Heavy Welded Pursuit Ram Push Bumper with Rubber Pads & Mini-Strobes (tubular frame!)
    add_box_geometry(bm, (1.82, 0.14, 0.14), (0.0, 2.48, 0.36), mat_idx=MAT_BAR)
    add_cylinder_geometry(bm, 0.032, 1.25, (0.0, 2.58, 0.64), rot=(0, math.pi/2, 0), mat_idx=MAT_BAR)
    add_cylinder_geometry(bm, 0.032, 1.25, (0.0, 2.58, 0.38), rot=(0, math.pi/2, 0), mat_idx=MAT_BAR)
    # Vertical rubber push pads
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.08, 0.12, 0.44), (sign * 0.38, 2.62, 0.50), mat_idx=MAT_TIRE)
    # Auxiliary mini-strobes: Red on driver side, Blue on passenger side
    add_box_geometry(bm, (0.16, 0.06, 0.08), (-0.18, 2.60, 0.58), mat_idx=MAT_RED)
    add_box_geometry(bm, (0.16, 0.06, 0.08), ( 0.18, 2.60, 0.58), mat_idx=MAT_BLUE)
    add_box_geometry(bm, (0.48, 0.04, 0.20), (0.0, 2.59, 0.38), uv_rect=UV_TRIM_PLATE_UNIT09, mat_idx=MAT_TRIM)

    # 5. Low-Poly Police Cockpit (Dashboard, MDT Terminal Screen, Steering Wheel, Seats)
    add_box_geometry(bm, (1.42, 0.45, 0.22), (0.0, 0.50, 0.74), mat_idx=MAT_BAR)
    add_box_geometry(bm, (0.24, 0.18, 0.16), (0.0, 0.45, 0.88), rot=(-0.25, 0.35, 0), mat_idx=MAT_BLUE)
    add_cylinder_geometry(bm, 0.15, 0.03, (-0.38, 0.35, 0.86), rot=(-0.55, 0, 0), mat_idx=MAT_CHROME)
    for sign in (-1.0, 1.0):
        add_box_geometry(bm, (0.44, 0.46, 0.45), (sign * 0.36, -0.05, 0.62), mat_idx=MAT_BAR)

    # 6. Driver A-Pillar Mounted Chrome Pursuit Spotlight
    add_cylinder_geometry(bm, 0.085, 0.14, (-0.88, 0.72, 0.98), rot=(0, math.pi/2, 0.45), mat_idx=MAT_CHROME)
    add_cylinder_geometry(bm, 0.072, 0.03, (-0.94, 0.75, 0.98), rot=(0, math.pi/2, 0.45), mat_idx=MAT_TRIM)

    # 7. Low-Profile Aerodynamic Emergency Lightbar (Split Red & Blue Strobes)
    add_box_geometry(bm, (1.08, 0.28, 0.04), (0.0, -0.15, 1.28), mat_idx=MAT_BAR)
    add_box_geometry(bm, (0.44, 0.24, 0.09), (-0.28, -0.15, 1.34), mat_idx=MAT_RED)
    add_box_geometry(bm, (0.44, 0.24, 0.09), ( 0.28, -0.15, 1.34), mat_idx=MAT_BLUE)
    add_box_geometry(bm, (0.16, 0.22, 0.09), ( 0.00, -0.15, 1.34), mat_idx=MAT_CHROME)

    # 8. Dual Rooftop Communication Whip Antennas
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.008, 0.55, (sign * 0.35, -0.65, 1.55), mat_idx=MAT_BAR)

    # 9. Rear Trunk Lip Spoiler & Taillight Fascia
    add_box_geometry(bm, (1.78, 0.16, 0.08), (0.0, -2.32, 0.83), rot=(-0.25, 0, 0), mat_idx=MAT_BODY)
    add_box_geometry(bm, (1.68, 0.10, 0.22), (0.0, -2.48, 0.64), uv_rect=UV_TRIM_TAIL, mat_idx=MAT_TRIM)
    add_box_geometry(bm, (0.46, 0.04, 0.18), (0.0, -2.50, 0.64), uv_rect=UV_TRIM_PLATE_UNIT09, mat_idx=MAT_TRIM)
    add_box_geometry(bm, (1.82, 0.15, 0.14), (0.0, -2.50, 0.48), mat_idx=MAT_BAR)
    for sign in (-1.0, 1.0):
        add_cylinder_geometry(bm, 0.045, 0.24, (sign * 0.55, -2.54, 0.32), rot=(math.pi/2, 0, 0), mat_idx=MAT_CHROME)

    # 10. Pursuit Steel Wheels with Chrome Dog-Dish Hubcaps
    add_sculpted_wheel(bm, (-0.84,  1.45, 0.34), 0.34, 0.26, is_dual=False, wheel_style="pursuit",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_BAR)
    add_sculpted_wheel(bm, ( 0.84,  1.45, 0.34), 0.34, 0.26, is_dual=False, wheel_style="pursuit",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_BAR)
    add_sculpted_wheel(bm, (-0.84, -1.45, 0.34), 0.34, 0.26, is_dual=False, wheel_style="pursuit",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_BAR)
    add_sculpted_wheel(bm, ( 0.84, -1.45, 0.34), 0.34, 0.26, is_dual=False, wheel_style="pursuit",
                       mat_tire_idx=MAT_TIRE, mat_rim_idx=MAT_RIM, mat_hub_idx=MAT_HUB, mat_chassis_idx=MAT_BAR)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("SecurityInterceptor_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("SecurityInterceptor_Mesh", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for m in [mat_body, mat_glass, mat_trim, mat_tire, mat_rim, mat_hub, mat_bar, mat_red, mat_blue, mat_chrome]:
        obj.data.materials.append(m)

    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported GTA-Grade Security Interceptor GLB:", out_glb)

if __name__ == "__main__":
    tex_dir = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter"
    out_dir = "/Users/bobbyinthelobby/{art/godot/models"
    blend_dir = "/Users/bobbyinthelobby/{art/models_source"
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(blend_dir, exist_ok=True)

    tex_barrier = os.path.join(tex_dir, "tex_traffic_barrier.png")
    tex_vendor  = os.path.join(tex_dir, "tex_street_vendor.png")
    tex_check   = os.path.join(tex_dir, "tex_security_checkpoint.png")

    build_traffic_barrier(tex_barrier, os.path.join(out_dir, "prop_traffic_barrier.glb"))
    build_street_vendor(tex_vendor, os.path.join(out_dir, "prop_street_vendor.glb"))
    build_security_checkpoint(tex_check, os.path.join(out_dir, "prop_security_checkpoint.glb"))

    # Build vehicles: Molded Library Coupe & Interceptor + Custom High-Polish Scrap Hauler
    import subprocess
    subprocess.run(["/Users/bobbyinthelobby/.local/bin/blender", "-b", "--python", "/Users/bobbyinthelobby/{art/scripts/blender_mold_library_vehicles.py"], check=True)
    build_scrap_hauler(os.path.join(out_dir, "scrap_hauler.glb"))

    # Save master blender file
    master_blend = os.path.join(blend_dir, "gears_expansion.blend")
    bpy.ops.wm.save_as_mainfile(filepath=master_blend)
    print("Saved Master Blender File:", master_blend)
