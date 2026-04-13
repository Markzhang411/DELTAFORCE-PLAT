#!/usr/bin/env python3
"""
Create admin dashboard and update login logic
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

def execute_ssh_commands(client, commands):
    """Execute multiple SSH commands"""
    for cmd in commands:
        stdin, stdout, stderr = client.exec_command(cmd)
        exit_code = stdout.channel.recv_exit_status()
        if exit_code != 0:
            print(f"Warning: Command failed: {cmd[:50]}...")
        else:
            print(f"OK: {cmd[:50]}...")

def create_dashboard():
    """Create dashboard.html and update login.html"""
    
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
        
        # ==================== CREATE DASHBOARD.HTML ====================
        print("\n1. Creating dashboard.html...")
        
        # Dashboard HTML content
        dashboard_content = '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>管理控制台 - 三角洲行动</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --primary: #00dbde; --secondary: #fc00ff; --dark: #16213e;
            --darker: #0f1529; --light: #ffffff; --gray: #a0a0c0;
            --success: #57ff89; --warning: #ffcc00; --danger: #ff4757;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--darker); color: var(--light); min-height: 100vh;
        }
        .header {
            background: var(--dark); padding: 20px 30px; display: flex;
            justify-content: space-between; align-items: center;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        .logo h1 {
            font-size: 24px; font-weight: 700;
            background: linear-gradient(90deg, var(--primary), var(--secondary));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        .logout-btn {
            padding: 8px 16px; background: rgba(255, 71, 87, 0.2);
            border: 1px solid var(--danger); border-radius: 6px;
            color: var(--danger); cursor: pointer; font-size: 14px;
        }
        .container { display: flex; min-height: calc(100vh - 80px); }
        .sidebar {
            width: 250px; background: var(--dark); padding: 30px 20px;
            border-right: 1px solid rgba(255, 255, 255, 0.1);
        }
        .nav-item {
            padding: 14px 16px; margin-bottom: 8px; border-radius: 8px;
            cursor: pointer; display: flex; align-items: center; gap: 12px;
            transition: all 0.3s;
        }
        .nav-item:hover { background: rgba(255, 255, 255, 0.1); }
        .nav-item.active {
            background: linear-gradient(90deg, var(--primary), var(--secondary));
            color: white;
        }
        .main-content { flex: 1; padding: 30px; }
        .page-title { font-size: 28px; margin-bottom: 30px; color: var(--light); }
        .stats-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px; margin-bottom: 40px;
        }
        .stat-card {
            background: rgba(255, 255, 255, 0.05); border-radius: 12px;
            padding: 24px; border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .stat-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 20px;
        }
        .stat-title { font-size: 16px; color: var(--gray); }
        .stat-value { font-size: 32px; font-weight: 700; margin-bottom: 10px; }
        .progress-bar {
            height: 8px; background: rgba(255, 255, 255, 0.1);
            border-radius: 4px; overflow: hidden; margin-top: 15px;
        }
        .progress-fill { height: 100%; border-radius: 4px; }
        .cpu-progress { background: linear-gradient(90deg, var(--primary), var(--secondary)); width: 65%; }
        .mem-progress { background: linear-gradient(90deg, #ffcc00, #ff9500); width: 42%; }
        .disk-progress { background: linear-gradient(90deg, #57ff89, #00d4aa); width: 78%; }
        .net-progress { background: linear-gradient(90deg, #9d4edd, #560bad); width: 23%; }
        .orders-section {
            background: rgba(255, 255, 255, 0.05); border-radius: 12px;
            padding: 30px; border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .section-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 25px;
        }
        .section-title { font-size: 20px; font-weight: 600; }
        .add-order-btn {
            padding: 10px 20px; background: linear-gradient(90deg, var(--primary), var(--secondary));
            border: none; border-radius: 8px; color: white; cursor: pointer; font-weight: 500;
        }
        table { width: 100%; border-collapse: collapse; }
        th {
            text-align: left; padding: 16px; color: var(--gray);
            font-weight: 500; border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        td { padding: 16px; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
        .status-badge { padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 500; }
        .status-pending { background: rgba(255, 204, 0, 0.2); color: #ffcc00; }
        .status-processing { background: rgba(0, 219, 222, 0.2); color: var(--primary); }
        .status-completed { background: rgba(87, 255, 137, 0.2); color: var(--success); }
        .status-cancelled { background: rgba(255, 71, 87, 0.2); color: var(--danger); }
        .action-btn {
            padding: 6px 12px; margin-right: 8px; border-radius: 6px;
            border: none; cursor: pointer; font-size: 12px;
        }
        .btn-view { background: rgba(0, 219, 222, 0.2); color: var(--primary); }
        .btn-edit { background: rgba(255, 204, 0, 0.2); color: #ffcc00; }
        .btn-delete { background: rgba(255, 71, 87, 0.2); color: var(--danger); }
        .footer {
            text-align: center; padding: 30px; color: var(--gray); font-size: 14px;
            border-top: 1px solid rgba(255, 255, 255, 0.1); margin-top: 40px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">
            <h1>三角洲行动</h1>
            <span style="color: var(--gray); font-size: 14px;">管理控制台</span>
        </div>
        <div class="user-info">
            <div>
                <div style="font-weight: 500;">管理员</div>
                <div style="color: var(--gray); font-size: 12px;">13800138000</div>
            </div>
            <button class="logout-btn" onclick="logout()">🚪 退出登录</button>
        </div>
    </div>
    
    <div class="container">
        <div class="sidebar">
            <div class="nav-item active"><span>📊</span> 仪表盘</div>
            <div class="nav-item"><span>📦</span> 订单管理</div>
            <div class="nav-item"><span>👥</span> 用户管理</div>
            <div class="nav-item"><span>💰</span> 财务管理</div>
            <div class="nav-item"><span>⚙️</span> 系统设置</div>
            <div class="nav-item"><span>📈</span> 数据分析</div>
            <div class="nav-item"><span>🔒</span> 权限管理</div>
        </div>
        
        <div class="main-content">
            <h1 class="page-title">📊 系统仪表盘</h1>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">CPU 使用率</div>
                        <div style="color: var(--primary); font-weight: 600;">65%</div>
                    </div>
                    <div class="stat-value">3.2 GHz</div>
                    <div>Intel Xeon E5 · 8核心</div>
                    <div class="progress-bar"><div class="progress-fill cpu-progress"></div></div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">内存使用</div>
                        <div style="color: #ffcc00; font-weight: 600;">42%</div>
                    </div>
                    <div class="stat-value">6.7 GB / 16 GB</div>
                    <div>DDR4 3200MHz</div>
                    <div class="progress-bar"><div class="progress-fill mem-progress"></div></div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">磁盘空间</div>
                        <div style="color: #57ff89; font-weight: 600;">78%</div>
                    </div>
                    <div class="stat-value">156 GB / 200 GB</div>
                    <div>NVMe SSD</div>
                    <div class="progress-bar"><div class="progress-fill disk-progress"></div></div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-title">网络流量</div>
                        <div style="color: #9d4edd; font-weight: 600;">23%</div>
                    </div>
                    <div class="stat-value">2.3 TB / 10 TB</div>
                    <div>1 Gbps 带宽</div>
                    <div class="progress-bar"><div class="progress-fill net-progress"></div></div>
                </div>
            </div>
            
            <div class="orders-section">
                <div class="section-header">
                    <div class="section-title">📦 最近订单</div>
                    <button class="add-order-btn" onclick="addOrder()">+ 新建订单</button>
                </div>
                
                <table>
                    <thead>
                        <tr>
                            <th>订单号</th><th>游戏</th><th>服务类型</th><th>金额</th>
                            <th>用户</th><th>状态</th><th>创建时间</th><th>操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>#DELTA-2026-001</td><td>使命召唤</td><td>排位代练</td><td>¥ 299.00</td>
                            <td>张先生</td><td><span class="status-badge status-processing">处理中</span></td>
                            <td>2026-04-12 14:30</td>
                            <td><button class="action-btn btn-view">查看</button><button class="action-btn btn-edit">编辑</button></td>
                        </tr>
                        <tr>
                            <td>#DELTA-2026-002</td><td>英雄联盟</td><td>段位提升</td><td>¥ 450.00</td>
                            <td>王女士</td><td><span class="status-badge status-completed">已完成</span></td>
                            <td>2026-04-12 10:15</td>
                            <td><button class="action-btn btn-view">查看</button><button class="action-btn btn-delete">删除</button></td>
                        </tr>
                        <tr>
                            <td>#DELTA-2026-003</td><td>原神</td><td>材料收集</td><td>¥ 120.00</td>
                            <td>李先生</td><td><span class="status-badge status-pending">待处理</span></td>
                            <td>2026-04-12 09:45</td>
                            <td><button class="action-btn btn-view">查看</button><button class="action-btn btn-edit">编辑</button></td>
                        </tr>
                        <tr>
                            <td>#DELTA-2026-004</td><td>APEX英雄</td><td>等级提升</td><td>¥ 380.00</td>
                            <td>赵先生</td><td><span class="status-badge status-processing">处理中</span></td>
                            <td>2026-04-11 16:20</td>
                            <td><button class="action-btn btn-view">查看</button><button class="action-btn btn-edit">编辑</button></td>
                        </tr>
                        <tr>
                            <td>#DELTA-2026-005</td><td>永劫无间</td><td>装备打造</td><td>¥ 560.00</td>
                            <td>孙女士</td><td><span class="status-badge status-cancelled">已取消</span></td>
                            <td>2026-04-11 11:10</td>
                            <td><button class="action-btn btn-view">查看</button><button class="action-btn btn-delete">删除</button></td>
                        </tr>
                    </tbody>
                </table>
            </div>
            
            <div class="footer">
                <p>© 2026 三角洲行动 · 护航接单平台 | 服务器: 154.64.228.29:8080 | 最后更新: 2026-04-13 04:06</p>
                <p>专业游戏服务交易系统 · 管理控制台 v2.0</p>
            </div>
        </div>
    </div>

    <script>
        function logout() {
            if (confirm('确定要退出登录吗？')) {
                window.location.href = 'login.html';
            }
        }
        
        function addOrder() {
            alert('📝 新建订单功能\\n\\n订单管理模块已就绪\\n实际功能需连接后端API');
        }
        
        // Update stats every 30 seconds (simulated)
        setInterval(() => {
            document.querySelector('.cpu-progress').style.width = (65 + Math.random() * 5) + '%';
            document.querySelector('.mem-progress').style.width = (42 + Math.random() * 3) + '%';
        }, 30000);
    </script>
</body>
</html>'''
        
        # Write dashboard.html
        cmd = f"cat > /var/www/delta-8080/public/admin/dashboard.html << 'DASHBOARD_EOF'\n{dashboard_content}\nDASHBOARD_EOF"
        execute_ssh_commands(client, [cmd])
        
        # ==================== UPDATE LOGIN.HTML ====================
        print("\n2. Updating login.html for redirect...")
        
        # First backup the original
        execute_ssh_commands(client, [
            "cp /var/www/delta-8080/public/admin/login.html /var/www/delta-8080/public/admin/login.html.backup"
        ])
        
        # Update login.html JavaScript to redirect to dashboard
        update_script = '''
        // Update login function to redirect to dashboard
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const phone = document.getElementById('phone').value;
            const password = document.getElementById('password').value;
            const btn = document.getElementById