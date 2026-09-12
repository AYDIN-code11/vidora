import 'package:flutter/foundation.dart';
import 'package:kmep/kmep.dart' show VideoInfo, VideoSearchResult;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidora/models/local_models.dart';

enum HistorySort { newest, oldest }

enum BookmarkSort { newest, oldest, title }

/// App-wide local state: subscriptions, history, bookmarks, search
/// queries and user settings, persisted to SharedPreferences.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kSubs = 'vidora.subs';
  static const _kHistory = 'vidora.history';
  static const _kBookmarks = 'vidora.bookmarks';
  static const _kQueries = 'vidora.queries';
  static const _kHistoryEnabled = 'vidora.history.enabled';
  static const _kDefaultRes = 'vidora.player.defaultRes';
  static const _kAutoplayNext = 'vidora.player.autoplayNext';
  static const _kRegion = 'vidora.region';
  static const _kSearchLimit = 'vidora.search.limit';

  // ---------------- subscriptions ----------------

  final List<SubChannel> _subs = [];
  List<SubChannel> get subs => List.unmodifiable(_subs);

  bool isSubscribed(String channelId) =>
      _subs.any((s) => s.channelId == channelId);

  void toggleSubscription(SubChannel channel) {
    final i = _subs.indexWhere((s) => s.channelId == channel.channelId);
    if (i >= 0) {
      _subs.removeAt(i);
    } else {
      _subs.add(channel);
    }
    _persistSubs();
    notifyListeners();
  }

  void _persistSubs() => _prefs.setString(
      _kSubs, StoreCodec.encodeList(_subs.map((e) => e.toJson()).toList()));

  void _loadSubs() => _subs
      ..clear()
      ..addAll(StoreCodec.decodeList(_prefs.getString(_kSubs) ?? '')
          .map(SubChannel.fromJson));

  // ---------------- history ----------------

  final List<HistoryEntry> _history = [];
  List<HistoryEntry> get history => List.unmodifiable(_history);

  bool historyEnabled = true;
  HistorySort historySort = HistorySort.newest;

  List<HistoryEntry> get sortedHistory {
    final copy = List<HistoryEntry>.from(_history);
    copy.sort((a, b) => historySort == HistorySort.newest
        ? b.watchedAt.compareTo(a.watchedAt)
        : a.watchedAt.compareTo(b.watchedAt));
    return copy;
  }

  void setHistorySort(HistorySort s) {
    historySort = s;
    notifyListeners();
  }

  HistoryEntry? historyEntryFor(String videoId) {
    for (final e in _history) {
      if (e.videoId == videoId) return e;
    }
    return null;
  }

  void recordWatch(VideoInfo info, {int watchedSeconds = 0}) {
    if (!historyEnabled) return;
    final i = _history.indexWhere((e) => e.videoId == info.videoId);
    final entry = HistoryEntry(
      videoId: info.videoId,
      title: info.title,
      channelName: info.channelName,
      thumbnailUrl:
          info.thumbnails.isNotEmpty ? info.thumbnails.first : '',
      durationSeconds: info.durationSeconds,
      watchedSeconds: watchedSeconds,
      watchedAt: DateTime.now(),
    );
    if (i >= 0) {
      _history[i] = entry;
    } else {
      _history.insert(0, entry);
    }
    _persistHistory();
    notifyListeners();
  }

  void updateProgress(String videoId, int watchedSeconds) {
    if (!historyEnabled) return;
    final i = _history.indexWhere((e) => e.videoId == videoId);
    if (i < 0) return;
    _history[i] = _history[i].withProgress(watchedSeconds);
    _persistHistory();
  }

  void removeHistory(String videoId) {
    _history.removeWhere((e) => e.videoId == videoId);
    _persistHistory();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _persistHistory();
    notifyListeners();
  }

  void _persistHistory() => _prefs.setString(
      _kHistory,
      StoreCodec.encodeList(
          _history.take(1000).map((e) => e.toJson()).toList()));

  void _loadHistory() => _history
    ..clear()
    ..addAll(StoreCodec.decodeList(_prefs.getString(_kHistory) ?? '')
        .map(HistoryEntry.fromJson));

  void setHistoryEnabled(bool v) {
    historyEnabled = v;
    _prefs.setBool(_kHistoryEnabled, v);
    notifyListeners();
  }

  // ---------------- bookmarks ----------------

  final List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  BookmarkSort bookmarkSort = BookmarkSort.newest;

  List<Bookmark> get sortedBookmarks {
    final copy = List<Bookmark>.from(_bookmarks);
    switch (bookmarkSort) {
      case BookmarkSort.newest:
        copy.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case BookmarkSort.oldest:
        copy.sort((a, b) => a.addedAt.compareTo(b.addedAt));
      case BookmarkSort.title:
        copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return copy;
  }

  void setBookmarkSort(BookmarkSort s) {
    bookmarkSort = s;
    notifyListeners();
  }

  bool isBookmarked(String videoId) =>
      _bookmarks.any((b) => b.videoId == videoId);

  void toggleBookmark(VideoSearchResult card) {
    final i = _bookmarks.indexWhere((b) => b.videoId == card.videoId);
    if (i >= 0) {
      _bookmarks.removeAt(i);
    } else {
      _bookmarks.insert(
        0,
        Bookmark(
          videoId: card.videoId,
          title: card.title,
          channelName: card.channelName,
          thumbnailUrl: card.thumbnailUrl,
          durationSeconds: card.durationSeconds,
          viewCount: card.viewCount,
          uploadDate: card.uploadDate,
          addedAt: DateTime.now(),
        ),
      );
    }
    _persistBookmarks();
    notifyListeners();
  }

  void removeBookmark(String videoId) {
    _bookmarks.removeWhere((b) => b.videoId == videoId);
    _persistBookmarks();
    notifyListeners();
  }

  void clearBookmarks() {
    _bookmarks.clear();
    _persistBookmarks();
    notifyListeners();
  }

  void _persistBookmarks() => _prefs.setString(
      _kBookmarks,
      StoreCodec.encodeList(
          _bookmarks.map((e) => e.toJson()).toList()));

  void _loadBookmarks() => _bookmarks
    ..clear()
    ..addAll(StoreCodec.decodeList(_prefs.getString(_kBookmarks) ?? '')
        .map(Bookmark.fromJson));

  // ---------------- search queries ----------------

  final List<QueryItem> _queries = [];
  List<QueryItem> get queries => List.unmodifiable(_queries);

  void addQuery(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _queries.removeWhere((q) => q.text == t);
    _queries.insert(0, QueryItem(text: t, addedAt: DateTime.now()));
    if (_queries.length > 100) _queries.removeLast();
    _persistQueries();
    notifyListeners();
  }

  void removeQuery(String text) {
    _queries.removeWhere((q) => q.text == text);
    _persistQueries();
    notifyListeners();
  }

  void clearQueries() {
    _queries.clear();
    _persistQueries();
    notifyListeners();
  }

  void _persistQueries() => _prefs.setString(
      _kQueries, StoreCodec.encodeList(_queries.map((e) => e.toJson()).toList()));

  void _loadQueries() => _queries
    ..clear()
    ..addAll(StoreCodec.decodeList(_prefs.getString(_kQueries) ?? '')
        .map(QueryItem.fromJson));

  // ---------------- player / general settings ----------------

  int defaultResolution = 720;
  bool autoplayNext = true;
  String region = 'US';
  int searchLimit = 30;

  void setDefaultResolution(int h) {
    defaultResolution = h;
    _prefs.setInt(_kDefaultRes, h);
    notifyListeners();
  }

  void setAutoplayNext(bool v) {
    autoplayNext = v;
    _prefs.setBool(_kAutoplayNext, v);
    notifyListeners();
  }

  void setRegion(String r) {
    region = r;
    _prefs.setString(_kRegion, r);
    notifyListeners();
  }

  void setSearchLimit(int v) {
    searchLimit = v;
    _prefs.setInt(_kSearchLimit, v);
    notifyListeners();
  }

  // ---------------- boot ----------------

  void _load() {
    historyEnabled = _prefs.getBool(_kHistoryEnabled) ?? true;
    defaultResolution = _prefs.getInt(_kDefaultRes) ?? 720;
    autoplayNext = _prefs.getBool(_kAutoplayNext) ?? true;
    region = _prefs.getString(_kRegion) ?? 'US';
    searchLimit = _prefs.getInt(_kSearchLimit) ?? 30;
    _loadQueries();
    _loadSubs();
    _loadHistory();
    _loadBookmarks();
  }
}
