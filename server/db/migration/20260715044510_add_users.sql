-- +goose Up
CREATE TABLE users (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL UNIQUE,
    password_hash bytea NOT NULL,
    created_at timestamptz NOT NULL default now()
);

-- +goose Down
DROP TABLE users;
