#!/bin/bash
# ================================================
# 三角洲行动 · 安全部署脚本（续）
# ================================================

# 继续部署脚本...

# 完成管理员登录页面
cat >> $BASE_DIR/public/admin/login.html << 'EOF'
      transition: transform 0.2s, box-shadow 0.2s;
      margin-top: 10px;
    }
    .btn-login:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 20px rgba(0, 219, 222, 0.3);
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
  </style>
</head>
<body>
  <div class="login-container">
    <div class="login-card">
      <div class="logo">
        <h1>三角洲行动</h1>
        <p>管理员控制台 · 安全部署版本</p>
      </div>
      
      <div class="server-info">
        <h3>🖥️ 部署信息</h3>
        <p>服务器: $SERVER_IP</p>
        <p>端口: $USE_PORT</p>
        <p>路径: $BASE_DIR</p>
        <p>部署时间: $(date)</p>
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
          登录管理控制台
        </button>
      </form>
      
      <div style="text-align: center; margin-top: 30px; color: #8888aa; font-size: 13px;">
        <p>© 2026 三角洲行动 · 安全部署版本</p>
        <p>默认账号: 13800138000 / admin123</p>
      </div>
    </div>
  </div>

  <script>
    // 根据部署方案设置API地址
    const API_BASE = window.location.origin.replace(/:\d+$/, ':3000');
    
    document.getElementById('loginForm').addEventListener('submit', async function(e) {
      e.preventDefault();
      
      const phone = document.getElementById('phone').value;
      const password = document.getElementById('password').value;
      const btn = document.getElementById('loginBtn');
      
      btn.disabled = true;
      btn.textContent = '登录中...';
      
      try {
        const response = await fetch(API_BASE + '/api/admin/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ phone, password })
        });
        
        const data = await response.json();
        
        if (data.ok) {
          alert('登录成功！API服务器运行正常。');
          // 在实际版本中，这里会跳转到仪表盘
        } else {
          alert('登录失败: ' + data.msg);
        }
      } catch (error) {
        alert('API服务器连接失败，请确保后端服务正在运行。');
      } finally {
        btn.disabled = false;
        btn.textContent = '登录管理控制台';
      }
    });
  </script>
</body>
</html>
EOF

# ================================================
# 6. 部署后端API（简化版）
# ================================================
log "部署后端API..."

# 创建简化版后端
cat > $BASE_DIR/backend/server.js << 'EOF'
/**
 * 三角洲行动 · 简化版后端API
 * 用于测试部署是否成功
 */

const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({ 
    ok: true, 
    msg: '三角洲行动API运行正常',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    server: '安全部署版本'
  });
});

// 模拟管理员登录
app.post('/api/admin/login', (req, res) => {
  const { phone, password } = req.body;
  
  if (phone === '13800138000' && password === 'admin123') {
    res.json({
      ok: true,
      msg: '登录成功（模拟）',
      token: 'simulated_jwt_token_for_test',
      user: {
        id: 1,
        phone: '13800138000',
        name: '系统管理员',
        role: 'admin'
      }
    });
  } else {
    res.json({ ok: false, msg: '账号或密码错误' });
  }
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════╗
  ║  三角洲行动 · 简化API已启动       ║
  ║  端口: ${PORT}                    ║
  ║  目录: ${BASE_DIR}                ║
  ║                                   ║
  ║  测试账号:                        ║
  ║  手机号: 13800138000              ║
  ║  密码: admin123                   ║
  ╚═══════════════════════════════════╝
  `);
});
EOF

# 创建package.json
cat > $BASE_DIR/backend/package.json << 'EOF'
{
  "name": "delta-backend-safe",
  "version": "1.0.0",
  "description": "三角洲行动 · 安全部署版本",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

# 安装依赖
log "安装Node.js依赖..."
cd $BASE_DIR/backend
npm install --production

# ================================================
# 7. 配置Web服务器
# ================================================
log "配置Web服务器..."

if [ "$USE_SUBDIRECTORY" = true ]; then
    # 子目录部署配置
    cat > /etc/nginx/sites-available/delta-safe << EOF
# 三角洲行动 · 子目录部署配置
# 访问地址: http://$SERVER_IP/$SUBDIR/

location /$SUBDIR/ {
    alias $BASE_DIR/public/;
    index index.html;
    try_files \$uri \$uri/ =404;
    
    # 管理员界面
    location /$SUBDIR/admin/ {
        alias $BASE_DIR/public/admin/;
        try_files \$uri \$uri/ =404;
    }
}
EOF
else
    # 独立部署配置
    cat > /etc/nginx/sites-available/delta-safe << EOF
# 三角洲行动 · 独立部署配置
# 访问地址: http://$SERVER_IP:$USE_PORT/

server {
    listen $USE_PORT;
    server_name $SERVER_IP;
    
    root $BASE_DIR/public;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location /admin/ {
        alias $BASE_DIR/public/admin/;
        try_files \$uri \$uri/ =404;
    }
    
    # API代理（如果API在运行）
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
fi

# 启用配置
ln -sf /etc/nginx/sites-available/delta-safe /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# ================================================
# 8. 启动服务
# ================================================
log "启动服务..."

# 启动Node.js API（后台运行）
cd $BASE_DIR/backend
node server.js &
API_PID=$!
echo $API_PID > $BASE_DIR/backend/api.pid

# ================================================
# 9. 验证部署
# ================================================
log "验证部署..."

sleep 2  # 等待服务启动

echo ""
echo "=== 部署验证 ==="
echo ""

# 检查文件
echo "1. 文件检查:"
if [ -f "$BASE_DIR/public/index.html" ]; then
    echo "  ✅ 前端文件: 存在"
else
    echo "  ❌ 前端文件: 缺失"
fi

if [ -f "$BASE_DIR/public/admin/login.html" ]; then
    echo "  ✅ 管理员界面: 存在"
else
    echo "  ❌ 管理员界面: 缺失"
fi

if [ -f "$BASE_DIR/backend/server.js" ]; then
    echo "  ✅ 后端API: 存在"
else
    echo "  ❌ 后端API: 缺失"
fi

# 检查服务
echo ""
echo "2. 服务检查:"

# 检查Nginx配置
if nginx -t &> /dev/null; then
    echo "  ✅ Nginx配置: 有效"
else
    echo "  ❌ Nginx配置: 错误"
    nginx -t
fi

# 检查API服务
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo "  ✅ API服务: 运行正常"
else
    echo "  ❌ API服务: 未响应"
fi

# 检查端口
echo ""
echo "3. 端口检查:"
if netstat -tln | grep -q ":$USE_PORT "; then
    echo "  ✅ 端口 $USE_PORT: 监听中"
else
    echo "  ❌ 端口 $USE_PORT: 未监听"
fi

# ================================================
# 10. 部署完成
# ================================================
log "部署完成！"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                安全部署完成！                            ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  📍 部署信息:                                            ║"
echo "║     目录: $BASE_DIR                                      ║"
echo "║     端口: $USE_PORT                                      ║"
EOF

if [ "$USE_SUBDIRECTORY" = true ]; then
cat >> $BASE_DIR/public/admin/deploy-info.html << 'EOF'
    ║     访问路径: http://$SERVER_IP/$SUBDIR/                   ║
EOF
else
cat >> $BASE_DIR/public/admin/deploy-info.html << 'EOF'
    ║     访问路径: http://$SERVER_IP:$USE_PORT/                 ║
EOF
fi

cat >> $BASE_DIR/public/admin/deploy-info.html << 'EOF'
    ║                                                          ║
    ║  🌐 访问地址:                                            ║
    ║     网站首页: http://$SERVER_IP:$USE_PORT/               ║
    ║     管理员登录: http://$SERVER_IP:$USE_PORT/admin/       ║
    ║     API健康检查: http://localhost:3000/api/health        ║
    ║                                                          ║
    ║  🔐 测试账号:                                            ║
    ║     手机号: 13800138000                                  ║
    ║     密码: admin123                                       ║
    ║                                                          ║
    ║  ⚠️  重要提醒:                                           ║
    ║     1. 这是简化部署版本，仅用于测试                      ║
    ║     2. 生产环境需要完整部署                              ║
    ║     3. 已备份原有配置到: $BACKUP_DIR                     ║
    ║     4. API服务PID: $API_PID                              ║
    ║                                                          ║
    ╚══════════════════════════════════════════════════════════╝
EOF

# 创建部署信息页面
cat > $BASE_DIR/public/admin/deploy-info.html << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>部署信息 - 三角洲行动</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
            color: white;
            padding: 20px;
        }
        .info-container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 16px;
            padding: 30px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .info-grid {
            display: grid;
            gap: 20px;
        }
        .info-card {
            background: rgba(255, 255, 255, 0.03);
            border-radius: 12px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.05);
        }
        .info-card h3 {
            color: #00dbde;
            margin-bottom: 15px;
            font-size: 18px;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }
        .info-item:last-child {
            border-bottom: none;
        }
        .label {
            color: #b0b0d0;
        }
        .value {
            font-weight: 500;
        }
        .btn-group {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 30px;
        }
        .btn {
            padding: 12px 24px;
            border-radius: 10px;
            text-decoration: none;
            color: white;
            font-weight: 600;
            transition: all 0.3s;
        }
        .btn-primary {
            background: linear-gradient(90deg, #00dbde, #fc00ff);
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(0, 219, 222, 0.3);
        }
        .note {
            margin-top: 30px;
            padding: 15px;
            background: rgba(255, 215, 0, 0.1);
            border-radius: 10px;
            border: 1px solid rgba(255, 215, 0, 0.2);
            color: #ffd700;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="info-container">
        <h1>部署信息 · 三角洲行动</h1>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>📋 部署配置</h3>
                <div class="info-item">
                    <span class="label">服务器IP</span>
                    <span class="value">$SERVER_IP</span>
                </div>
                <div class="info-item">
                    <span class="label">部署端口</span>
                    <span class="value">$USE_PORT</span>
                </div>
                <div class="info-item">
                    <span class="label">部署目录</span>
                    <span class="value">$BASE_DIR</span>
                </div>
                <div class="info-item">
                    <span class="label">部署时间</span>
                    <span class="value">$(date)</span>
                </div>
            </div>
            
            <div class="info-card">
                <h3>🌐 访问地址</h3>
                <div class="info-item">
                    <span class="label">网站首页</span>
                    <span class="value">http://$SERVER_IP:$USE_PORT/</span>
                </div>
                <div class="info-item">
                    <span class="label">管理员登录</span>
                    <span class="value">http://$SERVER_IP:$USE_PORT/admin/</span>
                </div>
                <div class="info-item">
                    <span class="label">API服务</span>
                    <span class="value">http://localhost: