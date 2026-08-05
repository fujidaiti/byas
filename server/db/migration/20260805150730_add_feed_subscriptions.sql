-- +goose Up
CREATE TABLE feed_subscriptions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id int NOT NULL REFERENCES users (id),
    feed_id bigint NOT NULL REFERENCES feeds (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_feed_per_user UNIQUE (user_id, feed_id)
);

-- +goose Down
DROP TABLE feed_subscriptions;
