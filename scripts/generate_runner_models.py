import math
import os
import numpy as np

class OBJMesh:
    def __init__(self, name):
        self.name = name
        self.vertices = []
        self.uvs = []
        self.normals = []
        self.faces = []

    def add_vertex(self, x, y, z):
        self.vertices.append((x, y, z))
        return len(self.vertices)

    def add_uv(self, u, v):
        self.uvs.append((u, v))
        return len(self.uvs)

    def add_normal(self, nx, ny, nz):
        self.normals.append((nx, ny, nz))
        return len(self.normals)

    def add_tri(self, v1, uv1, n1, v2, uv2, n2, v3, uv3, n3):
        self.faces.append(((v1, uv1, n1), (v2, uv2, n2), (v3, uv3, n3)))

    def add_quad(self, v1, uv1, n1, v2, uv2, n2, v3, uv3, n3, v4, uv4, n4):
        self.add_tri(v1, uv1, n1, v2, uv2, n2, v3, uv3, n3)
        self.add_tri(v1, uv1, n1, v3, uv3, n3, v4, uv4, n4)

    def add_cylinder(self, p1, p2, radius, segments=8, uv_rect=(0, 0, 1, 1), caps=False):
        p1 = np.array(p1, dtype=float)
        p2 = np.array(p2, dtype=float)
        axis = p2 - p1
        length = np.linalg.norm(axis)
        if length < 1e-6:
            return
        d = axis / length

        up = np.array([0.0, 1.0, 0.0])
        if abs(np.dot(d, up)) > 0.95:
            up = np.array([1.0, 0.0, 0.0])
        u_axis = np.cross(d, up)
        u_axis = u_axis / np.linalg.norm(u_axis)
        v_axis = np.cross(d, u_axis)

        u1, v1, u2, v2 = uv_rect
        v1_indices = []
        v2_indices = []
        uv1_indices = []
        uv2_indices = []

        for i in range(segments + 1):
            theta = 2.0 * math.pi * (i / segments)
            rad_dir = math.cos(theta) * u_axis + math.sin(theta) * v_axis
            pos1 = p1 + radius * rad_dir
            pos2 = p2 + radius * rad_dir

            v1_indices.append(self.add_vertex(pos1[0], pos1[1], pos1[2]))
            v2_indices.append(self.add_vertex(pos2[0], pos2[1], pos2[2]))

            u_coord = u1 + (u2 - u1) * (i / segments)
            uv1_indices.append(self.add_uv(u_coord, v1))
            uv2_indices.append(self.add_uv(u_coord, v2))

        for i in range(segments):
            pt1 = np.array(self.vertices[v1_indices[i] - 1])
            pt2 = np.array(self.vertices[v1_indices[i+1] - 1])
            pt3 = np.array(self.vertices[v2_indices[i+1] - 1])

            geom_norm = np.cross(pt2 - pt1, pt3 - pt1)
            rad_vec = pt1 - p1
            is_outward = (np.dot(geom_norm, rad_vec) >= 0)

            n_unit = geom_norm / (np.linalg.norm(geom_norm) + 1e-8)
            n_idx = self.add_normal(n_unit[0], n_unit[1], n_unit[2])

            if is_outward:
                self.add_quad(v1_indices[i], uv1_indices[i], n_idx,
                              v1_indices[i+1], uv1_indices[i+1], n_idx,
                              v2_indices[i+1], uv2_indices[i+1], n_idx,
                              v2_indices[i], uv2_indices[i], n_idx)
            else:
                n_idx = self.add_normal(-n_unit[0], -n_unit[1], -n_unit[2])
                self.add_quad(v1_indices[i+1], uv1_indices[i+1], n_idx,
                              v1_indices[i], uv1_indices[i], n_idx,
                              v2_indices[i], uv2_indices[i], n_idx,
                              v2_indices[i+1], uv2_indices[i+1], n_idx)

        if caps:
            n_cap1_vec = -d
            n_cap1 = self.add_normal(n_cap1_vec[0], n_cap1_vec[1], n_cap1_vec[2])
            uv_cap1 = self.add_uv((u1+u2)*0.5, (v1+v2)*0.5)
            v_center1 = self.add_vertex(p1[0], p1[1], p1[2])
            p_c1 = p1
            p_u1 = np.array(self.vertices[v1_indices[0] - 1])
            p_u2 = np.array(self.vertices[v1_indices[1] - 1])
            geom_cap1 = np.cross(p_u1 - p_c1, p_u2 - p_c1)
            swap_cap1 = (np.dot(geom_cap1, n_cap1_vec) < 0)
            for i in range(segments):
                if not swap_cap1:
                    self.add_tri(v_center1, uv_cap1, n_cap1,
                                 v1_indices[i+1], uv1_indices[i+1], n_cap1,
                                 v1_indices[i], uv1_indices[i], n_cap1)
                else:
                    self.add_tri(v_center1, uv_cap1, n_cap1,
                                 v1_indices[i], uv1_indices[i], n_cap1,
                                 v1_indices[i+1], uv1_indices[i+1], n_cap1)

            n_cap2_vec = d
            n_cap2 = self.add_normal(n_cap2_vec[0], n_cap2_vec[1], n_cap2_vec[2])
            uv_cap2 = self.add_uv((u1+u2)*0.5, (v1+v2)*0.5)
            v_center2 = self.add_vertex(p2[0], p2[1], p2[2])
            p_c2 = p2
            p_u1 = np.array(self.vertices[v2_indices[0] - 1])
            p_u2 = np.array(self.vertices[v2_indices[1] - 1])
            geom_cap2 = np.cross(p_u1 - p_c2, p_u2 - p_c2)
            swap_cap2 = (np.dot(geom_cap2, n_cap2_vec) < 0)
            for i in range(segments):
                if not swap_cap2:
                    self.add_tri(v_center2, uv_cap2, n_cap2,
                                 v2_indices[i], uv2_indices[i], n_cap2,
                                 v2_indices[i+1], uv2_indices[i+1], n_cap2)
                else:
                    self.add_tri(v_center2, uv_cap2, n_cap2,
                                 v2_indices[i+1], uv2_indices[i+1], n_cap2,
                                 v2_indices[i], uv2_indices[i], n_cap2)

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

        # Strictly verified outward CCW winding:
        # -Z Face (Front)
        make_face([(cx+hx, cy-hy, cz-hz), (cx-hx, cy-hy, cz-hz), (cx-hx, cy+hy, cz-hz), (cx+hx, cy+hy, cz-hz)], (0, 0, -1), uv_map.get('-Z', def_uv))
        # +Z Face (Back)
        make_face([(cx-hx, cy-hy, cz+hz), (cx+hx, cy-hy, cz+hz), (cx+hx, cy+hy, cz+hz), (cx-hx, cy+hy, cz+hz)], (0, 0, 1), uv_map.get('+Z', def_uv))
        # +X Face (Right)
        make_face([(cx+hx, cy-hy, cz+hz), (cx+hx, cy-hy, cz-hz), (cx+hx, cy+hy, cz-hz), (cx+hx, cy+hy, cz+hz)], (1, 0, 0), uv_map.get('+X', def_uv))
        # -X Face (Left)
        make_face([(cx-hx, cy-hy, cz-hz), (cx-hx, cy-hy, cz+hz), (cx-hx, cy+hy, cz+hz), (cx-hx, cy+hy, cz-hz)], (-1, 0, 0), uv_map.get('-X', def_uv))
        # +Y Face (Top)
        make_face([(cx-hx, cy+hy, cz-hz), (cx-hx, cy+hy, cz+hz), (cx+hx, cy+hy, cz+hz), (cx+hx, cy+hy, cz-hz)], (0, 1, 0), uv_map.get('+Y', def_uv))
        # -Y Face (Bottom)
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


# Highly Calibrated UV Bounds in tex_runner_atlas.png (1254x1254)
UV_JACKET_FRONT       = (0.0159, 0.0080, 0.3389, 0.2990)
UV_JACKET_BACK        = (0.3469, 0.0080, 0.5582, 0.2990)
UV_SLEEVE_L           = (0.5662, 0.0199, 0.6978, 0.2911)
UV_SLEEVE_R           = (0.7137, 0.0199, 0.8254, 0.2911)
UV_COLLAR_OUTER       = (0.8413, 0.0120, 0.9888, 0.0558)
UV_COLLAR_INNER       = (0.8413, 0.0678, 0.9888, 0.1276)
UV_JACKET_CUFF        = (0.8453, 0.1396, 0.9848, 0.1754)

UV_HELMET_FRONT       = (0.0159, 0.3349, 0.1196, 0.4625)
UV_HELMET_SIDE_L      = (0.1316, 0.3349, 0.2392, 0.4625)
UV_HELMET_SIDE_R      = (0.2552, 0.3349, 0.3589, 0.4625)
UV_HELMET_BACK        = (0.3708, 0.3349, 0.4585, 0.4625)
UV_HELMET_TOP         = (0.4705, 0.3349, 0.5662, 0.4625)
UV_HELMET_VISOR       = (0.0250, 0.3980, 0.1100, 0.4220)

UV_TELEMETRY_FRONT    = (0.5821, 0.3509, 0.6579, 0.4625)
UV_TELEMETRY_CORE     = (0.6061, 0.3788, 0.6340, 0.4346)
UV_TELEMETRY_SIDE     = (0.6715, 0.3509, 0.7033, 0.4625)
UV_TELEMETRY_BACK     = (0.7177, 0.3509, 0.7815, 0.4625)

UV_SATCHEL_FRONT      = (0.0159, 0.5024, 0.2193, 0.6340)
UV_SATCHEL_BACK       = (0.2352, 0.5024, 0.3788, 0.6340)
UV_SATCHEL_SIDE_L     = (0.3987, 0.5144, 0.4466, 0.6340)
UV_SATCHEL_SIDE_R     = (0.4625, 0.5144, 0.5104, 0.6340)
UV_SATCHEL_STRAP      = (0.5223, 0.5223, 0.7815, 0.5781)

UV_PANTS_FRONT_L      = (0.0678, 0.6818, 0.1236, 0.9649)
UV_PANTS_FRONT_R      = (0.0120, 0.6818, 0.0678, 0.9649)
UV_PANTS_BACK_L       = (0.1316, 0.6818, 0.1834, 0.9649)
UV_PANTS_BACK_R       = (0.1834, 0.6818, 0.2352, 0.9649)
UV_PANTS_SIDE_L       = (0.2432, 0.6818, 0.3030, 0.9649)
UV_PANTS_SIDE_R       = (0.3070, 0.6818, 0.3708, 0.8533)
UV_KNEE_PAD_L         = (0.4904, 0.6818, 0.5742, 0.7775)
UV_KNEE_PAD_R         = (0.5861, 0.6818, 0.6699, 0.7775)

UV_SNEAKER_OUTER      = (0.3788, 0.8333, 0.5144, 0.9649)
UV_SNEAKER_INNER      = (0.5223, 0.8333, 0.6340, 0.9649)
UV_SNEAKER_SOLE       = (0.6419, 0.7895, 0.7137, 0.9689)

UV_GLOVE_BACK_L       = (0.7097, 0.6778, 0.7855, 0.8174)
UV_GLOVE_BACK_R       = (0.7855, 0.6778, 0.8612, 0.8174)
UV_GLOVE_PALM         = (0.8692, 0.6778, 0.9729, 0.8174)
UV_WRIST_CUFFS        = (0.7018, 0.8254, 0.7815, 0.8652)


def build_torso():
    mesh = OBJMesh("runner_torso")
    
    # 6 cross sections with broad athletic V-wedge taper and thoracic forward hunch
    rings_y = [-0.30, -0.20, -0.06, 0.08, 0.16, 0.22]
    dims = [
        (0.180, 0.115, 0.115),  # 0: Waist (athletic cinched)
        (0.198, 0.126, 0.120),  # 1: Lower abdomen
        (0.235, 0.148, 0.135),  # 2: Mid torso
        (0.268, 0.168, 0.145),  # 3: Broad upper chest / lat wedge (broad back!)
        (0.258, 0.158, 0.140),  # 4: Shoulder clavicle level
        (0.205, 0.132, 0.120),  # 5: Shoulder slope
    ]
    # Thoracic forward hunch shifts z forward towards -Z at upper rings
    z_hunch = [0.000, -0.006, -0.018, -0.032, -0.042, -0.048]
    
    v_rings = []
    uv_rings = []
    
    for r_idx, (ry, (hx, zf, zb)) in enumerate(zip(rings_y, dims)):
        zh = z_hunch[r_idx]
        pts = [
            (-hx * 0.55, ry, -zf + zh),          # 0: Front-Left (-Z is front)
            ( hx * 0.55, ry, -zf + zh),          # 1: Front-Right
            ( hx,        ry, -zf * 0.40 + zh),   # 2: Right-Front
            ( hx,        ry,  zb * 0.45 + zh),   # 3: Right-Back
            ( hx * 0.55, ry,  zb + zh),          # 4: Back-Right
            (-hx * 0.55, ry,  zb + zh),          # 5: Back-Left
            (-hx,        ry,  zb * 0.45 + zh),   # 6: Left-Back
            (-hx,        ry, -zf * 0.40 + zh),   # 7: Left-Front
        ]
        
        # Safe v_fac strictly within dark jacket fabric bounds (0.12 to 0.95)
        # Avoids grey image background at v_fac < 0.10
        v_fac = 0.12 + 0.83 * ((ry - rings_y[0]) / (rings_y[-1] - rings_y[0]))
        r_v = []
        r_uv = []
        for i, pt in enumerate(pts):
            idx_v = mesh.add_vertex(pt[0], pt[1], pt[2])
            r_v.append(idx_v)
            
            if i in [0, 1, 7, 2]:
                u_rect = UV_JACKET_FRONT
                u_center = (u_rect[0] + u_rect[2]) * 0.5
                u_span = (u_rect[2] - u_rect[0]) * 0.45
                u = u_center + (pt[0] / hx) * u_span
                v = u_rect[3] - v_fac * (u_rect[3] - u_rect[1])
            else:
                u_rect = UV_JACKET_BACK
                u_center = (u_rect[0] + u_rect[2]) * 0.5
                u_span = (u_rect[2] - u_rect[0]) * 0.45
                u = u_center - (pt[0] / hx) * u_span
                v = u_rect[3] - v_fac * (u_rect[3] - u_rect[1])
                
            idx_uv = mesh.add_uv(u, v)
            r_uv.append(idx_uv)
            
        v_rings.append(r_v)
        uv_rings.append(r_uv)

    # Build torso quads with verified CCW outward winding
    for r in range(len(rings_y) - 1):
        ring_v1 = v_rings[r]
        ring_v2 = v_rings[r+1]
        uv1 = uv_rings[r]
        uv2 = uv_rings[r+1]
        for i in range(8):
            next_i = (i + 1) % 8
            p1 = np.array(mesh.vertices[ring_v1[i]-1])
            p2 = np.array(mesh.vertices[ring_v1[next_i]-1])
            p3 = np.array(mesh.vertices[ring_v2[next_i]-1])
            n_geom = np.cross(p2 - p1, p3 - p1)
            n_rad = np.array([p1[0], 0.0, p1[2]])
            n_unit = n_geom / (np.linalg.norm(n_geom) + 1e-8)
            n_idx = mesh.add_normal(n_unit[0], n_unit[1], n_unit[2])
            if np.dot(n_geom, n_rad) >= 0:
                mesh.add_quad(ring_v1[i], uv1[i], n_idx,
                              ring_v1[next_i], uv1[next_i], n_idx,
                              ring_v2[next_i], uv2[next_i], n_idx,
                              ring_v2[i], uv2[i], n_idx)
            else:
                n_idx = mesh.add_normal(-n_unit[0], -n_unit[1], -n_unit[2])
                mesh.add_quad(ring_v1[next_i], uv1[next_i], n_idx,
                              ring_v1[i], uv1[i], n_idx,
                              ring_v2[i], uv2[i], n_idx,
                              ring_v2[next_i], uv2[next_i], n_idx)

    # Seamless shoulder slope to collar base (y = 0.22 to 0.25, z shifted forward by -0.05)
    neck_base_v = []
    neck_base_uv = []
    for i in range(8):
        theta = 2.0 * math.pi * (i / 8.0)
        nx = math.sin(theta) * 0.105
        nz = -math.cos(theta) * 0.095 - 0.050
        idx_v = mesh.add_vertex(nx, 0.25, nz)
        neck_base_v.append(idx_v)
        if i in [0, 1, 7, 2]:
            u_rect = UV_JACKET_FRONT
            u_center = (u_rect[0] + u_rect[2]) * 0.5
            u_span = (u_rect[2] - u_rect[0]) * 0.40
            u = u_center + (nx / 0.105) * u_span
            v = u_rect[1] + 0.055  # Safe inside dark collar fabric!
        else:
            u_rect = UV_JACKET_BACK
            u_center = (u_rect[0] + u_rect[2]) * 0.5
            u_span = (u_rect[2] - u_rect[0]) * 0.40
            u = u_center - (nx / 0.105) * u_span
            v = u_rect[1] + 0.055  # Safe inside dark dorsal fabric!
        idx_uv = mesh.add_uv(u, v)
        neck_base_uv.append(idx_uv)

    n_sh = mesh.add_normal(0.0, 0.85, 0.1)
    for i in range(8):
        next_i = (i + 1) % 8
        mesh.add_quad(v_rings[-1][next_i], uv_rings[-1][next_i], n_sh,
                      v_rings[-1][i], uv_rings[-1][i], n_sh,
                      neck_base_v[i], neck_base_uv[i], n_sh,
                      neck_base_v[next_i], neck_base_uv[next_i], n_sh)

    # REBUILT RIGID DOUBLE-WALLED FUNNEL STORM COLLAR
    col_out_v = []
    col_out_uv = []
    u_c1, v_c1, u_c2, v_c2 = UV_COLLAR_OUTER
    for i in range(8):
        theta = 2.0 * math.pi * (i / 8.0)
        cowl_lift = 0.025 if i in [0, 1, 7] else 0.0
        cy = 0.36 + cowl_lift
        cx = math.sin(theta) * 0.118
        cz = -math.cos(theta) * 0.108 - 0.052
        idx_v = mesh.add_vertex(cx, cy, cz)
        col_out_v.append(idx_v)
        u = u_c1 + (u_c2 - u_c1) * (i / 8.0)
        idx_uv = mesh.add_uv(u, v_c1)
        col_out_uv.append(idx_uv)

    n_col_out = mesh.add_normal(0.0, 0.20, -0.98)
    for i in range(8):
        next_i = (i + 1) % 8
        uv_b1 = mesh.add_uv(u_c1 + (u_c2 - u_c1) * (i / 8.0), v_c2)
        uv_b2 = mesh.add_uv(u_c1 + (u_c2 - u_c1) * ((i + 1) / 8.0), v_c2)
        mesh.add_quad(neck_base_v[i], uv_b1, n_col_out,
                      col_out_v[i], col_out_uv[i], n_col_out,
                      col_out_v[next_i], col_out_uv[next_i], n_col_out,
                      neck_base_v[next_i], uv_b2, n_col_out)

    col_in_v = []
    col_in_uv = []
    u_in1, v_in1, u_in2, v_in2 = UV_COLLAR_INNER
    for i in range(8):
        theta = 2.0 * math.pi * (i / 8.0)
        cowl_lift = 0.023 if i in [0, 1, 7] else 0.0
        cy = 0.355 + cowl_lift
        cx = math.sin(theta) * 0.102
        cz = -math.cos(theta) * 0.092 - 0.052
        idx_v = mesh.add_vertex(cx, cy, cz)
        col_in_v.append(idx_v)
        u = u_in1 + (u_in2 - u_in1) * (i / 8.0)
        col_in_uv.append(mesh.add_uv(u, v_in1))

    n_rim = mesh.add_normal(0.0, 1.0, 0.0)
    for i in range(8):
        next_i = (i + 1) % 8
        mesh.add_quad(col_out_v[i], col_out_uv[i], n_rim,
                      col_in_v[i], col_in_uv[i], n_rim,
                      col_in_v[next_i], col_in_uv[next_i], n_rim,
                      col_out_v[next_i], col_out_uv[next_i], n_rim)

    v_neck_floor = mesh.add_vertex(0.0, 0.22, -0.052)
    uv_neck_floor = mesh.add_uv((u_in1 + u_in2)*0.5, (v_in1 + v_in2)*0.5)
    n_floor = mesh.add_normal(0.0, 1.0, 0.0)
    for i in range(8):
        next_i = (i + 1) % 8
        mesh.add_tri(v_neck_floor, uv_neck_floor, n_floor,
                     col_in_v[next_i], col_in_uv[next_i], n_floor,
                     col_in_v[i], col_in_uv[i], n_floor)

    v_bot = mesh.add_vertex(0.0, -0.30, 0.0)
    n_bot = mesh.add_normal(0.0, -1.0, 0.0)
    uv_bot = mesh.add_uv(UV_JACKET_CUFF[0], UV_JACKET_CUFF[1])
    for i in range(8):
        next_i = (i + 1) % 8
        mesh.add_tri(v_bot, uv_bot, n_bot,
                     v_rings[0][next_i], uv_bot, n_bot,
                     v_rings[0][i], uv_bot, n_bot)

    # 3D DIAGONAL SATCHEL CROSS-SLING STRAP
    # Runs from RIGHT shoulder (+X) across chest to LEFT hip (-X) to match Candidate B!
    p_f_start = np.array([ 0.15, 0.23, -0.04])   # Right shoulder
    p_f_mid   = np.array([-0.02, 0.06, -0.19])   # Center chest
    p_f_end   = np.array([-0.23,-0.12, -0.08])   # Left hip (satchel entry)
    p_b_start = np.array([ 0.15, 0.23, -0.02])   # Right shoulder back
    p_b_end   = np.array([-0.21,-0.14,  0.13])   # Left lower back

    mesh.add_cylinder(p_f_start, p_f_mid, radius=0.018, segments=6, uv_rect=UV_SATCHEL_STRAP)
    mesh.add_cylinder(p_f_mid, p_f_end, radius=0.018, segments=6, uv_rect=UV_SATCHEL_STRAP)
    mesh.add_cylinder(p_b_start, p_b_end, radius=0.018, segments=6, uv_rect=UV_SATCHEL_STRAP)
    
    # Cam tension buckle at chest center
    mesh.add_box((-0.02, 0.06, -0.20), (0.055, 0.045, 0.018), uv_map={
        '-Z': UV_TELEMETRY_SIDE, '+Z': UV_TELEMETRY_SIDE,
        '+X': UV_TELEMETRY_SIDE, '-X': UV_TELEMETRY_SIDE,
        '+Y': UV_SATCHEL_STRAP,  '-Y': UV_SATCHEL_STRAP
    })

    return mesh


def build_telemetry():
    mesh = OBJMesh("runner_telemetry")
    # Positioned on character RIGHT chest strap (screen left in front view: +X in Godot coordinates!)
    mesh.add_box((0.08, 0.06, -0.185), (0.082, 0.135, 0.024), uv_map={
        '-Z': UV_TELEMETRY_FRONT,
        '+Z': UV_TELEMETRY_BACK,
        '+X': UV_TELEMETRY_SIDE,
        '-X': UV_TELEMETRY_SIDE,
        '+Y': UV_TELEMETRY_SIDE,
        '-Y': UV_TELEMETRY_SIDE
    })
    # Mounting bracket ears
    mesh.add_box((0.08, 0.135, -0.180), (0.092, 0.016, 0.016), uv_map={
        '-Z': UV_TELEMETRY_SIDE, '+Z': UV_TELEMETRY_SIDE,
        '+X': UV_TELEMETRY_SIDE, '-X': UV_TELEMETRY_SIDE,
        '+Y': UV_TELEMETRY_SIDE, '-Y': UV_TELEMETRY_SIDE
    })
    mesh.add_box((0.08, -0.015, -0.180), (0.092, 0.016, 0.016), uv_map={
        '-Z': UV_TELEMETRY_SIDE, '+Z': UV_TELEMETRY_SIDE,
        '+X': UV_TELEMETRY_SIDE, '-X': UV_TELEMETRY_SIDE,
        '+Y': UV_TELEMETRY_SIDE, '-Y': UV_TELEMETRY_SIDE
    })
    return mesh


def build_telemetry_core():
    mesh = OBJMesh("runner_telemetry_core")
    # Recessed glowing cyan power cell (inset inside telemetry housing at +X)
    mesh.add_box((0.08, 0.06, -0.198), (0.038, 0.072, 0.006), uv_map={
        '-Z': UV_TELEMETRY_CORE,
        '+Z': UV_TELEMETRY_CORE,
        '+X': UV_TELEMETRY_CORE,
        '-X': UV_TELEMETRY_CORE,
        '+Y': UV_TELEMETRY_CORE,
        '-Y': UV_TELEMETRY_CORE
    })
    return mesh


def build_satchel():
    mesh = OBJMesh("runner_satchel")
    # TRIPLED VOLUME on LEFT FLANK (cx = -0.24, projects outward to x = -0.36!)
    # Matches Candidate B reference perfectly!
    cx, cy, cz = -0.24, -0.12, 0.05
    w, h, d = 0.24, 0.26, 0.35
    
    # 1. Main Bag Body (heavy tarpaulin messenger bag)
    mesh.add_box((cx, cy, cz), (w, h, d), uv_map={
        '-X': UV_SATCHEL_SIDE_L, # Outer flank face
        '+X': UV_SATCHEL_SIDE_R, # Inner body-facing face
        '+Z': UV_SATCHEL_BACK,
        '-Z': UV_SATCHEL_FRONT,
        '+Y': UV_SATCHEL_STRAP,
        '-Y': UV_SATCHEL_STRAP
    })
    
    # 2. Rolltop Fold upper wedge
    mesh.add_box((cx, cy + h*0.5 + 0.035, cz - 0.02), (w * 0.88, 0.070, d * 0.75), uv_map={
        '-X': UV_SATCHEL_SIDE_L,
        '+X': UV_SATCHEL_SIDE_R,
        '+Z': UV_SATCHEL_BACK,
        '-Z': UV_SATCHEL_FRONT,
        '+Y': UV_SATCHEL_STRAP,
        '-Y': UV_SATCHEL_STRAP
    })
    
    # 3. Heavy Outer Messenger Flap with "COURIER" stencil across outer face (-X)
    mesh.add_box((cx - 0.012, cy - 0.015, cz), (0.024, h * 0.82, d * 0.94), uv_map={
        '-X': UV_SATCHEL_FRONT, # "COURIER" stencil boldly visible on left flank!
        '+X': UV_SATCHEL_BACK,
        '+Z': UV_SATCHEL_STRAP,
        '-Z': UV_SATCHEL_STRAP,
        '+Y': UV_SATCHEL_STRAP,
        '-Y': UV_SATCHEL_STRAP
    })
    
    # 4. Two Heavy 3D Webbing Straps and metal buckles running vertically across flap
    for z_off in [-0.09, 0.09]:
        mesh.add_box((cx - 0.025, cy - 0.015, cz + z_off), (0.012, h * 0.84, 0.034), uv_map={
            '-X': UV_SATCHEL_STRAP, '+X': UV_SATCHEL_STRAP,
            '+Z': UV_SATCHEL_STRAP, '-Z': UV_SATCHEL_STRAP,
            '+Y': UV_SATCHEL_STRAP, '-Y': UV_SATCHEL_STRAP
        })
        mesh.add_box((cx - 0.033, cy - 0.08, cz + z_off), (0.014, 0.040, 0.038), uv_map={
            '-X': UV_TELEMETRY_SIDE, '+X': UV_TELEMETRY_SIDE,
            '+Z': UV_TELEMETRY_SIDE, '-Z': UV_TELEMETRY_SIDE,
            '+Y': UV_TELEMETRY_SIDE, '-Y': UV_TELEMETRY_SIDE
        })

    return mesh


def build_helmet():
    mesh = OBJMesh("runner_helmet")
    
    # Scaled down by 20% to eliminate bobblehead ratio
    rings_y = [-0.11, -0.05, 0.02, 0.09, 0.135]
    rings_geom = [
        (0.082, 0.098, 0.074),  # 0: Jaw / Chin
        (0.106, 0.126, 0.094),  # 1: Brow / Visor level
        (0.112, 0.134, 0.106),  # 2: Temples
        (0.104, 0.114, 0.102),  # 3: Upper cranium
        (0.056, 0.060, 0.060),  # 4: Top apex
    ]
    
    v_rings = []
    for ry, (hx, zf, zb) in zip(rings_y, rings_geom):
        pts = [
            (-hx * 0.45, ry, -zf),          # 0: Front-Left (-Z is Front)
            ( hx * 0.45, ry, -zf),          # 1: Front-Right
            ( hx,        ry, -zf * 0.35),   # 2: Right Temple
            ( hx * 0.95, ry,  zb * 0.50),   # 3: Back-Right
            ( hx * 0.45, ry,  zb),          # 4: Back-Right Center (+Z is Back)
            (-hx * 0.45, ry,  zb),          # 5: Back-Left Center
            (-hx * 0.95, ry,  zb * 0.50),   # 6: Back-Left
            (-hx,        ry, -zf * 0.35),   # 7: Left Temple
        ]
        r_v = []
        for pt in pts:
            r_v.append(mesh.add_vertex(pt[0], pt[1], pt[2]))
        v_rings.append(r_v)

    for r in range(len(rings_y) - 1):
        v1 = v_rings[r]
        v2 = v_rings[r+1]
        
        y_bot = rings_y[r]
        y_top = rings_y[r+1]
        v_fac_bot = (y_bot - rings_y[0]) / (rings_y[-1] - rings_y[0])
        v_fac_top = (y_top - rings_y[0]) / (rings_y[-1] - rings_y[0])
        
        for i in range(8):
            next_i = (i + 1) % 8
            
            if i in [0, 1, 7]:
                u_rect = UV_HELMET_FRONT
                if i == 7:
                    u_a, u_b = u_rect[0], u_rect[0] + (u_rect[2]-u_rect[0])*0.30
                elif i == 0:
                    u_a, u_b = u_rect[0] + (u_rect[2]-u_rect[0])*0.30, u_rect[0] + (u_rect[2]-u_rect[0])*0.70
                else: # 1
                    u_a, u_b = u_rect[0] + (u_rect[2]-u_rect[0])*0.70, u_rect[2]
            elif i == 2:
                u_rect = UV_HELMET_SIDE_R
                u_a, u_b = u_rect[2], u_rect[0]
            elif i in [3, 4, 5]:
                u_rect = UV_HELMET_BACK
                if i == 3:
                    u_a, u_b = u_rect[2], u_rect[0] + (u_rect[2]-u_rect[0])*0.65
                elif i == 4:
                    u_a, u_b = u_rect[0] + (u_rect[2]-u_rect[0])*0.65, u_rect[0] + (u_rect[2]-u_rect[0])*0.35
                else: # 5
                    u_a, u_b = u_rect[0] + (u_rect[2]-u_rect[0])*0.35, u_rect[0]
            else: # 6
                u_rect = UV_HELMET_SIDE_L
                u_a, u_b = u_rect[2], u_rect[0]
                
            va = u_rect[3] - (u_rect[3] - u_rect[1]) * v_fac_bot
            vb = u_rect[3] - (u_rect[3] - u_rect[1]) * v_fac_top
            
            p1 = np.array(mesh.vertices[v1[i]-1])
            p2 = np.array(mesh.vertices[v1[next_i]-1])
            p3 = np.array(mesh.vertices[v2[next_i]-1])
            norm = np.cross(p2 - p1, p3 - p1)
            norm = norm / np.linalg.norm(norm)
            n_idx = mesh.add_normal(norm[0], norm[1], norm[2])
            
            uv1_idx = mesh.add_uv(u_a, va)
            uv2_idx = mesh.add_uv(u_b, va)
            uv3_idx = mesh.add_uv(u_b, vb)
            uv4_idx = mesh.add_uv(u_a, vb)
            
            mesh.add_quad(v1[i], uv1_idx, n_idx,
                          v1[next_i], uv2_idx, n_idx,
                          v2[next_i], uv3_idx, n_idx,
                          v2[i], uv4_idx, n_idx)

    # Dome top cap with strictly FORWARD-POINTING DIRECTIONAL HEADING TRIANGLE!
    # In crop_helmet_top.png: triangle points toward lower v!
    # Front is -Z: so when pt[2] is -0.10, v must be lower (triangle apex pointing forward)!
    v_top_center = mesh.add_vertex(0.0, 0.145, 0.0)
    n_top = mesh.add_normal(0.0, 1.0, 0.0)
    u_c = (UV_HELMET_TOP[0] + UV_HELMET_TOP[2]) * 0.5
    v_c = (UV_HELMET_TOP[1] + UV_HELMET_TOP[3]) * 0.5
    u_hw = (UV_HELMET_TOP[2] - UV_HELMET_TOP[0]) * 0.5
    v_hh = (UV_HELMET_TOP[3] - UV_HELMET_TOP[1]) * 0.5
    uv_top_center = mesh.add_uv(u_c, v_c)
    
    top_ring = v_rings[-1]
    top_uvs = []
    for idx_v in top_ring:
        pt = mesh.vertices[idx_v - 1]
        u_pt = u_c + (pt[0] / 0.10) * u_hw * 0.95
        # v_pt increases with pt[2] so -Z gives lower v (triangle apex points forward):
        v_pt = v_c + (pt[2] / 0.10) * v_hh * 0.95
        top_uvs.append(mesh.add_uv(u_pt, v_pt))
        
    for i in range(8):
        next_i = (i + 1) % 8
        mesh.add_tri(v_top_center, uv_top_center, n_top,
                     top_ring[next_i], top_uvs[next_i], n_top,
                     top_ring[i], top_uvs[i], n_top)

    # SCULPTED 3D AERODYNAMIC DORSAL CREST RIDGE
    # Diffuse albedo only (no emission, prevents bloom blowout!)
    mesh.add_box((0.0, 0.150, 0.005), (0.038, 0.032, 0.185), uv_map={
        '+Y': UV_HELMET_TOP,
        '-Y': UV_HELMET_TOP,
        '+X': UV_HELMET_SIDE_R,
        '-X': UV_HELMET_SIDE_L,
        '-Z': UV_HELMET_FRONT,
        '+Z': UV_HELMET_BACK
    })

    # Ear Discs
    for sign in [-1.0, 1.0]:
        x_ear = sign * 0.114
        uv_ear = UV_HELMET_SIDE_L if sign < 0 else UV_HELMET_SIDE_R
        mesh.add_cylinder((x_ear * 0.95, 0.0, -0.01), (x_ear * 1.05, 0.0, -0.01), 0.028, segments=8, uv_rect=uv_ear, caps=True)

    # Rear Spoiler Fin
    mesh.add_box((0.0, 0.05, 0.108), (0.046, 0.060, 0.022), uv_map={
        '+Z': UV_HELMET_BACK, '-Z': UV_HELMET_BACK,
        '+X': UV_HELMET_SIDE_R, '-X': UV_HELMET_SIDE_L,
        '+Y': UV_HELMET_TOP, '-Y': UV_HELMET_BACK
    })

    # Matte Black Visor Brow Bezel
    mesh.add_box((0.0, 0.030, -0.126), (0.130, 0.022, 0.018), uv_map={
        '-Z': UV_HELMET_FRONT, '+Z': UV_HELMET_FRONT,
        '+X': UV_HELMET_SIDE_R, '-X': UV_HELMET_SIDE_L,
        '+Y': UV_HELMET_FRONT, '-Y': UV_HELMET_FRONT
    })
    mesh.add_box((0.0, -0.025, -0.122), (0.120, 0.022, 0.018), uv_map={
        '-Z': UV_HELMET_FRONT, '+Z': UV_HELMET_FRONT,
        '+X': UV_HELMET_SIDE_R, '-X': UV_HELMET_SIDE_L,
        '+Y': UV_HELMET_FRONT, '-Y': UV_HELMET_FRONT
    })

    return mesh


def build_visor():
    mesh = OBJMesh("runner_visor")
    segments = 8
    r_curve = 0.130
    
    v_top = []
    v_bot = []
    uv_top = []
    uv_bot = []
    
    y_b = -0.006
    y_t =  0.020
    
    u1, v1, u2, v2 = UV_HELMET_VISOR
    
    for i in range(segments + 1):
        frac = i / segments
        angle = -0.50 + frac * 1.00
        
        x = math.sin(angle) * r_curve
        z = -math.cos(angle) * r_curve
        
        idx_b = mesh.add_vertex(x, y_b, z)
        idx_t = mesh.add_vertex(x, y_t, z)
        
        u = u1 + (u2 - u1) * frac
        idx_uv_b = mesh.add_uv(u, v2)
        idx_uv_t = mesh.add_uv(u, v1)
        
        v_bot.append(idx_b)
        v_top.append(idx_t)
        uv_bot.append(idx_uv_b)
        uv_top.append(idx_uv_t)
        
    for i in range(segments):
        p1 = np.array(mesh.vertices[v_bot[i]-1])
        p2 = np.array(mesh.vertices[v_bot[i+1]-1])
        p3 = np.array(mesh.vertices[v_top[i+1]-1])
        norm = np.cross(p2 - p1, p3 - p1)
        norm = norm / np.linalg.norm(norm)
        n_idx = mesh.add_normal(norm[0], norm[1], norm[2])
        
        mesh.add_quad(v_bot[i], uv_bot[i], n_idx,
                      v_bot[i+1], uv_bot[i+1], n_idx,
                      v_top[i+1], uv_top[i+1], n_idx,
                      v_top[i], uv_top[i], n_idx)
        
    return mesh


def build_arm(is_left=True):
    mesh = OBJMesh("runner_arm_left" if is_left else "runner_arm_right")
    u_sleeve = UV_SLEEVE_L if is_left else UV_SLEEVE_R
    u1, v1, u2, v2 = u_sleeve

    rings_y = [0.02, -0.07, -0.16, -0.25, -0.32, -0.44, -0.46, -0.50]
    z_flex = [0.0, 0.005, 0.012, 0.018, 0.008, -0.015, -0.018, -0.022]
    radii = [
        (0.090, 0.086), # Deltoid top
        (0.086, 0.082), # Deltoid bell
        (0.078, 0.074), # Bicep mid
        (0.070, 0.068), # Elbow flexion
        (0.066, 0.062), # Forearm upper
        (0.056, 0.054), # Forearm lower
        (0.060, 0.058), # Cuff upper ring
        (0.058, 0.056), # Cuff lower ring
    ]

    v_rings = []
    uv_rings = []

    for r_idx, (ry, (rx, rz)) in enumerate(zip(rings_y, radii)):
        r_v = []
        r_uv = []
        zf = z_flex[r_idx]
        
        if r_idx <= 5:
            v_frac = (rings_y[0] - ry) / (rings_y[0] - rings_y[5])
            v_val = (v1 + 0.01) + (v2 - v1 - 0.02) * v_frac
        else:
            v_frac = (rings_y[6] - ry) / (rings_y[6] - rings_y[7])
            v_val = UV_JACKET_CUFF[1] + (UV_JACKET_CUFF[3] - UV_JACKET_CUFF[1]) * v_frac

        for i in range(8):
            ang = 2.0 * math.pi * (i / 8.0)
            x_sign = -1.0 if is_left else 1.0
            px = math.sin(ang) * rx * x_sign
            pz = -math.cos(ang) * rz + zf
            idx_v = mesh.add_vertex(px, ry, pz)
            r_v.append(idx_v)

            if r_idx <= 5:
                if is_left:
                    u_map = [0.22, 0.40, 0.60, 0.80, 0.95, 1.00, 0.00, 0.10]
                else:
                    u_map = [0.75, 0.55, 0.35, 0.20, 0.05, 0.00, 1.00, 0.90]
                u_val = u1 + (u2 - u1) * u_map[i]
            else:
                u_c1, _, u_c2, _ = UV_JACKET_CUFF
                u_map_cuff = [0.50, 0.75, 1.00, 0.85, 0.50, 0.25, 0.00, 0.25]
                u_val = u_c1 + (u_c2 - u_c1) * u_map_cuff[i]

            idx_uv = mesh.add_uv(u_val, v_val)
            r_uv.append(idx_uv)

        v_rings.append(r_v)
        uv_rings.append(r_uv)

    for r in range(len(rings_y) - 1):
        ring_v1 = v_rings[r]
        ring_v2 = v_rings[r+1]
        uv1 = uv_rings[r]
        uv2 = uv_rings[r+1]

        for i in range(8):
            next_i = (i + 1) % 8
            p1 = np.array(mesh.vertices[ring_v1[i]-1])
            p2 = np.array(mesh.vertices[ring_v1[next_i]-1])
            p3 = np.array(mesh.vertices[ring_v2[next_i]-1])
            n_rad = np.array([p1[0], 0.0, p1[2]])
            n_geom = np.cross(p2 - p1, p3 - p1)
            n_unit = n_geom / (np.linalg.norm(n_geom) + 1e-8)
            n_idx = mesh.add_normal(n_unit[0], n_unit[1], n_unit[2])

            if np.dot(n_geom, n_rad) >= 0:
                mesh.add_quad(ring_v1[i], uv1[i], n_idx,
                              ring_v1[next_i], uv1[next_i], n_idx,
                              ring_v2[next_i], uv2[next_i], n_idx,
                              ring_v2[i], uv2[i], n_idx)
            else:
                n_idx = mesh.add_normal(-n_unit[0], -n_unit[1], -n_unit[2])
                mesh.add_quad(ring_v1[next_i], uv1[next_i], n_idx,
                              ring_v1[i], uv1[i], n_idx,
                              ring_v2[i], uv2[i], n_idx,
                              ring_v2[next_i], uv2[next_i], n_idx)

    x_inward = 0.040 if is_left else -0.040
    v_top_sh = mesh.add_vertex(x_inward, 0.025, 0.0)
    n_top_sh = mesh.add_normal(0.0, 1.0, 0.0)
    uv_top_sh = mesh.add_uv((u1 + u2)*0.5, v1 + 0.005)
    p_top = np.array([x_inward, 0.025, 0.0])
    for i in range(8):
        next_i = (i + 1) % 8
        pa = p_top
        pb = np.array(mesh.vertices[v_rings[0][i]-1])
        pc = np.array(mesh.vertices[v_rings[0][next_i]-1])
        n_cap = np.cross(pb - pa, pc - pa)
        if n_cap[1] >= 0:
            mesh.add_tri(v_top_sh, uv_top_sh, n_top_sh,
                         v_rings[0][i], uv_rings[0][i], n_top_sh,
                         v_rings[0][next_i], uv_rings[0][next_i], n_top_sh)
        else:
            mesh.add_tri(v_top_sh, uv_top_sh, n_top_sh,
                         v_rings[0][next_i], uv_rings[0][next_i], n_top_sh,
                         v_rings[0][i], uv_rings[0][i], n_top_sh)

    uv_glove = UV_GLOVE_BACK_L if is_left else UV_GLOVE_BACK_R
    mesh.add_box((0.0, -0.56, -0.022), (0.076, 0.100, 0.054), uv_map={
        '-Z': uv_glove,
        '+Z': UV_GLOVE_PALM,
        '-X': uv_glove if is_left else UV_GLOVE_PALM,
        '+X': UV_GLOVE_PALM if is_left else uv_glove,
        '+Y': UV_WRIST_CUFFS,
        '-Y': uv_glove
    })

    mesh.add_box((0.0, -0.55, -0.052), (0.070, 0.040, 0.012), uv_map={
        '-Z': uv_glove, '+Z': uv_glove,
        '-X': uv_glove, '+X': uv_glove,
        '+Y': uv_glove, '-Y': uv_glove
    })

    mesh.add_box((0.0, -0.61, -0.030), (0.068, 0.060, 0.044), uv_map={
        '-Z': uv_glove,
        '+Z': UV_GLOVE_PALM,
        '-X': uv_glove if is_left else UV_GLOVE_PALM,
        '+X': UV_GLOVE_PALM if is_left else uv_glove,
        '+Y': uv_glove,
        '-Y': UV_GLOVE_PALM
    })

    return mesh


def build_leg(is_left=True):
    mesh = OBJMesh("runner_leg_left" if is_left else "runner_leg_right")
    uv_pants_f = UV_PANTS_FRONT_L if is_left else UV_PANTS_FRONT_R
    uv_pants_b = UV_PANTS_BACK_L if is_left else UV_PANTS_BACK_R
    uv_pants_s = UV_PANTS_SIDE_L if is_left else UV_PANTS_SIDE_R
    uv_kneepad = UV_KNEE_PAD_L if is_left else UV_KNEE_PAD_R

    rings_y = [0.02, -0.12, -0.26, -0.38, -0.46, -0.56, -0.64, -0.68]
    z_knee_flex = [0.0, -0.005, -0.012, -0.022, -0.018, -0.006, 0.0, 0.0]
    radii = [
        (0.096, 0.092), # Hip connection
        (0.090, 0.086), # Upper Thigh
        (0.084, 0.080), # Mid Thigh
        (0.076, 0.074), # Knee upper
        (0.074, 0.072), # Knee lower
        (0.068, 0.064), # Calf mid
        (0.060, 0.058), # Ankle cinch top
        (0.058, 0.056), # Ankle cinch bot
    ]

    v_rings = []
    uv_rings = []

    for r_idx, (ry, (rx, rz)) in enumerate(zip(rings_y, radii)):
        r_v = []
        r_uv = []
        zk = z_knee_flex[r_idx]
        v_fac = (rings_y[0] - ry) / (rings_y[0] - rings_y[-1])

        vf = uv_pants_f[1] + (uv_pants_f[3] - uv_pants_f[1]) * v_fac
        vs = uv_pants_s[1] + (uv_pants_s[3] - uv_pants_s[1]) * v_fac
        vb = uv_pants_b[1] + (uv_pants_b[3] - uv_pants_b[1]) * v_fac

        for i in range(8):
            ang = 2.0 * math.pi * (i / 8.0)
            x_sign = -1.0 if is_left else 1.0
            px = math.sin(ang) * rx * x_sign
            pz = -math.cos(ang) * rz + zk
            idx_v = mesh.add_vertex(px, ry, pz)
            r_v.append(idx_v)

            if i in [7, 0, 1]:
                u_center = (uv_pants_f[0] + uv_pants_f[2]) * 0.5
                u_span = (uv_pants_f[2] - uv_pants_f[0]) * 0.48
                u_val = u_center + (px / rx) * u_span
                v_val = vf
            elif i in [2, 3]:
                u_center = (uv_pants_s[0] + uv_pants_s[2]) * 0.5
                u_span = (uv_pants_s[2] - uv_pants_s[0]) * 0.48
                u_val = u_center + (pz / rz) * u_span
                v_val = vs
            elif i in [4, 5]:
                u_center = (uv_pants_b[0] + uv_pants_b[2]) * 0.5
                u_span = (uv_pants_b[2] - uv_pants_b[0]) * 0.48
                u_val = u_center - (px / rx) * u_span
                v_val = vb
            else: # 6
                u_val = uv_pants_f[0] + 0.005
                v_val = vf

            idx_uv = mesh.add_uv(u_val, v_val)
            r_uv.append(idx_uv)

        v_rings.append(r_v)
        uv_rings.append(r_uv)

    for r in range(len(rings_y) - 1):
        ring_v1 = v_rings[r]
        ring_v2 = v_rings[r+1]
        uv1 = uv_rings[r]
        uv2 = uv_rings[r+1]

        for i in range(8):
            next_i = (i + 1) % 8
            p1 = np.array(mesh.vertices[ring_v1[i]-1])
            p2 = np.array(mesh.vertices[ring_v1[next_i]-1])
            p3 = np.array(mesh.vertices[ring_v2[next_i]-1])
            n_rad = np.array([p1[0], 0.0, p1[2]])
            n_geom = np.cross(p2 - p1, p3 - p1)
            n_unit = n_geom / (np.linalg.norm(n_geom) + 1e-8)
            n_idx = mesh.add_normal(n_unit[0], n_unit[1], n_unit[2])

            if np.dot(n_geom, n_rad) >= 0:
                mesh.add_quad(ring_v1[i], uv1[i], n_idx,
                              ring_v1[next_i], uv1[next_i], n_idx,
                              ring_v2[next_i], uv2[next_i], n_idx,
                              ring_v2[i], uv2[i], n_idx)
            else:
                n_idx = mesh.add_normal(-n_unit[0], -n_unit[1], -n_unit[2])
                mesh.add_quad(ring_v1[next_i], uv1[next_i], n_idx,
                              ring_v1[i], uv1[i], n_idx,
                              ring_v2[i], uv2[i], n_idx,
                              ring_v2[next_i], uv2[next_i], n_idx)

    v_top_hip = mesh.add_vertex(0.0, 0.025, 0.0)
    n_top_hip = mesh.add_normal(0.0, 1.0, 0.0)
    uv_top_hip = mesh.add_uv(uv_pants_f[0], uv_pants_f[1])
    p_top_h = np.array([0.0, 0.025, 0.0])
    for i in range(8):
        next_i = (i + 1) % 8
        pa = p_top_h
        pb = np.array(mesh.vertices[v_rings[0][i]-1])
        pc = np.array(mesh.vertices[v_rings[0][next_i]-1])
        n_cap = np.cross(pb - pa, pc - pa)
        if n_cap[1] >= 0:
            mesh.add_tri(v_top_hip, uv_top_hip, n_top_hip,
                         v_rings[0][i], uv_rings[0][i], n_top_hip,
                         v_rings[0][next_i], uv_rings[0][next_i], n_top_hip)
        else:
            mesh.add_tri(v_top_hip, uv_top_hip, n_top_hip,
                         v_rings[0][next_i], uv_rings[0][next_i], n_top_hip,
                         v_rings[0][i], uv_rings[0][i], n_top_hip)

    # Contoured Bellows Cargo Pocket
    x_pouch = -0.090 if is_left else 0.090
    mesh.add_box((x_pouch, -0.22, -0.012), (0.024, 0.135, 0.096), uv_map={
        '-X': uv_pants_s if is_left else uv_pants_f,
        '+X': uv_pants_f if is_left else uv_pants_s,
        '-Z': uv_pants_s, '+Z': uv_pants_s,
        '+Y': uv_pants_s, '-Y': uv_pants_s
    })
    mesh.add_box((x_pouch * 1.08, -0.155, -0.012), (0.014, 0.035, 0.100), uv_map={
        '-X': uv_pants_s if is_left else uv_pants_f,
        '+X': uv_pants_f if is_left else uv_pants_s,
        '-Z': UV_JACKET_CUFF, '+Z': UV_JACKET_CUFF,
        '+Y': UV_JACKET_CUFF, '-Y': UV_JACKET_CUFF
    })

    # Articulated Conforming Combat Knee Armor
    mesh.add_box((0.0, -0.42, -0.095), (0.120, 0.126, 0.022), uv_map={
        '-Z': uv_kneepad, '+Z': uv_kneepad,
        '-X': uv_kneepad, '+X': uv_kneepad,
        '+Y': uv_kneepad, '-Y': uv_kneepad
    })
    mesh.add_box((0.0, -0.360, -0.085), (0.112, 0.024, 0.016), uv_map={
        '-Z': uv_kneepad, '+Z': uv_kneepad,
        '-X': uv_kneepad, '+X': uv_kneepad,
        '+Y': uv_kneepad, '-Y': uv_kneepad
    })
    mesh.add_box((0.0, -0.480, -0.085), (0.112, 0.024, 0.016), uv_map={
        '-Z': uv_kneepad, '+Z': uv_kneepad,
        '-X': uv_kneepad, '+X': uv_kneepad,
        '+Y': uv_kneepad, '-Y': uv_kneepad
    })
    for y_strap in [-0.37, -0.47]:
        mesh.add_cylinder((0.0, y_strap, 0.0), (0.0, y_strap - 0.020, 0.0), radius=0.076, segments=8, uv_rect=UV_JACKET_CUFF)

    # Orange Ankle Cinch Strap Collar
    mesh.add_box((0.0, -0.66, 0.0), (0.130, 0.032, 0.124), uv_map={
        '-Z': UV_JACKET_CUFF, '+Z': UV_JACKET_CUFF,
        '-X': UV_JACKET_CUFF, '+X': UV_JACKET_CUFF,
        '+Y': UV_JACKET_CUFF, '-Y': UV_JACKET_CUFF
    })

    # Sculpted Athletic High-Top Techwear Sneaker
    mesh.add_box((0.0, -0.71, -0.01), (0.092, 0.065, 0.140), uv_map={
        '-X': UV_SNEAKER_OUTER if is_left else UV_SNEAKER_INNER,
        '+X': UV_SNEAKER_INNER if is_left else UV_SNEAKER_OUTER,
        '-Z': UV_SNEAKER_OUTER, '+Z': UV_SNEAKER_OUTER,
        '+Y': UV_SNEAKER_OUTER, '-Y': UV_SNEAKER_OUTER
    })
    mesh.add_box((0.0, -0.765, -0.045), (0.096, 0.055, 0.220), uv_map={
        '-X': UV_SNEAKER_OUTER if is_left else UV_SNEAKER_INNER,
        '+X': UV_SNEAKER_INNER if is_left else UV_SNEAKER_OUTER,
        '-Z': UV_SNEAKER_OUTER, '+Z': UV_SNEAKER_OUTER,
        '+Y': UV_SNEAKER_OUTER, '-Y': UV_SNEAKER_SOLE
    })
    mesh.add_box((0.0, -0.815, -0.045), (0.106, 0.045, 0.240), uv_map={
        '-X': UV_SNEAKER_OUTER if is_left else UV_SNEAKER_INNER,
        '+X': UV_SNEAKER_INNER if is_left else UV_SNEAKER_OUTER,
        '-Z': UV_SNEAKER_OUTER, '+Z': UV_SNEAKER_OUTER,
        '+Y': UV_SNEAKER_OUTER, '-Y': UV_SNEAKER_SOLE
    })

    return mesh


def main():
    output_dir = "godot/models/runner"
    os.makedirs(output_dir, exist_ok=True)
    
    print("Generating Courier Runner modular OBJ meshes with calibrated UVs and left-flank satchel...")
    build_torso().save(f"{output_dir}/runner_torso.obj")
    build_telemetry().save(f"{output_dir}/runner_telemetry.obj")
    build_telemetry_core().save(f"{output_dir}/runner_telemetry_core.obj")
    build_satchel().save(f"{output_dir}/runner_satchel.obj")
    build_helmet().save(f"{output_dir}/runner_helmet.obj")
    build_visor().save(f"{output_dir}/runner_visor.obj")
    build_arm(is_left=True).save(f"{output_dir}/runner_arm_left.obj")
    build_arm(is_left=False).save(f"{output_dir}/runner_arm_right.obj")
    build_leg(is_left=True).save(f"{output_dir}/runner_leg_left.obj")
    build_leg(is_left=False).save(f"{output_dir}/runner_leg_right.obj")
    print("All Courier Runner meshes generated successfully.")


if __name__ == "__main__":
    main()
