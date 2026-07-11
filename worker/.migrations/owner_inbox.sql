CREATE TABLE IF NOT EXISTS owner_alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  alert_key TEXT UNIQUE,
  type TEXT NOT NULL,
  priority TEXT DEFAULT 'normal',
  title TEXT NOT NULL,
  body TEXT,
  order_id TEXT,
  phone TEXT,
  customer_name TEXT,
  amount REAL DEFAULT 0,
  source TEXT,
  action_type TEXT,
  action_label TEXT,
  action_url TEXT,
  meta_json TEXT DEFAULT '{}',
  is_read INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  read_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_owner_alerts_created
ON owner_alerts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_owner_alerts_read
ON owner_alerts(is_read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_owner_alerts_type
ON owner_alerts(type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_owner_alerts_order
ON owner_alerts(order_id);