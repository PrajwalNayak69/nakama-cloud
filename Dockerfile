
FROM heroiclabs/nakama:3.30.0

# Copy config and startup script
COPY local.yml /nakama/data/local.yml
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Create the runtime modules directory and copy the Lua module
RUN mkdir -p /data/modules
COPY ./modules/tic_tac_toe.lua /data/modules/tic_tac_toe.lua
COPY ./modules/init.lua /data/modules/init.lua


ENTRYPOINT ["/bin/sh", "/start.sh"]