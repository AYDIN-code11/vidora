import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show VideoSearchResult;
import 'package:vidora/core/theme.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/widgets/common.dart';
import 'package:vidora/widgets/video_card.dart';

/// Home screen: trending and category feeds via InnerTube /browse.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _selected = ValueNotifier<int>(0);
  final _pages = <int, List<VideoSearchResult>>{};
  final _loading = <int, bool>{};
  final _errors = <int, String?>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  Future<void> _load(int index) async {
    if (_loading[index] == true) return;
    setState(() {
      _loading[index] = true;
      _errors[index] = null;
    });
    try {
      final cat = trendingCategories[index];
      final videos = await Yt.I.trending.fetch(
        cat.id,
        hl: 'en',
        gl: 'US',
      );
      if (!mounted) return;
      setState(() {
        _pages[index] = videos;
        _loading[index] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[index] = e.toString();
        _loading[index] = false;
      });
    }
  }

  void _open(VideoSearchResult v) {
    Navigator.of(context).pushNamed('/watch', arguments: v.videoId);
  }

  void _openChannel(VideoSearchResult v) {
    // Channel ids aren't on trending cards; channel page accepts a
    // channel name search — open the channel finder instead.
    Navigator.of(context)
        .pushNamed('/channel_lookup', arguments: v.channelName);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(
        title: Row(children: [
          AppIcons.logo.icon(size: 26),
          const SizedBox(width: 8),
          const Text('Vidora'),
        ]),
        automaticallyImplyLeading: false,
      ),
      body: Column(children: [
        _CategoryStrip(
          selected: _selected,
          onChanged: (i) {
            _selected.value = i;
            if (!_pages.containsKey(i)) _load(i);
          },
        ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _selected,
            builder: (context, index, _) {
              if (_loading[index] == true) {
                return const Loader(label: 'Loading feed…');
              }
              final err = _errors[index];
              if (err != null) {
                return ErrorView(
                  message: err,
                  onRetry: () => _load(index),
                );
              }
              final videos = _pages[index] ?? const [];
              if (videos.isEmpty) {
                return const EmptyView(message: 'Nothing here yet.');
              }
              return RefreshIndicator(
                color: V.red,
                backgroundColor: V.surface,
                onRefresh: () => _load(index),
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.98,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, i) => VideoCard(
                    video: videos[i],
                    onTap: () => _open(videos[i]),
                    onChannelTap: () => _openChannel(videos[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final ValueNotifier<int> selected;
  final ValueChanged<int> onChanged;

  const _CategoryStrip({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      color: V.bg,
      child: ValueListenableBuilder<int>(
        valueListenable: selected,
        builder: (context, sel, _) => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          scrollDirection: Axis.horizontal,
          itemCount: trendingCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final cat = trendingCategories[i];
            final active = i == sel;
            return ChoiceChip(
              label: Text(
                cat.label,
                style: TextStyle(
                  color: active ? Colors.white : V.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: active,
              showCheckmark: false,
              selectedColor: V.red,
              backgroundColor: V.surface,
              side: BorderSide(color: active ? V.red : V.outline),
              onSelected: (_) => onChanged(i),
            );
          },
        ),
      ),
    );
  }
}
