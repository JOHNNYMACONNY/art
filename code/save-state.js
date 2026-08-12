(() => {
  'use strict';

  const DEFAULT_PLAYER_X = 420;
  const DEFAULT_PLAYER_Y = 620;
  const DEFAULT_HEALTH = 100;
  const DEFAULT_AMMO = 120;

  class SaveState {
    static STORAGE_KEY = 'fb13-hs7-save-v2';

    static getVehicleId(player) {
      if (!player || !player.vehicle) return null;
      return player.vehicle.id || null;
    }

    static serializePlayer(player) {
      if (!player) {
        return {
          x: DEFAULT_PLAYER_X,
          y: DEFAULT_PLAYER_Y,
          health: DEFAULT_HEALTH,
          maxHealth: DEFAULT_HEALTH,
          ammo: DEFAULT_AMMO,
          inVehicle: null
        };
      }
      return {
        x: typeof player.x === 'number' ? player.x : DEFAULT_PLAYER_X,
        y: typeof player.y === 'number' ? player.y : DEFAULT_PLAYER_Y,
        health: typeof player.hp === 'number' ? player.hp : DEFAULT_HEALTH,
        maxHealth: typeof player.maxHp === 'number' ? player.maxHp : DEFAULT_HEALTH,
        ammo: typeof player.ammo === 'number' ? player.ammo : DEFAULT_AMMO,
        inVehicle: SaveState.getVehicleId(player)
      };
    }

    static serializeVehicle(vehicle) {
      if (!vehicle) return null;
      return {
        id: vehicle.id || 'vehicle_unknown',
        type: vehicle.type || 'standard',
        x: vehicle.x || 0,
        y: vehicle.y || 0,
        health: typeof vehicle.hp === 'number' ? vehicle.hp : DEFAULT_HEALTH
      };
    }

    static createDefault(player, vehicles, missions, police, thrum, wavicle) {
      const activeVehicles = Array.isArray(vehicles)
        ? vehicles.map(v => SaveState.serializeVehicle(v)).filter(Boolean)
        : [];

      const completed = (missions && missions.completed) ? Array.from(missions.completed) : [];

      return {
        version: '1.0.0',
        timestamp: Date.now(),
        player: SaveState.serializePlayer(player),
        vehicles: activeVehicles,
        missionState: {
          currentMissionId: missions ? missions.currentId : null,
          stepIndex: missions ? missions.stepIndex : 0,
          completedMissions: completed
        },
        worldFlags: (missions && missions.flags) ? { ...missions.flags } : {},
        policeState: {
          heat: police ? police.heat : 0,
          wantedLevel: police ? police.wanted : 0,
          cooldownTimer: police ? police.cooldown : 0
        },
        thrumState: {
          intensity: thrum ? thrum.intensity : 0,
          active: Boolean(thrum && thrum.active)
        },
        wavicleState: {
          destabilization: wavicle ? wavicle.destabilization : 0,
          active: Boolean(wavicle && wavicle.active)
        }
      };
    }

    static save(state) {
      try {
        state.timestamp = Date.now();
        localStorage.setItem(SaveState.STORAGE_KEY, JSON.stringify(state));
        return true;
      } catch (err) {
        console.error('SaveState save error:', err);
        return false;
      }
    }

    static load() {
      try {
        const raw = localStorage.getItem(SaveState.STORAGE_KEY);
        if (!raw) return null;
        return JSON.parse(raw);
      } catch (err) {
        console.error('SaveState load error:', err);
        return null;
      }
    }

    static clear() {
      try {
        localStorage.removeItem(SaveState.STORAGE_KEY);
      } catch (err) {
        console.error('SaveState clear error:', err);
      }
    }
  }

  window.SaveState = SaveState;
})();
