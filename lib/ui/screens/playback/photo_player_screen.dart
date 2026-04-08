import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../l10n/app_localizations.dart';

class PhotoPlayerScreen extends StatefulWidget {
  final String itemId;

  const PhotoPlayerScreen({super.key, required this.itemId});

  @override
  State<PhotoPlayerScreen> createState() => _PhotoPlayerScreenState();
}

class _PhotoPlayerScreenState extends State<PhotoPlayerScreen> {
  final _client = GetIt.instance<MediaServerClient>();
  final _transformController = TransformationController();

  List<AggregatedItem> _items = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _controlsVisible = true;
  Timer? _slideshowTimer;
  Timer? _hideTimer;

  static const _slideshowInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadPhoto();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _hideTimer?.cancel();
    _transformController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadPhoto() async {
    try {
      final data = await _client.itemsApi.getItem(widget.itemId);
      final item = AggregatedItem(
        id: data['Id'] as String,
        serverId: data['ServerId'] as String? ?? '',
        rawData: data,
      );
      final parentId = item.parentId;
      if (parentId != null) {
        final siblings = await _client.itemsApi.getItems(
          parentId: parentId,
          includeItemTypes: ['Photo'],
          sortBy: 'SortName',
          sortOrder: 'Ascending',
          limit: 500,
        );
        final rawItems = siblings['Items'] as List? ?? [];
        final items = rawItems
            .cast<Map<String, dynamic>>()
            .map((d) => AggregatedItem(
                  id: d['Id'] as String,
                  serverId: d['ServerId'] as String? ?? '',
                  rawData: d,
                ))
            .toList();
        final idx = items.indexWhere((i) => i.id == widget.itemId);
        setState(() {
          _items = items;
          _currentIndex = idx >= 0 ? idx : 0;
        });
      } else {
        setState(() {
          _items = [item];
          _currentIndex = 0;
        });
      }
    } catch (_) {}
  }

  String? _getImageUrl(AggregatedItem item) {
    return _client.imageApi.getPrimaryImageUrl(
      item.id,
      maxWidth: 1920,
      tag: item.primaryImageTag,
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= _items.length) return;
    _transformController.value = Matrix4.identity();
    setState(() => _currentIndex = index);
  }

  void _next() {
    if (_currentIndex < _items.length - 1) {
      _goTo(_currentIndex + 1);
    } else {
      _goTo(0);
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      _goTo(_currentIndex - 1);
    } else {
      _goTo(_items.length - 1);
    }
  }

  void _toggleSlideshow() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _slideshowTimer = Timer.periodic(_slideshowInterval, (_) => _next());
    } else {
      _slideshowTimer?.cancel();
    }
  }

  void _showControlsTemporarily() {
    setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControlsTemporarily();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPhotoView(),
            if (_controlsVisible) _buildOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoView() {
    if (_items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColorScheme.accent),
      );
    }

    final item = _items[_currentIndex];
    final url = _getImageUrl(item);
    if (url == null) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 64),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: InteractiveViewer(
        key: ValueKey(item.id),
        transformationController: _transformController,
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: AppColorScheme.accent),
            ),
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white38,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final item = _items.isNotEmpty ? _items[_currentIndex] : null;
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: padding.top + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item?.name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_items.length > 1)
                  Text(
                    AppLocalizations.of(context).photoCountOf(_currentIndex + 1, _items.length),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              bottom: padding.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                  onPressed: _items.length > 1 ? _previous : null,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: _items.length > 1 ? _toggleSlideshow : null,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                  onPressed: _items.length > 1 ? _next : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
