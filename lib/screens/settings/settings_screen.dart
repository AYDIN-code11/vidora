import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/state/app_state.dart';

/// Settings: player defaults, history toggle, region, about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _regions = {
    'US': 'United States',
    'GB': 'United Kingdom',
    'DE': 'Germany',
    'FR': 'France',
    'RU': 'Russia',
    'TR': 'Türkiye',
    'KZ': 'Kazakhstan',
    'AZ': 'Azerbaijan',
    'IN': 'India',
    'JP': 'Japan',
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _section('Player'),
          ListTile(
            leading: AppIcons.play.icon(size: 22),
            title: const Text('Default quality',
                style: TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(
                app.defaultResolution >= 2160
                    ? 'Highest available'
                    : '${app.defaultResolution}p',
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _pickQuality(context, app),
          ),
          SwitchListTile(
            activeColor: V.red,
            secondary: AppIcons.play.icon(size: 22),
            title: const Text('Autoplay next',
                style: TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: const Text(
                'Play suggested videos when one ends',
                style: TextStyle(color: V.textDim, fontSize: 12.5)),
            value: app.autoplayNext,
            onChanged: app.setAutoplayNext,
          ),
          _section('Privacy'),
          SwitchListTile(
            activeColor: V.red,
            secondary: AppIcons.history.icon(size: 22),
            title: const Text('Watch history',
                style: TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: const Text('Stored only on this device',
                style: TextStyle(color: V.textDim, fontSize: 12.5)),
            value: app.historyEnabled,
            onChanged: app.setHistoryEnabled,
          ),
          _section('Content'),
          ListTile(
            leading: AppIcons.trending.icon(size: 22),
            title: const Text('Content region',
                style: TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(
                '${_regions[app.region] ?? app.region} (${app.region})',
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _pickRegion(context, app),
          ),
          _section('About'),
          ListTile(
            leading: AppIcons.about.icon(size: 22),
            title: const Text('About Vidora',
                style: TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: const Text('Version 1.0.0',
                style: TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _about(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
              color: V.red,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2),
        ),
      );

  void _pickQuality(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Default quality',
                  style: TextStyle(
                      color: V.text, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            for (final h in const [360, 480, 720, 1080, 1440, 2160])
              RadioListTile<int>(
                activeColor: V.red,
                value: h,
                groupValue: app.defaultResolution,
                onChanged: (v) {
                  app.setDefaultResolution(v!);
                  Navigator.pop(context);
                },
                title: Text(
                  h == 2160 ? 'Highest available (4K+)' : '${h}p',
                  style: const TextStyle(color: V.text),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickRegion(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Content region',
                    style: TextStyle(
                        color: V.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _regions.entries
                        .map((e) => RadioListTile<String>(
                              activeColor: V.red,
                              value: e.key,
                              groupValue: app.region,
                              onChanged: (v) {
                                app.setRegion(v!);
                                Navigator.pop(context);
                              },
                              title: Text('${e.value} (${e.key})',
                                  style:
                                      const TextStyle(color: V.text)),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: V.surface,
        title: Row(children: [
          AppIcons.logo.icon(size: 30),
          const SizedBox(width: 10),
          const Text('Vidora', style: TextStyle(color: V.text)),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0',
                style: TextStyle(color: V.red, fontSize: 12.5)),
            SizedBox(height: 10),
            Text(
              'A privacy-friendly YouTube client built with Flutter and '
              'KMEP. No account, no ads, no tracking — everything runs '
              'on your device.',
              style: TextStyle(color: V.textDim, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 10),
            Text('Licensed under GPL-3.0.',
                style: TextStyle(color: V.textDim, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: V.red)),
          ),
        ],
      ),
    );
  }
}
