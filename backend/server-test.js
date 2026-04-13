/**
 * 测试用简化服务器 - 不依赖数据库
 */

'use strict';

const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');

const PORT = 3001; // 使用不同端口避免冲突
const JWT_SECRET = 'test_jwt_secret_2026';

// 模拟数据库数据
const mockUsers = [
  { id: 1, phone: '13800138000', password: '$2a$10$N9qo8uLOickgx2ZMRZoMy.MrqK.3.8.9.0.1.2.3.4.5.6.7.8.9', name: '测试管理员', role: 'admin', rating: 5.0, orders_done: 0, created_at: '2026-04-12 20:00:00' },
  { id: 2, phone: '13900139000', password: '$2a$10$N9qo8uLOickgx2ZMRZoMy.MrqK.3.8.9.0.1.2.3.4.5.6.7.8.9', name: '客户张三', role: 'client', rating: 4.5, orders_done: 3, created_at: '2026-04-12 19:00:00' },
  { id: 3, phone: '13700137000', password: '$2a$10$N9qo8uLOickgx2ZMRZoMy.MrqK.3.8.9.0.1.2.3.4.5.6.7.8.9', name: '护航员李四', role: 'hunter', rating: 4.8, orders_done: 15, created_at: '2026-04-12 18:00:00' }
];

const mockOrders = [
  { id: 1, order_id: 'ORD12345678', service_type: 'escort', map: 'hangtian', price: 200, status: 'pending', remark: '新手求带', client_id: 2, created_at: '2026-04-12 20:30:00' },
  { id: 2, order_id: 'ORD12345679', service_type: 'loot', map: 'linghaodaba', price: 50, status: 'doing', remark: '刷材料', client_id: 2, hunter_id: 3, created_at: '2026-04-12 19:30:00' },
  { id: 3, order_id: 'ORD12345680', service_type: 'crash', map: 'bakashi', price: 0, status: 'completed', remark: '交换物资', client_id: 2, hunter_id: 3, created_at: '2026-04-12 18:30:00' }
];

const app = express();
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 速率限制
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 20,
  message: { ok: false, msg: '请求过于频繁' },
});

// 中间件
function authRequired(req, res, next) {
  const auth = req.headers['authorization'] || '';
  const token = auth.replace('Bearer ', '').trim();
  if (!token) return res.json({ ok: false, msg: '请先登录' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch(e) {
    res.json({ ok: false, msg: 'Token 已过期' });
  }
}

function adminRequired(req, res, next) {
  if (!req.user) return res.json({ ok: false, msg: '请先登录' });
  if (req.user.role !== 'admin') {
    return res.json({ ok: false, msg: '需要管理员权限' });
  }
  next();
}

// 公共API
app.get('/api/stats', (req, res) => {
  res.json({
    ok: true,
    stats: {
      total: mockOrders.length,
      pending: mockOrders.filter(o => o.status === 'pending').length,
      active: mockOrders.filter(o => ['locked', 'doing'].includes(o.status)).length,
      users: mockUsers.length,
      done: mockOrders.filter(o => o.status === 'completed').length
    }
  });
});

// 管理员登录
app.post('/api/admin/login', loginLimiter, (req, res) => {
  const { phone, password } = req.body;
  
  if (!phone || !password) {
    return res.json({ ok: false, msg: '请输入手机号和密码' });
  }
  
  const user = mockUsers.find(u => u.phone === phone && u.role === 'admin');
  if (!user) {
    return res.json({ ok: false, msg: '管理员账号不存在' });
  }
  
  // 模拟密码验证 (实际应该用bcrypt)
  if (password !== 'admin123') {
    return res.json({ ok: false, msg: '密码错误' });
  }
  
  const token = jwt.sign(
    { id: user.id, phone: user.phone, name: user.name, role: user.role },
    JWT_SECRET, { expiresIn: '30d' }
  );
  
  res.json({
    ok: true, msg: '管理员登录成功', token,
    user: { id: user.id, phone: user.phone, name: user.name, role: user.role }
  });
});

// 管理员API - 获取用户列表
app.get('/api/admin/users', adminRequired, (req, res) => {
  const { page = 1, limit = 20, search = '', role = '' } = req.query;
  const offset = (Number(page) - 1) * Number(limit);
  
  let filteredUsers = [...mockUsers];
  
  if (search) {
    filteredUsers = filteredUsers.filter(u => 
      u.phone.includes(search) || u.name.includes(search)
    );
  }
  
  if (role && role !== 'all') {
    filteredUsers = filteredUsers.filter(u => u.role === role);
  }
  
  const paginatedUsers = filteredUsers.slice(offset, offset + Number(limit));
  
  res.json({
    ok: true,
    users: paginatedUsers,
    total: filteredUsers.length,
    page: Number(page)
  });
});

// 管理员API - 获取订单列表
app.get('/api/admin/orders', adminRequired, (req, res) => {
  const { page = 1, limit = 20, status = '', type = '' } = req.query;
  const offset = (Number(page) - 1) * Number(limit);
  
  let filteredOrders = [...mockOrders];
  
  if (status && status !== 'all') {
    filteredOrders = filteredOrders.filter(o => o.status === status);
  }
  
  if (type && type !== 'all') {
    filteredOrders = filteredOrders.filter(o => o.service_type === type);
  }
  
  const paginatedOrders = filteredOrders.slice(offset, offset + Number(limit));
  
  // 添加用户信息
  const ordersWithUsers = paginatedOrders.map(order => ({
    ...order,
    client_name: mockUsers.find(u => u.id === order.client_id)?.name || '未知',
    hunter_name: order.hunter_id ? mockUsers.find(u => u.id === order.hunter_id)?.name || '未知' : null
  }));
  
  res.json({
    ok: true,
    orders: ordersWithUsers,
    total: filteredOrders.length,
    page: Number(page)
  });
});

// 管理员API - 获取统计信息
app.get('/api/admin/stats', adminRequired, (req, res) => {
  const totalOrders = mockOrders.length;
  const pendingOrders = mockOrders.filter(o => o.status === 'pending').length;
  const activeOrders = mockOrders.filter(o => ['locked', 'doing'].includes(o.status)).length;
  const totalUsers = mockUsers.length;
  const completedOrders = mockOrders.filter(o => o.status === 'completed').length;
  const totalRevenue = mockOrders.filter(o => o.status === 'completed').reduce((sum, o) => sum + o.price, 0);
  
  const roleStats = [
    { role: 'admin', count: mockUsers.filter(u => u.role === 'admin').length },
    { role: 'hunter', count: mockUsers.filter(u => u.role === 'hunter').length },
    { role: 'client', count: mockUsers.filter(u => u.role === 'client').length }
  ];
  
  const serviceStats = [
    { service_type: 'escort', count: mockOrders.filter(o => o.service_type === 'escort').length },
    { service_type: 'loot', count: mockOrders.filter(o => o.service_type === 'loot').length },
    { service_type: 'crash', count: mockOrders.filter(o => o.service_type === 'crash').length }
  ];
  
  res.json({
    ok: true,
    stats: {
      totalOrders, pendingOrders, activeOrders, totalUsers, completedOrders, totalRevenue,
      roleStats, serviceStats,
      dailyTrend: [
        { date: '2026-04-12', count: 3, revenue: 250 },
        { date: '2026-04-11', count: 2, revenue: 180 },
        { date: '2026-04-10', count: 1, revenue: 100 }
      ]
    }
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════╗
  ║  测试服务器已启动                  ║
  ║  http://localhost:${PORT}           ║
  ║                                   ║
  ║  测试账号:                        ║
  ║  手机号: 13800138000              ║
  ║  密码: admin123                   ║
  ╚═══════════════════════════════════╝
  `);
  
  console.log('\n📋 可用API:');
  console.log('  GET  /api/stats              - 公开统计');
  console.log('  POST /api/admin/login        - 管理员登录');
  console.log('  GET  /api/admin/users        - 用户列表 (需要管理员token)');
  console.log('  GET  /api/admin/orders       - 订单列表 (需要管理员token)');
  console.log('  GET  /api/admin/stats        - 详细统计 (需要管理员token)');
  
  console.log('\n🌐 管理员控制台:');
  console.log('  登录页面: http://localhost:3001/admin/login.html');
  console.log('  注意: 需要修改前端API_BASE为 http://localhost:3001');
});