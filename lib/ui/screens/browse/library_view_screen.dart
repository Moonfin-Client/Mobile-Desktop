import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/services/background_service.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/viewmodels/library_view_view_model.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_card.dart';
import '../../../l10n/app_localizations.dart';

const _navyBackground = Color(0xFF101528);
const _jellyfinBlue = Color(0xFF00A4DC);
const _horizontalPadding = 60.0;

class LibraryViewScreen extends StatefulWidget {
  final String libraryId;

  const LibraryViewScreen({super.key, required this.libraryId});

  @override
  State<LibraryViewScreen> createState() => _LibraryViewScreenState();
}

class _LibraryViewScreenState extends State<LibraryViewScreen> {
  late final LibraryViewViewModel _vm;
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _prefs = GetIt.instance<UserPreferences>();
  StreamSubscription<String?>? _backgroundSub;
  String? _backdropUrl;

  @override
  void initState() {
    super.initState();
    _vm = LibraryViewViewModel(
      libraryId: widget.libraryId,
      dataSource: GetIt.instance<RowDataSource>(),
      client: GetIt.instance<MediaServerClient>(),
    );
    _vm.addListener(_onChanged);
    _vm.load();
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;
    _prefs.addListener(_onChanged);
  }

  @override
  void dispose() {
    _backgroundSub?.cancel();
    _vm.removeListener(_onChanged);
    _prefs.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onItemFocused(AggregatedItem item) {
    _vm.setFocusedItem(item);
    _backgroundService.setBackground(item, context: BlurContext.browsing);
  }

  @override
  Widget build(BuildContext context) {
    final hasBackdrop = _backdropUrl != null;
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
              _LibraryViewHeader(
                libraryName: _vm.libraryName,
                onHome: () => context.go(Destinations.home),
                onBrowse: () =>
                    context.push(Destinations.library(widget.libraryId)),
                onGenres: () =>
                    context.push(Destinations.libraryGenresOf(widget.libraryId)),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _jellyfinBlue),
      );
    }

    if (_vm.rows.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noItemsFound, style: const TextStyle(color: Colors.white70)),
      );
    }

    final posterSize = _prefs.get(UserPreferences.posterSize);
    final watchedBehavior = _prefs.get(UserPreferences.watchedIndicatorBehavior);
  final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);
    final cardExpansion = _prefs.get(UserPreferences.cardFocusExpansion);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: _vm.rows.length,
      itemBuilder: (context, index) {
        final row = _vm.rows[index];
        return LibraryRow(
          title: row.title,
          children: row.items.map((item) {
            final ar = MediaCard.aspectRatioForType(item.type);
            final height = ar > 1
                ? posterSize.landscapeHeight.toDouble()
                : posterSize.portraitHeight.toDouble();
            final width = height * ar;
            final imageUrl = item.primaryImageTag != null
                ? _vm.imageApi.getPrimaryImageUrl(
                    item.id,
                    maxHeight: (height * 2).toInt(),
                    tag: item.primaryImageTag,
                  )
                : null;
            return MediaCard(
              title: item.name,
              subtitle: item.subtitle,
              imageUrl: imageUrl,
              width: width,
              aspectRatio: ar,
              isFavorite: item.isFavorite,
              isPlayed: item.isPlayed,
              unplayedCount: item.unplayedItemCount,
              playedPercentage: item.playedPercentage,
              watchedBehavior: watchedBehavior,
              itemType: item.type,
              focusColor: focusColor,
              cardFocusExpansion: cardExpansion,
              onFocus: () => _onItemFocused(item),
              onHoverStart: () => _onItemFocused(item),
              onHoverEnd: () => _vm.setFocusedItem(null),
              onTap: () => context.push(Destinations.itemOrPhoto(item.id, serverId: item.serverId, type: item.type)),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LibraryViewHeader extends StatelessWidget {
  final String libraryName;
  final VoidCallback onHome;
  final VoidCallback onBrowse;
  final VoidCallback onGenres;

  const _LibraryViewHeader({
    required this.libraryName,
    required this.onHome,
    required this.onBrowse,
    required this.onGenres,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          _horizontalPadding, 20, _horizontalPadding, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white70, size: 22),
            onPressed: onHome,
            tooltip: AppLocalizations.of(context).home,
          ),
          const SizedBox(width: 12),
          Text(
            libraryName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.grid_view, size: 18),
            label: Text(AppLocalizations.of(context).browseAll),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            onPressed: onBrowse,
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.category, size: 18),
            label: Text(AppLocalizations.of(context).genres),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            onPressed: onGenres,
          ),
        ],
      ),
    );
  }
}
