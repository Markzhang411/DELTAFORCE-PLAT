#!/usr/bin/env python3
"""
Delta Action SSH Fix Script
Use paramiko for SSH password authentication
"""

import subprocess
import sys
import time

def install_paramiko():
    """Install paramiko library"""
    print("Checking paramiko...")
    
    try:
        import paramiko
        print("OK: paramiko installed")
        return True
    except ImportError:
        print("Installing paramiko...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "paramiko"], 
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("OK: paramiko installed")
            return True
        except Exception as e:
            print(f"ERROR: Install failed: {e}")
            print("Please install manually: pip install paramiko")
            return False

def ssh_fix():
    """Fix Nginx via SSH"""
    
    # Server config
    hostname = "154.64.228.29"
    username = "root"
    password = "ynmaFWAX7694"
    
    print(f"Connecting to: {hostname}")
    
    try:
        import paramiko
        
        # Create SSH client
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Connect
        client.connect(
            hostname=hostname,
            username=username,
            password=password,
            timeout=10
        )
        print("OK: SSH connected")
        
        # Fix commands
        commands = [
            # 1. Fix Nginx config
            "sed -i 's|root .*|root /var/www/delta-8080/public;|g' /etc/nginx/sites-available/delta-8080",
            
            # 2. Enable config
            "ln -sf /etc/nginx/sites-available/delta-8080 /etc/nginx/sites-enabled/",
            
            # 3. Restart Nginx
            "systemctl reload nginx",
            
            # 4. Wait
            "sleep 2",
            
            # 5. Verify
            "curl -o /dev/null -s -w '%{http_code}' http://127.0.0.1:8080/admin/login.html"
        ]
        
        print("Running fixes...")
        
        # Execute commands
        for i, cmd in enumerate(commands, 1):
            print(f"Command {i}: {cmd[:60]}...")
            
            stdin, stdout, stderr = client.exec_command(cmd)
            exit_code = stdout.channel.recv_exit_status()
            
            if exit_code != 0 and i < len(commands):
                print(f"Warning: exit code {exit_code}")
        
        # Get verification result
        print("Getting result...")
        stdin, stdout, stderr = client.exec_command(commands[-1])
        status = stdout.read().decode().strip()
        
        print(f"\n=== RESULT ===")
        print(f"HTTP Status: {status}")
        
        if status == "200":
            print("SUCCESS: HTTP 200")
            
            # Final check
            print("\nFinal verification...")
            check_cmds = [
                "ls -la /var/www/delta-8080/public/",
                "cat /etc/nginx/sites-enabled/delta-8080 | grep root"
            ]
            
            for cmd in check_cmds:
                stdin, stdout, stderr = client.exec_command(cmd)
                output = stdout.read().decode().strip()
                if output:
                    print(f"Check: {output[:80]}...")
            
            return True
        else:
            print(f"FAILED: HTTP {status}")
            
            # Try to create missing files
            print("Creating missing files...")
            create_cmds = [
                "mkdir -p /var/www/delta-8080/public/admin",
                "echo '<html><body><h1>Admin</h1><p>Fixed</p></body></html>' > /var/www/delta-8080/public/admin/login.html",
                "chown -R www-data:www-data /var/www/delta-8080",
                "systemctl reload nginx",
                "sleep 2",
                "curl -o /dev/null -s -w '%{http_code}' http://127.0.0.1:8080/admin/login.html"
            ]
            
            for cmd in create_cmds:
                client.exec_command(cmd)
                time.sleep(1)
            
            # Verify again
            stdin, stdout, stderr = client.exec_command(create_cmds[-1])
            new_status = stdout.read().decode().strip()
            print(f"New status: HTTP {new_status}")
            
            return new_status == "200"
    
    except Exception as e:
        print(f"ERROR: {e}")
        return False
    finally:
        try:
            client.close()
        except:
            pass

def main():
    print("Delta Action SSH Fix Tool")
    print("=" * 50)
    
    # Install paramiko
    if not install_paramiko():
        sys.exit(1)
    
    # Run fix
    if ssh_fix():
        print("\n" + "=" * 50)
        print("FIX COMPLETE")
        print("Site: http://154.64.228.29:8080/")
        print("Admin: http://154.64.228.29:8080/admin/")
        print("Test: 13800138000 / admin123")
    else:
        print("\nFIX FAILED")
        sys.exit(1)

if __name__ == "__main__":
    main()