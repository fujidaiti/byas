BEGIN;

ALTER TABLE entries RENAME TO feed_entries;
ALTER TABLE feed_entries RENAME CONSTRAINT entries_pkey TO feed_entries_pkey;
ALTER TABLE feed_entries RENAME CONSTRAINT entries_dedup_key_key TO feed_entries_dedup_key_key;
ALTER TABLE feed_entries RENAME CONSTRAINT entries_feed_id_fkey TO feed_entries_feed_id_fkey;
ALTER SEQUENCE entries_id_seq RENAME TO feed_entries_id_seq;

ALTER TABLE stories RENAME COLUMN entry_id TO feed_entry_id;
ALTER TABLE stories RENAME CONSTRAINT stories_entry_id_fkey TO stories_feed_entry_id_fkey;

COMMIT;
