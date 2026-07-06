import 'package:skillswap/config/app_config.dart';

/// Resolves a raw avatar / profile-picture value from the backend into a
/// fully-qualified URL that can be passed directly to [Image.network].
///
/// Returns `null` when [raw] is null, empty, or unresolvable.
String? resolveAvatarUrl(dynamic raw) {
  String? url;

  if (raw is String) {
    url = raw;
  } else if (raw is Map) {
    url = raw['profile_picture'] as String? ??
        raw['avatar_url'] as String? ??
        raw['url'] as String? ??
        raw['path'] as String?;
  }

  if (url == null || url.isEmpty) return null;

  if (url.startsWith('http')) {
    // Fix missing /storage/ segment in absolute URLs coming from the backend.
    if (url.contains('/profile_pictures/') &&
        !url.contains('/storage/profile_pictures/')) {
      url = url.replaceFirst('/profile_pictures/', '/storage/profile_pictures/');
    }
  } else {
    // Relative path — prepend the storage prefix then the base URL.
    if (url.startsWith('profile_pictures') && !url.startsWith('storage/')) {
      url = 'storage/$url';
    }
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    url = '$base$path';
  }

  return url.isEmpty ? null : url;
}

/// Computes two-letter initials from a display [name].
/// "John Doe" → "JD", "Alice" → "A", "" → "?"
String initialsOf(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}
  