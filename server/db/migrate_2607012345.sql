CREATE TABLE reading_list_items (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind          text NOT NULL CHECK (kind IN ('feed_entry', 'web_article')),
  feed_entry_id bigint REFERENCES feed_entries (id),
  title         text NOT NULL,
  description   text,
  archived      boolean NOT NULL DEFAULT false,
  saved_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_kind_and_id CHECK (
    (kind = 'feed_entry' AND feed_entry_id IS NOT NULL) OR
    (kind = 'web_article' AND feed_entry_id IS NULL)
  )
);

CREATE TABLE reading_list_item_web_article_details (
  reading_list_item_id bigint PRIMARY KEY
                            REFERENCES reading_list_items (id)
                            ON DELETE CASCADE,
  url                   text NOT NULL,
  content               text,
  fetch_status          text NOT NULL DEFAULT 'pending'
                            CHECK (fetch_status IN ('pending', 'done', 'failed')),
  updated_at            timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_content_when_done CHECK (
    (fetch_status = 'done' AND content IS NOT NULL) OR
    (fetch_status != 'done' AND content IS NULL)
  )
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reading_list_item_web_article_details_updated_at
BEFORE UPDATE ON reading_list_item_web_article_details
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
