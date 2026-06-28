// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(entryRepository)
final entryRepositoryProvider = EntryRepositoryProvider._();

final class EntryRepositoryProvider
    extends
        $FunctionalProvider<EntryRepository, EntryRepository, EntryRepository>
    with $Provider<EntryRepository> {
  EntryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entryRepositoryHash();

  @$internal
  @override
  $ProviderElement<EntryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EntryRepository create(Ref ref) {
    return entryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntryRepository>(value),
    );
  }
}

String _$entryRepositoryHash() => r'418f4a58264a067dabbaba55b3a961895e1607c2';

@ProviderFor(entry)
final entryProvider = EntryFamily._();

final class EntryProvider
    extends
        $FunctionalProvider<
          AsyncValue<FeedEntry>,
          FeedEntry,
          FutureOr<FeedEntry>
        >
    with $FutureModifier<FeedEntry>, $FutureProvider<FeedEntry> {
  EntryProvider._({
    required EntryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'entryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryHash();

  @override
  String toString() {
    return r'entryProvider'
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
    return entry(ref, id: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryHash() => r'ba0ab272b82d843d24c4c678d9838ef4ae8b864c';

final class EntryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FeedEntry>, int> {
  EntryFamily._()
    : super(
        retry: null,
        name: r'entryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryProvider call({required int id}) =>
      EntryProvider._(argument: id, from: this);

  @override
  String toString() => r'entryProvider';
}
