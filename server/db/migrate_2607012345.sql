CREATE TABLE web_clips (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  url text NOT NULL,
  title text,
  description text,
  content text,
  fetch_status text NOT NULL DEFAULT 'pending'
    CHECK (fetch_status IN ('pending', 'done', 'failed')),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_content_when_done CHECK (
    (fetch_status = 'done' AND content IS NOT NULL) OR
    (fetch_status != 'done' AND content IS NULL)
  )
);

CREATE TABLE reading_list_items (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind          text NOT NULL CHECK (kind IN ('feed_entry', 'web_clip')),
  web_clip_id bigint REFERENCES web_clips (id),
  feed_entry_id bigint REFERENCES feed_entries (id),
  title         text NOT NULL,
  description   text,
  archived      boolean NOT NULL DEFAULT false,
  saved_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_kind_and_id CHECK (
    (kind = 'feed_entry' AND feed_entry_id IS NOT NULL AND web_clip_id IS NULL) OR
    (kind = 'web_clip' AND feed_entry_id IS NULL AND web_clip_id is NOT NULL)
  )
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_web_clips_updated_at
BEFORE UPDATE ON web_clips
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
