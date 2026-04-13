# ================================================
# 三角洲行动 · PowerShell自动部署脚本（修复版）
# 功能: 自动连接到VPS服务器并完成安全部署
# 运行: powershell -ExecutionPolicy Bypass -File auto-deploy-fixed.ps1
# ================================================

# 配置信息
$ServerIP = "154.64.228.29"
$Username = "root"
$Password = "ynmaFWAX7694"
$DeployPort = "8080"  # 安全部署端口

# 显示标题
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        三角洲行动 · PowerShell自动部署工具             ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "║  服务器: $ServerIP                                       ║" -ForegroundColor White
Write-Host "║  端口: $DeployPort (安全部署)                           ║" -ForegroundColor White
Write-Host "║  时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')         ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ================================================
# 1. 检查必要工具
# ================================================
Write-Host "步骤1: 检查必要工具..." -ForegroundColor Blue

# 检查SSH客户端
if (Get-Command ssh -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ SSH客户端已安装" -ForegroundColor Green
} else {
    Write-Host "  ✗ SSH客户端未安装" -ForegroundColor Red
    Write-Host "  请安装OpenSSH客户端:" -ForegroundColor Yellow
    Write-Host "    1. 打开'设置' → '应用' → '可选功能'" -ForegroundColor Gray
    Write-Host "    2. 搜索'OpenSSH客户端'并安装" -ForegroundColor Gray
    Write-Host "    或运行: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Gray
    exit 1
}

# 检查SCP
if (Get-Command scp -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ SCP客户端已安装" -ForegroundColor Green
} else {
    Write-Host "  ✗ SCP客户端未安装" -ForegroundColor Red
    exit 1
}

# ================================================
# 2. 测试服务器连接
# ================================================
Write-Host "步骤2: 测试服务器连接..." -ForegroundColor Blue

try {
    $TestConnection = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue -ErrorAction Stop
    if ($TestConnection.TcpTestSucceeded) {
        Write-Host "  ✓ 服务器SSH端口可访问" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 无法连接到服务器SSH端口" -ForegroundColor Red
        Write-Host "  请检查:" -ForegroundColor Yellow
        Write-Host "    • 服务器是否运行" -ForegroundColor Gray
        Write-Host "    • 防火墙是否允许SSH" -ForegroundColor Gray
        Write-Host "    • 网络连接是否正常" -ForegroundColor Gray
        exit 1
    }
} catch {
    Write-Host "  ✗ 连接测试失败: $_" -ForegroundColor Red
    exit 1
}

# ================================================
# 3. 准备部署文件
# ================================================
Write-Host "步骤3: 准备部署文件..." -ForegroundColor Blue

$DeployFiles = @(
    "deploy-safe.sh",
    "deploy-safe-continue.sh"
)

$MissingFiles = @()
foreach ($file in $DeployFiles) {
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (未找到)" -ForegroundColor Red
        $MissingFiles += $file
    }
}

if ($MissingFiles.Count -gt 0) {
    Write-Host "缺少必要的部署文件，请确保以下文件存在:" -ForegroundColor Red
    foreach ($file in $MissingFiles) {
        Write-Host "  • $file" -ForegroundColor Gray
    }
    exit 1
}

# ================================================
# 4. 上传文件到服务器
# ================================================
Write-Host "步骤4: 上传文件到服务器..." -ForegroundColor Blue

# 创建SSH密钥文件（避免重复输入密码）
$SSHDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $SSHDir)) {
    New-Item -ItemType Directory -Path $SSHDir -Force | Out-Null
}

# 尝试使用SSH密钥（如果存在）
$HasKey = $false
if (Test-Path "$SSHDir\id_rsa") {
    $HasKey = $true
    Write-Host "  ✓ 发现SSH密钥，尝试使用密钥认证" -ForegroundColor Green
}

$UploadSuccess = $false
$UploadAttempts = @(
    @{Method="SCP直接上传"; Command="scp `"$PSScriptRoot\deploy-safe.sh`" ${Username}@${ServerIP}:/root/"},
    @{Method="带密码SCP"; Command="echo '${Password}' | scp -o PasswordAuthentication=yes `"$PSScriptRoot\deploy-safe.sh`" ${Username}@${ServerIP}:/root/"}
)

foreach ($attempt in $UploadAttempts) {
    Write-Host "  尝试: $($attempt.Method)..." -ForegroundColor Gray
    try {
        $result = Invoke-Expression $attempt.Command 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ 上传成功" -ForegroundColor Green
            $UploadSuccess = $true
            break
        } else {
            Write-Host "  ✗ 上传失败: $result" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ✗ 上传异常: $_" -ForegroundColor Red
    }
}

if (-not $UploadSuccess) {
    Write-Host "所有上传方法都失败，请手动上传:" -ForegroundColor Yellow
    Write-Host "  1. 打开PowerShell" -ForegroundColor Gray
    Write-Host "  2. 运行: scp deploy-safe.sh root@${ServerIP}:/root/" -ForegroundColor Gray
    Write-Host "  3. 输入密码: $Password" -ForegroundColor Gray
    exit 1
}

# 上传第二个文件
try {
    scp "$PSScriptRoot\deploy-safe-continue.sh" ${Username}@${ServerIP}:/root/
    Write-Host "  ✓ 第二个文件上传成功" -ForegroundColor Green
} catch {
    Write-Host "  ⚠ 第二个文件上传失败，但继续部署..." -ForegroundColor Yellow
}

# ================================================
# 5. 执行远程部署
# ================================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║                正在连接到服务器...                      ║" -ForegroundColor Yellow
Write-Host "║  这可能需要几分钟时间，请耐心等待...                    ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

Write-Host "步骤5: 执行远程部署..." -ForegroundColor Blue

# 创建远程执行命令
$RemoteCommands = @"
#!/bin/bash
echo "=== PowerShell自动部署开始 ==="
echo "时间: \$(date)"
echo ""

# 设置文件权限
chmod +x /root/deploy-safe.sh /root/deploy-safe-continue.sh 2>/dev/null
chmod +x /root/deploy-safe.sh

# 执行部署脚本（使用expect自动应答）
echo "执行安全部署脚本..."
echo "选择部署方案: 3 (端口部署)"
echo "使用端口: $DeployPort"
echo ""

# 创建自动应答脚本
cat > /root/auto-deploy.exp << 'EOF2'
#!/usr/bin/expect -f
set timeout 300
spawn /root/deploy-safe.sh
expect "请选择方案 (1-4):"
send "3\r"
expect "请输入端口号 (默认: 8080):"
send "$DeployPort\r"
expect "是否继续部署? (y/n):"
send "y\r"
expect eof
EOF2

chmod +x /root/auto-deploy.exp
/root/auto-deploy.exp

echo ""
echo "=== 部署完成 ==="
echo "请访问: http://${ServerIP}:${DeployPort}/"
echo "管理员: http://${ServerIP}:${DeployPort}/admin/"
echo "测试账号: 13800138000 / admin123"
echo "部署时间: \$(date)"
"@

# 保存远程脚本
$RemoteScriptPath = Join-Path $env:TEMP "remote-deploy.sh"
$RemoteCommands | Out-File -FilePath $RemoteScriptPath -Encoding UTF8 -Force

# 上传并执行
try {
    Write-Host "  上传远程执行脚本..." -ForegroundColor Gray
    scp $RemoteScriptPath ${Username}@${ServerIP}:/tmp/remote-deploy.sh
    
    Write-Host "  执行远程部署..." -ForegroundColor Gray
    ssh ${Username}@${ServerIP} "bash /tmp/remote-deploy.sh"
    
    Write-Host "  ✓ 远程部署命令已发送" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 远程执行失败: $_" -ForegroundColor Red
    Write-Host "请手动执行以下命令:" -ForegroundColor Yellow
    Write-Host "  ssh root@${ServerIP}" -ForegroundColor Gray
    Write-Host "  chmod +x /root/deploy-safe.sh" -ForegroundColor Gray
    Write-Host "  /root/deploy-safe.sh" -ForegroundColor Gray
    Write-Host "  选择: 3 → ${DeployPort} → y" -ForegroundColor Gray
}

# 清理临时文件
Remove-Item $RemoteScriptPath -ErrorAction SilentlyContinue

# ================================================
# 6. 验证部署结果
# ================================================
Write-Host "步骤6: 验证部署结果..." -ForegroundColor Blue

Write-Host "等待服务启动..." -ForegroundColor Gray
Start-Sleep -Seconds 15

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    部署验证测试                         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$TestResults = @()

# 测试网站首页
Write-Host "  测试1: 网站首页" -ForegroundColor Gray
Write-Host "  URL: http://${ServerIP}:${DeployPort}/" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:${DeployPort}/" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✓ 访问正常 (状态码: $($response.StatusCode))" -ForegroundColor Green
        $TestResults += @{Test="网站首页"; Result="成功"}
    } else {
        Write-Host "  ⚠ 访问异常 (状态码: $($response.StatusCode))" -ForegroundColor Yellow
        $TestResults += @{Test="网站首页"; Result="异常"}
    }
} catch {
    Write-Host "  ✗ 访问失败: $($_.Exception.Message)" -ForegroundColor Red
    $TestResults += @{Test="网站首页"; Result="失败"}
}

Write-Host ""

# 测试管理员页面
Write-Host "  测试2: 管理员登录页面" -ForegroundColor Gray
Write-Host "  URL: http://${ServerIP}:${DeployPort}/admin/" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:${DeployPort}/admin/" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✓ 访问正常 (状态码: $($response.StatusCode))" -ForegroundColor Green
        $TestResults += @{Test="管理员页面"; Result="成功"}
    } else {
        Write-Host "  ⚠ 访问异常 (状态码: $($response.StatusCode))" -ForegroundColor Yellow
        $TestResults += @{Test="管理员页面"; Result="异常"}
    }
} catch {
    Write-Host "  ✗ 访问失败: $($_.Exception.Message)" -ForegroundColor Red
    $TestResults += @{Test="管理员页面"; Result="失败"}
}

Write-Host ""

# 测试API健康检查
Write-Host "  测试3: API健康检查" -ForegroundColor Gray
Write-Host "  URL: http://${ServerIP}:3000/api/health" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:3000/api/health" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✓ API运行正常 (状态码: $($response.StatusCode))" -ForegroundColor Green
        $TestResults += @{Test="API健康检查"; Result="成功"}
    } else {
        Write-Host "  ⚠ API异常 (状态码: $($response.StatusCode))" -ForegroundColor Yellow
        $TestResults += @{Test="API健康检查"; Result="异常"}
    }
} catch {
    Write-Host "  ✗ API访问失败: $($_.Exception.Message)" -ForegroundColor Red
    $TestResults += @{Test="API健康检查"; Result="失败"}
}

# ================================================
# 7. 生成部署报告
# ================================================
Write-Host "步骤7: 生成部署报告..." -ForegroundColor Blue

$SuccessCount = ($TestResults | Where-Object { $_.Result -eq "成功" }).Count
$TotalTests = $TestResults.Count

$Report = @"
# 三角洲行动 · 自动部署报告

## 部署信息
- **部署时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **服务器IP**: ${ServerIP}
- **部署端口**: ${DeployPort}
- **部署方式**: 安全端口部署
- **测试结果**: ${SuccessCount}/${TotalTests} 项通过

## 访问地址
- 🌐 网站首页: http://${ServerIP}:${DeployPort}/
- 🔐 管理员登录: http://${ServerIP}:${DeployPort}/admin/
- 🩺 API健康: http://${ServerIP}:3000/api/health

## 默认账号
- 📱 手机号: 13800138000
- 🔑 密码: admin123

## 测试结果
$($TestResults | ForEach-Object { "- $($_.Test): $($_.Result)" } | Out-String)

## 部署状态
$(if ($SuccessCount -eq $TotalTests) {
    "✅ 部署成功 - 所有服务可访问"
} elseif ($SuccessCount -gt 0) {
    "⚠️  部署部分成功 - ${SuccessCount}/${TotalTests} 项通过"
} else {
    "❌ 部署失败 - 所有测试都失败"
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

Write-Host "  ✓ 部署报告已保存: $ReportPath" -ForegroundColor Green

# ================================================
# 8. 完成部署
# ================================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    🎉 部署完成！                        ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "