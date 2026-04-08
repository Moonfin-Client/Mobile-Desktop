import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/filesystem_browser.dart';

class AdminGeneralSettingsScreen extends StatefulWidget {
  const AdminGeneralSettingsScreen({super.key});

  @override
  State<AdminGeneralSettingsScreen> createState() =>
      _AdminGeneralSettingsScreenState();
}

class _AdminGeneralSettingsScreenState
    extends State<AdminGeneralSettingsScreen> {
  late final AdminSystemApi _api;
  Map<String, dynamic>? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _browsingField;

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<MediaServerClient>().adminSystemApi;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await _api.getServerConfiguration();
      if (!mounted) return;
      setState(() {
        _config = config;
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

  Future<void> _save() async {
    if (_config == null) return;
    setState(() => _saving = true);
    try {
      await _api.updateServerConfiguration(_config!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminSettingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminSettingsSaveFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = AppLocalizations.of(context)!;
    if (_error != null || _config == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminSettingsLoadFailed,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error ?? l10n.adminUnknownError,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.adminGeneralSettingsTitle,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _textField('ServerName', l10n.adminGeneralServerName),
        const SizedBox(height: 16),
        _textField('PreferredMetadataLanguage', l10n.adminGeneralMetadataLanguage,
            hint: l10n.adminGeneralMetadataLanguageHint),
        const SizedBox(height: 16),
        _textField('MetadataCountryCode', l10n.adminGeneralMetadataCountry,
            hint: l10n.adminGeneralMetadataCountryHint),
        const SizedBox(height: 16),
        _pathField('CachePath', l10n.adminGeneralCachePath),
        const SizedBox(height: 16),
        _pathField('MetadataPath', l10n.adminGeneralMetadataPath),
        const SizedBox(height: 16),
        _intField('LibraryScanFanoutConcurrency', l10n.adminGeneralLibraryScanConcurrency),
        const SizedBox(height: 16),
        _intField(
            'ParallelImageEncodingLimit', l10n.adminGeneralImageEncodingLimit),
        const SizedBox(height: 16),
        _intField('SlowResponseThresholdMs', l10n.adminGeneralSlowResponseThreshold),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ),
      ],
    );
  }

  Widget _textField(String key, String label, {String? hint}) {
    return TextFormField(
      initialValue: _config![key]?.toString() ?? '',
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => _config![key] = v,
    );
  }

  Widget _intField(String key, String label) {
    return TextFormField(
      initialValue: (_config![key] as num?)?.toString() ?? '0',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) => _config![key] = int.tryParse(v) ?? 0,
    );
  }

  Widget _pathField(String key, String label) {
    final isBrowsing = _browsingField == key;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(_config![key]),
                initialValue: _config![key]?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _config![key] = v,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(isBrowsing ? Icons.close : Icons.folder_open),
              tooltip: isBrowsing ? AppLocalizations.of(context)!.adminCloseBrowser : AppLocalizations.of(context)!.adminBrowse,
              onPressed: () => setState(() {
                _browsingField = isBrowsing ? null : key;
              }),
            ),
          ],
        ),
        if (isBrowsing) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: FilesystemBrowser(
              initialPath: _config![key]?.toString(),
              onPathSelected: (path) {
                setState(() {
                  _config![key] = path;
                  _browsingField = null;
                });
              },
            ),
          ),
        ],
      ],
    );
  }
}
