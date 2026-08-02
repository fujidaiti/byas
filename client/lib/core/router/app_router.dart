import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paperdoll/core/router/routes.dart';
import 'package:paperdoll/debug_keys.dart';
import 'package:paperdoll/features/auth/presentation/providers/auth_providers.dart';
import 'package:paperdoll/features/auth/presentation/sign_in_screen.dart';
import 'package:paperdoll/features/auth/presentation/sign_up_screen.dart';
import 'package:paperdoll/features/auth/presentation/splash_screen.dart';
import 'package:paperdoll/features/feed/presentation/feed_detail_screen.dart';
import 'package:paperdoll/features/feed/presentation/feed_search_screen.dart';
import 'package:paperdoll/features/feed/presentation/feeds_screen.dart';
import 'package:paperdoll/features/feed_entry/presentation/feed_entry_reader_screen.dart';
import 'package:paperdoll/features/newspaper/presentation/today_screen.dart';
import 'package:paperdoll/features/reading_list/presentation/archived_reading_list_screen.dart';
import 'package:paperdoll/features/reading_list/presentation/reading_list_screen.dart';
import 'package:paperdoll/features/settings/presentation/settings_screen.dart';
import 'package:paperdoll/features/web_clip/presentation/web_clip_reader_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

const Set<String> _authRoutePaths = {
  routeSplashPath,
  routeSignInPath,
  routeSignUpPath,
};

/// The app's navigation graph: a bottom-nav shell over Today and Feeds, with
/// detail/discovery screens nested under each branch. The feed entry and web
/// article readers push onto the root navigator so they cover the bottom nav
/// bar. Sign-in/up and a splash screen sit outside the shell, gated by
/// [authSessionProvider] via [_authRedirect].
@riverpod
GoRouter goRouter(Ref ref) {
  final sessionAsync = ref.watch(authSessionProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: routeSplashPath,
    redirect: (context, state) => _authRedirect(sessionAsync, state),
    routes: [
      GoRoute(
        path: routeSplashPath,
        name: routeSplashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: routeSignInPath,
        name: routeSignInName,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: routeSignUpPath,
        name: routeSignUpName,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: routeSettingsPath,
        name: routeSettingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
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
                    path: routeTodayFeedEntryReaderPath,
                    name: routeTodayFeedEntryReaderName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => FeedEntryReaderScreen(
                      id: _idParam(state, 'feedEntryId'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: routeReadingListPath,
                name: routeReadingListName,
                builder: (context, state) => const ReadingListScreen(),
                routes: [
                  GoRoute(
                    path: routeArchivedReadingListPath,
                    name: routeArchivedReadingListName,
                    builder: (context, state) =>
                        const ArchivedReadingListScreen(),
                  ),
                  GoRoute(
                    path: routeWebClipReaderPath,
                    name: routeWebClipReaderName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => WebClipReaderScreen(
                      id: _idParam(state, 'id'),
                      initialTitle: state.extra! as String,
                    ),
                  ),
                  GoRoute(
                    path: routeReadingListFeedEntryReaderPath,
                    name: routeReadingListFeedEntryReaderName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => FeedEntryReaderScreen(
                      id: _idParam(state, 'feedEntryId'),
                    ),
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
                        path: routeFeedEntryReaderPath,
                        name: routeFeedEntryReaderName,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => FeedEntryReaderScreen(
                          id: _idParam(state, 'feedEntryId'),
                        ),
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

/// Sends signed-out users to Sign-in (unless already on an auth route),
/// signed-in users away from Splash/Sign-in/Sign-up to Today, and holds
/// signed-out-or-loading users on Splash while the token read is in flight.
/// A read failure is treated the same as signed-out.
String? _authRedirect(AsyncValue<String?> sessionAsync, GoRouterState state) {
  final onAuthRoute = _authRoutePaths.contains(state.matchedLocation);
  return switch (sessionAsync) {
    AsyncData(value: final token?) when token.isNotEmpty =>
      onAuthRoute ? routeTodayPath : null,
    AsyncData() || AsyncError() =>
      state.matchedLocation == routeSignInPath ||
              state.matchedLocation == routeSignUpPath
          ? null
          : routeSignInPath,
    _ => state.matchedLocation == routeSplashPath ? null : routeSplashPath,
  };
}

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
            key: AppDebugKey.todayNavDestination,
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Today',
          ),
          NavigationDestination(
            key: AppDebugKey.readingListNavDestination,
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Reading list',
          ),
          NavigationDestination(
            key: AppDebugKey.feedsNavDestination,
            icon: Icon(Icons.rss_feed),
            label: 'Feeds',
          ),
        ],
      ),
    );
  }
}
