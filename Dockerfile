# ----------- 1. Builder Stage -------------
FROM node:20.13.1-alpine AS builder

# Set working directory
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# Copy dependency files and install
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy prisma early so prisma generate won't fail
COPY prisma ./prisma

# Generate Prisma Client
RUN pnpm exec prisma generate

# Copy rest of the app
COPY . .

# Build the Next.js app
RUN pnpm run build


# ----------- 2. Runner Stage -------------
FROM node:20.13.1-alpine AS runner

WORKDIR /app

# Set environment variable for production deployment
ENV NODE_ENV=deployment

# Copy everything needed to run the app
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/.env.local ./.env.local

# Expose port
EXPOSE 3000

# Start the app
CMD ["pnpm", "start"]
