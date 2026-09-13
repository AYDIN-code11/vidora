import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show VideoSearchResult;
import 'package:provider/provider.dart';
import 'package:vidora/core/strings.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';

/// Grid card for a video with bookmark toggle and click-through.
class VideoCard extends StatelessWidget {
  final VideoSearchResult video;
  final VoidCallback onTap;
  final VoidCallback? onChannelTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onChannelTap,
  });

  void _toggleBookmark(BuildContext context) {
    context.read<AppState>().toggleBookmark(video);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bookmarked = app.isBookmarked(video.videoId);
    final progress = app.historyEntryFor(video.videoId);
    final watchedPct = progress != null &&
            progress.durationSeconds > 0 &&
            progress.watchedSeconds > 0
        ? (progress.watchedSeconds / progress.durationSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: V.outline, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail + duration + progress.
            Stack(children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: V.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: V.surface,
                    child: const Icon(Icons.error_outline, color: V.textDim),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.durationSeconds > 0
                        ? formatDuration(video.durationSeconds)
                        : context.s.live,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (watchedPct > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: watchedPct,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    color: V.red,
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: V.text, fontSize: 13.5, height: 1.25, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (video.channelName.isNotEmpty) video.channelName,
                          if (video.viewCount > 0)
                            '${compactViews(video.viewCount)} ${context.s.viewsSuffix}',
                          if (video.uploadDate.isNotEmpty) video.uploadDate,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: V.textDim, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: V.surface,
                  icon: const Icon(Icons.more_vert, color: V.textDim, size: 20),
                  onSelected: (v) {
                    if (v == 'bookmark') _toggleBookmark(context);
                    if (v == 'channel' && onChannelTap != null) {
                      onChannelTap!();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'bookmark',
                      child: Row(children: [
                        Icon(
                          bookmarked
                              ? Icons.bookmark_remove_outlined
                              : Icons.bookmark_add_outlined,
                          color: V.red,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          bookmarked
                              ? context.s.removeBookmark
                              : context.s.bookmark,
                          style: const TextStyle(color: V.text, fontSize: 14),
                        ),
                      ]),
                    ),
                    if (onChannelTap != null)
                      PopupMenuItem(
                        value: 'channel',
                        child: Row(children: [
                          const Icon(Icons.account_circle_outlined,
                              color: V.red, size: 18),
                          const SizedBox(width: 10),
                          Text(context.s.goChannel,
                              style: const TextStyle(
                                  color: V.text, fontSize: 14)),
                        ]),
                      ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-clickable avatar with fallback initial.
class ChannelAvatar extends StatelessWidget {
  final String url;
  final String name;
  final double size;

  const ChannelAvatar(
      {super.key, required this.url, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return ClipOval(
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallback(letter),
              placeholder: (_, __) => _fallback(letter),
            )
          : _fallback(letter),
    );
  }

  Widget _fallback(String letter) => Container(
        width: size,
        height: size,
        color: V.surfaceHi,
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            color: V.red,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
