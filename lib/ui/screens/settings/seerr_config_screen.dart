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

class SeerrConfigScreen extends StatefulWidget {
  const SeerrConfigScreen({super.key});

  @override
  State<SeerrConfigScreen> createState() => _SeerrConfigScreenState();
}

class _SeerrConfigScreenState extends State<SeerrConfigScreen> {
  late final PluginSyncService _syncService;
  late final UserPreferences _prefs;
  late final SeerrPreferences _seerrPrefs;

  String? _seerrUsername;
  late List<SeerrRowConfig> _rows;

  @override
  void initState() {
    super.initState();
    _syncService = GetIt.instance<PluginSyncService>();
    _prefs = GetIt.instance<UserPreferences>();
    _seerrPrefs = GetIt.instance<SeerrPreferences>();
    _rows = _seerrPrefs.rowsConfig;
    _syncService.addListener(_onSyncStateChanged);
    _ensureSeerrDisabledIfUnavailable();
    _loadSeerrUsername();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (!mounted) return;
    _ensureSeerrDisabledIfUnavailable();
    setState(() {
      _rows = _seerrPrefs.rowsConfig;
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

  void _ensureSeerrDisabledIfUnavailable() {
    if (!_syncService.pluginAvailable || !_syncService.seerrEnabled) {
      if (_prefs.get(UserPreferences.seerrEnabled)) {
        _prefs.set(UserPreferences.seerrEnabled, false);
      }
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

  String _rowLabel(SeerrRowType type) => switch (type) {
    SeerrRowType.recentRequests => 'Recent Requests',
    SeerrRowType.recentlyAdded => 'Recently Added',
    SeerrRowType.trending => 'Trending',
    SeerrRowType.popularMovies => 'Popular Movies',
    SeerrRowType.movieGenres => 'Movie Genres',
    SeerrRowType.upcomingMovies => 'Upcoming Movies',
    SeerrRowType.studios => 'Studios',
    SeerrRowType.popularSeries => 'Popular Series',
    SeerrRowType.seriesGenres => 'Series Genres',
    SeerrRowType.upcomingSeries => 'Upcoming Series',
    SeerrRowType.networks => 'Networks',
  };

  @override
  Widget build(BuildContext context) {
    final canEnableSeerr =
        _syncService.pluginAvailable && _syncService.seerrEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seerr'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset rows to defaults',
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
                title: 'Enable Seerr',
                subtitle: 'Show Seerr in navigation (requires server plugin)',
                icon: Icons.movie_filter,
                onChanged: () => _pushSync(),
              )
            else
              const ListTile(
                leading: Icon(Icons.movie_filter_outlined),
                title: Text('Enable Seerr'),
                subtitle: Text(
                  'Unavailable because server plugin Seerr support is disabled.',
                ),
              ),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_off),
              title: const Text('NSFW Filter'),
              subtitle: const Text('Hide adult content in results'),
              value: _seerrPrefs.blockNsfw,
              onChanged: _setBlockNsfw,
            ),
            if (canEnableSeerr && _seerrUsername != null)
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text('Logged in as: $_seerrUsername'),
              ),
            ListTile(
              leading: const Icon(Icons.view_carousel_outlined),
              title: const Text('Discover Rows'),
              subtitle: Text(
                _syncService.pluginAvailable
                    ? 'Drag to reorder. Enable or disable rows. Enabled row order syncs with the Moonfin plugin.'
                    : 'Drag to reorder. Enable or disable rows.',
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
            title: Text(_rowLabel(row.type)),
            subtitle: Text(row.enabled ? 'Enabled' : 'Hidden'),
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
