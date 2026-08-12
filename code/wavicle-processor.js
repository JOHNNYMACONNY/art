class WavicleProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.bufferSize = 44100;
    this.buffer = new Float32Array(this.bufferSize);
    this.writeIndex = 0;
    this.intensity = 0.0;
    this.grainSize = 1024;
    this.grainOffset = 0;
    this.feedback = 0.35;

    this.port.onmessage = (e) => {
      if (e.data) {
        if (typeof e.data.intensity === 'number') {
          this.intensity = Math.max(0, Math.min(1, e.data.intensity));
        }
        if (typeof e.data.grainSize === 'number') {
          this.grainSize = Math.max(256, Math.min(4096, e.data.grainSize));
        }
      }
    };
  }

  process(inputs, outputs, parameters) {
    const input = inputs[0];
    const output = outputs[0];
    if (!input || !input[0] || !output || !output[0]) return true;

    const inputChannel = input[0];
    const outputChannel = output[0];
    const len = inputChannel.length;

    for (let i = 0; i < len; i++) {
      const sample = inputChannel[i];
      let processedSample = sample;

      if (this.intensity > 0.05) {
        this.grainOffset = (this.grainOffset + 1) % this.grainSize;
        const grainWindow = 0.5 * (1 - Math.cos((2 * Math.PI * this.grainOffset) / this.grainSize));
        const jitter = (Math.random() * 2 - 1) * this.intensity * 2000;
        let readIndex = (this.writeIndex - 1000 + Math.floor(jitter) + this.bufferSize) % this.bufferSize;
        
        const delayedSample = this.buffer[readIndex];
        processedSample = sample * (1 - this.intensity) + delayedSample * grainWindow * this.intensity;

        // Feedback loop write back
        this.buffer[this.writeIndex] = sample + delayedSample * this.feedback * this.intensity;
      } else {
        this.buffer[this.writeIndex] = sample;
      }

      outputChannel[i] = processedSample;
      this.writeIndex = (this.writeIndex + 1) % this.bufferSize;
    }

    return true;
  }
}

registerProcessor('wavicle-processor', WavicleProcessor);
