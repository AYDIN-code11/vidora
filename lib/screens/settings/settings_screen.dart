import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidora/core/strings.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/services/caption_service.dart';
import 'package:vidora/state/app_state.dart';

/// Settings: language, player defaults, history toggle, region, about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _regions = {
    'US': 'United States',
    'GB': 'United Kingdom',
    'DE': 'Deutschland',
    'FR': 'France',
    'RU': 'Россия',
    'TR': 'Türkiye',
    'KZ': 'Қазақстан',
    'AZ': 'Azərbaycan',
    'IN': 'India',
    'JP': '日本',
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = context.s;

    return Scaffold(
      backgroundColor: V.bg,
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _section(context, s.language),
          ListTile(
            leading: AppIcons.community.icon(size: 22),
            title: Text(s.language,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(
                app.lang.label +
                    (app.lang.hl != 'en' ? ' (UI + YouTube)' : ''),
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _pickLanguage(context, app),
          ),
          _section(context, s.player),
          SwitchListTile(
            activeThumbColor: V.red,
            secondary: AppIcons.comments.icon(size: 22),
            title: Text(s.captions,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(s.captionsOff,
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            value: app.captionsOn,
            onChanged: app.setCaptionsOn,
          ),
          ListTile(
            leading: AppIcons.comments.icon(size: 22),
            title: Text(s.translate,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(
                CaptionService.supportedLanguages[app.captionLang] ??
                    app.captionLang,
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _pickCaptionLang(context, app),
          ),
          ListTile(
            leading: AppIcons.play.icon(size: 22),
            title: Text(s.defaultQuality,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(
                app.defaultResolution >= 2160
                    ? s.highestAvailable
                    : '${app.defaultResolution}p',
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _pickQuality(context, app),
          ),
          SwitchListTile(
            activeThumbColor: V.red,
            secondary: AppIcons.play.icon(size: 22),
            title: Text(s.autoplayNext,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(s.autoplayNextSub,
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            value: app.autoplayNext,
            onChanged: app.setAutoplayNext,
          ),
          _section(context, s.privacy),
          SwitchListTile(
            activeThumbColor: V.red,
            secondary: AppIcons.history.icon(size: 22),
            title: Text(s.watchHistory,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(s.watchHistorySub,
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            value: app.historyEnabled,
            onChanged: app.setHistoryEnabled,
          ),
          _section(context, s.content),
          ListTile(
            leading: AppIcons.trending.icon(size: 22),
            title: Text(s.contentRegion,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text(
                '${_regions[app.region] ?? app.region} (${app.region})',
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _pickRegion(context, app),
          ),
          _section(context, s.aboutVidora),
          ListTile(
            leading: AppIcons.about.icon(size: 22),
            title: Text(s.aboutVidora,
                style: const TextStyle(color: V.text, fontSize: 14.5)),
            subtitle: Text('${s.version} 1.1.0',
                style: const TextStyle(color: V.textDim, fontSize: 12.5)),
            trailing: const Icon(Icons.chevron_right, color: V.textDim),
            onTap: () => _about(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String label) => Padding(
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

  void _pickLanguage(BuildContext context, AppState app) {
    final s = context.s;
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(s.language,
                  style: const TextStyle(
                      color: V.text, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            for (final lang in S.all)
              ListTile(
                leading: Icon(
                  app.lang == lang
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: V.red,
                  size: 20,
                ),
                title: Text(lang.label,
                    style: const TextStyle(color: V.text, fontSize: 14)),
                subtitle: Text(
                  lang.hl == 'en' ? 'UI + YouTube metadata' : 'UI + YouTube',
                  style: const TextStyle(color: V.textDim, fontSize: 11.5),
                ),
                onTap: () {
                  app.setAppLanguage(lang);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickCaptionLang(BuildContext context, AppState app) {
    final s = context.s;
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(s.translate,
                    style: const TextStyle(
                        color: V.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e
                          in CaptionService.supportedLanguages.entries)
                        ListTile(
                          leading: Icon(
                            app.captionLang == e.key
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: V.red,
                            size: 20,
                          ),
                          title: Text(e.value,
                              style:
                                  const TextStyle(color: V.text, fontSize: 14)),
                          onTap: () {
                            app.setCaptionLang(e.key);
                            Navigator.pop(sheetContext);
                          },
                        ),
                    ],
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

  void _pickQuality(BuildContext context, AppState app) {
    final s = context.s;
    const qualities = [360, 480, 720, 1080, 1440, 2160];
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(s.defaultQuality,
                  style: const TextStyle(
                      color: V.text, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            for (final h in qualities)
              ListTile(
                leading: Icon(
                  app.defaultResolution == h
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: V.red,
                  size: 20,
                ),
                title: Text(
                  h == 2160 ? '${s.highestAvailable} (4K+)' : '${h}p',
                  style: const TextStyle(color: V.text, fontSize: 14),
                ),
                onTap: () {
                  app.setDefaultResolution(h);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickRegion(BuildContext context, AppState app) {
    final s = context.s;
    showModalBottomSheet<void>(
      backgroundColor: V.surface,
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(s.contentRegion,
                    style: const TextStyle(
                        color: V.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in _regions.entries)
                        ListTile(
                          leading: Icon(
                            app.region == e.key
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: V.red,
                            size: 20,
                          ),
                          title: Text('${e.value} (${e.key})',
                              style:
                                  const TextStyle(color: V.text, fontSize: 14)),
                          onTap: () {
                            app.setRegion(e.key);
                            Navigator.pop(sheetContext);
                          },
                        ),
                    ],
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
    final s = context.s;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: V.surface,
        title: Row(children: [
          AppIcons.logo.icon(size: 30),
          const SizedBox(width: 10),
          const Text('Vidora', style: TextStyle(color: V.text)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.version} 1.1.0',
                style: const TextStyle(color: V.red, fontSize: 12.5)),
            const SizedBox(height: 10),
            Text(s.aboutText,
                style:
                    const TextStyle(color: V.textDim, fontSize: 13, height: 1.5)),
            const SizedBox(height: 10),
            Text(s.licensedUnder,
                style: const TextStyle(color: V.textDim, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.close, style: const TextStyle(color: V.red)),
          ),
        ],
      ),
    );
  }
}
