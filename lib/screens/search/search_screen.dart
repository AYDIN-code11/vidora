import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show VideoSearchResult;
import 'package:provider/provider.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/models/local_models.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';
import 'package:vidora/widgets/video_list_tile.dart';

/// Search screen with query history and paginated results.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  List<VideoSearchResult> _results = [];
  String? _continuation;
  String _query = '';
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
              _scroll.position.maxScrollExtent - 600 &&
          _continuation != null &&
          !_loadingMore &&
          !_loading) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _run(String q) async {
    if (q.trim().isEmpty) return;
    _focus.unfocus();
    context.read<AppState>().addQuery(q);
    setState(() {
      _query = q;
      _loading = true;
      _error = null;
      _results = [];
      _continuation = null;
    });
    try {
      final page = await Yt.I.kmep.search(q);
      setState(() {
        _results = page.results;
        _continuation = page.continuation;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cont = _continuation;
    if (cont == null || _query.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await Yt.I.kmep.search(_query, continuation: cont);
      setState(() {
        // Dedup by id.
        final seen = _results.map((r) => r.videoId).toSet();
        _results.addAll(page.results.where((r) => !seen.contains(r.videoId)));
        _continuation = page.continuation;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  void _open(VideoSearchResult v) {
    Navigator.of(context).pushNamed('/watch', arguments: v.videoId);
  }

  @override
  Widget build(BuildContext context) {
    final queries = context.watch<AppState>().queries;
    final showHistory = _results.isEmpty && !_loading && _error == null;

    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _run,
            style: const TextStyle(color: V.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search videos, shorts, channels…',
              prefixIcon: const Icon(Icons.search, color: V.textDim, size: 22),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: V.textDim, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _results = [];
                          _error = null;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Loader(label: 'Searching…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _run(_query))
              : showHistory
                  ? _historyList(queries)
                  : _resultsList(),
    );
  }

  Widget _historyList(List<QueryItem> queries) {
    if (queries.isEmpty) {
      return const EmptyView(
          message: 'Search for anything on YouTube — anonymously.');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: queries.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: V.outline.withValues(alpha: 0.4)),
      itemBuilder: (context, i) {
        final q = queries[i];
        return ListTile(
          leading: const Icon(Icons.history, color: V.textDim, size: 22),
          title: Text(q.text,
              style: const TextStyle(color: V.text, fontSize: 14.5)),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: V.textDim, size: 18),
            onPressed: () => context.read<AppState>().removeQuery(q.text),
          ),
          onTap: () {
            _controller.text = q.text;
            _run(q.text);
          },
        );
      },
    );
  }

  Widget _resultsList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: _results.length + 1,
      itemBuilder: (context, i) {
        if (i == _results.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: V.red),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        final v = _results[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VideoListTile(
            video: v,
            onTap: () => _open(v),
          ),
        );
      },
    );
  }
}
