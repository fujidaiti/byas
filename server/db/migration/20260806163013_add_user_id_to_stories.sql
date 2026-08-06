-- +goose Up
ALTER TABLE stories ADD user_id int REFERENCES users (id);

-- Backfill a user to all stories' user_id (assuming there's exactly one user)
UPDATE stories SET user_id = (SELECT id FROM users LIMIT 1);

ALTER TABLE stories ALTER COLUMN user_id SET NOT NULL;


-- +goose Down
ALTER TABLE stories DROP COLUMN user_id;
