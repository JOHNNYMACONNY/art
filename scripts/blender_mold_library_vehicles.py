"""
blender_mold_library_vehicles.py
Builds Muscle Coupe and Security Interceptor with:
- True curved automotive bodies from Quaternius CC0 models
- Low-poly interior pods (dashboard, steering wheel, seats, shifter, police MDT computer)
- Translucent tinted windows (alpha 0.65, dark tint)
- Sockets / Empty marker nodes (Seat_Driver, Seat_Passenger, SteeringWheel_Mount, Door_Entry_L, Door_Entry_R)
- Project liveries, PBR materials, custom parts (blower, spoiler, chin splitter, bullbar, siren)
"""

import bpy, bmesh, os, math
from mathutils import Vector, Euler, Matrix

PROJ     = "/Users/bobbyinthelobby/{art"
LIB      = os.path.join(PROJ, "assets/library_meshes/quaternius")
TEX_DIR  = os.path.join(PROJ, "godot/textures/urban_clutter")
OUT_DIR  = os.path.join(PROJ, "godot/models")

COUPE_LIV   = os.path.join(TEX_DIR, "tex_coupe_livery.png")
INTER_LIV   = os.path.join(TEX_DIR, "tex_security_interceptor_livery.png")
TRIM_PATH   = os.path.join(TEX_DIR, "tex_vehicle_trim.png")

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections): bpy.data.collections.remove(c)
    for m in list(bpy.data.meshes):      bpy.data.meshes.remove(m)
    for mat in list(bpy.data.materials): bpy.data.materials.remove(mat)

def setup_pbr_mat(mat, diffuse=(1,1,1,1), roughness=0.5, metallic=0.0,
                  tex_path=None, emission=None, emission_strength=1.0, alpha=1.0):
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    out  = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    bsdf.inputs['Base Color'].default_value = diffuse
    bsdf.inputs['Roughness'].default_value  = roughness
    bsdf.inputs['Metallic'].default_value   = metallic
    if alpha < 1.0:
        bsdf.inputs['Alpha'].default_value = alpha
        mat.blend_method = 'BLEND'
    else:
        bsdf.inputs['Alpha'].default_value = 1.0
        mat.blend_method = 'OPAQUE'
    if tex_path and os.path.exists(tex_path):
        tex_node = nt.nodes.new('ShaderNodeTexImage')
        tex_node.image = bpy.data.images.load(tex_path)
        nt.links.new(tex_node.outputs['Color'], bsdf.inputs['Base Color'])
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*emission, 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

def create_pbr_mat(name, diffuse=(1,1,1,1), roughness=0.5, metallic=0.0,
                   tex_path=None, emission=None, emission_strength=1.0, alpha=1.0):
    mat = bpy.data.materials.new(name=name)
    return setup_pbr_mat(mat, diffuse, roughness, metallic, tex_path, emission, emission_strength, alpha)

def add_box(bm, size, loc, mat_idx=0):
    dx, dy, dz = size[0]/2, size[1]/2, size[2]/2
    cx, cy, cz = loc
    verts = [
        bm.verts.new((cx - dx, cy - dy, cz - dz)),
        bm.verts.new((cx + dx, cy - dy, cz - dz)),
        bm.verts.new((cx + dx, cy + dy, cz - dz)),
        bm.verts.new((cx - dx, cy + dy, cz - dz)),
        bm.verts.new((cx - dx, cy - dy, cz + dz)),
        bm.verts.new((cx + dx, cy - dy, cz + dz)),
        bm.verts.new((cx + dx, cy + dy, cz + dz)),
        bm.verts.new((cx - dx, cy + dy, cz + dz)),
    ]
    faces = [
        (0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1),
        (2, 6, 7, 3), (0, 3, 7, 4), (1, 5, 6, 2),
    ]
    for f_idx in faces:
        f = bm.faces.new([verts[i] for i in f_idx])
        f.material_index = mat_idx

def add_marker_socket(name, pos):
    empty = bpy.data.objects.new(name, None)
    empty.empty_display_type = 'PLAIN_AXES'
    empty.empty_display_size = 0.25
    empty.location = pos
    bpy.context.scene.collection.objects.link(empty)
    return empty

def add_standard_steering_wheel(bm, center_pos, tilt_deg=-25.0, mat_idx_rim=7, mat_idx_hub=7, mat_idx_col=7):
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

# =========================================================================
# 1. MOLD MUSCLE COUPE ("V8 SCRAP CHARGER")
# =========================================================================
def mold_muscle_coupe():
    reset_scene()
    sports_glb = os.path.join(LIB, "sports_car.glb")
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=sports_glb)
    all_obs = list(set(bpy.data.objects) - before)

    # Scale to ~4.85m length
    body = max([o for o in all_obs if o.type == 'MESH'],
               key=lambda o: len(o.data.vertices))
    body.name = "MuscleCoupe_Mesh"
    body.data.name = "MuscleCoupe_Mesh"
    bb = body.bound_box
    curr_len = max(v[1] for v in bb) - min(v[1] for v in bb)
    s = 4.85 / curr_len
    for ob in all_obs:
        ob.scale = (s, s, s)
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.transform_apply(scale=True)

    # Ground wheels to Z=0
    global_min_z = 999.0
    for ob in all_obs:
        if ob.type == 'MESH':
            for v in ob.bound_box:
                w_co = ob.matrix_world @ Vector(v)
                if w_co.z < global_min_z:
                    global_min_z = w_co.z
    for ob in all_obs:
        ob.location.z -= global_min_z
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.transform_apply(location=True)

    # Direct 180 rotation on vertices: make Front = +Y right away!
    for ob in all_obs:
        if ob.type == 'MESH':
            bm_rot = bmesh.new()
            bm_rot.from_mesh(ob.data)
            for v in bm_rot.verts:
                v.co.x = -v.co.x
                v.co.y = -v.co.y
            bm_rot.normal_update()
            bm_rot.to_mesh(ob.data)
            bm_rot.free()

    # Materials:
    # Slot 0: 'White' -> Dark Charcoal Paint + Livery Atlas
    # Slot 1: 'Windows' -> Translucent Tinted Smoked Glass (alpha=0.65)
    # Slot 2: 'Grey' -> Chrome / Trim
    # Slot 3: 'Headlights' -> Glowing Headlights
    # Slot 4: 'TailLights' -> Glowing Red Taillights
    setup_pbr_mat(body.data.materials[0], diffuse=(0.12, 0.11, 0.10, 1.0), roughness=0.55, metallic=0.15, tex_path=COUPE_LIV)
    setup_pbr_mat(body.data.materials[1], diffuse=(0.18, 0.22, 0.28, 1.0), roughness=0.06, metallic=0.10, alpha=0.35)
    setup_pbr_mat(body.data.materials[2], diffuse=(0.85, 0.88, 0.92, 1.0), roughness=0.20, metallic=0.88)
    setup_pbr_mat(body.data.materials[3], diffuse=(1.0, 0.95, 0.85, 1.0), roughness=0.10, emission=(1.0, 0.95, 0.85), emission_strength=5.0)
    setup_pbr_mat(body.data.materials[4], diffuse=(1.0, 0.05, 0.02, 1.0), roughness=0.10, emission=(1.0, 0.05, 0.02), emission_strength=4.0)

    # UV projection for Slot 0 (Body Panels)
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.faces.ensure_lookup_table()
    uv_layer = bm.loops.layers.uv.verify()

    min_y = min(v.co.y for v in bm.verts)
    max_y = max(v.co.y for v in bm.verts)
    min_z = min(v.co.z for v in bm.verts)
    max_z = max(v.co.z for v in bm.verts)
    len_y = max_y - min_y
    h_z   = max_z - min_z

    for f in bm.faces:
        if f.material_index == 0:
            c = f.calc_center_median()
            n = f.normal
            if abs(n.x) > 0.4:
                # Door / side panels
                if n.x > 0: # Right side
                    u1, v1, u2, v2 = (0.05, 0.76, 0.95, 0.98)
                    for l in f.loops:
                        ny = (l.vert.co.y - min_y) / len_y
                        nz = (l.vert.co.z - min_z) / h_z
                        l[uv_layer].uv = (u1 + ny * (u2 - u1), v1 + nz * (v2 - v1))
                else: # Left side
                    u1, v1, u2, v2 = (0.05, 0.52, 0.95, 0.74)
                    for l in f.loops:
                        ny = (l.vert.co.y - min_y) / len_y
                        nz = (l.vert.co.z - min_z) / h_z
                        l[uv_layer].uv = (u1 + (1.0 - ny) * (u2 - u1), v1 + nz * (v2 - v1))
            elif n.z > 0.3:
                # Top panels (Hood, Roof, Trunk)
                if c.y > 0.35: # Hood
                    u1, v1, u2, v2 = (0.05, 0.27, 0.46, 0.48)
                elif c.y < -0.55: # Trunk
                    u1, v1, u2, v2 = (0.05, 0.03, 0.46, 0.24)
                else: # Roof
                    u1, v1, u2, v2 = (0.54, 0.27, 0.95, 0.48)
                for l in f.loops:
                    nx = (l.vert.co.x + 0.94) / 1.88
                    ny = (l.vert.co.y - min_y) / len_y
                    l[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))

    # Add Custom Muscle Car Exterior Parts
    # Hood Blower (Cowl Induction) at +Y ~ 0.85
    add_box(bm, (0.42, 0.55, 0.16), (0.0, 0.85, 0.88), mat_idx=2)
    add_box(bm, (0.36, 0.10, 0.09), (0.0, 1.12, 0.92), mat_idx=0)
    # Ducktail rear spoiler at -Y ~ -2.18
    add_box(bm, (1.68, 0.22, 0.05), (0.0, -2.18, 0.88), mat_idx=0)
    add_box(bm, (0.08, 0.15, 0.12), (-0.65, -2.15, 0.80), mat_idx=2)
    add_box(bm, (0.08, 0.15, 0.12), ( 0.65, -2.15, 0.80), mat_idx=2)
    # Front chin splitter at +Y ~ 2.28
    add_box(bm, (1.82, 0.26, 0.04), (0.0, 2.28, 0.18), mat_idx=2)

    bm.to_mesh(body.data)
    bm.free()

    # Wheel Materials
    for ob in all_obs:
        if ob != body and ob.type == 'MESH':
            setup_pbr_mat(ob.data.materials[0], diffuse=(0.78, 0.80, 0.84, 1.0), roughness=0.25, metallic=0.88)
            setup_pbr_mat(ob.data.materials[1], diffuse=(0.06, 0.06, 0.07, 1.0), roughness=0.88, metallic=0.0)

    # 4. BUILD LOW-POLY INTERIOR POD DIRECTLY ON BODY MESH
    mat_int_dark  = create_pbr_mat("Mat_Coupe_IntDark", (0.08, 0.09, 0.10, 1.0), roughness=0.85)
    mat_int_seat  = create_pbr_mat("Mat_Coupe_IntSeat", (0.15, 0.15, 0.17, 1.0), roughness=0.80)
    mat_int_metal = create_pbr_mat("Mat_Coupe_IntMetal",(0.75, 0.78, 0.82, 1.0), roughness=0.20, metallic=0.90)

    body.data.materials.append(mat_int_dark)  # Slot 5
    body.data.materials.append(mat_int_seat)  # Slot 6
    body.data.materials.append(mat_int_metal) # Slot 7

    bm_int = bmesh.new()
    bm_int.from_mesh(body.data)

    # Dashboard
    r_d = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(1.34, 0.34, 0.22), verts=r_d['verts'])
    bmesh.ops.translate(bm_int, vec=(0.0, 0.58, 0.68), verts=r_d['verts'])
    for f in bm_int.faces:
        if all(v in r_d['verts'] for v in f.verts): f.material_index = 5

    # Driver Gauge Binnacle (recessed behind wheel in instrument cluster pocket)
    r_gb = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(0.30, 0.14, 0.10), verts=r_gb['verts'])
    bmesh.ops.translate(bm_int, vec=(-0.36, 0.52, 0.78), verts=r_gb['verts'])
    for f in bm_int.faces:
        if all(v in r_gb['verts'] for v in f.verts): f.material_index = 5

    # Standard Automotive Steering Wheel (36cm outer diameter, torus rim, 3 spokes, hub, 25-deg column)
    add_standard_steering_wheel(bm_int, (-0.36, 0.35, 0.79), tilt_deg=-25.0, mat_idx_rim=7, mat_idx_hub=7, mat_idx_col=7)

    # Center Console & Shifter
    r_con = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(0.22, 0.72, 0.20), verts=r_con['verts'])
    bmesh.ops.translate(bm_int, vec=(0.0, 0.12, 0.45), verts=r_con['verts'])
    for f in bm_int.faces:
        if all(v in r_con['verts'] for v in f.verts): f.material_index = 5

    r_shf = bmesh.ops.create_cone(bm_int, cap_ends=True, cap_tris=False, segments=8, radius1=0.025, radius2=0.015, depth=0.12)
    bmesh.ops.translate(bm_int, vec=(0.0, 0.20, 0.60), verts=r_shf['verts'])
    for f in bm_int.faces:
        if all(v in r_shf['verts'] for v in f.verts): f.material_index = 7

    # Dual Bucket Seats
    for sx in (-0.36, 0.36):
        r_cush = bmesh.ops.create_cube(bm_int, size=1.0)
        bmesh.ops.scale(bm_int, vec=(0.42, 0.44, 0.12), verts=r_cush['verts'])
        bmesh.ops.translate(bm_int, vec=(sx, 0.05, 0.42), verts=r_cush['verts'])
        for f in bm_int.faces:
            if all(v in r_cush['verts'] for v in f.verts): f.material_index = 6

        r_back = bmesh.ops.create_cube(bm_int, size=1.0)
        bmesh.ops.scale(bm_int, vec=(0.40, 0.12, 0.50), verts=r_back['verts'])
        bmesh.ops.rotate(bm_int, matrix=Matrix.Rotation(math.radians(-15), 3, 'X'), verts=r_back['verts'])
        bmesh.ops.translate(bm_int, vec=(sx, -0.16, 0.68), verts=r_back['verts'])
        for f in bm_int.faces:
            if all(v in r_back['verts'] for v in f.verts): f.material_index = 6

        r_head = bmesh.ops.create_cube(bm_int, size=1.0)
        bmesh.ops.scale(bm_int, vec=(0.22, 0.09, 0.14), verts=r_head['verts'])
        bmesh.ops.rotate(bm_int, matrix=Matrix.Rotation(math.radians(-15), 3, 'X'), verts=r_head['verts'])
        bmesh.ops.translate(bm_int, vec=(sx, -0.23, 0.96), verts=r_head['verts'])
        for f in bm_int.faces:
            if all(v in r_head['verts'] for v in f.verts): f.material_index = 6

    bm_int.to_mesh(body.data)
    bm_int.free()

    # 5. ADD SOCKET MARKER NODES
    add_marker_socket("Seat_Driver", (-0.36, 0.05, 0.45))
    add_marker_socket("Seat_Passenger", (0.36, 0.05, 0.45))
    add_marker_socket("SteeringWheel_Mount", (-0.36, 0.35, 0.79))
    add_marker_socket("Door_Entry_L", (-1.30, 0.05, 0.0))
    add_marker_socket("Door_Entry_R", (1.30, 0.05, 0.0))

    out_path = os.path.join(OUT_DIR, "muscle_coupe.glb")
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        use_selection=True,
        export_format='GLB',
        export_materials='EXPORT',
        export_texcoords=True,
        export_normals=True
    )
    print("[MOLDED PRO] Exported Muscle Coupe with Interior & Sockets:", out_path)

# =========================================================================
# 2. MOLD SECURITY INTERCEPTOR ("UNIT-09")
# =========================================================================
def mold_security_interceptor():
    reset_scene()
    police_glb = os.path.join(LIB, "police_car.glb")
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=police_glb)
    all_obs = list(set(bpy.data.objects) - before)

    body = max([o for o in all_obs if o.type == 'MESH'],
               key=lambda o: len(o.data.vertices))
    body.name = "SecurityInterceptor_Mesh"
    body.data.name = "SecurityInterceptor_Mesh"
    bb = body.bound_box
    curr_len = max(v[1] for v in bb) - min(v[1] for v in bb)
    s = 5.05 / curr_len
    for ob in all_obs:
        ob.scale = (s, s, s)
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.transform_apply(scale=True)

    global_min_z = 999.0
    for ob in all_obs:
        if ob.type == 'MESH':
            for v in ob.bound_box:
                w_co = ob.matrix_world @ Vector(v)
                if w_co.z < global_min_z:
                    global_min_z = w_co.z
    for ob in all_obs:
        ob.location.z -= global_min_z
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.transform_apply(location=True)

    # Direct 180 rotation on vertices: Front = +Y
    for ob in all_obs:
        if ob.type == 'MESH':
            bm_rot = bmesh.new()
            bm_rot.from_mesh(ob.data)
            for v in bm_rot.verts:
                v.co.x = -v.co.x
                v.co.y = -v.co.y
            bm_rot.normal_update()
            bm_rot.to_mesh(ob.data)
            bm_rot.free()

    # Materials
    setup_pbr_mat(body.data.materials[0], diffuse=(0.95, 0.95, 0.97, 1.0), roughness=0.40, metallic=0.10, tex_path=INTER_LIV)
    setup_pbr_mat(body.data.materials[1], diffuse=(0.18, 0.22, 0.28, 1.0), roughness=0.06, metallic=0.10, alpha=0.35)
    setup_pbr_mat(body.data.materials[2], diffuse=(0.35, 0.38, 0.42, 1.0), roughness=0.40, metallic=0.75)
    setup_pbr_mat(body.data.materials[3], diffuse=(1.0, 0.95, 0.85, 1.0), roughness=0.10, emission=(1.0, 0.95, 0.85), emission_strength=5.0)
    setup_pbr_mat(body.data.materials[4], diffuse=(0.10, 0.12, 0.15, 1.0), roughness=0.55, metallic=0.12)
    setup_pbr_mat(body.data.materials[5], diffuse=(1.0, 0.05, 0.02, 1.0), roughness=0.10, emission=(1.0, 0.05, 0.02), emission_strength=4.0)
    setup_pbr_mat(body.data.materials[6], diffuse=(1.0, 0.05, 0.05, 1.0), roughness=0.10, emission=(1.0, 0.05, 0.05), emission_strength=6.0)
    setup_pbr_mat(body.data.materials[7], diffuse=(0.05, 0.35, 1.0, 1.0), roughness=0.10, emission=(0.05, 0.35, 1.0), emission_strength=6.0)

    # UV projection for white doors
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.faces.ensure_lookup_table()
    uv_layer = bm.loops.layers.uv.verify()

    min_y = min(v.co.y for v in bm.verts)
    max_y = max(v.co.y for v in bm.verts)
    min_z = min(v.co.z for v in bm.verts)
    max_z = max(v.co.z for v in bm.verts)
    len_y = max_y - min_y
    h_z   = max_z - min_z

    for f in bm.faces:
        if f.material_index == 0:
            n = f.normal
            if n.x > 0:
                u1, v1, u2, v2 = (0.05, 0.74, 0.95, 0.98)
                for l in f.loops:
                    ny = (l.vert.co.y - min_y) / len_y
                    nz = (l.vert.co.z - min_z) / h_z
                    l[uv_layer].uv = (u1 + ny * (u2 - u1), v1 + nz * (v2 - v1))
            else:
                u1, v1, u2, v2 = (0.05, 0.50, 0.95, 0.72)
                for l in f.loops:
                    ny = (l.vert.co.y - min_y) / len_y
                    nz = (l.vert.co.z - min_z) / h_z
                    l[uv_layer].uv = (u1 + (1.0 - ny) * (u2 - u1), v1 + nz * (v2 - v1))

    # Add Heavy Bullbar at Front (+Y ~ 2.45)
    front_y = max_y + 0.05
    mat_bullbar = setup_pbr_mat(bpy.data.materials.new("Mat_PushBumper"), diffuse=(0.80, 0.83, 0.88, 1.0), roughness=0.20, metallic=0.92)
    body.data.materials.append(mat_bullbar)
    bullbar_idx = len(body.data.materials) - 1

    add_box(bm, (1.60, 0.08, 0.08), (0.0, front_y, 0.40), mat_idx=bullbar_idx)
    add_box(bm, (1.60, 0.08, 0.08), (0.0, front_y, 0.62), mat_idx=bullbar_idx)
    add_box(bm, (0.10, 0.12, 0.46), (-0.45, front_y, 0.51), mat_idx=bullbar_idx)
    add_box(bm, (0.10, 0.12, 0.46), ( 0.45, front_y, 0.51), mat_idx=bullbar_idx)
    add_box(bm, (0.12, 0.28, 0.07), (-0.76, front_y - 0.12, 0.51), mat_idx=bullbar_idx)
    add_box(bm, (0.12, 0.28, 0.07), ( 0.76, front_y - 0.12, 0.51), mat_idx=bullbar_idx)

    bm.to_mesh(body.data)
    bm.free()

    # Wheel Materials
    for ob in all_obs:
        if ob != body and ob.type == 'MESH':
            setup_pbr_mat(ob.data.materials[0], diffuse=(0.20, 0.22, 0.25, 1.0), roughness=0.35, metallic=0.80)
            setup_pbr_mat(ob.data.materials[1], diffuse=(0.06, 0.06, 0.07, 1.0), roughness=0.88, metallic=0.0)

    # 4. BUILD POLICE INTERCEPTOR INTERIOR POD
    bm_int = bmesh.new()
    mat_int_dark   = create_pbr_mat("Mat_Int_Dark",   (0.08, 0.09, 0.10, 1.0), roughness=0.85)
    mat_int_seat   = create_pbr_mat("Mat_Int_Seat",   (0.14, 0.14, 0.16, 1.0), roughness=0.80)
    mat_int_mdt    = create_pbr_mat("Mat_Int_MDT",    (0.15, 0.16, 0.18, 1.0), roughness=0.50, metallic=0.50)
    mat_int_screen = create_pbr_mat("Mat_Int_Screen", (0.10, 0.40, 1.00, 1.0), roughness=0.10, emission=(0.10, 0.40, 1.00), emission_strength=4.0)

    # Dashboard
    r_d = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(1.38, 0.34, 0.22), verts=r_d['verts'])
    bmesh.ops.translate(bm_int, vec=(0.0, 0.58, 0.68), verts=r_d['verts'])
    for f in bm_int.faces:
        if all(v in r_d['verts'] for v in f.verts): f.material_index = 0

    # Gauge Binnacle (recessed behind wheel in instrument cluster pocket)
    r_gb = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(0.30, 0.14, 0.10), verts=r_gb['verts'])
    bmesh.ops.translate(bm_int, vec=(-0.38, 0.52, 0.78), verts=r_gb['verts'])
    for f in bm_int.faces:
        if all(v in r_gb['verts'] for v in f.verts): f.material_index = 0

    # Standard Automotive Steering Wheel (36cm outer diameter, torus rim, 3 spokes, hub, 25-deg column)
    add_standard_steering_wheel(bm_int, (-0.38, 0.35, 0.79), tilt_deg=-25.0, mat_idx_rim=0, mat_idx_hub=0, mat_idx_col=0)

    # Police MDT Laptop Terminal (mounted between seats on swivel bracket)
    r_mdt_base = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(0.08, 0.08, 0.28), verts=r_mdt_base['verts'])
    bmesh.ops.translate(bm_int, vec=(0.0, 0.28, 0.56), verts=r_mdt_base['verts'])
    for f in bm_int.faces:
        if all(v in r_mdt_base['verts'] for v in f.verts): f.material_index = 2

    # MDT Keyboard
    r_mdt_kb = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(0.24, 0.18, 0.03), verts=r_mdt_kb['verts'])
    bmesh.ops.translate(bm_int, vec=(-0.05, 0.25, 0.71), verts=r_mdt_kb['verts'])
    for f in bm_int.faces:
        if all(v in r_mdt_kb['verts'] for v in f.verts): f.material_index = 2

    # Glowing Blue MDT Screen (angled toward driver)
    r_scr = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(0.22, 0.03, 0.16), verts=r_scr['verts'])
    bmesh.ops.rotate(bm_int, matrix=Matrix.Rotation(math.radians(-20), 3, 'X'), verts=r_scr['verts'])
    bmesh.ops.rotate(bm_int, matrix=Matrix.Rotation(math.radians(22), 3, 'Z'), verts=r_scr['verts'])
    bmesh.ops.translate(bm_int, vec=(-0.05, 0.35, 0.82), verts=r_scr['verts'])
    for f in bm_int.faces:
        if all(v in r_scr['verts'] for v in f.verts): f.material_index = 3

    # Dual Bucket Seats
    for sx in (-0.38, 0.38):
        r_cush = bmesh.ops.create_cube(bm_int, size=1.0)
        bmesh.ops.scale(bm_int, vec=(0.42, 0.44, 0.12), verts=r_cush['verts'])
        bmesh.ops.translate(bm_int, vec=(sx, 0.05, 0.42), verts=r_cush['verts'])
        for f in bm_int.faces:
            if all(v in r_cush['verts'] for v in f.verts): f.material_index = 1

        r_back = bmesh.ops.create_cube(bm_int, size=1.0)
        bmesh.ops.scale(bm_int, vec=(0.40, 0.12, 0.50), verts=r_back['verts'])
        bmesh.ops.rotate(bm_int, matrix=Matrix.Rotation(math.radians(-15), 3, 'X'), verts=r_back['verts'])
        bmesh.ops.translate(bm_int, vec=(sx, -0.16, 0.68), verts=r_back['verts'])
        for f in bm_int.faces:
            if all(v in r_back['verts'] for v in f.verts): f.material_index = 1

        r_head = bmesh.ops.create_cube(bm_int, size=1.0)
        bmesh.ops.scale(bm_int, vec=(0.22, 0.09, 0.14), verts=r_head['verts'])
        bmesh.ops.rotate(bm_int, matrix=Matrix.Rotation(math.radians(-15), 3, 'X'), verts=r_head['verts'])
        bmesh.ops.translate(bm_int, vec=(sx, -0.23, 0.96), verts=r_head['verts'])
        for f in bm_int.faces:
            if all(v in r_head['verts'] for v in f.verts): f.material_index = 1

    # Security Divider Mesh behind seats (Y ~ -0.32)
    r_cage = bmesh.ops.create_cube(bm_int, size=1.0)
    bmesh.ops.scale(bm_int, vec=(1.35, 0.04, 0.62), verts=r_cage['verts'])
    bmesh.ops.translate(bm_int, vec=(0.0, -0.32, 0.75), verts=r_cage['verts'])
    for f in bm_int.faces:
        if all(v in r_cage['verts'] for v in f.verts): f.material_index = 2

    mesh_int = bpy.data.meshes.new("Interceptor_Interior")
    bm_int.to_mesh(mesh_int)
    bm_int.free()
    ob_int = bpy.data.objects.new("Interceptor_Interior", mesh_int)
    ob_int.data.materials.append(mat_int_dark)
    ob_int.data.materials.append(mat_int_seat)
    ob_int.data.materials.append(mat_int_mdt)
    ob_int.data.materials.append(mat_int_screen)
    bpy.context.scene.collection.objects.link(ob_int)
    all_obs.append(ob_int)

    # 5. ADD SOCKET MARKER NODES
    add_marker_socket("Seat_Driver", (-0.38, 0.05, 0.45))
    add_marker_socket("Seat_Passenger", (0.38, 0.05, 0.45))
    add_marker_socket("SteeringWheel_Mount", (-0.38, 0.35, 0.79))
    add_marker_socket("Door_Entry_L", (-1.32, 0.05, 0.0))
    add_marker_socket("Door_Entry_R", (1.32, 0.05, 0.0))

    out_path = os.path.join(OUT_DIR, "security_interceptor.glb")
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        use_selection=True,
        export_format='GLB',
        export_materials='EXPORT',
        export_texcoords=True,
        export_normals=True
    )
    print("[MOLDED PRO] Exported Security Interceptor with Interior & Sockets:", out_path)

if __name__ == "__main__":
    mold_muscle_coupe()
    mold_security_interceptor()
    print("=== MOLDING PRO COMPLETE ===")
