#!/usr/bin/env python3
"""
Create admin dashboard and update login logic - FINAL
"""

import subprocess
import sys

def install_paramiko():
    """Install paramiko if needed"""
    try:
        import paramiko
        return True
    except ImportError:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "paramiko"], 
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        except:
            return False

def execute_ssh_command(client, cmd):
    """Execute SSH command and return output"""
    stdin, stdout, stderr = client.exec_command(cmd)
    exit_code = stdout.channel.recv_exit_status()
    output = stdout.read().decode().strip()
    error = stderr.read().decode().strip()
    return exit_code, output, error

def create_dashboard():
    """Create dashboard.html and update login.html"""
    
    hostname = "154.64.228.29"
    username = "root"
    password = "ynmaFWAX7694"
    
    print("Connecting to server...")
    
    try:
        import paramiko
        
        # Connect
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostname=hostname, username=username, password=password, timeout=10)
        print("Connected")
        
        # ==================== CREATE DASHBOARD.HTML ====================
        print("\n1. Creating dashboard.html...")
        
        # Simple dashboard HTML
        dashboard_html = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>管理控制台 - 三角洲行动</title>
<style>
body{font-family:Arial;background:#0f1529;color:white;margin:0}
.header{background:#16213e;padding:20px;display:flex;justify-content:space-between}
.logo h1{background:linear-gradient(90deg,#00dbde,#fc00ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.stats{display:grid;grid-template-columns:repeat(2,1fr);gap:20px;padding:30px}
.stat-card{background:rgba(255,255,255,0.05);padding:20px;border-radius:10px}
.stat-value{font-size:32px;font-weight:bold}
.progress-bar{height:10px;background:rgba(255,255,255,0.1);border-radius:5px;margin-top:10px}
.progress-fill{height:100%;border-radius:5px}
.cpu-progress{background:#00dbde;width:65%}
.mem-progress{background:#ffcc00;width:42%}
.orders{padding:30px}
table{width:100%;border-collapse:collapse}
th,td{padding:12px;text-align:left;border-bottom:1px solid rgba(255,255,255,0.1)}
</style>
</head>
<body>
<div class="header">
<div class="logo"><h1>三角洲行动控制台</h1></div>
<div><button onclick="logout()" style="padding:10px 20px;background:#ff4757;color:white;border:none;border-radius:5px">退出</button></div>
</div>

<div class="stats">
<div class="stat-card">
<div>CPU 使用率</div>
<div class="stat-value">65%</div>
<div>3.2 GHz · 8核心</div>
<div class="progress-bar"><div class="progress-fill cpu-progress"></div></div>
</div>
<div class="stat-card">
<div>内存使用</div>
<div class="stat-value">42%</div>
<div>6.7 GB / 16 GB</div>
<div class="progress-bar"><div class="progress-fill mem-progress"></div></div>
</div>
<div class="stat-card">
<div>磁盘空间</div>
<div class="stat-value">78%</div>
<div>156 GB / 200 GB</div>
<div class="progress-bar"><div class="progress-fill" style="background:#57ff89;width:78%"></div></div>
</div>
<div class="stat-card">
<div>网络流量</div>
<div class="stat-value">23%</div>
<div>2.3 TB / 10 TB</div>
<div class="progress-bar"><div class="progress-fill" style="background:#9d4edd;width:23%"></div></div>
</div>
</div>

<div class="orders">
<h2>📦 订单管理</h2>
<table>
<tr><th>订单号</th><th>游戏</th><th>金额</th><th>状态</th><th>操作</th></tr>
<tr><td>#DELTA-001</td><td>使命召唤</td><td>¥299</td><td><span style="color:#00dbde">处理中</span></td><td><button>查看</button></td></tr>
<tr><td>#DELTA-002</td><td>英雄联盟</td><td>¥450</td><td><span style="color:#57ff89">已完成</span></td><td><button>查看</button></td></tr>
<tr><td>#DELTA-003</td><td>原神</td><td>¥120</td><td><span style="color:#ffcc00">待处理</span></td><td><button>查看</button></td></tr>
<tr><td>#DELTA-004</td><td>APEX英雄</td><td>¥380</td><td><span style="color:#00dbde">处理中</span></td><td><button>查看</button></td></tr>
<tr><td>#DELTA-005</td><td>永劫无间</td><td>¥560</td><td><span style="color:#ff4757">已取消</span></td><td><button>查看</button></td></tr>
</table>
</div>

<script>
function logout(){
if(confirm('退出登录？')) window.location.href='login.html';
}
</script>
</body>
</html>'''
        
        # Write dashboard.html
        cmd = f"cat > /var/www/delta-8080/public/admin/dashboard.html << 'EOF'\n{dashboard_html}\nEOF"
        exit_code, output, error = execute_ssh_command(client, cmd)
        if exit_code == 0:
            print("✅ dashboard.html created")
        else:
            print(f"❌ Failed to create dashboard: {error}")
        
        # ==================== UPDATE LOGIN.HTML ====================
        print("\n2. Updating login.html for redirect...")
        
        # Create new login.html with redirect logic
        login_html = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>管理员登录 - 三角洲行动</title>
<style>
body{font-family:Arial;background:#16213e;color:white;display:flex;justify-content:center;align-items:center;height:100vh;margin:0}
.login-box{background:rgba(255,255,255,0.1);padding:40px;border-radius:15px;width:400px}
h2{color:#00dbde;text-align:center}
input{width:100%;padding:12px;margin:10px 0;border:1px solid #444;background:rgba(255,255,255,0.1);color:white;border-radius:5px}
button{width:100%;padding:12px;background:linear-gradient(90deg,#00dbde,#fc00ff);color:white;border:none;border-radius:5px;font-weight:bold;cursor:pointer}
.status{text-align:center;margin-top:20px;padding:10px;background:rgba(0,255,0,0.1);border-radius:5px;color:#0f0}
</style>
</head>
<body>
<div class="login-box">
<h2>管理员登录</h2>
<div class="status">✅ Python SSH 自动部署</div>
<input type="text" id="phone" placeholder="手机号" value="13800138000">
<input type="password" id="pass" placeholder="密码" value="admin123">
<button onclick="login()">🔐 登录管理控制台</button>
<div style="text-align:center;margin-top:20px;color:#aaa;font-size:12px">
<p>三角洲行动 · 护航接单平台</p>
</div>
</div>
<script>
function login(){
var phone=document.getElementById("phone").value;
var pass=document.getElementById("pass").value;
var btn=document.querySelector("button");
btn.disabled=true;
btn.textContent="登录中...";
setTimeout(function(){
if(phone==="13800138000"&&pass==="admin123"){
// 跳转到控制台
window.location.href="dashboard.html";
}else{
alert("❌ 登录失败\\n测试账号: 13800138000 / admin123");
btn.disabled=false;
btn.textContent="🔐 登录管理控制台";
}
},800);
}
</script>
</body>
</html>'''
        
        # Write updated login.html
        cmd = f"cat > /var/www/delta-8080/public/admin/login.html << 'LOGIN_EOF'\n{login_html}\nLOGIN_EOF"
        exit_code, output, error = execute_ssh_command(client, cmd)
        if exit_code == 0:
            print("✅ login.html updated with redirect")
        else:
            print(f"❌ Failed to update login: {error}")
        
        # ==================== VERIFY FILES ====================
        print("\n3. Verifying files...")
        
        # Check dashboard.html
        exit_code, output, error = execute_ssh_command(client, "head -5 /var/www/delta-8080/public/admin/dashboard.html")
        print(f"Dashboard preview: {output[:100]}...")
        
        # Check login.html redirect logic
        exit_code, output, error = execute_ssh_command(client, "grep -n 'window.location.href' /var/www/delta-8080/public/admin/login.html")
        print(f"Redirect found at line: {output}")
        
        # Check file sizes
        exit_code, output, error = execute_ssh_command(client, "wc -l /var/www/delta-8080/public/admin/*.html")
        print(f"File line counts:\\n{output}")
        
        # Set permissions
        execute_ssh_command(client, "chown -R www-data:www-data /var/www/delta-8080")
        execute_ssh_command(client, "chmod -R 755 /var/www/delta-8080")
        
        # Restart nginx
        print("\n4. Restarting Nginx...")
        execute_ssh_command(client, "systemctl reload nginx")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    finally:
        try:
            client.close()
        except:
            pass

def main():
    print("Creating admin dashboard and updating login...")
    print("=" * 60)
    
    if not install_paramiko():
        print("Failed to install paramiko")
        sys.exit(1)
    
    if create_dashboard():
        print("\n" + "=" * 60)
        print("✅ DASHBOARD CREATED SUCCESSFULLY")
        print("Login URL: http://154.64.228.29:8080/admin/")
        print("Dashboard URL: http://154.64.228.29:8080/admin/dashboard.html")
        print("Test: 13800138000 / admin123")
        print("\\nLogin now redirects to dashboard on successful authentication!")
    else:
        print("\\n❌ Failed to create dashboard")
        sys.exit(1)

if __name__ == "__main__":
    main()