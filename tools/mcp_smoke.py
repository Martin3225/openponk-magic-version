#!/usr/bin/env python3
"""Kourovy test MCP serveru bezicího OpenPonku (jen standardni knihovna)."""
import base64, json, sys, urllib.request

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:47100/mcp"
OUT = sys.argv[2] if len(sys.argv) > 2 else None
_id = 0

def post(payload):
    req = urllib.request.Request(URL, data=json.dumps(payload).encode(), method="POST",
        headers={"Content-Type": "application/json", "Accept": "application/json, text/event-stream"})
    with urllib.request.urlopen(req, timeout=60) as r:
        body = r.read().decode()
        return r.status, (json.loads(body) if body else None)

def rpc(method, params=None):
    global _id
    _id += 1
    status, msg = post({"jsonrpc": "2.0", "id": _id, "method": method, "params": params or {}})
    if "error" in msg:
        raise SystemExit(f"{method}: {msg['error']}")
    return msg["result"]

def tool(tool_name, **args):
    res = rpc("tools/call", {"name": tool_name, "arguments": args})
    text = next((c["text"] for c in res["content"] if c["type"] == "text"), None)
    if res.get("isError"):
        raise SystemExit(f"{tool_name} -> ERROR {text}")
    if tool_name == "export_diagram_png":
        return res
    return json.loads(text)

init = rpc("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "smoke", "version": "1"}})
print("initialize:", init["protocolVersion"], init["serverInfo"])
print("notification status:", post({"jsonrpc": "2.0", "method": "notifications/initialized"})[0])
print("tools:", len(rpc("tools/list")["tools"]))
project = tool("create_project", name="MCP demo – univerzita", notation="ER Diagram")
pid = project["id"]
print("project:", project["name"], project["diagrams"][0]["notation"])
types = [t["type"] for t in tool("list_element_types", project=pid)["types"]]
print("types:", types)
student = tool("create_element", project=pid, type="Regular Entity", name="Student", x=80, y=200)
predmet = tool("create_element", project=pid, type="Regular Entity", name="Předmět", x=520, y=200)
zapis = tool("create_element", project=pid, type="Regular Relation", name="zapsán", x=320, y=205)
ids = {}
for name, x in (("číslo", 20), ("jméno", 150)):
    a = tool("create_element", project=pid, type="Key Attribute" if name == "číslo" else "Regular Attribute", name=name, x=x, y=60)
    tool("connect_elements", project=pid, type="Regular Connection", source=a["id"], target=student["id"])
kod = tool("create_element", project=pid, type="Key Attribute", name="kód", x=560, y=60)
tool("connect_elements", project=pid, type="Regular Connection", source=kod["id"], target=predmet["id"])
tool("connect_elements", project=pid, type="Regular Connection", source=zapis["id"], target=student["id"])
tool("connect_elements", project=pid, type="Total Connection", source=zapis["id"], target=predmet["id"])
d = tool("get_diagram", project=pid)
print("elements:", len(d["elements"]), "nodes:", sum(e["kind"] == "node" for e in d["elements"]))
print("names:", sorted(e["name"] for e in d["elements"] if e["kind"] == "node"))
copies = tool("duplicate_elements", project=pid, elements=[student["id"]])["copies"]
print("duplicate:", [(c["name"], c["x"], c["y"]) for c in copies])
tool("undo", project=pid)
print("after undo:", len(tool("get_diagram", project=pid)["elements"]))
png = tool("export_diagram_png", project=pid)
img = next(c for c in png["content"] if c["type"] == "image")
if OUT:
    with open(OUT, "wb") as f:
        f.write(base64.b64decode(img["data"]))
    print("png saved:", OUT)
