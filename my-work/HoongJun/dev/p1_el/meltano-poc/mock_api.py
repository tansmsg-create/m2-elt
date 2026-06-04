"""Tiny mock of jsonplaceholder so the POC runs fully offline / behind TLS
interception. Serves /users and /users/{id}/posts with the same shape.
Run: python3 mock_api.py  (listens on 127.0.0.1:8089)
"""
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

USERS = [
    {"id": i, "name": f"User {i}", "username": f"user{i}",
     "email": f"user{i}@example.com", "phone": "555-0100", "website": "example.com",
     "address": {"street": "Main", "suite": f"Apt {i}", "city": "Singapore", "zipcode": "01"},
     "company": {"name": f"Co {i}", "catchPhrase": "Sovereign AI"}}
    for i in range(1, 4)
]
POSTS = {
    uid: [{"id": uid * 10 + p, "userId": uid, "title": f"Post {p} by user {uid}",
           "body": "lorem ipsum"} for p in range(1, 3)]
    for uid in range(1, 4)
}


class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass  # quiet

    def do_GET(self):
        parts = [p for p in self.path.split("/") if p]
        if self.path == "/users":
            body = USERS
        elif len(parts) == 3 and parts[0] == "users" and parts[2] == "posts":
            body = POSTS.get(int(parts[1]), [])
        else:
            self.send_response(404); self.end_headers(); return
        payload = json.dumps(body).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8089), H).serve_forever()
