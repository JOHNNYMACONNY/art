const fs = require('fs');

async function downloadImage(imageUrl, outputPath) {
  // 1. Get ChatGPT tab webSocket url
  const res = await fetch('http://localhost:9222/json/list');
  const tabs = await res.json();
  const chatTab = tabs.find(t => t.url && t.url.includes('chatgpt.com/g/g-p-699d1f9e9c188191a392e1cc0783af99'));
  if (!chatTab) {
    throw new Error('ChatGPT tab not found in http://localhost:9222/json/list');
  }

  const wsUrl = chatTab.webSocketDebuggerUrl;
  console.log('Connecting to WebSocket:', wsUrl);

  const ws = new WebSocket(wsUrl);
  await new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = reject;
  });

  const evalExpression = `(async () => {
    const resp = await fetch("${imageUrl}");
    const blob = await resp.blob();
    const reader = new FileReader();
    return new Promise(resolve => {
      reader.onloadend = () => resolve(reader.result);
      reader.readAsDataURL(blob);
    });
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
  const dataUrl = await resultPromise;
  ws.close();

  const b64Data = dataUrl.split(',')[1];
  const buffer = Buffer.from(b64Data, 'base64');
  fs.writeFileSync(outputPath, buffer);
  console.log(`Saved ${buffer.length} bytes to ${outputPath}`);
}

const args = process.argv.slice(2);
if (args.length < 2) {
  console.log('Usage: node download_cdp_image.js <imageUrl> <outputPath>');
  process.exit(1);
}

downloadImage(args[0], args[1]).catch(err => {
  console.error('Error downloading image:', err);
  process.exit(1);
});
