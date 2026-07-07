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

/// Loads a web clip for the reader and holds it as mutable state so the reader
/// can reflect an archive/unarchive toggle optimistically, without refetching.

@ProviderFor(WebClipController)
final webClipControllerProvider = WebClipControllerFamily._();

/// Loads a web clip for the reader and holds it as mutable state so the reader
/// can reflect an archive/unarchive toggle optimistically, without refetching.
final class WebClipControllerProvider
    extends $AsyncNotifierProvider<WebClipController, WebClip> {
  /// Loads a web clip for the reader and holds it as mutable state so the reader
  /// can reflect an archive/unarchive toggle optimistically, without refetching.
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

String _$webClipControllerHash() => r'924cd352426cb36d36e24593ee52136012cb6037';

/// Loads a web clip for the reader and holds it as mutable state so the reader
/// can reflect an archive/unarchive toggle optimistically, without refetching.

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

  /// Loads a web clip for the reader and holds it as mutable state so the reader
  /// can reflect an archive/unarchive toggle optimistically, without refetching.

  WebClipControllerProvider call({required int id}) =>
      WebClipControllerProvider._(argument: id, from: this);

  @override
  String toString() => r'webClipControllerProvider';
}

/// Loads a web clip for the reader and holds it as mutable state so the reader
/// can reflect an archive/unarchive toggle optimistically, without refetching.

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
