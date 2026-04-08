import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../util/download_utils.dart';

class AdminBackupsScreen extends StatefulWidget {
  const AdminBackupsScreen({super.key});

  @override
  State<AdminBackupsScreen> createState() => _AdminBackupsScreenState();
}

class _AdminBackupsScreenState extends State<AdminBackupsScreen> {
  bool _loading = true;
  bool _creating = false;
  String? _error;
  List<Map<String, dynamic>> _backups = const [];

  AdminBackupApi get _api => GetIt.instance<MediaServerClient>().adminBackupApi;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 404 || status == 405 || status == 501) {
        return AppLocalizations.of(context).adminBackupsNotAvailable;
      }
    }
    return error.toString();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final backups = await _api.getBackups();
      if (!mounted) return;
      setState(() {
        _backups = backups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _backupPath(Map<String, dynamic> item) {
    final value =
        item['Path'] ?? item['BackupPath'] ?? item['FilePath'] ?? item['Name'];
    return (value ?? '').toString();
  }

  String _backupName(Map<String, dynamic> item) {
    final path = _backupPath(item);
    if (path.isEmpty) return AppLocalizations.of(context).adminUnnamedBackup;
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  int _backupSize(Map<String, dynamic> item) {
    final value = item['Size'] ?? item['FileSize'] ?? item['Length'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  DateTime? _backupDate(Map<String, dynamic> item) {
    final raw =
        item['DateCreated'] ??
        item['Created'] ??
        item['Date'] ??
        item['DateModified'];
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context).adminUnknownDate;
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createBackup() async {
    if (_creating) return;
    setState(() => _creating = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(AppLocalizations.of(context).adminCreatingBackup)),
              ],
            ),
          ),
    );

    try {
      await _api.createBackup();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await _loadBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminBackupCreated)),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).adminBackupCreateFailed(e.toString()))));
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _viewManifest(Map<String, dynamic> backup) async {
    final path = _backupPath(backup);
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminBackupPathMissing)),
      );
      return;
    }

    try {
      final manifest = await _api.getBackupManifest(path);
      if (!mounted) return;
      final pretty = const JsonEncoder.withIndent('  ').convert(manifest);
      await showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context).adminBackupManifest(_backupName(backup))),
              content: SizedBox(
                width: (MediaQuery.sizeOf(ctx).width - 32).clamp(280.0, 640.0),
                child: SingleChildScrollView(
                  child: SelectableText(
                    pretty,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context).close),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).adminManifestLoadFailed(e.toString()))));
    }
  }

  Future<bool> _confirmStep(String message, String confirmLabel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context).adminConfirmRestore),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final path = _backupPath(backup);
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminBackupPathMissing)),
      );
      return;
    }

    final step1 = await _confirmStep(
      AppLocalizations.of(context).adminRestoreWarning1,
      AppLocalizations.of(context).continueAction,
    );
    if (!step1 || !mounted) return;

    final step2 = await _confirmStep(
      AppLocalizations.of(context).adminRestoreWarning2,
      AppLocalizations.of(context).continueAction,
    );
    if (!step2 || !mounted) return;

    final step3 = await _confirmStep(
      AppLocalizations.of(context).adminRestoreWarning3,
      AppLocalizations.of(context).continueAction,
    );
    if (!step3 || !mounted) return;

    final step4 = await _confirmStep(
      AppLocalizations.of(context).adminRestoreConfirmMessage(_backupName(backup)),
      AppLocalizations.of(context).restore,
    );
    if (!step4 || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(AppLocalizations.of(context).adminRestoringBackup)),
              ],
            ),
          ),
    );

    try {
      await _api.restoreBackup(path);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).adminRestoreRequested,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).adminRestoreFailed(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Map<String, dynamic>>.from(_backups)..sort((a, b) {
      final ad = _backupDate(a);
      final bd = _backupDate(b);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).adminBackupsLoadFailed),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadBackups,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).adminBackupsTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _creating ? null : _createBackup,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context).adminCreateBackup),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: AppLocalizations.of(context).refresh,
                onPressed: _loadBackups,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child:
              sorted.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context).adminNoBackups))
                  : ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final backup = sorted[index];
                      final size = _backupSize(backup);
                      final date = _backupDate(backup);
                      return ListTile(
                        leading: const Icon(Icons.backup_outlined),
                        title: Text(_backupName(backup)),
                        subtitle: Text(
                          '${_formatDate(date)} | ${formatBytes(size)}\n${_backupPath(backup)}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'manifest') {
                              _viewManifest(backup);
                            } else if (value == 'restore') {
                              _restoreBackup(backup);
                            }
                          },
                          itemBuilder:
                              (ctx) => [
                                PopupMenuItem(
                                  value: 'manifest',
                                  child: Text(AppLocalizations.of(context).adminViewDetails),
                                ),
                                PopupMenuItem(
                                  value: 'restore',
                                  child: Text(AppLocalizations.of(context).restore),
                                ),
                              ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
