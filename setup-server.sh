#!/bin/bash
# ════════════════════════════════════════════════
#  代号Delta · 一键服务器安装脚本
#  适用于 Ubuntu 22.04 · 运行: bash setup-server.sh
# ════════════════════════════════════════════════
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[Delta]${NC} $1"; }
warn() { echo -e "${YELLOW}[警告]${NC} $1"; }

log "开始安装代号Delta服务器环境..."

# ── 1. 更新系统 ─────────────────────────────────
log "更新系统包..."
apt-get update -y
apt-get upgrade -y

# ── 2. 安装 Nginx ───────────────────────────────
log "安装 Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx

# ── 3. 安装 Node.js 20 LTS ─────────────────────
log "安装 Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
node -v && npm -v

# ── 4. 安装 PM2（进程管理）──────────────────────
log "安装 PM2..."
npm install -g pm2

# ── 5. 安装 SQLite3 ────────────────────────────
log "安装 SQLite3..."
apt-get install -y sqlite3 libsqlite3-dev

# ── 6. 配置防火墙 ───────────────────────────────
log "配置防火墙（开放 80/443/3000）..."
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 3000
ufw --force enable

# ── 7. 创建项目目录 ─────────────────────────────
log "创建项目目录..."
mkdir -p /var/www/delta
mkdir -p /var/www/delta/backend
mkdir -p /var/www/delta/data

# ── 8. 配置 Nginx ───────────────────────────────
log "配置 Nginx..."
cat > /etc/nginx/sites-available/delta << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    # 前端静态文件
    root /var/www/delta/public;
    index index.html;

    # 前端路由（SPA）
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
}
NGINX_EOF

ln -sf /etc/nginx/sites-available/delta /etc/nginx/sites-enabled/delta
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

log "✅ 安装完成！"
echo ""
echo "下一步："
echo "1. 上传前端文件到 /var/www/delta/public/"
echo "2. 上传后端文件到 /var/www/delta/backend/"
echo "3. 在 /var/www/delta/backend/ 运行: npm install && pm2 start server.js --name delta"
echo "4. 访问 http://154.64.228.29 查看网站"
