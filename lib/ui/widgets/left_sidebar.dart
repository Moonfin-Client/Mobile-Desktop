import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../auth/repositories/user_repository.dart';
import '../../data/models/aggregated_library.dart';
import '../../data/repositories/multi_server_repository.dart';
import '../../data/repositories/user_views_repository.dart';
import '../../data/services/plugin_sync_service.dart';
import '../../preference/preference_constants.dart';
import '../../preference/seerr_preferences.dart';
import '../../preference/user_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../util/platform_detection.dart';
import '../navigation/destinations.dart';
import '../navigation/home_refresh_bus.dart';
import 'seerr_icons.dart';
import 'shuffle_options_dialog.dart';
import 'user_menu_dialog.dart';

const _kExpandedWidthDesktop = 240.0;
const _kExpandedWidthMobile = 260.0;
const _kExpandDuration = Duration(milliseconds: 200);
const _kAccent = Color(0xFF00A4DC);

class LeftSidebar extends StatefulWidget {
  final String? activeRoute;
  final FocusNode? contentFocusNode;
  final bool showBackButton;

  const LeftSidebar({super.key, this.activeRoute, this.contentFocusNode, this.showBackButton = false});

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
  final _userRepo = GetIt.instance<UserRepository>();
  final _prefs = GetIt.instance<UserPreferences>();
  final _sidebarFocus = FocusScopeNode(debugLabel: 'LeftSidebar');
  final _scrollController = ScrollController();

  List<AggregatedLibrary> _libraries = [];
  bool _isExpanded = false;
  bool _showLabels = false;
  bool _librariesExpanded = false;
  Timer? _clockTimer;
  Timer? _labelTimer;
  String _currentTime = '';
  StreamSubscription? _userSub;
  String? _userImageUrl;

  bool get _isMobile => PlatformDetection.useMobileUi;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
    _loadUserImage();
    _userSub = _userRepo.currentUserStream.listen((_) => _loadUserImage());
    _prefs.addListener(_onPrefsChanged);
    _loadLibraries();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _labelTimer?.cancel();
    _sidebarFocus.dispose();
    _scrollController.dispose();
    _userSub?.cancel();
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    _loadLibraries();
    setState(() {});
  }

  void _updateClock() {
    final now = DateTime.now();
    final use24 = _prefs.get(UserPreferences.use24HourClock);
    final minute = now.minute.toString().padLeft(2, '0');
    if (use24) {
      final hour = now.hour.toString().padLeft(2, '0');
      if (mounted) setState(() => _currentTime = '$hour:$minute');
    } else {
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final period = now.hour >= 12 ? 'PM' : 'AM';
      if (mounted) setState(() => _currentTime = '$hour:$minute $period');
    }
  }

  void _loadUserImage() {
    final user = _userRepo.currentUser;
    if (user == null) {
      setState(() => _userImageUrl = null);
      return;
    }
    try {
      final client = GetIt.instance<MediaServerClient>();
      setState(() => _userImageUrl = client.imageApi.getUserImageUrl(user.id));
    } catch (_) {
      setState(() => _userImageUrl = null);
    }
  }

  Future<void> _loadLibraries() async {
    try {
      final libs = _prefs.get(UserPreferences.enableMultiServerLibraries)
          ? await GetIt.instance<MultiServerRepository>().getAggregatedLibraries()
          : await GetIt.instance<UserViewsRepository>().getUserViews();
      if (mounted) setState(() => _libraries = libs);
    } catch (_) {}
  }

  Color _overlayColor() {
    final colorName = _prefs.get(UserPreferences.navbarColor);
    return switch (colorName) {
      'black' => Colors.black,
      'gray' => Colors.grey,
      'dark_blue' => const Color(0xFF1A2332),
      'purple' => const Color(0xFF4A148C),
      'teal' => const Color(0xFF00695C),
      'navy' => const Color(0xFF0D1B2A),
      'charcoal' => const Color(0xFF36454F),
      'brown' => const Color(0xFF3E2723),
      'dark_red' => const Color(0xFF8B0000),
      'dark_green' => const Color(0xFF0B4F0F),
      'slate' => const Color(0xFF475569),
      'indigo' => const Color(0xFF1E3A8A),
      _ => Colors.grey,
    };
  }

  double _overlayOpacity() {
    return _prefs.get(UserPreferences.navbarOpacity) / 100.0;
  }

  void _expand() {
    if (_isExpanded) return;
    setState(() => _isExpanded = true);
    _labelTimer?.cancel();
    _labelTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showLabels = true);
    });
  }

  void _collapse() {
    if (!_isExpanded) return;
    _labelTimer?.cancel();
    setState(() {
      _isExpanded = false;
      _showLabels = false;
      _librariesExpanded = false;
    });
  }

  void _toggle() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _onSidebarFocusChange(bool hasFocus) {
    if (hasFocus) {
      _expand();
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _collapse();
      widget.contentFocusNode?.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _isActive(String route) => widget.activeRoute == route;

  @override
  Widget build(BuildContext context) {
    return _buildDrawerLayout();
  }

  Widget _buildDrawerLayout() {
    final expandedWidth = _isMobile ? _kExpandedWidthMobile : _kExpandedWidthDesktop;
    return Stack(
      children: [
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _collapse,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        AnimatedPositioned(
          duration: _kExpandDuration,
          curve: Curves.easeInOut,
          left: _isExpanded ? 0 : -expandedWidth,
          top: 0,
          bottom: 0,
          width: expandedWidth,
          child: FocusScope(
            node: _sidebarFocus,
            onFocusChange: _onSidebarFocusChange,
            onKeyEvent: _onKeyEvent,
            child: Container(
              decoration: BoxDecoration(
                gradient: _isMobile
                    ? null
                    : LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _overlayColor().withValues(alpha: _overlayOpacity()),
                          _overlayColor().withValues(alpha: _overlayOpacity() * 0.75),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.7, 1.0],
                      ),
                color: _isMobile ? _overlayColor().withValues(alpha: _overlayOpacity()) : null,
                boxShadow: _isExpanded
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(4, 0))]
                    : null,
              ),
              child: _isMobile
                  ? SafeArea(right: false, child: _buildContent())
                  : _buildContent(),
            ),
          ),
        ),
        if (!_isExpanded)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _toggle,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu,
                          size: 22,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    if (widget.showBackButton) ...[
                      const SizedBox(width: 6),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.popOrHome(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    final showShuffle = _prefs.get(UserPreferences.showShuffleButton);
    final showGenres = _prefs.get(UserPreferences.showGenresButton);
    final showFavorites = _prefs.get(UserPreferences.showFavoritesButton);
    final showLibraries = _prefs.get(UserPreferences.showLibrariesInToolbar);
    final showFolders = _prefs.get(UserPreferences.enableFolderView);
    final showSyncPlay = _prefs.get(UserPreferences.syncPlayEnabled);
    final clockBehavior = _prefs.get(UserPreferences.clockBehavior);
    final showClock = clockBehavior == ClockBehavior.always ||
        clockBehavior == ClockBehavior.inMenus;

    return Column(
      children: [
        _buildUserSection(),
        _buildSeparator(),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              _SidebarItem(
                icon: Icons.home_rounded,
                label: l10n.home,
                showLabel: _showLabels,
                isActive: _isActive(Destinations.home),
                onPressed: () {
                  _onNavigate();
                  if (_isActive(Destinations.home)) {
                    requestHomeRefresh();
                    return;
                  }
                  requestHomeRefreshAfterNavigation();
                  context.go(Destinations.home);
                },
              ),
              _SidebarItem(
                icon: Icons.search_rounded,
                label: l10n.search,
                showLabel: _showLabels,
                isActive: _isActive(Destinations.search),
                onPressed: () { _onNavigate(); context.push(Destinations.search); },
              ),
              if (showShuffle)
                _SidebarItem(
                  icon: Icons.shuffle_rounded,
                  label: l10n.shuffle,
                  showLabel: _showLabels,
                  onPressed: () {
                    _onNavigate();
                    _shuffleRandom(context);
                  },
                  onLongPress: () {
                    _onNavigate();
                    showShuffleDialog(context);
                  },
                ),
              if (showGenres)
                _SidebarItem(
                  iconBuilder: (size, color) => Image.asset(
                    'assets/icons/genres.png',
                    width: size,
                    height: size,
                    color: color,
                  ),
                  label: l10n.genres,
                  showLabel: _showLabels,
                  isActive: _isActive(Destinations.allGenres),
                  onPressed: () { _onNavigate(); context.push(Destinations.allGenres); },
                ),
              if (showFavorites)
                _SidebarItem(
                  icon: Icons.favorite_rounded,
                  label: l10n.favorites,
                  showLabel: _showLabels,
                  isActive: _isActive(Destinations.allFavorites),
                  onPressed: () { _onNavigate(); context.push(Destinations.allFavorites); },
                ),
              if (showFolders)
                _SidebarItem(
                  icon: Icons.folder_rounded,
                  label: l10n.folders,
                  showLabel: _showLabels,
                  isActive: _isActive(Destinations.folderView),
                  onPressed: () { _onNavigate(); context.push(Destinations.folderView); },
                ),
              if (showSyncPlay)
                _SidebarItem(
                  icon: Icons.groups_rounded,
                  label: l10n.syncPlay,
                  showLabel: _showLabels,
                  onPressed: () {},
                ),
              if (GetIt.instance<PluginSyncService>().pluginAvailable &&
                  _prefs.get(UserPreferences.seerrEnabled))
                Builder(builder: (context) {
                  final seerrPrefs = GetIt.instance<SeerrPreferences>();
                  final isSeerr = seerrPrefs.isSeerrVariant;
                  final label = seerrPrefs.moonfinDisplayName.isNotEmpty
                      ? seerrPrefs.moonfinDisplayName
                      : (isSeerr ? l10n.seerr : l10n.jellyseerr);
                  return _SidebarItem(
                    iconBuilder: (size, color) => isSeerr
                        ? SeerrIcon(size: size, color: color)
                        : JellyseerrIcon(size: size, color: color),
                    label: label,
                    showLabel: _showLabels,
                    isActive: _isActive(Destinations.seerrDiscover),
                    onPressed: () { _onNavigate(); context.push(Destinations.seerrDiscover); },
                  );
                }),
              if (showLibraries && _libraries.isNotEmpty) ...[
                _buildSeparator(),
                _SidebarItem(
                  iconBuilder: (size, color) => Image.asset(
                    'assets/icons/clapperboard.png',
                    width: size,
                    height: size,
                    color: color,
                    fit: BoxFit.contain,
                  ),
                  label: l10n.libraries,
                  showLabel: _showLabels,
                  isActive: _librariesExpanded,
                  trailing: _showLabels
                      ? AnimatedRotation(
                          turns: _librariesExpanded ? 0.5 : 0,
                          duration: _kExpandDuration,
                          child: Icon(Icons.expand_more, size: 16,
                              color: Colors.white.withValues(alpha: 0.5)),
                        )
                      : null,
                  onPressed: () => setState(() => _librariesExpanded = !_librariesExpanded),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _librariesExpanded
                      ? Column(
                          children: _libraries
                              .map((lib) => _SidebarLibraryItem(
                                    label: lib.name,
                                    showLabel: _showLabels,
                                    onPressed: () {
                                      _onNavigate();
                                      if (lib.collectionType == 'music') {
                                        context.push('/music/${lib.id}');
                                      } else if (lib.collectionType == 'livetv') {
                                        context.push(Destinations.liveTvGuide);
                                      } else {
                                        context.push('/library/${lib.id}');
                                      }
                                    },
                                  ))
                              .toList(),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
        _buildSeparator(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _SidebarItem(
            icon: Icons.settings_rounded,
            label: l10n.settings,
            showLabel: _showLabels,
            isActive: _isActive(Destinations.settings),
            onPressed: () { _onNavigate(); context.push(Destinations.settings); },
          ),
        ),
        if (showClock && _showLabels)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _currentTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(height: showClock && _showLabels ? 8 : 16),
      ],
    );
  }

  void _onNavigate() {
    if (_isMobile) _collapse();
  }

  Future<void> _shuffleRandom(BuildContext context) async {
    final contentType = _prefs.get(UserPreferences.shuffleContentType);
    await fetchRandomAndNavigate(context, contentType: contentType);
  }

  Widget _buildUserSection() {
    final user = _userRepo.currentUser;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '?';
    final fallback = Center(
      child: Text(initial,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: GestureDetector(
        onTap: () { _onNavigate(); showUserMenu(context); },
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00A4DC), Color(0xFF0077B6)],
                  ),
                ),
                child: ClipOval(
                  child: _userImageUrl != null
                      ? Image.network(
                          _userImageUrl!,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (_, __, ___) => fallback,
                        )
                      : fallback,
                ),
              ),
              if (_showLabels) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user?.name ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData? icon;
  final Widget Function(double size, Color color)? iconBuilder;
  final String label;
  final bool showLabel;
  final bool isActive;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const _SidebarItem({
    this.icon,
    this.iconBuilder,
    required this.label,
    required this.showLabel,
    this.isActive = false,
    required this.onPressed,
    this.onLongPress,
    this.trailing,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  final _prefs = GetIt.instance<UserPreferences>();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _isFocused || _isHovered;
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);
    final fgColor = widget.isActive
        ? _kAccent
        : highlighted
            ? focusColor
            : Colors.white.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              widget.onPressed();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: widget.onPressed,
            onLongPress: widget.onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: highlighted
                    ? focusColor.withValues(alpha: 0.12)
                    : widget.isActive
                        ? _kAccent.withValues(alpha: 0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: widget.iconBuilder?.call(24, fgColor) ?? Icon(widget.icon, size: 24, color: fgColor),
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLibraryItem extends StatefulWidget {
  final String label;
  final bool showLabel;
  final VoidCallback onPressed;

  const _SidebarLibraryItem({
    required this.label,
    required this.showLabel,
    required this.onPressed,
  });

  @override
  State<_SidebarLibraryItem> createState() => _SidebarLibraryItemState();
}

class _SidebarLibraryItemState extends State<_SidebarLibraryItem> {
  final _prefs = GetIt.instance<UserPreferences>();
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            padding: const EdgeInsets.only(left: 50, right: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? focusColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: widget.showLabel
                ? Text(
                    widget.label,
                    style: TextStyle(
                      color: _isHovered
                          ? focusColor
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
