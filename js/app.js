/* ========================================
   DELTA护航 · 三角洲行动护航接单平台
   ======================================== */

var API_BASE = 'http://127.0.0.1:18082';
function apiCall(method, path, body, token) {
  var opts = { method: method, headers: { 'Content-Type': 'application/json' } };
  if (token) opts.headers['Authorization'] = 'Bearer ' + token;
  if (body)  opts.body = JSON.stringify(body);
  return fetch(API_BASE + '/api' + path, opts).then(function(r) { return r.json(); });
}

function apiUserCall(method, path, body, token) {
  var opts = { method: method, headers: { 'Content-Type': 'application/json' } };
  opts.headers['clientType'] = 'h5';
  if (token) opts.headers['Authorization'] = 'Bearer ' + token;
  if (body)  opts.body = JSON.stringify(body);
  return fetch(API_BASE + path, opts).then(function(r) { return r.json(); });
}

// ─── 全局状态 ───
var App = {
  currentPage: 'home',
  currentRole: 'client',
  currentFilter: 'all',
  currentMyOrderFilter: 'all',
  currentServiceType: 'escort',
  currentMap: 'linghaodaba',
  currentLoginRole: 'client',
  isLoggedIn: false,
  user: null,
  token: null,
  menuOpen: false,
  useAPI: true,
};

// ─── 常量 ───
var MAPS = {
  hangtian:    { name:'航天基地', risk:'secret', badge:'绝密', hint:'绝密高难 · 双护推荐' },
  chaoxi:      { name:'潮汐监狱', risk:'secret', badge:'绝密', hint:'绝密高难 · 需要配合' },
  linghaodaba: { name:'零号大坝', risk:'mid',    badge:'机密', hint:'机密主流 · 适合新手' },
  bakashi:     { name:'巴克什',   risk:'mid',    badge:'机密', hint:'机密资源 · 跑刀圣地' },
  changong:    { name:'长弓溪谷', risk:'low',    badge:'常规', hint:'常规探索 · 路线成熟' },
};

var SERVICE_TYPES = {
  escort:  { name:'护航服务', icon:'🛡️' },
  loot:    { name:'代肝跑刀', icon:'💰' },
  play:    { name:'陪玩服务', icon:'🎮' },
  boost:   { name:'3×3代打', icon:'🏆' },
  trade:   { name:'物品交易', icon:'🔑' },
  account: { name:'账号服务', icon:'👤' },
  // Legacy compat
  crash:   { name:'物品交易', icon:'🔑' },
  clear:   { name:'护航服务', icon:'🛡️' },
};

var STATUS_LABELS = { pending:'待匹配', locked:'已匹配', doing:'护航中', completed:'已完成', cancelled:'已取消' };
var STATUS_CLASS  = { pending:'status-pending', locked:'status-locked', doing:'status-doing', completed:'status-completed', cancelled:'status-pending' };
var TAG_CLASS     = { escort:'tag-escort', loot:'tag-loot', play:'tag-play', boost:'tag-boost', trade:'tag-trade', account:'tag-account', crash:'tag-trade', clear:'tag-escort' };

// ─── 真实市场数据的DEMO订单 ───
var DEMO_ORDERS = [
  { id:'ORD001', serviceType:'escort', map:'hangtian',    price:180, status:'pending',   time:'2分钟前',  clientName:'老板_A7x2', detail:'绝密双护猛攻 · 保底1250w' },
  { id:'ORD002', serviceType:'loot',   map:'changong',    price:60,  status:'doing',     time:'5分钟前',  clientName:'老板_K9mQ', detail:'跑刀1000w哈夫币' },
  { id:'ORD003', serviceType:'escort', map:'linghaodaba',  price:140, status:'pending',   time:'8分钟前',  clientName:'老板_B3zR', detail:'机密双护 · 老板选图' },
  { id:'ORD004', serviceType:'play',   map:'bakashi',     price:70,  status:'doing',     time:'12分钟前', clientName:'老板_P1nT', detail:'大神陪玩 · 1小时' },
  { id:'ORD005', serviceType:'escort', map:'chaoxi',      price:350, status:'pending',   time:'15分钟前', clientName:'老板_W5yG', detail:'VIP大红单 · 保底2000w+' },
  { id:'ORD006', serviceType:'boost',  map:'linghaodaba',  price:650, status:'locked',    time:'22分钟前', clientName:'老板_M2kL', detail:'3×3赛季全包代打' },
  { id:'ORD007', serviceType:'loot',   map:'bakashi',     price:80,  status:'pending',   time:'28分钟前', clientName:'老板_R8fD', detail:'跑刀1000w · 加急' },
  { id:'ORD008', serviceType:'escort', map:'hangtian',    price:60,  status:'completed', time:'35分钟前', clientName:'老板_X4nJ', detail:'新人体验单 · 保底400w' },
  { id:'ORD009', serviceType:'play',   map:'linghaodaba',  price:60,  status:'pending',   time:'40分钟前', clientName:'老板_G6pS', detail:'甜妹陪玩 · 1小时' },
  { id:'ORD010', serviceType:'trade',  map:'changong',    price:50,  status:'pending',   time:'48分钟前', clientName:'老板_Q1bH', detail:'国王卡交易' },
];

// ─── 页面路由 ───
function goPage(page) {
  App.currentPage = page;
  document.querySelectorAll('.page').forEach(function(p) { p.classList.remove('active'); });
  document.getElementById('page-' + page).classList.add('active');
  document.querySelectorAll('.nav-link').forEach(function(l) {
    l.classList.toggle('active', l.getAttribute('data-page') === page);
  });
  document.querySelectorAll('.tab-item').forEach(function(t) {
    t.classList.toggle('active', t.getAttribute('data-page') === page);
  });
  window.scrollTo(0, 0);
  if (page === 'home') { renderHomeOrders(); animateNumbers(); }
  if (page === 'market') renderMarket();
  if (page === 'orders') renderMyOrders();
  if (page === 'publish') renderDynamicForm();
  closeMenu();
}

function goPublish(type) {
  App.currentServiceType = type;
  goPage('publish');
  document.querySelectorAll('.type-block').forEach(function(b) { b.classList.remove('active'); });
  var blocks = document.querySelectorAll('.type-block');
  var types = ['escort','loot','play','boost','trade','account'];
  var idx = types.indexOf(type);
  if (idx >= 0 && blocks[idx]) blocks[idx].classList.add('active');
  renderDynamicForm();
}

// ─── 角色切换 ───
function toggleRole() {
  App.currentRole = App.currentRole === 'client' ? 'hunter' : 'client';
  document.getElementById('roleIcon').textContent = App.currentRole === 'client' ? '👑' : '⚔️';
  document.getElementById('roleText').textContent = App.currentRole === 'client' ? '老板模式' : '打手模式';
}

// ─── 菜单 ───
function toggleMenu() {
  App.menuOpen = !App.menuOpen;
  document.getElementById('navLinks').classList.toggle('show', App.menuOpen);
}
function closeMenu() { App.menuOpen = false; document.getElementById('navLinks').classList.remove('show'); }

// ─── 登录 ───
function showLogin() { document.getElementById('loginModal').style.display = 'flex'; }
function hideLogin() { document.getElementById('loginModal').style.display = 'none'; }
function selectLoginRole(role) {
  App.currentLoginRole = role;
  document.getElementById('loginClient').classList.toggle('active', role === 'client');
  document.getElementById('loginHunter').classList.toggle('active', role === 'hunter');
}

function doLogin() {
  // var phone = document.getElementById('loginPhone').value.trim();
  var username = document.getElementById('loginName').value.trim();
  var pass  = document.getElementById('loginPass').value.trim();
  if (!username || !pass) return showToast('请输入用户名和密码');
  if (App.useAPI) {
    apiUserCall('POST', '/client/login', { username: username, password: pass }).then(function(data) {
      if (data.code == 0) {finishLogin(data.data);}
    }).catch(function() { finishLogin(data.data); });
  } 
}

function localLogin(data) {
  App.isLoggedIn = true;
  App.user = data.userInfo;
    // App.user = { phone: phone, name: '干员_' + phone.slice(-4) };
  App.token = data.token;
  localStorage.setItem('delta_token', App.token);
  localStorage.setItem('delta_user', JSON.stringify(App.user));
  updateUserUI();
  hideLogin();
  showToast('登录成功，欢迎干员！');
}

function finishLogin(data) {
  App.isLoggedIn = true;
  App.token = data.token;
  App.user = data.userInfo;
  localStorage.setItem('delta_token', App.token);
  localStorage.setItem('delta_user', JSON.stringify(App.user));
  updateUserUI();
  hideLogin();
  showToast('登录成功！');
}

function updateUserUI() {
  if (App.isLoggedIn) {
    document.getElementById('loginBtn').style.display = 'none';
    document.getElementById('userInfo').style.display = 'flex';
    document.getElementById('userName').textContent = App.user.name;
    document.getElementById('userAvatar').textContent = App.user.name.charAt(0);
  }
}

function showRegister() { showToast('注册功能开发中...'); }

// ─── 数字动画 ───
function animateNumbers() {
  document.querySelectorAll('.hs-num[data-target]').forEach(function(el) {
    var target = parseInt(el.getAttribute('data-target'));
    var duration = 1500;
    var start = 0;
    var startTime = null;
    function step(ts) {
      if (!startTime) startTime = ts;
      var progress = Math.min((ts - startTime) / duration, 1);
      var ease = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.floor(ease * target);
      if (progress < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  });
}

// ─── 首页订单 ───
function renderHomeOrders() {
  var list = document.getElementById('homeOrderList');
  if (!list) return;
  list.innerHTML = DEMO_ORDERS.slice(0, 6).map(function(o) {
    var svc = SERVICE_TYPES[o.serviceType] || SERVICE_TYPES.escort;
    var mapName = MAPS[o.map] ? MAPS[o.map].name : o.map;
    return '<div class="order-card">' +
      '<div class="oc-left">' +
        '<span class="tag ' + (TAG_CLASS[o.serviceType] || 'tag-escort') + '">' + svc.icon + ' ' + svc.name + '</span>' +
        '<span class="oc-map">' + mapName + '</span>' +
        '<span class="oc-map" style="font-size:11px">' + (o.detail || '') + '</span>' +
      '</div>' +
      '<div class="oc-right">' +
        '<span class="oc-price">¥' + o.price + '</span>' +
        '<span class="status-pill ' + (STATUS_CLASS[o.status] || '') + '">' + (STATUS_LABELS[o.status] || o.status) + '</span>' +
      '</div></div>';
  }).join('');
}

// ─── 市场 ───
function setFilter(f, btn) {
  App.currentFilter = f;
  document.querySelectorAll('.filter-btn').forEach(function(b) { b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  renderMarket();
}

function renderMarket() {
  var list = document.getElementById('marketList');
  if (!list) return;
  var orders = DEMO_ORDERS.filter(function(o) {
    return App.currentFilter === 'all' || o.serviceType === App.currentFilter;
  });
  if (!orders.length) {
    list.innerHTML = '<div class="empty-state"><span class="empty-icon">📋</span><p>暂无该类型订单</p></div>';
    return;
  }
  list.innerHTML = orders.map(function(o) {
    var svc = SERVICE_TYPES[o.serviceType] || SERVICE_TYPES.escort;
    var mapName = MAPS[o.map] ? MAPS[o.map].name : o.map;
    var borderColor = o.serviceType === 'escort' ? 'var(--accent)' :
                      o.serviceType === 'loot' ? 'var(--warning)' :
                      o.serviceType === 'play' ? 'var(--blue)' : 'var(--gold)';
    return '<div class="market-card" style="border-left-color:' + borderColor + '">' +
      '<div class="mc-top">' +
        '<span class="tag ' + (TAG_CLASS[o.serviceType] || 'tag-escort') + '">' + svc.icon + ' ' + svc.name + '</span>' +
        '<span class="tag" style="background:rgba(255,255,255,0.05);color:var(--text-secondary)">' + mapName + '</span>' +
        '<span class="mc-time">' + o.time + '</span>' +
      '</div>' +
      '<div class="mc-price-row">' +
        '<span class="mc-price">¥' + o.price + '</span>' +
        '<span class="mc-earn">' + o.clientName + '</span>' +
      '</div>' +
      '<div class="mc-detail">' + (o.detail || '') + '</div>' +
      '<div class="mc-footer">' +
        '<span class="status-pill ' + (STATUS_CLASS[o.status] || '') + '">' + (STATUS_LABELS[o.status] || o.status) + '</span>' +
        (o.status === 'pending' ? '<button class="pc-btn" style="width:auto;margin:0;padding:6px 20px" onclick="event.stopPropagation();takeOrder(\'' + o.id + '\')">接单</button>' : '') +
      '</div></div>';
  }).join('');
}

function takeOrder(id) {
  if (!App.isLoggedIn) return showLogin();
  var order = DEMO_ORDERS.find(function(o) { return o.id === id; });
  if (order) { order.status = 'locked'; renderMarket(); showToast('接单成功！请联系老板'); }
}

// ─── 发布 ───
function selectType(type, el) {
  App.currentServiceType = type;
  document.querySelectorAll('.type-block').forEach(function(b) { b.classList.remove('active'); });
  if (el) el.classList.add('active');
  renderDynamicForm();
}

function selectMap(map, el) {
  App.currentMap = map;
  document.querySelectorAll('.map-row').forEach(function(r) { r.classList.remove('active'); });
  if (el) el.classList.add('active');
}

function renderDynamicForm() {
  var container = document.getElementById('dynamicForm');
  if (!container) return;
  var type = App.currentServiceType;
  var html = '';

  if (type === 'escort') {
    html = '<h3 class="form-title">护航选项</h3>' +
      '<div class="form-label">护航模式</div>' +
      '<div class="mode-row">' +
        '<div class="mode-card active" onclick="selectMode(this)"><span class="mode-icon">🛡️</span><span class="mode-name">单护</span><span class="mode-desc">1个打手护航</span></div>' +
        '<div class="mode-card" onclick="selectMode(this)"><span class="mode-icon">🛡️🛡️</span><span class="mode-name">双护</span><span class="mode-desc">2个打手护航（推荐）</span></div>' +
      '</div>' +
      '<div class="form-label">保底哈夫币</div>' +
      '<div class="quick-hfc">' +
        '<span class="hfc-chip" onclick="setHfc(400,this)">400w</span>' +
        '<span class="hfc-chip active" onclick="setHfc(800,this)">800w</span>' +
        '<span class="hfc-chip" onclick="setHfc(1250,this)">1250w</span>' +
        '<span class="hfc-chip" onclick="setHfc(2000,this)">2000w+</span>' +
      '</div>' +
      '<div class="form-label">预算（元）</div>' +
      '<div class="quick-price">' +
        '<span class="price-chip" onclick="setPrice(60,this)">¥60</span>' +
        '<span class="price-chip" onclick="setPrice(80,this)">¥80</span>' +
        '<span class="price-chip active" onclick="setPrice(140,this)">¥140</span>' +
        '<span class="price-chip" onclick="setPrice(180,this)">¥180</span>' +
        '<span class="price-chip" onclick="setPrice(350,this)">¥350+</span>' +
      '</div>' +
      '<div class="why-pay">💡 炸单每把+50w保底 · 追缴全额赔付 · 不满意免费换打手</div>';
  } else if (type === 'loot') {
    html = '<h3 class="form-title">代肝跑刀选项</h3>' +
      '<div class="form-label">需要刷多少哈夫币</div>' +
      '<div class="hfc-input-row"><input class="hfc-input" id="hfcAmount" type="number" placeholder="1000" value="1000"><span class="hfc-unit">万哈夫币</span></div>' +
      '<div class="quick-hfc">' +
        '<span class="hfc-chip" onclick="setHfcInput(500,this)">500w</span>' +
        '<span class="hfc-chip active" onclick="setHfcInput(1000,this)">1000w</span>' +
        '<span class="hfc-chip" onclick="setHfcInput(2000,this)">2000w</span>' +
        '<span class="hfc-chip" onclick="setHfcInput(5000,this)">5000w</span>' +
      '</div>' +
      '<div class="why-pay">💡 当前市场价约 ¥60/1000w · 纯手工绿色跑刀 · 效率型打手2.5h/1000w</div>';
  } else if (type === 'play') {
    html = '<h3 class="form-title">陪玩选项</h3>' +
      '<div class="form-label">陪玩类型</div>' +
      '<div class="mode-row">' +
        '<div class="mode-card active" onclick="selectMode(this)"><span class="mode-icon">🎮</span><span class="mode-name">娱乐陪玩</span><span class="mode-desc">¥30-50/h</span></div>' +
        '<div class="mode-card" onclick="selectMode(this)"><span class="mode-icon">⚔️</span><span class="mode-name">大神陪玩</span><span class="mode-desc">¥70-100/h</span></div>' +
      '</div>' +
      '<div class="form-label">时长</div>' +
      '<div class="time-grid">' +
        '<span class="time-chip active" onclick="setTime(this)">1小时</span>' +
        '<span class="time-chip" onclick="setTime(this)">2小时</span>' +
        '<span class="time-chip" onclick="setTime(this)">3小时</span>' +
        '<span class="time-chip" onclick="setTime(this)">包天</span>' +
      '</div>' +
      '<div class="form-label">预算</div>' +
      '<div class="quick-price">' +
        '<span class="price-chip" onclick="setPrice(30,this)">¥30</span>' +
        '<span class="price-chip active" onclick="setPrice(50,this)">¥50</span>' +
        '<span class="price-chip" onclick="setPrice(70,this)">¥70</span>' +
        '<span class="price-chip" onclick="setPrice(100,this)">¥100</span>' +
      '</div>';
  } else if (type === 'boost') {
    html = '<h3 class="form-title">3×3代打选项</h3>' +
      '<div class="form-label">服务范围</div>' +
      '<div class="mode-row">' +
        '<div class="mode-card active" onclick="selectMode(this)"><span class="mode-icon">📋</span><span class="mode-name">全包</span><span class="mode-desc">¥650-1500</span></div>' +
        '<div class="mode-card" onclick="selectMode(this)"><span class="mode-icon">✂️</span><span class="mode-name">分段</span><span class="mode-desc">¥200-300</span></div>' +
      '</div>' +
      '<div class="form-label">预算</div>' +
      '<div class="quick-price">' +
        '<span class="price-chip" onclick="setPrice(200,this)">¥200</span>' +
        '<span class="price-chip" onclick="setPrice(300,this)">¥300</span>' +
        '<span class="price-chip active" onclick="setPrice(650,this)">¥650</span>' +
        '<span class="price-chip" onclick="setPrice(800,this)">¥800</span>' +
      '</div>';
  } else if (type === 'trade') {
    html = '<h3 class="form-title">交易物品</h3>' +
      '<div class="items-grid">' +
        '<div class="item-block active" onclick="toggleItem(this)"><span class="item-icon">👑</span><span class="item-name">国王卡</span></div>' +
        '<div class="item-block" onclick="toggleItem(this)"><span class="item-icon">🔴</span><span class="item-name">大红</span></div>' +
        '<div class="item-block" onclick="toggleItem(this)"><span class="item-icon">🔑</span><span class="item-name">钥匙卡</span></div>' +
        '<div class="item-block" onclick="toggleItem(this)"><span class="item-icon">🎯</span><span class="item-name">AWM弹药</span></div>' +
        '<div class="item-block" onclick="toggleItem(this)"><span class="item-icon">🎖️</span><span class="item-name">限定皮肤</span></div>' +
        '<div class="item-block" onclick="toggleItem(this)"><span class="item-icon">📦</span><span class="item-name">其他物品</span></div>' +
      '</div>' +
      '<div class="form-label">期望价格（元）</div>' +
      '<div class="pay-input-row"><span class="pay-prefix">¥</span><input class="pay-input" type="number" placeholder="面议"></div>';
  } else if (type === 'account') {
    html = '<h3 class="form-title">账号服务类型</h3>' +
      '<div class="mode-row">' +
        '<div class="mode-card active" onclick="selectMode(this)"><span class="mode-icon">🔄</span><span class="mode-name">账号出租</span><span class="mode-desc">¥5-15/h</span></div>' +
        '<div class="mode-card" onclick="selectMode(this)"><span class="mode-icon">💎</span><span class="mode-name">成品号购买</span><span class="mode-desc">¥328起</span></div>' +
      '</div>' +
      '<div class="why-pay">💡 出租收购价约1:7 · 自售约1:13 · 大红号价值更高</div>';
  }

  container.innerHTML = html;
}

function selectMode(el) {
  var row = el.parentElement;
  row.querySelectorAll('.mode-card').forEach(function(c) { c.classList.remove('active'); });
  el.classList.add('active');
}

function setHfc(val, el) {
  el.parentElement.querySelectorAll('.hfc-chip').forEach(function(c) { c.classList.remove('active'); });
  el.classList.add('active');
}

function setHfcInput(val, el) {
  document.getElementById('hfcAmount').value = val;
  el.parentElement.querySelectorAll('.hfc-chip').forEach(function(c) { c.classList.remove('active'); });
  el.classList.add('active');
}

function setPrice(val, el) {
  el.parentElement.querySelectorAll('.price-chip').forEach(function(c) { c.classList.remove('active'); });
  el.classList.add('active');
}

function setTime(el) {
  el.parentElement.querySelectorAll('.time-chip').forEach(function(c) { c.classList.remove('active'); });
  el.classList.add('active');
}

function toggleItem(el) { el.classList.toggle('active'); }

function updateCount() {
  var t = document.getElementById('remark');
  document.getElementById('remarkCount').textContent = t ? t.value.length : 0;
}

function submitOrder() {
  if (!App.isLoggedIn) return showLogin();
  var svc = SERVICE_TYPES[App.currentServiceType] || SERVICE_TYPES.escort;
  var mapObj = MAPS[App.currentMap] || { name: App.currentMap };
  var price = 0;
  var activePrice = document.querySelector('.price-chip.active');
  if (activePrice) price = parseInt(activePrice.textContent.replace(/[^0-9]/g, '')) || 0;
  if (!price) {
    var inp = document.querySelector('.pay-input');
    if (inp) price = parseInt(inp.value) || 0;
  }
  if (!price) {
    var hfcInp = document.getElementById('hfcAmount');
    if (hfcInp) price = Math.round((parseInt(hfcInp.value) || 1000) * 0.06);
  }
  if (!price) price = 100;

  var newOrder = {
    id: 'ORD' + Date.now().toString().slice(-6),
    serviceType: App.currentServiceType,
    map: App.currentMap,
    price: price,
    status: 'pending',
    time: '刚刚',
    clientName: App.user ? App.user.name : '干员',
    detail: svc.name + ' · ' + mapObj.name,
  };

  DEMO_ORDERS.unshift(newOrder);
  showToast('需求已发布，正在为您匹配打手...');
  setTimeout(function() { goPage('orders'); }, 800);
}

// ─── 我的订单 ───
function filterMyOrders(filter, btn) {
  App.currentMyOrderFilter = filter;
  document.querySelectorAll('.tab-btn').forEach(function(b) { b.classList.remove('active'); });
  if (btn) btn.classList.add('active');
  renderMyOrders();
}

function renderMyOrders() {
  var list = document.getElementById('myOrderList');
  if (!list) return;
  var orders = DEMO_ORDERS.filter(function(o) {
    if (App.currentMyOrderFilter === 'all') return true;
    return o.status === App.currentMyOrderFilter;
  });
  if (!orders.length) {
    list.innerHTML = '<div class="empty-state"><span class="empty-icon">📋</span><p>暂无订单</p></div>';
    return;
  }
  list.innerHTML = orders.map(function(o) {
    var svc = SERVICE_TYPES[o.serviceType] || SERVICE_TYPES.escort;
    var mapName = MAPS[o.map] ? MAPS[o.map].name : o.map;
    return '<div class="order-card">' +
      '<div class="oc-left">' +
        '<span class="tag ' + (TAG_CLASS[o.serviceType] || 'tag-escort') + '">' + svc.icon + ' ' + svc.name + '</span>' +
        '<span class="oc-map">' + mapName + ' · ' + (o.detail || '') + '</span>' +
      '</div>' +
      '<div class="oc-right">' +
        '<span class="oc-price">¥' + o.price + '</span>' +
        '<span class="status-pill ' + (STATUS_CLASS[o.status] || '') + '">' + (STATUS_LABELS[o.status] || o.status) + '</span>' +
      '</div></div>';
  }).join('');
}

// ─── Toast ───
function showToast(msg) {
  var t = document.createElement('div');
  t.className = 'toast';
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(function() { t.remove(); }, 2500);
}

// ─── 初始化 ───
document.addEventListener('DOMContentLoaded', function() {
  // Restore login
  var savedToken = localStorage.getItem('delta_token');
  var savedUser  = localStorage.getItem('delta_user');
  if (savedToken && savedUser) {
    App.isLoggedIn = true;
    App.token = savedToken;
    try { App.user = JSON.parse(savedUser); } catch(e) {}
    updateUserUI();
  }

  // Probe API
  fetch(API_BASE + '/api/stats').then(function(r) { return r.json(); }).then(function(d) {
    if (d && d.totalOrders !== undefined) App.useAPI = true;
  }).catch(function() {});

  // Render
  renderHomeOrders();
  renderDynamicForm();
  animateNumbers();
});

/* ═══════════════════════════════════════════════════
   DELTA 2.0 – 新功能模块
   ═══════════════════════════════════════════════════ */

// ─── 我的页面入口 ───
function goProfile() {
  if (!App.isLoggedIn) { showLogin(); return; }
  goPage('profile');
  renderProfile();
}

function renderProfile() {
  if (!App.user) return;
  // 名字 & 头像
  var nameEl = document.getElementById('profileName');
  var phoneEl = document.getElementById('profilePhone');
  var avatarEl = document.getElementById('profileAvatar');
  if (nameEl) nameEl.textContent = App.user.name || '未登录';
  if (phoneEl) phoneEl.textContent = App.user.phone ? App.user.phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : '--';
  if (avatarEl) {
    if (App.user.avatarUrl) {
      avatarEl.innerHTML = '<img src="' + App.user.avatarUrl + '" alt="avatar">';
    } else {
      avatarEl.textContent = (App.user.name || 'Δ').charAt(0).toUpperCase();
    }
  }
  if (document.getElementById('bindPhoneVal')) {
    document.getElementById('bindPhoneVal').textContent = App.user.phone ? App.user.phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : '未绑定';
  }
  // 统计
  var sent = DEMO_ORDERS.filter(function(o) { return o.clientName === App.user.name; }).length;
  var done = DEMO_ORDERS.filter(function(o) { return o.status === 'completed'; }).length;
  var total = DEMO_ORDERS.length;
  if (document.getElementById('statOrdersSent')) document.getElementById('statOrdersSent').textContent = sent;
  if (document.getElementById('statOrdersDone')) document.getElementById('statOrdersDone').textContent = done;
  if (document.getElementById('statRate')) document.getElementById('statRate').textContent = total ? Math.round(done / total * 100) + '%' : '--';
  // 余额
  if (document.getElementById('balanceAmt')) document.getElementById('balanceAmt').textContent = (App.user.balance || 0).toFixed(2);
}

// ─── 改名 ───
function showEditName() { document.getElementById('editNameBox').style.display = 'block'; document.getElementById('newNameInput').value = App.user.name || ''; }
function hideEditName() { document.getElementById('editNameBox').style.display = 'none'; }
function saveName() {
  var val = document.getElementById('newNameInput').value.trim();
  if (!val || val.length < 2) return showToast('昵称至少2个字符');
  App.user.name = val;
  localStorage.setItem('delta_user', JSON.stringify(App.user));
  updateUserUI();
  renderProfile();
  hideEditName();
  showToast('昵称已更新');
}

// ─── 头像 ───
function triggerAvatarUpload() { document.getElementById('avatarInput').click(); }
function handleAvatarChange(e) {
  var file = e.target.files[0];
  if (!file) return;
  var reader = new FileReader();
  reader.onload = function(ev) {
    App.user.avatarUrl = ev.target.result;
    localStorage.setItem('delta_user', JSON.stringify(App.user));
    renderProfile();
    updateUserUI();
    showToast('头像已更新');
  };
  reader.readAsDataURL(file);
}
function updateUserUI() {
  if (App.isLoggedIn && App.user) {
    document.getElementById('loginBtn').style.display = 'none';
    document.getElementById('userInfo').style.display = 'flex';
    document.getElementById('userName').textContent = App.user.name;
    var avatarSpan = document.getElementById('userAvatar');
    if (avatarSpan) {
      if (App.user.avatarUrl) {
        avatarSpan.innerHTML = '<img src="' + App.user.avatarUrl + '" style="width:100%;height:100%;border-radius:50%;object-fit:cover">';
      } else {
        avatarSpan.textContent = (App.user.name || 'Δ').charAt(0).toUpperCase();
      }
    }
  }
}

// ─── 充值/提现面板 ───
var App_payMethod = 'alipay';
var App_payAmount = 50;
var App_wdMethod  = 'alipay';

function showRecharge()  { document.getElementById('rechargePanel').style.display = 'block'; }
function hideRecharge()  { document.getElementById('rechargePanel').style.display = 'none'; }
function showWithdraw()  { document.getElementById('withdrawPanel').style.display = 'block'; }
function hideWithdraw()  { document.getElementById('withdrawPanel').style.display = 'none'; }

function selectPay(method) {
  App_payMethod = method;
  document.querySelectorAll('[id^="pay-"]').forEach(function(el) { el.classList.remove('active'); });
  document.getElementById('pay-' + method).classList.add('active');
}
function selectWd(method) {
  App_wdMethod = method;
  document.querySelectorAll('[id^="wd-"]').forEach(function(el) { el.classList.remove('active'); });
  document.getElementById('wd-' + method).classList.add('active');
}
function selectAmount(amt, el) {
  App_payAmount = amt;
  document.querySelectorAll('.pay-chip').forEach(function(c) { c.classList.remove('active'); });
  el.classList.add('active');
  document.getElementById('customAmount').value = '';
}
function doRecharge() {
  var custom = parseInt(document.getElementById('customAmount').value) || App_payAmount;
  // 【接口预留】: 对接支付宝/微信时，在这里调用支付API
  showToast('【预留接口】' + (App_payMethod === 'alipay' ? '支付宝' : '微信') + '充值 ¥' + custom + ' · 正式上线后对接');
  App.user.balance = (App.user.balance || 0) + custom; // demo: 直接加余额
  localStorage.setItem('delta_user', JSON.stringify(App.user));
  renderProfile();
  hideRecharge();
}
function doWithdraw() {
  var account = document.getElementById('wdAccount').value.trim();
  var amount  = parseFloat(document.getElementById('wdAmount').value) || 0;
  if (!account) return showToast('请填写提现账号');
  if (amount < 10)  return showToast('最低提现金额 ¥10');
  if (amount > (App.user.balance || 0)) return showToast('余额不足');
  // 【接口预留】: 对接提现API
  showToast('【预留接口】提现申请 ¥' + amount + ' · 正式上线后对接');
  App.user.balance = (App.user.balance || 0) - amount;
  localStorage.setItem('delta_user', JSON.stringify(App.user));
  renderProfile();
  hideWithdraw();
}

// ─── 登录方式切换 ───
function switchLoginTab(tab) {
  document.querySelectorAll('.ltab').forEach(function(t) { t.classList.remove('active'); });
  document.getElementById('ltab-' + tab).classList.add('active');
  ['phone','wechat','qq'].forEach(function(t) {
    var el = document.getElementById('login-form-' + t);
    if (el) el.style.display = t === tab ? 'block' : 'none';
  });
}
function togglePassLogin() {
  var area = document.getElementById('passLoginArea');
  if (area) area.style.display = area.style.display === 'none' ? 'block' : 'none';
}

// ─── 短信验证码（预留接口）───
var smsTimers = {};
function sendSms(phoneInputId, btnId) {
  var phone = document.getElementById(phoneInputId) ? document.getElementById(phoneInputId).value.trim() : '';
  if (!/^1[3-9]\d{9}$/.test(phone)) return showToast('请输入正确的手机号');
  // 【接口预留】: 调用短信API: apiCall('POST', '/auth/sms', { phone: phone })
  showToast('【预留接口】验证码已发送至 ' + phone);
  var btn = document.getElementById(btnId);
  if (!btn) return;
  var count = 60;
  btn.disabled = true;
  btn.textContent = count + 's后重发';
  smsTimers[btnId] = setInterval(function() {
    count--;
    btn.textContent = count + 's后重发';
    if (count <= 0) {
      clearInterval(smsTimers[btnId]);
      btn.disabled = false;
      btn.textContent = '获取验证码';
    }
  }, 1000);
}

// ─── 短信登录 ───
function doLoginSms() {
  var phone = document.getElementById('loginPhone') ? document.getElementById('loginPhone').value.trim() : '';
  var code  = document.getElementById('loginSmsCode') ? document.getElementById('loginSmsCode').value.trim() : '';
  if (!phone) return showToast('请输入手机号');
  // 【接口预留】: 对接短信验证API
  // apiCall('POST','/auth/verify',{phone,code}).then(...)
  localLogin(phone); // demo模式：跳过验证码校验
}

// ─── 绑定手机 ───
function showBindPhone()  { document.getElementById('bindPhoneBox').style.display = 'block'; }
function hideBindPhone()  { document.getElementById('bindPhoneBox').style.display = 'none'; }
function saveBindPhone() {
  var phone = document.getElementById('bindPhoneInput').value.trim();
  if (!/^1[3-9]\d{9}$/.test(phone)) return showToast('请输入正确的手机号');
  App.user.phone = phone;
  localStorage.setItem('delta_user', JSON.stringify(App.user));
  renderProfile();
  hideBindPhone();
  showToast('手机绑定成功');
}

// ─── 退出登录 ───
function doLogout() {
  App.isLoggedIn = false;
  App.user = null;
  App.token = null;
  localStorage.removeItem('delta_token');
  localStorage.removeItem('delta_user');
  document.getElementById('loginBtn').style.display = 'block';
  document.getElementById('userInfo').style.display = 'none';
  goPage('home');
  showToast('已退出登录');
}
