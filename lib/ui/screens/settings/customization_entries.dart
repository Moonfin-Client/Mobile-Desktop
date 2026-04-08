import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../navigation/destinations.dart';

class CustomizationEntryDescriptor {
  final IconData icon;
  final String title;
  final String subtitle;
  final String destination;

  const CustomizationEntryDescriptor({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.destination,
  });
}

List<CustomizationEntryDescriptor> buildCustomizationEntries({
  required bool isMobile,
  required AppLocalizations l10n,
}) => <CustomizationEntryDescriptor>[
  CustomizationEntryDescriptor(
    icon: Icons.palette,
    title: l10n.themeAndAppearance,
    subtitle: isMobile
        ? l10n.watchedIndicatorsBackdrops
        : l10n.focusColorWatchedIndicatorsBackdrops,
    destination: Destinations.settingsAppearance,
  ),
  CustomizationEntryDescriptor(
    icon: Icons.view_sidebar,
    title: l10n.navigation,
    subtitle: l10n.navbarStyleToolbarAppearance,
    destination: Destinations.settingsNavigation,
  ),
  CustomizationEntryDescriptor(
    icon: Icons.home,
    title: l10n.homeSections,
    subtitle: l10n.reorderToggleHomeRows,
    destination: Destinations.settingsHomeSections,
  ),
  CustomizationEntryDescriptor(
    icon: Icons.featured_play_list,
    title: l10n.mediaBar,
    subtitle: l10n.featuredContentAppearance,
    destination: Destinations.settingsMediaBar,
  ),
  CustomizationEntryDescriptor(
    icon: Icons.photo_library,
    title: l10n.libraryDisplay,
    subtitle: l10n.posterSizeImageTypeFolderView,
    destination: Destinations.settingsLibrary,
  ),
  CustomizationEntryDescriptor(
    icon: Icons.star,
    title: l10n.ratings,
    subtitle: l10n.mdbListTmdbRatingSources,
    destination: Destinations.settingsRatings,
  ),
];
