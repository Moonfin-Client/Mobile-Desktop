import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/viewmodels/seerr_browse_view_model.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';

const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';
const _navyBackground = Color(0xFF101528);
const _seerrAccent = Color(0xFF6366F1);
const _horizontalPadding = 60.0;
const _kCompactBreakpoint = 600.0;

bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile || MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

class SeerrBrowseScreen extends StatefulWidget {
  final String? filterId;
  final String? filterName;
  final String? mediaType;
  final String? filterType;

  const SeerrBrowseScreen({
    super.key,
    this.filterId,
    this.filterName,
    this.mediaType,
    this.filterType,
  });

  @override
  State<SeerrBrowseScreen> createState() => _SeerrBrowseScreenState();
}

class _SeerrBrowseScreenState extends State<SeerrBrowseScreen> {
  SeerrBrowseViewModel? _vm;
  bool _initializing = true;
  final _scrollController = ScrollController();
  SeerrDiscoverItem? _focusedItem;

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
    if (pos.pixels >= pos.maxScrollExtent - 600) {
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
      backgroundColor: _navyBackground,
      body: Column(
        children: [
          _SeerrBrowseHeader(
            title: widget.filterName ?? 'Browse',
            focusedItem: _focusedItem,
            filter: _vm?.state.filter ?? SeerrBrowseFilter.all,
            onFilterChanged: (f) => _vm?.setFilter(f),
            onHome: () => context.go(Destinations.home),
            onSort: () => _showSortDialog(context),
          ),
          Expanded(child: _buildBody()),
          _SeerrBrowseStatusBar(
            filter: _vm?.state.filter ?? SeerrBrowseFilter.all,
            itemCount: _vm?.state.items.length ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final vm = _vm;
    if (_initializing || vm == null || vm.state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _seerrAccent),
      );
    }

    final s = vm.state;

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

    return _buildGrid(s);
  }

  Widget _buildGrid(SeerrBrowseState s) {
    if (s.items.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: Colors.white70)),
      );
    }

    const cardWidth = 150.0;
    const spacing = 12.0;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = _isCompact(context);
      final gridPadding = isMobile ? 16.0 : _horizontalPadding;
      final crossAxisCount =
          ((constraints.maxWidth - gridPadding * 2 + spacing) /
                  (cardWidth + spacing))
              .floor()
              .clamp(2, 20);

      final cellWidth = (constraints.maxWidth - gridPadding * 2 -
              (crossAxisCount - 1) * spacing) /
          crossAxisCount;
      const titleHeight = 46.0;
      final childAspectRatio = cellWidth / (cellWidth / (2 / 3) + titleHeight);

      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gridPadding, 20, gridPadding, 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = s.items[index];
                  return MediaCard(
                    title: item.displayTitle,
                    subtitle: _cardSubtitle(item),
                    imageUrl: item.posterPath != null
                        ? '$_tmdbPosterBase${item.posterPath}'
                        : null,
                    width: double.infinity,
                    aspectRatio: 2 / 3,
                    onFocus: isMobile ? null : () => setState(() => _focusedItem = item),
                    onHoverStart: isMobile ? null : () => setState(() => _focusedItem = item),
                    onHoverEnd: isMobile ? null : () => setState(() => _focusedItem = null),
                    onTap: () {
                      final mt = item.mediaType ?? widget.mediaType ?? 'movie';
                      context.push(
                        Destinations.seerrMedia(item.id.toString()),
                        extra: {'mediaType': mt},
                      );
                    },
                  );
                },
                childCount: s.items.length,
              ),
            ),
          ),
          if (s.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: _seerrAccent),
                ),
              ),
            ),
        ],
      );
    });
  }

  static String? _cardSubtitle(SeerrDiscoverItem item) {
    final parts = <String>[];
    final date = item.releaseDate ?? item.firstAirDate;
    if (date != null && date.length >= 4) parts.add(date.substring(0, 4));
    if (item.voteAverage != null && item.voteAverage! > 0) {
      parts.add('★ ${item.voteAverage!.toStringAsFixed(1)}');
    }
    final status = item.mediaInfo?.status;
    if (status == 4 || status == 5) {
      parts.add('Available');
    } else if (status == 2 || status == 3) {
      parts.add('Requested');
    }
    return parts.isEmpty ? null : parts.join('  ');
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SeerrSortDialog(vm: _vm!),
    );
  }
}

class _SeerrBrowseHeader extends StatelessWidget {
  final String title;
  final SeerrDiscoverItem? focusedItem;
  final SeerrBrowseFilter filter;
  final ValueChanged<SeerrBrowseFilter> onFilterChanged;
  final VoidCallback onHome;
  final VoidCallback onSort;

  const _SeerrBrowseHeader({
    required this.title,
    this.focusedItem,
    required this.filter,
    required this.onFilterChanged,
    required this.onHome,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
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
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(height: 6),
            _FocusedItemHud(item: focusedItem),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _ToolbarButton(icon: Icons.home, onTap: onHome),
              const SizedBox(width: 4),
              _ToolbarButton(icon: Icons.sort, onTap: onSort),
              const SizedBox(width: 16),
              _SeerrFilterChips(filter: filter, onChanged: onFilterChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusedItemHud extends StatelessWidget {
  final SeerrDiscoverItem? item;

  const _FocusedItemHud({this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
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
                    item!.displayTitle,
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
                ],
              ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final SeerrDiscoverItem item;

  const _MetadataRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    final date = item.releaseDate ?? item.firstAirDate;
    if (date != null && date.length >= 4) {
      children.add(_infoText(date.substring(0, 4)));
    }

    if (item.voteAverage != null && item.voteAverage! > 0) {
      children.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
          const SizedBox(width: 2),
          _infoText(item.voteAverage!.toStringAsFixed(1)),
        ],
      ));
    }

    final status = item.mediaInfo?.status;
    if (status == 4 || status == 5) {
      children.add(_statusBadge('Available', const Color(0xFF22C55E)));
    } else if (status == 2 || status == 3) {
      children.add(_statusBadge('Requested', _seerrAccent));
    }

    final mt = item.mediaType;
    if (mt != null) {
      children.add(_infoText(mt == 'tv' ? 'Series' : 'Movie'));
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

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SeerrFilterChips extends StatelessWidget {
  final SeerrBrowseFilter filter;
  final ValueChanged<SeerrBrowseFilter> onChanged;

  const _SeerrFilterChips({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('All', SeerrBrowseFilter.all),
        const SizedBox(width: 6),
        _chip('Available', SeerrBrowseFilter.available),
        const SizedBox(width: 6),
        _chip('Requested', SeerrBrowseFilter.requested),
      ],
    );
  }

  Widget _chip(String label, SeerrBrowseFilter value) {
    final selected = filter == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _seerrAccent : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : Colors.white.withAlpha(179),
          ),
        ),
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

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _focused ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 28,
            color: _focused ? Colors.black : Colors.white.withAlpha(128),
          ),
        ),
      ),
    );
  }
}

class _SeerrBrowseStatusBar extends StatelessWidget {
  final SeerrBrowseFilter filter;
  final int itemCount;

  const _SeerrBrowseStatusBar({
    required this.filter,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = _isCompact(context) ? 16.0 : _horizontalPadding;
    final filterLabel = switch (filter) {
      SeerrBrowseFilter.all => 'All',
      SeerrBrowseFilter.available => 'Available',
      SeerrBrowseFilter.requested => 'Requested',
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            filterLabel,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(77),
            ),
          ),
          Text(
            '$itemCount Items',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(115),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeerrSortDialog extends StatefulWidget {
  final SeerrBrowseViewModel vm;

  const _SeerrSortDialog({required this.vm});

  @override
  State<_SeerrSortDialog> createState() => _SeerrSortDialogState();
}

class _SeerrSortDialogState extends State<_SeerrSortDialog> {
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
    final s = vm.state;
    return Dialog(
      backgroundColor: const Color(0xE6141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withAlpha(26)),
      ),
      child: SizedBox(
        width: 380,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            for (final option in seerrSortOptions)
              _radioTile(
                label: option.label,
                selected: s.sortBy.value == option.value,
                onTap: () {
                  vm.setSortBy(option);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _radioTile({
    required String label,
    required bool selected,
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
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _seerrAccent : Colors.white.withAlpha(128),
                  width: 2,
                ),
                color: selected ? _seerrAccent : Colors.transparent,
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
          ],
        ),
      ),
    );
  }
}
