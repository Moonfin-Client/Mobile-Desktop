import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/navigation_layout.dart';

class MusicFavoritesScreen extends StatelessWidget {
  final String parentId;

  const MusicFavoritesScreen({super.key, required this.parentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: Center(child: Text(l10n.favoriteTracksPlaceholder)),
      ),
    );
  }
}
