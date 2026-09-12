import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:kmep/kmep.dart';
import 'package:kmep_flutter_integration/webview_js_runtime.dart';
import 'package:vidora/services/trending_client.dart';

export 'trending_client.dart';

/// Extracts a video id from common YouTube URL forms (watch, youtu.be,
/// shorts, embed); returns the input unchanged if it's already a bare id.
String extractVideoId(String input) {
  final trimmed = input.trim();
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(trimmed)) return trimmed;
  final patterns = [
    RegExp(r'(?:youtube\.com/watch\?.*v=)([A-Za-z0-9_-]{11})'),
    RegExp(r'(?:youtu\.be/)([A-Za-z0-9_-]{11})'),
    RegExp(r'(?:youtube\.com/shorts/)([A-Za-z0-9_-]{11})'),
    RegExp(r'(?:youtube\.com/embed/)([A-Za-z0-9_-]{11})'),
    RegExp(r'(?:youtube\.com/live/)([A-Za-z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(trimmed);
    if (m != null) return m.group(1)!;
  }
  return trimmed;
}

/// Central KMEP wiring for the app: a singleton facade plus small
/// helpers (trending feed) that ride InnerTube.
class Yt {
  Yt._();

  static final Yt I = Yt._();

  Kmep? _kmep;
  TrendingClient? _trending;

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

  /// The shared Kmep facade. Lazily constructed; the headless WebView
  /// runtimes spin up on first stream resolution.
  Kmep get kmep => _kmep ??= Kmep.withOnDevicePoToken(
        // Separate JS contexts: player.js and BotGuard contaminate
        // each other when sharing globals (per KMEP docs).
        jsRuntime: WebViewJsRuntime(),
        potJsRuntime: WebViewJsRuntime(),
        fetchText: fetchText,
      );
  TrendingClient get trending => _trending ??= TrendingClient();

  /// Plain HTTP GET as text — the one platform thing KMEP needs.
  static Future<String> fetchText(String url) async {
    final resp = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': _ua},
    ).timeout(const Duration(seconds: 25));
    if (resp.statusCode != 200) {
      throw StateError('GET $url -> HTTP ${resp.statusCode}');
    }
    return resp.body;
  }

  /// Drops the facade (releases headless WebViews). Called from app
  /// teardown; the next access lazily rebuilds everything.
  void dispose() {
    _kmep = null;
    _trending = null;
  }
}
