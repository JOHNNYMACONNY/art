import bpy
import math
import os

OUT_DIR = os.path.abspath("docs/visual_direction/references")
os.makedirs(OUT_DIR, exist_ok=True)

# Open the blend file
blend_path = os.path.abspath("models_source/vending_machine.blend")
bpy.ops.wm.open_mainfile(filepath=blend_path)

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT'
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

# Add camera
cam_data = bpy.data.cameras.new("RenderCam")
cam_data.lens = 50
cam_obj = bpy.data.objects.new("RenderCam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

# Key light (Front-right)
light_data = bpy.data.lights.new("Sun", type='SUN')
light_data.energy = 3.5
light_obj = bpy.data.objects.new("Sun", light_data)
light_obj.rotation_euler = (math.radians(45), math.radians(30), math.radians(-45))
scene.collection.objects.link(light_obj)

# Side fill light (illuminating side wall)
side_data = bpy.data.lights.new("SideLight", type='SUN')
side_data.energy = 2.0
side_obj = bpy.data.objects.new("SideLight", side_data)
side_obj.rotation_euler = (math.radians(25), math.radians(-50), math.radians(65))
scene.collection.objects.link(side_obj)

# Ambient fill light
fill_data = bpy.data.lights.new("Fill", type='SUN')
fill_data.energy = 1.2
fill_obj = bpy.data.objects.new("Fill", fill_data)
fill_obj.rotation_euler = (math.radians(-30), math.radians(-60), math.radians(120))
scene.collection.objects.link(fill_obj)

def render_view(name, pos, rot, lens=50):
    cam_obj.location = pos
    cam_obj.rotation_euler = rot
    cam_data.lens = lens
    scene.render.filepath = os.path.join(OUT_DIR, f"{name}.png")
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {scene.render.filepath}")

# View 1: Direct Front Elevation
render_view("vending_blender_front", (0.0, -3.2, 1.0), (math.radians(90), 0, 0), lens=55)

# View 2: Isometric 3/4 Perspective
render_view("vending_blender_iso", (2.2, -2.4, 2.0), (math.radians(65), 0, math.radians(42)), lens=50)

# View 3: Close-up Marquee
render_view("vending_blender_marquee", (0.0, -1.8, 1.80), (math.radians(90), 0, 0), lens=75)

# View 4: Close-up Keypad & Display
render_view("vending_blender_mid", (0.05, -1.8, 1.15), (math.radians(90), 0, 0), lens=70)

# View 5: Close-up Hopper
render_view("vending_blender_hopper", (0.0, -1.8, 0.36), (math.radians(90), 0, 0), lens=75)

print("Blender render verification complete.")
