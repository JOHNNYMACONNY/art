"""
scripts/blender_build_bike.py
Constructs the low-poly Courier Bike (FB-13) in Blender 4.3.2
Based on the orthographic model sheet: docs/visual_direction/references/courier_bike_3d_model_sheet.png
Uses g2b() to accurately translate Godot coordinates to Blender's Z-up system.
Exports to:
  - godot/models/courier_bike.glb (unified glTF 2.0 scene)
  - models_source/courier_bike.blend (full Blender project)
  - godot/models/courier_bike/bike_*.obj (modular in-engine components)
"""

import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

def g2b(v):
    # Godot: X is right, Y is up, -Z is forward (+Z is rear)
    # Blender: X is right, +Y is forward (-Y is rear), Z is up
    return Vector((v[0], -v[2], v[1]))

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in bpy.data.collections:
        bpy.data.collections.remove(c)
    for m in bpy.data.meshes:
        bpy.data.meshes.remove(m)
    for mat in bpy.data.materials:
        bpy.data.materials.remove(mat)

def create_toon_material(name, diffuse_color, roughness=0.5, metallic=0.0, emission_color=(0,0,0,1), emission_strength=0.0):
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
    
    if emission_strength > 0.0:
        node_bsdf.inputs['Emission Color'].default_value = emission_color
        node_bsdf.inputs['Emission Strength'].default_value = emission_strength
        
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def setup_materials():
    mats = {}
    mats['Frame'] = create_toon_material('Mat_Frame', (0.12, 0.13, 0.15, 1.0), roughness=0.4, metallic=0.7)
    mats['Orange'] = create_toon_material('Mat_Orange', (1.0, 0.38, 0.0, 1.0), roughness=0.3, metallic=0.1)
    mats['Tire'] = create_toon_material('Mat_Tire', (0.08, 0.09, 0.10, 1.0), roughness=0.85, metallic=0.0)
    mats['Metal'] = create_toon_material('Mat_Metal', (0.55, 0.58, 0.62, 1.0), roughness=0.35, metallic=0.85)
    mats['Seat'] = create_toon_material('Mat_Seat', (0.07, 0.07, 0.08, 1.0), roughness=0.7, metallic=0.0)
    mats['CyanGlow'] = create_toon_material('Mat_CyanGlow', (0.0, 0.88, 1.0, 1.0), emission_color=(0.0, 0.9, 1.0, 1.0), emission_strength=3.2)
    mats['Headlight'] = create_toon_material('Mat_Headlight', (1.0, 0.98, 0.85, 1.0), emission_color=(1.0, 0.96, 0.82, 1.0), emission_strength=1.35)
    mats['Taillight'] = create_toon_material('Mat_Taillight', (0.9, 0.05, 0.05, 1.0), emission_color=(1.0, 0.1, 0.1, 1.0), emission_strength=2.2)
    mats['StencilWhite'] = create_toon_material('Mat_StencilWhite', (0.92, 0.93, 0.95, 1.0), roughness=0.5)
    return mats

def add_cylinder(bm, p1, p2, r, segments=8):
    v = p2 - p1
    length = v.length
    if length < 1e-6:
        return
    center = (p1 + p2) * 0.5
    rot = Vector((0, 0, 1)).rotation_difference(v)
    mat_rot = rot.to_matrix().to_4x4()
    mat_trans = Matrix.Translation(center)
    mat_scale = Matrix.Scale(r, 4, Vector((1, 0, 0))) @ Matrix.Scale(r, 4, Vector((0, 1, 0))) @ Matrix.Scale(length * 0.5, 4, Vector((0, 0, 1)))
    xform = mat_trans @ mat_rot @ mat_scale
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments, radius1=1.0, radius2=1.0, depth=2.0, matrix=xform)

def build_chassis_frame(mats):
    mesh = bpy.data.meshes.new('Chassis_Mesh')
    bm = bmesh.new()
    
    # Head tube: Godot (0, 1.05, -0.55) to (0, 0.85, -0.65)
    p_top = g2b((0, 1.05, -0.55))
    p_bot = g2b((0, 0.85, -0.65))
    add_cylinder(bm, p_bot, p_top, 0.032, segments=8)
    
    # Backbone: head tube top to mid (0, 0.88, -0.15) to rear (0, 0.82, 0.25)
    bb_mid = g2b((0, 0.88, -0.15))
    bb_rear = g2b((0, 0.82, 0.25))
    add_cylinder(bm, p_top, bb_mid, 0.026, segments=8)
    add_cylinder(bm, bb_mid, bb_rear, 0.026, segments=8)
    
    # Twin Down Tubes splitting from head tube
    for side in (-1, 1):
        dt_start = g2b((side * 0.025, 0.88, -0.60))
        dt_cradle_f = g2b((side * 0.11, 0.40, -0.35))
        dt_cradle_r = g2b((side * 0.11, 0.38, 0.15))
        dt_pivot = g2b((side * 0.06, 0.45, 0.30))
        
        add_cylinder(bm, dt_start, dt_cradle_f, 0.020, segments=8)
        add_cylinder(bm, dt_cradle_f, dt_cradle_r, 0.020, segments=8)
        add_cylinder(bm, dt_cradle_r, dt_pivot, 0.020, segments=8)
        add_cylinder(bm, dt_pivot, bb_rear, 0.020, segments=8)
        
        # Subframe rails
        sf_mid = g2b((side * 0.09, 0.85, 0.55))
        sf_rear = g2b((side * 0.08, 0.87, 0.90))
        add_cylinder(bm, bb_rear, sf_mid, 0.018, segments=8)
        add_cylinder(bm, sf_mid, sf_rear, 0.018, segments=8)
        add_cylinder(bm, dt_pivot, sf_mid, 0.016, segments=8)
        
        # Swingarm (pivot to rear wheel axle at z=0.85, y=0.35)
        rear_axle = g2b((side * 0.08, 0.35, 0.85))
        add_cylinder(bm, dt_pivot, rear_axle, 0.024, segments=8)
        
        # Shock absorbers
        shock_bot = g2b((side * 0.09, 0.38, 0.72))
        add_cylinder(bm, sf_mid, shock_bot, 0.020, segments=8)
        
    p1 = g2b((-0.08, 0.87, 0.90))
    p2 = g2b((0.08, 0.87, 0.90))
    add_cylinder(bm, p1, p2, 0.018, segments=8)
    
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Frame', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Frame'])
    return obj

def build_skid_plate(mats):
    mesh = bpy.data.meshes.new('Skid_Mesh')
    bm = bmesh.new()
    c = g2b((0, 0.34, -0.10))
    # In Blender: X width=0.24, Y depth=0.52, Z height=0.015
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(c) @ Matrix.Scale(0.24, 4, Vector((1,0,0))) @ Matrix.Scale(0.52, 4, Vector((0,1,0))) @ Matrix.Scale(0.015, 4, Vector((0,0,1))))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new('SkidPlate', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Metal'])
    return obj

def build_fuel_tank(mats):
    mesh = bpy.data.meshes.new('Tank_Mesh')
    bm = bmesh.new()
    
    # Along Godot Z from -0.52 (front) to +0.10 (rear waist)
    gz_coords = [-0.52, -0.44, -0.32, -0.18, -0.04, 0.10]
    gy_centers = [0.98, 1.01, 1.02, 1.00, 0.96, 0.91]
    radii_x = [0.10, 0.17, 0.18, 0.16, 0.12, 0.09]  # Hourglass!
    radii_y = [0.08, 0.11, 0.11, 0.10, 0.08, 0.06]
    
    ring_verts = []
    for gz, gy, rx, ry in zip(gz_coords, gy_centers, radii_x, radii_y):
        verts = []
        for i in range(10):
            ang = i * (2.0 * math.pi / 10.0)
            y_mult = 0.65 if math.sin(ang) < -0.2 else 1.0
            x_mult = 0.85 if (gz > -0.20 and abs(math.cos(ang)) > 0.6) else 1.0
            gx = math.cos(ang) * rx * x_mult
            gy_pt = gy + math.sin(ang) * ry * y_mult
            gz_pt = gz
            verts.append(bm.verts.new(g2b((gx, gy_pt, gz_pt))))
        ring_verts.append(verts)
        
    for r in range(len(ring_verts) - 1):
        r1 = ring_verts[r]
        r2 = ring_verts[r+1]
        for i in range(10):
            i_next = (i + 1) % 10
            bm.faces.new([r1[i], r1[i_next], r2[i_next], r2[i]])
            
    bm.faces.new(ring_verts[0])
    bm.faces.new(reversed(ring_verts[-1]))
    
    cap_c = g2b((0, 1.13, -0.34))
    bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.038, radius2=0.038, depth=0.025, matrix=Matrix.Translation(cap_c))
    
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Tank', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Orange'])
    return obj

def build_scrambler_seat(mats):
    mesh = bpy.data.meshes.new('Seat_Mesh')
    bm = bmesh.new()
    
    gz_coords = [0.10, 0.22, 0.36, 0.50, 0.66]
    gy_coords = [0.91, 0.93, 0.94, 0.95, 0.95]
    radii_x = [0.088, 0.105, 0.110, 0.102, 0.085]
    
    ring_verts = []
    for gz, gy, rx in zip(gz_coords, gy_coords, radii_x):
        v0 = bm.verts.new(g2b((-rx, gy - 0.03, gz)))
        v1 = bm.verts.new(g2b((-rx * 0.9, gy + 0.035, gz)))
        v2 = bm.verts.new(g2b((0.0, gy + 0.045, gz)))
        v3 = bm.verts.new(g2b((rx * 0.9, gy + 0.035, gz)))
        v4 = bm.verts.new(g2b((rx, gy - 0.03, gz)))
        v5 = bm.verts.new(g2b((0.0, gy - 0.035, gz)))
        ring_verts.append([v0, v1, v2, v3, v4, v5])
        
    for r in range(len(ring_verts) - 1):
        r1 = ring_verts[r]
        r2 = ring_verts[r+1]
        for i in range(6):
            i_next = (i + 1) % 6
            bm.faces.new([r1[i], r1[i_next], r2[i_next], r2[i]])
            
    bm.faces.new(ring_verts[0])
    bm.faces.new(reversed(ring_verts[-1]))
    
    for gz_rib in [0.20, 0.30, 0.40, 0.50, 0.60]:
        add_cylinder(bm, g2b((-0.09, 0.975, gz_rib)), g2b((0.09, 0.975, gz_rib)), 0.008, segments=6)
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Seat', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Seat'])
    return obj

def build_battery_core(mats):
    mesh = bpy.data.meshes.new('Battery_Mesh')
    bm = bmesh.new()
    
    c = g2b((0, 0.55, -0.10))
    # Width X=0.20, Depth Y=0.36, Height Z=0.30 in Blender
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(c) @ Matrix.Scale(0.20, 4, Vector((1,0,0))) @ Matrix.Scale(0.36, 4, Vector((0,1,0))) @ Matrix.Scale(0.30, 4, Vector((0,0,1))))
    
    for side in (-1, 1):
        cell_f = g2b((side * 0.09, 0.55, -0.10 - 0.14))
        cell_r = g2b((side * 0.09, 0.55, -0.10 + 0.14))
        add_cylinder(bm, cell_f, cell_r, 0.055, segments=10)
        
    # Recessed horizontal glowing indicator slits
    for gy_slot in (0.50, 0.58):
        for side in (-1, 1):
            slot_c = g2b((side * 0.105, gy_slot, -0.10))
            bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(slot_c) @ Matrix.Scale(0.015, 4, Vector((1,0,0))) @ Matrix.Scale(0.18, 4, Vector((0,1,0))) @ Matrix.Scale(0.025, 4, Vector((0,0,1))))
            
    # High-voltage orange conduit cables looping from battery top into frame
    for side in (-1, 1):
        p_bat_top = g2b((side * 0.08, 0.68, -0.10))
        p_frame_loop = g2b((side * 0.11, 0.78, -0.28))
        add_cylinder(bm, p_bat_top, p_frame_loop, 0.013, segments=6)
        p_rear_loop = g2b((side * 0.08, 0.68, 0.05))
        p_subframe = g2b((side * 0.07, 0.74, 0.18))
        add_cylinder(bm, p_rear_loop, p_subframe, 0.011, segments=6)
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Battery', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Metal'])
    return obj

def build_front_fork_and_fender(mats):
    mesh = bpy.data.meshes.new('FrontFork_Mesh')
    bm = bmesh.new()
    
    tt_top = g2b((0, 1.08, -0.54))
    tt_bot = g2b((0, 0.88, -0.64))
    for tt_pos in (tt_top, tt_bot):
        bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(tt_pos) @ Matrix.Scale(0.22, 4, Vector((1,0,0))) @ Matrix.Scale(0.08, 4, Vector((0,1,0))) @ Matrix.Scale(0.03, 4, Vector((0,0,1))))
        
    for side in (-1, 1):
        fork_t = g2b((side * 0.085, 1.08, -0.54))
        fork_slider = g2b((side * 0.085, 0.70, -0.68))
        fork_axle = g2b((side * 0.085, 0.35, -0.92))
        add_cylinder(bm, fork_t, fork_slider, 0.020, segments=8)
        add_cylinder(bm, fork_slider, fork_axle, 0.026, segments=8)
        
    # High Front Fender
    f_pts = []
    for ang in [-0.5, -0.25, 0.0, 0.25, 0.5]:
        gz = -0.92 + math.sin(ang) * 0.40
        gy = 0.35 + math.cos(ang) * 0.40
        f_pts.append(g2b((0, gy, gz)))
    for i in range(len(f_pts) - 1):
        p1 = f_pts[i]
        p2 = f_pts[i+1]
        c = (p1 + p2) * 0.5
        v = p2 - p1
        rot = Vector((0,0,1)).rotation_difference(v)
        xform = Matrix.Translation(c) @ rot.to_matrix().to_4x4() @ Matrix.Scale(0.12, 4, Vector((1,0,0))) @ Matrix.Scale(0.012, 4, Vector((0,1,0))) @ Matrix.Scale(v.length * 0.5, 4, Vector((0,0,1)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=xform)
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('FrontFork', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Metal'])
    return obj

def build_wheel_mesh(name, mats, is_front=True):
    # Wheel centered at (0, 0, 0) in local space
    # In Blender: wheel rolls on Y axis, upright along Z, width along X
    mesh = bpy.data.meshes.new(f'{name}_Mesh')
    bm = bmesh.new()
    
    tire_r_outer = 0.35
    tire_r_inner = 0.25
    tire_w = 0.11
    radial_segs = 16
    ring_verts = []
    
    for r_i in range(radial_segs):
        r_ang = r_i * (2.0 * math.pi / radial_segs)
        cy = math.sin(r_ang) * (tire_r_inner + (tire_r_outer - tire_r_inner) * 0.5)
        cz = math.cos(r_ang) * (tire_r_inner + (tire_r_outer - tire_r_inner) * 0.5)
        
        verts = []
        for p_i in range(8):
            p_ang = p_i * (2.0 * math.pi / 8)
            px = math.sin(p_ang) * (tire_w * 0.5)
            dr = (tire_r_outer - tire_r_inner) * 0.5 + math.cos(p_ang) * ((tire_r_outer - tire_r_inner) * 0.48)
            wheel_r = tire_r_inner + dr
            wy = math.sin(r_ang) * wheel_r
            wz = math.cos(r_ang) * wheel_r
            verts.append(bm.verts.new(Vector((px, wy, wz))))
        ring_verts.append(verts)
        
    for r in range(radial_segs):
        r1 = ring_verts[r]
        r2 = ring_verts[(r + 1) % radial_segs]
        for p in range(8):
            p_next = (p + 1) % 8
            bm.faces.new([r1[p], r1[p_next], r2[p_next], r2[p]])
            
    # Knobby 3D Tread Lugs
    lug_w, lug_h, lug_d = 0.030, 0.024, 0.028
    for i in range(20):
        ang = i * (2.0 * math.pi / 20.0)
        stagger = ((i % 3) - 1) * 0.034
        lug_pos = Vector((
            stagger,
            math.sin(ang) * (tire_r_outer + 0.006),
            math.cos(ang) * (tire_r_outer + 0.006)
        ))
        rot_mat = Matrix.Rotation(ang, 4, Vector((1, 0, 0)))
        xform = Matrix.Translation(lug_pos) @ rot_mat @ Matrix.Scale(lug_w, 4, Vector((1,0,0))) @ Matrix.Scale(lug_h, 4, Vector((0,1,0))) @ Matrix.Scale(lug_d, 4, Vector((0,0,1)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=xform)
        
    # Rim Hoop & Hub
    rim_r = 0.25
    bmesh.ops.create_cone(bm, cap_ends=False, segments=16, radius1=rim_r, radius2=rim_r, depth=0.07, matrix=Matrix.Rotation(math.pi*0.5, 4, Vector((0, 1, 0))))
    hub_r = 0.065
    bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=hub_r, radius2=hub_r, depth=0.09, matrix=Matrix.Rotation(math.pi*0.5, 4, Vector((0, 1, 0))))
    
    # Spokes
    for sp_i in range(12):
        ang = sp_i * (2.0 * math.pi / 12.0)
        for side in (-1, 1):
            p_hub = Vector((side * 0.035, math.sin(ang) * hub_r, math.cos(ang) * hub_r))
            p_rim = Vector((side * 0.015, math.sin(ang + 0.26) * rim_r, math.cos(ang + 0.26) * rim_r))
            add_cylinder(bm, p_hub, p_rim, 0.0035, segments=4)
            
    # Floating Brake Rotor
    rotor_x = 0.048
    rotor_r = 0.14 if is_front else 0.12
    bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=rotor_r, radius2=rotor_r, depth=0.006, matrix=Matrix.Translation(Vector((rotor_x, 0, 0))) @ Matrix.Rotation(math.pi*0.5, 4, Vector((0, 1, 0))))
    
    caliper_pos = Vector((rotor_x, rotor_r * 0.75, rotor_r * 0.40))
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(caliper_pos) @ Matrix.Scale(0.04, 4, Vector((1,0,0))) @ Matrix.Scale(0.07, 4, Vector((0,1,0))) @ Matrix.Scale(0.05, 4, Vector((0,0,1))))
    
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Tire'])
    return obj

def build_handlebars(mats):
    mesh = bpy.data.meshes.new('Handlebars_Mesh')
    bm = bmesh.new()
    
    clamp_c = g2b((0, 1.10, -0.50))
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(clamp_c) @ Matrix.Scale(0.12, 4, Vector((1,0,0))) @ Matrix.Scale(0.05, 4, Vector((0,1,0))) @ Matrix.Scale(0.035, 4, Vector((0,0,1))))
    
    hb_center = clamp_c + Vector((0, 0, 0.02))
    for side in (-1, 1):
        hb_mid = g2b((side * 0.22, 1.13, -0.48))
        hb_end = g2b((side * 0.40, 1.12, -0.44))
        add_cylinder(bm, hb_center, hb_mid, 0.013, segments=8)
        add_cylinder(bm, hb_mid, hb_end, 0.013, segments=8)
        
        # Grips
        grip_in = g2b((side * 0.28, 1.125, -0.45))
        add_cylinder(bm, grip_in, hb_end, 0.017, segments=8)
        
        # Handguards
        guard_start = grip_in
        guard_outer = g2b((side * 0.43, 1.16, -0.50))
        guard_end = g2b((side * 0.40, 1.12, -0.40))
        add_cylinder(bm, guard_start, guard_outer, 0.008, segments=6)
        add_cylinder(bm, guard_outer, guard_end, 0.008, segments=6)
        
        # Mirrors (flared for Chinatown Wars elevated camera distance)
        mirror_b = hb_end
        mirror_t = g2b((side * 0.44, 1.25, -0.46))
        add_cylinder(bm, mirror_b, mirror_t, 0.011, segments=8)
        bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=0.048, radius2=0.048, depth=0.016, matrix=Matrix.Translation(mirror_t))
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Handlebars', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Metal'])
    return obj

def build_headlight(mats):
    mesh = bpy.data.meshes.new('Headlight_Mesh')
    bm = bmesh.new()
    
    hl_center = g2b((0, 0.98, -0.70))
    # Bezel facing forward (+Y in Blender)
    bmesh.ops.create_cone(bm, cap_ends=True, segments=14, radius1=0.082, radius2=0.065, depth=0.08, matrix=Matrix.Translation(hl_center) @ Matrix.Rotation(math.pi*0.5, 4, Vector((1, 0, 0))))
    
    # Wire guard
    p1 = hl_center + Vector((-0.075, 0.04, 0))
    p2 = hl_center + Vector((0.075, 0.04, 0))
    add_cylinder(bm, p1, p2, 0.004, segments=4)
    p3 = hl_center + Vector((0, 0.04, -0.075))
    p4 = hl_center + Vector((0, 0.04, 0.075))
    add_cylinder(bm, p3, p4, 0.004, segments=4)
    
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Headlight', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Frame'])

    # Recessed glowing lens emitter
    mesh_lens = bpy.data.meshes.new('HeadlightLens_Mesh')
    bm_lens = bmesh.new()
    lens_center = hl_center + Vector((0, 0.038, 0))
    bmesh.ops.create_cone(bm_lens, cap_ends=True, segments=14, radius1=0.072, radius2=0.072, depth=0.006, matrix=Matrix.Translation(lens_center) @ Matrix.Rotation(math.pi*0.5, 4, Vector((1, 0, 0))))
    bm_lens.to_mesh(mesh_lens)
    bm_lens.free()
    obj_lens = bpy.data.objects.new('HeadlightLens', mesh_lens)
    bpy.context.scene.collection.objects.link(obj_lens)
    obj_lens.data.materials.append(mats['Headlight'])
    obj_lens.parent = obj
    return obj

def build_footpegs(mats):
    mesh = bpy.data.meshes.new('Footpegs_Mesh')
    bm = bmesh.new()
    # Scrambler knurled metal footpegs at Godot coords: Y=0.42, Z=0.08, X=+-0.10 to +-0.22
    for side in (-1, 1):
        p_in = g2b((side * 0.10, 0.42, 0.08))
        p_out = g2b((side * 0.22, 0.42, 0.08))
        add_cylinder(bm, p_in, p_out, 0.016, segments=8)
        p_flange = g2b((side * 0.225, 0.42, 0.08))
        add_cylinder(bm, p_out, p_flange, 0.022, segments=8)
        p_cradle = g2b((side * 0.10, 0.46, 0.14))
        add_cylinder(bm, p_cradle, p_in, 0.014, segments=6)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new('Footpegs', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Metal'])
    return obj


def build_cargo_and_tail(mats):
    mesh = bpy.data.meshes.new('Cargo_Mesh')
    bm = bmesh.new()
    
    rack_c = g2b((0, 0.98, 0.78))
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(rack_c) @ Matrix.Scale(0.26, 4, Vector((1,0,0))) @ Matrix.Scale(0.20, 4, Vector((0,1,0))) @ Matrix.Scale(0.12, 4, Vector((0,0,1))))
    
    for side in (-1, 1):
        strap_c = rack_c + Vector((side * 0.08, 0, 0.062))
        bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(strap_c) @ Matrix.Scale(0.028, 4, Vector((1,0,0))) @ Matrix.Scale(0.21, 4, Vector((0,1,0))) @ Matrix.Scale(0.012, 4, Vector((0,0,1))))
        
    tl_c = g2b((0, 0.88, 0.92))
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(tl_c) @ Matrix.Scale(0.12, 4, Vector((1,0,0))) @ Matrix.Scale(0.03, 4, Vector((0,1,0))) @ Matrix.Scale(0.035, 4, Vector((0,0,1))))
    
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('CargoRack', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Orange'])
    return obj

def build_exhaust(mats):
    mesh = bpy.data.meshes.new('Exhaust_Mesh')
    bm = bmesh.new()
    
    p_pts = [
        g2b((0.08, 0.42, -0.18)),
        g2b((0.14, 0.48, 0.05)),
        g2b((0.16, 0.62, 0.28)),
        g2b((0.15, 0.76, 0.52)),
        g2b((0.14, 0.82, 0.80)),
    ]
    for i in range(len(p_pts) - 1):
        add_cylinder(bm, p_pts[i], p_pts[i+1], 0.024, segments=8)
        
    muffler_c = g2b((0.15, 0.78, 0.62))
    bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=0.046, radius2=0.042, depth=0.34, matrix=Matrix.Translation(muffler_c))
    
    hs_c = g2b((0.175, 0.77, 0.52))
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(hs_c) @ Matrix.Scale(0.012, 4, Vector((1,0,0))) @ Matrix.Scale(0.28, 4, Vector((0,1,0))) @ Matrix.Scale(0.08, 4, Vector((0,0,1))))
    
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new('Exhaust', mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mats['Metal'])
    return obj

def main():
    print("=== Building Low-Poly Courier Bike (FB-13) in Blender 4.3 (Z-up) ===")
    reset_scene()
    mats = setup_materials()
    
    frame = build_chassis_frame(mats)
    skid = build_skid_plate(mats)
    tank = build_fuel_tank(mats)
    seat = build_scrambler_seat(mats)
    battery = build_battery_core(mats)
    forks = build_front_fork_and_fender(mats)
    bars = build_handlebars(mats)
    headlight = build_headlight(mats)
    cargo = build_cargo_and_tail(mats)
    exhaust = build_exhaust(mats)
    pegs = build_footpegs(mats)
    
    # Wheels placed at their true locations in the assembly:
    # Front wheel: Godot (0, 0.35, -0.92) -> Blender (0, 0.92, 0.35)
    # Rear wheel: Godot (0, 0.35, 0.85) -> Blender (0, -0.85, 0.35)
    wheel_front = build_wheel_mesh('WheelFront', mats, is_front=True)
    wheel_front.location = g2b((0, 0.35, -0.92))
    
    wheel_rear = build_wheel_mesh('WheelRear', mats, is_front=False)
    wheel_rear.location = g2b((0, 0.35, 0.85))
    
    # Hierarchy
    tank.parent = frame
    skid.parent = frame
    seat.parent = frame
    battery.parent = frame
    pegs.parent = frame
    forks.parent = frame
    bars.parent = forks
    headlight.parent = forks
    wheel_front.parent = forks
    wheel_rear.parent = frame
    cargo.parent = frame
    exhaust.parent = frame
    
    os.makedirs("models_source", exist_ok=True)
    out_blend = "models_source/courier_bike.blend"
    bpy.ops.wm.save_as_mainfile(filepath=out_blend)
    print(f"Saved .blend project to: {out_blend}")
    
    out_glb = "godot/models/courier_bike.glb"
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_materials='EXPORT'
    )
    print(f"Exported clean glTF 2.0 to: {out_glb}")
    print("=== Courier Bike Build Complete ===")

if __name__ == '__main__':
    main()
