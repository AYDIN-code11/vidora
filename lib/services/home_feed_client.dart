import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kmep/kmep.dart' show VideoSearchResult;

/// A category on the home feed.
class HomeCategory {
  final String id;
  final String label;
  final List<String> seedQueries;
  const HomeCategory(this.id, this.label, this.seedQueries);
}

/// Home feed categories. Trending/explore browse endpoints reject the
/// unauthenticated InnerTube client (HTTP 400), so each category is
/// powered by seed searches that approximate the same content —
/// sorted by relevance, deduped across queries, capped per query.
const List<HomeCategory> homeCategories = [
  HomeCategory('now', 'Now', [
    'most viewed youtube videos',
    'trending videos today',
    'viral videos this week',
  ]),
  HomeCategory('music', 'Music', [
    'top music videos',
    'popular songs this week',
    'new music video 2026',
  ]),
  HomeCategory('gaming', 'Gaming', [
    'gaming highlights this week',
    'most popular gameplay',
    'gaming news today',
  ]),
  HomeCategory('news', 'News', [
    'news today',
    'world news this week',
    'breaking news',
  ]),
  HomeCategory('tech', 'Tech', [
    'tech review 2026',
    'new smartphone review',
    'tech news today',
  ]),
  HomeCategory('sports', 'Sports', [
    'sports highlights this week',
    'best goals of the week',
    'sports news',
  ]),
  HomeCategory('movies', 'Movies', [
    'movie trailer 2026',
    'official trailer',
    'full movies',
  ]),
  HomeCategory('shorts', 'Shorts', [
    'funny shorts',
    'viral shorts',
  ]),
];

/// Client powering the home feed via InnerTube `/search` (the one
/// endpoint that reliably serves the unauthenticated WEB client).
class HomeFeedClient {
  HomeFeedClient();

  static final _endpoint =
      Uri.parse('https://www.youtube.com/youtubei/v1/search');

  /// Builds one home feed: runs the category's seed searches
  /// concurrently, interleaves the results round-robin (so no query
  /// dominates the top), dedupes by video id, caps the total.
  Future<List<VideoSearchResult>> fetch(
    HomeCategory category, {
    String hl = 'en',
    String gl = 'US',
    int perQuery = 15,
  }) async {
    final results = await Future.wait(
      category.seedQueries.map(
        (q) => _search(q, hl: hl, gl: gl).catchError((_) => <VideoSearchResult>[]),
      ),
    );

    // Round-robin interleave.
    final out = <VideoSearchResult>[];
    final seen = <String>{};
    for (var i = 0; i < perQuery; i++) {
      for (final list in results) {
        if (i >= list.length) continue;
        final v = list[i];
        if (seen.add(v.videoId)) out.add(v);
      }
    }
    return out;
  }

  Future<List<VideoSearchResult>> _search(
    String query, {
    required String hl,
    required String gl,
  }) async {
    final body = jsonEncode({
      'context': {
        'client': {
          'clientName': 'WEB',
          'clientVersion': '2.20240808.00.00',
          'hl': hl,
          'gl': gl,
        },
      },
      'query': query,
    });
    final resp = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0 Safari/537.36',
      },
      body: body,
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('search "$query" -> HTTP ${resp.statusCode}');
    }
    final parsed = parseVideoCards(jsonDecode(resp.body)
        as Map<String, dynamic>);
    return parsed;
  }
}

/// Walks a raw InnerTube `/search` JSON payload and collects video
/// renderers into lightweight cards, deduplicated by id.
List<VideoSearchResult> parseVideoCards(Map<String, dynamic> response) {
  final items = <VideoSearchResult>[];
  final seen = <String>{};

  void walk(dynamic node) {
    if (node is Map) {
      for (final key in const [
        'videoRenderer',
        'gridVideoRenderer',
        'reelItemRenderer',
        'compactVideoRenderer',
      ]) {
        final r = node[key];
        if (r is Map) {
          final id = r['videoId']?.toString();
          if (id != null && id.isNotEmpty && seen.add(id)) {
            items.add(_cardFrom(r.cast<String, dynamic>()));
          }
        }
      }
      for (final v in node.values) {
        walk(v);
      }
    } else if (node is List) {
      for (final v in node) {
        walk(v);
      }
    }
  }

  walk(response);
  return items;
}

VideoSearchResult _cardFrom(Map<String, dynamic> r) {
  final id = r['videoId']?.toString() ?? '';
  final title = runsText(r['title']) ?? runsText(r['headline']) ?? '';
  final channelName = runsText(r['ownerText']) ??
      runsText(r['longBylineText']) ??
      runsText(r['shortBylineText']) ??
      '';
  final lengthText = runsText(r['lengthText']);
  final duration = lengthText != null ? lengthToSeconds(lengthText) : 0;
  final viewsText = runsText(r['viewCountText']);
  final views = viewsText != null ? viewsFromText(viewsText) : 0;
  return VideoSearchResult(
    videoId: id,
    title: title,
    channelName: channelName,
    durationSeconds: duration,
    viewCount: views,
    thumbnailUrl: thumbnailUrlOf(r),
    uploadDate: runsText(r['publishedTimeText']) ?? '',
    isShort: false,
  );
}

// ---- small InnerTube text helpers (mirror KMEP's internal ones) ----

/// Reads InnerTube's `{simpleText}` / `{runs:[{text}]}` text shape.
String? runsText(dynamic obj) {
  if (obj is! Map) return null;
  final simple = obj['simpleText'];
  if (simple is String) return simple;
  final runs = obj['runs'];
  if (runs is List && runs.isNotEmpty && runs.first is Map) {
    final text = (runs.first as Map)['text'];
    if (text != null) return text.toString();
  }
  return null;
}

/// Parses a duration string like `"12:34"` or `"1:02:03"` into seconds.
int lengthToSeconds(String text) {
  final parts = text.split(':');
  if (parts.length > 3) return 0;
  var seconds = 0;
  for (final p in parts) {
    seconds = seconds * 60 + (int.tryParse(p.trim()) ?? 0);
  }
  return seconds;
}

/// Parses a localized view-count string (e.g. `"1.2M views"`, `"1,2 млн просмотров"`).
/// Locale-aware multipliers: K/тыс, M/млн, B/млрд.
/// Parses a localized view-count string ("1,234 views", "1.2 млн
/// просмотров", "483 тыс.") into a number. Locale-aware multipliers.
int viewsFromText(String text) {
  final t = text.toLowerCase();
  final m = RegExp(r'([\d.,]+)\s*(k|тыс|m|млн|b|млрд|万个|万回|만)?')
      .firstMatch(t);
  if (m == null) return 0;
  final rawNum = m.group(1)!.replaceAll(',', '');
  final num = double.tryParse(rawNum) ?? 0;
  switch (m.group(2)) {
    case 'k':
    case 'тыс':
      return (num * 1000).round();
    case 'm':
    case 'млн':
      return (num * 1000000).round();
    case 'b':
    case 'млрд':
      return (num * 1000000000).round();
    case '万个':
    case '万回':
    case '만':
      return (num * 10000).round();
    default:
      return num.round();
  }
}

/// Picks the highest-resolution thumbnail URL out of a renderer's
/// `thumbnail.thumbnails[]` array, normalizing protocol-relative URLs.
String thumbnailUrlOf(Map<String, dynamic> renderer) {
  final thumb = renderer['thumbnail'];
  if (thumb is Map && thumb['thumbnails'] is List) {
    final list = thumb['thumbnails'] as List;
    if (list.isNotEmpty && list.last is Map) {
      var url = (list.last as Map)['url']?.toString() ?? '';
      if (url.startsWith('//')) url = 'https:$url';
      return url;
    }
  }
  return '';
}
