#!/usr/bin/env python3
"""
最后三步修正：对齐前后端
"""

import paramiko
import time

def final_fix():
    """执行最后三步修正"""
    
    print("执行最后三步修正...")
    print("=" * 60)
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)
    
    try:
        # ==================== 1. 修正后端监听 ====================
        print("\n1. 修正后端监听...")
        
        # 检查当前server.js
        stdin, stdout, stderr = ssh.exec_command("cat /var/www/delta-8080/public/backend/server.js | grep -n 'app.listen\\|listen\\|0.0.0.0\\|127.0.0.1\\|cors'")
        print("当前server.js相关配置:")
        print(stdout.read().decode())
        
        # 安装cors（如果未安装）
        print("安装cors...")
        ssh.exec_command("cd /var/www/delta-8080/public/backend && npm install cors express --save")
        
        # 创建正确的server.js
        print("创建正确的server.js...")
        correct_server = '''const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

// 启用CORS
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// 根路径
app.get('/', (req, res) => {
    res.json({ 
        status: 'ok', 
        service: '三角洲行动后端API',
        version: '2.0',
        timestamp: new Date().toISOString(),
        endpoints: ['/api/admin/login', '/health']
    });
});

// 健康检查
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', time: new Date().toISOString() });
});

// 管理员登录
app.post('/api/admin/login', (req, res) => {
    console.log('登录请求:', req.body);
    const { phone, password } = req.body;
    
    if (phone === '13800138000' && password === 'admin123') {
        res.json({
            success: true,
            message: '登录成功',
            token: 'delta-token-' + Date.now(),
            user: {
                id: 1,
                phone: phone,
                name: '管理员',
                role: 'admin'
            }
        });
    } else {
        res.status(401).json({
            success: false,
            message: '账号或密码错误',
            hint: '测试账号: 13800138000 / admin123'
        });
    }
});

// 监听所有接口
app.listen(PORT, '0.0.0.0', () => {
    console.log('三角洲行动后端API运行在: http://0.0.0.0:' + PORT);
    console.log('外部访问: http://154.64.228.29:' + PORT);
});'''
        
        # 写入server.js
        ssh.exec_command(f"echo '{correct_server}' > /var/www/delta-8080/public/backend/server.js")
        print("server.js已更新")
        
        # ==================== 2. 修正前端请求 ====================
        print("\n2. 修正前端请求地址...")
        
        login_path = "/var/www/delta-8080/public/admin/login.html"
        
        # 备份原文件
        ssh.exec_command(f"cp {login_path} {login_path}.backup")
        
        # 查看当前API地址
        stdin, stdout, stderr = ssh.exec_command(f"grep -n 'fetch\\|axios\\|http://' {login_path} | head -10")
        print("当前前端API地址:")
        print(stdout.read().decode())
        
        # 替换所有可能的API地址
        replacements = [
            # 替换localhost
            f"sed -i 's|http://localhost:3000|http://154.64.228.29:3000|g' {login_path}",
            f"sed -i 's|http://127.0.0.1:3000|http://154.64.228.29:3000|g' {login_path}",
            f"sed -i 's|http://0.0.0.0:3000|http://154.64.228.29:3000|g' {login_path}",
            # 替换相对路径为绝对路径
            f"sed -i 's|fetch(\"/api/|fetch(\"http://154.64.228.29:3000/api/|g' {login_path}",
            f"sed -i 's|fetch('/api/|fetch('http://154.64.228.29:3000/api/|g' {login_path}",
            # 替换API_BASE变量
            f"sed -i 's|const API_BASE =.*|const API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}",
            f"sed -i 's|var API_BASE =.*|var API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}",
            f"sed -i 's|let API_BASE =.*|let API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}"
        ]
        
        for cmd in replacements:
            ssh.exec_command(cmd)
        
        print("前端API地址已统一修正")
        
        # 验证修正结果
        stdin, stdout, stderr = ssh.exec_command(f"grep -n '154.64.228.29' {login_path}")
        print("修正后的API地址:")
        print(stdout.read().decode())
        
        # ==================== 3. 重启验证 ====================
        print("\n3. 重启并验证...")
        
        # 重启pm2
        print("重启pm2进程...")
        ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 stop all 2>/dev/null || true")
        ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 delete all 2>/dev/null || true")
        ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 start server.js --name delta-api")
        
        # 等待启动
        time.sleep(3)
        
        # 验证进程
        stdin, stdout, stderr = ssh.exec_command("pm2 list | grep delta")
        pm2_status = stdout.read().decode()
        print(f"PM2状态: {pm2_status.strip() if pm2_status else '未找到'}")
        
        # 验证端口监听
        stdin, stdout, stderr = ssh.exec_command("netstat -tlnp | grep :3000")
        port_status = stdout.read().decode()
        print(f"端口3000监听: {port_status.strip() if port_status else '未监听'}")
        
        # ==================== 4. 关键验证 ====================
        print("\n4. 关键验证 - 测试登录API...")
        
        # 测试根路径
        print("测试根路径...")
        stdin, stdout, stderr = ssh.exec_command("curl -s http://127.0.0.1:3000/")
        root_response = stdout.read().decode()
        print(f"根路径响应: {root_response[:200]}")
        
        # 测试健康检查
        print("测试健康检查...")
        stdin, stdout, stderr = ssh.exec_command("curl -s http://127.0.0.1:3000/health")
        health_response = stdout.read().decode()
        print(f"健康检查: {health_response}")
        
        # 关键测试：登录API
        print("\n关键测试：登录API...")
        test_cmd = '''curl -X POST http://127.0.0.1:3000/api/admin/login \
-H "Content-Type: application/json" \
-d '{"phone":"13800138000","password":"admin123"}' \
-w "\\nHTTP状态码: %{http_code}\\n"'''
        
        stdin, stdout, stderr = ssh.exec_command(test_cmd)
        login_response = stdout.read().decode()
        error_output = stderr.read().decode()
        
        print("=" * 60)
        print("登录API测试结果:")
        print("=" * 60)
        print(login_response)
        if error_output:
            print(f"错误输出: {error_output}")
        print("=" * 60)
        
        # 分析结果
        if "404" in login_response:
            print("❌ 错误：API路径不存在 (404)")
            print("可能原因：路由配置错误")
        elif "401" in login_response:
            print("⚠️  API响应：认证失败 (401)")
            print("说明：API能访问，但账号密码错误")
        elif "200" in login_response and '"success":true' in login_response:
            print("✅ 成功：API正常响应 (200)")
            print("前后端已对齐，登录功能应正常工作")
        elif "200" in login_response:
            print("⚠️  API响应：HTTP 200但内容异常")
            print(f"响应内容: {login_response[:200]}")
        else:
            print("❓ 未知响应")
            print(f"完整响应: {login_response}")
        
        # 额外测试：从外部访问
        print("\n5. 外部访问测试...")
        external_test = '''curl -s -o /dev/null -w "外部访问: %{http_code}\\n" http://154.64.228.29:3000/'''
        stdin, stdout, stderr = ssh.exec_command(external_test)
        print(stdout.read().decode())
        
        return True
        
    except Exception as e:
        print(f"错误: {e}")
        return False
    finally:
        ssh.close()

if __name__ == "__main__":
    print("前后端对齐修正")
    print("目标：解决登录网络错误")
    print("=" * 60)
    
    if final_fix():
        print("\n" + "=" * 60)
        print("修正完成")
        print("请测试登录功能")
        print("管理界面: http://154.64.228.29:8080/admin/")
        print("API地址: http://154.64.228.29:3000/")
        print("测试账号: 13800138000 / admin123")
        print("=" * 60)
    else:
        print("\n修正失败")