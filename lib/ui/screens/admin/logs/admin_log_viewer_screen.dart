import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

class AdminLogViewerScreen extends StatefulWidget {
  final String fileName;

  const AdminLogViewerScreen({
    super.key,
    required this.fileName,
  });

  @override
  State<AdminLogViewerScreen> createState() => _AdminLogViewerScreenState();
}

class _AdminLogViewerScreenState extends State<AdminLogViewerScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _content = '';
  String _query = '';
  String? _levelFilter;

  AdminSystemApi get _api => GetIt.instance<MediaServerClient>().adminSystemApi;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLog() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final text = await _api.getLogFileContent(widget.fileName);
      if (!mounted) return;
      setState(() {
        _content = text;
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

  List<String> get _lines {
    final all = _content.replaceAll('\r\n', '\n').split('\n');
    final q = _query.trim().toLowerCase();
    return all.where((line) {
      if (q.isNotEmpty && !line.toLowerCase().contains(q)) return false;
      if (_levelFilter != null &&
          !line.toUpperCase().contains('[$_levelFilter]')) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).adminLogCopied)),
    );
  }

  Future<void> _saveToFile() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: AppLocalizations.of(context).adminSaveLogFile,
      fileName: widget.fileName,
    );
    if (path == null) return;

    try {
      await File(path).writeAsString(_content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminSavedTo(path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminSaveFailed(e.toString()))),
      );
    }
  }

  Color _lineColor(ThemeData theme, String line) {
    final upper = line.toUpperCase();
    if (upper.contains('[ERR]')) return Colors.red;
    if (upper.contains('[WRN]')) return Colors.orange;
    if (upper.contains('[INF]')) return Colors.green;
    if (upper.contains('[DBG]')) return Colors.grey;
    return theme.colorScheme.onSurface;
  }

  TextSpan _buildLineSpan({
    required String line,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
  }) {
    final q = _query.trim();
    if (q.isEmpty) {
      return TextSpan(text: line, style: baseStyle);
    }

    final lowerLine = line.toLowerCase();
    final lowerQuery = q.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerLine.indexOf(lowerQuery, start);
      if (index < 0) {
        if (start < line.length) {
          spans.add(TextSpan(text: line.substring(start), style: baseStyle));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: line.substring(start, index), style: baseStyle));
      }

      final end = index + lowerQuery.length;
      spans.add(TextSpan(text: line.substring(index, end), style: highlightStyle));
      start = end;
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).adminLogViewerLoadFailed(widget.fileName)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadLog,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      );
    }

    final lines = _lines;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.fileName,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).copy,
                onPressed: _copyAll,
                icon: const Icon(Icons.copy_all),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).save,
                onPressed: _saveToFile,
                icon: const Icon(Icons.download),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).refresh,
                onPressed: _loadLog,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: AppLocalizations.of(context).adminSearchInLog,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final (label, filter) in <(String, String?)>[
                ('All', null),
                ('ERR', 'ERR'),
                ('WRN', 'WRN'),
                ('INF', 'INF'),
                ('DBG', 'DBG'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(label),
                    selected: _levelFilter == filter,
                    onSelected: (_) => setState(() => _levelFilter = filter),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (_query.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      AppLocalizations.of(context).adminLogViewerMatches(lines.length),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: lines.isEmpty
              ? Center(child: Text(AppLocalizations.of(context).adminLogViewerNoMatches))
              : ListView.builder(
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final color = _lineColor(theme, line);
                    final base = TextStyle(
                      color: color,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.35,
                    );
                    final highlight = base.copyWith(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      fontWeight: FontWeight.w700,
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${index + 1}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outlineVariant,
                                fontFamily: 'monospace',
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText.rich(
                              _buildLineSpan(
                                line: line,
                                baseStyle: base,
                                highlightStyle: highlight,
                              ),
                            ),
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
