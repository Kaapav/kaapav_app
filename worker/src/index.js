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

async function sendFCMNotification(env, phone, name, text) {
  try {
    const deviceToken = await env.KV.get('fcm_token:flutter');
    if (!deviceToken) return;
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
              priority: 'max',
              default_vibrate_timings: true,
              default_sound: true,
              visibility: 'public',
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

    ctx.waitUntil(sendFCMNotification(env, phone, name, text));

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

    // Check WhatsApp API error
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
  const limit = parseInt(url.searchParams.get('limit') || '50');
  const category = url.searchParams.get('category');
  let query = `SELECT * FROM products WHERE is_active = 1 ORDER BY created_at DESC LIMIT ?`;
  const params = [limit];
  if (category) { query = `SELECT * FROM products WHERE is_active = 1 AND category = ? ORDER BY created_at DESC LIMIT ?`; params.unshift(category); }
  const { results } = await env.DB.prepare(query).bind(...params).all();
  return jsonResponse({ success: true, products: results, total: results.length });
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

// ═══════════════════ AUTORESPONDER (LUXURY EDITION) ═══════════════════
class AutoResponder {
  constructor(env) { this.env = env; }

  async process({ phone, name, text, messageType, buttonId, messageId }) {
    const dedupeKey = `dedup:${messageId}`;
    const already = await this.env.KV.get(dedupeKey);
    if (already) return;
    await this.env.KV.put(dedupeKey, '1', { expirationTtl: 86400 });

    const input = (buttonId || text || '').toLowerCase().trim();
    const action = this.resolveAction(input);
    if (!action) return;

    await this.executeAction(phone, action);
  }

  resolveAction(input) {
    const ID_MAP = {
      'main_menu': 'MAIN_MENU', 'back': 'MAIN_MENU', 'home': 'MAIN_MENU', 'start': 'MAIN_MENU',
      'jewellery_menu': 'JEWELLERY_MENU',
      'offers_menu': 'OFFERS_MENU',
      'payment_menu': 'PAYMENT_MENU',
      'chat_menu': 'CHAT_MENU',
      'social_menu': 'SOCIAL_MENU',
      'open_website': 'OPEN_WEBSITE',
      'open_catalog': 'OPEN_CATALOG',
      'open_bestsellers': 'OPEN_BESTSELLERS',
      'pay_now': 'PAY_NOW',
      'track_order': 'TRACK_ORDER',
      'chat_now': 'CHAT_NOW',
      'open_facebook': 'OPEN_FACEBOOK',
      'open_instagram': 'OPEN_INSTAGRAM',
    };
    if (ID_MAP[input]) return ID_MAP[input];

    if (/^(hi|hello|hey|helo)/.test(input)) return 'MAIN_MENU';
    if (/browse|shop|website|collection/.test(input)) return 'JEWELLERY_MENU';
    if (/offer|discount|deal|sale/.test(input)) return 'OFFERS_MENU';
    if (/payment|pay|upi|card/.test(input)) return 'PAYMENT_MENU';
    if (/chat|help|support|agent/.test(input)) return 'CHAT_MENU';
    if (/back|menu|start/.test(input)) return 'MAIN_MENU';
    if (/bestseller|trending/.test(input)) return 'OPEN_BESTSELLERS';
    if (/catalog|catalogue/.test(input)) return 'OPEN_CATALOG';
    if (/track|tracking|order status/.test(input)) return 'TRACK_ORDER';
    if (/facebook|fb/.test(input)) return 'OPEN_FACEBOOK';
    if (/insta|instagram/.test(input)) return 'OPEN_INSTAGRAM';
    return null;
  }

  async executeAction(phone, action) {
    const env = this.env;
    const send = (text) => sendWhatsAppText(env, phone, text);
    const buttons = (text, btns, footer = null) => sendWhatsAppButtons(env, phone, text, btns, footer);
    const saveOutgoing = async (text, type = 'text') => {
      const msgId = `auto_${Date.now()}_${phone}`;
      await env.DB.prepare(`
        INSERT OR IGNORE INTO messages (message_id, phone, text, message_type, direction, status, is_auto_reply, timestamp, created_at)
        VALUES (?, ?, ?, ?, 'outgoing', 'sent', 1, datetime('now'), datetime('now'))
      `).bind(msgId, phone, text, type).run();
    };

    switch (action) {

      case 'MAIN_MENU':
        await buttons(
`═══════════════════════════
   ✨ *KAAPAV Fashion Jewellery* ✨
 ═══════════════════════════

👑 Crafted for Royalty

💎 Timeless elegance
✨ Stunning designs
🎁 Perfect gifting

Select below 👇`,
          [
            { id: 'jewellery_menu', title: '💎 Jewellery' },
            { id: 'offers_menu', title: '🎁 Offers' },
            { id: 'chat_menu', title: '💬 Chat with Us' },
          ],
          '💖 Where Luxury Meets You'
        );
        await saveOutgoing('Main Menu sent', 'buttons');
        break;

      case 'JEWELLERY_MENU':
        await buttons(
`═══════════════════════════
   💎 *Our Collections* 💎
═══════════════════════════

👑 Curated for You

✨ Handcrafted pieces
🎀 Gift-ready packaging
💝 Made with love

Explore now 👇`,
          [
            { id: 'open_website', title: '🌐 Website' },
            { id: 'open_catalog', title: '📱 Catalogue' },
            { id: 'main_menu', title: '🏠 Back' },
          ],
          '🌐 kaapav.com'
        );
        await saveOutgoing('Jewellery Menu sent', 'buttons');
        break;

      case 'OFFERS_MENU':
        await buttons(
`═══════════════════════════
   🎁 *Exclusive Offers* 🎁
═══════════════════════════

👑 Limited Time Only

🔥 Flat 50% OFF
🚚 Free shipping ₹498+
⚡ Hurry, grab yours!

Shop now 👇`,
          [
            { id: 'open_bestsellers', title: '🛍️ Bestsellers' },
            { id: 'payment_menu', title: '💳 Pay & Track' },
            { id: 'main_menu', title: '🏠 Back' },
          ],
          "✨ Don't miss out!"
        );
        await saveOutgoing('Offers Menu sent', 'buttons');
        break;

      case 'PAYMENT_MENU':
        await buttons(
`═══════════════════════════
   💳 *Payment & Tracking* 💳
═══════════════════════════

👑 Secure & Easy

🏦 UPI / Cards / Netbanking
✅ Instant confirmation
📦 Track your order

⚠️ COD not available

Choose below 👇`,
          [
            { id: 'pay_now', title: '💳 Pay Now' },
            { id: 'track_order', title: '📦 Track Order' },
            { id: 'main_menu', title: '🏠 Back' },
          ],
          '🔒 100% Secure'
        );
        await saveOutgoing('Payment Menu sent', 'buttons');
        break;

      case 'CHAT_MENU':
        await buttons(
`═══════════════════════════
   💬 *We're Here to Help* 💬
═══════════════════════════

👑 Personal Assistance

👗 Styling advice
📋 Order support
⚡ Quick response

How can we help? 👇`,
          [
            { id: 'chat_now', title: '💬 Chat Now' },
            { id: 'social_menu', title: '📱 Follow Us' },
            { id: 'main_menu', title: '🏠 Back' },
          ],
          '💝 At your service'
        );
        await saveOutgoing('Chat Menu sent', 'buttons');
        break;

      case 'SOCIAL_MENU':
        await buttons(
`═══════════════════════════
   📱 *Join Our World* 📱
═══════════════════════════

👑 Stay Connected

🆕 New launches
🎁 Exclusive offers
💕 Behind the scenes

Follow us 👇`,
          [
            { id: 'open_facebook', title: '👍 Facebook' },
            { id: 'open_instagram', title: '📷 Instagram' },
            { id: 'main_menu', title: '🏠 Back' },
          ],
          '✨ Be part of KAAPAV'
        );
        await saveOutgoing('Social Menu sent', 'buttons');
        break;

      case 'OPEN_WEBSITE':
        await send(
`═══════════════════════════
🌐 *Visit Our Website*
═══════════════════════════

👑 Complete Collection

💎 Latest arrivals
🛍️ Exclusive designs
✨ Easy shopping

Explore now:
${env.WEBSITE_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Website link sent');
        break;

      case 'OPEN_CATALOG':
        await send(
`═══════════════════════════
📱 *WhatsApp Catalogue*
═══════════════════════════

👑 Quick Browse & Order

👆 Tap to view
💝 Easy selection
🛒 Instant order

Browse now:
${env.CATALOG_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Catalog link sent');
        break;

      case 'OPEN_BESTSELLERS':
        await send(
`═══════════════════════════
🛍️ *Bestselling Pieces*
═══════════════════════════

👑 Customer Favorites

❤️ Most loved designs
🔥 Trending now
⚡ Limited stock!

Shop now:
${env.BESTSELLERS_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Bestsellers link sent');
        break;

      case 'PAY_NOW':
        await send(
`═══════════════════════════
💳 *Secure Payment*
═══════════════════════════

👑 100% Safe Checkout

🏦 UPI / Cards / Netbanking
✅ Instant confirmation
🔒 Secure & trusted

Pay now:
${env.PAYMENT_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Payment link sent');
        break;

      case 'TRACK_ORDER':
        await send(
`═══════════════════════════
📦 *Track Your Order*
═══════════════════════════

👑 Real-Time Updates

📍 Live tracking
🚚 Delivery status
⏰ ETA updates

Track here:
${env.TRACKING_URL}

Or share your Order ID (KP-XXXXX) and we'll check for you!

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Track order sent');
        break;

      case 'CHAT_NOW':
        await send(
`═══════════════════════════
💬 *Chat With Us*
═══════════════════════════

👑 Personal Assistance

👗 Styling advice
📋 Order help
⚡ Quick response

Chat now:
${env.WAME_CHAT_URL}

Business hours: 10:30 AM – 7:00 PM IST
Sunday Off
We'll respond shortly! 😊

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Chat now sent');
        break;

      case 'OPEN_FACEBOOK':
        await send(
`═══════════════════════════
👍 *Follow on Facebook*
═══════════════════════════

👑 Join Our Community

🆕 New launches
🎁 Exclusive offers
📸 Behind the scenes

Follow us:
${env.FACEBOOK_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Facebook link sent');
        break;

      case 'OPEN_INSTAGRAM':
        await send(
`═══════════════════════════
📷 *Follow on Instagram*
═══════════════════════════

👑 Daily Inspiration

💅 Styling tips
✨ New arrivals
💕 Customer stories

Follow us:
${env.INSTAGRAM_URL}

═══════════════════════════
💎 KAAPAV Fashion Jewellery`
        );
        await saveOutgoing('Instagram link sent');
        break;
    }
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
    if (path === '/api/push/fcm-register' && method === 'POST') return handleRegisterFCM(request, env);
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