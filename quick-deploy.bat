@echo off
echo ================================================
echo  三角洲行动 · 快速部署工具
echo ================================================
echo.
echo 注意：请确保已经通过SSH连接到服务器
echo 服务器: 154.64.228.29
echo 端口: 8080
echo.
echo 如果你已经在SSH会话中，请：
echo 1. 切换到SSH窗口
echo 2. 复制下面的命令
echo 3. 粘贴并执行
echo.
echo ================================================
echo 部署命令：
echo.
echo # 一键部署命令（复制全部）：
echo DEPLOY_DIR="/var/www/delta-8080" && mkdir -p $DEPLOY_DIR/public/{css,js,admin} && chown -R www-data:www-data $DEPLOY_DIR && chmod -R 755 $DEPLOY_DIR && cat > $DEPLOY_DIR/public/index.html << 'EOF'
echo ^<!DOCTYPE html^>
echo ^<html^>
echo ^<head^>^<title^>三角洲行动^</title^>
echo ^<style^>
echo body{font-family:Arial;background:#1a1a2e;color:white;text-align:center;padding:50px}
echo h1{color:#00dbde;font-size:48px}
echo .btn{display:inline-block;padding:15px 30px;margin:10px;background:linear-gradient(90deg,#00dbde,#fc00ff);color:white;text-decoration:none;border-radius:10px;font-weight:bold}
echo .info{margin-top:40px;color:#aaa}
echo ^</style^>
echo ^</head^>
echo ^<body^>
echo ^<h1^>三角洲行动^</h1^>
echo ^<p^>游戏服务交易平台 · 部署成功^</p^>
echo ^<a href="/" class="btn"^>🏠 首页^</a^>
echo ^<a href="/admin/" class="btn"^>🔐 管理员^</a^>
echo ^<div class="info"^>
echo ^<p^>服务器: 154.64.228.29:8080^</p^>
echo ^<p^>时间: $(date)^</p^>
echo ^<p^>测试账号: 13800138000 / admin123^</p^>
echo ^</div^>
echo ^</body^>
echo ^</html^>
echo EOF
echo && cat > $DEPLOY_DIR/public/admin/login.html << 'EOF'
echo ^<!DOCTYPE html^>
echo ^<html^>
echo ^<head^>^<title^>管理员登录^</title^>
echo ^<style^>
echo body{font-family:Arial;background:#1a1a2e;color:white;display:flex;justify-content:center;align-items:center;height:100vh;margin:0}
echo .login-box{background:rgba(255,255,255,0.1);padding:40px;border-radius:15px;width:400px}
echo h2{color:#00dbde;text-align:center}
echo input{width:100%;padding:12px;margin:10px 0;border:1px solid #444;background:rgba(255,255,255,0.1);color:white;border-radius:5px}
echo button{width:100%;padding:12px;background:linear-gradient(90deg,#00dbde,#fc00ff);color:white;border:none;border-radius:5px;font-weight:bold;cursor:pointer}
echo .status{text-align:center;margin-top:20px;padding:10px;background:rgba(0,255,0,0.1);border-radius:5px;color:#0f0}
echo ^</style^>
echo ^</head^>
echo ^<body^>
echo ^<div class="login-box"^>
echo ^<h2^>管理员登录^</h2^>
echo ^<div class="status"^>✅ 部署完成^</div^>
echo ^<input type="text" id="phone" value="13800138000"^>
echo ^<input type="password" id="pass" value="admin123"^>
echo ^<button onclick="login()"^>登录^</button^>
echo ^<div style="text-align:center;margin-top:20px;color:#aaa;font-size:12px"^>
echo ^<p^>三角洲行动 · 快速部署^</p^>
echo ^</div^>
echo ^</div^>
echo ^<script^>
echo function login(){
echo if(document.getElementById('phone').value==='13800138000'&&document.getElementById('pass').value==='admin123'){
echo alert('登录成功！\\\\n\\\\n🌐 网站: http://154.64.228.29:8080/\\\\n🔐 管理员: http://154.64.228.29:8080/admin/');
echo }else{alert('测试账号: 13800138000 / admin123')}
echo }
echo ^</script^>
echo ^</body^>
echo ^</html^>
echo EOF
echo && cat > /etc/nginx/sites-available/delta-8080 << 'EOF'
echo server {
echo     listen 8080;
echo     server_name 154.64.228.29;
echo     root /var/www/delta-8080/public;
echo     index index.html;
echo     location / { try_files $uri $uri/ =404; }
echo     location /admin/ { alias /var/www/delta-8080/public/admin/; try_files $uri $uri/ =404; }
echo }
echo EOF
echo && ln -sf /etc/nginx/sites-available/delta-8080 /etc/nginx/sites-enabled/ && nginx -t && systemctl reload nginx && echo "✅ 部署完成！访问: http://154.64.228.29:8080/"
echo.
echo ================================================
echo.
echo 或者使用简化版命令：
echo.
echo # 简化部署命令：
echo DEPLOY_DIR="/var/www/delta-8080"
echo mkdir -p $DEPLOY_DIR/public/{css,js,admin}
echo chown -R www-data:www-data $DEPLOY_DIR
echo chmod -R 755 $DEPLOY_DIR
echo echo "部署完成！"
echo echo "访问: http://154.64.228.29:8080/"
echo.
echo ================================================
echo.
echo 按任意键退出...
pause > nul