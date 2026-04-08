import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/viewmodels/folder_browse_view_model.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../../l10n/app_localizations.dart';

class FolderBrowseScreen extends StatefulWidget {
  final String folderId;

  const FolderBrowseScreen({super.key, required this.folderId});

  @override
  State<FolderBrowseScreen> createState() => _FolderBrowseScreenState();
}

class _FolderBrowseScreenState extends State<FolderBrowseScreen> {
  late final FolderBrowseViewModel _vm;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = FolderBrowseViewModel(GetIt.instance<MediaServerClient>());
    _vm.addListener(_onChanged);
    _scrollController.addListener(_onScroll);
    _vm.loadFolder(widget.folderId);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _vm.loadMore();
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _imageUrl(AggregatedItem item) {
    final api = _vm.imageApi;

    final imageTags = item.rawData['ImageTags'];
    if (imageTags is Map) {
      final thumbTag = imageTags['Thumb'] as String?;
      if (thumbTag != null) {
        return api.getThumbImageUrl(item.id, tag: thumbTag);
      }

      final primaryTag = imageTags['Primary'] as String?;
      if (primaryTag != null) {
        return api.getPrimaryImageUrl(item.id, tag: primaryTag);
      }

      final backdropTag = imageTags['Backdrop'] as String?;
      if (backdropTag != null) {
        return api.getBackdropImageUrl(item.id, tag: backdropTag);
      }
    }

    if (item.primaryImageTag != null) {
      return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
    }

    if (item.seriesId != null && item.seriesPrimaryImageTag != null) {
      return api.getPrimaryImageUrl(item.seriesId!, tag: item.seriesPrimaryImageTag);
    }

    if (item.backdropImageTags.isNotEmpty) {
      return api.getBackdropImageUrl(item.id, tag: item.backdropImageTags.first);
    }

    final parentThumbItemId = item.rawData['ParentThumbItemId'] as String?;
    final parentThumbTag = item.rawData['ParentThumbImageTag'] as String?;
    if (parentThumbItemId != null && parentThumbTag != null) {
      return api.getThumbImageUrl(parentThumbItemId, tag: parentThumbTag);
    }

    return null;
  }

  void _onItemTap(AggregatedItem item) {
    if (_vm.isNavigableFolder(item)) {
      _scrollController.jumpTo(0);
      _vm.enterFolder(item);
    } else {
      context.push(Destinations.itemOrPhoto(item.id, serverId: item.serverId, type: item.type));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              if (_vm.breadcrumbs.isNotEmpty) _buildBreadcrumbs(),
              const Divider(color: Colors.white24, height: 1),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < _vm.breadcrumbs.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, color: Colors.white38, size: 18),
              ),
            Builder(builder: (context) {
              final isLast = i == _vm.breadcrumbs.length - 1;
              return TextButton(
              onPressed: !isLast
                  ? () {
                      _scrollController.jumpTo(0);
                      _vm.navigateTo(i);
                    }
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: !isLast
                    ? Colors.blue
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                _vm.breadcrumbs[i].name,
                style: const TextStyle(fontSize: 14),
              ),
            );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_vm.state) {
      case FolderBrowseState.loading:
        return const Center(child: CircularProgressIndicator());
      case FolderBrowseState.error:
        return Center(
          child: Text(
            AppLocalizations.of(context).failedToLoadFolderError(_vm.errorMessage ?? ''),
            style: TextStyle(color: Colors.white.withAlpha(179)),
          ),
        );
      case FolderBrowseState.ready when _vm.items.isEmpty:
        return Center(
          child: Text(
            AppLocalizations.of(context).thisFolderIsEmpty,
            style: TextStyle(color: Colors.white.withAlpha(179)),
          ),
        );
      case FolderBrowseState.ready:
        return _buildGrid();
    }
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0;
        const spacing = 12.0;
        const targetCardWidth = 170.0;

        final crossAxisCount =
            ((constraints.maxWidth - horizontalPadding * 2 + spacing) /
                    (targetCardWidth + spacing))
                .floor()
                .clamp(2, 10);

        final cardWidth =
            (constraints.maxWidth - horizontalPadding * 2 -
                    (crossAxisCount - 1) * spacing) /
                crossAxisCount;

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            32,
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: 16,
            children: [
              for (final item in _vm.items)
                SizedBox(
                  width: cardWidth,
                  child: _FolderGridCard(
                    item: item,
                    imageUrl: _imageUrl(item),
                    isFolder: _vm.isNavigableFolder(item),
                    icon: MediaCard.iconForType(item.type),
                    subtitle: _subtitleText(item, _vm.isNavigableFolder(item)),
                    onTap: () => _onItemTap(item),
                  ),
                ),
              if (_vm.hasMore)
                SizedBox(
                  width: cardWidth,
                  child: const AspectRatio(
                    aspectRatio: 1,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _subtitleText(AggregatedItem item, bool isFolder) {
    final parts = <String>[];
    if (item.type != null) parts.add(item.type!);
    if (isFolder && item.childCount != null) {
      parts.add(AppLocalizations.of(context).itemCountLabel(item.childCount!));
    }
    if (item.productionYear != null) parts.add('${item.productionYear}');
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _FolderGridCard extends StatelessWidget {
  final AggregatedItem item;
  final String? imageUrl;
  final bool isFolder;
  final IconData icon;
  final String? subtitle;
  final VoidCallback onTap;

  const _FolderGridCard({
    required this.item,
    required this.imageUrl,
    required this.isFolder,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ar = isFolder ? 16 / 9 : MediaCard.aspectRatioForType(item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: ar,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Center(child: Icon(icon, color: Colors.white70, size: 30)),
                      )
                    else
                      Center(
                        child: Icon(icon, color: Colors.white70, size: 30),
                      ),
                    if (isFolder)
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
