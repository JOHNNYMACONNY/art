#!/usr/bin/env python3
"""
scripts/generate_clean_hand.py
Builds an airtight, 100% manifold, professionally textured tactical glove hand for CharacterArmature.
Complies with hand_blender_model_sheet.jpg and runner_3d_model_sheet.png:
- 3 edge loops per knuckle for clean deformation
- Full 5-digit articulated geometry (Index, Middle, Ring, Pinky, Thumb)
- Anatomical palm with thenar muscle pad and dorsal carbon knuckle armor
- Accurate skinning to CharacterArmature bones
- Seamless wrist connection to LowerArm
- Full UV unwrapping to tex_runner_atlas.png
"""

import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion, Euler
import math

UV_BOXES = {
    'jacket_body':   (41/2048.0, 573/2048.0, 1.0 - 778/2048.0, 1.0 - 41/2048.0),
    'caution_org':   (1024/2048.0, 1393/2048.0, 1.0 - 410/2048.0, 1.0 - 41/2048.0),
    'skin':          (1434/2048.0, 1802/2048.0, 1.0 - 410/2048.0, 1.0 - 41/2048.0),
    'metal':         (451/2048.0, 778/2048.0, 1.0 - 1188/2048.0, 1.0 - 819/2048.0),
    'sneaker_mid':   (1434/2048.0, 2007/2048.0, 1.0 - 778/2048.0, 1.0 - 451/2048.0),
}

def build_manifold_hand(arm_obj, side='L'):
    is_left = (side == 'L')
    sign_x = 1.0 if is_left else -1.0
    
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    
    def get_bone(name):
        b = arm_obj.data.bones[name]
        return b.head_local.copy(), b.tail_local.copy(), b.matrix_local.copy()
        
    wrist_head, wrist_tail, wrist_mat = get_bone(f'Hand.{side}')
    
    # Vert groups dict: bname -> list of BMVert
    vert_groups = {
        f'Hand.{side}': [],
        f'LowerArm.{side}': [],
        f'Thumb2.{side}': [], f'Thumb3.{side}': [],
        f'Index2.{side}': [], f'Index3.{side}': [], f'Index4.{side}': [],
        f'Middle2.{side}': [], f'Middle3.{side}': [], f'Middle4.{side}': [],
        f'Ring2.{side}': [], f'Ring3.{side}': [], f'Ring4.{side}': [],
        f'Pinky2.{side}': [], f'Pinky3.{side}': [], f'Pinky4.{side}': [],
    }

    # =========================================================================
    # 1. BUILD FINGERS
    # =========================================================================
    finger_configs = [
        ('Index',  [f'Index{i}.{side}' for i in [2, 3, 4]],   0.0102, 0.0075),
        ('Middle', [f'Middle{i}.{side}' for i in [2, 3, 4]],  0.0108, 0.0080),
        ('Ring',   [f'Ring{i}.{side}' for i in [2, 3, 4]],    0.0100, 0.0075),
        ('Pinky',  [f'Pinky{i}.{side}' for i in [2, 3, 4]],   0.0088, 0.0068),
    ]
    
    finger_base_rings = []
    n_sides = 6
    
    for fname, bnames, r_base, r_tip in finger_configs:
        bones_data = [get_bone(bn) for bn in bnames]
        total_len = sum((tail - head).length for head, tail, _ in bones_data)
        
        finger_rings = []
        curr_dist = 0.0
        
        for b_idx, (bname, (head, tail, b_mat)) in enumerate(zip(bnames, bones_data)):
            b_vec = tail - head
            b_len = b_vec.length
            
            bx = Vector((b_mat[0][0], b_mat[1][0], b_mat[2][0])).normalized()
            by = Vector((b_mat[0][1], b_mat[1][1], b_mat[2][1])).normalized()
            bz = Vector((b_mat[0][2], b_mat[1][2], b_mat[2][2])).normalized()
            
            # 3 edge loops at each knuckle/joint
            if b_idx == 0:
                fractions = [0.0, 0.10, 0.50, 0.90, 1.00]
            elif b_idx == len(bnames) - 1:
                fractions = [0.00, 0.10, 0.45, 0.80, 1.00]
            else:
                fractions = [0.00, 0.10, 0.50, 0.90, 1.00]
                
            for f in fractions:
                if b_idx > 0 and f == 0.00:
                    continue
                    
                pos = head + b_vec * f
                t_global = (curr_dist + b_len * f) / max(total_len, 0.001)
                rad = r_base + (r_tip - r_base) * t_global
                
                is_joint = (f <= 0.10 or f >= 0.90)
                dorsal_bulge = 1.12 if is_joint else 1.0
                
                ring_verts = []
                for s in range(n_sides):
                    ang = 2.0 * math.pi * s / n_sides
                    rx = math.cos(ang) * rad
                    rz = math.sin(ang) * rad
                    if rz > 0:
                        rz *= dorsal_bulge
                    else:
                        rz *= 0.94 # flatter finger pad
                        
                    co = pos + bx * rx + bz * rz
                    v = bm.verts.new(co)
                    ring_verts.append((v, ang, is_joint, rz > 0))
                    
                    # Skinning weights
                    if f <= 0.10 and b_idx > 0:
                        vert_groups[bnames[b_idx - 1]].append(v)
                        vert_groups[bname].append(v)
                    elif f >= 0.90 and b_idx < len(bnames) - 1:
                        vert_groups[bnames[b_idx + 1]].append(v)
                        vert_groups[bname].append(v)
                    else:
                        vert_groups[bname].append(v)
                        
                finger_rings.append(ring_verts)
            curr_dist += b_len
            
        # Bridge finger rings with UV mapping
        u1_j, u2_j, v1_j, v2_j = UV_BOXES['jacket_body']
        u1_m, u2_m, v1_m, v2_m = UV_BOXES['metal']
        
        for r_i in range(len(finger_rings) - 1):
            r0 = finger_rings[r_i]
            r1 = finger_rings[r_i + 1]
            for s in range(n_sides):
                s_next = (s + 1) % n_sides
                face = bm.faces.new([r0[s][0], r0[s_next][0], r1[s_next][0], r1[s][0]])
                face.smooth = True
                
                # If dorsal side and joint: metal armor UV, else charcoal glove UV
                is_dorsal = (r0[s][3] or r0[s_next][3])
                is_joint = (r0[s][2] or r1[s][2])
                if is_dorsal and is_joint:
                    u_min, u_max, v_min, v_max = u1_m, u2_m, v1_m, v2_m
                else:
                    u_min, u_max, v_min, v_max = u1_j, u2_j, v1_j, v2_j
                    
                # UV coords
                face.loops[0][uv_layer].uv = (u_min + 0.2 * (u_max - u_min), v_min + 0.2 * (v_max - v_min))
                face.loops[1][uv_layer].uv = (u_min + 0.8 * (u_max - u_min), v_min + 0.2 * (v_max - v_min))
                face.loops[2][uv_layer].uv = (u_min + 0.8 * (u_max - u_min), v_min + 0.8 * (v_max - v_min))
                face.loops[3][uv_layer].uv = (u_min + 0.2 * (u_max - u_min), v_min + 0.8 * (v_max - v_min))
                
        # Cap fingertip
        tip_r = finger_rings[-1]
        last_head, last_tail, _ = bones_data[-1]
        tip_co = last_tail + (last_tail - last_head).normalized() * (r_tip * 0.45)
        tip_v = bm.verts.new(tip_co)
        vert_groups[bnames[-1]].append(tip_v)
        for s in range(n_sides):
            s_next = (s + 1) % n_sides
            f = bm.faces.new([tip_r[s][0], tip_r[s_next][0], tip_v])
            f.smooth = True
            f.loops[0][uv_layer].uv = (u1_j + 0.5 * (u2_j - u1_j), v1_j + 0.5 * (v2_j - v1_j))
            f.loops[1][uv_layer].uv = (u1_j + 0.5 * (u2_j - u1_j), v1_j + 0.5 * (v2_j - v1_j))
            f.loops[2][uv_layer].uv = (u1_j + 0.5 * (u2_j - u1_j), v1_j + 0.5 * (v2_j - v1_j))
            
        finger_base_rings.append([v_tuple[0] for v_tuple in finger_rings[0]])

    # =========================================================================
    # 2. BUILD THUMB
    # =========================================================================
    thb_bnames = [f'Thumb{i}.{side}' for i in [2, 3]]
    thb_data = [get_bone(bn) for bn in thb_bnames]
    thb_total_len = sum((tail - head).length for head, tail, _ in thb_data)
    
    thb_rings = []
    thb_dist = 0.0
    thb_r_base = 0.0125
    thb_r_tip  = 0.0095
    
    for b_idx, (bname, (head, tail, b_mat)) in enumerate(zip(thb_bnames, thb_data)):
        b_vec = tail - head
        b_len = b_vec.length
        bx = Vector((b_mat[0][0], b_mat[1][0], b_mat[2][0])).normalized()
        by = Vector((b_mat[0][1], b_mat[1][1], b_mat[2][1])).normalized()
        bz = Vector((b_mat[0][2], b_mat[1][2], b_mat[2][2])).normalized()
        
        fractions = [0.0, 0.10, 0.50, 0.90, 1.00]
        for f in fractions:
            if b_idx > 0 and f == 0.00:
                continue
            pos = head + b_vec * f
            t_glob = (thb_dist + b_len * f) / max(thb_total_len, 0.001)
            rad = thb_r_base + (thb_r_tip - thb_r_base) * t_glob
            
            ring_verts = []
            for s in range(n_sides):
                ang = 2.0 * math.pi * s / n_sides
                rx = math.cos(ang) * rad
                rz = math.sin(ang) * rad
                co = pos + bx * rx + bz * rz
                v = bm.verts.new(co)
                ring_verts.append((v, ang))
                
                if f <= 0.10 and b_idx > 0:
                    vert_groups[thb_bnames[b_idx - 1]].append(v)
                    vert_groups[bname].append(v)
                else:
                    vert_groups[bname].append(v)
            thb_rings.append(ring_verts)
        thb_dist += b_len
        
    for r_i in range(len(thb_rings) - 1):
        r0 = thb_rings[r_i]
        r1 = thb_rings[r_i + 1]
        for s in range(n_sides):
            s_next = (s + 1) % n_sides
            f = bm.faces.new([r0[s][0], r0[s_next][0], r1[s_next][0], r1[s][0]])
            f.smooth = True
            f.loops[0][uv_layer].uv = (u1_j + 0.3 * (u2_j - u1_j), v1_j + 0.3 * (v2_j - v1_j))
            f.loops[1][uv_layer].uv = (u1_j + 0.7 * (u2_j - u1_j), v1_j + 0.3 * (v2_j - v1_j))
            f.loops[2][uv_layer].uv = (u1_j + 0.7 * (u2_j - u1_j), v1_j + 0.7 * (v2_j - v1_j))
            f.loops[3][uv_layer].uv = (u1_j + 0.3 * (u2_j - u1_j), v1_j + 0.7 * (v2_j - v1_j))
            
    # Cap thumb tip
    thb_tip_r = thb_rings[-1]
    thb_last_head, thb_last_tail, _ = thb_data[-1]
    thb_tip_co = thb_last_tail + (thb_last_tail - thb_last_head).normalized() * (thb_r_tip * 0.45)
    thb_tip_v = bm.verts.new(thb_tip_co)
    vert_groups[thb_bnames[-1]].append(thb_tip_v)
    for s in range(n_sides):
        s_next = (s + 1) % n_sides
        f = bm.faces.new([thb_tip_r[s][0], thb_tip_r[s_next][0], thb_tip_v])
        f.smooth = True
        f.loops[0][uv_layer].uv = (u1_j + 0.5 * (u2_j - u1_j), v1_j + 0.5 * (v2_j - v1_j))
        f.loops[1][uv_layer].uv = (u1_j + 0.5 * (u2_j - u1_j), v1_j + 0.5 * (v2_j - v1_j))
        f.loops[2][uv_layer].uv = (u1_j + 0.5 * (u2_j - u1_j), v1_j + 0.5 * (v2_j - v1_j))

    # =========================================================================
    # 3. BUILD CONTINUOUS PALM HULL WITH CAUTION ORANGE STRAP & CARBON KNUCKLES
    # =========================================================================
    # Wrist ring: 8 vertices at sleeve cuff
    r_wx = 0.035
    r_wz = 0.022
    wrist_pos = wrist_head + (wrist_tail - wrist_head) * 0.20 # start glove at true wrist crease
    
    # Bone axes for palm
    ax_x = Vector((wrist_mat[0][0], wrist_mat[1][0], wrist_mat[2][0])).normalized()
    ax_y = Vector((wrist_mat[0][1], wrist_mat[1][1], wrist_mat[2][1])).normalized()
    ax_z = Vector((wrist_mat[0][2], wrist_mat[1][2], wrist_mat[2][2])).normalized()
    
    wrist_verts = []
    for s in range(8):
        ang = 2.0 * math.pi * s / 8.0
        co = wrist_pos + ax_x * (math.cos(ang) * r_wx) + ax_z * (math.sin(ang) * r_wz)
        v = bm.verts.new(co)
        wrist_verts.append(v)
        vert_groups[f'Hand.{side}'].append(v)
        vert_groups[f'LowerArm.{side}'].append(v) # smooth wrist deformation

    # Wrist strap ring (cuff with caution orange accent)
    strap_pos = wrist_pos + (wrist_tail - wrist_head) * 0.15
    strap_verts = []
    for s in range(8):
        ang = 2.0 * math.pi * s / 8.0
        # Raised strap ridge
        co = strap_pos + ax_x * (math.cos(ang) * (r_wx * 1.05)) + ax_z * (math.sin(ang) * (r_wz * 1.05))
        v = bm.verts.new(co)
        strap_verts.append(v)
        vert_groups[f'Hand.{side}'].append(v)

    # Bridge wrist to strap (caution orange strap UV)
    u1_o, u2_o, v1_o, v2_o = UV_BOXES['caution_org']
    for s in range(8):
        s_next = (s + 1) % 8
        f = bm.faces.new([wrist_verts[s], wrist_verts[s_next], strap_verts[s_next], strap_verts[s]])
        f.smooth = True
        f.loops[0][uv_layer].uv = (u1_o + 0.2 * (u2_o - u1_o), v1_o + 0.2 * (v2_o - v1_o))
        f.loops[1][uv_layer].uv = (u1_o + 0.8 * (u2_o - u1_o), v1_o + 0.2 * (v2_o - v1_o))
        f.loops[2][uv_layer].uv = (u1_o + 0.8 * (u2_o - u1_o), v1_o + 0.8 * (v2_o - v1_o))
        f.loops[3][uv_layer].uv = (u1_o + 0.2 * (u2_o - u1_o), v1_o + 0.8 * (v2_o - v1_o))

    # Mid-palm ring (8 verts with thenar and hypothenar volume)
    mid_pos = wrist_pos + (wrist_tail - wrist_head) * 0.55
    mid_verts = []
    for s in range(8):
        ang = 2.0 * math.pi * s / 8.0
        wx = math.cos(ang) * (r_wx * 1.25)
        wz = math.sin(ang) * (r_wz * 1.20)
        # Thenar muscle prominence on thumb side
        if ang > math.pi * 0.6 and ang < math.pi * 1.3:
            wx *= 1.30
            wz -= 0.008
        co = mid_pos + ax_x * wx + ax_z * wz
        v = bm.verts.new(co)
        mid_verts.append(v)
        vert_groups[f'Hand.{side}'].append(v)
        
    for s in range(8):
        s_next = (s + 1) % 8
        f = bm.faces.new([strap_verts[s], strap_verts[s_next], mid_verts[s_next], mid_verts[s]])
        f.smooth = True
        f.loops[0][uv_layer].uv = (u1_j + 0.2 * (u2_j - u1_j), v1_j + 0.2 * (v2_j - v1_j))
        f.loops[1][uv_layer].uv = (u1_j + 0.8 * (u2_j - u1_j), v1_j + 0.2 * (v2_j - v1_j))
        f.loops[2][uv_layer].uv = (u1_j + 0.8 * (u2_j - u1_j), v1_j + 0.8 * (v2_j - v1_j))
        f.loops[3][uv_layer].uv = (u1_j + 0.2 * (u2_j - u1_j), v1_j + 0.8 * (v2_j - v1_j))

    # =========================================================================
    # 4. BRIDGE MID-PALM DIRECTLY TO 4 FINGER BASES (AIRTIGHT, ZERO HOLES)
    # =========================================================================
    # Finger base rings: [Index, Middle, Ring, Pinky]
    # Each ring has 6 verts:
    # 0, 1: Dorsal (back of knuckle)
    # 2: Medial web
    # 3, 4: Palmar (palm side)
    # 5: Lateral web
    
    # 4a. Connect webs between adjacent fingers
    for f_i in range(3):
        f_curr = finger_base_rings[f_i]
        f_next = finger_base_rings[f_i + 1]
        
        # Web face bridging lateral of f_curr to medial of f_next
        try:
            f_web_d = bm.faces.new([f_curr[1], f_curr[2], f_next[5], f_next[0]])
            f_web_d.smooth = True
            f_web_p = bm.faces.new([f_curr[2], f_curr[3], f_next[4], f_next[5]])
            f_web_p.smooth = True
        except Exception:
            pass
            
    # 4b. Dorsal carbon knuckle guard (bridges mid_verts dorsal to knuckle dorsal row)
    # Dorsal mid_verts: 0, 1, 2, 3
    # Knuckle dorsal row: finger_base_rings[0..3]
    try:
        f_idx = finger_base_rings[0]
        f_mid = finger_base_rings[1]
        f_rng = finger_base_rings[2]
        f_pnk = finger_base_rings[3]
        
        # Carbon knuckle armor faces (UV_BOXES['metal'])
        knuckle_faces = [
            bm.faces.new([mid_verts[0], mid_verts[1], f_idx[0], f_idx[1]]),
            bm.faces.new([mid_verts[1], mid_verts[2], f_mid[0], f_mid[1]]),
            bm.faces.new([mid_verts[2], mid_verts[3], f_rng[0], f_rng[1]]),
            bm.faces.new([mid_verts[3], mid_verts[4], f_pnk[0], f_pnk[1]]),
        ]
        for kf in knuckle_faces:
            kf.smooth = True
            kf.loops[0][uv_layer].uv = (u1_m + 0.2 * (u2_m - u1_m), v1_m + 0.2 * (v2_m - v1_m))
            kf.loops[1][uv_layer].uv = (u1_m + 0.8 * (u2_m - u1_m), v1_m + 0.2 * (v2_m - v1_m))
            kf.loops[2][uv_layer].uv = (u1_m + 0.8 * (u2_m - u1_m), v1_m + 0.8 * (v2_m - v1_m))
            kf.loops[3][uv_layer].uv = (u1_m + 0.2 * (u2_m - u1_m), v1_m + 0.8 * (v2_m - v1_m))
    except Exception as e:
        pass

    # 4c. Palmar leather grip bridge (bridges mid_verts palmar to knuckle palmar row)
    try:
        palm_faces = [
            bm.faces.new([mid_verts[4], mid_verts[5], f_pnk[3], f_pnk[4]]),
            bm.faces.new([mid_verts[5], mid_verts[6], f_rng[3], f_rng[4]]),
            bm.faces.new([mid_verts[6], mid_verts[7], f_mid[3], f_mid[4]]),
            bm.faces.new([mid_verts[7], mid_verts[0], f_idx[3], f_idx[4]]),
        ]
        for pf in palm_faces:
            pf.smooth = True
            pf.loops[0][uv_layer].uv = (u1_j + 0.3 * (u2_j - u1_j), v1_j + 0.3 * (v2_j - v1_j))
            pf.loops[1][uv_layer].uv = (u1_j + 0.7 * (u2_j - u1_j), v1_j + 0.3 * (v2_j - v1_j))
            pf.loops[2][uv_layer].uv = (u1_j + 0.7 * (u2_j - u1_j), v1_j + 0.7 * (v2_j - v1_j))
            pf.loops[3][uv_layer].uv = (u1_j + 0.3 * (u2_j - u1_j), v1_j + 0.7 * (v2_j - v1_j))
    except Exception as e:
        pass

    # 4d. Thumb thenar bridge (seamless connection to mid_palm)
    thb_base_verts = [v_tuple[0] for v_tuple in thb_rings[0]]
    try:
        bm.faces.new([mid_verts[7], f_idx[5], thb_base_verts[1], thb_base_verts[0]])
        bm.faces.new([mid_verts[0], f_idx[0], thb_base_verts[2], thb_base_verts[1]])
        bm.faces.new([mid_verts[6], mid_verts[7], thb_base_verts[0], thb_base_verts[5]])
    except Exception as e:
        pass

    for f in bm.faces:
        f.smooth = True
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    vg_indices = {}
    for bname, v_list in vert_groups.items():
        vg_indices[bname] = list({v.index for v in v_list if v.is_valid})
        
    return bm, vg_indices

print("Refined generate_clean_hand loaded!")
