import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/services/background_service.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/viewmodels/music_browse_view_model.dart';
import '../../navigation/destinations.dart';

const _navyBackground = Color(0xFF101528);
const _cardSize = 140.0;
const _horizontalPadding = 60.0;
const _cardSpacing = 12.0;

class MusicBrowseScreen extends StatefulWidget {
  final String libraryId;

  const MusicBrowseScreen({super.key, required this.libraryId});

  @override
  State<MusicBrowseScreen> createState() => _MusicBrowseScreenState();
}

class _MusicBrowseScreenState extends State<MusicBrowseScreen> {
  late final MusicBrowseViewModel _vm;
  final _backgroundService = GetIt.instance<BackgroundService>();

  @override
  void initState() {
    super.initState();
    _vm = MusicBrowseViewModel(
      libraryId: widget.libraryId,
      dataSource: GetIt.instance<RowDataSource>(),
      client: GetIt.instance<MediaServerClient>(),
    );
    _vm.addListener(_onChanged);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onItemFocused(AggregatedItem item) {
    _vm.setFocusedItem(item);
    _backgroundService.setBackground(item);
  }

  void _onItemTap(AggregatedItem item) {
    context.push(Destinations.item(item.id, serverId: item.serverId));
  }

  void _onRandomAlbum() async {
    try {
      final client = GetIt.instance<MediaServerClient>();
      final response = await client.itemsApi.getItems(
        parentId: widget.libraryId,
        includeItemTypes: ['MusicAlbum'],
        sortBy: 'Random',
        sortOrder: 'Ascending',
        recursive: true,
        limit: 1,
      );
      final items = (response['Items'] as List?) ?? [];
      if (items.isNotEmpty && mounted) {
        final id = items.first['Id'] as String;
        context.push(Destinations.itemListOf(id));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBackground,
      body: Stack(
        children: [
          Container(color: _navyBackground.withAlpha(191)),
          Column(
            children: [
              _MusicHeader(
                libraryName: _vm.libraryName,
                focusedItem: _vm.focusedItem,
              ),
              Expanded(
                child: _vm.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00A4DC),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _vm.refresh,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            _MusicViewsRow(
                              libraryId: widget.libraryId,
                              onRandomAlbum: _onRandomAlbum,
                            ),
                            ..._vm.rows.map((row) => _MusicItemRow(
                                  title: row.title,
                                  items: row.items,
                                  imageApi: _vm.imageApi,
                                  getSubtitle: _vm.getMusicSubtitle,
                                  getImageUrl: _vm.getMusicImageUrl,
                                  onFocused: _onItemFocused,
                                  onTap: _onItemTap,
                                )),
                          ],
                        ),
                      ),
              ),
              _StatusBar(libraryName: _vm.libraryName),
            ],
          ),
        ],
      ),
    );
  }
}

class _MusicHeader extends StatelessWidget {
  final String libraryName;
  final AggregatedItem? focusedItem;

  const _MusicHeader({required this.libraryName, this.focusedItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          _horizontalPadding, 12, _horizontalPadding, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              libraryName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: focusedItem != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        focusedItem!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (focusedItem!.productionYear != null)
                        Text(
                          '${focusedItem!.productionYear}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(179),
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ToolbarButton(
                icon: Icons.home,
                onTap: () => context.go(Destinations.home),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _MusicViewsRow extends StatelessWidget {
  final String libraryId;
  final VoidCallback onRandomAlbum;

  const _MusicViewsRow({required this.libraryId, required this.onRandomAlbum});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(_horizontalPadding, 16, _horizontalPadding, 8),
          child: Text(
            'Views',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            children: [
              _ViewButton(
                icon: Icons.album,
                label: 'Albums',
                onTap: () => context.push(Destinations.library(libraryId)),
              ),
              const SizedBox(width: _cardSpacing),
              _ViewButton(
                icon: Icons.person,
                label: 'Album Artists',
                onTap: () => context.push(Destinations.library(libraryId)),
              ),
              const SizedBox(width: _cardSpacing),
              _ViewButton(
                icon: Icons.person_outline,
                label: 'Artists',
                onTap: () => context.push(Destinations.library(libraryId)),
              ),
              const SizedBox(width: _cardSpacing),
              _ViewButton(
                icon: Icons.theater_comedy,
                label: 'Genres',
                onTap: () =>
                    context.push(Destinations.libraryGenresOf(libraryId)),
              ),
              const SizedBox(width: _cardSpacing),
              _ViewButton(
                icon: Icons.shuffle,
                label: 'Random',
                onTap: onRandomAlbum,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ViewButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ViewButton> createState() => _ViewButtonState();
}

class _ViewButtonState extends State<_ViewButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _cardSize,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(_focused ? 51 : 20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: Colors.white.withAlpha(_focused ? 255 : 153),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _focused ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.white.withAlpha(_focused ? 255 : 179),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicItemRow extends StatelessWidget {
  final String title;
  final List<AggregatedItem> items;
  final ImageApi imageApi;
  final String Function(AggregatedItem) getSubtitle;
  final String? Function(AggregatedItem) getImageUrl;
  final ValueChanged<AggregatedItem> onFocused;
  final ValueChanged<AggregatedItem> onTap;

  const _MusicItemRow({
    required this.title,
    required this.items,
    required this.imageApi,
    required this.getSubtitle,
    required this.getImageUrl,
    required this.onFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              _horizontalPadding, 16, _horizontalPadding, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: _cardSize + 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: _cardSpacing),
            itemBuilder: (_, i) {
              final item = items[i];
              return _MusicSquareCard(
                title: item.name,
                subtitle: getSubtitle(item),
                imageUrl: getImageUrl(item),
                onFocus: () => onFocused(item),
                onTap: () => onTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MusicSquareCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onFocus;
  final VoidCallback? onTap;

  const _MusicSquareCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onFocus,
    this.onTap,
  });

  @override
  State<_MusicSquareCard> createState() => _MusicSquareCardState();
}

class _MusicSquareCardState extends State<_MusicSquareCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardSize,
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() => _focused = hasFocus);
          if (hasFocus) widget.onFocus?.call();
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _focused ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedOpacity(
              opacity: _focused ? 1.0 : 0.75,
              duration: const Duration(milliseconds: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: _cardSize,
                      height: _cardSize,
                      color: Colors.white.withAlpha(_focused ? 20 : 15),
                      child: widget.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration:
                                  const Duration(milliseconds: 200),
                              errorWidget: (_, __, ___) =>
                                  _albumPlaceholder(),
                            )
                          : _albumPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _albumPlaceholder() {
    return Center(
      child: Icon(
        Icons.album,
        size: 48,
        color: Colors.white.withAlpha(51),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String libraryName;

  const _StatusBar({required this.libraryName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            libraryName,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }
}
