#!/bin/bash
# 三角洲行动 · 全自动部署脚本
# 自动SSH连接 + 密码输入 + 完整部署

set -e
echo "🚀 开始全自动部署..."
echo "时间: $(date)"
echo ""

# 配置信息
SERVER_IP="154.64.228.29"
USERNAME="root"
PASSWORD="ynmaFWAX7694"
DEPLOY_PORT="8080"
DEPLOY_DIR="/var/www/delta-8080"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# 1. 检查工具
info "检查必要工具..."
if ! command -v sshpass &> /dev/null; then
    error "sshpass未安装，正在安装..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y sshpass
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
    elif [[ "$OSTYPE" == "msys"* ]]; then
        error "Windows请手动安装sshpass或使用Git Bash"
        exit 1
    fi
fi
success "工具检查完成"

# 2. 测试连接
info "测试服务器连接..."
if sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$USERNAME@$SERVER_IP" "echo '连接测试成功'"; then
    success "服务器连接成功"
else
    error "服务器连接失败"
    exit 1
fi

# 3. 执行远程部署
info "开始远程部署..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER_IP" << EOF
#!/bin/bash
set -e

echo "=== 远程部署开始 ==="
echo "时间: \$(date)"
echo "IP: \$(hostname -I)"
echo ""

# 安装必要工具
echo "安装必要工具..."
apt-get update > /dev/null 2>&1
apt-get install -y nginx curl net-tools > /dev/null 2>&1
echo "工具安装完成"

# 创建部署目录
echo "创建部署目录..."
rm -rf $DEPLOY_DIR 2>/dev/null || true
mkdir -p $DEPLOY_DIR/public/{css,js,images,admin}
chown -R www-data:www-data $DEPLOY_DIR
chmod -R 755 $DEPLOY_DIR
echo "目录创建完成: $DEPLOY_DIR"

# 创建网站首页
echo "创建网站首页..."
cat > $DEPLOY_DIR/public/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>三角洲行动 · 护航接单平台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            padding: 20px;
        }
        .container {
            text-align: center;
            max-width: 800px;
        }
        h1 {
            font-size: 42px;
            margin-bottom: 20px;
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        p {
            font-size: 20px;
            color: #a0a0c0;
            margin-bottom: 40px;
        }
        .links {
            display: flex;
            gap: 20px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            padding: 14px 28px;
            background: rgba(255, 255, 255, 0.1);
            color: white;
            text-decoration: none;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            transition: all 0.3s;
            font-weight: 600;
        }
        .btn:hover {
            background: rgba(255, 255, 255, 0.15);
            transform: translateY(-2px);
        }
        .btn-admin {
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            border: none;
        }
        .btn-admin:hover {
            box-shadow: 0 10px 20px rgba(0, 219, 222, 0.3);
        }
        .info {
            margin-top: 40px;
            color: #8888aa;
            font-size: 14px;
            line-height: 1.6;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            background: rgba(87, 255, 137, 0.2);
            border: 1px solid rgba(87, 255, 137, 0.5);
            border-radius: 20px;
            color: #57ff89;
            font-size: 12px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="status-badge">✅ 全自动部署完成</div>
        <h1>三角洲行动 · 护航接单平台</h1>
        <p>游戏服务交易平台 - 专业、安全、高效</p>
        <div class="links">
            <a href="/" class="btn">🏠 首页</a>
            <a href="/admin/" class="btn btn-admin">🔐 管理员入口</a>
        </div>
        <div class="info">
            <p><strong>✅ 部署状态</strong>: <span style="color:#57ff89">运行中</span></p>
            <p><strong>🌐 访问地址</strong>: http://$SERVER_IP:$DEPLOY_PORT/</p>
            <p><strong>🔐 管理员</strong>: http://$SERVER_IP:$DEPLOY_PORT/admin/</p>
            <p><strong>📱 测试账号</strong>: 13800138000 / admin123</p>
            <p><strong>🕐 部署时间</strong>: \$(date '+%Y-%m-%d %H:%M:%S')</p>
            <p><strong>⚡ 部署方式</strong>: 全自动脚本部署</p>
        </div>
    </div>
</body>
</html>
HTML_EOF
echo "网站首页创建完成"

# 创建管理员页面
echo "创建管理员页面..."
cat > $DEPLOY_DIR/public/admin/login.html << 'ADMIN_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>管理员登录 - 三角洲行动</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
      padding: 20px;
    }
    .login-container {
      width: 100%;
      max-width: 500px;
    }
    .login-card {
      background: rgba(255, 255, 255, 0.05);
      backdrop-filter: blur(10px);
      border-radius: 16px;
      padding: 40px 30px;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    .logo {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo h1 {
      font-size: 28px;
      font-weight: 700;
      background: linear-gradient(90deg, #00dbde, #fc00ff);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 8px;
    }
    .logo p {
      color: #a0a0c0;
      font-size: 14px;
    }
    .server-info {
      background: rgba(0, 219, 222, 0.1);
      border: 1px solid rgba(0, 219, 222, 0.3);
      border-radius: 10px;
      padding: 15px;
      margin-bottom: 20px;
      font-size: 14px;
    }
    .server-info h3 {
      color: #00dbde;
      margin-bottom: 8px;
      font-size: 16px;
    }
    .form-group {
      margin-bottom: 24px;
    }
    .form-group label {
      display: block;
      margin-bottom: 8px;
      color: #b0b0d0;
      font-size: 14px;
      font-weight: 500;
    }
    .form-control {
      width: 100%;
      padding: 14px 16px;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 10px;
      color: #fff;
      font-size: 16px;
    }
    .btn-login {
      width: 100%;
      padding: 16px;
      background: linear-gradient(90deg, #00dbde, #fc00ff);
      border: none;
      border-radius: 10px;
      color: white;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: transform 0.2s, box-shadow 0.2s;
      margin-top: 10px;
    }
    .btn-login:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 20px rgba(0, 219, 222, 0.3);
    }
    .deploy-status {
      text-align: center;
      margin-top: 20px;
      padding: 10px;
      background: rgba(87, 255, 137, 0.1);
      border-radius: 8px;
      color: #57ff89;
      font-size: 13px;
    }
  </style>
</head>
<body>
  <div class="login-container">
    <div class="login-card">
      <div class="logo">
        <h1>三角洲行动</h1>
        <p>管理员控制台 · 全自动部署</p>
      </div>
      
      <div class="server-info">
        <h3>🖥️ 部署信息</h3>
        <p><strong>服务器:</strong> $SERVER_IP</p>
        <p><strong>端口:</strong> $DEPLOY_PORT</p>
        <p><strong>部署时间:</strong> \$(date '+%Y-%m-%d %H:%M:%S')</p>
        <p><strong>测试账号:</strong> 13800138000 / admin123</p>
        <p><strong>部署方式:</strong> 全自动脚本</p>
      </div>
      
      <div class="deploy-status">
        ✅ 前端部署完成 · 全自动脚本部署
      </div>
      
      <form id="loginForm">
        <div class="form-group">
          <label for="phone">管理员手机号</label>
          <input type="text" id="phone" class="form-control" 
                 placeholder="请输入管理员手机号" value="13800138000" required>
        </div>
        
        <div class="form-group">
          <label for="password">密码</label>
          <input type="password" id="password" class="form-control" 
                 placeholder="请输入密码" value="admin123" required>
        </div>
        
        <button type="submit" class="btn-login" id="loginBtn">
          🔐 登录管理控制台
        </button>
      </form>
      
      <div style="text-align: center; margin-top: 30px; color: #8888aa; font-size: 13px;">
        <p>© 2026 三角洲行动 · 全自动部署版本 v2.0</p>
        <p>部署完成时间: \$(date '+%Y-%m-%d %H:%M:%S')</p>
      </div>
    </div>
  </div>

  <script>
    document.getElementById('loginForm').addEventListener('submit', function(e) {
      e.preventDefault();
      const phone = document.getElementById('phone').value;
      const password = document.getElementById('password').value;
      const btn = document.getElementById('loginBtn');
      
      btn.disabled = true;
      btn.textContent = '登录中...';
      
      setTimeout(() => {
        if (phone === '13800138000' && password === 'admin123') {
          alert('🎉 登录成功！\\n\\n🌐 网站: http://$SERVER_IP:$DEPLOY_PORT/\\n🔐 管理员: http://$SERVER_IP:$DEPLOY_PORT/admin/\\n\\n✅ 全自动部署完成');
        } else {
          alert('❌ 登录失败\\n请使用测试账号:\\n📱 13800138000\\n🔑 admin123');
        }
        btn.disabled = false;
        btn.textContent = '🔐 登录管理控制台';
      }, 800);
    });
  </script>
</body>
</html>
ADMIN_EOF
echo "管理员页面创建完成"

# 配置Nginx
echo "配置Nginx..."
cat > /etc/nginx/sites-available/delta-8080 << 'NGINX_EOF'
# 三角洲行动 · 端口8080部署
# 自动生成时间: $(date)

server {
    listen $DEPLOY_PORT;
    server_name $SERVER_IP;
    
    root $DEPLOY_DIR/public;
    index index.html;
    
    # 主站点
    location / {
        try_files \$uri \$uri/ =404;
        add_header X-Deployment-Mode "auto-deploy-full";
        add_header X-Deployment-Time "$(date '+%Y-%m-%d %H:%M:%S')";
    }
    
    # 管理员界面
    location /admin/ {
        alias $DEPLOY_DIR/public/admin/;
        try_files \$uri \$uri/ =404;
        add_header X-Admin-Access "enabled";
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
    
    # 访问日志
    access_log /var/log/nginx/delta-8080-access.log;
    error_log /var/log/nginx/delta-8080-error.log;
}
NGINX_EOF

# 启用配置
ln -sf /etc/nginx/sites-available/delta-8080 /etc/nginx/sites-enabled/ 2>/dev/null || true

# 测试配置
nginx -t

# 重启Nginx
systemctl reload nginx
echo "Nginx配置完成并重启"

# 创建简单的后端API
echo "创建测试API..."
cat > $DEPLOY_DIR/backend/test-api.js << 'API_EOF'
const http = require('http');
const PORT = 3001;

const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    if (req.url === '/api/health') {
        res.end(JSON.stringify({
            ok: true,
            service: 'delta-auto-deploy',
            version: '2.0.0',
            status: 'running',
            timestamp: new Date().toISOString(),
            deployment: 'auto-deploy-full',
            server: '$SERVER_IP',
            port: '$DEPLOY_PORT'
        }));
    } else if (req.url === '/api/deploy-info') {
        res.end(JSON.stringify({
            deployment: {
                time: '$(date)',
                method: 'auto-script',
                directory: '$DEPLOY_DIR',
                port: $DEPLOY_PORT,
                status: 'success'
            }
        }));
    }