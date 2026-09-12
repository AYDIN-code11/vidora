import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart'
    show
        ChannelInfo,
        VideoSearchResult,
        kChannelVideosTabNewest,
        kChannelVideosTabPopular,
        kChannelVideosTabOldest;
import 'package:provider/provider.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/models/local_models.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';
import 'package:vidora/widgets/video_card.dart';

/// Channel page: banner, meta, subscribe, videos with sort chips.
class ChannelScreen extends StatefulWidget {
  final String channelId;

  const ChannelScreen({super.key, required this.channelId});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

enum _ChanSort { newest, popular, oldest }

class _ChannelScreenState extends State<ChannelScreen> {
  ChannelInfo? _info;
  String? _error;
  bool _loading = true;

  List<VideoSearchResult> _videos = [];
  String? _continuation;
  bool _loadingMore = false;
  _ChanSort _sort = _ChanSort.newest;
  final _scroll = ScrollController();

  String get _sortParam {
    switch (_sort) {
      case _ChanSort.newest:
        return kChannelVideosTabNewest;
      case _ChanSort.popular:
        return kChannelVideosTabPopular;
      case _ChanSort.oldest:
        return kChannelVideosTabOldest;
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 600 &&
          _continuation != null &&
          !_loadingMore &&
          !_loading) {
        _loadMore();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await Yt.I.kmep.getChannel(widget.channelId);
      final page =
          await Yt.I.kmep.getChannelVideos(info.channelId, params: _sortParam);
      if (!mounted) return;
      setState(() {
        _info = info;
        _videos = page.videos;
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
    final info = _info;
    if (cont == null || info == null) return;
    setState(() => _loadingMore = true);
    try {
      final page =
          await Yt.I.kmep.getChannelVideos(info.channelId, continuation: cont);
      if (!mounted) return;
      setState(() {
        final seen = _videos.map((v) => v.videoId).toSet();
        _videos.addAll(page.videos.where((v) => !seen.contains(v.videoId)));
        _continuation = page.continuation;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setSort(_ChanSort s) {
    if (s == _sort) return;
    setState(() {
      _sort = s;
      _videos = [];
      _continuation = null;
    });
    _load();
  }

  void _open(VideoSearchResult v) =>
      Navigator.of(context).pushNamed('/watch', arguments: v.videoId);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final info = _info;
    final subscribed = info != null && app.isSubscribed(info.channelId);

    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(
        title: Text(
          _loading ? 'Channel' : info?.name ?? 'Channel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Loader(label: 'Loading channel…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(info!, subscribed),
    );
  }

  Widget _buildBody(ChannelInfo info, bool subscribed) {
    final app = context.read<AppState>();
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        // Banner.
        if (info.banner != null && info.banner!.isNotEmpty)
          SliverToBoxAdapter(
            child: Image.network(
              info.banner!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        // Header.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  ChannelAvatar(
                    url: info.avatars.isNotEmpty ? info.avatars.last : '',
                    name: info.name,
                    size: 62,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.name,
                            style: const TextStyle(
                                color: V.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (info.handle != null) info.handle!,
                            if (info.subscriberCount != null)
                              '${compactViews(info.subscriberCount!)} subscribers',
                            if (info.videoCount != null)
                              '${info.videoCount} videos',
                          ].join(' • '),
                          style: const TextStyle(
                              color: V.textDim, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: subscribed ? V.surface : V.red,
                      foregroundColor: subscribed ? V.text : Colors.white,
                      side: BorderSide(
                          color: subscribed ? V.outline : V.red),
                    ),
                    onPressed: () {
                      app.toggleSubscription(SubChannel(
                        channelId: info.channelId,
                        name: info.name,
                        avatarUrl:
                            info.avatars.isNotEmpty ? info.avatars.last : '',
                        subscribedAt: DateTime.now(),
                      ));
                    },
                    child: Text(subscribed ? 'Subscribed' : 'Subscribe',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ]),
                if (info.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    info.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: V.textDim, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Sort chips.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              AppIcons.sort.icon(size: 16),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Newest'),
                selected: _sort == _ChanSort.newest,
                onSelected: (_) => _setSort(_ChanSort.newest),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Popular'),
                selected: _sort == _ChanSort.popular,
                onSelected: (_) => _setSort(_ChanSort.popular),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Oldest'),
                selected: _sort == _ChanSort.oldest,
                onSelected: (_) => _setSort(_ChanSort.oldest),
              ),
            ]),
          ),
        ),
        // Videos grid.
        if (_videos.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyView(message: 'No videos on this channel.'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.98,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == _videos.length && _loadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: V.red),
                      ),
                    );
                  }
                  return VideoCard(
                    video: _videos[i],
                    onTap: () => _open(_videos[i]),
                  );
                },
                childCount: _videos.length + (_loadingMore ? 1 : 0),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mini screen: resolve a channel by searching its name — used when a
/// trending card has a channel name but no id.
class ChannelLookupScreen extends StatefulWidget {
  final String channelName;

  const ChannelLookupScreen({super.key, required this.channelName});

  @override
  State<ChannelLookupScreen> createState() => _ChannelLookupScreenState();
}

class _ChannelLookupScreenState extends State<ChannelLookupScreen> {
  List<VideoSearchResult> _results = [];
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
      final page = await Yt.I.kmep.search(widget.channelName);
      if (!mounted) return;
      setState(() {
        _results = page.results.take(20).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(title: Text('Find channel: ${widget.channelName}')),
      body: _loading
          ? const Loader()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final v = _results[i];
                    return VideoCard(
                      video: v,
                      onTap: () => Navigator.of(context)
                          .pushNamed('/watch', arguments: v.videoId),
                    );
                  },
                ),
    );
  }
}
