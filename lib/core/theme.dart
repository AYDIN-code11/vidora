import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Palette for the Vidora dark red/black theme.
class V {
  static const red = Color(0xFFFF1F2E);
  static const redDark = Color(0xFFB3151F);
  static const bg = Color(0xFF0E0E0E);
  static const bgLight = Color(0xFF161616);
  static const surface = Color(0xFF1F1F1F);
  static const surfaceHi = Color(0xFF2A2A2A);
  static const outline = Color(0xFF333333);
  static const text = Color(0xFFF1F1F1);
  static const textDim = Color(0xFF9A9A9A);

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: red,
        onPrimary: Colors.white,
        secondary: red,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: Color(0xFFFF5252),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF141414),
        selectedItemColor: red,
        unselectedItemColor: textDim,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF141414),
        indicatorColor: red.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.all(const IconThemeData(color: textDim)),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: textDim, fontSize: 11),
        ),
      ),
      cardTheme: const CardThemeData(color: bgLight, elevation: 0),
      dividerColor: outline,
      listTileTheme: const ListTileThemeData(iconColor: red),
      tabBarTheme: const TabBarThemeData(
        labelColor: red,
        unselectedLabelColor: textDim,
        indicatorColor: red,
        dividerColor: outline,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceHi,
        contentTextStyle: TextStyle(color: text),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: red),
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: red, selectionColor: red),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: surface),
      sliderTheme: const SliderThemeData(
        activeTrackColor: red,
        thumbColor: red,
        inactiveTrackColor: surfaceHi,
      ),
    );
  }
}

/// Asset-backed SVG icon set with red tinting.
class AppIcons {
  static const _dir = 'assets/icons/';

  static final home = _i('home.svg');
  static final trending = _i('trending.svg');
  static final search = _i('search.svg');
  static final subscriptions = _i('subscriptions.svg');
  static final bookmarks = _i('bookmarks.svg');
  static final history = _i('history.svg');
  static final settings = _i('settings.svg');
  static final play = _i('play.svg');
  static final sort = _i('sort.svg');
  static final playlist = _i('playlist.svg');
  static final bookmark = _i('bookmark.svg');
  static final bookmarkFilled = _i('bookmark_filled.svg');
  static final star = _i('star.svg');
  static final starFilled = _i('star_filled.svg');
  static final channel = _i('channel.svg');
  static final shorts = _i('shorts.svg');
  static final logout = _i('logout.svg');
  static final about = _i('about.svg');
  static final phone = _i('phone.svg');
  static final logo = _i('logo.svg');
  static final community = _i('community.svg');
  static final comments = _i('comments.svg');
  static final share = _i('share.svg');
  static final thumbnail = _i('thumbnail.svg');

  /// Looks an icon up by bare asset name (without directory/extension).
  static SvgAsset byName(String name) {
    switch (name) {
      case 'home':
        return home;
      case 'search':
        return search;
      case 'subscriptions':
        return subscriptions;
      case 'bookmarks':
        return bookmarks;
      case 'history':
        return history;
      case 'settings':
        return settings;
      case 'trending':
        return trending;
      case 'play':
        return play;
      case 'sort':
        return sort;
      case 'playlist':
        return playlist;
      case 'bookmark':
        return bookmark;
      case 'bookmark_filled':
        return bookmarkFilled;
      case 'star':
        return star;
      case 'star_filled':
        return starFilled;
      case 'channel':
        return channel;
      case 'shorts':
        return shorts;
      case 'logout':
        return logout;
      case 'about':
        return about;
      case 'phone':
        return phone;
      case 'logo':
        return logo;
      case 'community':
        return community;
      case 'comments':
        return comments;
      case 'share':
        return share;
      case 'thumbnail':
        return thumbnail;
    }
    return logo;
  }

  static String path(String name) => '$_dir$name.svg';

  static SvgAsset _i(String file) => SvgAsset('$_dir$file');
}

/// An SVG asset icon that renders tinted red or in any given color.
class SvgAsset {
  final String asset;
  const SvgAsset(this.asset);

  Widget icon({double size = 24, Color color = V.red}) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}
