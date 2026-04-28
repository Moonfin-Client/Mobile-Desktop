import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/home_screen_sections_service.dart';
import '../../../data/services/plugin_sync_service.dart';
import '../../../preference/home_section_config.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/poster_size_settings_dialog.dart';
import '../../widgets/settings/settings_panel.dart';
import '../../../l10n/app_localizations.dart';
import 'home_rows_image_type_screen.dart';
import 'settings_app_bar.dart';

class HomeSectionsScreen extends StatefulWidget {
  final bool showGeneralOptions;

  const HomeSectionsScreen({
    super.key,
    this.showGeneralOptions = true,
  });

  @override
  State<HomeSectionsScreen> createState() => _HomeSectionsScreenState();
}

class _HomeSectionsScreenState extends State<HomeSectionsScreen> {
  final _prefs = GetIt.instance<UserPreferences>();
  late List<HomeSectionConfig> _sections;
  HomeSectionConfig? _mediaBarConfig;
  final _focusNodes = <FocusNode>[];

  @override
  void initState() {
    super.initState();
    final all = _prefs.homeSectionsConfig;
    _mediaBarConfig = all.where((s) => s.type == HomeSectionType.mediaBar).firstOrNull;
    _sections = all.where((s) => s.type != HomeSectionType.mediaBar).toList();
    _mergeDiscoveredPluginSections();
    _rebuildFocusNodes();
    _refreshPluginSections();
  }

  /// Probes for newly discovered plugin sections in the background and
  /// re-merges the result into the visible list.
  Future<void> _refreshPluginSections() async {
    if (!GetIt.instance.isRegistered<HomeScreenSectionsService>()) return;
    final service = GetIt.instance<HomeScreenSectionsService>();
    await service.refreshAll();
    if (!mounted) return;
    setState(() {
      _mergeDiscoveredPluginSections();
      _rebuildFocusNodes();
    });
  }

  /// Adds plugin-dynamic sections discovered by the Home Screen Sections
  /// plugin into the in-memory list (disabled by default) and prunes stale
  /// entries whose section is no longer reported by the server.
  void _mergeDiscoveredPluginSections() {
    if (!GetIt.instance.isRegistered<HomeScreenSectionsService>()) return;
    final service = GetIt.instance<HomeScreenSectionsService>();
    final discovered = service.availableServers.toList();
    if (discovered.isEmpty) return;

    final existing = <String, HomeSectionConfig>{
      for (final cfg in _sections.where((c) => c.isPluginDynamic))
        cfg.stableId: cfg,
    };

    final freshIds = <String>{};
    var nextOrder = _sections.length;
    for (final cap in discovered) {
      for (final section in cap.sections) {
        final stableId =
            'pluginDynamic:${cap.serverId}:${section.section}:${section.additionalData ?? ''}';
        final cfg = HomeSectionConfig.pluginDynamic(
          serverId: cap.serverId,
          pluginSection: section.section,
          pluginAdditionalData: section.additionalData,
          pluginDisplayText: section.displayText,
          enabled: existing[stableId]?.enabled ?? false,
          order: nextOrder++,
        );
        freshIds.add(cfg.stableId);
        final idx = _sections.indexWhere((s) => s.stableId == cfg.stableId);
        if (idx >= 0) {
          _sections[idx] = _sections[idx].copyWith(
            pluginDisplayText: cfg.pluginDisplayText,
          );
        } else {
          _sections.add(cfg);
        }
      }
    }

    final probedServers = discovered.map((c) => c.serverId).toSet();
    _sections.removeWhere((s) =>
        s.isPluginDynamic &&
        s.serverId != null &&
        probedServers.contains(s.serverId) &&
        !freshIds.contains(s.stableId));
  }

  void _rebuildFocusNodes() {
    for (final n in _focusNodes) {
      n.dispose();
    }
    _focusNodes.clear();
    for (var i = 0; i < _sections.length; i++) {
      _focusNodes.add(FocusNode(debugLabel: 'section_$i'));
    }
  }

  @override
  void dispose() {
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _pushSyncSettings() {
    final syncService = GetIt.instance<PluginSyncService>();
    if (syncService.pluginAvailable) {
      final client = GetIt.instance<MediaServerClient>();
      syncService.pushSettings(client);
    }
  }

  void _setMergeContinueWatchingNextUp(bool value, {bool pushSync = true}) {
    _prefs.set(UserPreferences.mergeContinueWatchingNextUp, value);
    if (pushSync) {
      _pushSyncSettings();
    }
  }

  void _save() {
    for (var i = 0; i < _sections.length; i++) {
      _sections[i] = _sections[i].copyWith(order: i);
    }
    final toSave = [..._sections];
    if (_mediaBarConfig != null) toSave.add(_mediaBarConfig!);
    _prefs.setHomeSectionsConfig(toSave);
    _pushSyncSettings();
  }

  void _moveSection(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _sections.length) return;
    setState(() {
      final item = _sections.removeAt(index);
      _sections.insert(newIndex, item);
      final node = _focusNodes.removeAt(index);
      _focusNodes.insert(newIndex, node);
    });
    _save();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newIndex < _focusNodes.length) {
        _focusNodes[newIndex].requestFocus();
      }
    });
  }

  String _labelFor(HomeSectionConfig cfg, AppLocalizations l10n) {
    if (cfg.isPluginDynamic) {
      return cfg.pluginDisplayText?.isNotEmpty == true
          ? cfg.pluginDisplayText!
          : (cfg.pluginSection ?? l10n.none);
    }
    return _labelForType(cfg.type, l10n);
  }

  String _labelForType(HomeSectionType type, AppLocalizations l10n) => switch (type) {
    HomeSectionType.mediaBar => l10n.mediaBar,
    HomeSectionType.latestMedia => l10n.latestMedia,
    HomeSectionType.recentlyReleased => l10n.recentlyReleased,
    HomeSectionType.libraryTilesSmall => l10n.myMedia,
    HomeSectionType.libraryButtons => l10n.myMediaSmall,
    HomeSectionType.resume => l10n.continueWatching,
    HomeSectionType.resumeAudio => l10n.resumeAudio,
    HomeSectionType.resumeBook => l10n.resumeBooks,
    HomeSectionType.activeRecordings => l10n.activeRecordings,
    HomeSectionType.nextUp => l10n.nextUp,
    HomeSectionType.playlists => l10n.playlists,
    HomeSectionType.liveTv => l10n.liveTV,
    HomeSectionType.none => l10n.none,
  };

  String _posterSizeLabel(PosterSize size, AppLocalizations l10n) => switch (size) {
    PosterSize.small => l10n.small,
    PosterSize.medium => l10n.medium,
    PosterSize.large => l10n.large,
    PosterSize.extraLarge => l10n.extraLarge,
  };

  Future<void> _showPosterSizeDialog() async {
    await showFocusRestoringDialog<void>(
      context: context,
      builder: (_) => PosterSizeSettingsDialog(
        prefs: _prefs,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: buildSettingsAppBar(
        context,
        Text(l10n.homeSections),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: l10n.resetToDefaults,
            onPressed: () {
              setState(() {
                _sections = HomeSectionConfig.defaults();
                _rebuildFocusNodes();
                _setMergeContinueWatchingNextUp(
                  UserPreferences.mergeContinueWatchingNextUp.defaultValue,
                  pushSync: false,
                );
              });
              _save();
            },
          ),
        ],
      ),
      body: PlatformDetection.isTV
          ? _buildTvList(l10n)
          : _buildReorderableList(l10n),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.photo_size_select_large),
          title: Text(l10n.homeRowPosterSize),
          subtitle: Text(_posterSizeLabel(_prefs.get(UserPreferences.posterSize), l10n)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showPosterSizeDialog,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.image),
          title: Text(l10n.perRowImageTypeSelection),
          subtitle: Text(l10n.configureImageTypeForEachRow),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              context.pushSettingsScreen(const HomeRowsImageTypeScreen()),
        ),
        const Divider(),
        SwitchListTile(
          secondary: const Icon(Icons.merge_type),
          title: Text(l10n.mergeContinueWatchingAndNextUp),
          subtitle: Text(l10n.combineBothRows),
          value: _prefs.get(UserPreferences.mergeContinueWatchingNextUp),
          onChanged: (value) {
            _setMergeContinueWatchingNextUp(value);
            setState(() {});
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildReorderableList(AppLocalizations l10n) {
    return ReorderableListView.builder(
      header: widget.showGeneralOptions ? _buildHeader(l10n) : null,
      itemCount: _sections.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _sections.removeAt(oldIndex);
          _sections.insert(newIndex, item);
          final node = _focusNodes.removeAt(oldIndex);
          _focusNodes.insert(newIndex, node);
        });
        _save();
      },
      itemBuilder: (context, index) {
        final section = _sections[index];
        return ListTile(
          key: ValueKey(section.stableId),
          leading: Checkbox(
            value: section.enabled,
            onChanged: (enabled) {
              setState(() {
                _sections[index] = section.copyWith(enabled: enabled ?? false);
              });
              _save();
            },
          ),
          title: Text(_labelFor(section, l10n)),
          subtitle: section.isPluginDynamic
              ? const Text('Home Screen Sections plugin')
              : null,
          onTap: () {
            setState(() {
              _sections[index] = section.copyWith(enabled: !section.enabled);
            });
            _save();
          },
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        );
      },
    );
  }

  Widget _buildTvList(AppLocalizations l10n) {
    return ListView.builder(
      itemCount: _sections.length + (widget.showGeneralOptions ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.showGeneralOptions && index == 0) {
          return _buildHeader(l10n);
        }
        final sectionIndex = index - (widget.showGeneralOptions ? 1 : 0);
        final section = _sections[sectionIndex];
        return _HomeSectionTile(
          key: ValueKey(section.stableId),
          focusNode: _focusNodes[sectionIndex],
          autofocus: sectionIndex == 0,
          label: _labelFor(section, l10n),
          enabled: section.enabled,
          isFirst: sectionIndex == 0,
          isLast: sectionIndex == _sections.length - 1,
          onToggle: (enabled) {
            setState(() {
              _sections[sectionIndex] = section.copyWith(enabled: enabled);
            });
            _save();
          },
          onMoveUp: () => _moveSection(sectionIndex, -1),
          onMoveDown: () => _moveSection(sectionIndex, 1),
        );
      },
    );
  }
}

class _HomeSectionTile extends StatefulWidget {
  final FocusNode focusNode;
  final String label;
  final bool enabled;
  final bool isFirst;
  final bool isLast;
  final bool autofocus;
  final ValueChanged<bool> onToggle;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _HomeSectionTile({
    super.key,
    required this.focusNode,
    required this.label,
    required this.enabled,
    required this.isFirst,
    required this.isLast,
    this.autofocus = false,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<_HomeSectionTile> createState() => _HomeSectionTileState();
}

class _HomeSectionTileState extends State<_HomeSectionTile> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (f) {
        if (_focused != f && mounted) setState(() => _focused = f);
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft && !widget.isFirst) {
          widget.onMoveUp();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight && !widget.isLast) {
          widget.onMoveDown();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onToggle(!widget.enabled);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _focused ? Colors.white : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          leading: Icon(
            widget.enabled ? Icons.check_box : Icons.check_box_outline_blank,
            color: _focused
                ? Colors.black54
                : (widget.enabled ? colorScheme.primary : Colors.white70),
          ),
          title: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _focused ? Colors.black87 : Colors.white,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isFirst)
                Icon(Icons.arrow_left, size: 18,
                    color: _focused ? Colors.black54 : Colors.white70),
              if (!widget.isLast)
                Icon(Icons.arrow_right, size: 18,
                    color: _focused ? Colors.black54 : Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
