CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT UNIQUE,
  email TEXT UNIQUE,
  password_hash TEXT,
  name TEXT,
  role TEXT DEFAULT 'admin',
  avatar TEXT,
  is_active INTEGER DEFAULT 1,
  last_login TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  token TEXT UNIQUE,
  user_id TEXT,
  expires_at TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone TEXT UNIQUE,
  name TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  pincode TEXT,
  segment TEXT DEFAULT 'new',
  tier TEXT DEFAULT 'bronze',
  labels TEXT DEFAULT '[]',
  message_count INTEGER DEFAULT 0,
  order_count INTEGER DEFAULT 0,
  total_spent REAL DEFAULT 0,
  cart TEXT DEFAULT '[]',
  cart_updated_at TEXT,
  language TEXT DEFAULT 'en',
  opted_in INTEGER DEFAULT 1,
  first_seen TEXT DEFAULT (datetime('now')),
  last_seen TEXT DEFAULT (datetime('now')),
  last_order_at TEXT,
  push_subscription TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS chats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone TEXT UNIQUE,
  customer_name TEXT,
  last_message TEXT,
  last_message_type TEXT DEFAULT 'text',
  last_timestamp TEXT,
  last_direction TEXT DEFAULT 'incoming',
  unread_count INTEGER DEFAULT 0,
  total_messages INTEGER DEFAULT 0,
  assigned_to TEXT,
  status TEXT DEFAULT 'open',
  priority TEXT DEFAULT 'normal',
  labels TEXT DEFAULT '[]',
  is_starred INTEGER DEFAULT 0,
  is_blocked INTEGER DEFAULT 0,
  is_bot_enabled INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id TEXT UNIQUE,
  phone TEXT,
  text TEXT,
  message_type TEXT DEFAULT 'text',
  direction TEXT DEFAULT 'incoming',
  media_id TEXT,
  media_url TEXT,
  media_mime TEXT,
  media_caption TEXT,
  button_id TEXT,
  button_text TEXT,
  buttons TEXT,
  is_menu INTEGER DEFAULT 0,
  list_id TEXT,
  list_title TEXT,
  context_message_id TEXT,
  is_forwarded INTEGER DEFAULT 0,
  status TEXT DEFAULT 'sent',
  is_auto_reply INTEGER DEFAULT 0,
  is_template INTEGER DEFAULT 0,
  template_name TEXT,
  timestamp TEXT,
  delivered_at TEXT,
  read_at TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sku TEXT UNIQUE,
  name TEXT,
  description TEXT,
  price REAL DEFAULT 0,
  compare_price REAL DEFAULT 0,
  cost_price REAL DEFAULT 0,
  category TEXT,
  subcategory TEXT,
  tags TEXT DEFAULT '[]',
  stock INTEGER DEFAULT 0,
  track_inventory INTEGER DEFAULT 1,
  image_url TEXT,
  images TEXT DEFAULT '[]',
  video_url TEXT,
  has_variants INTEGER DEFAULT 0,
  variants TEXT DEFAULT '[]',
  wa_product_id TEXT,
  view_count INTEGER DEFAULT 0,
  order_count INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  is_featured INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id TEXT UNIQUE,
  phone TEXT,
  customer_name TEXT,
  items TEXT DEFAULT '[]',
  item_count INTEGER DEFAULT 0,
  subtotal REAL DEFAULT 0,
  discount REAL DEFAULT 0,
  discount_code TEXT,
  shipping_cost REAL DEFAULT 0,
  tax REAL DEFAULT 0,
  total REAL DEFAULT 0,
  shipping_name TEXT,
  shipping_phone TEXT,
  shipping_address TEXT,
  shipping_city TEXT,
  shipping_state TEXT,
  shipping_pincode TEXT,
  status TEXT DEFAULT 'pending',
  payment_status TEXT DEFAULT 'unpaid',
  payment_method TEXT,
  payment_id TEXT,
  payment_link TEXT,
  payment_link_expires TEXT,
  paid_at TEXT,
  courier TEXT,
  tracking_id TEXT,
  tracking_url TEXT,
  shipment_id TEXT,
  awb_number TEXT,
  confirmed_at TEXT,
  shipped_at TEXT,
  delivered_at TEXT,
  cancelled_at TEXT,
  customer_notes TEXT,
  internal_notes TEXT,
  cancellation_reason TEXT,
  source TEXT DEFAULT 'whatsapp',
  confirmation_sent INTEGER DEFAULT 0,
  shipping_sent INTEGER DEFAULT 0,
  delivery_sent INTEGER DEFAULT 0,
  review_sent INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payment_id TEXT UNIQUE,
  order_id TEXT,
  phone TEXT,
  gateway TEXT DEFAULT 'razorpay',
  gateway_payment_id TEXT,
  gateway_order_id TEXT,
  gateway_signature TEXT,
  amount REAL DEFAULT 0,
  currency TEXT DEFAULT 'INR',
  status TEXT DEFAULT 'pending',
  method TEXT,
  paid_at TEXT,
  failed_at TEXT,
  refund_amount REAL DEFAULT 0,
  refund_id TEXT,
  refunded_at TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS carts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone TEXT UNIQUE,
  items TEXT DEFAULT '[]',
  item_count INTEGER DEFAULT 0,
  total REAL DEFAULT 0,
  status TEXT DEFAULT 'active',
  reminder_count INTEGER DEFAULT 0,
  last_reminder_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  converted_at TEXT
);

CREATE TABLE IF NOT EXISTS coupons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE,
  type TEXT DEFAULT 'percent',
  value REAL DEFAULT 0,
  min_order REAL DEFAULT 0,
  max_discount REAL DEFAULT 0,
  usage_limit INTEGER DEFAULT 0,
  used_count INTEGER DEFAULT 0,
  starts_at TEXT,
  expires_at TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS quick_replies (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  shortcut TEXT UNIQUE,
  title TEXT,
  message TEXT,
  message_type TEXT DEFAULT 'text',
  buttons TEXT,
  list_data TEXT,
  media_url TEXT,
  category TEXT DEFAULT 'general',
  variables TEXT DEFAULT '[]',
  use_count INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  wa_template_id TEXT,
  wa_status TEXT DEFAULT 'pending',
  category TEXT,
  language TEXT DEFAULT 'en',
  header_type TEXT,
  header_text TEXT,
  body_text TEXT,
  footer_text TEXT,
  buttons TEXT,
  variables TEXT DEFAULT '[]',
  sent_count INTEGER DEFAULT 0,
  delivered_count INTEGER DEFAULT 0,
  read_count INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS broadcasts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  broadcast_id TEXT UNIQUE,
  name TEXT,
  message_type TEXT DEFAULT 'text',
  message TEXT,
  template_name TEXT,
  template_params TEXT,
  media_url TEXT,
  buttons TEXT,
  target_type TEXT DEFAULT 'all',
  target_labels TEXT,
  target_segment TEXT,
  target_filters TEXT,
  target_count INTEGER DEFAULT 0,
  sent_count INTEGER DEFAULT 0,
  delivered_count INTEGER DEFAULT 0,
  read_count INTEGER DEFAULT 0,
  failed_count INTEGER DEFAULT 0,
  clicked_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'draft',
  scheduled_at TEXT,
  started_at TEXT,
  completed_at TEXT,
  send_rate INTEGER DEFAULT 30,
  created_by TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS broadcast_recipients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  broadcast_id TEXT,
  phone TEXT,
  status TEXT DEFAULT 'pending',
  message_id TEXT,
  sent_at TEXT,
  delivered_at TEXT,
  read_at TEXT,
  clicked_at TEXT,
  failed_at TEXT,
  error_message TEXT
);

CREATE TABLE IF NOT EXISTS automations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  description TEXT,
  trigger_type TEXT,
  trigger_conditions TEXT,
  actions TEXT DEFAULT '[]',
  delay_minutes INTEGER DEFAULT 0,
  triggered_count INTEGER DEFAULT 0,
  last_triggered_at TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS automation_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  automation_id INTEGER,
  phone TEXT,
  trigger_type TEXT,
  trigger_data TEXT,
  actions_executed TEXT,
  status TEXT DEFAULT 'success',
  error_message TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS conversation_state (
  phone TEXT PRIMARY KEY,
  current_flow TEXT,
  current_step TEXT,
  flow_data TEXT DEFAULT '{}',
  started_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  expires_at TEXT
);

CREATE TABLE IF NOT EXISTS labels (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  color TEXT,
  description TEXT,
  customer_count INTEGER DEFAULT 0,
  chat_count INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS analytics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type TEXT,
  event_name TEXT,
  phone TEXT,
  order_id TEXT,
  product_id TEXT,
  campaign_id TEXT,
  data TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE,
  value TEXT,
  updated_at TEXT DEFAULT (datetime('now'))
);

-- DEFAULT DATA
INSERT OR IGNORE INTO users (user_id, email, password_hash, name, role) 
VALUES ('admin', 'admin@kaapav.com', 'pin_auth', 'KAAPAV Admin', 'admin');

INSERT OR IGNORE INTO labels (name, color, description) VALUES
('VIP', '#FFD700', 'VIP customers'),
('Hot Lead', '#FF6B6B', 'High intent buyers'),
('New', '#4ECDC4', 'New customers'),
('Returning', '#45B7D1', 'Returning customers'),
('Wholesale', '#96CEB4', 'Wholesale buyers');

INSERT OR IGNORE INTO settings (key, value) VALUES
('business_name', 'KAAPAV Fashion Jewellery'),
('business_phone', '919148330016'),
('business_email', 'hello@kaapav.com'),
('ai_auto_reply', 'true'),
('auto_greeting', 'true'),
('business_hours', '{"start":"09:00","end":"21:00"}'),
('away_message', 'We are currently away. We will get back to you soon!');

INSERT OR IGNORE INTO quick_replies (shortcut, title, message, category) VALUES
('/hi', 'Greeting', 'Hello! Welcome to KAAPAV Fashion Jewellery 💎 How can I help you today?', 'greeting'),
('/catalog', 'Catalog', 'Here is our latest collection 👆', 'sales'),
('/price', 'Price Inquiry', 'Our prices are very competitive! Check our catalog for latest prices.', 'sales'),
('/order', 'Order Status', 'Please share your order ID (KP-XXXXX) and I will check the status for you.', 'support'),
('/cod', 'COD Info', 'Yes we offer Cash on Delivery! COD available for orders above ₹299.', 'sales'),
('/return', 'Return Policy', 'We have a 7-day return policy. Items must be unused and in original packaging.', 'support'),
('/thanks', 'Thank You', 'Thank you for shopping with KAAPAV! 💎 Have a wonderful day!', 'closing');