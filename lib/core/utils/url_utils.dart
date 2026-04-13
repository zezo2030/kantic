import '../constants/api_constants.dart';

String _serverRootFromApiBase() {
  try {
    final uri = Uri.parse(ApiConstants.baseUrl);
    final portPart = (uri.hasPort && uri.port != 0) ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  } catch (_) {
    // Fallback: strip common api suffixes if present
    final base = ApiConstants.baseUrl;
    final idx = base.indexOf('/api/');
    return idx > 0 ? base.substring(0, idx) : base;
  }
}

/// Builds a full URL for a file served by the backend static server.
/// - If [path] is already an absolute URL, returns it as is.
/// - If [path] starts with '/', prefixes the API server root (without /api/v1).
/// - Otherwise, prefixes with server root and a '/'.
String resolveFileUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final root = _serverRootFromApiBase();
  if (path.startsWith('/')) return '$root$path';
  return '$root/$path';
}

/// Cache-busting helper for previews/just-uploaded images
String resolveFileUrlWithBust(String? path) {
  final url = resolveFileUrl(path);
  if (url.isEmpty) return '';
  final sep = url.contains('?') ? '&' : '?';
  return '$url${sep}v=${DateTime.now().millisecondsSinceEpoch}';
}
