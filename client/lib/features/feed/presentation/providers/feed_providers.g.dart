// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedRepository)
final feedRepositoryProvider = FeedRepositoryProvider._();

final class FeedRepositoryProvider
    extends $FunctionalProvider<FeedRepository, FeedRepository, FeedRepository>
    with $Provider<FeedRepository> {
  FeedRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeedRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeedRepository create(Ref ref) {
    return feedRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedRepository>(value),
    );
  }
}

String _$feedRepositoryHash() => r'd4a3492cc9d9fd60215d0f6583f52b2b9b89c7e8';

@ProviderFor(feeds)
final feedsProvider = FeedsFamily._();

final class FeedsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Feed>>,
          List<Feed>,
          FutureOr<List<Feed>>
        >
    with $FutureModifier<List<Feed>>, $FutureProvider<List<Feed>> {
  FeedsProvider._({
    required FeedsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'feedsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedsHash();

  @override
  String toString() {
    return r'feedsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Feed>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Feed>> create(Ref ref) {
    final argument = this.argument as String?;
    return feeds(ref, cursor: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedsHash() => r'de3b0a133b07e32a659545890ecd877bd1bef46b';

final class FeedsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Feed>>, String?> {
  FeedsFamily._()
    : super(
        retry: null,
        name: r'feedsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedsProvider call({String? cursor}) =>
      FeedsProvider._(argument: cursor, from: this);

  @override
  String toString() => r'feedsProvider';
}

@ProviderFor(feedDetail)
final feedDetailProvider = FeedDetailFamily._();

final class FeedDetailProvider
    extends $FunctionalProvider<AsyncValue<Feed>, Feed, FutureOr<Feed>>
    with $FutureModifier<Feed>, $FutureProvider<Feed> {
  FeedDetailProvider._({
    required FeedDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'feedDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedDetailHash();

  @override
  String toString() {
    return r'feedDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Feed> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Feed> create(Ref ref) {
    final argument = this.argument as int;
    return feedDetail(ref, id: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedDetailHash() => r'df5e5de4ca1311fa7cb2ede86ef1fd18a6df27d6';

final class FeedDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Feed>, int> {
  FeedDetailFamily._()
    : super(
        retry: null,
        name: r'feedDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedDetailProvider call({required int id}) =>
      FeedDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'feedDetailProvider';
}

@ProviderFor(feedTimeline)
final feedTimelineProvider = FeedTimelineFamily._();

final class FeedTimelineProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedEntry>>,
          List<FeedEntry>,
          FutureOr<List<FeedEntry>>
        >
    with $FutureModifier<List<FeedEntry>>, $FutureProvider<List<FeedEntry>> {
  FeedTimelineProvider._({
    required FeedTimelineFamily super.from,
    required ({int id, String? cursor}) super.argument,
  }) : super(
         retry: null,
         name: r'feedTimelineProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedTimelineHash();

  @override
  String toString() {
    return r'feedTimelineProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<FeedEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedEntry>> create(Ref ref) {
    final argument = this.argument as ({int id, String? cursor});
    return feedTimeline(ref, id: argument.id, cursor: argument.cursor);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedTimelineProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedTimelineHash() => r'a589419eb89c155af391d90d86ba43af4bd8c0bf';

final class FeedTimelineFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<FeedEntry>>,
          ({int id, String? cursor})
        > {
  FeedTimelineFamily._()
    : super(
        retry: null,
        name: r'feedTimelineProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedTimelineProvider call({required int id, String? cursor}) =>
      FeedTimelineProvider._(argument: (id: id, cursor: cursor), from: this);

  @override
  String toString() => r'feedTimelineProvider';
}

/// Drives the Feed Search / Subscribe screen. [search] populates the candidate
/// list; [subscribe] adds a feed and refreshes the Feeds list.

@ProviderFor(FeedSearchController)
final feedSearchControllerProvider = FeedSearchControllerProvider._();

/// Drives the Feed Search / Subscribe screen. [search] populates the candidate
/// list; [subscribe] adds a feed and refreshes the Feeds list.
final class FeedSearchControllerProvider
    extends $AsyncNotifierProvider<FeedSearchController, List<FeedCandidate>> {
  /// Drives the Feed Search / Subscribe screen. [search] populates the candidate
  /// list; [subscribe] adds a feed and refreshes the Feeds list.
  FeedSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedSearchControllerHash();

  @$internal
  @override
  FeedSearchController create() => FeedSearchController();
}

String _$feedSearchControllerHash() =>
    r'ca1049cf6563a5ac646514f9f3a3b26739c025c5';

/// Drives the Feed Search / Subscribe screen. [search] populates the candidate
/// list; [subscribe] adds a feed and refreshes the Feeds list.

abstract class _$FeedSearchController
    extends $AsyncNotifier<List<FeedCandidate>> {
  FutureOr<List<FeedCandidate>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<FeedCandidate>>, List<FeedCandidate>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FeedCandidate>>, List<FeedCandidate>>,
              AsyncValue<List<FeedCandidate>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
