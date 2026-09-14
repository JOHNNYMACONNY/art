import http.server
import os
import sys

PORT = 9876
SAVE_DIR = "docs/visual_direction/references/crops"
os.makedirs(SAVE_DIR, exist_ok=True)

class UploadHandler(http.server.BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def do_POST(self):
        filename = self.path.lstrip("/").split("?")[0]
        length = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(length)
        out_path = os.path.join(SAVE_DIR, filename)
        with open(out_path, "wb") as f:
            f.write(data)
        print(f"Received and saved {filename} ({len(data)} bytes)", flush=True)
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(b"OK")

print(f"Starting server on port {PORT}...", flush=True)
server = http.server.HTTPServer(("127.0.0.1", PORT), UploadHandler)
server.serve_forever()
