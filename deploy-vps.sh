#!/bin/bash
# ================================================
# 三角洲行动 · VPS一键部署脚本
# 在服务器上运行: bash deploy-vps.sh
# ================================================
set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[Delta]${NC} $1"; }
warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
error() { echo -e "${RED}[错误]${NC} $1"; }
info() { echo -e "${BLUE}[信息]${NC} $1"; }

# 配置变量
SERVER_IP="154.64.228.29"
SITE_DIR="/var/www/delta"
PUBLIC_DIR="$SITE_DIR/public"
BACKEND_DIR="$SITE_DIR/backend"
DATA_DIR="$SITE_DIR/data"
ADMIN_DIR="$PUBLIC_DIR/admin"
DOMAIN=""  # 如果没有域名，使用IP地址

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then 
  warn "建议使用sudo运行此脚本"
  read -p "是否继续? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# ================================================
# 1. 系统更新和依赖安装
# ================================================
log "更新系统包..."
apt-get update
apt-get upgrade -y

log "安装必要依赖..."
apt-get install -y \
  curl \
  wget \
  git \
  build-essential \
  nginx \
  certbot \
  python3-certbot-nginx \
  sqlite3 \
  libsqlite3-dev \
  nodejs \
  npm \
  pm2

# 更新Node.js到最新LTS版本
if ! command -v n &> /dev/null; then
  log "安装Node.js版本管理工具..."
  npm install -g n
  n lts
fi

# ================================================
# 2. 创建目录结构
# ================================================
log "创建网站目录..."
mkdir -p $PUBLIC_DIR $BACKEND_DIR $DATA_DIR $ADMIN_DIR
mkdir -p $PUBLIC_DIR/{css,js,images}

# 设置权限
chown -R www-data:www-data $SITE_DIR
chmod -R 755 $SITE_DIR

# ================================================
# 3. 部署前端文件
# ================================================
log "部署前端文件..."

# 复制主页面
cat > $PUBLIC_DIR/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>三角洲行动 · 护航接单平台</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <h1>三角洲行动 · 护航接单平台</h1>
        <p>游戏服务交易平台 - 专业、安全、高效</p>
        <div class="links">
            <a href="/" class="btn">首页</a>
            <a href="/admin/login.html" class="btn btn-admin">管理员入口</a>
        </div>
    </div>
</body>
</html>
EOF

# 创建CSS文件
cat > $PUBLIC_DIR/css/style.css << 'EOF'
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
EOF

# ================================================
# 4. 部署管理员控制台
# ================================================
log "部署管理员控制台..."

# 创建管理员登录页面
cat > $ADMIN_DIR/login.html << 'EOF'
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
      opacity: 0.8;
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
    .server-info code {
      background: rgba(0, 0, 0, 0.3);
      padding: 2px 6px;
      border-radius: 4px;
      font-family: monospace;
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
      transition: all 0.3s;
    }
    .form-control:focus {
      outline: none;
      border-color: #00dbde;
      background: rgba(255, 255, 255, 0.12);
    }
    .form-control::placeholder {
      color: #8888aa;
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
    .btn-login:disabled {
      opacity: 0.6;
      cursor: not-allowed;
      transform: none !important;
    }
    .alert {
      padding: 12px 16px;
      border-radius: 8px;
      margin-bottom: 20px;
      font-size: 14px;
      display: none;
    }
    .alert-error {
      background: rgba(255, 87, 87, 0.1);
      border: 1px solid rgba(255, 87, 87, 0.3);
      color: #ff5757;
    }
    .alert-success {
      background: rgba(87, 255, 137, 0.1);
      border: 1px solid rgba(87, 255, 137, 0.3);
      color: #57ff89;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      color: #8888aa;
      font-size: 13px;
    }
    .footer a {
      color: #00dbde;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="login-container">
    <div class="login-card">
      <div class="logo">
        <h1>三角洲行动</h1>
        <p>管理员控制台 · 生产环境</p>
      </div>
      
      <div class="server-info">
        <h3>🖥️ 服务器信息</h3>
        <p>IP地址: <code>154.64.228.29</code></p>
        <p>部署时间: <script>document.write(new Date().toLocaleDateString('zh-CN'));</script></p>
      </div>
      
      <div id="alert" class="alert"></div>
      
      <form id="loginForm">
        <div class="form-group">
          <label for="phone">管理员手机号</label>
          <input type="text" id="phone" class="form-control" 
                 placeholder="请输入管理员手机号" required>
        </div>
        
        <div class="form-group">
          <label for="password">密码</label>
          <input type="password" id="password" class="form-control" 
                 placeholder="请输入密码" required>
        </div>
        
        <button type="submit" class="btn-login" id="loginBtn">
          登录管理控制台
        </button>
      </form>
      
      <div class="footer">
        <p>© 2026 三角洲行动 · 管理员控制台 v1.0</p>
        <p>首次使用请创建管理员账号</p>
      </div>
    </div>
  </div>

  <script>
    const API_BASE = window.location.origin.replace(/:\d+$/, ':3000');
    
    function showAlert(message, type = 'error') {
      const alert = document.getElementById('alert');
      alert.textContent = message;
      alert.className = `alert alert-${type}`;
      alert.style.display = 'block';
      
      if (type === 'success') {
        setTimeout(() => alert.style.display = 'none', 3000);
      }
    }
    
    async function handleLogin(e) {
      e.preventDefault();
      
      const phone = document.getElementById('phone').value.trim();
      const password = document.getElementById('password').value;
      const loginBtn = document.getElementById('loginBtn');
      
      if (!phone || !password) {
        showAlert('请输入手机号和密码');
        return;
      }
      
      loginBtn.disabled = true;
      loginBtn.textContent = '登录中...';
      
      try {
        const response = await fetch(`${API_BASE}/api/admin/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ phone, password })
        });
        
        const data = await response.json();
        
        if (data.ok) {
          showAlert('登录成功，正在跳转...', 'success');
          
          localStorage.setItem('admin_token', data.token);
          localStorage.setItem('admin_user', JSON.stringify(data.user));
          
          setTimeout(() => {
            window.location.href = 'dashboard.html';
          }, 1000);
        } else {
          showAlert(data.msg || '登录失败');
        }
      } catch (error) {
        console.error('登录错误:', error);
        showAlert('API服务器连接失败，请确保后端服务正在运行');
      } finally {
        loginBtn.disabled = false;
        loginBtn.textContent = '登录管理控制台';
      }
    }
    
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    
    // 检查是否已登录
    const token = localStorage.getItem('admin_token');
    if (token) {
      try {
        const user = JSON.parse(localStorage.getItem('admin_user') || '{}');
        if (user.role === 'admin') {
          window.location.href = 'dashboard.html';
        }
      } catch (e) {
        localStorage.clear();
      }
    }
  </script>
</body>
</html>
EOF

# 创建管理员仪表盘页面（简化版）
cat > $ADMIN_DIR/dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>管理控制台 - 三角洲行动</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      min-height: 100vh;
      color: white;
      padding: 20px;
    }
    .dashboard {
      max-width: 1200px;
      margin: 0 auto;
    }
    header {
      text-align: center;
      margin-bottom: 40px;
    }
    h1 {
      font-size: 36px;
      margin-bottom: 10px;
      background: linear-gradient(90deg, #00dbde, #fc00ff);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .subtitle {
      color: #a0a0c0;
      font-size: 18px;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-bottom: 40px;
    }
    .stat-card {
      background: rgba(255, 255, 255, 0.05);
      border-radius: 12px;
      padding: 25px;
      border: 1px solid rgba(255, 255, 255, 0.1);
      text-align: center;
    }
    .stat-value {
      font-size: 42px;
      font-weight: bold;
      margin-bottom: 10px;
      background: linear-gradient(90deg, #00dbde, #fc00ff);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .stat-label {
      color: #8888aa;
      font-size: 16px;
    }
    .actions {
      display: flex;
      gap: 15px;
      justify-content: center;
      margin-top: 40px;
      flex-wrap: wrap;
    }
    .btn {
      padding: 12px 24px;
      border-radius: 10px;
      text-decoration: none;
      font-weight: 600;
      font-size: 16px;
      transition: all 0.3s;
      border: none;
      cursor: pointer;
    }
    .btn-primary {
      background: linear-gradient(90deg, #00dbde, #fc00ff);
      color: white;
    }
    .btn-primary:hover {
      transform: translateY(-3px);
      box-shadow: 0 10px 20px rgba(0, 219, 222, 0.3);
    }
    .btn-secondary {
      background: rgba(255, 255, 255, 0.1);
      color: white;
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
    .btn-secondary:hover {
      background: rgba(255, 255, 255, 0.15);
      transform: translateY(-2px);
    }
    .server-info {
      background: rgba(0, 219, 222, 0.1);
      border: 1px solid rgba(0, 219, 222, 0.3);
      border-radius: 12px;
      padding: 20px;
      margin: 30px 0;
      text-align: left;
    }
    .server-info h3 {
      color: #00dbde;
      margin-bottom: 15px;
    }
    .info-item {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }
    .info-item:last-child {
      border-bottom: none;
    }
    .alert {
      padding: 15px;
      border-radius: 10px;
      margin: 20px 0;
      display: none;
    }
    .alert-success {
      background: rgba(87, 255, 137, 0.1);
      border: 1px solid rgba(87, 255, 137, 0.3);
      color: #57ff89;
    }
    .alert-error {
      background: rgba(255, 87, 87, 0.1);
      border: 1px solid rgba(255, 87, 87, 0.3);
      color: #ff5757;
    }
  </style>
</head>
<body>
  <div class="dashboard">
    <header>
      <h1>管理控制台</h1>
      <p class="subtitle">三角洲行动 · 生产环境</p>
    </header>
    
    <div id="alert" class="alert"></div>
    
    <div class="server-info">
      <h3>🖥️ 服务器状态</h3>
      <div class="info-item">
        <span>服务器IP</span>
        <span><code>154.64.228.29</code></span>
      </div>
      <div class="info-item">
        <span>API状态</span>
        <span id="apiStatus">检查中...</span>
      </div>
      <div class="info-item">
        <span>数据库状态</span>
        <span id="dbStatus">检查中...</span>
      </div>
      <div class="info-item">
        <span>管理员账号</span>
        <span id="adminStatus">未设置</span>
      </div>
    </div>
    
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-value" id="totalUsers">0</div>
        <div class="stat-label">总用户数</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="totalOrders">0</div>
        <div class="stat-label">总订单数</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="activeOrders">0</div>
        <div class="stat-label">活跃订单</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="totalRevenue">¥0</div>
        <div class="stat-label">总收入</div>
      </div>
    </div>
    
    <div class="actions">
      <button class="btn btn-primary" onclick="createAdmin()">
        创建管理员账号
      </button>
      <button class="btn btn-secondary" onclick="refreshData()">
        刷新数据
      </button>
      <button class="btn btn-secondary" onclick="viewLogs()">
        查看日志
      </button>
      <button class="btn btn-secondary" onclick="logout()">
        退出登录
      </button>
    </div>
  </div>

  <script>
    const API_BASE = window.location.origin.replace(/:\d+$/, ':3000');
    let adminToken = localStorage.getItem('admin_token');
    
    // 检查认证
    if (!adminToken) {
      window.location.href = 'login.html';
    }
    
    // 初始化
    async function init() {
      checkServerStatus();
      loadStats();
      setInterval(checkServerStatus, 30000); // 30秒检查一次
    }
    
    // 检查服务器状态
    async function checkServerStatus() {
      try {
        const response = await fetch(`${API_BASE}/api/stats`);
        if (response.ok) {
          document.getElementById('apiStatus').textContent = '✅ 运行正常';
          document.getElementById('apiStatus').style.color = '#57ff89';
        } else {
          document.getElementById('apiStatus').textContent = '❌ 连接失败';
          document.getElementById('apiStatus').style.color = '#ff5757';
        }
      } catch (error) {
        document.getElementById('apiStatus').textContent = '❌ 无法连接';
        document.getElementById('apiStatus').style.color = '#ff5757';
      }
      
      // 检查数据库
      try {
        const response = await fetch(`${API_BASE}/api/admin/stats`, {
          headers: { 'Authorization': `Bearer ${adminToken}` }
        });
        if (response.ok) {
          document.getElementById('dbStatus').textContent = '✅ 连接正常';
          document.getElementById('dbStatus').style.color = '#57ff89';
        }
      } catch (error) {
        document.getElementById('dbStatus').textContent = '❌ 连接失败';
        document.getElementById('dbStatus').style.color = '#ff5757';
      }
    }
    
    // 加载统计数据
    async function loadStats() {
      try {
        const response = await fetch(`${API_BASE}/api/admin/stats`, {
          headers: { 'Authorization': `Bearer ${adminToken}` }
        });
        
        if (response.status === 401) {
          localStorage.clear();
          window.location.href = 'login.html';
          return;
        }
        
        if (response.ok) {
          const data = await response.json();
          if (data.ok) {
            document.getElementById('totalUsers').textContent = data.stats.totalUsers || 0;
            document.getElementById('totalOrders').textContent = data.stats.totalOrders || 0;
            document.getElementById('activeOrders').textContent = data.stats.activeOrders || 0;
            document.getElementById('totalRevenue').textContent = `¥${data.stats.totalRevenue || 0}`;
            
            // 更新管理员状态
            document.getElementById('adminStatus').textContent = '✅ 已设置';
            document.getElementById('adminStatus').style.color = '#57ff89';
          }
        }
      } catch (error) {
        console.error('加载统计失败:', error);
      }
    }
    
    // 创建管理员账号
    async function createAdmin() {
      const phone = prompt('请输入管理员手机号:');
      if (!phone) return;
      
      const password = prompt('请输入密码:');
      if (!password) return;
      
      const name = prompt('请输入管理员姓名:', '系统管理员');
      
      try {
        const response = await fetch(`${API_BASE}/api/admin/create`, {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${adminToken}`
          },
          body: JSON.stringify({ phone, password, name, role: 'admin' })
        });
        
        const data = await response.json();
        
        if (data.ok) {
          showAlert('管理员账号创建成功!', 'success');
          loadStats();
        } else {
          showAlert(data.msg || '创建失败', 'error');
        }
      } catch (error) {
        showAlert('创建失败: ' + error.message, 'error');
      }
    }
    
    // 刷新数据
    function refreshData() {
      showAlert('正在刷新数据...', 'success');
      loadStats();
      checkServerStatus();
    }
    
    // 查看日志
    function viewLogs() {
      alert('日志查看功能将在后续版本中实现');
    }
    
    // 退出登录
    function logout() {
      if (confirm('确定要退出登录吗？')) {
        localStorage.clear();
        window.location.href = 'login.html';
      }
    }
    
    // 显示提示
    function showAlert(message, type = 'success') {
      const alert = document.getElementById('alert');
      alert.textContent = message;
      alert.className = `alert alert-${type}`;
      alert.style.display = 'block';
      
      setTimeout(() => {
        alert.style.display = 'none';
      }, 3000);
    }
    
    // 页面加载完成后初始化
    window.addEventListener('load', init);
  </script>
</body>
</html>
EOF
