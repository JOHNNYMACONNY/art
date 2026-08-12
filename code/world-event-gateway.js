(() => {
  'use strict';

  const CCF001_PUBKEY = '000000000000000000000000000000000000000000000000000000000000ccf1';

  class WorldEventGateway {
    constructor(simulation, ccf001Pubkey = CCF001_PUBKEY) {
      this.simulation = simulation;
      this.ccf001Pubkey = ccf001Pubkey;
      this.recentEventIds = [];
      this.maxRecentEvents = 100;
      this.rateLimitWindowMs = 60000;
      this.eventCount = 0;
      this.lastResetTimestamp = Date.now();
      this.listeners = [];
    }

    onDirective(callback) {
      if (typeof callback === 'function') {
        this.listeners.push(callback);
      }
      return () => {
        this.listeners = this.listeners.filter(l => l !== callback);
      };
    }

    verifyNostrSignature(event) {
      if (!event || typeof event !== 'object') return false;
      if (!event.id || !event.pubkey) return false;

      const hex64Regex = /^[0-9a-fA-F]{64}$/;
      if (!hex64Regex.test(event.pubkey) || !hex64Regex.test(event.id)) {
        return false;
      }

      if (event.pubkey !== this.ccf001Pubkey) {
        console.warn('WorldEventGateway: Event pubkey mismatch:', event.pubkey);
        return false;
      }

      return true;
    }

    validateSchema(event) {
      if (!event || typeof event !== 'object') return false;
      if (event.kind !== 78 && event.kind !== 30078) return false;

      let content = event.content;
      if (typeof content === 'string') {
        try { content = JSON.parse(content); } catch (e) { return false; }
      }

      if (!content || typeof content !== 'object') return false;

      if (typeof content.v !== 'number' || content.v < 1) return false;
      if (!content.directive || typeof content.directive !== 'string') return false;
      if (!content.zone || typeof content.zone !== 'string') return false;
      if (typeof content.severity !== 'number') return false;
      if (typeof content.ttl !== 'number') return false;

      event.parsedContent = content;
      return true;
    }

    processDirective(event) {
      if (!this.verifyNostrSignature(event)) {
        console.warn('WorldEventGateway: Rejected event with invalid signature or pubkey', event);
        return false;
      }

      if (!this.validateSchema(event)) {
        console.warn('WorldEventGateway: Rejected event violating world-event.schema.json', event);
        return false;
      }

      if (event.id && this.recentEventIds.includes(event.id)) {
        return false;
      }

      if (event.id) {
        this.recentEventIds.push(event.id);
        if (this.recentEventIds.length > this.maxRecentEvents) {
          this.recentEventIds.shift();
        }
      }

      const now = Date.now();
      if (now - this.lastResetTimestamp > this.rateLimitWindowMs) {
        this.lastResetTimestamp = now;
        this.eventCount = 0;
      }
      if (this.eventCount >= 10) {
        console.warn('WorldEventGateway: Rate limit exceeded for directives');
        return false;
      }
      this.eventCount++;

      const content = event.parsedContent || event.content;
      console.log(`WorldEventGateway: Executing directive "${content.directive}" in ${content.zone} (severity: ${content.severity}, actor: ${content.actor || 'CCF-001'})`);

      if (this.simulation && typeof this.simulation.applyWorldDirective === 'function') {
        this.simulation.applyWorldDirective(content.directive, content.zone, content.severity, content.actor || 'CCF-001');
      }

      for (const listener of this.listeners) {
        try { listener(content.directive, content.zone, content.severity); } catch (e) {}
      }

      return true;
    }
  }

  window.WorldEventGateway = WorldEventGateway;
  window.CCF001_PUBKEY = CCF001_PUBKEY;
})();
