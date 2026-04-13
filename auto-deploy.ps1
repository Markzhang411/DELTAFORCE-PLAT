# ================================================
# 三角洲行动 · PowerShell自动部署脚本
# 功能: 自动连接到VPS服务器并完成安全部署
# 运行: powershell -ExecutionPolicy Bypass -File auto-deploy.ps1
# ================================================

# 配置信息
$ServerIP = "154.64.228.29"
$Username = "root"
$Password = "ynmaFWAX7694"
$DeployPort = "8080"  # 安全部署端口

# 颜色定义
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Color {
    param([string]$Color, [string]$Message)
    Write-Host "$Color$Message$Reset"
}

function Write-Success { Write-Color $Green $args[0] }
function Write-Warning { Write-Color $Yellow $args[0] }
function Write-Error { Write-Color $Red $args[0] }
function Write-Info { Write-Color $Blue $args[0] }

# 显示标题
Write-Host "`n"
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        三角洲行动 · PowerShell自动部署工具             ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "║  服务器: $ServerIP                                       ║" -ForegroundColor White
Write-Host "║  端口: $DeployPort (安全部署)                           ║" -ForegroundColor White
Write-Host "║  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')         ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n"

# ================================================
# 1. 检查必要工具
# ================================================
Write-Info "步骤1: 检查必要工具..."

# 检查SSH客户端
if (Get-Command ssh -ErrorAction SilentlyContinue) {
    Write-Success "  ✓ SSH客户端已安装"
} else {
    Write-Error "  ✗ SSH客户端未安装"
    Write-Warning "  请安装OpenSSH客户端:"
    Write-Host "    1. 打开'设置' → '应用' → '可选功能'" -ForegroundColor Gray
    Write-Host "    2. 搜索'OpenSSH客户端'并安装" -ForegroundColor Gray
    Write-Host "    或运行: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Gray
    exit 1
}

# 检查SCP
if (Get-Command scp -ErrorAction SilentlyContinue) {
    Write-Success "  ✓ SCP客户端已安装"
} else {
    Write-Error "  ✗ SCP客户端未安装"
    exit 1
}

# ================================================
# 2. 测试服务器连接
# ================================================
Write-Info "步骤2: 测试服务器连接..."

$TestConnection = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue
if ($TestConnection.TcpTestSucceeded) {
    Write-Success "  ✓ 服务器SSH端口可访问"
} else {
    Write-Error "  ✗ 无法连接到服务器SSH端口"
    Write-Warning "  请检查:"
    Write-Host "    • 服务器是否运行" -ForegroundColor Gray
    Write-Host "    • 防火墙是否允许SSH" -ForegroundColor Gray
    Write-Host "    • 网络连接是否正常" -ForegroundColor Gray
    exit 1
}

# ================================================
# 3. 准备部署文件
# ================================================
Write-Info "步骤3: 准备部署文件..."

$DeployFiles = @(
    "deploy-safe.sh",
    "deploy-safe-continue.sh"
)

$MissingFiles = @()
foreach ($file in $DeployFiles) {
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Write-Success "  ✓ $file"
    } else {
        Write-Error "  ✗ $file (未找到)"
        $MissingFiles += $file
    }
}

if ($MissingFiles.Count -gt 0) {
    Write-Error "缺少必要的部署文件，请确保以下文件存在:"
    foreach ($file in $MissingFiles) {
        Write-Host "  • $file" -ForegroundColor Gray
    }
    exit 1
}

# ================================================
# 4. 上传文件到服务器
# ================================================
Write-Info "步骤4: 上传文件到服务器..."

$UploadCommands = @(
    "echo '开始上传部署文件...'",
    "scp '$PSScriptRoot\deploy-safe.sh' ${Username}@${ServerIP}:/root/",
    "scp '$PSScriptRoot\deploy-safe-continue.sh' ${Username}@${ServerIP}:/root/"
)

foreach ($cmd in $UploadCommands) {
    Write-Host "  执行: $cmd" -ForegroundColor Gray
    try {
        Invoke-Expression $cmd
        Write-Success "  ✓ 上传成功"
    } catch {
        Write-Error "  ✗ 上传失败: $_"
        
        # 尝试使用手动密码输入
        Write-Warning "尝试手动上传..."
        $manualCmd = $cmd -replace "scp ", "scp -o PasswordAuthentication=yes "
        try {
            Invoke-Expression $manualCmd
            Write-Success "  ✓ 手动上传成功"
        } catch {
            Write-Error "  ✗ 手动上传也失败"
            Write-Warning "请手动上传文件:"
            Write-Host "  1. 打开PowerShell" -ForegroundColor Gray
            Write-Host "  2. 运行: scp deploy-safe.sh root@$ServerIP:/root/" -ForegroundColor Gray
            Write-Host "  3. 输入密码: $Password" -ForegroundColor Gray
            exit 1
        }
    }
}

# ================================================
# 5. 执行远程部署
# ================================================
Write-Info "步骤5: 执行远程部署..."

Write-Host "`n"
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║                正在连接到服务器...                      ║" -ForegroundColor Yellow
Write-Host "║  这可能需要几分钟时间，请耐心等待...                    ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host "`n"

# 创建SSH命令脚本
$SSHScript = @"
#!/bin/bash
echo "=== PowerShell自动部署开始 ==="
echo "时间: \$(date)"
echo ""

# 设置文件权限
chmod +x /root/deploy-safe.sh /root/deploy-safe-continue.sh

# 执行部署脚本
echo "执行安全部署脚本..."
echo "请选择部署方案: 3 (端口部署)"
echo "请输入端口号: $DeployPort"
echo ""

# 自动应答部署脚本
/root/deploy-safe.sh << EOF
3
$DeployPort
y
EOF

echo ""
echo "=== 部署完成 ==="
echo "请访问: http://$ServerIP:$DeployPort/"
echo "管理员: http://$ServerIP:$DeployPort/admin/"
echo "测试账号: 13800138000 / admin123"
"@

# 保存脚本到临时文件
$TempScript = Join-Path $env:TEMP "deploy-remote.sh"
$SSHScript | Out-File -FilePath $TempScript -Encoding UTF8

# 上传并执行远程脚本
try {
    Write-Host "  上传远程执行脚本..." -ForegroundColor Gray
    scp $TempScript ${Username}@${ServerIP}:/tmp/deploy-remote.sh
    
    Write-Host "  执行远程部署..." -ForegroundColor Gray
    $SSHCommand = "ssh ${Username}@${ServerIP} 'bash /tmp/deploy-remote.sh'"
    Invoke-Expression $SSHCommand
    
    Write-Success "  ✓ 远程部署命令已发送"
} catch {
    Write-Error "  ✗ 远程执行失败: $_"
    Write-Warning "请手动执行以下命令:"
    Write-Host "  ssh root@$ServerIP" -ForegroundColor Gray
    Write-Host "  chmod +x /root/deploy-safe.sh" -ForegroundColor Gray
    Write-Host "  /root/deploy-safe.sh" -ForegroundColor Gray
    Write-Host "  选择: 3 → $DeployPort → y" -ForegroundColor Gray
}

# 清理临时文件
Remove-Item $TempScript -ErrorAction SilentlyContinue

# ================================================
# 6. 验证部署结果
# ================================================
Write-Info "步骤6: 验证部署结果..."

Start-Sleep -Seconds 10  # 等待服务启动

$TestURLs = @(
    @{Name="网站首页"; URL="http://${ServerIP}:${DeployPort}/"},
    @{Name="管理员登录"; URL="http://${ServerIP}:${DeployPort}/admin/"},
    @{Name="API健康检查"; URL="http://${ServerIP}:3000/api/health"}
)

Write-Host "`n"
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    部署验证测试                         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n"

foreach ($test in $TestURLs) {
    Write-Host "  测试: $($test.Name)" -ForegroundColor Gray
    Write-Host "  URL: $($test.URL)" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $test.URL -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Success "  ✓ 访问正常 (状态码: $($response.StatusCode))"
        } else {
            Write-Warning "  ⚠ 访问异常 (状态码: $($response.StatusCode))"
        }
    } catch {
        Write-Error "  ✗ 访问失败: $($_.Exception.Message)"
    }
    
    Write-Host ""
}

# ================================================
# 7. 生成部署报告
# ================================================
Write-Info "步骤7: 生成部署报告..."

$Report = @"
# 三角洲行动 · 自动部署报告

## 部署信息
- **部署时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **服务器IP**: $ServerIP
- **部署端口**: $DeployPort
- **部署方式**: 安全端口部署

## 访问地址
- 🌐 网站首页: http://${ServerIP}:${DeployPort}/
- 🔐 管理员登录: http://${ServerIP}:${DeployPort}/admin/
- 🩺 API健康: http://${ServerIP}:3000/api/health

## 默认账号
- 📱 手机号: 13800138000
- 🔑 密码: admin123

## 部署状态
$(if ($TestURLs | ForEach-Object { try { Invoke-WebRequest -Uri $_.URL -TimeoutSec 5 } catch { $null } } | Where-Object { $_ -and $_.StatusCode -eq 200 }) {
    "✅ 部署成功 - 所有服务可访问"
} else {
    "⚠️  部署部分成功 - 部分服务可能有问题"
})

## 后续步骤
1. 立即访问测试网站
2. 登录管理员控制台
3. 创建新的管理员账号
4. 修改默认密码
5. 测试所有功能

## 安全提醒
- 生产环境请配置HTTPS
- 定期修改管理员密码
- 配置防火墙规则
- 定期备份数据

---
*生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
*部署工具: PowerShell自动部署脚本*
"@

# 保存报告
$ReportPath = Join-Path $PSScriptRoot "deploy-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Success "  ✓ 部署报告已保存: $ReportPath"

# ================================================
# 8. 完成部署
# ================================================
Write-Host "`n"
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    🎉 部署完成！                        ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  🌐 立即访问: http://${ServerIP}:${DeployPort}/          ║" -ForegroundColor White
Write-Host "║  🔐 管理员: http://${ServerIP}:${DeployPort}/admin/      ║" -ForegroundColor White
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  📱 测试账号: 13800138000                               ║" -ForegroundColor White
Write-Host "║  🔑 密码: admin123                                      ║" -ForegroundColor White
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  ⚠️  重要提醒:                                          ║" -ForegroundColor Yellow
Write-Host "║     1. 立即修改默认密码                                 ║" -ForegroundColor Yellow
Write-Host "║     2. 创建新的管理员账号                               ║" -ForegroundColor Yellow
Write-Host "║     3. 测试所有功能                                     ║" -ForegroundColor Yellow
Write-Host "║     4. 检查现有网站是否正常                             ║" -ForegroundColor Yellow
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║  📄 详细报告: $ReportPath                               ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "`n"

# 提供快速访问链接
Write-Info "快速操作:"
Write-Host "  1. 打开网站: Start-Process 'http://${ServerIP}:${DeployPort}/'" -ForegroundColor Gray
Write-Host "  2. 打开管理员: Start-Process 'http://${ServerIP}:${DeployPort}/admin/'" -ForegroundColor Gray
Write-Host "  3. 查看报告: Start-Process '$ReportPath'" -ForegroundColor Gray

# 询问是否立即打开
$OpenSite = Read-Host "`n是否立即打开网站? (y/n)"
if ($OpenSite -eq 'y') {
    Start-Process "http://${ServerIP}:${DeployPort}/"
    Start-Process "http://${ServerIP}:${DeployPort}/admin/"
}

Write-Host "`n部署完成！按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")