import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/navigation_layout.dart';

class CollectionScreen extends StatelessWidget {
  final String collectionId;

  const CollectionScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: Center(child: Text(AppLocalizations.of(context).collectionPlaceholder)),
      ),
    );
  }
}
