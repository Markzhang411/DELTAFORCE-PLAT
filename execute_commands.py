import paramiko
import time

def execute_commands():
    """执行命令并返回结果"""
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)
    
    try:
        commands = [
            "cd /var/www/delta-8080/public/backend",
            "node -c server.js",
            "pm2 stop delta-api || true",
            "pm2 start server.js --name delta-api",
            "sleep 2",
            '''curl -s -X POST http://127.0.0.1:3000/api/admin/login -H 'Content-Type: application/json' -d '{"phone":"13800138000","password":"admin123"}' '''
        ]
        
        full_command = " && ".join(commands)
        
        print("执行命令...")
        stdin, stdout, stderr = ssh.exec_command(full_command)
        
        # 获取输出
        output = stdout.read().decode()
        error = stderr.read().decode()
        
        print("=" * 60)
        print("命令输出:")
        print("=" * 60)
        print(output)
        if error:
            print("错误输出:")
            print(error)
        print("=" * 60)
        
        # 检查结果
        if '"success":true' in output or '"success": true' in output:
            print("✅ 成功获取到 success: true 的 JSON")
            return True, output
        else:
            print("❌ 未获取到 success: true")
            
            # 检查pm2日志
            print("\n检查pm2日志...")
            stdin, stdout, stderr = ssh.exec_command("pm2 logs delta-api --lines 20")
            logs = stdout.read().decode()
            if logs:
                print("PM2日志:")
                print(logs[:500])
            
            return False, output
            
    except Exception as e:
        print(f"执行错误: {e}")
        return False, str(e)
    finally:
        ssh.close()

if __name__ == "__main__":
    success, result = execute_commands()
    
    if success:
        print("\n✅ 任务成功完成")
        print(f"JSON结果: {result}")
    else:
        print("\n❌ 任务失败")
        print(f"输出: {result}")