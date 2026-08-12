window.SPRITES = {};
window.__gameErrors=[];
window.addEventListener('error', e => {console.error("GAME RUNTIME ERROR:", e.error || e.message);window.__gameErrors.push(e.message||String(e.error));});
(() => {
'use strict';
const canvas=document.querySelector('#game'),ctx=canvas.getContext('2d');ctx.imageSmoothingEnabled=false;
const W=canvas.width,H=canvas.height,WORLD={w:2400,h:1350};
const keys={},mouse={x:W/2,y:H/2,down:false,held:false};let running=false,paused=false,last=0,shake=0,flashTime=0,storm=0,storm2=0,wind=0;
const SAVE = (window.SaveState && window.SaveState.STORAGE_KEY) || 'fb13-hs7-save-v2';

// ── SUBSYSTEM INITIALIZATION ──────────────────────────────────────────────────
if (window.Simulation) window.simulation = new window.Simulation(WORLD.w, WORLD.h);
if (window.Renderer) window.renderer = new window.Renderer(canvas);
if (window.Camera) window.cameraInstance = new window.Camera(W, H, WORLD.w, WORLD.h);
if (window.AudioEngine) window.audioEngine = new window.AudioEngine();
if (window.NostrGateway && window.WorldEventGateway) {
  window.nostrGateway = new window.NostrGateway();
  window.worldEventGateway = new window.WorldEventGateway(window.simulation);
  window.nostrGateway.onAgentDirective(event => window.worldEventGateway.processDirective(event));
  window.worldEventGateway.onDirective((directive, zone, severity) => {
    if (directive === 'dispatch_hunters' || directive === 'police_sweep') {
      addHeat(severity * 40);
    } else if (directive === 'thrum_spike') {
      if (window.audioEngine) window.audioEngine.setThrum(severity);
    }
  });
  window.nostrGateway.connect();
}

const clamp=(v,a,b)=>Math.max(a,Math.min(b,v)),dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y),rnd=(a,b)=>a+Math.random()*(b-a);

// ── WEB AUDIO SYNTHESIZER ───────────────────────────────────────────────────────
let actx=null;
function audio(){
  if (window.audioEngine) { window.audioEngine.init(); window.audioEngine.resume(); return; }
  if(!actx)actx=new(window.AudioContext||window.webkitAudioContext)();if(actx.state==='suspended')actx.resume();ambient();
}
function sfx(type){
  if (window.audioEngine) { window.audioEngine.playSfx(type); return; }

  try {
    audio();if(!actx)return;
    const t=actx.currentTime;
    if(type==='shoot'){
      const o=actx.createOscillator(),g=actx.createGain();
      o.type='sawtooth';o.frequency.setValueAtTime(600,t);o.frequency.exponentialRampToValueAtTime(120,t+.1);
      g.gain.setValueAtTime(.2,t);g.gain.linearRampToValueAtTime(.01,t+.1);
      o.connect(g);g.connect(actx.destination);o.start(t);o.stop(t+.1);
    }else if(type==='thrum'){
      const o=actx.createOscillator(),g=actx.createGain();
      o.type='sine';o.frequency.setValueAtTime(110,t);o.frequency.exponentialRampToValueAtTime(40,t+.35);
      g.gain.setValueAtTime(.35,t);g.gain.linearRampToValueAtTime(.01,t+.35);
      o.connect(g);g.connect(actx.destination);o.start(t);o.stop(t+.35);
    }else if(type==='echo'){
      const o1=actx.createOscillator(),o2=actx.createOscillator(),g=actx.createGain();
      o1.type='triangle';o1.frequency.setValueAtTime(880,t);o1.frequency.linearRampToValueAtTime(1320,t+.3);
      o2.type='sine';o2.frequency.setValueAtTime(440,t);o2.frequency.linearRampToValueAtTime(660,t+.3);
      g.gain.setValueAtTime(.25,t);g.gain.linearRampToValueAtTime(.01,t+.4);
      o1.connect(g);o2.connect(g);g.connect(actx.destination);o1.start(t);o2.start(t);o1.stop(t+.4);o2.stop(t+.4);
    }else if(type==='hit'){
      const o=actx.createOscillator(),g=actx.createGain();
      o.type='square';o.frequency.setValueAtTime(160,t);o.frequency.linearRampToValueAtTime(40,t+.12);
      g.gain.setValueAtTime(.2,t);g.gain.linearRampToValueAtTime(.01,t+.12);
      o.connect(g);g.connect(actx.destination);o.start(t);o.stop(t+.12);
    }else if(type==='blip'){
      const o=actx.createOscillator(),g=actx.createGain();
      o.type='sine';o.frequency.setValueAtTime(520,t);
      g.gain.setValueAtTime(.1,t);g.gain.linearRampToValueAtTime(.01,t+.05);
      o.connect(g);g.connect(actx.destination);o.start(t);o.stop(t+.05);
    }else if(type==='thunder'){
      const o=actx.createOscillator(),g=actx.createGain();
      o.type='sawtooth';o.frequency.setValueAtTime(88,t);o.frequency.exponentialRampToValueAtTime(26,t+1.3);
      g.gain.setValueAtTime(.4,t);g.gain.exponentialRampToValueAtTime(.001,t+1.5);
      o.connect(g);g.connect(actx.destination);o.start(t);o.stop(t+1.5);
    }else if(type==='siren'){
      const o=actx.createOscillator(),g=actx.createGain(),lfo=actx.createOscillator(),lg=actx.createGain(),lp=actx.createBiquadFilter();
      o.type='sine';o.frequency.value=520;lfo.type='sine';lfo.frequency.value=.5;lg.gain.value=140;lfo.connect(lg);lg.connect(o.frequency);
      lp.type='lowpass';lp.frequency.value=720;
      g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(.04,t+1.2);g.gain.setValueAtTime(.04,t+2.4);g.gain.linearRampToValueAtTime(0,t+3.5);
      o.connect(g);g.connect(lp);lp.connect(actx.destination);o.start(t);lfo.start(t);o.stop(t+3.6);lfo.stop(t+3.6);
    }
  }catch(e){}
}
let rainGain=null;
function ambient(){try{if(!actx||rainGain)return;const len=actx.sampleRate*2,buf=actx.createBuffer(1,len,actx.sampleRate),d=buf.getChannelData(0);for(let i=0;i<len;i++)d[i]=Math.random()*2-1;const src=actx.createBufferSource();src.buffer=buf;src.loop=true;const lp=actx.createBiquadFilter();lp.type='lowpass';lp.frequency.value=900;rainGain=actx.createGain();rainGain.gain.value=.05;src.connect(lp);lp.connect(rainGain);rainGain.connect(actx.destination);src.start()}catch(e){}}

// ── SPRITE SYSTEM ──────────────────────────────────────────────────────────────
const SPRITE_CFG = {
  fb13:    { file:`fb13.png?v=${Date.now()}`,            rows:1, frames:4, scale:28,  rotOffset:0 },
};
const imgs = window.SPRITES;

for (const [key, cfg] of Object.entries(SPRITE_CFG)) {
  const img = new Image();
  img.onload = () => { imgs[key] = img; };
  img.onerror = () => {};
  img.src = `assets/sprites/${cfg.file}`;
}
// Load ground tileset
const tileImg = new Image();
tileImg.onload = () => { imgs.tileset = tileImg; };
tileImg.src = `assets/sprites/street_tileset.png?v=${Date.now()}`;

// ── ATMOSPHERE & LIGHTING ─────────────────────────────────────────────────
function makeGlow(r,color,a=1){const c=document.createElement('canvas');c.width=c.height=r*2;const x=c.getContext('2d'),g=x.createRadialGradient(r,r,0,r,r,r);g.addColorStop(0,color);g.addColorStop(.35,color);g.addColorStop(1,'rgba(0,0,0,0)');x.globalAlpha=a;x.fillStyle=g;x.fillRect(0,0,r*2,r*2);return c}
const glowPool=makeGlow(110,'#e4a050',0.2);const glowCyan=makeGlow(64,'#56e6d4',.3);
const rain=[],embers=[],fog=[],ripples=[];
function initAtmosphere(){rain.length=0;embers.length=0;fog.length=0;for(let i=0;i<160;i++)rain.push({x:rnd(0,W),y:rnd(0,H),len:rnd(8,18),speed:rnd(450,750),a:rnd(.06,.18)});for(let i=0;i<25;i++)embers.push({x:rnd(210,2190),y:rnd(180,1120),vx:rnd(-8,8),vy:rnd(-20,-3),life:rnd(2,5),ml:rnd(2,5),sz:rnd(1.5,3)});for(let i=0;i<7;i++)fog.push({x:rnd(200,2200),y:rnd(160,1150),w:rnd(220,420),h:rnd(70,140),vx:rnd(4,10),vy:rnd(-3,3)})}
const lamps=[{x:300,y:510},{x:550,y:510},{x:850,y:510},{x:1100,y:510},{x:1400,y:510},{x:1700,y:510},{x:2000,y:510},{x:300,y:710},{x:550,y:710},{x:850,y:710},{x:1100,y:710},{x:1400,y:710},{x:1700,y:710},{x:2000,y:710}];

function dirRow(angle) {
  const a = ((angle % (Math.PI*2)) + Math.PI*2) % (Math.PI*2);
  const shifted = (a - Math.PI/2 + Math.PI*2) % (Math.PI*2);
  return Math.floor(shifted / (Math.PI/4) + 0.5) % 8;
}

function drawSpr(key, row, frame, cx, cy) {
  const img = imgs[key];
  if (!img || !img.complete || !img.naturalWidth || !img.naturalHeight) return false;
  const cfg = SPRITE_CFG[key];
  const fw = img.naturalWidth  / cfg.frames;
  const fh = img.naturalHeight / cfg.rows;
  const s  = cfg.scale;
  let sx = frame * fw, sy = row * fh, sw = fw, sh = fh;
  if (fw > fh) { sw = fh; sx = frame * fw + (fw - fh) / 2; }
  if (!isFinite(sx) || !isFinite(sy) || !isFinite(sw) || !isFinite(sh)) return false;
  ctx.drawImage(img, sx, sy, sw, sh, cx - s/2, cy - s/2, s, s);
  return true;
}

function drawChar(key, angle, wf, cx, cy, fallback) {
  const cfg = SPRITE_CFG[key];
  const row   = cfg.rows === 8 ? dirRow(angle) : 0;
  const frame = Math.floor(wf) % cfg.frames;
  if (!drawSpr(key, row, frame, cx, cy)) fallback();
}

function drawVehicle(key, angle, cx, cy, fallback) {
  const img = imgs[key];
  if (!img || !img.complete || !img.naturalWidth || !img.naturalHeight) { fallback(); return; }
  const cfg = SPRITE_CFG[key];
  const s = cfg.scale;
  const ar = img.naturalHeight / img.naturalWidth;
  const w = s, h = s * ar;
  if (!isFinite(w) || !isFinite(h)) { fallback(); return; }
  ctx.save();
  ctx.translate(cx, cy);
  ctx.rotate(angle + cfg.rotOffset);
  ctx.drawImage(img, -w/2, -h/2, w, h);
  ctx.restore();
}

// ── ENHANCED PROCEDURAL RENDERING ─────────────────────────────────────────────
function roundRect(x,y,w,h,r){
  ctx.beginPath();ctx.moveTo(x+r,y);ctx.lineTo(x+w-r,y);ctx.arcTo(x+w,y,x+w,y+r,r);
  ctx.lineTo(x+w,y+h-r);ctx.arcTo(x+w,y+h,x+w-r,y+h,r);ctx.lineTo(x+r,y+h);
  ctx.arcTo(x,y+h,x,y+h-r,r);ctx.lineTo(x,y+r);ctx.arcTo(x,y,x+r,y,r);ctx.closePath();ctx.fill();
}
function shadeColor(hex,amt){
  const r=clamp(parseInt(hex.slice(1,3),16)+amt,0,255);
  const g=clamp(parseInt(hex.slice(3,5),16)+amt,0,255);
  const b=clamp(parseInt(hex.slice(5,7),16)+amt,0,255);
  return`rgb(${r},${g},${b})`;
}

function drawBldg(r,i){
  const wallH=22;
  if(i<4){ctx.fillStyle='#101518';ctx.fillRect(r.x,r.y,r.w,r.h);return;}
  // south wall
  ctx.fillStyle='#2d1c18';ctx.fillRect(r.x,r.y+r.h,r.w,wallH);
  // brick pattern on south wall
  ctx.fillStyle='#35211a';for(let bx=r.x;bx<r.x+r.w;bx+=12)for(let by=r.y+r.h+2;by<r.y+r.h+wallH-2;by+=6){const off=(by%12<6)?0:6;ctx.fillRect(bx+off,by,10,4);}
  // east wall
  ctx.fillStyle='#3a2620';ctx.fillRect(r.x+r.w,r.y,wallH,r.h+wallH);
  // corner
  ctx.fillStyle='#251a14';ctx.fillRect(r.x+r.w,r.y+r.h,wallH,wallH);
  // roof
  ctx.fillStyle='#4c342d';ctx.fillRect(r.x,r.y,r.w,r.h);
  // parapet / cornice
  ctx.fillStyle='#5a3c2d';ctx.fillRect(r.x-2,r.y-3,r.w+4,5);ctx.fillRect(r.x+r.w-1,r.y-3,wallH+3,5);
  // AC units on roof
  if(i%2===0){ctx.fillStyle='#3a4048';ctx.fillRect(r.x+r.w-40,r.y+8,18,14);ctx.fillStyle='#2a3038';ctx.beginPath();ctx.arc(r.x+r.w-31,r.y+15,5,0,Math.PI*2);ctx.fill();}
  if(i%3===1){ctx.fillStyle='#3a4048';ctx.fillRect(r.x+20,r.y+12,14,10);}
  // rooftop water tower
  if(i===5||i===8){const tx=r.x+r.w-70,ty=r.y+20;ctx.fillStyle='#3a342c';ctx.fillRect(tx-9,ty-4,3,6);ctx.fillRect(tx+6,ty-4,3,6);ctx.fillStyle='#5a4632';ctx.fillRect(tx-8,ty-12,16,9);ctx.fillStyle='#6a5238';ctx.beginPath();ctx.arc(tx,ty-12,8,Math.PI,0);ctx.fill();ctx.fillStyle='#4a3a2a';ctx.fillRect(tx-8,ty-4,16,2);ctx.strokeStyle='#4a3828';ctx.lineWidth=1;ctx.strokeRect(tx-8,ty-12,16,9);}
  // antenna
  if(i===4||i===9){const ax=r.x+r.w/2;ctx.fillStyle='#3a4046';ctx.fillRect(ax-1,r.y-26,2,26);ctx.fillStyle='#4a5056';ctx.fillRect(ax-8,r.y-28,16,2);ctx.fillRect(ax-1,r.y-30,2,3);}
  // satellite dish
  if(i===7){const sx=r.x+60,sy=r.y+26;ctx.strokeStyle='#4a5056';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(sx-10,sy-14);ctx.lineTo(sx-10,sy);ctx.stroke();ctx.fillStyle='#565e66';ctx.beginPath();ctx.ellipse(sx-10,sy-10,6,8,0,0,Math.PI*2);ctx.fill();ctx.fillStyle='#6a727a';ctx.beginPath();ctx.arc(sx-10,sy-10,3,0,Math.PI*2);ctx.fill();}
  // window grid (skylights, some boarded)
  for(let x=r.x+14;x<r.x+r.w-10;x+=36)for(let y=r.y+14;y<r.y+r.h-10;y+=32){
    if((x+y*3)%5===0){ctx.fillStyle='#3a2c20';ctx.fillRect(x,y,16,7);ctx.strokeStyle='#2a2018';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+16,y+7);ctx.moveTo(x+16,y);ctx.lineTo(x,y+7);ctx.stroke();}
    else{ctx.fillStyle='#6c4935';ctx.fillRect(x,y,16,7);}
  }
  // roof edge
  ctx.strokeStyle='#976040';ctx.lineWidth=1;ctx.strokeRect(r.x+.5,r.y+.5,r.w-1,r.h-1);
  // south wall bottom
  ctx.strokeStyle='#5a3c28';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(r.x,r.y+r.h+wallH);ctx.lineTo(r.x+r.w,r.y+r.h+wallH);ctx.stroke();
  // east wall right
  ctx.strokeStyle='#4a3020';ctx.beginPath();ctx.moveTo(r.x+r.w+wallH,r.y);ctx.lineTo(r.x+r.w+wallH,r.y+r.h+wallH);ctx.stroke();
  // Lit windows on south wall (varied warmth)
  for(let wx=r.x+16;wx<r.x+r.w-10;wx+=34){const fl=Math.sin(S.time*2+wx*.1)*.1+.9,warm=(wx*7%3===0)?'255,180,90':'255,195,110';ctx.fillStyle=`rgba(${warm},${(.38*fl).toFixed(2)})`;ctx.fillRect(wx,r.y+r.h+4,11,7);
    // window frame
    ctx.strokeStyle='rgba(0,0,0,0.3)';ctx.strokeRect(wx,r.y+r.h+4,11,7);}
  // East wall windows
  for(let wy=r.y+18;wy<r.y+r.h-10;wy+=30){const fl=Math.sin(S.time*1.7+wy*.1)*.1+.9;ctx.fillStyle=`rgba(255,195,110,${(.3*fl).toFixed(2)})`;ctx.fillRect(r.x+r.w+4,wy,7,11);}
  // storefront door + awning on some facades
  if(i===3||i===7||i===9){const dx=r.x+16,dy=r.y+r.h+3;ctx.fillStyle='#1f1612';ctx.fillRect(dx,dy,15,19);ctx.fillStyle='#4d3528';ctx.fillRect(dx+1,dy+1,13,18);ctx.fillStyle='#2d2118';ctx.fillRect(dx+9,dy+6,4,13);ctx.fillStyle='#d9b45c';ctx.fillRect(dx+3,dy+4,2,3);ctx.fillStyle='rgba(110,58,36,0.6)';ctx.beginPath();ctx.moveTo(dx-6,dy);ctx.lineTo(dx+21,dy);ctx.lineTo(dx+17,dy-5);ctx.lineTo(dx-2,dy-5);ctx.closePath();ctx.fill();}
  if(i>=5&&i!==7){ctx.fillStyle='rgba(120,60,40,0.5)';ctx.beginPath();ctx.moveTo(r.x+8,r.y+r.h+2);ctx.lineTo(r.x+60,r.y+r.h+2);ctx.lineTo(r.x+55,r.y+r.h-4);ctx.lineTo(r.x+13,r.y+r.h-4);ctx.fill();}
  // facade graffiti
  if(i===2||i===6){ctx.strokeStyle='rgba(212,66,90,0.5)';ctx.lineWidth=2;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(r.x+26,r.y+34);ctx.lineTo(r.x+38,r.y+26);ctx.lineTo(r.x+42,r.y+42);ctx.lineTo(r.x+54,r.y+28);ctx.moveTo(r.x+58,r.y+40);ctx.lineTo(r.x+70,r.y+30);ctx.stroke();ctx.fillStyle='rgba(238,180,60,0.35)';ctx.beginPath();ctx.arc(r.x+88,r.y+50,7,0,Math.PI*2);ctx.fill();}
  // Neon shop sign on south wall
  if(i>=4){const SN=[['FIX','#e85d75'],['BAR','#6be8c9'],['KINO','#8b7bf0'],['24H','#f0c14b'],['SHOP','#5be2d4'],['HOTEL','#f0844b']],ns=SN[i-4]||SN[0],sx=r.x+r.w/2,sy=r.y+r.h+wallH,fl=Math.sin(S.time*9+i)*.06+.94;ctx.save();ctx.globalAlpha=fl;ctx.shadowColor=ns[1];ctx.shadowBlur=12;ctx.fillStyle=ns[1];ctx.fillRect(sx-16,sy-7,32,14);ctx.shadowBlur=0;ctx.fillStyle='#0a0a0a';ctx.fillRect(sx-15,sy-6,30,12);ctx.fillStyle=ns[1];ctx.font='10px "Share Tech Mono",monospace';ctx.textAlign='center';ctx.fillText(ns[0],sx,sy+1);ctx.restore()}
}

function drawGameCar(c){
  ctx.save();ctx.translate(c.x,c.y);ctx.rotate(c.a);
  const col=c.hp>0?c.color:'#292929',dead=c.hp<=0,weak=c.hp>0&&c.hp<=50;
  // shadow
  ctx.fillStyle='rgba(0,0,0,0.35)';ctx.beginPath();ctx.ellipse(2,5,30,16,0,0,Math.PI*2);ctx.fill();
  // body
  ctx.fillStyle=col;roundRect(-26,-13,52,26,5);
  // metallic sheen
  if(!dead){ctx.fillStyle='rgba(255,255,255,0.07)';roundRect(-22,-11,40,9,2);}
  // panel lines
  ctx.strokeStyle=shadeColor(col,-50);ctx.lineWidth=1;
  ctx.beginPath();ctx.moveTo(-1,-13);ctx.lineTo(-1,13);ctx.stroke();
  ctx.beginPath();ctx.moveTo(10,-13);ctx.lineTo(10,13);ctx.stroke();
  // cabin
  ctx.fillStyle=shadeColor(col,-35);ctx.fillRect(-7,-9,14,18);
  // windshield with reflection
  const wg=ctx.createLinearGradient(-5,-7,-5,-2);wg.addColorStop(0,'#1a2a3a');wg.addColorStop(.5,'#2a4050');wg.addColorStop(1,'#1a2a3a');
  ctx.fillStyle=wg;ctx.fillRect(-5,-7,10,5);
  // rear window
  ctx.fillStyle='#142028';ctx.fillRect(7,-6,5,12);
  // side mirrors
  ctx.fillStyle=shadeColor(col,-20);ctx.fillRect(-26,-15,4,3);ctx.fillRect(-26,12,4,3);
  // chrome bumpers
  ctx.fillStyle='#8a8a8a';ctx.fillRect(-28,-11,3,2);ctx.fillRect(-28,9,3,2);ctx.fillRect(25,-11,3,2);ctx.fillRect(25,9,3,2);
  // headlights
  ctx.fillStyle=weak?'#886620':'#e9d680';ctx.fillRect(-28,-9,3,4);ctx.fillRect(-28,5,3,4);
  // taillights
  ctx.fillStyle='#c44';ctx.fillRect(25,-8,2,3);ctx.fillRect(25,5,2,3);
  // wheels (dark tire + lighter rim)
  ctx.fillStyle='#1a1a1a';
  for(const[wx,wy]of[[-16,-13],[-16,13],[14,-13],[14,13]]){ctx.beginPath();ctx.arc(wx,wy+1.5,4.5,0,Math.PI*2);ctx.fill();}
  ctx.fillStyle='#555';
  for(const[wx,wy]of[[-16,-13],[-16,13],[14,-13],[14,13]]){ctx.beginPath();ctx.arc(wx,wy+1.5,2.5,0,Math.PI*2);ctx.fill();}
  // chrome trim
  ctx.strokeStyle=dead?'#444':shadeColor(col,40);ctx.lineWidth=1;ctx.strokeRect(-25.5,-12.5,51,25);
  // roof rack line
  if(!dead){ctx.strokeStyle=shadeColor(col,20);ctx.beginPath();ctx.moveTo(-4,-13);ctx.lineTo(9,-13);ctx.stroke();}
  // damage cracks
  if(weak||dead){ctx.strokeStyle='rgba(0,0,0,0.45)';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(-15,-5);ctx.lineTo(-8,3);ctx.lineTo(-12,9);ctx.stroke();ctx.beginPath();ctx.moveTo(5,-8);ctx.lineTo(12,-2);ctx.lineTo(8,5);ctx.stroke();}
  ctx.restore();
  // ground shadow
  ctx.save();ctx.translate(c.x,c.y);ctx.rotate(c.a-Math.PI/2);
  ctx.globalAlpha=0.22;ctx.fillStyle=col;ctx.fillRect(-28,-15,56,30);ctx.globalAlpha=1;ctx.restore();
  // Headlight cone + taillight glow
  ctx.save();ctx.translate(c.x,c.y);ctx.rotate(c.a);
  ctx.globalCompositeOperation='lighter';
  ctx.fillStyle=`rgba(232,216,128,${(0.05+Math.random()*.025).toFixed(3)})`;
  ctx.beginPath();ctx.moveTo(-30,-8);ctx.lineTo(-130,-40);ctx.lineTo(-130,40);ctx.lineTo(-30,8);ctx.fill();
  ctx.fillStyle='rgba(220,80,80,0.12)';ctx.beginPath();ctx.arc(28,0,12,0,Math.PI*2);ctx.fill();
  ctx.globalCompositeOperation='source-over';ctx.restore();
}

function drawGamePerson(n){
  ctx.save();ctx.translate(n.x,n.y);const sc=n.hgt||1;ctx.scale(sc,sc);
  // shadow
  ctx.fillStyle='rgba(0,0,0,0.25)';ctx.beginPath();ctx.ellipse(0,4,8,5,0,0,Math.PI*2);ctx.fill();
  // legs
  ctx.fillStyle=shadeColor(n.col||'#8d6955',-25);ctx.fillRect(-4,5,3,6);ctx.fillRect(1,5,3,6);
  // body
  ctx.fillStyle=n.col||'#8d6955';ctx.beginPath();ctx.ellipse(0,0,7,9,0,0,Math.PI*2);ctx.fill();
  // belt
  ctx.fillStyle='#3a3020';ctx.fillRect(-5,2,10,2);
  // head
  const hx=Math.cos(n.a)*2,hy=Math.sin(n.a)*2-4;
  ctx.fillStyle=n.skin||'#d7ac7d';ctx.beginPath();ctx.arc(hx,hy,5,0,Math.PI*2);ctx.fill();
  // eyes
  ctx.fillStyle='#222';ctx.fillRect(hx-2,hy-1,1.5,1.5);ctx.fillRect(hx+1,hy-1,1.5,1.5);
  // hair
  ctx.fillStyle='#4a3828';ctx.beginPath();ctx.arc(hx,hy-1,4,Math.PI,0);ctx.fill();
  // accessories: 1=cap 2=hat 3=scarf
  if(n.acc===1){ctx.fillStyle='#5f5f5f';ctx.fillRect(hx-4,hy-4,8,3);ctx.fillRect(hx-3,hy-6,6,2)}
  if(n.acc===2){ctx.fillStyle='#6b4a2f';ctx.beginPath();ctx.arc(hx,hy-3,5,Math.PI,0);ctx.fill();ctx.fillRect(hx-5,hy-3,10,2)}
  if(n.acc===3){ctx.fillStyle='#b4553a';ctx.fillRect(hx-4,hy+1,8,2)}
  ctx.restore();
}

function drawGamePolice(n){
  ctx.save();ctx.translate(n.x,n.y);
  // shadow
  ctx.fillStyle='rgba(0,0,0,0.3)';ctx.beginPath();ctx.ellipse(0,4,9,6,0,0,Math.PI*2);ctx.fill();
  // legs
  ctx.fillStyle='#1a2a3a';ctx.fillRect(-4,5,3,6);ctx.fillRect(1,5,3,6);
  // body
  ctx.fillStyle='#315c78';ctx.beginPath();ctx.ellipse(0,0,8,10,0,0,Math.PI*2);ctx.fill();
  // harness
  ctx.strokeStyle='#1a3a50';ctx.lineWidth=1.5;
  ctx.beginPath();ctx.moveTo(-4,-4);ctx.lineTo(-4,6);ctx.moveTo(4,-4);ctx.lineTo(4,6);ctx.stroke();
  // belt
  ctx.fillStyle='#1a1a2a';ctx.fillRect(-6,2,12,3);ctx.fillStyle='#888';ctx.fillRect(-1,2,3,3);
  // badge
  ctx.fillStyle='#d4a840';ctx.beginPath();ctx.arc(-3,-3,2,0,Math.PI*2);ctx.fill();
  // shoulder light
  if(Math.sin(S.time*4+n.x)>.7){ctx.fillStyle='rgba(100,180,255,0.6)';ctx.beginPath();ctx.arc(6,-5,2,0,Math.PI*2);ctx.fill();}
  // head
  const hx=Math.cos(n.a)*2,hy=Math.sin(n.a)*2-5;
  ctx.fillStyle='#77c6e8';ctx.beginPath();ctx.arc(hx,hy,5,0,Math.PI*2);ctx.fill();
  // visor
  ctx.fillStyle='#e83030';ctx.fillRect(hx-4,hy-1,8,2);
  ctx.restore();
}

function drawNpc(n){
  ctx.save();ctx.translate(n.x,n.y);
  const B=n.body;
  // shadow
  ctx.fillStyle='rgba(0,0,0,0.28)';ctx.beginPath();ctx.ellipse(0,4,9,5,0,0,Math.PI*2);ctx.fill();
  // legs
  ctx.fillStyle=shadeColor(B[0],-20);ctx.fillRect(-4,6,3,7);ctx.fillRect(1,6,3,7);
  // body
  ctx.fillStyle=B[0];roundRect(-8,-12,16,25,3);
  // collar
  ctx.fillStyle=B[1];ctx.fillRect(-3,-12,6,4);
  // belt
  ctx.fillStyle='#2a2420';ctx.fillRect(-7,3,14,2);
  // head
  ctx.fillStyle=B[2];ctx.beginPath();ctx.arc(0,-16,5.5,0,Math.PI*2);ctx.fill();
  // eyes
  ctx.fillStyle='#1a1a1a';ctx.fillRect(-2,-17,1.5,1.5);ctx.fillRect(1,-17,1.5,1.5);
  // hair
  ctx.fillStyle=B[3];ctx.beginPath();ctx.arc(0,-18,4.5,Math.PI,0);ctx.fill();
  // hat
  if(n.hat){ctx.fillStyle='#1c1c22';ctx.fillRect(-7,-24,14,4);ctx.fillRect(-4,-28,8,5)}
  // helmet
  if(n.helm){ctx.fillStyle=B[4];ctx.beginPath();ctx.arc(0,-19,6,Math.PI,0);ctx.fill();ctx.fillRect(-6,-18,12,2);}
  // hood
  if(n.hood){ctx.fillStyle=B[4];ctx.beginPath();ctx.arc(0,-18,7.5,Math.PI,0);ctx.fill();ctx.fillRect(-7,-15,14,3);}
  // goggles
  if(n.goggles){ctx.fillStyle='#cfe8ee';ctx.fillRect(-5,-18,3,3);ctx.fillRect(2,-18,3,3);ctx.strokeStyle='#1c2a30';ctx.lineWidth=1;ctx.strokeRect(-5,-19,10,5);}
  // scarf
  if(n.scarf){ctx.fillStyle=B[4];ctx.fillRect(-5,-11,10,3);}
  ctx.restore();
}

function drawGamePlayer(p){
  ctx.save();ctx.translate(p.x,p.y);
  // shadow
  ctx.fillStyle='rgba(0,0,0,0.3)';ctx.beginPath();ctx.ellipse(0,5,10,6,0,0,Math.PI*2);ctx.fill();
  // legs
  ctx.fillStyle='#2a2840';ctx.fillRect(-4,6,3,7);ctx.fillRect(1,6,3,7);
  // body (JMac orange hoodie)
  ctx.fillStyle='#d66b3d';ctx.beginPath();ctx.ellipse(0,0,9,11,0,0,Math.PI*2);ctx.fill();
  // hoodie seam
  ctx.strokeStyle='#b5552a';ctx.lineWidth=1;
  ctx.beginPath();ctx.moveTo(-3,-3);ctx.lineTo(-3,8);ctx.moveTo(3,-3);ctx.lineTo(3,8);ctx.stroke();
  // hood collar
  ctx.fillStyle='#c5603a';ctx.beginPath();ctx.arc(0,-8,6,Math.PI*1.2,Math.PI*1.8);ctx.fill();
  // pocket
  ctx.strokeStyle='#b5552a';ctx.lineWidth=1;ctx.strokeRect(-5,1,10,5);
  // belt
  ctx.fillStyle='#2a2420';ctx.fillRect(-7,5,14,2);
  // head
  const hx=Math.cos(p.angle)*2,hy=Math.sin(p.angle)*2-6;
  ctx.fillStyle='#e4bf8c';ctx.beginPath();ctx.arc(hx,hy,6,0,Math.PI*2);ctx.fill();
  // eyes
  ctx.fillStyle='#1a1a2a';ctx.fillRect(hx-2,hy-1,1.5,1.5);ctx.fillRect(hx+1,hy-1,1.5,1.5);
  // hair (dark spiky)
  ctx.fillStyle='#2a2040';ctx.beginPath();ctx.arc(hx,hy-2,5,Math.PI*0.8,Math.PI*0.2);ctx.fill();
  ctx.beginPath();ctx.moveTo(hx-2,hy-5);ctx.lineTo(hx,hy-9);ctx.lineTo(hx+2,hy-5);ctx.fill();
  // gun arm
  ctx.fillStyle='#b5b1a3';ctx.save();ctx.translate(Math.cos(p.angle)*14,Math.sin(p.angle)*14);ctx.rotate(p.angle);
  ctx.fillRect(0,-2,12,4);ctx.fillStyle='#8a8680';ctx.fillRect(10,-3,4,6);ctx.restore();
  ctx.restore();
}

const rects=[
{x:0,y:0,w:WORLD.w,h:150},{x:0,y:1200,w:WORLD.w,h:150},{x:0,y:0,w:180,h:WORLD.h},{x:2220,y:0,w:180,h:WORLD.h},
{x:280,y:230,w:470,h:260},{x:880,y:190,w:420,h:310},{x:1450,y:220,w:520,h:250},{x:300,y:770,w:500,h:270},{x:980,y:760,w:450,h:280},{x:1560,y:760,w:500,h:280}
];
const roads=[{x:180,y:500,w:2040,h:220},{x:800,y:150,w:80,h:1050},{x:1360,y:150,w:90,h:1050}];
const spawn={x:485,y:600};
let S;
const dialogues={
intro:[['FB-13','Good morning, courier. City is bankrupt, sky is rust, and somebody stole your car. So: Tuesday.'],['JMAC','Echotel repossessed it. They took Mayor Burn’s sedan too.'],['FB-13','Mayor Burn is waiting at the garage. Find him before the patrol sweeps the block.']],
burn:[['MAYOR BURN','JMac! Scrapheap’s favorite unemployed archivist. Echotel repossessed my municipal sedan.'],['JMAC','I can hotwire the municipal frequency.'],['MAYOR BURN','Bring it back to this garage. I have Lira’s location stored in the trunk memory.']],
lira:[['LIRA','That case hums. Echotel memory tech?'],['JMAC','Officially, plumbing parts.'],['LIRA','Officially, I’m repairing the district relay. Connect the case to the relay box up north before Echotel traces us!']],
burn2:[['MAYOR BURN','JMac. You remember the payout — my trunk, my whole life in it. It’s still out on the strip.']],
lira2:[['LIRA','Relay box at the district’s north edge. Plug the case in and vanish before the tower gets a lock.']],
relaytech:[['RELAY TECH','Signal bleeds across every block. You smell ozone? That’s the tower listening. Make it quick.']],
kael2:[['SISTER KAEL','HS-7 is no toy, courier. It’s the city’s wound. Aim it at the Core and stop running.']],
corekeeper:[['CORE KEEPER','The Silent Core hums even when the district sleeps. It remembers every memory we sold. Yours too.']],
kael:[['SISTER KAEL','HS-7 carries the night Echotel fell. The Archivist did not erase this city. The city paid to forget.'],['JMAC','Where is the Silent Core?'],['SISTER KAEL','Deep in the Gears District. Take HS-7 to the altar. Let the city remember.']]
};
const missions=[
{title:'CIVIC REPOSSESSION',steps:['Talk to Mayor Burn at the garage','Recover the mayor’s sedan','Return the sedan to Mayor Burn']},
{title:'SPECIAL DELIVERY',steps:['Collect the memory case from Lira','Drive the case to Echotel Relay','Lose the police pursuit']},
{title:'THE CITY THAT FORGOT',steps:['Meet Sister Kael at the shrine','Use HS-7 at the Silent Core','Escape the Gears District']}
];
function fresh(){
  const s = {
    player:{x:spawn.x,y:spawn.y,r:13,speed:185,hp:100,ammo:60,angle:0,inCar:null,wf:0,moving:false,cool:0},
    mission:0,step:0,heat:0,wanted:0,memories:0,flags:{},message:'',msgTime:0,dialogue:null,di:0,time:0
  };
  window.GAME_STATE = s;
  return s;
}
const cars=[
  {id:0,x:1010,y:610,a:0,v:0,hp:100,color:'#b79563',target:true,occupied:false},
  {id:1,x:650,y:610,a:Math.PI,v:0,hp:100,color:'#9a3e32',target:false,occupied:false},
  {id:2,x:1530,y:610,a:0,v:0,hp:100,color:'#387078',target:false,occupied:false},
  {id:3,x:1850,y:610,a:Math.PI,v:0,hp:100,color:'#655074',target:false,occupied:false}
];
const people=[];
const SKINS=['#d7ac7d','#c68d63','#8a5a3b','#5d3d2a','#e8c9a5'];
const CLOTHES=['#8d6955','#5a7a68','#7a5a72','#6b5a3a','#3f6070','#8a4a4a','#5a5a6b','#7a6a4a'];
const npcs=[
{x:430,y:529,body:['#3b2f3a','#d8d0c0','#e0b98f','#9a9a9a','#222'],hat:1,prop:'briefcase'},
{x:1200,y:684,body:['#2d5f63','#1f3a3d','#d9a077','#1a2220','#3f8f93'],goggles:1,scarf:1,prop:'case'},
{x:1510,y:674,body:['#2c4a41','#1e332c','#e6c9a8','#2a1512','#3f7a63'],hood:1,prop:'staff'},
{x:1900,y:594,body:['#5a6b3a','#c8b060','#d9a077','#33271f','#f0a030'],helm:1,goggles:1,prop:'tool'},
{x:2050,y:674,body:['#3d2f4a','#241b30','#dcc6a8','#1f1726','#7a5bb0'],hood:1,prop:'lantern'}
];
const landmarks={burn:{x:430,y:535},lira:{x:1200,y:690},relay:{x:1900,y:600},kael:{x:1510,y:680},core:{x:2050,y:680},exit:{x:2200,y:600}};
let bullets=[],police=[],particles=[],decor=[],GD=[];
function save(){
  if (window.SaveState) {
    const defaultState = window.SaveState.createDefault(S.player, cars, { currentId: S.mission, stepIndex: S.step, completed: [], flags: S.flags }, { heat: S.heat, wanted: S.wanted, cooldown: 0 }, { intensity: 0, active: false }, { destabilization: 0, active: false });
    window.SaveState.save(defaultState);
  } else {
    localStorage.setItem(SAVE,JSON.stringify({mission:S.mission,step:S.step,flags:S.flags,memories:S.memories,px:S.player.x,py:S.player.y,hp:S.player.hp,ammo:S.player.ammo}));
  }
}
function load(){
  S=fresh();
  try{
    if (window.SaveState) {
      const data = window.SaveState.load();
      if (!data) return false;
      if (data.missionState) { S.mission = data.missionState.currentMissionId || 0; S.step = data.missionState.stepIndex || 0; }
      if (data.player) { S.player.x = data.player.x; S.player.y = data.player.y; S.player.hp = data.player.health; S.player.ammo = data.player.ammo; }
      if (data.worldFlags) Object.assign(S.flags, data.worldFlags);
      return true;
    }
    const d=JSON.parse(localStorage.getItem(SAVE));
    if(!d)return false;
    Object.assign(S,d);
    Object.assign(S.flags,d.flags||{});
    if(d.px!==undefined){S.player.x=d.px;S.player.y=d.py;S.player.hp=d.hp||100;S.player.ammo=d.ammo||60;}
    return true;
  }catch(e){return false;}
}
function initDecor(){
  decor.length=0;GD.length=0;
  const P=(x,y,k)=>decor.push({x,y,k});
  // curbside + alley props
  P(300,505,'hydrant');P(410,503,'bench');P(600,498,'dumpster');P(690,505,'crate');P(880,516,'trash');P(1040,504,'planter');P(1180,502,'barrel');P(1265,498,'sign');
  P(1470,476,'stack');P(1620,470,'dumpster');P(1795,474,'barrel');P(1895,474,'bench');P(2050,478,'crate');
  P(315,782,'crate');P(520,782,'dumpster');P(700,786,'planter');P(1000,772,'hydrant');P(1145,768,'bench');P(1345,774,'barrel');
  P(1580,780,'trash');P(1700,774,'crate');P(1900,770,'dumpster');P(2020,768,'sign');
  P(782,505,'sign');P(1342,505,'hydrant');P(782,690,'barrel');P(1342,690,'crate');
  P(215,615,'trash');P(2180,615,'trash');P(345,650,'planter');P(1995,655,'crate');
  // ground decals
  [[300,560,14],[700,640,10],[1100,680,16],[1500,540,12],[1900,660,14],[220,580,8],[500,680,12],[1300,590,10],[2000,540,9],[900,540,11],[1600,630,9],[240,660,10]].forEach(([x,y,r])=>GD.push({k:'stain',x,y,r,a:rnd(.2,.35)}));
  [[420,600],[760,550],[1200,700],[1650,520],[2100,640],[260,600],[860,660],[1450,620],[1900,700],[1000,560]].forEach(([x,y])=>GD.push({k:'crack',x,y}));
  [[600,560],[1000,700],[1500,590],[2000,560],[400,660],[1150,560],[1750,680],[820,600],[1380,650],[230,540]].forEach(([x,y])=>GD.push({k:'grate',x,y}));
  [[350,640],[750,520],[950,580],[1250,620],[1550,560],[1850,600],[2100,520],[480,580],[1350,660],[1700,540],[260,680],[2050,650]].forEach(([x,y])=>GD.push({k:'litter',x,y,ph:rnd(0,Math.PI*2),c:Math.random()<.5?'#8a8f92':'#c9a06a'}));
}
function drawGroundDecals(cam){
  for(const d of GD){
    if(d.x<cam.x-30||d.x>cam.x+W+30||d.y<cam.y-30||d.y>cam.y+H+30)continue;
    if(d.k==='stain'){ctx.fillStyle=`rgba(12,16,20,${d.a})`;ctx.beginPath();ctx.ellipse(d.x,d.y,d.r,d.r*.55,0,0,Math.PI*2);ctx.fill();}
    else if(d.k==='crack'){ctx.strokeStyle='rgba(10,13,16,0.5)';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(d.x-6,d.y);ctx.lineTo(d.x-2,d.y-2);ctx.lineTo(d.x+1,d.y+1);ctx.lineTo(d.x+5,d.y-1);ctx.lineTo(d.x+8,d.y+2);ctx.stroke();}
    else if(d.k==='grate'){ctx.fillStyle='#1a1e22';ctx.fillRect(d.x-6,d.y-3,12,6);ctx.fillStyle='#0e1114';for(let i=-4;i<=4;i+=2)ctx.fillRect(d.x+i,d.y-3,1,6);ctx.strokeStyle='#2a2e32';ctx.lineWidth=1;ctx.strokeRect(d.x-6,d.y-3,12,6);}
    else{ctx.save();ctx.translate(d.x,d.y);ctx.rotate(d.ph);ctx.fillStyle=d.c;ctx.fillRect(-2,-1,4,3);ctx.fillStyle='#e8e2d2';ctx.fillRect(0,0,2,1);ctx.restore();}
  }
}
function drawProp(pr){
  ctx.save();ctx.translate(pr.x,pr.y);
  ctx.fillStyle='rgba(0,0,0,0.22)';ctx.beginPath();ctx.ellipse(0,3,9,3.5,0,0,Math.PI*2);ctx.fill();
  switch(pr.k){
    case 'hydrant':
      ctx.fillStyle='#a03a2c';ctx.fillRect(-4,-9,8,9);ctx.fillStyle='#8a2f24';ctx.fillRect(-4,-9,8,2);
      ctx.beginPath();ctx.arc(-3,-9,2,0,Math.PI*2);ctx.arc(3,-9,2,0,Math.PI*2);ctx.fill();
      ctx.fillStyle='#b84a3a';ctx.beginPath();ctx.arc(0,-13,3.5,Math.PI,0);ctx.fill();ctx.fillStyle='#8a2f24';ctx.fillRect(-1.5,-15,3,2);break;
    case 'bench':
      ctx.fillStyle='#3a2c22';ctx.fillRect(-10,-6,20,2);ctx.fillStyle='#2e241c';ctx.fillRect(-10,-4,20,1);ctx.fillRect(-9,2,2,4);ctx.fillRect(7,2,2,4);
      ctx.fillStyle='#4a3a2a';ctx.fillRect(-9,-8,18,1);break;
    case 'dumpster':
      ctx.fillStyle='#3f4a40';ctx.fillRect(-11,-9,22,9);ctx.fillStyle='#4d5a4e';ctx.fillRect(-11,-9,22,2);
      ctx.fillStyle='#333c34';ctx.fillRect(5,-12,3,4);ctx.fillRect(-9,-9,2,9);ctx.fillRect(-4,-9,1,9);ctx.fillRect(1,-9,1,9);
      ctx.fillStyle='#55624e';ctx.fillRect(-11,-10,22,1);break;
    case 'crate':
      ctx.fillStyle='#6b4f33';ctx.fillRect(-7,-7,14,7);ctx.fillStyle='#7d5e3f';ctx.fillRect(-7,-7,14,2);
      ctx.strokeStyle='#54402a';ctx.lineWidth=1;ctx.strokeRect(-7,-7,14,7);ctx.fillStyle='#54402a';ctx.fillRect(-7,-3,14,1);ctx.fillRect(-2,-7,1,7);break;
    case 'stack':
      ctx.fillStyle='#6b4f33';ctx.fillRect(-7,-7,14,7);ctx.fillStyle='#5d442c';ctx.fillRect(-4,-13,14,7);
      ctx.strokeStyle='#54402a';ctx.lineWidth=1;ctx.strokeRect(-4,-13,14,7);ctx.strokeRect(-7,-7,14,7);break;
    case 'barrel':
      ctx.fillStyle='#6a4a32';ctx.fillRect(-5,-9,10,9);ctx.fillStyle='#7d5a3a';ctx.beginPath();ctx.ellipse(0,-9,5,2,0,0,Math.PI*2);ctx.fill();
      ctx.strokeStyle='#54402a';ctx.lineWidth=1;ctx.strokeRect(-5,-6,10,1);ctx.strokeRect(-5,-2,10,1);
      ctx.fillStyle='#3a5a4a';ctx.fillRect(-4,-10,3,1.5);break;
    case 'trash':
      ctx.fillStyle='#26231e';ctx.beginPath();ctx.ellipse(0,-4,7,5,0,0,Math.PI*2);ctx.fill();
      ctx.fillStyle='#33302a';ctx.beginPath();ctx.ellipse(1,-6,5,3.5,0,0,Math.PI*2);ctx.fill();
      ctx.fillStyle='#8a7a6a';ctx.fillRect(-3,-8,2,2);break;
    case 'planter':
      ctx.fillStyle='#4a4036';ctx.fillRect(-8,-6,16,6);ctx.fillStyle='#5a4e40';ctx.fillRect(-8,-6,16,2);
      ctx.fillStyle='#3f7a4a';ctx.beginPath();ctx.arc(-4,-9,3,0,Math.PI*2);ctx.arc(0,-11,3.5,0,Math.PI*2);ctx.arc(4,-9,3,0,Math.PI*2);ctx.fill();
      ctx.fillStyle='#5a8a5a';ctx.fillRect(-2,-14,2,5);break;
    case 'sign':
      ctx.fillStyle='#4a5260';ctx.fillRect(-1,-14,2,14);ctx.fillStyle='#3a4250';ctx.fillRect(-8,-16,16,5);ctx.fillStyle='#2c3440';ctx.fillRect(-6,-15,5,3);ctx.fillStyle='#7a8288';ctx.fillRect(0,-15,3,3);break;
  }
  ctx.restore();
}
function resetWorld(){
  const init=[{x:1010,y:610,a:0},{x:650,y:610,a:Math.PI},{x:1530,y:610,a:0},{x:1850,y:610,a:Math.PI}];
  cars.forEach((c,i)=>Object.assign(c,init[i],{id:i,v:0,hp:100,occupied:false}));
  people.length=0;
  for(let i=0;i<20;i++)people.push({x:rnd(210,2190),y:rnd(520,700),r:10,type:'civilian',hp:30,a:rnd(0,Math.PI*2),cool:rnd(1,4),wf:0,moving:false,col:CLOTHES[Math.floor(Math.random()*CLOTHES.length)],skin:SKINS[Math.floor(Math.random()*SKINS.length)],hgt:rnd(.9,1.1),acc:Math.floor(Math.random()*4)});
  bullets=[];police=[];particles=[];ripples.length=0;decor.length=0;GD.length=0;initDecor();initAtmosphere();
}
function start(cont){
  boot=false;cancelAnimationFrame(bootRAF);
  if(!cont||!load())S=fresh();
  resetWorld();
  running=true;
  paused=false;
  document.querySelector('#start').classList.add('hidden');
  talk('intro');
  requestAnimationFrame(loop);
}
function talk(id){S.dialogue=dialogues[id];S.di=0;sfx('blip')}
function flash(text,t=2.5){S.message=text;S.msgTime=t;}
function solid(x,y,r=10){return rects.some(q=>x+r>q.x&&x-r<q.x+q.w&&y+r>q.y&&y-r<q.y+q.h)}
function moveBody(o,dx,dy,r=o.r||12){if(!solid(o.x+dx,o.y,r))o.x=clamp(o.x+dx,r,WORLD.w-r);if(!solid(o.x,o.y+dy,r))o.y=clamp(o.y+dy,r,WORLD.h-r)}
function addHeat(n){S.heat=clamp(S.heat+n,0,100);S.wanted=Math.ceil(S.heat/25);}
function spawnPolice(){const p=S.player;let a=Math.random()*Math.PI*2,d=380;let px=clamp(p.x+Math.cos(a)*d,200,2200),py=clamp(p.y+Math.sin(a)*d,160,1190);if(dist(p,{x:px,y:py})<150){px=clamp(p.x-Math.cos(a)*d,200,2200);py=clamp(p.y-Math.sin(a)*d,160,1190);}police.push({x:px,y:py,r:10,hp:40,a:0,wf:0,moving:false});}
function shoot(x,y,a,enemy=false){
  bullets.push({x,y,vx:Math.cos(a)*520,vy:Math.sin(a)*520,life:1.3,enemy});
  for(let i=0;i<4;i++)particles.push({x,y,vx:Math.cos(a+rnd(-.3,.3))*rnd(50,120),vy:Math.sin(a+rnd(-.3,.3))*rnd(50,120),life:rnd(.08,.18),color:enemy?'#f05b58':'#f9dd6c'});
  for(let i=0;i<3;i++)particles.push({x:x-Math.cos(a)*8,y:y-Math.sin(a)*8,vx:Math.cos(a)*rnd(-20,10),vy:Math.sin(a)*rnd(-20,10)+rnd(-18,4),life:rnd(.3,.65),color:'#454b52',sz:rnd(5,9)});
  if(!enemy) {
    flashTime=.08;
    if(window.nostrGateway) window.nostrGateway.emitPlayerEcho('shoot', 'gears_district', 0.4);
  }
  sfx('shoot');
}
function objective(){return S.mission>=missions.length?'VERTICAL SLICE COMPLETE':missions[S.mission].steps[S.step]}
function advance(){
  S.step++;
  if(window.nostrGateway) window.nostrGateway.emitPlayerEcho('mission_step', 'gears_district', 0.7, missions[S.mission]?missions[S.mission].id:null);
  if(S.step>=3){S.mission++;S.step=0;save();flash(S.mission>=3?'THE SILENT CORE REMEMBERS YOU':'MISSION COMPLETE');sfx('echo');}else{sfx('blip');}
}
function interact(){
  if(S.dialogue){S.di++;sfx('blip');if(S.di>=S.dialogue.length)S.dialogue=null;return}
  const p=S.player;
  if(p.inCar!==null){const c=cars[p.inCar];if(c)c.occupied=false;p.inCar=null;let ex=c?c.x+Math.cos(c.a+Math.PI/2)*30:p.x,ey=c?c.y+Math.sin(c.a+Math.PI/2)*30:p.y;if(solid(ex,ey,12)){ex=c?c.x:p.x;ey=c?c.y:p.y;}p.x=ex;p.y=ey;sfx('blip');return}
  const car=cars.find(c=>dist(p,c)<44&&c.hp>0);
  if(car){p.inCar=car.id;car.occupied=true;sfx('blip');return}
  if(S.mission===0&&S.step===0&&dist(p,landmarks.burn)<60){talk('burn');S.flags.burn=true;advance()}
  else if(S.mission===0&&S.step===2&&dist(p,landmarks.burn)<75&&p.inCar===null&&dist(cars[0],landmarks.burn)<120)advance()
  else if(S.mission===1&&S.step===0&&dist(p,landmarks.lira)<60){talk('lira');S.flags.lira=S.flags.case=true;advance();addHeat(20)}
  else if(S.mission===2&&S.step===0&&dist(p,landmarks.kael)<60){talk('kael');S.flags.kael=true;advance()}
  else{
    const hit=[['burn','burn2'],['lira','lira2'],['relay','relaytech'],['kael','kael2'],['core','corekeeper']].find(([k])=>dist(p,landmarks[k])<60);
    if(hit&&!S.flags['npc_'+hit[0]]){S.flags['npc_'+hit[0]]=1;talk(hit[1])}
  }
}
function updateAtmosphere(dt,cam){
  const _nf=clamp(.6-Math.sin(S.time*.02),0,1),_ws=.5+_nf*.6+storm*.8;
  particles.forEach(q=>{q.x+=q.vx*dt;q.y+=q.vy*dt;q.life-=dt});particles=particles.filter(q=>q.life>0);
  if(Math.random()<dt*26)ripples.push({x:cam.x+rnd(10,W-10),y:cam.y+rnd(10,H-10),r:rnd(2,6),g:rnd(18,45),life:0});
  ripples.forEach(q=>{q.life+=dt*40;q.r+=dt*14});ripples.splice(0,ripples.length,...ripples.filter(q=>q.life<q.g));
  rain.forEach(d=>{d.y+=d.speed*_ws*dt;d.x-=d.speed*_ws*(.06+wind)*dt;if(d.y>H){d.y=-d.len;d.x=rnd(0,W)}});
  embers.forEach(e=>{e.x+=e.vx*dt;e.y+=e.vy*dt;e.life-=dt;if(e.life<=0){e.x=rnd(210,2190);e.y=rnd(600,700);e.life=e.ml}});
  fog.forEach(f=>{const fm=.4+_nf*.8;f.x+=f.vx*fm*dt;f.y+=f.vy*fm*dt;if(f.x<-260)f.x=WORLD.w+260;if(f.x>WORLD.w+260)f.x=-260;if(f.y<-120)f.y=WORLD.h+120;if(f.y>WORLD.h+120)f.y=-120});
  cars.forEach(c=>{if(c.hp<=0&&Math.random()<dt*30)particles.push({x:c.x+rnd(-12,12),y:c.y+rnd(-14,2),vx:rnd(-5,5),vy:rnd(-18,-6),life:rnd(.8,1.6),color:'#454b52',sz:rnd(4,9),pa:.5})});
}
function update(dt){
  if(paused)return;S.time+=dt;S.msgTime=Math.max(0,S.msgTime-dt);const p=S.player;p.cool=Math.max(0,p.cool-dt);
  if (window.cameraInstance) { window.cameraInstance.update(dt, p.x, p.y); }
  if (window.simulation) { window.simulation.update(dt); }
  if(S.dialogue)return;
  if(keys.KeyQ){
    keys.KeyQ=false;flash('FB-13 THRUM // MECHANISMS RESONATE');sfx('thrum');
    if(window.audioEngine) window.audioEngine.setThrum(0.85);
    if(window.nostrGateway) window.nostrGateway.emitPlayerEcho('thrum', 'gears_district', 0.85);
    for(const cop of police)if(dist(p,cop)<120)cop.hp-=20;
  }
  if(keys.KeyR){
    keys.KeyR=false;
    sfx('echo');
    if(window.nostrGateway) window.nostrGateway.emitPlayerEcho('echo', 'gears_district', 0.85);
    if(S.mission===2&&S.step===1&&dist(p,landmarks.core)<80){S.flags.core=true;S.memories=3;advance()}else if(S.memories)flash('HS-7 ECHO // '+['A lobby full of rain.','Echotel signed the collapse protocol.','Sister Kael holds the master key.'][S.memories-1])
  }
  if(p.inCar!==null){
    const c=cars[p.inCar];
    if(c){
      if(c.hp<=0){p.inCar=null;c.occupied=false;flash('VEHICLE DESTROYED - DISMOUNTED');sfx('hit');return;}
      const acc=(keys.KeyW?250:0)-(keys.KeyS?180:0);
      c.v+=acc*dt;c.v*=Math.pow(.965,dt*60);c.v=clamp(c.v,-90,260);
      if(Math.abs(c.v)>8)c.a+=((keys.KeyD?1:0)-(keys.KeyA?1:0))*2.2*dt*Math.sign(c.v);
      const ox=c.x,oy=c.y;moveBody(c,Math.cos(c.a)*c.v*dt,Math.sin(c.a)*c.v*dt,17);
      if(Math.abs(c.v)>30&&Math.random()<dt*24)particles.push({x:c.x-Math.cos(c.a)*24,y:c.y-Math.sin(c.a)*24,vx:Math.cos(c.a)*rnd(-25,-5)+rnd(-7,7),vy:Math.sin(c.a)*rnd(-25,-5)+rnd(-15,-5),life:rnd(.5,.9),color:'#3a4148',sz:rnd(3,6),pa:.55});
      if(c.x===ox&&c.y===oy&&Math.abs(c.v)>15){
        c.v*=-.35;shake=7;sfx('hit');
        const imp=Math.abs(c.v);
        if(imp>60){
          c.hp=Math.max(0,c.hp-imp*.4);
          for(let i=0;i<Math.min(14,imp/12|0);i++)particles.push({x:c.x+rnd(-6,6),y:c.y+rnd(-4,4),vx:rnd(-240,240),vy:rnd(-240,180),life:rnd(.15,.45),color:Math.random()<.6?'#ffd27a':'#ff8a5a',sz:rnd(1.5,3)});
          for(let i=0;i<6;i++)particles.push({x:c.x+rnd(-8,8),y:c.y+rnd(-6,2),vx:rnd(-16,16),vy:rnd(-42,-8),life:rnd(.6,1.3),color:'#3a4148',sz:rnd(5,11),pa:.6});
          if(c.hp<=0){c.hp=0;flash('VEHICLE WRECKED');shake=12;sfx('hit');p.inCar=null;c.occupied=false;}
        }
      }
      // ── CAR-CAR COLLISION ──
      for(const o of cars){
        if(o.id===c.id)continue;
        const d=dist(c,o);
        if(d<44){
          const imp=Math.abs(c.v),wasC=c.hp>0,wasO=o.hp>0;
          const nx=d>0?(c.x-o.x)/d:1,ny=d>0?(c.y-o.y)/d:0;
          c.x+=nx*(44-d)*.5;c.y+=ny*(44-d)*.5;
          c.v*=-.2;c.hp=Math.max(0,c.hp-imp*.2);
          o.hp=Math.max(0,o.hp-imp*.5);
          shake=Math.max(shake,5);sfx('hit');
          const mx=(c.x+o.x)/2,my=(c.y+o.y)/2;
          for(let i=0;i<Math.min(14,imp/12|0);i++)particles.push({x:mx+rnd(-6,6),y:my+rnd(-4,4),vx:rnd(-240,240),vy:rnd(-240,180),life:rnd(.15,.45),color:Math.random()<.6?'#ffd27a':'#ff8a5a',sz:rnd(1.5,3)});
          for(let i=0;i<6;i++)particles.push({x:mx+rnd(-8,8),y:my+rnd(-6,2),vx:rnd(-16,16),vy:rnd(-42,-8),life:rnd(.6,1.3),color:'#3a4148',sz:rnd(5,11),pa:.6});
          if(wasC&&c.hp<=0){c.hp=0;flash('VEHICLE WRECKED');shake=12;sfx('hit')}
          if(wasO&&o.hp<=0){o.hp=0;flash('VEHICLE DESTROYED');shake=10;sfx('hit')}
          break;
        }
      }
      p.x=c.x;p.y=c.y;p.angle=c.a;p.moving=Math.abs(c.v)>10;
    }
  }else{
    let dx=(keys.KeyD?1:0)-(keys.KeyA?1:0),dy=(keys.KeyS?1:0)-(keys.KeyW?1:0),l=Math.hypot(dx,dy)||1;
    p.moving=(dx!==0||dy!==0);
    moveBody(p,dx/l*p.speed*dt,dy/l*p.speed*dt);
    const cam=camera();p.angle=Math.atan2(mouse.y+cam.y-p.y,mouse.x+cam.x-p.x);
  }
  if(p.moving) p.wf=(p.wf+dt*8)%4; else p.wf=0;
  if((mouse.down||mouse.held)&&p.inCar===null&&p.ammo>0&&p.cool<=0){
    mouse.down=false;p.cool=0.16;p.ammo--;
    shoot(p.x+Math.cos(p.angle)*16,p.y+Math.sin(p.angle)*16,p.angle);
  }
  if(S.mission===0&&S.step===1&&p.inCar===0)advance();
  if(S.mission===1&&S.step===1&&S.flags.case&&dist(p,landmarks.relay)<75){S.flags.case=false;S.memories=1;advance();addHeat(50);}
  if(S.mission===1&&S.step===2&&S.wanted===0)advance();
  if(S.mission===2&&S.step===2&&dist(p,landmarks.exit)<70)advance();
  bullets.forEach(b=>{
    b.x+=b.vx*dt;b.y+=b.vy*dt;b.life-=dt;
    if(solid(b.x,b.y,2)){b.life=0;for(let i=0;i<3;i++)particles.push({x:b.x,y:b.y,vx:rnd(-100,100),vy:rnd(-100,100),life:rnd(.1,.25),color:b.enemy?'#f05b58':'#f9dd6c',sz:rnd(1,3)})}
    if(b.enemy){if(dist(b,p)<16){p.hp-=10;b.life=0;shake=10;sfx('hit');}}
    else{police.forEach(c=>{if(dist(b,c)<16){c.hp-=25;b.life=0;sfx('hit');if(c.hp<=0)addHeat(-5)}});}
  });
  bullets=bullets.filter(b=>b.life>0);
  people.forEach(n=>{
    if(n.hp<=0)return;n.cool-=dt;
    if(S.wanted&&dist(n,p)<250){n.a=Math.atan2(n.y-p.y,n.x-p.x);n.moving=true;}else if(n.cool<=0){n.cool=rnd(2,5);n.a=rnd(0,Math.PI*2);n.moving=Math.random()>.4;}
    if(n.moving){moveBody(n,Math.cos(n.a)*45*dt,Math.sin(n.a)*45*dt);n.wf=(n.wf+dt*6)%4;}else{n.wf=0;}
  });
  if(S.wanted&&police.length<S.wanted*2&&Math.random()<dt*1.5)spawnPolice();
  let seen=false;
  police.forEach(c=>{
    if(c.hp<=0)return;const d=dist(c,p),a=Math.atan2(p.y-c.y,p.x-c.x);if(d<500)seen=true;c.a=a;
    if(d>80){moveBody(c,Math.cos(a)*130*dt,Math.sin(a)*130*dt);c.wf=(c.wf+dt*7)%4;c.moving=true;}else{c.wf=0;c.moving=false;}
    if(Math.random()<dt*1.2)shoot(c.x,c.y,a,true);
  });
  police=police.filter(c=>c.hp>0);
  if(S.heat>0&&!seen){S.heat=Math.max(0,S.heat-dt*(S.step===2&&S.mission===1?13:5));S.wanted=Math.ceil(S.heat/25)}
  updateAtmosphere(dt,camera());
  if(p.hp<=0){p.hp=100;p.ammo=Math.max(20,p.ammo);p.inCar=null;p.x=spawn.x;p.y=spawn.y;S.heat=0;S.wanted=0;police=[];bullets=[];flash('ECHOTEL RECOVERY SIGNAL REBOOT');sfx('hit');}
  shake*=.84;flashTime=Math.max(0,flashTime-dt);const _wn=clamp(.6-Math.sin(S.time*.02),0,1);wind+=(Math.sin(S.time*.4)*.45+_wn*.15-wind)*dt*2;if(storm>0)storm=Math.max(0,storm-dt*1.6);if(storm2>0)storm2=Math.max(0,storm2-dt*5);if(!S.dialogue&&Math.random()<dt*(.03+_wn*.04)){storm=1;storm2=.3;sfx('thunder')}if(actx&&!S.dialogue&&Math.random()<dt*(S.wanted?.08:.012))sfx('siren');
}
function camera(){
  if (window.cameraInstance) {
    const offset = window.cameraInstance.getOffset();
    return {
      x: clamp(offset.x, 0, WORLD.w - W),
      y: clamp(offset.y, 0, WORLD.h - H)
    };
  }
  return {x:clamp(S.player.x-W/2,0,WORLD.w-W),y:clamp(S.player.y-H/2,0,WORLD.h-H)};
}
function box(x,y,w,h,color){
  ctx.fillStyle='rgba(6,9,12,0.9)';ctx.fillRect(x,y,w,h);
  ctx.globalAlpha=.22;ctx.strokeStyle=color;ctx.lineWidth=3;ctx.strokeRect(x+1,y+1,w-2,h-2);ctx.globalAlpha=1;
  ctx.lineWidth=1;ctx.strokeRect(x+.5,y+.5,w-1,h-1);
  ctx.beginPath();const t=6;
  ctx.moveTo(x+1,y+t);ctx.lineTo(x+1,y+1);ctx.lineTo(x+t,y+1);
  ctx.moveTo(x+w-t-1,y+1);ctx.lineTo(x+w-1,y+1);ctx.lineTo(x+w-1,y+t);
  ctx.moveTo(x+1,y+h-t);ctx.lineTo(x+1,y+h-1);ctx.lineTo(x+t,y+h-1);
  ctx.moveTo(x+w-t-1,y+h-1);ctx.lineTo(x+w-1,y+h-1);ctx.lineTo(x+w-1,y+h-t);
  ctx.stroke();
}
function text(t,x,y,size=15,color='#d7c9ad',align='left'){ctx.font=`${size}px "Share Tech Mono",monospace`;ctx.textAlign=align;ctx.fillStyle='#000';ctx.fillText(t,x+2,y+2);ctx.fillStyle=color;ctx.fillText(t,x,y)}
function drawPuddles(cam){ctx.save();ctx.globalCompositeOperation='lighter';lamps.forEach(l=>{if(l.x+160<cam.x||l.x-160>cam.x+W||l.y+50<cam.y||l.y-50>cam.y+H)return;const sh=Math.sin(S.time*6+l.x)*.18+.82;ctx.globalAlpha=.22*sh;ctx.save();ctx.translate(l.x,l.y);ctx.scale(1.8,.5);ctx.drawImage(glowPool,-110,-110);ctx.restore()});ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';ctx.restore()}
function drawFog(cam){const _nf=clamp(.6-Math.sin(S.time*.02),0,1),_fa=.04+_nf*.07+storm*.03;ctx.save();fog.forEach(f=>{if(f.x+f.w<cam.x||f.x-f.w>cam.x+W||f.y+f.h<cam.y||f.y-f.h>cam.y+H)return;const g=ctx.createRadialGradient(f.x,f.y,0,f.x,f.y,f.w);g.addColorStop(0,`rgba(150,166,182,${_fa.toFixed(3)})`);g.addColorStop(1,'rgba(150,166,182,0)');ctx.fillStyle=g;ctx.beginPath();ctx.ellipse(f.x,f.y,f.w,f.h,0,0,Math.PI*2);ctx.fill()});ctx.restore()}
function drawWorld(cam){
  ctx.fillStyle='#141b1e';ctx.fillRect(0,0,W,H);ctx.save();ctx.translate(-cam.x,-cam.y);const p=S.player;
  // Ground — tiled texture
  const tile=imgs.tileset;
  if(tile&&tile.complete&&tile.naturalWidth){
    ctx.save();ctx.beginPath();ctx.rect(180,150,2040,1050);ctx.clip();
    const tw=tile.naturalWidth,th=tile.naturalHeight;
    for(let tx=180;tx<2220;tx+=tw)for(let ty=150;ty<1200;ty+=th)
      if(tx+tw>cam.x-200&&tx<cam.x+W+200&&ty+th>cam.y-200&&ty<cam.y+H+200)ctx.drawImage(tile,tx,ty);
    ctx.restore();
  }else{ctx.fillStyle='#252a29';ctx.fillRect(180,150,2040,1050);}
  // Roads
  roads.forEach(r=>{
    ctx.fillStyle='rgba(18,22,26,0.6)';ctx.fillRect(r.x,r.y,r.w,r.h);
    // edge lines (white)
    ctx.strokeStyle='#6a6558';ctx.lineWidth=1;
    ctx.beginPath();ctx.moveTo(r.x,r.y+.5);ctx.lineTo(r.x+r.w,r.y+.5);ctx.stroke();
    ctx.beginPath();ctx.moveTo(r.x,r.y+r.h-.5);ctx.lineTo(r.x+r.w,r.y+r.h-.5);ctx.stroke();
    // center dashes (yellow)
    ctx.strokeStyle='#8a7a40';ctx.setLineDash([28,22]);ctx.lineWidth=2;
    ctx.beginPath();ctx.moveTo(r.x,r.y+r.h/2);ctx.lineTo(r.x+r.w,r.y+r.h/2);ctx.stroke();ctx.setLineDash([]);
    // manhole covers
    if(r.w>200){[.3,.55,.8].forEach(f=>{ctx.fillStyle='#1e2226';ctx.beginPath();ctx.arc(r.x+r.w*f,r.y+r.h/2,6,0,Math.PI*2);ctx.fill();ctx.strokeStyle='#2a2e32';ctx.lineWidth=1;ctx.stroke();ctx.beginPath();ctx.moveTo(r.x+r.w*f-4,r.y+r.h/2);ctx.lineTo(r.x+r.w*f+4,r.y+r.h/2);ctx.stroke();});}
  });
  // Crosswalks at intersections
  [[830,500,80,220],[1390,500,90,220]].forEach(([cx,cy,cw,ch])=>{
    ctx.fillStyle='rgba(180,170,150,0.15)';
    for(let s=cy+8;s<cy+ch-8;s+=12)ctx.fillRect(cx-4,s,8,6);
    for(let s=cy+8;s<cy+ch-8;s+=12)ctx.fillRect(cx+cw-4,s,8,6);
  });
  drawPuddles(cam);
  // Street lamp light pools
  ctx.save();ctx.globalCompositeOperation='lighter';
  lamps.forEach(l=>{if(l.x+120>cam.x&&l.x-120<cam.x+W&&l.y+120>cam.y&&l.y-120<cam.y+H){const fl=(Math.sin(S.time*7+l.x)*.05+.95)*(storm?0.8:1);ctx.drawImage(glowPool,l.x-110,l.y-110);ctx.fillStyle='#5a4a3a';ctx.fillRect(l.x-1,l.y-16,2,18);ctx.fillRect(l.x-1,l.y+2,6,3);ctx.fillRect(l.x-3,l.y+5,8,2);ctx.fillRect(l.x-6,l.y-16,12,2);ctx.fillRect(l.x-8,l.y-19,2,4);ctx.fillRect(l.x+6,l.y-19,2,4);ctx.fillStyle='#e4a050';ctx.globalAlpha=fl;ctx.beginPath();ctx.arc(l.x-7,l.y-17,2.5,0,Math.PI*2);ctx.arc(l.x+7,l.y-17,2.5,0,Math.PI*2);ctx.fill();ctx.globalAlpha=1;ctx.fillStyle='#6a5a4a';ctx.fillRect(l.x-1.5,l.y+1,3,4)}});
  ctx.globalCompositeOperation='source-over';ctx.restore();
  drawFog(cam);
  // Player & companion light pools
  ctx.save();ctx.globalCompositeOperation='lighter';
  ctx.drawImage(glowPool,p.x-110,p.y-110);
  if(p.inCar===null){ctx.globalAlpha=.5;ctx.drawImage(glowCyan,p.x+16-64,p.y+15-64);ctx.globalAlpha=1}
  ctx.globalCompositeOperation='source-over';ctx.restore();
  // Build z-sort render queue
  const rq=[];
  rects.forEach((r,i)=>rq.push({t:'bldg',d:r,i,sy:r.y+r.h}));
  [['BURN',landmarks.burn,'#e4793e'],['LIRA',landmarks.lira,'#5be2d4'],['RELAY',landmarks.relay,'#d75672'],['KAEL',landmarks.kael,'#d7b85c'],['CORE',landmarks.core,'#a981da']].forEach(([n,lp,c])=>rq.push({t:'lm',d:{n,lp,c},sy:lp.y}));
  cars.forEach(c=>rq.push({t:'car',d:c,sy:c.y}));
  people.forEach(n=>{if(n.hp>0)rq.push({t:'person',d:n,sy:n.y});});
  police.forEach(n=>{if(n.hp>0)rq.push({t:'police',d:n,sy:n.y});});
  npcs.forEach(n=>rq.push({t:'npc',d:n,sy:n.y}));
  if(p.inCar===null)rq.push({t:'player',d:p,sy:p.y});
  rq.sort((a,b)=>a.sy-b.sy);
  for(const it of rq){
    switch(it.t){
      case 'bldg':drawBldg(it.d,it.i);break;
      case 'lm':{const{d:{n,lp,c}}=it;ctx.save();ctx.shadowColor=c;ctx.shadowBlur=14;ctx.strokeStyle=c;ctx.lineWidth=2;ctx.strokeRect(lp.x-22,lp.y-22,44,44);ctx.shadowBlur=0;text(n,lp.x,lp.y-30,10,c,'center');ctx.restore();}break;
      case 'car':drawGameCar(it.d);break;
      case 'person':drawGamePerson(it.d);break;
      case 'police':drawGamePolice(it.d);break;
      case 'npc':drawNpc(it.d);break;
      case 'player':drawGamePlayer(it.d);break;
    }
  }
  // ── NPC INTERACT PROMPT ──
  if(p.inCar===null&&!S.dialogue){
    const lm=[['burn',landmarks.burn],['lira',landmarks.lira],['relay',landmarks.relay],['kael',landmarks.kael],['core',landmarks.core]];
    for(const [k,lp] of lm){
      if(dist(p,lp)>80)continue;
      let talkable=false;
      if(S.mission===0&&S.step===0&&k==='burn')talkable=true;
      else if(S.mission===0&&S.step===2&&k==='burn'&&dist(cars[0],landmarks.burn)<120)talkable=true;
      else if(S.mission===1&&S.step===0&&k==='lira')talkable=true;
      else if(S.mission===2&&S.step===0&&k==='kael')talkable=true;
      else if(!S.flags['npc_'+k])talkable=true;
      if(talkable){const pulse=Math.sin(S.time*5)*.3+.7;ctx.save();ctx.globalAlpha=pulse;ctx.font='bold 16px "Share Tech Mono",monospace';ctx.textAlign='center';ctx.strokeStyle='#000';ctx.lineWidth=3;ctx.strokeText('E',lp.x,lp.y-36);ctx.fillStyle='#e4bd72';ctx.fillText('E',lp.x,lp.y-36);ctx.globalAlpha=1;ctx.restore();break}
    }
  }
  // Bullets + particles (on top)
  bullets.forEach(b=>{ctx.save();ctx.translate(b.x,b.y);ctx.rotate(Math.atan2(b.vy,b.vx));ctx.globalCompositeOperation='lighter';ctx.fillStyle=b.enemy?'rgba(240,91,88,.85)':'rgba(249,221,108,.9)';ctx.fillRect(-10,-1.5,22,3);ctx.fillRect(-15,-.5,30,1);ctx.fillStyle=b.enemy?'rgba(240,91,88,.18)':'rgba(249,221,108,.18)';ctx.beginPath();ctx.arc(11,0,5,0,Math.PI*2);ctx.fill();ctx.globalCompositeOperation='source-over';ctx.restore()});if(flashTime>0&&S.player.inCar===null){const p=S.player,fx=p.x+Math.cos(p.angle)*16,fy=p.y+Math.sin(p.angle)*16;ctx.save();ctx.globalCompositeOperation='lighter';ctx.fillStyle='rgba(255,240,200,0.55)';ctx.beginPath();ctx.arc(fx,fy,14,0,Math.PI*2);ctx.fill();ctx.globalCompositeOperation='source-over';ctx.restore()}
  particles.forEach(q=>{ctx.globalAlpha=q.life*(q.pa||4);ctx.fillStyle=q.color;ctx.fillRect(q.x,q.y,q.sz||3,q.sz||3);ctx.globalAlpha=1});embers.forEach(e=>{const a=e.life/e.ml;ctx.globalAlpha=a*.45;ctx.fillStyle='#e89040';ctx.fillRect(e.x-e.sz/2,e.y-e.sz/2,e.sz,e.sz)});ctx.globalAlpha=1;ripples.forEach(q=>{const a=1-q.life/q.g;ctx.globalAlpha=a*.22;ctx.strokeStyle='#9ec4e0';ctx.lineWidth=1;ctx.beginPath();ctx.ellipse(q.x,q.y,q.r,q.r*.4,0,0,Math.PI*2);ctx.stroke()});ctx.globalAlpha=1;
  // FB-13 companion
  if(p.inCar===null){
    const fx=p.x-24-Math.cos(S.time*2)*5,fy=p.y+20+Math.sin(S.time*5)*3;
    const fb13Frame=Math.floor(S.time*8)%4;
    if(!drawSpr('fb13',0,fb13Frame,fx,fy)){ctx.strokeStyle='#d78343';ctx.lineWidth=3;ctx.beginPath();ctx.arc(fx,fy,8,0,Math.PI*2);ctx.stroke();for(let i=0;i<3;i++){const a=S.time*2+i*2.1;ctx.fillStyle='#c7a36a';ctx.fillRect(fx+Math.cos(a)*5-2,fy+Math.sin(a)*5-2,4,4)}}
    // HS-7 companion (procedural)
    ctx.fillStyle=S.memories?'#56e6d4':'#46605f';
    ctx.beginPath();ctx.arc(p.x+16,p.y+15,6,0,Math.PI*2);ctx.fill();
    ctx.fillStyle=S.memories?'#7af5ea':'#3a5050';
    ctx.beginPath();ctx.arc(p.x+16,p.y+15,3,0,Math.PI*2);ctx.fill();
  }
  // Mission target
  let target=null;
  if(S.mission===0)target=[landmarks.burn,cars[0],landmarks.burn][S.step];
  if(S.mission===1)target=[landmarks.lira,landmarks.relay,null][S.step];
  if(S.mission===2)target=[landmarks.kael,landmarks.core,landmarks.exit][S.step];
  if(target){ctx.strokeStyle='#f5ca65';ctx.lineWidth=2;ctx.beginPath();ctx.arc(target.x,target.y,22+Math.sin(S.time*5)*4,0,Math.PI*2);ctx.stroke();
    ctx.strokeStyle='rgba(245,202,101,0.3)';ctx.lineWidth=4;ctx.beginPath();ctx.arc(target.x,target.y,26+Math.sin(S.time*5)*4,0,Math.PI*2);ctx.stroke();}
  ctx.restore();
}
function drawHud(){
  box(16,15,330,76,'#8b674d');text('JMAC',30,37,14,'#e17042');ctx.fillStyle='#352326';ctx.fillRect(30,48,180,10);ctx.fillStyle=S.player.hp>30?'#d85843':'#ff3131';ctx.fillRect(30,48,180*S.player.hp/100,10);text(`HP ${S.player.hp}  //  AMMO ${S.player.ammo}`,30,78,13);ctx.save();ctx.translate(S.wanted?rnd(-1.5,1.5):0,0);box(W-255,15,239,76,S.wanted?'#ff4b4b':'#527e7a');text('ECHOTEL MUNICIPAL ALERT',W-135,36,11,'#68ddd2','center');text('◆'.repeat(S.wanted)+'◇'.repeat(4-S.wanted),W-135,65,26,S.wanted?'#ff3131':'#536269','center');ctx.restore();
  box(16,H-70,W-32,53,'#72513d');text(S.mission<3?missions[S.mission].title:'ECHOES RECOVERED',31,H-47,13,'#e27843');text(objective(),31,H-28,15,'#e6d8bc');text(`FB-13 [Q]  HS-7 [R] ${'◆'.repeat(S.memories)}  INTERACT [E]`,W-30,H-29,12,'#6fd8d2','right');
  if(S.message&&S.msgTime>0){box(W/2-250,110,500,42,'#d0703f');text(S.message,W/2,137,15,'#f1cc82','center')}
  if(S.dialogue){const line=S.dialogue[S.di];box(90,H-190,W-180,95,'#9d653f');text(line[0],112,H-160,15,'#5ce0d6');text(line[1],112,H-132,15,'#e8d7b9');text('E / CLICK TO CONTINUE',W-112,H-111,10,'#8b958f','right')}
  if(paused){ctx.fillStyle='#05080bdc';ctx.fillRect(0,0,W,H);text('ARCHIVE PAUSED',W/2,H/2-20,38,'#e17243','center');text('ESC resume  //  F5 save  //  N new game',W/2,H/2+25,16,'#62d8d2','center')}
}
function drawRain(){const _nf=clamp(.6-Math.sin(S.time*.02),0,1),_ri=.5+_nf*.5+storm*1.5;ctx.save();ctx.lineWidth=1;rain.forEach(d=>{ctx.globalAlpha=d.a*_ri;ctx.strokeStyle='rgba(140,170,210,0.5)';ctx.beginPath();ctx.moveTo(d.x,d.y);ctx.lineTo(d.x-1,d.y+d.len*(.8+storm*.5));ctx.stroke()});ctx.globalAlpha=1;ctx.restore()}
function dayTint(){const ph=Math.sin(S.time*.02),t=clamp(.6-ph,0,1),w=1-t;ctx.fillStyle=`rgba(${Math.round(8+40*w)},${Math.round(14+18*w)},${Math.round(34-10*w)},${(.05+t*.34).toFixed(3)})`;ctx.fillRect(0,0,W,H)}
function drawVignette(){const g=ctx.createRadialGradient(W/2,H/2,W*.28,W/2,H/2,W*.72);g.addColorStop(0,'rgba(0,0,0,0)');g.addColorStop(1,'rgba(5,8,12,0.55)');ctx.fillStyle=g;ctx.fillRect(0,0,W,H)}
function draw(){const cam=camera(),sx=rnd(-shake,shake),sy=rnd(-shake,shake);ctx.save();ctx.translate(sx,sy);drawWorld(cam);ctx.restore();drawRain();dayTint();if(storm>0){ctx.fillStyle=`rgba(205,220,250,${(storm*.13).toFixed(3)})`;ctx.fillRect(0,0,W,H);if(storm2>0){ctx.fillStyle=`rgba(225,235,255,${(storm2*.55).toFixed(3)})`;ctx.fillRect(0,0,W,H)}}drawHud();drawVignette()}
function loop(t){
  if(!running)return;
  const dt=Math.min(.033,(t-last)/1000||0);
  last=t;
  try {
    update(dt);
    draw();
  } catch (err) {
    console.error("GAME LOOP ERROR:", err);
  }
  requestAnimationFrame(loop);
}
window.addEventListener('keydown',e=>{audio();keys[e.code]=true;if(e.code==='KeyE')interact();if(e.code==='Escape')paused=!paused;if(e.code==='F5'){e.preventDefault();save()}if(e.code==='KeyN'&&paused){localStorage.removeItem(SAVE);S=fresh();resetWorld();paused=false;talk('intro')}});window.addEventListener('keyup',e=>keys[e.code]=false);
canvas.addEventListener('mousemove',e=>{const r=canvas.getBoundingClientRect();mouse.x=(e.clientX-r.left)*W/r.width;mouse.y=(e.clientY-r.top)*H/r.height});
canvas.addEventListener('mousedown',()=>{audio();mouse.held=true;if(S&&S.dialogue)interact();else mouse.down=true});
canvas.addEventListener('mouseup',()=>{mouse.held=false;});canvas.addEventListener('mouseleave',()=>{mouse.held=false;});
document.querySelector('#newGame').onclick=()=>{audio();localStorage.removeItem(SAVE);start(false)};document.querySelector('#continueGame').onclick=()=>{audio();start(true)};
// ── PRE-START AMBIENT DRIFT ─────────────────────────────────────────────────────
let boot=true,bootRAF=null;
S=fresh();resetWorld();
function bootUpdate(t){
  if(!boot)return;const dt=Math.min(.033,(t-last)/1000||0);last=t;
  try{
    S.time+=dt;
    wind+=(Math.sin(S.time*.4)*.45+clamp(.6-Math.sin(S.time*.02),0,1)*.15-wind)*dt*2;
    if(Math.random()<dt*(.02+clamp(.6-Math.sin(S.time*.02),0,1)*.04)){storm=1;storm2=.3;if(actx)sfx('thunder')}
    const cam={x:(S.time*18)%(WORLD.w-W),y:270+Math.sin(S.time*.05)*46};
    updateAtmosphere(dt,cam);
    drawWorld(cam);drawRain();dayTint();drawVignette();
  }catch(e){}
  bootRAF=requestAnimationFrame(bootUpdate);
}
bootRAF=requestAnimationFrame(bootUpdate);
window.GAME_STATE = S;window.CARS = cars;window.interact = interact;window.startGame=start;
})();
