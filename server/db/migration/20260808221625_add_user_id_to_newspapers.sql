-- +goose Up
ALTER TABLE newspapers ADD user_id int REFERENCES users (id);

-- Backfill a user to all newspapers' user_id (assuming there's exactly one user)
UPDATE newspapers SET user_id = (SELECT id FROM users LIMIT 1);

ALTER TABLE newspapers ALTER COLUMN user_id SET NOT NULL;

ALTER TABLE newspapers DROP CONSTRAINT newspapers_published_at_key;
ALTER TABLE newspapers ADD CONSTRAINT uq_newspaper_per_user UNIQUE (user_id, published_at);

-- +goose Down
ALTER TABLE newspapers DROP CONSTRAINT uq_newspaper_per_user;
ALTER TABLE newspapers ADD CONSTRAINT newspapers_published_at_key UNIQUE (published_at);
ALTER TABLE newspapers DROP COLUMN user_id;
