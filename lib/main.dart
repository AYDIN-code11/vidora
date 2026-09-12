import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/screens/channel/channel_screen.dart';
import 'package:vidora/screens/shorts/shorts_screen.dart';
import 'package:vidora/screens/watch/watch_screen.dart';
import 'package:vidora/state/app_state.dart';
import 'package:vidora/widgets/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF141414),
  ));

  final prefs = await SharedPreferences.getInstance();
  runApp(VidoraApp(prefs: prefs));
}

class VidoraApp extends StatelessWidget {
  final SharedPreferences prefs;

  const VidoraApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: MaterialApp(
        title: 'Vidora',
        debugShowCheckedModeBanner: false,
        theme: V.theme(),
        routes: {
          '/': (context) => const HomeShell(),
          '/watch': (context) {
            final id = ModalRoute.of(context)!.settings.arguments as String;
            return WatchScreen(videoId: id);
          },
          '/channel': (context) {
            final id =
                ModalRoute.of(context)!.settings.arguments as String;
            return ChannelScreen(channelId: id);
          },
          '/channel_lookup': (context) {
            final name =
                ModalRoute.of(context)!.settings.arguments as String;
            return ChannelLookupScreen(channelName: name);
          },
          '/shorts': (context) => const ShortsScreen(),
        },
      ),
    );
  }
}
