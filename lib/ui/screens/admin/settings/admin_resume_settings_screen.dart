import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

class AdminResumeSettingsScreen extends StatefulWidget {
  const AdminResumeSettingsScreen({super.key});

  @override
  State<AdminResumeSettingsScreen> createState() =>
      _AdminResumeSettingsScreenState();
}

class _AdminResumeSettingsScreenState extends State<AdminResumeSettingsScreen> {
  late final AdminSystemApi _api;
  Map<String, dynamic>? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminResumeSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminSettingsSaveFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _intVal(String key, [int fallback = 0]) =>
      (_config![key] as num?)?.toInt() ?? fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _config == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminResumeLoadFailed,
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
        Text(l10n.adminDrawerResume, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l10n.adminResumeDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _sectionHeader(l10n.adminResumeVideo),
        _sliderField(
          'MinResumePct',
          l10n.adminMinResumePercentage,
          min: 0,
          max: 100,
          subtitle: l10n.adminMinResumeSubtitle,
        ),
        const SizedBox(height: 16),
        _sliderField(
          'MaxResumePct',
          l10n.adminMaxResumePercentage,
          min: 1,
          max: 100,
          subtitle: l10n.adminMaxResumeSubtitle,
        ),
        const SizedBox(height: 16),
        _intField(
          'MinResumeDurationSeconds',
          l10n.adminMinResumeDuration,
          subtitle: l10n.adminMinResumeDurationSubtitle,
        ),
        const Divider(height: 32),
        _sectionHeader(l10n.adminResumeAudiobooks),
        _sliderField(
          'MinAudiobookResume',
          l10n.adminResumeMinAudiobookPct,
          min: 0,
          max: 100,
        ),
        const SizedBox(height: 16),
        _sliderField(
          'MaxAudiobookResume',
          l10n.adminResumeMaxAudiobookPct,
          min: 1,
          max: 100,
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
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _sliderField(
    String key,
    String label, {
    required double min,
    required double max,
    String? subtitle,
  }) {
    final value = _intVal(key).clamp(min.toInt(), max.toInt()).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        if (subtitle != null)
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: '${value.toInt()}%',
                onChanged: (v) =>
                    setState(() => _config![key] = v.toInt()),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('${value.toInt()}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ],
    );
  }

  Widget _intField(String key, String label, {String? subtitle}) {
    return TextFormField(
      initialValue: _intVal(key).toString(),
      decoration: InputDecoration(
        labelText: label,
        helperText: subtitle,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) => _config![key] = int.tryParse(v) ?? 0,
    );
  }
}
