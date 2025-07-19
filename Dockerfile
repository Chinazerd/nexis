# ----------- 1. Builder Stage -------------
FROM node:20.13.1-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package and lock files
COPY package.json pnpm-lock.yaml ./

# ✅ Copy prisma folder early before install to avoid prisma generate error
COPY prisma ./prisma

# Now install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Build the app
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

EXPOSE 3000

CMD ["pnpm", "start"]
