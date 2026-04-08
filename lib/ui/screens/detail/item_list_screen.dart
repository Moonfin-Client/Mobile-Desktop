import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ItemListScreen extends StatelessWidget {
  final String itemId;

  const ItemListScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trackList)),
      body: Center(child: Text(l10n.itemListPlaceholder)),
    );
  }
}
