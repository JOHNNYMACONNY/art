(() => {
  'use strict';

  class Camera {
    constructor(viewportWidth = 960, viewportHeight = 540, worldWidth = 2400, worldHeight = 1350) {
      this.vw = viewportWidth;
      this.vh = viewportHeight;
      this.ww = worldWidth;
      this.wh = worldHeight;
      
      this.x = 0;
      this.y = 0;
      this.targetX = 0;
      this.targetY = 0;
      
      this.stiffness = 8.0;
      this.lookAheadFactor = 0.15;
      this.shakeIntensity = 0;
      this.shakeDecay = 0.85;
    }

    update(dt, targetX, targetY, targetVx = 0, targetVy = 0) {
      const aheadX = targetX + targetVx * this.lookAheadFactor;
      const aheadY = targetY + targetVy * this.lookAheadFactor;

      const idealX = aheadX - this.vw / 2;
      const idealY = aheadY - this.vh / 2;

      this.targetX = Math.max(0, Math.min(this.ww - this.vw, idealX));
      this.targetY = Math.max(0, Math.min(this.wh - this.vh, idealY));

      const alpha = 1 - Math.exp(-this.stiffness * dt);
      this.x += (this.targetX - this.x) * alpha;
      this.y += (this.targetY - this.y) * alpha;

      if (this.shakeIntensity > 0.1) {
        this.x += (Math.random() * 2 - 1) * this.shakeIntensity;
        this.y += (Math.random() * 2 - 1) * this.shakeIntensity;
        this.shakeIntensity *= Math.pow(this.shakeDecay, dt * 60);
      } else {
        this.shakeIntensity = 0;
      }
    }

    addShake(amount) {
      this.shakeIntensity = Math.min(25, this.shakeIntensity + amount);
    }

    getOffset() {
      return {
        x: Math.round(this.x),
        y: Math.round(this.y)
      };
    }
  }

  window.Camera = Camera;
})();
