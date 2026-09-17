#!/usr/bin/env python3
"""
scripts/blender_build_vending_machine.py
Builds authentic, game-industry-grade 3D model for Commercial Storefront Vending Machine:
- High-fidelity volumetric geometry (cabinet housing, angled marquee, recessed window, control keypad, dispenser flap).
- Materials: PBR main casing with tex_vending_machine.png, glass window, emissive marquee.
- Exports to godot/models/prop_vending_machine.glb and models_source/vending_machine.blend.
"""

import bpy
import bmesh
from mathutils import Vector, Euler, Matrix
import os
import math

TEXTURE_DIR = "/Users/bobbyinthelobby/{art/godot/textures/urban_clutter"
TEX_PATH = os.path.join(TEXTURE_DIR, "tex_vending_machine.png")
OUT_GLB = "/Users/bobbyinthelobby/{art/godot/models/prop_vending_machine.glb"
MODELS_SOURCE_DIR = "/Users/bobbyinthelobby/{art/models_source"
OUT_BLEND = os.path.join(MODELS_SOURCE_DIR, "vending_machine.blend")

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)

def create_pbr_material(name, diffuse_color=(0.5, 0.5, 0.5, 1.0), roughness=0.5, metallic=0.0,
                        emission_color=(0,0,0,1), emission_strength=0.0, texture_path=None, alpha=1.0):
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

    if alpha < 1.0:
        node_bsdf.inputs['Alpha'].default_value = alpha
        mat.blend_method = 'BLEND'
    else:
        node_bsdf.inputs['Alpha'].default_value = 1.0
        mat.blend_method = 'OPAQUE'

    if texture_path and os.path.exists(texture_path):
        node_tex = nodes.new('ShaderNodeTexImage')
        node_tex.location = (-250, 0)
        img = bpy.data.images.load(texture_path)
        node_tex.image = img
        links.new(node_tex.outputs['Color'], node_bsdf.inputs['Base Color'])

    if emission_strength > 0.0:
        node_bsdf.inputs['Emission Color'].default_value = emission_color
        node_bsdf.inputs['Emission Strength'].default_value = emission_strength

    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def add_box_geometry(bm, size, pos, rot=(0,0,0), uv_rect=None, mat_idx=0, flip_u=False, default_uv=(0.5, 0.5)):
    res = bmesh.ops.create_cube(bm, size=1.0)
    new_verts = res['verts']
    new_verts_set = set(new_verts)
    new_faces = [f for f in bm.faces if all(v in new_verts_set for v in f.verts)]

    uv_layer = bm.loops.layers.uv.verify()
    if uv_rect is not None:
        u1, v1, u2, v2 = uv_rect
        for face in new_faces:
            face.material_index = mat_idx
            for loop in face.loops:
                v_co = loop.vert.co
                nx = (1.0 - (v_co.x + 0.5)) if flip_u else (v_co.x + 0.5)
                ny = (v_co.y + 0.5)
                nz = (v_co.z + 0.5)
                if abs(face.normal.y) > 0.8:
                    loop[uv_layer].uv = (u1 + nx * (u2 - u1), v1 + nz * (v2 - v1))
                elif abs(face.normal.x) > 0.8:
                    cu1, cv1, cu2, cv2 = (0.0, 0.0, 0.5, 0.5)
                    loop[uv_layer].uv = (cu1 + ny * (cu2 - cu1), cv1 + nz * (cv2 - cv1))
                else:
                    cu1, cv1, cu2, cv2 = (0.0, 0.0, 0.5, 0.5)
                    loop[uv_layer].uv = (cu1 + nx * (cu2 - cu1), cv1 + ny * (cv2 - cu1))
    else:
        for face in new_faces:
            face.material_index = mat_idx
            for loop in face.loops:
                loop[uv_layer].uv = default_uv

    S = Matrix.Scale(size[0], 4, (1, 0, 0)) @ Matrix.Scale(size[1], 4, (0, 1, 0)) @ Matrix.Scale(size[2], 4, (0, 0, 1))
    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    bmesh.ops.transform(bm, matrix=(T @ R @ S), verts=new_verts)
    return new_faces

def add_cylinder_geometry(bm, radius, height, pos, rot=(0,0,0), segs=16, uv_rect=None, mat_idx=0):
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=radius, radius2=radius, depth=height)
    new_verts = res['verts']
    new_verts_set = set(new_verts)
    new_faces = [f for f in bm.faces if all(v in new_verts_set for v in f.verts)]

    uv_layer = bm.loops.layers.uv.verify()
    if uv_rect is not None:
        u1, v1, u2, v2 = uv_rect
        for face in new_faces:
            face.material_index = mat_idx
            for loop in face.loops:
                v_co = loop.vert.co
                angle = math.atan2(v_co.y, v_co.x)
                u = u1 + ((angle + math.pi) / (2.0 * math.pi)) * (u2 - u1)
                v = v1 + (v_co.z / height + 0.5) * (v2 - v1)
                loop[uv_layer].uv = (u, v)

    R = Euler(rot, 'XYZ').to_matrix().to_4x4() if rot != (0,0,0) else Matrix.Identity(4)
    T = Matrix.Translation(Vector(pos))
    bmesh.ops.transform(bm, matrix=(T @ R), verts=new_verts)
    return new_faces

def build_vending_machine():
    os.makedirs(MODELS_SOURCE_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
    reset_scene()
    bm = bmesh.new()

    # Materials
    # mat 0: Main textured PBR
    mat_main = create_pbr_material("Mat_VendingMain", texture_path=TEX_PATH, roughness=0.6, metallic=0.2)
    # mat 1: Glass display pane
    mat_glass = create_pbr_material("Mat_VendingGlass", diffuse_color=(0.1, 0.2, 0.25, 0.6), roughness=0.1, metallic=0.8, alpha=0.45)
    # mat 2: Emissive marquee & neon screen
    mat_emissive = create_pbr_material("Mat_VendingEmissive", diffuse_color=(0.1, 0.85, 1.0, 1.0), roughness=0.2,
                                       emission_color=(0.1, 0.85, 1.0, 1.0), emission_strength=2.5)
    # mat 3: Chrome / steel trim
    mat_steel = create_pbr_material("Mat_VendingSteel", diffuse_color=(0.8, 0.82, 0.85, 1.0), roughness=0.25, metallic=0.9)

    # 1. Base plinth / bottom feet (mat 0)
    add_box_geometry(bm, (0.95, 0.85, 0.12), (0.0, 0.0, 0.06), uv_rect=(0.75, 0.0, 1.0, 0.25), mat_idx=0)
    # Steel leveling feet pegs
    for fx in (-0.42, 0.42):
        for fy in (-0.38, 0.38):
            add_cylinder_geometry(bm, 0.04, 0.08, (fx, fy, 0.04), uv_rect=(0.75, 0.0, 1.0, 0.25), mat_idx=3)

    # 2. Main cabinet outer frame (0.95m W x 0.85m D x 1.88m H) (mat 0)
    add_box_geometry(bm, (0.95, 0.85, 1.84), (0.0, 0.0, 1.04), uv_rect=(0.0, 0.0, 0.5, 0.5), mat_idx=0)

    # 3. Top illuminated marquee sign - angled header (mat 0 with UV mapped to marquee)
    add_box_geometry(bm, (0.96, 0.22, 0.32), (0.0, -0.36, 1.80), rot=(0.14, 0.0, 0.0), uv_rect=(0.5, 0.75, 1.0, 1.0), mat_idx=0)

    # 4. Front display cavity / goods shelves (mat 0)
    add_box_geometry(bm, (0.56, 0.18, 0.95), (-0.16, -0.34, 1.15), uv_rect=(0.0, 0.5, 0.5, 1.0), mat_idx=0)

    # 5. Front glass window pane (mat 1)
    add_box_geometry(bm, (0.58, 0.02, 0.96), (-0.16, -0.43, 1.15), mat_idx=1)

    # 6. Right side control interface & keypad housing (mat 0)
    add_box_geometry(bm, (0.32, 0.16, 0.95), (0.29, -0.35, 1.15), uv_rect=(0.5, 0.0, 0.75, 0.75), mat_idx=0)

    # 7. Bottom dispenser hopper door (mat 0 & mat 3)
    add_box_geometry(bm, (0.76, 0.18, 0.36), (0.0, -0.38, 0.36), uv_rect=(0.75, 0.25, 1.0, 0.75), mat_idx=0)
    # Flap chrome push handle
    add_cylinder_geometry(bm, 0.016, 0.52, (0.0, -0.49, 0.28), rot=(0.0, math.pi/2, 0.0), uv_rect=(0.75, 0.25, 1.0, 0.75), mat_idx=3)

    # 8. Side cooling vents louvers (mat 0)
    for sx in (-0.48, 0.48):
        add_box_geometry(bm, (0.02, 0.52, 0.45), (sx, 0.05, 1.20), uv_rect=(0.75, 0.0, 1.0, 0.25), mat_idx=0)

    # 9. Rear electrical conduit box & cable pipe (mat 3)
    add_box_geometry(bm, (0.22, 0.14, 0.28), (0.22, 0.44, 0.75), uv_rect=(0.75, 0.0, 1.0, 0.25), mat_idx=3)
    add_cylinder_geometry(bm, 0.025, 0.75, (0.22, 0.44, 0.38), rot=(0.0, 0.0, 0.0), uv_rect=(0.75, 0.0, 1.0, 0.25), mat_idx=3)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("VendingMachine_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("VendingMachine", mesh)
    bpy.context.scene.collection.objects.link(obj)

    obj.data.materials.append(mat_main)
    obj.data.materials.append(mat_glass)
    obj.data.materials.append(mat_emissive)
    obj.data.materials.append(mat_steel)

    # Save source blend
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
    print("Saved source blend:", OUT_BLEND)

    # Export GLB
    bpy.ops.export_scene.gltf(filepath=OUT_GLB, export_format='GLB')
    print("Exported Vending Machine GLB:", OUT_GLB)

if __name__ == "__main__":
    build_vending_machine()
