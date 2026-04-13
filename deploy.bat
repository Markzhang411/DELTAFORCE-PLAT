@echo off
echo ================================================
echo  三角洲行动 · 一键部署工具
echo ================================================
echo 服务器: 154.64.228.29
echo 端口: 8080 (安全部署)
echo 时间: %date% %time%
echo.

echo 步骤1: 检查SSH连接...
ping -n 2 154.64.228.29 > nul
if errorlevel 1 (
    echo 错误: 无法连接到服务器
    pause
    exit /b 1
)
echo ✓ 服务器可访问
echo.

echo 步骤2: 上传部署文件...
echo 请手动执行以下命令:
echo.
echo scp deploy-safe.sh root@154.64.228.29:/root/
echo 密码: ynmaFWAX7694
echo.
echo 按任意键继续...
pause > nul
echo.

echo 步骤3: 执行远程部署...
echo 请手动执行以下命令:
echo.
echo ssh root@154.64.228.29
echo 密码: ynmaFWAX7694
echo.
echo 在服务器上执行:
echo chmod +x /root/deploy-safe.sh
echo /root/deploy-safe.sh
echo.
echo 选择: 3 (端口部署) -> 8080 -> y
echo.
echo 按任意键继续...
pause > nul
echo.

echo 步骤4: 测试部署结果...
echo 部署完成后，请访问:
echo.
echo 网站: http://154.64.228.29:8080/
echo 管理员: http://154.64.228.29:8080/admin/
echo.
echo 测试账号: 13800138000 / admin123
echo.
echo 按任意键打开浏览器测试...
pause > nul
start http://154.64.228.29:8080/
start http://154.64.228.29:8080/admin/
echo.

echo 部署完成！
pause