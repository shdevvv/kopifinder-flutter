# Dockerfile — KopiFinder Backend
# Multi-stage build: build TypeScript → run compiled JS

# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies (including devDependencies for tsc)
COPY package*.json ./
RUN npm ci

# Copy source & compile
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM node:20-alpine AS runtime

WORKDIR /app

# Production-only deps
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled output from builder
COPY --from=builder /app/dist ./dist

# Non-root user for security
RUN addgroup -S kopi && adduser -S kopi -G kopi
USER kopi

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/v1/health || exit 1

CMD ["node", "dist/server.js"]
