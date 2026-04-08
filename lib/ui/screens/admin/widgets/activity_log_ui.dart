import 'package:flutter/material.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

String activityBucketLabel(DateTime date, AppLocalizations l10n, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(date);

  if (diff.inMinutes < 5) {
    return l10n.adminActivityJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.adminActivityLastHour;
  }

  final local = date.toLocal();
  final today = DateTime(reference.year, reference.month, reference.day);
  final entryDay = DateTime(local.year, local.month, local.day);
  if (!entryDay.isBefore(today)) {
    return l10n.adminActivityToday;
  }
  if (diff.inDays < 2) {
    return l10n.adminActivityYesterday;
  }
  return l10n.adminActivityOlder;
}

List<Object> buildActivityListItems(
  List<ActivityLogEntry> entries,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final items = <Object>[];
  final reference = now ?? DateTime.now();
  String? lastBucket;

  for (final entry in entries) {
    final bucket = activityBucketLabel(entry.date, l10n, now: reference);
    if (bucket != lastBucket) {
      items.add(bucket);
      lastBucket = bucket;
    }
    items.add(entry);
  }

  return items;
}

String activityTimeAgo(DateTime date, AppLocalizations l10n, {bool compact = true}) {
  final diff = DateTime.now().difference(date);
  if (compact) {
    if (diff.inMinutes < 1) return l10n.adminActivityNow;
    if (diff.inMinutes < 60) return l10n.adminActivityMinutesShort(diff.inMinutes);
    if (diff.inHours < 24) return l10n.adminActivityHoursShort(diff.inHours);
    if (diff.inDays < 7) return l10n.adminActivityDaysShort(diff.inDays);
    return l10n.adminActivityDateShort(date.month, date.day);
  }

  if (diff.inDays > 0) return l10n.adminActivityDaysAgo(diff.inDays);
  if (diff.inHours > 0) return l10n.adminActivityHoursAgo(diff.inHours);
  if (diff.inMinutes > 0) return l10n.adminActivityMinutesAgo(diff.inMinutes);
  return l10n.adminActivityJustNow;
}

(Color, Widget) activitySeverityIndicator(String severity, ThemeData theme) {
  switch (severity.toLowerCase()) {
    case 'error':
      return (
        theme.colorScheme.error,
        Icon(Icons.error_outline, size: 15, color: theme.colorScheme.error),
      );
    case 'warning':
    case 'warn':
      return (
        Colors.orange,
        const Icon(Icons.warning_amber, size: 15, color: Colors.orange),
      );
    case 'information':
      return (
        theme.colorScheme.primary,
        Icon(Icons.info_outline, size: 15, color: theme.colorScheme.primary),
      );
    default:
      return (
        theme.colorScheme.outlineVariant,
        Icon(
          Icons.info_outline,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
  }
}