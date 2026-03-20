-- ═══════════════════════════════════════════════
-- KAAPAV D1 SCHEMA — COMPLETE + FAQ SYSTEM
-- ═══════════════════════════════════════════════

-- Core tables (unchanged)
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

CREATE TABLE IF NOT EXISTS order_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_source TEXT,
  message TEXT,
  meta_json TEXT,
  created_at TEXT DEFAULT (datetime('now'))
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

-- ═══════════════════════════════════════════════
-- QUICK REPLIES — FAQ SYSTEM (UPGRADED)
-- Added: keywords, group_name columns
-- ═══════════════════════════════════════════════
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
  group_name TEXT DEFAULT 'general',
  keywords TEXT DEFAULT '[]',
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

CREATE TABLE IF NOT EXISTS notification_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel TEXT NOT NULL,
  recipient TEXT NOT NULL,
  payload TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  attempt_count INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS return_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id TEXT NOT NULL,
  phone TEXT NOT NULL,
  sku TEXT,
  item_name TEXT,
  reason TEXT,
  status TEXT DEFAULT 'requested',
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
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

-- ═══════════════════════════════════════════════
-- NOTIFICATION LOG
-- Tracks all WhatsApp notifications sent
-- ═══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notification_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phone TEXT,
  type TEXT, -- order_confirmed|shipped|delivered|payment|review
  order_id TEXT,
  message TEXT,
  status TEXT DEFAULT 'sent',
  sent_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS return_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id TEXT NOT NULL,
  phone TEXT NOT NULL,
  sku TEXT,
  item_name TEXT,
  reason TEXT,
  status TEXT DEFAULT 'requested',
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- ═══════════════════════════════════════════════
-- DEFAULT DATA
-- ═══════════════════════════════════════════════

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
('business_email', 'care.kaapav@gmail.com'),
('website_url', 'https://www.kaapav.com'),
('instagram_url', 'https://www.instagram.com/kaapavfashionjewellery'),
('facebook_url', 'https://www.facebook.com/kaapavfashionjewellery'),
('ai_auto_reply', 'true'),
('auto_greeting', 'true'),
('business_hours_start', '10:30'),
('business_hours_end', '19:00'),
('business_days', 'mon,tue,wed,thu,fri,sat'),
('away_message', 'We are currently away. Available 10:30 AM - 7:00 PM IST Mon-Sat'),
('free_shipping_threshold', '498'),
('currency', 'INR'),
('timezone', 'Asia/Kolkata');

-- ═══════════════════════════════════════════════
-- FAQ DATA — 40 Questions
-- category = 'faq'
-- keywords = JSON array of trigger words
-- ═══════════════════════════════════════════════

-- GROUP 1: Real Life Appearance
INSERT OR IGNORE INTO quick_replies
(shortcut, title, message, category, group_name, keywords) VALUES
('faq_photo', 'Will it look the same as photos?',
'═══════════════════════════
📸 *Photo vs Reality*
═══════════════════════════
Simple Luxury. What You See = What You Get. 💎

100% same as photos!
We shoot in natural light — no filters, no tricks.

Browse our collection:
www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'appearance',
'["real", "photo", "actual", "look", "same", "different", "dikhega", "image", "picture", "pic", "original look", "real life", "as shown", "like photo", "photo same", "real photo", "actual look", "will it look", "how it looks", "dekh", "dekhna", "dikhta", "color same", "exactly same", "what it looks"]'),

-- GROUP 2: Durability
('faq_last', 'How long will it last?',
'═══════════════════════════
⏳ *How Long Will It Last?*
═══════════════════════════
Simple Luxury. Built to Last. 💎

With basic care — months to years!
✅ High quality alloy
✅ Anti-tarnish coated
✅ Built for regular wear
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'durability',
'["last", "days", "how long", "durable", "actually", "kitne din", "long", "how many days", "lifetime", "long lasting", "quality", "tiktok", "stay", "months", "years", "chalega", "chalta", "kitne time", "how much time", "durable", "reliable", "lasting", "long time", "kab tak"]'),

('faq_tarnish', 'Will it turn black or green?',
'═══════════════════════════
🌿 *Black or Green?*
═══════════════════════════
Simple Luxury. Stay Shiny. 💎

Not if you follow basic care!
❌ Avoid water, perfume, soap
✅ Wipe after use
✅ Store in pouch

Our customers wear it daily — no issues!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'durability',
'["black", "green", "tarnish", "colour", "change", "rust", "fade", "kaala", "hara", "color change", "turn black", "go black", "blacken", "discolor", "colour fade", "lose colour", "oxidize", "dark", "stain", "spoil", "kharab", "rang", "color jaega", "colour jaega", "green ho", "black ho", "color ho"]'),

('faq_daily', 'Can I wear it daily?',
'═══════════════════════════
💫 *Daily Wear?*
═══════════════════════════
Simple Luxury. Every Day. 💎

Absolutely yes!
✅ Office & college wear
✅ Casual & festive
✅ Lightweight all-day comfort
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'durability',
'["daily", "everyday", "regular", "roz", "always", "wear daily", "roz pehnu", "daily use", "daily wear", "har roz", "every day", "office", "college", "school", "regular use", "regular basis", "all day", "pehnte rehna", "continuously", "regular pehna", "daily pehnna", "use daily"]'),

('faq_plating', 'How long before plating fades?',
'═══════════════════════════
✨ *Plating & Finish*
═══════════════════════════
Simple Luxury. Long Lasting. 💎

Stays beautiful with care!
✅ Keep away from water
✅ Remove before bath
✅ Store in pouch
✅ No perfume contact
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'durability',
'["plating", "polish", "coating", "fade", "finish", "colour go", "gold plating", "silver plating", "plating jaegi", "polish jaegi", "coating jaegi", "gold fade", "silver fade", "finish jaegi", "plating kitne din", "how long plating", "plating last", "gold color", "shine jae", "shine jaegi", "gloss", "luster", "shiny", "brightness fade"]'),

('faq_strong', 'Is it strong?',
'═══════════════════════════
💪 *Strength & Durability*
═══════════════════════════
Simple Luxury. Built Strong. 💎

✅ High quality alloy base
✅ Secure clasps & hooks
✅ Tested for daily wear

Handle with normal care — it wont disappoint!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'durability',
'["break", "fragile", "strong", "weak", "toot", "durable", "quality", "tutega", "tootega", "breaking", "clasp", "hook", "lock", "chain break", "easily break", "delicate", "sturdy", "solid", "robust", "strong material", "will it break", "kya tootega", "material strong", "build quality", "good quality", "poor quality", "cheap"]'),

-- GROUP 3: Size & Fit
('faq_ring_size', 'Will the ring fit?',
'═══════════════════════════
💍 *Ring Size*
═══════════════════════════
Simple Luxury. Perfect Fit. 💎

✅ All rings are adjustable
✅ Fits most finger sizes
✅ Easy to resize at home

One size fits all!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'size',
'["ring", "size", "finger", "fit", "adjustable", "ring size", "ring fit", "ungli", "finger size", "which size", "what size", "size kya", "ring size kya", "fit hogi", "fit hoga", "adjust", "small ring", "big ring", "large", "medium", "ring number", "number ring", "ring number kya", "size chart ring"]'),

('faq_bracelet_size', 'Will the bracelet fit?',
'═══════════════════════════
📿 *Bracelet Size*
═══════════════════════════
Simple Luxury. Perfect Fit. 💎

✅ Size: 2.6 inches
✅ Adjustable: 2.4 to 2.6 inches
✅ Fits most wrist sizes

Slim or regular wrist — fits all!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'size',
'["bracelet", "wrist", "loose", "tight", "bracelet size", "fit", "kada", "bangle", "kangan", "wrist size", "hand size", "haath", "fit hoga", "fit hogi", "adjustable bracelet", "bracelet fit", "wrist fit", "slim wrist", "big wrist", "small wrist", "2.6", "size bracelet", "bracelet number"]'),

('faq_necklace_length', 'How long is the necklace?',
'═══════════════════════════
📿 *Necklace Length*
═══════════════════════════
Simple Luxury. Elegant Fit. 💎

✅ Length: 18 to 20 inches
✅ Varies by design
✅ Sits beautifully on all necklines

Exact measurements on:
www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'size',
'["necklace", "length", "long", "short", "cm", "inches", "chain length", "haar", "chain", "necklace length", "how long necklace", "necklace size", "size necklace", "18 inch", "20 inch", "neck", "collar", "choker", "long chain", "short chain", "extender", "length kya", "kitni lambi", "lambi chain"]'),

('faq_earring_weight', 'Are earrings heavy?',
'═══════════════════════════
👂 *Earring Weight*
═══════════════════════════
Simple Luxury. Feather Light. 💎

✅ Super lightweight
✅ Designed for all-day comfort
✅ No ear pain or pulling

Wear from morning to night — zero discomfort!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'size',
'["earring", "heavy", "light", "pain", "hurt", "kaan", "weight", "bhari", "halki", "ear pain", "kaan mein dard", "pulling", "stretch", "earlobe", "ear hole", "lightweight earring", "heavy earring", "comfortable", "earring weight", "bhaari", "halka", "ear hurts", "kaan kheenchna", "ear stretch"]'),

('faq_piercing', 'Do I need pierced ears?',
'═══════════════════════════
👂 *Piercing Required?*
═══════════════════════════
Simple Luxury. For Everyone. 💎

Most earrings need pierced ears.
Types available:
✅ Studs (pierced)
✅ Hook/drop (pierced)
✅ Ear cuffs (no piercing!)

Check product details:
www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'size',
'["pierced", "clip", "without piercing", "hook", "stud", "no piercing", "kaan cheda", "piercing chahiye", "bina piercing", "clip on", "ear cuff", "screw back", "push back", "without hole", "bina chhed", "non pierced", "no hole", "kaan mein hole", "chhed", "kaan ka hole", "piercing needed", "unpierced"]'),

-- GROUP 4: Pricing & Offers
('faq_price', 'What are the prices?',
'═══════════════════════════
💰 *KAAPAV Flat Pricing*
═══════════════════════════
Simple Luxury. Honest Pricing. 💎

💍 Earrings & Rings → ₹249/-
📿 Necklace, Bracelet & Pendant → ₹499/-
✨ Earring + Pendant Set → ₹699/-

🔥 50% OFF — Introductory offer!
🚚 FREE shipping above ₹498/-

www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'pricing',
'["price", "cost", "rate", "how much", "kitna", "pricing", "rates", "daam", "kitne ka", "price kya", "how much cost", "rate kya", "total price", "price list", "price range", "starting price", "minimum price", "maximum price", "249", "499", "699", "rupees", "rs", "inr", "amount", "charges", "fee", "total amount"]'),

('faq_discount', 'Any discount or coupon?',
'═══════════════════════════
🎁 *Offers & Discounts*
═══════════════════════════
Simple Luxury. Amazing Value. 💎

🔥 50% OFF on most collections!
✅ Best prices starting ₹249/-
✅ FREE shipping above ₹498/-

Follow for exclusive deals:
📘 facebook.com/kaapavfashionjewellery
📷 instagram.com/kaapavfashionjewellery
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'pricing',
'["discount", "coupon", "offer", "promo", "code", "sale", "deal", "छूट", "bachao", "save", "cheap", "less price", "discount code", "promo code", "coupon code", "offer code", "any offer", "koi offer", "discount milega", "sale hai", "offer hai", "50 off", "percent off", "flat off", "extra off", "special offer", "festive offer"]'),

('faq_shipping_cost', 'Is delivery free?',
'═══════════════════════════
🚚 *Delivery Charges*
═══════════════════════════
Simple Luxury. Fast Delivery. 💎

✅ FREE shipping above ₹498/-
✅ Below ₹498/- — calculated at
   checkout based on pincode

💡 Add one more piece → FREE shipping!

www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'pricing',
'["delivery charge", "shipping cost", "free delivery", "free shipping", "charge", "delivery kitna", "shipping charge", "delivery free", "free hai", "free milega", "shipping fee", "delivery fee", "postage", "courier charge", "how much delivery", "delivery charges kya", "free nahi", "paid delivery", "charges lagenge", "extra charge"]'),

('faq_combo', 'Any combo deals?',
'═══════════════════════════
✨ *Combo Deals*
═══════════════════════════
Simple Luxury. Better Together. 💎

✅ Earring + Pendant Sets → ₹699/-
✅ Save vs buying separately!

Browse all combos:
www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'pricing',
'["combo", "set", "bundle", "together", "deal", "pair", "set hai", "combo hai", "earring set", "necklace set", "jewellery set", "matching set", "complete set", "full set", "set price", "combo price", "2 piece", "two piece", "matching", "pair earring", "set milega", "full jewellery", "complete jewellery"]'),

('faq_minimum', 'Minimum order?',
'═══════════════════════════
🛍️ *Minimum Order*
═══════════════════════════
Simple Luxury. No Limits. 💎

✅ No minimum order!
✅ Single piece from ₹249/-
✅ Order as many as you like

Start with one — you will come back for more!
www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'pricing',
'["minimum", "single", "one piece", "one item", "ek", "min order", "ek hi", "sirf ek", "only one", "just one", "single item", "minimum order", "min quantity", "ek piece", "1 piece", "one product", "single product", "ek product", "kitna kharidna", "minimum kharidna"]'),

-- GROUP 5: Ordering & Payment
('faq_how_order', 'How to place an order?',
'═══════════════════════════
🛒 *How to Order*
═══════════════════════════
Simple Luxury. Easy Ordering. 💎

3 easy ways:
1️⃣ Website → www.kaapav.com
2️⃣ WhatsApp Catalogue →
   wa.me/c/919148330016
3️⃣ WhatsApp — tell us what you like!
   We will send payment link
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'ordering',
'["order", "how", "process", "steps", "buy", "kaise", "purchase", "order kaise", "kaise kharidun", "kaise lu", "how to buy", "how to order", "ordering process", "place order", "kaise order", "order karna", "kharidna", "purchase karna", "order place", "order dena", "buying process", "shop kaise", "kaise shop"]'),

('faq_cod', 'Is COD available?',
'═══════════════════════════
💰 *Cash on Delivery*
═══════════════════════════
Simple Luxury. Zero Risk. 💎

✅ COD available!
Pay when it arrives at your door!

Also accept:
✅ UPI — GPay, PhonePe, Paytm
✅ Credit/Debit Cards
✅ Net Banking
✅ Razorpay Payment Link
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'ordering',
'["cod", "cash", "delivery payment", "cash on delivery", "pay on delivery", "cod milega", "cod available", "cash milega", "delivery pe pay", "delivery par pay", "ghar pe pay", "door pe pay", "receive karke pay", "milne ke baad pay", "baad mein pay", "pehle milega phir pay", "cash dena", "naqd", "nakit"]'),

('faq_payment_safe', 'Is payment safe?',
'═══════════════════════════
🔒 *Payment Safety*
═══════════════════════════
Simple Luxury. 100% Secure. 💎

✅ Powered by Razorpay
✅ Bank-grade encryption
✅ UPI / Cards / Net Banking
✅ COD also available

Trusted by customers across India!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'ordering',
'["safe", "secure", "trust", "payment safe", "upi", "card", "gpay", "phonepe", "paytm", "razorpay", "net banking", "online payment", "payment method", "safe payment", "payment secure", "secure hai", "safe hai", "reliable payment", "payment options", "kaise pay", "payment kaise", "online pay", "digital payment"]'),

('faq_confirmation', 'How will I get confirmation?',
'═══════════════════════════
✅ *Order Confirmation*
═══════════════════════════
Simple Luxury. Always Updated. 💎

After ordering you get:
✅ WhatsApp confirmation
✅ Order ID (KP-XXXXX)
✅ Shipping update when dispatched
✅ Tracking link via WhatsApp
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'ordering',
'["confirm", "confirmation", "message", "call", "order id", "confirmed", "order confirm", "kaise pata", "how to know", "order place hua", "order hua", "order successful", "confirmation milega", "message milega", "whatsapp aayega", "receipt", "invoice", "acknowledgement", "order receipt", "proof of order"]'),

('faq_gift_order', 'Can I order as a gift?',
'═══════════════════════════
🎁 *Gifting Orders*
═══════════════════════════
Simple Luxury. Perfect Gift. 💎

✅ Order to any address in India
✅ Add gift message at checkout
✅ Packed neatly & securely

Starting ₹249/- — most affordable
luxury gift for her!

www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'ordering',
'["gift", "different address", "someone else", "friend", "gifting", "present order", "gift karna", "kisi aur ko", "doosre ko", "alag address", "different location", "deliver to friend", "send as gift", "gift bhejana", "sister", "behen", "mom", "maa", "wife", "girlfriend", "bhabhi", "cousin", "best friend", "surprise gift"]'),

-- GROUP 6: Delivery
('faq_delivery_time', 'Delivery time?',
'═══════════════════════════
🚚 *Delivery Time*
═══════════════════════════
Simple Luxury. Fast Delivery. 💎

📦 2 to 4 working days!
Order → Confirmed same day
Packed → Dispatched next day
Delivered → 2-4 working days

Tracking link sent once shipped!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'delivery',
'["days", "delivery", "time", "when", "how long", "kitne din", "fast", "delivery time", "kitne days", "kab milega", "kab aayega", "when will arrive", "delivery kab", "kitne din mein", "expected delivery", "estimated delivery", "delivery date", "when deliver", "speed", "quick", "fast delivery", "express", "same day", "next day", "2 days", "3 days", "4 days"]'),

('faq_delivery_area', 'Do you deliver to my area?',
'═══════════════════════════
📍 *Delivery Locations*
═══════════════════════════
Simple Luxury. Pan India. 💎

✅ All states covered
✅ Metro & Tier 2/3 cities
✅ Powered by Shiprocket

Check your pincode:
www.shiprocket.in/pincode-serviceability/
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'delivery',
'["area", "pincode", "city", "location", "deliver", "my area", "available", "mera area", "mere yahan", "yahan milega", "deliver hoga", "delivery available", "serviceable", "my city", "my pincode", "village", "town", "district", "state", "rural", "remote", "north india", "south india", "east", "west", "pan india", "all india", "india mein"]'),

('faq_packaging', 'Will packaging be safe?',
'═══════════════════════════
📦 *Packaging*
═══════════════════════════
Simple Luxury. Packed with Care. 💎

✅ Secure multi-layer packaging
✅ Jewellery pouch included
✅ Damage-proof for transit
✅ Neat enough to gift directly!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'delivery',
'["packaging", "safe", "break", "damage", "box", "packed", "pouch", "packing", "packing kaisi", "packing safe", "achhi packing", "how packed", "kaise pack", "secure packing", "damage proof", "protective", "cushioned", "bubble wrap", "parcel", "box mein", "safely packed", "nice packing", "gift packing", "packaging quality"]'),

('faq_track', 'How to track my order?',
'═══════════════════════════
📦 *Track Your Order*
═══════════════════════════
Simple Luxury. Full Transparency. 💎

Share your Order ID (KP-XXXXX)
I will fetch status instantly!

Or track directly:
www.shiprocket.in/shipment-tracking/

Tracking link sent via WhatsApp
once shipped!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'delivery',
'["track", "status", "where", "order id", "KP", "tracking", "shipment", "track order", "order status", "kahan hai", "where is order", "tracking number", "AWB", "courier number", "tracking link", "shiprocket", "track karna", "order kahan", "parcel kahan", "delivery status", "shipment status", "out for delivery", "in transit"]'),

('faq_delayed', 'What if delivery is delayed?',
'═══════════════════════════
⏰ *Delayed Delivery?*
═══════════════════════════
Simple Luxury. Always Reliable. 💎

Track your order live:
www.shiprocket.in/shipment-tracking/

Your Order ID (KP-XXXXX) sent
via WhatsApp once shipped.

Need help? Email:
care.kaapav@gmail.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'delivery',
'["late", "delay", "not received", "missing", "delayed", "where is", "nahi aaya", "abhi tak nahi", "still not received", "waiting", "order late", "delivery late", "late ho gaya", "zyada din", "too long", "taking too long", "not delivered", "delivery delayed", "expected date", "past due", "overdue", "stuck"]'),

-- GROUP 7: Returns & Refunds
('faq_return', 'Can I return?',
'═══════════════════════════
🔄 *Return Policy*
═══════════════════════════
Simple Luxury. Hassle-free Returns. 💎

✅ 7-Day Return Policy
1️⃣ Email within 7 days of delivery
2️⃣ care.kaapav@gmail.com
3️⃣ Order ID + reason + unboxing video

• ₹60/- reverse shipping deducted
• Unworn, unused & original condition
• Refund in 7 days after quality check
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'returns',
'["return", "wapas", "send back", "dont like", "not happy", "refund", "return policy", "wapas karna", "vapas", "return kar sakti", "return ho sakta", "return milega", "7 day", "7 din", "seven day", "pasand nahi", "not satisfied", "unhappy", "disappointed", "not as expected", "want to return", "how to return", "return process", "return request"]'),

('faq_damaged', 'What if damaged?',
'═══════════════════════════
😟 *Damaged Product?*
═══════════════════════════
Simple Luxury. We Make It Right. 💎

1️⃣ Record unboxing video (mandatory)
2️⃣ Email within 7 days:
   care.kaapav@gmail.com
3️⃣ Order ID + clear video

We do 3-layer quality check before
every shipment.

Damaged = full refund/replacement!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'returns',
'["damage", "broken", "defective", "wrong item", "missing", "damaged", "tuta", "toot gaya", "damaged item", "damaged product", "broken product", "cracked", "bent", "scratched", "faulty", "defective item", "not working", "wrong product", "wrong order", "different product", "not what ordered", "missing item", "incomplete order", "partial delivery"]'),

('faq_refund_time', 'How long for refund?',
'═══════════════════════════
💰 *Refund Timeline*
═══════════════════════════
Simple Luxury. Fast Refunds. 💎

✅ Return received → Inspected
✅ Approved → Refund in 7 days
✅ Credited to original payment

COD orders → Bank transfer
(share account details)

care.kaapav@gmail.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'returns',
'["refund", "money back", "when", "days", "credited", "bank", "refund kab", "paise kab", "paise wapas", "money return", "money refund", "refund milega", "refund kitne din", "bank mein", "account mein", "credit", "debit", "paisa", "amount return", "refund process", "how long refund", "refund time", "money credited"]'),

('faq_exchange', 'Can I exchange?',
'═══════════════════════════
🔄 *Exchange Policy*
═══════════════════════════
Simple Luxury. Easy Exchange. 💎

1️⃣ Email within 7 days
2️⃣ care.kaapav@gmail.com
3️⃣ Order ID + preferred item

• ₹60/- reverse shipping applies
• Item must be unworn & unused
• Subject to availability
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'returns',
'["exchange", "swap", "different", "change", "replace", "exchange karna", "badalna", "badal", "different product", "another piece", "other design", "change design", "exchange policy", "product exchange", "swap product", "different colour", "different size", "different style", "exchange milega", "exchange ho sakta", "kya exchange"]'),

('faq_cancel', 'Can I cancel?',
'═══════════════════════════
❌ *Order Cancellation*
═══════════════════════════
Simple Luxury. Quick Processing. 💎

We process orders immediately
for fastest delivery.

Cancellations not accepted
after placing.

Please review carefully
before confirming!

Need help? care.kaapav@gmail.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'returns',
'["cancel", "cancellation", "stop order", "dont want", "cancel karna", "order cancel", "cancel order", "cancel kar", "nahi chahiye", "mind change", "changed mind", "cancel ho sakta", "order band", "order rok", "stop", "cancel milega", "cancellation policy", "after order cancel", "can i cancel", "order cancellation"]'),

-- GROUP 8: Jewellery Care
('faq_care', 'How to care for jewellery?',
'═══════════════════════════
✨ *Jewellery Care Guide*
═══════════════════════════
Simple Luxury. Long Lasting Shine. 💎

✅ Wipe with soft cloth after use
✅ Store in pouch provided
✅ Wear after perfume & makeup

❌ Avoid water, sweat, soap
❌ No sleeping with it on
❌ Keep from chemicals
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'care',
'["care", "maintain", "tips", "store", "clean", "how to care", "care tips", "jewellery care", "maintenance", "keep", "preserve", "dekhbhal", "clean karna", "store karna", "how to maintain", "long lasting tips", "care guide", "cleaning tips", "storage", "how to clean", "jewellery tips", "care kaise", "polish karna", "shine maintain"]'),

('faq_perfume', 'Can I spray perfume?',
'═══════════════════════════
🌸 *Perfume & Jewellery*
═══════════════════════════
Simple Luxury. Stay Shiny. 💎

Best practice:
✅ Apply perfume FIRST
✅ Let it dry completely
✅ Then wear your jewellery

Keeps shine & finish lasting longer!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'care',
'["perfume", "spray", "chemical", "deodorant", "scent", "ittar", "attar", "body spray", "fragrance", "deo", "perfume lagana", "spray karna", "perfume with jewellery", "perfume damage", "chemical effect", "chemical damage", "soap", "lotion", "cream", "moisturizer", "body lotion", "contact", "chemical contact"]'),

('faq_sleep', 'Can I sleep wearing it?',
'═══════════════════════════
🌙 *Sleeping With Jewellery*
═══════════════════════════
Simple Luxury. Gentle Care. 💎

We recommend removing it!

❌ Chain can tangle
❌ Stress on clasps
❌ Reduces lifespan

Remove → Store in pouch → Wear fresh!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'care',
'["night", "sleep", "remove", "wear overnight", "sleeping", "raat ko", "sone ke baad", "so sakti", "pehnke so", "overnight", "24 hours", "all night", "bathing", "shower", "swimming", "while sleeping", "bedtime", "before sleep", "remove karna", "utarne", "kab utare", "when to remove"]'),

-- GROUP 9: Gifting
('faq_gifting', 'Is it good for gifting?',
'═══════════════════════════
🎁 *Perfect Gift Choice!*
═══════════════════════════
Simple Luxury. Most Thoughtful Gift. 💎

Perfect for:
🎂 Birthdays & Anniversaries
🎓 Graduations
🥳 Celebrations
💕 Just because!

Starting ₹249/- — luxury look
at unbeatable price!

www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'gifting',
'["gift", "present", "birthday", "anniversary", "gifting", "dena", "gift dena", "kisi ko dena", "surprise", "gift idea", "gift for her", "gift for girlfriend", "gift for wife", "gift for sister", "gift for mom", "gift for friend", "birthday gift", "anniversary gift", "wedding gift", "festival gift", "diwali gift", "christmas gift", "rakhi gift", "valentine gift"]'),

('faq_gift_pack', 'Gift packaging available?',
'═══════════════════════════
🎁 *Gift Packaging*
═══════════════════════════
Simple Luxury. Gift Ready. 💎

Premium gift packaging coming soon!

Currently packed neatly & securely
— ready to gift as-is!

Follow for updates:
📷 instagram.com/kaapavfashionjewellery
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'gifting',
'["gift pack", "wrap", "box", "gift ready", "gift box", "packaging", "gift wrapping", "gift wrap", "special packaging", "gift bag", "ribbon", "tissue", "fancy box", "nice packaging", "gift packaging", "gift packing", "presentation", "nicely packed", "beautifully packed", "surprise box", "wrapped", "bow", "decorated box"]'),

('faq_multiple', 'Can I order multiple pieces?',
'═══════════════════════════
🛍️ *Multiple Pieces*
═══════════════════════════
Simple Luxury. No Limits. 💎

✅ No maximum limit
✅ Mix & match freely
✅ FREE shipping above ₹498/-

More pieces = more savings on shipping!

www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'gifting',
'["multiple", "quantity", "more than one", "bulk", "many pieces", "zyada", "kai pieces", "2 pieces", "3 pieces", "multiple items", "many items", "lot of", "several", "few pieces", "more pieces", "mix match", "different pieces", "assorted", "variety", "collection", "many products", "bulk order", "large quantity"]'),

-- GROUP 10: Brand
('faq_about', 'About KAAPAV',
'═══════════════════════════
👑 *About KAAPAV*
═══════════════════════════
Simple Luxury. Crafted for You. 💎

Premium Indian fashion jewellery
designed for the modern woman
who loves style without
spending a fortune.

✅ Trendy & timeless designs
✅ Lightweight & comfortable
✅ Starting ₹249/- only

www.kaapav.com
📷 instagram.com/kaapavfashionjewellery
📘 facebook.com/kaapavfashionjewellery
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'brand',
'["about", "kaapav", "brand", "who are you", "tell me", "what is", "brand details", "company", "about brand", "brand info", "kaapav kya hai", "kaapav ke baare mein", "brand story", "your brand", "new brand", "indian brand", "fashion brand", "jewellery brand", "who makes", "founded", "started", "origin", "background", "history", "kaapav brand"]'),

('faq_social', 'Social media links?',
'═══════════════════════════
📱 *Follow KAAPAV*
═══════════════════════════
Simple Luxury. Every Day. 💎

✨ New launches
🔥 Exclusive offers
📸 Styling inspiration
🎁 Giveaways & deals

📷 instagram.com/kaapavfashionjewellery
📘 facebook.com/kaapavfashionjewellery
🌐 www.kaapav.com
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'brand',
'["instagram", "facebook", "social", "follow", "insta", "fb", "social media", "instagram link", "facebook link", "follow karna", "follow us", "page", "kaapav instagram", "kaapav facebook", "handle", "username", "@kaapav", "social page", "online presence", "find online", "kaapav page", "brand page", "official page"]'),

('faq_contact', 'How to contact?',
'═══════════════════════════
💬 *Contact KAAPAV*
═══════════════════════════
Simple Luxury. Always Here. 💎

📧 care.kaapav@gmail.com
🌐 www.kaapav.com
📱 WhatsApp: You are already here!

🕙 10:30 AM – 7:00 PM IST
📅 Monday to Saturday

We respond within 24 hours!
═══════════════════════════
💎 KAAPAV Fashion Jewellery',
'faq', 'brand',
'["contact", "email", "reach", "talk", "human", "support", "help", "contact us", "get in touch", "helpline", "customer care", "customer support", "speak to", "agent", "team", "staff", "real person", "human support", "call", "phone", "number", "contact number", "email id", "mail", "write to us", "feedback", "complaint", "query"]');


-- ═══════════════════════════════════════════════
-- PINCODES TABLE (for pincode serviceability)
-- ═══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS pincodes (
  pincode TEXT PRIMARY KEY,
  city TEXT,
  state TEXT,
  is_serviceable INTEGER DEFAULT 1,
  cod_available INTEGER DEFAULT 1,
  delivery_days INTEGER DEFAULT 4,
  shipping_cost REAL DEFAULT 0,
  courier_priority TEXT DEFAULT '[]'
);

-- ═══════════════════════════════════════════════
-- PUSH SUBSCRIPTIONS
-- ═══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  endpoint TEXT,
  p256dh TEXT,
  auth TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

-- ═══════════════════════════════════════════════
-- FIX FAQ GROUP_NAME — run after inserts
-- Required because INSERT OR IGNORE skips updates
-- on existing rows, leaving group_name = 'general'
-- ═══════════════════════════════════════════════
UPDATE quick_replies SET category = 'faq' WHERE shortcut LIKE 'faq_%';

UPDATE quick_replies SET group_name = 'durability' WHERE shortcut IN ('faq_last','faq_tarnish','faq_daily','faq_plating','faq_strong');
UPDATE quick_replies SET group_name = 'size'       WHERE shortcut IN ('faq_ring_size','faq_bracelet_size','faq_necklace_length','faq_earring_weight','faq_piercing');
UPDATE quick_replies SET group_name = 'pricing'    WHERE shortcut IN ('faq_price','faq_discount','faq_shipping_cost','faq_combo','faq_minimum');
UPDATE quick_replies SET group_name = 'ordering'   WHERE shortcut IN ('faq_how_order','faq_cod','faq_payment_safe','faq_confirmation','faq_gift_order');
UPDATE quick_replies SET group_name = 'delivery'   WHERE shortcut IN ('faq_delivery_time','faq_delivery_area','faq_packaging','faq_track','faq_delayed');
UPDATE quick_replies SET group_name = 'returns'    WHERE shortcut IN ('faq_return','faq_damaged','faq_refund_time','faq_exchange','faq_cancel');
UPDATE quick_replies SET group_name = 'care'       WHERE shortcut IN ('faq_care','faq_perfume','faq_sleep');
UPDATE quick_replies SET group_name = 'gifting'    WHERE shortcut IN ('faq_gifting','faq_gift_pack','faq_multiple');
UPDATE quick_replies SET group_name = 'brand'      WHERE shortcut IN ('faq_about','faq_social','faq_contact');

ALTER TABLE products ADD COLUMN website_link TEXT;
ALTER TABLE products ADD COLUMN material TEXT;
ALTER TABLE products ADD COLUMN tags TEXT DEFAULT '[]';
ALTER TABLE orders ADD COLUMN shiprocket_order_id TEXT;
ALTER TABLE orders ADD COLUMN awb_code TEXT;
ALTER TABLE orders ADD COLUMN return_requested INTEGER DEFAULT 0;
ALTER TABLE orders ADD COLUMN return_reason TEXT;
ALTER TABLE orders ADD COLUMN return_requested_at TEXT;
ALTER TABLE orders ADD COLUMN review_sent INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN reserved_stock INTEGER DEFAULT 0;
