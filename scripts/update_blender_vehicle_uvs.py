#!/usr/bin/env python3
"""
Updates scripts/blender_build_expansion.py with specialized add_vehicle_box()
that maps separate UV zones for Side, Top, Front, Back, and Bottom.
"""

with open("scripts/blender_build_expansion.py", "r") as f:
    code = f.read()

# Replace add_box with enhanced multi-surface mapping support
new_add_vehicle_box = '''
def add_vehicle_box(bm, size, pos, rot=(0,0,0), uv_side=(0,0,1,1), uv_top=(0,0,1,1), uv_front=(0,0,1,1), uv_back=(0,0,1,1), mat_idx=0):
    res = bmesh.ops.create_cube(bm, size=1.0)
    new_verts = res['verts']
    new_verts_set = set(new_verts)
    new_faces = [f for f in bm.faces if all(v in new_verts_set for v in f.verts)]

    uv_layer = bm.loops.layers.uv.verify()
    for face in new_faces:
        face.material_index = mat_idx
        # Determine face orientation:
        # normal.y > 0.8: Front face (+Y in Blender)
        # normal.y < -0.8: Back face (-Y in Blender)
        # normal.x > 0.8 or normal.x < -0.8: Side faces (+/- X)
        # normal.z > 0.8: Top face (+Z)
        # normal.z < -0.8: Bottom face (-Z)
        
        if face.normal.y > 0.7:
            u1, v1, u2, v2 = uv_front
            for loop in face.loops:
                nx = loop.vert.co.x + 0.5
                nz = loop.vert.co.z + 0.5
                loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
        elif face.normal.y < -0.7:
            u1, v1, u2, v2 = uv_back
            for loop in face.loops:
                nx = (1.0 - (loop.vert.co.x + 0.5))
                nz = loop.vert.co.z + 0.5
                loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
        elif abs(face.normal.x) > 0.7:
            u1, v1, u2, v2 = uv_side
            for loop in face.loops:
                ny = loop.vert.co.y + 0.5
                nz = loop.vert.co.z + 0.5
                if face.normal.x > 0:
                    loop[uv_layer].uv = (u1 + ny * (u2 - u1), v1 + nz * (v2 - v1))
                else:
                    loop[uv_layer].uv = (u2 - ny * (u2 - u1), v1 + nz * (v2 - v1))
        elif face.normal.z > 0.7:
            u1, v1, u2, v2 = uv_top
            for loop in face.loops:
                nx = loop.vert.co.x + 0.5
                ny = loop.vert.co.y + 0.5
                loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))
        else: # Bottom
            u1, v1, u2, v2 = uv_side
            for loop in face.loops:
                nx = loop.vert.co.x + 0.5
                ny = loop.vert.co.y + 0.5
                loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + ny * (v2 - v1))

    S = Matrix.Scale(size[0], 4, (1, 0, 0)) @ Matrix.Scale(size[1], 4, (0, 1, 0)) @ Matrix.Scale(size[2], 4, (0, 0, 1))
    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    bmesh.ops.transform(bm, matrix=(T @ R @ S), verts=new_verts)
'''

# Find position after add_cylinder and insert add_vehicle_box
idx = code.find("def build_traffic_barrier")
code = code[:idx] + new_add_vehicle_box + "\n" + code[idx:]

# Replace build_muscle_coupe
new_coupe = '''def build_muscle_coupe(tex_path, out_glb):
    reset_scene()
    bm = bmesh.new()

    # UV Regions in baked 2048x2048 atlas:
    # Side: (0.0, 0.67, 1.0, 1.0)
    # Top: (0.01, 0.01, 0.49, 0.66)
    # Front: (0.51, 0.35, 0.99, 0.66)
    # Rear: (0.51, 0.01, 0.99, 0.34)
    uv_s = (0.0, 0.67, 1.0, 1.0)
    uv_t = (0.01, 0.01, 0.49, 0.66)
    uv_f = (0.51, 0.35, 0.99, 0.66)
    uv_r = (0.51, 0.01, 0.99, 0.34)

    # Main chassis & lower body: 1.82m wide, 4.3m long, 0.45m high (center z=0.45m)
    add_vehicle_box(bm, (1.82, 4.3, 0.45), (0.0, 0.0, 0.45), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Cabin / Greenhouse: 1.45m wide, 1.9m long, 0.48m high (center y=-0.2m, z=0.88m)
    add_vehicle_box(bm, (1.45, 1.9, 0.48), (0.0, -0.2, 0.88), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Hood cowl / blower scoop on front hood: 0.6m wide, 1.1m long, 0.18m high (y=1.0m, z=0.74m)
    add_vehicle_box(bm, (0.6, 1.1, 0.18), (0.0, 1.0, 0.74), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Front chin spoiler / bumper: 1.85m wide, 0.25m deep, 0.15m high (y=2.15m, z=0.25m)
    add_vehicle_box(bm, (1.85, 0.25, 0.15), (0.0, 2.15, 0.25), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Rear deck ducktail spoiler: 1.65m wide, 0.25m deep, 0.12m high (y=-2.05m, z=0.75m)
    add_vehicle_box(bm, (1.65, 0.25, 0.12), (0.0, -2.05, 0.75), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)

    # 4 Wide Wheels (radius 0.35m, width 0.28m, track width +/- 0.88m, wheelbase +/- 1.35m)
    for wx in (-0.88, 0.88):
        for wy in (-1.35, 1.35):
            add_cylinder(bm, 0.35, 0.28, (wx, wy, 0.35), rot=(0, math.pi/2, 0), uv_rect=(0.7, 0.0, 1.0, 0.35))

    mesh = bpy.data.meshes.new("MuscleCoupe_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("MuscleCoupe_Mesh", mesh)
    bpy.context.collection.objects.link(obj)
    mat = create_material("Mat_MuscleCoupe", tex_path)
    obj.data.materials.append(mat)

    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Muscle Coupe GLB:", out_glb)
'''

# Replace build_scrap_hauler
new_hauler = '''def build_scrap_hauler(tex_path, out_glb):
    reset_scene()
    bm = bmesh.new()

    uv_s = (0.0, 0.67, 1.0, 1.0)
    uv_f = (0.01, 0.34, 0.49, 0.66)
    uv_r = (0.01, 0.01, 0.49, 0.33)
    uv_t = (0.51, 0.01, 0.99, 0.66) # Scrap metal top

    # Heavy Lower Frame: 1.65m wide, 3.7m long, 0.42m high (center z=0.45m)
    add_vehicle_box(bm, (1.65, 3.7, 0.42), (0.0, 0.0, 0.45), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Forward-Control Industrial Truck Cab: 1.55m wide, 1.45m long, 1.05m high (y=1.05m, z=1.15m)
    add_vehicle_box(bm, (1.55, 1.45, 1.05), (0.0, 1.05, 1.15), uv_side=uv_s, uv_top=uv_s, uv_front=uv_f, uv_back=uv_r)
    # Cab Roof Visor & Clearance Light Brow: 1.60m wide, 0.35m deep, 0.12m high (y=1.55m, z=1.70m)
    add_vehicle_box(bm, (1.60, 0.35, 0.12), (0.0, 1.55, 1.70), uv_side=uv_s, uv_top=uv_s, uv_front=uv_f, uv_back=uv_r)
    # Heavy Front Bullbar / Grille Guard: 1.65m wide, 0.20m deep, 0.70m high (y=1.85m, z=0.60m)
    add_vehicle_box(bm, (1.65, 0.20, 0.70), (0.0, 1.85, 0.60), uv_side=uv_s, uv_top=uv_s, uv_front=uv_f, uv_back=uv_r)
    # Scrap Cargo Bed / Hopper: 1.68m wide, 2.05m long, 0.65m high (y=-0.75m, z=0.95m)
    add_vehicle_box(bm, (1.68, 2.05, 0.65), (0.0, -0.75, 0.95), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)

    # 6 Wheels (2 front, 4 dual rear, radius 0.40m, width 0.30m)
    for wx in (-0.85, 0.85):
        add_cylinder(bm, 0.40, 0.30, (wx, 1.25, 0.40), rot=(0, math.pi/2, 0), uv_rect=(0.7, 0.7, 1.0, 1.0))
        add_cylinder(bm, 0.40, 0.30, (wx, -0.65, 0.40), rot=(0, math.pi/2, 0), uv_rect=(0.7, 0.7, 1.0, 1.0))
        add_cylinder(bm, 0.40, 0.30, (wx, -1.35, 0.40), rot=(0, math.pi/2, 0), uv_rect=(0.7, 0.7, 1.0, 1.0))

    mesh = bpy.data.meshes.new("ScrapHauler_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("ScrapHauler_Mesh", mesh)
    bpy.context.collection.objects.link(obj)
    mat = create_material("Mat_ScrapHauler", tex_path)
    obj.data.materials.append(mat)

    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Scrap Hauler GLB:", out_glb)
'''

# Replace build_security_interceptor
new_interceptor = '''def build_security_interceptor(tex_path, out_glb):
    reset_scene()
    bm = bmesh.new()

    uv_s = (0.0, 0.67, 1.0, 1.0)
    uv_f = (0.01, 0.34, 0.49, 0.66)
    uv_r = (0.01, 0.01, 0.49, 0.33)
    uv_t = (0.51, 0.01, 0.99, 0.66) # High-vis roof identification decal & stencils

    # Pursuit Cruiser Lower Body: 1.82m wide, 4.25m long, 0.48m high (center z=0.48m)
    add_vehicle_box(bm, (1.82, 4.25, 0.48), (0.0, 0.0, 0.48), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Aerodynamic Cabin: 1.48m wide, 2.1m long, 0.48m high (y=-0.1m, z=0.92m)
    add_vehicle_box(bm, (1.48, 2.1, 0.48), (0.0, -0.1, 0.92), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # High-contrast roof identification decal plate
    add_vehicle_box(bm, (1.20, 1.40, 0.03), (0.0, -0.1, 1.17), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Front hood high-contrast pursuit chevron stripe
    add_vehicle_box(bm, (1.10, 1.00, 0.03), (0.0, 1.15, 0.72), uv_side=uv_s, uv_top=uv_t, uv_front=uv_f, uv_back=uv_r)
    # Heavy-Duty Front Push Bumper / Ram Bar: 1.80m wide, 0.30m deep, 0.45m high (y=2.2m, z=0.45m)
    add_vehicle_box(bm, (1.80, 0.30, 0.45), (0.0, 2.2, 0.45), uv_side=uv_s, uv_top=uv_s, uv_front=uv_f, uv_back=uv_r)
    # Aerodynamic Roof Strobe Light Bar: 1.1m wide, 0.35m deep, 0.12m high (y=-0.1m, z=1.22m)
    add_vehicle_box(bm, (1.1, 0.35, 0.12), (0.0, -0.1, 1.22), uv_side=uv_s, uv_top=uv_f, uv_front=uv_f, uv_back=uv_r)
    # A-Pillar Spotlight
    add_cylinder(bm, 0.08, 0.18, (-0.78, 0.75, 1.02), rot=(0.3, 0, -0.4), uv_rect=(0.8, 0.8, 1.0, 1.0))
    # Tactical Rear Deck Spoiler: 1.55m wide, 0.25m deep, 0.12m high (y=-2.0m, z=0.78m)
    add_vehicle_box(bm, (1.55, 0.25, 0.12), (0.0, -2.0, 0.78), uv_side=uv_s, uv_top=uv_s, uv_front=uv_f, uv_back=uv_r)

    # 4 Steel Pursuit Wheels
    for wx in (-0.88, 0.88):
        for wy in (-1.30, 1.30):
            add_cylinder(bm, 0.36, 0.28, (wx, wy, 0.36), rot=(0, math.pi/2, 0), uv_rect=(0.7, 0.0, 1.0, 0.35))

    mesh = bpy.data.meshes.new("SecurityInterceptor_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("SecurityInterceptor_Mesh", mesh)
    bpy.context.collection.objects.link(obj)
    mat = create_material("Mat_SecurityInterceptor", tex_path, emission_color=(1, 0.1, 0.1, 1), emission_strength=1.5)
    obj.data.materials.append(mat)

    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB')
    print("Exported Security Interceptor GLB:", out_glb)
'''

# Find build_muscle_coupe and replace up to main()
start_mc = code.find("def build_muscle_coupe")
end_interceptor = code.find("def main():")
code = code[:start_mc] + new_coupe + "\n" + new_hauler + "\n" + new_interceptor + "\n\n" + code[end_interceptor:]

with open("scripts/blender_build_expansion.py", "w") as f:
    f.write(code)

print("Updated scripts/blender_build_expansion.py with multi-surface vehicle UV mapping!")
