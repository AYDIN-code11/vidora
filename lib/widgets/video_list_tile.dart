import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show VideoSearchResult;
import 'package:provider/provider.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';

/// Horizontal list row for a video (search results, related lists).
class VideoListTile extends StatelessWidget {
  final VideoSearchResult video;
  final VoidCallback onTap;

  const VideoListTile({
    super.key,
    required this.video,
    required this.onTap,
  });

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

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(children: [
              SizedBox(
                width: 160,
                height: 90,
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: V.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: V.surface,
                    child: const Icon(Icons.error_outline,
                        color: V.textDim, size: 26),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    video.durationSeconds > 0
                        ? formatDuration(video.durationSeconds)
                        : 'LIVE',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
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
          ),
          const SizedBox(width: 10),
          // Texts.
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
                      '${compactViews(video.viewCount)} views',
                    if (video.uploadDate.isNotEmpty) video.uploadDate,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: V.textDim, fontSize: 11.5),
                ),
              ],
            ),
          ),
          // Bookmark toggle.
          GestureDetector(
            onTap: () =>
                context.read<AppState>().toggleBookmark(video),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: bookmarked
                  ? AppIcons.bookmarkFilled.icon(size: 18)
                  : AppIcons.bookmark.icon(size: 18, color: V.textDim),
            ),
          ),
        ],
      ),
    );
  }
}
