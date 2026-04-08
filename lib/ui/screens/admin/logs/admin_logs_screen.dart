import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../util/download_utils.dart';
import '../../../navigation/destinations.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  bool _loading = true;
  String? _error;
  bool _newestFirst = true;
  List<LogFileInfo> _logs = const [];

  AdminSystemApi get _api => GetIt.instance<MediaServerClient>().adminSystemApi;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final files = await _api.getLogFiles();
      if (!mounted) return;
      setState(() {
        _logs = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<LogFileInfo> get _sortedLogs {
    final copy = List<LogFileInfo>.from(_logs);
    copy.sort((a, b) {
      final result = a.dateModified.compareTo(b.dateModified);
      return _newestFirst ? -result : result;
    });
    return copy;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _relativeDate(DateTime date) {
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return AppLocalizations.of(context).adminLogsJustNow;
    if (diff.inMinutes < 60) return AppLocalizations.of(context).adminLogsMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return AppLocalizations.of(context).adminLogsHoursAgo(diff.inHours);
    if (diff.inDays < 7) return AppLocalizations.of(context).adminLogsDaysAgo(diff.inDays);
    return _formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final logs = _sortedLogs;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).adminLogsLoadFailed),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadLogs,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (logs.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).adminNoLogFiles));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).adminLogsTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: _newestFirst ? AppLocalizations.of(context).adminLogsNewestFirst : AppLocalizations.of(context).adminLogsOldestFirst,
                onPressed: () {
                  setState(() {
                    _newestFirst = !_newestFirst;
                  });
                },
                icon: Icon(
                  _newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).refresh,
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = logs[index];
              final isActive = index == 0 && _newestFirst;
              final theme = Theme.of(context);
              return ListTile(
                leading: Icon(
                  isActive
                      ? Icons.description
                      : Icons.description_outlined,
                  color: isActive ? theme.colorScheme.primary : null,
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(item.name)),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${formatBytes(item.size)} \u00b7 ${_relativeDate(item.dateModified)}',
                ),
                onTap: () =>
                    context.push(Destinations.adminLogFile(item.name)),
              );
            },
          ),
        ),
      ],
    );
  }
}
