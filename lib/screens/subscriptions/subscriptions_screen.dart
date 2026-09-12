import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show ChannelVideosPage, VideoSearchResult;
import 'package:provider/provider.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/models/local_models.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';
import 'package:vidora/widgets/video_card.dart';

/// Subscriptions feed: latest videos from all subscribed channels,
/// merged newest-first, with per-channel browsing.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final List<VideoSearchResult> _feed = [];
  bool _loading = false;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
    }
  }

  Future<void> _reload() async {
    final subs = context.read<AppState>().subs;
    if (subs.isEmpty) {
      setState(() {
        _feed.clear();
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    // Fetch latest videos from each channel concurrently.
    final futures = subs
        .map((s) => Yt.I.kmep
            .getChannelVideos(s.channelId)
            .timeout(const Duration(seconds: 20))
            .then<ChannelVideosPage?>((p) => p)
            .catchError((_) => null))
        .toList();
    final pages = await Future.wait(futures);

    if (!mounted) return;
    final merged = <VideoSearchResult>[];
    for (final page in pages) {
      if (page != null) merged.addAll(page.videos.take(10));
    }
    // Rough newest-first by uploadDate text length heuristic isn't
    // reliable; keep channel-grouped order but interleave round-robin
    // so no channel dominates the top.
    final byChannel = <String, List<VideoSearchResult>>{};
    for (final v in merged) {
      byChannel.putIfAbsent(v.channelName, () => []).add(v);
    }
    final interleaved = <VideoSearchResult>[];
    var idx = 0;
    var remaining = byChannel.values.map((l) => l).toList();
    while (remaining.any((l) => l.isNotEmpty)) {
      for (final list in remaining) {
        if (idx < list.length) interleaved.add(list[idx]);
      }
      idx++;
      remaining = remaining.where((l) => l.isNotEmpty).toList();
      if (idx > 10) break;
    }

    setState(() {
      _feed
        ..clear()
        ..addAll(interleaved);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subs = context.watch<AppState>().subs;

    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(title: const Text('Subscriptions')),
      body: subs.isEmpty
          ? const EmptyView(
              message:
                  'No subscriptions yet. Subscribe to channels from any '
                  'video or channel page.')
          : _loading
              ? const Loader(label: 'Building your feed…')
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _reload)
                  : RefreshIndicator(
                      color: V.red,
                      onRefresh: _reload,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _feed.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return _subStrip(context, subs);
                          }
                          final v = _feed[i - 1];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              height: 96,
                              child: VideoCard(
                                video: v,
                                onTap: () => Navigator.of(context)
                                    .pushNamed('/watch', arguments: v.videoId),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _subStrip(BuildContext context, List<SubChannel> subs) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: subs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final s = subs[i];
          return GestureDetector(
            onTap: () => Navigator.of(context)
                .pushNamed('/channel', arguments: s.channelId),
            child: Column(children: [
              ChannelAvatar(url: s.avatarUrl, name: s.name, size: 52),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: V.textDim, fontSize: 11),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
