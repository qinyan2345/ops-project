#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import threading

def run_deploy():
    subprocess.run(
        ['/home/qinyan/ops-project/scripts/deploy.sh'],
        capture_output=True, text=True
    )

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        self.rfile.read(content_length)   # 读取请求体

        if self.path == '/deploy':
            threading.Thread(target=run_deploy).start()
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'deploy triggered\n')
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'webhook receiver is running\n')

HTTPServer(('0.0.0.0', 5001), Handler).serve_forever()
