/**
 * 模拟API服务器 - 提供管理员控制台测试数据
 * 运行: node mock-api.js
 */

const http = require('http');
const url = require('url');

const PORT = 3000;
const JWT_SECRET = 'test_jwt_secret_2026';

// 模拟数据
const mockData = {
  users: [
    { id: 1, phone: '13800138000', name: '系统管理员', role: 'admin', rating: 5.0, orders_done: 0, created_at: '2026-04-12 20:00:00', last_login: '2026-04-12 21:00:00' },
    { id: 2, phone: '13900139000', name: '客户张三', role: 'client', rating: 4.5, orders_done: 3, created_at: '2026-04-12 19:00:00', last_login: '2026-04-12 20:30:00' },
    { id: 3, phone: '13700137000', name: '护航员李四', role: 'hunter', rating: 4.8, orders_done: 15, created_at: '2026-04-12 18:00:00', last_login: '2026-04-12 20:00:00' },
    { id: 4, phone: '13600136000', name: '客户王五', role: 'client', rating: 4.2, orders_done: 1, created_at: '2026-04-12 17:00:00', last_login: '2026-04-12 19:30:00' },
    { id: 5, phone: '13500135000', name: '护航员赵六', role: 'hunter', rating: 4.9, orders_done: 8, created_at: '2026-04-12 16:00:00', last_login: '2026-04-12 19:00:00' }
  ],
  orders: [
    { id: 1, order_id: 'ORD20260412001', service_type: 'escort', map: 'hangtian', price: 200, status: 'pending', remark: '新手求带', client_id: 2, created_at: '2026-04-12 20:30:00' },
    { id: 2, order_id: 'ORD20260412002', service_type: 'loot', map: 'linghaodaba', price: 50, status: 'doing', remark: '刷材料', client_id: 2, hunter_id: 3, created_at: '2026-04-12 19:30:00' },
    { id: 3, order_id: 'ORD20260412003', service_type: 'crash', map: 'bakashi', price: 0, status: 'completed', remark: '交换物资', client_id: 4, hunter_id: 5, created_at: '2026-04-12 18:30:00' },
    { id: 4, order_id: 'ORD20260412004', service_type: 'clear', map: 'chaoxi', price: 80, status: 'pending', remark: '清图服务', client_id: 4, created_at: '2026-04-12 17:30:00' },
    { id: 5, order_id: 'ORD20260412005', service_type: 'escort', map: 'changong', price: 150, status: 'locked', remark: '带新手', client_id: 2, hunter_id: 5, created_at: '2026-04-12 16:30:00' }
  ]
};

// 简单的JWT生成（仅用于演示）
function generateToken(user) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64');
  const payload = Buffer.from(JSON.stringify({
    id: user.id,
    phone: user.phone,
    name: user.name,
    role: user.role,
    exp: Math.floor(Date.now() / 1000) + 3600 // 1小时过期
  })).toString('base64');
  const signature = 'mock_signature_for_demo';
  return `${header}.${payload}.${signature}`;
}

// 解析查询参数
function parseQueryParams(queryString) {
  const params = {};
  if (queryString) {
    queryString.split('&').forEach(param => {
      const [key, value] = param.split('=');
      if (key && value) {
        params[key] = decodeURIComponent(value);
      }
    });
  }
  return params;
}

// 创建HTTP服务器
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url);
  const path = parsedUrl.pathname;
  const query = parseQueryParams(parsedUrl.query);
  
  // 设置CORS头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  
  // 处理预检请求
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  console.log(`${req.method} ${path}`);
  
  // 路由处理
  if (req.method === 'GET') {
    handleGetRequest(req, res, path, query);
  } else if (req.method === 'POST') {
    handlePostRequest(req, res, path);
  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ ok: false, msg: 'API not found' }));
  }
});

function handleGetRequest(req, res, path, query) {
  // 公开统计
  if (path === '/api/stats') {
    const stats = {
      total: mockData.orders.length,
      pending: mockData.orders.filter(o => o.status === 'pending').length,
      active: mockData.orders.filter(o => ['locked', 'doing'].includes(o.status)).length,
      users: mockData.users.length,
      done: mockData.orders.filter(o => o.status === 'completed').length
    };
    res.writeHead(200);
    res.end(JSON.stringify({ ok: true, stats }));
    return;
  }
  
  // 检查Authorization头
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.writeHead(401);
    res.end(JSON.stringify({ ok: false, msg: '需要登录' }));
    return;
  }
  
  const token = authHeader.replace('Bearer ', '');
  // 简单验证token（演示用）
  if (!token.includes('mock_signature_for_demo')) {
    res.writeHead(401);
    res.end(JSON.stringify({ ok: false, msg: 'Token无效' }));
    return;
  }
  
  // 管理员API
  if (path === '/api/admin/users') {
    const { page = 1, limit = 20, search = '', role = '' } = query;
    const offset = (Number(page) - 1) * Number(limit);
    
    let filteredUsers = [...mockData.users];
    
    if (search) {
      filteredUsers = filteredUsers.filter(u => 
        u.phone.includes(search) || u.name.includes(search)
      );
    }
    
    if (role && role !== 'all') {
      filteredUsers = filteredUsers.filter(u => u.role === role);
    }
    
    const paginatedUsers = filteredUsers.slice(offset, offset + Number(limit));
    
    res.writeHead(200);
    res.end(JSON.stringify({
      ok: true,
      users: paginatedUsers,
      total: filteredUsers.length,
      page: Number(page)
    }));
    return;
  }
  
  if (path === '/api/admin/orders') {
    const { page = 1, limit = 20, status = '', type = '' } = query;
    const offset = (Number(page) - 1) * Number(limit);
    
    let filteredOrders = [...mockData.orders];
    
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
      client_name: mockData.users.find(u => u.id === order.client_id)?.name || '未知',
      hunter_name: order.hunter_id ? mockData.users.find(u => u.id === order.hunter_id)?.name || '未知' : null
    }));
    
    res.writeHead(200);
    res.end(JSON.stringify({
      ok: true,
      orders: ordersWithUsers,
      total: filteredOrders.length,
      page: Number(page)
    }));
    return;
  }
  
  if (path === '/api/admin/stats') {
    const totalOrders = mockData.orders.length;
    const pendingOrders = mockData.orders.filter(o => o.status === 'pending').length;
    const activeOrders = mockData.orders.filter(o => ['locked', 'doing'].includes(o.status)).length;
    const totalUsers = mockData.users.length;
    const completedOrders = mockData.orders.filter(o => o.status === 'completed').length;
    const totalRevenue = mockData.orders.filter(o => o.status === 'completed').reduce((sum, o) => sum + o.price, 0);
    
    const roleStats = [
      { role: 'admin', count: mockData.users.filter(u => u.role === 'admin').length },
      { role: 'hunter', count: mockData.users.filter(u => u.role === 'hunter').length },
      { role: 'client', count: mockData.users.filter(u => u.role === 'client').length }
    ];
    
    const serviceStats = [
      { service_type: 'escort', count: mockData.orders.filter(o => o.service_type === 'escort').length },
      { service_type: 'loot', count: mockData.orders.filter(o => o.service_type === 'loot').length },
      { service_type: 'crash', count: mockData.orders.filter(o => o.service_type === 'crash').length },
      { service_type: 'clear', count: mockData.orders.filter(o => o.service_type === 'clear').length }
    ];
    
    res.writeHead(200);
    res.end(JSON.stringify({
      ok: true,
      stats: {
        totalOrders, pendingOrders, activeOrders, totalUsers, completedOrders, totalRevenue,
        roleStats, serviceStats,
        dailyTrend: [
          { date: '2026-04-12', count: 5, revenue: 480 },
          { date: '2026-04-11', count: 3, revenue: 320 },
          { date: '2026-04-10', count: 2, revenue: 180 }
        ]
      }
    }));
    return;
  }
  
  // 未找到的API
  res.writeHead(404);
  res.end(JSON.stringify({ ok: false, msg: 'API not found' }));
}

function handlePostRequest(req, res, path) {
  let body = '';
  
  req.on('data', chunk => {
    body += chunk.toString();
  });
  
  req.on('end', () => {
    try {
      const data = JSON.parse(body);
      
      if (path === '/api/admin/login') {
        const { phone, password } = data;
        
        if (!phone || !password) {
          res.writeHead(400);
          res.end(JSON.stringify({ ok: false, msg: '请输入手机号和密码' }));
          return;
        }
        
        const user = mockData.users.find(u => u.phone === phone && u.role === 'admin');
        if (!user) {
          res.writeHead(401);
          res.end(JSON.stringify({ ok: false, msg: '管理员账号不存在' }));
          return;
        }
        
        // 演示用，固定密码
        if (password !== 'admin123') {
          res.writeHead(401);
          res.end(JSON.stringify({ ok: false, msg: '密码错误' }));
          return;
        }
        
        const token = generateToken(user);
        
        res.writeHead(200);
        res.end(JSON.stringify({
          ok: true,
          msg: '管理员登录成功',
          token,
          user: { id: user.id, phone: user.phone, name: user.name, role: user.role }
        }));
        return;
      }
      
      // 其他POST API
      res.writeHead(404);
      res.end(JSON.stringify({ ok: false, msg: 'API not found' }));
      
    } catch (error) {
      res.writeHead(400);
      res.end(JSON.stringify({ ok: false, msg: '请求数据格式错误' }));
    }
  });
}

// 启动服务器
server.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════╗
  ║  模拟API服务器已启动              ║
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
  console.log('  GET  /api/admin/users        - 用户列表 (需要token)');
  console.log('  GET  /api/admin/orders       - 订单列表 (需要token)');
  console.log('  GET  /api/admin/stats        - 详细统计 (需要token)');
  
  console.log('\n🌐 访问地址:');
  console.log('  静态文件: http://localhost:8000/admin/login.html');
  console.log('  注意: 前端需要修改API_BASE为 http://localhost:3000');
});