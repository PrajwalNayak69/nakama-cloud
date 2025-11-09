FROM heroiclabs/nakama:3.30.0

# Optional local Nakama config
COPY local.yml /nakama/data/local.yml

# Add a proper startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Override Nakama's entrypoint so our script runs instead
ENTRYPOINT ["/bin/sh", "/start.sh"]
