"""
scripts/blender_build_runner.py
Constructs the low-poly Near-Future Sci-Fi GTA Courier Runner protagonist (HS-7)
in Blender 4.3.2 for the Chinatown Wars 32-degree elevated camera.

Key Architectural Calibrations:
- Strict Godot coordinate convention (-Z forward, +Z rear, +Y up, -X left, +X right).
- Torso front surface is at gz = -0.140 (chest) to -0.150 (shoulders).
- Contrast orange lapels, zipper, tactical sling strap, and Cobra buckle placed proudly on chest surface (gz = -0.148 to -0.160).
- Open storm collar with front V-notch dipping to gy = 0.22, revealing throat skin daylight.
- Dark charcoal exterior collar shell (NO orange doughnut).
- Rear-left flank courier satchel (cx = -0.18, cz = +0.18, cy = -0.14) with >15cm arm clearance.
- Thick 3D curved AR smart glasses visor bar with both front and top faces for instant top-down heading readout.
- Deep forward-projecting hair fringe locks over forehead.
- Extruded left forearm cyber-comm console with bright cyan telemetry screen.
- Tactical half-finger gloves with knuckle armor plates and skin-tone fingertips.
- Physical cargo pockets on thighs, articulated knee armor plates with chevrons.
- Chunky techwear sneakers with off-white wedge midsoles and physical 3D orange saw-tooth lug treads.
- UVs mapped 1:1 to clean vector 2048x2048 atlas (tex_runner_atlas.png).
"""

import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

def g2b(v):
    # Godot: X right, Y up, -Z forward (+Z rear)
    # Blender: X right, +Y forward (-Y rear), +Z up
    return Vector((v[0], -v[2], v[1]))

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in bpy.data.collections:
        bpy.data.collections.remove(c)
    for m in bpy.data.meshes:
        bpy.data.meshes.remove(m)
    for mat in bpy.data.materials:
        bpy.data.materials.remove(mat)

def create_toon_material(name, atlas_path, fallback_color=(0.15, 0.16, 0.18, 1.0), roughness=0.55, metallic=0.1, emission_strength=0.0, is_glow=False):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    node_out = nodes.new('ShaderNodeOutputMaterial')
    node_out.location = (450, 0)
    
    node_bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    node_bsdf.location = (150, 0)
    node_bsdf.inputs['Roughness'].default_value = roughness
    node_bsdf.inputs['Metallic'].default_value = metallic
    
    if os.path.exists(atlas_path) and not is_glow:
        node_tex = nodes.new('ShaderNodeTexImage')
        node_tex.location = (-180, 0)
        img = bpy.data.images.load(atlas_path)
        node_tex.image = img
        links.new(node_tex.outputs['Color'], node_bsdf.inputs['Base Color'])
    else:
        node_bsdf.inputs['Base Color'].default_value = fallback_color
        
    if emission_strength > 0.0:
        if is_glow:
            node_bsdf.inputs['Emission Color'].default_value = (0.0, 0.92, 1.0, 1.0)
        else:
            node_bsdf.inputs['Emission Color'].default_value = fallback_color
        node_bsdf.inputs['Emission Strength'].default_value = emission_strength
        
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def setup_materials(atlas_path):
    mats = {}
    mats['Charcoal'] = create_toon_material('Mat_Charcoal', atlas_path, fallback_color=(0.12, 0.13, 0.15, 1.0), roughness=0.6, metallic=0.1)
    mats['Orange'] = create_toon_material('Mat_Orange', atlas_path, fallback_color=(1.0, 0.38, 0.0, 1.0), roughness=0.35, metallic=0.05)
    mats['Skin'] = create_toon_material('Mat_Skin', atlas_path, fallback_color=(0.85, 0.65, 0.52, 1.0), roughness=0.7, metallic=0.0)
    mats['Hair'] = create_toon_material('Mat_Hair', atlas_path, fallback_color=(0.08, 0.08, 0.09, 1.0), roughness=0.8, metallic=0.0)
    mats['Metal'] = create_toon_material('Mat_Metal', atlas_path, fallback_color=(0.55, 0.58, 0.62, 1.0), roughness=0.35, metallic=0.8)
    mats['CyanGlow'] = create_toon_material('Mat_CyanGlow', atlas_path, fallback_color=(0.0, 0.90, 1.0, 1.0), emission_strength=3.5, is_glow=True)
    mats['SneakerWhite'] = create_toon_material('Mat_SneakerWhite', atlas_path, fallback_color=(0.88, 0.88, 0.85, 1.0), roughness=0.5, metallic=0.05)
    mats['Armor'] = create_toon_material('Mat_Armor', atlas_path, fallback_color=(0.15, 0.16, 0.18, 1.0), roughness=0.4, metallic=0.3)
    return mats

# =========================================================================
# EXACT 2048x2048 VECTOR-SHARP ATLAS UV COORDINATES
# =========================================================================
UV_JACKET_BODY     = (0.020, 0.620, 0.280, 0.980) # Dark matte charcoal shell
UV_INNER_TEE       = (0.300, 0.800, 0.480, 0.980) # Compression shirt & straps
UV_CAUTION_ORG     = (0.500, 0.863, 0.680, 0.980) # Pure safety orange
UV_SKIN            = (0.700, 0.849, 0.880, 0.980) # Clean stylized GTA skin tone
UV_HAIR            = (0.020, 0.420, 0.200, 0.600) # Dark spiky hair & headset
UV_METAL           = (0.220, 0.420, 0.380, 0.600) # Steel zipper & buckle
UV_COBRA_BUCKLE    = (0.234, 0.512, 0.366, 0.580) # Cobra buckle detail
UV_PANTS_CARGO     = (0.400, 0.420, 0.680, 0.780) # Cargo joggers charcoal
UV_KNEE_ARMOR      = (0.595, 0.609, 0.661, 0.755) # Ballistic knee plate chevron
UV_SNEAKER_MIDSOLE = (0.700, 0.620, 0.980, 0.780) # Off-white wedge midsole
UV_SNEAKER_TREAD   = (0.700, 0.420, 0.980, 0.600) # Orange saw-tooth lug tread
UV_SATCHEL_FLAP    = (0.020, 0.020, 0.480, 0.400) # Flap border & straps
UV_SATCHEL_STENCIL = (0.044, 0.267, 0.456, 0.371) # COURIER // RUNNER stencil
UV_DORSAL_SPINE    = (0.500, 0.020, 0.720, 0.400) # Spine chevrons, HS-7, motto
UV_CYAN_COMM       = (0.740, 0.150, 0.980, 0.400) # Cyan telemetry screen
UV_CYAN_VISOR      = (0.740, 0.020, 0.980, 0.120) # Cyan smart glasses visor

def add_box_uv(bm, uv_layer, center_g, size_g, uv_rect, mat_index=0, smooth=False):
    cb = g2b(center_g)
    sx, sy, sz = size_g
    xform = (Matrix.Translation(cb) @
             Matrix.Scale(sx, 4, Vector((1, 0, 0))) @
             Matrix.Scale(sz, 4, Vector((0, 1, 0))) @
             Matrix.Scale(sy, 4, Vector((0, 0, 1))))
    res = bmesh.ops.create_cube(bm, size=1.0, matrix=xform)
    u1, v1, u2, v2 = uv_rect
    for vert in res['verts']:
        for face in vert.link_faces:
            face.material_index = mat_index
            face.smooth = smooth
            if uv_layer:
                for loop in face.loops:
                    vl = loop.vert.co - cb
                    n = face.normal
                    if abs(n.z) > 0.6:
                        u = u1 + (vl.x / sx + 0.5) * (u2 - u1)
                        v = v1 + (vl.y / sz + 0.5) * (v2 - v1)
                    elif abs(n.y) > 0.6:
                        u = u1 + (vl.x / sx + 0.5) * (u2 - u1)
                        v = v1 + (vl.z / sy + 0.5) * (v2 - v1)
                    else:
                        u = u1 + (vl.y / sz + 0.5) * (u2 - u1)
                        v = v1 + (vl.z / sy + 0.5) * (v2 - v1)
                    loop[uv_layer].uv = (max(0.0, min(1.0, u)), max(0.0, min(1.0, v)))
    return res

def add_cylinder_uv(bm, uv_layer, p1_g, p2_g, r, segments=8, uv_rect=(0, 0, 1, 1), mat_index=0, smooth=True):
    p1 = g2b(p1_g)
    p2 = g2b(p2_g)
    v = p2 - p1
    length = v.length
    if length < 1e-6:
        return None
    center = (p1 + p2) * 0.5
    rot = Vector((0, 0, 1)).rotation_difference(v)
    mat_rot = rot.to_matrix().to_4x4()
    mat_trans = Matrix.Translation(center)
    mat_scale = (Matrix.Scale(r, 4, Vector((1, 0, 0))) @
                 Matrix.Scale(r, 4, Vector((0, 1, 0))) @
                 Matrix.Scale(length * 0.5, 4, Vector((0, 0, 1))))
    xform = mat_trans @ mat_rot @ mat_scale
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments, radius1=1.0, radius2=1.0, depth=2.0, matrix=xform)
    u1, v1, u2, v2 = uv_rect
    for vert in res['verts']:
        for face in vert.link_faces:
            face.material_index = mat_index
            face.smooth = smooth
            if uv_layer:
                for loop in face.loops:
                    vl = loop.vert.co - center
                    u = u1 + (math.atan2(vl.y, vl.x) / (2.0 * math.pi) + 0.5) * (u2 - u1)
                    v = v1 + (vl.z / length + 0.5) * (v2 - v1)
                    loop[uv_layer].uv = (max(0.0, min(1.0, u)), max(0.0, min(1.0, v)))
    return res

# =========================================================================
# 1. HEAD, HAIR, COMM HEADSET & SMART GLASSES
# =========================================================================
def build_head(mats):
    mesh = bpy.data.meshes.new('Helmet_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    
    # Anatomical Stylized Head (Chiseled Jaw, Chin Bone Structure, Ears, Cranium)
    # Head origin is at neck pivot: Godot sits at (0, 1.48, -0.06)
    head_rings_data = [
        # (gy, gz_offset, radius_x, radius_z_front, radius_z_back, is_skin)
        (0.00, -0.020, 0.046, 0.046, 0.046, True),   # 0: Throat / neck base
        (0.04, -0.024, 0.048, 0.050, 0.048, True),   # 1: Mid neck
        (0.07, -0.038, 0.054, 0.074, 0.055, True),   # 2: Angular Chin & Jaw base
        (0.11, -0.046, 0.068, 0.086, 0.068, True),   # 3: Mouth & Mandible angle
        (0.15, -0.042, 0.074, 0.088, 0.076, True),   # 4: Cheeks & Brow
        (0.19, -0.028, 0.080, 0.082, 0.082, False),  # 5: Forehead & Hairline
        (0.22, -0.016, 0.082, 0.078, 0.086, False),  # 6: Lower crown
        (0.245, -0.006, 0.070, 0.065, 0.075, False), # 7: Top crown
    ]
    
    ring_verts = []
    for gy, gzo, rx, rzf, rzb, _is_sk in head_rings_data:
        v_list = []
        for i in range(12):
            ang = i * (2.0 * math.pi / 12.0)
            rz = rzf if math.sin(ang) >= 0.0 else rzb
            gx = math.cos(ang) * rx
            gz = gzo - math.sin(ang) * rz
            v_list.append(bm.verts.new(g2b((gx, gy, gz))))
        ring_verts.append(v_list)
        
    for r in range(len(ring_verts) - 1):
        r1 = ring_verts[r]
        r2 = ring_verts[r+1]
        is_skin = (r < 5)
        mat_idx = 2 if is_skin else 3
        uv_rect = UV_SKIN if is_skin else UV_HAIR
        for i in range(12):
            i_next = (i + 1) % 12
            f = bm.faces.new([r1[i], r1[i_next], r2[i_next], r2[i]])
            f.material_index = mat_idx
            f.smooth = True
            for loop in f.loops:
                vl = loop.vert.co
                u = uv_rect[0] + (vl.x / 0.17 + 0.5) * (uv_rect[2] - uv_rect[0])
                v = uv_rect[1] + (vl.z / 0.25) * (uv_rect[3] - uv_rect[1])
                loop[uv_layer].uv = (max(0.0, min(1.0, u)), max(0.0, min(1.0, v)))
                
    f_top = bm.faces.new(ring_verts[-1])
    f_top.material_index = 3
    f_top.smooth = True
    for loop in f_top.loops:
        loop[uv_layer].uv = ((UV_HAIR[0] + UV_HAIR[2]) * 0.5, (UV_HAIR[1] + UV_HAIR[3]) * 0.5)
        
    f_bot = bm.faces.new(reversed(ring_verts[0]))
    f_bot.material_index = 2
    f_bot.smooth = True
    for loop in f_bot.loops:
        loop[uv_layer].uv = ((UV_SKIN[0] + UV_SKIN[2]) * 0.5, UV_SKIN[1])
        
    # Distinct Modeled Ears
    for side in (-1.0, 1.0):
        ear_c = (side * 0.082, 0.135, -0.020)
        add_box_uv(bm, uv_layer, ear_c, (0.015, 0.038, 0.024), UV_SKIN, mat_index=2, smooth=True)
        
    # Dynamic Messy Anime/GTA Hair Fringe (Extruded forward past the brow!)
    fringe_data = [
        # (gx, gy, gz, sx, sy, sz)
        (0.000, 0.190, -0.135, 0.046, 0.045, 0.040),  # Central forehead fringe overhang
        (-0.044, 0.180, -0.128, 0.038, 0.040, 0.036), # Left temple fringe
        (0.044, 0.180, -0.128, 0.038, 0.040, 0.036),  # Right temple fringe
        (-0.072, 0.165, -0.100, 0.030, 0.038, 0.032), # Sideburn fringe L
        (0.072, 0.165, -0.100, 0.030, 0.038, 0.032),  # Sideburn fringe R
        (0.000, 0.258, -0.015, 0.052, 0.026, 0.058),  # Spiky crown crest
        (-0.042, 0.252, 0.015, 0.044, 0.024, 0.050),  # Crown crest L
        (0.042, 0.252, 0.015, 0.044, 0.024, 0.050),   # Crown crest R
        (0.000, 0.242, 0.058, 0.054, 0.026, 0.044),   # Rear occipital crest
    ]
    for fx, fy, fz, fsx, fsy, fsz in fringe_data:
        add_box_uv(bm, uv_layer, (fx, fy, fz), (fsx, fsy, fsz), UV_HAIR, mat_index=3, smooth=True)
        
    # Neck Comms Headset resting around base of neck
    add_cylinder_uv(bm, uv_layer, (-0.055, 0.035, -0.025), (0.055, 0.035, -0.025), 0.062, segments=12, uv_rect=UV_HAIR, mat_index=3, smooth=True)
    for s in (-1.0, 1.0):
        add_box_uv(bm, uv_layer, (s * 0.086, 0.130, -0.020), (0.018, 0.024, 0.020), UV_METAL, mat_index=4, smooth=False)
        
    # AR Smart Glasses Dark Frame (Mounted across brow)
    frame_c = (0.0, 0.162, -0.115)
    add_box_uv(bm, uv_layer, frame_c, (0.144, 0.018, 0.024), UV_HAIR, mat_index=3, smooth=False)
    for side in (-1.0, 1.0):
        temple_c = (side * 0.076, 0.160, -0.075)
        add_box_uv(bm, uv_layer, temple_c, (0.012, 0.016, 0.080), UV_HAIR, mat_index=3, smooth=False)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Helmet', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Charcoal'])
    obj.data.materials.append(mats['Orange'])
    obj.data.materials.append(mats['Skin'])
    obj.data.materials.append(mats['Hair'])
    obj.data.materials.append(mats['Metal'])
    obj.data.materials.append(mats['CyanGlow'])
    return obj

def build_visor(mats):
    # Thick Curved Wraparound Holographic Cyan AR Lens (Has top, front, and bottom faces!)
    mesh = bpy.data.meshes.new('Visor_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    
    arc_angles = [-0.44 * math.pi, -0.28 * math.pi, -0.12 * math.pi, 0.0, 0.12 * math.pi, 0.28 * math.pi, 0.44 * math.pi]
    rx_out, rz_out = 0.078, 0.110
    rx_in, rz_in = 0.072, 0.098
    
    top_out, top_in = [], []
    bot_out, bot_in = [], []
    
    for ang in arc_angles:
        gx_o = math.sin(ang) * rx_out
        gz_o = -0.042 - math.cos(ang) * rz_out
        gx_i = math.sin(ang) * rx_in
        gz_i = -0.042 - math.cos(ang) * rz_in
        
        top_out.append(bm.verts.new(g2b((gx_o, 0.174, gz_o))))
        top_in.append(bm.verts.new(g2b((gx_i, 0.174, gz_i))))
        bot_out.append(bm.verts.new(g2b((gx_o, 0.144, gz_o))))
        bot_in.append(bm.verts.new(g2b((gx_i, 0.144, gz_i))))
        
    for i in range(len(arc_angles) - 1):
        # Front face
        f_front = bm.faces.new([top_out[i], top_out[i+1], bot_out[i+1], bot_out[i]])
        f_front.material_index = 0
        f_front.smooth = False
        # Top face (VITAL for top-down 32-degree and 90-degree camera readability!)
        f_top = bm.faces.new([top_in[i], top_in[i+1], top_out[i+1], top_out[i]])
        f_top.material_index = 0
        f_top.smooth = False
        # Bottom face
        f_bot = bm.faces.new([bot_out[i], bot_out[i+1], bot_in[i+1], bot_in[i]])
        f_bot.material_index = 0
        f_bot.smooth = False
        
        for f in [f_front, f_top, f_bot]:
            for loop in f.loops:
                u_t = UV_CYAN_VISOR[0] + (i / float(len(arc_angles) - 1)) * (UV_CYAN_VISOR[2] - UV_CYAN_VISOR[0])
                loop[uv_layer].uv = (u_t, (UV_CYAN_VISOR[1] + UV_CYAN_VISOR[3]) * 0.5)
                
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Visor', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['CyanGlow'])
    return obj

# =========================================================================
# 2. TORSO, OPEN STORM COLLAR, DORSAL SPINE & SLING
# =========================================================================
def build_torso(mats):
    mesh = bpy.data.meshes.new('Torso_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    
    # Athletic Street Slouch Cross Sections (Torso leans slightly forward ~7°)
    torso_rings = [
        # (gy, gz_center, width_x, depth_z)
        (0.28, -0.035, 0.420, 0.230),  # 0: Shoulders (front = -0.150)
        (0.18, -0.030, 0.390, 0.220),  # 1: Upper chest (front = -0.140)
        (0.06, -0.022, 0.350, 0.205),  # 2: Mid torso (front = -0.125)
        (-0.06, -0.012, 0.320, 0.190), # 3: Waist (front = -0.107)
        (-0.18, 0.000, 0.300, 0.185),  # 4: Lower jacket hem (front = -0.092)
        (-0.24, 0.005, 0.280, 0.175),  # 5: Pelvis / belt line
    ]
    
    ring_verts = []
    for gy, gz_c, wx, dz in torso_rings:
        v_list = []
        for i in range(12):
            ang = i * (2.0 * math.pi / 12.0)
            gx = math.cos(ang) * (wx * 0.5)
            gz = gz_c - math.sin(ang) * (dz * 0.5)
            v_list.append(bm.verts.new(g2b((gx, gy, gz))))
        ring_verts.append(v_list)
        
    for r in range(len(ring_verts) - 1):
        r1 = ring_verts[r]
        r2 = ring_verts[r+1]
        for i in range(12):
            i_next = (i + 1) % 12
            f = bm.faces.new([r1[i], r1[i_next], r2[i_next], r2[i]])
            f.material_index = 0 # Charcoal techwear shell
            f.smooth = True
            for loop in f.loops:
                vl = loop.vert.co
                u = UV_JACKET_BODY[0] + (vl.x / 0.45 + 0.5) * (UV_JACKET_BODY[2] - UV_JACKET_BODY[0])
                v = UV_JACKET_BODY[1] + (vl.z / 0.60 + 0.5) * (UV_JACKET_BODY[3] - UV_JACKET_BODY[1])
                loop[uv_layer].uv = (max(0.0, min(1.0, u)), max(0.0, min(1.0, v)))
                
    f_top = bm.faces.new(ring_verts[0])
    f_top.material_index = 0
    f_top.smooth = True
    f_bot = bm.faces.new(reversed(ring_verts[-1]))
    f_bot.material_index = 0
    f_bot.smooth = True
    
    # OPEN STORM COLLAR (Stands up in back to gy=0.34, dips in front to gy=0.22)
    # Exterior shell is dark charcoal (UV_JACKET_BODY) - NO ORANGE DOUGHNUT!
    c_ring_base = []
    c_ring_top = []
    for i in range(10):
        ang = i * (2.0 * math.pi / 10.0)
        front_factor = max(0.0, math.sin(ang))
        cgy1 = 0.27 - front_factor * 0.05
        cgy2 = 0.34 - front_factor * 0.12 # Dips from 0.34 in rear down to 0.22 in front
        crx = 0.076 + front_factor * 0.015
        crz = 0.070
        cgz = -0.035 - math.sin(ang) * crz
        gx = math.cos(ang) * crx
        c_ring_base.append(bm.verts.new(g2b((gx, cgy1, cgz))))
        c_ring_top.append(bm.verts.new(g2b((gx, cgy2, cgz))))
        
    for i in range(10):
        i_next = (i + 1) % 10
        if math.sin(i * (2.0 * math.pi / 10.0)) > 0.8 and math.sin(i_next * (2.0 * math.pi / 10.0)) > 0.8:
            continue
        f = bm.faces.new([c_ring_base[i], c_ring_base[i_next], c_ring_top[i_next], c_ring_top[i]])
        f.material_index = 0
        f.smooth = True
        for loop in f.loops:
            loop[uv_layer].uv = ((UV_JACKET_BODY[0] + UV_JACKET_BODY[2]) * 0.5, (UV_JACKET_BODY[1] + UV_JACKET_BODY[3]) * 0.5)
            
    # Folded-Back Contrast Orange Lapels (Framing the open V-notch proudly on the chest!)
    # Placed at gz = -0.148, so they sit in front of the chest shell (-0.140)!
    for s in (-1.0, 1.0):
        lapel_c = (s * 0.070, 0.20, -0.148)
        add_box_uv(bm, uv_layer, lapel_c, (0.046, 0.115, 0.016), UV_CAUTION_ORG, mat_index=1, smooth=False)
        
    # Inner Dark Compression Undershirt & Skin Throat (Visible in open collar)
    add_box_uv(bm, uv_layer, (0.0, 0.14, -0.136), (0.088, 0.14, 0.012), UV_INNER_TEE, mat_index=0, smooth=True)
    add_box_uv(bm, uv_layer, (0.0, 0.24, -0.110), (0.068, 0.08, 0.024), UV_SKIN, mat_index=2, smooth=True) # Throat daylight!
    
    # Front Metal Zipper Track & Pull Tab (Proud of chest surface at gz = -0.146)
    add_box_uv(bm, uv_layer, (-0.010, 0.02, -0.146), (0.012, 0.30, 0.010), UV_METAL, mat_index=4, smooth=False)
    add_box_uv(bm, uv_layer, (-0.010, 0.14, -0.154), (0.010, 0.025, 0.010), UV_CAUTION_ORG, mat_index=1, smooth=False)
    
    # Dorsal Spine Chevron Plate (HS-7, Orange Downward Chevrons, Motto)
    # Extruded flat runner plate running along back spine: gz = +0.110
    spine_plate_c = (0.0, 0.03, 0.110)
    add_box_uv(bm, uv_layer, spine_plate_c, (0.056, 0.40, 0.012), UV_DORSAL_SPINE, mat_index=1, smooth=False)
    
    # Diagonal Cross-Body Tactical Webbing Sling Strap (Hugging chest contour!)
    strap_pts_g = [
        (0.14, 0.26, -0.05),
        (0.10, 0.16, -0.146),
        (0.02, 0.03, -0.134),
        (-0.06, -0.08, -0.118),
        (-0.14, -0.17, -0.04),
    ]
    for i in range(len(strap_pts_g) - 1):
        add_cylinder_uv(bm, uv_layer, strap_pts_g[i], strap_pts_g[i+1], 0.018, segments=6, uv_rect=UV_INNER_TEE, mat_index=0, smooth=False)
        
    # Extruded Physical Cobra Buckle on Chest with Release Ears (gz = -0.156)
    buckle_c = (0.060, 0.11, -0.156)
    add_box_uv(bm, uv_layer, buckle_c, (0.052, 0.038, 0.022), UV_COBRA_BUCKLE, mat_index=4, smooth=False)
    for bs in (-1.0, 1.0):
        add_box_uv(bm, uv_layer, (0.060 + bs * 0.030, 0.11, -0.156), (0.008, 0.016, 0.012), UV_CAUTION_ORG, mat_index=1, smooth=False)
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Torso', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Charcoal'])
    obj.data.materials.append(mats['Orange'])
    obj.data.materials.append(mats['Skin'])
    obj.data.materials.append(mats['Hair'])
    obj.data.materials.append(mats['Metal'])
    return obj

# =========================================================================
# 3. REAR-LEFT FLANK COURIER SATCHEL (ZERO ARM CLIPPING)
# =========================================================================
def build_satchel(mats):
    # Shifted rearward and downward: cx = -0.18, cz = +0.18, cy = -0.14
    # Completely clears swinging left arm (>15cm clearance!)
    mesh = bpy.data.meshes.new('Satchel_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    
    # Main Modular Pack Body
    pack_c = (-0.18, -0.14, 0.18)
    add_box_uv(bm, uv_layer, pack_c, (0.13, 0.24, 0.16), UV_SATCHEL_FLAP, mat_index=0, smooth=False)
    
    # Volumetric Stencil Flap (Angled along pelvic line)
    # Stencil Face mapped directly to UV_SATCHEL_STENCIL (Crisp 'COURIER // RUNNER')
    flap_c = (-0.235, -0.14, 0.18)
    add_box_uv(bm, uv_layer, flap_c, (0.016, 0.23, 0.15), UV_SATCHEL_STENCIL, mat_index=1, smooth=False)
    
    # Twin Nylon Retention Straps & Metal Buckles
    for sz_off in (-0.045, 0.045):
        strap_c = (-0.245, -0.14, 0.18 + sz_off)
        add_box_uv(bm, uv_layer, strap_c, (0.008, 0.24, 0.016), UV_CAUTION_ORG, mat_index=1, smooth=False)
        buckle_c = (-0.248, -0.06, 0.18 + sz_off)
        add_box_uv(bm, uv_layer, buckle_c, (0.010, 0.022, 0.022), UV_METAL, mat_index=4, smooth=False)
        
    # Top Grab Handle
    handle_c = (-0.18, -0.01, 0.18)
    add_box_uv(bm, uv_layer, handle_c, (0.06, 0.016, 0.014), UV_INNER_TEE, mat_index=0, smooth=False)
    
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Satchel', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Charcoal'])
    obj.data.materials.append(mats['Orange'])
    obj.data.materials.append(mats['Metal'])
    return obj

# =========================================================================
# 4. ARMS, CYBER-COMM CONSOLE & TACTICAL HALF-FINGER GLOVES
# =========================================================================
def build_arm(mats, is_left=True):
    name = 'Arm_left' if is_left else 'Arm_right'
    mesh = bpy.data.meshes.new(f'{name}_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    
    s = -1.0 if is_left else 1.0
    
    # Upper Arm (Jacket sleeve, smooth folds)
    p_sh = (s * 0.02, 0.00, 0.00)
    p_elb = (s * 0.03, -0.22, 0.01)
    add_cylinder_uv(bm, uv_layer, p_sh, p_elb, 0.052, segments=8, uv_rect=UV_JACKET_BODY, mat_index=0, smooth=True)
    
    # Forearm
    p_wri = (s * 0.04, -0.44, 0.02)
    add_cylinder_uv(bm, uv_layer, p_elb, p_wri, 0.044, segments=8, uv_rect=UV_JACKET_BODY, mat_index=0, smooth=True)
    
    if is_left:
        # EXTRUDED CYBER-COMM CONSOLE ON LEFT FOREARM
        comm_housing_c = (-0.042, -0.32, -0.040)
        add_box_uv(bm, uv_layer, comm_housing_c, (0.044, 0.095, 0.036), UV_JACKET_BODY, mat_index=0, smooth=False)
        comm_screen_c = (-0.045, -0.32, -0.058)
        add_box_uv(bm, uv_layer, comm_screen_c, (0.038, 0.082, 0.008), UV_CYAN_COMM, mat_index=5, smooth=False)
    else:
        # Right Arm Caution Orange Hazard Band
        band_c = (s * 0.035, -0.30, 0.015)
        add_box_uv(bm, uv_layer, band_c, (0.048, 0.035, 0.048), UV_CAUTION_ORG, mat_index=1, smooth=False)
        
    # Tactical Half-Finger Glove Hand
    hand_c = (s * 0.04, -0.50, 0.02)
    add_box_uv(bm, uv_layer, hand_c, (0.034, 0.075, 0.068), UV_JACKET_BODY, mat_index=0, smooth=True)
    knuckle_c = (s * 0.04, -0.50, -0.016)
    add_box_uv(bm, uv_layer, knuckle_c, (0.030, 0.026, 0.012), UV_KNEE_ARMOR, mat_index=4, smooth=False)
    
    # Segmented Exposed Skin Fingertips
    finger_c = (s * 0.04, -0.555, 0.02)
    add_box_uv(bm, uv_layer, finger_c, (0.028, 0.036, 0.060), UV_SKIN, mat_index=2, smooth=True)
    thumb_c = (s * 0.062, -0.485, -0.010)
    add_box_uv(bm, uv_layer, thumb_c, (0.018, 0.030, 0.020), UV_SKIN, mat_index=2, smooth=True)
    
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Charcoal'])
    obj.data.materials.append(mats['Orange'])
    obj.data.materials.append(mats['Skin'])
    obj.data.materials.append(mats['Hair'])
    obj.data.materials.append(mats['Metal'])
    obj.data.materials.append(mats['CyanGlow'])
    return obj

# =========================================================================
# 5. LEGS, CARGO POCKETS, KNEE ARMOR & CHUNKY SNEAKERS
# =========================================================================
def build_leg(mats, is_left=True):
    name = 'Leg_left' if is_left else 'Leg_right'
    mesh = bpy.data.meshes.new(f'{name}_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    
    s = -1.0 if is_left else 1.0
    
    # Thigh (Athletic jogger drape)
    p_hip = (0.0, 0.00, 0.00)
    p_knee = (0.0, -0.38, -0.02)
    add_cylinder_uv(bm, uv_layer, p_hip, p_knee, 0.075, segments=8, uv_rect=UV_PANTS_CARGO, mat_index=0, smooth=True)
    
    # Volumetric Extruded Cargo Pocket on outer thigh
    cargo_c = (s * 0.075, -0.18, 0.00)
    add_box_uv(bm, uv_layer, cargo_c, (0.046, 0.130, 0.095), UV_PANTS_CARGO, mat_index=0, smooth=False)
    cargo_flap_c = (s * 0.082, -0.115, 0.00)
    add_box_uv(bm, uv_layer, cargo_flap_c, (0.038, 0.022, 0.090), UV_CAUTION_ORG, mat_index=1, smooth=False)
    
    # Articulated Ballistic Knee Armor Plate
    knee_plate_c = (0.0, -0.38, -0.082)
    add_box_uv(bm, uv_layer, knee_plate_c, (0.092, 0.130, 0.032), UV_KNEE_ARMOR, mat_index=1, smooth=False)
    for sy_off in (-0.035, 0.035):
        strap_c = (0.0, -0.38 + sy_off, -0.015)
        add_box_uv(bm, uv_layer, strap_c, (0.105, 0.016, 0.095), UV_INNER_TEE, mat_index=0, smooth=False)
        
    # Calf / Shin
    p_ank = (0.0, -0.68, 0.00)
    add_cylinder_uv(bm, uv_layer, p_knee, p_ank, 0.060, segments=8, uv_rect=UV_PANTS_CARGO, mat_index=0, smooth=True)
    
    # CHUNKY TECHWEAR SNEAKER
    boot_c = (0.0, -0.73, -0.03)
    add_box_uv(bm, uv_layer, boot_c, (0.092, 0.090, 0.190), UV_JACKET_BODY, mat_index=0, smooth=False)
    cuff_c = (0.0, -0.69, -0.01)
    add_box_uv(bm, uv_layer, cuff_c, (0.096, 0.032, 0.120), UV_CAUTION_ORG, mat_index=1, smooth=False)
    
    # Sculpted Off-White Wedge Midsole
    sole_c = (0.0, -0.795, -0.03)
    add_box_uv(bm, uv_layer, sole_c, (0.106, 0.045, 0.225), UV_SNEAKER_MIDSOLE, mat_index=6, smooth=False)
    
    # Heavy-Duty 3D Saw-Tooth Orange Lug Outsole
    tread_c = (0.0, -0.825, -0.03)
    add_box_uv(bm, uv_layer, tread_c, (0.108, 0.020, 0.228), UV_SNEAKER_TREAD, mat_index=1, smooth=False)
    for lz in [-0.11, -0.06, -0.01, 0.04, 0.09]:
        lug_c = (0.0, -0.840, -0.03 + lz)
        add_box_uv(bm, uv_layer, lug_c, (0.102, 0.014, 0.028), UV_SNEAKER_TREAD, mat_index=1, smooth=False)
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Charcoal'])
    obj.data.materials.append(mats['Orange'])
    obj.data.materials.append(mats['Skin'])
    obj.data.materials.append(mats['Hair'])
    obj.data.materials.append(mats['Metal'])
    obj.data.materials.append(mats['CyanGlow'])
    obj.data.materials.append(mats['SneakerWhite'])
    return obj

# =========================================================================
# 6. CHEST TELEMETRY BADGE & CORE (FOR GODOT COMPATIBILITY)
# =========================================================================
def build_telemetry(mats):
    mesh = bpy.data.meshes.new('Telemetry_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    c = (-0.08, 0.16, -0.144)
    add_box_uv(bm, uv_layer, c, (0.042, 0.034, 0.014), UV_JACKET_BODY, mat_index=0, smooth=False)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new('Telemetry', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Charcoal'])
    return obj

def build_telemetry_core(mats):
    mesh = bpy.data.meshes.new('TelemetryCore_Mesh')
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.verify()
    c = (-0.08, 0.16, -0.152)
    add_box_uv(bm, uv_layer, c, (0.032, 0.024, 0.008), UV_CYAN_COMM, mat_index=0, smooth=False)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new('TelemetryCore', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['CyanGlow'])
    return obj

def export_component_obj(obj, filepath):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    mesh = obj.data
    uv_layer = mesh.uv_layers.active
    
    with open(filepath, 'w') as f:
        f.write(f"# Component OBJ: {obj.name}\n")
        f.write(f"o {obj.name}\n")
        for v in mesh.vertices:
            # Export in Godot coordinate system:
            # Blender (bx, by, bz) -> Godot (bx, bz, -by)
            gx = v.co.x
            gy = v.co.z
            gz = -v.co.y
            f.write(f"v {gx:.5f} {gy:.5f} {gz:.5f}\n")
        if uv_layer:
            for poly in mesh.polygons:
                for loop_idx in poly.loop_indices:
                    uv = uv_layer.data[loop_idx].uv
                    f.write(f"vt {uv.x:.5f} {uv.y:.5f}\n")
        for poly in mesh.polygons:
            for loop_idx in poly.loop_indices:
                n = mesh.loops[loop_idx].normal
                f.write(f"vn {n.x:.5f} {n.z:.5f} {-n.y:.5f}\n")
                
        loop_counter = 1
        for poly in mesh.polygons:
            f_str = []
            for _ in poly.loop_indices:
                v_idx = poly.vertices[_ - poly.loop_start] + 1
                f_str.append(f"{v_idx}/{loop_counter}/{loop_counter}")
                loop_counter += 1
            f.write(f"f {' '.join(f_str)}\n")
    print(f"Exported component OBJ: {filepath}")

def main():
    print("=== Building Low-Poly Sci-Fi GTA Runner Character (HS-7) in Blender 4.3 (Z-up) ===")
    reset_scene()
    
    atlas_path = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter/tex_runner_atlas.png"
    mats = setup_materials(atlas_path)
    
    torso = build_torso(mats)
    satchel = build_satchel(mats)
    telemetry = build_telemetry(mats)
    telemetry_core = build_telemetry_core(mats)
    head = build_head(mats)
    visor = build_visor(mats)
    arm_l = build_arm(mats, is_left=True)
    arm_r = build_arm(mats, is_left=False)
    leg_l = build_leg(mats, is_left=True)
    leg_r = build_leg(mats, is_left=False)
    
    # Export Component OBJs for modular Godot scene assembly
    out_obj_dir = "godot/models/runner"
    export_component_obj(torso, f"{out_obj_dir}/runner_torso.obj")
    export_component_obj(telemetry, f"{out_obj_dir}/runner_telemetry.obj")
    export_component_obj(telemetry_core, f"{out_obj_dir}/runner_telemetry_core.obj")
    export_component_obj(satchel, f"{out_obj_dir}/runner_satchel.obj")
    export_component_obj(head, f"{out_obj_dir}/runner_helmet.obj")
    export_component_obj(visor, f"{out_obj_dir}/runner_visor.obj")
    export_component_obj(arm_l, f"{out_obj_dir}/runner_arm_left.obj")
    export_component_obj(arm_r, f"{out_obj_dir}/runner_arm_right.obj")
    export_component_obj(leg_l, f"{out_obj_dir}/runner_leg_left.obj")
    export_component_obj(leg_r, f"{out_obj_dir}/runner_leg_right.obj")
    
    # Save master .blend file
    os.makedirs("models_source", exist_ok=True)
    out_blend = "models_source/runner.blend"
    bpy.ops.wm.save_as_mainfile(filepath=out_blend)
    print(f"Saved .blend project to: {out_blend}")
    
    # Export unified master glTF 2.0
    out_glb = "godot/models/runner.glb"
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_materials='EXPORT'
    )
    print(f"Exported clean glTF 2.0 to: {out_glb}")
    print("=== Runner Character Build Complete ===")

if __name__ == '__main__':
    main()
