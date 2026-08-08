-- +goose Up
ALTER TABLE reading_list_items ADD user_id int REFERENCES users (id);

-- Backfill a user to all reading list items' user_id (assuming there's exactly one user)
UPDATE reading_list_items SET user_id = (SELECT id FROM users LIMIT 1);

ALTER TABLE reading_list_items ALTER COLUMN user_id SET NOT NULL;

-- +goose Down
ALTER TABLE reading_list_items DROP COLUMN user_id;
