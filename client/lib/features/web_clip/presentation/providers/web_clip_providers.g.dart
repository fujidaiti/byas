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

@ProviderFor(webClip)
final webClipProvider = WebClipFamily._();

final class WebClipProvider
    extends $FunctionalProvider<AsyncValue<WebClip>, WebClip, FutureOr<WebClip>>
    with $FutureModifier<WebClip>, $FutureProvider<WebClip> {
  WebClipProvider._({
    required WebClipFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'webClipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$webClipHash();

  @override
  String toString() {
    return r'webClipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WebClip> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WebClip> create(Ref ref) {
    final argument = this.argument as int;
    return webClip(ref, id: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WebClipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$webClipHash() => r'c56a6d94b1639d1095baa082580f6a625a1dbb3c';

final class WebClipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WebClip>, int> {
  WebClipFamily._()
    : super(
        retry: null,
        name: r'webClipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WebClipProvider call({required int id}) =>
      WebClipProvider._(argument: id, from: this);

  @override
  String toString() => r'webClipProvider';
}
