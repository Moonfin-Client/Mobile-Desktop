import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeAndAppearance)),
      body: ListView(
        children: [
          if (!isMobile)
            ListTile(
              leading: const Icon(Icons.border_outer),
              title: Text(l10n.focusBorderColor),
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
            title: l10n.watchedIndicators,
            icon: Icons.visibility,
            labelOf: (v) => switch (v) {
              WatchedIndicatorBehavior.always => l10n.always,
              WatchedIndicatorBehavior.hideUnwatched => l10n.hideUnwatched,
              WatchedIndicatorBehavior.episodesOnly => l10n.episodesOnly,
              WatchedIndicatorBehavior.never => l10n.never,
            },
          ),
          if (!isMobile)
            SwitchPreferenceTile(
              preference: UserPreferences.cardFocusExpansion,
              title: l10n.focusExpansionAnimation,
              subtitle: l10n.scaleFocusedCards,
              icon: Icons.zoom_in,
            ),
          SwitchPreferenceTile(
            preference: UserPreferences.backdropEnabled,
            title: l10n.backgroundBackdrops,
            subtitle: l10n.showBackdropImages,
            icon: Icons.wallpaper,
            onChanged: _pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.seriesThumbnailsEnabled,
            title: l10n.seriesThumbnails,
            subtitle: l10n.seriesThumbnailsDescription,
            icon: Icons.image_aspect_ratio,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.homeRowInfoOverlay,
            title: l10n.homeRowInfoOverlay,
            subtitle: l10n.showTitleMetadataOnHomeRows,
            icon: Icons.info_outline,
          ),
          EnumPreferenceTile<ClockBehavior>(
            preference: UserPreferences.clockBehavior,
            title: l10n.clockDisplay,
            icon: Icons.access_time,
            labelOf: (v) => switch (v) {
              ClockBehavior.always => l10n.always,
              ClockBehavior.inMenus => l10n.inMenus,
              ClockBehavior.inVideo => l10n.inVideo,
              ClockBehavior.never => l10n.never,
            },
          ),
          const Divider(),
          StringPickerPreferenceTile(
            preference: UserPreferences.seasonalSurprise,
            title: l10n.seasonalEffects,
            icon: Icons.celebration,
            options: {
              'none': l10n.none,
              'snow': l10n.snow,
              'fireworks': l10n.fireworks,
              'confetti': l10n.confetti,
              'leaves': l10n.fallingLeaves,
            },
            onChanged: _pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.themeMusicEnabled,
            title: l10n.themeMusic,
            subtitle: l10n.playThemeMusicOnDetailPages,
            icon: Icons.music_note,
            onChanged: _pushSync,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.themeMusicVolume,
            title: l10n.themeMusicVolume,
            icon: Icons.volume_up,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => l10n.percentValue(v),
            onChangeEnd: _pushSync,
          ),
          if (!isMobile)
            SwitchPreferenceTile(
              preference: UserPreferences.themeMusicOnHomeRows,
              title: l10n.themeMusicOnHomeRows,
              subtitle: l10n.playWhenBrowsingHomeScreen,
              icon: Icons.queue_music,
              onChanged: _pushSync,
            ),
          const Divider(),
          SliderPreferenceTile(
            preference: UserPreferences.detailsBackgroundBlurAmount,
            title: l10n.detailsBackgroundBlur,
            icon: Icons.blur_on,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => l10n.pixelValue(v),
            onChangeEnd: _pushSync,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.browsingBackgroundBlurAmount,
            title: l10n.browsingBackgroundBlur,
            icon: Icons.blur_circular,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => l10n.pixelValue(v),
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
