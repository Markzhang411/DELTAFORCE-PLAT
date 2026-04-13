import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("154.64.228.29", username="root", password="ynmaFWAX7694", timeout=10)

print("检查并修正配置...")
print("=" * 60)

try:
    # 1. 检查Nginx配置
    print("\n1. Nginx配置:")
    stdin, stdout, stderr = ssh.exec_command("cat /etc/nginx/sites-enabled/delta-8080")
    nginx_config = stdout.read().decode()
    print(nginx_config)
    
    # 检查root路径
    if "/var/www/delta-8080/public" in nginx_config:
        print("✅ Nginx root路径正确")
    else:
        print("❌ Nginx root路径不正确")
    
    # 2. 检查admin目录
    print("\n2. Admin目录:")
    stdin, stdout, stderr = ssh.exec_command("ls -la /var/www/delta-8080/public/admin/")
    print(stdout.read().decode())
    
    # 3. 检查login.html中的API地址
    print("\n3. 检查login.html中的API地址:")
    login_path = "/var/www/delta-8080/public/admin/login.html"
    
    # 查找API地址
    stdin, stdout, stderr = ssh.exec_command(f"grep -n 'fetch\\|axios\\|localhost\\|127.0.0.1\\|API_BASE' {login_path}")
    api_lines = stdout.read().decode()
    print("当前API配置:")
    print(api_lines)
    
    # 4. 修正API地址
    print("\n4. 修正API地址...")
    
    # 备份原文件
    ssh.exec_command(f"cp {login_path} {login_path}.backup")
    
    # 替换所有可能的错误地址
    replacements = [
        f"sed -i 's|http://localhost:3000|http://154.64.228.29:3000|g' {login_path}",
        f"sed -i 's|http://127.0.0.1:3000|http://154.64.228.29:3000|g' {login_path}",
        f"sed -i 's|localhost:3000|154.64.228.29:3000|g' {login_path}",
        f"sed -i 's|127.0.0.1:3000|154.64.228.29:3000|g' {login_path}",
        f"sed -i 's|const API_BASE =.*|const API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}",
        f"sed -i 's|var API_BASE =.*|var API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}",
        f"sed -i 's|let API_BASE =.*|let API_BASE = \"http://154.64.228.29:3000\";|g' {login_path}"
    ]
    
    for cmd in replacements:
        ssh.exec_command(cmd)
    
    print("API地址已修正")
    
    # 5. 检查跳转路径
    print("\n5. 检查跳转路径:")
    stdin, stdout, stderr = ssh.exec_command(f"grep -n 'window.location.href\\|location.href' {login_path}")
    redirect_lines = stdout.read().decode()
    print("当前跳转配置:")
    print(redirect_lines)
    
    # 修正跳转路径（确保是相对路径）
    print("\n修正跳转路径...")
    ssh.exec_command(f"sed -i 's|window.location.href = \"/admin/|window.location.href = \"|g' {login_path}")
    ssh.exec_command(f"sed -i 's|window.location.href = \"/|window.location.href = \"|g' {login_path}")
    ssh.exec_command(f"sed -i 's|window.location.href = \"http://|window.location.href = \"|g' {login_path}")
    ssh.exec_command(f"sed -i 's|window.location.href = \"dashboard.html\"|window.location.href = \"./dashboard.html\"|g' {login_path}")
    
    # 6. 验证修正结果
    print("\n6. 验证修正结果:")
    
    # 检查API地址
    stdin, stdout, stderr = ssh.exec_command(f"grep -n '154.64.228.29' {login_path}")
    print("修正后的API地址:")
    print(stdout.read().decode())
    
    # 检查跳转路径
    stdin, stdout, stderr = ssh.exec_command(f"grep -n 'window.location.href' {login_path}")
    print("修正后的跳转路径:")
    print(stdout.read().decode())
    
    # 7. 重启Nginx
    print("\n7. 重启Nginx...")
    ssh.exec_command("nginx -t && systemctl reload nginx")
    print("Nginx已重启")
    
    # 8. 最终确认
    print("\n" + "=" * 60)
    print("✅ 检查修正完成")
    print("\n唯一正确的登录URL:")
    print("http://154.64.228.29:8080/admin/login.html")
    print("\n测试账号:")
    print("手机号: 13800138000")
    print("密码: admin123")
    print("=" * 60)
    
except Exception as e:
    print(f"错误: {e}")

ssh.close()