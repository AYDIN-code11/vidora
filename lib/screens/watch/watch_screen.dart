import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kmep/kmep.dart' show VideoInfo, VideoSearchResult, KMEPStream;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/models/local_models.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';
import 'package:vidora/widgets/quality_picker.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// A standalone, fully functional video player screen for one video.
/// Resolves streams via KMEP on open and plays the selected quality.
class WatchScreen extends StatefulWidget {
  final String videoId;
  final String? channelId;

  const WatchScreen({super.key, required this.videoId, this.channelId});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  VideoInfo? _video;
  String? _error;
  bool _loading = true;
  int _retries = 0;

  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  int _selectedItag = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final app = context.read<AppState>();
    try {
      final video = await Yt.I.kmep.getVideo(widget.videoId);
      final wantedHeight = app.defaultResolution;
      final wanted = video.streams
          .where((s) => s.type == 'video')
          .toList()
        ..sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));

      // Best stream <= preferred resolution.
      KMEPStream? pick;
      for (final s in wanted) {
        if ((s.height ?? 0) <= wantedHeight) {
          pick = s;
          break;
        }
      }
      pick ??= wanted.isNotEmpty ? wanted.first : null;

      if (pick == null) {
        throw Exception('No playable streams found for this video.');
      }
      await _player.open(Media(pick.url));
      if (!mounted) return;
      app.recordWatch(video);
      final pickedItag = pick.itag;
      setState(() {
        _video = video;
        _selectedItag = pickedItag;
        _loading = false;
      });
    } catch (e) {
      if (_retries < 2) {
        _retries++;
        await Future<void>.delayed(const Duration(seconds: 1));
        return _load();
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _switchStream(int itag) async {
    final video = _video;
    if (video == null) return;
    final stream =
        video.streams.where((s) => s.itag == itag).firstOrNull;
    if (stream == null) return;
    final position = await _player.stream.position.first;
    if (!mounted) return;
    setState(() => _selectedItag = itag);
    await _player.open(Media(stream.url));
    if (position.inMilliseconds > 0) {
      await _player.seek(position);
    }
  }

  void _share() {
    // Delegates to the share sheet via share_plus (wired in main).
    final video = _video;
    if (video != null) {
      ShareLink.open(context, video);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(
        title: Text(
          _video?.title ?? 'Watching',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: _video == null ? null : _share,
            icon: AppIcons.share.icon(size: 20),
          ),
        ],
      ),
      body: _loading
          ? const Loader(label: 'Resolving streams…')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final video = _video!;
    final app = context.watch<AppState>();
    final bookmarked = app.isBookmarked(video.videoId);
    final infoRow = [
      if (video.publishDate != null) video.publishDate!,
      if (video.viewCount > 0) '${compactViews(video.viewCount)} views',
      if (video.likes != null) '${compactViews(video.likes!)} likes',
    ].join(' • ');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Video(
            controller: _controller,
            controls: AdaptiveVideoControls,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            video.title,
            style: const TextStyle(
                color: V.text, fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(infoRow,
              style: const TextStyle(color: V.textDim, fontSize: 12.5)),
        ),
        const SizedBox(height: 10),
        QualityPicker(
          video: video,
          selectedItag: _selectedItag,
          onSelected: _switchStream,
        ),
        const SizedBox(height: 6),
        // Action row: channel, subscribe, bookmark.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _openChannel(context, video),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.smart_display_outlined,
                        color: V.red, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        video.channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: V.text, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ActionChip(
              label: app.isSubscribed(video.channelId) ? 'Subscribed' : 'Subscribe',
              filled: !app.isSubscribed(video.channelId),
              onTap: () => _toggleSub(video),
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: bookmarked
                  ? AppIcons.bookmarkFilled.icon(size: 16)
                  : AppIcons.bookmark.icon(size: 16),
              label: bookmarked ? 'Saved' : 'Save',
              onTap: () => _toggleBookmark(video),
            ),
          ]),
        ),
        Divider(height: 1, color: V.outline.withValues(alpha: 0.5)),
        // Description.
        if (video.description.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              video.description.trim(),
              style: const TextStyle(color: V.textDim, fontSize: 13, height: 1.45),
            ),
          ),
      ],
    );
  }

  void _openChannel(BuildContext context, VideoInfo video) {
    Navigator.of(context).pushNamed('/channel', arguments: video.channelId);
  }

  void _toggleSub(VideoInfo video) {
    final app = context.read<AppState>();
    app.toggleSubscription(SubChannel(
      channelId: video.channelId,
      name: video.channelName,
      avatarUrl: video.channelAvatar ?? '',
      subscribedAt: DateTime.now(),
    ));
  }

  void _toggleBookmark(VideoInfo video) {
    context.read<AppState>().toggleBookmark(VideoSearchResult(
          videoId: video.videoId,
          title: video.title,
          channelName: video.channelName,
          thumbnailUrl:
              video.thumbnails.isNotEmpty ? video.thumbnails.first : '',
          durationSeconds: video.durationSeconds,
          viewCount: video.viewCount,
          uploadDate: video.publishDate ?? '',
        ));
  }
}

/// Small filled/outlined pill button for the action row.
class _ActionChip extends StatelessWidget {  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Widget? icon;

  const _ActionChip({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? V.red : V.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: filled ? V.red : V.outline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : V.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ]),
      ),
    );
  }
}

/// Central helper for the platform share sheet.
class ShareLink {
  static Future<void> open(BuildContext context, VideoInfo video) async {
    final url = 'https://www.youtube.com/watch?v=${video.videoId}';
    await Share.share(
      '${video.title} — $url',
      subject: video.title,
    );
  }
}
