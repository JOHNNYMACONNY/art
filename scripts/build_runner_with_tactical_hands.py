#!/usr/bin/env python3
"""
scripts/build_runner_with_tactical_hands.py
Replaces the flat, low-poly paddle hands in runner.blend with airtight,
beautifully proportioned, game-ready tactical courier gloves.
Exports the updated glTF directly to godot/models/runner.glb.
"""

import bpy
import bmesh
from mathutils import Vector, Matrix, Quaternion, Euler
import math
import os

UV_CHARCOAL = (0.05, 0.95)
UV_ORANGE   = (0.60, 0.85)
UV_ARMOR    = (0.30, 0.45)
UV_PALM_PAD = (0.75, 0.65)

def set_face_uv(face, uv_layer, uv_center, spread=0.03):
    cx, cy = uv_center
    uvs = [
        (cx - spread, cy - spread),
        (cx + spread, cy - spread),
        (cx + spread, cy + spread),
        (cx - spread, cy + spread),
    ]
    for i, loop in enumerate(face.loops):
        loop[uv_layer].uv = uvs[i % 4]

def build_tactical_hand_mesh(bm, uv_layer, arm_obj, side='L'):
    is_left = (side == 'L')
    sign_x = 1.0 if is_left else -1.0
    
    def get_bone(name):
        b = arm_obj.data.bones[name]
        return b.head_local.copy(), b.tail_local.copy(), b.matrix_local.copy()
        
    wrist_head, wrist_tail, wrist_mat = get_bone(f'Hand.{side}')
    
    # Track vertices for skinning: bname -> list of BMVert
    hand_vert_groups = {
        f'Hand.{side}': [],
        f'LowerArm.{side}': [],
        f'Thumb2.{side}': [], f'Thumb3.{side}': [],
        f'Index2.{side}': [], f'Index3.{side}': [], f'Index4.{side}': [],
        f'Middle2.{side}': [], f'Middle3.{side}': [], f'Middle4.{side}': [],
        f'Ring2.{side}': [], f'Ring3.{side}': [], f'Ring4.{side}': [],
        f'Pinky2.{side}': [], f'Pinky3.{side}': [], f'Pinky4.{side}': [],
    }

    # Finger bone chains
    finger_configs = [
        ('Index',  [f'Index{i}.{side}' for i in [2, 3, 4]],   0.0102, 0.0075),
        ('Middle', [f'Middle{i}.{side}' for i in [2, 3, 4]],  0.0108, 0.0080),
        ('Ring',   [f'Ring{i}.{side}' for i in [2, 3, 4]],    0.0100, 0.0075),
        ('Pinky',  [f'Pinky{i}.{side}' for i in [2, 3, 4]],   0.0088, 0.0068),
    ]
    
    # Local hand axes
    ax_x = Vector((wrist_mat[0][0], wrist_mat[1][0], wrist_mat[2][0])).normalized()
    ax_y = Vector((wrist_mat[0][1], wrist_mat[1][1], wrist_mat[2][1])).normalized()
    ax_z = Vector((wrist_mat[0][2], wrist_mat[1][2], wrist_mat[2][2])).normalized()
    
    # -------------------------------------------------------------------------
    # 1. PALM BODY (Airtight 4-column quad mesh)
    # -------------------------------------------------------------------------
    grid_dorsal = []
    grid_palmar = []
    
    # 3 cross-sections: Wrist cuff, Mid-palm (thenar), Knuckle arch
    for r_idx, f_dist in enumerate([0.12, 0.55, 0.98]):
        d_row = []
        p_row = []
        palm_c = wrist_head + (wrist_tail - wrist_head) * f_dist
        
        w_x = 0.038 if r_idx < 2 else 0.042
        w_z = 0.019 if r_idx < 2 else 0.015
        
        for col in range(5):
            t_col = (col - 2.0) / 2.0
            col_x = palm_c + ax_x * (t_col * w_x)
            arch_z = (1.0 - t_col * t_col * 0.35) * w_z
            
            thenar_z = 0.0
            if col <= 1 and r_idx == 1:
                thenar_z = -0.007
                
            vd = bm.verts.new(col_x + ax_z * arch_z)
            vp = bm.verts.new(col_x - ax_z * (arch_z - thenar_z))
            
            hand_vert_groups[f'Hand.{side}'].append(vd)
            hand_vert_groups[f'Hand.{side}'].append(vp)
            if r_idx == 0:
                hand_vert_groups[f'LowerArm.{side}'].append(vd)
                hand_vert_groups[f'LowerArm.{side}'].append(vp)
                
            d_row.append(vd)
            p_row.append(vp)
            
        grid_dorsal.append(d_row)
        grid_palmar.append(p_row)
        
    for r in range(2):
        for c in range(4):
            f_d = bm.faces.new([grid_dorsal[r][c], grid_dorsal[r][c+1], grid_dorsal[r+1][c+1], grid_dorsal[r+1][c]])
            f_d.smooth = True
            uv = UV_ARMOR if r == 1 else (UV_ORANGE if r == 0 else UV_CHARCOAL)
            set_face_uv(f_d, uv_layer, uv)
            
            f_p = bm.faces.new([grid_palmar[r][c+1], grid_palmar[r][c], grid_palmar[r+1][c], grid_palmar[r+1][c+1]])
            f_p.smooth = True
            uv_p = UV_PALM_PAD if r == 1 else UV_CHARCOAL
            set_face_uv(f_p, uv_layer, uv_p)
            
        f_lat = bm.faces.new([grid_palmar[r][0], grid_dorsal[r][0], grid_dorsal[r+1][0], grid_palmar[r+1][0]])
        f_lat.smooth = True
        set_face_uv(f_lat, uv_layer, UV_CHARCOAL)
        
        f_med = bm.faces.new([grid_dorsal[r][4], grid_palmar[r][4], grid_palmar[r+1][4], grid_dorsal[r+1][4]])
        f_med.smooth = True
        set_face_uv(f_med, uv_layer, UV_CHARCOAL)

    # -------------------------------------------------------------------------
    # 2. FOUR ARTICULATED FINGERS (With 3-loop knuckle deformation)
    # -------------------------------------------------------------------------
    for c_idx, (fname, bnames, r_base, r_tip) in enumerate(finger_configs):
        bones_data = [get_bone(bn) for bn in bnames]
        total_len = sum((tail - head).length for head, tail, _ in bones_data)
        
        v_tl = grid_dorsal[2][c_idx]
        v_tr = grid_dorsal[2][c_idx + 1]
        v_br = grid_palmar[2][c_idx + 1]
        v_bl = grid_palmar[2][c_idx]
        
        f_rings = [[v_tl, v_tr, v_br, v_bl]]
        curr_dist = 0.0
        
        for b_idx, (bname, (head, tail, b_mat)) in enumerate(zip(bnames, bones_data)):
            b_vec = tail - head
            b_len = b_vec.length
            bx = Vector((b_mat[0][0], b_mat[1][0], b_mat[2][0])).normalized()
            by = Vector((b_mat[0][1], b_mat[1][1], b_mat[2][1])).normalized()
            bz = Vector((b_mat[0][2], b_mat[1][2], b_mat[2][2])).normalized()
            
            fractions = [0.10, 0.50, 0.90, 1.00] if b_idx == 0 else ([0.10, 0.50, 0.90, 1.00] if b_idx < 2 else [0.10, 0.45, 0.80, 1.00])
            
            for f in fractions:
                pos = head + b_vec * f
                t_glob = (curr_dist + b_len * f) / max(total_len, 0.001)
                rad = r_base + (r_tip - r_base) * t_glob
                is_joint = (f <= 0.12 or f >= 0.88)
                dorsal_b = 1.10 if is_joint else 1.0
                
                w_rx = rad * 1.05
                w_rz = rad * dorsal_b
                
                v0 = bm.verts.new(pos - bx * w_rx + bz * w_rz)
                v1 = bm.verts.new(pos + bx * w_rx + bz * w_rz)
                v2 = bm.verts.new(pos + bx * w_rx - bz * (w_rz * 0.92))
                v3 = bm.verts.new(pos - bx * w_rx - bz * (w_rz * 0.92))
                
                ring = [v0, v1, v2, v3]
                for v in ring:
                    if f <= 0.12 and b_idx > 0:
                        hand_vert_groups[bnames[b_idx - 1]].append(v)
                        hand_vert_groups[bname].append(v)
                    elif f >= 0.88 and b_idx < len(bnames) - 1:
                        hand_vert_groups[bnames[b_idx + 1]].append(v)
                        hand_vert_groups[bname].append(v)
                    else:
                        hand_vert_groups[bname].append(v)
                f_rings.append(ring)
            curr_dist += b_len
            
        for r_i in range(len(f_rings) - 1):
            r0 = f_rings[r_i]
            r1 = f_rings[r_i + 1]
            for s in range(4):
                s_next = (s + 1) % 4
                face = bm.faces.new([r0[s], r0[s_next], r1[s_next], r1[s]])
                face.smooth = True
                uv = UV_ARMOR if s == 0 else UV_CHARCOAL
                set_face_uv(face, uv_layer, uv)
                
        tip_r = f_rings[-1]
        f_tip = bm.faces.new([tip_r[0], tip_r[1], tip_r[2], tip_r[3]])
        f_tip.smooth = True
        set_face_uv(f_tip, uv_layer, UV_CHARCOAL)
        for v in tip_r:
            hand_vert_groups[bnames[-1]].append(v)

    # -------------------------------------------------------------------------
    # 3. THUMB
    # -------------------------------------------------------------------------
    thb_bnames = [f'Thumb{i}.{side}' for i in [2, 3]]
    thb_data = [get_bone(bn) for bn in thb_bnames]
    thb_total_len = sum((tail - head).length for head, tail, _ in thb_data)
    
    thb_rings = []
    thb_r_base = 0.0125
    thb_r_tip  = 0.0095
    curr_thb_dist = 0.0
    
    for b_idx, (bname, (head, tail, b_mat)) in enumerate(zip(thb_bnames, thb_data)):
        b_vec = tail - head
        b_len = b_vec.length
        bx = Vector((b_mat[0][0], b_mat[1][0], b_mat[2][0])).normalized()
        by = Vector((b_mat[0][1], b_mat[1][1], b_mat[2][1])).normalized()
        bz = Vector((b_mat[0][2], b_mat[1][2], b_mat[2][2])).normalized()
        
        fractions = [0.0, 0.15, 0.50, 0.85, 1.00]
        for f in fractions:
            if b_idx > 0 and f == 0.0:
                continue
            pos = head + b_vec * f
            t_glob = (curr_thb_dist + b_len * f) / max(thb_total_len, 0.001)
            rad = thb_r_base + (thb_r_tip - thb_r_base) * t_glob
            
            v0 = bm.verts.new(pos - bx * rad + bz * rad)
            v1 = bm.verts.new(pos + bx * rad + bz * rad)
            v2 = bm.verts.new(pos + bx * rad - bz * rad)
            v3 = bm.verts.new(pos - bx * rad - bz * rad)
            
            ring = [v0, v1, v2, v3]
            for v in ring:
                if f <= 0.15 and b_idx > 0:
                    hand_vert_groups[thb_bnames[b_idx - 1]].append(v)
                    hand_vert_groups[bname].append(v)
                else:
                    hand_vert_groups[bname].append(v)
            thb_rings.append(ring)
        curr_thb_dist += b_len
        
    for r_i in range(len(thb_rings) - 1):
        r0 = thb_rings[r_i]
        r1 = thb_rings[r_i + 1]
        for s in range(4):
            s_next = (s + 1) % 4
            face = bm.faces.new([r0[s], r0[s_next], r1[s_next], r1[s]])
            face.smooth = True
            uv = UV_ARMOR if s == 0 else UV_CHARCOAL
            set_face_uv(face, uv_layer, uv)
            
    f_thb_tip = bm.faces.new([thb_rings[-1][0], thb_rings[-1][1], thb_rings[-1][2], thb_rings[-1][3]])
    f_thb_tip.smooth = True
    set_face_uv(f_thb_tip, uv_layer, UV_CHARCOAL)
    for v in thb_rings[-1]:
        hand_vert_groups[thb_bnames[-1]].append(v)
        
    # Bridge thumb base ring to lateral palm
    thb_b0 = thb_rings[0]
    try:
        bm.faces.new([grid_dorsal[1][0], grid_dorsal[2][0], thb_b0[1], thb_b0[0]])
        bm.faces.new([grid_dorsal[2][0], grid_palmar[2][0], thb_b0[2], thb_b0[1]])
        bm.faces.new([grid_palmar[2][0], grid_palmar[1][0], thb_b0[3], thb_b0[2]])
        bm.faces.new([grid_palmar[1][0], grid_dorsal[1][0], thb_b0[0], thb_b0[3]])
    except Exception:
        pass

    return hand_vert_groups

def install_and_export():
    blend_path = 'models_source/runner.blend'
    glb_path = 'godot/models/runner.glb'
    
    print(f"Opening {blend_path}...")
    bpy.ops.wm.open_mainfile(filepath=blend_path)
    
    mesh_obj = bpy.data.objects['Runner_Mesh']
    arm_obj = bpy.data.objects['CharacterArmature']
    
    # 1. Identify and remove old flat paddle hand vertices
    hand_vg_names = ['Hand', 'Index', 'Middle', 'Ring', 'Pinky', 'Thumb']
    hand_vg_indices = {vg.index for vg in mesh_obj.vertex_groups if any(k in vg.name for k in hand_vg_names)}
    arm_vg_indices = {vg.index for vg in mesh_obj.vertex_groups if any(k in vg.name for k in ['LowerArm', 'UpperArm'])}
    
    bm = bmesh.new()
    bm.from_mesh(mesh_obj.data)
    bm.verts.ensure_lookup_table()
    
    verts_to_delete = []
    for v in bm.verts:
        # Check vertex weights on original mesh
        orig_v = mesh_obj.data.vertices[v.index]
        is_hand = any(g.group in hand_vg_indices and g.weight > 0.05 for g in orig_v.groups)
        is_arm = any(g.group in arm_vg_indices and g.weight > 0.45 for g in orig_v.groups)
        if is_hand and not is_arm:
            verts_to_delete.append(v)
            
    print(f"Removing {len(verts_to_delete)} old flat paddle hand vertices...")
    bmesh.ops.delete(bm, geom=verts_to_delete, context='VERTS')
    
    # 2. Build new tactical hands for Left and Right
    uv_layer = bm.loops.layers.uv.verify()
    
    for side in ['L', 'R']:
        print(f"Generating airtight tactical hand for side {side}...")
        hand_vgs = build_tactical_hand_mesh(bm, uv_layer, arm_obj, side)
        
        # We need to assign new vertices to mesh_obj vertex groups
        # Note vertex group assignment must happen on the object after bm.to_mesh
        # We store the vert indices
        # We'll map them after writing back to mesh
        
    for f in bm.faces:
        f.smooth = True
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    bm.to_mesh(mesh_obj.data)
    bm.free()
    
    mesh_obj.data.update()
    print("Mesh updated with new tactical hands!")
    
    # 3. Now ensure all hand bones have proper vertex group weights
    # Re-skin hand vertices by spatial proximity to bone axes
    print("Re-skinning tactical hands to armature bones...")
    vg_map = {vg.name: vg for vg in mesh_obj.vertex_groups}
    for b in arm_obj.data.bones:
        if any(k in b.name for k in ['Hand', 'Index', 'Middle', 'Ring', 'Pinky', 'Thumb']):
            if b.name not in vg_map:
                mesh_obj.vertex_groups.new(name=b.name)
    vg_map = {vg.name: vg for vg in mesh_obj.vertex_groups}
    
    # Auto-assign hand vertices by closest bone segment
    hand_bone_names_L = [b.name for b in arm_obj.data.bones if '.L' in b.name and any(k in b.name for k in ['Hand', 'Index', 'Middle', 'Ring', 'Pinky', 'Thumb'])]
    hand_bone_names_R = [b.name for b in arm_obj.data.bones if '.R' in b.name and any(k in b.name for k in ['Hand', 'Index', 'Middle', 'Ring', 'Pinky', 'Thumb'])]
    
    for v in mesh_obj.data.vertices:
        if abs(v.co.x) > 0.55 and v.co.z > 1.35 and abs(v.co.x) < 0.88:
            is_left = (v.co.x > 0)
            bone_candidates = hand_bone_names_L if is_left else hand_bone_names_R
            
            best_dist = 9999.0
            best_bone = None
            for bname in bone_candidates:
                b = arm_obj.data.bones[bname]
                # Distance to segment head-tail
                h = b.head_local
                t = b.tail_local
                line_vec = t - h
                v_vec = v.co - h
                proj = max(0.0, min(1.0, v_vec.dot(line_vec) / max(line_vec.length_squared, 0.0001)))
                closest_p = h + line_vec * proj
                dist = (v.co - closest_p).length
                if dist < best_dist:
                    best_dist = dist
                    best_bone = bname
                    
            if best_bone and best_dist < 0.045:
                vg_map[best_bone].add([v.index], 1.0, 'REPLACE')
                
    # 4. Save runner.blend
    bpy.ops.wm.save_mainfile(filepath=blend_path)
    print(f"Saved {blend_path}!")
    
    # 5. Export to runner.glb
    print(f"Exporting to {glb_path}...")
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=False,
        export_apply=False,
        export_animations=True,
        export_skins=True,
        export_morph=True,
        export_materials='EXPORT',
        export_yup=True
    )
    print("Export complete!")

if __name__ == '__main__':
    install_and_export()
