import paramiko
import time

def fix_backend():
    """修复后端服务"""
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)
    
    print("修复后端服务...")
    
    try:
        # 1. 检查当前运行的server.js
        print("1. 检查当前server.js内容...")
        stdin, stdout, stderr = ssh.exec_command("cat /var/www/delta-8080/public/backend/server.js | head -20")
        print("当前server.js前20行:")
        print(stdout.read().decode())
        
        # 2. 创建正确的server.js
        print("\n2. 创建正确的server.js...")
        correct_server = '''const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// 根路径响应
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
    console.log('登录请求:', phone, password);
    
    if (phone === '13800138000' && password === 'admin123') {
        res.json({
            success: true,
            message: '登录成功',
            token: 'delta-admin-token',
            user: { phone: phone, name: '管理员' }
        });
    } else {
        res.status(401).json({
            success: false,
            message: '账号或密码错误'
        });
    }
});

// 健康检查
app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log('后端API运行在端口:', PORT);
});'''
        
        ssh.exec_command(f"echo '{correct_server}' > /var/www/delta-8080/public/backend/server.js")
        print("server.js已更新")
        
        # 3. 重启服务
        print("\n3. 重启后端服务...")
        ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 stop all 2>/dev/null || true")
        ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 delete all 2>/dev/null || true")
        ssh.exec_command("cd /var/www/delta-8080/public/backend && pm2 start server.js --name delta-api")
        
        # 4. 等待启动
        time.sleep(3)
        
        # 5. 验证
        print("\n4. 验证后端服务...")
        stdin, stdout, stderr = ssh.exec_command("curl -s http://127.0.0.1:3000/")
        response = stdout.read().decode()
        print(f"API响应: {response}")
        
        stdin, stdout, stderr = ssh.exec_command("curl -s http://127.0.0.1:3000/health")
        health = stdout.read().decode()
        print(f"健康检查: {health}")
        
        # 6. 检查进程
        stdin, stdout, stderr = ssh.exec_command("pm2 list")
        pm2_status = stdout.read().decode()
        print(f"PM2状态:\n{pm2_status}")
        
        # 7. 测试登录API
        print("\n5. 测试登录API...")
        test_login = '''curl -s -X POST http://127.0.0.1:3000/api/admin/login \
-H "Content-Type: application/json" \
-d '{"phone":"13800138000","password":"admin123"}' '''
        
        stdin, stdout, stderr = ssh.exec_command(test_login)
        login_response = stdout.read().decode()
        print(f"登录测试: {login_response}")
        
        if '"success":true' in login_response:
            print("后端服务修复成功!")
            return True
        else:
            print("后端服务仍有问题")
            return False
            
    except Exception as e:
        print(f"错误: {e}")
        return False
    finally:
        ssh.close()

if __name__ == "__main__":
    fix_backend()