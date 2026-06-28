import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/features/entry/presentation/entry_reader_screen.dart';
import 'package:paperdoll/features/feed/presentation/feed_detail_screen.dart';
import 'package:paperdoll/features/feed/presentation/feed_search_screen.dart';
import 'package:paperdoll/features/feed/presentation/feeds_screen.dart';
import 'package:paperdoll/features/newspaper/presentation/story_reader_screen.dart';
import 'package:paperdoll/features/newspaper/presentation/today_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's navigation graph: a bottom-nav shell over Today and Feeds, with
/// detail/discovery screens nested under each branch. The story and entry
/// readers push onto the root navigator so they cover the bottom nav bar.
@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: routeTodayPath,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: routeTodayPath,
                name: routeTodayName,
                builder: (context, state) => const TodayScreen(),
                routes: [
                  GoRoute(
                    path: routeStoryPath,
                    name: routeStoryName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        StoryReaderScreen(id: _idParam(state, 'id')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: routeFeedsPath,
                name: routeFeedsName,
                builder: (context, state) => const FeedsScreen(),
                routes: [
                  GoRoute(
                    path: routeFeedSearchPath,
                    name: routeFeedSearchName,
                    builder: (context, state) => const FeedSearchScreen(),
                  ),
                  GoRoute(
                    path: routeFeedDetailPath,
                    name: routeFeedDetailName,
                    builder: (context, state) =>
                        FeedDetailScreen(id: _idParam(state, 'id')),
                    routes: [
                      GoRoute(
                        path: routeEntryReaderPath,
                        name: routeEntryReaderName,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            EntryReaderScreen(id: _idParam(state, 'entryId')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

int _idParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? -1;

class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Today',
          ),
          NavigationDestination(icon: Icon(Icons.rss_feed), label: 'Feeds'),
        ],
      ),
    );
  }
}
