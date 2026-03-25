import 'package:flutter/material.dart';
import 'package:server_core/server_core.dart';

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
                Text('Server Actions', style: theme.textTheme.titleMedium),
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
                    label: const Text('Restart Server'),
                    onPressed: () => _confirmAction(
                      context,
                      title: 'Restart Server',
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
                  label: const Text('Shutdown Server'),
                  onPressed: () => _confirmAction(
                    context,
                    title: 'Shutdown Server',
                    message: 'Are you sure you want to shut down the server? You will need to restart it manually.',
                    onConfirm: () async {
                      await client.adminSystemApi.shutdownServer();
                    },
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Libraries'),
                  onPressed: () async {
                    try {
                      await client.adminLibraryApi.refreshLibrary();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Library scan started')),
                        );
                      }
                      onActionComplete();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
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
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PopScope(
        canPop: true,
        child: AlertDialog(
          title: Text('Server reboot in progress'),
          content: Text('Server reboot in progress, please restart Moonfin'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
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
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
