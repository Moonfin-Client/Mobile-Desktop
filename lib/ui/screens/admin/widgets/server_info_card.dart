import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ServerInfoCard extends StatelessWidget {
  final Map<String, dynamic> systemInfo;

  const ServerInfoCard({super.key, required this.systemInfo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final os = _value(
      systemInfo,
      const ['OperatingSystemDisplayName', 'OperatingSystem'],
      fallback: 'Unknown',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.adminServerInfo, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _row('Name', systemInfo['ServerName'] as String? ?? ''),
            _row('Version', systemInfo['Version'] as String? ?? ''),
            _row('OS', os),
            if (systemInfo['HasPendingRestart'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  avatar: Icon(Icons.warning, size: 16, color: theme.colorScheme.error),
                  label: Text(l10n.adminRestartPending),
                  backgroundColor: theme.colorScheme.errorContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _value(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final raw = source[key];
      final text = (raw ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
