import 'package:flutter/material.dart';
import 'package:kmep/kmep.dart' show VideoInfo, KMEPStream;
import 'package:vidora/core/theme.dart';

/// Horizontal quality selector strip below the player.
class QualityPicker extends StatelessWidget {
  final VideoInfo video;
  final int selectedItag;
  final ValueChanged<int> onSelected;

  const QualityPicker({
    super.key,
    required this.video,
    required this.selectedItag,
    required this.onSelected,
  });

  List<KMEPStream> get _progressive => video.streams
      .where((s) => s.type == 'video')
      .toList()
      ..sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));

  @override
  Widget build(BuildContext context) {
    if (_progressive.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _progressive.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _progressive[i];
          final selected = s.itag == selectedItag;
          return ChoiceChip(
            label: Text(
              s.isLive ? 'LIVE' : s.quality,
              style: TextStyle(
                color: selected ? Colors.white : V.textDim,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: selected,
            showCheckmark: false,
            selectedColor: V.red,
            backgroundColor: V.surface,
            side: BorderSide(
                color: selected ? V.red : V.outline, width: 1),
            onSelected: (_) => onSelected(s.itag),
          );
        },
      ),
    );
  }
}
