import paramiko
import time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)

print("创建正确的server.js...")

# 正确的server.js内容
server_js = '''const express = require("express");
const cors = require("cors");
const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
    res.json({ status: "ok", service: "Delta Action API" });
});

app.post("/api/admin/login", (req, res) => {
    const { phone, password } = req.body;
    
    if (phone === "13800138000" && password === "admin123") {
        res.json({ 
            success: true, 
            message: "登录成功",
            token: "delta-token"
        });
    } else {
        res.status(401).json({ 
            success: false, 
            message: "账号或密码错误" 
        });
    }
});

app.listen(PORT, "0.0.0.0", () => {
    console.log("API服务运行在端口 " + PORT);
});'''

# 写入文件
ssh.exec_command('cd /var/www/delta-8080/public/backend && echo \'' + server_js.replace("'", "'\"'\"'") + '\' > server.js')

print("语法检查...")
stdin, stdout, stderr = ssh.exec_command("cd /var/www/delta-8080/public/backend && node -c server.js")
syntax_output = stderr.read().decode()
if "SyntaxError" in syntax_output:
    print(f"语法错误: {syntax_output[:200]}")
else:
    print("语法检查通过")

print("重启服务...")
ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 stop delta-api 2>/dev/null || true")
ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 start server.js --name delta-api")

time.sleep(2)

print("测试API...")
test_cmd = '''curl -s -X POST http://127.0.0.1:3000/api/admin/login -H "Content-Type: application/json" -d '{"phone":"13800138000","password":"admin123"}' '''
stdin, stdout, stderr = ssh.exec_command(test_cmd)
result = stdout.read().decode()

print("=" * 60)
print("API响应结果:")
print(result)
print("=" * 60)

# 检查是否包含success:true
if '"success":true' in result or '"success": true' in result:
    print("✅ 成功获取到 success: true 的 JSON")
else:
    print("❌ 未获取到 success: true")
    
    # 检查日志
    print("\n检查PM2日志...")
    stdin, stdout, stderr = ssh.exec_command("pm2 logs delta-api --lines 20")
    logs = stdout.read().decode()
    if logs:
        print("PM2日志:")
        print(logs[:500])

ssh.close()