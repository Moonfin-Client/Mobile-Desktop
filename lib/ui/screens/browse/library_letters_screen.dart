import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class LibraryLettersScreen extends StatelessWidget {
  final String libraryId;

  const LibraryLettersScreen({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).browseByLetter)),
      body: Center(child: Text(AppLocalizations.of(context).alphabeticalBrowsePlaceholder)),
    );
  }
}
