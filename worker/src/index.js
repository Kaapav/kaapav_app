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
  const expiry = Math.floor(Date.now() / 1000) + 86400; // 24 hours
  const res = await fetch('https://api.razorpay.com/v1/payment_links', {
    method: 'POST',
    headers: { 'Authorization': `Basic ${auth}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      amount: Math.round(amount * 100), // paise
      currency: 'INR',
      description,
      customer: { name, contact: `+91${phone.replace(/\D/g,'')}` },
      notify: { sms: true, whatsapp: false },
      reminder_enable: true,
      expire_by: expiry,
      reference_id: orderId,
      callback_url: `https://wa.kaapav.com/api/payment/callback`,
      callback_method: 'get',
    })
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.description || 'Razorpay error');
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

    if (msg.type === 'text') text = msg.text?.body || '';
    else if (msg.type === 'interactive') {
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

    await env.DB.prepare(`
      INSERT OR IGNORE INTO messages (message_id, phone, text, message_type, direction, button_id, button_text, status, timestamp, created_at)
      VALUES (?, ?, ?, ?, 'incoming', ?, ?, 'delivered', ?, datetime('now'))
    `).bind(messageId, phone, text, messageType, buttonId, buttonText, timestamp).run();

    await env.DB.prepare(`
      INSERT INTO chats (phone, customer_name, last_message, last_message_type, last_timestamp, last_direction, unread_count, total_messages, updated_at)
      VALUES (?, ?, ?, ?, ?, 'incoming', 1, 1, datetime('now'))
      ON CONFLICT(phone) DO UPDATE SET
        customer_name = excluded.customer_name,
        last_message = excluded.last_message,
        last_message_type = excluded.last_message_type,
        last_timestamp = excluded.last_timestamp,
        last_direction = 'incoming',
        unread_count = unread_count + 1,
        total_messages = total_messages + 1,
        updated_at = datetime('now')
    `).bind(phone, name, text || messageType, messageType, timestamp).run();

    await env.DB.prepare(`
      INSERT INTO customers (phone, name, message_count, first_seen, last_seen, updated_at)
      VALUES (?, ?, 1, datetime('now'), datetime('now'), datetime('now'))
      ON CONFLICT(phone) DO UPDATE SET
        name = excluded.name,
        message_count = message_count + 1,
        last_seen = datetime('now'),
        updated_at = datetime('now')
    `).bind(phone, name).run();

    console.log('Calling FCM with messageId:', messageId);
    ctx.waitUntil(sendFCMNotification(env, phone, name, text, messageId));

    try {
      const autoResponder = new AutoResponder(env);
      await autoResponder.process({ phone, name, text, messageType, buttonId, messageId });
    } catch (e) { console.error('Autoresponder error:', e); }

    return jsonResponse({ status: 'ok' });
  } catch (e) {
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

async function handleCreateProduct(request, env) {
  const body = await request.json();
  const { sku, name, category, price, compare_price, description, stock, image_url, is_active, is_featured, tags, website_link, material } = body;
  if (!sku || !name || !price) return errorResponse('sku, name, price required');
  await env.DB.prepare(`
    INSERT OR REPLACE INTO products (sku, name, category, price, compare_price, description, stock, image_url, is_active, is_featured, tags, website_link, material, updated_at, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
  `).bind(sku, name, category || 'bracelet', price, compare_price || 0, description || '', stock || 0, image_url || '', is_active ?? 1, is_featured ?? 0, JSON.stringify(tags || []), website_link || '', material || '').run();
  return jsonResponse({ success: true });
}

async function handleUpdateProduct(sku, request, env) {
  const body = await request.json();
  const fields = [];
  const values = [];
  const allowed = ['name','category','price','compare_price','description','stock','image_url','is_active','is_featured','tags','website_link','material'];
  for (const key of allowed) {
    if (body[key] !== undefined) {
      fields.push(`${key} = ?`);
      values.push(key === 'tags' ? JSON.stringify(body[key]) : body[key]);
    }
  }
  if (fields.length === 0) return errorResponse('nothing to update');
  fields.push(`updated_at = datetime('now')`);
  values.push(sku);
  await env.DB.prepare(`UPDATE products SET ${fields.join(', ')} WHERE sku = ?`).bind(...values).run();
  return jsonResponse({ success: true });
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
    if (/^(hi|hello|hey|helo|hii|hiii|namaste|namaskar|jai|ram|shri|good\s*(morning|evening|afternoon|night))/.test(inputLower)) {
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
      'btn_shop':         'SHOP_MENU',
      'btn_offers':       'OFFERS_MENU',
      'btn_help':         'HELP_PROMPT',

      // Shop menu buttons
      'btn_website':      'OPEN_WEBSITE',
      'btn_catalogue':    'OPEN_CATALOG',
      'btn_shop_back':    'MAIN_MENU',

      // Offers menu buttons
      'btn_deals':        'DEALS_MENU',
      'btn_pay_track':    'PAY_TRACK_MENU',
      'btn_offers_back':  'MAIN_MENU',

      // Deals menu buttons
      'btn_bestsellers':  'OPEN_BESTSELLERS',
      'btn_shop_now':     'OPEN_WEBSITE',
      'btn_deals_back':   'OFFERS_MENU',

      // Pay & Track menu buttons
      'btn_pay_now':      'PAY_NOW',
      'btn_track_order':  'TRACK_ORDER',
      'btn_paytrack_back':'OFFERS_MENU',

      // Help prompt buttons
      'btn_browse':       'BROWSE_TOPICS',
      'btn_help_back':    'MAIN_MENU',

      // Post-FAQ buttons
      'faq_more':         null, // handled separately above
      'faq_order':        null, // handled separately above
      'faq_home':         null, // handled separately above
    };
    return MAP[id] ?? null;
  }

  // ── TEXT TRIGGER → ACTION MAP ──────────────────────────────────
  resolveTextTrigger(inputLower) {
    // ORDER FLOW — text trigger only (as per spec)
    if (/order\s*karn[ae]|order\s*dena|order\s*chahiye|mujhe\s*order|place\s*order|i\s*want\s*to\s*order|buy\s*karna|kharidna\s*hai/.test(inputLower)) {
      return 'ORDER_FLOW';
    }
      // Category browsing
    if (/bracelet|bangle|kada|kara|bangles/.test(inputLower)) return 'CAT_BRACELET';
    if (/necklace|haar|chain|mala|necklac/.test(inputLower)) return 'CAT_NECKLACE';
    if (/earring|jhumka|bali|stud|tops|jhumke/.test(inputLower)) return 'CAT_EARRINGS';
    if (/pendant\s*set|jewellery\s*set|full\s*set|set\s*chahiye/.test(inputLower)) return 'CAT_PENDANT_SETS';
    if (/pendant|locket|mangalsutra/.test(inputLower)) return 'CAT_PENDANT';
    if (/ring|anguthi|angoothi|band/.test(inputLower)) return 'CAT_RINGS';
    if (/catalogue|catalog|collection|sab\s*dikhao|all\s*products|poora/.test(inputLower)) return 'OPEN_CATALOG';
    // No other text triggers
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

💎 Timeless elegance
✨ Stunning designs
🎁 Perfect gifting	

How can we help you today? 👇`,
          [
            { id: 'btn_shop',   title: '💎 Jewellery' },
            { id: 'btn_offers', title: '🎁 Offers & Track' },
            { id: 'btn_help',   title: '❓ Help & FAQs' },
          ],
          '💖 Where Luxury Meets You'
        );
        break;

      // ════════════════════════════════════════
      // SHOP MENU
      // ════════════════════════════════════════
      case 'SHOP_MENU':
        await sendButtons(
`═══════════════════════════
💎 *Shop KAAPAV*
═══════════════════════════

👑 Curated for You

✨ Handcrafted pieces
🎀 Gift-ready packaging
💝 Made with love

Where would you like to shop? 👇`,
          [
            { id: 'btn_website',   title: '🌐 Website' },
            { id: 'btn_catalogue', title: '📱 Catalogue' },
            { id: 'btn_shop_back', title: '🏠 Back' },
          ],
          '🌐 kaapav.com'
        );
        break;

      // ════════════════════════════════════════
      // OFFERS & TRACK MENU
      // ════════════════════════════════════════
      case 'OFFERS_MENU':
        await sendButtons(
`═══════════════════════════
🎁 *Offers & Track*
═══════════════════════════

👑 Deals & Order Tracking

🔥 50% OFF on collections
🚚 Free shipping above ₹498/-
⚡ Hurry, grab yours!

What do you need? 👇`,
          [
            { id: 'btn_deals',       title: '🔥 Deals & Offers' },
            { id: 'btn_pay_track',   title: '💳  Pay & Track' },
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
🔥 *Deals & Offers*
═══════════════════════════

👑 Best Prices Guaranteed

🔥 Flat 50% OFF — limited time!
💍 Earrings & Rings → ₹249/-
📿 Necklace & Bracelet → ₹499/-
✨ Sets → ₹699/-

🚚 FREE shipping above ₹498/-

Grab your favourites! 👇`,
          [
            { id: 'btn_bestsellers', title: '🛍️ Bestsellers' },
            { id: 'btn_shop_now',    title: '🌐 Shop Now' },
            { id: 'btn_deals_back',  title: '🏠 Back' },
          ],
          "⚡ Don't miss out!"
        );
        break;

      // ════════════════════════════════════════
      // PAY & TRACK MENU
      // ════════════════════════════════════════
      case 'PAY_TRACK_MENU':
        await sendButtons(
`═══════════════════════════
📦 *Pay & Track*
═══════════════════════════

👑 Secure Payment & Live Tracking

💳 UPI / Cards / Net Banking
✅ Instant confirmation
📦 Track your order live
🚚 Delivered in 2–4 working days

What do you need? 👇`,
          [
            { id: 'btn_pay_now',      title: '💳 Pay Now' },
            { id: 'btn_track_order',  title: '📦 Track Order' },
            { id: 'btn_paytrack_back',title: '🏠 Back' },
          ],
          '🔒 100% Secure'
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
            { id: 'btn_browse',    title: '📋 Browse Topics' },
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

      // ════════════════════════════════════════
      // OPEN CATALOG
      // ════════════════════════════════════════
      case 'OPEN_CATALOG':
        await sendText(
`═══════════════════════════
📱 *WhatsApp Catalogue*
═══════════════════════════

💎 Browse & Order on WhatsApp

👆 Tap to view all products
🛒 Add to cart directly
💝 Easy & instant

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

      // ════════════════════════════════════════
      // PAY NOW
      // ════════════════════════════════════════
      case 'PAY_NOW':
        await sendText(
`═══════════════════════════
💳 *Secure Payment*
═══════════════════════════

💎 Pay Safely & Instantly

🏦 UPI / Cards / Net Banking
✅ Order confirmed instantly
🔒 Powered by Razorpay

👉 ${env.PAYMENT_URL}

Need a payment link for your order?
Just tell us what you'd like to order!

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        break;

      // ════════════════════════════════════════
      // TRACK ORDER
      // ════════════════════════════════════════
      case 'TRACK_ORDER':
        await sendText(
`═══════════════════════════
📦 *Track Your Order*
═══════════════════════════

💎 Real-Time Order Tracking

📍 Live delivery updates
🚚 Know exactly where it is
⏰ Estimated arrival time

Or track here:
👉 ${env.TRACKING_URL}

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

2️⃣ *WhatsApp Catalogue* — quick order:
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

    if (path === '/webhook' || path === '/api/webhook') {
      if (method === 'GET') return handleWebhookVerify(request, env);
      if (method === 'POST') return handleWebhookPost(request, env, ctx);
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
      const result = await sendWhatsAppText(env, env.WA_PHONE_ID, 'Test message from KAAPAV Worker ✅');
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
    console.log('Cron running:', new Date().toISOString());
  }
};