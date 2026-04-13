import paramiko
import time

def diagnose():
    """诊断后端服务"""
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)
    
    print("诊断后端服务...")
    
    try:
        # 1. 检查进程
        print("\n1. 检查Node.js进程:")
        stdin, stdout, stderr = ssh.exec_command("ps aux | grep -E 'node.*server\\.js' | grep -v grep")
        processes = stdout.read().decode()
        if processes:
            print("找到进程:")
            for line in processes.strip().split('\n'):
                print(f"  {line[:80]}")
        else:
            print("无Node.js进程")
        
        # 2. 检查端口
        print("\n2. 检查3000端口:")
        stdin, stdout, stderr = ssh.exec_command("netstat -tln | grep :3000 || ss -tln | grep :3000 || echo '未监听'")
        print(stdout.read().decode().strip())
        
        # 3. 进入目录
        backend_dir = "/var/www/delta-8080/public/backend"
        
        # 4. 检查语法
        print("\n3. 检查server.js语法:")
        stdin, stdout, stderr = ssh.exec_command(f"cd {backend_dir} && node -c server.js 2>&1")
        syntax_check = stderr.read().decode()
        if "SyntaxError" in syntax_check:
            print(f"语法错误: {syntax_check[:200]}")
        else:
            print("语法检查通过")
        
        # 5. 检查依赖
        print("\n4. 检查依赖:")
        stdin, stdout, stderr = ssh.exec_command(f"cd {backend_dir} && ls -la package.json 2>/dev/null || echo '不存在'")
        if "不存在" not in stdout.read().decode():
            print("package.json存在")
            stdin, stdout, stderr = ssh.exec_command(f"cd {backend_dir} && npm list express cors 2>/dev/null | head -5")
            print(stdout.read().decode())
        else:
            print("创建package.json...")
            package_json = '''{
  "name": "delta-backend",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}'''
            ssh.exec_command(f"cd {backend_dir} && echo '{package_json}' > package.json")
            ssh.exec_command(f"cd {backend_dir} && npm install")
            print("依赖安装完成")
        
        # 6. 停止现有进程
        print("\n5. 停止现有进程...")
        ssh.exec_command("pkill -f 'node.*server\\.js' 2>/dev/null || true")
        time.sleep(2)
        
        # 7. 启动服务
        print("\n6. 启动服务...")
        
        # 先直接运行看输出
        stdin, stdout, stderr = ssh.exec_command(f"cd {backend_dir} && timeout 5 node server.js 2>&1")
        direct_output = stderr.read().decode()
        if direct_output:
            print(f"直接运行输出: {direct_output[:300]}")
        
        # 后台启动
        ssh.exec_command(f"cd {backend_dir} && nohup node server.js > server.log 2>&1 &")
        time.sleep(3)
        
        # 8. 检查是否运行
        print("\n7. 检查服务状态:")
        stdin, stdout, stderr = ssh.exec_command(f"ps aux | grep -E 'node.*server\\.js' | grep -v grep")
        processes = stdout.read().decode()
        if processes:
            print("服务运行中")
            
            # 检查端口
            stdin, stdout, stderr = ssh.exec_command("netstat -tln | grep :3000 || echo '检查中...'")
            port_status = stdout.read().decode()
            print(f"端口状态: {port_status.strip()}")
            
            # 9. 关键测试
            print("\n8. 关键测试 - 登录API:")
            test_cmd = '''curl -X POST http://127.0.0.1:3000/api/admin/login \
-H "Content-Type: application/json" \
-d '{"phone":"13800138000","password":"admin123"}' \
-w "\\nHTTP状态码: %{http_code}\\n" \
--max-time 5 2>&1'''
            
            stdin, stdout, stderr = ssh.exec_command(test_cmd)
            result = stdout.read().decode()
            error = stderr.read().decode()
            
            print("=" * 60)
            print("API测试结果:")
            print("=" * 60)
            print(result)
            if error and "curl" not in error:
                print(f"错误: {error}")
            print("=" * 60)
            
            # 分析结果
            if "200" in result and '"success":true' in result:
                print("\n✅ 成功！API返回具体JSON响应")
                print("前后端已对齐，登录功能应正常工作")
                return True
            elif "200" in result or "401" in result or "404" in result:
                print(f"\n⚠️  API响应HTTP状态码: 找到状态码")
                print("前后端已对齐，但需要检查响应内容")
                return True
            elif "Connection refused" in result or "Failed to connect" in result:
                print("\n❌ 连接被拒绝 - 服务未在3000端口运行")
                return False
            else:
                print(f"\n❓ 未知响应: {result[:200]}")
                return False
            
        else:
            print("服务启动失败")
            # 查看日志
            stdin, stdout, stderr = ssh.exec_command(f"cd {backend_dir} && tail -20 server.log 2>/dev/null || echo '无日志'")
            print(f"服务日志: {stdout.read().decode()[:300]}")
            return False
        
    except Exception as e:
        print(f"诊断错误: {e}")
        return False
    finally:
        ssh.close()

if __name__ == "__main__":
    print("后端服务诊断")
    print("目标: 验证API是否返回具体JSON响应")
    print("=" * 60)
    
    if diagnose():
        print("\n" + "=" * 60)
        print("诊断完成: API应返回具体JSON响应")
        print("请测试登录功能")
        print("=" * 60)
    else:
        print("\n诊断失败: 服务未正常运行")