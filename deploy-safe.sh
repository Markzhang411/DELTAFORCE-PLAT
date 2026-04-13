#!/bin/bash
# ================================================
# 三角洲行动 · 安全部署脚本
# 在已有内容的服务器上安全部署
# ================================================
set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[Delta]${NC} $1"; }
warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
error() { echo -e "${RED}[错误]${NC} $1"; }
info() { echo -e "${BLUE}[信息]${NC} $1"; }

# 配置变量
SERVER_IP="154.64.228.29"
BASE_DIR="/var/www/delta"  # 可以修改为其他目录
USE_SUBDIRECTORY=false     # 是否使用子目录部署
USE_PORT=8080              # 如果使用端口部署

# ================================================
# 1. 服务器状态检查
# ================================================
log "开始服务器状态检查..."

echo ""
echo "=== 服务器状态报告 ==="
echo ""

# 检查系统信息
info "系统信息:"
echo "  主机名: $(hostname)"
echo "  IP地址: $(hostname -I | awk '{print $1}')"
echo "  操作系统: $(lsb_release -d | cut -f2)"
echo "  内核版本: $(uname -r)"
echo "  内存: $(free -h | awk '/^Mem:/ {print $2}')"
echo "  磁盘: $(df -h / | awk 'NR==2 {print $4 " 可用 / " $2 " 总量"}')"

echo ""
info "现有网站目录:"
if [ -d "/var/www" ]; then
    find /var/www -maxdepth 2 -type d | sort
else
    echo "  /var/www 目录不存在"
fi

echo ""
info "Web服务器状态:"
# 检查Nginx
if systemctl is-active --quiet nginx; then
    echo "  Nginx: 运行中"
    echo "  配置文件:"
    ls -la /etc/nginx/sites-available/ 2>/dev/null || echo "    无配置文件"
else
    echo "  Nginx: 未运行"
fi

# 检查Apache
if systemctl is-active --quiet apache2; then
    echo "  Apache: 运行中"
elif systemctl is-active --quiet httpd; then
    echo "  Apache (httpd): 运行中"
fi

echo ""
info "端口占用情况:"
for port in 80 443 3000 8080 8000; do
    if netstat -tln | grep -q ":$port "; then
        process=$(lsof -i :$port | awk 'NR==2 {print $1}')
        echo "  端口 $port: 被占用 (进程: $process)"
    else
        echo "  端口 $port: 空闲"
    fi
done

echo ""
info "数据库服务:"
if command -v mysql &> /dev/null && systemctl is-active --quiet mysql; then
    echo "  MySQL: 运行中"
fi
if command -v postgres &> /dev/null && systemctl is-active --quiet postgresql; then
    echo "  PostgreSQL: 运行中"
fi
if [ -f "/var/www/delta/data/delta.db" ]; then
    echo "  SQLite (delta.db): 已存在"
fi

echo ""
warn "⚠️  发现以下潜在冲突:"
CONFLICTS=()

# 检查目录冲突
if [ -d "/var/www/delta" ]; then
    CONFLICTS+=("目录 /var/www/delta 已存在")
fi

# 检查端口冲突
if netstat -tln | grep -q ":80 "; then
    CONFLICTS+=("端口80已被占用")
fi
if netstat -tln | grep -q ":3000 "; then
    CONFLICTS+=("端口3000已被占用")
fi

# 检查Nginx配置冲突
if [ -f "/etc/nginx/sites-available/delta" ]; then
    CONFLICTS+=("Nginx配置delta已存在")
fi

if [ ${#CONFLICTS[@]} -eq 0 ]; then
    echo "  未发现冲突"
else
    for conflict in "${CONFLICTS[@]}"; do
        echo "  • $conflict"
    done
fi

echo ""
echo "=== 检查完成 ==="
echo ""

# ================================================
# 2. 部署方案选择
# ================================================
log "请选择部署方案:"

echo ""
echo "1. 标准部署 (推荐)"
echo "   - 使用 /var/www/delta 目录"
echo "   - 使用端口80 (如果可用)"
echo "   - 创建独立的Nginx配置"
echo ""
echo "2. 子目录部署"
echo "   - 部署到现有网站的子目录"
echo "   - 例如: http://服务器IP/delta/"
echo "   - 不影响现有网站"
echo ""
echo "3. 端口部署"
echo "   - 使用非标准端口 (如8080)"
echo "   - 例如: http://服务器IP:8080/"
echo "   - 完全独立，不冲突"
echo ""
echo "4. 自定义部署"
echo "   - 手动指定目录和端口"
echo ""

read -p "请选择方案 (1-4): " DEPLOY_CHOICE

case $DEPLOY_CHOICE in
    1)
        log "选择标准部署方案"
        BASE_DIR="/var/www/delta"
        USE_SUBDIRECTORY=false
        USE_PORT=80
        ;;
    2)
        log "选择子目录部署方案"
        read -p "请输入子目录名称 (默认: delta): " SUBDIR
        SUBDIR=${SUBDIR:-delta}
        BASE_DIR="/var/www/$SUBDIR"
        USE_SUBDIRECTORY=true
        USE_PORT=80
        ;;
    3)
        log "选择端口部署方案"
        read -p "请输入端口号 (默认: 8080): " PORT
        USE_PORT=${PORT:-8080}
        BASE_DIR="/var/www/delta"
        USE_SUBDIRECTORY=false
        
        # 检查端口是否可用
        if netstat -tln | grep -q ":$USE_PORT "; then
            error "端口 $USE_PORT 已被占用，请选择其他端口"
            exit 1
        fi
        ;;
    4)
        log "选择自定义部署方案"
        read -p "请输入部署目录 (默认: /var/www/delta): " CUSTOM_DIR
        BASE_DIR=${CUSTOM_DIR:-/var/www/delta}
        read -p "请输入端口号 (默认: 80): " CUSTOM_PORT
        USE_PORT=${CUSTOM_PORT:-80}
        read -p "是否使用子目录? (y/n, 默认: n): " USE_SUBDIR
        if [[ $USE_SUBDIR =~ ^[Yy]$ ]]; then
            USE_SUBDIRECTORY=true
        else
            USE_SUBDIRECTORY=false
        fi
        ;;
    *)
        error "无效选择"
        exit 1
        ;;
esac

# 确认部署信息
echo ""
log "部署配置确认:"
echo "  部署目录: $BASE_DIR"
echo "  访问端口: $USE_PORT"
if [ "$USE_SUBDIRECTORY" = true ]; then
    echo "  访问路径: http://$SERVER_IP/$SUBDIR/"
else
    echo "  访问路径: http://$SERVER_IP:$USE_PORT/"
fi
echo "  管理员界面: http://$SERVER_IP:$USE_PORT/admin/"
echo ""

read -p "是否继续部署? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "部署取消"
    exit 0
fi

# ================================================
# 3. 备份现有配置（如果存在）
# ================================================
log "备份现有配置..."

BACKUP_DIR="/backup/delta-setup-$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# 备份现有delta目录（如果存在）
if [ -d "/var/www/delta" ]; then
    warn "发现现有delta目录，正在备份..."
    tar -czf "$BACKUP_DIR/delta-backup.tar.gz" -C /var/www delta
    echo "  备份到: $BACKUP_DIR/delta-backup.tar.gz"
fi

# 备份Nginx配置（如果存在）
if [ -f "/etc/nginx/sites-available/delta" ]; then
    cp /etc/nginx/sites-available/delta "$BACKUP_DIR/nginx-delta.conf"
    echo "  备份Nginx配置"
fi

# 备份数据库（如果存在）
if [ -f "/var/www/delta/data/delta.db" ]; then
    cp /var/www/delta/data/delta.db "$BACKUP_DIR/delta.db.backup"
    echo "  备份数据库"
fi

echo "备份完成: $BACKUP_DIR"

# ================================================
# 4. 准备部署目录
# ================================================
log "准备部署目录..."

# 创建目录结构
mkdir -p $BASE_DIR/{public,backend,data}
mkdir -p $BASE_DIR/public/{css,js,images,admin}

# 设置权限
chown -R www-data:www-data $BASE_DIR
chmod -R 755 $BASE_DIR

# ================================================
# 5. 部署前端文件（简化版）
# ================================================
log "部署前端文件..."

# 创建首页
cat > $BASE_DIR/public/index.html << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>三角洲行动 · 护航接单平台</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            padding: 20px;
        }
        .container {
            text-align: center;
            max-width: 800px;
        }
        h1 {
            font-size: 42px;
            margin-bottom: 20px;
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        p {
            font-size: 20px;
            color: #a0a0c0;
            margin-bottom: 40px;
        }
        .links {
            display: flex;
            gap: 20px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            padding: 14px 28px;
            background: rgba(255, 255, 255, 0.1);
            color: white;
            text-decoration: none;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            transition: all 0.3s;
            font-weight: 600;
        }
        .btn:hover {
            background: rgba(255, 255, 255, 0.15);
            transform: translateY(-2px);
        }
        .btn-admin {
            background: linear-gradient(90deg, #00dbde, #fc00ff);
            border: none;
        }
        .btn-admin:hover {
            box-shadow: 0 10px 20px rgba(0, 219, 222, 0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>三角洲行动 · 护航接单平台</h1>
        <p>游戏服务交易平台 - 专业、安全、高效</p>
        <div class="links">
            <a href="/" class="btn">首页</a>
            <a href="/admin/" class="btn btn-admin">管理员入口</a>
        </div>
        <div style="margin-top: 40px; color: #8888aa; font-size: 14px;">
            <p>部署时间: $(date)</p>
            <p>服务器IP: $SERVER_IP</p>
        </div>
    </div>
</body>
</html>
EOF

# 创建管理员登录页面（简化版）
cat > $BASE_DIR/public/admin/login.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>管理员登录 - 三角洲行动</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
      padding: 20px;
    }
    .login-container {
      width: 100%;
      max-width: 500px;
    }
    .login-card {
      background: rgba(255, 255, 255, 0.05);
      backdrop-filter: blur(10px);
      border-radius: 16px;
      padding: 40px 30px;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    .logo {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo h1 {
      font-size: 28px;
      font-weight: 700;
      background: linear-gradient(90deg, #00dbde, #fc00ff);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 8px;
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
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 10px;
      color: #fff;
      font-size: 16px;
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
      cursor: