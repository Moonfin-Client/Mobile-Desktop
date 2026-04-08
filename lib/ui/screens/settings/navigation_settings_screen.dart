import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class NavigationSettingsScreen extends StatefulWidget {
  const NavigationSettingsScreen({super.key});

  @override
  State<NavigationSettingsScreen> createState() =>
      _NavigationSettingsScreenState();
}

class _NavigationSettingsScreenState extends State<NavigationSettingsScreen> {
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
    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navigation)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.view_sidebar),
            title: Text(l10n.navigationStyle),
            subtitle: Text(
              navbarPosition == NavbarPosition.top
                  ? l10n.topBar
                  : l10n.leftSidebar,
            ),
            onTap: () {
              final newPos = navbarPosition == NavbarPosition.top
                  ? NavbarPosition.left
                  : NavbarPosition.top;
              _prefs.set(UserPreferences.navbarPosition, newPos);
              _pushSync();
              NavigationLayout.positionNotifier.value = newPos;
              setState(() {});
            },
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.showShuffleButton,
            title: l10n.showShuffleButton,
            icon: Icons.shuffle,
            onChanged: _pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showGenresButton,
            title: l10n.showGenresButton,
            icon: Icons.category,
            onChanged: _pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showFavoritesButton,
            title: l10n.showFavoritesButton,
            icon: Icons.favorite,
            onChanged: _pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showLibrariesInToolbar,
            title: l10n.showLibrariesInToolbar,
            iconBuilder: (size, color) => Image.asset(
              'assets/icons/clapperboard.png',
              width: size,
              height: size,
              color: color,
              fit: BoxFit.contain,
            ),
            onChanged: _pushSync,
          ),
          const Divider(),
          SliderPreferenceTile(
            preference: UserPreferences.navbarOpacity,
            title: l10n.navbarOpacity,
            icon: Icons.opacity,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => l10n.percentValue(v),
            onChangeEnd: _pushSync,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.navbarColor,
            title: l10n.navbarColor,
            icon: Icons.color_lens,
            options: {
              'gray': l10n.gray,
              'black': l10n.black,
              'dark_blue': l10n.darkBlue,
              'purple': l10n.purple,
              'teal': l10n.teal,
              'navy': l10n.navy,
              'charcoal': l10n.charcoal,
              'brown': l10n.brown,
              'dark_red': l10n.darkRed,
              'dark_green': l10n.darkGreen,
              'slate': l10n.slate,
              'indigo': l10n.indigo,
            },
            onChanged: _pushSync,
          ),
        ],
      ),
    );
  }
}
