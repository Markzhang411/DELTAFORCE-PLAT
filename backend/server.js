/**
 * 代号Delta · 游戏服务平台 · 后端 API
 * Node.js + Express + SQLite (better-sqlite3)
 *
 * 端口: 3000
 * 数据库: /var/www/delta/data/delta.db (生产) | ./delta.db (开发)
 */

'use strict';

const express    = require('express');
const cors       = require('cors');
const bcrypt     = require('bcryptjs');
const jwt        = require('jsonwebtoken');
const rateLimit  = require('express-rate-limit');
const path       = require('path');
const fs         = require('fs');

// ── SQLite 初始化 ─────────────────────────────────────────────
const Database = require('better-sqlite3');
const DB_PATH  = process.env.NODE_ENV === 'production'
  ? '/var/www/delta/data/delta.db'
  : path.join(__dirname, 'delta.db');

const db = new Database(DB_PATH, { verbose: process.env.DEBUG ? console.log : null });

// WAL 模式提高并发性能
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// ── 建表 ──────────────────────────────────────────────────────
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    phone       TEXT    UNIQUE NOT NULL,
    password    TEXT    NOT NULL,
    name        TEXT    NOT NULL DEFAULT '',
    role        TEXT    NOT NULL DEFAULT 'client',
    avatar      TEXT    DEFAULT '',
    rating      REAL    DEFAULT 5.0,
    orders_done INTEGER DEFAULT 0,
    created_at  TEXT    DEFAULT (datetime('now')),
    last_login  TEXT
  );

  CREATE TABLE IF NOT EXISTS orders (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id     TEXT    UNIQUE NOT NULL,
    service_type TEXT    NOT NULL,
    map          TEXT    NOT NULL,
    price        REAL    DEFAULT 0,
    status       TEXT    DEFAULT 'pending',
    remark       TEXT    DEFAULT '',
    client_id    INTEGER,
    hunter_id    INTEGER,
    created_at   TEXT    DEFAULT (datetime('now')),
    updated_at   TEXT    DEFAULT (datetime('now')),
    FOREIGN KEY (client_id) REFERENCES users(id),
    FOREIGN KEY (hunter_id) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS messages (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id   TEXT    NOT NULL,
    sender_id  INTEGER NOT NULL,
    content    TEXT    NOT NULL,
    created_at TEXT    DEFAULT (datetime('now')),
    FOREIGN KEY (sender_id) REFERENCES users(id)
  );

  CREATE INDEX IF NOT EXISTS idx_orders_status       ON orders(status);
  CREATE INDEX IF NOT EXISTS idx_orders_service_type ON orders(service_type);
  CREATE INDEX IF NOT EXISTS idx_orders_client_id    ON orders(client_id);
  CREATE INDEX IF NOT EXISTS idx_orders_hunter_id    ON orders(hunter_id);
  CREATE INDEX IF NOT EXISTS idx_messages_order_id   ON messages(order_id);
`);

// ── 插入演示数据 (首次) ───────────────────────────────────────
const countOrders = db.prepare('SELECT COUNT(*) as n FROM orders').get();
if (countOrders.n === 0) {
  const insertOrder = db.prepare(`
    INSERT INTO orders (order_id, service_type, map, price, status, remark)
    VALUES (@order_id, @service_type, @map, @price, @status, @remark)
  `);
  const demos = [
    { order_id:'DEMO001', service_type:'escort', map:'hangtian',    price:200, status:'pending',   remark:'' },
    { order_id:'DEMO002', service_type:'loot',   map:'linghaodaba', price:30,  status:'doing',     remark:'' },
    { order_id:'DEMO003', service_type:'crash',  map:'bakashi',     price:0,   status:'pending',   remark:'换大红+金块' },
    { order_id:'DEMO004', service_type:'clear',  map:'chaoxi',      price:80,  status:'pending',   remark:'' },
    { order_id:'DEMO005', service_type:'escort', map:'changong',    price:150, status:'pending',   remark:'新手，请多关照' },
    { order_id:'DEMO006', service_type:'loot',   map:'hangtian',    price:45,  status:'completed', remark:'' },
  ];
  const insertMany = db.transaction((rows) => { for (const r of rows) insertOrder.run(r); });
  insertMany(demos);
  console.log('[Delta] 已插入演示订单');
}

// ── 常量 ─────────────────────────────────────────────────────
const JWT_SECRET = process.env.JWT_SECRET || 'delta_jwt_secret_2026_change_me';
const PORT       = process.env.PORT || 3000;

const MAPS = {
  hangtian:'航天基地', chaoxi:'潮汐监狱', linghaodaba:'零号大坝',
  bakashi:'巴克什', changong:'长弓溪谷',
};
const SERVICE_TYPES = {
  escort:'陪玩护航', loot:'组队刷图', crash:'物资互助', clear:'清图服务',
};

// ── Express 应用 ──────────────────────────────────────────────
const app = express();

app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 速率限制（防止暴力破解）
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 20,
  message: { ok: false, msg: '请求过于频繁，请15分钟后重试' },
});

// ── JWT 中间件 ────────────────────────────────────────────────
function authRequired(req, res, next) {
  const auth = req.headers['authorization'] || '';
  const token = auth.replace('Bearer ', '').trim();
  if (!token) return res.json({ ok: false, msg: '请先登录' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch(e) {
    res.json({ ok: false, msg: 'Token 已过期，请重新登录' });
  }
}

// ── 管理员权限中间件 ────────────────────────────────────────────
function adminRequired(req, res, next) {
  if (!req.user) return res.json({ ok: false, msg: '请先登录' });
  if (req.user.role !== 'admin') {
    return res.json({ ok: false, msg: '需要管理员权限' });
  }
  next();
}

// ── 时间格式化 ────────────────────────────────────────────────
function timeAgo(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr + 'Z').getTime();
  if (diff < 60000) return '刚刚';
  if (diff < 3600000) return Math.floor(diff/60000) + '分钟前';
  if (diff < 86400000) return Math.floor(diff/3600000) + '小时前';
  return Math.floor(diff/86400000) + '天前';
}

function fmtOrder(o) {
  return {
    ...o,
    mapName:         MAPS[o.map] || o.map,
    serviceTypeName: SERVICE_TYPES[o.service_type] || o.service_type,
    time:            timeAgo(o.created_at),
  };
}

// ═══════════════════════════════════════════════════════════════
//  API 路由
// ═══════════════════════════════════════════════════════════════

// ── 健康检查 ──────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ ok: true, msg: '代号Delta API 运行中', time: new Date().toISOString() });
});

// ── 用户注册 ──────────────────────────────────────────────────
app.post('/api/auth/register', loginLimiter, (req, res) => {
  const { phone, password, role = 'client' } = req.body;
  if (!phone || !password) return res.json({ ok: false, msg: '手机号和密码不能为空' });
  if (!/^1[3-9]\d{9}$/.test(phone)) return res.json({ ok: false, msg: '手机号格式不正确' });
  if (password.length < 6) return res.json({ ok: false, msg: '密码至少6位' });

  const exists = db.prepare('SELECT id FROM users WHERE phone = ?').get(phone);
  if (exists) return res.json({ ok: false, msg: '该手机号已注册' });

  const hash = bcrypt.hashSync(password, 10);
  const name = '玩家_' + phone.slice(-4);

  try {
    const info = db.prepare(`
      INSERT INTO users (phone, password, name, role) VALUES (?, ?, ?, ?)
    `).run(phone, hash, name, role);

    const token = jwt.sign({ id: info.lastInsertRowid, phone, name, role }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ ok: true, msg: '注册成功', token, user: { id: info.lastInsertRowid, phone, name, role, rating: 5.0, orders_done: 0 } });
  } catch(e) {
    res.json({ ok: false, msg: '注册失败: ' + e.message });
  }
});

// ── 用户登录 ──────────────────────────────────────────────────
app.post('/api/auth/login', loginLimiter, (req, res) => {
  const { phone, password } = req.body;
  if (!phone || !password) return res.json({ ok: false, msg: '手机号和密码不能为空' });

  const user = db.prepare('SELECT * FROM users WHERE phone = ?').get(phone);
  if (!user) return res.json({ ok: false, msg: '手机号或密码错误' });

  const match = bcrypt.compareSync(password, user.password);
  if (!match) return res.json({ ok: false, msg: '手机号或密码错误' });

  // 更新最后登录时间
  db.prepare("UPDATE users SET last_login = datetime('now') WHERE id = ?").run(user.id);

  const token = jwt.sign(
    { id: user.id, phone: user.phone, name: user.name, role: user.role },
    JWT_SECRET, { expiresIn: '30d' }
  );
  res.json({
    ok: true, msg: '登录成功', token,
    user: { id: user.id, phone: user.phone, name: user.name, role: user.role, rating: user.rating, orders_done: user.orders_done },
  });
});

// ── 获取当前用户信息 ──────────────────────────────────────────
app.get('/api/auth/me', authRequired, (req, res) => {
  const user = db.prepare('SELECT id,phone,name,role,rating,orders_done,created_at FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.json({ ok: false, msg: '用户不存在' });
  res.json({ ok: true, user });
});

// ── 切换角色 ──────────────────────────────────────────────────
app.post('/api/auth/role', authRequired, (req, res) => {
  const { role } = req.body;
  if (!['client','hunter'].includes(role)) return res.json({ ok: false, msg: '无效角色' });
  db.prepare('UPDATE users SET role = ? WHERE id = ?').run(role, req.user.id);
  const token = jwt.sign({ ...req.user, role }, JWT_SECRET, { expiresIn: '30d' });
  res.json({ ok: true, role, token });
});

// ── 获取市场订单列表 ──────────────────────────────────────────
app.get('/api/orders', (req, res) => {
  const { type, status = 'pending', page = 1, limit = 20 } = req.query;
  const offset = (Number(page) - 1) * Number(limit);

  let sql = `
    SELECT o.*, u.name as client_name, u.rating as client_rating
    FROM orders o
    LEFT JOIN users u ON o.client_id = u.id
    WHERE 1=1
  `;
  const params = [];

  if (type && type !== 'all') { sql += ' AND o.service_type = ?'; params.push(type); }
  if (status !== 'all')       { sql += ' AND o.status = ?';       params.push(status); }

  sql += ' ORDER BY o.created_at DESC LIMIT ? OFFSET ?';
  params.push(Number(limit), offset);

  try {
    const rows = db.prepare(sql).all(...params);
    const total = db.prepare(
      'SELECT COUNT(*) as n FROM orders WHERE 1=1' +
      (type && type !== 'all' ? ' AND service_type = ?' : '') +
      (status !== 'all' ? ' AND status = ?' : '')
    ).get(...params.slice(0, -2)).n;

    res.json({ ok: true, orders: rows.map(fmtOrder), total, page: Number(page) });
  } catch(e) {
    res.json({ ok: false, msg: e.message });
  }
});

// ── 发布订单 ──────────────────────────────────────────────────
app.post('/api/orders', authRequired, (req, res) => {
  const { service_type, map, price = 0, remark = '' } = req.body;
  if (!service_type) return res.json({ ok: false, msg: '请选择服务类型' });
  if (!map)          return res.json({ ok: false, msg: '请选择地图' });
  if (!MAPS[map])    return res.json({ ok: false, msg: '无效地图' });

  const order_id = 'ORD' + Date.now().toString().slice(-10);

  try {
    const info = db.prepare(`
      INSERT INTO orders (order_id, service_type, map, price, remark, client_id)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(order_id, service_type, map, Number(price), remark, req.user.id);

    const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(info.lastInsertRowid);
    res.json({ ok: true, msg: '订单已发布', order: fmtOrder(order) });
  } catch(e) {
    res.json({ ok: false, msg: e.message });
  }
});

// ── 接单 ──────────────────────────────────────────────────────
app.post('/api/orders/:orderId/take', authRequired, (req, res) => {
  const { orderId } = req.params;
  const order = db.prepare('SELECT * FROM orders WHERE order_id = ?').get(orderId);

  if (!order)                         return res.json({ ok: false, msg: '订单不存在' });
  if (order.status !== 'pending')     return res.json({ ok: false, msg: '该订单已被接单' });
  if (order.client_id === req.user.id) return res.json({ ok: false, msg: '不能接自己的订单' });

  db.prepare(`
    UPDATE orders SET status = 'locked', hunter_id = ?, updated_at = datetime('now')
    WHERE order_id = ?
  `).run(req.user.id, orderId);

  res.json({ ok: true, msg: '接单成功，请联系发布者' });
});

// ── 更新订单状态 ──────────────────────────────────────────────
app.put('/api/orders/:orderId/status', authRequired, (req, res) => {
  const { orderId } = req.params;
  const { status } = req.body;
  const validStatuses = ['pending','locked','doing','completed','cancelled'];

  if (!validStatuses.includes(status)) return res.json({ ok: false, msg: '无效状态' });

  const order = db.prepare('SELECT * FROM orders WHERE order_id = ?').get(orderId);
  if (!order) return res.json({ ok: false, msg: '订单不存在' });

  // 只有相关用户才能修改
  if (order.client_id !== req.user.id && order.hunter_id !== req.user.id) {
    return res.json({ ok: false, msg: '无权修改此订单' });
  }

  db.prepare("UPDATE orders SET status = ?, updated_at = datetime('now') WHERE order_id = ?")
    .run(status, orderId);

  // 完成订单时增加服务者计数
  if (status === 'completed' && order.hunter_id) {
    db.prepare('UPDATE users SET orders_done = orders_done + 1 WHERE id = ?').run(order.hunter_id);
  }

  res.json({ ok: true, msg: '状态已更新' });
});

// ── 我的订单 ──────────────────────────────────────────────────
app.get('/api/my-orders', authRequired, (req, res) => {
  const { status } = req.query;
  let sql = `
    SELECT o.*, u.name as hunter_name
    FROM orders o
    LEFT JOIN users u ON o.hunter_id = u.id
    WHERE o.client_id = ?
  `;
  const params = [req.user.id];
  if (status && status !== 'all') { sql += ' AND o.status = ?'; params.push(status); }
  sql += ' ORDER BY o.created_at DESC';

  const rows = db.prepare(sql).all(...params);
  res.json({ ok: true, orders: rows.map(fmtOrder) });
});

// ── 我接的单 ──────────────────────────────────────────────────
app.get('/api/taken-orders', authRequired, (req, res) => {
  const rows = db.prepare(`
    SELECT o.*, u.name as client_name
    FROM orders o
    LEFT JOIN users u ON o.client_id = u.id
    WHERE o.hunter_id = ?
    ORDER BY o.updated_at DESC
  `).all(req.user.id);
  res.json({ ok: true, orders: rows.map(fmtOrder) });
});

// ── 平台统计 ──────────────────────────────────────────────────
app.get('/api/stats', (req, res) => {
  const total   = db.prepare("SELECT COUNT(*) as n FROM orders").get().n;
  const pending = db.prepare("SELECT COUNT(*) as n FROM orders WHERE status='pending'").get().n;
  const active  = db.prepare("SELECT COUNT(*) as n FROM orders WHERE status IN ('locked','doing')").get().n;
  const users   = db.prepare("SELECT COUNT(*) as n FROM users").get().n;
  const done    = db.prepare("SELECT COUNT(*) as n FROM orders WHERE status='completed'").get().n;

  res.json({ ok: true, stats: { total, pending, active, users, done } });
});

// ── 发送消息 ──────────────────────────────────────────────────
app.post('/api/messages', authRequired, (req, res) => {
  const { order_id, content } = req.body;
  if (!order_id || !content) return res.json({ ok: false, msg: '参数缺失' });

  const order = db.prepare('SELECT * FROM orders WHERE order_id = ?').get(order_id);
  if (!order) return res.json({ ok: false, msg: '订单不存在' });

  db.prepare('INSERT INTO messages (order_id, sender_id, content) VALUES (?, ?, ?)')
    .run(order_id, req.user.id, content.trim());

  res.json({ ok: true, msg: '发送成功' });
});

// ── 获取订单消息 ──────────────────────────────────────────────
app.get('/api/messages/:orderId', authRequired, (req, res) => {
  const rows = db.prepare(`
    SELECT m.*, u.name as sender_name, u.role as sender_role
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    WHERE m.order_id = ?
    ORDER BY m.created_at ASC
  `).all(req.params.orderId);

  res.json({ ok: true, messages: rows });
});

// ── 取消订单 ──────────────────────────────────────────────────
app.delete('/api/orders/:orderId', authRequired, (req, res) => {
  const order = db.prepare('SELECT * FROM orders WHERE order_id = ?').get(req.params.orderId);
  if (!order) return res.json({ ok: false, msg: '订单不存在' });
  if (order.client_id !== req.user.id) return res.json({ ok: false, msg: '无权操作' });
  if (!['pending'].includes(order.status)) return res.json({ ok: false, msg: '只能取消待接单的订单' });

  db.prepare("UPDATE orders SET status='cancelled', updated_at=datetime('now') WHERE order_id=?")
    .run(req.params.orderId);
  res.json({ ok: true, msg: '订单已取消' });
});

// ═══════════════════════════════════════════════════════════════
//  管理员 API
// ═══════════════════════════════════════════════════════════════

// ── 管理员登录（特殊权限） ──────────────────────────────────────
app.post('/api/admin/login', loginLimiter, (req, res) => {
  const { phone, password } = req.body;
  if (!phone || !password) return res.json({ ok: false, msg: '请输入手机号和密码' });

  const user = db.prepare('SELECT * FROM users WHERE phone = ?').get(phone);
  if (!user) return res.json({ ok: false, msg: '用户不存在' });
  if (user.role !== 'admin') return res.json({ ok: false, msg: '非管理员账号' });

  const valid = bcrypt.compareSync(password, user.password);
  if (!valid) return res.json({ ok: false, msg: '密码错误' });

  // 更新最后登录时间
  db.prepare("UPDATE users SET last_login = datetime('now') WHERE id = ?").run(user.id);

  const token = jwt.sign(
    { id: user.id, phone: user.phone, name: user.name, role: user.role },
    JWT_SECRET, { expiresIn: '30d' }
  );
  res.json({
    ok: true, msg: '管理员登录成功', token,
    user: { id: user.id, phone: user.phone, name: user.name, role: user.role },
  });
});

// ── 获取所有用户 ───────────────────────────────────────────────
app.get('/api/admin/users', adminRequired, (req, res) => {
  const { page = 1, limit = 20, search = '', role = '' } = req.query;
  const offset = (Number(page) - 1) * Number(limit);

  let sql = 'SELECT id,phone,name,role,rating,orders_done,created_at,last_login FROM users WHERE 1=1';
  const params = [];

  if (search) {
    sql += ' AND (phone LIKE ? OR name LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }
  if (role && role !== 'all') {
    sql += ' AND role = ?';
    params.push(role);
  }

  sql += ' ORDER BY id DESC LIMIT ? OFFSET ?';
  params.push(Number(limit), offset);

  const rows = db.prepare(sql).all(...params);
  const total = db.prepare(
    'SELECT COUNT(*) as n FROM users WHERE 1=1' +
    (search ? ' AND (phone LIKE ? OR name LIKE ?)' : '') +
    (role && role !== 'all' ? ' AND role = ?' : '')
  ).get(...params.slice(0, -2)).n;

  res.json({ ok: true, users: rows, total, page: Number(page) });
});

// ── 更新用户信息 ───────────────────────────────────────────────
app.put('/api/admin/users/:id', adminRequired, (req, res) => {
  const { name, role, rating } = req.body;
  const userId = Number(req.params.id);

  if (!userId) return res.json({ ok: false, msg: '用户ID无效' });
  if (role && !['client', 'hunter', 'admin'].includes(role)) {
    return res.json({ ok: false, msg: '无效角色' });
  }

  const updates = [];
  const params = [];

  if (name !== undefined) { updates.push('name = ?'); params.push(name); }
  if (role !== undefined) { updates.push('role = ?'); params.push(role); }
  if (rating !== undefined) { updates.push('rating = ?'); params.push(Number(rating)); }

  if (updates.length === 0) return res.json({ ok: false, msg: '没有更新内容' });

  params.push(userId);
  db.prepare(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`).run(...params);

  res.json({ ok: true, msg: '用户信息已更新' });
});

// ── 删除用户 ───────────────────────────────────────────────────
app.delete('/api/admin/users/:id', adminRequired, (req, res) => {
  const userId = Number(req.params.id);
  if (!userId) return res.json({ ok: false, msg: '用户ID无效' });

  // 检查用户是否有未完成的订单
  const activeOrders = db.prepare(
    "SELECT COUNT(*) as n FROM orders WHERE (client_id = ? OR hunter_id = ?) AND status IN ('pending', 'locked', 'doing')"
  ).get(userId, userId).n;

  if (activeOrders > 0) {
    return res.json({ ok: false, msg: '用户有未完成的订单，无法删除' });
  }

  db.prepare('DELETE FROM users WHERE id = ?').run(userId);
  res.json({ ok: true, msg: '用户已删除' });
});

// ── 获取所有订单（管理员视图） ──────────────────────────────────
app.get('/api/admin/orders', adminRequired, (req, res) => {
  const { page = 1, limit = 20, status = '', type = '', search = '' } = req.query;
  const offset = (Number(page) - 1) * Number(limit);

  let sql = `
    SELECT o.*, 
           c.name as client_name, c.phone as client_phone,
           h.name as hunter_name, h.phone as hunter_phone
    FROM orders o
    LEFT JOIN users c ON o.client_id = c.id
    LEFT JOIN users h ON o.hunter_id = h.id
    WHERE 1=1
  `;
  const params = [];

  if (status && status !== 'all') { sql += ' AND o.status = ?'; params.push(status); }
  if (type && type !== 'all') { sql += ' AND o.service_type = ?'; params.push(type); }
  if (search) {
    sql += ' AND (o.order_id LIKE ? OR o.remark LIKE ? OR c.name LIKE ? OR h.name LIKE ?)';
    params.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
  }

  sql += ' ORDER BY o.created_at DESC LIMIT ? OFFSET ?';
  params.push(Number(limit), offset);

  const rows = db.prepare(sql).all(...params);
  const total = db.prepare(
    'SELECT COUNT(*) as n FROM orders o WHERE 1=1' +
    (status && status !== 'all' ? ' AND o.status = ?' : '') +
    (type && type !== 'all' ? ' AND o.service_type = ?' : '') +
    (search ? ' AND (o.order_id LIKE ? OR o.remark LIKE ?)' : '')
  ).get(...params.slice(0, -2)).n;

  res.json({ ok: true, orders: rows.map(fmtOrder), total, page: Number(page) });
});

// ── 管理员操作订单 ─────────────────────────────────────────────
app.put('/api/admin/orders/:orderId', adminRequired, (req, res) => {
  const { status, price, remark } = req.body;
  const orderId = req.params.orderId;

  const order = db.prepare('SELECT * FROM orders WHERE order_id = ?').get(orderId);
  if (!order) return res.json({ ok: false, msg: '订单不存在' });

  const updates = [];
  const params = [];

  if (status && ['pending', 'locked', 'doing', 'completed', 'cancelled'].includes(status)) {
    updates.push('status = ?');
    params.push(status);
  }
  if (price !== undefined) {
    updates.push('price = ?');
    params.push(Number(price));
  }
  if (remark !== undefined) {
    updates.push('remark = ?');
    params.push(remark);
  }

  if (updates.length === 0) return res.json({ ok: false, msg: '没有更新内容' });

  updates.push("updated_at = datetime('now')");
  params.push(orderId);

  db.prepare(`UPDATE orders SET ${updates.join(', ')} WHERE order_id = ?`).run(...params);
  res.json({ ok: true, msg: '订单已更新' });
});

// ── 删除订单 ───────────────────────────────────────────────────
app.delete('/api/admin/orders/:orderId', adminRequired, (req, res) => {
  const orderId = req.params.orderId;
  
  // 先删除相关消息
  db.prepare('DELETE FROM messages WHERE order_id = ?').run(orderId);
  
  // 再删除订单
  const result = db.prepare('DELETE FROM orders WHERE order_id = ?').run(orderId);
  
  if (result.changes === 0) {
    return res.json({ ok: false, msg: '订单不存在' });
  }
  
  res.json({ ok: true, msg: '订单已删除' });
});

// ── 获取详细统计 ───────────────────────────────────────────────
app.get('/api/admin/stats', adminRequired, (req, res) => {
  // 基础统计
  const totalOrders = db.prepare("SELECT COUNT(*) as n FROM orders").get().n;
  const pendingOrders = db.prepare("SELECT COUNT(*) as n FROM orders WHERE status='pending'").get().n;
  const activeOrders = db.prepare("SELECT COUNT(*) as n FROM orders WHERE status IN ('locked','doing')").get().n;
  const totalUsers = db.prepare("SELECT COUNT(*) as n FROM users").get().n;
  const completedOrders = db.prepare("SELECT COUNT(*) as n FROM orders WHERE status='completed'").get().n;
  
  // 收入统计
  const revenueResult = db.prepare(
    "SELECT COALESCE(SUM(price), 0) as total FROM orders WHERE status='completed'"
  ).get();
  
  // 用户角色分布
  const roleStats = db.prepare(
    "SELECT role, COUNT(*) as count FROM users GROUP BY role"
  ).all();
  
  // 服务类型分布
  const serviceStats = db.prepare(
    "SELECT service_type, COUNT(*) as count FROM orders GROUP BY service_type"
  ).all();
  
  // 每日订单趋势（最近7天）
  const dailyTrend = db.prepare(`
    SELECT 
      DATE(created_at) as date,
      COUNT(*) as count,
      COALESCE(SUM(CASE WHEN status='completed' THEN price ELSE 0 END), 0) as revenue
    FROM orders 
    WHERE created_at >= DATE('now', '-7 days')
    GROUP BY DATE(created_at)
    ORDER BY date
  `).all();
  
  res.json({
    ok: true,
    stats: {
      totalOrders, pendingOrders, activeOrders, totalUsers, completedOrders,
      totalRevenue: revenueResult.total || 0,
      roleStats, serviceStats, dailyTrend
    }
  });
});

// ── 获取系统日志（最近操作） ───────────────────────────────────
app.get('/api/admin/logs', adminRequired, (req, res) => {
  const { limit = 50 } = req.query;
  
  // 这里可以扩展为真正的日志系统，现在先返回一些基本信息
  const recentOrders = db.prepare(`
    SELECT order_id, service_type, status, created_at 
    FROM orders 
    ORDER BY created_at DESC 
    LIMIT ?
  `).all(Number(limit));
  
  const recentUsers = db.prepare(`
    SELECT id, phone, name, role, created_at 
    FROM users 
    ORDER BY created_at DESC 
    LIMIT ?
  `).all(Number(limit));
  
  res.json({ ok: true, recentOrders, recentUsers });
});

// ── 创建管理员账号（仅开发使用） ───────────────────────────────
app.post('/api/admin/create', (req, res) => {
  // 仅在生产环境禁用或在开发环境使用
  if (process.env.NODE_ENV === 'production') {
    return res.json({ ok: false, msg: '生产环境禁止此操作' });
  }
  
  const { phone, password, name } = req.body;
  if (!phone || !password) return res.json({ ok: false, msg: '请输入手机号和密码' });
  
  const existing = db.prepare('SELECT id FROM users WHERE phone = ?').get(phone);
  if (existing) return res.json({ ok: false, msg: '手机号已存在' });
  
  const hashed = bcrypt.hashSync(password, 10);
  const result = db.prepare(
    'INSERT INTO users (phone, password, name, role) VALUES (?, ?, ?, ?)'
  ).run(phone, hashed, name || '管理员', 'admin');
  
  res.json({ ok: true, msg: '管理员账号已创建', userId: result.lastInsertRowid });
});

// ═══════════════════════════════════════════════════════════════
//  启动
// ═══════════════════════════════════════════════════════════════
app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════╗
  ║  代号Delta API 已启动              ║
  ║  http://localhost:${PORT}           ║
  ║  数据库: ${DB_PATH}
  ╚═══════════════════════════════════╝
  `);
});

module.exports = app;
