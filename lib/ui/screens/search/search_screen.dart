import 'package:custom_tv_text_field/custom_tv_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:server_core/server_core.dart';
import 'package:voice_search/voice_search.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/search_repository.dart';
import '../../../data/repositories/seerr_repository.dart';
import '../../../data/viewmodels/search_view_model.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../../util/platform_detection.dart';
import '../../../util/focus/dpad_keys.dart';
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
  final _voiceFocus = FocusNode();
  final _searchFocus = FocusNode();
  final _searchInputFocus = FocusNode();
  final _searchTvFieldKey = GlobalKey<CustomTVTextFieldState>();
  final _resultsScrollController = ScrollController();
  final _speechToText = stt.SpeechToText();
  late final SearchViewModel _vm;
  static const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';
  bool _voiceReady = false;
  bool _voiceInitializing = false;
  bool _isVoiceListening = false;
  bool _isFirstRowFocused = false;

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

    _searchController.addListener(_onSearchTextChanged);
    _voiceFocus.addListener(_onFocusChanged);
    _searchFocus.addListener(_onFocusChanged);
    _searchInputFocus.addListener(_onFocusChanged);

    if (PlatformDetection.isTV) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
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

  void _onSearchTextChanged() {
    _vm.searchDebounced(_searchController.text);
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (_searchFocus.hasFocus || _searchInputFocus.hasFocus) {
      _restoreNavbarToNormalPosition();
    }
    if (mounted) setState(() {});
  }

  void _restoreNavbarToNormalPosition() {
    if (!_resultsScrollController.hasClients ||
        _resultsScrollController.offset <= 0) {
      return;
    }
    _resultsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  void _focusNavbarHome() {
    final focusNavbar = NavigationLayout.focusNavbarNotifier.value;
    if (focusNavbar != null) {
      focusNavbar();
    }
  }

  KeyEventResult _onContentKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!event.logicalKey.isUpKey) return KeyEventResult.ignored;
    if (!_isFirstRowFocused) return KeyEventResult.ignored;

    if (PlatformDetection.isTV) {
      _searchFocus.requestFocus();
    } else {
      _searchInputFocus.requestFocus();
    }
    return KeyEventResult.handled;
  }

  void _applyVoiceSearchResult(String result) {
    final query = result.trim();
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);

    if (_isVoiceListening) {
      _speechToText.stop();
      _isVoiceListening = false;
    }

    if (query.isEmpty) {
      _vm.searchDebounced('');
    } else {
      _vm.searchImmediate(query);
    }
    if (mounted) {
      if (PlatformDetection.isTV) {
        _searchFocus.requestFocus();
      } else {
        _searchInputFocus.requestFocus();
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  String _voiceLocaleCode(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode.trim();
    final countryCode = locale.countryCode?.trim();

    if (languageCode.isEmpty) {
      return 'en_US';
    }
    if (countryCode == null || countryCode.isEmpty) {
      return languageCode;
    }
    return '${languageCode}_$countryCode';
  }

  @override
  void dispose() {
    _vm.removeListener(_onViewModelChanged);
    _searchController.removeListener(_onSearchTextChanged);
    _voiceFocus.removeListener(_onFocusChanged);
    _searchFocus.removeListener(_onFocusChanged);
    _searchInputFocus.removeListener(_onFocusChanged);
    _voiceFocus.dispose();
    _searchFocus.dispose();
    _searchInputFocus.dispose();
    _resultsScrollController.dispose();
    _vm.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _ensureVoiceReady() async {
    if (_voiceReady) return true;
    if (_voiceInitializing) return false;

    _voiceInitializing = true;
    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final listening = status == 'listening';
        if (_isVoiceListening != listening) {
          setState(() {
            _isVoiceListening = listening;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isVoiceListening = false;
        });
      },
    );
    _voiceInitializing = false;
    if (mounted) {
      setState(() {
        _voiceReady = available;
      });
    } else {
      _voiceReady = available;
    }
    return available;
  }

  Future<void> _toggleTvVoiceSearch() async {
    final localeCode = _voiceLocaleCode(context);

    if (_isVoiceListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isVoiceListening = false;
        });
      }
      return;
    }

    final ready = await _ensureVoiceReady();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice search is unavailable.')),
        );
      }
      return;
    }

    await _speechToText.listen(
      localeId: localeCode,
      onResult: (result) => _applyVoiceSearchResult(result.recognizedWords),
    );
    if (mounted) {
      setState(() {
        _isVoiceListening = true;
      });
    }
  }

  KeyEventResult _onVoiceKey(FocusNode node, KeyEvent event) {
    if (!PlatformDetection.isTV) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey.isUpKey) {
      _focusNavbarHome();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      _toggleTvVoiceSearch();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (!PlatformDetection.isTV) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey.isUpKey) {
      _focusNavbarHome();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _voiceFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      if (!_searchFocus.hasFocus) _searchFocus.requestFocus();
      _searchTvFieldKey.currentState?.openKeyboard();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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

  Widget _buildVoiceActivation() {
    final localeCode = _voiceLocaleCode(context);

    if (!PlatformDetection.isTV) {
      return SizedBox(
        width: 54,
        height: 54,
        child: VoiceSearchWidget(
          localeCode: localeCode,
          minRadius: 22,
          maxRadius: 26,
          activeWidgetColor: const Color(0xFF8B1A1A),
          inactiveWidgetColor: const Color(0xFF2A323D),
          activeIcon: Icons.mic,
          inactiveIcon: Icons.mic_none,
          borderColor: Colors.white24,
          elevation: 0,
          onResult: _applyVoiceSearchResult,
        ),
      );
    }

    final hasFocus = _voiceFocus.hasFocus;
    final backgroundColor = _isVoiceListening
      ? const Color(0xFF8B1A1A)
      : (hasFocus ? Colors.white : const Color(0xFF2A323D));
    final iconColor = _isVoiceListening
      ? Colors.white
      : (hasFocus ? Colors.black : Colors.white);

    return Focus(
      focusNode: _voiceFocus,
      onKeyEvent: _onVoiceKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: hasFocus ? Colors.white : Colors.white24,
            width: 1,
          ),
          boxShadow: _isVoiceListening
              ? const [
                  BoxShadow(
                    color: Color(0x4400A4DC),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          _isVoiceListening ? Icons.mic : Icons.mic_none,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchHasFocus = PlatformDetection.isTV
      ? _searchFocus.hasFocus
      : _searchInputFocus.hasFocus;
    final searchBackgroundColor = searchHasFocus
      ? Colors.white
      : const Color(0xFF2A323D);
    final searchTextColor = searchHasFocus ? Colors.black : Colors.white;
    final searchHintColor = searchHasFocus
      ? Colors.black.withAlpha(153)
      : Colors.white.withAlpha(128);
    final searchIconColor = searchHasFocus ? Colors.black : Colors.white70;
    const searchBorderRadius = 28.0;

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
                child: Row(
                  children: [
                    _buildVoiceActivation(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: PlatformDetection.isTV
                          ? Focus(
                              focusNode: _searchFocus,
                              onKeyEvent: _onSearchKey,
                              child: CustomTVTextField(
                                key: _searchTvFieldKey,
                                controller: _searchController,
                                isFocused: _searchFocus.hasFocus,
                                hint: widget.scopedLibraryId != null &&
                                        widget.scopedLibraryId!.isNotEmpty
                                    ? l10n.searchThisLibrary
                                    : l10n.searchEllipsis,
                                textStyle: TextStyle(
                                  color: searchTextColor,
                                  fontSize: 20,
                                ),
                                hintStyle: TextStyle(
                                  color: searchHintColor,
                                  fontSize: 20,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: searchIconColor,
                                  size: 30,
                                ),
                                filled: true,
                                fillColor: searchBackgroundColor,
                                borderRadius: searchBorderRadius,
                                borderColor: Colors.transparent,
                                focusedBorderColor: Colors.transparent,
                                borderWidth: 0,
                                focusedBorderWidth: 0,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            )
                          : TextField(
                              controller: _searchController,
                              focusNode: _searchInputFocus,
                              autofocus: true,
                              style: TextStyle(
                                color: searchTextColor,
                                fontSize: 20,
                              ),
                              decoration: InputDecoration(
                                hintText: widget.scopedLibraryId != null &&
                                        widget.scopedLibraryId!.isNotEmpty
                                    ? l10n.searchThisLibrary
                                    : l10n.searchEllipsis,
                                hintStyle: TextStyle(color: searchHintColor),
                                filled: true,
                                fillColor: searchBackgroundColor,
                                enabledBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(searchBorderRadius),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(searchBorderRadius),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(searchBorderRadius),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: searchIconColor,
                                  size: 30,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 54,
                                  minHeight: 54,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: searchIconColor,
                                        ),
                                        onPressed: _searchController.clear,
                                      )
                                    : null,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: _onContentKeyEvent,
                  child: _buildBody(),
                ),
              ),
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
    final prefs = GetIt.instance<UserPreferences>();
    final focusColor = Color(prefs.get(UserPreferences.focusColor).colorValue);
    final cardFocusExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final hasSeerr = _vm.seerrResults.isNotEmpty;
    final totalCount = _vm.results.length + (hasSeerr ? 1 : 0);
    return ListView.builder(
      controller: _resultsScrollController,
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < _vm.results.length) {
          final group = _vm.results[index];
          final isFirstVisibleRow = index == 0;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LibraryRow(
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
                  focusColor: focusColor,
                  cardFocusExpansion: cardFocusExpansion,
                  onFocus: () {
                    if (isFirstVisibleRow) {
                      _isFirstRowFocused = true;
                      _restoreNavbarToNormalPosition();
                    }
                  },
                  onFocusLost: () {
                    if (isFirstVisibleRow) {
                      _isFirstRowFocused = false;
                    }
                  },
                  onTap: () => context.push(Destinations.itemOrPhoto(item.id, serverId: item.serverId, type: item.type)),
                );
              }).toList(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _buildSeerrRow(
            focusColor: focusColor,
            cardFocusExpansion: cardFocusExpansion,
          ),
        );
      },
    );
  }

  Widget _buildSeerrRow({
    required Color focusColor,
    required bool cardFocusExpansion,
  }) {
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
          focusColor: focusColor,
          cardFocusExpansion: cardFocusExpansion,
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
