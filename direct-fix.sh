#!/bin/bash
# 直接修复脚本

echo "=== 检查当前配置 ==="

# 1. 检查Nginx配置
echo "1. 检查 /etc/nginx/sites-enabled/delta-8080"
if [ -f "/etc/nginx/sites-enabled/delta-8080" ]; then
    echo "配置文件存在:"
    cat /etc/nginx/sites-enabled/delta-8080
    echo ""
    
    # 提取root路径
    ROOT_PATH=$(grep -i "root" /etc/nginx/sites-enabled/delta-8080 | head -1 | awk '{print $2}' | tr -d ';')
    echo "当前root路径: $ROOT_PATH"
else
    echo "配置文件不存在"
    ROOT_PATH=""
fi

echo ""

# 2. 检查网站目录
echo "2. 检查 /var/www/delta-8080"
if [ -d "/var/www/delta-8080" ]; then
    echo "目录存在:"
    ls -la /var/www/delta-8080/
    echo ""
    
    # 检查index.html
    if [ -f "/var/www/delta-8080/public/index.html" ]; then
        echo "index.html 存在"
        echo "文件大小: $(wc -l < /var/www/delta-8080/public/index.html) 行"
    else
        echo "index.html 不存在"
    fi
else
    echo "目录不存在"
fi

echo ""

# 3. 检查路径是否匹配
echo "3. 路径匹配检查"
EXPECTED_PATH="/var/www/delta-8080/public"
if [ "$ROOT_PATH" = "$EXPECTED_PATH" ]; then
    echo "✅ 路径匹配: $ROOT_PATH"
else
    echo "❌ 路径不匹配"
    echo "当前: $ROOT_PATH"
    echo "期望: $EXPECTED_PATH"
    
    # 4. 修复配置
    echo ""
    echo "=== 修复配置 ==="
    
    # 创建正确的配置
    cat > /etc/nginx/sites-available/delta-8080 << 'EOF'
server {
    listen 8080;
    server_name 154.64.228.29;
    root /var/www/delta-8080/public;
    index index.html;
    location / { try_files $uri $uri/ =404; }
    location /admin/ { alias /var/www/delta-8080/public/admin/; try_files $uri $uri/ =404; }
}
EOF
    
    # 启用配置
    ln -sf /etc/nginx/sites-available/delta-8080 /etc/nginx/sites-enabled/
    
    echo "✅ 配置已修复"
fi

echo ""

# 5. 确保目录和文件存在
echo "5. 确保网站文件存在"
mkdir -p /var/www/delta-8080/public/{css,js,admin}
chown -R www-data:www-data /var/www/delta-8080
chmod -R 755 /var/www/delta-8080

# 创建简单的index.html如果不存在
if [ ! -f "/var/www/delta-8080/public/index.html" ]; then
    cat > /var/www/delta-8080/public/index.html << 'EOF'
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
<p>时间: $(date)</p>
<p>测试账号: 13800138000 / admin123</p>
</div>
</body>
</html>
EOF
    echo "✅ index.html 已创建"
fi

echo ""

# 6. 测试并重启Nginx
echo "6. 测试并重启Nginx"
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    echo "✅ Nginx 已重启"
else
    echo "❌ Nginx 配置测试失败"
fi

echo ""

# 7. 测试访问
echo "7. 测试访问"
curl -s -o /dev/null -w "网站: %{http_code}\n" http://localhost:8080/
curl -s -o /dev/null -w "管理员: %{http_code}\n" http://localhost:8080/admin/

echo ""
echo "=== 修复完成 ==="
echo "配置已检查并修复"
echo "root路径: /var/www/delta-8080/public"
echo "网站: http://154.64.228.29:8080/"
echo "管理员: http://154.64.228.29:8080/admin/"