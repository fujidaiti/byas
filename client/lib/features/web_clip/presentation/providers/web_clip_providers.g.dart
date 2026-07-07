// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_clip_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(webClipRepository)
final webClipRepositoryProvider = WebClipRepositoryProvider._();

final class WebClipRepositoryProvider
    extends
        $FunctionalProvider<
          WebClipRepository,
          WebClipRepository,
          WebClipRepository
        >
    with $Provider<WebClipRepository> {
  WebClipRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webClipRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webClipRepositoryHash();

  @$internal
  @override
  $ProviderElement<WebClipRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WebClipRepository create(Ref ref) {
    return webClipRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebClipRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebClipRepository>(value),
    );
  }
}

String _$webClipRepositoryHash() => r'53586faadd7246a222f08fe5f404d220a2a6c437';

/// Single source of truth for one web clip in the reader. It loads the clip
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached clip optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.

@ProviderFor(WebClipController)
final webClipControllerProvider = WebClipControllerFamily._();

/// Single source of truth for one web clip in the reader. It loads the clip
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached clip optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.
final class WebClipControllerProvider
    extends $AsyncNotifierProvider<WebClipController, WebClip> {
  /// Single source of truth for one web clip in the reader. It loads the clip
  /// and owns every reading-list mutation (save, remove, archive, unarchive):
  /// each one patches the cached clip optimistically so watchers update
  /// instantly, fires the request, and rolls the state back before rethrowing if
  /// it fails. The UI only reacts to the state and surfaces snackbars.
  WebClipControllerProvider._({
    required WebClipControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'webClipControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$webClipControllerHash();

  @override
  String toString() {
    return r'webClipControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WebClipController create() => WebClipController();

  @override
  bool operator ==(Object other) {
    return other is WebClipControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$webClipControllerHash() => r'7a0a0e60026f2eb3bf4cbafc6c3eaa34e7b7b4fe';

/// Single source of truth for one web clip in the reader. It loads the clip
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached clip optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.

final class WebClipControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          WebClipController,
          AsyncValue<WebClip>,
          WebClip,
          FutureOr<WebClip>,
          int
        > {
  WebClipControllerFamily._()
    : super(
        retry: null,
        name: r'webClipControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Single source of truth for one web clip in the reader. It loads the clip
  /// and owns every reading-list mutation (save, remove, archive, unarchive):
  /// each one patches the cached clip optimistically so watchers update
  /// instantly, fires the request, and rolls the state back before rethrowing if
  /// it fails. The UI only reacts to the state and surfaces snackbars.

  WebClipControllerProvider call({required int id}) =>
      WebClipControllerProvider._(argument: id, from: this);

  @override
  String toString() => r'webClipControllerProvider';
}

/// Single source of truth for one web clip in the reader. It loads the clip
/// and owns every reading-list mutation (save, remove, archive, unarchive):
/// each one patches the cached clip optimistically so watchers update
/// instantly, fires the request, and rolls the state back before rethrowing if
/// it fails. The UI only reacts to the state and surfaces snackbars.

abstract class _$WebClipController extends $AsyncNotifier<WebClip> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<WebClip> build({required int id});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WebClip>, WebClip>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WebClip>, WebClip>,
              AsyncValue<WebClip>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(id: _$args));
  }
}
