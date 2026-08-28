ALTER TABLE return_requests
ADD COLUMN payment_id TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_id TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_idempotency_key TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_status TEXT NOT NULL DEFAULT 'not_started';

ALTER TABLE return_requests
ADD COLUMN refund_gateway TEXT NOT NULL DEFAULT '';

ALTER TABLE return_requests
ADD COLUMN refund_method TEXT NOT NULL DEFAULT 'original_payment';

ALTER TABLE return_requests
ADD COLUMN refund_currency TEXT NOT NULL DEFAULT 'INR';

ALTER TABLE return_requests
ADD COLUMN refund_speed_requested TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_speed_processed TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_acquirer_reference TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_acquirer_reference_type TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_reference TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_failure_reason TEXT NOT NULL DEFAULT '';

ALTER TABLE return_requests
ADD COLUMN approved_by TEXT NOT NULL DEFAULT '';

ALTER TABLE return_requests
ADD COLUMN refund_initiated_at TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_processed_at TEXT;

ALTER TABLE return_requests
ADD COLUMN refund_failed_at TEXT;

CREATE TABLE IF NOT EXISTS return_refund_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  event_id TEXT NOT NULL UNIQUE,
  request_id TEXT NOT NULL,
  order_id TEXT NOT NULL,

  payment_id TEXT,
  refund_id TEXT,

  event_type TEXT NOT NULL,
  refund_status TEXT NOT NULL DEFAULT '',

  amount REAL NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'INR',

  acquirer_reference TEXT,
  acquirer_reference_type TEXT,

  payload_json TEXT NOT NULL DEFAULT '{}',

  processing_status TEXT NOT NULL DEFAULT 'received',
  error_message TEXT NOT NULL DEFAULT '',

  received_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  processed_at TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_return_requests_refund_id
  ON return_requests(refund_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_return_requests_refund_idempotency
  ON return_requests(refund_idempotency_key);

CREATE INDEX IF NOT EXISTS idx_return_requests_refund_status
  ON return_requests(refund_status);

CREATE INDEX IF NOT EXISTS idx_return_refund_events_request_id
  ON return_refund_events(request_id);

CREATE INDEX IF NOT EXISTS idx_return_refund_events_order_id
  ON return_refund_events(order_id);

CREATE INDEX IF NOT EXISTS idx_return_refund_events_refund_id
  ON return_refund_events(refund_id);

CREATE INDEX IF NOT EXISTS idx_return_refund_events_event_type
  ON return_refund_events(event_type);

CREATE INDEX IF NOT EXISTS idx_return_refund_events_received_at
  ON return_refund_events(received_at);