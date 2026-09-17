import subprocess

# Let us adjust capture_storefront.gd lights slightly to bring out rich colors without washout:
# 1. sun energy: 0.85
# 2. fill energy: 0.35
# 3. bay_fill energy: 1.8 (was 3.0)
# 4. shop_light and shop_light2: 2.2 (was 3.2)
# 5. env ambient_light_energy: 0.35 (was 0.45)
# 6. env ambient_light_color: Color(0.40, 0.42, 0.46)
print("Balancing lighting values...")
