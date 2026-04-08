import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../data/services/socket_handler.dart';
import '../widgets/activity_log_ui.dart';

enum _ActivityFilter { all, user, system }

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final List<ActivityLogEntry> _entries = [];
  final ScrollController _scrollController = ScrollController();
  _ActivityFilter _filter = _ActivityFilter.all;
  DateTimeRange? _dateRange;
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalCount = 0;
  String? _error;
  StreamSubscription<ServerWebSocketMessage>? _socketSubscription;

  static const _pageSize = 30;

  AdminSystemApi get _api => GetIt.instance<MediaServerClient>().adminSystemApi;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _socketSubscription = GetIt.instance<SocketHandler>().events.listen((event) {
      switch (event) {
        case ServerEventMessage(:final type) when type == 'ActivityLogEntry':
          _refresh();
        default:
          break;
      }
    });
    _loadPage();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getActivityLog(
        startIndex: _entries.length,
        limit: _pageSize,
        hasUserId: _filter == _ActivityFilter.all
            ? null
            : _filter == _ActivityFilter.user,
      );
      setState(() {
        _entries.addAll(result.items);
        _totalCount = result.totalRecordCount;
        _hasMore = _entries.length < _totalCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeFilter(_ActivityFilter filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _entries.clear();
      _hasMore = true;
      _totalCount = 0;
    });
    _loadPage();
  }

  Future<void> _refresh() async {
    setState(() {
      _entries.clear();
      _hasMore = true;
      _totalCount = 0;
    });
    await _loadPage();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked == null) {
      return;
    }
    setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._ActivityFilter.values.map(
                (f) => FilterChip(
                  selected: _filter == f,
                  label: Text(_filterLabel(f)),
                  onSelected: (_) => _changeFilter(f),
                ),
              ),
              FilterChip(
                selected: _dateRange != null,
                label: Text(
                  _dateRange == null
                      ? 'Date range'
                      : '${_dateRange!.start.month}/${_dateRange!.start.day} - ${_dateRange!.end.month}/${_dateRange!.end.day}',
                ),
                onSelected: (_) => _pickDateRange(),
              ),
              if (_dateRange != null)
                ActionChip(
                  label: Text(l10n.adminClearDates),
                  onPressed: () => setState(() => _dateRange = null),
                ),
              if (_totalCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${_entries.length} of $_totalCount',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody(theme, l10n)),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    final visibleEntries = _entries.where((entry) {
      if (_dateRange == null) {
        return true;
      }
      final localDate = entry.date.toLocal();
      final rangeStart = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final rangeEnd = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );
      return !localDate.isBefore(rangeStart) && !localDate.isAfter(rangeEnd);
    }).toList();

    if (_entries.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty && _error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminActivityLoadFailed(_error ?? '')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refresh,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (visibleEntries.isEmpty) {
      return Center(child: Text(l10n.adminNoActivityEntries));
    }

    final listItems = buildActivityListItems(visibleEntries, l10n);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: listItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= listItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = listItems[index];
          if (item is String) {
            return _DateHeader(label: item);
          }
          return _ActivityTile(entry: item as ActivityLogEntry);
        },
      ),
    );
  }

  String _filterLabel(_ActivityFilter f) {
    switch (f) {
      case _ActivityFilter.all:
        return 'All';
      case _ActivityFilter.user:
        return 'User Activity';
      case _ActivityFilter.system:
        return 'System Events';
    }
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityLogEntry entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (rail, icon) = activitySeverityIndicator(entry.severity, theme);

    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if ((entry.shortOverview ?? '').trim().isNotEmpty)
                      Text(
                        entry.shortOverview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activityTimeAgo(entry.date, l10n, compact: false),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _SeverityBadge(severity: entry.severity),
                  const Spacer(),
                  Text(
                    _formatDateTime(entry.date),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (entry.overview != null) ...[
                const SizedBox(height: 12),
                Text(entry.overview!),
              ],
              if (entry.shortOverview != null &&
                  entry.shortOverview != entry.overview) ...[
                const SizedBox(height: 8),
                Text(entry.shortOverview!, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Text(
                'Type: ${entry.type}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_p(local.month)}-${_p(local.day)} '
        '${_p(local.hour)}:${_p(local.minute)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _severityStyle(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            severity,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _severityStyle(String severity) {
    switch (severity) {
      case 'Error':
        return (Colors.red, Icons.error_outline);
      case 'Warning':
      case 'Warn':
        return (Colors.orange, Icons.warning_amber);
      case 'Information':
        return (Colors.blue, Icons.info_outline);
      default:
        return (Colors.blueGrey, Icons.info_outline);
    }
  }
}
