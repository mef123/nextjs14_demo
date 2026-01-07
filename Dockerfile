# syntax=docker/dockerfile:1.6

############################
# 1) deps
############################
FROM node:20-alpine AS deps
WORKDIR /app

# Needed for some native deps on alpine; harmless if unused
RUN apk add --no-cache libc6-compat

# Copy lockfiles first for better caching
COPY package.json ./
COPY package-lock.json ./
# If you use yarn/pnpm, replace the npm ci line and copy the right lockfile.

RUN npm ci

############################
# 2) builder
############################
FROM node:20-alpine AS builder
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build Next.js (or any Node build script)
RUN npm run build

############################
# 3) runner
############################
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Your Ansible env includes:
# PORT=3000 (container_port) and HOSTNAME=0.0.0.0
# We'll set safe defaults here too.
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Create non-root user
RUN addgroup -S nodejs && adduser -S node -G nodejs

# --- Option A (recommended): Next.js standalone output ---
# Requires next.config.js:  module.exports = { output: 'standalone' }
#
# This will work if standalone exists; if not, comment these lines
# and use Option B below.
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# --- Option B (fallback): non-standalone ---
# Uncomment this block if you do NOT use standalone output:
# COPY --from=builder /app/package.json ./package.json
# COPY --from=builder /app/node_modules ./node_modules
# COPY --from=builder /app/.next ./.next
# COPY --from=builder /app/public ./public
# COPY --from=builder /app/next.config.* ./  # if present

USER node

EXPOSE 3000

# Standalone entrypoint:
#CMD ["node", "server.js"]

# If using fallback Option B (next start), use:
CMD ["npm", "run", "start"]
