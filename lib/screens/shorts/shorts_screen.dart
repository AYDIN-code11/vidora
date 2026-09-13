import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show VideoSearchResult;
import 'package:vidora/core/strings.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/widgets/common.dart';
import 'package:vidora/widgets/video_card.dart';

/// Shorts feed: paginated vertical list of shorts cards for a query.
class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  static const _queries = [
    'shorts',
    'viral shorts',
    'funny shorts',
    'music shorts',
  ];

  List<VideoSearchResult> _items = [];
  String? _continuation;
  int _queryIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await Yt.I.kmep
          .shortsFeed(query: _queries[_queryIndex]);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _continuation = page.continuation;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cont = _continuation;
    if (cont == null || _loading) return;
    setState(() => _loading = true);
    try {
      final page =
          await Yt.I.kmep.shortsFeed(query: _queries[_queryIndex], continuation: cont);
      if (!mounted) return;
      setState(() {
        final seen = _items.map((i) => i.videoId).toSet();
        _items.addAll(page.items.where((i) => !seen.contains(i.videoId)));
        _continuation = page.continuation;
        _loading = false;
      });
    } catch (_) {
      // Rotate query if this one exhausted itself.
      if (mounted) {
        setState(() {
          _queryIndex = (_queryIndex + 1) % _queries.length;
          _continuation = null;
        });
        _load();
      }
    }
  }

  void _open(VideoSearchResult v) =>
      Navigator.of(context).pushNamed('/watch', arguments: v.videoId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(title: Text('${context.s.homeShorts} — ${_queries[_queryIndex]}')),
      body: _loading && _items.isEmpty
          ? Loader(label: context.s.loadingShorts)
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >=
                        n.metrics.maxScrollExtent - 500) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final v = _items[i];
                      return VideoCard(
                        video: v,
                        onTap: () => _open(v),
                      );
                    },
                  ),
                ),
    );
  }
}
