import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/settings/preference_tiles.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final _prefs = GetIt.instance<UserPreferences>();

  @override
  Widget build(BuildContext context) {
    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
    final focusColor = _prefs.get(UserPreferences.focusColor);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme & Appearance')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.view_sidebar),
            title: const Text('Navigation Style'),
            subtitle: Text(navbarPosition == NavbarPosition.top ? 'Top Bar' : 'Left Sidebar'),
            onTap: () {
              final newPos = navbarPosition == NavbarPosition.top
                  ? NavbarPosition.left
                  : NavbarPosition.top;
              _prefs.set(UserPreferences.navbarPosition, newPos);
              NavigationLayout.positionNotifier.value = newPos;
              setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.border_outer),
            title: const Text('Focus Border Color'),
            subtitle: Text(focusColor.name),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(focusColor.colorValue),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            onTap: () => _showFocusColorPicker(context),
          ),
          EnumPreferenceTile<WatchedIndicatorBehavior>(
            preference: UserPreferences.watchedIndicatorBehavior,
            title: 'Watched Indicators',
            icon: Icons.visibility,
            labelOf: (v) => switch (v) {
              WatchedIndicatorBehavior.always => 'Always',
              WatchedIndicatorBehavior.hideUnwatched => 'Hide Unwatched',
              WatchedIndicatorBehavior.episodesOnly => 'Episodes Only',
              WatchedIndicatorBehavior.never => 'Never',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.cardFocusExpansion,
            title: 'Card Focus Expansion',
            subtitle: 'Scale cards when focused',
            icon: Icons.zoom_in,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.backdropEnabled,
            title: 'Background Backdrops',
            subtitle: 'Show backdrop images behind content',
            icon: Icons.wallpaper,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.seriesThumbnailsEnabled,
            title: 'Series Thumbnails',
            subtitle: 'Use landscape thumbnails for series',
            icon: Icons.image_aspect_ratio,
          ),
          EnumPreferenceTile<ClockBehavior>(
            preference: UserPreferences.clockBehavior,
            title: 'Clock Display',
            icon: Icons.access_time,
            labelOf: (v) => switch (v) {
              ClockBehavior.always => 'Always',
              ClockBehavior.inMenus => 'In Menus',
              ClockBehavior.inVideo => 'In Video',
              ClockBehavior.never => 'Never',
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.detailsBackgroundBlurAmount,
            title: 'Details Background Blur',
            icon: Icons.blur_on,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '${v}px',
          ),
          SliderPreferenceTile(
            preference: UserPreferences.browsingBackgroundBlurAmount,
            title: 'Browsing Background Blur',
            icon: Icons.blur_circular,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '${v}px',
          ),
        ],
      ),
    );
  }

  void _showFocusColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Focus Border Color'),
        children: AppColorScheme.focusBorderPresets.entries.map((e) {
          return ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: e.value,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            title: Text(e.key),
            onTap: () {
              final match = AppTheme.values.where(
                (t) => t.colorValue == e.value.value,
              );
              if (match.isNotEmpty) {
                _prefs.set(UserPreferences.focusColor, match.first);
                setState(() {});
              }
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}
