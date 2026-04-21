import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../di/providers.dart';
import '../../../util/platform_detection.dart';

import '../../../auth/store/authentication_preferences.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../widgets/settings/settings_panel.dart';
import 'about_screen.dart';
import 'home_rows_image_type_screen.dart';
import 'home_sections_screen.dart';
import 'library_settings_screen.dart';
import 'media_bar_settings_screen.dart';
import 'navigation_settings_screen.dart';
import 'parental_settings_screen.dart';
import 'pin_code_settings_screen.dart';
import 'playback_settings_screen.dart';
import 'plugin_settings_screen.dart';
import 'screensaver_settings_screen.dart';
import 'seerr_config_screen.dart';
import 'settings_app_bar.dart';
import 'subtitle_settings_screen.dart';
import '../syncplay/syncplay_screen.dart';

class SettingsSidePanel extends ConsumerStatefulWidget {
  const SettingsSidePanel({super.key});

  @override
  ConsumerState<SettingsSidePanel> createState() => _SettingsSidePanelState();
}

class _SettingsSidePanelState extends ConsumerState<SettingsSidePanel> {
  final _firstFocusNode = FocusNode(debugLabel: 'TvSettingsPanelFirstItem');

  void _requestInitialFocus({int attempt = 0}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focusScope = FocusScope.of(context);
      if (_firstFocusNode.context == null && attempt < 10) {
        Future<void>.delayed(const Duration(milliseconds: 16), () {
          _requestInitialFocus(attempt: attempt + 1);
        });
        return;
      }
      _firstFocusNode.requestFocus();
      focusScope.requestFocus(_firstFocusNode);
    });
  }

  @override
  void initState() {
    super.initState();
    _requestInitialFocus();
  }

  @override
  void dispose() {
    _firstFocusNode.dispose();
    super.dispose();
  }

  bool _isActiveServerJellyfin() {
    try {
      final factory = GetIt.instance<MediaServerClientFactory>();
      return factory.getActiveClient().serverType == ServerType.jellyfin;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJellyfinActive = _isActiveServerJellyfin();
    final showAdmin = !PlatformDetection.isTV && ref.watch(isAdminProvider);
    final entries = <_PanelEntry>[
      _PanelEntry(
        icon: Icons.people,
        title: 'Authentication',
        subtitle: 'Manage servers & users',
        focusNode: _firstFocusNode,
        onTap: () =>
            context.pushSettingsScreen(const _AuthenticationCategoryScreen()),
      ),
      if (showAdmin)
        _PanelEntry(
          icon: Icons.admin_panel_settings,
          title: 'Administration',
          subtitle: 'Server settings, users, libraries',
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            GoRouter.of(context).push(Destinations.admin);
          },
        ),
      _PanelEntry(
        icon: Icons.brush,
        title: 'Customization',
        subtitle: 'Theme, clock, watched indicators',
        onTap: () =>
            context.pushSettingsScreen(const _CustomizationCategoryScreen()),
      ),
      _PanelEntry(
        icon: Icons.home,
        title: 'Home',
        subtitle: 'Sections, poster size, image type',
        onTap: () => context.pushSettingsScreen(const _HomeCategoryScreen()),
      ),
      _PanelEntry(
        icon: Icons.settings,
        title: 'Plugin',
        subtitle: 'Navbar, shuffle, media bar',
        onTap: () => context.pushSettingsScreen(const _PluginCategoryScreen()),
      ),
      _PanelEntry(
        icon: Icons.auto_awesome,
        title: 'Screensaver',
        subtitle: 'Mode, timeout, dimming',
        onTap: () =>
            context.pushSettingsScreen(const ScreensaverSettingsScreen()),
      ),
      _PanelEntry(
        icon: Icons.play_circle,
        title: 'Playback',
        subtitle: 'Quality, next up, audio',
        onTap: () =>
            context.pushSettingsScreen(const _PlaybackCategoryScreen()),
      ),
      if (isJellyfinActive)
        _PanelEntry(
          icon: Icons.groups,
          title: 'SyncPlay',
          subtitle: 'Synchronized playback settings',
          onTap: () =>
              context.pushSettingsScreen(const _SyncPlaySettingsScreen()),
        ),
      _PanelEntry(
        icon: Icons.lock,
        title: 'Parental Controls',
        subtitle: 'Block content by rating',
        onTap: () => context.pushSettingsScreen(const ParentalSettingsScreen()),
      ),
      _PanelEntry(
        icon: Icons.info,
        title: 'About',
        subtitle: 'Version & licenses',
        onTap: () => context.pushSettingsScreen(const AboutScreen()),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context, rootNavigator: true).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: PlatformDetection.isTV
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
          automaticallyImplyLeading: !PlatformDetection.isTV,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (_, i) => _PanelEntryTile(entry: entries[i]),
        ),
      ),
    );
  }
}

class _PanelEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  const _PanelEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.focusNode,
  });
}

class _PanelEntryTile extends StatelessWidget {
  final _PanelEntry entry;

  const _PanelEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return _TvSettingsListTile(
      focusNode: entry.focusNode,
      autofocus: entry.focusNode != null,
      leading: Icon(entry.icon),
      title: Text(entry.title),
      subtitle: Text(entry.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: entry.onTap,
    );
  }
}

class _TvSettingsListTile extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  const _TvSettingsListTile({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<_TvSettingsListTile> createState() => _TvSettingsListTileState();
}

class _TvSettingsListTileState extends State<_TvSettingsListTile> {
  bool _focused = false;
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onTap?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = _focused
        ? Colors.white
        : colorScheme.surfaceContainerLow;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _onKeyEvent,
      onFocusChange: (hasFocus) {
        if (_focused == hasFocus) return;
        setState(() => _focused = hasFocus);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: _focused ? Colors.black : Colors.white70,
                      size: 22,
                    ),
                    child: widget.leading!,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _focused ? Colors.black : null,
                        ),
                        child: widget.title,
                      ),
                      if (widget.subtitle != null)
                        DefaultTextStyle.merge(
                          style: TextStyle(
                            fontSize: 12,
                            color: _focused
                                ? Colors.black54
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                          child: widget.subtitle!,
                        ),
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  IconTheme(
                    data: IconThemeData(
                      color: _focused ? Colors.black54 : Colors.white38,
                      size: 20,
                    ),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthenticationCategoryScreen extends StatelessWidget {
  const _AuthenticationCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Authentication')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Sort Servers By'),
            subtitle: const Text('Order of servers in the list'),
            onTap: () =>
                context.pushSettingsScreen(const _SortServersByScreen()),
          ),
          EnumPreferenceTile<UserSelectBehavior>(
            preference: UserPreferences.autoLoginUserBehavior,
            title: 'Auto Sign In',
            icon: Icons.person,
            labelOf: (v) => switch (v) {
              UserSelectBehavior.disabled => 'Disabled',
              UserSelectBehavior.lastUser => 'Last User',
              UserSelectBehavior.specificUser => 'Specific User',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.alwaysAuthenticate,
            title: 'Always Authenticate',
            subtitle: 'Require authentication every launch',
            icon: Icons.lock,
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.lock),
            title: const Text('PIN Code Protection'),
            subtitle: const Text('Require PIN to access the app'),
            onTap: () =>
                context.pushSettingsScreen(const PinCodeSettingsScreen()),
          ),
        ],
      ),
    );
  }
}

class _SortServersByScreen extends StatefulWidget {
  const _SortServersByScreen();

  @override
  State<_SortServersByScreen> createState() => _SortServersByScreenState();
}

class _SortServersByScreenState extends State<_SortServersByScreen> {
  late final PreferenceBinding<UserSortBy> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      AuthenticationPreferences.sortBy,
    );
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Sort Servers By')),
      body: ValueListenableBuilder<UserSortBy>(
        valueListenable: _binding,
        builder: (_, value, __) => Column(
          children: UserSortBy.values.map((option) {
            final label = option == UserSortBy.lastUsed
                ? 'Last Used'
                : 'Alphabetical';
            return RadioListTile<UserSortBy>(
              title: Text(label),
              value: option,
              groupValue: value,
              onChanged: (selected) {
                if (selected != null) _binding.value = selected;
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CustomizationCategoryScreen extends StatelessWidget {
  const _CustomizationCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Customization')),
      body: ListView(
        children: [
          _FocusColorPreferenceTile(),
          EnumPreferenceTile<ClockBehavior>(
            preference: UserPreferences.clockBehavior,
            title: 'Clock',
            icon: Icons.access_time,
            labelOf: (v) => switch (v) {
              ClockBehavior.always => 'Always',
              ClockBehavior.inMenus => 'In Menus',
              ClockBehavior.inVideo => 'In Video',
              ClockBehavior.never => 'Never',
            },
          ),
          EnumPreferenceTile<WatchedIndicatorBehavior>(
            preference: UserPreferences.watchedIndicatorBehavior,
            title: 'Watched Indicator',
            icon: Icons.check_circle,
            labelOf: (v) => switch (v) {
              WatchedIndicatorBehavior.always => 'Always',
              WatchedIndicatorBehavior.hideUnwatched => 'Hide Unwatched',
              WatchedIndicatorBehavior.episodesOnly => 'Episodes Only',
              WatchedIndicatorBehavior.never => 'Never',
            },
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.subtitles),
            title: const Text('Subtitles'),
            subtitle: const Text('Appearance and defaults'),
            onTap: () =>
                context.pushSettingsScreen(const SubtitleSettingsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('Libraries'),
            subtitle: const Text('Per-library display settings'),
            onTap: () =>
                context.pushSettingsScreen(const LibrarySettingsScreen()),
          ),
        ],
      ),
    );
  }
}

class _HomeCategoryScreen extends StatelessWidget {
  const _HomeCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Home')),
      body: ListView(
        children: [
          EnumPreferenceTile<PosterSize>(
            preference: UserPreferences.posterSize,
            title: 'Poster Size',
            icon: Icons.photo_size_select_large,
            labelOf: (v) => switch (v) {
              PosterSize.small => 'Small',
              PosterSize.medium => 'Medium',
              PosterSize.large => 'Large',
              PosterSize.extraLarge => 'Extra Large',
            },
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Image Type'),
            subtitle: const Text('Type of image shown on cards'),
            onTap: () =>
                context.pushSettingsScreen(const HomeRowsImageTypeScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.list),
            title: const Text('Sections'),
            subtitle: const Text('Reorder and toggle home sections'),
            onTap: () => context.pushSettingsScreen(
              const HomeSectionsScreen(showGeneralOptions: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _PluginCategoryScreen extends StatelessWidget {
  const _PluginCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Plugin')),
      body: ListView(
        children: [
          const PluginSettingsSection(),
          _TvSettingsListTile(
            leading: const Icon(Icons.view_sidebar),
            title: const Text('Toolbar'),
            subtitle: const Text('Navbar, shuffle, genres, libraries'),
            onTap: () =>
                context.pushSettingsScreen(const _ToolbarExtrasScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.featured_play_list),
            title: const Text('Media Bar'),
            subtitle: const Text('Featured slideshow on home screen'),
            onTap: () =>
                context.pushSettingsScreen(const MediaBarSettingsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Backgrounds'),
            subtitle: const Text('Backdrop, blur, seasonal effects'),
            onTap: () =>
                context.pushSettingsScreen(const _BackgroundsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Previews & Music'),
            subtitle: const Text('Media previews, theme music'),
            onTap: () =>
                context.pushSettingsScreen(const _PreviewsAndMusicScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Integrations'),
            subtitle: const Text('Seerr, multi-server, ratings'),
            onTap: () =>
                context.pushSettingsScreen(const _IntegrationsScreen()),
          ),
        ],
      ),
    );
  }
}

class _ToolbarExtrasScreen extends StatelessWidget {
  const _ToolbarExtrasScreen();

  @override
  Widget build(BuildContext context) {
    void pushSync() {
      final syncService = GetIt.instance<PluginSyncService>();
      if (syncService.pluginAvailable) {
        syncService.pushSettings(GetIt.instance<MediaServerClient>());
      }
    }

    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Toolbar')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.view_sidebar),
            title: const Text('Navbar Position'),
            subtitle: const Text('Where to display the navigation bar'),
            onTap: () =>
                context.pushSettingsScreen(const NavigationSettingsScreen()),
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.shuffleContentType,
            title: 'Shuffle Content Type',
            icon: Icons.shuffle,
            options: const {
              'movies': 'Movies',
              'tvshows': 'TV Shows',
              'both': 'Both',
            },
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showShuffleButton,
            title: 'Show Shuffle Button',
            subtitle: 'Show shuffle in toolbar',
            icon: Icons.shuffle,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showGenresButton,
            title: 'Show Genres Button',
            subtitle: 'Show genres in toolbar',
            icon: Icons.theater_comedy,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showFavoritesButton,
            title: 'Show Favorites Button',
            subtitle: 'Show favorites in toolbar',
            icon: Icons.favorite,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showLibrariesInToolbar,
            title: 'Show Libraries Button',
            subtitle: 'Show libraries in toolbar',
            icon: Icons.video_library,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.mergeContinueWatchingNextUp,
            title: 'Merge Continue Watching & Next Up',
            subtitle: 'Combine into a single row',
            icon: Icons.merge_type,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableFolderView,
            title: 'Enable Folder View',
            subtitle: 'Show folders in libraries',
            icon: Icons.folder,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showSyncPlayButton,
            title: 'Show SyncPlay Button',
            subtitle: 'Show SyncPlay in navigation',
            icon: Icons.groups,
            onChanged: pushSync,
          ),
        ],
      ),
    );
  }
}

class _BackgroundsScreen extends StatelessWidget {
  const _BackgroundsScreen();

  @override
  Widget build(BuildContext context) {
    void pushSync() {
      final syncService = GetIt.instance<PluginSyncService>();
      if (syncService.pluginAvailable) {
        syncService.pushSettings(GetIt.instance<MediaServerClient>());
      }
    }

    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Backgrounds')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.backdropEnabled,
            title: 'Backdrop',
            subtitle: 'Show background images',
            icon: Icons.photo,
            onChanged: pushSync,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.detailsBackgroundBlurAmount,
            title: 'Details Background Blur',
            icon: Icons.blur_on,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '$v',
            onChangeEnd: pushSync,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.browsingBackgroundBlurAmount,
            title: 'Browsing Background Blur',
            icon: Icons.blur_circular,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '$v',
            onChangeEnd: pushSync,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.seasonalSurprise,
            title: 'Seasonal Surprise',
            icon: Icons.auto_awesome,
            options: const {
              'none': 'None',
              'snow': 'Snow',
              'fireworks': 'Fireworks',
              'confetti': 'Confetti',
              'leaves': 'Leaves',
            },
            onChanged: pushSync,
          ),
        ],
      ),
    );
  }
}

class _PreviewsAndMusicScreen extends StatelessWidget {
  const _PreviewsAndMusicScreen();

  @override
  Widget build(BuildContext context) {
    void pushSync() {
      final syncService = GetIt.instance<PluginSyncService>();
      if (syncService.pluginAvailable) {
        syncService.pushSettings(GetIt.instance<MediaServerClient>());
      }
    }

    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Previews & Music')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.episodePreviewEnabled,
            title: 'Media Preview',
            subtitle: 'Show media previews on home rows',
            icon: Icons.ondemand_video,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.previewAudioEnabled,
            title: 'Preview Audio',
            subtitle: 'Play audio during previews',
            icon: Icons.volume_up,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.themeMusicEnabled,
            title: 'Theme Music',
            subtitle: 'Play theme music on detail screens',
            icon: Icons.music_note,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.themeMusicOnHomeRows,
            title: 'Theme Music on Home Rows',
            subtitle: 'Play when browsing home rows',
            icon: Icons.queue_music,
            onChanged: pushSync,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.themeMusicVolume,
            title: 'Theme Music Volume',
            icon: Icons.volume_down,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
            onChangeEnd: pushSync,
          ),
        ],
      ),
    );
  }
}

class _IntegrationsScreen extends StatelessWidget {
  const _IntegrationsScreen();

  @override
  Widget build(BuildContext context) {
    void pushSync() {
      final syncService = GetIt.instance<PluginSyncService>();
      if (syncService.pluginAvailable) {
        syncService.pushSettings(GetIt.instance<MediaServerClient>());
      }
    }

    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Integrations')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.movie),
            title: const Text('Seerr'),
            subtitle: const Text('Media request management'),
            onTap: () => context.pushSettingsScreen(const SeerrConfigScreen()),
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableMultiServerLibraries,
            title: 'Multi-Server',
            subtitle: 'Aggregate content from all logged-in servers',
            icon: Icons.dns,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableAdditionalRatings,
            title: 'Additional Ratings',
            subtitle: 'Show MDBList ratings on media bar',
            icon: Icons.star,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableEpisodeRatings,
            title: 'Episode Ratings',
            subtitle: 'Show TMDB episode ratings',
            icon: Icons.tv,
            onChanged: pushSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showRatingLabels,
            title: 'Rating Labels',
            subtitle: 'Show text labels next to rating icons',
            icon: Icons.label,
            onChanged: pushSync,
          ),
        ],
      ),
    );
  }
}

class _PlaybackCategoryScreen extends StatelessWidget {
  const _PlaybackCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Playback')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.play_circle),
            title: const Text('Playback'),
            subtitle: const Text('Quality, next up, audio'),
            onTap: () =>
                context.pushSettingsScreen(const PlaybackSettingsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.subtitles),
            title: const Text('Subtitles'),
            subtitle: const Text('Appearance and defaults'),
            onTap: () =>
                context.pushSettingsScreen(const SubtitleSettingsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Advanced'),
            subtitle: const Text('Resolution, zoom, delays, and more'),
            onTap: () =>
                context.pushSettingsScreen(const _PlaybackExtrasScreen()),
          ),
        ],
      ),
    );
  }
}

class _PlaybackExtrasScreen extends StatelessWidget {
  const _PlaybackExtrasScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Playback Advanced')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.cinemaModeEnabled,
            title: 'Prerolls Enabled',
            subtitle: 'Short movie intros before main content',
            icon: Icons.movie,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.videoStartDelay,
            title: 'Video Start Delay',
            icon: Icons.schedule,
            min: 0,
            max: 5000,
            divisions: 20,
            labelOf: (v) => '$v ms',
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.resumeSubtractDuration,
            title: 'Resume Pre-roll',
            icon: Icons.replay,
            options: const {
              '0': 'None',
              '5': '5 seconds',
              '10': '10 seconds',
              '15': '15 seconds',
              '30': '30 seconds',
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.unpauseRewindDuration,
            title: 'Unpause Rewind',
            icon: Icons.fast_rewind,
            min: 0,
            max: 10000,
            divisions: 20,
            labelOf: (v) => '${(v / 1000).toStringAsFixed(1)} s',
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.liveTvDirectPlayEnabled,
            title: 'Direct Play (Live TV)',
            subtitle: 'Play live streams directly',
            icon: Icons.live_tv,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaSegmentActions,
            title: 'Media Segments',
            icon: Icons.content_cut,
            options: const {
              'intro:askToSkip,outro:askToSkip': 'Prompt User',
              'intro:skip,outro:skip': 'Skip',
              'intro:doNothing,outro:doNothing': 'Do Nothing',
            },
          ),
        ],
      ),
    );
  }
}

class _SyncPlaySettingsScreen extends StatefulWidget {
  const _SyncPlaySettingsScreen();

  @override
  State<_SyncPlaySettingsScreen> createState() =>
      _SyncPlaySettingsScreenState();
}

class _SyncPlaySettingsScreenState extends State<_SyncPlaySettingsScreen> {
  late final PreferenceBinding<double> _minDelaySpeed;
  late final PreferenceBinding<double> _maxDelaySpeed;
  late final PreferenceBinding<double> _speedDuration;
  late final PreferenceBinding<double> _minDelaySkip;
  late final PreferenceBinding<double> _extraOffset;

  @override
  void initState() {
    super.initState();
    final store = GetIt.instance<PreferenceStore>();
    _minDelaySpeed = PreferenceBinding(
      store,
      UserPreferences.syncPlayMinDelaySpeedToSync,
    );
    _maxDelaySpeed = PreferenceBinding(
      store,
      UserPreferences.syncPlayMaxDelaySpeedToSync,
    );
    _speedDuration = PreferenceBinding(
      store,
      UserPreferences.syncPlaySpeedToSyncDuration,
    );
    _minDelaySkip = PreferenceBinding(
      store,
      UserPreferences.syncPlayMinDelaySkipToSync,
    );
    _extraOffset = PreferenceBinding(
      store,
      UserPreferences.syncPlayExtraTimeOffset,
    );
  }

  @override
  void dispose() {
    _minDelaySpeed.dispose();
    _maxDelaySpeed.dispose();
    _speedDuration.dispose();
    _minDelaySkip.dispose();
    _extraOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('SyncPlay')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.group_work),
            title: const Text('Open Groups'),
            subtitle: const Text('Create, join, or manage SyncPlay groups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SyncPlayScreen(),
              ),
            ),
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.syncPlayEnabled,
            title: 'Enabled',
            subtitle: 'Enable SyncPlay synchronized playback',
            icon: Icons.groups,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.syncPlayAdvancedCorrectionEnabled,
            title: 'Advanced Correction',
            subtitle: 'Use lead/late tolerances and drift correction',
            icon: Icons.tune,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.syncPlayEnableSyncCorrection,
            title: 'Sync Correction',
            subtitle: 'Automatically correct playback drift',
            icon: Icons.sync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.syncPlayUseSpeedToSync,
            title: 'Speed to Sync',
            subtitle: 'Adjust playback speed to sync',
            icon: Icons.speed,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.syncPlayUseSkipToSync,
            title: 'Skip to Sync',
            subtitle: 'Skip ahead/back to sync position',
            icon: Icons.skip_next,
          ),
          _DoubleSliderTile(
            title: 'Min Delay (Speed)',
            icon: Icons.timer,
            binding: _minDelaySpeed,
            min: 0,
            max: 5000,
          ),
          _DoubleSliderTile(
            title: 'Max Delay (Speed)',
            icon: Icons.timer,
            binding: _maxDelaySpeed,
            min: 0,
            max: 15000,
          ),
          _DoubleSliderTile(
            title: 'Speed Duration',
            icon: Icons.schedule,
            binding: _speedDuration,
            min: 100,
            max: 5000,
          ),
          _DoubleSliderTile(
            title: 'Min Delay (Skip)',
            icon: Icons.timer,
            binding: _minDelaySkip,
            min: 0,
            max: 15000,
          ),
          _DoubleSliderTile(
            title: 'Extra Time Offset',
            icon: Icons.schedule,
            binding: _extraOffset,
            min: -2000,
            max: 2000,
          ),
        ],
      ),
    );
  }
}

class _FocusColorPreferenceTile extends StatefulWidget {
  @override
  State<_FocusColorPreferenceTile> createState() =>
      _FocusColorPreferenceTileState();
}

class _FocusColorPreferenceTileState extends State<_FocusColorPreferenceTile> {
  final _prefs = GetIt.instance<UserPreferences>();

  @override
  Widget build(BuildContext context) {
    final focusColor = _prefs.get(UserPreferences.focusColor);
    return ListTile(
      leading: const Icon(Icons.border_color),
      title: const Text('Focus Border Color'),
      subtitle: Text(_formatThemeName(focusColor.name)),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(focusColor.colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
      ),
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Focus Border Color'),
        children: AppTheme.values.map((theme) {
          return ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(theme.colorValue),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            title: Text(_formatThemeName(theme.name)),
            onTap: () async {
              await _prefs.set(UserPreferences.focusColor, theme);
              if (!mounted) return;
              setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  String _formatThemeName(String camelCase) {
    final buf = StringBuffer();
    for (var i = 0; i < camelCase.length; i++) {
      final c = camelCase[i];
      if (i == 0) {
        buf.write(c.toUpperCase());
      } else if (c == c.toUpperCase() && c != c.toLowerCase()) {
        buf.write(' ');
        buf.write(c);
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }
}

class _DoubleSliderTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final PreferenceBinding<double> binding;
  final double min;
  final double max;

  const _DoubleSliderTile({
    required this.title,
    required this.icon,
    required this.binding,
    required this.min,
    required this.max,
  });

  @override
  State<_DoubleSliderTile> createState() => _DoubleSliderTileState();
}

class _DoubleSliderTileState extends State<_DoubleSliderTile> {
  late final FocusNode _sliderFocusNode;

  @override
  void initState() {
    super.initState();
    _sliderFocusNode = FocusNode(
      debugLabel: 'DoubleSlider_${widget.title}',
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          node.previousFocus();
          return KeyEventResult.skipRemainingHandlers;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          node.nextFocus();
          return KeyEventResult.skipRemainingHandlers;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _sliderFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.binding,
      builder: (_, value, __) => _TvSettingsListTile(
        leading: Icon(widget.icon),
        title: Text(widget.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${value.round()} ms'),
            Slider(
              focusNode: _sliderFocusNode,
              value: value.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              divisions: 40,
              onChanged: (v) => widget.binding.value = v,
            ),
          ],
        ),
      ),
    );
  }
}
