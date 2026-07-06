import 'package:paperdoll/features/web_clip/domain/web_clip.dart';

/// Reads saved web clips by id.
abstract interface class WebClipRepository {
  /// `GET /web-clips/{id}` → the clip's url, title, and content.
  Future<WebClip> getWebClip(int id);
}
