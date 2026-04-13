#!/bin/bash
# ════════════════════════════════════════════════
#  代号Delta · 一键部署脚本
#  在服务器上运行: bash deploy.sh
# ════════════════════════════════════════════════
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[Delta]${NC} $1"; }

SITE_DIR="/var/www/delta"
PUBLIC_DIR="$SITE_DIR/public"
BACKEND_DIR="$SITE_DIR/backend"

log "创建目录..."
mkdir -p $PUBLIC_DIR $BACKEND_DIR/node_modules /var/www/delta/data

log "复制前端文件..."
cp -r /tmp/delta-upload/index.html    $PUBLIC_DIR/
cp -r /tmp/delta-upload/css           $PUBLIC_DIR/
cp -r /tmp/delta-upload/js            $PUBLIC_DIR/

log "复制管理员控制台..."
cp -r /tmp/delta-upload/admin         $PUBLIC_DIR/ 2>/dev/null || true

log "复制后端文件..."
cp /tmp/delta-upload/backend/package.json $BACKEND_DIR/
cp /tmp/delta-upload/backend/server.js    $BACKEND_DIR/

log "安装后端依赖..."
cd $BACKEND_DIR && npm install --production

log "启动/重启后端..."
pm2 delete delta 2>/dev/null || true
NODE_ENV=production pm2 start server.js --name delta --log /var/log/delta.log
pm2 save

log "重载 Nginx..."
systemctl reload nginx

log "✅ 部署完成！"
echo ""
echo "  🌐 网站:  http://154.64.228.29"
echo "  🔌 API:   http://154.64.228.29/api/health"
echo "  📊 状态:  pm2 status"
echo "  📝 日志:  pm2 logs delta"
