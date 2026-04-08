import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/seerr_preferences.dart';
import '../../../preference/seerr_row_config.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class SeerrConfigScreen extends StatefulWidget {
  const SeerrConfigScreen({super.key});

  @override
  State<SeerrConfigScreen> createState() => _SeerrConfigScreenState();
}

class _SeerrConfigScreenState extends State<SeerrConfigScreen> {
  late final PluginSyncService _syncService;
  late final SeerrPreferences _seerrPrefs;

  String? _seerrUsername;
  late List<SeerrRowConfig> _rows;

  @override
  void initState() {
    super.initState();
    _syncService = GetIt.instance<PluginSyncService>();
    _seerrPrefs = GetIt.instance<SeerrPreferences>();
    _rows = List.of(_seerrPrefs.rowsConfig);
    _syncService.addListener(_onSyncStateChanged);
    _loadSeerrUsername();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (!mounted) return;
    setState(() {
      _rows = List.of(_seerrPrefs.rowsConfig);
    });
    _loadSeerrUsername();
  }

  void _setSeerrUsername(String? value) {
    if (!mounted || _seerrUsername == value) return;
    setState(() => _seerrUsername = value);
  }

  Future<void> _loadSeerrUsername() async {
    if (!_syncService.pluginAvailable || !_syncService.seerrEnabled) {
      _setSeerrUsername(null);
      return;
    }

    try {
      final repo = await GetIt.instance.getAsync<SeerrRepository>();
      final status = await repo.checkMoonfinStatus();
      _setSeerrUsername(status.authenticated ? status.displayName : null);
    } catch (_) {
      _setSeerrUsername(null);
    }
  }

  Future<void> _pushSync() async {
    if (!_syncService.pluginAvailable) return;
    final client = GetIt.instance<MediaServerClient>();
    await _syncService.pushSettings(client);
  }

  Future<void> _saveRows() async {
    for (var i = 0; i < _rows.length; i++) {
      _rows[i] = _rows[i].copyWith(order: i);
    }
    await _seerrPrefs.setRowsConfig(_rows);
    await _pushSync();
  }

  Future<void> _setBlockNsfw(bool value) async {
    await _seerrPrefs.setBlockNsfw(value);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _resetRows() async {
    setState(() {
      _rows = SeerrRowConfig.defaults();
    });
    await _saveRows();
  }

  String _rowLabel(SeerrRowType type, AppLocalizations l10n) => switch (type) {
    SeerrRowType.recentRequests => l10n.recentRequests,
    SeerrRowType.recentlyAdded => l10n.recentlyAdded,
    SeerrRowType.trending => l10n.trending,
    SeerrRowType.popularMovies => l10n.popularMovies,
    SeerrRowType.movieGenres => l10n.movieGenres,
    SeerrRowType.upcomingMovies => l10n.upcomingMovies,
    SeerrRowType.studios => l10n.studios,
    SeerrRowType.popularSeries => l10n.popularSeries,
    SeerrRowType.seriesGenres => l10n.seriesGenres,
    SeerrRowType.upcomingSeries => l10n.upcomingSeries,
    SeerrRowType.networks => l10n.networks,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEnableSeerr =
        _syncService.pluginAvailable && _syncService.seerrEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.seerr),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: l10n.resetRowsToDefaults,
            onPressed: _resetRows,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        header: Column(
          children: [
            if (canEnableSeerr)
              SwitchPreferenceTile(
                preference: UserPreferences.seerrEnabled,
                title: l10n.enableSeerr,
                subtitle: l10n.showSeerrInNavigation,
                icon: Icons.movie_filter,
                onChanged: () => _pushSync(),
              )
            else
              ListTile(
                leading: const Icon(Icons.movie_filter_outlined),
                title: Text(l10n.enableSeerr),
                subtitle: Text(
                  l10n.seerrUnavailable,
                ),
              ),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_off),
              title: Text(l10n.nsfwFilter),
              subtitle: Text(l10n.hideAdultContent),
              value: _seerrPrefs.blockNsfw,
              onChanged: _setBlockNsfw,
            ),
            if (canEnableSeerr && _seerrUsername != null)
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(l10n.loggedInAs(_seerrUsername!)),
              ),
            ListTile(
              leading: const Icon(Icons.view_carousel_outlined),
              title: Text(l10n.discoverRows),
              subtitle: Text(
                _syncService.pluginAvailable
                    ? l10n.discoverRowsDescriptionPlugin
                    : l10n.discoverRowsDescription,
              ),
            ),
            const Divider(height: 1),
          ],
        ),
        itemCount: _rows.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _rows.removeAt(oldIndex);
            _rows.insert(newIndex, item);
          });
          _saveRows();
        },
        itemBuilder: (context, index) {
          final row = _rows[index];
          return ListTile(
            key: ValueKey(row.type),
            leading: Checkbox(
              value: row.enabled,
              onChanged: (enabled) {
                setState(() {
                  _rows[index] = row.copyWith(enabled: enabled ?? false);
                });
                _saveRows();
              },
            ),
            title: Text(_rowLabel(row.type, l10n)),
            subtitle: Text(row.enabled ? l10n.enabled : l10n.hidden),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          );
        },
      ),
    );
  }
}
