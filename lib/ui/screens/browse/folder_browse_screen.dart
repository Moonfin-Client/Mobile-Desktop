import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/viewmodels/folder_browse_view_model.dart';
import '../../navigation/destinations.dart';
import '../../widgets/navigation_layout.dart';

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
    if (item.primaryImageTag != null) {
      return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
    }
    if (item.backdropImageTags.isNotEmpty) {
      return api.getBackdropImageUrl(item.id, tag: item.backdropImageTags.first);
    }
    return null;
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'Folder':
      case 'CollectionFolder':
      case 'UserView':
        return Icons.folder_rounded;
      case 'Series':
        return Icons.tv;
      case 'Season':
        return Icons.format_list_numbered;
      case 'Movie':
        return Icons.movie;
      case 'Episode':
        return Icons.play_circle_outline;
      case 'Audio':
        return Icons.music_note;
      case 'MusicAlbum':
        return Icons.album;
      case 'MusicArtist':
        return Icons.person;
      case 'Photo':
        return Icons.photo;
      case 'PhotoAlbum':
        return Icons.photo_library;
      case 'BoxSet':
        return Icons.collections_bookmark;
      case 'Playlist':
        return Icons.playlist_play;
      case 'Book':
        return Icons.book;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _onItemTap(AggregatedItem item) {
    if (_vm.isNavigableFolder(item)) {
      _scrollController.jumpTo(0);
      _vm.enterFolder(item);
    } else {
      context.push(Destinations.item(item.id, serverId: item.serverId));
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
            'Failed to load folder: ${_vm.errorMessage}',
            style: TextStyle(color: Colors.white.withAlpha(179)),
          ),
        );
      case FolderBrowseState.ready when _vm.items.isEmpty:
        return Center(
          child: Text(
            'This folder is empty',
            style: TextStyle(color: Colors.white.withAlpha(179)),
          ),
        );
      case FolderBrowseState.ready:
        return _buildList();
    }
  }

  Widget _buildList() {
    final itemCount = _vm.items.length + (_vm.hasMore ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= _vm.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = _vm.items[index];
        final isFolder = _vm.isNavigableFolder(item);
        final imageUrl = _imageUrl(item);

        return ListTile(
          leading: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Icon(_iconForType(item.type), color: Colors.white70),
                  ),
                )
              : Icon(_iconForType(item.type), color: Colors.white70, size: 28),
          title: Text(
            item.name,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _buildSubtitle(item, isFolder),
          trailing: isFolder
              ? const Icon(Icons.chevron_right, color: Colors.white38)
              : null,
          onTap: () => _onItemTap(item),
        );
      },
    );
  }

  Widget? _buildSubtitle(AggregatedItem item, bool isFolder) {
    final parts = <String>[];
    if (item.type != null) parts.add(item.type!);
    if (isFolder && item.childCount != null) {
      parts.add('${item.childCount} items');
    }
    if (item.productionYear != null) parts.add('${item.productionYear}');
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
