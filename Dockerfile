# Multi-stage build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev for build)
RUN npm ci

# Copy source code
COPY . .

# Build the Vite application
RUN npm run build

# Production stage
FROM node:20-alpine AS production

WORKDIR /app

# Install only production dependencies for vite preview
COPY package*.json ./
RUN npm ci --only=production

# Copy built assets from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/vite ./node_modules/vite

# Install vite globally or use local
RUN npm install -g vite

# Expose port (Vite preview default is 4173)
EXPOSE 4173

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4173/ || exit 1

# Start Vite preview server
CMD ["vite", "preview", "--host", "0.0.0.0", "--port", "4173"]