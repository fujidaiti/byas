import 'package:openapi/api.dart' as api;

/// A shared universe of fixtures for the widget tests.
final fixture = (
  feeds: (
    bbcNews: _bbcNews,
    nasa: _nasa,
    stackOverflow: _stackOverflow,
    wikipedia: _wikipedia,
  ),
  entries: (
    nuclearDeal: _nuclearDeal,
    houthiStrikes: _houthiStrikes,
    moonshotAi: _moonshotAi,
  ),
  webClips: (buildingEffectiveAgents: _buildingEffectiveAgents),
  candidates: (
    // What /feeds/search returns before NASA is subscribed to.
    nasa: api.FeedCandidate(
      url: _nasa.url,
      siteUrl: _nasa.siteUrl,
      iconUrl: 'https://www.google.com/s2/favicons?domain=nasa.gov&sz=64',
      title: _nasa.title,
      description: _nasa.description,
    ),
  ),
  stories: (
    nuclearDeal: api.Story(
      id: 1,
      resourceId: _nuclearDeal.id,
      kind: api.StoryKindEnum.feedEntry,
      title: _nuclearDeal.title,
      source_: _bbcNews.title,
    ),
  ),
  readingList: (
    savedWebClip: api.ReadingListItem(
      id: 1,
      resourceId: _buildingEffectiveAgents.id,
      kind: api.ReadingListItemKindEnum.webClip,
      title: _buildingEffectiveAgents.title!,
      savedAt: DateTime.utc(2026, 7, 1),
    ),
    savedFeedEntry: api.ReadingListItem(
      id: 5,
      resourceId: _nuclearDeal.id,
      kind: api.ReadingListItemKindEnum.feedEntry,
      title: _nuclearDeal.title,
      savedAt: DateTime.utc(2026, 7, 1),
    ),
  ),
);

final _bbcNews = api.Feed(
  id: 1,
  url: 'http://feeds.bbci.co.uk/news/rss.xml',
  siteUrl: 'https://www.bbc.co.uk/news',
  iconUrl: 'https://news.bbcimg.co.uk/nol/shared/img/bbc_news_120x60.gif',
  title: 'BBC News',
  description: 'BBC News - News Front Page',
);

final _nasa = api.Feed(
  id: 2,
  url: 'http://www.nasa.gov/news-release/feed/',
  siteUrl: 'https://www.nasa.gov',
  title: 'NASA',
  description: 'Official National Aeronautics and Space Administration Website',
);

final _stackOverflow = api.Feed(
  id: 3,
  url: 'http://stackoverflow.com/feeds',
  siteUrl: 'https://stackoverflow.com/questions',
  title: 'Recent Questions - Stack Overflow',
  description: 'most recent 30 from stackoverflow.com',
);

final _wikipedia = api.Feed(
  id: 4,
  url:
      'http://en.wikipedia.org/w/api.php?limit=50&action=feedrecentchanges&feedformat=rss',
  siteUrl: 'https://en.wikipedia.org/wiki/Special:RecentChanges',
  title: 'Wikipedia  - Recent changes [en]',
  description: 'Track the most recent changes to the wiki in this feed.',
);

final _nuclearDeal = api.FeedEntry(
  id: 11,
  feedId: _bbcNews.id,
  url: 'https://www.bbc.co.uk/news/articles/cj03r59z73po',
  title: 'US signs landmark nuclear deal with Saudi Arabia',
  content:
      '<article><p>The US Department of Energy says the "peaceful" '
      'co-operation agreement will give US firms great access to the Saudi '
      'nuclear energy programme.</p></article>',
  snapshotAt: DateTime.utc(2026, 7, 23),
);

final _houthiStrikes = api.FeedEntry(
  id: 12,
  feedId: _bbcNews.id,
  url: 'https://www.bbc.co.uk/news/articles/cpw9xzx9r4ko',
  title:
      'Houthis claim attack on oil tankers as US launches more strikes on Iran',
  snapshotAt: DateTime.utc(2026, 7, 23),
);

final _moonshotAi = api.FeedEntry(
  id: 13,
  feedId: _bbcNews.id,
  url: 'https://www.bbc.co.uk/news/articles/c5ye2gyz0x4o',
  title: "China's Moonshot AI stole from Anthropic, Trump tech adviser says",
  snapshotAt: DateTime.utc(2026, 7, 23),
);

final _buildingEffectiveAgents = api.GetWebClip200Response(
  id: 7,
  url: 'https://www.anthropic.com/engineering/building-effective-agents',
  title: 'Building effective agents',
  content:
      '<article><p>The most successful implementations use simple, composable '
      'patterns rather than complex frameworks.</p></article>',
);
