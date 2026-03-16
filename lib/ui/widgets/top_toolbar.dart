import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../auth/repositories/user_repository.dart';
import '../../data/models/aggregated_library.dart';
import '../../data/repositories/user_views_repository.dart';
import '../../preference/preference_constants.dart';
import '../../preference/seerr_preferences.dart';
import '../../preference/user_preferences.dart';
import '../../util/platform_detection.dart';
import '../navigation/destinations.dart';
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

  void _onPrefsChanged() {
    if (mounted) setState(() {});
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
      final viewsRepo = GetIt.instance<UserViewsRepository>();
      final libs = await viewsRepo.getUserViews();
      if (mounted) setState(() => _libraries = libs);
    } catch (_) {}
  }

  bool _isActive(String route) => widget.activeRoute == route;

  @override
  Widget build(BuildContext context) {
    final isTV = PlatformDetection.useLeanbackUi;
    final isMobile = PlatformDetection.useMobileUi;
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
            child: Row(
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.popOrHome(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.9),
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00A4DC), Color(0xFF0077B6)],
              ),
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

    int order = 1;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
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
                  label: 'Home',
                  isActive: _isActive(Destinations.home),
                  onPressed: () => context.go(Destinations.home),
                ),
              ),
              _gap(),
              _orderButton(
                order: (order++).toDouble(),
                child: ExpandableIconButton(
                  icon: Icons.search_rounded,
                  label: 'Search',
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
                    label: 'Shuffle',
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
                    icon: Icons.theater_comedy_rounded,
                    label: 'Genres',
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
                    label: 'Favorites',
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
                    label: 'Folders',
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
                    label: 'SyncPlay',
                    onPressed: () {},
                  ),
                ),
              ],
              if (_prefs.get(UserPreferences.seerrEnabled)) ...[
                _gap(),
                _orderButton(
                  order: (order++).toDouble(),
                  child: Builder(builder: (context) {
                    final seerrPrefs = GetIt.instance<SeerrPreferences>();
                    final isSeerr = seerrPrefs.moonfinVariant == 'seerr';
                    final label = seerrPrefs.moonfinDisplayName.isNotEmpty
                        ? seerrPrefs.moonfinDisplayName
                        : (isSeerr ? 'Seerr' : 'Jellyseerr');
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
                  label: 'Settings',
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
  final ValueChanged<AggregatedLibrary> onLibraryTap;

  const _LibrariesDropdown({
    required this.libraries,
    required this.onLibraryTap,
  });

  @override
  State<_LibrariesDropdown> createState() => _LibrariesDropdownState();
}

class _LibrariesDropdownState extends State<_LibrariesDropdown> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _buttonHovered = false;
  bool _dropdownHovered = false;
  Timer? _hideTimer;

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
    return CompositedTransformFollower(
      link: _layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: Offset.zero,
      child: Align(
        alignment: Alignment.topLeft,
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
                  constraints: const BoxConstraints(minWidth: 180),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
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
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          icon: Icons.video_library_rounded,
          label: 'Libraries',
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          child: Text(
            widget.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
