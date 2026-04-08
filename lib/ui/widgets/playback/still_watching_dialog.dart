import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../../l10n/app_localizations.dart';

class StillWatchingDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onStop;

  const StillWatchingDialog({
    super.key,
    required this.onContinue,
    required this.onStop,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StillWatchingDialog(
        onContinue: () => Navigator.of(context).pop(true),
        onStop: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.stillWatching,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
      content: Text(
        l10n.stillWatchingContent,
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: onStop,
          child: Text(l10n.stillWatchingStop, style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorScheme.accent,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.stillWatchingContinue),
        ),
      ],
    );
  }
}
