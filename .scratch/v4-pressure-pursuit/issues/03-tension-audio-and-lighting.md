# 03 — Tension Audio & Ambient Red Lighting

**What to build:**
Spatial `SIREN_ALARM` audio event stream, dynamic ambient lighting shift to red (`Color(0.4, 0.1, 0.1)`) during active pursuit, and smooth transition back to calm lighting.

**Blocked by:** 02 — Pursuit Loop State Machine

**Status:** ready-for-agent

- [ ] Spatial 3D siren alarm audio event (`SIREN_ALARM`)
- [ ] WorldEnvironment ambient lighting pulse to cold industrial red during pursuit
- [ ] Smooth lighting and audio fade upon evading pursuer
- [ ] WebGL2 renderer safe lighting adjustments
