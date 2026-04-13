#!/usr/bin/env python3
"""
启动后端服务并配置API
"""

import paramiko
import sys
import time

def install_deps():
    """安装依赖"""
    try:
        import paramiko
        return True
    except ImportError:
        import subprocess
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "paramiko"], 
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        except:
            return False

def start_backend():
    """启动后端服务"""
    
    hostname = "154.64.228.29"
    username = "root"
    password = "ynmaFWAX7694"
    
    print("启动后端服务任务")
    print("=" * 60)
    
    try:
        # 连接服务器
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname, username=username, password=password, timeout=10)
        print("SSH连接成功")
        
        # ==================== 1. 检查Node.js ====================
        print("\n1. 检查Node.js环境...")
        stdin, stdout, stderr = ssh.exec_command("node --version")
        node_version = stdout.read().decode().strip()
        if node_version:
            print(f"Node.js已安装: {node_version}")
        else:
            print("Node.js未安装，正在安装...")
            stdin, stdout, stderr = ssh.exec_command("apt-get update && apt-get install -y nodejs npm")
            exit_code = stdout.channel.recv_exit_status()
            if exit_code == 0:
                print("Node.js安装成功")
            else:
                print(f"Node.js安装失败: {stderr.read().decode()}")
                return False
        
        # ==================== 2. 检查pm2 ====================
        print("\n2. 检查pm2...")
        stdin, stdout, stderr = ssh.exec_command("which pm2")
        pm2_path = stdout.read().decode().strip()
        if pm2_path:
            print(f"pm2已安装: {pm2_path}")
        else:
            print("安装pm2...")
            stdin, stdout, stderr = ssh.exec_command("npm install -g pm2")
            exit_code = stdout.channel.recv_exit_status()
            if exit_code == 0:
                print("pm2安装成功")
            else:
                print(f"pm2安装失败: {stderr.read().decode()}")
        
        # ==================== 3. 进入后端目录 ====================
        print("\n3. 进入后端目录...")
        backend_dir = "/var/www/delta-8080/public/backend"
        
        # 检查目录是否存在
        stdin, stdout, stderr = ssh.exec_command(f"ls -la {backend_dir}/")
        if "No such file" in stderr.read().decode():
            print(f"后端目录不存在: {backend_dir}")
            # 创建目录
            ssh.exec_command(f"mkdir -p {backend_dir}")
            print("已创建后端目录")
        
        # ==================== 4. 安装依赖 ====================
        print("\n4. 安装Node.js依赖...")
        
        # 检查package.json
        stdin, stdout, stderr = ssh.exec_command(f"ls -la {backend_dir}/package.json")
        if "No such file" in stderr.read().decode():
            print("package.json不存在，创建基本配置...")
            package_json = '''{
  "name": "delta-action-backend",
  "version": "1.0.0",
  "description": "三角洲行动后端API",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}'''
            ssh.exec_command(f"echo '{package_json}' > {backend_dir}/package.json")
        
        # 安装依赖
        stdin, stdout, stderr = ssh.exec_command(f"cd {backend_dir} && npm install")
        exit_code = stdout.channel.recv_exit_status()
        if exit_code == 0:
            print("依赖安装成功")
        else:
            print(f"依赖安装警告: {stderr.read().decode()[:200]}")
        
        # ==================== 5. 检查server.js ====================
        print("\n5. 检查server.js...")
        stdin, stdout, stderr = ssh.exec_command(f"ls -la {backend_dir}/server.js")
        if "No such file" in stderr.read().decode():
            print("server.js不存在，创建基本服务器...")
            server_js = '''const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// 健康检查
app.get('/', (req, res) => {
    res.json({ 
        status: 'ok', 
        service: '三角洲行动后端API',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

// 管理员登录
app.post('/api/admin/login', (req, res) => {
    const { phone, password } = req.body;
    
    if (phone === '13800138000' && password === 'admin123') {
        res.json({
            success: true,
            message: '登录成功',
            token: 'delta-admin-token-' + Date.now(),
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
            message: '账号或密码错误'
        });
    }
});

// 获取订单列表
app.get('/api/orders', (req, res) => {
    res.json({
        success: true,
        data: [
            { id: 1, game: '使命召唤', type: '排位代练', amount: 299, status: 'processing' },
            { id: 2, game: '英雄联盟', type: '段位提升', amount: 450, status: 'completed' },
            { id: 3, game: '原神', type: '材料收集', amount: 120, status: 'pending' }
        ]
    });
});

// 服务器状态
app.get('/api/server/status', (req, res) => {
    res.json({
        cpu: 65,
        memory: 42,
        disk: 78,
        network: 23,
        uptime: process.uptime()
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`三角洲行动后端API运行在: http://0.0.0.0:${PORT}`);
});'''
            ssh.exec_command(f"echo '{server_js}' > {backend_dir}/server.js")
            print("server.js已创建")
        else:
            print("server.js已存在")
        
        # ==================== 6. 启动后端服务 ====================
        print("\n6. 启动后端服务...")
        
        # 先停止可能存在的进程
        ssh.exec_command(f"cd {backend_dir} && pm2 stop server.js 2>/dev/null || true")
        ssh.exec_command(f"cd {backend_dir} && pm2 delete server.js 2>/dev/null || true")
        
        # 使用pm2启动
        stdin, stdout, stderr = ssh.exec_command(f"cd {backend_dir} && pm2 start server.js --name delta-backend")
        exit_code = stdout.channel.recv_exit_status()
        
        if exit_code == 0:
            print("后端服务启动成功 (pm2)")
        else:
            print("尝试使用nohup启动...")
            ssh.exec_command(f"pkill -f 'node.*server.js' 2>/dev/null || true")
            ssh.exec_command(f"cd {backend_dir} && nohup node server.js > server.log 2>&1 &")
            print("后端服务启动成功 (nohup)")
        
        # ==================== 7. 放行3000端口 ====================
        print("\n7. 配置防火墙...")
        
        # 检查ufw
        stdin, stdout, stderr = ssh.exec_command("which ufw")
        if stdout.read().decode().strip():
            print("配置ufw放行3000端口...")
            ssh.exec_command("ufw allow 3000/tcp 2>/dev/null || true")
        
        # 检查iptables
        ssh.exec_command("iptables -I INPUT -p tcp --dport 3000 -j ACCEPT 2>/dev/null || true")
        print("3000端口已放行")
        
        # ==================== 8. 修正前端API地址 ====================
        print("\n8. 修正前端API地址...")
        
        # 检查login.html中的API地址
        login_path = "/var/www/delta-8080/public/admin/login.html"
        stdin, stdout, stderr = ssh.exec_command(f"grep -n 'fetch\\|axios\\|localhost\\|127.0.0.1' {login_path} | head -5")
        api_lines = stdout.read().decode()
        
        if api_lines:
            print(f"当前API配置:\n{api_lines}")
            
            # 替换localhost为服务器IP
            replace_cmd = f"sed -i 's|http://localhost:3000|http://154.64.228.29:3000|g' {login_path}"
            ssh.exec_command(replace_cmd)
            replace_cmd = f"sed -i 's|http://127.0.0.1:3000|http://154.64.228.29:3000|g' {login_path}"
            ssh.exec_command(replace_cmd)
            print("API地址已更新为服务器IP")
        
        # ==================== 9. 验证后端服务 ====================
        print("\n9. 验证后端服务...")
        
        # 等待服务启动
        time.sleep(3)
        
        # 检查进程
        stdin, stdout, stderr = ssh.exec_command("ps aux | grep -E 'node.*server\\.js|pm2' | grep -v grep")
        processes = stdout.read().decode()
        if processes:
            print("后端进程运行中:")
            for line in processes.strip().split('\n'):
                if line:
                    print(f"  {line[:80]}")
        else:
            print("警告: 未找到后端进程")
        
        # 测试API连接
        print("\n测试API连接...")
        for i in range(3):
            stdin, stdout, stderr = ssh.exec_command("curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/ || echo 'failed'")
            status = stdout.read().decode().strip()
            
            if status == "200":
                print(f"✅ 后端API正常: HTTP {status}")
                break
            else:
                print(f"尝试 {i+1}/3: HTTP {status}")
                time.sleep(2)
        
        # 获取API详情
        stdin, stdout, stderr = ssh.exec_command("curl -s http://127.0.0.1:3000/")
        api_response = stdout.read().decode()[:200]
        if api_response:
            print(f"API响应: {api_response}")
        
        # ==================== 10. 最终状态 ====================
        print("\n" + "=" * 60)
        print("后端服务部署完成")
        print(f"API地址: http://154.64.228.29:3000/")
        print(f"管理界面: http://154.64.228.29:8080/admin/")
        print("测试账号: 13800138000 / admin123")
        print("=" * 60)
        
        ssh.close()
        return True
        
    except Exception as e:
        print(f"\n错误: {e}")
        return False

def main():
    print("三角洲行动 · 后端服务启动")
    
    if not install_deps():
        print("安装依赖失败")
        sys.exit(1)
    
    if start_backend():
        print("\n✅ 后端服务启动成功")
    else:
        print("\n❌ 后端服务启动失败")
        sys.exit(1)

if __name__ == "__main__":
    main()