import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../l10n/app_localizations.dart';
import '../../auth/repositories/user_repository.dart';
import '../../data/models/aggregated_library.dart';
import '../../data/repositories/multi_server_repository.dart';
import '../../data/repositories/user_views_repository.dart';
import '../../data/services/plugin_sync_service.dart';
import '../../preference/preference_constants.dart';
import '../../preference/seerr_preferences.dart';
import '../../preference/user_preferences.dart';
import '../../util/platform_detection.dart';
import '../navigation/destinations.dart';
import '../navigation/home_refresh_bus.dart';
import 'expandable_icon_button.dart';
import 'seerr_icons.dart';
import 'shuffle_options_dialog.dart';
import 'user_menu_dialog.dart';

const _kToolbarHeightTV = 95.0;
const _kToolbarHeightDesktop = 80.0;
const _kToolbarHeightMobile = 60.0;
const _kOverscanH = 48.0;
const _kOverscanV = 27.0;
const _kAccent = Color(0xFF00A4DC);
const _kNavbarBackdrop = Color(0x1AFFFFFF);
const _kAvatarSize = 40.0;
const _kPillRadius = 36.0;
const _kButtonSpacing = 12.0;
const _kButtonSpacingMobile = 8.0;

class TopToolbar extends StatefulWidget {
  final String? activeRoute;
  final bool showBackButton;

  const TopToolbar({super.key, this.activeRoute, this.showBackButton = false});

  @override
  State<TopToolbar> createState() => _TopToolbarState();
}

class _TopToolbarState extends State<TopToolbar> {
  final _userRepo = GetIt.instance<UserRepository>();
  final _prefs = GetIt.instance<UserPreferences>();

  final _avatarFocus = FocusNode();
  List<AggregatedLibrary> _libraries = [];
  Timer? _clockTimer;
  String _currentTime = '';
  StreamSubscription? _userSub;
  String? _userImageUrl;

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
    _avatarFocus.dispose();
    _userSub?.cancel();
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
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

  Color _toolbarSurfaceColor() {
    return _overlayColor().withValues(alpha: _overlayOpacity());
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

  bool _isActive(String route) => widget.activeRoute == route;

  @override
  Widget build(BuildContext context) {
    final isTV = PlatformDetection.useLeanbackUi;
    final isMobile = PlatformDetection.useMobileUi;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final hPad = isTV ? _kOverscanH : isMobile ? 12.0 : 32.0;
    final vPad = isTV ? _kOverscanV : isMobile ? 8.0 : 10.0;
    final toolbarHeight = isTV
        ? _kToolbarHeightTV
        : isMobile
            ? _kToolbarHeightMobile
            : _kToolbarHeightDesktop;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: toolbarHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: isLandscape
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildCenter(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStart(),
                      ),
                      if (!isMobile)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildEnd(),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      _buildStart(),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCenter()),
                      if (!isMobile) ...[
                        const SizedBox(width: 12),
                        _buildEnd(),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStart() {
    return FocusTraversalOrder(
      order: const NumericFocusOrder(0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(),
          if (widget.showBackButton) ...[
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.popOrHome(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _toolbarSurfaceColor(),
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
    );
  }

  Widget _buildAvatar() {
    const avatarSize = _kAvatarSize;

    return Focus(
      focusNode: _avatarFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          _showUserMenu();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _showUserMenu,
        child: AnimatedScale(
          scale: _avatarFocus.hasFocus ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: _avatarFocus.hasFocus
                  ? Border.all(color: _kAccent, width: 2)
                  : null,
            ),
            child: ClipOval(
              child: _userImageUrl != null
                  ? Image.network(
                      _userImageUrl!,
                      fit: BoxFit.cover,
                      width: avatarSize,
                      height: avatarSize,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    final user = _userRepo.currentUser;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '?';
    final isMobile = PlatformDetection.useMobileUi;
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _kNavbarBackdrop,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 18 : 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showUserMenu() {
    showUserMenu(context);
  }

  Widget _buildCenter() {
    final showShuffle = _prefs.get(UserPreferences.showShuffleButton);
    final showGenres = _prefs.get(UserPreferences.showGenresButton);
    final showFavorites = _prefs.get(UserPreferences.showFavoritesButton);
    final showLibraries = _prefs.get(UserPreferences.showLibrariesInToolbar);
    final showFolders = _prefs.get(UserPreferences.enableFolderView);
    final showSyncPlay = _prefs.get(UserPreferences.syncPlayEnabled);

    final l10n = AppLocalizations.of(context);
    int order = 1;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _toolbarSurfaceColor(),
          borderRadius: BorderRadius.circular(_kPillRadius),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _orderButton(
                order: (order++).toDouble(),
                child: ExpandableIconButton(
                  icon: Icons.home_rounded,
                  label: l10n.home,
                  isActive: _isActive(Destinations.home),
                  onPressed: () {
                    if (_isActive(Destinations.home)) {
                      requestHomeRefresh();
                      return;
                    }
                    requestHomeRefreshAfterNavigation();
                    context.go(Destinations.home);
                  },
                ),
              ),
              _gap(),
              _orderButton(
                order: (order++).toDouble(),
                child: ExpandableIconButton(
                  icon: Icons.search_rounded,
                  label: l10n.search,
                  isActive: _isActive(Destinations.search),
                  onPressed: () => context.push(Destinations.search),
                ),
              ),
              if (showShuffle) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    icon: Icons.shuffle_rounded,
                    label: l10n.shuffle,
                    onPressed: () => _shuffleRandom(context),
                    onLongPress: () => showShuffleDialog(context),
                  ),
                ),
              ],
              if (showGenres) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    iconBuilder: (size, color) => Image.asset(
                      'assets/icons/genres.png',
                      width: size,
                      height: size,
                      color: color,
                      fit: BoxFit.contain,
                    ),
                    label: l10n.genres,
                    isActive: _isActive(Destinations.allGenres),
                    onPressed: () => context.push(Destinations.allGenres),
                  ),
                ),
              ],
              if (showFavorites) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    icon: Icons.favorite_rounded,
                    label: l10n.favorites,
                    isActive: _isActive(Destinations.allFavorites),
                    onPressed: () => context.push(Destinations.allFavorites),
                  ),
                ),
              ],
              if (showFolders) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    icon: Icons.folder_rounded,
                    label: l10n.folders,
                    isActive: _isActive(Destinations.folderView),
                    onPressed: () => context.push(Destinations.folderView),
                  ),
                ),
              ],
              if (showSyncPlay) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: ExpandableIconButton(
                    icon: Icons.groups_rounded,
                    label: l10n.syncPlay,
                    onPressed: () {},
                  ),
                ),
              ],
              if (GetIt.instance<PluginSyncService>().pluginAvailable &&
                  _prefs.get(UserPreferences.seerrEnabled)) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: Builder(builder: (context) {
                    final seerrPrefs = GetIt.instance<SeerrPreferences>();
                    final isSeerr = seerrPrefs.isSeerrVariant;
                    final label = seerrPrefs.moonfinDisplayName.isNotEmpty
                        ? seerrPrefs.moonfinDisplayName
                        : (isSeerr ? l10n.seerr : l10n.jellyseerr);
                    return ExpandableIconButton(
                      iconBuilder: (size, color) => isSeerr
                          ? SeerrIcon(size: size, color: color)
                          : JellyseerrIcon(size: size, color: color),
                      label: label,
                      isActive: _isActive(Destinations.seerrDiscover),
                      onPressed: () => context.push(Destinations.seerrDiscover),
                    );
                  }),
                ),
              ],
              if (showLibraries && _libraries.isNotEmpty) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: _buildLibrariesButton(),
                ),
              ],
              _gap(),
              _orderButton(
                order: 99,
                child: ExpandableIconButton(
                  icon: Icons.settings_rounded,
                  label: l10n.settings,
                  isActive: _isActive(Destinations.settings),
                  onPressed: () => context.push(Destinations.settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibrariesButton() {
    return _LibrariesDropdown(
      libraries: _libraries,
      surfaceColor: _toolbarSurfaceColor(),
      onLibraryTap: (lib) {
        if (lib.collectionType == 'music') {
          context.push('/music/${lib.id}');
        } else if (lib.collectionType == 'livetv') {
          context.push(Destinations.liveTvGuide);
        } else {
          context.push('/library/${lib.id}');
        }
      },
    );
  }

  Future<void> _shuffleRandom(BuildContext context) async {
    final contentType = _prefs.get(UserPreferences.shuffleContentType);
    await fetchRandomAndNavigate(context, contentType: contentType);
  }

  Widget _buildEnd() {
    final clockBehavior = _prefs.get(UserPreferences.clockBehavior);
    final showClock = clockBehavior == ClockBehavior.always ||
        clockBehavior == ClockBehavior.inMenus;

    if (!showClock) return const SizedBox.shrink();

    return Text(
      _currentTime,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _gap() => SizedBox(
    width: PlatformDetection.useMobileUi ? _kButtonSpacingMobile : _kButtonSpacing,
  );

  Widget _orderButton({required double order, required Widget child}) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }
}

class _LibrariesDropdown extends StatefulWidget {
  final List<AggregatedLibrary> libraries;
  final Color surfaceColor;
  final ValueChanged<AggregatedLibrary> onLibraryTap;

  const _LibrariesDropdown({
    required this.libraries,
    required this.surfaceColor,
    required this.onLibraryTap,
  });

  @override
  State<_LibrariesDropdown> createState() => _LibrariesDropdownState();
}

class _LibrariesDropdownState extends State<_LibrariesDropdown> {
  final _targetKey = GlobalKey();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _buttonHovered = false;
  bool _dropdownHovered = false;
  Timer? _hideTimer;
  bool _openToLeft = false;
  double _menuWidth = 220;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdown() {
    _hideTimer?.cancel();
    if (_overlayEntry != null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    _menuWidth = (screenWidth - 16).clamp(180.0, 280.0);

    final targetBox = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox != null) {
      final targetLeft = targetBox.localToGlobal(Offset.zero).dx;
      final wouldOverflowRight = targetLeft + _menuWidth > screenWidth - 8;
      _openToLeft = wouldOverflowRight;
    } else {
      _openToLeft = false;
    }

    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _hideDropdown() {
    _removeOverlay();
    setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_buttonHovered && !_dropdownHovered) {
        _hideDropdown();
      }
    });
  }

  Widget _buildOverlay(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxMenuHeight = (screenHeight - 120).clamp(220.0, 520.0);

    return CompositedTransformFollower(
      link: _layerLink,
      targetAnchor: _openToLeft ? Alignment.bottomRight : Alignment.bottomLeft,
      followerAnchor: _openToLeft ? Alignment.topRight : Alignment.topLeft,
      offset: Offset.zero,
      child: Align(
        alignment: _openToLeft ? Alignment.topRight : Alignment.topLeft,
        child: MouseRegion(
          onEnter: (_) {
            _dropdownHovered = true;
            _hideTimer?.cancel();
          },
          onExit: (_) {
            _dropdownHovered = false;
            _scheduleHide();
          },
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: 180,
                    maxWidth: _menuWidth,
                    maxHeight: maxMenuHeight,
                  ),
                  decoration: BoxDecoration(
                    color: widget.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      scrollbars: false,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: widget.libraries
                          .map((lib) => _LibraryDropdownItem(
                                name: lib.name,
                                onTap: () {
                                  _hideDropdown();
                                  widget.onLibraryTap(lib);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      key: _targetKey,
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _buttonHovered = true;
          if (PlatformDetection.useDesktopUi) _showDropdown();
        },
        onExit: (_) {
          _buttonHovered = false;
          _scheduleHide();
        },
        child: ExpandableIconButton(
          iconBuilder: (size, color) => Image.asset(
            'assets/icons/clapperboard.png',
            width: size,
            height: size,
            color: color,
            fit: BoxFit.contain,
          ),
          label: AppLocalizations.of(context).libraries,
          isActive: _overlayEntry != null,
          onPressed: () {
            if (_overlayEntry != null) {
              _hideDropdown();
            } else {
              _showDropdown();
            }
          },
        ),
      ),
    );
  }
}

class _LibraryDropdownItem extends StatefulWidget {
  final String name;
  final VoidCallback onTap;

  const _LibraryDropdownItem({
    required this.name,
    required this.onTap,
  });

  @override
  State<_LibraryDropdownItem> createState() => _LibraryDropdownItemState();
}

class _LibraryDropdownItemState extends State<_LibraryDropdownItem> {
  final _prefs = GetIt.instance<UserPreferences>();
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: _isHovered
              ? focusColor.withValues(alpha: 0.12)
              : Colors.transparent,
          child: Text(
            widget.name,
            style: TextStyle(
              color: _isHovered ? focusColor : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
