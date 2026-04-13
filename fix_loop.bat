@echo off
echo 开始修复循环...
echo.

:loop
echo 1. 修正Nginx配置...
ssh -o PasswordAuthentication=yes -o StrictHostKeyChecking=no root@154.64.228.29 "sed -i 's|root .*|root /var/www/delta-8080/public;|g' /etc/nginx/sites-available/delta-8080 && ln -sf /etc/nginx/sites-available/delta-8080 /etc/nginx/sites-enabled/ && systemctl reload nginx"

echo 2. 验证状态...
ssh -o PasswordAuthentication=yes -o StrictHostKeyChecking=no root@154.64.228.29 "STATUS=\$(curl -o /dev/null -s -w '%{http_code}' http://127.0.0.1:8080/admin/login.html); echo 状态码: \$STATUS; if [ \$STATUS -eq 200 ]; then exit 0; else exit 1; fi"

if errorlevel 1 (
    echo ❌ 状态不是200，继续修复...
    timeout /t 2 > nul
    goto loop
) else (
    echo ✅ 状态200，修复成功！
)

echo.
echo 修复完成！
pause