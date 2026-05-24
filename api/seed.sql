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
    snapshot_at timestamptz NOT NULL,
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
),
(
    'https://news.mit.edu/rss/topic/philosophy',
    NULL,
    NULL,
    'MIT News - Philosophy | Ethics | Metaphysics',
    NULL
),
('https://research.swtch.com/feed.atom', NULL, NULL, 'research!rsc', NULL),
(
    'https://www.wheresyoured.at/rss/',
    'https://www.wheresyoured.at/',
    NULL,
    'Ed Zitron''s Where''s Your Ed At',
    NULL
),
(
    'https://www.youtube.com/feeds/videos.xml?playlist_id=UULFrDwWp7EBBv4NwvScIpBDOA',
    NULL,
    NULL,
    'Anthropic-YouTube',
    NULL
),
(
    'https://blog.samaltman.com/posts.atom',
    'https://blog.samaltman.com',
    NULL,
    'Sam Altman',
    NULL
),
(
    'https://api.reddit.com/subreddit/Vulfpeck',
    'https://www.reddit.com/r/Vulfpeck/new',
    NULL,
    'r/Vulfpeck',
    NULL
),
(
    'https://news.mit.edu/topic/mitartificial-intelligence2-rss.xml',
    NULL,
    NULL,
    'MIT News - Artificial intelligence',
    NULL
),
(
    'https://github.blog/changelog/rss',
    'https://github.blog/changelog/',
    NULL,
    'Archive: 2026 - GitHub Changelog',
    NULL
),
(
    'http://9to5google.com/feed/',
    'https://9to5google.com/',
    NULL,
    '9to5Google',
    NULL
),
(
    'https://raw.githubusercontent.com/Olshansk/rss-feeds/main/feeds/feed_anthropic_research.xml',
    'https://www.anthropic.com/research',
    NULL,
    'Anthropic Research',
    NULL
),
(
    'https://www.technologyreview.jp/feed/',
    'https://www.technologyreview.jp',
    NULL,
    'MITテクノロジーレビュー',
    NULL
),
(
    'https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/dynamodbupdates.rss',
    'https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/',
    NULL,
    'Amazon DynamoDB Developer Guide Updates',
    NULL
),
(
    'https://www.youtube.com/feeds/videos.xml?channel_id=UCrDwWp7EBBv4NwvScIpBDOA',
    'https://www.youtube.com/channel/UCrDwWp7EBBv4NwvScIpBDOA',
    NULL,
    'Anthropic',
    NULL
),
(
    'http://hnrss.org/newest?points=100',
    'https://news.ycombinator.com/newest',
    NULL,
    'Hacker News: Newest',
    NULL
),
(
    'https://joisino.hatenablog.com/feed',
    'https://joisino.hatenablog.com/',
    NULL,
    'ｼﾞｮｲｼﾞｮｲｼﾞｮｲ',
    NULL
),
(
    'http://googleblog.blogspot.com/atom.xml',
    'https://blog.google/',
    NULL,
    'The Official Google Blog',
    NULL
),
(
    'https://blog.openai.com/rss/',
    'https://blog.openai.com',
    NULL,
    'OpenAI',
    NULL
),
(
    'http://www.androidcentral.com/feed',
    'https://www.androidcentral.com',
    NULL,
    'Latest from Android Central',
    NULL
),
(
    'https://www.youtube.com/feeds/videos.xml?channel_id=UCXZCJLdBC09xxGZ6gcdrc6A',
    'https://www.youtube.com/channel/UCXZCJLdBC09xxGZ6gcdrc6A',
    NULL,
    'OpenAI',
    NULL
),
(
    'http://www.technologyreview.com/computing/rss/',
    'https://www.technologyreview.com',
    NULL,
    'Computing – MIT Technology Review',
    NULL
),
('http://9to5mac.com/feed/', 'https://9to5mac.com/', NULL, '9to5Mac', NULL),
(
    'http://www.macrumors.com/macrumors.xml',
    'https://www.macrumors.com',
    NULL,
    'MacRumors',
    NULL
),
(
    'https://github.com/blog/all.atom',
    'https://github.blog/',
    NULL,
    'The GitHub Blog',
    NULL
),
(
    'http://iosdevweekly.com/issues.rss',
    'https://main--iosdevweekly.netlify.app/',
    NULL,
    'iOS Dev Weekly',
    NULL
),
(
    'https://www.youtube.com/feeds/videos.xml?channel_id=UCwXdFgeE9KYzlDdR7TG9cMw',
    'https://www.youtube.com/channel/UCwXdFgeE9KYzlDdR7TG9cMw',
    NULL,
    'Flutter',
    NULL
),
(
    'https://dart.dev/blog/feed.xml',
    'https://dart.dev/blog',
    NULL,
    'The Dart Blog',
    'Dart is an approachable, portable, and productive language for high-quality apps on any platform.'
),
('https://blog.golang.org/feed.atom', NULL, NULL, 'The Go Blog', NULL),
(
    'https://github.com/flutter/flutter/releases.atom',
    'https://github.com/flutter/flutter/releases',
    NULL,
    'Release notes from flutter',
    NULL
),
(
    'https://zenn.dev/schroneko/feed',
    'https://zenn.dev/schroneko',
    NULL,
    'ぬこぬこさんのフィード',
    NULL
),
(
    'https://medium.com/feed/flutter-io',
    'https://blog.flutter.dev/',
    NULL,
    'Flutter - Medium',
    NULL
);
