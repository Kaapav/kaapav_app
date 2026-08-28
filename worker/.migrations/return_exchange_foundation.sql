CREATE TABLE IF NOT EXISTS return_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  request_id TEXT NOT NULL UNIQUE,
  order_id TEXT NOT NULL,

  phone TEXT NOT NULL DEFAULT '',
  customer_name TEXT NOT NULL DEFAULT '',

  request_type TEXT NOT NULL
    CHECK (request_type IN ('return', 'exchange')),

  request_scope TEXT NOT NULL DEFAULT 'items'
    CHECK (request_scope IN ('full_order', 'items')),

  reason_code TEXT NOT NULL DEFAULT 'other',
  reason_text TEXT NOT NULL DEFAULT '',
  customer_note TEXT NOT NULL DEFAULT '',

  evidence_urls_json TEXT NOT NULL DEFAULT '[]',

  status TEXT NOT NULL DEFAULT 'requested'
    CHECK (
      status IN (
        'requested',
        'approved',
        'rejected',
        'pickup_scheduled',
        'picked_up',
        'received',
        'qc_pending',
        'qc_passed',
        'qc_failed',
        'refund_pending',
        'refunded',
        'exchange_pending',
        'exchange_shipped',
        'completed',
        'cancelled'
      )
    ),

  reverse_shipping_fee REAL NOT NULL DEFAULT 60,
  refund_amount REAL NOT NULL DEFAULT 0,
  price_difference REAL NOT NULL DEFAULT 0,

  owner_note TEXT NOT NULL DEFAULT '',

  requested_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  approved_at TEXT,
  rejected_at TEXT,
  pickup_scheduled_at TEXT,
  picked_up_at TEXT,
  received_at TEXT,
  qc_completed_at TEXT,
  completed_at TEXT,
  cancelled_at TEXT,

  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS return_request_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  request_id TEXT NOT NULL,
  order_id TEXT NOT NULL,

  line_index INTEGER NOT NULL DEFAULT 0,
  sku TEXT NOT NULL,
  product_name TEXT NOT NULL DEFAULT '',

  quantity INTEGER NOT NULL DEFAULT 1
    CHECK (quantity > 0),

  unit_price REAL NOT NULL DEFAULT 0,

  replacement_sku TEXT,
  replacement_name TEXT,
  replacement_unit_price REAL,

  condition_note TEXT NOT NULL DEFAULT '',
  evidence_urls_json TEXT NOT NULL DEFAULT '[]',

  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE (request_id, line_index)
);

CREATE INDEX IF NOT EXISTS idx_return_requests_order_id
  ON return_requests(order_id);

CREATE INDEX IF NOT EXISTS idx_return_requests_phone
  ON return_requests(phone);

CREATE INDEX IF NOT EXISTS idx_return_requests_status
  ON return_requests(status);

CREATE INDEX IF NOT EXISTS idx_return_requests_type
  ON return_requests(request_type);

CREATE INDEX IF NOT EXISTS idx_return_requests_created_at
  ON return_requests(created_at);

CREATE INDEX IF NOT EXISTS idx_return_request_items_request_id
  ON return_request_items(request_id);

CREATE INDEX IF NOT EXISTS idx_return_request_items_order_id
  ON return_request_items(order_id);

CREATE INDEX IF NOT EXISTS idx_return_request_items_sku
  ON return_request_items(sku);