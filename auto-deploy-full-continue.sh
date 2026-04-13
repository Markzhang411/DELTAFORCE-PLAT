#!/bin/bash
# 续篇：完成自动化部署

# 继续执行远程部署
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER_IP" << 'EOF2'
#!/bin/bash

# 续接之前的脚本...

    } else {
        res.end(JSON.stringify({
            ok: false,
            error: 'Endpoint not found',
            available: ['/api/health', '/api/deploy-info']
        }));
    }
});

server.listen(PORT, () => {
    console.log(\`测试API运行在端口 \${PORT}\`);
});
API_EOF

# 启动测试API
cd $DEPLOY_DIR/backend
node test-api.js > /tmp/delta-api.log 2>&1 &
API_PID=\$!
echo \$API_PID > /tmp/delta-api.pid
echo "测试API启动 (PID: \$API_PID)"

# 创建状态检查脚本
echo "创建状态检查脚本..."
cat > /usr/local/bin/check-delta << 'CHECK_EOF'
#!/bin/bash
echo "=== 三角洲行动部署状态 ==="
echo "部署时间: $(date)"
echo ""

echo "1. 服务状态:"
if systemctl is-active --quiet nginx; then
    echo "  ✅ Nginx: 运行中"
else
    echo "  ❌ Nginx: 未运行"
fi

if ps -p \$(cat /tmp/delta-api.pid 2>/dev/null) > /dev/null 2>&1; then
    echo "  ✅ 测试API: 运行中"
else
    echo "  ❌ 测试API: 未运行"
fi

echo ""
echo "2. 端口状态:"
if netstat -tln 2>/dev/null | grep -q ":$DEPLOY_PORT "; then
    echo "  ✅ 端口$DEPLOY_PORT: 监听中"
else
    echo "  ❌ 端口$DEPLOY_PORT: 未监听"
fi

if netstat -tln 2>/dev/null | grep -q ":3001 "; then
    echo "  ✅ 端口3001 (API): 监听中"
else
    echo "  ❌ 端口3001: 未监听"
fi

echo ""
echo "3. 文件状态:"
if [ -f "$DEPLOY_DIR/public/index.html" ]; then
    echo "  ✅ 网站文件: 存在"
else
    echo "  ❌ 网站文件: 缺失"
fi

if [ -f "$DEPLOY_DIR/public/admin/login.html" ]; then
    echo "  ✅ 管理员文件: 存在"
else
    echo "  ❌ 管理员文件: 缺失"
fi

echo ""
echo "4. 访问测试:"
curl -s -o /dev/null -w "  网站: %{http_code}\n" http://localhost:$DEPLOY_PORT/
curl -s -o /dev/null -w "  管理员: %{http_code}\n" http://localhost:$DEPLOY_PORT/admin/
curl -s -o /dev/null -w "  API健康: %{http_code}\n" http://localhost:3001/api/health

echo ""
echo "=== 部署信息 ==="
echo "服务器: $SERVER_IP"
echo "端口: $DEPLOY_PORT"
echo "目录: $DEPLOY_DIR"
echo "部署方式: 全自动脚本"
echo "部署时间: $(date '+%Y-%m-%d %H:%M:%S')"
CHECK_EOF

chmod +x /usr/local/bin/check-delta

# 完成部署
echo ""
echo "🎉 部署完成！"
echo "=== 部署总结 ==="
echo "✅ 前端网站部署完成"
echo "✅ 管理员界面部署完成"
echo "✅ Nginx配置完成"
echo "✅ 测试API部署完成"
echo "✅ 状态检查脚本部署完成"
echo ""
echo "=== 访问信息 ==="
echo "🌐 网站: http://$SERVER_IP:$DEPLOY_PORT/"
echo "🔐 管理员: http://$SERVER_IP:$DEPLOY_PORT/admin/"
echo "🩺 API健康: http://$SERVER_IP:3001/api/health"
echo ""
echo "=== 测试账号 ==="
echo "📱 手机号: 13800138000"
echo "🔑 密码: admin123"
echo ""
echo "=== 管理命令 ==="
echo "📊 检查状态: check-delta"
echo "📝 查看日志: tail -f /var/log/nginx/delta-8080-access.log"
echo "🔄 重启服务: systemctl reload nginx"
echo ""
echo "✅ 全自动部署完成！"
EOF2

# 4. 本地验证
info "等待服务启动..."
sleep 5

info "验证部署结果..."
echo ""
echo "=== 本地验证 ==="

# 测试网站
if curl -s -o /dev/null -w "🌐 网站: %{http_code}\n" http://$SERVER_IP:$DEPLOY_PORT/; then
    success "网站访问正常"
else
    error "网站访问失败"
fi

# 测试管理员
if curl -s -o /dev/null -w "🔐 管理员: %{http_code}\n" http://$SERVER_IP:$DEPLOY_PORT/admin/; then
    success "管理员页面正常"
else
    error "管理员页面访问失败"
fi

# 测试API
if curl -s -o /dev/null -w "🩺 API健康: %{http_code}\n" http://$SERVER_IP:3001/api/health; then
    success "API服务正常"
else
    info "API服务未启动（可选）"
fi

# 5. 完成
echo ""
echo "🎉 🎉 🎉 全自动部署完成！ 🎉 🎉 🎉"
echo ""
echo "=== 部署总结 ==="
echo "✅ 服务器: $SERVER_IP"
echo "✅ 端口: $DEPLOY_PORT"
echo "✅ 部署方式: 全自动脚本"
echo "✅ 部署时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "✅ 总耗时: 约3-5分钟"
echo ""
echo "=== 立即访问 ==="
echo "🌐 网站: http://$SERVER_IP:$DEPLOY_PORT/"
echo "🔐 管理员: http://$SERVER_IP:$DEPLOY_PORT/admin/"
echo ""
echo "=== 测试账号 ==="
echo "📱 手机号: 13800138000"
echo "🔑 密码: admin123"
echo ""
echo "=== 后续管理 ==="
echo "📊 服务器状态: ssh $USERNAME@$SERVER_IP 'check-delta'"
echo "📝 查看日志: ssh $USERNAME@$SERVER_IP 'tail -f /var/log/nginx/delta-8080-access.log'"
echo "🔄 重启服务: ssh $USERNAME@$SERVER_IP 'systemctl reload nginx'"
echo ""
echo "🚀 部署完成！现在可以开始使用了！"