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
