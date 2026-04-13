# 🚀 三角洲行动 · VPS服务器部署指南

## 📋 服务器信息
- **IP地址**: `154.64.228.29`
- **用户名**: `root`
- **密码**: `ynmaFWAX7694`
- **操作系统**: Ubuntu 22.04
- **配置**: 1核CPU / 1GB内存 / 20GB硬盘
- **带宽**: 50Mbps
- **流量**: 800GB/月

## 🔧 部署前准备

### 1. 连接服务器
```powershell
# Windows PowerShell
ssh root@154.64.228.29
# 密码: ynmaFWAX7694
```

### 2. 安全加固（强烈建议）
```bash
# 修改root密码
passwd

# 创建部署专用用户
adduser delta
usermod -aG sudo delta

# 切换到部署用户
su - delta
```

## 🚀 一键部署（推荐）

### 方法A：从本地复制部署脚本
```bash
# 在本地电脑执行
scp C:\Users\Administrator\Desktop\website2\deploy-vps.sh root@154.64.228.29:/root/

# 在服务器上执行
ssh root@154.64.228.29
chmod +x /root/deploy-vps.sh
/root/deploy-vps.sh
```

### 方法B：手动部署步骤

#### 步骤1：上传文件到服务器
```bash
# 在本地创建压缩包
cd C:\Users\Administrator\Desktop\website2
tar -czf delta-deploy.tar.gz admin/ backend/ deploy.sh

# 上传到服务器
scp delta-deploy.tar.gz root@154.64.228.29:/tmp/

# 在服务器上解压
ssh root@154.64.228.29
tar -xzf /tmp/delta-deploy.tar.gz -C /var/www/
```

#### 步骤2：运行部署脚本
```bash
cd /var/www/delta
chmod +x deploy.sh
./deploy.sh
```

## 📁 部署后目录结构

```
/var/www/delta/
├── public/                    # 前端文件
│   ├── index.html            # 主页面
│   ├── css/                  # 样式文件
│   ├── js/                   # JavaScript文件
│   └── admin/                # 管理员控制台
│       ├── login.html        # 登录页面
│       ├── dashboard.html    # 仪表盘
│       └── README.md         # 使用指南
├── backend/                  # 后端API
│   ├── server.js            # 主程序
│   ├── package.json         # 依赖配置
│   └── ecosystem.config.js  # PM2配置
├── data/                     # 数据库
│   └── delta.db             # SQLite数据库
└── logs/                    # 日志目录
```

## 🌐 访问地址

### 生产环境
- **网站首页**: `http://154.64.228.29`
- **管理员登录**: `http://154.64.228.29/admin/login.html`
- **API接口**: `http://154.64.228.29/api/`

### 默认管理员账号
- **手机号**: `13800138000`
- **密码**: `admin123`

## 🔐 首次登录后的安全设置

### 1. 修改默认密码
登录后立即创建新的管理员账号并修改默认密码。

### 2. 创建新的管理员账号
在仪表盘中点击"创建管理员账号"按钮，设置新的管理员账号。

### 3. 禁用默认账号（可选）
```bash
# 连接到数据库
sqlite3 /var/www/delta/data/delta.db

# 删除或禁用默认账号
UPDATE users SET password = 'disabled' WHERE phone = '13800138000';
```

## 🛠️ 管理命令

### 服务管理
```bash
# 查看所有服务状态
delta-monitor

# 重启后端API
pm2 restart delta-backend

# 重启Nginx
systemctl restart nginx

# 查看服务日志
pm2 logs delta-backend
tail -f /var/log/delta/combined.log
```

### 数据备份
```bash
# 手动备份
delta-backup

# 查看备份文件
ls -la /backup/delta/
```

### 系统监控
```bash
# 查看系统资源
htop
df -h
free -h

# 查看访问日志
tail -f /var/log/nginx/access.log
```

## ⚙️ 配置文件说明

### 1. Nginx配置
位置: `/etc/nginx/sites-available/delta`
```nginx
server {
    listen 80;
    server_name 154.64.228.29;
    
    location / {
        root /var/www/delta/public;
        index index.html;
    }
    
    location /admin/ {
        alias /var/www/delta/public/admin/;
    }
    
    location /api/ {
        proxy_pass http://localhost:3000;
    }
}
```

### 2. PM2进程管理
位置: `/var/www/delta/backend/ecosystem.config.js`
```javascript
module.exports = {
  apps: [{
    name: 'delta-backend',
    script: 'server.js',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      JWT_SECRET: 'your_secret_key_here'
    }
  }]
};
```

### 3. 环境变量
位置: `/var/www/delta/backend/.env`（需要手动创建）
```
NODE_ENV=production
PORT=3000
JWT_SECRET=your_strong_jwt_secret_here
```

## 🔒 安全配置

### 1. 配置HTTPS（推荐）
```bash
# 安装Certbot
apt-get install certbot python3-certbot-nginx

# 获取证书
certbot --nginx -d 154.64.228.29

# 自动续期
certbot renew --dry-run
```

### 2. 防火墙配置
```bash
# 查看当前规则
ufw status

# 只开放必要端口
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 3000/tcp  # 内部API

# 启用防火墙
ufw enable
```

### 3. SSH安全加固
```bash
# 编辑SSH配置
vim /etc/ssh/sshd_config

# 修改以下设置：
Port 2222                    # 修改默认端口
PermitRootLogin no           # 禁止root登录
PasswordAuthentication no    # 禁用密码登录（使用密钥）
MaxAuthTries 3               # 最大尝试次数

# 重启SSH服务
systemctl restart sshd
```

## 📊 监控和维护

### 每日检查清单
```bash
# 1. 检查服务状态
delta-monitor

# 2. 检查磁盘空间
df -h /var/www/delta

# 3. 检查日志错误
grep -i error /var/log/delta/error.log | tail -20

# 4. 检查访问统计
tail -100 /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr
```

### 每周维护任务
```bash
# 1. 系统更新
apt update && apt upgrade -y

# 2. 清理日志
find /var/log/delta -name "*.log" -mtime +7 -delete

# 3. 数据库优化
sqlite3 /var/www/delta/data/delta.db "VACUUM;"

# 4. 备份验证
delta-backup
```

## 🚨 故障排除

### 常见问题及解决方案

#### Q1: 无法访问网站
```bash
# 检查Nginx状态
systemctl status nginx

# 检查端口
netstat -tln | grep :80

# 检查防火墙
ufw status
```

#### Q2: 管理员登录失败
```bash
# 检查API服务
pm2 status delta-backend

# 检查数据库
ls -la /var/www/delta/data/delta.db

# 检查JWT配置
grep JWT_SECRET /var/www/delta/backend/ecosystem.config.js
```

#### Q3: 数据库连接错误
```bash
# 检查数据库文件权限
ls -la /var/www/delta/data/

# 修复权限
chown -R www-data:www-data /var/www/delta/data/
chmod 644 /var/www/delta/data/delta.db

# 检查SQLite版本
sqlite3 --version
```

#### Q4: 内存不足
```bash
# 查看内存使用
free -h

# 重启服务释放内存
pm2 restart delta-backend

# 优化Node.js内存限制
# 编辑 ecosystem.config.js，增加：
# max_memory_restart: '150M'
```

### 紧急恢复步骤

1. **服务完全崩溃**
```bash
# 重启所有服务
pm2 restart all
systemctl restart nginx

# 检查日志
tail -f /var/log/delta/error.log
```

2. **数据库损坏**
```bash
# 从备份恢复
cp /backup/delta/delta.db.latest /var/www/delta/data/delta.db

# 重启服务
pm2 restart delta-backend
```

3. **文件丢失**
```bash
# 从备份恢复
tar -xzf /backup/delta/delta_backup_latest.tar.gz -C /var/www/

# 重启服务
systemctl restart nginx
pm2 restart delta-backend
```

## 📞 技术支持

### 联系信息
- **服务器提供商**: 自行管理
- **技术支持**: 系统管理员
- **紧急联系人**: [你的联系方式]

### 文档位置
- **部署文档**: `/var/www/delta/admin/README.md`
- **API文档**: 集成在管理员控制台中
- **监控脚本**: `/usr/local/bin/delta-monitor`

### 更新日志
```bash
# 查看部署版本
cat /var/www/delta/backend/package.json | grep version

# 查看最近更新
ls -la /var/www/delta/backend/server.js
```

## 🎯 最佳实践

### 开发环境
1. 使用Git进行版本控制
2. 在本地测试后再部署
3. 保留完整的部署日志

### 生产环境
1. 启用HTTPS
2. 配置自动备份
3. 设置监控告警
4. 定期安全扫描

### 性能优化
1. 启用Nginx缓存
2. 优化数据库索引
3. 配置CDN（如有需要）
4. 监控资源使用

---

## ✅ 部署完成检查清单

- [ ] 网站可访问: http://154.64.228.29
- [ ] 管理员登录正常: http://154.64.228.29/admin/login.html
- [ ] 默认账号可登录
- [ ] 已创建新的管理员账号
- [ ] 已修改默认密码
- [ ] 防火墙已配置
- [ ] 备份脚本已测试
- [ ] 监控脚本正常工作
- [ ] 日志目录可写入
- [ ] 数据库权限正确

---

**最后更新**: 2026-04-12  
**部署版本**: v1.0.0  
**技术支持**: OpenClaw AI Assistant