DROP TABLE IF EXISTS customer_otps;
DROP TABLE IF EXISTS customer_auth_sessions;
DROP TABLE IF EXISTS customer_accounts;
DROP TABLE IF EXISTS customer_addresses;
DROP TABLE IF EXISTS customer_wishlist;

CREATE TABLE IF NOT EXISTS customer_accounts (
  email TEXT PRIMARY KEY,
  name TEXT,
  phone TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS customer_otps (
  email TEXT PRIMARY KEY,
  otp_hash TEXT NOT NULL,
  attempts INTEGER DEFAULT 0,
  expires_at TEXT NOT NULL,
  consumed_at TEXT,
  last_sent_at TEXT DEFAULT (datetime('now')),
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS customer_auth_sessions (
  token_hash TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  last_seen_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS customer_addresses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  pincode TEXT,
  is_default INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS customer_wishlist (
  email TEXT NOT NULL,
  sku TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  PRIMARY KEY (email, sku)
);

CREATE INDEX IF NOT EXISTS idx_customer_sessions_email ON customer_auth_sessions(email);
CREATE INDEX IF NOT EXISTS idx_customer_sessions_expiry ON customer_auth_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_email ON customer_addresses(email);
CREATE INDEX IF NOT EXISTS idx_customer_wishlist_email ON customer_wishlist(email);
