#!/bin/bash
set -euo pipefail

# ============================================================
# Social App - Server Initial Deployment Script
# Run this ONCE on the server for initial setup
# ============================================================

DEPLOY_DIR="/opt/social-app"

echo "=== Social App Initial Deployment ==="
echo "Deploy directory: $DEPLOY_DIR"

# 1. Install Docker (if not installed)
echo "[1/7] Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt update && apt install -y docker.io
    systemctl enable docker && systemctl start docker
fi

# 2. Install Docker Compose plugin (if not installed)
echo "[2/7] Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    apt install -y docker-compose-plugin
fi

# 3. Install Nginx (if not installed)
echo "[3/7] Checking Nginx..."
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    apt install -y nginx
fi

# 4. Create directory structure
echo "[4/7] Creating directories..."
mkdir -p "$DEPLOY_DIR"/{nginx,uploads,backups,flutter-web,scripts}
touch "$DEPLOY_DIR/uploads/.gitkeep"

# 5. Create Docker network
echo "[5/7] Setting up Docker network..."
docker network create social-app-network 2>/dev/null || true

# 6. Set proper permissions
echo "[6/7] Setting permissions..."
chmod -R 755 "$DEPLOY_DIR/uploads"

# 7. Setup Nginx
echo "[7/7] Configuring Nginx..."
if [ -f "$DEPLOY_DIR/nginx/social-app.conf" ]; then
    ln -sf "$DEPLOY_DIR/nginx/social-app.conf" /etc/nginx/sites-available/social-app.conf
    ln -sf /etc/nginx/sites-available/social-app.conf /etc/nginx/sites-enabled/social-app.conf
    nginx -t && systemctl reload nginx
    echo "Nginx configured on port 8080"
fi

echo ""
echo "=== Initial Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Create .env file with your secrets:"
echo "   nano $DEPLOY_DIR/.env"
echo ""
echo "2. Copy docker-compose.prod.yml to $DEPLOY_DIR/"
echo ""
echo "3. Start services:"
echo "   cd $DEPLOY_DIR && docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "4. Run database migrations:"
echo "   cd $DEPLOY_DIR && docker compose -f docker-compose.prod.yml exec backend npx prisma db push"
echo ""
echo "Access URLs:"
echo "  Backend API:  http://YOUR_IP:3100/api"
echo "  Flutter Web:  http://YOUR_IP:8080/social/"
echo ""
