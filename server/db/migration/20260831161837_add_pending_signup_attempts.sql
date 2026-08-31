-- +goose Up
CREATE TABLE pending_signup_attempts (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL,
    password_hash bytea NOT NULL,
    verification_code_hash bytea NOT NULL,
    ticket_hash bytea NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    fail_count int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX pending_signup_attempts_email_created_at_idx
    ON pending_signup_attempts (email, created_at);

-- +goose Down
DROP TABLE pending_signup_attempts;
