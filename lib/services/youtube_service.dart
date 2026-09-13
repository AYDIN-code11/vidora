import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:kmep/kmep.dart';
import 'package:kmep_flutter_integration/webview_js_runtime.dart';
import 'package:vidora/core/strings.dart';
import 'package:vidora/services/home_feed_client.dart';

export 'home_feed_client.dart';

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

/// Central KMEP wiring for the app: a facade rebuilt when the content
/// locale changes, plus the search-powered home feed client.
class Yt {
  Yt._();

  static final Yt I = Yt._();

  Kmep? _kmep;
  HomeFeedClient? _home;

  /// Current UI language — drives both the facade's hl and the home
  /// feed's metadata language.
  S lang = S.en;

  /// Current content region (gl).
  String gl = 'US';

  /// The shared Kmep facade. Lazily constructed; the headless WebView
  /// runtimes spin up on first stream resolution. Changing [lang] or
  /// [gl] drops the facade so the next call picks the new locale.
  Kmep get kmep => _kmep ??= Kmep.withOnDevicePoToken(
        // Separate JS contexts: player.js and BotGuard contaminate
        // each other when sharing globals (per KMEP docs).
        jsRuntime: WebViewJsRuntime(),
        potJsRuntime: WebViewJsRuntime(),
        fetchText: fetchText,
        hl: lang.hl,
        gl: gl,
      );

  HomeFeedClient get home => _home ??= HomeFeedClient();

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

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
    _home = null;
  }
}
