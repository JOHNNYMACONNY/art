#!/usr/bin/env python3
"""
scripts/test_render_tactical_hand.py
Tests generating and rendering the tactical glove hand in Blender on CharacterArmature.
"""

import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion, Euler
import math
import sys, os
sys.path.append(os.path.abspath('scripts'))
from generate_clean_hand import build_manifold_hand

def run():
    bpy.ops.wm.open_mainfile(filepath='models_source/runner.blend')
    scene = bpy.context.scene
    arm_obj = bpy.data.objects['CharacterArmature']
    
    # Set armature to REST pose so we inspect pure geometry
    arm_obj.data.pose_position = 'REST'
    
    bm, vg_indices = build_manifold_hand(arm_obj, 'L')
    
    # Create new mesh object for tactical hand
    hand_mesh = bpy.data.meshes.new("TacticalHand_L")
    bm.to_mesh(hand_mesh)
    bm.free()
    
    hand_obj = bpy.data.objects.new("TacticalHand_L", hand_mesh)
    scene.collection.objects.link(hand_obj)
    hand_obj.matrix_world = arm_obj.matrix_world.copy()
    
    # Add armature modifier
    mod = hand_obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj
    
    # Assign vertex groups
    for bname, indices in vg_indices.items():
        if indices:
            vg = hand_obj.vertex_groups.new(name=bname)
            vg.add(indices, 1.0, 'REPLACE')
            
    print(f"Tactical hand created: {len(hand_mesh.vertices)} verts, {len(hand_mesh.polygons)} polys")
    
    # Setup Camera looking right at Left Hand
    hand_center_local = Vector((0.70, -0.09, 1.43))
    hand_center_world = arm_obj.matrix_world @ hand_center_local
    
    cam_data = bpy.data.cameras.new('TestCam')
    cam_obj = bpy.data.objects.new('TestCam', cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    
    # Camera looking at back of hand / knuckles
    cam_obj.location = hand_center_world + Vector((0.0, -0.40, 0.25))
    direction = (hand_center_world - cam_obj.location).normalized()
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    
    # Setup lighting
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 32
    
    world = bpy.data.worlds.new('World')
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (0.75, 0.77, 0.80, 1.0)
    bg.inputs['Strength'].default_value = 1.0
    
    scene.render.image_settings.file_format = 'PNG'
    scene.render.filepath = '/Users/bobbyinthelobby/{art/docs/visual_direction/references/tactical_hand_rest_test.png'
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    
    # Hide Runner_Mesh so only TacticalHand is visible
    bpy.data.objects['Runner_Mesh'].hide_render = True
    
    bpy.ops.render.render(write_still=True)
    print("Rendered tactical_hand_rest_test.png")

if __name__ == '__main__':
    run()
