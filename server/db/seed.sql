CREATE TABLE feeds (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    url text NOT NULL UNIQUE,
    site_url text,
    icon_url text,
    title text NOT NULL,
    description text
);

CREATE TABLE feed_entries (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dedup_key text NOT NULL UNIQUE,
    feed_id bigint NOT NULL REFERENCES feeds (id),
    url text NOT NULL,
    title text NOT NULL,
    description text,
    content text,
    snapshot_at timestamptz NOT NULL,
    published_at timestamptz
);

CREATE TABLE newspapers (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    published_at timestamptz NOT NULL UNIQUE,
    draft boolean NOT NULL DEFAULT true
);

CREATE TABLE stories (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    feed_entry_id bigint NOT NULL REFERENCES feed_entries (id),
    newspaper_id bigint REFERENCES newspapers (id),
    title text NOT NULL,
    description text,
    published_at timestamptz,
    source text
);

CREATE TABLE newspaper_schedules (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    label text NOT NULL,
    -- 1439min = 60min * 24h - 1min = 23h 59min
    minute_of_date integer NOT NULL CHECK (minute_of_date BETWEEN 0 AND 1439)
);

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

INSERT INTO newspaper_schedules (label, minute_of_date)
VALUES ('Morning', 420), ('Afternoon', 780), ('Evening', 1140);

INSERT INTO feeds (url, site_url, icon_url, title, description)
VALUES
(
    'https://raw.githubusercontent.com/Olshansk/rss-feeds/main/feeds/feed_anthropic_engineering.xml',
    'https://www.anthropic.com/engineering',
    'https://www.anthropic.com/images/icons/apple-touch-icon.png',
    'Anthropic Engineering Blog',
    'Inside the team building reliable AI systems'
),
(
    'https://raw.githubusercontent.com/Olshansk/rss-feeds/main/feeds/feed_cursor.xml',
    'https://cursor.com/blog',
    'https://cursor.com/favicon.ico',
    'Cursor Blog',
    'Latest updates from Cursor'
),
(
    'https://feeds.cnn.co.jp/rss/cnn/cnn.rdf',
    'https://www.cnn.co.jp',
    null,
    '国際ニュース - CNN.co.jp',
    'CNN.co.jpはCNN.com日本語訳サイトです'
),
(
    'https://news.mit.edu/rss/topic/philosophy',
    null,
    null,
    'MIT News - Philosophy | Ethics | Metaphysics',
    null
),
('https://research.swtch.com/feed.atom', null, null, 'research!rsc', null),
(
    'https://www.wheresyoured.at/rss/',
    'https://www.wheresyoured.at/',
    null,
    'Ed Zitron''s Where''s Your Ed At',
    null
),
(
    'https://www.youtube.com/feeds/videos.xml?playlist_id=UULFrDwWp7EBBv4NwvScIpBDOA',
    null,
    null,
    'Anthropic-YouTube',
    null
),
(
    'https://blog.samaltman.com/posts.atom',
    'https://blog.samaltman.com',
    null,
    'Sam Altman',
    null
),
(
    'https://api.reddit.com/subreddit/Vulfpeck',
    'https://www.reddit.com/r/Vulfpeck/new',
    null,
    'r/Vulfpeck',
    null
),
(
    'https://news.mit.edu/topic/mitartificial-intelligence2-rss.xml',
    null,
    null,
    'MIT News - Artificial intelligence',
    null
),
(
    'https://github.blog/changelog/rss',
    'https://github.blog/changelog/',
    null,
    'Archive: 2026 - GitHub Changelog',
    null
),
(
    'http://9to5google.com/feed/',
    'https://9to5google.com/',
    null,
    '9to5Google',
    null
),
(
    'https://raw.githubusercontent.com/Olshansk/rss-feeds/main/feeds/feed_anthropic_research.xml',
    'https://www.anthropic.com/research',
    null,
    'Anthropic Research',
    null
),
(
    'https://www.technologyreview.jp/feed/',
    'https://www.technologyreview.jp',
    null,
    'MITテクノロジーレビュー',
    null
),
(
    'https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/dynamodbupdates.rss',
    'https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/',
    null,
    'Amazon DynamoDB Developer Guide Updates',
    null
),
(
    'https://www.youtube.com/feeds/videos.xml?channel_id=UCrDwWp7EBBv4NwvScIpBDOA',
    'https://www.youtube.com/channel/UCrDwWp7EBBv4NwvScIpBDOA',
    null,
    'Anthropic',
    null
),
(
    'http://hnrss.org/newest?points=100',
    'https://news.ycombinator.com/newest',
    null,
    'Hacker News: Newest',
    null
),
(
    'https://joisino.hatenablog.com/feed',
    'https://joisino.hatenablog.com/',
    null,
    'ｼﾞｮｲｼﾞｮｲｼﾞｮｲ',
    null
),
(
    'http://googleblog.blogspot.com/atom.xml',
    'https://blog.google/',
    null,
    'The Official Google Blog',
    null
),
(
    'https://blog.openai.com/rss/',
    'https://blog.openai.com',
    null,
    'OpenAI',
    null
),
(
    'http://www.androidcentral.com/feed',
    'https://www.androidcentral.com',
    null,
    'Latest from Android Central',
    null
),
(
    'https://www.youtube.com/feeds/videos.xml?channel_id=UCXZCJLdBC09xxGZ6gcdrc6A',
    'https://www.youtube.com/channel/UCXZCJLdBC09xxGZ6gcdrc6A',
    null,
    'OpenAI',
    null
),
(
    'http://www.technologyreview.com/computing/rss/',
    'https://www.technologyreview.com',
    null,
    'Computing – MIT Technology Review',
    null
),
('http://9to5mac.com/feed/', 'https://9to5mac.com/', null, '9to5Mac', null),
(
    'http://www.macrumors.com/macrumors.xml',
    'https://www.macrumors.com',
    null,
    'MacRumors',
    null
),
(
    'https://github.com/blog/all.atom',
    'https://github.blog/',
    null,
    'The GitHub Blog',
    null
),
(
    'http://iosdevweekly.com/issues.rss',
    'https://main--iosdevweekly.netlify.app/',
    null,
    'iOS Dev Weekly',
    null
),
(
    'https://www.youtube.com/feeds/videos.xml?channel_id=UCwXdFgeE9KYzlDdR7TG9cMw',
    'https://www.youtube.com/channel/UCwXdFgeE9KYzlDdR7TG9cMw',
    null,
    'Flutter',
    null
),
(
    'https://dart.dev/blog/feed.xml',
    'https://dart.dev/blog',
    null,
    'The Dart Blog',
    'Dart is an approachable, portable, and productive language for high-quality apps on any platform.'
),
('https://blog.golang.org/feed.atom', null, null, 'The Go Blog', null),
(
    'https://github.com/flutter/flutter/releases.atom',
    'https://github.com/flutter/flutter/releases',
    null,
    'Release notes from flutter',
    null
),
(
    'https://zenn.dev/schroneko/feed',
    'https://zenn.dev/schroneko',
    null,
    'ぬこぬこさんのフィード',
    null
),
(
    'https://medium.com/feed/flutter-io',
    'https://blog.flutter.dev/',
    null,
    'Flutter - Medium',
    null
);
