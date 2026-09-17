const fs = require('fs');

async function extractLatestImage(outputPath) {
  const res = await fetch('http://localhost:9222/json/list');
  const tabs = await res.json();
  const chatTab = tabs.find(t => t.url && t.url.includes('chatgpt.com'));
  if (!chatTab) {
    throw new Error('ChatGPT tab not found in http://localhost:9222/json/list');
  }

  const wsUrl = chatTab.webSocketDebuggerUrl;
  console.log('[EXTRACTOR] Connecting to WebSocket:', wsUrl);

  const ws = new WebSocket(wsUrl);
  await new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = reject;
  });

  const evalExpression = `(() => {
    const imgs = Array.from(document.querySelectorAll('img')).filter(i => !i.src.startsWith('data:image/svg'));
    if (imgs.length === 0) return null;
    const lastImg = imgs[imgs.length - 1];
    return {
      src: lastImg.src,
      w: lastImg.naturalWidth,
      h: lastImg.naturalHeight,
      alt: lastImg.alt
    };
  })()`;

  const msgId = 1;
  const req = {
    id: msgId,
    method: 'Runtime.evaluate',
    params: {
      expression: evalExpression,
      awaitPromise: true,
      returnByValue: true,
      max_depth: 2
    }
  };

  const resultPromise = new Promise((resolve, reject) => {
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.id === msgId) {
        if (data.result && data.result.result && data.result.result.value) {
          resolve(data.result.result.value);
        } else if (data.error) {
          reject(new Error(JSON.stringify(data.error)));
        } else if (data.result && data.result.exceptionDetails) {
          reject(new Error(JSON.stringify(data.result.exceptionDetails)));
        } else {
          reject(new Error('Unknown response: ' + event.data.slice(0, 200)));
        }
      }
    };
  });

  ws.send(JSON.stringify(req));
  const imgInfo = await resultPromise;
  ws.close();

  if (!imgInfo || !imgInfo.src) {
    throw new Error('No image found in conversation');
  }

  console.log(`[EXTRACTOR] Found image: ${imgInfo.w}x${imgInfo.h}, alt="${imgInfo.alt}"`);

  let buffer;
  if (imgInfo.src.startsWith('data:')) {
    const b64Data = imgInfo.src.split(',')[1];
    buffer = Buffer.from(b64Data, 'base64');
  } else {
    const fetchRes = await fetch(imgInfo.src);
    const arrayBuffer = await fetchRes.arrayBuffer();
    buffer = Buffer.from(arrayBuffer);
  }

  fs.writeFileSync(outputPath, buffer);
  console.log(`[EXTRACTOR] Successfully saved ${buffer.length} bytes to ${outputPath}`);
}

const out = process.argv[2] || 'docs/visual_direction/references/chatgpt_gen_vending_machine.png';
extractLatestImage(out).catch(err => {
  console.error('[EXTRACTOR] Error:', err);
  process.exit(1);
});
