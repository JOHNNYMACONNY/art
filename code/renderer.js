(() => {
  'use strict';

  class Renderer {
    constructor(canvas) {
      this.canvas = canvas;
      this.ctx = canvas.getContext('2d');
      this.ctx.imageSmoothingEnabled = false;
      this.viewportWidth = canvas.width;
      this.viewportHeight = canvas.height;
      this.particles = [];
      this.maxParticles = 100;
    }

    clear() {
      this.ctx.fillStyle = '#0a0b10';
      this.ctx.fillRect(0, 0, this.viewportWidth, this.viewportHeight);
    }

    drawWorldBoundary(cameraOffset, worldWidth, worldHeight) {
      this.ctx.strokeStyle = '#1e2430';
      this.ctx.lineWidth = 4;
      this.ctx.strokeRect(-cameraOffset.x, -cameraOffset.y, worldWidth, worldHeight);
    }

    renderEntitiesYSorted(cameraOffset, entities = []) {
      const sorted = [...entities].sort((a, b) => (a.y || 0) - (b.y || 0));
      for (const entity of sorted) {
        if (typeof entity.render === 'function') {
          entity.render(this.ctx, cameraOffset);
        } else {
          this.renderDefaultEntity(entity, cameraOffset);
        }
      }
    }

    renderDefaultEntity(entity, cameraOffset) {
      const screenX = entity.x - cameraOffset.x;
      const screenY = entity.y - cameraOffset.y;
      const radius = entity.radius || 12;

      this.ctx.fillStyle = entity.color || '#3a86ff';
      this.ctx.beginPath();
      this.ctx.arc(screenX, screenY, radius, 0, Math.PI * 2);
      this.ctx.fill();
    }

    addParticle(x, y, vx, vy, color, life = 0.5, size = 3) {
      if (this.particles.length >= this.maxParticles) {
        this.particles.shift();
      }
      this.particles.push({ x, y, vx, vy, color, life, maxLife: life, size });
    }

    updateAndRenderParticles(dt, cameraOffset) {
      for (let i = this.particles.length - 1; i >= 0; i--) {
        const p = this.particles[i];
        p.life -= dt;
        if (p.life <= 0) {
          this.particles.splice(i, 1);
          continue;
        }

        p.x += p.vx * dt;
        p.y += p.vy * dt;

        const screenX = p.x - cameraOffset.x;
        const screenY = p.y - cameraOffset.y;
        const alpha = Math.max(0, p.life / p.maxLife);

        this.ctx.fillStyle = p.color;
        this.ctx.globalAlpha = alpha;
        this.ctx.fillRect(screenX - p.size / 2, screenY - p.size / 2, p.size, p.size);
        this.ctx.globalAlpha = 1.0;
      }
    }

    renderMuzzleFlash(x, y, angle, cameraOffset) {
      const screenX = x - cameraOffset.x;
      const screenY = y - cameraOffset.y;

      this.ctx.save();
      this.ctx.translate(screenX, screenY);
      this.ctx.rotate(angle);

      this.ctx.fillStyle = '#ffbe0b';
      this.ctx.beginPath();
      this.ctx.moveTo(10, 0);
      this.ctx.lineTo(24, -6);
      this.ctx.lineTo(32, 0);
      this.ctx.lineTo(24, 6);
      this.ctx.closePath();
      this.ctx.fill();

      this.ctx.restore();
    }

    renderAtmosphereOverlay(thrumIntensity = 0, wavicleIntensity = 0) {
      if (thrumIntensity > 0.1) {
        this.ctx.fillStyle = `rgba(180, 80, 20, ${thrumIntensity * 0.15})`;
        this.ctx.fillRect(0, 0, this.viewportWidth, this.viewportHeight);
      }

      if (wavicleIntensity > 0.1) {
        this.ctx.fillStyle = `rgba(40, 180, 220, ${wavicleIntensity * 0.12})`;
        this.ctx.fillRect(0, 0, this.viewportWidth, this.viewportHeight);
      }
    }
  }

  window.Renderer = Renderer;
})();
