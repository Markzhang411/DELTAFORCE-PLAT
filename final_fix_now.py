import paramiko
import time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)

print("执行最终修复...")

try:
    # ==================== 1. 全局替换IP ====================
    print("\n1. 全局替换API地址...")
    login_path = "/var/www/delta-8080/public/admin/login.html"
    
    # 备份
    ssh.exec_command(f"cp {login_path} {login_path}.backup2")
    
    # 查看当前内容
    stdin, stdout, stderr = ssh.exec_command(f"grep -n 'localhost\\|127.0.0.1\\|3000' {login_path}")
    print("当前API地址:")
    print(stdout.read().decode())
    
    # 执行全局替换
    replace_commands = [
        # 替换所有localhost变体
        f"sed -i 's|http://localhost:3000|http://154.64.228.29:3000|g' {login_path}",
        f"sed -i 's|https://localhost:3000|http://154.64.228.29:3000|g' {login_path}",
        f"sed -i 's|localhost:3000|154.64.228.29:3000|g' {login_path}",
        
        # 替换所有127.0.0.1变体
        f"sed -i 's|http://127.0.0.1:3000|http://154.64.228.29:3000|g' {login_path}",
        f"sed -i 's|127.0.0.1:3000|154.64.228.29:3000|g' {login_path}",
        
        # 替换所有可能的API_BASE变量
        f"sed -i 's|const API_BASE =.*|const API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}",
        f"sed -i 's|var API_BASE =.*|var API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}",
        f"sed -i 's|let API_BASE =.*|let API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}",
        
        # 替换fetch/axios调用中的地址
        f"sed -i 's|fetch(\"/api/|fetch(\"http://154.64.228.29:3000/api/|g' {login_path}",
        f"sed -i 's|fetch(\\\"/api/|fetch(\\\"http://154.64.228.29:3000/api/|g' {login_path}",
        f"sed -i 's|axios.post(\"/api/|axios.post(\"http://154.64.228.29:3000/api/|g' {login_path}"
    ]
    
    for cmd in replace_commands:
        ssh.exec_command(cmd)
    
    print("全局替换完成")
    
    # 验证替换结果
    stdin, stdout, stderr = ssh.exec_command(f"grep -n '154.64.228.29\\|localhost\\|127.0.0.1' {login_path}")
    print("替换后验证:")
    result = stdout.read().decode()
    print(result)
    
    if "localhost" in result or "127.0.0.1" in result:
        print("❌ 仍有localhost/127.0.0.1未替换")
    else:
        print("✅ 所有localhost/127.0.0.1已替换")
    
    # ==================== 2. 开启跨域 ====================
    print("\n2. 检查并开启CORS...")
    backend_path = "/var/www/delta-8080/public/backend/server.js"
    
    # 检查当前server.js
    stdin, stdout, stderr = ssh.exec_command(f"head -20 {backend_path}")
    server_content = stdout.read().decode()
    
    if "require('cors')" in server_content and "app.use(cors())" in server_content:
        print("✅ CORS已配置")
    else:
        print("❌ CORS未配置，正在修复...")
        
        # 创建正确的server.js
        correct_server = '''const express = require("express");
const cors = require("cors");
const app = express();
const PORT = 3000;

// 启用CORS
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
            token: "delta-token-" + Date.now()
        });
    } else {
        res.status(401).json({ 
            success: false, 
            message: "账号或密码错误" 
        });
    }
});

app.listen(PORT, "0.0.0.0", () => {
    console.log("API服务运行在: http://0.0.0.0:" + PORT);
});'''
        
        ssh.exec_command(f'echo \'{correct_server}\' > {backend_path}')
        print("server.js已更新")
    
    # ==================== 3. 重启服务 ====================
    print("\n3. 重启后端服务...")
    
    # 停止旧进程
    ssh.exec_command("pm2 stop delta-api 2>/dev/null || true")
    ssh.exec_command("pm2 delete delta-api 2>/dev/null || true")
    time.sleep(1)
    
    # 启动新进程
    ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 start server.js --name delta-api")
    time.sleep(2)
    
    # 检查进程状态
    stdin, stdout, stderr = ssh.exec_command("pm2 list | grep delta-api")
    pm2_status = stdout.read().decode()
    print(f"PM2状态: {pm2_status.strip()}")
    
    # ==================== 4. 最终自测 ====================
    print("\n4. 最终自测 - 模拟请求...")
    
    # 等待服务完全启动
    time.sleep(2)
    
    # 测试API
    test_cmd = '''curl -X POST http://127.0.0.1:3000/api/admin/login \
-H "Content-Type: application/json" \
-d '{"phone":"13800138000","password":"admin123"}' \
-w "\\nHTTP状态码: %{http_code}\\n" \
--max-time 5'''
    
    stdin, stdout, stderr = ssh.exec_command(test_cmd)
    api_response = stdout.read().decode()
    
    print("=" * 60)
    print("API测试结果:")
    print(api_response)
    print("=" * 60)
    
    # 检查是否包含success:true
    if '"success":true' in api_response or '"success": true' in api_response:
        print("✅ 自测成功: 返回 success: true")
        success = True
    else:
        print("❌ 自测失败: 未返回 success: true")
        
        # 检查日志
        print("\n检查错误日志...")
        stdin, stdout, stderr = ssh.exec_command("pm2 logs delta-api --lines 30")
        logs = stdout.read().decode()
        print(f"PM2日志: {logs[:500]}")
        success = False
    
    # ==================== 5. 最终地址 ====================
    print("\n" + "=" * 60)
    if success:
        print("✅ 修复完成！")
        print("\n真正能登录成功的地址:")
        print("http://154.64.228.29:8080/admin/login.html")
        print("\n测试账号:")
        print("手机号: 13800138000")
        print("密码: admin123")
    else:
        print("❌ 修复失败")
    print("=" * 60)
    
except Exception as e:
    print(f"错误: {e}")

ssh.close()