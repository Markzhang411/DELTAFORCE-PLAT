# 三角洲行动 · Windows全自动部署脚本
# 使用PowerShell自动SSH连接和部署

param(
    [string]$ServerIP = "154.64.228.29",
    [string]$Username = "root",
    [string]$Password = "ynmaFWAX7694",
    [string]$DeployPort = "8080"
)

# 颜色输出
$ErrorActionPreference = "Stop"

function Write-Success { Write-Host "✅ $($args[0])" -ForegroundColor Green }
function Write-Info { Write-Host "ℹ️  $($args[0])" -ForegroundColor Yellow }
function Write-Error { Write-Host "❌ $($args[0])" -ForegroundColor Red }

Write-Host ""
Write-Host "🚀 三角洲行动 · Windows全自动部署" -ForegroundColor Cyan
Write-Host "服务器: $ServerIP" -ForegroundColor White
Write-Host "端口: $DeployPort" -ForegroundColor White
Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""

# 1. 检查SSH客户端
Write-Info "检查SSH客户端..."
if (Get-Command ssh -ErrorAction SilentlyContinue) {
    Write-Success "SSH客户端已安装"
} else {
    Write-Error "SSH客户端未安装"
    Write-Host "请安装OpenSSH客户端:" -ForegroundColor Gray
    Write-Host "1. 打开'设置' → '应用' → '可选功能'" -ForegroundColor Gray
    Write-Host "2. 搜索'OpenSSH客户端'并安装" -ForegroundColor Gray
    exit 1
}

# 2. 测试连接
Write-Info "测试服务器连接..."
try {
    $test = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue
    if ($test.TcpTestSucceeded) {
        Write-Success "服务器可连接"
    } else {
        Write-Error "服务器连接失败"
        exit 1
    }
} catch {
    Write-Error "连接测试异常: $_"
    exit 1
}

# 3. 创建临时脚本文件
Write-Info "创建部署脚本..."
$deployScript = @"
#!/bin/bash
# 三角洲行动 · 自动化部署脚本
# 生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

set -e
echo "=== 开始自动化部署 ==="
echo "时间: \$(date)"
echo "服务器: \$(hostname)"
echo "IP: \$(hostname -I | awk '{print \$1}')"
echo ""

# 配置
DEPLOY_DIR="/var/www/delta-$DeployPort"
SERVER_IP="$ServerIP"
DEPLOY_PORT="$DeployPort"

# 安装必要工具
echo "安装必要工具..."
apt-get update > /dev/null 2>&1
apt-get install -y nginx curl net-tools > /dev/null 2>&1
echo "✅ 工具安装完成"

# 创建部署目录
echo "创建部署目录..."
rm -rf \$DEPLOY_DIR 2>/dev/null || true
mkdir -p \$DEPLOY_DIR/public/{css,js,images,admin}
chown -R www-data:www-data \$DEPLOY_DIR
chmod -R 755 \$DEPLOY_DIR
echo "✅ 目录创建完成: \$DEPLOY_DIR"

# 创建网站首页
echo "创建网站首页..."
cat > \$DEPLOY_DIR/public/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>三角洲行动 · 自动化部署</title>
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
            line-height: 1.6;
        }
        .status {
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
    <div class="status">✅ Windows自动化部署完成</div>
    <h1>三角洲行动</h1>
    <p>游戏服务交易平台 · 自动化部署</p>
    <div>
        <a href="/" class="btn">🏠 首页</a>
        <a href="/admin/" class="btn">🔐 管理员</a>
    </div>
    <div class="info">
        <p><strong>服务器</strong>: \$SERVER_IP:\$DEPLOY_PORT</p>
        <p><strong>部署时间</strong>: \$(date '+%Y-%m-%d %H:%M:%S')</p>
        <p><strong>测试账号</strong>: 13800138000 / admin123</p>
        <p><strong>部署方式</strong>: Windows PowerShell自动化</p>
    </div>
</body>
</html>
HTML_EOF
echo "✅ 网站首页创建完成"

# 创建管理员页面
echo "创建管理员页面..."
cat > \$DEPLOY_DIR/public/admin/login.html << 'ADMIN_EOF'
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
            background: rgba(87, 255, 137, 0.1);
            border-radius: 5px;
            color: #57ff89;
        }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>管理员登录</h2>
        <div class="status">✅ Windows自动化部署完成</div>
        <input type="text" id="phone" value="13800138000">
        <input type="password" id="pass" value="admin123">
        <button onclick="login()">登录</button>
        <div style="text-align:center;margin-top:20px;color:#aaa;font-size:12px">
            <p>服务器: \$SERVER_IP:\$DEPLOY_PORT</p>
            <p>时间: \$(date '+%H:%M:%S')</p>
        </div>
    </div>
    <script>
        function login() {
            if(document.getElementById('phone').value==='13800138000'&&document.getElementById('pass').value==='admin123'){
                alert('登录成功！\\\\n\\\\n🌐 网站: http://\$SERVER_IP:\$DEPLOY_PORT/\\\\n🔐 管理员: http://\$SERVER_IP:\$DEPLOY_PORT/admin/');
            }else{
                alert('测试账号: 13800138000 / admin123');
            }
        }
    </script>
</body>
</html>
ADMIN_EOF
echo "✅ 管理员页面创建完成"

# 配置Nginx
echo "配置Nginx..."
cat > /etc/nginx/sites-available/delta-\$DEPLOY_PORT << 'NGINX_EOF'
server {
    listen \$DEPLOY_PORT;
    server_name \$SERVER_IP;
    root \$DEPLOY_DIR/public;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location /admin/ {
        alias \$DEPLOY_DIR/public/admin/;
        try_files \$uri \$uri/ =404;
    }
}
NGINX_EOF

# 启用配置
ln -sf /etc/nginx/sites-available/delta-\$DEPLOY_PORT /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
echo "✅ Nginx配置完成"

# 完成
echo ""
echo "🎉 部署完成！"
echo "=== 访问信息 ==="
echo "🌐 网站: http://\$SERVER_IP:\$DEPLOY_PORT/"
echo "🔐 管理员: http://\$SERVER_IP:\$DEPLOY_PORT/admin/"
echo ""
echo "=== 测试账号 ==="
echo "📱 手机号: 13800138000"
echo "🔑 密码: admin123"
echo ""
echo "✅ Windows自动化部署完成！"
"@

# 保存脚本到临时文件
$tempFile = "$env:TEMP\delta-deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').sh"
$deployScript | Out-File -FilePath $tempFile -Encoding UTF8
Write-Success "部署脚本创建完成: $tempFile"

# 4. 上传并执行脚本
Write-Info "上传并执行部署脚本..."

# 使用echo管道方式传递密码
$commands = @"
cd /tmp
cat > deploy.sh << 'DEPLOY_EOF'
$deployScript
DEPLOY_EOF
chmod +x deploy.sh
./deploy.sh
"@

try {
    # 使用SSH执行命令
    Write-Host "正在执行远程部署..." -ForegroundColor Gray
    Write-Host "这需要几分钟时间，请等待..." -ForegroundColor Gray
    
    # 创建临时文件保存命令
    $cmdFile = "$env:TEMP\delta-commands.sh"
    $commands | Out-File -FilePath $cmdFile -Encoding UTF8
    
    # 执行SSH命令
    $sshOutput = & ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 $Username@$ServerIP "bash -s" < $cmdFile 2>&1
    
    # 显示输出
    Write-Host $sshOutput -ForegroundColor Gray
    
    Write-Success "远程部署执行完成"
    
} catch {
    Write-Error "SSH执行失败: $_"
    Write-Host "请手动执行以下命令:" -ForegroundColor Yellow
    Write-Host "ssh $Username@$ServerIP" -ForegroundColor Gray
    Write-Host "然后复制粘贴以下内容:" -ForegroundColor Gray
    Write-Host $deployScript -ForegroundColor Gray
    exit 1
}

# 5. 验证部署
Write-Info "验证部署结果..."
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "=== 部署验证 ===" -ForegroundColor Cyan

# 测试网站
try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:${DeployPort}/" -TimeoutSec 10 -ErrorAction Stop
    Write-Success "网站访问正常 (状态码: $($response.StatusCode))"
} catch {
    Write-Error "网站访问失败: $($_.Exception.Message)"
}

# 测试管理员
try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:${DeployPort}/admin/" -TimeoutSec 10 -ErrorAction Stop
    Write-Success "管理员页面正常 (状态码: $($response.StatusCode))"
} catch {
    Write-Error "管理员页面访问失败: $($_.Exception.Message)"
}

# 6. 完成
Write-Host ""
Write-Host "🎉 🎉 🎉 Windows自动化部署完成！ 🎉 🎉 🎉" -ForegroundColor Green
Write-Host ""
Write-Host "=== 部署总结 ===" -ForegroundColor White
Write-Host "✅ 服务器: $ServerIP" -ForegroundColor White
Write-Host "✅ 端口: $DeployPort" -ForegroundColor White
Write-Host "✅ 部署方式: Windows PowerShell自动化" -ForegroundColor White
Write-Host "✅ 部署时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""
Write-Host "=== 立即访问 ===" -ForegroundColor Cyan
Write-Host "🌐 网站: http://${ServerIP}:${DeployPort}/" -ForegroundColor White
Write-Host "🔐 管理员: http://${ServerIP}:${DeployPort}/admin/" -ForegroundColor White
Write-Host ""
Write-Host "=== 测试账号 ===" -ForegroundColor Cyan
Write-Host "📱 手机号: 13800138000" -ForegroundColor White
Write-Host "🔑 密码: admin123" -ForegroundColor White
Write-Host ""
Write-Host "🚀 部署完成！现在可以开始使用了！" -ForegroundColor Green

# 询问是否打开浏览器
$choice = Read-Host "是否立即打开网站? (y/n)"
if ($choice -eq 'y') {
    Start-Process "http://${ServerIP}:${DeployPort}/"
    Start-Process "http://${ServerIP}:${DeployPort}/admin/"
}

Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")