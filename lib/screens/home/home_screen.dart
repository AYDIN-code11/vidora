import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show VideoSearchResult;
import 'package:provider/provider.dart';
import 'package:vidora/core/strings.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';
import 'package:vidora/widgets/video_card.dart';

/// Home screen: category feeds (Now, Music, Gaming, News, …) via
/// seed searches on the InnerTube endpoint that reliably serves the
/// unauthenticated client. Switching the content language in Settings
/// localizes titles and view-count texts.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload the visible category when the content language changes.
    if (_lastLang != context.read<AppState>().lang) {
      _lastLang = context.read<AppState>().lang;
      _pages.clear();
      _errors.clear();
      _load(_selected.value);
    }
  }

  S? _lastLang;

  Future<void> _load(int index) async {
    if (_loading[index] == true) return;
    setState(() {
      _loading[index] = true;
      _errors[index] = null;
    });
    try {
      final app = context.read<AppState>();
      final cat = homeCategories[index];
      final videos = await Yt.I.home.fetch(
        cat,
        hl: app.lang.hl,
        gl: app.region,
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
                return Loader(label: context.s.loadingFeed);
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
                return EmptyView(message: context.s.nothingHere);
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
          itemCount: homeCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final cat = homeCategories[i];
            final active = i == sel;
            return ChoiceChip(
              label: Text(
                _categoryLabel(context, cat.id),
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

  String _categoryLabel(BuildContext context, String id) {
    final s = context.s;
    switch (id) {
      case 'music':
        return s.homeMusic;
      case 'gaming':
        return s.homeGaming;
      case 'news':
        return s.homeNews;
      case 'tech':
        return s.homeTech;
      case 'sports':
        return s.homeSports;
      case 'movies':
        return s.homeMovies;
      case 'shorts':
        return s.homeShorts;
      default:
        return s.homeNow;
    }
  }
}
