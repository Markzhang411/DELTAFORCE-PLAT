@echo off
echo 检查Nginx配置...
echo.

echo 1. 连接到服务器检查配置...
echo 请手动执行以下SSH命令：
echo.
echo ssh root@154.64.228.29
echo 密码: ynmaFWAX7694
echo.
echo 2. 在服务器上执行：
echo.
echo # 检查配置文件
echo cat /etc/nginx/sites-enabled/delta-8080
echo.
echo # 检查网站目录
echo ls -la /var/www/delta-8080/public/
echo.
echo # 测试访问
echo curl -I http://localhost:8080/
echo.
echo 3. 如果路径不对，修改配置：
echo.
echo sudo nano /etc/nginx/sites-available/delta-8080
echo # 修改root路径为: /var/www/delta-8080/public
echo.
echo 4. 重启Nginx：
echo.
echo sudo nginx -t
echo sudo systemctl reload nginx
echo.
pause