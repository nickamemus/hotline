import os
import httpx
from fastapi import FastAPI, Request

MATRIX_HS = os.environ["MATRIX_HOMESERVER"]
ROOM_ID = os.environ["MATRIX_ROOM_ID"]
MATRIX_TOKEN = os.environ["MATRIX_ACCESS_TOKEN"]

JASMIN_API = os.environ["JASMIN_API"]

app = FastAPI()
client = httpx.AsyncClient()

# ---- Helpers ----

async def send_matrix(message: str):
    url = f"{MATRIX_HS}/_matrix/client/v3/rooms/{ROOM_ID}/send/m.room.message"
    headers = {"Authorization": f"Bearer {MATRIX_TOKEN}"}
    payload = {
        "msgtype": "m.text",
        "body": message
    }
    await client.post(url, headers=headers, json=payload)

async def send_sms(number: str, text: str):
    payload = {
        "to": number,
        "content": text
    }
    await client.post(f"{JASMIN_API}/send", json=payload)

# ---- Inbound SMS webhook ----

@app.post("/sms/inbound")
async def inbound_sms(req: Request):
    data = await req.json()

    sender = data.get("from")
    content = data.get("content")

    if not sender or not content:
        return {"status": "ignored"}

    await send_matrix(
        f"📩 SMS from {sender}:\n{content}"
    )

    return {"status": "ok"}

# ---- Matrix → SMS (manual trigger MVP) ----
# Volunteers reply like:
# @+15551234567 Your message here

@app.post("/matrix/reply")
async def matrix_reply(req: Request):
    data = await req.json()
    body = data.get("body", "")

    if body.startswith("@+"):
        try:
            number, text = body.split(" ", 1)
            await send_sms(number[1:], text)
        except ValueError:
            pass

    return {"status": "ok"}
