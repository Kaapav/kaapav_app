CREATE TABLE IF NOT EXISTS customer_otps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  otp_hash TEXT NOT NULL,
  attempts INTEGER DEFAULT 0,
  expires_at TEXT NOT NULL,
  consumed_at TEXT,
  last_sent_at TEXT DEFAULT (datetime('now')),
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS customer_auth_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  token_hash TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  last_seen_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_customer_otps_email ON customer_otps(email);
CREATE INDEX IF NOT EXISTS idx_customer_auth_sessions_token ON customer_auth_sessions(token_hash);
CREATE INDEX IF NOT EXISTS idx_customer_auth_sessions_email ON customer_auth_sessions(email);
