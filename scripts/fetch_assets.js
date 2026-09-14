
async () => {
  const targets = [["burnside_sign", "https://chatgpt.com/backend-api/estuary/content?id=file_0000000001dc8230a0db320fbc660967&ts=496924&p=fs&cid=1&sig=4c72ef275bf96004b824f131cf40018f3ee95d1d0848d92b8c01678416a7b47f&v=0"], ["civic_kiosk", "https://chatgpt.com/backend-api/estuary/content?id=file_000000000a08823098cdbc0ec375456f&ts=496924&p=fs&cid=1&sig=b774ed7c2c4e98b6432119ae4ce4b35259bd3a15fe2a26980463bf0ab11869f0&v=0"], ["shutter_door", "https://chatgpt.com/backend-api/estuary/content?id=file_00000000fda88230bd10c63442c0b22d&ts=496924&p=fs&cid=1&sig=85259d55c44b8a26aaecc6c42d7c00bf4d5eea5cee5727a0eda40d2e64052301&v=0"], ["garage_door", "https://chatgpt.com/backend-api/estuary/content?id=file_000000004a1c8230b70cf286b592bc48&ts=496924&p=fs&cid=1&sig=d3b6e3d23d29af1dc398d1e2fd2af31e672ebd8ac5daf1db924b31bea1741f11&v=0"], ["service_door", "https://chatgpt.com/backend-api/estuary/content?id=file_000000004afc8230b9b8f81f9e38c60c&ts=496924&p=fs&cid=1&sig=f3181eec1345604ee126b5dca75d530d012201b652e0e2b166f4275e1eed96b1&v=0"], ["propaganda_wall", "https://chatgpt.com/backend-api/estuary/content?id=file_0000000046ec823099b039e54358b8b4&ts=496924&p=fs&cid=1&sig=9989216e3fe1d9cb43610a46720184f3bc4bd7935e1546c8b3f764e5522ebbb7&v=0"], ["restricted_sign", "https://chatgpt.com/backend-api/estuary/content?id=file_000000008af482309be231f1850418a7&ts=496924&p=fs&cid=1&sig=845ab06bf1f9f3e46dc3d43fc54cca2fe4c89cc612b60f30383809f81b11fa15&v=0"], ["electrical_panel", "https://chatgpt.com/backend-api/estuary/content?id=file_00000000a6e48230b4202279b9000a5a&ts=496924&p=fs&cid=1&sig=b244795b281f62137ea6c278a9c33658dc76395b0c797b5e43bc0ba4974cfc14&v=0"], ["salvage_board", "https://chatgpt.com/backend-api/estuary/content?id=file_00000000aee48230b54fdd52&ts=496924&p=fs&cid=1&sig=bc760e5faeb49e29a98efdcf83b7ff46eaebfa746f3325c4ef69d45eeb65f12e&v=0"]];
  const results = {};
  for (const [name, url] of targets) {
    try {
      const resp = await fetch(url);
      const blob = await resp.blob();
      const b64 = await new Promise(r => {
        const reader = new FileReader();
        reader.onloadend = () => r(reader.result);
        reader.readAsDataURL(blob);
      });
      results[name] = b64;
    } catch (e) {
      results[name] = "ERROR: " + e.message;
    }
  }
  return results;
}
