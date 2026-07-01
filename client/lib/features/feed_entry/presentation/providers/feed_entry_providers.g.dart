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

@ProviderFor(feedEntry)
final feedEntryProvider = FeedEntryFamily._();

final class FeedEntryProvider
    extends
        $FunctionalProvider<
          AsyncValue<FeedEntry>,
          FeedEntry,
          FutureOr<FeedEntry>
        >
    with $FutureModifier<FeedEntry>, $FutureProvider<FeedEntry> {
  FeedEntryProvider._({
    required FeedEntryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'feedEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedEntryHash();

  @override
  String toString() {
    return r'feedEntryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FeedEntry> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FeedEntry> create(Ref ref) {
    final argument = this.argument as int;
    return feedEntry(ref, id: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedEntryHash() => r'06620ab93008f8dcfdaf83649d55cca1f51b15b6';

final class FeedEntryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FeedEntry>, int> {
  FeedEntryFamily._()
    : super(
        retry: null,
        name: r'feedEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedEntryProvider call({required int id}) =>
      FeedEntryProvider._(argument: id, from: this);

  @override
  String toString() => r'feedEntryProvider';
}
