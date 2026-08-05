-- +goose Up
CREATE TABLE feed_subscriptions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id int REFERENCES users (id),
    feed_id bigint REFERENCES feeds (id),
    CONSTRAINT uq_feed_per_user UNIQUE (user_id, feed_id)
);

-- +goose Down
DROP TABLE feed_subscriptions;
