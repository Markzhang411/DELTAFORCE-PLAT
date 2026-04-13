#!/bin/bash
# 三角洲行动 · 极简部署脚本

echo "🚀 开始极简部署..."
echo "时间: $(date)"
echo ""

# 1. 创建目录
echo "📁 创建目录..."
DEPLOY_DIR="/var/www/delta-8080"
mkdir -p $DEPLOY_DIR/public/{css,js,admin}
chown -R www-data:www-data $DEPLOY_DIR
chmod -R 755 $DEPLOY_DIR

# 2. 创建首页
echo "🌐 创建首页..."
cat > $DEPLOY_DIR/public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>三角洲行动</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            color: white;
            text-align: center;
            padding: 50px;
        }
        h1 {
            color: #00dbde;
            font-size: 48px;
            margin-bottom: 20px;
        }
        .btn {
            display: inline-block;
            padding: 15px 30px;
            margin: 10px;
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            color: white;
            text-decoration: none;
            border-radius: 10px;
            font-weight: bold;
        }
        .info {
            margin-top: 40px;
            color: #aaa;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <h1>三角洲行动 · 部署成功</h1>
    <p>游戏服务交易平台</p>
    <div>
        <a href="/" class="btn">🏠 首页</a>
        <a href="/admin/" class="btn">🔐 管理员</a>
    </div>
    <div class="info">
        <p>服务器: 154.64.228.29:8080</p>
        <p>部署时间: $(date '+%Y-%m-%d %H:%M:%S')</p>
        <p>测试账号: 13800138000 / admin123</p>
    </div>
</body>
</html>
EOF

# 3. 创建管理员页面
echo "🔐 创建管理员页面..."
cat > $DEPLOY_DIR/public/admin/login.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>管理员登录</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .login-box {
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 15px;
            width: 400px;
        }
        h2 {
            color: #00dbde;
            text-align: center;
        }
        input {
            width: 100%;
            padding: 12px;
            margin: 10px 0;
            border: 1px solid #444;
            background: rgba(255,255,255,0.1);
            color: white;
            border-radius: 5px;
        }
        button {
            width: 100%;
            padding: 12px;
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            color: white;
            border: none;
            border-radius: 5px;
            font-weight: bold;
            cursor: pointer;
        }
        .status {
            text-align: center;
            margin-top: 20px;
            padding: 10px;
            background: rgba(0,255,0,0.1);
            border-radius: 5px;
            color: #0f0;
        }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>管理员登录</h2>
        <div class="status">✅ 部署完成</div>
        <form onsubmit="return login()">
            <input type="text" id="phone" placeholder="手机号" value="13800138000">
            <input type="password" id="pass" placeholder="密码" value="admin123">
            <button type="submit">登录</button>
        </form>
        <div style="text-align:center; margin-top:20px; color:#aaa; font-size:12px">
            <p>三角洲行动 · 极简部署</p>
            <p>时间: $(date '+%H:%M:%S')</p>
        </div>
    </div>
    <script>
        function login() {
            const phone = document.getElementById('phone').value;
            const pass = document.getElementById('pass').value;
            if(phone === '13800138000' && pass === 'admin123') {
                alert('登录成功！\n前端部署完成。\n访问: http://154.64.228.29:8080/');
                return false;
            }
            alert('测试账号: 13800138000 / admin123');
            return false;
        }
    </script>
</body>
</html>
EOF

# 4. 配置Nginx
echo "⚙️ 配置Nginx..."
cat > /etc/nginx/sites-available/delta-8080 << 'EOF'
server {
    listen 8080;
    server_name 154.64.228.29;
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

# 5. 启用配置
echo "🔧 启用配置..."
ln -sf /etc/nginx/sites-available/delta-8080 /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# 6. 完成
echo ""
echo "🎉 部署完成！"
echo "🌐 访问: http://154.64.228.29:8080/"
echo "🔐 管理员: http://154.64.228.29:8080/admin/"
echo "📱 账号: 13800138000 / admin123"
echo ""
echo "✅ 前端部署完成 - 随时可以使用"