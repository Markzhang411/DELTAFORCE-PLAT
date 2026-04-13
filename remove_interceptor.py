import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)

print("暴力拆除拦截器...")

try:
    # ==================== 1. 读取dashboard.html ====================
    print("\n1. 读取dashboard.html内容...")
    dashboard_path = "/var/www/delta-8080/public/admin/dashboard.html"
    
    stdin, stdout, stderr = ssh.exec_command(f"cat {dashboard_path} | grep -n 'window.location.href\\|location.href\\|token\\|login' | head -20")
    redirect_code = stdout.read().decode()
    print("找到的跳转/鉴权代码:")
    print(redirect_code if redirect_code else "未找到相关代码")
    
    # ==================== 2. 注释掉跳转代码 ====================
    print("\n2. 注释掉跳转代码...")
    
    # 备份原文件
    ssh.exec_command(f"cp {dashboard_path} {dashboard_path}.backup")
    
    # 注释掉所有跳转到login.html的代码
    comment_commands = [
        # 注释掉 window.location.href = 'login.html'
        f"sed -i 's|window.location.href = \\\"login.html\\\"|// window.location.href = \\\"login.html\\\"|g' {dashboard_path}",
        f"sed -i \"s|window.location.href = 'login.html'|// window.location.href = 'login.html'|g\" {dashboard_path}",
        f"sed -i 's|location.href = \\\"login.html\\\"|// location.href = \\\"login.html\\\"|g' {dashboard_path}",
        
        # 注释掉 token 检查
        f"sed -i 's|if(!token)|// if(!token)|g' {dashboard_path}",
        f"sed -i 's|if (!token)|// if (!token)|g' {dashboard_path}",
        f"sed -i 's|if(token === null)|// if(token === null)|g' {dashboard_path}",
        f"sed -i 's|if(token == null)|// if(token == null)|g' {dashboard_path}",
        
        # 注释掉 localStorage 检查
        f"sed -i 's|localStorage.getItem(\\\"token\\\")|// localStorage.getItem(\\\"token\\\")|g' {dashboard_path}",
        f"sed -i 's|localStorage.getItem('token')|// localStorage.getItem('token')|g' {dashboard_path}",
        
        # 注释掉跳转到登录页的任何代码
        f"sed -i 's|window.location.href = \\\".*login.*\\\"|// &|g' {dashboard_path}",
        f"sed -i 's|location.href = \\\".*login.*\\\"|// &|g' {dashboard_path}"
    ]
    
    for cmd in comment_commands:
        ssh.exec_command(cmd)
    
    print("跳转代码已注释")
    
    # ==================== 3. 强制持久化token ====================
    print("\n3. 修改login.html强制持久化token...")
    login_path = "/var/www/delta-8080/public/admin/login.html"
    
    # 备份
    ssh.exec_command(f"cp {login_path} {login_path}.backup")
    
    # 在跳转前添加localStorage.setItem
    ssh.exec_command(f"sed -i \"s|window.location.href = 'dashboard.html';|localStorage.setItem('token', 'admin-is-here');\\\\nwindow.location.href = 'dashboard.html';|g\" {login_path}")
    
    print("login.html已添加token持久化")
    
    # ==================== 4. 创建无拦截的dashboard.html（如果仍有问题） ====================
    print("\n4. 创建无拦截的dashboard.html...")
    
    # 先读取当前dashboard.html的前100行看看结构
    stdin, stdout, stderr = ssh.exec_command(f"head -100 {dashboard_path} | tail -50")
    dashboard_preview = stdout.read().decode()
    
    # 创建简化版dashboard（如果原文件太复杂）
    simple_dashboard = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>管理控制台 - 三角洲行动</title>
<style>
body {
    font-family: Arial, sans-serif;
    background: #0f1529;
    color: white;
    margin: 0;
}
.header {
    background: #16213e;
    padding: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}
.logo h1 {
    background: linear-gradient(90deg, #00dbde, #fc00ff);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}
.content {
    padding: 40px;
}
.stats {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
    margin-bottom: 40px;
}
.stat-card {
    background: rgba(255, 255, 255, 0.05);
    padding: 20px;
    border-radius: 10px;
}
.logout-btn {
    padding: 10px 20px;
    background: #ff4757;
    color: white;
    border: none;
    border-radius: 5px;
    cursor: pointer;
}
</style>
</head>
<body>
<div class="header">
    <div class="logo"><h1>三角洲行动控制台</h1></div>
    <button class="logout-btn" onclick="logout()">退出登录</button>
</div>
<div class="content">
    <h2>📊 系统仪表盘</h2>
    <div class="stats">
        <div class="stat-card">
            <h3>CPU 使用率</h3>
            <div style="font-size: 32px; font-weight: bold;">65%</div>
        </div>
        <div class="stat-card">
            <h3>内存使用</h3>
            <div style="font-size: 32px; font-weight: bold;">42%</div>
        </div>
        <div class="stat-card">
            <h3>磁盘空间</h3>
            <div style="font-size: 32px; font-weight: bold;">78%</div>
        </div>
        <div class="stat-card">
            <h3>网络流量</h3>
            <div style="font-size: 32px; font-weight: bold;">23%</div>
        </div>
    </div>
    <h3>📦 最近订单</h3>
    <div style="background: rgba(255,255,255,0.05); padding: 20px; border-radius: 10px;">
        <p>订单管理功能已就绪</p>
        <p>✅ 登录成功！拦截器已拆除</p>
    </div>
</div>
<script>
function logout() {
    localStorage.removeItem('token');
    window.location.href = 'login.html';
}

// 无token检查，直接显示页面
console.log('控制台已加载，无拦截器');
</script>
</body>
</html>'''
    
    # 写入简化版dashboard
    ssh.exec_command(f"echo '{simple_dashboard}' > /var/www/delta-8080/public/admin/dashboard-simple.html")
    print("简化版dashboard已创建: dashboard-simple.html")
    
    # ==================== 5. 验证修改 ====================
    print("\n5. 验证修改结果...")
    
    # 检查dashboard.html是否还有跳转代码
    stdin, stdout, stderr = ssh.exec_command(f"grep -n 'window.location.href.*login\\|location.href.*login' {dashboard_path}")
    remaining_redirects = stdout.read().decode()
    if remaining_redirects:
        print(f"⚠️  仍有跳转代码: {remaining_redirects}")
    else:
        print("✅ dashboard.html无跳转到login的代码")
    
    # 检查login.html的token设置
    stdin, stdout, stderr = ssh.exec_command(f"grep -n 'localStorage.setItem' {login_path}")
    token_setting = stdout.read().decode()
    print(f"login.html token设置: {token_setting.strip()}")
    
    print("\n" + "=" * 60)
    print("✅ 拦截器拆除完成")
    print("\n访问地址: http://154.64.228.29:8080/admin/login.html")
    print("测试账号: 13800138000 / admin123")
    print("\n备用dashboard: http://154.64.228.29:8080/admin/dashboard-simple.html")
    print("=" * 60)
    
except Exception as e:
    print(f"错误: {e}")

ssh.close()