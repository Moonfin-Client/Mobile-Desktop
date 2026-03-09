import 'package:flutter/material.dart';

import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

class LibrarySettingsScreen extends StatelessWidget {
  const LibrarySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library Display')),
      body: ListView(
        children: [
          EnumPreferenceTile<PosterSize>(
            preference: UserPreferences.posterSize,
            title: 'Poster Size',
            icon: Icons.photo_size_select_large,
            labelOf: (v) => switch (v) {
              PosterSize.small => 'Small',
              PosterSize.medium => 'Medium',
              PosterSize.large => 'Large',
              PosterSize.extraLarge => 'Extra Large',
            },
          ),
          EnumPreferenceTile<ImageType>(
            preference: UserPreferences.homeRowsUniversalImageType,
            title: 'Image Type',
            icon: Icons.image,
            labelOf: (v) => switch (v) {
              ImageType.poster => 'Poster',
              ImageType.thumb => 'Thumbnail',
              ImageType.banner => 'Banner',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.homeRowsUniversalOverride,
            title: 'Override Per-Library Settings',
            subtitle: 'Apply image type to all libraries',
            icon: Icons.layers,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableMultiServerLibraries,
            title: 'Multi-Server Libraries',
            subtitle: 'Show libraries from all connected servers',
            icon: Icons.dns,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableFolderView,
            title: 'Enable Folder View',
            subtitle: 'Show folder browsing option',
            icon: Icons.folder,
          ),
        ],
      ),
    );
  }
}
