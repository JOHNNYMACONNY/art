(() => {
  'use strict';

  const SoundType = {
    SHOOT: 'shoot',
    THRUM: 'thrum',
    ECHO: 'echo',
    HIT: 'hit',
    BLIP: 'blip',
    THUNDER: 'thunder',
    SIREN: 'siren'
  };

  class AudioEngine {
    constructor() {
      this.ctx = null;
      this.thrumFilter = null;
      this.masterGain = null;
      this.wavicleNode = null;
      this.thrumIntensity = 0.0;
      this.isInitialized = false;
      this.ambientRainNode = null;
    }

    init() {
      if (this.isInitialized) return;
      try {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        this.ctx = new AudioCtx();
        
        this.masterGain = this.ctx.createGain();
        this.masterGain.gain.setValueAtTime(0.8, this.ctx.currentTime);
        this.masterGain.connect(this.ctx.destination);

        this.thrumFilter = this.ctx.createBiquadFilter();
        this.thrumFilter.type = 'lowpass';
        this.thrumFilter.frequency.setValueAtTime(18000, this.ctx.currentTime);
        this.thrumFilter.Q.setValueAtTime(1.0, this.ctx.currentTime);
        this.thrumFilter.connect(this.masterGain);

        this.loadWavicleProcessor();
        this.startAmbientRain();
        this.isInitialized = true;
      } catch (err) {
        console.warn('AudioEngine Web Audio API initialized in fallback mode:', err);
      }
    }

    async loadWavicleProcessor() {
      if (!this.ctx || !this.ctx.audioWorklet) return;
      try {
        await this.ctx.audioWorklet.addModule('wavicle-processor.js');
        this.wavicleNode = new AudioWorkletNode(this.ctx, 'wavicle-processor');
        this.wavicleNode.connect(this.thrumFilter);
      } catch (e) {
        console.warn('Wavicle processor Worklet unavailable, using main graph');
      }
    }

    resume() {
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume();
      }
    }

    setThrum(intensity) {
      this.thrumIntensity = Math.max(0, Math.min(1, intensity));
      if (!this.ctx || !this.thrumFilter) return;
      
      const targetFreq = 18000 * Math.pow(0.015, this.thrumIntensity);
      const targetQ = 1.0 + this.thrumIntensity * 12.0;
      const t = this.ctx.currentTime;
      
      this.thrumFilter.frequency.setTargetAtTime(targetFreq, t, 0.05);
      this.thrumFilter.Q.setTargetAtTime(targetQ, t, 0.05);

      if (this.wavicleNode) {
        this.wavicleNode.port.postMessage({ intensity: this.thrumIntensity });
      }
    }

    playSfx(type) {
      if (!this.isInitialized) this.init();
      this.resume();
      if (!this.ctx) return;

      const t = this.ctx.currentTime;
      const dest = this.thrumFilter || this.masterGain || this.ctx.destination;

      if (type === SoundType.SHOOT) {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(600, t);
        osc.frequency.exponentialRampToValueAtTime(120, t + 0.1);
        gain.gain.setValueAtTime(0.2, t);
        gain.gain.linearRampToValueAtTime(0.01, t + 0.1);
        osc.connect(gain);
        gain.connect(dest);
        osc.start(t);
        osc.stop(t + 0.1);
      } else if (type === SoundType.THRUM) {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(110, t);
        osc.frequency.exponentialRampToValueAtTime(40, t + 0.35);
        gain.gain.setValueAtTime(0.35, t);
        gain.gain.linearRampToValueAtTime(0.01, t + 0.35);
        osc.connect(gain);
        gain.connect(dest);
        osc.start(t);
        osc.stop(t + 0.35);
      } else if (type === SoundType.ECHO) {
        const osc1 = this.ctx.createOscillator();
        const osc2 = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc1.type = 'triangle';
        osc1.frequency.setValueAtTime(880, t);
        osc1.frequency.linearRampToValueAtTime(1320, t + 0.3);
        osc2.type = 'sine';
        osc2.frequency.setValueAtTime(440, t);
        osc2.frequency.linearRampToValueAtTime(660, t + 0.3);
        gain.gain.setValueAtTime(0.25, t);
        gain.gain.linearRampToValueAtTime(0.01, t + 0.4);
        osc1.connect(gain);
        osc2.connect(gain);
        gain.connect(dest);
        osc1.start(t);
        osc2.start(t);
        osc1.stop(t + 0.4);
        osc2.stop(t + 0.4);
      } else if (type === SoundType.HIT) {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'square';
        osc.frequency.setValueAtTime(160, t);
        osc.frequency.linearRampToValueAtTime(40, t + 0.12);
        gain.gain.setValueAtTime(0.2, t);
        gain.gain.linearRampToValueAtTime(0.01, t + 0.12);
        osc.connect(gain);
        gain.connect(dest);
        osc.start(t);
        osc.stop(t + 0.12);
      } else if (type === SoundType.BLIP) {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(520, t);
        osc.frequency.exponentialRampToValueAtTime(320, t + 0.08);
        gain.gain.setValueAtTime(0.15, t);
        gain.gain.linearRampToValueAtTime(0.01, t + 0.08);
        osc.connect(gain);
        gain.connect(dest);
        osc.start(t);
        osc.stop(t + 0.08);
      } else if (type === SoundType.THUNDER) {
        const bufferSize = this.ctx.sampleRate * 0.8;
        const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) data[i] = (Math.random() * 2 - 1) * Math.exp(-i / (bufferSize * 0.2));
        const noise = this.ctx.createBufferSource();
        noise.buffer = buffer;
        const filter = this.ctx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(200, t);
        const gain = this.ctx.createGain();
        gain.gain.setValueAtTime(0.3, t);
        gain.gain.linearRampToValueAtTime(0.01, t + 0.8);
        noise.connect(filter);
        filter.connect(gain);
        gain.connect(dest);
        noise.start(t);
      } else if (type === SoundType.SIREN) {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(600, t);
        osc.frequency.linearRampToValueAtTime(900, t + 0.4);
        gain.gain.setValueAtTime(0.1, t);
        gain.gain.linearRampToValueAtTime(0.01, t + 0.4);
        osc.connect(gain);
        gain.connect(dest);
        osc.start(t);
        osc.stop(t + 0.4);
      }
    }

    startAmbientRain() {
      if (!this.ctx) return;
      try {
        const bufferSize = this.ctx.sampleRate * 2;
        const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
          data[i] = Math.random() * 2 - 1;
        }

        const noise = this.ctx.createBufferSource();
        noise.buffer = buffer;
        noise.loop = true;

        const filter = this.ctx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 800;

        const gain = this.ctx.createGain();
        gain.gain.value = 0.04;

        noise.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);
        noise.start();
        this.ambientRainNode = noise;
      } catch (e) {
        console.warn('Ambient rain audio node init deferred');
      }
    }
  }

  window.SoundType = SoundType;
  window.AudioEngine = AudioEngine;
})();
