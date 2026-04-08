import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/search_repository.dart';
import '../../../data/repositories/seerr_repository.dart';
import '../../../data/viewmodels/search_view_model.dart';
import '../../navigation/destinations.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? scopedLibraryId;

  const SearchScreen({super.key, this.initialQuery, this.scopedLibraryId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  late final SearchViewModel _vm;

  static const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';

  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    _vm = SearchViewModel(
      getIt<SearchRepository>(),
      getIt<MediaServerClient>(),
      scopedParentId: widget.scopedLibraryId,
    );
    _vm.addListener(_onViewModelChanged);
    _initSeerr();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _vm.searchImmediate(widget.initialQuery!);
    }
  }

  Future<void> _initSeerr() async {
    try {
      final repo = await GetIt.instance.getAsync<SeerrRepository>();
      await repo.ensureInitialized();
      if (repo.isAvailable && mounted) {
        _vm.setSeerrRepository(repo);
        if (_vm.query.isNotEmpty) {
          _vm.searchImmediate(_vm.query);
        }
      }
    } catch (_) {}
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onViewModelChanged);
    _vm.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _imageUrl(AggregatedItem item) {
    final api = _vm.imageApi;
    final type = item.type;
    if (type == 'Episode' || type == 'Program' || type == 'Recording') {
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(item.id, tag: item.backdropImageTags.first);
      }
      final parentId = item.parentBackdropItemId;
      final parentTags = item.parentBackdropImageTags;
      if (parentId != null && parentTags.isNotEmpty) {
        return api.getBackdropImageUrl(parentId, tag: parentTags.first);
      }
    }
    if (item.primaryImageTag != null) {
      return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
    }
    return null;
  }

  String? _subtitle(AggregatedItem item) {
    if (item.type == 'Audio') return item.albumArtist ?? item.album;
    return item.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    hintText:
                      widget.scopedLibraryId != null &&
                        widget.scopedLibraryId!.isNotEmpty
                      ? l10n.searchThisLibrary
                      : l10n.searchEllipsis,
                    hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              _vm.searchDebounced('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (query) => _vm.searchDebounced(query),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_vm.state) {
      case SearchState.idle:
        return const SizedBox.shrink();
      case SearchState.loading:
        if (_vm.results.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildResults();
      case SearchState.ready when _vm.results.isEmpty && _vm.seerrResults.isEmpty:
        return Center(
          child: Text(
            AppLocalizations.of(context).noResultsForQuery(_vm.query),
            style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 16),
          ),
        );
      case SearchState.ready:
        return _buildResults();
      case SearchState.error:
        return Center(
          child: Text(
            AppLocalizations.of(context).searchFailedError(_vm.errorMessage),
            style: const TextStyle(color: Colors.redAccent),
          ),
        );
    }
  }

  Widget _buildResults() {
    final hasSeerr = _vm.seerrResults.isNotEmpty;
    final totalCount = _vm.results.length + (hasSeerr ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < _vm.results.length) {
          final group = _vm.results[index];
          return LibraryRow(
            title: group.title,
            rowHeight: _rowHeight(group),
            children: group.items.map((item) {
              final ar = MediaCard.aspectRatioForType(item.type);
              final height = ar >= 1 ? 150.0 : 200.0;
              final width = height * ar;
              return MediaCard(
                title: item.name,
                subtitle: _subtitle(item),
                imageUrl: _imageUrl(item),
                width: width,
                aspectRatio: ar,
                isFavorite: item.isFavorite,
                isPlayed: item.isPlayed,
                unplayedCount: item.unplayedItemCount,
                playedPercentage: item.playedPercentage,
                itemType: item.type,
                onTap: () => context.push(Destinations.itemOrPhoto(item.id, serverId: item.serverId, type: item.type)),
              );
            }).toList(),
          );
        }
        return _buildSeerrRow();
      },
    );
  }

  Widget _buildSeerrRow() {
    const height = 200.0;
    const ar = 2.0 / 3.0;
    const width = height * ar;
    return LibraryRow(
      title: AppLocalizations.of(context).seerr,
      rowHeight: height + 56,
      children: _vm.seerrResults.map((item) {
        final year = (item.releaseDate ?? item.firstAirDate);
        final yearStr = (year != null && year.length >= 4) ? year.substring(0, 4) : null;
        return MediaCard(
          title: item.displayTitle,
          subtitle: yearStr,
          imageUrl: item.posterPath != null
              ? '$_tmdbPosterBase${item.posterPath}'
              : null,
          width: width,
          aspectRatio: ar,
          itemType: item.mediaType == 'tv' ? 'Series' : 'Movie',
          onTap: () => context.push(
            Destinations.seerrMedia(item.id.toString()),
            extra: {'mediaType': item.mediaType ?? 'movie'},
          ),
        );
      }).toList(),
    );
  }

  double _rowHeight(SearchResultGroup group) {
    final ar = MediaCard.aspectRatioForType(group.items.first.type);
    return (ar >= 1 ? 150.0 : 200.0) + 56;
  }
}
