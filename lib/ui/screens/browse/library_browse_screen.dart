import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/mdblist_repository.dart';
import '../../../data/services/background_service.dart';
import '../../../data/viewmodels/library_browse_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';
import '../../widgets/rating_display.dart';

const _navyBackground = Color(0xFF101528);
const _jellyfinBlue = Color(0xFF00A4DC);
const _horizontalPadding = 60.0;
const _kCompactBreakpoint = 600.0;

bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile ||
    MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

class LibraryBrowseScreen extends StatefulWidget {
  final String libraryId;
  final String? genreId;
  final String? genreName;
  final List<String>? includeItemTypes;

  const LibraryBrowseScreen({
    super.key,
    required this.libraryId,
    this.genreId,
    this.genreName,
    this.includeItemTypes,
  });

  @override
  State<LibraryBrowseScreen> createState() => _LibraryBrowseScreenState();
}

class _LibraryBrowseScreenState extends State<LibraryBrowseScreen> {
  late final LibraryBrowseViewModel _vm;
  final _scrollController = ScrollController();
  final _prefs = GetIt.instance<UserPreferences>();
  final _backgroundService = GetIt.instance<BackgroundService>();
  StreamSubscription<String?>? _backgroundSub;
  String? _backdropUrl;

  @override
  void initState() {
    super.initState();
    _vm = LibraryBrowseViewModel(
      libraryId: widget.libraryId,
      client: GetIt.instance<MediaServerClient>(),
      prefs: _prefs,
      mdbListRepository: GetIt.instance<MdbListRepository>(),
      genreId: widget.genreId,
      overrideName: widget.genreName,
      includeItemTypes: widget.includeItemTypes,
    );
    _vm.addListener(_onChanged);
    _vm.load();
    _scrollController.addListener(_onScroll);
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;
    _prefs.addListener(_onChanged);
  }

  @override
  void dispose() {
    _backgroundSub?.cancel();
    _scrollController.dispose();
    _vm.removeListener(_onChanged);
    _prefs.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 600) {
      _vm.loadMore();
    }
  }

  void _onItemFocused(AggregatedItem item) {
    _vm.setFocusedItem(item);
    _backgroundService.setBackground(item, context: BlurContext.browsing);
  }

  void _onItemTap(AggregatedItem item) {
    if (_vm.isNavigableFolder(item)) {
      context.push(Destinations.folder(item.id));
      return;
    }

    context
        .push(
          Destinations.itemOrPhoto(
            item.id,
            serverId: item.serverId,
            type: item.type,
          ),
        )
        .then((result) {
          if (result == true && mounted) {
            _vm.load();
          }
        });
  }

  double _cardWidth() {
    if (_vm.isMusicBrowse || _vm.isPlaylistBrowse) {
      return _vm.posterSize.portraitHeight.toDouble();
    }
    final posterSize = _vm.posterSize;
    return switch (_vm.imageType) {
      ImageType.thumb => posterSize.landscapeHeight * (16 / 9),
      ImageType.banner => posterSize.landscapeHeight * (16 / 9),
      ImageType.poster => posterSize.portraitHeight * (2 / 3),
    };
  }

  double _selectedImageAspectRatio() {
    return switch (_vm.imageType) {
      ImageType.thumb => 16 / 9,
      ImageType.banner => 16 / 9,
      ImageType.poster => 2 / 3,
    };
  }

  double _gridBaseAspectRatio() {
    if (_vm.isMusicBrowse || _vm.isPlaylistBrowse) return 1.0;
    if (_vm.isGenreBrowse) return _selectedImageAspectRatio();
    if (_vm.imageType != ImageType.poster &&
        _vm.items.isNotEmpty &&
        _vm.items.every(_vm.isNavigableFolder)) {
      return 16 / 9;
    }
    return switch (_vm.imageType) {
      ImageType.thumb => 16 / 9,
      ImageType.banner => 16 / 9,
      ImageType.poster => 2 / 3,
    };
  }

  double _itemAspectRatio(AggregatedItem item) {
    if (_vm.isMusicBrowse || _vm.isPlaylistBrowse) return 1.0;
    if (_vm.isGenreBrowse) return _selectedImageAspectRatio();
    if (_vm.isNavigableFolder(item) && _vm.imageType != ImageType.poster) {
      return 16 / 9;
    }
    return switch (_vm.imageType) {
      ImageType.thumb => switch (item.type) {
        'MusicAlbum' ||
        'MusicArtist' ||
        'Audio' ||
        'Playlist' ||
        'Person' => 1.0,
        _ => 16 / 9,
      },
      ImageType.banner => 16 / 9,
      ImageType.poster => MediaCard.aspectRatioForType(item.type),
    };
  }

  bool _prefersThumbArtwork(AggregatedItem item) {
    return switch (item.type) {
      'Episode' || 'Program' || 'Recording' || 'Video' || 'MusicVideo' => true,
      _ => false,
    };
  }

  String? _tagForType(AggregatedItem item, String imageType) {
    final tags = item.rawData['ImageTags'];
    if (tags is! Map) return null;
    return tags[imageType] as String?;
  }

  String? _imageUrl(AggregatedItem item) {
    final api = _vm.imageApi;

    final itemThumbTag = _tagForType(item, 'Thumb');
    final itemBannerTag = _tagForType(item, 'Banner');
    final parentThumbItemId = item.rawData['ParentThumbItemId'] as String?;
    final parentThumbTag = item.rawData['ParentThumbImageTag'] as String?;
    final prefersThumbArtwork = _prefersThumbArtwork(item);

    if (_vm.isNavigableFolder(item)) {
      if (_vm.imageType == ImageType.poster) {
        if (item.primaryImageTag != null) {
          return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
        }
        if (itemThumbTag != null) {
          return api.getThumbImageUrl(item.id, tag: itemThumbTag);
        }
        if (item.backdropImageTags.isNotEmpty) {
          return api.getBackdropImageUrl(
            item.id,
            tag: item.backdropImageTags.first,
          );
        }
        return null;
      }
      if (itemThumbTag != null) {
        return api.getThumbImageUrl(item.id, tag: itemThumbTag);
      }
      if (itemBannerTag != null) {
        return api.getBannerImageUrl(item.id, tag: itemBannerTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      if (item.primaryImageTag != null) {
        return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return api.getThumbImageUrl(parentThumbItemId, tag: parentThumbTag);
      }
      return null;
    }

    if (_vm.isPlaylistBrowse) {
      return item.primaryImageTag != null
          ? api.getPrimaryImageUrl(item.id)
          : null;
    }

    if (_vm.imageType == ImageType.banner) {
      if (itemBannerTag != null) {
        return api.getBannerImageUrl(item.id, tag: itemBannerTag);
      }
      if (item.primaryImageTag != null) {
        return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      return null;
    }

    if (_vm.imageType == ImageType.thumb) {
      if (itemThumbTag != null) {
        return api.getThumbImageUrl(item.id, tag: itemThumbTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return api.getThumbImageUrl(parentThumbItemId, tag: parentThumbTag);
      }
      if (item.parentBackdropItemId != null &&
          item.parentBackdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.parentBackdropItemId!,
          tag: item.parentBackdropImageTags.first,
        );
      }
      if (item.primaryImageTag != null) {
        return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
      }
      return null;
    }

    if (prefersThumbArtwork && !_vm.isGenreBrowse) {
      if (itemThumbTag != null) {
        return api.getThumbImageUrl(item.id, tag: itemThumbTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return api.getThumbImageUrl(parentThumbItemId, tag: parentThumbTag);
      }
    }

    if (item.primaryImageTag != null) {
      return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
    }

    if (item.seriesId != null && item.seriesPrimaryImageTag != null) {
      return api.getPrimaryImageUrl(
        item.seriesId!,
        tag: item.seriesPrimaryImageTag,
      );
    }

    if (itemThumbTag != null) {
      return api.getThumbImageUrl(item.id, tag: itemThumbTag);
    }

    if (item.backdropImageTags.isNotEmpty) {
      return api.getBackdropImageUrl(
        item.id,
        tag: item.backdropImageTags.first,
      );
    }

    return null;
  }

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
              _LibraryHeader(
                libraryName: _vm.libraryName,
                totalCount: _vm.totalCount,
                focusedItem: _vm.focusedItem,
                focusedRatings: _vm.focusedRatings,
                enableAdditionalRatings: _prefs.get(
                  UserPreferences.enableAdditionalRatings,
                ),
                enabledRatings: _prefs.get(UserPreferences.enabledRatings),
                blockedRatings: _prefs.get(UserPreferences.blockedRatings),
                showLabels: _prefs.get(UserPreferences.showRatingLabels),
                showBadges: _prefs.get(UserPreferences.showRatingBadges),
                sortBy: _vm.sortBy,
                letterFilter: _vm.letterFilter,
                isMusicBrowse: _vm.isMusicBrowse,
                onBack: () => context.pop(),
                onSort: () => _showFilterSortDialog(context),
                onSettings: () => _showSettingsDialog(context),
                onLetterChanged: (l) => _vm.setLetterFilter(l),
              ),
              Expanded(child: _buildBody()),
              _LibraryStatusBar(
                statusText: _vm.statusText,
                counterText: _vm.counterText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_vm.state) {
      LibraryBrowseState.loading => const Center(
        child: CircularProgressIndicator(color: _jellyfinBlue),
      ),
      LibraryBrowseState.error => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _vm.errorMessage ?? 'Failed to load library',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _vm.load, child: const Text('Retry')),
          ],
        ),
      ),
      LibraryBrowseState.ready => _buildGrid(),
    };
  }

  Widget _buildGrid() {
    if (_vm.items.isEmpty) {
      return const Center(
        child: Text('No items found', style: TextStyle(color: Colors.white70)),
      );
    }

    final cardWidth = _cardWidth();
    const spacing = 12.0;
    final watchedBehavior = _prefs.get(
      UserPreferences.watchedIndicatorBehavior,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = _isCompact(context);
        final gridPadding = isMobile ? 16.0 : _horizontalPadding;
        final crossAxisCount =
            ((constraints.maxWidth - gridPadding * 2 + spacing) /
                    (cardWidth + spacing))
                .floor()
                .clamp(2, 20);

        final cellWidth =
            (constraints.maxWidth -
                gridPadding * 2 -
                (crossAxisCount - 1) * spacing) /
            crossAxisCount;
        final ar = _gridBaseAspectRatio();
        final hasSubtitles = _vm.items.any(
          (item) => (_cardSubtitle(item)?.isNotEmpty ?? false),
        );
        final textHeight = hasSubtitles ? 38.0 : 22.0;
        final childAspectRatio = cellWidth / (cellWidth / ar + textHeight);

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gridPadding, 20, gridPadding, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _vm.items[index];
                  final itemAspectRatio = _itemAspectRatio(item);
                  final focusColor = Color(
                    _prefs.get(UserPreferences.focusColor).colorValue,
                  );
                  return MediaCard(
                    title: item.name,
                    subtitle: _cardSubtitle(item),
                    imageUrl: _imageUrl(item),
                    width: double.infinity,
                    aspectRatio: itemAspectRatio,
                    focusColor: focusColor,
                    cardFocusExpansion: _prefs.get(
                      UserPreferences.cardFocusExpansion,
                    ),
                    isPlayed: item.isPlayed,
                    isFavorite: item.isFavorite,
                    unplayedCount: item.unplayedItemCount,
                    playedPercentage: item.playedPercentage,
                    watchedBehavior: watchedBehavior,
                    itemType: item.type,
                    onFocus: isMobile ? null : () => _onItemFocused(item),
                    onHoverStart: isMobile ? null : () => _onItemFocused(item),
                    onHoverEnd: isMobile
                        ? null
                        : () => _vm.setFocusedItem(null),
                    onLongPress: isMobile ? null : () => _onItemFocused(item),
                    onTap: () => _onItemTap(item),
                  );
                }, childCount: _vm.items.length),
              ),
            ),
            if (_vm.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: _jellyfinBlue),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String? _cardSubtitle(AggregatedItem item) {
    final parts = <String>[];
    if (_vm.isNavigableFolder(item)) {
      if (item.childCount != null) {
        parts.add('${item.childCount} items');
      }
      return parts.isEmpty ? 'Folder' : parts.join('  ');
    }

    if (item.productionYear != null) parts.add('${item.productionYear}');
    if (item.officialRating != null) parts.add(item.officialRating!);
    final rt = item.runtime;
    if (rt != null) {
      final h = rt.inHours;
      final m = rt.inMinutes % 60;
      if (h > 0) {
        parts.add('${h}h ${m}m');
      } else {
        parts.add('${m}m');
      }
    }
    if (item.communityRating != null) {
      parts.add('★ ${item.communityRating!.toStringAsFixed(1)}');
    }
    return parts.isEmpty ? null : parts.join('  ');
  }

  void _showFilterSortDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => _FilterSortDialog(vm: _vm),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => _SettingsDialog(vm: _vm),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final String libraryName;
  final int totalCount;
  final AggregatedItem? focusedItem;
  final Map<String, double> focusedRatings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;
  final bool showBadges;
  final LibrarySortBy sortBy;
  final String letterFilter;
  final bool isMusicBrowse;
  final VoidCallback onBack;
  final VoidCallback onSort;
  final VoidCallback onSettings;
  final ValueChanged<String> onLetterChanged;

  const _LibraryHeader({
    required this.libraryName,
    required this.totalCount,
    this.focusedItem,
    this.focusedRatings = const {},
    this.enableAdditionalRatings = false,
    this.enabledRatings = 'tomatoes,stars',
    this.blockedRatings = '',
    this.showLabels = true,
    this.showBadges = true,
    required this.sortBy,
    required this.letterFilter,
    this.isMusicBrowse = false,
    required this.onBack,
    required this.onSort,
    required this.onSettings,
    required this.onLetterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isMobile && isLandscape;
    final isCompactPortrait = isMobile && !isLandscape;
    final showInlineAlpha =
        sortBy == LibrarySortBy.name && (!isMobile || isCompactLandscape);
    final showBelowAlpha = sortBy == LibrarySortBy.name && isCompactPortrait;
    final topPad = isMobile ? MediaQuery.of(context).padding.top + 8 : 12.0;
    final hPad = isMobile ? 16.0 : _horizontalPadding;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                libraryName,
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
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(height: 6),
            _FocusedItemHud(
              item: focusedItem,
              ratings: focusedRatings,
              enableAdditionalRatings: enableAdditionalRatings,
              enabledRatings: enabledRatings,
              blockedRatings: blockedRatings,
              showLabels: showLabels,
              showBadges: showBadges,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: (isMobile && !showInlineAlpha)
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              _ToolbarButton(icon: Icons.arrow_back, onTap: onBack),
              const SizedBox(width: 4),
              _ToolbarButton(icon: Icons.sort, onTap: onSort),
              if (!isMusicBrowse) ...[
                const SizedBox(width: 4),
                _ToolbarButton(icon: Icons.settings, onTap: onSettings),
              ],
              if (showInlineAlpha) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _AlphaPickerBar(
                    selected: letterFilter,
                    onChanged: onLetterChanged,
                  ),
                ),
              ],
            ],
          ),
          if (showBelowAlpha) ...[
            const SizedBox(height: 8),
            _AlphaPickerBar(selected: letterFilter, onChanged: onLetterChanged),
          ],
        ],
      ),
    );
  }
}

class _FocusedItemHud extends StatelessWidget {
  final AggregatedItem? item;
  final Map<String, double> ratings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;
  final bool showBadges;

  const _FocusedItemHud({
    this.item,
    this.ratings = const {},
    this.enableAdditionalRatings = false,
    this.enabledRatings = 'tomatoes,stars',
    this.blockedRatings = '',
    this.showLabels = true,
    this.showBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    final hudHeight = showLabels ? 96.0 : 80.0;
    return SizedBox(
      height: hudHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: item == null
            ? const SizedBox.shrink(key: ValueKey('empty'))
            : Column(
                key: ValueKey(item!.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _MetadataRow(item: item!),
                  const SizedBox(height: 4),
                  RatingsRow(
                    ratings: ratings,
                    communityRating: item!.communityRating,
                    criticRating: item!.criticRating,
                    enableAdditionalRatings: enableAdditionalRatings,
                    enabledRatings: enabledRatings,
                    blockedRatings: blockedRatings,
                    showLabels: showLabels,
                    showBadges: showBadges,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final AggregatedItem item;

  const _MetadataRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (item.productionYear != null) {
      children.add(_infoText('${item.productionYear}'));
    }

    if (item.type != 'Series') {
      final rt = item.runtime;
      if (rt != null) {
        final h = rt.inHours;
        final m = rt.inMinutes % 60;
        final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
        children.add(_infoText(timeStr));
      }
    }

    if (item.type == 'Series' && item.status != null) {
      final continuing = item.status == 'Continuing';
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: continuing
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            continuing ? 'Continuing' : 'Ended',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (item.officialRating != null) {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.officialRating!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _infoText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withAlpha(179),
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.onTap});

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final focusColor = Color(
      GetIt.instance<UserPreferences>()
          .get(UserPreferences.focusColor)
          .colorValue,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (f) => setFocused(f),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: focused ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: showFocusBorder
                  ? Border.all(color: focusColor, width: 1.5)
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 28,
              color: focused ? Colors.black : Colors.white.withAlpha(128),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlphaPickerBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _AlphaPickerBar({required this.selected, required this.onChanged});

  static const _letters = [
    '',
    '#',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _letters.map((letter) {
          final isSelected = selected == letter;
          return _AlphaLetterButton(
            label: letter.isEmpty ? 'All' : letter,
            isSelected: isSelected,
            onTap: () => onChanged(letter),
          );
        }).toList(),
      ),
    );
  }
}

class _AlphaLetterButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlphaLetterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AlphaLetterButton> createState() => _AlphaLetterButtonState();
}

class _AlphaLetterButtonState extends State<_AlphaLetterButton>
    with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final focusColor = Color(
      GetIt.instance<UserPreferences>()
          .get(UserPreferences.focusColor)
          .colorValue,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (f) => setFocused(f),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSelected ? Colors.white.withAlpha(26) : null,
              borderRadius: BorderRadius.circular(4),
              border: showFocusBorder
                  ? Border.all(color: focusColor, width: 1.5)
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: widget.isSelected
                    ? _jellyfinBlue
                    : Colors.white.withAlpha(140),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryStatusBar extends StatelessWidget {
  final String statusText;
  final String counterText;

  const _LibraryStatusBar({
    required this.statusText,
    required this.counterText,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = _isCompact(context) ? 16.0 : _horizontalPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            statusText,
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(77)),
          ),
          Text(
            counterText,
            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(115)),
          ),
        ],
      ),
    );
  }
}

class _FilterSortDialog extends StatefulWidget {
  final LibraryBrowseViewModel vm;

  const _FilterSortDialog({required this.vm});

  @override
  State<_FilterSortDialog> createState() => _FilterSortDialogState();
}

class _FilterSortDialogState extends State<_FilterSortDialog> {
  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final dialogWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      280.0,
      380.0,
    );
    return Dialog(
      backgroundColor: const Color(0xE6141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withAlpha(26)),
      ),
      child: SizedBox(
        width: dialogWidth,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Sort & Filter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            _sectionHeader('Sort By'),
            for (final option in LibrarySortBy.values)
              _radioTile(
                label: option.displayName,
                selected: vm.sortBy == option,
                trailing: vm.sortBy == option
                    ? IconButton(
                        icon: Icon(
                          vm.sortDirection == SortDirection.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: _jellyfinBlue,
                          size: 18,
                        ),
                        onPressed: () => vm.toggleSortDirection(),
                      )
                    : null,
                onTap: () {
                  if (vm.sortBy == option) {
                    vm.toggleSortDirection();
                  } else {
                    vm.setSortBy(option);
                  }
                },
              ),
            Divider(color: Colors.white.withAlpha(20)),
            _sectionHeader('Filters'),
            _checkboxTile(
              label: 'Favorites',
              checked: vm.favoriteFilter,
              onTap: () => vm.setFavoriteFilter(!vm.favoriteFilter),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            _sectionHeader('Played Status'),
            for (final status in PlayedStatusFilter.values)
              _radioTile(
                label: switch (status) {
                  PlayedStatusFilter.all => 'All',
                  PlayedStatusFilter.watched => 'Watched',
                  PlayedStatusFilter.unwatched => 'Unwatched',
                },
                selected: vm.playedFilter == status,
                onTap: () => vm.setPlayedFilter(status),
              ),
            if (vm.isSeriesLibrary) ...[
              Divider(color: Colors.white.withAlpha(20)),
              _sectionHeader('Series Status'),
              for (final status in SeriesStatusFilter.values)
                _radioTile(
                  label: switch (status) {
                    SeriesStatusFilter.all => 'All',
                    SeriesStatusFilter.continuing => 'Continuing',
                    SeriesStatusFilter.ended => 'Ended',
                  },
                  selected: vm.seriesFilter == status,
                  onTap: () => vm.setSeriesFilter(status),
                ),
            ],
            if (vm.isGenreBrowse && vm.libraries.isNotEmpty) ...[
              Divider(color: Colors.white.withAlpha(20)),
              _sectionHeader('Library'),
              _radioTile(
                label: 'All Libraries',
                selected: vm.libraryFilter == null,
                onTap: () => vm.setLibraryFilter(null),
              ),
              for (final lib in vm.libraries)
                _radioTile(
                  label: lib['Name'] as String? ?? '',
                  selected: vm.libraryFilter == lib['Id'],
                  onTap: () => vm.setLibraryFilter(lib['Id'] as String),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withAlpha(115),
        ),
      ),
    );
  }

  Widget _radioTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _jellyfinBlue : Colors.white.withAlpha(128),
                  width: 2,
                ),
                color: selected ? _jellyfinBlue : Colors.transparent,
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: selected ? Colors.white : Colors.white.withAlpha(179),
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _checkboxTile({
    required String label,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked ? _jellyfinBlue : Colors.white.withAlpha(128),
                  width: 2,
                ),
                color: checked ? _jellyfinBlue : Colors.transparent,
              ),
              child: checked
                  ? const Center(
                      child: Text(
                        '✓',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: checked ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  final LibraryBrowseViewModel vm;

  const _SettingsDialog({required this.vm});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final dialogWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      280.0,
      340.0,
    );
    return Dialog(
      backgroundColor: const Color(0xE6141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withAlpha(26)),
      ),
      child: SizedBox(
        width: dialogWidth,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Display',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            if (!vm.isPlaylistBrowse) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Text(
                  'Image Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(115),
                  ),
                ),
              ),
              for (final type in ImageType.values) _settingsRadioTile(vm, type),
              Divider(color: Colors.white.withAlpha(20)),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                'Poster Size',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(115),
                ),
              ),
            ),
            for (final size in PosterSize.values)
              _posterSizeRadioTile(vm, size),
          ],
        ),
      ),
    );
  }

  Widget _settingsRadioTile(LibraryBrowseViewModel vm, ImageType type) {
    final selected = vm.imageType == type;
    return InkWell(
      onTap: () => vm.setImageType(type),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _radioCircle(selected),
            const SizedBox(width: 12),
            Text(
              type.name[0].toUpperCase() + type.name.substring(1),
              style: TextStyle(
                fontSize: 15,
                color: selected ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterSizeRadioTile(LibraryBrowseViewModel vm, PosterSize size) {
    final selected = vm.posterSize == size;
    final label = switch (size) {
      PosterSize.small => 'Small',
      PosterSize.medium => 'Medium',
      PosterSize.large => 'Large',
      PosterSize.extraLarge => 'Extra Large',
    };
    return InkWell(
      onTap: () => vm.setPosterSize(size),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _radioCircle(selected),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: selected ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _jellyfinBlue : Colors.white.withAlpha(128),
          width: 2,
        ),
        color: selected ? _jellyfinBlue : Colors.transparent,
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
