CREATE TABLE feeds (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    url text NOT NULL UNIQUE,
    site_url text,
    icon_url text,
    title text NOT NULL,
    description text
);

CREATE TABLE entries (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dedup_key text NOT NULL UNIQUE,
    feed_id bigint NOT NULL REFERENCES feeds (id),
    url text NOT NULL,
    title text NOT NULL,
    description text,
    content text,
    published_at timestamptz
);

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
    NULL,
    '国際ニュース - CNN.co.jp',
    'CNN.co.jpはCNN.com日本語訳サイトです'
);
