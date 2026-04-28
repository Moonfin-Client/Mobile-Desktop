import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:server_core/server_core.dart' hide ImageType;
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/plugin_sync_service.dart';
import '../../../di/providers.dart';
import '../../../util/focus/dpad_keys.dart';
import '../../../util/platform_detection.dart';

import '../../../auth/store/authentication_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../widgets/settings/settings_panel.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/focus/request_initial_focus.dart';
import 'home_rows_image_type_screen.dart';
import 'home_screen_sections_integration_screen.dart';
import 'kefin_tweaks_integration_screen.dart';
import 'appearance_theme_screen.dart';
import 'home_sections_screen.dart';
import 'library_settings_screen.dart';
import 'media_bar_settings_screen.dart';
import 'parental_settings_screen.dart';
import 'pin_code_settings_screen.dart';
import 'plugin_settings_screen.dart';
import 'ratings_config_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final showAdmin = !PlatformDetection.isTV && ref.watch(isAdminProvider);
    final entries = <_PanelEntry>[
      if (showAdmin)
        _PanelEntry(
          icon: Icons.admin_panel_settings,
          title: 'Administration',
          subtitle: 'Access the server administration panel',
          focusNode: _firstFocusNode,
          onTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.navigateTopLevel(Destinations.admin);
          },
        ),
      _PanelEntry(
        icon: Icons.lock,
        title: 'Account & Security',
        subtitle: 'Authentication, PIN code, and parental controls',
        focusNode: showAdmin ? null : _firstFocusNode,
        onTap: () =>
            context.pushSettingsScreen(const _AuthenticationCategoryScreen()),
      ),
      _PanelEntry(
        icon: Icons.palette,
        title: 'Personalization',
        subtitle: 'Theme, navigation, home rows, and library visibility',
        onTap: () =>
            context.pushSettingsScreen(const _CustomizationCategoryScreen()),
      ),
      _PanelEntry(
        icon: Icons.featured_play_list,
        title: 'Dynamic Content',
        subtitle: 'Media Bar and visual overlays',
        onTap: () => context.pushSettingsScreen(const _PluginCategoryScreen()),
      ),
      _PanelEntry(
        icon: Icons.play_circle,
        title: 'Playback & SyncPlay',
        subtitle: 'Audio/video settings, subtitles, downloads, and SyncPlay controls',
        onTap: () =>
            context.pushSettingsScreen(const _PlaybackCategoryScreen()),
      ),
      _PanelEntry(
        icon: Icons.hub,
        title: 'Integrations',
        subtitle: 'Plugin sync, Seerr, ratings, and more',
        onTap: () => context.pushSettingsScreen(const _IntegrationsScreen()),
      ),
      _PanelEntry(
        icon: Icons.info_outline,
        title: 'About',
        subtitle: 'App version, legal information, and credits',
        onTap: () => context.pushSettingsScreen(const _AboutCategoryScreen()),
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
          leading: PlatformDetection.isTV
              ? IconButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  icon: const Icon(Icons.close),
                )
              : null,
          automaticallyImplyLeading: !PlatformDetection.isTV,
          title: const Text('Settings'),
        ),
        body: ListView(
          children: [
            for (final entry in entries) _PanelEntryTile(entry: entry),
          ],
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
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _TvSettingsListTile({
    this.focusNode,
    this.autofocus = false,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<_TvSettingsListTile> createState() => _TvSettingsListTileState();
}

class _TvSettingsListTileState extends State<_TvSettingsListTile> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
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

  @override
  Widget build(BuildContext context) {
    final resolvedTrailing =
        widget.trailing ?? (widget.onTap != null ? const Icon(Icons.chevron_right) : null);
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          final onTap = widget.onTap;
          if (onTap != null) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TvFocusHighlight(
        builder: (context, focused) => ListTile(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          leading: widget.leading != null
              ? IconTheme(
                  data: IconThemeData(
                    size: 22,
                    color: focused ? Colors.black54 : Colors.white70,
                  ),
                  child: widget.leading!,
                )
              : null,
          title: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: focused ? Colors.black87 : Colors.white,
            ),
            child: widget.title,
          ),
          subtitle: widget.subtitle != null
              ? DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 12,
                    color: focused ? Colors.black54 : Colors.white70,
                  ),
                  child: widget.subtitle!,
                )
              : null,
          trailing: resolvedTrailing != null
              ? IconTheme(
                  data: IconThemeData(
                    size: 20,
                    color: focused ? Colors.black54 : Colors.white70,
                  ),
                  child: resolvedTrailing,
                )
              : null,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

String _formatCamelCaseLabel(String camelCase) {
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

void _ensureSettingsTileVisible(BuildContext context, {double alignment = 0.9}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Scrollable.ensureVisible(
      context,
      alignment: alignment,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  });
}

class _AuthenticationCategoryScreen extends StatelessWidget {
  const _AuthenticationCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Account & Security')),
      body: ListView(
        children: [
          const _SectionHeader('AUTHENTICATION'),
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
            title: 'Always Authenticate?',
            subtitle: 'Require the account password every time the app opens',
            icon: Icons.lock,
          ),
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.pin),
            title: const Text('PIN Code Protection'),
            subtitle: const Text('Set a required numeric PIN to access this account'),
            onTap: () =>
                context.pushSettingsScreen(const PinCodeSettingsScreen()),
          ),
          EnumPreferenceTile<UserSortBy>(
            preference: AuthenticationPreferences.sortBy,
            title: 'Sort Servers By',
            icon: Icons.swap_horiz,
            labelOf: (v) => switch (v) {
              UserSortBy.lastUsed => 'Last Used',
              UserSortBy.alphabetical => 'Alphabetical',
            },
          ),
          const _SectionHeader('PRIVACY & SAFETY'),
          _TvSettingsListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Blocked Ratings'),
            subtitle: const Text('Hide content from the selected parental ratings'),
            onTap: () =>
                context.pushSettingsScreen(const ParentalSettingsScreen()),
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.confirmExit,
            title: 'Exit Confirmation',
            subtitle: 'Show a confirmation prompt before closing Moonfin',
            icon: Icons.exit_to_app,
          ),
          ],
        ),
    );
  }
}

class _CustomizationCategoryScreen extends StatelessWidget {
  const _CustomizationCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Personalization')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.style),
            title: const Text('General Style'),
            subtitle: const Text(
              'Theme accents, backdrops, watched indicators, and theme music',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _GeneralStyleScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.view_sidebar),
            title: const Text('Navigation'),
            subtitle: const Text(
              'Navbar position, color, opacity, and toolbar buttons',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _NavigationCategoryScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home Page'),
            subtitle: const Text(
              'Sections, image types, overlays, and media previews',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _HomePageCategoryScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Libraries'),
            subtitle: const Text(
              'Library visibility, folder view, and multi-server behavior',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _LibrariesCategoryScreen()),
          ),
        ],
      ),
    );
  }
}

void _pushPersonalizationSync() {
  final syncService = GetIt.instance<PluginSyncService>();
  if (syncService.pluginAvailable) {
    syncService.pushSettings(GetIt.instance<MediaServerClient>());
  }
}

class _GeneralStyleScreen extends StatefulWidget {
  const _GeneralStyleScreen();

  @override
  State<_GeneralStyleScreen> createState() => _GeneralStyleScreenState();
}

class _GeneralStyleScreenState extends State<_GeneralStyleScreen> {
  final _generalStyleScope = FocusScopeNode(
    debugLabel: 'GeneralStyleSettingsScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.stop,
  );

  @override
  void dispose() {
    _generalStyleScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = PlatformDetection.isTV ? 96.0 : 24.0;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('General Style')),
      body: FocusScope(
        node: _generalStyleScope,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad),
          children: [
            _TvSettingsListTile(
              autofocus: true,
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.settingsAppearanceTheme),
              subtitle: Text(l10n.settingsAppearanceThemeSubtitle),
              onTap: () => context.pushSettingsScreen(const AppearanceThemeScreen()),
            ),
            EnumPreferenceTile<AppTheme>(
            preference: UserPreferences.focusColor,
            title: 'Focus Border Color',
            icon: Icons.border_color,
            labelOf: (v) => _formatCamelCaseLabel(v.name),
          ),
            EnumPreferenceTile<ClockBehavior>(
            preference: UserPreferences.clockBehavior,
            title: 'Clock Display',
            icon: Icons.access_time,
            labelOf: (v) => switch (v) {
              ClockBehavior.always => 'Always',
              ClockBehavior.inMenus => 'In Menus',
              ClockBehavior.inVideo => 'In Video',
              ClockBehavior.never => 'Never',
            },
          ),
            SwitchPreferenceTile(
            preference: UserPreferences.use24HourClock,
            title: '24-Hour Clock',
            subtitle: 'Use 24-hour time formatting wherever the clock is shown',
            icon: Icons.schedule,
          ),
            if (!PlatformDetection.useMobileUi)
              SwitchPreferenceTile(
              preference: UserPreferences.cardFocusExpansion,
              title: 'Card Focus Expansion',
              subtitle: 'Cards grow slightly when focused',
              icon: Icons.zoom_in,
            ),
            SwitchPreferenceTile(
            preference: UserPreferences.backdropEnabled,
            title: 'Show Backdrops',
            subtitle: 'Show fanart in the background of detail pages',
            icon: Icons.photo,
            onChanged: _pushPersonalizationSync,
          ),
            SliderPreferenceTile(
            preference: UserPreferences.browsingBackgroundBlurAmount,
            title: 'Browsing Blur',
            icon: Icons.blur_circular,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '$v',
            onChangeEnd: _pushPersonalizationSync,
          ),
            SliderPreferenceTile(
            preference: UserPreferences.detailsBackgroundBlurAmount,
            title: 'Details Blur',
            icon: Icons.blur_on,
            min: 0,
            max: 25,
            divisions: 25,
            labelOf: (v) => '$v',
            onChangeEnd: _pushPersonalizationSync,
          ),
            EnumPreferenceTile<WatchedIndicatorBehavior>(
            preference: UserPreferences.watchedIndicatorBehavior,
            title: 'Watched Indicators',
            icon: Icons.check_circle,
            labelOf: (v) => switch (v) {
              WatchedIndicatorBehavior.always => 'Always',
              WatchedIndicatorBehavior.hideUnwatched => 'Hide Unwatched',
              WatchedIndicatorBehavior.episodesOnly => 'Episodes Only',
              WatchedIndicatorBehavior.never => 'Never',
            },
          ),
            SwitchPreferenceTile(
            preference: UserPreferences.themeMusicEnabled,
            title: 'Theme Music',
            subtitle: 'Play theme songs while browsing media detail pages',
            icon: Icons.music_note,
            onChanged: _pushPersonalizationSync,
          ),
            SliderPreferenceTile(
            preference: UserPreferences.themeMusicVolume,
            title: 'Theme Music Volume',
            icon: Icons.volume_down,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
            onChangeEnd: _pushPersonalizationSync,
          ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCategoryScreen extends StatelessWidget {
  const _NavigationCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Navigation')),
      body: ListView(
        children: [
          EnumPreferenceTile<NavbarPosition>(
            preference: UserPreferences.navbarPosition,
            title: 'Navbar Position',
            icon: Icons.view_sidebar,
            labelOf: (v) => switch (v) {
              NavbarPosition.top => 'Top',
              NavbarPosition.left => 'Left',
            },
            onChanged: () {
              final pos = GetIt.instance<UserPreferences>()
                  .get(UserPreferences.navbarPosition);
              NavigationLayout.positionNotifier.value = pos;
              _pushPersonalizationSync();
            },
          ),
          _NavbarColorPickerTile(onChanged: _pushPersonalizationSync),
          SliderPreferenceTile(
            preference: UserPreferences.navbarOpacity,
            title: 'Navbar Opacity',
            icon: Icons.opacity,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showShuffleButton,
            title: 'Shuffle Button',
            subtitle: 'Show the shuffle button in the navigation bar',
            icon: Icons.shuffle,
            onChanged: _pushPersonalizationSync,
          ),
          _ShuffleContentTypePickerTile(onChanged: _pushPersonalizationSync),
          SwitchPreferenceTile(
            preference: UserPreferences.showGenresButton,
            title: 'Genres Button',
            subtitle: 'Show the genres button in the navigation bar',
            icon: Icons.theater_comedy,
            onChanged: _pushPersonalizationSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showFavoritesButton,
            title: 'Favorites Button',
            subtitle: 'Show the favorites button in the navigation bar',
            icon: Icons.favorite,
            onChanged: _pushPersonalizationSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showLibrariesInToolbar,
            title: 'Libraries Button',
            subtitle: 'Show the libraries button in the navigation bar',
            icon: Icons.video_library,
            onChanged: _pushPersonalizationSync,
          ),
        ],
      ),
    );
  }
}

class _HomePageCategoryScreen extends StatelessWidget {
  const _HomePageCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Home Page')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.list),
            title: const Text('Home Sections'),
            subtitle: const Text('Configure which rows appear on the home screen'),
            onTap: () => context.pushSettingsScreen(
              const HomeSectionsScreen(showGeneralOptions: false),
            ),
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.mergeContinueWatchingNextUp,
            title: 'Merge Continue Watching',
            subtitle: 'Combine Continue Watching and Next Up into one row',
            icon: Icons.merge_type,
            onChanged: _pushPersonalizationSync,
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Home Row Image Type'),
            subtitle: const Text('Per-row image type override'),
            onTap: () =>
                context.pushSettingsScreen(const HomeRowsImageTypeScreen()),
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.seriesThumbnailsEnabled,
            title: 'Series Thumbnails',
            subtitle: 'If thumbnails are selected in Home Row Image, show series instead of episode thumbnails.',
            icon: Icons.image_aspect_ratio,
          ),
          EnumPreferenceTile<PosterSize>(
            preference: UserPreferences.posterSize,
            title: 'Image Size',
            icon: Icons.photo_size_select_large,
            labelOf: (v) => switch (v) {
              PosterSize.small => 'Small',
              PosterSize.medium => 'Medium',
              PosterSize.large => 'Large',
              PosterSize.extraLarge => 'Extra Large',
            },
            onChanged: _pushPersonalizationSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.homeRowInfoOverlay,
            title: 'Home Row Overlay',
            subtitle: 'Show descriptive overlay for the selected item',
            icon: Icons.info_outline,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.themeMusicOnHomeRows,
            title: 'Play Theme Music on Home Page',
            subtitle: 'Also play theme music while browsing the home screen',
            icon: Icons.queue_music,
            onChanged: _pushPersonalizationSync,
          ),
        ],
      ),
    );
  }
}

class _LibrariesCategoryScreen extends StatelessWidget {
  const _LibrariesCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Libraries')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Library Visibility'),
            subtitle: const Text(
              'Toggle home page visibility per library. '
              'Restart Moonfin for changes to take effect.',
            ),
            onTap: () =>
                context.pushSettingsScreen(const LibraryVisibilityScreen()),
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableFolderView,
            title: 'Folder View',
            subtitle: 'Enable browsing by file system structure',
            icon: Icons.folder,
            onChanged: _pushPersonalizationSync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableMultiServerLibraries,
            title: 'Multi-Server Libraries',
            subtitle: 'Combine items from multiple servers in a single view',
            icon: Icons.dns,
            onChanged: _pushPersonalizationSync,
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
      appBar: buildSettingsAppBar(context, const Text('Dynamic Content')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.featured_play_list),
            title: const Text('Media Bar & Local Previews'),
            subtitle: const Text(
              'Spotlight carousel, content filters, and auto-advance',
            ),
            onTap: () =>
                context.pushSettingsScreen(const MediaBarSettingsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Visual Overlays'),
            subtitle: const Text(
              'Seasonal effects and screensaver appearance',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _VisualOverlaysScreen()),
          ),
        ],
      ),
    );
  }
}

class _VisualOverlaysScreen extends StatelessWidget {
  const _VisualOverlaysScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Visual Overlays')),
      body: ListView(
        children: [
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
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverInAppEnabled,
            title: 'In-App Screensaver',
            subtitle: 'Protect your screen with a built-in screensaver',
            icon: Icons.screen_lock_landscape,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.screensaverMode,
            title: 'Screensaver Mode',
            icon: Icons.tv,
            options: const {
              'library': 'Library',
              'logo': 'Logo',
              'clock': 'Clock',
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverInAppTimeout,
            title: 'Screensaver Timeout',
            icon: Icons.timer,
            min: 60000,
            max: 1800000,
            divisions: 29,
            labelOf: (v) => '${(v / 1000).round()}s',
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverDimmingLevel,
            title: 'Screensaver Dimming Level',
            icon: Icons.brightness_low,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverAgeRatingMax,
            title: 'Screensaver Max Age Rating',
            icon: Icons.shield,
            min: 0,
            max: 18,
            divisions: 18,
            labelOf: (v) => v == 0 ? 'Any' : '$v+',
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverAgeRatingRequired,
            title: 'Screensaver Rating Requirement',
            subtitle: 'Only show items that have a rating',
            icon: Icons.verified,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverShowClock,
            title: 'Screensaver Clock',
            subtitle: 'Always show the system clock on the screensaver',
            icon: Icons.access_time,
          ),
        ],
      ),
    );
  }
}

class _IntegrationsScreen extends StatefulWidget {
  const _IntegrationsScreen();

  @override
  State<_IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<_IntegrationsScreen> {
  final _integrationsScope = FocusScopeNode(
    debugLabel: 'IntegrationsSettingsScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _integrationsScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Integrations')),
      body: FocusScope(
        node: _integrationsScope,
        autofocus: true,
        child: ListView(
          children: [
            _TvSettingsListTile(
              autofocus: true,
              leading: const Icon(Icons.extension),
              title: const Text('Plugin'),
              subtitle: const Text(
                'Moonbase status, sync profiles, and plugin sync controls',
              ),
              onTap: () =>
                  context.pushSettingsScreen(const _PluginScreen()),
            ),
            _TvSettingsListTile(
              leading: const Icon(Icons.star),
              title: const Text('Metadata & Ratings'),
              subtitle: const Text(
                'Rating sources, display options, and API keys',
              ),
              onTap: () =>
                  context.pushSettingsScreen(const _MetadataRatingsScreen()),
            ),
            _TvSettingsListTile(
              leading: Image.asset(
                'assets/icons/seerr.png',
                width: 24,
                height: 24,
              ),
              title: const Text('Seerr'),
              subtitle: const Text(
                'Enable and configure Seerr for media request management',
              ),
              onTap: () => context.pushSettingsScreen(const SeerrConfigScreen()),
            ),
            _TvSettingsListTile(
              leading: Image.asset(
                'assets/icons/hss.png',
                width: 24,
                height: 24,
              ),
              title: const Text('Home Screen Sections'),
              subtitle: const Text(
                'Detect and configure the Home Screen Sections plugin',
              ),
              onTap: () => context.pushSettingsScreen(
                const HomeScreenSectionsIntegrationScreen(),
              ),
            ),
            _TvSettingsListTile(
              leading: Image.asset(
                'assets/icons/kf.png',
                width: 24,
                height: 24,
              ),
              title: const Text('KefinTweaks'),
              subtitle: const Text(
                'Mirror home rows from the KefinTweaks front-end plugin',
              ),
              onTap: () => context.pushSettingsScreen(
                const KefinTweaksIntegrationScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PluginScreen extends StatefulWidget {
  const _PluginScreen();

  @override
  State<_PluginScreen> createState() => _PluginScreenState();
}

class _PluginScreenState extends State<_PluginScreen> {
  final _pluginScope = FocusScopeNode(
    debugLabel: 'PluginSettingsScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _pluginScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Plugin')),
      body: FocusScope(
        node: _pluginScope,
        autofocus: true,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.extension,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Moonbase powers server-side integrations including additional '
                        'rating sources, Seerr requests, and synced preferences.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PluginSettingsSection(),
          ],
        ),
      ),
    );
  }
}

class _MetadataRatingsScreen extends StatefulWidget {
  const _MetadataRatingsScreen();

  @override
  State<_MetadataRatingsScreen> createState() =>
      _MetadataRatingsScreenState();
}

class _MetadataRatingsScreenState extends State<_MetadataRatingsScreen> {
  final _metadataScope = FocusScopeNode(
    debugLabel: 'MetadataRatingsSettingsScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _metadataScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          buildSettingsAppBar(context, const Text('Metadata & Ratings')),
      body: FocusScope(
        node: _metadataScope,
        autofocus: true,
        child: ListView(
          children: [
            SwitchPreferenceTile(
              preference: UserPreferences.enableAdditionalRatings,
              title: 'Fetch Additional Ratings',
              subtitle: 'Pull scores from IMDb, Rotten Tomatoes, and more',
              icon: Icons.star,
              onChanged: _pushPersonalizationSync,
            ),
            _TvSettingsListTile(
              leading: const Icon(Icons.reorder),
              title: const Text('Enabled Rating Sources'),
              subtitle: const Text('Configure providers and display order'),
              onTap: () =>
                  context.pushSettingsScreen(const RatingsConfigScreen()),
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.enableEpisodeRatings,
              title: 'Show Episode Ratings',
              subtitle: 'Show ratings for individual episodes',
              icon: Icons.stars,
              onChanged: _pushPersonalizationSync,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.showRatingLabels,
              title: 'Show Rating Text Labels',
              subtitle: 'Show text labels in addition to source icons',
              icon: Icons.label,
              onChanged: _pushPersonalizationSync,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.showRatingBadges,
              title: 'Show Rating Badges',
              subtitle: 'Show rating score badges on cards',
              icon: Icons.style,
              onChanged: _pushPersonalizationSync,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineDownloadsScreen extends StatefulWidget {
  const _OfflineDownloadsScreen();

  @override
  State<_OfflineDownloadsScreen> createState() =>
      _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<_OfflineDownloadsScreen> {
  final _offlineScope = FocusScopeNode(
    debugLabel: 'OfflineDownloadsSettingsScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _offlineScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          buildSettingsAppBar(context, const Text('Offline Downloads')),
      body: FocusScope(
        node: _offlineScope,
        autofocus: true,
        child: ListView(
          children: [
            StringPickerPreferenceTile(
              preference: UserPreferences.defaultDownloadQuality,
              title: 'Default Download Quality',
              icon: Icons.high_quality,
              options: const {
                'original': 'Original',
                'high': 'High',
                'medium': 'Medium',
                'low': 'Low',
              },
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.downloadWifiOnly,
              title: 'WiFi Only',
              subtitle: 'Only allow downloads when connected to WiFi',
              icon: Icons.wifi,
            ),
            SliderPreferenceTile(
              preference: UserPreferences.downloadStorageLimitMb,
              title: 'Storage Limit',
              icon: Icons.storage,
              min: 0,
              max: 102400,
              divisions: 100,
              labelOf: (v) => v == 0
                  ? 'No limit'
                  : '${(v / 1024).toStringAsFixed(1)} GB',
            ),
            _EditableStringPreferenceTile(
              preference: UserPreferences.customDownloadPath,
              title: 'Custom Path',
              icon: Icons.folder_open,
              hintText: 'Enter download folder path',
            ),
            IntPickerPreferenceTile(
              preference: UserPreferences.downloadConcurrentCount,
              title: 'Concurrent Downloads',
              description: 'Maximum number of items to download at once.',
              icon: Icons.queue,
              options: const {
                1: '1',
                2: '2',
                3: '3',
                4: '4',
                5: '5',
                6: '6',
                7: '7',
                8: '8',
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCategoryScreen extends StatelessWidget {
  const _AboutCategoryScreen();

  @override
  Widget build(BuildContext context) {
    final appVersion = GetIt.instance<DeviceInfo>().appVersion;
    final platformLabel = _platformLabel();
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('About')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Image.asset(
              'assets/images/logo_and_text.png',
              height: 72,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version $appVersion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const _SectionHeader('APP INFO'),
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(appVersion),
            trailing: const SizedBox.shrink(),
            onTap: () {},
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Platform'),
            subtitle: Text(platformLabel),
            trailing: const SizedBox.shrink(),
            onTap: () {},
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text(
              'github.com/Moonfin-Client/Mobile-Desktop',
            ),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/Moonfin-Client/Mobile-Desktop',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report an Issue'),
            subtitle: const Text(
              'Open the issue tracker on GitHub',
            ),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/Moonfin-Client/Mobile-Desktop/issues',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Support Moonfin'),
            subtitle: const Text(
              'Star the project on GitHub or contribute',
            ),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/Moonfin-Client'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const _SectionHeader('LEGAL'),
          _TvSettingsListTile(
            leading: const Icon(Icons.description),
            title: const Text('Licenses'),
            subtitle: const Text('Open-source license notices'),
            onTap: () => context.pushSettingsScreen(const _LicensesScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How Moonfin handles your data'),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/Moonfin-Client/Mobile-Desktop/blob/main/PRIVACY_POLICY.md',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }

  String _platformLabel() {
    if (PlatformDetection.isTV) return 'Android TV';
    if (PlatformDetection.isAndroid) return 'Android';
    if (PlatformDetection.isIOS) return 'iOS';
    if (PlatformDetection.isMacOS) return 'macOS';
    if (PlatformDetection.isWindows) return 'Windows';
    if (PlatformDetection.isLinux) return 'Linux';
    if (PlatformDetection.isWeb) return 'Web';
    return 'Unknown';
  }
}

class _LicensesScreen extends StatefulWidget {
  const _LicensesScreen();

  @override
  State<_LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<_LicensesScreen> {
  final _firstLicenseFocusNode = FocusNode(debugLabel: 'LicensesFirstItem');
  late final Future<List<_LicensePackageData>> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _licensesFuture = _loadLicenses();
  }

  @override
  void dispose() {
    _firstLicenseFocusNode.dispose();
    super.dispose();
  }

  Future<List<_LicensePackageData>> _loadLicenses() async {
    final licenseBlocksByPackage = <String, List<String>>{};

    await for (final entry in LicenseRegistry.licenses) {
      final text = _licenseText(entry.paragraphs);
      if (text.isEmpty) continue;

      for (final package in entry.packages) {
        final normalized = package.trim();
        if (normalized.isEmpty) continue;
        if (normalized.toLowerCase() == 'moonfin') continue;
        licenseBlocksByPackage.putIfAbsent(normalized, () => []).add(text);
      }
    }

    final packages = licenseBlocksByPackage.entries
        .map(
          (entry) => _LicensePackageData(
            packageName: entry.key,
            blocks: List<String>.unmodifiable(entry.value),
          ),
        )
        .toList()
      ..sort((a, b) => a.packageName.toLowerCase().compareTo(b.packageName.toLowerCase()));

    return packages;
  }

  String _licenseText(Iterable<LicenseParagraph> paragraphs) {
    final buffer = StringBuffer();
    for (final paragraph in paragraphs) {
      final text = paragraph.text.trimRight();
      if (text.isEmpty) {
        buffer.writeln();
        continue;
      }
      final indent = '  ' * paragraph.indent;
      for (final line in text.split('\n')) {
        buffer.writeln('$indent${line.trimRight()}');
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return RequestInitialFocus(
      targetNode: PlatformDetection.isTV ? _firstLicenseFocusNode : null,
      child: Scaffold(
        appBar: buildSettingsAppBar(context, const Text('Licenses')),
        body: FutureBuilder<List<_LicensePackageData>>(
          future: _licensesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final packages = snapshot.data ?? const <_LicensePackageData>[];
            return ListView(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Powered by Flutter',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                for (final entry in packages)
                  _TvSettingsListTile(
                    focusNode: identical(entry, packages.firstOrNull)
                        ? _firstLicenseFocusNode
                        : null,
                    autofocus: identical(entry, packages.firstOrNull),
                    leading: const Icon(Icons.description_outlined),
                    title: Text(entry.packageName),
                    subtitle: Text(
                      entry.blocks.length == 1
                          ? '1 license notice'
                          : '${entry.blocks.length} license notices',
                    ),
                    onTap: () => context.pushSettingsScreen(
                      _LicenseDetailScreen(entry: entry),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LicenseDetailScreen extends StatefulWidget {
  final _LicensePackageData entry;

  const _LicenseDetailScreen({required this.entry});

  @override
  State<_LicenseDetailScreen> createState() => _LicenseDetailScreenState();
}

class _LicenseDetailScreenState extends State<_LicenseDetailScreen> {
  final _scrollController = ScrollController();
  final _scrollFocusNode = FocusNode(debugLabel: 'LicenseDetailScroll');

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onScrollKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_scrollController.hasClients) return KeyEventResult.ignored;

    const delta = 120.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _scrollBy(delta);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _scrollBy(-delta);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scrollBy(double delta) {
    final position = _scrollController.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RequestInitialFocus(
      targetNode: PlatformDetection.isTV ? _scrollFocusNode : null,
      child: Scaffold(
        appBar: buildSettingsAppBar(context, Text(widget.entry.packageName)),
        body: Focus(
          focusNode: _scrollFocusNode,
          onKeyEvent: _onScrollKey,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: widget.entry.blocks.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  widget.entry.blocks[index],
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LicensePackageData {
  final String packageName;
  final List<String> blocks;

  const _LicensePackageData({
    required this.packageName,
    required this.blocks,
  });
}

class _PlaybackCategoryScreen extends StatelessWidget {
  const _PlaybackCategoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Playback & SyncPlay')),
      body: ListView(
        children: [
          _TvSettingsListTile(
            autofocus: true,
            leading: const Icon(Icons.play_circle),
            title: const Text('Video Playback Preferences'),
            subtitle: const Text(
              'Core video engine and streaming quality settings',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _VideoPlaybackScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Audio Preferences'),
            subtitle: const Text(
              'Audio tracks, processing, and passthrough options',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _AudioPreferencesScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.subtitles),
            title: const Text('Subtitles'),
            subtitle: const Text('Formatting, timing, and rendering options'),
            onTap: () =>
                context.pushSettingsScreen(const SubtitleSettingsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.queue_play_next),
            title: const Text('Automation & Queue'),
            subtitle: const Text('Automated playback and sequencing'),
            onTap: () =>
                context.pushSettingsScreen(const _AutomationQueueScreen()),
          ),
          if (!PlatformDetection.isTV)
            _TvSettingsListTile(
              leading: const Icon(Icons.download),
              title: const Text('Offline Downloads'),
              subtitle: const Text(
                'Download quality, storage limits, and queue size',
              ),
              onTap: () =>
                  context.pushSettingsScreen(const _OfflineDownloadsScreen()),
            ),
          _TvSettingsListTile(
            leading: const Icon(Icons.groups),
            title: const Text('SyncPlay'),
            subtitle: const Text('Synchronization logic for group sessions'),
            onTap: () =>
                context.pushSettingsScreen(const _SyncPlaySettingsScreen()),
          ),
          _TvSettingsListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Advanced Options'),
            subtitle: const Text(
              'Specialized player features. Use with caution, as some options may cause playback issues',
            ),
            onTap: () =>
                context.pushSettingsScreen(const _AdvancedOptionsScreen()),
          ),
        ],
      ),
    );
  }
}

class _VideoPlaybackScreen extends StatelessWidget {
  const _VideoPlaybackScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(
        context,
        const Text('Video Playback Preferences'),
      ),
      body: ListView(
        children: [
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaSegmentActions,
            title: 'Skip Intros and Outros?',
            icon: Icons.content_cut,
            options: const {
              'intro:askToSkip,outro:askToSkip': 'Prompt User',
              'intro:skip,outro:skip': 'Skip',
              'intro:doNothing,outro:doNothing': 'Do Nothing',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showDescriptionOnPause,
            title: 'Show Description on Pause',
            subtitle: 'Show video description overlay while paused',
            icon: Icons.pause_circle_outline,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.maxBitrate,
            title: 'Max Bitrate',
            description:
                'Cap the streaming bitrate. Content above this threshold '
                'will be transcoded to fit.',
            icon: Icons.network_check,
            options: const {
              'auto': 'Auto',
              '200000000': '200 Mbps',
              '120000000': '120 Mbps',
              '80000000': '80 Mbps',
              '40000000': '40 Mbps',
              '20000000': '20 Mbps',
              '10000000': '10 Mbps',
              '5000000': '5 Mbps',
              '2000000': '2 Mbps',
              '1000000': '1 Mbps',
            },
          ),
          EnumPreferenceTile<MaxVideoResolution>(
            preference: UserPreferences.maxVideoResolution,
            title: 'Max Resolution',
            description:
                'Limit the maximum resolution the player will request. '
                'Higher-resolution content will be transcoded down.',
            icon: Icons.high_quality,
            labelOf: (v) => switch (v) {
              MaxVideoResolution.auto => 'Auto',
              MaxVideoResolution.res480p => '480p',
              MaxVideoResolution.res720p => '720p',
              MaxVideoResolution.res1080p => '1080p',
              MaxVideoResolution.res2160p => '2160p (4K)',
            },
          ),
          EnumPreferenceTile<ZoomMode>(
            preference: UserPreferences.playerZoomMode,
            title: 'Player Zoom',
            description:
                'How video should be scaled to fit the screen.',
            icon: Icons.zoom_out_map,
            labelOf: (v) => switch (v) {
              ZoomMode.fit => 'Fit',
              ZoomMode.autoCrop => 'Auto Crop',
              ZoomMode.stretch => 'Stretch',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.hardwareDecoding,
            title: 'Hardware Decoding',
            subtitle: 'Use GPU for video decoding if available',
            icon: Icons.memory,
          ),
          EnumPreferenceTile<RefreshRateSwitchingBehavior>(
            preference: UserPreferences.refreshRateSwitchingBehavior,
            title: 'Refresh Rate Switching',
            icon: Icons.speed,
            labelOf: (v) => switch (v) {
              RefreshRateSwitchingBehavior.disabled => 'Disabled',
              RefreshRateSwitchingBehavior.scaleOnTv => 'Scale on TV',
              RefreshRateSwitchingBehavior.scaleOnDevice => 'Scale on Device',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.trickPlayEnabled,
            title: 'Trick Play',
            subtitle: 'Show thumbnails while scrubbing (if available)',
            icon: Icons.image_search,
          ),
          if (PlatformDetection.useMobileUi)
            SwitchPreferenceTile(
              preference: UserPreferences.osdLockEnabled,
              title: 'Mobile Lock Button',
              subtitle: 'Show a lock button during playback',
              icon: Icons.lock,
            ),
          StringPickerPreferenceTile(
            preference: UserPreferences.resumeSubtractDuration,
            title: 'Resume Rewind',
            description:
                'When resuming playback (from Continue Watching or a media '
                'item page), how many seconds should be rewound?',
            icon: Icons.replay,
            options: const {
              '0': 'Disabled',
              '5': '5 seconds',
              '10': '10 seconds',
              '15': '15 seconds',
              '30': '30 seconds',
            },
          ),
          IntPickerPreferenceTile(
            preference: UserPreferences.unpauseRewindDuration,
            title: 'Unpause Rewind',
            description:
                'When resuming playback after pressing the pause button, '
                'how many seconds should be rewound?',
            icon: Icons.replay_circle_filled,
            options: const {
              0: 'Disabled',
              5000: '5 seconds',
              10000: '10 seconds',
              15000: '15 seconds',
              30000: '30 seconds',
            },
          ),
          IntPickerPreferenceTile(
            preference: UserPreferences.skipBackLength,
            title: 'Skip Back Length',
            description:
                'How many seconds to jump back after pressing the rewind '
                'button.',
            icon: Icons.fast_rewind,
            options: const {
              1000: '1 second',
              3000: '3 seconds',
              5000: '5 seconds',
              10000: '10 seconds',
              15000: '15 seconds',
              30000: '30 seconds',
              45000: '45 seconds',
              60000: '60 seconds',
            },
          ),
          IntPickerPreferenceTile(
            preference: UserPreferences.skipForwardLength,
            title: 'Skip Forward Length',
            description:
                'How many seconds to jump forward after pressing the fast '
                'forward button.',
            icon: Icons.fast_forward,
            options: const {
              1000: '1 second',
              3000: '3 seconds',
              5000: '5 seconds',
              10000: '10 seconds',
              15000: '15 seconds',
              30000: '30 seconds',
              45000: '45 seconds',
              60000: '60 seconds',
            },
          ),
        ],
      ),
    );
  }
}

class _AudioPreferencesScreen extends StatelessWidget {
  const _AudioPreferencesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Audio Preferences')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.audioNightMode,
            title: 'Audio Night Mode',
            subtitle: 'Reduce dynamic range for late night listening',
            icon: Icons.nights_stay,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.defaultAudioLanguage,
            title: 'Default Audio Language',
            icon: Icons.language,
            options: const {
              'auto': 'Auto',
              'eng': 'English',
              'spa': 'Spanish',
              'fra': 'French',
              'deu': 'German',
              'ita': 'Italian',
              'por': 'Portuguese',
              'jpn': 'Japanese',
              'kor': 'Korean',
              'zho': 'Chinese',
              'rus': 'Russian',
              'ara': 'Arabic',
              'hin': 'Hindi',
              'nld': 'Dutch',
              'swe': 'Swedish',
              'nor': 'Norwegian',
              'dan': 'Danish',
              'fin': 'Finnish',
              'pol': 'Polish',
            },
          ),
          EnumPreferenceTile<AudioBehavior>(
            preference: UserPreferences.audioBehavior,
            title: 'Audio Behavior',
            icon: Icons.surround_sound,
            labelOf: (v) => switch (v) {
              AudioBehavior.directStream => 'Direct Stream',
              AudioBehavior.downmixToStereo => 'Downmix',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.ac3Enabled,
            title: 'AC3 Passthrough',
            subtitle: 'Bitstream AC3 to external decoder',
            icon: Icons.speaker,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.trueHdEnabled,
            title: 'TrueHD Support',
            subtitle: 'Enable TrueHD/HD audio passthrough',
            icon: Icons.graphic_eq,
          ),
        ],
      ),
    );
  }
}

class _AutomationQueueScreen extends StatelessWidget {
  const _AutomationQueueScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Automation & Queue')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.cinemaModeEnabled,
            title: 'Cinema Mode',
            subtitle: 'Play trailers/prerolls before a main feature',
            icon: Icons.movie_filter,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.mediaQueuingEnabled,
            title: 'Episode Queuing',
            subtitle: 'Automatically queue subsequent episodes',
            icon: Icons.queue,
          ),
          EnumPreferenceTile<NextUpBehavior>(
            preference: UserPreferences.nextUpBehavior,
            title: 'Enable Next Up Prompt',
            description:
                'Extended shows a full card with episode artwork and '
                'description. Minimal shows a compact countdown overlay. '
                'Disabled hides the prompt entirely.',
            icon: Icons.skip_next,
            labelOf: (v) => switch (v) {
              NextUpBehavior.extended => 'Extended',
              NextUpBehavior.minimal => 'Minimal',
              NextUpBehavior.disabled => 'Disabled',
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.nextUpTimeout,
            title: 'Next Up Prompt Timeout',
            icon: Icons.timer,
            min: 0,
            max: 30000,
            divisions: 30,
            labelOf: (v) => '${(v / 1000).toStringAsFixed(1)}s',
          ),
          EnumPreferenceTile<StillWatchingBehavior>(
            preference: UserPreferences.stillWatchingBehavior,
            title: 'Enable Still Watching Prompt',
            icon: Icons.visibility,
            labelOf: (v) => switch (v) {
              StillWatchingBehavior.short_ => 'Short',
              StillWatchingBehavior.medium => 'Medium',
              StillWatchingBehavior.long_ => 'Long',
              StillWatchingBehavior.veryLong => 'Very Long',
              StillWatchingBehavior.disabled => 'Off',
            },
          ),
        ],
      ),
    );
  }
}

class _AdvancedOptionsScreen extends StatefulWidget {
  const _AdvancedOptionsScreen();

  @override
  State<_AdvancedOptionsScreen> createState() =>
      _AdvancedOptionsScreenState();
}

class _AdvancedOptionsScreenState extends State<_AdvancedOptionsScreen> {
  final _advancedScope = FocusScopeNode(
    debugLabel: 'AdvancedOptionsSettingsScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _advancedScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('Advanced Options')),
      body: FocusScope(
        node: _advancedScope,
        autofocus: true,
        child: ListView(
          children: [
            SliderPreferenceTile(
              preference: UserPreferences.videoStartDelay,
              title: 'Video Start Delay',
              icon: Icons.schedule,
              min: 0,
              max: 5000,
              divisions: 20,
              labelOf: (v) => '$v ms',
            ),
            if (!PlatformDetection.isTV && !PlatformDetection.isIOS) ...[
              SwitchPreferenceTile(
                preference: UserPreferences.customMpvConfEnabled,
                title: 'Custom MPV Conf',
                subtitle: 'Use a custom mpv.conf file',
                icon: Icons.tune,
              ),
              _EditableStringPreferenceTile(
                preference: UserPreferences.customMpvConfPath,
                title: 'MPV Conf Path',
                icon: Icons.description,
                hintText: 'Path to custom mpv.conf',
              ),
              SwitchPreferenceTile(
                preference: UserPreferences.customMpvConfUnsafeAdvanced,
                title: 'Unsafe MPV Options',
                subtitle: 'Allow unsafe advanced options in MPV conf',
                icon: Icons.warning_amber,
              ),
            ],
            SwitchPreferenceTile(
              preference: UserPreferences.liveTvDirectPlayEnabled,
              title: 'Live TV Direct',
              subtitle: 'Enable direct play for Live TV',
              icon: Icons.live_tv,
            ),
          ],
        ),
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
  final _syncPlayScope = FocusScopeNode(
    debugLabel: 'SyncPlaySettingsScope',
    traversalEdgeBehavior: TraversalEdgeBehavior.stop,
  );
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
    _syncPlayScope.dispose();
    _minDelaySpeed.dispose();
    _maxDelaySpeed.dispose();
    _speedDuration.dispose();
    _minDelaySkip.dispose();
    _extraOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = PlatformDetection.isTV ? 96.0 : 24.0;
    return Scaffold(
      appBar: buildSettingsAppBar(context, const Text('SyncPlay')),
      body: FocusScope(
        node: _syncPlayScope,
        autofocus: true,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad),
          children: [
            _TvSettingsListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('Open Groups'),
              subtitle: const Text('Create, join, or manage SyncPlay groups'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SyncPlayScreen(),
                ),
              ),
            ),
            const Divider(),
            SwitchPreferenceTile(
              preference: UserPreferences.syncPlayEnabled,
              title: 'SyncPlay Enabled',
              subtitle: 'Enable group watching features',
              icon: Icons.groups,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.showSyncPlayButton,
              title: 'SyncPlay Button',
              subtitle: 'Show the SyncPlay button on the navigation bar',
              icon: Icons.toggle_on,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.syncPlayAdvancedCorrectionEnabled,
              title: 'Advanced Correction',
              subtitle: 'Enable fine-grained sync logic',
              icon: Icons.tune,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.syncPlayEnableSyncCorrection,
              title: 'Sync Correction',
              subtitle: 'Automatically adjust playback to stay in sync',
              icon: Icons.sync,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.syncPlayUseSpeedToSync,
              title: 'Speed to Sync',
              subtitle: 'Use playback speed adjustment to sync',
              icon: Icons.speed,
            ),
            SwitchPreferenceTile(
              preference: UserPreferences.syncPlayUseSkipToSync,
              title: 'Skip to Sync',
              subtitle: 'Use seeking to sync',
              icon: Icons.skip_next,
            ),
            _DoubleSliderTile(
              title: 'Minimum Speed Delay',
              icon: Icons.timer,
              binding: _minDelaySpeed,
              min: 0,
              max: 5000,
            ),
            _DoubleSliderTile(
              title: 'Maximum Speed Delay',
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
              title: 'Minimum Skip Delay',
              icon: Icons.timer,
              binding: _minDelaySkip,
              min: 0,
              max: 15000,
            ),
            _DoubleSliderTile(
              title: 'SyncPlay Extra Offset',
              icon: Icons.schedule,
              binding: _extraOffset,
              min: -2000,
              max: 2000,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableStringPreferenceTile extends StatefulWidget {
  final Preference<String> preference;
  final String title;
  final IconData icon;
  final String hintText;

  const _EditableStringPreferenceTile({
    required this.preference,
    required this.title,
    required this.icon,
    required this.hintText,
  });

  @override
  State<_EditableStringPreferenceTile> createState() =>
      _EditableStringPreferenceTileState();
}

class _EditableStringPreferenceTileState extends State<_EditableStringPreferenceTile> {
  late final PreferenceBinding<String> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _binding,
      builder: (_, value, _) => _TvSettingsListTile(
        leading: Icon(widget.icon),
        title: Text(widget.title),
        subtitle: Text(_displaySubtitle(value)),
        onTap: () => _showEditor(context, value),
      ),
    );
  }

  String _displaySubtitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Not set';
    return trimmed;
  }

  Future<void> _showEditor(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final next = await showFocusRestoringDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: widget.hintText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (next == null) return;
    _binding.value = next;
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
  late final FocusNode _outerFocusNode;
  late final FocusNode _sliderInternalNode;
  bool _outerFocused = false;

  double get _step {
    final s = (widget.max - widget.min) / 40;
    return s <= 0 ? 1 : s;
  }

  @override
  void initState() {
    super.initState();
    _outerFocusNode = FocusNode(debugLabel: 'DoubleSliderOuter_${widget.title}');
    _sliderInternalNode = FocusNode(
      debugLabel: 'DoubleSliderInner_${widget.title}',
      canRequestFocus: false,
      skipTraversal: true,
    );
  }

  @override
  void dispose() {
    _outerFocusNode.dispose();
    _sliderInternalNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      node.previousFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      node.nextFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      final delta = key == LogicalKeyboardKey.arrowLeft ? -_step : _step;
      final current = widget.binding.value;
      final next = (current + delta).clamp(widget.min, widget.max);
      if (next != current) {
        widget.binding.value = next;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _outerFocusNode,
      onKeyEvent: _onKeyEvent,
      onFocusChange: (focused) {
        if (focused) {
          _ensureSettingsTileVisible(context);
        }
        if (_outerFocused != focused && mounted) {
          setState(() => _outerFocused = focused);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _outerFocused ? Colors.white : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTileTheme.merge(
          textColor: _outerFocused ? Colors.black87 : Colors.white,
          iconColor: _outerFocused ? Colors.black54 : Colors.white70,
          titleTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          subtitleTextStyle: const TextStyle(fontSize: 12),
          child: ValueListenableBuilder<double>(
            valueListenable: widget.binding,
            builder: (_, value, _) => ListTile(
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              leading: Icon(widget.icon),
              title: Text(widget.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${value.round()} ms',
                    style: TextStyle(
                      color: _outerFocused ? Colors.black54 : Colors.white70,
                    ),
                  ),
                  Slider(
                    focusNode: _sliderInternalNode,
                    value: value.clamp(widget.min, widget.max),
                    min: widget.min,
                    max: widget.max,
                    divisions: 40,
                    onChanged: (v) => widget.binding.value = v,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavbarColorPickerTile extends StatefulWidget {
  final VoidCallback? onChanged;

  const _NavbarColorPickerTile({this.onChanged});

  @override
  State<_NavbarColorPickerTile> createState() => _NavbarColorPickerTileState();
}

class _NavbarColorPickerTileState extends State<_NavbarColorPickerTile> {
  static const _labels = <String, String>{
    'gray': 'Gray',
    'black': 'Black',
    'dark_blue': 'Dark Blue',
    'purple': 'Purple',
    'teal': 'Teal',
    'navy': 'Navy',
    'charcoal': 'Charcoal',
    'brown': 'Brown',
    'dark_red': 'Dark Red',
    'dark_green': 'Dark Green',
    'slate': 'Slate',
    'indigo': 'Indigo',
  };

  static const _swatches = <String, int>{
    'gray': 0xFF6B7280,
    'black': 0xFF111827,
    'dark_blue': 0xFF1E3A8A,
    'purple': 0xFF6D28D9,
    'teal': 0xFF0F766E,
    'navy': 0xFF1E293B,
    'charcoal': 0xFF374151,
    'brown': 0xFF7C4A2D,
    'dark_red': 0xFF7F1D1D,
    'dark_green': 0xFF14532D,
    'slate': 0xFF334155,
    'indigo': 0xFF4338CA,
  };

  late final PreferenceBinding<String> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      UserPreferences.navbarColor,
    );
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  Color _swatchColor(String key) => Color(_swatches[key] ?? 0xFF6B7280);

  Color _swatchBorder(Color color) =>
      color.computeLuminance() > 0.8 ? Colors.black38 : Colors.white24;

  String _labelFor(String key) => _labels[key] ?? _formatCamelCaseLabel(key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _binding,
      builder: (context, value, _) => _TvSettingsListTile(
        leading: const Icon(Icons.palette),
        title: const Text('Navbar Color'),
        subtitle: Text(_labelFor(value)),
        trailing: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _swatchColor(value),
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              ThemeRegistry.active.borders.chipBorder.copyWith(
                color: _swatchBorder(_swatchColor(value)),
              ),
            ),
          ),
        ),
        onTap: () => _showPicker(context, value),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, String current) async {
    final entries = _labels.entries.toList();
    final selectedIndex = entries.indexWhere((e) => e.key == current);
    final autofocusIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final result = await showFocusRestoringDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
          if (event is KeyDownEvent) {
            return KeyEventResult.handled;
          }
          if (event is KeyUpEvent) {
            Navigator.pop(ctx);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SimpleDialog(
          title: const Text('Navbar Color'),
          children: entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final selected = e.key == current;
            final swatch = _swatchColor(e.key);
            return TvFocusHighlight(
              builder: (_, _) => ListTile(
                autofocus: i == autofocusIndex,
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      ThemeRegistry.active.borders.chipBorder.copyWith(
                        color: _swatchBorder(swatch),
                      ),
                    ),
                  ),
                ),
                title: Text(e.value),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (!mounted || result == null || result == _binding.value) return;
    _binding.value = result;
    widget.onChanged?.call();
  }
}

class _ShuffleContentTypePickerTile extends StatefulWidget {
  final VoidCallback? onChanged;

  const _ShuffleContentTypePickerTile({this.onChanged});

  @override
  State<_ShuffleContentTypePickerTile> createState() =>
      _ShuffleContentTypePickerTileState();
}

class _ShuffleContentTypePickerTileState
    extends State<_ShuffleContentTypePickerTile> {
  static const _labels = <String, String>{
    'movies': 'Movies',
    'tvshows': 'TV Shows',
    'both': 'Both',
  };
  static const _fallbackKey = 'both';

  late final PreferenceBinding<String> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      UserPreferences.shuffleContentType,
    );
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  String _normalize(String key) => _labels.containsKey(key) ? key : _fallbackKey;

  String _label(String key) => _labels[_normalize(key)] ?? 'Both';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _binding,
      builder: (context, value, _) {
        final normalized = _normalize(value);
        if (normalized != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _binding.value == normalized) return;
            _binding.value = normalized;
            widget.onChanged?.call();
          });
        }
        return _TvSettingsListTile(
          leading: const Icon(Icons.shuffle),
          title: const Text('Shuffle Content Type Filter'),
          subtitle: Text(_label(normalized)),
          onTap: () => _showPicker(context, normalized),
        );
      },
    );
  }

  Future<void> _showPicker(BuildContext context, String current) async {
    final entries = _labels.entries.toList();
    final normalizedCurrent = _normalize(current);
    final selectedIndex = entries.indexWhere((e) => e.key == normalizedCurrent);
    final autofocusIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final result = await showFocusRestoringDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        var closed = false;
        void closeOnce() {
          if (closed) return;
          closed = true;
          Navigator.pop(ctx);
        }
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, event) {
            if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
            if (event is KeyDownEvent || event is KeyUpEvent) {
              closeOnce();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: FocusScope(
            autofocus: true,
            child: SimpleDialog(
              title: const Text('Shuffle Content Type Filter'),
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final selected = e.key == normalizedCurrent;
                return TvFocusHighlight(
                  builder: (_, _) => ListTile(
                    autofocus: i == autofocusIndex,
                    title: Text(e.value),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(ctx, e.key),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null || result == _binding.value) return;
    _binding.value = result;
    widget.onChanged?.call();
  }
}
