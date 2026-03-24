const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Platform, X-Client-Version',
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function errorResponse(message, status = 400) {
  return jsonResponse({ success: false, error: message }, status);
}

async function logOrderEvent(env, orderId, eventType, message, meta = {}, source = 'system') {
  try {
    const createdAt = new Date().toISOString();

    await env.DB.prepare(`
      INSERT INTO order_events (
        order_id, event_type, event_source, message, meta_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      orderId,
      eventType,
      source,
      message || '',
      JSON.stringify(meta || {}),
      createdAt
    ).run();

    await appendOrderEventToGoogleSheets(env, {
      created_at: createdAt,
      order_id: orderId,
      event_type: eventType,
      event_source: source,
      message: message || '',
      meta_json: JSON.stringify(meta || {}),
    });
  } catch (e) {
    console.error('logOrderEvent error:', e);

    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order_event',
      entity_id: orderId,
      action: eventType,
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }
}

// ═══════════════════ JWT ═══════════════════
async function generateJWT(payload, secret) {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const body = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const data = `${header}.${body}`;
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${data}.${sigB64}`;
}

async function verifyJWT(token, secret) {
  try {
    const [header, payload, sig] = token.split('.');
    const data = `${header}.${payload}`;
    const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);
    const sigBytes = Uint8Array.from(atob(sig.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0));
    const valid = await crypto.subtle.verify('HMAC', key, sigBytes, new TextEncoder().encode(data));
    if (!valid) return null;
    const decoded = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')));
    if (decoded.exp < Math.floor(Date.now() / 1000)) return null;
    return decoded;
  } catch { return null; }
}

async function authMiddleware(request, env) {
  const auth = request.headers.get('Authorization');
  if (!auth?.startsWith('Bearer ')) return null;
  return await verifyJWT(auth.slice(7), env.JWT_SECRET);
}

// ═══════════════════ FCM ═══════════════════
function b64url(str) {
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

async function getAccessToken(env) {
  const cached = await env.KV.get('fcm_access_token');
  if (cached) return cached;
  try {
    const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
    const now = Math.floor(Date.now() / 1000);
    const claim = b64url(JSON.stringify({
      iss: env.FCM_CLIENT_EMAIL,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }));
    const sigInput = `${header}.${claim}`;
    const pemBody = env.FCM_PRIVATE_KEY.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, '');
    const binaryDer = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0));
    const privateKey = await crypto.subtle.importKey('pkcs8', binaryDer, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
    const sigBuffer = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(sigInput));
    const sigBytes = new Uint8Array(sigBuffer);
    let sigStr = '';
    for (let i = 0; i < sigBytes.length; i++) sigStr += String.fromCharCode(sigBytes[i]);
    const sig = b64url(sigStr);
    const jwt = `${sigInput}.${sig}`;
    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });
    const tokenData = await tokenRes.json();
    if (tokenData.access_token) {
      await env.KV.put('fcm_access_token', tokenData.access_token, { expirationTtl: 3300 });
      return tokenData.access_token;
    }
  } catch (e) { console.error('FCM token error:', e); }
  return null;
}

// ═══════════════════ GOOGLE SHEETS ═══════════════════
function base64UrlEncode(bytes) {
  let binary = '';
  const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  for (let i = 0; i < arr.length; i++) {
    binary += String.fromCharCode(arr[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function utf8ToBase64Url(str) {
  return base64UrlEncode(new TextEncoder().encode(str));
}

async function getGoogleSheetsAccessToken(env) {
  const cached = await env.KV.get('google_sheets_access_token');
  if (cached) return cached;

  const now = Math.floor(Date.now() / 1000);
  const header = utf8ToBase64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = utf8ToBase64Url(JSON.stringify({
    iss: env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
    scope: 'https://www.googleapis.com/auth/spreadsheets',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }));

  const signingInput = `${header}.${claim}`;

  const pem = env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\\n/g, '\n')
    .replace(/\n/g, '');

  const binaryDer = Uint8Array.from(atob(pem), c => c.charCodeAt(0));

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${base64UrlEncode(signature)}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok || !tokenJson.access_token) {
    throw new Error(`Google token error: ${JSON.stringify(tokenJson)}`);
  }

  await env.KV.put('google_sheets_access_token', tokenJson.access_token, {
    expirationTtl: 3300,
  });

  return tokenJson.access_token;
}

async function googleSheetsRequest(env, method, path, body) {
  const token = await getGoogleSheetsAccessToken(env);

  const res = await fetch(`https://sheets.googleapis.com/v4/spreadsheets/${env.GOOGLE_SHEETS_SPREADSHEET_ID}${path}`, {
    method,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  let json = {};
  try { json = text ? JSON.parse(text) : {}; } catch (_) {}

  if (!res.ok) {
    throw new Error(`Sheets API ${method} ${path} failed: ${text}`);
  }

  return json;
}

async function getSheetValues(env, tabName) {
  const encodedRange = encodeURIComponent(`${tabName}!A:ZZ`);
  const json = await googleSheetsRequest(env, 'GET', `/values/${encodedRange}`, null);
  return json.values || [];
}

async function appendSheetRow(env, tabName, row) {
  const encodedRange = encodeURIComponent(`${tabName}!A:ZZ`);
  return await googleSheetsRequest(env, 'POST', `/values/${encodedRange}:append?valueInputOption=RAW`, {
    values: [row],
  });
}

async function updateSheetRow(env, tabName, rowIndex1Based, row) {
  const encodedRange = encodeURIComponent(`${tabName}!A${rowIndex1Based}:ZZ${rowIndex1Based}`);
  return await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, {
    values: [row],
  });
}

async function findSheetRowIndexByKey(env, tabName, keyColumnIndex, keyValue) {
  const rows = await getSheetValues(env, tabName);
  if (!rows || rows.length < 2) return null;

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i] || [];
    if ((row[keyColumnIndex] || '').toString() === (keyValue || '').toString()) {
      return i + 1; // 1-based row index in Google Sheets
    }
  }
  return null;
}

async function upsertSheetRow(env, tabName, keyColumnIndex, keyValue, row) {
  const existingRowIndex = await findSheetRowIndexByKey(env, tabName, keyColumnIndex, keyValue);
  if (existingRowIndex) {
    return await updateSheetRow(env, tabName, existingRowIndex, row);
  }
  return await appendSheetRow(env, tabName, row);
}

function safeText(value) {
  return value == null ? '' : String(value);
}

function safeNumber(value) {
  if (value == null || value === '') return 0;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function itemsSummaryFromJson(itemsRaw) {
  try {
    const items = typeof itemsRaw === 'string' ? JSON.parse(itemsRaw || '[]') : (itemsRaw || []);
    if (!Array.isArray(items)) return '';
    return items.map(i => `${i.name || i.sku || 'Item'} x${i.qty || i.quantity || 1}`).join(', ');
  } catch (_) {
    return '';
  }
}

function labelsSummary(labelsRaw) {
  try {
    const labels = typeof labelsRaw === 'string' ? JSON.parse(labelsRaw || '[]') : (labelsRaw || []);
    if (!Array.isArray(labels)) return '';
    return labels.join(', ');
  } catch (_) {
    return '';
  }
}

function tagsSummary(tagsRaw) {
  try {
    const tags = typeof tagsRaw === 'string' ? JSON.parse(tagsRaw || '[]') : (tagsRaw || []);
    if (!Array.isArray(tags)) return '';
    return tags.join(', ');
  } catch (_) {
    return '';
  }
}

function mapOrderToSheetRow(order) {
  return [
    safeText(order.order_id),
    safeText(order.created_at),
    safeText(order.updated_at),
    safeText(order.customer_name),
    safeText(order.phone),
    safeText(order.source),
    itemsSummaryFromJson(order.items),
    safeNumber(order.item_count),
    safeNumber(order.subtotal),
    safeNumber(order.shipping_cost),
    safeNumber(order.total),
    safeText(order.status),
    safeText(order.payment_status),
    safeText(order.payment_id),
    safeText(order.payment_method),
    safeText(order.payment_link),
    safeText(order.payment_link_expires),
    safeText(order.shipping_name),
    safeText(order.shipping_phone),
    safeText(order.shipping_address),
    safeText(order.shipping_city),
    safeText(order.shipping_state),
    safeText(order.shipping_pincode),
    safeText(order.paid_at),
    safeText(order.cancelled_at),
    safeText(order.cancellation_reason),
    safeText(order.customer_notes),
    safeText(order.internal_notes),
    '', // owner_note (manual)
    '', // follow_up_needed (manual)
    '', // verified (manual)
  ];
}

async function getAllProductCategories(env) {
  const { results } = await env.DB.prepare(`SELECT sku, category FROM products`).all();
  const map = {};
  for (const p of (results || [])) {
    if (p.sku && p.category) map[p.sku] = p.category;
  }
  return map;
}

function getCategoryFromItems(itemsRaw, categoryMap) {
  try {
    const items = typeof itemsRaw === 'string' ? JSON.parse(itemsRaw || '[]') : (itemsRaw || []);
    if (!Array.isArray(items)) return '';
    const cats = [];
    for (const item of items) {
      const cat = categoryMap[item.sku];
      if (cat && !cats.includes(cat)) cats.push(cat);
    }
    return cats.join(', ');
  } catch (_) { return ''; }
}

function parseProductImages(product) {
  let images = [];
  try {
    images = typeof product.images === 'string'
      ? JSON.parse(product.images || '[]')
      : (product.images || []);
    if (!Array.isArray(images)) images = [];
  } catch (_) { images = []; }
  return {
    image_1: images[0] || '',
    image_2: images[1] || '',
    image_3: images[2] || '',
  };
}

function mapCustomerToSheetRow(customer, unpaidOrderCount = 0, unpaidOrderValue = 0) {
  let cartItems = [];
  try {
    cartItems = JSON.parse(customer.cart || '[]');
    if (!Array.isArray(cartItems)) cartItems = [];
  } catch (_) {
    cartItems = [];
  }

  const cartItemCount = cartItems.reduce((sum, item) => {
    return sum + Number(item.qty || item.quantity || 1);
  }, 0);

  const cartValue = cartItems.reduce((sum, item) => {
    const qty = Number(item.qty || item.quantity || 1);
    const price = Number(item.price || 0);
    return sum + (qty * price);
  }, 0);

  return [
    safeText(customer.phone),
    safeText(customer.name),
    safeText(customer.email),
    safeText(customer.city),
    safeText(customer.state),
    safeText(customer.pincode),
    '', // source, can derive later
    safeText(customer.segment),
    safeText(customer.tier),
    labelsSummary(customer.labels),
    safeNumber(customer.message_count),
    safeNumber(customer.order_count),
    safeNumber(customer.total_spent),
    cartItemCount,
    cartValue,
    safeNumber(unpaidOrderCount),
    safeNumber(unpaidOrderValue),
    safeText(customer.first_seen),
    safeText(customer.last_seen),
    safeText(customer.last_order_at),
    '', // owner_note (manual)
    '', // follow_up_priority (manual)
  ];
}

function mapProductToSheetRow(product) {
  return [
    safeText(product.sku),
    safeText(product.name),
    safeText(product.category),
    safeText(product.subcategory),
    safeNumber(product.price),
    safeNumber(product.compare_price),
    safeNumber(product.stock),
    safeNumber(product.reserved_stock),
    safeText(product.is_active),
    safeText(product.is_featured),
    safeText(product.image_url),
    safeText(product.website_link),
    safeText(product.material),
    tagsSummary(product.tags),
    safeText(product.updated_at),
    '', // restock_note (manual)
  ];
}

function mapShipmentToSheetRow(order) {
  return [
    safeText(order.order_id),
    safeText(order.customer_name),
    safeText(order.phone),
    safeText(order.status),
    safeText(order.payment_status),
    safeText(order.shiprocket_order_id),
    safeText(order.shipment_id),
    safeText(order.courier),
    safeText(order.awb_number),
    safeText(order.awb_code),
    safeText(order.tracking_id),
    safeText(order.tracking_url),
    safeText(order.shipping_city),
    safeText(order.shipping_state),
    safeText(order.shipping_pincode),
    safeText(order.paid_at),
    safeText(order.shipped_at),
    safeText(order.delivered_at),
    safeText(order.updated_at),
    '', // dispatch_note (manual)
    '', // dispatch_verified (manual)
  ];
}

function mapCartToSheetRow(cart, customerName = '') {
  return [
    safeText(cart.phone),
    safeText(customerName),
    safeNumber(cart.item_count),
    safeNumber(cart.total),
    itemsSummaryFromJson(cart.items),
    safeText(cart.status),
    safeNumber(cart.reminder_count),
    safeText(cart.last_reminder_at),
    safeText(cart.created_at),
    safeText(cart.updated_at),
    safeText(cart.converted_at),
    '', // owner_note (manual)
    '', // follow_up_needed (manual)
  ];
}

function deriveLeadStatus(customer) {
  const orderCount = safeNumber(customer.order_count);
  const totalSpent = safeNumber(customer.total_spent);
  const messageCount = safeNumber(customer.message_count);

  if (orderCount > 0 || totalSpent > 0) return 'ordered';
  if (messageCount >= 5) return 'interested';
  if (messageCount > 0) return 'engaged';
  return 'new';
}

function mapLeadToSheetRow(customer) {
  return [
    safeText(customer.created_at || customer.first_seen),
    safeText(customer.phone),
    safeText(customer.name),
    '', // source, derive later if available
    deriveLeadStatus(customer),
    safeNumber(customer.message_count),
    safeNumber(customer.order_count),
    safeNumber(customer.total_spent),
    safeText(customer.segment),
    safeText(customer.tier),
    labelsSummary(customer.labels),
    safeText(customer.last_seen),
    safeText(customer.last_order_at),
    '', // owner_note (manual)
    '', // follow_up_needed (manual)
  ];
}

function deriveSalesStage(order) {
  if (safeText(order.status) === 'delivered') return 'delivered';
  if (safeText(order.status) === 'shipped') return 'shipped';
  if (safeText(order.payment_status) === 'paid') return 'paid';
  if (safeText(order.payment_status) === 'unpaid') return 'unpaid';
  return 'lead';
}

function mapSalesToSheetRow(order) {
  return [
    safeText(order.order_id),
    safeText(order.created_at),
    safeText(order.source),
    safeText(order.customer_name),
    safeText(order.phone),
    safeNumber(order.total),
    safeText(order.payment_status),
    safeText(order.status),
    safeText(order.paid_at),
    safeText(order.shipped_at),
    safeText(order.delivered_at),
    safeNumber(order.item_count),
    itemsSummaryFromJson(order.items),
    deriveSalesStage(order),
    '', // owner_note (manual)
  ];
}

async function appendOrderEventToGoogleSheets(env, eventRow) {
  try {
    await appendSheetRow(env, 'Order Events', [
      safeText(eventRow.created_at),
      safeText(eventRow.order_id),
      safeText(eventRow.event_type),
      safeText(eventRow.event_source),
      safeText(eventRow.message),
      safeText(eventRow.meta_json),
    ]);
  } catch (e) {
    console.error('Order Events sheet append error:', e);
  }
}

async function appendSyncFailureToGoogleSheets(env, failure) {
  try {
    await appendSheetRow(env, 'Sync Failures', [
      safeText(failure.created_at || new Date().toISOString()),
      safeText(failure.destination || 'google_sheets'),
      safeText(failure.entity_type),
      safeText(failure.entity_id),
      safeText(failure.action),
      safeText(failure.error_message),
      safeText(failure.retry_count || 0),
      safeText(failure.status || 'failed'),
    ]);
  } catch (e) {
    console.error('Sync Failures sheet append error:', e);
  }
}



async function syncOrderToGoogleSheets(env, orderId) {
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) throw new Error(`Order not found for Sheets sync: ${orderId}`);

  const row = mapOrderToSheetRow(order);
  await upsertSheetRow(env, 'Orders', 0, order.order_id, row);
}

async function syncCustomerToGoogleSheets(env, phone) {
  const customer = await env.DB.prepare(
    `SELECT * FROM customers WHERE phone = ?`
  ).bind(phone).first();

  if (!customer) return;

  const unpaid = await env.DB.prepare(`
    SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as value
    FROM orders
    WHERE phone = ?
      AND payment_status = 'unpaid'
      AND status != 'cancelled'
  `).bind(phone).first();

  const row = mapCustomerToSheetRow(
    customer,
    unpaid?.count || 0,
    unpaid?.value || 0
  );

  await upsertSheetRow(env, 'Customers', 0, customer.phone, row);
}

async function syncProductToGoogleSheets(env, sku) {
  const product = await env.DB.prepare(
    `SELECT * FROM products WHERE sku = ?`
  ).bind(sku).first();

  if (!product) throw new Error(`Product not found for Sheets sync: ${sku}`);

  const row = mapProductToSheetRow(product);
  await upsertSheetRow(env, 'Inventory', 0, product.sku, row);
}



async function syncSalesToGoogleSheets(env, orderId) {
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) return;

  const row = mapSalesToSheetRow(order);
  await upsertSheetRow(env, 'Sales', 0, order.order_id, row);
}

async function rebuildSourcePerformanceSheet(env) {
  const today = new Date().toISOString().slice(0, 10);

  const sourceRows = await env.DB.prepare(`
    SELECT
      LOWER(COALESCE(source, 'unknown')) as source,
      COUNT(*) as orders,
      SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) as paid_orders,
      COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN total ELSE 0 END), 0) as revenue
    FROM orders
    GROUP BY LOWER(COALESCE(source, 'unknown'))
  `).all();

  const leadRows = await env.DB.prepare(`
    SELECT
      '' as source,
      COUNT(*) as leads
    FROM customers
  `).all();

  const values = [[
    'date', 'source', 'leads', 'orders', 'paid_orders', 'revenue', 'avg_order_value', 'conversion_rate', 'notes'
  ]];

  const leadsFallback = Number(leadRows?.results?.[0]?.leads || 0);

  for (const row of (sourceRows?.results || [])) {
    const orders = Number(row.orders || 0);
    const paidOrders = Number(row.paid_orders || 0);
    const revenue = Number(row.revenue || 0);
    const avgOrderValue = paidOrders > 0 ? revenue / paidOrders : 0;
    const conversionRate = leadsFallback > 0 ? (orders / leadsFallback) * 100 : 0;

    values.push([
      today,
      safeText(row.source),
      leadsFallback,
      orders,
      paidOrders,
      revenue,
      avgOrderValue.toFixed(2),
      conversionRate.toFixed(2),
      '',
    ]);
  }

  const encodedRange = encodeURIComponent('Source Performance!A:I');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, {
    values,
  });
}

async function syncShipmentToGoogleSheets(env, orderId) {
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) throw new Error(`Order not found for shipment sync: ${orderId}`);

  const row = mapShipmentToSheetRow(order);
  await upsertSheetRow(env, 'Shipments', 0, order.order_id, row);
}

async function syncCartToGoogleSheets(env, phone) {
  const cart = await env.DB.prepare(
    `SELECT * FROM carts WHERE phone = ?`
  ).bind(phone).first();

  if (!cart) return;

  const customer = await env.DB.prepare(
    `SELECT name FROM customers WHERE phone = ?`
  ).bind(phone).first();

  const row = mapCartToSheetRow(cart, customer?.name || '');
  await upsertSheetRow(env, 'Cart Activity', 0, cart.phone, row);
}

async function syncLeadToGoogleSheets(env, phone) {
  const customer = await env.DB.prepare(
    `SELECT * FROM customers WHERE phone = ?`
  ).bind(phone).first();

  if (!customer) return;

  const row = mapLeadToSheetRow(customer);
  await upsertSheetRow(env, 'Leads', 1, customer.phone, row);
}

const SHEET_MANUAL_COLUMNS = {
  'Orders': [30, 31, 32],
  'Shipments': [19, 20],
  'Inventory': [18],
  'Order Events': [],
  'Sync Failures': [],
  'Leads': [15, 16],
  'Sales': [15],
  'Source Performance': [8],
  'Customers': [21, 22],
  'Cart Activity': [11, 12],
};

const SHEET_HEADERS = {
  'Orders': [
    'order_id','created_at','updated_at','customer_name','phone','source','category',
    'items_summary','item_count','subtotal','shipping_cost','total',
    'status','payment_status','payment_id','payment_method','payment_link','payment_link_expires',
    'shipping_name','shipping_phone','shipping_address','shipping_city','shipping_state','shipping_pincode',
    'paid_at','cancelled_at','cancellation_reason','customer_notes','internal_notes',
    'owner_note','follow_up_needed','verified'
  ],
  'Customers': [
    'phone','name','email','city','state','pincode','source','segment','tier','labels',
    'message_count','order_count','total_spent','cart_item_count','cart_value',
    'unpaid_order_count','unpaid_order_value','first_seen','last_seen','last_order_at',
    'owner_note','follow_up_priority'
  ],
  'Leads': [
    'created_at','phone','name','source','category','lead_status',
    'message_count','order_count','total_spent','segment','tier','labels',
    'last_seen','first_order_at',
    'owner_note','follow_up_needed'
  ],
  'Sales': [
    'order_id','created_at','source','category','customer_name','phone','total',
    'payment_status','status','paid_at','shipped_at','delivered_at',
    'item_count','items_summary','sales_stage','owner_note'
  ],
  'Inventory': [
    'sku','name','category','subcategory','price','compare_price','stock','reserved_stock',
    'status','is_featured','image_url','website_link','material','tags_summary','updated_at',
    'image_1','image_2','image_3','restock_note'
  ],
  'Shipments': [
    'order_id','customer_name','phone','status','payment_status',
    'shiprocket_order_id','shipment_id','courier','awb_number','awb_code',
    'tracking_id','tracking_url','shipping_city','shipping_state','shipping_pincode',
    'paid_at','shipped_at','delivered_at','updated_at',
    'dispatch_note','dispatch_verified'
  ],
  'Cart Activity': [
    'phone','customer_name','item_count','total','items_summary','status',
    'reminder_count','last_reminder_at','created_at','updated_at','converted_at',
    'owner_note','follow_up_needed'
  ],
};
 
function mergeSheetRowPreservingManual(existingRow = [], newRow = [], manualIndexes = []) {
  const maxLen = Math.max(existingRow.length, newRow.length);
  const merged = Array.from({ length: maxLen }, (_, i) =>
    i < newRow.length ? newRow[i] : (existingRow[i] ?? '')
  );

  for (const idx of manualIndexes) {
    if (existingRow[idx] !== undefined && existingRow[idx] !== '') {
      merged[idx] = existingRow[idx];
    }
  }

  return merged;
}

async function getSheetRowByKey(env, tabName, keyColumnIndex, keyValue) {
  const rows = await getSheetValues(env, tabName);
  if (!rows || rows.length < 2) return null;

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i] || [];
    if ((row[keyColumnIndex] || '').toString() === (keyValue || '').toString()) {
      return { rowIndex1Based: i + 1, row };
    }
  }
  return null;
}

async function upsertSheetRowSafe(env, tabName, keyColumnIndex, keyValue, row) {
  const existing = await getSheetRowByKey(env, tabName, keyColumnIndex, keyValue);
  const manualIndexes = SHEET_MANUAL_COLUMNS[tabName] || [];

  if (existing) {
    const mergedRow = mergeSheetRowPreservingManual(existing.row, row, manualIndexes);
    return await updateSheetRow(env, tabName, existing.rowIndex1Based, mergedRow);
  }

  return await appendSheetRow(env, tabName, row);
}

async function syncOrderToGoogleSheetsSafe(env, orderId) {
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();
  if (!order) return;

  const categoryMap = await getAllProductCategories(env);
  const category = getCategoryFromItems(order.items, categoryMap);

  const row = [
    safeText(order.order_id),
    safeText(order.created_at),
    safeText(order.updated_at),
    safeText(order.customer_name),
    safeText(order.phone),
    safeText(order.source),
    safeText(category),
    itemsSummaryFromJson(order.items),
    safeNumber(order.item_count),
    safeNumber(order.subtotal),
    safeNumber(order.shipping_cost),
    safeNumber(order.total),
    safeText(order.status),
    safeText(order.payment_status),
    safeText(order.payment_id),
    safeText(order.payment_method),
    safeText(order.payment_link),
    safeText(order.payment_link_expires),
    safeText(order.shipping_name),
    safeText(order.shipping_phone),
    safeText(order.shipping_address),
    safeText(order.shipping_city),
    safeText(order.shipping_state),
    safeText(order.shipping_pincode),
    safeText(order.paid_at),
    safeText(order.cancelled_at),
    safeText(order.cancellation_reason),
    safeText(order.customer_notes),
    safeText(order.internal_notes),
    '', '', '',
  ];

  await upsertSheetRowSafe(env, 'Orders', 0, order.order_id, row);
}

async function syncSalesToGoogleSheetsSafe(env, orderId) {
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();
  if (!order) return;

  const categoryMap = await getAllProductCategories(env);
  const category = getCategoryFromItems(order.items, categoryMap);

  const row = [
    safeText(order.order_id),
    safeText(order.created_at),
    safeText(order.source),
    safeText(category),
    safeText(order.customer_name),
    safeText(order.phone),
    safeNumber(order.total),
    safeText(order.payment_status),
    safeText(order.status),
    safeText(order.paid_at),
    safeText(order.shipped_at),
    safeText(order.delivered_at),
    safeNumber(order.item_count),
    itemsSummaryFromJson(order.items),
    deriveSalesStage(order),
    '',
  ];

  await upsertSheetRowSafe(env, 'Sales', 0, order.order_id, row);
}

async function syncLeadToGoogleSheetsSafe(env, phone) {
  const customer = await env.DB.prepare(
    `SELECT * FROM customers WHERE phone = ?`
  ).bind(phone).first();
  if (!customer) return;

  const categoryMap = await getAllProductCategories(env);

  const orderStats = await env.DB.prepare(`
    SELECT
      COUNT(*) as order_count,
      COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN total ELSE 0 END), 0) as total_spent
    FROM orders WHERE phone = ? OR phone = ?
  `).bind(phone, phone.replace(/^91/, '')).first();

  const firstOrder = await env.DB.prepare(`
    SELECT source, items, created_at
    FROM orders
    WHERE phone = ? OR phone = ?
    ORDER BY datetime(created_at) ASC
    LIMIT 1
  `).bind(phone, phone.replace(/^91/, '')).first();

  const category = firstOrder ? getCategoryFromItems(firstOrder.items, categoryMap) : '';
  const orderCount = safeNumber(orderStats?.order_count || 0);
  const totalSpent = safeNumber(orderStats?.total_spent || 0);
  const messageCount = safeNumber(customer.message_count);

  let leadStatus = 'new';
  if (orderCount > 0 || totalSpent > 0) leadStatus = 'ordered';
  else if (messageCount >= 5) leadStatus = 'interested';
  else if (messageCount > 0) leadStatus = 'engaged';

  const row = [
    safeText(customer.created_at || customer.first_seen),
    safeText(customer.phone),
    safeText(customer.name),
    safeText(firstOrder?.source || ''),
    safeText(category),
    leadStatus,
    messageCount,
    orderCount,
    totalSpent,
    safeText(customer.segment),
    safeText(customer.tier),
    labelsSummary(customer.labels),
    safeText(customer.last_seen),
    safeText(firstOrder?.created_at || ''),
    '', '',
  ];

  await upsertSheetRowSafe(env, 'Leads', 1, customer.phone, row);
}

async function syncCustomerToGoogleSheetsSafe(env, phone) {
  const customer = await env.DB.prepare(
    `SELECT * FROM customers WHERE phone = ?`
  ).bind(phone).first();
  if (!customer) return;

  const orderStats = await env.DB.prepare(`
    SELECT
      COUNT(*) as order_count,
      COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN total ELSE 0 END), 0) as total_spent
    FROM orders WHERE phone = ? OR phone = ?
  `).bind(phone, phone.replace(/^91/, '')).first();

  const unpaid = await env.DB.prepare(`
    SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as value
    FROM orders
    WHERE (phone = ? OR phone = ?)
      AND payment_status = 'unpaid'
      AND status != 'cancelled'
  `).bind(phone, phone.replace(/^91/, '')).first();

  const firstOrder = await env.DB.prepare(`
    SELECT source, shipping_city, shipping_state, shipping_pincode
    FROM orders
    WHERE phone = ? OR phone = ?
    ORDER BY datetime(created_at) ASC
    LIMIT 1
  `).bind(phone, phone.replace(/^91/, '')).first();

  let cartItems = [];
  try {
    cartItems = JSON.parse(customer.cart || '[]');
    if (!Array.isArray(cartItems)) cartItems = [];
  } catch (_) { cartItems = []; }

  const cartItemCount = cartItems.reduce((s, i) => s + Number(i.qty || i.quantity || 1), 0);
  const cartValue = cartItems.reduce((s, i) => {
    return s + (Number(i.qty || i.quantity || 1) * Number(i.price || 0));
  }, 0);

  const row = [
    safeText(customer.phone),
    safeText(customer.name),
    safeText(customer.email),
    safeText(customer.city || firstOrder?.shipping_city || ''),
    safeText(customer.state || firstOrder?.shipping_state || ''),
    safeText(customer.pincode || firstOrder?.shipping_pincode || ''),
    safeText(firstOrder?.source || ''),
    safeText(customer.segment),
    safeText(customer.tier),
    labelsSummary(customer.labels),
    safeNumber(customer.message_count),
    safeNumber(orderStats?.order_count || 0),
    safeNumber(orderStats?.total_spent || 0),
    cartItemCount,
    cartValue,
    safeNumber(unpaid?.count || 0),
    safeNumber(unpaid?.value || 0),
    safeText(customer.first_seen),
    safeText(customer.last_seen),
    safeText(customer.last_order_at),
    '', '',
  ];

  await upsertSheetRowSafe(env, 'Customers', 0, customer.phone, row);
}

async function syncProductToGoogleSheetsSafe(env, sku) {
  const product = await env.DB.prepare(
    `SELECT * FROM products WHERE sku = ?`
  ).bind(sku).first();
  if (!product) return;

  const imgs = parseProductImages(product);

  const row = [
    safeText(product.sku),
    safeText(product.name),
    safeText(product.category),
    safeText(product.subcategory),
    safeNumber(product.price),
    safeNumber(product.compare_price),
    safeNumber(product.stock),
    safeNumber(product.reserved_stock || 0),
    product.is_active ? 'Enabled' : 'Disabled',
    product.is_featured ? 'Yes' : 'No',
    safeText(product.image_url),
    safeText(product.website_link),
    safeText(product.material),
    tagsSummary(product.tags),
    safeText(product.updated_at),
    safeText(imgs.image_1),
    safeText(imgs.image_2),
    safeText(imgs.image_3),
    '',
  ];

  await upsertSheetRowSafe(env, 'Inventory', 0, product.sku, row);
}

async function syncShipmentToGoogleSheetsSafe(env, orderId) {
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) throw new Error(`Order not found for shipment sync: ${orderId}`);

  const row = mapShipmentToSheetRow(order);
  await upsertSheetRowSafe(env, 'Shipments', 0, order.order_id, row);
}

async function syncCartToGoogleSheetsSafe(env, phone) {
  const cart = await env.DB.prepare(
    `SELECT * FROM carts WHERE phone = ?`
  ).bind(phone).first();

  if (!cart) return;

  const customer = await env.DB.prepare(
    `SELECT name FROM customers WHERE phone = ?`
  ).bind(phone).first();

  const row = mapCartToSheetRow(cart, customer?.name || '');
  await upsertSheetRowSafe(env, 'Cart Activity', 0, cart.phone, row);
}


async function backfillOrdersToGoogleSheets(env) {
  const { results: orders } = await env.DB.prepare(`
    SELECT * FROM orders ORDER BY created_at DESC
  `).all();

  if (!orders || orders.length === 0) return { totalOrders: 0 };

  const categoryMap = await getAllProductCategories(env);
  const existing = await getSheetValues(env, 'Orders');
  const manualIndexes = SHEET_MANUAL_COLUMNS['Orders'] || [];

  const existingMap = {};
  for (let i = 1; i < (existing || []).length; i++) {
    const key = (existing[i] || [])[0];
    if (key) existingMap[key] = existing[i];
  }

  const rows = [SHEET_HEADERS['Orders']];

  for (const order of orders) {
    const category = getCategoryFromItems(order.items, categoryMap);
    const newRow = [
      safeText(order.order_id),
      safeText(order.created_at),
      safeText(order.updated_at),
      safeText(order.customer_name),
      safeText(order.phone),
      safeText(order.source),
      safeText(category),
      itemsSummaryFromJson(order.items),
      safeNumber(order.item_count),
      safeNumber(order.subtotal),
      safeNumber(order.shipping_cost),
      safeNumber(order.total),
      safeText(order.status),
      safeText(order.payment_status),
      safeText(order.payment_id),
      safeText(order.payment_method),
      safeText(order.payment_link),
      safeText(order.payment_link_expires),
      safeText(order.shipping_name),
      safeText(order.shipping_phone),
      safeText(order.shipping_address),
      safeText(order.shipping_city),
      safeText(order.shipping_state),
      safeText(order.shipping_pincode),
      safeText(order.paid_at),
      safeText(order.cancelled_at),
      safeText(order.cancellation_reason),
      safeText(order.customer_notes),
      safeText(order.internal_notes),
      '', '', '',
    ];

    const existingRow = existingMap[order.order_id] || [];
    const merged = mergeSheetRowPreservingManual(existingRow, newRow, manualIndexes);
    rows.push(merged);
  }

  const encodedRange = encodeURIComponent('Orders!A:ZZ');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values: rows });

  return { totalOrders: orders.length };
}

async function backfillCustomersToGoogleSheets(env) {
  const { results: customers } = await env.DB.prepare(`
    SELECT * FROM customers ORDER BY last_seen DESC
  `).all();

  if (!customers || customers.length === 0) return { totalCustomers: 0 };

  const existing = await getSheetValues(env, 'Customers');
  const manualIndexes = SHEET_MANUAL_COLUMNS['Customers'] || [];

  const existingMap = {};
  for (let i = 1; i < (existing || []).length; i++) {
    const key = (existing[i] || [])[0];
    if (key) existingMap[key] = existing[i];
  }

  const rows = [SHEET_HEADERS['Customers']];

  for (const customer of customers) {
    const orderStats = await env.DB.prepare(`
      SELECT
        COUNT(*) as order_count,
        COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN total ELSE 0 END), 0) as total_spent,
        MIN(created_at) as first_order_at
      FROM orders WHERE phone = ? OR phone = ?
    `).bind(customer.phone, customer.phone.replace(/^91/, '')).first();

    const unpaid = await env.DB.prepare(`
      SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as value
      FROM orders
      WHERE (phone = ? OR phone = ?)
        AND payment_status = 'unpaid'
        AND status != 'cancelled'
    `).bind(customer.phone, customer.phone.replace(/^91/, '')).first();

    const firstOrder = await env.DB.prepare(`
      SELECT source, shipping_city, shipping_state, shipping_pincode
      FROM orders
      WHERE phone = ? OR phone = ?
      ORDER BY datetime(created_at) ASC
      LIMIT 1
    `).bind(customer.phone, customer.phone.replace(/^91/, '')).first();

    let cartItems = [];
    try {
      cartItems = JSON.parse(customer.cart || '[]');
      if (!Array.isArray(cartItems)) cartItems = [];
    } catch (_) { cartItems = []; }

    const cartItemCount = cartItems.reduce((s, i) => s + Number(i.qty || i.quantity || 1), 0);
    const cartValue = cartItems.reduce((s, i) => {
      return s + (Number(i.qty || i.quantity || 1) * Number(i.price || 0));
    }, 0);

    const newRow = [
      safeText(customer.phone),
      safeText(customer.name),
      safeText(customer.email),
      safeText(customer.city || firstOrder?.shipping_city || ''),
      safeText(customer.state || firstOrder?.shipping_state || ''),
      safeText(customer.pincode || firstOrder?.shipping_pincode || ''),
      safeText(firstOrder?.source || ''),
      safeText(customer.segment),
      safeText(customer.tier),
      labelsSummary(customer.labels),
      safeNumber(customer.message_count),
      safeNumber(orderStats?.order_count || customer.order_count || 0),
      safeNumber(orderStats?.total_spent || customer.total_spent || 0),
      cartItemCount,
      cartValue,
      safeNumber(unpaid?.count || 0),
      safeNumber(unpaid?.value || 0),
      safeText(customer.first_seen),
      safeText(customer.last_seen),
      safeText(orderStats?.first_order_at || customer.last_order_at || ''),
      '', '',
    ];

    const existingRow = existingMap[customer.phone] || [];
    const merged = mergeSheetRowPreservingManual(existingRow, newRow, manualIndexes);
    rows.push(merged);
  }

  const encodedRange = encodeURIComponent('Customers!A:ZZ');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values: rows });

  return { totalCustomers: customers.length };
}

async function backfillLeadsToGoogleSheets(env) {
  const { results: customers } = await env.DB.prepare(`
    SELECT * FROM customers ORDER BY last_seen DESC
  `).all();

  if (!customers || customers.length === 0) return { totalLeads: 0 };

  const categoryMap = await getAllProductCategories(env);
  const existing = await getSheetValues(env, 'Leads');
  const manualIndexes = SHEET_MANUAL_COLUMNS['Leads'] || [];

  const existingMap = {};
  for (let i = 1; i < (existing || []).length; i++) {
    const key = (existing[i] || [])[1];
    if (key) existingMap[key] = existing[i];
  }

  const rows = [SHEET_HEADERS['Leads']];

  for (const customer of customers) {
    const orderStats = await env.DB.prepare(`
      SELECT
        COUNT(*) as order_count,
        COALESCE(SUM(CASE WHEN payment_status = 'paid' THEN total ELSE 0 END), 0) as total_spent,
        MIN(created_at) as first_order_at
      FROM orders WHERE phone = ? OR phone = ?
    `).bind(customer.phone, customer.phone.replace(/^91/, '')).first();

    const firstOrder = await env.DB.prepare(`
      SELECT source, items, created_at
      FROM orders
      WHERE phone = ? OR phone = ?
      ORDER BY datetime(created_at) ASC
      LIMIT 1
    `).bind(customer.phone, customer.phone.replace(/^91/, '')).first();

    const category = firstOrder ? getCategoryFromItems(firstOrder.items, categoryMap) : '';
    const orderCount = safeNumber(orderStats?.order_count || customer.order_count || 0);
    const totalSpent = safeNumber(orderStats?.total_spent || customer.total_spent || 0);
    const messageCount = safeNumber(customer.message_count);

    let leadStatus = 'new';
    if (orderCount > 0 || totalSpent > 0) leadStatus = 'ordered';
    else if (messageCount >= 5) leadStatus = 'interested';
    else if (messageCount > 0) leadStatus = 'engaged';

    const newRow = [
      safeText(customer.created_at || customer.first_seen),
      safeText(customer.phone),
      safeText(customer.name),
      safeText(firstOrder?.source || ''),
      safeText(category),
      leadStatus,
      messageCount,
      orderCount,
      totalSpent,
      safeText(customer.segment),
      safeText(customer.tier),
      labelsSummary(customer.labels),
      safeText(customer.last_seen),
      safeText(firstOrder?.created_at || ''),
      '', '',
    ];

    const existingRow = existingMap[customer.phone] || [];
    const merged = mergeSheetRowPreservingManual(existingRow, newRow, manualIndexes);
    rows.push(merged);
  }

  const encodedRange = encodeURIComponent('Leads!A:ZZ');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values: rows });

  return { totalLeads: customers.length };
}

async function backfillSalesToGoogleSheets(env) {
  const { results: orders } = await env.DB.prepare(`
    SELECT * FROM orders ORDER BY created_at DESC
  `).all();

  if (!orders || orders.length === 0) return { totalSales: 0 };

  const categoryMap = await getAllProductCategories(env);
  const existing = await getSheetValues(env, 'Sales');
  const manualIndexes = SHEET_MANUAL_COLUMNS['Sales'] || [];

  const existingMap = {};
  for (let i = 1; i < (existing || []).length; i++) {
    const key = (existing[i] || [])[0];
    if (key) existingMap[key] = existing[i];
  }

  const rows = [SHEET_HEADERS['Sales']];

  for (const order of orders) {
    const category = getCategoryFromItems(order.items, categoryMap);
    const newRow = [
      safeText(order.order_id),
      safeText(order.created_at),
      safeText(order.source),
      safeText(category),
      safeText(order.customer_name),
      safeText(order.phone),
      safeNumber(order.total),
      safeText(order.payment_status),
      safeText(order.status),
      safeText(order.paid_at),
      safeText(order.shipped_at),
      safeText(order.delivered_at),
      safeNumber(order.item_count),
      itemsSummaryFromJson(order.items),
      deriveSalesStage(order),
      '',
    ];

    const existingRow = existingMap[order.order_id] || [];
    const merged = mergeSheetRowPreservingManual(existingRow, newRow, manualIndexes);
    rows.push(merged);
  }

  const encodedRange = encodeURIComponent('Sales!A:ZZ');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values: rows });

  return { totalSales: orders.length };
}

async function backfillProductsToGoogleSheets(env) {
  const { results: products } = await env.DB.prepare(`
    SELECT * FROM products ORDER BY name ASC
  `).all();

  if (!products || products.length === 0) return { totalProducts: 0 };

  const existing = await getSheetValues(env, 'Inventory');
  const manualIndexes = SHEET_MANUAL_COLUMNS['Inventory'] || [];

  const existingMap = {};
  for (let i = 1; i < (existing || []).length; i++) {
    const key = (existing[i] || [])[0];
    if (key) existingMap[key] = existing[i];
  }

  const rows = [SHEET_HEADERS['Inventory']];

  for (const product of products) {
    const imgs = parseProductImages(product);
    const newRow = [
      safeText(product.sku),
      safeText(product.name),
      safeText(product.category),
      safeText(product.subcategory),
      safeNumber(product.price),
      safeNumber(product.compare_price),
      safeNumber(product.stock),
      safeNumber(product.reserved_stock || 0),
      product.is_active ? 'Enabled' : 'Disabled',
      product.is_featured ? 'Yes' : 'No',
      safeText(product.image_url),
      safeText(product.website_link),
      safeText(product.material),
      tagsSummary(product.tags),
      safeText(product.updated_at),
      safeText(imgs.image_1),
      safeText(imgs.image_2),
      safeText(imgs.image_3),
      '',
    ];

    const existingRow = existingMap[product.sku] || [];
    const merged = mergeSheetRowPreservingManual(existingRow, newRow, manualIndexes);
    rows.push(merged);
  }

  const encodedRange = encodeURIComponent('Inventory!A:ZZ');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values: rows });

  return { totalProducts: products.length };
}

async function backfillShipmentsToGoogleSheets(env) {
  const { results: orders } = await env.DB.prepare(`
    SELECT * FROM orders
    WHERE (shipment_id IS NOT NULL AND shipment_id != '')
       OR (shiprocket_order_id IS NOT NULL AND shiprocket_order_id != '')
       OR (awb_number IS NOT NULL AND awb_number != '')
       OR (awb_code IS NOT NULL AND awb_code != '')
    ORDER BY created_at DESC
  `).all();

  if (!orders || orders.length === 0) return { totalShipments: 0 };

  const existing = await getSheetValues(env, 'Shipments');
  const manualIndexes = SHEET_MANUAL_COLUMNS['Shipments'] || [];

  const existingMap = {};
  for (let i = 1; i < (existing || []).length; i++) {
    const key = (existing[i] || [])[0];
    if (key) existingMap[key] = existing[i];
  }

  const rows = [SHEET_HEADERS['Shipments']];

  for (const order of orders) {
    const newRow = mapShipmentToSheetRow(order);
    const existingRow = existingMap[order.order_id] || [];
    const merged = mergeSheetRowPreservingManual(existingRow, newRow, manualIndexes);
    rows.push(merged);
  }

  const encodedRange = encodeURIComponent('Shipments!A:ZZ');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values: rows });

  return { totalShipments: orders.length };
}

async function backfillCartsToGoogleSheets(env) {
  const { results: carts } = await env.DB.prepare(`
    SELECT * FROM carts ORDER BY updated_at DESC
  `).all();

  if (!carts || carts.length === 0) return { totalCarts: 0 };

  const existing = await getSheetValues(env, 'Cart Activity');
  const manualIndexes = SHEET_MANUAL_COLUMNS['Cart Activity'] || [];

  const existingMap = {};
  for (let i = 1; i < (existing || []).length; i++) {
    const key = (existing[i] || [])[0];
    if (key) existingMap[key] = existing[i];
  }

  const rows = [SHEET_HEADERS['Cart Activity']];

  for (const cart of carts) {
    const customer = await env.DB.prepare(
      `SELECT name FROM customers WHERE phone = ?`
    ).bind(cart.phone).first();

    const newRow = mapCartToSheetRow(cart, customer?.name || '');
    const existingRow = existingMap[cart.phone] || [];
    const merged = mergeSheetRowPreservingManual(existingRow, newRow, manualIndexes);
    rows.push(merged);
  }

  const encodedRange = encodeURIComponent('Cart Activity!A:ZZ');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values: rows });

  return { totalCarts: carts.length };
}

async function backfillOrderEventsToGoogleSheets(env) {
  const { results: events } = await env.DB.prepare(`
    SELECT created_at, order_id, event_type, event_source, message, meta_json
    FROM order_events
    ORDER BY created_at ASC
  `).all().catch(() => ({ results: [] }));

  if (!events || events.length === 0) return { totalOrderEvents: 0 };

  const values = [[
    'created_at', 'order_id', 'event_type', 'event_source', 'message', 'meta_json'
  ]];

  for (const event of events) {
    values.push([
      safeText(event.created_at),
      safeText(event.order_id),
      safeText(event.event_type),
      safeText(event.event_source),
      safeText(event.message),
      safeText(event.meta_json),
    ]);
  }

  const encodedRange = encodeURIComponent('Order Events!A:F');
  await googleSheetsRequest(env, 'PUT', `/values/${encodedRange}?valueInputOption=RAW`, { values });

  return { totalOrderEvents: events.length };
}

async function backfillAllGoogleSheets(env) {
  let orders = { totalOrders: 0 };
  let customers = { totalCustomers: 0 };
  let leads = { totalLeads: 0 };
  let sales = { totalSales: 0 };
  let products = { totalProducts: 0 };
  let shipments = { totalShipments: 0 };
  let carts = { totalCarts: 0 };
  let events = { totalOrderEvents: 0 };
  let sourcePerf = false;

  try { orders = await backfillOrdersToGoogleSheets(env); } catch (e) {
    console.error('Backfill orders error:', e);
  }
  try { customers = await backfillCustomersToGoogleSheets(env); } catch (e) {
    console.error('Backfill customers error:', e);
  }
  try { leads = await backfillLeadsToGoogleSheets(env); } catch (e) {
    console.error('Backfill leads error:', e);
  }
  try { sales = await backfillSalesToGoogleSheets(env); } catch (e) {
    console.error('Backfill sales error:', e);
  }
  try { products = await backfillProductsToGoogleSheets(env); } catch (e) {
    console.error('Backfill products error:', e);
  }
  try { shipments = await backfillShipmentsToGoogleSheets(env); } catch (e) {
    console.error('Backfill shipments error:', e);
  }
  try { carts = await backfillCartsToGoogleSheets(env); } catch (e) {
    console.error('Backfill carts error:', e);
  }
  try { events = await backfillOrderEventsToGoogleSheets(env); } catch (e) {
    console.error('Backfill events error:', e);
  }
  try { await rebuildSourcePerformanceSheet(env); sourcePerf = true; } catch (e) {
    console.error('Backfill source perf error:', e);
  }

  return {
    orders,
    customers,
    leads,
    sales,
    products,
    shipments,
    carts,
    events,
    sourcePerformance: sourcePerf,
    syncedAt: new Date().toISOString(),
  };
}

async function sendFCMNotification(env, phone, name, text, messageId) {
  try {
    if (messageId) {
      const already = await env.KV.get(`fcm_notif:${messageId}`);
      console.log('FCM dedup check:', already ? 'DUPLICATE' : 'NEW');
      if (already) {
        console.log('FCM: duplicate skipped', messageId);
        return;
      }
      await env.KV.put(`fcm_notif:${messageId}`, '1', { expirationTtl: 300 });
    }

    const deviceToken = await env.KV.get('fcm_token:flutter');
    if (!deviceToken) return;
    console.log("FCM token from KV:", deviceToken.substring(0, 20));

    const accessToken = await getAccessToken(env);
    if (!accessToken) return;
    const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${env.FCM_PROJECT_ID}/messages:send`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: {
            title: name || phone,
            body: text || 'New message',
          },
          android: {
            priority: 'high',
            notification: {
              channel_id: 'kaapav_messages',
              default_vibrate_timings: true,
              default_sound: true,
              visibility: 'PUBLIC',
            },
          },
          data: {
            phone: phone,
            type: 'new_message',
            title: name || phone,
            body: text || 'New message',
          },
        },
      }),
    });
    const fcmData = await fcmRes.json();
    console.log('FCM result:', JSON.stringify(fcmData));
    if (fcmData?.error?.details?.[0]?.errorCode === 'UNREGISTERED') {
      await env.KV.delete('fcm_token:flutter');
      await env.KV.delete('fcm_access_token');
      console.log('FCM: Cleared stale token');
    }
  } catch (e) { console.error('FCM error:', e); }
}



// ═══════════════════ WHATSAPP ═══════════════════
async function sendWhatsAppText(env, phone, text) {
  const res = await fetch(`https://graph.facebook.com/v18.0/${env.WA_PHONE_ID}/messages`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${env.WA_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ messaging_product: 'whatsapp', to: phone, type: 'text', text: { body: text } }),
  });
  return res.json();
}

async function sendWhatsAppTextOnce(env, dedupeKey, phone, text, ttl = 86400 * 30) {
  const already = await env.KV.get(dedupeKey);
  if (already) return { success: true, skipped: true };

  const result = await sendWhatsAppText(env, phone, text);
  if (!result?.error) {
    await env.KV.put(dedupeKey, '1', { expirationTtl: ttl });
  }
  return result;
}

async function notifyOwnerFailure(env, title, lines = []) {
  try {
    await sendWhatsAppText(
      env,
      env.OWNER_PHONE,
      `⚠️ *${title}*\n\n` + lines.join('\n')
    );
  } catch (e) {
    console.error('notifyOwnerFailure error:', e);
  }
}
async function sendWhatsAppButtons(env, phone, text, buttons, footer = null) {
  const interactive = {
    type: 'button',
    body: { text },
    action: { buttons: buttons.map(b => ({ type: 'reply', reply: { id: b.id, title: b.title } })) }
  };
  if (footer) interactive.footer = { text: footer };

  const res = await fetch(`https://graph.facebook.com/v18.0/${env.WA_PHONE_ID}/messages`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${env.WA_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      messaging_product: 'whatsapp', to: phone, type: 'interactive', interactive
    }),
  });
  return res.json();
}

async function sendWhatsAppList(env, phone, text, buttonLabel, sections, footer = null) {
  const interactive = {
    type: 'list',
    body: { text },
    action: { button: buttonLabel, sections },
  };
  if (footer) interactive.footer = { text: footer };
  const res = await fetch(`https://graph.facebook.com/v18.0/${env.WA_PHONE_ID}/messages`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${env.WA_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ messaging_product: 'whatsapp', to: phone, type: 'interactive', interactive }),
  });
  return res.json();
}

async function sendWhatsAppImage(env, phone, mediaUrl, caption) {
  const res = await fetch(`https://graph.facebook.com/v18.0/${env.WA_PHONE_ID}/messages`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${env.WA_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to: phone,
      type: 'image',
      image: {
        link: mediaUrl,
        ...(caption ? { caption } : {}),
      },
    }),
  });
  return res.json();
}

async function sendWhatsAppDocument(env, phone, mediaUrl, filename, caption) {
  const res = await fetch(`https://graph.facebook.com/v18.0/${env.WA_PHONE_ID}/messages`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${env.WA_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to: phone,
      type: 'document',
      document: {
        link: mediaUrl,
        ...(filename ? { filename } : {}),
        ...(caption ? { caption } : {}),
      },
    }),
  });
  return res.json();
}

async function sendWhatsAppVideo(env, phone, mediaUrl, caption) {
  const res = await fetch(`https://graph.facebook.com/v18.0/${env.WA_PHONE_ID}/messages`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${env.WA_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to: phone,
      type: 'video',
      video: {
        link: mediaUrl,
        ...(caption ? { caption } : {}),
      },
    }),
  });
  return res.json();
}

// ── CONVERSATION STATE ─────────────────────────────────────────
async function getConvState(phone, env) {
  try {
    const row = await env.DB.prepare(
      `SELECT state, data FROM conversation_state WHERE phone = ?`
    ).bind(phone).first();
    if (!row) return null;
    return { state: row.state, data: JSON.parse(row.data || '{}') };
  } catch { return null; }
}

async function setConvState(phone, state, data, env) {
  await env.DB.prepare(`
    INSERT INTO conversation_state (phone, state, data, updated_at)
    VALUES (?, ?, ?, datetime('now'))
    ON CONFLICT(phone) DO UPDATE SET
      state = excluded.state,
      data  = excluded.data,
      updated_at = excluded.updated_at
  `).bind(phone, state, JSON.stringify(data)).run();
}

async function clearConvState(phone, env) {
  await env.DB.prepare(`DELETE FROM conversation_state WHERE phone = ?`).bind(phone).run();
}

// ── RAZORPAY — create payment link ────────────────────────────
async function createRazorpayLink(env, { amount, name, phone, orderId, description }) {
  const auth = btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
  const expiry = Math.floor(Date.now() / 1000) + 86400;

  const cleanPhone = String(phone || '').replace(/\D/g, '').slice(-10);
  const finalAmount = Math.round(Number(amount || 0) * 100);

  console.log('RAZORPAY DEBUG', JSON.stringify({
    orderId,
    amount,
    finalAmount,
    name,
    phone,
    cleanPhone,
    hasKeyId: !!env.RAZORPAY_KEY_ID,
    hasKeySecret: !!env.RAZORPAY_KEY_SECRET,
  }));

  const res = await fetch('https://api.razorpay.com/v1/payment_links', {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      amount: finalAmount,
      currency: 'INR',
      description,
      customer: {
        name,
        contact: `+91${cleanPhone}`
      },
      notify: { sms: true, whatsapp: false },
      reminder_enable: true,
      expire_by: expiry,
      reference_id: orderId,
      callback_url: `https://wa.kaapav.com/api/payment/callback`,
      callback_method: 'get',
    })
  });

  const data = await res.json();
  console.log('RAZORPAY RESPONSE', JSON.stringify(data));

  if (!res.ok) {
    throw new Error(data.error?.description || data.error?.message || 'Razorpay error');
  }

  return data.short_url;
}

// ── SHIPROCKET — auth + create order ──────────────────────────
async function shiprocketToken(env) {
  const res = await fetch('https://apiv2.shiprocket.in/v1/external/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: env.SHIPROCKET_EMAIL, password: env.SHIPROCKET_PASSWORD })
  });
  const data = await res.json();
  if (!data.token) throw new Error('Shiprocket auth failed');
  return data.token;
}

async function createShiprocketOrder(env, { order, customer, items }) {
  const token = await shiprocketToken(env);
  const orderDate = new Date().toISOString().slice(0, 10);

  const orderItems = items.map(i => ({
    name: i.name,
    sku: i.sku,
    units: i.qty,
    selling_price: i.price,
    discount: 0,
    tax: 0,
  }));

  const res = await fetch('https://apiv2.shiprocket.in/v1/external/orders/create/adhoc', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      order_id: order.orderNumber,
      order_date: orderDate,
      pickup_location: 'Primary', // set this in Shiprocket dashboard
      channel_id: '',
      comment: 'WhatsApp Order',
      billing_customer_name: customer.name.split(' ')[0],
      billing_last_name: customer.name.split(' ').slice(1).join(' ') || '.',
      billing_address: customer.address,
      billing_address_2: '',
      billing_city: customer.city || 'Delhi',
      billing_pincode: customer.pincode || '110001',
      billing_state: customer.state || 'Delhi',
      billing_country: 'India',
      billing_email: `orders@kaapav.com`,
      billing_phone: customer.phone.replace(/\D/g, '').slice(-10),
      shipping_is_billing: true,
      order_items: orderItems,
      payment_method: 'Prepaid',
      shipping_charges: 0,
      giftwrap_charges: 0,
      transaction_charges: 0,
      total_discount: 0,
      sub_total: order.total,
      length: 10, breadth: 10, height: 5, weight: 0.3,
    })
  });
  const data = await res.json();
  return data;
}

// ═══════════════════ WEBHOOK HANDLERS ═══════════════════
async function handleWebhookVerify(request, env) {
  const url = new URL(request.url);
  const mode = url.searchParams.get('hub.mode');
  const token = url.searchParams.get('hub.verify_token');
  const challenge = url.searchParams.get('hub.challenge');
  if (mode === 'subscribe' && token === env.WEBHOOK_VERIFY_TOKEN) {
    return new Response(challenge, { status: 200 });
  }
  return new Response('Forbidden', { status: 403 });
}

async function resolveMediaToR2(mediaId, env) {
  // Step 1: Get download URL from Meta
  const metaRes = await fetch(`https://graph.facebook.com/v18.0/${mediaId}`, {
    headers: { Authorization: `Bearer ${env.WA_TOKEN}` }
  });
  const metaData = await metaRes.json();
  if (!metaData.url) throw new Error('No URL from Meta');

  // Step 2: Download the actual media (needs auth header)
  const mediaRes = await fetch(metaData.url, {
    headers: { Authorization: `Bearer ${env.WA_TOKEN}` }
  });
  if (!mediaRes.ok) throw new Error('Media download failed');

  // Step 3: Upload to R2
  const blob = await mediaRes.arrayBuffer();
  const mime = metaData.mime_type || 'image/jpeg';
  const ext = mime.split('/')[1]?.split(';')[0] || 'jpg';
  const key = `media/wa_${mediaId}.${ext}`;
  await env.MEDIA.put(key, blob, { httpMetadata: { contentType: mime } });

  return `https://pub-e8a17aa027ff420f83623e808512141f.r2.dev/${key}`;
}

async function generateOrderId(env) {
  const now = new Date();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const yy = String(now.getFullYear()).slice(2);

  // FY starts April 1 — resets once a year
  const fyYear = now.getMonth() >= 3 // April = month 3 (0-indexed)
    ? now.getFullYear()
    : now.getFullYear() - 1;
  const fyKey = `order_seq:FY${fyYear}`;

  const current = await env.KV.get(fyKey);
  const next = current ? parseInt(current) + 1 : 1;
  // No TTL — persists until next FY key is created
  await env.KV.put(fyKey, String(next));

  const seq = String(next).padStart(4, '0');
  return `KFJW-${mm}${dd}${yy}${seq}`;
}

async function handleWebhookPost(request, env, ctx) {
  try {
    const body = await request.json();
    const entry = body?.entry?.[0];
    const changes = entry?.changes?.[0];
    const value = changes?.value;
    if (!value?.messages?.[0]) return jsonResponse({ status: 'ok' });

    const msg = value.messages[0];
    const phone = msg.from;
    const contact = value.contacts?.[0];
    const name = contact?.profile?.name || phone;

    let text = '';
    let messageType = msg.type;
    let buttonId = null;
    let buttonText = null;
    let mediaUrl = null;
    let mediaCaption = null;
    let mediaId = null;

    if (msg.type === 'text') {
      text = msg.text?.body || '';
    } else if (msg.type === 'image') {
      mediaId = msg.image?.id;
      mediaCaption = msg.image?.caption || '';
      text = mediaCaption || '[Photo]';
      if (mediaId) {
        try { mediaUrl = await resolveMediaToR2(mediaId, env); } catch(e) { console.error('Media resolve error:', e); }
      }
    } else if (msg.type === 'video') {
      mediaId = msg.video?.id;
      text = '[Video]';
      if (mediaId) {
        try { mediaUrl = await resolveMediaToR2(mediaId, env); } catch(e) {}
      }
    } else if (msg.type === 'audio' || msg.type === 'voice') {
      mediaId = msg.audio?.id || msg.voice?.id;
      text = '[Audio]';
      if (mediaId) {
        try { mediaUrl = await resolveMediaToR2(mediaId, env); } catch(e) {}
      }
    } else if (msg.type === 'document') {
      mediaId = msg.document?.id;
      mediaCaption = msg.document?.filename || '';
      text = mediaCaption || '[Document]';
      if (mediaId) {
        try { mediaUrl = await resolveMediaToR2(mediaId, env); } catch(e) {}
      }
    } else if (msg.type === 'interactive') {
      if (msg.interactive?.type === 'button_reply') {
        buttonId = msg.interactive.button_reply?.id;
        buttonText = msg.interactive.button_reply?.title;
        text = buttonText || '';
      } else if (msg.interactive?.type === 'list_reply') {
        buttonId = msg.interactive.list_reply?.id;
        buttonText = msg.interactive.list_reply?.title;
        text = buttonText || '';
      }
    }

    const messageId = msg.id;
    const timestamp = new Date(parseInt(msg.timestamp) * 1000).toISOString();

    // Save incoming message to D1
    await env.DB.prepare(`
      INSERT OR IGNORE INTO messages (
        message_id, phone, text, message_type, direction,
        button_id, button_text, media_url, media_caption,
        status, timestamp, created_at
      ) VALUES (?, ?, ?, ?, 'incoming', ?, ?, ?, ?, 'delivered', ?, datetime('now'))
    `).bind(
      messageId, phone, text, messageType,
      buttonId, buttonText, mediaUrl, mediaCaption, timestamp
    ).run();

    // Upsert chat
    await env.DB.prepare(`
      INSERT INTO chats (
        phone, customer_name, last_message, last_message_type,
        last_timestamp, last_direction, unread_count, total_messages, updated_at
      ) VALUES (?, ?, ?, ?, ?, 'incoming', 1, 1, datetime('now'))
      ON CONFLICT(phone) DO UPDATE SET
        customer_name   = excluded.customer_name,
        last_message    = excluded.last_message,
        last_message_type = excluded.last_message_type,
        last_timestamp  = excluded.last_timestamp,
        last_direction  = 'incoming',
        unread_count    = unread_count + 1,
        total_messages  = total_messages + 1,
        updated_at      = datetime('now')
    `).bind(phone, name, text || messageType, messageType, timestamp).run();

    // Upsert customer
    await env.DB.prepare(`
      INSERT INTO customers (phone, name, message_count, first_seen, last_seen, updated_at)
      VALUES (?, ?, 1, datetime('now'), datetime('now'), datetime('now'))
      ON CONFLICT(phone) DO UPDATE SET
        name          = excluded.name,
        message_count = message_count + 1,
        last_seen     = datetime('now'),
        updated_at    = datetime('now')
    `).bind(phone, name).run();

    // FCM push — fires in parallel, does not block autoresponder
    ctx.waitUntil(sendFCMNotification(env, phone, name, text, messageId));

    // AutoResponder
    try {
      const autoResponder = new AutoResponder(env);
      await autoResponder.process({ phone, name, text, messageType, buttonId, messageId });
    } catch(e) { console.error('Autoresponder error:', e); }

    return jsonResponse({ status: 'ok' });

  } catch(e) {
    console.error('Webhook error:', e);
    return jsonResponse({ status: 'ok' });
  }
}
async function handleLogin(request, env) {
  const body = await request.json();
  const { method, pin, email, password } = body;

  if (method === 'pin' || method === 'biometric') {
    const validPin = pin === env.APP_PIN;
    if (!validPin) return errorResponse('Invalid PIN', 401);
  } else if (method === 'password') {
    if (email !== 'admin@kaapav.com') return errorResponse('Invalid credentials', 401);
  } else {
    return errorResponse('Invalid method', 400);
  }

  const payload = { userId: 'admin', email: 'admin@kaapav.com', role: 'admin', exp: Math.floor(Date.now() / 1000) + 7 * 24 * 3600 };
  const token = await generateJWT(payload, env.JWT_SECRET);
  return jsonResponse({ success: true, token, user: { id: 'admin', email: 'admin@kaapav.com', name: 'KAAPAV Admin', role: 'admin' } });
}

async function handleGetChats(request, env) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const offset = parseInt(url.searchParams.get('offset') || '0');
  const { results } = await env.DB.prepare(
    `SELECT * FROM chats ORDER BY last_timestamp DESC LIMIT ? OFFSET ?`
  ).bind(limit, offset).all();
  return jsonResponse({ success: true, chats: results, total: results.length });
}

async function handleGetMessages(phone, request, env) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const before = url.searchParams.get('before');
  let query = `SELECT * FROM messages WHERE phone = ? ORDER BY timestamp DESC LIMIT ?`;
  const params = [phone, limit];
  if (before) { query = `SELECT * FROM messages WHERE phone = ? AND timestamp < ? ORDER BY timestamp DESC LIMIT ?`; params.splice(1, 0, before); }
  const { results } = await env.DB.prepare(query).bind(...params).all();
  await env.DB.prepare(`UPDATE chats SET unread_count = 0 WHERE phone = ?`).bind(phone).run();
  return jsonResponse({ success: true, messages: results.reverse(), total: results.length });
}

async function handleSendMessage(request, env) {
  const body = await request.json();
  const phone = body.phone || body.to;
  const text = body.text || body.message;
  const type = body.type || 'text';
  const mediaUrl = body.mediaUrl;
  const mediaCaption = body.mediaCaption;
  const filename = body.filename;

  if (!phone) return errorResponse('phone required');

  let waResult;
  let savedText = text || '';

  try {
    switch (type) {
      case 'image':
        if (!mediaUrl) return errorResponse('mediaUrl required for image');
        waResult = await sendWhatsAppImage(env, phone, mediaUrl, mediaCaption);
        savedText = mediaCaption || '📷 Photo';
        break;

      case 'document':
        if (!mediaUrl) return errorResponse('mediaUrl required for document');
        waResult = await sendWhatsAppDocument(env, phone, mediaUrl, filename, mediaCaption);
        savedText = filename || mediaCaption || '📄 Document';
        break;

      case 'video':
        if (!mediaUrl) return errorResponse('mediaUrl required for video');
        waResult = await sendWhatsAppVideo(env, phone, mediaUrl, mediaCaption);
        savedText = mediaCaption || '🎬 Video';
        break;

      case 'buttons':
        if (!text) return errorResponse('text required');
        waResult = await sendWhatsAppButtons(env, phone, text, body.buttons);
        break;

      default:
        if (!text) return errorResponse('text required');
        waResult = await sendWhatsAppText(env, phone, text);
        break;
    }

    if (waResult?.error) {
      console.error('WhatsApp API error:', JSON.stringify(waResult.error));
      return errorResponse(`WhatsApp error: ${waResult.error.message || 'Unknown'}`, 502);
    }

    const messageId = waResult?.messages?.[0]?.id || `local_${Date.now()}`;
    const timestamp = new Date().toISOString();

    await env.DB.prepare(`
      INSERT OR IGNORE INTO messages (message_id, phone, text, message_type, direction, media_url, media_caption, status, timestamp, created_at)
      VALUES (?, ?, ?, ?, 'outgoing', ?, ?, 'sent', ?, datetime('now'))
    `).bind(messageId, phone, savedText, type, mediaUrl || null, mediaCaption || null, timestamp).run();

    await env.DB.prepare(`
      UPDATE chats SET last_message = ?, last_message_type = ?, last_timestamp = ?, last_direction = 'outgoing', updated_at = datetime('now') WHERE phone = ?
    `).bind(savedText, type, timestamp, phone).run();

    return jsonResponse({ success: true, messageId, timestamp });

  } catch (e) {
    console.error('Send message error:', e);
    return errorResponse('Failed to send: ' + e.message, 500);
  }
}

async function handleGetOrders(request, env) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') || '100');
  const status = url.searchParams.get('status');
  let query = `SELECT * FROM orders ORDER BY created_at DESC LIMIT ?`;
  const params = [limit];
  if (status) { query = `SELECT * FROM orders WHERE status = ? ORDER BY created_at DESC LIMIT ?`; params.unshift(status); }
  const { results } = await env.DB.prepare(query).bind(...params).all();
  return jsonResponse({ success: true, orders: results, total: results.length });
}

async function handleGetProducts(request, env) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') || '500');
  const category = url.searchParams.get('category');
  // Admin app gets ALL products (no is_active filter)
  let query = `SELECT * FROM products ORDER BY name ASC LIMIT ?`;
  const params = [limit];
  if (category) { query = `SELECT * FROM products WHERE category = ? ORDER BY name ASC LIMIT ?`; params.unshift(category); }
  const { results } = await env.DB.prepare(query).bind(...params).all();
  return jsonResponse({ success: true, products: results, total: results.length });
}

async function handleSendProduct(request, env) {
  const body = await request.json();
  const { sku, phone } = body;
  if (!sku || !phone) return errorResponse('sku and phone required');
  const product = await env.DB.prepare(`SELECT * FROM products WHERE sku = ?`).bind(sku).first();
  if (!product) return errorResponse('product not found', 404);

  const discount = product.compare_price > product.price
    ? Math.round((product.compare_price - product.price) / product.compare_price * 100) : 0;
  const priceStr = discount > 0
    ? `₹${product.price}/₹${product.compare_price} (${discount}% Off)`
    : `₹${product.price}`;
  const caption =
    `💎 *${product.name}*\n` +
    `💰 ${priceStr}\n` +
    (product.website_link ? `🛍️ ${product.website_link}` : '');

  let waResult;
  if (product.image_url) {
    waResult = await sendWhatsAppImage(env, phone, product.image_url, caption);
  } else {
    waResult = await sendWhatsAppText(env, phone, caption);
  }

  if (waResult?.error) return errorResponse(waResult.error.message, 502);

  const msgId = waResult?.messages?.[0]?.id || `local_${Date.now()}`;
  const timestamp = new Date().toISOString();
  await env.DB.prepare(`
    INSERT OR IGNORE INTO messages (message_id, phone, text, message_type, direction, media_url, media_caption, status, timestamp, created_at)
    VALUES (?, ?, ?, ?, 'outgoing', ?, ?, 'sent', ?, datetime('now'))
  `).bind(msgId, phone, product.name, 'image', product.image_url, caption, timestamp).run();
  await env.DB.prepare(`
    UPDATE chats SET last_message = ?, last_message_type = 'image', last_timestamp = ?, last_direction = 'outgoing', updated_at = datetime('now') WHERE phone = ?
  `).bind(product.name, timestamp, phone).run();

  return jsonResponse({ success: true });
}

async function handleUpdateProduct(sku, request, env) {
  const body = await request.json();
  const fields = [];
  const values = [];

  const allowed = [
    'name',
    'category',
    'price',
    'compare_price',
    'description',
    'stock',
    'image_url',
    'images',
    'is_active',
    'is_featured',
    'tags',
    'website_link',
    'material'
  ];

  for (const key of allowed) {
    if (body[key] !== undefined) {
      fields.push(`${key} = ?`);

      if (key === 'tags' || key === 'images') {
        values.push(JSON.stringify(body[key] || []));
      } else {
        values.push(body[key]);
      }
    }
  }

  if (fields.length === 0) return errorResponse('nothing to update');

  fields.push(`updated_at = datetime('now')`);
  values.push(sku);

  await env.DB.prepare(
    `UPDATE products SET ${fields.join(', ')} WHERE sku = ?`
  ).bind(...values).run();
  try {
    await syncProductToGoogleSheetsSafe(env, sku);
   } catch (e) {
    console.error('Google Sheets sync error (product update):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'product',
      entity_id: sku,
      action: 'product_updated',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }

  return jsonResponse({ success: true });
}

async function handleCreateProduct(request, env) {
  const body = await request.json();

  const sku = safeText(body.sku).trim();
  if (!sku) return errorResponse('sku required');

  const name = safeText(body.name).trim();
  if (!name) return errorResponse('name required');

  await env.DB.prepare(`
    INSERT INTO products (
      sku, name, description, price, compare_price, cost_price,
      category, subcategory, tags, stock, track_inventory,
      image_url, images, video_url, has_variants, variants,
      wa_product_id, is_active, is_featured, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
  `).bind(
    sku,
    name,
    safeText(body.description),
    safeNumber(body.price),
    safeNumber(body.compare_price),
    safeNumber(body.cost_price),
    safeText(body.category),
    safeText(body.subcategory),
    JSON.stringify(body.tags || []),
    safeNumber(body.stock),
    body.track_inventory === undefined ? 1 : safeNumber(body.track_inventory),
    safeText(body.image_url),
    JSON.stringify(body.images || []),
    safeText(body.video_url),
    body.has_variants === undefined ? 0 : safeNumber(body.has_variants),
    JSON.stringify(body.variants || []),
    safeText(body.wa_product_id),
    body.is_active === undefined ? 1 : safeNumber(body.is_active),
    body.is_featured === undefined ? 0 : safeNumber(body.is_featured),
  ).run();

  // Optional extended columns if present in DB
  try {
    await env.DB.prepare(`
      UPDATE products SET
        website_link = ?,
        material = ?,
        updated_at = datetime('now')
      WHERE sku = ?
    `).bind(
      safeText(body.website_link),
      safeText(body.material),
      sku
    ).run();
  } catch (_) {}

  try {
    await syncProductToGoogleSheetsSafe(env, sku);
  } catch (e) {
    console.error('Google Sheets sync error (product create):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'product',
      entity_id: sku,
      action: 'product_created',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }

  return jsonResponse({ success: true, sku });
}

async function handleDeleteProduct(sku, env) {
  await env.DB.prepare(`DELETE FROM products WHERE sku = ?`).bind(sku).run();
  return jsonResponse({ success: true });
}

async function handleUpdateStock(sku, request, env) {
  const body = await request.json();
  const stock = parseInt(body.stock);
  if (isNaN(stock)) return errorResponse('stock required');
  await env.DB.prepare(`UPDATE products SET stock = ?, updated_at = datetime('now') WHERE sku = ?`).bind(stock, sku).run();
  try {
    await syncProductToGoogleSheetsSafe(env, sku);
   } catch (e) {
    console.error('Google Sheets sync error (stock update):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'product',
      entity_id: sku,
      action: 'stock_updated',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }

  return jsonResponse({ success: true });
}

async function handleGetCustomers(request, env) {
  const url = new URL(request.url);
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const { results } = await env.DB.prepare(`SELECT * FROM customers ORDER BY last_seen DESC LIMIT ?`).bind(limit).all();
  return jsonResponse({ success: true, customers: results, total: results.length });
}

async function handleGetStats(env) {
  const [chats, orders, customers, products, revenue] = await Promise.all([
    env.DB.prepare(`SELECT COUNT(*) as count, SUM(unread_count) as unread FROM chats`).first(),
    env.DB.prepare(`SELECT COUNT(*) as count, COUNT(CASE WHEN status='pending' THEN 1 END) as pending FROM orders`).first(),
    env.DB.prepare(`SELECT COUNT(*) as count FROM customers`).first(),
    env.DB.prepare(`SELECT COUNT(*) as count FROM products WHERE is_active=1`).first(),
    env.DB.prepare(`SELECT SUM(total) as total FROM orders WHERE payment_status='paid'`).first(),
  ]);
  return jsonResponse({
    success: true,
    stats: {
      totalChats: chats?.count || 0,
      unreadMessages: chats?.unread || 0,
      totalOrders: orders?.count || 0,
      pendingOrders: orders?.pending || 0,
      totalCustomers: customers?.count || 0,
      totalProducts: products?.count || 0,
      totalRevenue: revenue?.total || 0,
    }
  });
}

async function handleGetSettings(env) {
  const { results } = await env.DB.prepare(`SELECT key, value FROM settings`).all();
  const settings = {};
  results.forEach(r => { settings[r.key] = r.value; });
  return jsonResponse({ success: true, settings });
}

async function handleGetAnalytics(env) {
  const { results } = await env.DB.prepare(`SELECT * FROM analytics ORDER BY created_at DESC LIMIT 100`).all();
  return jsonResponse({ success: true, analytics: results });
}

async function handleGetActivities(env) {
  const messages = await env.DB.prepare(`SELECT phone, text, direction, timestamp FROM messages ORDER BY created_at DESC LIMIT 20`).all();
  return jsonResponse({ success: true, activities: messages.results });
}

async function handleSyncCheck(env) {
  const [chats, messages] = await Promise.all([
    env.DB.prepare(`SELECT COUNT(*) as count FROM chats`).first(),
    env.DB.prepare(`SELECT COUNT(*) as count FROM messages`).first(),
  ]);
  return jsonResponse({ success: true, sync: { chats: chats?.count || 0, messages: messages?.count || 0, timestamp: new Date().toISOString() } });
}

async function handleRegisterFCM(request, env) {
  const body = await request.json();
  const { token } = body;
  if (!token) return errorResponse('token required');
  await env.KV.put('fcm_token:flutter', token);
  return jsonResponse({ success: true });
}

async function getSettingValue(env, key, fallback = null) {
  try {
    const row = await env.DB.prepare(
      `SELECT value FROM settings WHERE key = ?`
    ).bind(key).first();
    return row?.value ?? fallback;
  } catch (_) {
    return fallback;
  }
}

function toBool(value, fallback = false) {
  if (typeof value === 'boolean') return value;
  const raw = String(value ?? '').toLowerCase().trim();
  if (raw === 'true' || raw === '1' || raw === 'yes') return true;
  if (raw === 'false' || raw === '0' || raw === 'no') return false;
  return fallback;
}

async function handleGetDashboardOps(env) {
  try {
    const today = new Date().toISOString().slice(0, 10);

    const [
      paidSummary,
      unpaidSummary,
      todayPaidSummary,
      todayUnpaidSummary,
      readyForShiprocketRow,
      shiprocketBookedRow,
      awbAddedRow,
      lowStockRow,
      outOfStockRow,
      totalProductsRow,
      sourceRows,
      todayOrdersRow,
      todayPaidOrdersRow,
      todayUnpaidOrdersRow,
      todayReadyToShipRow,
      todayShippedRow,
      syncMode,
      sheetsEnabledRaw,
      supabaseEnabledRaw,
      pendingQueueRow,
      failedQueueRow,
      lastSyncSuccessRow,
      lastSyncFailureRow,
    ] = await Promise.all([
      env.DB.prepare(`
        SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as value
        FROM orders
        WHERE payment_status = 'paid'
      `).first(),

      env.DB.prepare(`
        SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as value
        FROM orders
        WHERE payment_status = 'unpaid'
      `).first(),

      env.DB.prepare(`
        SELECT COALESCE(SUM(total), 0) as value
        FROM orders
        WHERE payment_status = 'paid'
          AND substr(created_at, 1, 10) = ?
      `).bind(today).first(),

      env.DB.prepare(`
        SELECT COALESCE(SUM(total), 0) as value
        FROM orders
        WHERE payment_status = 'unpaid'
          AND substr(created_at, 1, 10) = ?
      `).bind(today).first(),

      env.DB.prepare(`
  SELECT COUNT(*) as count
  FROM orders
  WHERE (
    (shipment_id IS NOT NULL AND shipment_id != '')
    OR (shiprocket_order_id IS NOT NULL AND shiprocket_order_id != '')
  )
  AND (
    (awb_number IS NULL OR awb_number = '')
    AND (awb_code IS NULL OR awb_code = '')
  )
  AND status NOT IN ('delivered', 'cancelled')
`).first(),    

       env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM orders
        WHERE (
          (shipment_id IS NOT NULL AND shipment_id != '')
          OR (shiprocket_order_id IS NOT NULL AND shiprocket_order_id != '')
        )
        AND (
          (awb_number IS NULL OR awb_number = '')
          AND (awb_code IS NULL OR awb_code = '')
        )
        AND status NOT IN ('delivered', 'cancelled')
      `).first(),

       env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM orders
        WHERE (
          (awb_number IS NOT NULL AND awb_number != '')
          OR (awb_code IS NOT NULL AND awb_code != '')
        )
        AND status NOT IN ('delivered', 'cancelled')
      `).first(),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM products
        WHERE is_active = 1
          AND stock > 0
          AND stock <= 5
      `).first(),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM products
        WHERE is_active = 1
          AND stock <= 0
      `).first(),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM products
        WHERE is_active = 1
      `).first(),

      env.DB.prepare(`
        SELECT LOWER(COALESCE(source, 'unknown')) as source, COUNT(*) as count
        FROM orders
        GROUP BY LOWER(COALESCE(source, 'unknown'))
      `).all(),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM orders
        WHERE substr(created_at, 1, 10) = ?
      `).bind(today).first(),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM orders
        WHERE payment_status = 'paid'
          AND substr(created_at, 1, 10) = ?
      `).bind(today).first(),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM orders
        WHERE payment_status = 'unpaid'
          AND substr(created_at, 1, 10) = ?
      `).bind(today).first(),

      env.DB.prepare(`
  SELECT COUNT(*) as count
  FROM orders
  WHERE payment_status = 'paid'
    AND status IN ('confirmed', 'processing')
    AND (
      (shipment_id IS NULL OR shipment_id = '')
      AND (shiprocket_order_id IS NULL OR shiprocket_order_id = '')
    )
    AND substr(created_at, 1, 10) = ?
`).bind(today).first(),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM orders
        WHERE status = 'shipped'
          AND substr(shipped_at, 1, 10) = ?
      `).bind(today).first(),

      getSettingValue(env, 'sync_mode', 'd1_only'),
      getSettingValue(env, 'sync_google_sheets_enabled', 'false'),
      getSettingValue(env, 'sync_supabase_enabled', 'false'),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM sync_queue
        WHERE status = 'pending'
      `).first().catch(() => ({ count: 0 })),

      env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM sync_queue
        WHERE status = 'failed'
      `).first().catch(() => ({ count: 0 })),

      env.DB.prepare(`
        SELECT created_at
        FROM sync_log
        WHERE status = 'success'
        ORDER BY created_at DESC
        LIMIT 1
      `).first().catch(() => null),

      env.DB.prepare(`
        SELECT created_at
        FROM sync_log
        WHERE status = 'failed'
        ORDER BY created_at DESC
        LIMIT 1
      `).first().catch(() => null),
    ]);

    const sourceMap = {
      whatsapp: 0,
      catalogue: 0,
      website: 0,
      manual: 0,
    };

    for (const row of (sourceRows?.results || [])) {
      const key = String(row.source || '').toLowerCase();
      if (sourceMap[key] != null) {
        sourceMap[key] = Number(row.count || 0);
      }
    }

    return jsonResponse({
      success: true,
      ops: {
        lastSyncAt: new Date().toISOString(),

        paymentBreakdown: {
          paidCount: Number(paidSummary?.count || 0),
          unpaidCount: Number(unpaidSummary?.count || 0),
          paidValue: Number(paidSummary?.value || 0),
          unpaidValue: Number(unpaidSummary?.value || 0),
          todayPaid: Number(todayPaidSummary?.value || 0),
          todayUnpaid: Number(todayUnpaidSummary?.value || 0),
        },

        shipmentQueue: {
          readyForShiprocket: Number(readyForShiprocketRow?.count || 0),
          shiprocketBooked: Number(shiprocketBookedRow?.count || 0),
          awbAdded: Number(awbAddedRow?.count || 0),
        },

        inventory: {
          lowStockCount: Number(lowStockRow?.count || 0),
          outOfStockCount: Number(outOfStockRow?.count || 0),
          totalProducts: Number(totalProductsRow?.count || 0),
        },

        sourceBreakdown: {
          whatsapp: sourceMap.whatsapp,
          catalogue: sourceMap.catalogue,
          website: sourceMap.website,
          manual: sourceMap.manual,
        },

        syncHealth: {
          d1Live: true,
          googleSheetsConnected: toBool(sheetsEnabledRaw, false),
          supabaseConnected: toBool(supabaseEnabledRaw, false),
          pendingQueue: Number(pendingQueueRow?.count || 0),
          failedQueue: Number(failedQueueRow?.count || 0),
          mode: syncMode || 'd1_only',
          lastSuccess: lastSyncSuccessRow?.created_at || null,
          lastFailure: lastSyncFailureRow?.created_at || null,
        },

        todayOps: {
          totalOrders: Number(todayOrdersRow?.count || 0),
          paidOrders: Number(todayPaidOrdersRow?.count || 0),
          unpaidOrders: Number(todayUnpaidOrdersRow?.count || 0),
          readyToShip: Number(todayReadyToShipRow?.count || 0),
          shippedToday: Number(todayShippedRow?.count || 0),
        },
      }
    });
  } catch (e) {
    console.error('handleGetDashboardOps error:', e);
    return errorResponse('Failed to load dashboard ops', 500);
  }
}

// ═══════════════════════════════════════════════════════════════
// AUTORESPONDER — KAAPAV MENU SYSTEM
//
// FLOW MAP:
//   MAIN MENU        → [💎 Shop] [🎁 Offers & Track] [❓ Help & FAQs]
//   SHOP MENU        → [🌐 Website] [📱 Catalogue] [🏠 Back]
//   OFFERS MENU      → [🔥 Deals & Offers] [📦 Pay & Track] [🏠 Back]
//   DEALS MENU       → [🛍️ Bestsellers] [🌐 Shop Now] [🏠 Back]
//   PAY & TRACK MENU → [💳 Pay Now] [📦 Track Order] [🏠 Back]
//   HELP PROMPT      → freetext FAQ + [📋 Browse Topics] [🏠 Back]
//   BROWSE TOPICS    → List of 10 FAQ categories (WhatsApp list)
//   FAQ ANSWER       → answer text + [❓ More] [🛒 Order] [🏠 Home]
//
//   SOCIAL → inside Browse Topics → "Brand & Contact" category
//   ORDER  → text trigger only ("order karna hai" etc.)
// ═══════════════════════════════════════════════════════════════
class AutoResponder {
  constructor(env) {
    this.env = env;

    // ── FAQ category → group_name mapping (matches schema.sql) ──
    // These are the 10 Browse Topics shown in the WhatsApp list
    this.FAQ_CATEGORIES = [
      { id: 'faq_cat_durability', title: '⏳ Durability',        desc: 'How long it lasts',           group: 'durability' },
      { id: 'faq_cat_size',       title: '📐 Size & Fit',        desc: 'Rings, bracelets, earrings',  group: 'size'       },
      { id: 'faq_cat_pricing',    title: '💰 Pricing & Offers',  desc: 'Prices, discounts, shipping', group: 'pricing'    },
      { id: 'faq_cat_ordering',   title: '🛒 Ordering & Payment',desc: 'How to order, COD, pay',      group: 'ordering'   },
      { id: 'faq_cat_delivery',   title: '🚚 Delivery',          desc: 'Time, area, tracking',        group: 'delivery'   },
      { id: 'faq_cat_returns',    title: '🔄 Returns & Refunds', desc: 'Return, exchange, cancel',    group: 'returns'    },
      { id: 'faq_cat_care',       title: '✨ Jewellery Care',    desc: 'Care tips, cleaning',         group: 'care'       },
      { id: 'faq_cat_brand',      title: '👑 Brand & Contact',   desc: 'About us, social, contact',   group: 'brand'      },
    ];

  // ── Short titles for WhatsApp list (max 24 chars hard limit) ──
    this.FAQ_SHORT_TITLES = {
      'faq_last':            'How long will it last?',
      'faq_tarnish':         'Black or green?',
      'faq_daily':           'Can I wear daily?',
      'faq_plating':         'Plating fade time?',
      'faq_strong':          'Is it strong?',
      'faq_ring_size':       'Will ring fit?',
      'faq_bracelet_size':   'Bracelet size?',
      'faq_necklace_length': 'Necklace length?',
      'faq_earring_weight':  'Are earrings heavy?',
      'faq_piercing':        'Need pierced ears?',
      'faq_price':           'What are prices?',
      'faq_discount':        'Any discount?',
      'faq_shipping_cost':   'Is delivery free?',
      'faq_combo':           'Any combo deals?',
      'faq_minimum':         'Minimum order?',
      'faq_how_order':       'How to order?',
      'faq_cod':             'COD available?',
      'faq_payment_safe':    'Is payment safe?',
      'faq_confirmation':    'Order confirmation?',
      'faq_gift_order':      'Order as a gift?',
      'faq_delivery_time':   'Delivery time?',
      'faq_delivery_area':   'Deliver to my area?',
      'faq_packaging':       'Packaging safe?',
      'faq_track':           'Track my order?',
      'faq_delayed':         'Delivery delayed?',
      'faq_return':          'Can I return?',
      'faq_damaged':         'What if damaged?',
      'faq_refund_time':     'Refund timeline?',
      'faq_exchange':        'Can I exchange?',
      'faq_cancel':          'Can I cancel?',
      'faq_care':            'How to care?',
      'faq_perfume':         'Spray perfume OK?',
      'faq_sleep':           'Sleep wearing it?',
      'faq_gift_pack':       'Gift packaging?',
      'faq_multiple':        'Order many pieces?',
      'faq_about':           'About KAAPAV',
      'faq_social':          'Social media links?',
      'faq_contact':         'How to contact?',
    };

  this.FAQ_DATA = {
  durability: [
    { shortcut: 'faq_last',     title: 'How long will it last?',  message: '⏳ *Durability*\n\nWith proper care, KAAPAV jewellery lasts *years* and beyond with proper Care.\n\n✅ Our anti-tarnish coating protects against daily wear\n✅ Keep away from water, sweat, perfume\n✅ Store in the pouch provided\n\n💎 Thousands of happy customers wear it daily!' },
    { shortcut: 'faq_tarnish',  title: 'Will it turn black/green?', message: '🟢 *Tarnishing*\n\nWith basic care — *no*.\n\n✅ Anti-tarnish coating applied\n✅ Avoid water, sweat, perfume directly\n✅ Wipe dry after wear\n\nIf it does tarnish → gently wipe with dry soft cloth.' },
    { shortcut: 'faq_daily',    title: 'Can I wear it daily?',    message: '✨ *Daily Wear*\n\nYes! Designed for everyday wear.\n\n✅ Remove before shower/swim\n✅ Apply perfume BEFORE wearing\n✅ Wipe dry after sweating\n\n💎 Proper care = long lasting beauty!' },
    { shortcut: 'faq_plating',  title: 'How long does plating last?', message: '💛 *Plating Durability*\n\n6 months to 2+ years depending on care.\n\n⚡ Avoid chemicals, water, sweat\n⚡ Store in pouch when not wearing\n⚡ Don\'t rub against hard surfaces\n\n✅ Our plating is thick & premium quality.' },
    { shortcut: 'faq_strong',   title: 'Is it strong/sturdy?',   message: '💪 *Strength*\n\nYes! Made from high-quality brass/copper alloy base.\n\n✅ Won\'t bend easily\n✅ Clasps are secure & reliable\n✅ Won\'t break under normal wear\n\n⚠️ Avoid dropping on hard surfaces or heavy impact.' },
  ],
  size: [
    { shortcut: 'faq_ring_size',       title: 'Will the ring fit?',       message: '💍 *Ring Size*\n\nMost of our rings are *free size / adjustable*.\n\nFits finger sizes: *(Indian size 14–18 depends on Ring Width)*\n\n✅ Gently adjust to your finger\n✅ Don\'t over-bend\n' },
    { shortcut: 'faq_bracelet_size',   title: 'Bracelet size?',           message: '📿 *Bracelet Size*\n\nMost bracelets are *adjustable* with extender chain.\n\nFits wrist: *16cm–20cm*\n\n✅ Extender adds 2–3cm extra\n✅ Works for most wrists\n\nMeasure your wrist & message us if unsure!' },
    { shortcut: 'faq_necklace_length', title: 'Necklace length?',         message: '📏 *Necklace Length*\n\nStandard lengths in our collection:\n\n• *16 inch* — choker style\n• *18 inch* — collarbone (most popular)\n• *20 inch* — just below collarbone\n\nWith extender chain (+2 inch) included on most pieces!' },
    { shortcut: 'faq_earring_weight',  title: 'Are earrings heavy?',      message: '⚖️ *Earring Weight*\n\nOur earrings are *lightweight* — designed for all-day comfort!\n\n✅ 2–6 grams typically\n✅ No ear pain even after hours\n✅ Secure backs (push-back)\n\n💎 Comfort is our priority!' },
    { shortcut: 'faq_piercing',        title: 'Do I need pierced ears?',  message: '👂 *Pierced Ears*\n\nAll earrings require *pierced ears*.\n\nWe offer:\n✅ Push-back studs\n' },
  ],
  pricing: [
    { shortcut: 'faq_price',         title: 'What are the prices?',    message: '💰 *Our Prices*\n\n💍 *Earrings & Rings* — ₹249/-\n📿 *Necklace & Bracelet* — ₹499/-\n✨ *Pendant Sets* — ₹699/-\n\n🔥 Already *50% OFF* — MRP crossed out!\n🚚 FREE shipping above ₹498/-\n\n👉 ' + this.env.WEBSITE_URL },
    { shortcut: 'faq_discount',      title: 'Any discount available?', message: '🎉 *Discounts*\n\n✅ Already *50% OFF* on all products!\n✅ No extra coupon needed\n\n🚚 FREE delivery on orders above ₹498/-\n\n⚡ Prices are *fixed* — already lowest possible.\nWe don\'t negotiate as every piece is handcrafted.' },
    { shortcut: 'faq_shipping_cost', title: 'Is delivery free?',        message: '🚚 *Shipping Cost*\n\n✅ *FREE* on orders above ₹498/-\n💸 ₹60/- shipping on orders below ₹498/-\n\n💡 Pro tip: Order 2 items to get free shipping!\n\nDelivery in *2–4 working days* via Shiprocket.' },
    { shortcut: 'faq_combo',         title: 'Any combo deals?',         message: '🎁 *Combo Deals*\n\nYes! Check our website for current combo sets:\n\n✨ Pendant + Earring sets\n✨ Necklace + Bracelet sets\n✨ Full bridal sets\n\n👉 ' + this.env.WEBSITE_URL + '\n\n💬 Message us for custom combinations!' },
    { shortcut: 'faq_minimum',       title: 'Any minimum order?',       message: '🛒 *Minimum Order*\n\nNo minimum order! Order even *1 piece*.\n\n✅ Single pieces available\n✅ Sets available\n✅ Multiple pieces — no limit!\n\n💡 Order 2+ items → FREE shipping automatically!' },
  ],
  ordering: [
    { shortcut: 'faq_how_order',    title: 'How to place an order?',  message: '🛒 *How to Order*\n\n3 easy ways:\n\n1️⃣ *Website* → browse → add to cart → checkout\n   👉 ' + this.env.WEBSITE_URL + '\n\n2️⃣ *WhatsApp Catalogue* → tap → order\n   👉 ' + this.env.CATALOG_URL + '\n\n3️⃣ *Payment link* 👉 ' + this.env.PAYMENT_URL + '\n\n✅ Payment via UPI / Card / Net Banking' },
    { shortcut: 'faq_cod',          title: 'Is COD available?',       message: '💸 *Cash on Delivery*\n\n❌ *COD is NOT available.*\n\nWe only accept *online payment*:\n✅ UPI (GPay, PhonePe, Paytm)\n✅ Debit/Credit Card\n✅ Net Banking\n✅ Razorpay Payment Link\n\n🔒 100% secure & instant confirmation.' },
    { shortcut: 'faq_payment_safe', title: 'Is payment safe?',        message: '🔒 *Payment Safety*\n\n100% SAFE & SECURE!\n\n✅ Powered by *Razorpay* (India\'s #1 payment gateway)\n✅ SSL encrypted\n✅ No card details stored\n✅ RBI compliant\n✅ Instant order confirmation\n\n💎 100,000+ safe transactions processed daily by Razorpay.' },
    { shortcut: 'faq_confirmation', title: 'Will I get confirmation?', message: '✅ *Order Confirmation*\n\nYes! You\'ll receive:\n\n📱 *WhatsApp message* — instant confirmation\n📧 *Email* — order details (if provided)\n\nYou\'ll get:\n• Order ID (KP-XXXXX)\n• Items ordered\n• Delivery address\n• Tracking details when shipped\n\n💎 We confirm every order personally!' },
    ],
  delivery: [
    { shortcut: 'faq_delivery_time', title: 'How long to deliver?',     message: '🚚 *Delivery Time*\n\n📦 *2–4 working days* across India\n\n• Metro cities: 2–3 days\n• Other cities: 3–4 days\n• Remote areas: 4–7 days\n\n✅ Powered by *Shiprocket*\n✅ Tracking link sent on WhatsApp\n✅ Working days (Mon–Sat)' },
    { shortcut: 'faq_delivery_area', title: 'Deliver to my area?', message: '📍 *Delivery Coverage*\n\n✅ We deliver *PAN India* — all 28 states!\n\nIncluding:\n• All metro cities\n• Tier 2 & 3 cities\n• Towns & villages\n' },
    { shortcut: 'faq_packaging',     title: 'Is packaging safe?',       message: '📦 *Packaging*\n\n✅ Each piece individually wrapped\n✅ Bubble wrap protection\n✅ Rigid box for safety\n✅ KAAPAV branded packaging\n✅ 100% damage-proof for transit\n\n🎁 Gift-ready packaging on every order!' },
    { shortcut: 'faq_track',         title: 'How to track my order?',   message: '📦 *Track Your Order*\n\nOr track directly:\n👉 ' + this.env.TRACKING_URL + '\n\n✅ AWB/tracking number sent on WhatsApp when shipped\n✅ Real-time Shiprocket tracking\n✅ SMS + email updates too!' },
    { shortcut: 'faq_delayed',       title: 'My order is delayed',      message: '⏰ *Order Delayed?*\n\nSorry for the inconvenience! 🙏\n\nCommon reasons:\n• High demand period\n• Remote location\n• Courier delay\n' },
  ],
  returns: [
    { shortcut: 'faq_return',      title: 'Can I return the order?',  message: '🔄 *Returns Policy*\n\n✅ *7-day return policy*\n\nConditions:\n✅ Unboxing video mandatory\n✅ Item unused & in original packaging\n✅ Return request within 7 days of delivery\n\n⚠️ ₹60/- reverse shipping deducted\n\nMessage us with Order ID + video to start return.' },
    { shortcut: 'faq_damaged',     title: 'Item arrived damaged',     message: '😟 *Damaged Item*\n\nSo sorry! This shouldn\'t happen. 🙏\n\nDo this IMMEDIATELY:\n1. Record unboxing video (if not done)\n2. Share Order ID + photos/video here\n3. We\'ll replace or refund ASAP!\n\n✅ Damage cases resolved within 24 hours\n✅ Full replacement or refund — your choice!' },
    { shortcut: 'faq_refund_time', title: 'How long for refund?',    message: '💰 *Refund Timeline*\n\nAfter we receive & verify the return:\n\n⏰ *5–7 working days* to original payment method\n\n• UPI → 2–3 days\n• Card/Net Banking → 5–7 days\n• Bank transfer → 3–5 days\n\n✅ We notify you on WhatsApp at every step!' },
    { shortcut: 'faq_exchange',    title: 'Can I exchange?',          message: '🔄 *Exchange Policy*\n\n✅ Exchange available within *7 days*\n\nConditions:\n✅ Unboxing video required\n✅ Item unused & undamaged\n✅ Exchange for same or higher value item\n\n⚠️ ₹60/- shipping deducted for both ways\n\nMessage us with Order ID to start exchange!' },
    { shortcut: 'faq_cancel',      title: 'Can I cancel my order?',  message: '❌ *Order Cancellation*\n\n⚠️ *Orders cannot be cancelled* once placed.\n\nReason: We process & ship within hours!\n\nIf delivered and issue:\n✅ Return within 7 days (with unboxing video)\n✅ Full refund minus ₹60 shipping\n\nPlease order carefully. Sizes & details in product description!' },
  ],
  care: [
    { shortcut: 'faq_care',    title: 'How to care for jewellery?', message: '✨ *Jewellery Care Tips*\n\n💎 To make it last years:\n\n✅ Remove before shower/swimming\n✅ Apply perfume BEFORE wearing\n✅ Wipe dry with soft cloth after use\n✅ Store in pouch when not wearing\n✅ Avoid direct sunlight storage\n\n❌ Don\'t use harsh cleaners\n❌ Don\'t soak in water\n\n💛 5 minutes of care = years of beauty!' },
    { shortcut: 'faq_perfume', title: 'Can I spray perfume on it?', message: '🌸 *Perfume & Jewellery*\n\n⚠️ Avoid spraying perfume DIRECTLY on jewellery.\n\n✅ Apply perfume first → let it dry → then wear\n✅ This prevents chemical reaction with plating\n✅ Your jewellery stays shiny longer!\n\n💡 Rule: Jewellery is the LAST thing you put on!' },
    { shortcut: 'faq_sleep',   title: 'Can I sleep wearing it?',   message: '😴 *Sleeping with Jewellery*\n\nWe recommend *removing jewellery before sleep*.\n\nWhy:\n⚠️ Sweat & body heat accelerate tarnishing\n⚠️ Risk of bending delicate pieces\n⚠️ Chain can tangle or break\n\n✅ Store in pouch overnight\n✅ Takes 10 seconds — adds months to lifespan!' },
  ],
 brand: [
    { shortcut: 'faq_about',   title: 'About KAAPAV',            message: '👑 *About KAAPAV*\n\n💎 *Where luxury meets attitude. ✨*\n\nKAAPAV is an Indian D2C fashion jewellery brand offering premium anti-tarnish jewellery at honest prices.\n\n✨ 250+ unique designs\n🇮🇳 Made with love in India\n💰 Starting ₹249/- only\n🚚 Free shipping above ₹498/-\n📦 Fast 2–4 day delivery\n\n💖 Luxury for every woman, every day.' },
    { shortcut: 'faq_social',  title: 'Social media links',      message: '📱 *Follow KAAPAV*\n\n📸 *Instagram:*\n👉 ' + this.env.INSTAGRAM_URL + '\n\n👍 *Facebook:*\n👉 ' + this.env.FACEBOOK_URL + '\n\n🌐 *Website:*\n👉 ' + this.env.WEBSITE_URL + '\n\n💬 *WhatsApp Chat:*\n👉 ' + this.env.WAME_CHAT_URL + '\n\n🤍 Follow us for new arrivals & offers!' },
    { shortcut: 'faq_contact', title: 'How to contact us',       message: '📞 *Contact KAAPAV*\n\n💬 *WhatsApp* (fastest):\nJust message us here!\n\n📧 *Email:*\ncare.kaapav@gmail.com\n\n🌐 *Website:*\n👉 ' + this.env.WEBSITE_URL + '\n\n⏰ Response time: Within a few hours\n✅ We reply 7 days a week!' },
  ],
};

  }
  

  // ── ENTRY POINT ────────────────────────────────────────────────
  async process({ phone, name, text, messageType, buttonId, messageId }) {
    // Global dedup — never process same message twice
    const dedupeKey = `dedup:${messageId}`;
    const already = await this.env.KV.get(dedupeKey);
    if (already) return;
    await this.env.KV.put(dedupeKey, '1', { expirationTtl: 86400 });

    // ── 0. Order state machine — check first ─────────────────────
    const convState = await getConvState(phone, this.env);
    if (convState && convState.state.startsWith('order_')) {
      await this.handleOrderState(phone, convState.state, convState.data, (text || '').trim());
      return;
    }

    const input = (buttonId || text || '').trim();
    const inputLower = input.toLowerCase();

    // ── 1. Hard button IDs (exact match, no ambiguity) ───────────
    const action = this.resolveButtonId(input);
    if (action) {
      await this.executeAction(phone, action, input);
      return;
    }

    // ── 2. FAQ category list selection ───────────────────────────
    //    buttonId looks like "faq_cat_appearance" etc.
    const faqCat = this.FAQ_CATEGORIES.find(c => c.id === input);
    if (faqCat) {
      await this.sendFaqCategoryMenu(phone, faqCat);
      return;
    }

    // ── 3. Individual FAQ item selected from category sub-list ───
    //    buttonId looks like "faq_item_0", "faq_item_1" etc.
    //    We store pending category in KV so we know which group
    if (/^faq_item_\d+$/.test(input)) {
      await this.handleFaqItemSelection(phone, input);
      return;
    }

    // ── 4. Post-FAQ action buttons ───────────────────────────────
    if (input === 'faq_more')  { await this.sendBrowseTopics(phone); return; }
    if (input === 'faq_order') { await this.executeAction(phone, 'ORDER_FLOW'); return; }
    if (input === 'faq_home')  { await this.executeAction(phone, 'MAIN_MENU'); return; }

    // ── 5. Text triggers ─────────────────────────────────────────
    const textAction = this.resolveTextTrigger(inputLower);
    if (textAction) {
      await this.executeAction(phone, textAction, input);
      return;
    }

    // ── 6. Free-text FAQ keyword search (inside Help flow) ───────
    //    Only fire if user is in help context OR no other match
    const faqMatch = await this.searchFaqByKeyword(inputLower);
    if (faqMatch) {
      await this.sendFaqAnswer(phone, faqMatch);
      return;
    }

    // ── 7. Greeting → always show Main Menu ──────────────────────
    const greetRegex = new RegExp(
  '^(hi|hello|hey|helo|hii|hiii|namaste|namaskar|jai|ram|shri|' +
  'good (morning|evening|afternoon|night)|' +
  'vanakkam|vannakkam|sugam|hai|enna|start|begin|menu|' +
  '\u0bb5\u0ba3\u0b95\u0bcd\u0b95\u0bae\u0bcd|' +  // Tamil: வணக்கம்
  '\u0c28\u0c2e\u0c38\u0c4d\u0c15\u0c3e\u0c30\u0c02\u0c32\u0c41|' + // Telugu: నమస్కారంలు
  '\u0ca8\u0cae\u0cb8\u0ccd\u0c95\u0cbe\u0cb0)'     // Kannada: ನಮಸ್ಕಾರ
);
if (greetRegex.test(inputLower)) {
  await this.executeAction(phone, 'MAIN_MENU');
  return;
}

    // ── 8. No match → show Help prompt ───────────────────────────
    await this.sendHelpPrompt(phone);
  }

  // ── BUTTON ID → ACTION MAP ─────────────────────────────────────
  // All interactive button reply IDs used in menus
  resolveButtonId(id) {
    const MAP = {
      // Main navigation
      'main_menu':        'MAIN_MENU',
      'back':             'MAIN_MENU',
      'home':             'MAIN_MENU',
      // Main menu buttons
      'btn_website':       'OPEN_WEBSITE',
      'btn_catalogue':     'OPEN_CATALOG',
      'btn_help':          'HELP_MENU',

      // Help menu buttons
      'btn_browse':        'BROWSE_TOPICS',
      'btn_offers':        'OFFERS_MENU',
      'btn_help_back':     'MAIN_MENU',

      // Offers menu buttons
      'btn_deals':         'DEALS_MENU',
      'btn_offers_back':   'HELP_MENU',

      // Deals menu buttons
      'btn_bestsellers':   'OPEN_BESTSELLERS',
      'btn_shop_now':      'OPEN_WEBSITE',
      'btn_deals_back':    'HELP_MENU',

      // Post-FAQ buttons
      'faq_more':         null, // handled separately above
      'faq_order':        null, // handled separately above
      'faq_home':         null, // handled separately above
    };
    return MAP[id] ?? null;
  }

  // ── TEXT TRIGGER → ACTION MAP ──────────────────────────────────
  resolveTextTrigger(inputLower) {

  // ── ORDER FLOW ─────────────────────────────────────────────
  const orderRegex = new RegExp(
    'i want to (buy|order|purchase)|how to (buy|order)|want to buy|can i order|place an? order|' +
    'order karn[ae]|order dena|order chahiye|mujhe order|buy karna|kharidna hai|' +
    'order pannanum|vanganum|vaanganam|' +
    'order cheyali|kaavali|order cheyyandi|' +
    'order maadabeku|kharidi maadabeku'
  );
  if (orderRegex.test(inputLower)) return 'ORDER_FLOW';

  // ── BRACELET ───────────────────────────────────────────────
  const braceletRegex = new RegExp(
    'bracelet|bangle|bangles|kada|kara|' +
    '\u0bb5\u0bb3\u0bc8\u0baf\u0bb2\u0bcd|' +  // Tamil: வளையல்
    '\u0c17\u0c3e\u0c1c\u0c41\u0c32\u0c41|' +  // Telugu: గాజులు
    '\u0c2c\u0cb3\u0cc6'                         // Kannada: ಬಳೆ
  );
  if (braceletRegex.test(inputLower)) return 'CAT_BRACELET';

  // ── NECKLACE ───────────────────────────────────────────────
  const necklaceRegex = new RegExp(
    'necklace|haar|chain|mala|' +
    '\u0bae\u0bbe\u0bb2\u0bc8|' +              // Tamil: மாலை
    '\u0c28\u0c46\u0c15\u0c4d\u0c32\u0c46\u0c38\u0c4d|' + // Telugu: నెక్లెస్
    '\u0cb9\u0cbe\u0cb0'                         // Kannada: ಹಾರ
  );
  if (necklaceRegex.test(inputLower)) return 'CAT_NECKLACE';

  // ── EARRINGS ───────────────────────────────────────────────
  const earringRegex = new RegExp(
    'earring|jhumka|bali|stud|tops|jhumke|' +
    '\u0b95\u0bbe\u0ba4\u0ba3\u0bbf|' +        // Tamil: காதணி
    '\u0c1a\u0c46\u0c35\u0c3f\u0c2a\u0c4b\u0c17\u0c41\u0c32\u0c41|' + // Telugu: చెవిపోగులు
    '\u0c95\u0cbf\u0cb5\u0cbf\u0caf\u0ccb\u0cb2\u0cc6'  // Kannada: ಕಿವಿಯೋಲೆ
  );
  if (earringRegex.test(inputLower)) return 'CAT_EARRINGS';

  // ── PENDANT SETS ───────────────────────────────────────────
  const pendantSetRegex = new RegExp(
    'pendant set|jewellery set|full set|set chahiye|' +
    '\u0ba8\u0b95\u0bc8 \u0b9a\u0bc6\u0b9f\u0bcd|' +    // Tamil: நகை செட்
    '\u0c1c\u0c4d\u0c2f\u0c41\u0c2f\u0c46\u0c32\u0c30\u0c40 \u0c38\u0c46\u0c1f\u0c4d|' + // Telugu: జ్యుయెలరీ సెట్
    '\u0c92\u0ca1\u0cb5\u0cc6 \u0c38\u0cc6\u0c9f\u0ccd'  // Kannada: ಒಡವೆ ಸೆಟ್
  );
  if (pendantSetRegex.test(inputLower)) return 'CAT_PENDANT_SETS';

  // ── PENDANT ────────────────────────────────────────────────
  const pendantRegex = new RegExp(
    'pendant|locket|mangalsutra|' +
    '\u0bb2\u0bbe\u0b95\u0bcd\u0b95\u0bc6\u0b9f\u0bcd|' + // Tamil: லாக்கெட்
    '\u0c32\u0c3e\u0c15\u0c46\u0c1f\u0c4d|' +             // Telugu: లాకెట్
    '\u0cb2\u0cbe\u0c95\u0cc6\u0c9f\u0ccd'                 // Kannada: ಲಾಕೆಟ್
  );
  if (pendantRegex.test(inputLower)) return 'CAT_PENDANT';

  // ── RINGS ──────────────────────────────────────────────────
  const ringRegex = new RegExp(
    '\\bring\\b|anguthi|angoothi|' +
    '\u0bae\u0bcb\u0ba4\u0bbf\u0bb0\u0bae\u0bcd|' +  // Tamil: மோதிரம்
    '\u0c09\u0c02\u0c17\u0c30\u0c02|' +               // Telugu: ఉంగరం
    '\u0c89\u0c02\u0c17\u0cb0'                         // Kannada: ಉಂಗರ
  );
  if (ringRegex.test(inputLower)) return 'CAT_RINGS';

  // ── CATALOGUE ──────────────────────────────────────────────
  const catalogRegex = new RegExp(
    'catalogue|catalog|collection|sab dikhao|all products|poora|' +
    '\u0b95\u0bbe\u0b9f\u0bcd\u0b9f\u0bc1|' +  // Tamil: காட்டு
    '\u0c1a\u0c42\u0c2a\u0c3f\u0c02\u0c1a\u0c41|' + // Telugu: చూపించు
    '\u0ca4\u0ccb\u0cb0\u0cbf\u0cb8\u0cc1'      // Kannada: ತೋರಿಸು
  );
  if (catalogRegex.test(inputLower)) return 'OPEN_CATALOG';

  return null;
}

  // ── EXECUTE ACTION ─────────────────────────────────────────────
  async executeAction(phone, action) {
    const env = this.env;

    const saveOutgoing = async (text, type = 'text') => {
      const msgId = `auto_${Date.now()}_${Math.random().toString(36).slice(2)}_${phone}`;
      await env.DB.prepare(`
        INSERT OR IGNORE INTO messages
          (message_id, phone, text, message_type, direction, status, is_auto_reply, timestamp, created_at)
        VALUES (?, ?, ?, ?, 'outgoing', 'sent', 1, datetime('now'), datetime('now'))
      `).bind(msgId, phone, text, type).run();
      await env.DB.prepare(`
        UPDATE chats SET
          last_message = ?, last_message_type = ?, last_direction = 'outgoing',
          last_timestamp = datetime('now'), updated_at = datetime('now')
        WHERE phone = ?
      `).bind(text.substring(0, 100), type, phone).run();
    };

    const sendButtons = async (text, btns, footer = null) => {
      await sendWhatsAppButtons(env, phone, text, btns, footer);
      await saveOutgoing('[Menu] ' + text.substring(0, 80), 'buttons');
    };

    const sendText = async (text) => {
      await sendWhatsAppText(env, phone, text);
      await saveOutgoing(text.substring(0, 100), 'text');
    };

    switch (action) {

      // ════════════════════════════════════════
      // MAIN MENU
      // ════════════════════════════════════════
      case 'MAIN_MENU':
        await sendButtons(
`═══════════════════════════
✨ *KAAPAV Fashion Jewellery* ✨
═══════════════════════════

💎 Simple Luxury — Crafted for You

👑 Elegant collections
✨ Timeless sparkle
💝 Crafted to impress	

How can we help you today? 👇`,
          [
            { id: 'btn_website',   title: '💎 Website' },
            { id: 'btn_catalogue', title: '📱 Catalogue' },
            { id: 'btn_help',      title: '❓ Help & FAQs' },	
          ],
          '💖 Where Luxury Meets You'
        );
        break;



      // ════════════════════════════════════════
      // HELP MENU
      // ════════════════════════════════════════
      case 'HELP_MENU':
        await sendButtons(
`═══════════════════════════
❓ *Help & FAQs*
═══════════════════════════

👑 We’re here to assist you

💬 Get instant answers
🎁 Explore offers & tracking
✨ Everything in one place

What would you like to do? 👇`,
          [
            { id: 'btn_browse',    title: '📋 FAQs' },
            { id: 'btn_offers',    title: '🎁 Offers' },
            { id: 'btn_help_back', title: '🏠 Back' },
          ],
          '💖 Assistance with elegance'
        );
        break;

      // ════════════════════════════════════════
      // OFFERS & DEALS MENU
      // ════════════════════════════════════════
      case 'OFFERS_MENU':
        await sendButtons(
`═══════════════════════════
🎁 *Offers*
═══════════════════════════

👑 Discover our special picks

🔥 Bestselling favourites
✨ Luxury at irresistible prices
💎 Curated to be loved

What would you like to explore? 👇`,
          [
            { id: 'btn_deals',       title: '🔥 Bestsellers' },
            { id: 'btn_shop_now',    title: '💎 Website' },
            { id: 'btn_offers_back', title: '🏠 Back' },
          ],
          '✨ Great deals await!'
        );
        break;

      // ════════════════════════════════════════
      // DEALS MENU
      // ════════════════════════════════════════
      case 'DEALS_MENU':
        await sendButtons(
`═══════════════════════════
🔥 *Bestsellers*
═══════════════════════════

👑 Most loved by KAAPAV customers

💍 Earrings & Rings → ₹249/-
📿 Necklace & Bracelet → ₹499/-
✨ Sets → ₹699/-
🚚 FREE shipping above ₹498/-

Explore our favourites 👇`,
          [
            { id: 'btn_bestsellers', title: '🛍️ Open Bestsellers' },
            { id: 'btn_shop_now',    title: '💎 Website' },
            { id: 'btn_deals_back',  title: '🏠 Back' },
          ],
          "💖 Crafted to stand out"
        );
        break;

 
      // ════════════════════════════════════════
      // HELP PROMPT
      // User types freely OR browses topics
      // ════════════════════════════════════════
      case 'HELP_PROMPT':
        await sendButtons(
`═══════════════════════════
❓ *Help & FAQs*
═══════════════════════════

Just type your question! 😊

For example:
• "Will it tarnish?"
• "How long to deliver?"
• "Can I return it?"
• "What is the price?"

Or browse all topics below 👇`,
          [
            { id: 'btn_browse',    title: '📋 FAQs' },
            { id: 'btn_offers',    title: '🎁 Offers & Track' },
            { id: 'btn_help_back', title: '🏠 Back' },
          ],
          '💬 We answer everything!'
        );
        break;

      // ════════════════════════════════════════
      // BROWSE TOPICS — WhatsApp List (10 categories)
      // ════════════════════════════════════════
      case 'BROWSE_TOPICS':
        await this.sendBrowseTopics(phone);
        break;

      // ════════════════════════════════════════
      // OPEN WEBSITE
      // ════════════════════════════════════════
      case 'OPEN_WEBSITE':
        await sendText(
`═══════════════════════════
🌐 *Visit Our Website*
═══════════════════════════

💎 Complete Collection Online

✨ Latest arrivals
🛍️ All categories
💳 Easy & secure checkout

👉 ${env.WEBSITE_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        break;

      case 'OPEN_CATALOG':
        await sendText(
`═══════════════════════════
📱 *KAAPAV Catalogue*
═══════════════════════════

💎 Explore our online collection

✨ Browse all categories
🛍️ Discover your favourites
💝 Designed for effortless shopping

👉 ${env.CATALOG_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        break;

      // ════════════════════════════════════════
      // OPEN BESTSELLERS
      // ════════════════════════════════════════
      case 'OPEN_BESTSELLERS':
        await sendText(
`═══════════════════════════
🛍️ *Bestselling Pieces*
═══════════════════════════

💎 Most Loved by Customers

❤️ Top rated designs
🔥 Trending right now
⚡ Limited stock available!

👉 ${env.BESTSELLERS_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        break;

      
      case 'CAT_BRACELET':
        await sendText(
`═══════════════════════════
📿 *KAAPAV Bracelets*
═══════════════════════════

💎 Our Bracelet Collection

✨ Anti-tarnish artificial gold
💰 Starting ₹499/- only
🚚 Free shipping above ₹498/-

👉 https://www.kaapav.com/shop/category/all-jewellery-bracelets-13

💬 Message us to order!`
        );
        break;

      case 'CAT_NECKLACE':
        await sendText(
`═══════════════════════════
✨ *KAAPAV Necklaces*
═══════════════════════════

💎 Our Necklace Collection

✨ Elegant & timeless designs
💰 Starting ₹499/- only
🚚 Free shipping above ₹498/-

👉 https://www.kaapav.com/shop/category/all-jewellery-necklaces-14

💬 Message us to order!`
        );
        break;

      case 'CAT_EARRINGS':
        await sendText(
`═══════════════════════════
👂 *KAAPAV Earrings*
═══════════════════════════

💎 Our Earring Collection

✨ Lightweight & comfortable
💰 Starting ₹249/- only
🚚 Free shipping above ₹498/-

👉 https://www.kaapav.com/shop/category/all-jewellery-earrings-15

💬 Message us to order!`
        );
        break;

      case 'CAT_RINGS':
        await sendText(
`═══════════════════════════
💍 *KAAPAV Rings*
═══════════════════════════

💎 Our Ring Collection

✨ Free size & adjustable
💰 Starting ₹249/- only
🚚 Free shipping above ₹498/-

👉 https://www.kaapav.com/shop/category/all-jewellery-rings-16

💬 Message us to order!`
        );
        break;

      case 'CAT_PENDANT':
        await sendText(
`═══════════════════════════
💎 *KAAPAV Pendants*
═══════════════════════════

💎 Our Pendant Collection

✨ Stunning designs
💰 Starting ₹499/- only
🚚 Free shipping above ₹498/-

👉 https://www.kaapav.com/shop/category/all-jewellery-pendants-17

💬 Message us to order!`
        );
        break;

      case 'CAT_PENDANT_SETS':
        await sendText(
`═══════════════════════════
🎁 *KAAPAV Pendant Sets*
═══════════════════════════

💎 Our Jewellery Sets

✨ Matching pendant + earring sets
💰 Starting ₹699/- only
🚚 Free shipping above ₹498/-

👉 https://www.kaapav.com/shop/category/all-jewellery-pendant-sets-18

💬 Message us to order!`
        );
        break;

      // ════════════════════════════════════════
      // ORDER FLOW (text trigger only)
      // ════════════════════════════════════════
      case 'ORDER_FLOW':
        await sendText(
`═══════════════════════════
🛒 *Let's Place Your Order!*
═══════════════════════════

💎 Simple Luxury. Easy Ordering.

3 easy ways to order:

1️⃣ *Website* — browse & checkout:
   👉 ${env.WEBSITE_URL}

2️⃣ *Catalogue Website* — browse & order:
   👉 ${env.CATALOG_URL}

💍 Earrings & Rings → ₹249/-
📿 Necklace & Bracelet → ₹499/-
✨ Sets → ₹699/-
🚚 FREE shipping above ₹498/-

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        break;
    }
  }

  // ── BROWSE TOPICS — WhatsApp List Message ─────────────────────
  // Shows all 10 FAQ categories as a scrollable list
  async sendBrowseTopics(phone) {
    const env = this.env;

    // WhatsApp list allows max 10 items in one section
    const sections = [
      {
        title: 'Choose a Topic',
        rows: this.FAQ_CATEGORIES.map(cat => ({
          id: cat.id,
          title: cat.title,
          description: cat.desc,
        })),
      }
    ];

    await sendWhatsAppList(
      env,
      phone,
`═══════════════════════════
📋 *Browse FAQ Topics*
═══════════════════════════

💎 Pick a topic below and
I'll answer all your questions!

Tap to select 👇`,
      '📋 Choose Topic',
      sections,
      '💬 Everything you need to know'
    );

    const msgId = `auto_${Date.now()}_${phone}`;
    await env.DB.prepare(`
      INSERT OR IGNORE INTO messages
        (message_id, phone, text, message_type, direction, status, is_auto_reply, timestamp, created_at)
      VALUES (?, ?, ?, ?, 'outgoing', 'sent', 1, datetime('now'), datetime('now'))
    `).bind(msgId, phone, '[Browse Topics list sent]', 'list').run();
    await env.DB.prepare(`
      UPDATE chats SET last_message = 'Browse Topics', last_message_type = 'list',
        last_direction = 'outgoing', last_timestamp = datetime('now'), updated_at = datetime('now')
      WHERE phone = ?
    `).bind(phone).run();
  }

  // ── FAQ CATEGORY SELECTED from Browse Topics list ─────────────
  // Shows sub-list of all FAQ questions in that group
async sendFaqCategoryMenu(phone, faqCat) {
  const env = this.env;

  // Use hardcoded FAQ data instead of DB
  const faqs = this.FAQ_DATA[faqCat.group] || [];

  if (faqs.length === 0) {
    await sendWhatsAppText(env, phone,
      `No FAQs found for ${faqCat.title}. Type your question and I'll help! 😊`
    );
    return;
  }

  // Store FAQ index in KV for item selection
  const faqIndex = faqs.map(f => f.shortcut);
  await env.KV.put(`faq_index:${phone}`, JSON.stringify(faqIndex), { expirationTtl: 600 });

  const rows = faqs.slice(0, 10).map((f, i) => ({
    id: `faq_item_${i}`,
    title: f.title.substring(0, 24),
    description: '',
  }));

  const sections = [{ title: faqCat.title, rows }];

  await sendWhatsAppList(
    env, phone,
`═══════════════════════════
${faqCat.title}
═══════════════════════════

💎 Select your question below
and get an instant answer! 👇`,
    '❓ Select Question',
    sections,
    '💬 Tap to get your answer'
  );

  // Save to DB
  const msgId = `auto_${Date.now()}_${phone}`;
  await env.DB.prepare(`
    INSERT OR IGNORE INTO messages
      (message_id, phone, text, message_type, direction, status, is_auto_reply, timestamp, created_at)
    VALUES (?, ?, ?, ?, 'outgoing', 'sent', 1, datetime('now'), datetime('now'))
  `).bind(msgId, phone, `[FAQ category: ${faqCat.group}]`, 'list').run();
  await env.DB.prepare(`
    UPDATE chats SET last_message = ?, last_message_type = 'list',
      last_direction = 'outgoing', last_timestamp = datetime('now'), updated_at = datetime('now')
    WHERE phone = ?
  `).bind(faqCat.title, phone).run();
}

 async handleOrderState(phone, state, data, input) {
  const env = this.env;
  const lower = input.toLowerCase();

  // Cancel anytime
  if (/cancel|stop|quit|nahi|nope/.test(lower)) {
    await clearConvState(phone, env);
    await sendWhatsAppText(env, phone, '❌ Order cancelled. No worries!\n\nType *order karna hai* anytime to start again. 💎');
    return;
  }

  switch (state) {
    case 'order_name':
      if (input.length < 2) {
        await sendWhatsAppText(env, phone, '😊 Please enter your *full name* for delivery:');
        return;
      }
      data.name = input;
      await setConvState(phone, 'order_address', data, env);
      await sendWhatsAppText(env, phone, `Thanks ${input.split(' ')[0]}! 👋\n\nPlease enter your *complete delivery address*:\n_(House no, Street, Area, City)_`);
      break;

    case 'order_address':
      if (input.length < 10) {
        await sendWhatsAppText(env, phone, '📍 Please enter a more complete address:');
        return;
      }
      data.address = input;
      await setConvState(phone, 'order_pincode', data, env);
      await sendWhatsAppText(env, phone, '📮 Enter your *PIN code*:');
      break;

    case 'order_pincode':
      if (!/^\d{6}$/.test(input)) {
        await sendWhatsAppText(env, phone, '⚠️ Please enter a valid *6-digit PIN code*:');
        return;
      }
      data.pincode = input;
      await setConvState(phone, 'order_confirm', data, env);

      const cart = data.cart || [];
      const total = cart.reduce((s, i) => s + (i.price * (i.qty || 1)), 0);
      const shipping = total >= 498 ? 0 : 60;
      const grand = total + shipping;
      const lines = cart.map(i => `• ${i.name} × ${i.qty || 1} — ₹${i.price * (i.qty || 1)}`).join('\n');

      await sendWhatsAppButtons(env, phone,
`═══════════════════════════
🛒 *Order Summary*
═══════════════════════════

${lines}
━━━━━━━━━━━━━━━━━━
📦 Subtotal: ₹${total}
🚚 Shipping: ${shipping === 0 ? 'FREE 🎉' : '₹' + shipping}
💰 *Total: ₹${grand}*
═══════════════════════════

📍 *Deliver to:*
${data.name}
${data.address}
PIN: ${data.pincode}

Confirm order? 👇`,
        [
          { id: 'order_yes', title: '✅ Confirm Order' },
          { id: 'order_no',  title: '❌ Cancel' },
        ]
      );
      break;

   case 'order_confirm':
  if (input === 'order_yes' || /yes|confirm|haan|ha/.test(lower)) {
    const cart = data.cart || [];
    const total = cart.reduce((s, i) => s + (i.price * (i.qty || 1)), 0);
    const shipping = total >= 498 ? 0 : 60;
    const grand = total + shipping;
    const orderId = await generateOrderId(env);
    const items = cart.map(i => ({
      name: i.name, sku: i.sku, qty: i.qty || 1, price: i.price
    }));

    // Save order to D1
    await env.DB.prepare(`
      INSERT INTO orders (
        order_id, phone, customer_name, items, item_count,
        subtotal, shipping_cost, total,
        shipping_name, shipping_address, shipping_pincode,
        status, payment_status, source, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'unpaid', 'whatsapp', datetime('now'), datetime('now'))
    `).bind(
      orderId, phone, data.name,
      JSON.stringify(items), items.length,
      total, shipping, grand,
      data.name, data.address, data.pincode
    ).run();
 
    await logOrderEvent(env, orderId, 'order_created', 'WhatsApp order created', {
  phone,
  customerName: data.name,
  total: grand,
  itemCount: items.length,
}, 'whatsapp_bot');

    try {
      await syncOrderToGoogleSheetsSafe(env, orderId);
      await syncCustomerToGoogleSheetsSafe(env, phone);
      await syncLeadToGoogleSheetsSafe(env, phone);
      await syncSalesToGoogleSheetsSafe(env, orderId);
      await rebuildSourcePerformanceSheet(env);
    } catch (e) {
      console.error('Google Sheets sync error (WhatsApp order):', e);
      await appendSyncFailureToGoogleSheets(env, {
        destination: 'google_sheets',
        entity_type: 'order',
        entity_id: orderId,
        action: 'order_created',
        error_message: e.message,
        retry_count: 0,
        status: 'failed',
      });
    }
    await clearConvState(phone, env);

    // Build item lines for owner message
    const itemLines = items
      .map(i => `• ${i.name} x${i.qty} — \u20B9${i.price * i.qty}`)
      .join('\n');

    // Owner WA — new order alert (before payment, so they know it's coming)
    await sendWhatsAppText(env, env.OWNER_PHONE,
      `🛒 *New Order Placed!*\n\n` +
      `Order ID: *${orderId}*\n` +
      `Customer: ${data.name} (${phone})\n` +
      `Address: ${data.address}\n` +
      `PIN: ${data.pincode}\n\n` +
      `🛍️ *Items:*\n${itemLines}\n\n` +
      `📦 Subtotal: \u20B9${total}\n` +
      `🚚 Shipping: ${shipping === 0 ? 'FREE' : '\u20B9' + shipping}\n` +
      `💰 *Total: \u20B9${grand}*\n\n` +
      `⏳ Payment link sent. Awaiting payment...`
    );

    // Generate Razorpay payment link and send to customer
    try {
      const payLink = await createRazorpayLink(env, {
        amount: grand,
        name: data.name,
        phone,
        orderId,
        description: `KAAPAV Order ${orderId}`
      });

      await env.DB.prepare(
        `UPDATE orders SET payment_link = ? WHERE order_id = ?`
      ).bind(payLink, orderId).run();

      // Customer WA — order confirmed + payment link
      await sendWhatsAppText(env, phone,
        `💎 *Order Placed Successfully!*\n\n` +
        `Order ID: *${orderId}*\n\n` +
        `🛍️ *Items:*\n${itemLines}\n\n` +
        `📦 Subtotal: \u20B9${total}\n` +
        `🚚 Shipping: ${shipping === 0 ? 'FREE 🎉' : '\u20B9' + shipping}\n` +
        `💰 *Total: \u20B9${grand}*\n\n` +
        `💳 *Complete payment here (valid 24 hrs):*\n${payLink}\n\n` +
        `_Your order ships once payment is confirmed_ 🚚\n\n` +
        `💎 KAAPAV Fashion Jewellery`
      );

    } catch(e) {
      console.error('Razorpay error:', e);
      // Fallback — order saved, tell customer we'll send link
      await sendWhatsAppText(env, phone,
        `✅ *Order Placed!*\n\n` +
        `Order ID: *${orderId}*\n\n` +
        `We'll send your payment link shortly! 💳\n\n` +
        `💎 KAAPAV Fashion Jewellery`
      );
    }

  } else {
    await clearConvState(phone, env);
    await sendWhatsAppText(env, phone,
      `❌ Order cancelled.\n\nType *order karna hai* anytime to start again! 💎`
    );
  }
  break;

    default:
      await clearConvState(phone, env);
      await sendWhatsAppText(env, phone, 'Something went wrong. Let\'s start fresh!\n\nType *hi* to see the main menu. 😊');
  }
}
  // ── FAQ ITEM SELECTED from category sub-list ──────────────────
  async handleFaqItemSelection(phone, buttonId) {
  const env = this.env;
  const idx = parseInt(buttonId.split('_').pop(), 10);

  const faqIndexRaw = await env.KV.get(`faq_index:${phone}`);
  if (!faqIndexRaw) { await this.sendBrowseTopics(phone); return; }

  const faqIndex = JSON.parse(faqIndexRaw);
  const shortcut = faqIndex[idx];
  if (!shortcut) { await this.sendBrowseTopics(phone); return; }

  // Find in hardcoded FAQ_DATA
  let faq = null;
  for (const group of Object.values(this.FAQ_DATA)) {
    faq = group.find(f => f.shortcut === shortcut);
    if (faq) break;
  }

  if (!faq) {
    await sendWhatsAppText(env, phone, 'Sorry, could not find that answer. Please try again! 😊');
    return;
  }

  await this.sendFaqAnswer(phone, faq);
}

  // ── SEND FAQ ANSWER + post-answer buttons ─────────────────────
  // After answer: [❓ More] [🛒 Order] [🏠 Home]
  async sendFaqAnswer(phone, faq) {
    const env = this.env;

    // Send the answer text
    await sendWhatsAppText(env, phone, faq.message);

    // Small delay so answer arrives before buttons
    await new Promise(r => setTimeout(r, 800));

    // Post-FAQ action buttons
    await sendWhatsAppButtons(
      env,
      phone,
      'Was that helpful? What would you like to do next?',
      [
        { id: 'faq_more',  title: '❓ More Questions' },
        { id: 'faq_order', title: '🛒 Order Now' },
        { id: 'faq_home',  title: '🏠 Home' },
      ],
      '💎 KAAPAV Fashion Jewellery'
    );

    // Save to DB
    const msgId1 = `auto_${Date.now()}_faq_${phone}`;
    await env.DB.prepare(`
      INSERT OR IGNORE INTO messages
        (message_id, phone, text, message_type, direction, status, is_auto_reply, timestamp, created_at)
      VALUES (?, ?, ?, ?, 'outgoing', 'sent', 1, datetime('now'), datetime('now'))
    `).bind(msgId1, phone, faq.message.substring(0, 100), 'text').run();

    await env.DB.prepare(`
      UPDATE chats SET last_message = ?, last_message_type = 'buttons',
        last_direction = 'outgoing', last_timestamp = datetime('now'), updated_at = datetime('now')
      WHERE phone = ?
    `).bind(faq.title, phone).run();
  }

  // ── KEYWORD SEARCH across all FAQs ───────────────────────────
  // Scans keywords JSON array in quick_replies for any word match
  async searchFaqByKeyword(inputLower) {
  if (inputLower.length < 3) return null;

  // Simple keyword matching against FAQ titles and shortcuts
  const keywords = {
    'tarnish|black|green|colour|color':        'faq_tarnish',
    'last|long|durable|durability':            'faq_last',
    'daily|everyday|regular':                  'faq_daily',
    'ring|size|fit':                           'faq_ring_size',
    'bracelet':                                'faq_bracelet_size',
    'necklace|length|chain':                   'faq_necklace_length',
    'earring|heavy|weight|ear':                'faq_earring_weight',
    'price|cost|rate|₹|rupee':                 'faq_price',
    'discount|offer|sale|off':                 'faq_discount',
    'shipping|delivery charge|free ship':      'faq_shipping_cost',
    'cod|cash on delivery|cash':               'faq_cod',
    'how to order|place order|ordering':       'faq_how_order',
    'return|refund|wapas':                     'faq_return',
    'exchange|replace':                        'faq_exchange',
    'cancel':                                  'faq_cancel',
    'track|tracking|status|kahan':             'faq_track',
    'deliver|delivery time|days':              'faq_delivery_time',
    'care|clean|maintain':                     'faq_care',
    'damage|broken|defect':                    'faq_damaged',
    'about|kaapav|brand':                      'faq_about',
    'contact|reach|email|phone':               'faq_contact',
    'instagram|facebook|social':               'faq_social',
    'payment|pay|safe|secure|upi|card':        'faq_payment_safe',
    'safe|strong|strong|sturdy':               'faq_strong',
    'plating|fade':                            'faq_plating',
    'perfume|spray|chemical':                  'faq_perfume',
    'sleep|night|wear at night':               'faq_sleep',
    'piercing|pierced':                        'faq_piercing',
    'delayed|late|not received':               'faq_delayed',
    'area|pincode|deliver to':                 'faq_delivery_area',
    'packaging|pack|box':                      'faq_packaging',
    'refund time|when refund':                 'faq_refund_time',
    'confirm|confirmation':                    'faq_confirmation',
    'combo|set|bundle':                        'faq_combo',
    'minimum|min order':                       'faq_minimum',
    'multiple|many|bulk':                      'faq_multiple',
    'gift pack|gift box|gift wrap':            'faq_gift_pack',
    'gift order|order.*gift':                  'faq_gift_order',
  };

  let matchedShortcut = null;
  for (const [pattern, shortcut] of Object.entries(keywords)) {
    if (new RegExp(pattern).test(inputLower)) {
      matchedShortcut = shortcut;
      break;
    }
  }

  if (!matchedShortcut) return null;

  for (const group of Object.values(this.FAQ_DATA)) {
    const faq = group.find(f => f.shortcut === matchedShortcut);
    if (faq) return faq;
  }
  return null;
}

  // ── HELP PROMPT (fallback) ─────────────────────────────────────
  async sendHelpPrompt(phone) {
    const env = this.env;
    await sendWhatsAppButtons(
      env,
      phone,
`═══════════════════════════
❓ *Need Help?*
═══════════════════════════

Just type your question! 😊

Examples:
• "Will it tarnish?"
• "How to return?"
• "Delivery time?"

Or browse all FAQ topics 👇`,
      [
        { id: 'btn_browse',    title: '📋 Browse Topics' },
        { id: 'btn_help_back', title: '🏠 Back' },
      ],
      '💎 KAAPAV Fashion Jewellery'
    );

    const msgId = `auto_${Date.now()}_${phone}`;
    await env.DB.prepare(`
      INSERT OR IGNORE INTO messages
        (message_id, phone, text, message_type, direction, status, is_auto_reply, timestamp, created_at)
      VALUES (?, ?, ?, ?, 'outgoing', 'sent', 1, datetime('now'), datetime('now'))
    `).bind(msgId, phone, '[Help prompt sent]', 'buttons').run();
    await env.DB.prepare(`
      UPDATE chats SET last_message = 'Help & FAQs', last_message_type = 'buttons',
        last_direction = 'outgoing', last_timestamp = datetime('now'), updated_at = datetime('now')
      WHERE phone = ?
    `).bind(phone).run();
  }
}

// ═══════════════════ ROUTER ═══════════════════
export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });

    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    if (path === '/health') return new Response('OK', { status: 200 });

    if (path === '/api/debug/google-auth' && method === 'GET') {
  const email = env.GOOGLE_SERVICE_ACCOUNT_EMAIL || '';
  const key = env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY || '';

  return jsonResponse({
    email: email,
    emailLength: email.length,
    keyExists: !!key,
    keyLength: key.length,
    keyFirst30: key.substring(0, 30),
  });
}

    if (path === '/api/debug/sync-check' && method === 'POST') {
  const incomingKey = request.headers.get('x-sync-key');
  const storedKey = env.SYNC_API_KEY;

  return jsonResponse({
    incomingKeyExists: !!incomingKey,
    incomingKeyLength: incomingKey ? incomingKey.length : 0,
    incomingKeyFirst4: incomingKey ? incomingKey.substring(0, 4) : 'NONE',
    storedKeyExists: !!storedKey,
    storedKeyLength: storedKey ? storedKey.length : 0,
    storedKeyFirst4: storedKey ? storedKey.substring(0, 4) : 'NONE',
    keysMatch: incomingKey === storedKey,
    envVarsAvailable: {
      SYNC_API_KEY: !!env.SYNC_API_KEY,
      GOOGLE_SHEETS_SPREADSHEET_ID: !!env.GOOGLE_SHEETS_SPREADSHEET_ID,
      GOOGLE_SERVICE_ACCOUNT_EMAIL: !!env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
      GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: !!env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY,
    }
  });
}

    if (path === '/webhook' || path === '/api/webhook') {
      if (method === 'GET') return handleWebhookVerify(request, env);
      if (method === 'POST') return handleWebhookPost(request, env, ctx);
    }

if (path === '/api/catalogue' && method === 'GET') {
  const { results } = await env.DB.prepare(
    `SELECT sku, name, category, price, compare_price, image_url, images,
            website_link, description, tags, stock, is_featured
     FROM products WHERE is_active = 1 ORDER BY category ASC, name ASC`
  ).all();
  return new Response(JSON.stringify({ success: true, products: results || [] }), {
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-store, no-cache, must-revalidate',
      'Pragma': 'no-cache',
    }
  });
}
 
    // ═══ RAZORPAY WEBHOOK ═══
if ((path === '/api/razorpay/webhook' || path === '/api/payment/webhook') && method === 'POST') {
  const rawBody = await request.text();
  const sig = request.headers.get('x-razorpay-signature');

  // Verify HMAC signature
  try {
    const key = await crypto.subtle.importKey(
      'raw', new TextEncoder().encode(env.RAZORPAY_KEY_SECRET),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
    );
    const expectedSig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(rawBody));
    const expectedHex = Array.from(new Uint8Array(expectedSig))
      .map(b => b.toString(16).padStart(2, '0')).join('');
    if (sig !== expectedHex) return new Response('Invalid signature', { status: 400 });
  } catch(e) { return new Response('Sig error', { status: 400 }); }

  const event = JSON.parse(rawBody);
  const eventType = event.event;

  // ── payment_link.paid ─────────────────────────────────────────
  // Fires when customer pays via WhatsApp bot or Catalogue payment link
  if (eventType === 'payment_link.paid') {
    const pl = event.payload.payment_link.entity;
    const orderId = pl.reference_id;
    const paymentId = event.payload.payment.entity.id;
    const amount = pl.amount / 100;

    const order = await env.DB.prepare(
      `SELECT * FROM orders WHERE order_id = ?`
    ).bind(orderId).first();

    if (!order) return jsonResponse({ status: 'ok' });

    // Idempotent — skip if already paid
    if (order.payment_status === 'paid') return jsonResponse({ status: 'ok' });

    // Update order status
    await env.DB.prepare(`
      UPDATE orders SET
        payment_status = 'paid',
        status         = 'confirmed',
        payment_id     = ?,
        paid_at        = datetime('now'),
        updated_at     = datetime('now')
      WHERE order_id = ?
    `).bind(paymentId, orderId).run();

    await logOrderEvent(env, orderId, 'payment_confirmed', 'Payment confirmed via payment_link.paid webhook', {
  paymentId,
  amount,
  source: order.source || 'whatsapp',
}, 'razorpay_webhook');

    const phone = order.phone;
    try {
      await syncOrderToGoogleSheetsSafe(env, orderId);
      await syncCustomerToGoogleSheetsSafe(env, phone);
      await syncLeadToGoogleSheetsSafe(env, phone);
      await syncSalesToGoogleSheetsSafe(env, orderId);
      await rebuildSourcePerformanceSheet(env);
    } catch (e) {
      console.error('Google Sheets sync error (payment_link.paid):', e);
      await appendSyncFailureToGoogleSheets(env, {
        destination: 'google_sheets',
        entity_type: 'order',
        entity_id: orderId,
        action: 'payment_link_paid',
        error_message: e.message,
        retry_count: 0,
        status: 'failed',
      });
    }
    const customerName = order.customer_name || 'Customer';

    // Parse items for owner message
    let itemLines = '';
    try {
      const items = JSON.parse(order.items || '[]');
      itemLines = items.length > 0
        ? items.map(i => `• ${i.name} x${i.qty || 1} — \u20B9${i.price * (i.qty || 1)}`).join('\n')
        : '• (items not available)';
    } catch(e) { itemLines = '• (items not available)'; }

    // Customer WA — payment confirmed
    await sendWhatsAppText(env, phone,
      `✅ *Payment Confirmed!*\n\n` +
      `Hi ${customerName.split(' ')[0]}! 🎉\n\n` +
      `Order ID: *${orderId}*\n` +
      `Amount Paid: \u20B9${amount}\n` +
      `Payment ID: ${paymentId}\n\n` +
      `📦 Your order is confirmed!\n` +
      `We will pack & ship within *24 hours*.\n` +
      `You will get your tracking details here on WhatsApp once shipped. 🚚\n\n` +
      `Questions? Just message us here anytime 😊\n` +
      `💎 KAAPAV Fashion Jewellery`
    );

    // Owner WA — payment received alert
    await sendWhatsAppText(env, env.OWNER_PHONE,
      `💰 *Payment Received!*\n\n` +
      `Order: *${orderId}*\n` +
      `Customer: ${customerName} (${phone})\n` +
      `Amount: \u20B9${amount}\n` +
      `Payment ID: ${paymentId}\n` +
      `Source: ${order.source || 'whatsapp'}\n\n` +
      `🛍️ *Items:*\n${itemLines}\n\n` +
      `📦 Total: \u20B9${order.total}\n\n` +
      `✅ Open app → Orders → Book Shiprocket.`
    );

   
    // FCM push to Flutter app
    ctx.waitUntil(sendFCMNotification(
      env, phone, customerName,
      `💰 Payment received! Order ${orderId} — \u20B9${amount}`,
      `pay_${paymentId}`
    ));
  }

  // ── payment.captured ──────────────────────────────────────────
  // Fires when customer pays via Odoo website Razorpay checkout
  if (eventType === 'payment.captured') {
    const payment = event.payload.payment.entity;
    const orderId = payment.notes?.order_id
      || payment.description?.match(/KFJW-[0-9A-Z]+/)?.[0];

    if (!orderId) return jsonResponse({ status: 'ok' });

    const order = await env.DB.prepare(
      `SELECT * FROM orders WHERE order_id = ?`
    ).bind(orderId).first();

    if (!order) return jsonResponse({ status: 'ok' });

    // Idempotent — skip if already paid
    if (order.payment_status === 'paid') return jsonResponse({ status: 'ok' });

    const amount = payment.amount / 100;

    // Update order status
    await env.DB.prepare(`
      UPDATE orders SET
        payment_status = 'paid',
        status         = 'confirmed',
        payment_id     = ?,
        paid_at        = datetime('now'),
        updated_at     = datetime('now')
      WHERE order_id = ?
    `).bind(payment.id, orderId).run();
    
    await logOrderEvent(env, orderId, 'payment_confirmed', 'Payment confirmed via payment.captured webhook', {
  paymentId: payment.id,
  amount,
  source: order.source || 'website',
}, 'razorpay_webhook');

    const phone = order.phone;
    try {
      await syncOrderToGoogleSheetsSafe(env, orderId);
      await syncCustomerToGoogleSheetsSafe(env, phone);
      await syncLeadToGoogleSheetsSafe(env, phone);
      await syncSalesToGoogleSheetsSafe(env, orderId);
      await rebuildSourcePerformanceSheet(env);
     } catch (e) {
      console.error('Google Sheets sync error (payment.captured):', e);
      await appendSyncFailureToGoogleSheets(env, {
        destination: 'google_sheets',
        entity_type: 'order',
        entity_id: orderId,
        action: 'payment_captured',
        error_message: e.message,
        retry_count: 0,
        status: 'failed',
      });
    }

    const customerName = order.customer_name || 'Customer';

    // Parse items for owner message
    let itemLines = '';
    try {
      const items = JSON.parse(order.items || '[]');
      itemLines = items.length > 0
        ? items.map(i => `• ${i.name} x${i.qty || 1} — \u20B9${i.price * (i.qty || 1)}`).join('\n')
        : '• (items not available)';
    } catch(e) { itemLines = '• (items not available)'; }

    // Customer WA — payment confirmed
    await sendWhatsAppText(env, phone,
      `✅ *Payment Confirmed!*\n\n` +
      `Hi ${customerName.split(' ')[0]}! 🎉\n\n` +
      `Order ID: *${orderId}*\n` +
      `Amount Paid: \u20B9${amount}\n\n` +
      `📦 Your order is confirmed!\n` +
      `We will pack & ship within *24 hours*.\n` +
      `You will get your tracking details here on WhatsApp once shipped. 🚚\n\n` +
      `Questions? Just message us here anytime 😊\n` +
      `💎 KAAPAV Fashion Jewellery`
    );

    // Owner WA — payment received alert
    await sendWhatsAppText(env, env.OWNER_PHONE,
      `💰 *Payment Received!*\n\n` +
      `Order: *${orderId}*\n` +
      `Customer: ${customerName} (${phone})\n` +
      `Amount: \u20B9${amount}\n` +
      `Payment ID: ${payment.id}\n` +
      `Source: ${order.source || 'website'}\n\n` +
      `🛍️ *Items:*\n${itemLines}\n\n` +
      `📦 Total: \u20B9${order.total}\n\n` +
      `✅ Open app → Orders → Book Shiprocket.`
    );

    // FCM push to Flutter app
    ctx.waitUntil(sendFCMNotification(
      env, phone, customerName,
      `💰 Payment received! Order ${orderId} — \u20B9${amount}`,
      `pay_${payment.id}`
    ));
  }

  return jsonResponse({ status: 'ok' });
}

 
  if (path === '/api/orders/catalogue' && method === 'POST') {
  const body = await request.json();
  const { name, phone, address, city, state, pincode, items, total } = body;
  if (!phone || !items?.length) return errorResponse('phone and items required');
  const orderId = await generateOrderId(env);
  const itemsJson = JSON.stringify(items);
  const itemCount = items.reduce((s, i) => s + i.qty, 0);
  const shipping = total >= 498 ? 0 : 60;
  const grandTotal = total + shipping;
  await env.DB.prepare(`
    INSERT INTO orders (order_id, phone, customer_name, items, item_count, subtotal, shipping_cost, total,
      shipping_name, shipping_address, shipping_city, shipping_state, shipping_pincode,
      status, payment_status, source, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'unpaid', 'catalogue', datetime('now'), datetime('now'))
  `).bind(orderId, phone, name || phone, itemsJson, itemCount, total, shipping, grandTotal,
    name || '', address || '', city || '', state || '', pincode || '').run();

  await logOrderEvent(env, orderId, 'order_created', 'Catalogue order created', {
  phone,
  customerName: name || phone,
  total: grandTotal,
  itemCount,
}, 'catalogue');

  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncCustomerToGoogleSheetsSafe(env, phone);
    await syncLeadToGoogleSheetsSafe(env, phone);
    await syncSalesToGoogleSheetsSafe(env, orderId);
    await rebuildSourcePerformanceSheet(env);
  } catch (e) {
    console.error('Google Sheets sync error (catalogue order):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order',
      entity_id: orderId,
      action: 'catalogue_order_created',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  } 
 const itemsText = items.map(i => `• ${i.name} x${i.qty} — ₹${i.price * i.qty}`).join('\n');
  
await sendWhatsAppText(env, phone,
    `💎 *KAAPAV Order Summary*\n\nOrder ID: *${orderId}*\n\n${itemsText}\n\n` +
    `Subtotal: ₹${total}\nShipping: ₹${shipping}\n*Total: ₹${grandTotal}*\n\n` +
    `⏳ Complete payment to confirm your order.`
  );

  // Owner WA — new catalogue order
await sendWhatsAppText(env, env.OWNER_PHONE,
  `🛒 *New Catalogue Order!*\n\n` +
  `Order ID: *${orderId}*\n` +
  `Customer: ${name || 'Customer'} (${phone})\n` +
  `Address: ${address || '-'}, ${pincode || '-'}\n\n` +
  `🛍️ *Items:*\n${itemsText}\n\n` +
  `📦 Subtotal: \u20B9${total}\n` +
  `🚚 Shipping: ${shipping === 0 ? 'FREE' : '\u20B9' + shipping}\n` +
  `💰 *Total: \u20B9${grandTotal}*\n\n` +
  `⏳ Payment link sent. Awaiting payment...`
); 

  try {
    const payLink = await createRazorpayLink(env, {
      amount: grandTotal, name: name || 'Customer',
      phone, orderId, description: `KAAPAV Order ${orderId}`
    });
    await env.DB.prepare(`UPDATE orders SET payment_link = ? WHERE order_id = ?`).bind(payLink, orderId).run();
    await sendWhatsAppText(env, phone, `💳 *Pay here:*\n${payLink}\n\n_Link valid for 24 hours_`);
  } catch(e) { console.error('Razorpay error:', e); }
  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncCustomerToGoogleSheetsSafe(env, phone);
    await syncLeadToGoogleSheetsSafe(env, phone);
    await syncSalesToGoogleSheetsSafe(env, orderId);
    await rebuildSourcePerformanceSheet(env);
  } catch (e) {
    console.error('Google Sheets sync error (manual order):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order',
      entity_id: orderId,
      action: 'manual_order_created',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }
  return jsonResponse({ success: true, orderId, total: grandTotal });
} 

 
  if (path.match(/^\/api\/orders\/[^/]+\/events$/) && method === 'GET') {
  try {
    const orderId = decodeURIComponent(path.split('/')[3]);

    const order = await env.DB.prepare(
      `SELECT order_id FROM orders WHERE order_id = ?`
    ).bind(orderId).first();

    if (!order) return errorResponse('Order not found', 404);

    let results = [];
    try {
      const query = await env.DB.prepare(`
        SELECT order_id, event_type, event_source, message, meta_json, created_at
        FROM order_events
        WHERE order_id = ?
        ORDER BY created_at DESC
      `).bind(orderId).all();

      results = query.results || [];
    } catch (dbErr) {
      console.error('Order events query error:', dbErr);
      return jsonResponse({ success: true, events: [] });
    }

    return jsonResponse({ success: true, events: results });
  } catch (e) {
    console.error('Get order events error:', e);
    return jsonResponse({ success: true, events: [] });
  }
}
    
    if (path === '/api/orders/confirm' && method === 'POST') {
  const body = await request.json();
  const { orderId, paymentId, phone } = body;
  if (!orderId || !paymentId) return errorResponse('orderId and paymentId required');

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();
  if (!order) return errorResponse('Order not found', 404);

  // Idempotent — skip if already confirmed
  if (order.payment_status === 'paid') return jsonResponse({ success: true, already: true });

  await env.DB.prepare(`
    UPDATE orders SET payment_status = 'paid', status = 'confirmed',
      payment_id = ?, updated_at = datetime('now')
    WHERE order_id = ?
  `).bind(paymentId, orderId).run();
   
   await logOrderEvent(env, orderId, 'payment_confirmed', 'Payment confirmed manually from admin/app', {
  paymentId,
  amount: order.total,
}, 'admin_manual');

  const customerName = order.customer_name || 'Customer';
  const amount = order.total;

  
  // WA confirmation to customer
  await sendWhatsAppText(env, order.phone,
    `✅ *Payment Confirmed!*\n\n` +
    `Hi ${customerName}! 🎉\n\n` +
    `Order ID: *${orderId}*\n` +
    `Amount Paid: ₹${amount}\n\n` +
    `📦 Your order is confirmed!\n` +
    `We'll pack & ship within *24 hours*.\n` +
    `Tracking details will be sent here on WhatsApp. 🚚\n\n` +
    `💎 Thank you for shopping with KAAPAV!\n` +
    `Questions? Just message us here anytime.`
  );

    // Owner WA — manual payment confirmation
  await sendWhatsAppTextOnce(
    env,
    `owner_paid_manual:${orderId}`,
    env.OWNER_PHONE,
    `💰 *Payment Confirmed (Manual)*\n\n` +
    `Order: *${orderId}*\n` +
    `Customer: ${customerName} (${order.phone})\n` +
    `Amount: ₹${amount}\n` +
    `Payment ID: ${paymentId}\n\n` +
    `✅ Order confirmed manually.\n` +
    `➡️ Next: Press Shiprocket button in app.`
  );

  // FCM push to admin Flutter app
  ctx.waitUntil(sendFCMNotification(
    env, order.phone, customerName,
    `💰 Payment done! Order ${orderId} — ₹${amount}`,
    `confirm_${paymentId}`
  ));
  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncCustomerToGoogleSheetsSafe(env, order.phone);
    await syncLeadToGoogleSheetsSafe(env, order.phone);
    await syncSalesToGoogleSheetsSafe(env, orderId);
    await rebuildSourcePerformanceSheet(env);
  } catch (e) {
    console.error('Google Sheets sync error (manual payment confirm):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order',
      entity_id: orderId,
      action: 'manual_payment_confirm',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }
  return jsonResponse({ success: true, orderId, amount });
}

    if (path === '/api/auth/login' && method === 'POST') return handleLogin(request, env);
    if (path === '/api/auth/me' && method === 'GET') {
      const user = await authMiddleware(request, env);
      if (!user) return errorResponse('Unauthorized', 401);
      return jsonResponse({ success: true, user: { id: 'admin', email: 'admin@kaapav.com', name: 'KAAPAV Admin', role: 'admin' } });
    }
    if (path === '/api/auth/refresh' && method === 'POST') {
      const payload = { userId: 'admin', email: 'admin@kaapav.com', role: 'admin', exp: Math.floor(Date.now() / 1000) + 7 * 24 * 3600 };
      const token = await generateJWT(payload, env.JWT_SECRET);
      return jsonResponse({ success: true, token });
    }

  
    // PUBLIC — no auth needed, must be BEFORE auth wall
    if (path === '/api/push/fcm-register' && method === 'POST') return handleRegisterFCM(request, env);

        const syncKey = request.headers.get('x-sync-key');
    const hasValidSyncKey = syncKey && syncKey === env.SYNC_API_KEY;

    if (path === '/api/sync/google-sheets/full-sync' && method === 'POST') {
      if (!hasValidSyncKey) return errorResponse('Unauthorized', 401);

      try {
        const summary = await backfillAllGoogleSheets(env);
        return jsonResponse({ success: true, summary });
      } catch (e) {
        console.error('Google Sheets full sync error:', e);
        return errorResponse('Full sync failed: ' + e.message, 500);
      }
    }
    
    const user = await authMiddleware(request, env);
    if (!user) return errorResponse('Unauthorized', 401);

    if (path === '/api/chats' && method === 'GET') return handleGetChats(request, env);
    if (path.match(/^\/api\/chats\/(.+)\/messages$/) && method === 'GET') {
      const phone = path.match(/^\/api\/chats\/(.+)\/messages$/)[1];
      return handleGetMessages(phone, request, env);
    }
    if (path.match(/^\/api\/chats\/(.+)\/read$/) && method === 'POST') {
      const phone = path.match(/^\/api\/chats\/(.+)\/read$/)[1];
      await env.DB.prepare(`UPDATE chats SET unread_count = 0 WHERE phone = ?`).bind(phone).run();
      return jsonResponse({ success: true });
    }
    if (path.match(/^\/api\/chats\/(.+)$/) && method === 'GET') {
      const phone = path.match(/^\/api\/chats\/(.+)$/)[1];
      const chat = await env.DB.prepare(`SELECT * FROM chats WHERE phone = ?`).bind(phone).first();
      return jsonResponse({ success: true, chat });
    }

    if (path === '/api/messages/send' && method === 'POST') return handleSendMessage(request, env);
    if (path === '/api/orders' && method === 'GET') return handleGetOrders(request, env);
     
    // GET single order
if (path.match(/^\/api\/orders\/[^/]+$/) && method === 'GET') {
  const orderId = decodeURIComponent(path.split('/')[3]);
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();
  if (!order) return errorResponse('Order not found', 404);
  // Parse JSON fields
  try { order.items = JSON.parse(order.items || '[]'); } catch {}
  return jsonResponse({ success: true, order });
}

 // ── PATCH /api/orders/:id/details — admin edit customer/shipping details ──
if (path.match(/^\/api\/orders\/[^/]+\/details$/) && method === 'PATCH') {
  const orderId = path.split('/')[3];
  const body = await request.json();

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) return errorResponse('Order not found', 404);

  const customerName    = body.customerName ?? order.customer_name ?? '';
  const phone           = body.phone ?? order.phone ?? '';
  const shippingName    = body.shippingName ?? order.shipping_name ?? customerName;
  const shippingAddress = body.shippingAddress ?? order.shipping_address ?? '';
  const shippingCity    = body.shippingCity ?? order.shipping_city ?? '';
  const shippingState   = body.shippingState ?? order.shipping_state ?? '';
  const shippingPincode = body.shippingPincode ?? order.shipping_pincode ?? '';

  await env.DB.prepare(`
    UPDATE orders SET
      customer_name = ?,
      phone = ?,
      shipping_name = ?,
      shipping_address = ?,
      shipping_city = ?,
      shipping_state = ?,
      shipping_pincode = ?,
      updated_at = datetime('now')
    WHERE order_id = ?
  `).bind(
    customerName,
    phone,
    shippingName,
    shippingAddress,
    shippingCity,
    shippingState,
    shippingPincode,
    orderId
  ).run();

  await logOrderEvent(
    env,
    orderId,
    'details_updated',
    'Order customer/shipping details updated by admin',
    {
      customerName,
      phone,
      shippingName,
      shippingAddress,
      shippingCity,
      shippingState,
      shippingPincode,
    },
    'admin'
  );

  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncCustomerToGoogleSheetsSafe(env, phone);
    await syncLeadToGoogleSheetsSafe(env, phone);
    await syncSalesToGoogleSheetsSafe(env, orderId);
   } catch (e) {
    console.error('Google Sheets sync error (order details update):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order',
      entity_id: orderId,
      action: 'details_updated',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }

  return jsonResponse({
    success: true,
    orderId,
    details: {
      customerName,
      phone,
      shippingName,
      shippingAddress,
      shippingCity,
      shippingState,
      shippingPincode,
    }
  });
}

// ── PATCH /api/orders/:id/payment — admin edit payment info ──
if (path.match(/^\/api\/orders\/[^/]+\/payment$/) && method === 'PATCH') {
  const orderId = path.split('/')[3];
  const body = await request.json();

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) return errorResponse('Order not found', 404);

  const allowedPaymentStatuses = ['paid', 'unpaid', 'refunded'];
  const paymentStatus = (body.paymentStatus ?? order.payment_status ?? 'unpaid').toLowerCase();
  const paymentId = body.paymentId ?? order.payment_id ?? '';

  if (!allowedPaymentStatuses.includes(paymentStatus)) {
    return errorResponse('Invalid paymentStatus', 400);
  }

  let nextOrderStatus = order.status;

  if (paymentStatus === 'paid' && (order.status === 'pending' || order.status === 'cancelled')) {
    nextOrderStatus = 'confirmed';
  }
  if (paymentStatus === 'unpaid' && order.status === 'confirmed') {
    nextOrderStatus = 'pending';
  }

  await env.DB.prepare(`
    UPDATE orders SET
      payment_status = ?,
      payment_id = ?,
      status = ?,
      paid_at = CASE WHEN ? = 'paid' THEN COALESCE(paid_at, datetime('now')) ELSE paid_at END,
      updated_at = datetime('now')
    WHERE order_id = ?
  `).bind(
    paymentStatus,
    paymentId,
    nextOrderStatus,
    paymentStatus,
    orderId
  ).run();

  await logOrderEvent(
    env,
    orderId,
    'payment_updated',
    'Order payment details updated by admin',
    {
      paymentStatus,
      paymentId,
      orderStatus: nextOrderStatus,
    },
    'admin'
  );

  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncCustomerToGoogleSheetsSafe(env, order.phone);
    await syncLeadToGoogleSheetsSafe(env, order.phone);
    await syncSalesToGoogleSheetsSafe(env, orderId);
    await rebuildSourcePerformanceSheet(env);
  } catch (e) {
    console.error('Google Sheets sync error (order payment update):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order',
      entity_id: orderId,
      action: 'payment_updated',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }
  return jsonResponse({
    success: true,
    orderId,
    paymentStatus,
    paymentId,
    status: nextOrderStatus,
  });
}

// ── PATCH /api/orders/:id/cancel — admin cancel with reason ──
if (path.match(/^\/api\/orders\/[^/]+\/cancel$/) && method === 'PATCH') {
  const orderId = path.split('/')[3];
  const body = await request.json();
  const reason = body.reason || 'Cancelled by admin';

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) return errorResponse('Order not found', 404);

  await env.DB.prepare(`
    UPDATE orders SET
      status = 'cancelled',
      cancellation_reason = ?,
      cancelled_at = datetime('now'),
      updated_at = datetime('now')
    WHERE order_id = ?
  `).bind(reason, orderId).run();

  await logOrderEvent(
    env,
    orderId,
    'order_cancelled',
    'Order cancelled by admin',
    { reason },
    'admin'
  );

  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncCustomerToGoogleSheetsSafe(env, order.phone);
    await syncLeadToGoogleSheetsSafe(env, order.phone);
    await syncSalesToGoogleSheetsSafe(env, orderId);
    await rebuildSourcePerformanceSheet(env);
  } catch (e) {
    console.error('Google Sheets sync error (order cancel):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order',
      entity_id: orderId,
      action: 'order_cancelled',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }
  return jsonResponse({
    success: true,
    orderId,
    status: 'cancelled',
    reason,
  });
}



// PUT order status (fixed — moved here after auth, uses proper body read)
if (path.match(/^\/api\/orders\/[^/]+\/status$/) && method === 'PUT') {
  const orderId = path.split('/')[3];
  const bodyData = await request.json();
  const { status } = bodyData;
  const allowed = ['pending','confirmed','processing','shipped','delivered','cancelled'];
  if (!allowed.includes(status)) return errorResponse('Invalid status', 400);
  await env.DB.prepare(
    `UPDATE orders SET status = ?, updated_at = datetime('now') WHERE order_id = ?`
  ).bind(status, orderId).run();

  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncShipmentToGoogleSheetsSafe(env, orderId);

    const order = await env.DB.prepare(
      `SELECT * FROM orders WHERE order_id = ?`
    ).bind(orderId).first();

    if (order?.phone) {
      await syncCustomerToGoogleSheetsSafe(env, order.phone);
      await syncLeadToGoogleSheetsSafe(env, order.phone);
    }

    await syncSalesToGoogleSheetsSafe(env, orderId);
    await rebuildSourcePerformanceSheet(env);
  } catch (e) {
    console.error('Google Sheets sync error (order status update):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'order',
      entity_id: orderId,
      action: 'status_updated',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }

  return jsonResponse({ success: true, orderId, status });
}

// POST manual order (from Flutter admin app — Issue 4)
if (path === '/api/orders/manual' && method === 'POST') {
  const b = await request.json();
  const { name, phone, address, city, state: st, pincode, notes, items, email, source } = b;
  if (!phone || !name) return errorResponse('name and phone required');

  const itemsArr = Array.isArray(items) && items.length > 0 ? items : [];
  const subtotal = itemsArr.length > 0
    ? itemsArr.reduce((s, i) => s + ((i.price || 0) * (i.qty || 1)), 0)
    : (parseFloat(b.total) || 0);
  const shipping = subtotal >= 498 ? 0 : 60;
  const grandTotal = subtotal + shipping;
  const orderId = await generateOrderId(env);

  await env.DB.prepare(`
    INSERT INTO orders (
      order_id, phone, customer_name, items, item_count,
      subtotal, shipping_cost, total,
      shipping_name, shipping_address, shipping_city, shipping_state, shipping_pincode,
      customer_notes, status, payment_status, source, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'unpaid', ?, datetime('now'), datetime('now'))
  `).bind(
    orderId, phone, name,
    JSON.stringify(itemsArr),
    itemsArr.length || 1,
    subtotal, shipping, grandTotal,
    name, address || '', city || '', st || '', pincode || '',
    notes || '',
    source || 'manual'
  ).run();

  // Upsert customer
  await env.DB.prepare(`
    INSERT INTO customers (phone, name, first_seen, last_seen, updated_at)
    VALUES (?, ?, datetime('now'), datetime('now'), datetime('now'))
    ON CONFLICT(phone) DO UPDATE SET
      name = excluded.name, last_seen = datetime('now'), updated_at = datetime('now')
  `).bind(phone, name).run();

  return jsonResponse({ success: true, orderId, total: grandTotal });
}

// POST order notify — send WA message for order/shipping/delivery
if (path.match(/^\/api\/orders\/[^/]+\/send-notification$/) && method === 'POST') {
  const orderId = path.split('/')[3];
  const { type } = await request.json();
  const order = await env.DB.prepare(`SELECT * FROM orders WHERE order_id = ?`).bind(orderId).first();
  if (!order) return errorResponse('Order not found', 404);
  const name = order.customer_name || 'Customer';
  const msgs = {
    confirmed: `✅ *Order Confirmed!*\n\nHi ${name}! Your order *${orderId}* is confirmed.\n\n📦 We'll pack & ship within 24 hours.\n💎 KAAPAV Fashion Jewellery`,
    shipped:   `🚚 *Your Order is Shipped!*\n\nHi ${name}! Order *${orderId}* is on its way!\n\nTracking: ${order.tracking_id || 'Details coming soon'}\n\nDelivery in 2–4 working days. 💎`,
    delivered: `📦 *Order Delivered!*\n\nHi ${name}! Hope you love your KAAPAV jewellery! ✨\n\nOrder: *${orderId}*\n\nPlease share your unboxing! 💎`,
  };
  const msg = msgs[type];
  if (!msg) return errorResponse('Invalid type — use confirmed/shipped/delivered');
  await sendWhatsAppText(env, order.phone, msg);
  return jsonResponse({ success: true });
}
    // PATCH /api/orders/:id/notes
if (path.match(/^\/api\/orders\/[^/]+\/notes$/) && method === 'PATCH') {
  const orderId = path.split('/')[3];
  const { notes } = await request.json();
  await env.DB.prepare(
    `UPDATE orders SET internal_notes = ?, updated_at = datetime('now') WHERE order_id = ?`
  ).bind(notes || '', orderId).run();
  return jsonResponse({ success: true });
}

// ── POST /api/orders/:id/ship — Book Shiprocket + notify customer + owner ──
if (path.match(/^\/api\/orders\/[^/]+\/ship$/) && method === 'POST') {
  const orderId = path.split('/')[3];

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) return errorResponse('Order not found', 404);

  // Guard: only confirmed + paid orders can be shipped
  if (order.payment_status !== 'paid') {
    return errorResponse('Order is not paid yet', 400);
  }
  if (order.status === 'shipped' || order.status === 'delivered') {
    return errorResponse('Order already shipped', 400);
  }

  // Parse items
  let items = [];
  try { items = JSON.parse(order.items || '[]'); } catch(e) {}

  const customerName = order.customer_name || 'Customer';
  const phone        = order.phone;

  // Book Shiprocket
  let srOrderId = null;
  let srError   = null;

  try {
    const srData = await createShiprocketOrder(env, {
      order: {
        orderNumber: orderId,
        total: order.total,
      },
      customer: {
        name:    customerName,
        phone:   phone,
        address: order.shipping_address || '',
        city:    order.shipping_city    || 'Delhi',
        state:   order.shipping_state   || 'Delhi',
        pincode: order.shipping_pincode || '110001',
      },
      items: items.map(i => ({
        name:  i.name,
        sku:   i.sku,
        qty:   i.qty   || 1,
        price: i.price || 0,
      })),
    });

    if (srData.order_id) {
      srOrderId = String(srData.order_id);

      // Update order in D1
      await env.DB.prepare(`
        UPDATE orders SET
          shiprocket_order_id = ?,
          status              = 'processing',
          updated_at          = datetime('now')
        WHERE order_id = ?
      `).bind(srOrderId, orderId).run();

      await logOrderEvent(env, orderId, 'shiprocket_booked', 'Shiprocket booked successfully', {
  shiprocketOrderId: srOrderId,
}, 'admin');
      try {
        await syncOrderToGoogleSheetsSafe(env, orderId);
        await syncShipmentToGoogleSheetsSafe(env, orderId);
        await syncCustomerToGoogleSheetsSafe(env, phone);
        await syncLeadToGoogleSheetsSafe(env, phone);
        await syncSalesToGoogleSheetsSafe(env, orderId);
      } catch (e) {
        console.error('Google Sheets sync error (shiprocket booked):', e);
        await appendSyncFailureToGoogleSheets(env, {
          destination: 'google_sheets',
          entity_type: 'shipment',
          entity_id: orderId,
          action: 'shiprocket_booked',
          error_message: e.message,
          retry_count: 0,
          status: 'failed',
        });
      }

      // Build item lines for messages
      const itemLines = items.length > 0
        ? items.map(i =>
            `\u2022 ${i.name} \u00d7${i.qty || 1} \u2014 \u20B9${(i.price || 0) * (i.qty || 1)}`
          ).join('\n')
        : '\u2022 (items not available)';

      // Customer WA \u2014 order being packed
      await sendWhatsAppText(env, phone,
        `\ud83d\udce6 *Your Order is Being Packed!*\n\n` +
        `Hi ${customerName.split(' ')[0]}! \ud83c\udf89\n\n` +
        `Order ID: *${orderId}*\n\n` +
        `\ud83d\udee0\ufe0f *Items being packed:*\n${itemLines}\n\n` +
        `\u23f0 Shipping within *24 hours*\n` +
        `\ud83de\ude9a Delivery in *2\u20134 working days*\n\n` +
        `You will receive your tracking details here on WhatsApp once shipped! \ud83d\udccd\n\n` +
        `\ud83d\udcac Questions? Just message us anytime \ud83d\ude0a\n` +
        `\ud83d\udca0 KAAPAV Fashion Jewellery`
      );

      // Owner WA \u2014 Shiprocket booked confirmation
      await sendWhatsAppText(env, env.OWNER_PHONE,
        `\u2705 *Shiprocket Order Created!*\n\n` +
        `Order: *${orderId}*\n` +
        `Shiprocket ID: *${srOrderId}*\n` +
        `Customer: ${customerName} (${phone})\n` +
        `Amount: \u20B9${order.total}\n\n` +
        `\ud83d\udce6 *Items:*\n${itemLines}\n\n` +
        `\ud83d\udccd Address: ${order.shipping_address || '-'}, ${order.shipping_city || '-'} \u2014 ${order.shipping_pincode || '-'}\n\n` +
        `\u27a1\ufe0f Next: Open Shiprocket dashboard \u2192 assign AWB \u2192 press AWB button in app.`
      );

      return jsonResponse({
        success:       true,
        shiprocketOrderId: srOrderId,
        message:       'Shiprocket order created successfully',
      });

    } else {
      // Shiprocket returned no order_id — log the error
      srError = srData.message || srData.error || JSON.stringify(srData);
console.error('Shiprocket no order_id:', srError);

await notifyOwnerFailure(env, 'Shiprocket Booking Failed', [
  `Order: *${orderId}*`,
  `Customer: ${customerName} (${phone})`,
  `Error: ${srError}`,
]);

return errorResponse(`Shiprocket booking failed: ${srError}`, 502);
    }

  } catch(e) {
  console.error('Shiprocket ship error:', e);
  

  await notifyOwnerFailure(env, 'Shiprocket Error', [
    `Order: *${orderId}*`,
    `Customer: ${customerName} (${phone})`,
    `Error: ${e.message}`,
  ]);

  return errorResponse(`Shiprocket error: ${e.message}`, 500);
}
}

    // ── PUT /api/orders/:id/awb — save AWB + send tracking WA ──
if (path.match(/^\/api\/orders\/[^/]+\/awb$/) && method === 'PUT') {
  const orderId = path.split('/')[3];
  const { awb, courier } = await request.json();
  if (!awb) return errorResponse('awb required');

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();
  if (!order) return errorResponse('Order not found', 404);

  await env.DB.prepare(`
    UPDATE orders SET
      awb_number = ?, courier = ?,
      tracking_url = ?,
      status = 'shipped', shipped_at = datetime('now'),
      updated_at = datetime('now')
    WHERE order_id = ?
  `).bind(
    awb,
    courier || 'Shiprocket',
    `https://www.shiprocket.in/shipment-tracking/?id=${awb}`,
    orderId
  ).run();

  await logOrderEvent(env, orderId, 'awb_assigned', 'AWB assigned and customer notified', {
  awb,
  courier: courier || 'Shiprocket',
}, 'admin');
  try {
    await syncOrderToGoogleSheetsSafe(env, orderId);
    await syncShipmentToGoogleSheetsSafe(env, orderId);
    await syncCustomerToGoogleSheetsSafe(env, order.phone);
    await syncLeadToGoogleSheetsSafe(env, order.phone);
    await syncSalesToGoogleSheetsSafe(env, orderId);
  } catch (e) {
    console.error('Google Sheets sync error (awb assigned):', e);
    await appendSyncFailureToGoogleSheets(env, {
      destination: 'google_sheets',
      entity_type: 'shipment',
      entity_id: orderId,
      action: 'awb_assigned',
      error_message: e.message,
      retry_count: 0,
      status: 'failed',
    });
  }

  const name = order.customer_name || 'Customer';

  // Customer WA with tracking
  await sendWhatsAppText(env, order.phone,
    `🚚 *Your Order is Shipped!*\n\n` +
    `Hi ${name}! 🎉\n\n` +
    `Order ID: *${orderId}*\n` +
    `AWB: *${awb}*\n` +
    `Courier: ${courier || 'Shiprocket'}\n\n` +
    `📍 *Track your order:*\n` +
    `https://www.shiprocket.in/shipment-tracking/?id=${awb}\n\n` +
    `Estimated delivery: *2–4 working days*\n\n` +
    `💎 KAAPAV Fashion Jewellery`
  );

  // Owner WA
  await sendWhatsAppText(env, env.OWNER_PHONE,
    `🚚 *AWB Updated*\n\n` +
    `Order: *${orderId}*\n` +
    `Customer: ${name} (${order.phone})\n` +
    `AWB: *${awb}*\n\n` +
    `✅ Customer notified on WhatsApp.`
  );

  return jsonResponse({ success: true });
}


// ── POST /api/orders/:id/payment-link — regenerate Razorpay link ──
if (path.match(/^\/api\/orders\/[^/]+\/payment-link$/) && method === 'POST') {
  const orderId = path.split('/')[3];

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) return errorResponse('Order not found', 404);

  try {
    const cleanPhone = String(order.phone || '').replace(/\D/g, '');
    if (cleanPhone.length < 10) {
      return errorResponse('Invalid customer phone number', 400);
    }

    const amount = Number(order.total || 0);
    if (!amount || amount <= 0) {
      return errorResponse('Invalid order amount', 400);
    }

    const payLink = await createRazorpayLink(env, {
      amount,
      name: order.customer_name || 'Customer',
      phone: cleanPhone,
      orderId,
      description: `KAAPAV Order ${orderId}`
    });

    await env.DB.prepare(`
      UPDATE orders SET payment_link = ?, updated_at = datetime('now')
      WHERE order_id = ?
    `).bind(payLink, orderId).run();

    await logOrderEvent(
      env,
      orderId,
      'payment_link_generated',
      'Payment link generated and sent to customer',
      { paymentLink: payLink },
      'admin'
    );

    // Send to customer
    await sendWhatsAppText(env, order.phone,
      `💳 *Payment Link*\n\n` +
      `Hi ${order.customer_name || 'Customer'}!\n\n` +
      `Order ID: *${orderId}*\n` +
      `Amount: ₹${order.total}\n\n` +
      `👉 Pay here (valid 24 hrs):\n${payLink}\n\n` +
      `💎 KAAPAV Fashion Jewellery`
    );

    return jsonResponse({ success: true, paymentLink: payLink });

  } catch (e) {
    console.error('Payment link generation error:', e);

    await notifyOwnerFailure(env, 'Payment Link Generation Failed', [
      `Order: *${orderId}*`,
      `Customer: ${order.customer_name || 'Customer'} (${order.phone || '-'})`,
      `Amount: ₹${order.total || 0}`,
      `Error: ${e.message}`,
    ]);

    return errorResponse('Failed to generate link: ' + e.message, 500);
  }
}

// ── POST /api/orders/:id/return — mark return requested ──
if (path.match(/^\/api\/orders\/[^/]+\/return$/) && method === 'POST') {
  const orderId = path.split('/')[3];
  const { reason } = await request.json();
  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();
  if (!order) return errorResponse('Order not found', 404);

  await env.DB.prepare(`
    UPDATE orders SET
      return_requested = 1,
      return_reason = ?,
      return_requested_at = datetime('now'),
      status = 'cancelled',
      updated_at = datetime('now')
    WHERE order_id = ?
  `).bind(reason || 'Return requested', orderId).run();

  await logOrderEvent(env, orderId, 'return_requested', 'Order-level return requested', {
  reason: reason || 'Return requested',
}, 'customer');

  const name = order.customer_name || 'Customer';

  // Customer WA
  await sendWhatsAppText(env, order.phone,
    `🔄 *Return Request Received*\n\n` +
    `Hi ${name}!\n\n` +
    `Order ID: *${orderId}*\n` +
    `Reason: ${reason || 'Return requested'}\n\n` +
    `📋 *Next steps:*\n` +
    `1. Record unboxing video (mandatory)\n` +
    `2. Keep item unused & in original packaging\n` +
    `3. We'll arrange reverse pickup within 24 hrs\n\n` +
    `⚠️ ₹60/- reverse shipping will be deducted\n` +
    `💰 Refund in 5–7 working days after QC\n\n` +
    `Questions? Just message us here 😊\n` +
    `💎 KAAPAV Fashion Jewellery`
  );

  // Owner WA
  await sendWhatsAppText(env, env.OWNER_PHONE,
    `🔄 *Return Requested!*\n\n` +
    `Order: *${orderId}*\n` +
    `Customer: ${name} (${order.phone})\n` +
    `Amount: ₹${order.total}\n` +
    `Reason: ${reason || 'Not specified'}\n\n` +
    `⚠️ Action needed: Arrange reverse pickup.`
  );

  return jsonResponse({ success: true });
}


if (path.match(/^\/api\/orders\/[^/]+\/item-return$/) && method === 'POST') {
  const orderId = path.split('/')[3];
  const { sku, reason } = await request.json();

  if (!sku) return errorResponse('sku required');

  const order = await env.DB.prepare(
    `SELECT * FROM orders WHERE order_id = ?`
  ).bind(orderId).first();

  if (!order) return errorResponse('Order not found', 404);

  let items = [];
  try { items = JSON.parse(order.items || '[]'); } catch(e) {}

  const item = items.find(i => i.sku === sku);
  if (!item) return errorResponse('Item not found in order', 404);

  await env.DB.prepare(`
    INSERT INTO return_requests (
      order_id, phone, sku, item_name, reason, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, 'requested', datetime('now'), datetime('now'))
  `).bind(
    orderId,
    order.phone,
    sku,
    item.name || '',
    reason || 'Item return requested'
  ).run();

  await sendWhatsAppText(env, order.phone,
    `🔄 *Item Return Request Received*\n\n` +
    `Order ID: *${orderId}*\n` +
    `Item: *${item.name || sku}*\n` +
    `Reason: ${reason || 'Not specified'}\n\n` +
    `Our team will review and contact you shortly.\n\n` +
    `💎 KAAPAV Fashion Jewellery`
  );

  await sendWhatsAppText(env, env.OWNER_PHONE,
    `🔄 *Item Return Requested*\n\n` +
    `Order: *${orderId}*\n` +
    `Customer: ${order.customer_name || 'Customer'} (${order.phone})\n` +
    `Item: *${item.name || sku}*\n` +
    `Reason: ${reason || 'Not specified'}`
  );

  return jsonResponse({ success: true });
}

// ── GET /api/customers/:phone/orders — customer order history ──
if (path.match(/^\/api\/customers\/[^/]+\/orders$/) && method === 'GET') {
  const phone = decodeURIComponent(path.split('/')[3]);
  const { results } = await env.DB.prepare(`
    SELECT order_id, status, payment_status, total, items,
           created_at, shipping_pincode
    FROM orders WHERE phone = ?
    ORDER BY created_at DESC LIMIT 20
  `).bind(phone).all();
  return jsonResponse({ success: true, orders: results });
}

    if (path === '/api/products' && method === 'GET') return handleGetProducts(request, env);
    if (path === '/api/products/send' && method === 'POST') return handleSendProduct(request, env);
    if (path === '/api/products' && method === 'POST') return handleCreateProduct(request, env);
    if (path.match(/^\/api\/products\/(.+)\/stock$/) && (method === 'PATCH' || method === 'POST')) {
      const sku = path.match(/^\/api\/products\/(.+)\/stock$/)[1];
      return handleUpdateStock(sku, request, env);
    }
    if (path.match(/^\/api\/products\/(.+)$/) && method === 'PUT') {
      const sku = path.match(/^\/api\/products\/(.+)$/)[1];
      return handleUpdateProduct(sku, request, env);
    }
    if (path.match(/^\/api\/products\/(.+)$/) && method === 'DELETE') {
      const sku = path.match(/^\/api\/products\/(.+)$/)[1];
      return handleDeleteProduct(sku, env);
    }
    if (path === '/api/products/categories' && method === 'GET') {
      const { results } = await env.DB.prepare(`SELECT DISTINCT category FROM products WHERE is_active=1 AND category IS NOT NULL`).all();
      return jsonResponse({ success: true, categories: results.map(r => r.category) });
    }
    if (path === '/api/customers' && method === 'GET') return handleGetCustomers(request, env);
    if (path.match(/^\/api\/customers\/(.+)$/) && method === 'GET') {
      const phone = path.match(/^\/api\/customers\/(.+)$/)[1];
      const customer = await env.DB.prepare(`SELECT * FROM customers WHERE phone = ?`).bind(phone).first();
      return jsonResponse({ success: true, customer });
    }

    if (path === '/api/stats' && method === 'GET') return handleGetStats(env);
    if (path === '/api/dashboard/ops' && method === 'GET') return handleGetDashboardOps(env);
    if (path === '/api/analytics' && method === 'GET') return handleGetAnalytics(env);
    if (path === '/api/analytics/activities' && method === 'GET') return handleGetActivities(env);
    if (path === '/api/analytics/pending' && method === 'GET') {
      const { results } = await env.DB.prepare(`SELECT * FROM orders WHERE status='pending' ORDER BY created_at DESC LIMIT 20`).all();
      return jsonResponse({ success: true, pending: results });
    }

    if (path === '/api/settings' && method === 'GET') return handleGetSettings(env);
    if (path === '/api/settings' && method === 'PUT') {
      const body = await request.json();
      for (const [key, value] of Object.entries(body)) {
        await env.DB.prepare(`INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, datetime('now'))`).bind(key, String(value)).run();
      }
      return jsonResponse({ success: true });
    }

    if (path === '/api/quick-replies' && method === 'GET') {
      const { results } = await env.DB.prepare(`SELECT * FROM quick_replies WHERE is_active=1 ORDER BY use_count DESC`).all();
      return jsonResponse({ success: true, quickReplies: results });
    }
    if (path === '/api/labels' && method === 'GET') {
      const { results } = await env.DB.prepare(`SELECT * FROM labels WHERE is_active=1`).all();
      return jsonResponse({ success: true, labels: results });
    }
    if (path === '/api/templates' && method === 'GET') {
      const { results } = await env.DB.prepare(`SELECT * FROM templates ORDER BY created_at DESC`).all();
      return jsonResponse({ success: true, templates: results });
    }

    if (path === '/api/sync/check' && method === 'GET') return handleSyncCheck(env);
    if (path === '/api/settings/test-whatsapp' && method === 'POST') {
      const body = await request.json().catch(() => ({}));
      const phone = body.phone;
      if (!phone) return errorResponse('phone required', 400);

      const result = await sendWhatsAppText(env, phone, 'Test message from KAAPAV Worker');
      if (result?.error) {
        return errorResponse(result.error.message || 'WhatsApp send failed', 502);
      }

      return jsonResponse({ success: true, result });
    }

    if (path === '/api/media/upload' && method === 'POST') {
      try {
        const formData = await request.formData();
        const file = formData.get('file');
        if (!file) return errorResponse('file required', 400);
        const fileName = `${Date.now()}_${file.name || 'upload'}`;
        const arrayBuffer = await file.arrayBuffer();
        await env.MEDIA.put(fileName, arrayBuffer, {
          httpMetadata: { contentType: file.type || 'application/octet-stream' },
        });
        const url = `https://pub-e8a17aa027ff420f83623e808512141f.r2.dev/${fileName}`;
        return jsonResponse({ success: true, url, mediaUrl: url, fileName });
      } catch (e) {
        console.error('Upload error:', e);
        return errorResponse('Upload failed: ' + e.message, 500);
      }
    }
    
    return errorResponse('Not found', 404);
  },

  async scheduled(event, env, ctx) {
  // ── Abandoned payment reminder (30 min after order, unpaid) ─
try {
  const thirtyMinAgo = new Date(Date.now() - 30 * 60 * 1000).toISOString();
  const fortyMinAgo = new Date(Date.now() - 40 * 60 * 1000).toISOString();

  const { results: earlyUnpaidOrders } = await env.DB.prepare(`
    SELECT * FROM orders
    WHERE payment_status = 'unpaid'
    AND status = 'pending'
    AND payment_link IS NOT NULL
    AND created_at BETWEEN ? AND ?
    LIMIT 10
  `).bind(fortyMinAgo, thirtyMinAgo).all();

  for (const order of earlyUnpaidOrders) {
    await sendWhatsAppText(env, order.phone,
      `💎 *Complete Your KAAPAV Order*\n\n` +
      `Hi ${order.customer_name || 'there'}! 😊\n\n` +
      `Order ID: *${order.order_id}*\n` +
      `Amount: ₹${order.total}\n\n` +
      `💳 Payment link:\n${order.payment_link}\n\n` +
      `Your jewellery is waiting for you ✨`
    );
  }
} catch(e) {
  console.error('30-min payment reminder error:', e);
}
    console.log('Cron running:', new Date().toISOString());

        try {
      const nowUtc = new Date();
      const minuteUtc = nowUtc.getUTCMinutes();

      // Google Sheets reconciliation once per hour
      if (minuteUtc < 5) {
        await backfillAllGoogleSheets(env);
        console.log('Google Sheets hourly reconciliation complete');
      }
    } catch (e) {
      console.error('Google Sheets reconciliation error:', e);
      await appendSyncFailureToGoogleSheets(env, {
        destination: 'google_sheets',
        entity_type: 'system',
        entity_id: 'full_sync',
        action: 'cron_reconciliation',
        error_message: e.message,
        retry_count: 0,
        status: 'failed',
      });
    }

    const now = new Date();
    const hourIST = (now.getUTCHours() + 5) % 24;
    const minuteIST = (now.getUTCMinutes() + 30) % 60;

    // ── Daily summary at 9pm IST ──────────────────────────────
    if (hourIST === 21 && minuteIST < 5) {
      try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayStr = today.toISOString().slice(0, 10);

        const [todayOrders, pendingOrders, revenue, totalOrders] = await Promise.all([
          env.DB.prepare(`SELECT COUNT(*) as count FROM orders WHERE date(created_at) = ?`).bind(todayStr).first(),
          env.DB.prepare(`SELECT COUNT(*) as count FROM orders WHERE status = 'pending'`).first(),
          env.DB.prepare(`SELECT SUM(total) as total FROM orders WHERE payment_status = 'paid' AND date(created_at) = ?`).bind(todayStr).first(),
          env.DB.prepare(`SELECT COUNT(*) as count FROM orders`).first(),
        ]);

        await sendWhatsAppText(env, env.OWNER_PHONE,
          `📊 *KAAPAV Daily Summary*\n` +
          `📅 ${todayStr}\n\n` +
          `🛍️ Today's Orders: *${todayOrders?.count || 0}*\n` +
          `💰 Today's Revenue: *₹${revenue?.total || 0}*\n` +
          `⏳ Pending Orders: *${pendingOrders?.count || 0}*\n` +
          `📦 Total Orders Ever: *${totalOrders?.count || 0}*\n\n` +
          `💎 KAAPAV Fashion Jewellery`
        );
      } catch(e) { console.error('Daily summary error:', e); }
    }

    // ── Post-delivery review request (3 days after delivered) ─
    try {
      const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString();
      const oneDayAgo = new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString();
      const { results: deliveredOrders } = await env.DB.prepare(`
        SELECT * FROM orders
        WHERE status = 'delivered'
        AND review_sent = 0
        AND delivered_at BETWEEN ? AND ?
        LIMIT 10
      `).bind(oneDayAgo, threeDaysAgo).all();

      for (const order of deliveredOrders) {
        await sendWhatsAppText(env, order.phone,
          `💎 *How was your KAAPAV order?*\n\n` +
          `Hi ${order.customer_name || 'there'}! 😊\n\n` +
          `We hope you love your jewellery! ✨\n\n` +
          `🌟 *We'd love your feedback:*\n` +
          `📸 Share your unboxing on Instagram\n` +
          `🏷️ Tag us: @kaapavfashionjewellery\n\n` +
          `⭐ Your review helps us grow!\n\n` +
          `👉 ${env.INSTAGRAM_URL}\n\n` +
          `💎 Thank you for choosing KAAPAV!`
        );
        await env.DB.prepare(
          `UPDATE orders SET review_sent = 1, updated_at = datetime('now') WHERE order_id = ?`
        ).bind(order.order_id).run();
      }
    } catch(e) { console.error('Review request error:', e); }

    // ── Abandoned payment recovery (2 hrs after order, unpaid) ─
    try {
      const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();
      const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString();
      const { results: unpaidOrders } = await env.DB.prepare(`
        SELECT * FROM orders
        WHERE payment_status = 'unpaid'
        AND status = 'pending'
        AND payment_link IS NOT NULL
        AND created_at BETWEEN ? AND ?
        LIMIT 10
      `).bind(threeHoursAgo, twoHoursAgo).all();

      for (const order of unpaidOrders) {
        // Check if link still valid (created < 22hrs ago)
        await sendWhatsAppText(env, order.phone,
          `⏰ *Complete your KAAPAV order!*\n\n` +
          `Hi ${order.customer_name || 'there'}! 😊\n\n` +
          `You left something behind! 💎\n\n` +
          `Order ID: *${order.order_id}*\n` +
          `Amount: ₹${order.total}\n\n` +
          `💳 *Complete payment here:*\n` +
          `${order.payment_link}\n\n` +
          `⚠️ Link expires in a few hours!\n\n` +
          `Questions? Just reply here 😊\n` +
          `💎 KAAPAV Fashion Jewellery`
        );
      }
    } catch(e) { console.error('Cart recovery error:', e); }
  }
  
};