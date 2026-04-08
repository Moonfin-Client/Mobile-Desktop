import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../widgets/filesystem_browser.dart';
import '../../../../l10n/app_localizations.dart';

class AdminPlaybackSettingsScreen extends StatefulWidget {
  const AdminPlaybackSettingsScreen({super.key});

  @override
  State<AdminPlaybackSettingsScreen> createState() =>
      _AdminPlaybackSettingsScreenState();
}

class _AdminPlaybackSettingsScreenState
    extends State<AdminPlaybackSettingsScreen> {
  late final AdminSystemApi _api;
  Map<String, dynamic>? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _browsingField;

  static const _hwAccelOptions = [
    ('none', 'None'),
    ('vaapi', 'VA-API'),
    ('qsv', 'Intel Quick Sync'),
    ('nvenc', 'NVIDIA NVENC'),
    ('v4l2m2m', 'V4L2'),
    ('rkmpp', 'Rockchip MPP'),
    ('videotoolbox', 'VideoToolbox'),
  ];

  static const _hwDecodeCodecs = [
    ('h264', 'H.264'),
    ('hevc', 'HEVC'),
    ('mpeg2video', 'MPEG-2'),
    ('vc1', 'VC-1'),
    ('vp8', 'VP8'),
    ('vp9', 'VP9'),
    ('av1', 'AV1'),
  ];

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
      final config = await _api.getNamedConfiguration('encoding');
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
      await _api.updateNamedConfiguration('encoding', _config!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adminPlaybackSaved)),
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

  List<String> _getHardwareDecodingCodecs() {
    final raw = _config!['HardwareDecodingCodecs'];
    if (raw is List) return List<String>.from(raw);
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _config == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminPlaybackLoadFailed,
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

    final currentAccel =
        _config!['HardwareAccelerationType']?.toString() ?? 'none';

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomSafe + 40),
      children: [
        Text(l10n.adminPlaybackTranscoding,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _sectionHeader(l10n.adminPlaybackHwAccel),
        DropdownButtonFormField<String>(
          value: _hwAccelOptions.any((o) => o.$1 == currentAccel)
              ? currentAccel
              : 'none',
          decoration: InputDecoration(
            labelText: l10n.adminPlaybackHwAccelLabel,
            border: const OutlineInputBorder(),
          ),
          items: _hwAccelOptions
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$1 == 'none' ? l10n.none : o.$2)))
              .toList(),
          onChanged: (v) =>
              setState(() => _config!['HardwareAccelerationType'] = v),
        ),
        if (currentAccel == 'vaapi') ...[
          const SizedBox(height: 12),
          _textField('VaapiDevice', l10n.adminPlaybackVaapiDevice,
              hint: '/dev/dri/renderD128'),
        ],
        const SizedBox(height: 16),
        _switchTile('EnableHardwareEncoding', l10n.adminPlaybackEnableHwEncoding),
        const SizedBox(height: 8),
        Text(l10n.adminPlaybackEnableHwDecoding,
            style: Theme.of(context).textTheme.titleSmall),
        ..._buildCodecToggles(),
        const Divider(height: 32),
        _sectionHeader(l10n.adminPlaybackEncoding),
        _intField('EncodingThreadCount', l10n.adminPlaybackEncodingThreads,
            subtitle: l10n.adminPlaybackAutomatic),
        const SizedBox(height: 12),
        _pathField('TranscodingTempPath', l10n.adminPlaybackTranscodeTempPath),
        const SizedBox(height: 12),
        _switchTile('EnableFallbackFont', l10n.adminPlaybackFallbackFont),
        if (_config!['EnableFallbackFont'] == true) ...[
          const SizedBox(height: 8),
          _pathField('FallbackFontPath', l10n.adminPlaybackFallbackFontPath),
        ],
        const Divider(height: 32),
        _sectionHeader(l10n.adminPlaybackStreaming),
        _switchTile(
            'EnableSegmentDeletion', l10n.adminPlaybackSegmentDeletion),
        const SizedBox(height: 8),
        _intField('SegmentKeepSeconds', l10n.adminPlaybackSegmentKeep),
        const SizedBox(height: 12),
        _switchTile('EnableThrottling', l10n.adminPlaybackThrottleBuffering),
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

  List<Widget> _buildCodecToggles() {
    final enabled = _getHardwareDecodingCodecs();
    return _hwDecodeCodecs.map((codec) {
      return SwitchListTile(
        title: Text(codec.$2),
        dense: true,
        value: enabled.contains(codec.$1),
        onChanged: (v) {
          setState(() {
            final codecs = _getHardwareDecodingCodecs();
            if (v) {
              codecs.add(codec.$1);
            } else {
              codecs.remove(codec.$1);
            }
            _config!['HardwareDecodingCodecs'] = codecs;
          });
        },
      );
    }).toList();
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
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

  Widget _intField(String key, String label, {String? subtitle}) {
    return TextFormField(
      initialValue: (_config![key] as num?)?.toString() ?? '0',
      decoration: InputDecoration(
        labelText: label,
        helperText: subtitle,
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

  Widget _pathField(String key, String label) {
    final l10n = AppLocalizations.of(context)!;
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
              tooltip: isBrowsing ? l10n.adminCloseBrowser : l10n.adminBrowse,
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
