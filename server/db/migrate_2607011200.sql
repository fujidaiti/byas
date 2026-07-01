ALTER TABLE entries RENAME TO feed_entries;
ALTER TABLE stories RENAME COLUMN entry_id TO feed_entry_id;
