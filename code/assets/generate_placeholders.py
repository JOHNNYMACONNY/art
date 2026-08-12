import os

os.makedirs('code/assets/sprites', exist_ok=True)

# Minimal valid 1x1 transparent PNG base64
TRANSPARENT_PNG_B64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
import base64

def write_placeholder(path):
    with open(path, 'wb') as f:
        f.write(base64.b64decode(TRANSPARENT_PNG_B64))

assets = [
    'code/assets/sprites/jmac.png',
    'code/assets/sprites/fb13.png',
    'code/assets/sprites/hs7.png',
    'code/assets/sprites/civilian.png',
    'code/assets/sprites/police.png',
    'code/assets/sprites/mayor_burn.png',
    'code/assets/sprites/lira.png',
    'code/assets/sprites/sister_kael.png',
    'code/assets/sprites/sedan_beige.png',
    'code/assets/sprites/police_cruiser.png',
    'code/assets/ui/hud_hp.png',
    'code/assets/ui/dialogue_box.png'
]

for a in assets:
    write_placeholder(a)
    print('Created asset placeholder:', a)
