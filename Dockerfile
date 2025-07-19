# 1. Base image to install dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# Copy only the lock and package files to install deps
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# 2. Builder stage
FROM node:20-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Copy Prisma schema before generating

RUN pnpm prisma generate

# Build the app
RUN pnpm build

# 3. Final image
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Copy everything needed to run the app
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/.env.local ./.env.local

EXPOSE 3000
CMD ["pnpm", "start"]
