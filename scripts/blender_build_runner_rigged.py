#!/usr/bin/env python3
"""
scripts/blender_build_runner_rigged.py
Builds the rigged, skinned, skeletally-animated Near-Future Sci-Fi GTA Courier Runner (HS-7)
in Blender 4.3.2.
Integrates clean low-poly athletic humanoid topology with authentic techwear courier gear
and exports a single unified glTF (godot/models/runner.glb) containing:
- CharacterArmature / Skeleton3D
- Skinned continuous runner mesh with clean continuous atlas UVs
- 3 material slots: Mat_RunnerMain, Mat_RunnerVisor (cyan emission), Mat_RunnerComm (cyan emission)
- Full animation library: 'idle', 'walk', 'run', 'bike_ride'
"""

import bpy
import bmesh
from mathutils import Vector, Euler, Matrix, Quaternion
import math
import os

UV_BOXES = {
    'jacket_body':   (41/2048.0, 573/2048.0, 1.0 - 778/2048.0, 1.0 - 41/2048.0),
    'inner_tee':     (614/2048.0, 983/2048.0, 1.0 - 410/2048.0, 1.0 - 41/2048.0),
    'caution_org':   (1024/2048.0, 1393/2048.0, 1.0 - 410/2048.0, 1.0 - 41/2048.0),
    'skin':          (1434/2048.0, 1802/2048.0, 1.0 - 410/2048.0, 1.0 - 41/2048.0),
    'hair':          (41/2048.0, 410/2048.0, 1.0 - 1188/2048.0, 1.0 - 819/2048.0),
    'metal':         (451/2048.0, 778/2048.0, 1.0 - 1188/2048.0, 1.0 - 819/2048.0),
    'pants':         (819/2048.0, 1393/2048.0, 1.0 - 1188/2048.0, 1.0 - 451/2048.0),
    'sneaker_mid':   (1434/2048.0, 2007/2048.0, 1.0 - 778/2048.0, 1.0 - 451/2048.0),
    'sneaker_tread': (1434/2048.0, 2007/2048.0, 1.0 - 1188/2048.0, 1.0 - 819/2048.0),
    'satchel':       (41/2048.0, 983/2048.0, 1.0 - 2007/2048.0, 1.0 - 1229/2048.0),
    'dorsal_spine':  (1024/2048.0, 1475/2048.0, 1.0 - 2007/2048.0, 1.0 - 1229/2048.0),
    'comm_hud':      (1516/2048.0, 2007/2048.0, 1.0 - 1741/2048.0, 1.0 - 1229/2048.0),
    'visor_hud':     (1516/2048.0, 2007/2048.0, 1.0 - 2007/2048.0, 1.0 - 1761/2048.0),
}

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_atlas_material(name, atlas_path, emission_energy=0.0):
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
            node_bsdf.inputs['Emission Color'].default_value = (0.0, 0.92, 1.0, 1.0)
            node_bsdf.inputs['Emission Strength'].default_value = emission_energy

    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def create_box_mesh(name, size, pos, rot=(0,0,0), uv_key='jacket_body', weights={}, mat=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    
    for v in bm.verts:
        v.co.x *= size[0] * 0.5
        v.co.y *= size[1] * 0.5
        v.co.z *= size[2] * 0.5
        
    if rot != (0, 0, 0):
        rot_mat = Euler(rot, 'XYZ').to_matrix().to_4x4()
        for v in bm.verts:
            v.co = rot_mat @ v.co
            
    for v in bm.verts:
        v.co.x += pos[0]
        v.co.y += pos[1]
        v.co.z += pos[2]
        
    uv_layer = bm.loops.layers.uv.new("UVMap")
    u1, u2, v1, v2 = UV_BOXES[uv_key]
    
    min_x = pos[0] - size[0] * 0.5
    max_x = pos[0] + size[0] * 0.5
    min_z = pos[2] - size[2] * 0.5
    max_z = pos[2] + size[2] * 0.5
    dx = max(max_x - min_x, 0.001)
    dz = max(max_z - min_z, 0.001)

    for f in bm.faces:
        f.material_index = 0
        is_front = (f.normal.y < -0.3) or ('satchel' in uv_key and f.normal.y < 0.3) or ('visor' in uv_key) or ('comm' in uv_key)
        for l in f.loops:
            if is_front:
                nx = (l.vert.co.x - min_x) / dx
                nz = (l.vert.co.z - min_z) / dz
                nx = min(max(nx, 0.0), 1.0)
                nz = min(max(nz, 0.0), 1.0)
                l[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
            else:
                # Solid matte charcoal padding
                l[uv_layer].uv = (0.05, 0.95)

    mesh_data = bpy.data.meshes.new(name)
    bm.to_mesh(mesh_data)
    bm.free()

    obj = bpy.data.objects.new(name, mesh_data)
    bpy.context.scene.collection.objects.link(obj)
    if mat:
        obj.data.materials.append(mat)

    for bname, w in weights.items():
        vg = obj.vertex_groups.new(name=bname)
        for v in obj.data.vertices:
            vg.add([v.index], w, 'REPLACE')

    return obj

def re_uv_base_mesh(obj, mat_main):
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv_layer = mesh.uv_layers.active

    is_head = "Head" in obj.name
    is_body = "Body" in obj.name
    is_legs = "Legs" in obj.name
    is_feet = "Feet" in obj.name

    for poly in mesh.polygons:
        center = poly.center
        normal = poly.normal
        mname = obj.material_slots[poly.material_index].name if obj.material_slots else ""

        if is_head:
            if 'Hair' in mname or center.z > 1.74 or (center.y > 0.02 and center.z > 1.68):
                # Hair: clean solid dark hair region
                u1, u2, v1, v2 = UV_BOXES['hair']
                for loop_idx in poly.loop_indices:
                    uv_layer.data[loop_idx].uv = (u1 + 0.5 * (u2 - u1), v1 + 0.5 * (v2 - v1))
            else:
                # Face / Skin: smooth continuous projection across face
                u1, u2, v1, v2 = UV_BOXES['skin']
                for loop_idx in poly.loop_indices:
                    v_co = mesh.vertices[mesh.loops[loop_idx].vertex_index].co
                    u_norm = min(max((v_co.x - (-0.10)) / 0.20, 0.0), 1.0)
                    v_norm = min(max((v_co.z - 1.50) / 0.25, 0.0), 1.0)
                    uv_layer.data[loop_idx].uv = (u1 + u_norm * (u2 - u1), v1 + v_norm * (v2 - v1))

        elif is_body:
            if abs(center.x) > 0.65:
                # Hands
                if normal.y > 0.3 or center.z > 1.42:
                    # Knuckle armor
                    u1, u2, v1, v2 = UV_BOXES['metal']
                    for loop_idx in poly.loop_indices:
                        uv_layer.data[loop_idx].uv = (u1 + 0.5 * (u2 - u1), v1 + 0.5 * (v2 - v1))
                else:
                    # Skin palm / fingers
                    u1, u2, v1, v2 = UV_BOXES['skin']
                    for loop_idx in poly.loop_indices:
                        uv_layer.data[loop_idx].uv = (u1 + 0.5 * (u2 - u1), v1 + 0.5 * (v2 - v1))

            elif abs(center.x) > 0.20:
                # Sleeves: solid matte charcoal techwear fabric (zero stripes!)
                for loop_idx in poly.loop_indices:
                    uv_layer.data[loop_idx].uv = (0.05, 0.95)

            else:
                # Torso
                if normal.y < -0.15:
                    # Front of jacket: continuous mapping from right (-0.20) to left (+0.20)
                    if center.z > 1.44 and abs(center.x) < 0.06:
                        # Throat V-notch undershirt
                        u1, u2, v1, v2 = UV_BOXES['inner_tee']
                        for loop_idx in poly.loop_indices:
                            uv_layer.data[loop_idx].uv = (u1 + 0.5 * (u2 - u1), v1 + 0.5 * (v2 - v1))
                    else:
                        # Front jacket shell with single center zipper track & GEARS-01 patch
                        u1, u2, v1, v2 = UV_BOXES['jacket_body']
                        for loop_idx in poly.loop_indices:
                            v_co = mesh.vertices[mesh.loops[loop_idx].vertex_index].co
                            u_norm = min(max((v_co.x - (-0.20)) / 0.40, 0.0), 1.0)
                            v_norm = min(max((v_co.z - 1.02) / 0.46, 0.0), 1.0)
                            uv_layer.data[loop_idx].uv = (u1 + u_norm * (u2 - u1), v1 + v_norm * (v2 - v1))

                elif normal.y > 0.15:
                    # Back of jacket: continuous dorsal spine mapping with HS-7 and caution chevrons
                    u1, u2, v1, v2 = UV_BOXES['dorsal_spine']
                    for loop_idx in poly.loop_indices:
                        v_co = mesh.vertices[mesh.loops[loop_idx].vertex_index].co
                        # Flip X for rear view so HS-7 and chevrons align down center spine
                        u_norm = min(max((0.20 - v_co.x) / 0.40, 0.0), 1.0)
                        v_norm = min(max((v_co.z - 1.02) / 0.46, 0.0), 1.0)
                        uv_layer.data[loop_idx].uv = (u1 + u_norm * (u2 - u1), v1 + v_norm * (v2 - v1))
                else:
                    # Torso sides: solid matte charcoal
                    for loop_idx in poly.loop_indices:
                        uv_layer.data[loop_idx].uv = (0.05, 0.95)

        elif is_legs:
            # Cargo pants: solid charcoal cargo fabric (zero pattern noise!)
            u1, u2, v1, v2 = UV_BOXES['pants']
            for loop_idx in poly.loop_indices:
                uv_layer.data[loop_idx].uv = (u1 + 0.15 * (u2 - u1), v1 + 0.15 * (v2 - v1))

        elif is_feet:
            if normal.z < -0.5 or center.z < 0.025:
                # Soles: caution orange lug treads
                u1, u2, v1, v2 = UV_BOXES['sneaker_tread']
                for loop_idx in poly.loop_indices:
                    uv_layer.data[loop_idx].uv = (u1 + 0.5 * (u2 - u1), v1 + 0.5 * (v2 - v1))
            elif center.z < 0.08:
                # Midsoles: off-white Vibram midsole
                u1, u2, v1, v2 = UV_BOXES['sneaker_mid']
                for loop_idx in poly.loop_indices:
                    uv_layer.data[loop_idx].uv = (u1 + 0.5 * (u2 - u1), v1 + 0.5 * (v2 - v1))
            else:
                # Sneaker collar: matte charcoal
                for loop_idx in poly.loop_indices:
                    uv_layer.data[loop_idx].uv = (0.05, 0.95)

        poly.material_index = 0

    obj.data.materials.clear()
    obj.data.materials.append(mat_main)

def create_bike_ride_action(arm):
    """Creates an authentic scrambler motorcycle riding action matching Courier Bike ergonomics."""
    if not arm.animation_data:
        arm.animation_data_create()
    act = bpy.data.actions.new(name="bike_ride")
    arm.animation_data.action = act

    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='POSE')

    # Courier Bike dimensions in Blender coordinates:
    # Seat height: Z ~ 0.86m (lower Hips by 0.16m, Y forward 0.08m)
    # Pitch Hips forward 22 deg
    # Arch spine forward over tank
    # Flared thighs hugging tank, knees bent back, feet resting on footpegs

    for frame in [1, 15, 30]:
        bpy.context.scene.frame_set(frame)
        rumble = 0.003 if frame == 15 else 0.0

        # Hips: seated and pitched forward
        pb = arm.pose.bones.get('Hips')
        if pb:
            pb.location = Vector((0.0, 0.08, -0.16 + rumble))
            pb.rotation_mode = 'QUATERNION'
            pb.rotation_quaternion = Euler((math.radians(22.0), 0.0, 0.0), 'XYZ').to_quaternion()
            pb.keyframe_insert(data_path="location", frame=frame)
            pb.keyframe_insert(data_path="rotation_quaternion", frame=frame)

        # Spine / Chest: hunched forward over tank
        for bname, pitch in [('Abdomen', 14.0), ('Torso', 16.0), ('Chest', 12.0)]:
            pb = arm.pose.bones.get(bname)
            if pb:
                pb.rotation_mode = 'QUATERNION'
                pb.rotation_quaternion = Euler((math.radians(pitch), 0.0, 0.0), 'XYZ').to_quaternion()
                pb.keyframe_insert(data_path="rotation_quaternion", frame=frame)

        # Neck / Head: tilted up looking straight down the road
        pb = arm.pose.bones.get('Head')
        if pb:
            pb.rotation_mode = 'QUATERNION'
            pb.rotation_quaternion = Euler((math.radians(-32.0), 0.0, 0.0), 'XYZ').to_quaternion()
            pb.keyframe_insert(data_path="rotation_quaternion", frame=frame)

        # Legs: hugging scrambler chassis, feet on pegs
        # Left Leg
        arm.pose.bones['UpperLeg.L'].rotation_quaternion = Quaternion((0.8322, -0.1234, -0.0537, 0.5379))
        arm.pose.bones['LowerLeg.L'].rotation_quaternion = Quaternion((0.6874, 0.7222, -0.0525, -0.0560))
        arm.pose.bones['Foot.L'].rotation_quaternion = Quaternion((0.9954, -0.0860, 0.0284, -0.0319))
        arm.pose.bones['UpperLeg.L'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['LowerLeg.L'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['Foot.L'].keyframe_insert(data_path="rotation_quaternion", frame=frame)

        # Right Leg (symmetric)
        arm.pose.bones['UpperLeg.R'].rotation_quaternion = Quaternion((0.8322, -0.1234, 0.0537, -0.5379))
        arm.pose.bones['LowerLeg.R'].rotation_quaternion = Quaternion((0.6874, 0.7222, 0.0525, 0.0560))
        arm.pose.bones['Foot.R'].rotation_quaternion = Quaternion((0.9954, -0.0860, -0.0284, 0.0319))
        arm.pose.bones['UpperLeg.R'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['LowerLeg.R'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['Foot.R'].keyframe_insert(data_path="rotation_quaternion", frame=frame)

        # Arms: reach forward to scrambler handlebars (x = +/-0.35m)
        q_base_l = Quaternion((0.8585, -0.2801, -0.0938, -0.4191))
        q_spread_l = Euler((0, math.radians(-15), math.radians(18)), 'XYZ').to_quaternion()
        arm.pose.bones['UpperArm.L'].rotation_quaternion = q_base_l @ q_spread_l
        arm.pose.bones['LowerArm.L'].rotation_quaternion = Quaternion((0.7549, -0.0064, 0.0, -0.6559))
        arm.pose.bones['Hand.L'].rotation_quaternion = Quaternion((0.9737, 0.2275, -0.0093, 0.0058))
        arm.pose.bones['UpperArm.L'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['LowerArm.L'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['Hand.L'].keyframe_insert(data_path="rotation_quaternion", frame=frame)

        q_base_r = Quaternion((0.8585, -0.2801, 0.0938, 0.4191))
        q_spread_r = Euler((0, math.radians(15), math.radians(-18)), 'XYZ').to_quaternion()
        arm.pose.bones['UpperArm.R'].rotation_quaternion = q_base_r @ q_spread_r
        arm.pose.bones['LowerArm.R'].rotation_quaternion = Quaternion((0.7549, -0.0064, -0.0, 0.6559))
        arm.pose.bones['Hand.R'].rotation_quaternion = Quaternion((0.9737, 0.2275, 0.0093, -0.0058))
        arm.pose.bones['UpperArm.R'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['LowerArm.R'].keyframe_insert(data_path="rotation_quaternion", frame=frame)
        arm.pose.bones['Hand.R'].keyframe_insert(data_path="rotation_quaternion", frame=frame)

    bpy.ops.object.mode_set(mode='OBJECT')
    return act

def main():
    print("=== Building Rigged, Skinned, Skeletally-Animated Sci-Fi GTA Runner ===")
    reset_scene()

    atlas_path = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter/tex_runner_atlas.png"
    mat_main = create_atlas_material("Mat_RunnerMain", atlas_path, emission_energy=0.0)
    mat_visor = create_atlas_material("Mat_RunnerVisor", atlas_path, emission_energy=2.8)
    mat_comm = create_atlas_material("Mat_RunnerComm", atlas_path, emission_energy=2.8)

    # 1. Import base character
    bpy.ops.import_scene.fbx(filepath='assets/mixamo/character.fbx')
    char_arm = bpy.data.objects['CharacterArmature']
    char_arm.location = (0, 0, 0)
    char_arm.rotation_euler = (0, 0, 0)
    char_arm.scale = (1, 1, 1)

    base_meshes = [obj for obj in bpy.data.objects if obj.type == 'MESH']
    for m in base_meshes:
        re_uv_base_mesh(m, mat_main)

    # 2. Add Techwear Accessories
    accessories = []

    # AR Smart Glasses & Cyan Visor
    glasses_frame = create_box_mesh("Runner_GlassesFrame", (0.17, 0.04, 0.035), (0, -0.138, 1.68), uv_key='metal', weights={'Head': 1.0}, mat=mat_main)
    visor_lens = create_box_mesh("Runner_VisorLens", (0.16, 0.015, 0.030), (0, -0.155, 1.68), uv_key='visor_hud', weights={'Head': 1.0}, mat=mat_visor)
    accessories.extend([glasses_frame, visor_lens])

    # Messy Spiky Hair Fringe
    spikes_def = [
        ((0.04, 0.06, 0.07), (0.00, -0.13, 1.76), (0.35, 0, 0)),
        ((0.035, 0.055, 0.065), (0.04, -0.125, 1.75), (0.30, 0.20, -0.15)),
        ((0.035, 0.055, 0.065), (-0.04, -0.125, 1.75), (0.30, -0.20, 0.15)),
        ((0.03, 0.05, 0.06), (0.075, -0.10, 1.73), (0.25, 0.35, -0.30)),
        ((0.03, 0.05, 0.06), (-0.075, -0.10, 1.73), (0.25, -0.35, 0.30)),
    ]
    for i, (sz, p, r) in enumerate(spikes_def):
        spk = create_box_mesh(f"Runner_HairSpike_{i}", sz, p, rot=r, uv_key='hair', weights={'Head': 1.0}, mat=mat_main)
        accessories.append(spk)

    # Comms Headset & Boom Mic
    earpiece = create_box_mesh("Runner_CommsEar", (0.03, 0.04, 0.04), (0.095, -0.01, 1.66), uv_key='metal', weights={'Head': 1.0}, mat=mat_main)
    boom_mic = create_box_mesh("Runner_CommsMic", (0.015, 0.08, 0.015), (0.085, -0.07, 1.61), rot=(0.30, 0, 0.20), uv_key='metal', weights={'Head': 1.0}, mat=mat_main)
    accessories.extend([earpiece, boom_mic])

    # Open Storm Collar Shell & Folded Orange Lapels
    collar = create_box_mesh("Runner_StormCollar", (0.22, 0.18, 0.12), (0, -0.03, 1.54), uv_key='jacket_body', weights={'Chest': 0.7, 'Neck': 0.3}, mat=mat_main)
    lapel_l = create_box_mesh("Runner_Lapel_L", (0.04, 0.02, 0.10), (0.055, -0.135, 1.48), rot=(-0.15, 0.20, -0.25), uv_key='caution_org', weights={'Chest': 1.0}, mat=mat_main)
    lapel_r = create_box_mesh("Runner_Lapel_R", (0.04, 0.02, 0.10), (-0.055, -0.135, 1.48), rot=(-0.15, -0.20, 0.25), uv_key='caution_org', weights={'Chest': 1.0}, mat=mat_main)
    accessories.extend([collar, lapel_l, lapel_r])

    # Tactical Webbing Sling & Cobra Buckle
    sling = create_box_mesh("Runner_Sling", (0.045, 0.015, 0.36), (-0.01, -0.125, 1.30), rot=(0.15, 0, -0.55), uv_key='inner_tee', weights={'Chest': 1.0}, mat=mat_main)
    buckle = create_box_mesh("Runner_CobraBuckle", (0.055, 0.025, 0.055), (-0.02, -0.135, 1.32), rot=(0.15, 0, -0.55), uv_key='metal', weights={'Chest': 1.0}, mat=mat_main)
    accessories.extend([sling, buckle])

    # Rear-Left Flank Courier Satchel (>18cm clear of left arm)
    satchel = create_box_mesh("Runner_Satchel", (0.24, 0.11, 0.18), (0.21, 0.14, 0.96), rot=(-0.10, 0.18, -0.15), uv_key='satchel', weights={'Torso': 0.6, 'Hips': 0.4}, mat=mat_main)
    accessories.append(satchel)

    # Left Forearm Cyber-Comm
    comm_box = create_box_mesh("Runner_CommBox", (0.08, 0.05, 0.035), (0.42, -0.05, 1.43), uv_key='metal', weights={'LowerArm.L': 1.0}, mat=mat_main)
    comm_screen = create_box_mesh("Runner_CommScreen", (0.07, 0.04, 0.015), (0.42, -0.05, 1.455), uv_key='comm_hud', weights={'LowerArm.L': 1.0}, mat=mat_comm)
    accessories.extend([comm_box, comm_screen])

    # Thigh Cargo Pockets
    cargo_l = create_box_mesh("Runner_Cargo_L", (0.055, 0.13, 0.14), (0.18, -0.05, 0.74), rot=(0.05, 0, -0.08), uv_key='pants', weights={'UpperLeg.L': 1.0}, mat=mat_main)
    cargo_r = create_box_mesh("Runner_Cargo_R", (0.055, 0.13, 0.14), (-0.18, -0.05, 0.74), rot=(0.05, 0, 0.08), uv_key='pants', weights={'UpperLeg.R': 1.0}, mat=mat_main)
    accessories.extend([cargo_l, cargo_r])

    # Articulated Knee Armor Plates
    knee_l = create_box_mesh("Runner_Knee_L", (0.09, 0.045, 0.11), (0.12, -0.10, 0.52), rot=(0.10, 0, 0), uv_key='pants', weights={'LowerLeg.L': 1.0}, mat=mat_main)
    knee_r = create_box_mesh("Runner_Knee_R", (0.09, 0.045, 0.11), (-0.12, -0.10, 0.52), rot=(0.10, 0, 0), uv_key='pants', weights={'LowerLeg.R': 1.0}, mat=mat_main)
    accessories.extend([knee_l, knee_r])

    # Chunky Sneaker Outsoles
    sole_l = create_box_mesh("Runner_Sole_L", (0.11, 0.22, 0.025), (0.12, -0.10, 0.012), uv_key='sneaker_tread', weights={'Foot.L': 1.0}, mat=mat_main)
    sole_r = create_box_mesh("Runner_Sole_R", (0.11, 0.22, 0.025), (-0.12, -0.10, 0.012), uv_key='sneaker_tread', weights={'Foot.R': 1.0}, mat=mat_main)
    accessories.extend([sole_l, sole_r])

    # 3. Join all meshes into a unified skinned character mesh
    all_meshes = base_meshes + accessories
    bpy.ops.object.select_all(action='DESELECT')
    for m in all_meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = all_meshes[0]
    bpy.ops.object.join()

    runner_mesh = bpy.context.active_object
    runner_mesh.name = "Runner_Mesh"

    print("Joined material slots:", [s.name for s in runner_mesh.material_slots])

    # Ensure Armature modifier points to char_arm
    arm_mod = None
    for mod in runner_mesh.modifiers:
        if mod.type == 'ARMATURE':
            arm_mod = mod
            break
    if not arm_mod:
        arm_mod = runner_mesh.modifiers.new(name="Armature", type='ARMATURE')
    arm_mod.object = char_arm

    # 4. Import & process Animations
    # Walk
    bpy.ops.import_scene.fbx(filepath='assets/mixamo/walk.fbx')
    walk_act = [a for a in bpy.data.actions if 'walk' in a.name.lower() or 'mixamo' in a.name.lower()][0]
    walk_act.name = "walk"
    for fc in walk_act.fcurves:
        if fc.data_path == 'location' and fc.array_index == 1:
            for kp in fc.keyframe_points:
                kp.co[1] = 0.0
                kp.handle_left[1] = 0.0
                kp.handle_right[1] = 0.0

    # Run
    bpy.ops.import_scene.fbx(filepath='assets/mixamo/run.fbx')
    run_act = [a for a in bpy.data.actions if 'mixamo' in a.name.lower() and a != walk_act][0]
    run_act.name = "run"
    for fc in run_act.fcurves:
        if fc.data_path == 'location' and fc.array_index == 1:
            for kp in fc.keyframe_points:
                kp.co[1] = 0.0
                kp.handle_left[1] = 0.0
                kp.handle_right[1] = 0.0

    # Idle
    bpy.ops.import_scene.fbx(filepath='assets/mixamo/idle.fbx')
    idle_act = [a for a in bpy.data.actions if 'mixamo' in a.name.lower() and a not in (walk_act, run_act)][0]
    idle_act.name = "idle"

    # Remove extra imported armatures
    extra_arms = [obj for obj in bpy.data.objects if obj.type == 'ARMATURE' and obj != char_arm]
    for obj in extra_arms:
        bpy.data.objects.remove(obj, do_unlink=True)

    # Bike Ride
    bike_act = create_bike_ride_action(char_arm)

    # Push all actions onto NLA tracks on char_arm
    if not char_arm.animation_data:
        char_arm.animation_data_create()

    actions = [idle_act, walk_act, run_act, bike_act]
    for act in actions:
        track = char_arm.animation_data.nla_tracks.new()
        track.name = act.name
        strip = track.strips.new(act.name, int(act.frame_range[0]), act)
        strip.action = act

    char_arm.animation_data.action = idle_act

    # Save .blend project
    os.makedirs("models_source", exist_ok=True)
    out_blend = "models_source/runner.blend"
    bpy.ops.wm.save_as_mainfile(filepath=out_blend)
    print(f"Saved .blend project to: {out_blend}")

    # 5. Export glTF 2.0
    out_glb = "godot/models/runner.glb"
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        export_format='GLB',
        use_selection=False,
        export_skins=True,
        export_animations=True,
        export_apply=False,
        export_materials='EXPORT'
    )
    print(f"Exported rigged animated runner to: {out_glb}")
    print("=== Rigged Runner Build Successful! ===")

if __name__ == '__main__':
    main()
