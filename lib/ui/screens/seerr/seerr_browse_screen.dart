import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/viewmodels/seerr_browse_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';
import '../../../l10n/app_localizations.dart';

const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';
const _navyBackground = Color(0xFF101528);
const _seerrAccent = Color(0xFF6366F1);
const _horizontalPadding = 60.0;
const _kCompactBreakpoint = 600.0;

bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile ||
    MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

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
  final _prefs = GetIt.instance<UserPreferences>();
  SeerrDiscoverItem? _focusedItem;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _prefs.addListener(_onChanged);
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
    _prefs.removeListener(_onChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _navyBackground,
      body: Column(
        children: [
          _SeerrBrowseHeader(
            title: widget.filterName ?? l10n.browse,
            focusedItem: _focusedItem,
            filter: _vm?.state.filter ?? SeerrBrowseFilter.all,
            letterFilter: _vm?.state.letterFilter ?? '',
            onFilterChanged: (f) => _vm?.setFilter(f),
            onLetterChanged: (l) => _vm?.setLetterFilter(l),
            onHome: () => context.go(Destinations.home),
            onSort: () => _showSortDialog(context),
            onSettings: () => _showSettingsDialog(context),
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
    final l10n = AppLocalizations.of(context);
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
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return _buildGrid(s);
  }

  Widget _buildGrid(SeerrBrowseState s) {
    final l10n = AppLocalizations.of(context);
    if (s.items.isEmpty) {
      return Center(
        child: Text(l10n.noResults, style: const TextStyle(color: Colors.white70)),
      );
    }

    final cardWidth =
      _prefs.get(UserPreferences.posterSize).portraitHeight * (2 / 3);
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = _isCompact(context);
        final gridPadding = isMobile ? 16.0 : _horizontalPadding;
        final crossAxisCount = ((constraints.maxWidth -
                    gridPadding * 2 +
                    spacing) /
                (cardWidth + spacing))
            .floor()
            .clamp(2, 20);

        final cellWidth =
            (constraints.maxWidth -
                gridPadding * 2 -
                (crossAxisCount - 1) * spacing) /
            crossAxisCount;
        final hasSubtitles = s.items.any(
          (item) => (_cardSubtitle(item)?.isNotEmpty ?? false),
        );
        final textHeight = hasSubtitles ? 38.0 : 22.0;
        final childAspectRatio = cellWidth / (cellWidth / (2 / 3) + textHeight);

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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = s.items[index];
                  final focusColor = GetIt.instance<UserPreferences>()
                    .get(UserPreferences.focusColor).colorValue;
                  final cardExpansion = GetIt.instance<UserPreferences>()
                      .get(UserPreferences.cardFocusExpansion);
                  final resolvedFocusColor = Color(focusColor);
                  return MediaCard(
                    title: item.displayTitle,
                    subtitle: _cardSubtitle(item, l10n),
                    imageUrl:
                        item.posterPath != null
                            ? '$_tmdbPosterBase${item.posterPath}'
                            : null,
                    width: double.infinity,
                    aspectRatio: 2 / 3,
                    seerrMediaType: item.mediaType,
                    seerrStatus: item.mediaInfo?.status,
                    focusColor: resolvedFocusColor,
                    cardFocusExpansion: cardExpansion,
                    onFocus:
                        isMobile
                            ? null
                            : () => setState(() => _focusedItem = item),
                    onHoverStart:
                        isMobile
                            ? null
                            : () => setState(() => _focusedItem = item),
                    onHoverEnd:
                        isMobile
                            ? null
                            : () => setState(() => _focusedItem = null),
                    onTap: () {
                      final mt = item.mediaType ?? widget.mediaType ?? 'movie';
                      context.push(
                        Destinations.seerrMedia(item.id.toString()),
                        extra: {'mediaType': mt},
                      );
                    },
                  );
                }, childCount: s.items.length),
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
      },
    );
  }

  static String? _cardSubtitle(SeerrDiscoverItem item, [AppLocalizations? l10n]) {
    final parts = <String>[];
    final date = item.releaseDate ?? item.firstAirDate;
    if (date != null && date.length >= 4) parts.add(date.substring(0, 4));
    if (item.voteAverage != null && item.voteAverage! > 0) {
      parts.add('★ ${item.voteAverage!.toStringAsFixed(1)}');
    }
    final status = item.mediaInfo?.status;
    if (status == 4 || status == 5) {
      parts.add(l10n?.seerrAvailableStatus ?? 'Available');
    } else if (status == 2 || status == 3) {
      parts.add(l10n?.seerrRequestedStatus ?? 'Requested');
    }
    return parts.isEmpty ? null : parts.join('  ');
  }

  void _showSortDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => _SeerrSortDialog(vm: _vm!));
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => _SeerrSettingsDialog(prefs: _prefs));
  }
}

class _SeerrBrowseHeader extends StatelessWidget {
  final String title;
  final SeerrDiscoverItem? focusedItem;
  final SeerrBrowseFilter filter;
  final String letterFilter;
  final ValueChanged<SeerrBrowseFilter> onFilterChanged;
  final ValueChanged<String> onLetterChanged;
  final VoidCallback onHome;
  final VoidCallback onSort;
  final VoidCallback onSettings;

  const _SeerrBrowseHeader({
    required this.title,
    this.focusedItem,
    required this.filter,
    required this.letterFilter,
    required this.onFilterChanged,
    required this.onLetterChanged,
    required this.onHome,
    required this.onSort,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isMobile && isLandscape;
    final isCompactPortrait = isMobile && !isLandscape;
    final showInlineFilters = !isMobile || isCompactLandscape;
    final showBelowFilters = isCompactPortrait;
    final showInlineAlpha = showInlineFilters;
    final showBelowAlpha = showBelowFilters;
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
            mainAxisAlignment:
                (isMobile && !showInlineFilters)
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
            children: [
              _ToolbarButton(icon: Icons.home, onTap: onHome),
              const SizedBox(width: 4),
              _ToolbarButton(icon: Icons.sort, onTap: onSort),
              const SizedBox(width: 4),
              _ToolbarButton(icon: Icons.settings, onTap: onSettings),
              if (showInlineFilters) ...[
                const SizedBox(width: 16),
                _SeerrFilterChips(filter: filter, onChanged: onFilterChanged),
              ],
            ],
          ),
          if (showInlineAlpha) ...[
            const SizedBox(height: 8),
            _AlphaPickerBar(
              selected: letterFilter,
              onChanged: onLetterChanged,
            ),
          ],
          if (showBelowFilters) ...[
            const SizedBox(height: 8),
            _SeerrFilterChips(filter: filter, onChanged: onFilterChanged),
          ],
          if (showBelowAlpha) ...[
            const SizedBox(height: 8),
            _AlphaPickerBar(
              selected: letterFilter,
              onChanged: onLetterChanged,
            ),
          ],
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
        child:
            item == null
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
    final l10n = AppLocalizations.of(context);
    final children = <Widget>[];

    final date = item.releaseDate ?? item.firstAirDate;
    if (date != null && date.length >= 4) {
      children.add(_infoText(date.substring(0, 4)));
    }

    if (item.voteAverage != null && item.voteAverage! > 0) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
            const SizedBox(width: 2),
            _infoText(item.voteAverage!.toStringAsFixed(1)),
          ],
        ),
      );
    }

    final status = item.mediaInfo?.status;
    if (status == 4 || status == 5) {
      children.add(_statusBadge(l10n.seerrAvailableStatus, const Color(0xFF22C55E)));
    } else if (status == 2 || status == 3) {
      children.add(_statusBadge(l10n.seerrRequestedStatus, _seerrAccent));
    }

    final mt = item.mediaType;
    if (mt != null) {
      children.add(_infoText(mt == 'tv' ? l10n.series : l10n.movie));
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
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(l10n.all, SeerrBrowseFilter.all),
        const SizedBox(width: 6),
        _chip(l10n.seerrAvailableStatus, SeerrBrowseFilter.available),
        const SizedBox(width: 6),
        _chip(l10n.seerrRequestedStatus, SeerrBrowseFilter.requested),
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
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _letters.map((letter) {
              final isSelected = selected == letter;
              return _AlphaLetterButton(
                label: letter.isEmpty ? l10n.all : letter,
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
    final focusColor =
        Color(
          GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue,
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
              border:
                  showFocusBorder
                      ? Border.all(color: focusColor, width: 1.5)
                      : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    widget.isSelected
                        ? _seerrAccent
                        : Colors.white.withAlpha(140),
              ),
            ),
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

class _ToolbarButtonState extends State<_ToolbarButton> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
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
              border: showFocusBorder ? Border.all(color: focusColor, width: 1.5) : null,
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

class _SeerrBrowseStatusBar extends StatelessWidget {
  final SeerrBrowseFilter filter;
  final int itemCount;

  const _SeerrBrowseStatusBar({required this.filter, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hPad = _isCompact(context) ? 16.0 : _horizontalPadding;
    final filterLabel = switch (filter) {
      SeerrBrowseFilter.all => l10n.all,
      SeerrBrowseFilter.available => l10n.seerrAvailableStatus,
      SeerrBrowseFilter.requested => l10n.seerrRequestedStatus,
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            filterLabel,
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(77)),
          ),
          Text(
            l10n.itemsCount(itemCount),
            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(115)),
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
    final l10n = AppLocalizations.of(context);
    final vm = widget.vm;
    final s = vm.state;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                l10n.sortBy,
                style: const TextStyle(
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
              child:
                  selected
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

class _SeerrSettingsDialog extends StatelessWidget {
  final UserPreferences prefs;

  const _SeerrSettingsDialog({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = prefs.get(UserPreferences.posterSize);
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                l10n.seerrSettings,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                l10n.posterSize,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            for (final option in PosterSize.values)
              _settingsRadioTile(
                label: _posterSizeLabel(option, l10n),
                selected: current == option,
                onTap: () async {
                  await prefs.set(UserPreferences.posterSize, option);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  static String _posterSizeLabel(PosterSize size, AppLocalizations l10n) => switch (size) {
    PosterSize.small => l10n.small,
    PosterSize.medium => l10n.medium,
    PosterSize.large => l10n.large,
    PosterSize.extraLarge => l10n.extraLarge,
  };

  Widget _settingsRadioTile({
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
              child:
                  selected
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
