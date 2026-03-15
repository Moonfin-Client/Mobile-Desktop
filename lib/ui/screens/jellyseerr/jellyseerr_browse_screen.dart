import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/viewmodels/seerr_browse_view_model.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';

const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';

class JellyseerrBrowseScreen extends StatefulWidget {
  final String? filterId;
  final String? filterName;
  final String? mediaType;
  final String? filterType;

  const JellyseerrBrowseScreen({
    super.key,
    this.filterId,
    this.filterName,
    this.mediaType,
    this.filterType,
  });

  @override
  State<JellyseerrBrowseScreen> createState() =>
      _JellyseerrBrowseScreenState();
}

class _JellyseerrBrowseScreenState extends State<JellyseerrBrowseScreen> {
  SeerrBrowseViewModel? _vm;
  bool _initializing = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _init();
  }

  Future<void> _init() async {
    final repo = await GetIt.instance.getAsync<SeerrRepository>();
    final vm = SeerrBrowseViewModel(
      repo,
      filterId: widget.filterId,
      mediaType: widget.mediaType ?? 'movie',
      filterType: widget.filterType,
    );
    vm.addListener(_onChanged);

    if (!mounted) {
      vm.dispose();
      return;
    }

    setState(() {
      _vm = vm;
      _initializing = false;
    });

    vm.load();
  }

  void _onScroll() {
    final vm = _vm;
    if (vm == null) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      vm.loadMore();
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onChanged);
    _vm?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final vm = _vm;
    if (_initializing || vm == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final s = vm.state;

    if (s.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (s.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildContent(s);
  }

  Widget _buildContent(SeerrBrowseState s) {
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPad + 8),
        _buildHeader(s),
        _buildFilterBar(s),
        Expanded(child: _buildGrid(s)),
      ],
    );
  }

  Widget _buildHeader(SeerrBrowseState s) {
    final title = widget.filterName ?? 'Browse';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildSortDropdown(s),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(SeerrBrowseState s) {
    return PopupMenuButton<SeerrSortOption>(
      initialValue: s.sortBy,
      onSelected: (opt) => _vm?.setSortBy(opt),
      itemBuilder: (_) => seerrSortOptions
          .map((opt) => PopupMenuItem(
                value: opt,
                child: Text(opt.label),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.sortBy.label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(SeerrBrowseState s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _filterChip('All', SeerrBrowseFilter.all, s.filter),
          const SizedBox(width: 8),
          _filterChip('Available', SeerrBrowseFilter.available, s.filter),
          const SizedBox(width: 8),
          _filterChip('Requested', SeerrBrowseFilter.requested, s.filter),
        ],
      ),
    );
  }

  Widget _filterChip(
      String label, SeerrBrowseFilter value, SeerrBrowseFilter current) {
    final selected = value == current;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.white70)),
      selected: selected,
      onSelected: (_) => _vm?.setFilter(value),
      selectedColor: const Color(0xFF6366F1),
      backgroundColor: Colors.white12,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
    );
  }

  Widget _buildGrid(SeerrBrowseState s) {
    if (s.items.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: Colors.white54)),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 160).floor().clamp(2, 7);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: s.items.length + (s.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= s.items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final item = s.items[index];
        return MediaCard(
          title: item.displayTitle,
          subtitle: _yearFromItem(item),
          imageUrl: item.posterPath != null
              ? '$_tmdbPosterBase${item.posterPath}'
              : null,
          aspectRatio: 2 / 3,
          onTap: () {
            final mt = item.mediaType ?? widget.mediaType ?? 'movie';
            context.push(
              Destinations.jellyseerrMedia(item.id.toString()),
              extra: {'mediaType': mt},
            );
          },
        );
      },
    );
  }

  static String? _yearFromItem(SeerrDiscoverItem item) {
    final date = item.releaseDate ?? item.firstAirDate;
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }
}
