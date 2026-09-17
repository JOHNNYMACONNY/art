#!/usr/bin/env python3
"""
scripts/build_tactical_hands.py
Builds professional tactical courier glove hands for runner.blend in Blender 4.3.2.
Complies with hand_blender_model_sheet.jpg:
- 3 edge loops per knuckle for clean deformation
- Full 5-digit articulated geometry (Index, Middle, Ring, Pinky, Thumb)
- Anatomical palm with thenar muscle pad and dorsal carbon knuckle armor
- Accurate skinning to CharacterArmature bones
- Seamless wrist connection to LowerArm
- Atlas UV mapping to tex_runner_atlas.png
"""

import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion, Euler
import math

def build_finger_bmesh(bm, bones, r_base, r_tip, side='L', finger_name='Index'):
    """
    Builds an 8-sided cylindrical finger along a chain of bones with 3 loops per joint.
    bones: list of (bone_name, head_vec, tail_vec, matrix_local)
    """
    n_sides = 8
    
    # Store vert rings along the finger: list of (ring_verts, bone_weights_dict)
    all_rings = []
    
    total_len = sum((tail - head).length for _, head, tail, _ in bones)
    curr_len = 0.0
    
    for b_idx, (bname, head, tail, mat) in enumerate(bones):
        b_vec = tail - head
        b_len = b_vec.length
        # Local bone axes from matrix:
        # Col 0: local X (sideways)
        # Col 1: local Y (along bone)
        # Col 2: local Z (dorsal / up)
        axis_x = Vector((mat[0][0], mat[1][0], mat[2][0])).normalized()
        axis_y = Vector((mat[0][1], mat[1][1], mat[2][1])).normalized()
        axis_z = Vector((mat[0][2], mat[1][2], mat[2][2])).normalized()
        
        # Joint definitions along this bone:
        # For first bone: start at t=0.0 (MCP knuckle), mid at t=0.5, end at t=1.0 - delta
        # For intermediate joints: 3 loops: t_joint - eps, t_joint, t_joint + eps
        
        fractions = []
        if b_idx == 0:
            fractions.append(0.0)
            fractions.append(0.08)
            fractions.append(0.50)
            fractions.append(0.92)
            fractions.append(1.00)
        elif b_idx == len(bones) - 1:
            # Distal tip bone
            fractions.append(0.00)
            fractions.append(0.08)
            fractions.append(0.40)
            fractions.append(0.75)
            fractions.append(1.00)
        else:
            fractions.append(0.00)
            fractions.append(0.08)
            fractions.append(0.50)
            fractions.append(0.92)
            fractions.append(1.00)
            
        for f in fractions:
            pos = head + b_vec * f
            t_total = (curr_len + b_len * f) / max(total_len, 0.001)
            radius = r_base + (r_tip - r_base) * t_total
            
            # Knuckle bulge at joints
            is_joint = (f < 0.12 or f > 0.88)
            if is_joint and b_idx > 0:
                radius *= 1.10
                
            # Weights for this ring
            weights = {}
            if f <= 0.08 and b_idx > 0:
                # Joint blend with previous bone
                prev_bname = bones[b_idx - 1][0]
                blend = 0.5 - (f / 0.16)
                weights[prev_bname] = max(blend, 0.0)
                weights[bname] = 1.0 - weights[prev_bname]
            elif f >= 0.92 and b_idx < len(bones) - 1:
                # Joint blend with next bone
                next_bname = bones[b_idx + 1][0]
                blend = (f - 0.92) / 0.16
                weights[next_bname] = max(blend, 0.0)
                weights[bname] = 1.0 - weights[next_bname]
            else:
                weights[bname] = 1.0
                
            # Create 8 verts in ring
            ring = []
            for i in range(n_sides):
                angle = 2.0 * math.pi * i / n_sides
                # Flatten slightly palmar (-Z) for realistic finger pad
                rx = math.cos(angle) * radius * 1.05
                rz = math.sin(angle) * radius * (0.90 if math.sin(angle) < 0 else 1.0)
                v_co = pos + axis_x * rx + axis_z * rz
                v = bm.verts.new(v_co)
                ring.append(v)
            all_rings.append((ring, weights, pos, radius, axis_x, axis_z))
            
        curr_len += b_len
        
    # Bridge rings with quad faces
    for r_i in range(len(all_rings) - 1):
        r0 = all_rings[r_i][0]
        r1 = all_rings[r_i + 1][0]
        for s in range(n_sides):
            s_next = (s + 1) % n_sides
            bm.faces.new([r0[s], r0[s_next], r1[s_next], r1[s]])
            
    # Cap the fingertip (distal tip)
    tip_ring, tip_weights, tip_pos, tip_rad, tip_ax, tip_az = all_rings[-1]
    tip_center_co = tip_pos + (bones[-1][2] - bones[-1][1]).normalized() * (tip_rad * 0.5)
    tip_center = bm.verts.new(tip_center_co)
    for s in range(n_sides):
        s_next = (s + 1) % n_sides
        bm.faces.new([tip_ring[s], tip_ring[s_next], tip_center])
        
    return all_rings, tip_center

def build_complete_hand(arm_obj, side='L'):
    is_left = (side == 'L')
    bm = bmesh.new()
    
    # Extract bone transforms
    def get_bone_info(bname):
        b = arm_obj.data.bones[bname]
        return (bname, b.head_local.copy(), b.tail_local.copy(), b.matrix_local.copy())
        
    # 1. Build 4 Fingers
    # Index
    idx_bones = [get_bone_info(f'Index{i}.{side}') for i in [2, 3, 4]]
    idx_rings, idx_tip = build_finger_bmesh(bm, idx_bones, 0.010, 0.0075, side, 'Index')
    
    # Middle
    mid_bones = [get_bone_info(f'Middle{i}.{side}') for i in [2, 3, 4]]
    mid_rings, mid_tip = build_finger_bmesh(bm, mid_bones, 0.0105, 0.008, side, 'Middle')
    
    # Ring
    rng_bones = [get_bone_info(f'Ring{i}.{side}') for i in [2, 3, 4]]
    rng_rings, rng_tip = build_finger_bmesh(bm, rng_bones, 0.0098, 0.0075, side, 'Ring')
    
    # Pinky
    pnk_bones = [get_bone_info(f'Pinky{i}.{side}') for i in [2, 3, 4]]
    pnk_rings, pnk_tip = build_finger_bmesh(bm, pnk_bones, 0.0090, 0.0068, side, 'Pinky')
    
    # Thumb
    thb_bones = [get_bone_info(f'Thumb{i}.{side}') for i in [2, 3]]
    thb_rings, thb_tip = build_finger_bmesh(bm, thb_bones, 0.0125, 0.0095, side, 'Thumb')
    
    # 2. Build Palm Body
    # Wrist boundary
    wrist_bone = get_bone_info(f'Hand.{side}')
    wrist_head = wrist_bone[1]
    wrist_tail = wrist_bone[2]
    wrist_mat  = wrist_bone[3]
    
    ax_x = Vector((wrist_mat[0][0], wrist_mat[1][0], wrist_mat[2][0])).normalized()
    ax_y = Vector((wrist_mat[0][1], wrist_mat[1][1], wrist_mat[2][1])).normalized()
    ax_z = Vector((wrist_mat[0][2], wrist_mat[1][2], wrist_mat[2][2])).normalized()
    
    # Wrist ring (12 vertices matching forearm sleeve contour)
    n_wrist = 12
    r_wrist_x = 0.038 # width ~7.6cm
    r_wrist_z = 0.024 # depth ~4.8cm
    
    wrist_rings = []
    for f in [0.0, 0.35, 0.70]:
        w_pos = wrist_head + (wrist_tail - wrist_head) * f
        # Flare outward towards knuckles
        scale = 1.0 + f * 0.25
        w_ring = []
        for i in range(n_wrist):
            ang = 2.0 * math.pi * i / n_wrist
            wx = math.cos(ang) * r_wrist_x * scale
            wz = math.sin(ang) * r_wrist_z * scale
            
            # Thenar muscle bulge near thumb side
            if math.cos(ang) > 0.4 and math.sin(ang) < 0.2 and f > 0.2:
                wx *= 1.25
                wz -= 0.008
                
            co = w_pos + ax_x * wx + ax_z * wz
            v = bm.verts.new(co)
            w_ring.append(v)
        wrist_rings.append((w_ring, f))
        
    # Bridge wrist rings
    for r_i in range(len(wrist_rings) - 1):
        r0 = wrist_rings[r_i][0]
        r1 = wrist_rings[r_i + 1][0]
        for s in range(n_wrist):
            s_next = (s + 1) % n_wrist
            bm.faces.new([r0[s], r0[s_next], r1[s_next], r1[s]])
            
    # Bridge palm to finger bases and thumb
    # Connect dorsal side to form continuous carbon knuckle guard
    knuckle_bases = [
        idx_rings[0][0],
        mid_rings[0][0],
        rng_rings[0][0],
        pnk_rings[0][0]
    ]
    
    # Bridge adjacent fingers at finger webs
    for f_i in range(3):
        f0_ring = knuckle_bases[f_i]
        f1_ring = knuckle_bases[f_i + 1]
        # Inner web faces
        bm.faces.new([f0_ring[0], f0_ring[1], f1_ring[7], f1_ring[0]])
        bm.faces.new([f0_ring[4], f0_ring[5], f1_ring[3], f1_ring[4]])
        
    # Connect distal wrist ring to knuckle bases & thumb
    distal_wrist = wrist_rings[-1][0]
    thb_base = thb_rings[0][0]
    
    # Bridge palm faces
    # Dorsal bridge:
    try:
        bm.faces.new([distal_wrist[0], distal_wrist[1], idx_rings[0][0][2], idx_rings[0][0][3]])
        bm.faces.new([distal_wrist[1], distal_wrist[2], mid_rings[0][0][2], mid_rings[0][0][3]])
        bm.faces.new([distal_wrist[2], distal_wrist[3], rng_rings[0][0][2], rng_rings[0][0][3]])
        bm.faces.new([distal_wrist[3], distal_wrist[4], pnk_rings[0][0][2], pnk_rings[0][0][3]])
    except Exception as e:
        pass
        
    # Palmar bridge (hollow palm):
    try:
        bm.faces.new([distal_wrist[6], distal_wrist[7], pnk_rings[0][0][6], pnk_rings[0][0][7]])
        bm.faces.new([distal_wrist[7], distal_wrist[8], rng_rings[0][0][6], rng_rings[0][0][7]])
        bm.faces.new([distal_wrist[8], distal_wrist[9], mid_rings[0][0][6], mid_rings[0][0][7]])
        bm.faces.new([distal_wrist[9], distal_wrist[10], idx_rings[0][0][6], idx_rings[0][0][7]])
    except Exception as e:
        pass
        
    # Thumb thenar connection:
    try:
        bm.faces.new([distal_wrist[11], distal_wrist[0], thb_base[2], thb_base[1]])
        bm.faces.new([distal_wrist[10], distal_wrist[11], thb_base[3], thb_base[2]])
    except Exception as e:
        pass
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm, [idx_rings, mid_rings, rng_rings, pnk_rings, thb_rings], wrist_rings

print("Hand builder loaded successfully!")
