# ================================================
# 三角洲行动 · PowerShell自动部署脚本
# 简化版 - 直接执行部署
# ================================================

# 配置信息
$ServerIP = "154.64.228.29"
$Username = "root"
$Password = "ynmaFWAX7694"
$DeployPort = "8080"

Write-Host ""
Write-Host "三角洲行动 · 自动部署开始" -ForegroundColor Cyan
Write-Host "服务器: $ServerIP" -ForegroundColor White
Write-Host "端口: $DeployPort" -ForegroundColor White
Write-Host "时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor White
Write-Host ""

# 1. 检查工具
Write-Host "1. 检查工具..." -ForegroundColor Blue
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "错误: SSH客户端未安装" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ SSH客户端已安装" -ForegroundColor Green

# 2. 测试连接
Write-Host "2. 测试连接..." -ForegroundColor Blue
try {
    Test-NetConnection -ComputerName $ServerIP -Port 22 | Out-Null
    Write-Host "  ✓ 服务器可连接" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 连接失败" -ForegroundColor Red
    exit 1
}

# 3. 上传文件
Write-Host "3. 上传部署文件..." -ForegroundColor Blue
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 上传第一个文件
try {
    $cmd = "scp `"$ScriptDir\deploy-safe.sh`" ${Username}@${ServerIP}:/root/"
    Invoke-Expression $cmd
    Write-Host "  ✓ deploy-safe.sh 上传成功" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 上传失败，请手动上传" -ForegroundColor Red
    Write-Host "  命令: scp deploy-safe.sh root@${ServerIP}:/root/" -ForegroundColor Gray
    Write-Host "  密码: $Password" -ForegroundColor Gray
    exit 1
}

# 上传第二个文件
try {
    scp "$ScriptDir\deploy-safe-continue.sh" ${Username}@${ServerIP}:/root/
    Write-Host "  ✓ deploy-safe-continue.sh 上传成功" -ForegroundColor Green
} catch {
    Write-Host "  ⚠ 第二个文件上传失败，继续..." -ForegroundColor Yellow
}

# 4. 执行远程部署
Write-Host ""
Write-Host "4. 执行远程部署..." -ForegroundColor Blue
Write-Host "  这需要几分钟，请等待..." -ForegroundColor Gray

# 创建远程命令
$RemoteCmd = @"
#!/bin/bash
echo "开始部署三角洲行动..."
chmod +x /root/deploy-safe.sh

# 创建自动应答脚本
cat > /root/auto-deploy.sh << 'EOF'
#!/bin/bash
echo "3"       # 选择端口部署
echo "$DeployPort"  # 输入端口
echo "y"       # 确认部署
EOF

chmod +x /root/auto-deploy.sh
cat /root/auto-deploy.sh | /root/deploy-safe.sh

echo ""
echo "部署完成!"
echo "访问地址: http://${ServerIP}:${DeployPort}/"
echo "管理员: http://${ServerIP}:${DeployPort}/admin/"
echo "账号: 13800138000 / admin123"
"@

# 保存并上传远程命令
$TempFile = "$env:TEMP\remote-cmd.sh"
$RemoteCmd | Out-File $TempFile -Encoding UTF8

try {
    scp $TempFile ${Username}@${ServerIP}:/tmp/remote-cmd.sh
    ssh ${Username}@${ServerIP} "bash /tmp/remote-cmd.sh"
    Write-Host "  ✓ 远程部署执行完成" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 远程执行失败" -ForegroundColor Red
    Write-Host "请手动执行:" -ForegroundColor Yellow
    Write-Host "  ssh root@${ServerIP}" -ForegroundColor Gray
    Write-Host "  chmod +x /root/deploy-safe.sh" -ForegroundColor Gray
    Write-Host "  /root/deploy-safe.sh" -ForegroundColor Gray
    Write-Host "  选择: 3 → ${DeployPort} → y" -ForegroundColor Gray
}

# 5. 等待并测试
Write-Host ""
Write-Host "5. 等待服务启动..." -ForegroundColor Blue
Start-Sleep -Seconds 20

Write-Host ""
Write-Host "6. 测试部署结果..." -ForegroundColor Blue

# 测试网站
Write-Host "  测试网站..." -ForegroundColor Gray
try {
    $web = Invoke-WebRequest -Uri "http://${ServerIP}:${DeployPort}/" -TimeoutSec 10
    Write-Host "  ✓ 网站可访问 (状态: $($web.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 网站访问失败" -ForegroundColor Red
}

# 测试管理员
Write-Host "  测试管理员页面..." -ForegroundColor Gray
try {
    $admin = Invoke-WebRequest -Uri "http://${ServerIP}:${DeployPort}/admin/" -TimeoutSec 10
    Write-Host "  ✓ 管理员页面可访问 (状态: $($admin.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 管理员页面访问失败" -ForegroundColor Red
}

# 6. 完成
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    🎉 部署完成！                        ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  🌐 网站: http://${ServerIP}:${DeployPort}/              ║" -ForegroundColor White
Write-Host "║  🔐 管理员: http://${ServerIP}:${DeployPort}/admin/      ║" -ForegroundColor White
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  📱 测试账号: 13800138000                               ║" -ForegroundColor White
Write-Host "║  🔑 密码: admin123                                      ║" -ForegroundColor White
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  ⚠️  下一步:                                            ║" -ForegroundColor Yellow
Write-Host "║     1. 立即访问测试                                     ║" -ForegroundColor Yellow
Write-Host "║     2. 登录管理员控制台                                 ║" -ForegroundColor Yellow
Write-Host "║     3. 修改默认密码                                     ║" -ForegroundColor Yellow
Write-Host "║     4. 创建新的管理员账号                               ║" -ForegroundColor Yellow
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# 询问是否打开浏览器
$choice = Read-Host "是否立即打开网站? (y/n)"
if ($choice -eq 'y') {
    Start-Process "http://${ServerIP}:${DeployPort}/"
    Start-Process "http://${ServerIP}:${DeployPort}/admin/"
}

Write-Host "部署完成！按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")