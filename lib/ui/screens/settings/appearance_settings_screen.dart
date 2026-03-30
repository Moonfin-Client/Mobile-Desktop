import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/settings/preference_tiles.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final _prefs = GetIt.instance<UserPreferences>();

  void _pushSync() {
    final syncService = GetIt.instance<PluginSyncService>();
    if (syncService.pluginAvailable) {
      final client = GetIt.instance<MediaServerClient>();
      syncService.pushSettings(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = PlatformDetection.isMobile;
    final focusColor = _prefs.get(UserPreferences.focusColor);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme & Appearance')),
      body: ListView(
        children: [
          if (!isMobile)
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
          if (!isMobile)
            SwitchPreferenceTile(
              preference: UserPreferences.cardFocusExpansion,
              title: 'Focus Expansion Animation',
              subtitle: 'Scale focused or hovered cards and tiles',
              icon: Icons.zoom_in,
            ),
          SwitchPreferenceTile(
            preference: UserPreferences.backdropEnabled,
            title: 'Background Backdrops',
            subtitle: 'Show backdrop images behind content',
            icon: Icons.wallpaper,
            onChanged: _pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.seriesThumbnailsEnabled,
            title: 'Series Thumbnails',
            subtitle: 'Episodes only: use series artwork that matches each row image type',
            icon: Icons.image_aspect_ratio,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.homeRowInfoOverlay,
            title: 'Home Row Info Overlay',
            subtitle: 'Show title and metadata when browsing home rows',
            icon: Icons.info_outline,
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
          const Divider(),
          StringPickerPreferenceTile(
            preference: UserPreferences.seasonalSurprise,
            title: 'Seasonal Effects',
            icon: Icons.celebration,
            options: const {
              'none': 'None',
              'snow': 'Snow',
              'fireworks': 'Fireworks',
              'confetti': 'Confetti',
              'leaves': 'Falling Leaves',
            },
            onChanged: _pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.themeMusicEnabled,
            title: 'Theme Music',
            subtitle: 'Play theme music on detail pages',
            icon: Icons.music_note,
            onChanged: _pushSync,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.themeMusicVolume,
            title: 'Theme Music Volume',
            icon: Icons.volume_up,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
            onChangeEnd: _pushSync,
          ),
          if (!isMobile)
            SwitchPreferenceTile(
              preference: UserPreferences.themeMusicOnHomeRows,
              title: 'Theme Music on Home Rows',
              subtitle: 'Play when browsing home screen',
              icon: Icons.queue_music,
              onChanged: _pushSync,
            ),
          const Divider(),
          SliderPreferenceTile(
            preference: UserPreferences.detailsBackgroundBlurAmount,
            title: 'Details Background Blur',
            icon: Icons.blur_on,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '${v}px',
            onChangeEnd: _pushSync,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.browsingBackgroundBlurAmount,
            title: 'Browsing Background Blur',
            icon: Icons.blur_circular,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '${v}px',
            onChangeEnd: _pushSync,
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
        children: AppTheme.values.map((theme) {
          return ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(theme.colorValue),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            title: Text(_formatThemeName(theme.name)),
            onTap: () async {
              await _prefs.set(UserPreferences.focusColor, theme);
              if (!mounted) return;
              setState(() {});
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  String _formatThemeName(String camelCase) {
    final buf = StringBuffer();
    for (int i = 0; i < camelCase.length; i++) {
      final c = camelCase[i];
      if (i == 0) {
        buf.write(c.toUpperCase());
      } else if (c == c.toUpperCase() && c != c.toLowerCase()) {
        buf.write(' ');
        buf.write(c);
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }
}
