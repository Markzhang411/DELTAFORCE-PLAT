@echo off
echo ================================================
echo  三角洲行动 · 网站状态检查
echo ================================================
echo 时间: %date% %time%
echo 服务器: 154.64.228.29
echo 端口: 8080
echo.

echo 1. 检查网络连通性...
ping -n 2 154.64.228.29 > nul
if errorlevel 1 (
    echo ❌ 无法连接到服务器
    goto :end
)
echo ✅ 服务器可访问
echo.

echo 2. 检查端口8080...
powershell -Command "Test-NetConnection -ComputerName 154.64.228.29 -Port 8080 -WarningAction SilentlyContinue | Select-Object TcpTestSucceeded | Out-String"
echo.

echo 3. 打开浏览器测试...
echo 正在打开浏览器...
start http://154.64.228.29:8080/
timeout /t 2 > nul
start http://154.64.228.29:8080/admin/
echo ✅ 浏览器已打开
echo.

echo 4. 手动测试建议：
echo   1. 查看网站是否正常显示
echo   2. 点击"管理员"按钮
echo   3. 使用测试账号登录: 13800138000 / admin123
echo   4. 测试登录功能
echo.

:end
echo ================================================
echo 检查完成
echo 按任意键退出...
pause > nul