import paramiko
import time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)

print("深度自检开始...")
print("=" * 60)

try:
    # 1. 读取login.html中的fetch/axios代码
    print("\n1. login.html中的fetch/axios代码:")
    stdin, stdout, stderr = ssh.exec_command("grep -n -A3 -B1 'fetch\\|axios' /var/www/delta-8080/public/admin/login.html")
    fetch_code = stdout.read().decode()
    print(fetch_code if fetch_code else "未找到fetch/axios代码")
    
    # 2. 检查API地址
    print("\n2. API地址检查:")
    stdin, stdout, stderr = ssh.exec_command("grep -n '154.64.228.29\\|localhost\\|127.0.0.1\\|3000' /var/www/delta-8080/public/admin/login.html")
    api_addresses = stdout.read().decode()
    print(api_addresses if api_addresses else "未找到API地址")
    
    # 3. 检查跳转目标
    print("\n3. 跳转目标检查:")
    stdin, stdout, stderr = ssh.exec_command("grep -n 'window.location.href\\|location.href' /var/www/delta-8080/public/admin/login.html")
    redirects = stdout.read().decode()
    print(redirects if redirects else "未找到跳转代码")
    
    # 4. 检查dashboard文件
    print("\n4. dashboard文件检查:")
    stdin, stdout, stderr = ssh.exec_command("ls -la /var/www/delta-8080/public/admin/dashboard.html 2>/dev/null && echo 'admin/dashboard.html存在' || echo 'admin/dashboard.html不存在'")
    print(stdout.read().decode())
    
    stdin, stdout, stderr = ssh.exec_command("ls -la /var/www/delta-8080/public/dashboard.html 2>/dev/null && echo '根目录dashboard.html存在' || echo '根目录dashboard.html不存在'")
    print(stdout.read().decode())
    
    # 5. 强制重启Nginx
    print("\n5. 强制重启Nginx...")
    ssh.exec_command("systemctl restart nginx")
    time.sleep(2)
    print("Nginx重启完成")
    
    # 6. 检查并更新CORS配置
    print("\n6. 检查并更新CORS配置...")
    
    # 读取当前server.js
    stdin, stdout, stderr = ssh.exec_command("head -20 /var/www/delta-8080/public/backend/server.js")
    server_js = stdout.read().decode()
    print("当前server.js前20行:")
    print(server_js)
    
    # 更新CORS为 origin: '*'
    if "origin: '*'" not in server_js and "origin: \"*\"" not in server_js:
        print("更新CORS配置为 origin: '*'...")
        ssh.exec_command("sed -i 's|app.use(cors());|app.use(cors({ origin: \"*\" }));|g' /var/www/delta-8080/public/backend/server.js")
        ssh.exec_command("sed -i 's|app.use(cors({}));|app.use(cors({ origin: \"*\" }));|g' /var/www/delta-8080/public/backend/server.js")
        print("CORS配置已更新")
    else:
        print("CORS配置已包含 origin: '*'")
    
    # 7. 重启后端服务
    print("\n7. 重启后端服务...")
    ssh.exec_command("pm2 restart delta-api")
    time.sleep(3)
    
    # 检查进程状态
    stdin, stdout, stderr = ssh.exec_command("pm2 list | grep delta-api")
    pm2_status = stdout.read().decode()
    print(f"PM2状态: {pm2_status.strip()}")
    
    # 8. 最终测试
    print("\n8. 最终API测试...")
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
    
    # 9. 检查前端实际请求
    print("\n9. 模拟前端请求测试...")
    frontend_test = '''curl -X POST http://154.64.228.29:3000/api/admin/login \
-H "Content-Type: application/json" \
-H "Origin: http://154.64.228.29:8080" \
-d '{"phone":"13800138000","password":"admin123"}' \
-w "\\nHTTP状态码: %{http_code}\\n" \
--max-time 5'''
    
    stdin, stdout, stderr = ssh.exec_command(frontend_test)
    frontend_response = stdout.read().decode()
    print("前端模拟请求结果:")
    print(frontend_response)
    
    print("\n" + "=" * 60)
    print("深度自检完成")
    print("=" * 60)
    
except Exception as e:
    print(f"错误: {e}")

ssh.close()