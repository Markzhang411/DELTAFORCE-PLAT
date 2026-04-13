#!/usr/bin/env python3
"""
全量同步本地文件到服务器
"""

import os
import paramiko
from scp import SCPClient
import sys

def install_deps():
    """安装依赖"""
    try:
        import paramiko
        from scp import SCPClient
        return True
    except ImportError:
        import subprocess
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "paramiko", "scp"], 
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        except:
            return False

def get_local_files(local_dir):
    """获取本地所有网页相关文件"""
    extensions = {'.html', '.css', '.js', '.jpg', '.jpeg', '.png', '.gif', '.svg', '.ico', '.webp'}
    files = []
    
    for root, dirs, filenames in os.walk(local_dir):
        # 跳过一些不需要的目录
        if 'node_modules' in root or '.git' in root:
            continue
            
        for filename in filenames:
            ext = os.path.splitext(filename)[1].lower()
            if ext in extensions:
                full_path = os.path.join(root, filename)
                rel_path = os.path.relpath(full_path, local_dir)
                files.append((full_path, rel_path))
    
    return files

def sync_files_to_server():
    """同步文件到服务器"""
    
    # 配置
    local_dir = r"C:\Users\Administrator\Desktop\website2"
    hostname = "154.64.228.29"
    username = "root"
    password = "ynmaFWAX7694"
    remote_base = "/var/www/delta-8080/public"
    
    print("=" * 60)
    print("全量文件同步工具")
    print(f"本地目录: {local_dir}")
    print(f"服务器: {hostname}")
    print(f"远程目录: {remote_base}")
    print("=" * 60)
    
    # 获取本地文件
    print("\n扫描本地文件...")
    files = get_local_files(local_dir)
    
    if not files:
        print("未找到任何网页文件")
        return False
    
    print(f"找到 {len(files)} 个文件")
    
    # 显示前10个文件
    print("\n文件列表 (前10个):")
    for i, (full_path, rel_path) in enumerate(files[:10]):
        print(f"  {i+1}. {rel_path}")
    if len(files) > 10:
        print(f"  ... 还有 {len(files)-10} 个文件")
    
    try:
        # 连接服务器
        print("\n连接服务器...")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname, username=username, password=password, timeout=10)
        print("SSH连接成功")
        
        # 创建SCP客户端
        scp = SCPClient(ssh.get_transport())
        
        # 同步每个文件
        print("\n开始同步文件...")
        success_count = 0
        fail_count = 0
        
        for full_path, rel_path in files:
            try:
                # 构建远程路径
                remote_path = os.path.join(remote_base, rel_path).replace('\\', '/')
                remote_dir = os.path.dirname(remote_path)
                
                # 创建远程目录
                ssh.exec_command(f"mkdir -p '{remote_dir}'")
                
                # 上传文件
                print(f"上传: {rel_path} -> {remote_path}")
                scp.put(full_path, remote_path)
                success_count += 1
                
            except Exception as e:
                print(f"错误上传 {rel_path}: {e}")
                fail_count += 1
        
        # 关闭SCP
        scp.close()
        
        print(f"\n同步完成:")
        print(f"  成功: {success_count} 个文件")
        print(f"  失败: {fail_count} 个文件")
        
        if success_count > 0:
            # 设置权限
            print("\n设置文件权限...")
            stdin, stdout, stderr = ssh.exec_command(f"chown -R www-data:www-data {remote_base}")
            exit_code = stdout.channel.recv_exit_status()
            if exit_code == 0:
                print("权限设置成功")
            else:
                print(f"权限设置失败: {stderr.read().decode()}")
            
            # 重启Nginx
            print("重启Nginx...")
            stdin, stdout, stderr = ssh.exec_command("systemctl reload nginx")
            exit_code = stdout.channel.recv_exit_status()
            if exit_code == 0:
                print("Nginx重启成功")
            else:
                print(f"Nginx重启失败: {stderr.read().decode()}")
            
            # 验证login.html
            print("\n验证login.html内容...")
            stdin, stdout, stderr = ssh.exec_command(f"cat {remote_base}/admin/login.html | head -30")
            content = stdout.read().decode('utf-8', errors='ignore')
            
            print("=" * 60)
            print("login.html 前30行内容:")
            print("=" * 60)
            print(content[:2000])  # 限制输出长度
            print("=" * 60)
            
            # 检查是否包含原始代码特征
            check_keywords = ['三角洲行动', '管理员登录', '手机号', '密码', '登录']
            found_keywords = []
            for keyword in check_keywords:
                if keyword in content:
                    found_keywords.append(keyword)
            
            print(f"\n关键词检查: {len(found_keywords)}/{len(check_keywords)} 个匹配")
            if found_keywords:
                print(f"找到的关键词: {', '.join(found_keywords)}")
            
            # 检查文件大小
            stdin, stdout, stderr = ssh.exec_command(f"wc -l {remote_base}/admin/login.html")
            line_count = stdout.read().decode().strip()
            print(f"login.html 行数: {line_count}")
        
        ssh.close()
        return success_count > 0
        
    except Exception as e:
        print(f"\n同步失败: {e}")
        return False

def main():
    print("三角洲行动 · 全量文件同步")
    print("=" * 60)
    
    # 安装依赖
    if not install_deps():
        print("安装依赖失败")
        sys.exit(1)
    
    # 执行同步
    if sync_files_to_server():
        print("\n" + "=" * 60)
        print("✅ 同步完成")
        print(f"网站: http://154.64.228.29:8080/")
        print(f"管理员: http://154.64.228.29:8080/admin/")
        print("=" * 60)
    else:
        print("\n❌ 同步失败")
        sys.exit(1)

if __name__ == "__main__":
    main()