# 三角洲行动 · 管理员控制台

## 📋 功能概述

管理员控制台为平台管理员提供完整的管理功能，包括用户管理、订单管理、数据统计和系统监控。

## 🚀 快速开始

### 访问地址
- 管理员登录: `http://你的域名/admin/login.html`
- 管理仪表盘: `http://你的域名/admin/dashboard.html`

### 默认测试账号
```
手机号: 13800138000
密码: admin123
```

> **注意**: 首次使用需要在开发环境创建管理员账号，或修改数据库直接添加。

## 🔧 功能模块

### 1. 仪表盘 (Dashboard)
- 平台数据概览
- 实时统计卡片
- 最近订单和用户
- 快速操作入口

### 2. 用户管理 (Users)
- 查看所有用户列表
- 搜索和筛选用户
- 编辑用户信息
- 修改用户角色
- 删除用户（安全验证）

### 3. 订单管理 (Orders)
- 查看所有订单
- 按状态筛选订单
- 修改订单信息
- 删除订单
- 订单状态跟踪

### 4. 数据统计 (Statistics)
- 详细平台数据
- 收入统计
- 用户分布
- 服务类型分析
- 7天趋势图表

### 5. 系统日志 (Logs)
- 最近操作记录
- 用户活动跟踪
- 订单变更历史

### 6. 系统设置 (Settings)
- 平台配置管理
- 安全设置
- 通知设置

## 🔐 安全特性

### 权限控制
- 仅限 `role='admin'` 的用户访问
- JWT Token 认证
- 自动Token过期处理

### API保护
- 管理员专用API路由
- 请求频率限制
- 输入验证和过滤

### 数据安全
- 敏感操作确认提示
- 删除操作二次确认
- 操作日志记录

## 🛠️ 技术架构

### 前端技术
- 纯HTML/CSS/JavaScript
- 响应式设计
- 现代UI组件
- 实时数据更新

### 后端API
- Node.js + Express
- JWT身份验证
- SQLite数据库
- RESTful API设计

### 安全措施
- bcrypt密码哈希
- 请求速率限制
- CORS配置
- 输入验证

## 📁 文件结构

```
admin/
├── login.html          # 管理员登录页面
├── dashboard.html      # 管理仪表盘
├── users.html          # 用户管理
├── orders.html         # 订单管理
├── stats.html          # 数据统计
├── logs.html           # 系统日志
├── settings.html       # 系统设置
└── README.md           # 本文档
```

## 🔄 API接口

### 管理员认证
- `POST /api/admin/login` - 管理员登录
- `POST /api/admin/create` - 创建管理员（开发环境）

### 用户管理
- `GET /api/admin/users` - 获取用户列表
- `PUT /api/admin/users/:id` - 更新用户信息
- `DELETE /api/admin/users/:id` - 删除用户

### 订单管理
- `GET /api/admin/orders` - 获取订单列表
- `PUT /api/admin/orders/:orderId` - 更新订单
- `DELETE /api/admin/orders/:orderId` - 删除订单

### 数据统计
- `GET /api/admin/stats` - 获取详细统计
- `GET /api/stats` - 获取公开统计（无需认证）

## 🚨 注意事项

### 生产环境部署
1. 修改默认JWT密钥
2. 禁用 `/api/admin/create` 接口
3. 配置HTTPS加密
4. 设置访问日志
5. 定期备份数据库

### 安全建议
1. 使用强密码策略
2. 定期更换管理员密码
3. 监控管理员操作日志
4. 限制管理员登录IP
5. 启用双因素认证（如需）

### 性能优化
1. 启用数据库索引
2. 配置查询缓存
3. 压缩静态资源
4. 使用CDN加速
5. 监控API响应时间

## 🐛 故障排除

### 常见问题

**Q: 无法登录管理员控制台**
- 检查管理员账号是否存在
- 确认数据库连接正常
- 验证JWT密钥配置

**Q: API返回权限错误**
- 确认用户角色为 `admin`
- 检查Token是否过期
- 验证请求头中的Authorization

**Q: 页面加载缓慢**
- 检查网络连接
- 验证服务器资源使用
- 优化数据库查询

**Q: 数据不显示**
- 检查API响应状态
- 验证数据库数据
- 查看浏览器控制台错误

### 日志查看
```bash
# 查看后端日志
pm2 logs delta

# 查看Nginx访问日志
tail -f /var/log/nginx/access.log

# 查看错误日志
tail -f /var/log/nginx/error.log
```

## 📞 技术支持

如需技术支持，请联系：
- 系统管理员
- 开发团队
- 查看服务器日志

## 📄 版本历史

### v1.0.0 (2026-04-12)
- 初始版本发布
- 基础管理功能
- 完整API支持
- 响应式界面

---

**© 2026 三角洲行动 · 管理员控制台**