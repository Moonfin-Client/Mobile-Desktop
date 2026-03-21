import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/settings/preference_tiles.dart';

class NavigationSettingsScreen extends StatefulWidget {
  const NavigationSettingsScreen({super.key});

  @override
  State<NavigationSettingsScreen> createState() =>
      _NavigationSettingsScreenState();
}

class _NavigationSettingsScreenState extends State<NavigationSettingsScreen> {
  final _prefs = GetIt.instance<UserPreferences>();

  @override
  Widget build(BuildContext context) {
    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);

    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.view_sidebar),
            title: const Text('Navigation Style'),
            subtitle: Text(
              navbarPosition == NavbarPosition.top
                  ? 'Top Bar'
                  : 'Left Sidebar',
            ),
            onTap: () {
              final newPos = navbarPosition == NavbarPosition.top
                  ? NavbarPosition.left
                  : NavbarPosition.top;
              _prefs.set(UserPreferences.navbarPosition, newPos);
              NavigationLayout.positionNotifier.value = newPos;
              setState(() {});
            },
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.showShuffleButton,
            title: 'Show Shuffle Button',
            icon: Icons.shuffle,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showGenresButton,
            title: 'Show Genres Button',
            icon: Icons.category,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showFavoritesButton,
            title: 'Show Favorites Button',
            icon: Icons.favorite,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showLibrariesInToolbar,
            title: 'Show Libraries in Toolbar',
            iconBuilder: (size, color) => Image.asset(
              'assets/icons/clapperboard.png',
              width: size,
              height: size,
              color: color,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
