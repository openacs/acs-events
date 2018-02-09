-- Upgrade acs-events from 0.6 to 0.6.1
-- Fixes typo in index name "acs_events_activity_id_ids"

DROP INDEX IF EXISTS acs_events_activity_id_ids;
CREATE INDEX IF NOT EXISTS acs_events_activity_id_idx ON acs_events(activity_id);
