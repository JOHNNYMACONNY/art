#!/usr/bin/env python3
import os
import math
import numpy as np

class OBJMesh:
    def __init__(self, name="mesh"):
        self.name = name
        self.vertices = []
        self.normals = []
        self.uvs = []
        self.faces = []

    def add_vertex(self, x, y, z):
        self.vertices.append((float(x), float(y), float(z)))
        return len(self.vertices)

    def add_normal(self, nx, ny, nz):
        l = math.sqrt(nx*nx + ny*ny + nz*nz)
        if l > 1e-6:
            nx, ny, nz = nx/l, ny/l, nz/l
        else:
            nx, ny, nz = 0.0, 1.0, 0.0
        self.normals.append((float(nx), float(ny), float(nz)))
        return len(self.normals)

    def add_uv(self, u, v):
        self.uvs.append((float(u), float(v)))
        return len(self.uvs)

    def add_tri(self, v1, uv1, n1, v2, uv2, n2, v3, uv3, n3):
        self.faces.append(((v1, uv1, n1), (v2, uv2, n2), (v3, uv3, n3)))

    def add_quad(self, v1, uv1, n1, v2, uv2, n2, v3, uv3, n3, v4, uv4, n4):
        self.add_tri(v1, uv1, n1, v2, uv2, n2, v3, uv3, n3)
        self.add_tri(v1, uv1, n1, v3, uv3, n3, v4, uv4, n4)

    def add_cylinder(self, p1, p2, radius, segments=12, uv_rect=(0.0, 0.0, 1.0, 1.0), caps=True, r2=None):
        if r2 is None:
            r2 = radius
        p1 = np.array(p1, dtype=float)
        p2 = np.array(p2, dtype=float)
        d = p2 - p1
        length = np.linalg.norm(d)
        if length < 1e-6:
            return
        d = d / length

        up = np.array([0.0, 1.0, 0.0]) if abs(d[1]) < 0.9 else np.array([1.0, 0.0, 0.0])
        side = np.cross(d, up)
        side = side / np.linalg.norm(side)
        up = np.cross(side, d)

        u1, v1, u2, v2 = uv_rect
        v1_indices = []
        v2_indices = []
        uv1_indices = []
        uv2_indices = []
        n_indices = []

        for i in range(segments + 1):
            theta = 2.0 * math.pi * (i / segments)
            cos_t = math.cos(theta)
            sin_t = math.sin(theta)
            norm = cos_t * side + sin_t * up
            pt1 = p1 + radius * norm
            pt2 = p2 + r2 * norm

            u_coord = u1 + (u2 - u1) * (i / segments)
            
            idx_v1 = self.add_vertex(pt1[0], pt1[1], pt1[2])
            idx_v2 = self.add_vertex(pt2[0], pt2[1], pt2[2])
            idx_n = self.add_normal(norm[0], norm[1], norm[2])
            idx_uv1 = self.add_uv(u_coord, v2)
            idx_uv2 = self.add_uv(u_coord, v1)

            v1_indices.append(idx_v1)
            v2_indices.append(idx_v2)
            uv1_indices.append(idx_uv1)
            uv2_indices.append(idx_uv2)
            n_indices.append(idx_n)

        for i in range(segments):
            self.add_quad(
                v1_indices[i], uv1_indices[i], n_indices[i],
                v1_indices[i+1], uv1_indices[i+1], n_indices[i+1],
                v2_indices[i+1], uv2_indices[i+1], n_indices[i+1],
                v2_indices[i], uv2_indices[i], n_indices[i]
            )

        if caps:
            n_cap1 = self.add_normal(-d[0], -d[1], -d[2])
            uv_cap1 = self.add_uv((u1+u2)*0.5, (v1+v2)*0.5)
            v_center1 = self.add_vertex(p1[0], p1[1], p1[2])
            for i in range(segments):
                self.add_tri(v_center1, uv_cap1, n_cap1,
                             v1_indices[i+1], uv1_indices[i+1], n_cap1,
                             v1_indices[i], uv1_indices[i], n_cap1)

            n_cap2 = self.add_normal(d[0], d[1], d[2])
            uv_cap2 = self.add_uv((u1+u2)*0.5, (v1+v2)*0.5)
            v_center2 = self.add_vertex(p2[0], p2[1], p2[2])
            for i in range(segments):
                self.add_tri(v_center2, uv_cap2, n_cap2,
                             v2_indices[i], uv2_indices[i], n_cap2,
                             v2_indices[i+1], uv2_indices[i+1], n_cap2)

    def add_box(self, center, size, uv_map=None):
        cx, cy, cz = center
        hx, hy, hz = size[0]*0.5, size[1]*0.5, size[2]*0.5
        def_uv = (0.0, 0.0, 1.0, 1.0)
        if uv_map is None:
            uv_map = {k: def_uv for k in ['+Z', '-Z', '+X', '-X', '+Y', '-Y']}

        def make_face(pts, norm, uv_rect):
            u1, v1, u2, v2 = uv_rect
            n_idx = self.add_normal(norm[0], norm[1], norm[2])
            v_idx = [self.add_vertex(p[0], p[1], p[2]) for p in pts]
            uv_idx = [
                self.add_uv(u1, v2),
                self.add_uv(u2, v2),
                self.add_uv(u2, v1),
                self.add_uv(u1, v1)
            ]
            self.add_quad(v_idx[0], uv_idx[0], n_idx,
                          v_idx[1], uv_idx[1], n_idx,
                          v_idx[2], uv_idx[2], n_idx,
                          v_idx[3], uv_idx[3], n_idx)

        make_face([(cx-hx, cy-hy, cz+hz), (cx+hx, cy-hy, cz+hz), (cx+hx, cy+hy, cz+hz), (cx-hx, cy+hy, cz+hz)], (0, 0, 1), uv_map.get('+Z', def_uv))
        make_face([(cx+hx, cy-hy, cz-hz), (cx-hx, cy-hy, cz-hz), (cx-hx, cy+hy, cz-hz), (cx+hx, cy+hy, cz-hz)], (0, 0, -1), uv_map.get('-Z', def_uv))
        make_face([(cx+hx, cy-hy, cz+hz), (cx+hx, cy-hy, cz-hz), (cx+hx, cy+hy, cz-hz), (cx+hx, cy+hy, cz+hz)], (1, 0, 0), uv_map.get('+X', def_uv))
        make_face([(cx-hx, cy-hy, cz-hz), (cx-hx, cy-hy, cz+hz), (cx-hx, cy+hy, cz+hz), (cx-hx, cy+hy, cz-hz)], (-1, 0, 0), uv_map.get('-X', def_uv))
        make_face([(cx-hx, cy+hy, cz-hz), (cx-hx, cy+hy, cz+hz), (cx+hx, cy+hy, cz+hz), (cx+hx, cy+hy, cz-hz)], (0, 1, 0), uv_map.get('+Y', def_uv))
        make_face([(cx-hx, cy-hy, cz+hz), (cx-hx, cy-hy, cz-hz), (cx+hx, cy-hy, cz-hz), (cx+hx, cy-hy, cz+hz)], (0, -1, 0), uv_map.get('-Y', def_uv))

    def save(self, filepath):
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            f.write(f"# Wavefront OBJ generated for {self.name}\n")
            f.write(f"o {self.name}\n")
            for x, y, z in self.vertices:
                f.write(f"v {x:.5f} {y:.5f} {z:.5f}\n")
            for u, v in self.uvs:
                f.write(f"vt {u:.5f} {1.0 - v:.5f}\n")
            for nx, ny, nz in self.normals:
                f.write(f"vn {nx:.5f} {ny:.5f} {nz:.5f}\n")
            for (v1, uv1, n1), (v2, uv2, n2), (v3, uv3, n3) in self.faces:
                f.write(f"f {v1}/{uv1}/{n1} {v2}/{uv2}/{n2} {v3}/{uv3}/{n3}\n")
        print(f"Saved: {filepath} ({len(self.vertices)} v, {len(self.faces)} f)")


# Highly Calibrated UV Bounds in tex_courier_bike.png (1254x1254)
UV_TANK_SIDE_L = (0.040, 0.080, 0.470, 0.320)
UV_TANK_SIDE_R = (0.470, 0.080, 0.040, 0.320) # Mirrored for right side
UV_TANK_TOP    = (0.150, 0.080, 0.240, 0.120) # Pure clean weathered orange lacquer (no chopped letters!)
UV_METAL_DARK  = (0.750, 0.650, 0.790, 0.710)
UV_BATTERY_L   = (0.535, 0.030, 0.630, 0.335) # Cyan luminous core side
UV_BATTERY_R   = (0.635, 0.030, 0.730, 0.335) # High-voltage caution side
UV_BATTERY_TOP = (0.540, 0.015, 0.720, 0.070)
UV_SEAT_TOP    = (0.760, 0.030, 0.920, 0.390) # Ribbed seams
UV_SEAT_SIDE   = (0.745, 0.100, 0.760, 0.380)
UV_SKID        = (0.210, 0.370, 0.435, 0.565)
UV_CARGO_SIDE  = (0.460, 0.370, 0.785, 0.615)
UV_CARGO_TOP   = (0.460, 0.355, 0.785, 0.440)
UV_TIRE_TREAD  = (0.165, 0.615, 0.278, 0.905)
UV_TIRE_SIDE   = (0.020, 0.620, 0.140, 0.900)
UV_ROTOR       = (0.295, 0.825, 0.425, 0.950)
UV_SPROCKET    = (0.440, 0.850, 0.505, 0.915)
UV_SHOCK       = (0.298, 0.635, 0.340, 0.810)
UV_HEADLIGHT   = (0.425, 0.730, 0.520, 0.830)
UV_HANDLEBAR   = (0.450, 0.790, 0.850, 0.940)
UV_EXHAUST     = (0.665, 0.655, 0.980, 0.830)
UV_PLATE       = (0.905, 0.825, 0.980, 0.905)


def build_wheel(is_rear=False):
    mesh = OBJMesh("wheel_rear" if is_rear else "wheel_front")
    R_crown = 0.355
    R_shoulder = 0.338
    W = 0.22 if is_rear else 0.17
    hw = W * 0.5
    R_rim = 0.245
    R_hub = 0.055
    segments = 24

    # 1. Crowned tire carcass (3 rings: left shoulder, center crown, right shoulder)
    v_l, v_m, v_r = [], [], []
    uv_l, uv_m, uv_r = [], [], []
    n_l, n_m, n_r = [], [], []

    for i in range(segments + 1):
        theta = 2.0 * math.pi * (i / segments)
        ct, st = math.cos(theta), math.sin(theta)

        pt_l = (-hw, R_shoulder * ct, R_shoulder * st)
        pt_m = (0.0, R_crown * ct, R_crown * st)
        pt_r = (hw, R_shoulder * ct, R_shoulder * st)

        norm_l = (-0.3, ct * 0.95, st * 0.95)
        norm_m = (0.0, ct, st)
        norm_r = (0.3, ct * 0.95, st * 0.95)

        t_phase = (i % 6) / 6.0
        u1, v1, u2, v2 = UV_TIRE_TREAD
        vc = v1 + (v2 - v1) * t_phase
        um = (u1 + u2) * 0.5

        v_l.append(mesh.add_vertex(*pt_l))
        v_m.append(mesh.add_vertex(*pt_m))
        v_r.append(mesh.add_vertex(*pt_r))

        n_l.append(mesh.add_normal(*norm_l))
        n_m.append(mesh.add_normal(*norm_m))
        n_r.append(mesh.add_normal(*norm_r))

        uv_l.append(mesh.add_uv(u1, vc))
        uv_m.append(mesh.add_uv(um, vc))
        uv_r.append(mesh.add_uv(u2, vc))

    for i in range(segments):
        # Left half of crown
        mesh.add_quad(
            v_l[i], uv_l[i], n_l[i],
            v_m[i], uv_m[i], n_m[i],
            v_m[i+1], uv_m[i+1], n_m[i+1],
            v_l[i+1], uv_l[i+1], n_l[i+1]
        )
        # Right half of crown
        mesh.add_quad(
            v_m[i], uv_m[i], n_m[i],
            v_r[i], uv_r[i], n_r[i],
            v_r[i+1], uv_r[i+1], n_r[i+1],
            v_m[i+1], uv_m[i+1], n_m[i+1]
        )

    # 2. Staggered Dual-Sport Knobby Tread Lugs
    num_lugs = 20
    lug_h = 0.016
    for l in range(num_lugs):
        theta = 2.0 * math.pi * (l / num_lugs)
        ct, st = math.cos(theta), math.sin(theta)
        lug_len = (2.0 * math.pi * R_crown / num_lugs) * 0.45

        if l % 2 == 0:
            # Center lug
            pos = (0.0, (R_crown + lug_h*0.5) * ct, (R_crown + lug_h*0.5) * st)
            mesh.add_box(pos, (0.05, lug_h, lug_len), uv_map={k: UV_TIRE_TREAD for k in ['+Z','-Z','+X','-X','+Y','-Y']})
        else:
            # Staggered dual shoulder lugs (left and right)
            pos_l = (-hw*0.62, (R_shoulder + lug_h*0.5) * ct, (R_shoulder + lug_h*0.5) * st)
            pos_r = (hw*0.62, (R_shoulder + lug_h*0.5) * ct, (R_shoulder + lug_h*0.5) * st)
            mesh.add_box(pos_l, (hw*0.48, lug_h, lug_len), uv_map={k: UV_TIRE_TREAD for k in ['+Z','-Z','+X','-X','+Y','-Y']})
            mesh.add_box(pos_r, (hw*0.48, lug_h, lug_len), uv_map={k: UV_TIRE_TREAD for k in ['+Z','-Z','+X','-X','+Y','-Y']})

    # 3. Tire sidewalls
    for side, sign in [(-hw, -1.0), (hw, 1.0)]:
        n_side = mesh.add_normal(sign, 0.0, 0.0)
        v_outer = []
        v_inner = []
        uv_outer = []
        uv_inner = []

        su1, sv1, su2, sv2 = UV_TIRE_SIDE
        su_mid, sv_mid = (su1 + su2) * 0.5, (sv1 + sv2) * 0.5
        s_rad = (su2 - su1) * 0.48

        for i in range(segments + 1):
            theta = 2.0 * math.pi * (i / segments)
            ct, st = math.cos(theta), math.sin(theta)

            vo = mesh.add_vertex(side, R_shoulder * ct, R_shoulder * st)
            vi = mesh.add_vertex(side, R_rim * ct, R_rim * st)

            uvo = mesh.add_uv(su_mid + s_rad * ct, sv_mid + s_rad * st)
            uvi = mesh.add_uv(su_mid + s_rad * 0.7 * ct, sv_mid + s_rad * 0.7 * st)

            v_outer.append(vo)
            v_inner.append(vi)
            uv_outer.append(uvo)
            uv_inner.append(uvi)

        for i in range(segments):
            if sign > 0:
                mesh.add_quad(
                    v_inner[i], uv_inner[i], n_side,
                    v_inner[i+1], uv_inner[i+1], n_side,
                    v_outer[i+1], uv_outer[i+1], n_side,
                    v_outer[i], uv_outer[i], n_side
                )
            else:
                mesh.add_quad(
                    v_outer[i], uv_outer[i], n_side,
                    v_outer[i+1], uv_outer[i+1], n_side,
                    v_inner[i+1], uv_inner[i+1], n_side,
                    v_inner[i], uv_inner[i], n_side
                )

    # 4. Sunken Inner Rim Channel
    mesh.add_cylinder((-hw*0.8, 0, 0), (hw*0.8, 0, 0), R_rim, segments=segments, uv_rect=UV_METAL_DARK, caps=False)

    # 5. Center Hub
    mesh.add_cylinder((-hw*0.75, 0, 0), (hw*0.75, 0, 0), R_hub, segments=16, uv_rect=UV_METAL_DARK, caps=True)

    # 6. 16 Crossed Wire Spokes
    num_spokes = 16
    for i in range(num_spokes):
        theta_rim = 2.0 * math.pi * (i / num_spokes)
        theta_hub = theta_rim + (0.35 if (i % 2 == 0) else -0.35)
        hub_x = -hw * 0.55 if (i % 4 < 2) else hw * 0.55
        rim_x = -hw * 0.25 if (i % 4 < 2) else hw * 0.25

        p_hub = (hub_x, R_hub * math.cos(theta_hub), R_hub * math.sin(theta_hub))
        p_rim = (rim_x, (R_rim - 0.01) * math.cos(theta_rim), (R_rim - 0.01) * math.sin(theta_rim))
        mesh.add_cylinder(p_hub, p_rim, 0.0035, segments=4, uv_rect=UV_METAL_DARK, caps=False)

    # 7. Ventilated Brake Rotor Disc
    rotor_x = -hw - 0.01
    n_rot = mesh.add_normal(-1.0, 0.0, 0.0)
    ru1, rv1, ru2, rv2 = UV_ROTOR
    ru_mid, rv_mid = (ru1 + ru2) * 0.5, (rv1 + rv2) * 0.5
    r_rad = (ru2 - ru1) * 0.48
    R_rot = 0.175
    R_rot_in = 0.05
    v_rot_o, v_rot_i = [], []
    uv_rot_o, uv_rot_i = [], []
    for i in range(16 + 1):
        theta = 2.0 * math.pi * (i / 16)
        ct, st = math.cos(theta), math.sin(theta)
        vo = mesh.add_vertex(rotor_x, R_rot * ct, R_rot * st)
        vi = mesh.add_vertex(rotor_x, R_rot_in * ct, R_rot_in * st)
        uvo = mesh.add_uv(ru_mid + r_rad * ct, rv_mid + r_rad * st)
        uvi = mesh.add_uv(ru_mid + r_rad * 0.3 * ct, rv_mid + r_rad * 0.3 * st)
        v_rot_o.append(vo)
        v_rot_i.append(vi)
        uv_rot_o.append(uvo)
        uv_rot_i.append(uvi)
    for i in range(16):
        mesh.add_quad(v_rot_o[i], uv_rot_o[i], n_rot,
                      v_rot_o[i+1], uv_rot_o[i+1], n_rot,
                      v_rot_i[i+1], uv_rot_i[i+1], n_rot,
                      v_rot_i[i], uv_rot_i[i], n_rot)

    # Brake caliper
    mesh.add_box((rotor_x - 0.01, 0.14, -0.06), (0.035, 0.065, 0.08), uv_map={k: UV_METAL_DARK for k in ['+Z','-Z','+X','-X','+Y','-Y']})

    # Rear Wheel Specific: Drive Sprocket & Chain
    if is_rear:
        sproc_x = hw + 0.012
        n_sproc = mesh.add_normal(1.0, 0.0, 0.0)
        su1, sv1, su2, sv2 = UV_SPROCKET
        su_mid, sv_mid = (su1 + su2) * 0.5, (sv1 + sv2) * 0.5
        sp_rad = (su2 - su1) * 0.48
        R_sproc = 0.13
        R_sproc_in = 0.04
        v_sp_o, v_sp_i = [], []
        uv_sp_o, uv_sp_i = [], []
        for i in range(16 + 1):
            theta = 2.0 * math.pi * (i / 16)
            ct, st = math.cos(theta), math.sin(theta)
            vo = mesh.add_vertex(sproc_x, R_sproc * ct, R_sproc * st)
            vi = mesh.add_vertex(sproc_x, R_sproc_in * ct, R_sproc_in * st)
            uvo = mesh.add_uv(su_mid + sp_rad * ct, sv_mid + sp_rad * st)
            uvi = mesh.add_uv(su_mid + sp_rad * 0.3 * ct, sv_mid + sp_rad * 0.3 * st)
            v_sp_o.append(vo)
            v_sp_i.append(vi)
            uv_sp_o.append(uvo)
            uv_sp_i.append(uvi)
        for i in range(16):
            mesh.add_quad(v_sp_i[i], uv_sp_i[i], n_sproc,
                          v_sp_i[i+1], uv_sp_i[i+1], n_sproc,
                          v_sp_o[i+1], uv_sp_o[i+1], n_sproc,
                          v_sp_o[i], uv_sp_o[i], n_sproc)

        mesh.add_cylinder((sproc_x, R_sproc * 0.85, 0.0), (sproc_x, 0.06, -0.73), 0.012, segments=6, uv_rect=UV_METAL_DARK, caps=True)
        mesh.add_cylinder((sproc_x, -R_sproc * 0.85, 0.0), (sproc_x, -0.06, -0.73), 0.012, segments=6, uv_rect=UV_METAL_DARK, caps=True)

    return mesh


def build_front_forks():
    mesh = OBJMesh("bike_front_forks")
    # Front axle at (0, 0.35, -0.92) - Slacker 29-30 deg rake!
    # Triple tree at (0, 0.81, -0.65)
    fork_spacing = 0.125

    for sign in [-1.0, 1.0]:
        x = sign * fork_spacing
        p_axle = (x, 0.35, -0.92)
        p_boot_bottom = (x, 0.51, -0.825)
        p_boot_top = (x, 0.71, -0.705)
        p_clamp_top = (x, 0.82, -0.640)

        # 1. Lower slider
        mesh.add_cylinder(p_axle, p_boot_bottom, 0.024, segments=10, uv_rect=UV_METAL_DARK, caps=True)
        # Axle lug mount
        mesh.add_box((x, 0.35, -0.92), (0.05, 0.06, 0.06), uv_map={k: UV_METAL_DARK for k in ['+Z','-Z','+X','-X','+Y','-Y']})

        # 2. Accordion rubber gaiters
        num_ribs = 6
        for r in range(num_ribs):
            t1 = r / num_ribs
            t2 = (r + 1) / num_ribs
            pr1 = np.array(p_boot_bottom) + (np.array(p_boot_top) - np.array(p_boot_bottom)) * t1
            pr2 = np.array(p_boot_bottom) + (np.array(p_boot_top) - np.array(p_boot_bottom)) * t2
            prmid = (pr1 + pr2) * 0.5
            mesh.add_cylinder(pr1, prmid, 0.022, r2=0.030, segments=8, uv_rect=UV_METAL_DARK, caps=False)
            mesh.add_cylinder(prmid, pr2, 0.030, r2=0.022, segments=8, uv_rect=UV_METAL_DARK, caps=False)

        # 3. Upper stanchion
        mesh.add_cylinder(p_boot_top, p_clamp_top, 0.020, segments=10, uv_rect=UV_METAL_DARK, caps=True)

    # 4. Triple tree clamps
    mesh.add_box((0.0, 0.73, -0.690), (0.32, 0.035, 0.06), uv_map={k: UV_METAL_DARK for k in ['+Z','-Z','+X','-X','+Y','-Y']})
    mesh.add_box((0.0, 0.81, -0.645), (0.32, 0.035, 0.06), uv_map={k: UV_METAL_DARK for k in ['+Z','-Z','+X','-X','+Y','-Y']})
    mesh.add_cylinder((0.0, 0.72, -0.695), (0.0, 0.82, -0.640), 0.022, segments=8, uv_rect=UV_METAL_DARK, caps=True)

    # 5. Extended Scrambler High Front Mudguard / Fender (sweeping forward over tire)
    fender_pts = [
        (0.0, 0.70, -0.66),
        (0.0, 0.65, -0.82),
        (0.0, 0.56, -1.00),
        (0.0, 0.44, -1.10)
    ]
    fw = 0.17
    hfw = fw * 0.5
    uv_fen = UV_TANK_TOP
    for i in range(len(fender_pts) - 1):
        p1 = fender_pts[i]
        p2 = fender_pts[i+1]
        n_up = mesh.add_normal(0.0, 0.8, -0.6)
        v1 = mesh.add_vertex(-hfw, p1[1], p1[2])
        v2 = mesh.add_vertex(hfw, p1[1], p1[2])
        v3 = mesh.add_vertex(hfw, p2[1], p2[2])
        v4 = mesh.add_vertex(-hfw, p2[1], p2[2])

        uv1 = mesh.add_uv(uv_fen[0], uv_fen[1])
        uv2 = mesh.add_uv(uv_fen[2], uv_fen[1])
        uv3 = mesh.add_uv(uv_fen[2], uv_fen[3])
        uv4 = mesh.add_uv(uv_fen[0], uv_fen[3])

        mesh.add_quad(v1, uv1, n_up, v2, uv2, n_up, v3, uv3, n_up, v4, uv4, n_up)

    return mesh


def build_handlebars():
    mesh = OBJMesh("bike_handlebars")
    # Clean riser bar without mesh bloat
    for sign in [-1.0, 1.0]:
        mesh.add_box((sign * 0.08, 0.835, -0.645), (0.035, 0.035, 0.04), uv_map={k: UV_METAL_DARK for k in ['+Z','-Z','+X','-X','+Y','-Y']})

    mesh.add_cylinder((-0.14, 0.85, -0.645), (0.14, 0.85, -0.645), 0.014, segments=8, uv_rect=UV_HANDLEBAR, caps=False)
    for sign in [-1.0, 1.0]:
        p_c = (sign * 0.14, 0.85, -0.645)
        p_b = (sign * 0.26, 0.875, -0.635)
        p_end = (sign * 0.38, 0.865, -0.620)
        mesh.add_cylinder(p_c, p_b, 0.014, segments=8, uv_rect=UV_HANDLEBAR, caps=False)
        mesh.add_cylinder(p_b, p_end, 0.016, segments=10, uv_rect=UV_HANDLEBAR, caps=True)
        mesh.add_cylinder((sign * 0.28, 0.865, -0.635), (sign * 0.36, 0.860, -0.675), 0.005, segments=4, uv_rect=UV_METAL_DARK, caps=True)

        p_stem1 = (sign * 0.24, 0.875, -0.635)
        p_stem2 = (sign * 0.28, 0.965, -0.615)
        mesh.add_cylinder(p_stem1, p_stem2, 0.005, segments=6, uv_rect=UV_METAL_DARK, caps=True)
        mesh.add_cylinder((sign * 0.28, 0.965, -0.615), (sign * 0.28, 0.965, -0.600), 0.040, segments=12, uv_rect=UV_METAL_DARK, caps=True)

    dash_uv = {
        '+Z': UV_METAL_DARK, '-Z': UV_HEADLIGHT, '+X': UV_METAL_DARK, '-X': UV_METAL_DARK,
        '+Y': UV_HEADLIGHT, '-Y': UV_METAL_DARK
    }
    mesh.add_box((0.0, 0.875, -0.650), (0.12, 0.045, 0.07), uv_map=dash_uv)

    return mesh


def build_headlight():
    mesh = OBJMesh("bike_headlight")
    center = (0.0, 0.68, -0.73)
    R = 0.095
    length = 0.12
    p_back = (center[0], center[1], center[2] + length*0.5)
    p_front = (center[0], center[1], center[2] - length*0.5)
    mesh.add_cylinder(p_back, p_front, R, segments=16, uv_rect=UV_METAL_DARK, caps=True)

    n_lens = mesh.add_normal(0.0, 0.0, -1.0)
    hu1, hv1, hu2, hv2 = UV_HEADLIGHT
    hu_mid, hv_mid = (hu1 + hu2) * 0.5, (hv1 + hv2) * 0.5
    h_rad = (hu2 - hu1) * 0.48
    v_lens = []
    uv_lens = []
    v_center = mesh.add_vertex(p_front[0], p_front[1], p_front[2] - 0.005)
    uv_center = mesh.add_uv(hu_mid, hv_mid)

    for i in range(16 + 1):
        theta = 2.0 * math.pi * (i / 16)
        ct, st = math.cos(theta), math.sin(theta)
        v = mesh.add_vertex(center[0] + R * ct, center[1] + R * st, p_front[2] - 0.005)
        uv = mesh.add_uv(hu_mid + h_rad * ct, hv_mid + h_rad * st)
        v_lens.append(v)
        uv_lens.append(uv)

    for i in range(16):
        mesh.add_tri(v_center, uv_center, n_lens,
                     v_lens[i+1], uv_lens[i+1], n_lens,
                     v_lens[i], uv_lens[i], n_lens)

    for sign in [-1.0, 1.0]:
        mesh.add_cylinder((sign * 0.09, center[1], center[2]), (sign * 0.125, center[1], center[2] + 0.04), 0.010, segments=6, uv_rect=UV_METAL_DARK, caps=True)

    return mesh


def build_frame():
    mesh = OBJMesh("bike_frame")
    R_tube = 0.016
    R_sub = 0.013

    # 1. Steering Head Tube
    mesh.add_cylinder((0.0, 0.70, -0.68), (0.0, 0.83, -0.61), 0.026, segments=10, uv_rect=UV_METAL_DARK, caps=True)

    # 2. Main Backbone Tube under tank
    mesh.add_cylinder((0.0, 0.75, -0.62), (0.0, 0.60, 0.05), 0.022, segments=10, uv_rect=UV_METAL_DARK, caps=True)

    # 3. Double-Cradle Down-Tubes (Negative space under frame: y=0.22)
    for sign in [-1.0, 1.0]:
        x = sign * 0.08
        p_head = (x * 0.4, 0.72, -0.63)
        p_front_curve = (x, 0.46, -0.40)
        p_bottom_front = (x, 0.22, -0.32)
        p_bottom_rear = (x, 0.22, 0.05)
        p_pivot = (x * 1.1, 0.34, 0.12)

        mesh.add_cylinder(p_head, p_front_curve, R_tube, segments=8, uv_rect=UV_METAL_DARK, caps=False)
        mesh.add_cylinder(p_front_curve, p_bottom_front, R_tube, segments=8, uv_rect=UV_METAL_DARK, caps=False)
        mesh.add_cylinder(p_bottom_front, p_bottom_rear, R_tube, segments=8, uv_rect=UV_METAL_DARK, caps=False)
        mesh.add_cylinder(p_bottom_rear, p_pivot, R_tube, segments=8, uv_rect=UV_METAL_DARK, caps=False)

        if sign > 0:
            mesh.add_cylinder((-x, 0.22, -0.30), (x, 0.22, -0.30), R_tube, segments=6, uv_rect=UV_METAL_DARK, caps=True)
            mesh.add_cylinder((-x, 0.22, 0.04), (x, 0.22, 0.04), R_tube, segments=6, uv_rect=UV_METAL_DARK, caps=True)

    # 4. Rear Swingarm
    for sign in [-1.0, 1.0]:
        x_piv = sign * 0.10
        x_axle = sign * 0.14
        p_sw_piv = (x_piv, 0.34, 0.12)
        p_sw_axle = (x_axle, 0.35, 0.85)
        mesh.add_box(((x_piv + x_axle)*0.5, 0.345, (0.12 + 0.85)*0.5), (0.028, 0.055, 0.73), uv_map={k: UV_METAL_DARK for k in ['+Z','-Z','+X','-X','+Y','-Y']})
        mesh.add_box((x_axle, 0.35, 0.85), (0.035, 0.07, 0.08), uv_map={k: UV_METAL_DARK for k in ['+Z','-Z','+X','-X','+Y','-Y']})

    mesh.add_cylinder((-0.12, 0.34, 0.12), (0.12, 0.34, 0.12), 0.024, segments=8, uv_rect=UV_METAL_DARK, caps=True)

    # 5. Rear Subframe Loop under seat
    for sign in [-1.0, 1.0]:
        x = sign * 0.11
        p_sub_f = (x, 0.60, 0.05)
        p_sub_r = (x, 0.59, 0.54)
        mesh.add_cylinder(p_sub_f, p_sub_r, R_sub, segments=8, uv_rect=UV_METAL_DARK, caps=False)
        mesh.add_cylinder((x, 0.34, 0.12), (x, 0.59, 0.42), R_sub, segments=8, uv_rect=UV_METAL_DARK, caps=False)

        # Rear twin coilover shock with orange spring!
        p_sh_bot = (sign * 0.13, 0.35, 0.66)
        p_sh_top = (sign * 0.11, 0.58, 0.40)
        mesh.add_cylinder(p_sh_bot, p_sh_top, 0.020, segments=8, uv_rect=UV_SHOCK, caps=True)

        # Footpeg
        mesh.add_cylinder((sign * 0.08, 0.26, 0.05), (sign * 0.22, 0.26, 0.05), 0.015, segments=8, uv_rect=UV_METAL_DARK, caps=True)

    mesh.add_cylinder((-0.11, 0.59, 0.54), (0.11, 0.59, 0.54), R_sub, segments=8, uv_rect=UV_METAL_DARK, caps=True)

    return mesh


def build_tank():
    mesh = OBJMesh("bike_tank")
    # Dynamic hourglass scrambler tank:
    # Wide faceted shoulder (W=0.38m at z=-0.38m)
    # Aggressive taper to narrow waist (W=0.22m at z=-0.05m near rider seat!)
    # Top chamfer shoulders + pure orange top deck!

    # 1. Front Section (z from -0.56 to -0.38): width 0.32 to 0.38
    # 2. Mid Section (z from -0.38 to -0.20): width 0.38 to 0.30
    # 3. Rear Waist (z from -0.20 to -0.04): width 0.30 to 0.22
    
    # We construct sculpted segments:
    tank_uv_side = {
        '+X': UV_TANK_SIDE_R,
        '-X': UV_TANK_SIDE_L,
        '+Y': UV_TANK_TOP,
        '-Y': UV_METAL_DARK,
        '+Z': UV_METAL_DARK,
        '-Z': UV_TANK_TOP
    }
    
    # Front-mid main tank volume
    mesh.add_box((0.0, 0.67, -0.38), (0.36, 0.18, 0.34), uv_map=tank_uv_side)
    # Rear tapered waist volume
    mesh.add_box((0.0, 0.655, -0.12), (0.24, 0.15, 0.22), uv_map=tank_uv_side)
    # Shoulder swells
    mesh.add_box((-0.165, 0.67, -0.36), (0.05, 0.16, 0.26), uv_map={k: UV_TANK_SIDE_L for k in ['+Z','-Z','+X','-X','+Y','-Y']})
    mesh.add_box((0.165, 0.67, -0.36), (0.05, 0.16, 0.26), uv_map={k: UV_TANK_SIDE_R for k in ['+Z','-Z','+X','-X','+Y','-Y']})

    # Top center spine ridge (pure orange lacquer!)
    mesh.add_box((0.0, 0.77, -0.28), (0.16, 0.03, 0.44), uv_map={k: UV_TANK_TOP for k in ['+Z','-Z','+X','-X','+Y','-Y']})

    # Round silver fuel filler cap
    mesh.add_cylinder((0.0, 0.785, -0.36), (0.0, 0.815, -0.36), 0.045, segments=14, uv_rect=UV_METAL_DARK, caps=True)

    return mesh


def build_battery():
    mesh = OBJMesh("bike_battery")
    # Shrunk battery volume (20% volume reduction) to carve daylight pocket under backbone!
    # Height: 0.19m (from y=0.235 to y=0.425). Top of battery is at y=0.425.
    # Backbone is at y=0.60. Daylight clearance = 0.175m (~17cm)!
    center = (0.0, 0.33, -0.14)
    size = (0.18, 0.19, 0.30)
    bat_uv = {
        '+X': UV_BATTERY_R,
        '-X': UV_BATTERY_L,
        '+Y': UV_BATTERY_TOP,
        '-Y': UV_METAL_DARK,
        '+Z': UV_BATTERY_TOP,
        '-Z': UV_BATTERY_TOP
    }
    mesh.add_box(center, size, uv_map=bat_uv)

    # Left-side luminous cell tube
    mesh.add_cylinder((-0.095, 0.26, -0.14), (-0.095, 0.40, -0.14), 0.020, segments=10, uv_rect=UV_BATTERY_L, caps=True)

    # High-voltage orange conduit cables looping from battery top
    mesh.add_cylinder((-0.06, 0.425, -0.20), (-0.06, 0.480, -0.24), 0.008, segments=6, uv_rect=UV_TANK_TOP, caps=True)
    mesh.add_cylinder((0.06, 0.425, -0.20), (0.06, 0.480, -0.24), 0.008, segments=6, uv_rect=UV_TANK_TOP, caps=True)

    # Mounting brackets to cradle
    mesh.add_cylinder((-0.10, 0.24, -0.24), (0.10, 0.24, -0.24), 0.008, segments=6, uv_rect=UV_METAL_DARK, caps=True)
    mesh.add_cylinder((-0.10, 0.24, -0.04), (0.10, 0.24, -0.04), 0.008, segments=6, uv_rect=UV_METAL_DARK, caps=True)

    return mesh


def build_seat():
    mesh = OBJMesh("bike_seat")
    # Pinched scrambler bench saddle:
    # Front width 0.21m (tucks cleanly into tank waist!), rear width 0.26m
    seat_uv = {
        '+Y': UV_SEAT_TOP,
        '-Y': UV_METAL_DARK,
        '+X': UV_SEAT_SIDE,
        '-X': UV_SEAT_SIDE,
        '+Z': UV_SEAT_SIDE,
        '-Z': UV_SEAT_SIDE
    }
    mesh.add_box((0.0, 0.62, 0.22), (0.24, 0.08, 0.52), uv_map=seat_uv)
    mesh.add_cylinder((-0.10, 0.62, 0.46), (0.10, 0.62, 0.46), 0.038, segments=8, uv_rect=UV_SEAT_SIDE, caps=True)

    return mesh


def build_cargo():
    mesh = OBJMesh("bike_cargo")
    R_rack = 0.009
    mesh.add_cylinder((-0.15, 0.62, 0.48), (-0.15, 0.62, 0.86), R_rack, segments=6, uv_rect=UV_METAL_DARK, caps=False)
    mesh.add_cylinder((0.15, 0.62, 0.48), (0.15, 0.62, 0.86), R_rack, segments=6, uv_rect=UV_METAL_DARK, caps=False)
    mesh.add_cylinder((-0.15, 0.62, 0.86), (0.15, 0.62, 0.86), R_rack, segments=6, uv_rect=UV_METAL_DARK, caps=True)
    mesh.add_cylinder((-0.15, 0.62, 0.60), (0.15, 0.62, 0.60), R_rack, segments=6, uv_rect=UV_METAL_DARK, caps=True)
    mesh.add_cylinder((-0.15, 0.62, 0.74), (0.15, 0.62, 0.74), R_rack, segments=6, uv_rect=UV_METAL_DARK, caps=True)

    cargo_uv = {
        '+Z': UV_CARGO_SIDE,
        '-Z': UV_CARGO_SIDE,
        '+X': UV_CARGO_SIDE,
        '-X': UV_CARGO_SIDE,
        '+Y': UV_CARGO_TOP,
        '-Y': UV_METAL_DARK
    }
    mesh.add_box((0.0, 0.73, 0.68), (0.32, 0.20, 0.36), uv_map=cargo_uv)

    mesh.add_cylinder((-0.10, 0.84, 0.68), (0.10, 0.84, 0.68), 0.008, segments=6, uv_rect=UV_METAL_DARK, caps=True)
    mesh.add_cylinder((-0.10, 0.83, 0.68), (-0.10, 0.84, 0.68), 0.008, segments=6, uv_rect=UV_METAL_DARK, caps=False)
    mesh.add_cylinder((0.10, 0.83, 0.68), (0.10, 0.84, 0.68), 0.008, segments=6, uv_rect=UV_METAL_DARK, caps=False)

    mesh.add_box((0.0, 0.58, 0.86), (0.10, 0.04, 0.04), uv_map={k: UV_HEADLIGHT for k in ['+Z','-Z','+X','-X','+Y','-Y']})
    mesh.add_box((0.0, 0.50, 0.86), (0.14, 0.09, 0.01), uv_map={'+Z': UV_PLATE, '-Z': UV_METAL_DARK, '+X': UV_METAL_DARK, '-X': UV_METAL_DARK, '+Y': UV_METAL_DARK, '-Y': UV_METAL_DARK})

    return mesh


def build_skid():
    mesh = OBJMesh("bike_skid")
    pts = [
        (0.0, 0.40, -0.40),
        (0.0, 0.24, -0.32),
        (0.0, 0.19, -0.18),
        (0.0, 0.19, 0.04)
    ]
    sw = 0.20
    hsw = sw * 0.5
    u1, v1, u2, v2 = UV_SKID
    for i in range(len(pts) - 1):
        p1 = pts[i]
        p2 = pts[i+1]
        t1 = i / (len(pts) - 1)
        t2 = (i + 1) / (len(pts) - 1)
        n = mesh.add_normal(0.0, -1.0, 0.2)

        v1_idx = mesh.add_vertex(-hsw, p1[1], p1[2])
        v2_idx = mesh.add_vertex(hsw, p1[1], p1[2])
        v3_idx = mesh.add_vertex(hsw, p2[1], p2[2])
        v4_idx = mesh.add_vertex(-hsw, p2[1], p2[2])

        uv1_idx = mesh.add_uv(u1, v1 + (v2-v1)*t1)
        uv2_idx = mesh.add_uv(u2, v1 + (v2-v1)*t1)
        uv3_idx = mesh.add_uv(u2, v1 + (v2-v1)*t2)
        uv4_idx = mesh.add_uv(u1, v1 + (v2-v1)*t2)

        mesh.add_quad(v1_idx, uv1_idx, n, v2_idx, uv2_idx, n, v3_idx, uv3_idx, n, v4_idx, uv4_idx, n)

    return mesh


def build_exhaust():
    mesh = OBJMesh("bike_exhaust")
    p1 = (0.06, 0.35, -0.20)
    p2 = (0.13, 0.34, -0.08)
    p3 = (0.15, 0.42, 0.10)
    p4 = (0.16, 0.50, 0.32)
    p5 = (0.16, 0.52, 0.64)

    mesh.add_cylinder(p1, p2, 0.016, segments=8, uv_rect=UV_METAL_DARK, caps=False)
    mesh.add_cylinder(p2, p3, 0.016, segments=8, uv_rect=UV_METAL_DARK, caps=False)
    mesh.add_cylinder(p3, p4, 0.018, segments=8, uv_rect=UV_METAL_DARK, caps=False)
    mesh.add_cylinder(p4, p5, 0.038, segments=12, uv_rect=UV_EXHAUST, caps=True)
    p6 = (0.16, 0.53, 0.70)
    mesh.add_cylinder(p5, p6, 0.018, segments=8, uv_rect=UV_METAL_DARK, caps=True)

    return mesh


def main():
    target_dir = "/Users/bobbyinthelobby/{art/godot/models/courier_bike"
    os.makedirs(target_dir, exist_ok=True)

    wheel_front = build_wheel(is_rear=False)
    wheel_front.save(os.path.join(target_dir, "bike_wheel_front.obj"))

    wheel_rear = build_wheel(is_rear=True)
    wheel_rear.save(os.path.join(target_dir, "bike_wheel_rear.obj"))

    forks = build_front_forks()
    forks.save(os.path.join(target_dir, "bike_forks.obj"))

    bars = build_handlebars()
    bars.save(os.path.join(target_dir, "bike_handlebars.obj"))

    headlight = build_headlight()
    headlight.save(os.path.join(target_dir, "bike_headlight.obj"))

    frame = build_frame()
    frame.save(os.path.join(target_dir, "bike_frame.obj"))

    tank = build_tank()
    tank.save(os.path.join(target_dir, "bike_tank.obj"))

    battery = build_battery()
    battery.save(os.path.join(target_dir, "bike_battery.obj"))

    seat = build_seat()
    seat.save(os.path.join(target_dir, "bike_seat.obj"))

    cargo = build_cargo()
    cargo.save(os.path.join(target_dir, "bike_cargo.obj"))

    skid = build_skid()
    skid.save(os.path.join(target_dir, "bike_skid.obj"))

    exhaust = build_exhaust()
    exhaust.save(os.path.join(target_dir, "bike_exhaust.obj"))

    print("All Courier Bike refined models regenerated successfully!")

if __name__ == '__main__':
    main()
