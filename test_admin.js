/**
 * 管理员控制台测试脚本
 * 运行: node test_admin.js
 */

const http = require('http');

const API_BASE = 'http://localhost:3000';
const TEST_PHONE = '13800138000';
const TEST_PASSWORD = 'admin123';

async function testAPI() {
  console.log('🚀 开始测试管理员控制台API...\n');
  
  // 1. 测试创建管理员账号（开发环境）
  console.log('1. 测试创建管理员账号...');
  try {
    const createRes = await makeRequest('/api/admin/create', 'POST', {
      phone: TEST_PHONE,
      password: TEST_PASSWORD,
      name: '测试管理员'
    });
    
    if (createRes.ok) {
      console.log('✅ 管理员账号创建成功');
    } else {
      console.log('⚠️  管理员账号可能已存在:', createRes.msg);
    }
  } catch (error) {
    console.log('❌ 创建管理员失败:', error.message);
  }
  
  // 2. 测试管理员登录
  console.log('\n2. 测试管理员登录...');
  let token = null;
  try {
    const loginRes = await makeRequest('/api/admin/login', 'POST', {
      phone: TEST_PHONE,
      password: TEST_PASSWORD
    });
    
    if (loginRes.ok) {
      token = loginRes.token;
      console.log('✅ 管理员登录成功');
      console.log('   Token:', token.substring(0, 20) + '...');
    } else {
      console.log('❌ 管理员登录失败:', loginRes.msg);
      return;
    }
  } catch (error) {
    console.log('❌ 登录请求失败:', error.message);
    return;
  }
  
  // 3. 测试获取用户列表
  console.log('\n3. 测试获取用户列表...');
  try {
    const usersRes = await makeRequest('/api/admin/users?limit=5', 'GET', null, token);
    if (usersRes.ok) {
      console.log(`✅ 获取用户列表成功 (共${usersRes.total}个用户)`);
      console.log('   前5个用户:', usersRes.users.map(u => `${u.id}:${u.phone}`).join(', '));
    } else {
      console.log('❌ 获取用户列表失败:', usersRes.msg);
    }
  } catch (error) {
    console.log('❌ 用户列表请求失败:', error.message);
  }
  
  // 4. 测试获取订单列表
  console.log('\n4. 测试获取订单列表...');
  try {
    const ordersRes = await makeRequest('/api/admin/orders?limit=3', 'GET', null, token);
    if (ordersRes.ok) {
      console.log(`✅ 获取订单列表成功 (共${ordersRes.total}个订单)`);
      console.log('   前3个订单:', ordersRes.orders.map(o => `${o.order_id}:${o.service_type}`).join(', '));
    } else {
      console.log('❌ 获取订单列表失败:', ordersRes.msg);
    }
  } catch (error) {
    console.log('❌ 订单列表请求失败:', error.message);
  }
  
  // 5. 测试获取统计信息
  console.log('\n5. 测试获取统计信息...');
  try {
    const statsRes = await makeRequest('/api/admin/stats', 'GET', null, token);
    if (statsRes.ok) {
      console.log('✅ 获取统计信息成功');
      console.log('   用户数:', statsRes.stats.totalUsers);
      console.log('   订单数:', statsRes.stats.totalOrders);
      console.log('   总收入:', statsRes.stats.totalRevenue);
    } else {
      console.log('❌ 获取统计信息失败:', statsRes.msg);
    }
  } catch (error) {
    console.log('❌ 统计信息请求失败:', error.message);
  }
  
  // 6. 测试公开统计接口（无需token）
  console.log('\n6. 测试公开统计接口...');
  try {
    const publicStatsRes = await makeRequest('/api/stats', 'GET');
    if (publicStatsRes.ok) {
      console.log('✅ 公开统计接口正常');
      console.log('   数据:', publicStatsRes.stats);
    } else {
      console.log('❌ 公开统计接口失败:', publicStatsRes.msg);
    }
  } catch (error) {
    console.log('❌ 公开统计接口请求失败:', error.message);
  }
  
  console.log('\n🎉 测试完成！');
  console.log('\n📋 管理员控制台访问地址:');
  console.log('   登录页面: http://localhost:3000/admin/login.html');
  console.log('   仪表盘:   http://localhost:3000/admin/dashboard.html');
  console.log('   用户管理: http://localhost:3000/admin/users.html');
  console.log('\n🔑 测试账号:');
  console.log(`   手机号: ${TEST_PHONE}`);
  console.log(`   密码: ${TEST_PASSWORD}`);
}

// HTTP请求辅助函数
function makeRequest(path, method = 'GET', data = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }
    
    const req = http.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          resolve(JSON.parse(responseData));
        } catch (error) {
          resolve({ ok: false, msg: '响应解析失败' });
        }
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// 运行测试
testAPI().catch(console.error);