import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../data/models/aggregated_library.dart';
import '../../data/repositories/user_views_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../preference/user_preferences.dart';
import '../navigation/destinations.dart';
import 'focusable_dialog_row.dart';

const _kAccent = Color(0xFF00A4DC);

class ShuffleOptionsDialog extends StatefulWidget {
  final String shuffleContentType;
  final ValueChanged<ShuffleResult> onShuffle;

  const ShuffleOptionsDialog({
    super.key,
    required this.shuffleContentType,
    required this.onShuffle,
  });

  @override
  State<ShuffleOptionsDialog> createState() => _ShuffleOptionsDialogState();
}

enum _ShuffleMode { main, libraries, genres }

class ShuffleResult {
  final String? libraryId;
  final String? genreName;
  final String contentType;
  final String? collectionType;

  const ShuffleResult({
    this.libraryId,
    this.genreName,
    required this.contentType,
    this.collectionType,
  });
}

class _ShuffleOptionsDialogState extends State<ShuffleOptionsDialog> {
  _ShuffleMode _mode = _ShuffleMode.main;
  List<AggregatedLibrary> _libraries = [];
  List<String> _genres = [];
  bool _loadingLibraries = false;
  bool _loadingGenres = false;

  @override
  void initState() {
    super.initState();
    _loadLibraries();
  }

  Future<void> _loadLibraries() async {
    setState(() => _loadingLibraries = true);
    try {
      final viewsRepo = GetIt.instance<UserViewsRepository>();
      final libs = await viewsRepo.getUserViews();
      final filtered = libs.where(_supportsShuffleLibrary).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) {
        setState(() => _libraries = filtered);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLibraries = false);
  }

  Future<void> _loadGenres() async {
    if (_genres.isNotEmpty || _loadingGenres) return;
    setState(() => _loadingGenres = true);
    try {
      final client = GetIt.instance<MediaServerClient>();
      final result = await client.itemsApi.getGenres(
        userId: client.userId,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        recursive: true,
        fields: 'ItemCounts',
      );
      final items = (result['Items'] as List?) ?? [];
      if (mounted) {
        setState(() => _genres = items
            .cast<Map<String, dynamic>>()
            .where(_genreMatchesShuffleContent)
            .map((e) => e['Name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingGenres = false);
  }

  bool _supportsShuffleLibrary(AggregatedLibrary library) {
    final collectionType = library.collectionType.toLowerCase();
    final normalizedName = library.name.trim().toLowerCase();

    if ({'books', 'playlists', 'livetv', 'boxsets'}.contains(collectionType)) {
      return false;
    }

    if (normalizedName == 'folders' || normalizedName == 'recordings') {
      return false;
    }

    return switch (widget.shuffleContentType) {
      'movies' => collectionType != 'tvshows' && collectionType != 'music',
      'shows' => collectionType == 'tvshows' || collectionType.isEmpty,
      _ => collectionType != 'music',
    };
  }

  bool _genreMatchesShuffleContent(Map<String, dynamic> item) {
    final movieCount = item['MovieCount'] as int? ?? 0;
    final seriesCount = item['SeriesCount'] as int? ?? 0;

    return switch (widget.shuffleContentType) {
      'movies' => movieCount > 0,
      'shows' => seriesCount > 0,
      _ => movieCount > 0 || seriesCount > 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 340, maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xE6141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(l10n),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            _buildContent(l10n),
            const SizedBox(height: 4),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 4),
            FocusableDialogRow(
              label: l10n.cancel,
              dimmed: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [
          if (_mode != _ShuffleMode.main)
            _BackButton(onTap: () => setState(() => _mode = _ShuffleMode.main)),
          Text(
            switch (_mode) {
              _ShuffleMode.main => l10n.shuffleBy,
              _ShuffleMode.libraries => l10n.shuffleSelectLibrary,
              _ShuffleMode.genres => l10n.shuffleSelectGenre,
            },
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return switch (_mode) {
      _ShuffleMode.main => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FocusableDialogRow(
              iconBuilder: (size, color) => Image.asset(
                'assets/icons/clapperboard.png',
                width: size,
                height: size,
                color: color,
                fit: BoxFit.contain,
              ),
              label: l10n.shuffleLibrary,
              onTap: () => setState(() => _mode = _ShuffleMode.libraries),
              autofocus: true,
            ),
            FocusableDialogRow(
              iconBuilder: (size, color) => Image.asset(
                'assets/icons/genres.png',
                width: size,
                height: size,
                color: color,
                fit: BoxFit.contain,
              ),
              label: l10n.shuffleGenre,
              onTap: () {
                setState(() => _mode = _ShuffleMode.genres);
                _loadGenres();
              },
            ),
          ],
        ),
      _ShuffleMode.libraries => _loadingLibraries
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2)),
            )
          : _libraries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.shuffleNoLibraries,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _libraries.length,
                itemBuilder: (_, i) {
                  final lib = _libraries[i];
                  return FocusableDialogRow(
                    label: lib.name,
                    autofocus: i == 0,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onShuffle(ShuffleResult(
                        libraryId: lib.id,
                        contentType: widget.shuffleContentType,
                        collectionType: lib.collectionType,
                      ));
                    },
                  );
                },
              ),
            ),
      _ShuffleMode.genres => _loadingGenres
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2)),
            )
          : _genres.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.shuffleNoGenres,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _genres.length,
                itemBuilder: (_, i) {
                  final genre = _genres[i];
                  return FocusableDialogRow(
                    label: genre,
                    autofocus: i == 0,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onShuffle(ShuffleResult(
                        genreName: genre,
                        contentType: widget.shuffleContentType,
                      ));
                    },
                  );
                },
              ),
            ),
    };
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  final _prefs = GetIt.instance<UserPreferences>();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isFocused ? focusColor.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '\u276E',
              style: TextStyle(
                fontSize: 16,
                color: _isFocused ? focusColor : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showShuffleDialog(BuildContext context) {
  final prefs = GetIt.instance<UserPreferences>();
  final contentType = prefs.get(UserPreferences.shuffleContentType);

  showDialog(
    context: context,
    builder: (_) => ShuffleOptionsDialog(
      shuffleContentType: contentType,
      onShuffle: (result) => fetchRandomAndNavigate(
        context,
        contentType: result.contentType,
        parentId: result.libraryId,
        genreName: result.genreName,
      ),
    ),
  );
}

Future<void> fetchRandomAndNavigate(
  BuildContext context, {
  required String contentType,
  String? parentId,
  String? genreName,
}) async {
  final client = GetIt.instance<MediaServerClient>();
  final types = switch (contentType) {
    'movies' => ['Movie'],
    'shows' => ['Series'],
    _ => ['Movie', 'Series'],
  };
  try {
    final response = await client.itemsApi.getItems(
      includeItemTypes: types,
      sortBy: 'Random',
      limit: 1,
      recursive: true,
      parentId: parentId,
      genres: genreName != null ? [genreName] : null,
      enableTotalRecordCount: false,
    );
    final items = (response['Items'] as List?) ?? [];
    if (items.isNotEmpty && context.mounted) {
      final id = (items[0] as Map<String, dynamic>)['Id'] as String;
      context.push(Destinations.item(id));
    }
  } catch (_) {}
}
