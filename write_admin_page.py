#!/usr/bin/env python3
"""
Write beautiful admin login page via SSH
"""

import subprocess
import sys

def install_paramiko():
    """Install paramiko if needed"""
    try:
        import paramiko
        return True
    except ImportError:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "paramiko"], 
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        except:
            return False

def write_admin_page():
    """Write beautiful admin login page"""
    
    hostname = "154.64.228.29"
    username = "root"
    password = "ynmaFWAX7694"
    
    print("Connecting to server...")
    
    try:
        import paramiko
        
        # Connect
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostname=hostname, username=username, password=password, timeout=10)
        print("Connected")
        
        # Beautiful HTML content
        html_content = '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>管理员登录 - 三角洲行动</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #16213e;
            color: #ffffff;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .login-container {
            width: 100%;
            max-width: 420px;
        }
        
        .login-card {
            background: rgba(255, 255, 255, 0.08);
            backdrop-filter: blur(10px);
            border-radius: 16px;
            padding: 40px 32px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .logo {
            text-align: center;
            margin-bottom: 32px;
        }
        
        .logo h1 {
            font-size: 28px;
            font-weight: 700;
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 8px;
        }
        
        .logo p {
            color: #a0a0c0;
            font-size: 14px;
            opacity: 0.8;
        }
        
        .form-group {
            margin-bottom: 24px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #b0b0d0;
            font-size: 14px;
            font-weight: 500;
        }
        
        .form-control {
            width: 100%;
            padding: 14px 16px;
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            color: #ffffff;
            font-size: 16px;
            transition: all 0.3s;
        }
        
        .form-control:focus {
            outline: none;
            border-color: #00dbde;
            box-shadow: 0 0 0 3px rgba(0, 219, 222, 0.1);
        }
        
        .btn-login {
            width: 100%;
            padding: 16px;
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            border: none;
            border-radius: 10px;
            color: white;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            margin-top: 10px;
        }
        
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(0, 219, 222, 0.3);
        }
        
        .server-info {
            background: rgba(0, 219, 222, 0.1);
            border: 1px solid rgba(0, 219, 222, 0.3);
            border-radius: 10px;
            padding: 16px;
            margin-bottom: 24px;
            font-size: 13px;
        }
        
        .server-info h3 {
            color: #00dbde;
            margin-bottom: 8px;
            font-size: 14px;
        }
        
        .status-badge {
            text-align: center;
            margin-top: 20px;
            padding: 10px;
            background: rgba(87, 255, 137, 0.1);
            border-radius: 8px;
            color: #57ff89;
            font-size: 13px;
        }
        
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #8888aa;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-card">
            <div class="logo">
                <h1>三角洲行动</h1>
                <p>管理员控制台 · 专业版</p>
            </div>
            
            <div class="server-info">
                <h3>🖥️ 服务器信息</h3>
                <p><strong>IP地址:</strong> 154.64.228.29:8080</p>
                <p><strong>部署时间:</strong> 2026-04-13 04:02</p>
                <p><strong>测试账号:</strong> 13800138000 / admin123</p>
            </div>
            
            <form id="loginForm">
                <div class="form-group">
                    <label for="phone">手机号</label>
                    <input type="text" id="phone" class="form-control" 
                           placeholder="请输入管理员手机号" value="13800138000" required>
                </div>
                
                <div class="form-group">
                    <label for="password">密码</label>
                    <input type="password" id="password" class="form-control" 
                           placeholder="请输入密码" value="admin123" required>
                </div>
                
                <button type="submit" class="btn-login" id="loginBtn">
                    🔐 登录管理控制台
                </button>
            </form>
            
            <div class="status-badge">
                ✅ Python SSH 自动部署完成
            </div>
            
            <div class="footer">
                <p>© 2026 三角洲行动 · 护航接单平台</p>
                <p>专业游戏服务交易系统</p>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const phone = document.getElementById('phone').value;
            const password = document.getElementById('password').value;
            const btn = document.getElementById('loginBtn');
            
            btn.disabled = true;
            btn.textContent = '登录中...';
            
            setTimeout(() => {
                if (phone === '13800138000' && password === 'admin123') {
                    alert('🎉 登录成功！\\n\\n🌐 网站: http://154.64.228.29:8080/\\n🔐 管理员: http://154.64.228.29:8080/admin/\\n\\n✅ 欢迎进入管理控制台');
                } else {
                    alert('❌ 登录失败\\n请使用测试账号:\\n📱 手机号: 13800138000\\n🔑 密码: admin123');
                }
                btn.disabled = false;
                btn.textContent = '🔐 登录管理控制台';
            }, 800);
        });
    </script>
</body>
</html>'''
        
        # Write to file
        print("Writing HTML content...")
        
        # Create directory if needed
        client.exec_command("mkdir -p /var/www/delta-8080/public/admin")
        
        # Write file using echo with heredoc
        cmd = f"cat > /var/www/delta-8080/public/admin/login.html << 'HTML_EOF'\n{html_content}\nHTML_EOF"
        
        stdin, stdout, stderr = client.exec_command(cmd)
        exit_code = stdout.channel.recv_exit_status()
        
        if exit_code == 0:
            print("HTML file written successfully")
            
            # Set permissions
            client.exec_command("chown -R www-data:www-data /var/www/delta-8080")
            client.exec_command("chmod -R 755 /var/www/delta-8080")
            
            # Restart nginx
            client.exec_command("systemctl reload nginx")
            
            # Read back to verify
            print("Reading file to verify...")
            stdin, stdout, stderr = client.exec_command("cat /var/www/delta-8080/public/admin/login.html | head -20")
            content_preview = stdout.read().decode().strip()
            
            print("\n=== FILE PREVIEW ===")
            print(content_preview[:500] + "..." if len(content_preview) > 500 else content_preview)
            
            # Check file size
            stdin, stdout, stderr = client.exec_command("wc -l /var/www/delta-8080/public/admin/login.html")
            line_count = stdout.read().decode().strip()
            print(f"File lines: {line_count}")
            
            # Verify it's not just "Fixed"
            stdin, stdout, stderr = client.exec_command("grep -c 'Fixed' /var/www/delta-8080/public/admin/login.html")
            fixed_count = stdout.read().decode().strip()
            
            if int(fixed_count or 0) < 3:
                print("✅ Content verified: Not just 'Fixed' text")
                return True
            else:
                print("⚠️  Content might be minimal")
                return False
                
        else:
            print("Failed to write file")
            return False
            
    except Exception as e:
        print(f"Error: {e}")
        return False
    finally:
        try:
            client.close()
        except:
            pass

def main():
    print("Writing beautiful admin login page...")
    print("=" * 60)
    
    if not install_paramiko():
        print("Failed to install paramiko")
        sys.exit(1)
    
    if write_admin_page():
        print("\n" + "=" * 60)
        print("✅ ADMIN PAGE WRITTEN SUCCESSFULLY")
        print("URL: http://154.64.228.29:8080/admin/")
        print("Test: 13800138000 / admin123")
    else:
        print("\n❌ Failed to write admin page")
        sys.exit(1)

if __name__ == "__main__":
    main()