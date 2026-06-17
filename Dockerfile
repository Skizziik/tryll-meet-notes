# Раннер tryll-meet-notes как контейнер: стартует вместе с Docker (restart unless-stopped),
# следит за календарём, шлёт ботов в Vexa, делает заметки через claude CLI (по токену подписки).
FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI — для генерации заметок по подписке (NOTES_MODE=cli)
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
COPY assets ./assets

CMD ["npx", "tsx", "scripts/local.ts"]
