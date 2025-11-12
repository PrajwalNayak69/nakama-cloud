#!/bin/sh
set -e

echo "🚀 Running database migrations..."
/nakama/nakama migrate up --database.address "${DATABASE_URL}"

echo "✅ Starting Nakama..."
exec /nakama/nakama \
  --name nakama1 \
  --database.address "${DATABASE_URL}" \
  --logger.level INFO \
  --session.token_expiry_sec 7200 \
  --runtime.path /data/modules \
  --config /nakama/data/local.yml
