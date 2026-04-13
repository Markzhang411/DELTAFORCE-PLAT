#!/bin/bash
# 修复8080端口Nginx配置
# 执行: bash fix_8080.sh

echo "=== 开始修复8080配置 ==="
echo "时间: $(date)"
echo ""

# 1. 检查当前配置
echo "1. 检查当前配置..."
CONFIG_FILE="/etc/nginx/sites-enabled/delta-8080"
if [ -f "$CONFIG_FILE" ]; then
    echo "当前配置:"
    cat "$CONFIG_FILE"
    echo ""
    
    # 检查root路径
    CURRENT_ROOT=$(grep -i "root" "$CONFIG_FILE" | head -1 | awk '{print $2}' | tr -d ';')
    echo "当前root路径: $CURRENT_ROOT"
else
    echo "配置文件不存在，创建新配置"
fi

echo ""

# 2. 创建/修复配置
echo "2. 创建/修复配置..."
cat > /etc/nginx/sites-available/delta-8080 << 'EOF'
server {
    listen 8080;
    server_name 154.64.228.29;
    
    # 正确路径
    root /var/www/delta-8080/public;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /admin/ {
        alias /var/www/delta-8080/public/admin/;
        try_files $uri $uri/ =404;
    }
}
EOF

# 3. 启用配置
echo "3. 启用配置..."
ln -sf /etc/nginx/sites-available/delta-8080 /etc/nginx/sites-enabled/

# 4. 确保目录存在
echo "4. 确保目录存在..."
mkdir -p /var/www/delta-8080/public/{css,js,admin}
chown -R www-data:www-data /var/www/delta-8080
chmod -R 755 /var/www/delta-8080

# 5. 创建测试页面（如果不存在）
if [ ! -f "/var/www/delta-8080/public/index.html" ]; then
    echo "5. 创建测试页面..."
    cat > /var/www/delta-8080/public/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>三角洲行动</title>
<style>
body{font-family:Arial;background:#1a1a2e;color:white;text-align:center;padding:50px}
h1{color:#00dbde;font-size:48px}
.btn{display:inline-block;padding:15px 30px;margin:10px;background:linear-gradient(90deg,#00dbde,#fc00ff);color:white;text-decoration:none;border-radius:10px;font-weight:bold}
.info{margin-top:40px;color:#aaa}
</style>
</head>
<body>
<h1>三角洲行动</h1>
<p>游戏服务交易平台</p>
<a href="/" class="btn">🏠 首页</a>
<a href="/admin/" class="btn">🔐 管理员</a>
<div class="info">
<p>服务器: 154.64.228.29:8080</p>
<p>修复时间: $(date)</p>
<p>测试账号: 13800138000 / admin123</p>
</div>
</body>
</html>
HTML_EOF
fi

# 6. 测试配置
echo "6. 测试配置..."
nginx -t

# 7. 重启Nginx
echo "7. 重启Nginx..."
systemctl reload nginx

# 8. 验证
echo "8. 验证修复..."
echo ""
echo "=== 验证结果 ==="
curl -s -o /dev/null -w "网站状态: %{http_code}\n" http://localhost:8080/
curl -s -o /dev/null -w "管理员状态: %{http_code}\n" http://localhost:8080/admin/

echo ""
echo "=== 修复完成 ==="
echo "✅ 配置已修复"
echo "🌐 网站: http://154.64.228.29:8080/"
echo "🔐 管理员: http://154.64.228.29:8080/admin/"
echo "📱 测试账号: 13800138000 / admin123"
echo ""
echo "脚本执行完成"