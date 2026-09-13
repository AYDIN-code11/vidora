import 'package:flutter/material.dart';
import 'package:vidora/services/caption_service.dart';

/// Live subtitle overlay docked at the bottom of the video surface.
/// Shows the active [CaptionCue] text with a translucent black
/// backing for readability; small status lines for translation
/// in-flight / errors; nothing when captions are off.
class CaptionOverlay extends StatelessWidget {
  final CaptionCue? cue;
  final bool visible;
  final bool translating;
  final String? error;

  const CaptionOverlay({
    super.key,
    required this.cue,
    required this.visible,
    this.translating = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final status = error ?? (translating ? '…' : null);

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (cue != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                cue!.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
