#!/bin/bash
set -e

# === CONFIGURE THESE ===
ADMIN_USER="matrixadmin"
ADMIN_PASS="your_admin_password"
BOT_USER="hotline_bot"
BOT_PASS="your_bot_password"
ROOM_ALIAS="hotline:hotline.local"
SYNAPSE_URL="http://localhost:8008"

echo "Logging in admin..."
ADMIN_LOGIN_JSON=$(curl -s -XPOST "$SYNAPSE_URL/_matrix/client/v3/login" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"m.login.password\",\"user\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}")

ADMIN_TOKEN=$(echo "$ADMIN_LOGIN_JSON" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "ERROR: Admin login failed. Check username/password."
  exit 1
fi
echo "Admin token: $ADMIN_TOKEN"

# === Resolve room alias to room ID ===
ENCODED_ALIAS=$(python3 -c "import urllib.parse; print(urllib.parse.quote('#$ROOM_ALIAS', safe=''))")
ROOM_JSON=$(curl -s "$SYNAPSE_URL/_matrix/client/v3/directory/room/$ENCODED_ALIAS?access_token=$ADMIN_TOKEN")
ROOM_ID=$(echo "$ROOM_JSON" | jq -r '.room_id')

if [ "$ROOM_ID" = "null" ] || [ -z "$ROOM_ID" ]; then
  echo "Room not found. Creating room..."
  CREATE_JSON=$(curl -s -XPOST "$SYNAPSE_URL/_matrix/client/v3/createRoom?access_token=$ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"room_alias_name\":\"${ROOM_ALIAS%%:*}\", \"name\":\"Hotline Room\"}")
  ROOM_ID=$(echo "$CREATE_JSON" | jq -r '.room_id')
fi
echo "Room ID: $ROOM_ID"

# === Login bot user ===
echo "Logging in bot..."
BOT_LOGIN_JSON=$(curl -s -XPOST "$SYNAPSE_URL/_matrix/client/v3/login" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"m.login.password\",\"user\":\"$BOT_USER\",\"password\":\"$BOT_PASS\"}")
BOT_TOKEN=$(echo "$BOT_LOGIN_JSON" | jq -r '.access_token')

if [ "$BOT_TOKEN" = "null" ] || [ -z "$BOT_TOKEN" ]; then
  echo "Bot login failed. Make sure bot user exists and password is correct."
  exit 1
fi
echo "Bot token: $BOT_TOKEN"

# === Invite bot to room ===
BOT_USER_FULL="@${BOT_USER}:hotline.local"
echo "Inviting bot to room..."
INVITE_JSON=$(curl -s -XPOST "$SYNAPSE_URL/_matrix/client/v3/rooms/$ROOM_ID/invite?access_token=$ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$BOT_USER_FULL\"}")

echo "Bot invited. Response:"
echo "$INVITE_JSON"

# === Verify bot joined ===
JOINED_ROOMS=$(curl -s "$SYNAPSE_URL/_matrix/client/v3/joined_rooms?access_token=$BOT_TOKEN" | jq -r '.joined_rooms[]?')
echo "Bot joined rooms:"
echo "$JOINED_ROOMS"

echo "=== SETUP COMPLETE ==="
