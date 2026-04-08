import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/filesystem_browser.dart';

class AdminNetworkingScreen extends StatefulWidget {
  const AdminNetworkingScreen({super.key});

  @override
  State<AdminNetworkingScreen> createState() => _AdminNetworkingScreenState();
}

class _AdminNetworkingScreenState extends State<AdminNetworkingScreen> {
  late final AdminSystemApi _api;
  Map<String, dynamic>? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _showCertBrowser = false;
  final _listControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<MediaServerClient>().adminSystemApi;
    _load();
  }

  @override
  void dispose() {
    for (final c in _listControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await _api.getNamedConfiguration('network');
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
      await _api.updateNamedConfiguration('network', _config!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminNetworkingSaved),
            duration: Duration(seconds: 5),
          ),
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
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = AppLocalizations.of(context)!;
    if (_error != null || _config == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminNetworkingLoadFailed,
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomSafe + 40),
      children: [
        Text(l10n.adminNetworkingTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.warning_amber,
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.adminNetworkingRestartWarning,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _switchTile('EnableRemoteAccess', l10n.adminNetworkingRemoteAccess),
        const Divider(),
        _sectionHeader(l10n.adminNetworkingPorts),
        _intField('HttpServerPortNumber', l10n.adminNetworkingHttpPort),
        const SizedBox(height: 12),
        _intField('HttpsPortNumber', l10n.adminNetworkingHttpsPort),
        const SizedBox(height: 12),
        _intField('PublicHttpsPort', l10n.adminNetworkingPublicHttpsPort),
        const SizedBox(height: 12),
        _textField('BaseUrl', l10n.adminNetworkingBaseUrl, hint: l10n.adminNetworkingBaseUrlHint),
        const Divider(height: 32),
        _sectionHeader(l10n.adminNetworkingHttps),
        _switchTile('EnableHttps', l10n.adminNetworkingEnableHttps),
        const SizedBox(height: 8),
        _certPathField(),
        const Divider(height: 32),
        _sectionHeader(l10n.adminNetworkingLocalNetwork),
        _listEditor(
          'LocalNetworkAddresses',
          l10n.adminNetworkingLocalAddresses,
          hint: l10n.adminNetworkingAddressHint,
        ),
        const SizedBox(height: 16),
        _listEditor(
          'KnownProxies',
          l10n.adminNetworkingKnownProxies,
          hint: l10n.adminNetworkingProxyHint,
        ),
        const Divider(height: 32),
        _sectionHeader(l10n.adminNetworkingRemoteIpFilter),
        _filterModeSelector(),
        const SizedBox(height: 12),
        _listEditor(
          'RemoteIPFilter',
          l10n.adminNetworkingRemoteIpFilterLabel,
          hint: l10n.adminNetworkingAddressHint,
        ),
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

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:
          Text(text, style: Theme.of(context).textTheme.titleMedium),
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

  Widget _switchTile(String key, String title) {
    return SwitchListTile(
      title: Text(title),
      value: _config![key] as bool? ?? false,
      onChanged: (v) => setState(() => _config![key] = v),
    );
  }

  Widget _certPathField() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey(_config!['CertificatePath']),
                initialValue: _config!['CertificatePath']?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: l10n.adminNetworkingCertPath,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _config!['CertificatePath'] = v,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon:
                  Icon(_showCertBrowser ? Icons.close : Icons.folder_open),
              tooltip: _showCertBrowser ? l10n.adminCloseBrowser : l10n.adminBrowse,
              onPressed: () =>
                  setState(() => _showCertBrowser = !_showCertBrowser),
            ),
          ],
        ),
        if (_showCertBrowser) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: FilesystemBrowser(
              initialPath: _config!['CertificatePath']?.toString(),
              onPathSelected: (path) {
                setState(() {
                  _config!['CertificatePath'] = path;
                  _showCertBrowser = false;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _filterModeSelector() {
    final l10n = AppLocalizations.of(context)!;
    final isBlacklist =
        _config!['IsRemoteIPFilterBlacklist'] as bool? ?? false;
    return Row(
      children: [
        ChoiceChip(
          label: Text(l10n.adminNetworkingWhitelist),
          selected: !isBlacklist,
          onSelected: (v) {
            if (v) {
              setState(
                  () => _config!['IsRemoteIPFilterBlacklist'] = false);
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(l10n.adminNetworkingBlacklist),
          selected: isBlacklist,
          onSelected: (v) {
            if (v) {
              setState(
                  () => _config!['IsRemoteIPFilterBlacklist'] = true);
            }
          },
        ),
      ],
    );
  }

  TextEditingController _controllerFor(String key) {
    return _listControllers.putIfAbsent(key, () => TextEditingController());
  }

  void _addListItem(String key) {
    final controller = _controllerFor(key);
    final v = controller.text.trim();
    if (v.isEmpty) return;
    final items = List<String>.from(
        (_config![key] as List<dynamic>?) ?? <dynamic>[]);
    items.add(v);
    _config![key] = items;
    controller.clear();
    setState(() {});
  }

  Widget _listEditor(String key, String label, {String? hint}) {
    final items = List<String>.from(
        (_config![key] as List<dynamic>?) ?? <dynamic>[]);
    final controller = _controllerFor(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.value,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        items.removeAt(entry.key);
                        _config![key] = items;
                      });
                    },
                  ),
                ],
              ),
            )),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint ?? AppLocalizations.of(context)!.adminNetworkingAddEntry,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addListItem(key),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addListItem(key),
            ),
          ],
        ),
      ],
    );
  }
}
