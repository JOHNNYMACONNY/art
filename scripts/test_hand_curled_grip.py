#!/usr/bin/env python3
"""
scripts/test_hand_curled_grip.py
Tests the tactical glove hand deforming around a steering wheel rim in Blender.
"""

import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion, Euler
import math
import sys, os
sys.path.append(os.path.abspath('scripts'))
from test_airtight_hand import build_airtight_hand

def run():
    bpy.ops.wm.open_mainfile(filepath='models_source/runner.blend')
    scene = bpy.context.scene
    arm_obj = bpy.data.objects['CharacterArmature']
    
    # Hide original runner mesh
    bpy.data.objects['Runner_Mesh'].hide_render = True
    
    # Build airtight tactical hand
    bm, vg_indices = build_airtight_hand(arm_obj, 'L')
    
    hand_mesh = bpy.data.meshes.new("TacticalHand_L")
    bm.to_mesh(hand_mesh)
    bm.free()
    
    hand_obj = bpy.data.objects.new("TacticalHand_L", hand_mesh)
    scene.collection.objects.link(hand_obj)
    hand_obj.matrix_world = arm_obj.matrix_world.copy()
    
    # Add armature modifier
    mod = hand_obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj
    
    for bname, indices in vg_indices.items():
        if indices:
            vg = hand_obj.vertex_groups.new(name=bname)
            vg.add(indices, 1.0, 'REPLACE')
            
    # Assign tactical material to hand
    mat_main = bpy.data.materials.get('Mat_RunnerMain')
    if mat_main:
        hand_obj.data.materials.append(mat_main)
        
    # Pose the fingers in POSE mode to curl around a steering wheel rim
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='POSE')
    
    # Natural curling angles around 3cm tube (in radians)
    # Pitch rotation around bone local X axis:
    # MCP knuckle: ~45 deg, PIP joint: ~60 deg, DIP joint: ~45 deg
    curl_angles = {
        'Index2.L':  Euler((math.radians(-42.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Index3.L':  Euler((math.radians(-55.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Index4.L':  Euler((math.radians(-40.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Middle2.L': Euler((math.radians(-44.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Middle3.L': Euler((math.radians(-58.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Middle4.L': Euler((math.radians(-40.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Ring2.L':   Euler((math.radians(-45.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Ring3.L':   Euler((math.radians(-55.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Ring4.L':   Euler((math.radians(-40.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Pinky2.L':  Euler((math.radians(-42.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Pinky3.L':  Euler((math.radians(-52.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Pinky4.L':  Euler((math.radians(-38.0), 0.0, 0.0), 'XYZ').to_quaternion(),
        'Thumb2.L':  Euler((math.radians(15.0), math.radians(-25.0), math.radians(20.0)), 'XYZ').to_quaternion(),
        'Thumb3.L':  Euler((math.radians(-30.0), 0.0, 0.0), 'XYZ').to_quaternion(),
    }
    
    for bname, q in curl_angles.items():
        pb = arm_obj.pose.bones.get(bname)
        if pb:
            pb.rotation_mode = 'QUATERNION'
            pb.rotation_quaternion = q
            
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Add a visual steering wheel rim section (torus) inside the curling grip
    # Place torus right through the finger curl
    mid2_pb = arm_obj.pose.bones['Middle2.L']
    knuckle_pos = arm_obj.matrix_world @ mid2_pb.head
    
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.165,
        minor_radius=0.015,
        major_segments=36,
        minor_segments=16,
        location=knuckle_pos + Vector((-0.06, 0.02, -0.06)),
        rotation=Euler((math.radians(65.0), 0.0, math.radians(-25.0)), 'XYZ')
    )
    wheel_obj = bpy.context.active_object
    wheel_obj.name = "SteeringWheel_Ref"
    
    # Camera looking directly at the grip
    cam_data = bpy.data.cameras.new('GripCam')
    cam_obj = bpy.data.objects.new('GripCam', cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    
    cam_obj.location = knuckle_pos + Vector((-0.10, -0.32, 0.12))
    direction = (knuckle_pos - cam_obj.location).normalized()
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    
    # Lighting
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 32
    
    world = bpy.data.worlds.new('World')
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.22, 0.24, 0.28, 1.0)
    bg.inputs['Strength'].default_value = 0.8
    
    # Key light
    light_data = bpy.data.lights.new('KeyLight', 'SUN')
    light_data.energy = 2.5
    light_obj = bpy.data.objects.new('KeyLight', light_data)
    scene.collection.objects.link(light_obj)
    light_obj.rotation_euler = Euler((math.radians(-45.0), math.radians(35.0), 0.0), 'XYZ')
    
    scene.render.image_settings.file_format = 'PNG'
    scene.render.filepath = '/Users/bobbyinthelobby/{art/docs/visual_direction/references/tactical_hand_wheel_grip.png'
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    
    bpy.ops.render.render(write_still=True)
    print("Rendered tactical_hand_wheel_grip.png")

if __name__ == '__main__':
    run()
