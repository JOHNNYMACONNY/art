(() => {
  'use strict';

  class Simulation {
    constructor(worldWidth = 2400, worldHeight = 1350) {
      this.worldWidth = worldWidth;
      this.worldHeight = worldHeight;

      this.player = {
        x: 420, y: 620, radius: 14, angle: 0,
        hp: 100, maxHp: 100, ammo: 120, speed: 200,
        vehicle: null
      };

      this.vehicles = [
        { id: 'veh_01', type: 'scavenger_rig', x: 500, y: 600, angle: 0, speed: 0, hp: 200 },
        { id: 'veh_02', type: 'police_cruiser', x: 1200, y: 700, angle: 0, speed: 0, hp: 150 },
        { id: 'veh_03', type: 'echotel_van', x: 1800, y: 400, angle: 0, speed: 0, hp: 180 },
        { id: 'veh_04', type: 'silent_interceptor', x: 900, y: 1100, angle: 0, speed: 0, hp: 250 }
      ];

      this.police = { heat: 0, wanted: 0, cooldown: 0 };
      this.thrum = { intensity: 0, active: false };
      this.wavicle = { destabilization: 0, active: false };
      this.activeDirectives = [];
      this.maxDirectivesHistory = 50;
    }

    applyWorldDirective(directive, zone, severity, actor = 'CCF-001') {
      console.log(`Simulation applying directive: ${directive} in ${zone} (severity: ${severity})`);
      this.activeDirectives.push({
        directive, zone, severity, actor, timestamp: Date.now()
      });

      if (this.activeDirectives.length > this.maxDirectivesHistory) {
        this.activeDirectives.shift();
      }

      if (directive === 'dispatch_hunters' || directive === 'police_sweep') {
        this.police.heat = Math.min(1.0, this.police.heat + severity * 0.4);
        this.police.wanted = Math.min(5, Math.floor(this.police.heat * 5));
      } else if (directive === 'thrum_spike') {
        this.thrum.intensity = Math.min(1.0, this.thrum.intensity + severity * 0.5);
      }
    }

    update(dt) {
      if (this.police.cooldown > 0) {
        this.police.cooldown -= dt;
        if (this.police.cooldown <= 0) {
          this.police.heat = Math.max(0, this.police.heat - 0.1);
          this.police.wanted = Math.floor(this.police.heat * 5);
        }
      }
    }
  }

  window.Simulation = Simulation;
})();
