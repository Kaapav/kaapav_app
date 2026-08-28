-- ═══════════════════════════════════════════════
-- 003_return_tracking_awb.sql
-- Reverse Logistics & Return Tracking Columns
-- ═══════════════════════════════════════════════

ALTER TABLE return_requests
ADD COLUMN return_courier TEXT NOT NULL DEFAULT '';

ALTER TABLE return_requests
ADD COLUMN return_awb_number TEXT NOT NULL DEFAULT '';

ALTER TABLE return_requests
ADD COLUMN return_shipment_id TEXT NOT NULL DEFAULT '';

ALTER TABLE return_requests
ADD COLUMN return_tracking_url TEXT NOT NULL DEFAULT '';

ALTER TABLE return_requests
ADD COLUMN pickup_scheduled_date TEXT;

CREATE INDEX IF NOT EXISTS idx_return_requests_return_awb
  ON return_requests(return_awb_number);
