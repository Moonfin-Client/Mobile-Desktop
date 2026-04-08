import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class LibrarySuggestionsScreen extends StatelessWidget {
  final String libraryId;

  const LibrarySuggestionsScreen({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).suggestions)),
      body: Center(child: Text(AppLocalizations.of(context).suggestionsPlaceholder)),
    );
  }
}
