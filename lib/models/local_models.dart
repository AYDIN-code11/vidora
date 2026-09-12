import 'dart:convert';

/// A saved search query / feed entry.
class QueryItem {
  final String text;
  final DateTime addedAt;

  const QueryItem({required this.text, required this.addedAt});

  Map<String, dynamic> toJson() =>
      {'text': text, 'addedAt': addedAt.toIso8601String()};

  static QueryItem fromJson(Map<String, dynamic> j) => QueryItem(
        text: j['text'] as String,
        addedAt: DateTime.parse(j['addedAt'] as String),
      );
}

/// History entry: what was watched, when, and how far.
class HistoryEntry {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final int durationSeconds;
  final int watchedSeconds;
  final DateTime watchedAt;

  const HistoryEntry({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.watchedSeconds,
    required this.watchedAt,
  });

  HistoryEntry withProgress(int seconds) => HistoryEntry(
        videoId: videoId,
        title: title,
        channelName: channelName,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        watchedSeconds: seconds,
        watchedAt: watchedAt,
      );

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'channelName': channelName,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'watchedSeconds': watchedSeconds,
        'watchedAt': watchedAt.toIso8601String(),
      };

  static HistoryEntry fromJson(Map<String, dynamic> j) => HistoryEntry(
        videoId: j['videoId'] as String,
        title: j['title'] as String,
        channelName: j['channelName'] as String? ?? '',
        thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
        durationSeconds: j['durationSeconds'] as int? ?? 0,
        watchedSeconds: j['watchedSeconds'] as int? ?? 0,
        watchedAt: DateTime.parse(j['watchedAt'] as String),
      );
}

/// A bookmarked (locally saved) video card.
class Bookmark {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final int durationSeconds;
  final int viewCount;
  final String uploadDate;
  final DateTime addedAt;

  const Bookmark({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.viewCount,
    required this.uploadDate,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'channelName': channelName,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'viewCount': viewCount,
        'uploadDate': uploadDate,
        'addedAt': addedAt.toIso8601String(),
      };

  static Bookmark fromJson(Map<String, dynamic> j) => Bookmark(
        videoId: j['videoId'] as String,
        title: j['title'] as String,
        channelName: j['channelName'] as String? ?? '',
        thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
        durationSeconds: j['durationSeconds'] as int? ?? 0,
        viewCount: j['viewCount'] as int? ?? 0,
        uploadDate: j['uploadDate'] as String? ?? '',
        addedAt: DateTime.parse(j['addedAt'] as String),
      );
}

/// A local subscription to a channel.
class SubChannel {
  final String channelId;
  final String name;
  final String avatarUrl;
  final DateTime subscribedAt;

  const SubChannel({
    required this.channelId,
    required this.name,
    required this.avatarUrl,
    required this.subscribedAt,
  });

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'name': name,
        'avatarUrl': avatarUrl,
        'subscribedAt': subscribedAt.toIso8601String(),
      };

  static SubChannel fromJson(Map<String, dynamic> j) => SubChannel(
        channelId: j['channelId'] as String,
        name: j['name'] as String,
        avatarUrl: j['avatarUrl'] as String? ?? '',
        subscribedAt: DateTime.parse(j['subscribedAt'] as String),
      );
}

/// Helpers for encoding/decoding lists of these models via jsonEncode.
class StoreCodec {
  static String encodeList(List<Map<String, dynamic>> items) =>
      jsonEncode(items);

  static List<Map<String, dynamic>> decodeList(String raw) {
    if (raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList();
    }
    return [];
  }
}
