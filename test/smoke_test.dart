import 'package:flutter_test/flutter_test.dart';
import 'package:vidora/main.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/services/youtube_service.dart';
import 'package:vidora/models/local_models.dart';
import 'package:vidora/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('extractVideoId parses common URL forms', () {
    expect(extractVideoId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ');
    expect(extractVideoId('https://youtu.be/dQw4w9WgXcQ?t=1'), 'dQw4w9WgXcQ');
    expect(extractVideoId('https://www.youtube.com/shorts/abcdef12345'),
        'abcdef12345');
    expect(extractVideoId('https://www.youtube.com/embed/kJQP7kiw5Fk'),
        'kJQP7kiw5Fk');
  });

  test('parseVideoCards extracts renderer items and dedups', () {
    final fake = <String, dynamic>{
      'contents': {
        'items': [
          {
            'videoRenderer': {
              'videoId': 'abc12345678',
              'title': {'runs': [
                {'text': 'Test Video'}
              ]},
              'ownerText': {'runs': [
                {'text': 'Test Channel'}
              ]},
              'lengthText': {'simpleText': '1:23'},
              'viewCountText': {'simpleText': '1,234 views'},
              'publishedTimeText': {'simpleText': '2 days ago'},
              'thumbnail': {
                'thumbnails': [
                  {'url': '//i.ytimg.com/vi/abc/hq.jpg'}
                ]
              },
            }
          },
          {
            'videoRenderer': {
              'videoId': 'abc12345678',
              'title': {'runs': [
                {'text': 'Dup'}
              ]},
            }
          },
        ]
      }
    };
    final cards = parseVideoCards(fake);
    expect(cards.length, 1);
    expect(cards.first.videoId, 'abc12345678');
    expect(cards.first.title, 'Test Video');
    expect(cards.first.channelName, 'Test Channel');
    expect(cards.first.durationSeconds, 83);
    expect(cards.first.viewCount, 1234);
    expect(cards.first.thumbnailUrl, 'https://i.ytimg.com/vi/abc/hq.jpg');
  });

  test('runsText / lengthToSeconds / viewsFromText helpers', () {
    expect(runsText({'simpleText': 'hi'}), 'hi');
    expect(runsText({
      'runs': [
        {'text': 'yo'}
      ]
    }), 'yo');
    expect(runsText('notamap'), null);
    expect(lengthToSeconds('1:02:03'), 3723);
    expect(lengthToSeconds('12:34'), 754);
    expect(viewsFromText('1.2M views'), 12);
    expect(thumbnailUrlOf({'thumbnail': null}), '');
  });

  test('AppIcons exposes all SVG assets', () {
    expect(AppIcons.home, isNotNull);
    expect(AppIcons.byName('home').asset, 'assets/icons/home.svg');
    expect(AppIcons.byName('nonexistent').asset, 'assets/icons/logo.svg');
  });

  testWidgets('VidoraApp renders HomeShell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(VidoraApp(prefs: prefs));
    await tester.pump();
    expect(find.text('Vidora'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  test('AppState persists and mutates', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final app = AppState(prefs);
    expect(app.subs, isEmpty);
    expect(app.historyEnabled, isTrue);
    expect(app.defaultResolution, 720);

    final sub = SubChannel(
        channelId: 'UCx',
        name: 'X',
        avatarUrl: '',
        subscribedAt: DateTime(2026));
    app.toggleSubscription(sub);
    expect(app.isSubscribed('UCx'), isTrue);
    app.toggleSubscription(sub);
    expect(app.isSubscribed('UCx'), isFalse);

    app.addQuery('hello');
    app.addQuery('world');
    app.addQuery('hello');
    expect(app.queries.first.text, 'hello');
    expect(app.queries.length, 2);

    final fresh = AppState(prefs);
    expect(fresh.queries.map((q) => q.text), contains('hello'));
  });
}
