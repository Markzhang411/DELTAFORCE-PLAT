#!/bin/bash
# 直接部署脚本 - 无乱码版本

SERVER="154.64.228.29"
USER="root"
PASS="ynmaFWAX7694"
PORT="8080"

echo "开始直接部署..."

# 使用expect自动登录并执行
/usr/bin/expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${USER}@${SERVER}

expect "password:"
send "${PASS}\r"

expect "#"
send "echo '=== 开始清理 ==='\r"

expect "#"
send "rm -rf /var/www/delta-${PORT} 2>/dev/null || true\r"

expect "#"
send "rm -f /etc/nginx/sites-available/delta-${PORT} /etc/nginx/sites-enabled/delta-${PORT} 2>/dev/null || true\r"

expect "#"
send "systemctl reload nginx\r"

expect "#"
send "echo '✅ 清理完成'\r"

expect "#"
send "echo '=== 创建目录 ==='\r"

expect "#"
send "mkdir -p /var/www/delta-${PORT}/public/{css,js,admin}\r"

expect "#"
send "chown -R www-data:www-data /var/www/delta-${PORT}\r"

expect "#"
send "chmod -R 755 /var/www/delta-${PORT}\r"

expect "#"
send "echo '✅ 目录创建完成'\r"

expect "#"
send "echo '=== 创建网站首页 ==='\r"

expect "#"
send "cat > /var/www/delta-${PORT}/public/index.html << 'INDEX_EOF'\r"

expect ">"
send "<!DOCTYPE html>\r"

expect ">"
send "<html>\r"

expect ">"
send "<head>\r"

expect ">"
send "<meta charset=\"UTF-8\">\r"

expect ">"
send "<title>三角洲行动</title>\r"

expect ">"
send "<style>\r"

expect ">"
send "body{font-family:Arial;background:#1a1a2e;color:white;text-align:center;padding:50px}\r"

expect ">"
send "h1{color:#00dbde;font-size:48px}\r"

expect ">"
send ".btn{display:inline-block;padding:15px 30px;margin:10px;background:linear-gradient(90deg,#00dbde,#fc00ff);color:white;text-decoration:none;border-radius:10px;font-weight:bold}\r"

expect ">"
send ".info{margin-top:40px;color:#aaa}\r"

expect ">"
send "</style>\r"

expect ">"
send "</head>\r"

expect ">"
send "<body>\r"

expect ">"
send "<h1>三角洲行动</h1>\r"

expect ">"
send "<p>游戏服务交易平台</p>\r"

expect ">"
send "<a href=\"/\" class=\"btn\">首页</a>\r"

expect ">"
send "<a href=\"/admin/\" class=\"btn\">管理员</a>\r"

expect ">"
send "<div class=\"info\">\r"

expect ">"
send "<p>服务器: ${SERVER}:${PORT}</p>\r"

expect ">"
send "<p>部署时间: \$(date)</p>\r"

expect ">"
send "<p>测试账号: 13800138000 / admin123</p>\r"

expect ">"
send "</div>\r"

expect ">"
send "</body>\r"

expect ">"
send "</html>\r"

expect ">"
send "INDEX_EOF\r"

expect "#"
send "echo '✅ 首页创建完成'\r"

expect "#"
send "echo '=== 创建管理员页面 ==='\r"

expect "#"
send "cat > /var/www/delta-${PORT}/public/admin/login.html << 'ADMIN_EOF'\r"

expect ">"
send "<!DOCTYPE html>\r"

expect ">"
send "<html>\r"

expect ">"
send "<head>\r"

expect ">"
send "<meta charset=\"UTF-8\">\r"

expect ">"
send "<title>管理员登录</title>\r"

expect ">"
send "<style>\r"

expect ">"
send "body{font-family:Arial;background:#1a1a2e;color:white;display:flex;justify-content:center;align-items:center;height:100vh;margin:0}\r"

expect ">"
send ".login-box{background:rgba(255,255,255,0.1);padding:40px;border-radius:15px;width:400px}\r"

expect ">"
send "h2{color:#00dbde;text-align:center}\r"

expect ">"
send "input{width:100%;padding:12px;margin:10px 0;border:1px solid #444;background:rgba(255,255,255,0.1);color:white;border-radius:5px}\r"

expect ">"
send "button{width:100%;padding:12px;background:linear-gradient(90deg,#00dbde,#fc00ff);color:white;border:none;border-radius:5px;font-weight:bold;cursor:pointer}\r"

expect ">"
send ".status{text-align:center;margin-top:20px;padding:10px;background:rgba(0,255,0,0.1);border-radius:5px;color:#0f0}\r"

expect ">"
send "</style>\r"

expect ">"
send "</head>\r"

expect ">"
send "<body>\r"

expect ">"
send "<div class=\"login-box\">\r"

expect ">"
send "<h2>管理员登录</h2>\r"

expect ">"
send "<div class=\"status\">✅ 直接部署完成</div>\r"

expect ">"
send "<input type=\"text\" id=\"phone\" value=\"13800138000\">\r"

expect ">"
send "<input type=\"password\" id=\"pass\" value=\"admin123\">\r"

expect ">"
send "<button onclick=\"login()\">登录</button>\r"

expect ">"
send "<div style=\"text-align:center;margin-top:20px;color:#aaa;font-size:12px\">\r"

expect ">"
send "<p>三角洲行动 · 直接部署版本</p>\r"

expect ">"
send "</div>\r"

expect ">"
send "</div>\r"

expect ">"
send "<script>\r"

expect ">"
send "function login(){\r"

expect ">"
send "if(document.getElementById('phone').value==='13800138000'&&document.getElementById('pass').value==='admin123'){\r"

expect ">"
send "alert('登录成功！\\\\\\\\n\\\\\\\\n网站: http://${SERVER}:${PORT}/\\\\\\\\n管理员: http://${SERVER}:${PORT}/admin/');\r"

expect ">"
send "}else{alert('测试账号: 13800138000 / admin123')}\r"

expect ">"
send "}\r"

expect ">"
send "</script>\r"

expect ">"
send "</body>\r"

expect ">"
send "</html>\r"

expect ">"
send "ADMIN_EOF\r"

expect "#"
send "echo '✅ 管理员页面创建完成'\r"

expect "#"
send "echo '=== 配置Nginx ==='\r"

expect "#"
send "cat > /etc/nginx/sites-available/delta-${PORT} << 'NGINX_EOF'\r"

expect ">"
send "server {\r"

expect ">"
send "    listen ${PORT};\r"

expect ">"
send "    server_name ${SERVER};\r"

expect ">"
send "    root /var/www/delta-${PORT}/public;\r"

expect ">"
send "    index index.html;\r"

expect ">"
send "    location / { try_files \\\$uri \\\$uri/ =404; }\r"

expect ">"
send "    location /admin/ { alias /var/www/delta-${PORT}/public/admin/; try_files \\\$uri \\\$uri/ =404; }\r"

expect ">"
send "}\r"

expect ">"
send "NGINX_EOF\r"

expect "#"
send "ln -sf /etc/nginx/sites-available/delta-${PORT} /etc/nginx/sites-enabled/\r"

expect "#"
send "nginx -t\r"

expect "#"
send "systemctl reload nginx\r"

expect "#"
send "echo '✅ Nginx配置完成'\r"

expect "#"
send "echo '=== 部署完成 ==='\r"

expect "#"
send "echo '🎉 直接部署完成！'\r"

expect "#"
send "echo '🌐 网站: http://${SERVER}:${PORT}/'\r"

expect "#"
send "echo '🔐 管理员: http://${SERVER}:${PORT}/admin/'\r"

expect "#"
send "echo '📱 测试账号: 13800138000 / admin123'\r"

expect "#"
send "exit\r"

expect eof
EOF

echo "直接部署脚本执行完成"