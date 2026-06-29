ALTER TABLE stories ADD COLUMN source text;
-- Use feed title as the source of existing stories
UPDATE stories AS s
SET source = f.title
FROM entries AS e
JOIN feeds AS f ON f.id = e.feed_id
WHERE e.id = s.entry_id;
