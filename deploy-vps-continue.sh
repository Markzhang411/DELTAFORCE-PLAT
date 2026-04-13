#!/bin/bash
# ================================================
# 三角洲行动 · VPS部署脚本（续）
# ================================================

# 继续部署脚本...

# 安装Node.js依赖
log "安装Node.js依赖..."
cd $BACKEND_DIR
npm install --production

# ================================================
# 6. 配置Nginx
# ================================================
log "配置Nginx..."

# 创建Nginx配置文件
cat > /etc/nginx/sites-available/delta << 'EOF'
server {
    listen 80;
    server_name 154.64.228.29;
    
    # 前端静态文件
    location / {
        root /var/www/delta/public;
        index index.html;
        try_files $uri $uri/ =404;
    }
    
    # 管理员界面
    location /admin/ {
        alias /var/www/delta/public/admin/;
        try_files $uri $uri/ =404;
    }
    
    # API代理
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}

# HTTPS配置（注释状态，需要证书后启用）
# server {
#     listen 443 ssl http2;
#     server_name 154.64.228.29;
#     
#     ssl_certificate /etc/letsencrypt/live/154.64.228.29/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/154.64.228.29/privkey.pem;
#     
#     # SSL配置
#     ssl_protocols TLSv1.2 TLSv1.3;
#     ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
#     ssl_prefer_server_ciphers off;
#     ssl_session_cache shared:SSL:10m;
#     
#     # 其他配置与HTTP相同
#     location / {
#         root /var/www/delta/public;
#         index index.html;
#     }
#     
#     location /api/ {
#         proxy_pass http://localhost:3000;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#     }
# }
EOF

# 启用站点
ln -sf /etc/nginx/sites-available/delta /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试Nginx配置
nginx -t

# 重启Nginx
systemctl restart nginx

# ================================================
# 7. 配置PM2进程管理
# ================================================
log "配置PM2进程管理..."

# 创建PM2配置文件
cat > $BACKEND_DIR/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'delta-backend',
    script: 'server.js',
    cwd: '/var/www/delta/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '200M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      JWT_SECRET: 'delta_production_secret_2026'
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000,
      JWT_SECRET: 'delta_production_secret_2026'
    },
    error_file: '/var/log/delta/error.log',
    out_file: '/var/log/delta/out.log',
    log_file: '/var/log/delta/combined.log',
    time: true
  }]
};
EOF

# 创建日志目录
mkdir -p /var/log/delta
chown -R www-data:www-data /var/log/delta

# 启动应用
cd $BACKEND_DIR
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup

# ================================================
# 8. 防火墙配置
# ================================================
log "配置防火墙..."

# 允许SSH
ufw allow 22/tcp

# 允许HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# 允许Node.js API端口（内部）
ufw allow 3000/tcp

# 启用防火墙
ufw --force enable

# ================================================
# 9. 创建监控脚本
# ================================================
log "创建监控脚本..."

cat > /usr/local/bin/delta-monitor << 'EOF'
#!/bin/bash
# 三角洲行动 · 服务器监控脚本

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== 三角洲行动服务器监控 ==="
echo "时间: $(date)"
echo ""

# 检查服务状态
echo "1. 服务状态检查:"
if systemctl is-active --quiet nginx; then
    echo -e "   Nginx: ${GREEN}运行中${NC}"
else
    echo -e "   Nginx: ${RED}未运行${NC}"
fi

if pm2 status delta-backend | grep -q "online"; then
    echo -e "   Node.js API: ${GREEN}运行中${NC}"
else
    echo -e "   Node.js API: ${RED}未运行${NC}"
fi

# 检查端口
echo ""
echo "2. 端口检查:"
if netstat -tln | grep -q ":80 "; then
    echo -e "   端口80 (HTTP): ${GREEN}开放${NC}"
else
    echo -e "   端口80 (HTTP): ${RED}关闭${NC}"
fi

if netstat -tln | grep -q ":3000 "; then
    echo -e "   端口3000 (API): ${GREEN}开放${NC}"
else
    echo -e "   端口3000 (API): ${RED}关闭${NC}"
fi

# 检查API健康
echo ""
echo "3. API健康检查:"
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo -e "   API健康: ${GREEN}正常${NC}"
else
    echo -e "   API健康: ${RED}异常${NC}"
fi

# 系统资源
echo ""
echo "4. 系统资源:"
echo "   内存使用: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "   磁盘使用: $(df -h /var/www/delta | awk 'NR==2 {print $5}')"
echo "   负载: $(uptime | awk -F'load average:' '{print $2}')"

# 数据库状态
echo ""
echo "5. 数据库状态:"
if [ -f /var/www/delta/data/delta.db ]; then
    db_size=$(du -h /var/www/delta/data/delta.db | cut -f1)
    echo "   数据库文件: ${GREEN}存在${NC} ($db_size)"
    
    # 检查表数量
    table_count=$(sqlite3 /var/www/delta/data/delta.db "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "0")
    echo "   数据表数量: $table_count"
else
    echo -e "   数据库文件: ${RED}不存在${NC}"
fi

echo ""
echo "=== 监控完成 ==="
EOF

chmod +x /usr/local/bin/delta-monitor

# ================================================
# 10. 创建备份脚本
# ================================================
log "创建备份脚本..."

cat > /usr/local/bin/delta-backup << 'EOF'
#!/bin/bash
# 三角洲行动 · 数据备份脚本

BACKUP_DIR="/backup/delta"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/delta_backup_$DATE.tar.gz"

# 创建备份目录
mkdir -p $BACKUP_DIR

echo "开始备份三角洲行动数据..."
echo "备份时间: $(date)"
echo "备份文件: $BACKUP_FILE"
echo ""

# 备份数据库
echo "1. 备份数据库..."
cp /var/www/delta/data/delta.db $BACKUP_DIR/delta.db.$DATE

# 备份配置文件
echo "2. 备份配置文件..."
tar -czf $BACKUP_FILE \
  /var/www/delta/backend \
  /var/www/delta/public/admin \
  /etc/nginx/sites-available/delta \
  /var/www/delta/backend/ecosystem.config.js

# 清理旧备份（保留最近7天）
echo "3. 清理旧备份..."
find $BACKUP_DIR -name "delta_backup_*" -mtime +7 -delete
find $BACKUP_DIR -name "delta.db.*" -mtime +7 -delete

echo ""
echo "备份完成!"
echo "备份大小: $(du -h $BACKUP_FILE | cut -f1)"
echo "备份位置: $BACKUP_FILE"
EOF

chmod +x /usr/local/bin/delta-backup

# 创建备份目录
mkdir -p /backup/delta

# ================================================
# 11. 创建管理员使用指南
# ================================================
log "创建管理员使用指南..."

cat > $ADMIN_DIR/README.md << 'EOF'
# 三角洲行动 · 管理员控制台使用指南

## 快速开始

### 1. 访问地址
```
http://154.64.228.29/admin/login.html
```

### 2. 默认管理员账号
- **手机号**: `13800138000`
- **密码**: `admin123`

### 3. 首次登录后
1. 立即修改默认密码
2. 创建新的管理员账号
3. 禁用默认账号（可选）

## 功能说明

### 仪表盘
- 实时数据统计
- 服务器状态监控
- 用户和订单概览

### 用户管理
- 查看所有用户
- 搜索和筛选用户
- 修改用户信息
- 删除用户（谨慎操作）

### 订单管理
- 查看所有订单
- 按状态筛选订单
- 修改订单状态
- 删除订单

### 数据统计
- 详细的数据分析
- 收入统计
- 用户活跃度
- 服务类型分布

## 服务器管理

### 常用命令
```bash
# 查看服务状态
delta-monitor

# 重启后端服务
pm2 restart delta-backend

# 重启Nginx
systemctl restart nginx

# 查看日志
tail -f /var/log/delta/combined.log

# 数据备份
delta-backup
```

### 端口说明
- `80`: HTTP网站
- `3000`: 内部API（Node.js）
- `22`: SSH管理

## 安全建议

### 1. 密码安全
- 使用强密码（12位以上，包含大小写字母、数字、特殊字符）
- 定期更换密码
- 不要共享管理员账号

### 2. 服务器安全
- 定期更新系统：`apt update && apt upgrade`
- 配置防火墙：只开放必要端口
- 启用SSH密钥认证，禁用密码登录
- 定期备份数据

### 3. 应用安全
- 生产环境修改JWT_SECRET
- 配置HTTPS（推荐使用Let's Encrypt）
- 限制管理员界面的访问IP
- 启用操作日志记录

## 故障排除

### 常见问题

**Q: 无法访问管理员界面**
```
# 检查Nginx状态
systemctl status nginx

# 检查端口
netstat -tln | grep :80
```

**Q: 登录失败**
```
# 检查API服务
pm2 status delta-backend

# 检查数据库
ls -la /var/www/delta/data/delta.db
```

**Q: 数据不显示**
```
# 检查数据库连接
sqlite3 /var/www/delta/data/delta.db ".tables"

# 查看错误日志
tail -f /var/log/delta/error.log
```

## 联系方式

如有问题，请联系系统管理员。

---
*最后更新: $(date)*
EOF

# ================================================
# 12. 完成部署
# ================================================
log "完成部署！"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                部署完成！                                ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  🌐 网站地址: http://154.64.228.29                       ║"
echo "║  🔐 管理员入口: http://154.64.228.29/admin/login.html    ║"
echo "║                                                          ║"
echo "║  📋 默认管理员账号:                                      ║"
echo "║     手机号: 13800138000                                  ║"
echo "║     密码: admin123                                       ║"
echo "║                                                          ║"
echo "║  🛠️  管理命令:                                          ║"
echo "║     delta-monitor    # 监控服务器状态                    ║"
echo "║     delta-backup     # 数据备份                          ║"
echo "║     pm2 status       # 查看Node.js服务状态               ║"
echo "║                                                          ║"
echo "║  📁 重要目录:                                           ║"
echo "║     /var/www/delta/              # 网站根目录            ║"
echo "║     /var/www/delta/data/         # 数据库目录            ║"
echo "║     /var/log/delta/              # 日志目录              ║"
echo "║     /backup/delta/               # 备份目录              ║"
echo "║                                                          ║"
echo "║  ⚠️  安全提醒:                                           ║"
echo "║     1. 立即修改默认管理员密码                            ║"
echo "║     2. 配置HTTPS证书                                     ║"
echo "║     3. 设置SSH密钥认证                                   ║"
echo "║     4. 定期备份数据                                      ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "下一步:"
echo "1. 访问 http://154.64.228.29/admin/login.html"
echo "2. 使用默认账号登录"
echo "3. 创建新的管理员账号"
echo "4. 修改默认密码"
echo "5. 开始使用管理员控制台"
echo ""

# 运行监控脚本检查部署状态
/usr/local/bin/delta-monitor