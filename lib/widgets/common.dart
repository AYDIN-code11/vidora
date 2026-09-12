import 'package:flutter/material.dart';
import 'package:vidora/core/theme.dart';

/// Circular loader in app style.
class Loader extends StatelessWidget {
  final String? label;
  const Loader({super.key, this.label});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: V.red),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!,
                  style: const TextStyle(color: V.textDim, fontSize: 14)),
            ],
          ],
        ),
      );
}

/// Full-screen error panel with retry.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: V.red, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: V.text, fontSize: 15),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: V.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

/// Simple empty-state panel.
class EmptyView extends StatelessWidget {
  final String message;
  const EmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: V.textDim, fontSize: 15),
          ),
        ),
      );
}

/// Formats seconds into h:mm:ss / m:ss.
String formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '--:--';
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Compact view count: 1234567 -> 1.2M.
String compactViews(int views) {
  if (views < 1000) return '$views';
  if (views < 1000000) {
    final k = views / 1000;
    return '${k >= 100 ? k.round() : k.toStringAsFixed(1)}K';
  }
  if (views < 1000000000) {
    final m = views / 1000000;
    return '${m >= 100 ? m.round() : m.toStringAsFixed(1)}M';
  }
  return '${(views / 1000000000).toStringAsFixed(1)}B';
}
