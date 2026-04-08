import 'package:flutter/material.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import 'activity_log_ui.dart';

class ActivityLogCard extends StatelessWidget {
  final ActivityLogResult activityLog;

  const ActivityLogCard({super.key, required this.activityLog});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = activityLog.items;
    final errorCount =
        items.where((e) => e.severity.toLowerCase() == 'error').length;
    final warnCount = items.where((e) {
      final s = e.severity.toLowerCase();
      return s == 'warning' || s == 'warn';
    }).length;
    final listItems = buildActivityListItems(items, l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.adminRecentActivity, style: theme.textTheme.titleMedium),
                const Spacer(),
                if (errorCount > 0) ...[
                  Icon(Icons.error_outline,
                      size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 3),
                  Text(
                    '$errorCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (warnCount > 0) ...[
                  const Icon(Icons.warning_amber,
                      size: 14, color: Colors.orange),
                  const SizedBox(width: 3),
                  Text(
                    '$warnCount',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(l10n.adminNoRecentActivity)),
              )
            else
              for (final item in listItems)
                if (item is String)
                  _groupHeader(item, theme)
                else
                  _entryRow(item as ActivityLogEntry, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _entryRow(ActivityLogEntry entry, ThemeData theme, AppLocalizations l10n) {
    final (rail, icon) = activitySeverityIndicator(entry.severity, theme);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: rail,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            icon,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if ((entry.shortOverview ?? '').trim().isNotEmpty)
                    Text(
                      entry.shortOverview!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              activityTimeAgo(entry.date, l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
