import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

class AdminApiKeysScreen extends StatefulWidget {
  const AdminApiKeysScreen({super.key});

  @override
  State<AdminApiKeysScreen> createState() => _AdminApiKeysScreenState();
}

class _AdminApiKeysScreenState extends State<AdminApiKeysScreen> {
  late final AdminApiKeysApi _api;

  bool _loading = true;
  bool _creating = false;
  String? _error;
  List<Map<String, dynamic>> _keys = const [];

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<MediaServerClient>().adminApiKeysApi;
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getApiKeys();
      if (!mounted) return;
      setState(() {
        _keys = _extractKeyList(data);
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

  List<Map<String, dynamic>> _extractKeyList(Map<String, dynamic> data) {
    final raw = data['Items'] ?? data['items'] ?? data['Keys'] ?? data['keys'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  String _keyToken(Map<String, dynamic> item) {
    return (item['AccessToken'] ?? item['Key'] ?? item['Token'] ?? item['Id'] ?? '').toString();
  }

  String _appName(Map<String, dynamic> item) {
    final value = item['AppName'] ?? item['App'] ?? item['Name'] ?? item['Client'];
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? 'Unknown App' : text;
  }

  String _createdAt(Map<String, dynamic> item) {
    final raw = item['DateCreated'] ?? item['DateLastActivity'];
    if (raw is String && raw.isNotEmpty) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }
    }
    return 'Unknown';
  }

  String _masked(String token) {
    if (token.length <= 8) return token;
    return '${token.substring(0, 4)}****${token.substring(token.length - 4)}';
  }

  Future<void> _promptCreateKey() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final appName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminCreateApiKey),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.adminAppName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    controller.dispose();
    if (appName == null || appName.isEmpty || !mounted) return;

    final before = _keys.map(_keyToken).where((k) => k.isNotEmpty).toSet();

    setState(() => _creating = true);
    try {
      await _api.createApiKey(appName);
      final fresh = await _api.getApiKeys();
      final items = _extractKeyList(fresh);
      if (!mounted) return;
      setState(() {
        _keys = items;
        _creating = false;
      });

      final newKeys = items
          .map(_keyToken)
          .where((k) => k.isNotEmpty && !before.contains(k))
          .toList();

      if (!mounted) return;
      final generated = newKeys.length == 1 ? newKeys.first : null;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.adminApiKeyCreated),
          content: generated == null
              ? Text(l10n.adminApiKeyCreatedNoToken)
              : SelectableText(generated),
          actions: [
            if (generated != null)
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: generated));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.adminKeyCopied)),
                    );
                  }
                },
                child: Text(l10n.copy),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.done),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminApiKeyCreateFailed(e.toString()))),
      );
    }
  }

  Future<void> _revokeKey(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context);
    final token = _keyToken(item);
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminKeyTokenMissing)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminRevokeApiKey),
        content: Text(l10n.adminRevokeKeyConfirm(_appName(item))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.revoke),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.revokeApiKey(token);
      await _loadKeys();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminApiKeyRevoked)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminApiKeyRevokeFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminApiKeysLoadFailed),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadKeys,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'API Keys',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _creating ? null : _promptCreateKey,
                icon: const Icon(Icons.add),
                label: Text(l10n.adminCreateKey),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _keys.isEmpty
              ? Center(child: Text(l10n.adminNoApiKeys))
              : ListView.separated(
                  itemCount: _keys.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _keys[index];
                    final token = _keyToken(item);
                    return ListTile(
                      leading: const Icon(Icons.vpn_key),
                      title: Text(_appName(item)),
                      subtitle: Text('Token: ${_masked(token)}\nCreated: ${_createdAt(item)}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: l10n.revoke,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _revokeKey(item),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
