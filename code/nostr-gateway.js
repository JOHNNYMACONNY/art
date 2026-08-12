(() => {
  'use strict';

  class NostrGateway {
    constructor(relayUrl = 'wss://relay.damus.io') {
      this.relayUrl = relayUrl;
      this.ws = null;
      this.playerPrivkey = this.getOrGeneratePlayerPrivkey();
      this.playerPubkey = this.derivePlayerPubkey(this.playerPrivkey);
      this.connected = false;
      this.subscribers = [];
      this.seq = 0;
      this.sessionId = 's_' + Math.random().toString(36).substr(2, 6);
    }

    getOrGeneratePlayerPrivkey() {
      let key = localStorage.getItem('fb13_player_privkey');
      if (!key || key.length !== 64) {
        key = Array.from(crypto.getRandomValues(new Uint8Array(32)))
          .map(b => b.toString(16).padStart(2, '0')).join('');
        localStorage.setItem('fb13_player_privkey', key);
      }
      return key;
    }

    derivePlayerPubkey(privkey) {
      let pub = localStorage.getItem('fb13_player_pubkey');
      if (!pub || pub.length !== 64) {
        // Mock derive pubkey from privkey
        pub = Array.from(crypto.getRandomValues(new Uint8Array(32)))
          .map(b => b.toString(16).padStart(2, '0')).join('');
        localStorage.setItem('fb13_player_pubkey', pub);
      }
      return pub;
    }

    connect() {
      try {
        this.ws = new WebSocket(this.relayUrl);
        this.ws.onopen = () => {
          this.connected = true;
          this.subscribeAgentDirectives();
        };
        this.ws.onmessage = (msg) => this.handleMessage(msg);
        this.ws.onclose = () => { this.connected = false; };
        this.ws.onerror = (err) => { this.connected = false; };
      } catch (e) {
        console.warn('NostrGateway WebSocket fallback (offline mode)');
      }
    }

    subscribeAgentDirectives() {
      if (!this.ws || !this.connected) return;
      const req = JSON.stringify([
        "REQ",
        "agent_directives",
        { "kinds": [78, 30078], "#t": ["agent-intercept"] }
      ]);
      this.ws.send(req);
    }

    emitPlayerEcho(action, zone, intensity = 0.5, missionId = null) {
      this.seq++;
      const contentObj = {
        v: 1,
        type: "player.echo",
        session: this.sessionId,
        seq: this.seq,
        action: action,
        zone: zone || "gears_district",
        mission: missionId,
        intensity: intensity,
        world_time: Date.now()
      };

      const payload = {
        kind: 78,
        pubkey: this.playerPubkey,
        created_at: Math.floor(Date.now() / 1000),
        tags: [
          ["d", "echoes-scrapheap"],
          ["t", "memory-echo"]
        ],
        content: JSON.stringify(contentObj),
        id: Array.from(crypto.getRandomValues(new Uint8Array(32))).map(b => b.toString(16).padStart(2, '0')).join(''),
        sig: Array.from(crypto.getRandomValues(new Uint8Array(64))).map(b => b.toString(16).padStart(2, '0')).join('')
      };

      if (this.ws && this.connected) {
        this.ws.send(JSON.stringify(["EVENT", payload]));
      }

      return payload;
    }

    onAgentDirective(callback) {
      this.subscribers.push(callback);
      return () => {
        this.subscribers = this.subscribers.filter(sub => sub !== callback);
      };
    }

    handleMessage(evt) {
      try {
        const data = JSON.parse(evt.data);
        if (data && data[0] === "EVENT" && data[2]) {
          const event = data[2];
          if (typeof event.content === 'string') {
            try { event.content = JSON.parse(event.content); } catch (e) {}
          }
          for (const sub of this.subscribers) {
            sub(event);
          }
        }
      } catch (err) {
        console.warn('NostrGateway handleMessage error:', err);
      }
    }
  }

  window.NostrGateway = NostrGateway;
})();
