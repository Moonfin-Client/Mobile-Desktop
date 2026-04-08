import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../../data/services/background_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/genre_grid_card.dart';
import '../../widgets/poster_size_settings_dialog.dart';
import '../../../l10n/app_localizations.dart';

const _navyBackground = Color(0xFF101528);
const _jellyfinBlue = Color(0xFF00A4DC);
const _horizontalPadding = 60.0;
const _kCompactBreakpoint = 600.0;

bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile ||
    MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

class AllGenresScreen extends StatefulWidget {
  const AllGenresScreen({super.key});

  @override
  State<AllGenresScreen> createState() => _AllGenresScreenState();
}

class _AllGenresScreenState extends State<AllGenresScreen> {
  final _client = GetIt.instance<MediaServerClient>();
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _prefs = GetIt.instance<UserPreferences>();
  StreamSubscription<String?>? _backgroundSub;
  String? _backdropUrl;
  bool _disposed = false;

  ImageType get _imageType => _prefs.get(UserPreferences.allGenresImageType);

  List<GenreCardData> _genres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    _backgroundSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await _client.itemsApi.getGenres(
        sortBy: 'SortName',
        sortOrder: 'Ascending',
      );

      final items = (response['Items'] as List?) ?? [];
      _genres = items.map((g) {
        final data = g as Map<String, dynamic>;
        return GenreCardData(
          id: data['Id'] as String,
          name: data['Name'] as String? ?? '',
          itemCount:
              data['ChildCount'] as int? ??
              (data['MovieCount'] as int? ?? 0) +
                  (data['SeriesCount'] as int? ?? 0) +
                  (data['AlbumCount'] as int? ?? 0),
        );
      }).toList();
    } catch (_) {}

    _isLoading = false;
    if (!_disposed && mounted) setState(() {});

    _loadGenreArtwork();
  }

  Future<void> _loadGenreArtwork() async {
    await Future.wait(_genres.map(_loadGenreItems));

    final before = _genres.length;
    _genres.removeWhere((g) => g.itemCount == 0);
    if (!_disposed && mounted && _genres.length != before) setState(() {});
  }

  Future<void> _loadGenreItems(GenreCardData genre) async {
    if (_disposed) return;
    try {
      final response = await _client.itemsApi.getItems(
        genreIds: [genre.id],
        includeItemTypes: ['Movie', 'Series'],
        sortBy: 'Random',
        sortOrder: 'Ascending',
        recursive: true,
        limit: 10,
        fields: 'PrimaryImageTag,ImageTags,BackdropImageTags',
      );
      final totalCount = response['TotalRecordCount'] as int? ?? 0;
      genre.itemCount = totalCount;

      final items = (response['Items'] as List?) ?? [];
      String? imageUrl;
      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final backdropUrl = _backdropUrlFor(item);
        genre.backdropUrl ??= backdropUrl;
        imageUrl ??= _imageUrlFor(item, _imageType, backdropUrl: backdropUrl);
        if (imageUrl != null && genre.backdropUrl != null) {
          break;
        }
      }
      genre.imageUrl = imageUrl ?? genre.backdropUrl;
      if (!_disposed && mounted) setState(() {});
    } catch (_) {}
  }

  String? _tagForType(Map<String, dynamic> item, String imageType) {
    final tags = item['ImageTags'];
    if (tags is! Map) return null;
    return tags[imageType] as String?;
  }

  String? _backdropUrlFor(Map<String, dynamic> item) {
    final tags = (item['BackdropImageTags'] as List?) ?? const [];
    if (tags.isEmpty) {
      return null;
    }
    return _client.imageApi.getBackdropImageUrl(
      item['Id'] as String,
      maxWidth: BackgroundService.backdropMaxWidth,
      tag: tags.first as String,
    );
  }

  String? _imageUrlFor(
    Map<String, dynamic> item,
    ImageType imageType, {
    String? backdropUrl,
  }) {
    final itemId = item['Id'] as String;
    final primaryTag = item['PrimaryImageTag'] as String?;
    final thumbTag = _tagForType(item, 'Thumb');
    final bannerTag = _tagForType(item, 'Banner');
    final resolvedBackdropUrl = backdropUrl ?? _backdropUrlFor(item);

    return switch (imageType) {
      ImageType.poster =>
        primaryTag != null
            ? _client.imageApi.getPrimaryImageUrl(itemId, tag: primaryTag)
            : resolvedBackdropUrl ??
                  (thumbTag != null
                      ? _client.imageApi.getThumbImageUrl(itemId, tag: thumbTag)
                      : null),
      ImageType.thumb =>
        thumbTag != null
            ? _client.imageApi.getThumbImageUrl(itemId, tag: thumbTag)
            : resolvedBackdropUrl ??
                  (primaryTag != null
                      ? _client.imageApi.getPrimaryImageUrl(
                          itemId,
                          tag: primaryTag,
                        )
                      : null),
      ImageType.banner =>
        bannerTag != null
            ? _client.imageApi.getBannerImageUrl(itemId, tag: bannerTag)
            : resolvedBackdropUrl ??
                  (primaryTag != null
                      ? _client.imageApi.getPrimaryImageUrl(
                          itemId,
                          tag: primaryTag,
                        )
                      : null),
    };
  }

  double _cardWidth() {
    final posterSize = _prefs.get(UserPreferences.posterSize);
    return switch (_imageType) {
      ImageType.thumb => posterSize.landscapeHeight * (16 / 9),
      ImageType.banner => posterSize.landscapeHeight * (16 / 9),
      ImageType.poster => posterSize.portraitHeight * (2 / 3),
    };
  }

  double _cardAspectRatio() {
    return switch (_imageType) {
      ImageType.thumb => 16 / 9,
      ImageType.banner => 16 / 9,
      ImageType.poster => 2 / 3,
    };
  }

  Future<void> _showSettingsDialog() async {
    final previousPosterSize = _prefs.get(UserPreferences.posterSize);
    final previousImageType = _imageType;
    await showDialog(
      context: context,
      builder: (_) => PosterSizeSettingsDialog(
        prefs: _prefs,
        imageTypePreference: UserPreferences.allGenresImageType,
      ),
    );

    if (!mounted) {
      return;
    }

    if (previousImageType != _imageType) {
      for (final genre in _genres) {
        genre.imageUrl = null;
      }
      await _loadGenreArtwork();
    }

    if (previousPosterSize != _prefs.get(UserPreferences.posterSize) ||
        previousImageType != _imageType) {
      setState(() {});
    }
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
              color: _navyBackground.withAlpha(hasBackdrop ? 140 : 191),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16.0 : _horizontalPadding,
                  isMobile ? MediaQuery.of(context).padding.top + 8 : 20.0,
                  isMobile ? 16.0 : _horizontalPadding,
                  8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.home,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: () => context.go(Destinations.home),
                      tooltip: AppLocalizations.of(context).home,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: () => _showSettingsDialog(),
                      tooltip: AppLocalizations.of(context).displaySettings,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).allGenres,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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

    if (_genres.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noGenresFound, style: const TextStyle(color: Colors.white70)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = _isCompact(context);
        final hPad = isMobile ? 16.0 : _horizontalPadding;
        const spacing = 16.0;
        final minColumns = isMobile ? 1 : 2;
        final maxColumns = isMobile ? 4 : 8;
        final crossAxisCount =
            ((constraints.maxWidth - hPad * 2 + spacing) /
                    (_cardWidth() + spacing))
                .floor()
                .clamp(minColumns, maxColumns);

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: _cardAspectRatio(),
          ),
          itemCount: _genres.length,
          itemBuilder: (context, index) {
            final genre = _genres[index];
            return GenreGridCard(
              genre: genre,
              focusColor: Color(
                _prefs.get(UserPreferences.focusColor).colorValue,
              ),
              cardFocusExpansion: _prefs.get(
                UserPreferences.cardFocusExpansion,
              ),
              onTap: () => context.push(
                Destinations.genre(genre.name, genreId: genre.id),
              ),
              onHover: isMobile
                  ? null
                  : (hovering) {
                      final backgroundUrl = genre.backdropUrl ?? genre.imageUrl;
                      if (hovering && backgroundUrl != null) {
                        _backgroundService.setBackgroundUrl(backgroundUrl);
                      }
                    },
            );
          },
        );
      },
    );
  }
}
