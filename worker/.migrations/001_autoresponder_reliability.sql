-- KAAPAV autoresponder reliability migration
-- Safe to run more than once.

CREATE TABLE IF NOT EXISTS autoresponder_state (
  phone TEXT PRIMARY KEY,
  state TEXT NOT NULL,
  data TEXT NOT NULL DEFAULT '{}',
  started_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_autoresponder_state_expiry
  ON autoresponder_state(expires_at);

CREATE TABLE IF NOT EXISTS autoresponder_jobs (
  message_id TEXT PRIMARY KEY,
  phone TEXT NOT NULL,
  customer_name TEXT,
  text TEXT,
  message_type TEXT NOT NULL DEFAULT 'unknown',
  button_id TEXT,
  payload_json TEXT NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'retry', 'completed', 'skipped', 'failed')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  next_attempt_at TEXT NOT NULL DEFAULT (datetime('now')),
  locked_at TEXT,
  last_error TEXT,
  outcome TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  completed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_autoresponder_jobs_due
  ON autoresponder_jobs(status, next_attempt_at, created_at);

CREATE INDEX IF NOT EXISTS idx_autoresponder_jobs_phone
  ON autoresponder_jobs(phone, created_at);

-- Legacy conversation_state rows are migrated and self-healed by the Worker.
-- No destructive legacy-table statement is included because older deployments
-- use different column names (state/data vs current_flow/current_step/flow_data).
