import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidora/core/strings.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/models/local_models.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';

/// Bookmarks (locally saved videos) with sorting.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.sortedBookmarks;

    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(
        title: Text(context.s.saved),
        actions: [
          IconButton(
            tooltip: 'Sort',
            icon: AppIcons.sort.icon(size: 20),
            onPressed: () => _pickSort(context),
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined,
                color: V.red, size: 22),
            onPressed: items.isEmpty
                ? null
                : () => _confirmClear(context, app),
          ),
        ],
      ),
      body: items.isEmpty
          ? EmptyView(message: context.s.bookmarksEmpty)
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _BookmarkTile(item: items[i]),
            ),
    );
  }

  void _pickSort(BuildContext context) {
    final app = context.read<AppState>();
    final s = context.s;
    final options = [
      (s.sortNewest, BookmarkSort.newest),
      (s.sortOldest, BookmarkSort.oldest),
      (s.titleAZ, BookmarkSort.title),
    ];
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(context.s.sortBy,
                  style: const TextStyle(
                      color: V.text, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            for (final (label, value) in options)
              ListTile(
                leading: Icon(
                  app.bookmarkSort == value
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: V.red,
                  size: 20,
                ),
                title: Text(label, style: const TextStyle(color: V.text)),
                onTap: () {
                  app.setBookmarkSort(value);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState app) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: V.surface,
        title: Text(context.s.removeAllQ,
            style: const TextStyle(color: V.text)),
        content: Text(context.s.bookmarksBody,
            style: const TextStyle(color: V.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.s.cancel, style: const TextStyle(color: V.textDim)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: V.red),
            onPressed: () {
              app.clearBookmarks();
              Navigator.pop(context);
            },
            child: Text(context.s.remove),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Bookmark item;

  const _BookmarkTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context)
          .pushNamed('/watch', arguments: item.videoId),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 140,
            height: 79,
            child: item.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: V.surface),
                    errorWidget: (_, __, ___) =>
                        Container(color: V.surface),
                  )
                : Container(color: V.surface),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: V.text,
                      fontSize: 13.5,
                      height: 1.25,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                [
                  if (item.channelName.isNotEmpty) item.channelName,
                  if (item.durationSeconds > 0)
                    formatDuration(item.durationSeconds),
                  if (item.viewCount > 0)
                    '${compactViews(item.viewCount)} ${context.s.viewsSuffix}',
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: V.textDim, fontSize: 11.5),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: V.textDim, size: 20),
          onPressed: () =>
              context.read<AppState>().removeBookmark(item.videoId),
        ),
      ]),
    );
  }
}
