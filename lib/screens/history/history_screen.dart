import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/models/local_models.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/common.dart';

/// Watch history with sort, swipe-to-delete and resume info.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final entries = app.sortedHistory;

    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(
        title: const Text('History'),
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
            onPressed: entries.isEmpty
                ? null
                : () => _confirmClear(context, app),
          ),
        ],
      ),
      body: !app.historyEnabled
          ? const EmptyView(message: 'Watch history is disabled in Settings.')
          : entries.isEmpty
              ? const EmptyView(message: 'Nothing watched yet.')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return Dismissible(
                      key: Key('history-${e.videoId}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 18),
                        color: V.redDark,
                        child: const Icon(Icons.delete,
                            color: Colors.white, size: 22),
                      ),
                      onDismissed: (_) => app.removeHistory(e.videoId),
                      child: _HistoryTile(entry: e),
                    );
                  },
                ),
    );
  }

  void _pickSort(BuildContext context) {
    final app = context.read<AppState>();
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Sort by',
                  style: TextStyle(
                      color: V.text, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            RadioListTile<HistorySort>(
              activeColor: V.red,
              value: HistorySort.newest,
              groupValue: app.historySort,
              onChanged: (v) {
                app.setHistorySort(v!);
                Navigator.pop(context);
              },
              title: const Text('Newest first',
                  style: TextStyle(color: V.text)),
            ),
            RadioListTile<HistorySort>(
              activeColor: V.red,
              value: HistorySort.oldest,
              groupValue: app.historySort,
              onChanged: (v) {
                app.setHistorySort(v!);
                Navigator.pop(context);
              },
              title: const Text('Oldest first',
                  style: TextStyle(color: V.text)),
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
        title: const Text('Clear history?',
            style: TextStyle(color: V.text)),
        content: const Text(
            'This removes all watch history from this device.',
            style: TextStyle(color: V.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: V.textDim)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: V.red),
            onPressed: () {
              app.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date =
        '${entry.watchedAt.day.toString().padLeft(2, '0')}.'
        '${entry.watchedAt.month.toString().padLeft(2, '0')} '
        '${entry.watchedAt.hour.toString().padLeft(2, '0')}:'
        '${entry.watchedAt.minute.toString().padLeft(2, '0')}';
    final pct = entry.durationSeconds > 0 && entry.watchedSeconds > 0
        ? (entry.watchedSeconds / entry.durationSeconds).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: () => Navigator.of(context)
          .pushNamed('/watch', arguments: entry.videoId),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [
            SizedBox(
              width: 140,
              height: 79,
              child: entry.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      entry.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: V.surface),
                    )
                  : Container(color: V.surface),
            ),
            if (pct > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 3,
                  color: V.red,
                  backgroundColor: Colors.black38,
                ),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
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
                  if (entry.channelName.isNotEmpty) entry.channelName,
                  date,
                  if (pct > 0)
                    '${(pct * 100).toInt()}% watched'
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: V.textDim, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
