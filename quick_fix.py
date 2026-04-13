import paramiko
import sys

def main():
    hostname = "154.64.228.29"
    username = "root"
    password = "ynmaFWAX7694"
    
    print("Connecting...")
    
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostname=hostname, username=username, password=password, timeout=10)
        print("Connected")
        
        # Create dashboard.html
        dashboard = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>管理控制台</title>
<style>
body{font-family:Arial;background:#0f1529;color:white;margin:0}
.header{background:#16213e;padding:20px}
.stats{display:grid;grid-template-columns:repeat(2,1fr);gap:20px;padding:30px}
.stat-card{background:rgba(255,255,255,0.05);padding:20px;border-radius:10px}
table{width:100%;border-collapse:collapse}
th,td{padding:12px;border-bottom:1px solid rgba(255,255,255,0.1)}
</style>
</head>
<body>
<div class="header"><h1>三角洲行动控制台</h1></div>
<div class="stats">
<div class="stat-card"><div>CPU: 65%</div><div>3.2 GHz</div></div>
<div class="stat-card"><div>内存: 42%</div><div>6.7/16 GB</div></div>
<div class="stat-card"><div>磁盘: 78%</div><div>156/200 GB</div></div>
<div class="stat-card"><div>网络: 23%</div><div>2.3/10 TB</div></div>
</div>
<div style="padding:30px">
<h2>订单管理</h2>
<table>
<tr><th>订单号</th><th>游戏</th><th>金额</th><th>状态</th></tr>
<tr><td>#DELTA-001</td><td>使命召唤</td><td>¥299</td><td>处理中</td></tr>
<tr><td>#DELTA-002</td><td>英雄联盟</td><td>¥450</td><td>已完成</td></tr>
<tr><td>#DELTA-003</td><td>原神</td><td>¥120</td><td>待处理</td></tr>
</table>
</div>
<script>function logout(){window.location.href='login.html'}</script>
</body>
</html>'''
        
        # Write dashboard
        cmd = f"cat > /var/www/delta-8080/public/admin/dashboard.html << 'EOF'\n{dashboard}\nEOF"
        stdin, stdout, stderr = client.exec_command(cmd)
        print("Dashboard created")
        
        # Update login for redirect
        login = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>管理员登录</title>
<style>
body{font-family:Arial;background:#16213e;color:white;display:flex;justify-content:center;align-items:center;height:100vh}
.login-box{background:rgba(255,255,255,0.1);padding:40px;border-radius:15px;width:400px}
input{width:100%;padding:12px;margin:10px 0;border:1px solid #444;background:rgba(255,255,255,0.1);color:white;border-radius:5px}
button{width:100%;padding:12px;background:linear-gradient(90deg,#00dbde,#fc00ff);color:white;border:none;border-radius:5px;font-weight:bold;cursor:pointer}
</style>
</head>
<body>
<div class="login-box">
<h2>管理员登录</h2>
<input type="text" id="phone" value="13800138000">
<input type="password" id="pass" value="admin123">
<button onclick="login()">登录</button>
</div>
<script>
function login(){
var phone=document.getElementById("phone").value;
var pass=document.getElementById("pass").value;
if(phone==="13800138000"&&pass==="admin123"){
window.location.href="dashboard.html";
}else{
alert("测试账号: 13800138000 / admin123");
}
}
</script>
</body>
</html>'''
        
        cmd = f"cat > /var/www/delta-8080/public/admin/login.html << 'LOGIN'\n{login}\nLOGIN"
        stdin, stdout, stderr = client.exec_command(cmd)
        print("Login updated with redirect")
        
        # Verify
        stdin, stdout, stderr = client.exec_command("ls -la /var/www/delta-8080/public/admin/")
        print("Files:", stdout.read().decode())
        
        stdin, stdout, stderr = client.exec_command("grep -n 'window.location.href' /var/www/delta-8080/public/admin/login.html")
        print("Redirect check:", stdout.read().decode())
        
        client.close()
        print("Done")
        
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    main()