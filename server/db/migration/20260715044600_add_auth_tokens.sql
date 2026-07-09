-- +goose Up
CREATE TABLE auth_tokens (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id int NOT NULL REFERENCES users (id),
    device_kind text NOT NULL,
    token_hash bytea NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL default now()
);

-- +goose Down
DROP TABLE auth_tokens;
