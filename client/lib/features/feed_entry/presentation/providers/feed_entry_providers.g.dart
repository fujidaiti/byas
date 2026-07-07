// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_entry_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedEntryRepository)
final feedEntryRepositoryProvider = FeedEntryRepositoryProvider._();

final class FeedEntryRepositoryProvider
    extends
        $FunctionalProvider<
          FeedEntryRepository,
          FeedEntryRepository,
          FeedEntryRepository
        >
    with $Provider<FeedEntryRepository> {
  FeedEntryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedEntryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedEntryRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeedEntryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeedEntryRepository create(Ref ref) {
    return feedEntryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedEntryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedEntryRepository>(value),
    );
  }
}

String _$feedEntryRepositoryHash() =>
    r'f9c74603d05aaf5d786d1a55ae6ca43d0c9b5b5e';

/// Single source of truth for one feed entry in the reader. It loads the entry
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached entry optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.

@ProviderFor(FeedEntryController)
final feedEntryControllerProvider = FeedEntryControllerFamily._();

/// Single source of truth for one feed entry in the reader. It loads the entry
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached entry optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.
final class FeedEntryControllerProvider
    extends $AsyncNotifierProvider<FeedEntryController, FeedEntry> {
  /// Single source of truth for one feed entry in the reader. It loads the entry
  /// and owns every reading-list mutation (save, remove, archive, unarchive):
  /// each one patches the cached entry optimistically so watchers update
  /// instantly, fires the request, and rolls the state back before rethrowing if
  /// it fails. The UI only reacts to the state and surfaces snackbars.
  FeedEntryControllerProvider._({
    required FeedEntryControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'feedEntryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedEntryControllerHash();

  @override
  String toString() {
    return r'feedEntryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FeedEntryController create() => FeedEntryController();

  @override
  bool operator ==(Object other) {
    return other is FeedEntryControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedEntryControllerHash() =>
    r'c9fc7e07c4c7febec146922674574c1a9fd5f9e4';

/// Single source of truth for one feed entry in the reader. It loads the entry
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached entry optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.

final class FeedEntryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FeedEntryController,
          AsyncValue<FeedEntry>,
          FeedEntry,
          FutureOr<FeedEntry>,
          int
        > {
  FeedEntryControllerFamily._()
    : super(
        retry: null,
        name: r'feedEntryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Single source of truth for one feed entry in the reader. It loads the entry
  /// and owns every reading-list mutation (save, remove, archive, unarchive):
  /// each one patches the cached entry optimistically so watchers update
  /// instantly, fires the request, and rolls the state back before rethrowing if
  /// it fails. The UI only reacts to the state and surfaces snackbars.

  FeedEntryControllerProvider call({required int id}) =>
      FeedEntryControllerProvider._(argument: id, from: this);

  @override
  String toString() => r'feedEntryControllerProvider';
}

/// Single source of truth for one feed entry in the reader. It loads the entry
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached entry optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.

abstract class _$FeedEntryController extends $AsyncNotifier<FeedEntry> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<FeedEntry> build({required int id});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FeedEntry>, FeedEntry>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeedEntry>, FeedEntry>,
              AsyncValue<FeedEntry>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(id: _$args));
  }
}
