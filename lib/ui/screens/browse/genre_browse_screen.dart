import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/services/background_service.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';
import '../../widgets/poster_size_settings_dialog.dart';

const _navyBackground = Color(0xFF101528);
const _jellyfinBlue = Color(0xFF00A4DC);
const _horizontalPadding = 60.0;
const _pageSize = 100;
const _kCompactBreakpoint = 600.0;

bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile || MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

class GenreBrowseScreen extends StatefulWidget {
  final String genreName;
  final String genreId;
  final String? parentId;
  final String? includeType;

  const GenreBrowseScreen({
    super.key,
    required this.genreName,
    required this.genreId,
    this.parentId,
    this.includeType,
  });

  @override
  State<GenreBrowseScreen> createState() => _GenreBrowseScreenState();
}

class _GenreBrowseScreenState extends State<GenreBrowseScreen> {
  final _client = GetIt.instance<MediaServerClient>();
  final _prefs = GetIt.instance<UserPreferences>();
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _scrollController = ScrollController();
  StreamSubscription<String?>? _backgroundSub;
  String? _backdropUrl;

  List<AggregatedItem> _items = [];
  int _totalCount = 0;
  bool _isLoading = true;
  bool _loadingMore = false;

  List<Map<String, dynamic>> _libraries = [];
  String? _selectedLibraryId;

  bool get _hasMore => _items.length < _totalCount;

  @override
  void initState() {
    super.initState();
    _selectedLibraryId = widget.parentId;
    _scrollController.addListener(_onScroll);
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;
    _loadLibraries();
    _load();
  }

  @override
  void dispose() {
    _backgroundSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<void> _loadLibraries() async {
    try {
      final response = await _client.userViewsApi.getUserViews();
      final items = (response['Items'] as List?) ?? [];
      _libraries = items
          .cast<Map<String, dynamic>>()
          .where((lib) {
            final type = lib['CollectionType'] as String?;
            return type == 'movies' || type == 'tvshows' || type == null;
          })
          .toList();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _load() async {
    _isLoading = true;
    if (mounted) setState(() {});

    try {
      await _fetchPage(0);
    } catch (e) {
      debugPrint('Failed to load genre items: $e');
    }

    _isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    if (mounted) setState(() {});

    try {
      await _fetchPage(_items.length);
    } catch (_) {}

    _loadingMore = false;
    if (mounted) setState(() {});
  }

  Future<void> _fetchPage(int startIndex) async {
    final response = await _client.itemsApi.getItems(
      parentId: _selectedLibraryId,
      genreIds: [widget.genreId],
      includeItemTypes:
          widget.includeType != null ? [widget.includeType!] : ['Movie', 'Series'],
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      recursive: true,
      startIndex: startIndex,
      limit: _pageSize,
      fields:
          'PrimaryImageAspectRatio,BasicSyncInfo,Overview,Genres,CommunityRating,'
          'OfficialRating,RunTimeTicks,ProductionYear,Status,ImageTags,'
          'BackdropImageTags',
    );

    final rawItems = (response['Items'] as List?) ?? [];
    _totalCount = response['TotalRecordCount'] as int? ?? rawItems.length;

    final mapped = rawItems
        .cast<Map<String, dynamic>>()
        .map((raw) => AggregatedItem(
              id: raw['Id'] as String,
              serverId: _client.baseUrl,
              rawData: raw,
            ))
        .toList();

    if (startIndex == 0) {
      _items = mapped;
    } else {
      _items = [..._items, ...mapped];
    }
  }

  void _onItemFocused(AggregatedItem item) {
    _backgroundService.setBackground(item, context: BlurContext.browsing);
  }

  void _onLibraryChanged(String? libraryId) {
    _selectedLibraryId = libraryId;
    _items = [];
    _totalCount = 0;
    setState(() {});
    _load();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => PosterSizeSettingsDialog(
        prefs: _prefs,
        onChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  double _aspectRatio() => switch (widget.includeType) {
    'MusicAlbum' || 'MusicArtist' => 1.0,
    _ => 2 / 3,
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final hasBackdrop = !isMobile && _backdropUrl != null;
    return Scaffold(
      backgroundColor: _navyBackground,
      body: Stack(
        children: [
          if (hasBackdrop)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: BackgroundService.transitionDuration,
                child: CachedNetworkImage(
                  key: ValueKey(_backdropUrl),
                  imageUrl: _backdropUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fadeInDuration: const Duration(milliseconds: 300),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned.fill(
            child: Container(
              color: _navyBackground.withAlpha(hasBackdrop ? 115 : 191),
            ),
          ),
          Column(
            children: [
              _GenreHeader(
                genreName: widget.genreName,
                totalCount: _totalCount,
                libraries: _libraries,
                selectedLibraryId: _selectedLibraryId,
                onLibraryChanged: _onLibraryChanged,
                onSettings: _showSettingsDialog,
                onBack: () => context.pop(),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _jellyfinBlue),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('No items found', style: TextStyle(color: Colors.white70)),
      );
    }

    final ar = _aspectRatio();
    final posterSize = _prefs.get(UserPreferences.posterSize);
    final cardHeight = ar > 1
        ? posterSize.landscapeHeight.toDouble()
        : posterSize.portraitHeight.toDouble();
    final cardWidth = cardHeight * ar;
    final watchedBehavior = _prefs.get(UserPreferences.watchedIndicatorBehavior);
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);
    final cardExpansion = _prefs.get(UserPreferences.cardFocusExpansion);

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = _isCompact(context);
      final gridPadding = isMobile ? 16.0 : _horizontalPadding;
      const spacing = 12.0;
      final crossAxisCount =
          ((constraints.maxWidth - gridPadding * 2 + spacing) /
                  (cardWidth + spacing))
              .floor()
              .clamp(2, 20);

      final cellWidth = (constraints.maxWidth - gridPadding * 2 -
              (crossAxisCount - 1) * spacing) /
          crossAxisCount;
      const titleHeight = 46.0;
      final childAspectRatio = cellWidth / (cellWidth / ar + titleHeight);

      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                gridPadding, 20, gridPadding, 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _items[index];
                  final imageUrl = item.primaryImageTag != null
                      ? _client.imageApi.getPrimaryImageUrl(item.id,
                          maxHeight: (cardHeight * 2).toInt(),
                          tag: item.primaryImageTag)
                      : null;
                  return MediaCard(
                    title: item.name,
                    subtitle: item.subtitle,
                    imageUrl: imageUrl,
                    width: double.infinity,
                    aspectRatio: ar,
                    isPlayed: item.isPlayed,
                    isFavorite: item.isFavorite,
                    unplayedCount: item.unplayedItemCount,
                    playedPercentage: item.playedPercentage,
                    watchedBehavior: watchedBehavior,
                    itemType: item.type,
                    focusColor: focusColor,
                    cardFocusExpansion: cardExpansion,
                    onFocus: isMobile ? null : () => _onItemFocused(item),
                    onHoverStart: isMobile ? null : () => _onItemFocused(item),
                    onTap: () => context.push(Destinations.item(item.id)),
                  );
                },
                childCount: _items.length,
              ),
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: CircularProgressIndicator(color: _jellyfinBlue)),
              ),
            ),
        ],
      );
    });
  }
}

class _GenreHeader extends StatelessWidget {
  final String genreName;
  final int totalCount;
  final List<Map<String, dynamic>> libraries;
  final String? selectedLibraryId;
  final ValueChanged<String?> onLibraryChanged;
  final VoidCallback onSettings;
  final VoidCallback onBack;

  const _GenreHeader({
    required this.genreName,
    required this.totalCount,
    required this.libraries,
    required this.selectedLibraryId,
    required this.onLibraryChanged,
    required this.onSettings,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final topPad = isMobile ? MediaQuery.of(context).padding.top + 8 : 20.0;
    final hPad = isMobile ? 16.0 : _horizontalPadding;

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 22),
              onPressed: onBack,
              tooltip: 'Back',
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                genreName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (totalCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                '$totalCount Items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(102),
                ),
              ),
            ],
            if (libraries.isNotEmpty) ...[
              const SizedBox(width: 8),
              _LibraryDropdown(
                libraries: libraries,
                selectedId: selectedLibraryId,
                onChanged: onLibraryChanged,
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 22),
            onPressed: onBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: 12),
          Text(
            genreName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          if (totalCount > 0) ...[
            const SizedBox(width: 12),
            Text(
              '$totalCount Items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(102),
              ),
            ),
          ],
          const Spacer(),
          if (libraries.isNotEmpty)
            _LibraryDropdown(
              libraries: libraries,
              selectedId: selectedLibraryId,
              onChanged: onLibraryChanged,
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70, size: 22),
            onPressed: onSettings,
            tooltip: 'Display Settings',
          ),
        ],
      ),
    );
  }
}

class _LibraryDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> libraries;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _LibraryDropdown({
    required this.libraries,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId ?? '',
          dropdownColor: const Color(0xFF1A1A2E),
          style: const TextStyle(fontSize: 14, color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          isDense: true,
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('All Libraries'),
            ),
            ...libraries.map((lib) => DropdownMenuItem(
                  value: lib['Id'] as String,
                  child: Text(lib['Name'] as String? ?? ''),
                )),
          ],
          onChanged: (value) => onChanged(
            value == null || value.isEmpty ? null : value,
          ),
        ),
      ),
    );
  }
}
