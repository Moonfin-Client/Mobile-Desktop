import 'package:flutter/material.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

class ServerActionsCard extends StatelessWidget {
  final MediaServerClient client;
  final bool canSelfRestart;
  final VoidCallback onActionComplete;

  const ServerActionsCard({
    super.key,
    required this.client,
    required this.canSelfRestart,
    required this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_power, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.adminServerActions, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canSelfRestart)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.adminRestartServer),
                    onPressed: () => _confirmAction(
                      context,
                      title: l10n.adminRestartServer,
                      message: 'Are you sure you want to restart the server?',
                      onConfirm: () async {
                        await client.adminSystemApi.restartServer();
                        if (!context.mounted) return;
                        await _showRestartMessage(context);
                      },
                    ),
                  ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.power_settings_new),
                  label: Text(l10n.adminShutdownServer),
                  onPressed: () => _confirmAction(
                    context,
                    title: l10n.adminShutdownServer,
                    message: 'Are you sure you want to shut down the server? You will need to restart it manually.',
                    onConfirm: () async {
                      await client.adminSystemApi.shutdownServer();
                    },
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.adminScanLibraries),
                  onPressed: () async {
                    try {
                      await client.adminLibraryApi.refreshLibrary();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.adminLibraryScanStarted)),
                        );
                      }
                      onActionComplete();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRestartMessage(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PopScope(
        canPop: true,
        child: AlertDialog(
          title: Text(l10n.adminServerRebootInProgress),
          content: Text(l10n.adminServerRebootMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await onConfirm();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
          );
        }
      }
    }
  }
}
