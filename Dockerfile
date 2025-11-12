FROM heroiclabs/nakama:3.30.0

COPY local.yml /nakama/data/local.yml
RUN mkdir -p /data/modules
COPY ./modules/tic_tac_toe.lua /data/modules/tic_tac_toe.lua
COPY ./modules/init.lua /data/modules/init.lua

EXPOSE 7350

ENTRYPOINT ["/bin/sh", "-c", "\
  echo '🚀 Running database migrations...' && \
  /nakama/nakama migrate up --database.address \"$DATABASE_URL\" && \
  echo '✅ Starting Nakama server...' && \
  exec /nakama/nakama \
    --name nakama1 \
    --database.address \"$DATABASE_URL\" \
    --logger.level INFO \
    --session.token_expiry_sec 7200 \
    --runtime.path /data/modules \
    --config /nakama/data/local.yml \
"]