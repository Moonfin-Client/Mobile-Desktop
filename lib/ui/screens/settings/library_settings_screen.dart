import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../../data/models/aggregated_library.dart';
import '../../../data/repositories/user_views_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/settings/preference_tiles.dart';
import 'settings_app_bar.dart';
import '../../widgets/focus/request_initial_focus.dart';

class LibraryVisibilityScreen extends StatefulWidget {
  const LibraryVisibilityScreen({super.key});

  @override
  State<LibraryVisibilityScreen> createState() =>
      _LibraryVisibilityScreenState();
}

class _LibraryVisibilityScreenState extends State<LibraryVisibilityScreen> {
  final _viewsRepo = GetIt.instance<UserViewsRepository>();

  List<AggregatedLibrary>? _libraries;
  UserConfiguration? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _viewsRepo.getAllViews(),
        _viewsRepo.getUserConfiguration(),
      ]);
      if (!mounted) return;
      setState(() {
        _libraries = results[0] as List<AggregatedLibrary>;
        _config = results[1] as UserConfiguration;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleExclude(String libraryId, bool hidden,
      {required bool isLatest}) async {
    final config = _config;
    if (config == null) return;

    final source =
        isLatest ? config.latestItemsExcludes : config.myMediaExcludes;
    final excludes = List<String>.from(source);
    if (hidden) {
      if (!excludes.contains(libraryId)) excludes.add(libraryId);
    } else {
      excludes.remove(libraryId);
    }

    final updated = isLatest
        ? config.copyWith(latestItemsExcludes: excludes)
        : config.copyWith(myMediaExcludes: excludes);
    setState(() => _config = updated);
    try {
      await _viewsRepo.updateUserConfiguration(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _config = config);
    }
  }

  @override
  Widget build(BuildContext context) =>
      RequestInitialFocus(child: _buildContent(context));

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Library Visibility')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Toggle home page visibility per library. '
              'Restart Moonfin for changes to take effect.',
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_libraries != null && _config != null)
            ..._buildLibraryVisibilityTiles(),
        ],
      ),
    );
  }

  List<Widget> _buildLibraryVisibilityTiles() {
    final l10n = AppLocalizations.of(context);
    final config = _config!;
    final libraries = _libraries!;

    return [
      for (final lib in libraries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(lib.name, style: Theme.of(context).textTheme.titleMedium),
        ),
        TvFocusHighlight(
          builder: (_, focused) => SwitchListTile(
            secondary: Icon(Icons.visibility,
                color: focused ? Colors.black54 : null),
            title: Text(
              l10n.showInNavigation,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: focused ? Colors.black87 : Colors.white,
              ),
            ),
            value: !config.myMediaExcludes.contains(lib.id),
            onChanged: (v) => _toggleExclude(lib.id, !v, isLatest: false),
          ),
        ),
        TvFocusHighlight(
          builder: (_, focused) => SwitchListTile(
            secondary: Icon(Icons.new_releases,
                color: focused ? Colors.black54 : null),
            title: Text(
              l10n.showInLatestMedia,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: focused ? Colors.black87 : Colors.white,
              ),
            ),
            value: !config.latestItemsExcludes.contains(lib.id),
            onChanged: (v) => _toggleExclude(lib.id, !v, isLatest: true),
          ),
        ),
      ],
    ];
  }
}
