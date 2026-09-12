import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kmep/kmep.dart' show VideoSearchResult;

/// Raw InnerTube browse ids for YouTube's non-personalized feeds:
/// trending, music, gaming, news.
class TrendingCategory {
  final String id;
  final String label;
  const TrendingCategory(this.id, this.label);
}

const List<TrendingCategory> trendingCategories = [
  TrendingCategory('FEtrending', 'Now'),
  TrendingCategory('FEmusic', 'Music'),
  TrendingCategory('FEgaming', 'Gaming'),
  TrendingCategory('FEnews', 'News'),
];

/// Walks a raw InnerTube `/browse` JSON payload and collects video
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

/// Parses a localized view-count string (e.g. `"1.2M views"`).
int viewsFromText(String text) {
  final digits = text.replaceAll(RegExp('[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
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

/// Client for the InnerTube `/browse` trending/explore feeds. The
/// endpoint serves the unauthenticated WEB client without PO tokens —
/// the same path KMEP's search/channel machinery rides.
class TrendingClient {
  TrendingClient();

  static final _endpoint =
      Uri.parse('https://www.youtube.com/youtubei/v1/browse');

  Future<List<VideoSearchResult>> fetch(String browseId,
      {String hl = 'en', String gl = 'US'}) async {
    final body = jsonEncode({
      'context': {
        'client': {
          'clientName': 'WEB',
          'clientVersion': '2.20240726.00.00',
          'hl': hl,
          'gl': gl,
        },
      },
      'browseId': browseId,
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
    );
    if (resp.statusCode != 200) {
      throw Exception('browse $browseId -> HTTP ${resp.statusCode}');
    }
    return parseVideoCards(jsonDecode(resp.body)
        as Map<String, dynamic>);
  }
}
