#!/usr/bin/env python3
"""Local CORS proxy for MySteamBuddy's web build.

Steam's and ITAD's public APIs (and ITAD's image CDN) don't send
Access-Control-Allow-Origin, so a browser build can't call them directly.
This forwards:

  http://127.0.0.1:8787/steam/<path>  -> https://api.steampowered.com/<path>
  http://127.0.0.1:8787/itad/<path>   -> https://api.isthereanydeal.com/<path>
  http://127.0.0.1:8787/img/<path>    -> https://assets.isthereanydeal.com/<path>

adding permissive CORS headers to the response. Zero third-party
dependencies (stdlib only). Run this alongside `flutter run -d chrome` or a
served `flutter build web` output — the app auto-detects it's running on web
and points its API clients here instead of the real hosts.

Usage:
    python3 tool/web_proxy.py
"""
import http.server
import socketserver
import urllib.error
import urllib.request

PORT = 8787
UPSTREAMS = {
    "/steam/": "https://api.steampowered.com/",
    "/itad/": "https://api.isthereanydeal.com/",
    "/img/": "https://assets.isthereanydeal.com/",
}


class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        self._forward("GET")

    def do_POST(self):
        self._forward("POST")

    def _resolve(self):
        for prefix, upstream_base in UPSTREAMS.items():
            if self.path.startswith(prefix):
                return upstream_base + self.path[len(prefix):]
        return None

    def _forward(self, method):
        target = self._resolve()
        if target is None:
            self.send_response(404)
            self._cors()
            self.end_headers()
            self.wfile.write(b"Unknown proxy route")
            return

        body = None
        headers = {}
        if method == "POST":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length) if length else b""
            headers["Content-Type"] = self.headers.get("Content-Type", "application/json")

        req = urllib.request.Request(target, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=25) as resp:
                self.send_response(resp.status)
                self._cors()
                self.send_header("Content-Type", resp.headers.get("Content-Type", "application/json"))
                self.end_headers()
                self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self._cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:  # network hiccups, timeouts, etc.
            self.send_response(502)
            self._cors()
            self.end_headers()
            self.wfile.write(str(e).encode())

    def log_message(self, fmt, *args):
        pass  # keep the console quiet


if __name__ == "__main__":
    with socketserver.ThreadingTCPServer(("127.0.0.1", PORT), ProxyHandler) as httpd:
        print(f"MySteamBuddy web proxy listening on http://127.0.0.1:{PORT}")
        print("  /steam/* -> api.steampowered.com")
        print("  /itad/*  -> api.isthereanydeal.com")
        print("Leave this running while you use the web build. Ctrl+C to stop.")
        httpd.serve_forever()
