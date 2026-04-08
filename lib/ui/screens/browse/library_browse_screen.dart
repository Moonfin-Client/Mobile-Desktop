import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart' hide ImageType;
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/mdblist_repository.dart';
import '../../../data/services/background_service.dart';
import '../../../data/viewmodels/library_browse_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/media_card.dart';
import '../../widgets/rating_display.dart';
import '../../../l10n/app_localizations.dart';

const _navyBackground = Color(0xFF101528);
const _jellyfinBlue = Color(0xFF00A4DC);
const _bookBackground = Color(0xFF0F182A);
const _bookAccent = Color(0xFF32B9E8);
const _horizontalPadding = 60.0;
const _kCompactBreakpoint = 600.0;
const _discoverSubjectsPrefKey = 'book_discover_subjects';
const _discoverAudiobookGenresPrefKey = 'book_discover_audiobook_genres';
const _discoverPageSize = 24;
const _discoverGenrePool = <String>[
  'architecture',
  'art__art_instruction',
  'history_of_art__art__design_styles',
  'dance',
  'design',
  'fashion',
  'film',
  'graphic_design',
  'music',
  'music_theory',
  'painting__paintings',
  'photography',
  'bears',
  'cats',
  'kittens',
  'dogs',
  'puppies',
  'fiction',
  'romance',
  'fantasy',
  'mystery_and_detective_stories',
  'magic',
  'literature',
  'plays',
  'short_stories',
  'young_adult_fiction',
  'sciencemathematics',
  'biology',
  'chemistry',
  'mathematics',
  'physics',
  'programming',
  'business',
  'management',
  'entrepreneurship',
  'business__economics',
  'success_in_business',
  'finance',
  'mystery',
  'science_fiction',
  'juvenile_fiction',
  'juvenile_literature',
  'stories_in_rhyme',
  'infancy',
  'bedtime',
  'picture_books',
  'history',
  'ancient_civilization',
  'archaeology',
  'anthropology',
  'cooking',
  'cookbooks',
  'mental_health',
  'exercise',
  'nutrition',
  'self-help',
  'biography',
  'autobiography',
  'religion',
  'political_science',
  'psychology',
  'place%3Abrazil',
  'place%3Aindia',
  'place%3Aindonesia',
  'place%3Aunited_states',
  'textbooks',
  'historical_fiction',
  'thriller',
  'horror',
  'poetry',
];
const _discoverSubjectLabelOverrides = <String, String>{
  'art__art_instruction': 'Art Instruction',
  'history_of_art__art__design_styles': 'Art History',
  'painting__paintings': 'Painting',
  'mystery_and_detective_stories': 'Mystery and Detective Stories',
  'young_adult_fiction': 'Young Adult',
  'sciencemathematics': 'Science & Mathematics',
  'business__economics': 'Business Economics',
  'success_in_business': 'Business Success',
  'juvenile_fiction': "Children's",
  'juvenile_literature': 'Kids Books',
  'stories_in_rhyme': 'Stories in Rhyme',
  'place%3Abrazil': 'Brazil',
  'place%3Aindia': 'India',
  'place%3Aindonesia': 'Indonesia',
  'place%3Aunited_states': 'United States',
};

const _librivoxGenrePool = <String>[
  'Action & Adventure',
  'Adventure Fiction',
  'Biography & Autobiography',
  "Children's Fiction",
  'Classical',
  'Detective Fiction',
  'Drama',
  'Fantasy Fiction',
  'General Fiction',
  'General Non-fiction',
  'Historical Fiction',
  'Horror & Supernatural Fiction',
  'Humor',
  'Humorous Fiction',
  'Mystery & Detective Stories',
  'Mythology',
  'Nature',
  'Naval Fiction',
  'Philosophy',
  'Plays',
  'Poetry',
  'Religion',
  'Romance',
  'Satire',
  'Science Fiction',
  'Short Stories',
  'Travel & Geography',
  'Tragedy',
  'War & Military Fiction',
  'Westerns',
];

const _audiobookPlaceholderColors = <Color>[
  Color(0xFF1A5C9A),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFF00695C),
  Color(0xFFC62828),
  Color(0xFF4527A0),
  Color(0xFF558B2F),
  Color(0xFF283593),
  Color(0xFF4E342E),
  Color(0xFF00838F),
];


class _BookCollectionPickerDialog extends StatelessWidget {
  final String title;
  final List<AggregatedItem> items;
  final _BookOrganizeMode organizeMode;
  final UserPreferences prefs;
  final String? Function(AggregatedItem item) imageUrlBuilder;
  final String Function(AggregatedItem item) primaryAuthorBuilder;
  final String Function(AggregatedItem item) primaryGenreBuilder;
  final double? Function(AggregatedItem item) playedPercentageBuilder;
  final ValueChanged<AggregatedItem> onItemTap;
  final ValueChanged<AggregatedItem> onItemFocused;
  final VoidCallback onItemFocusCleared;

  const _BookCollectionPickerDialog({
    required this.title,
    required this.items,
    required this.organizeMode,
    required this.prefs,
    required this.imageUrlBuilder,
    required this.primaryAuthorBuilder,
    required this.primaryGenreBuilder,
    required this.playedPercentageBuilder,
    required this.onItemTap,
    required this.onItemFocused,
    required this.onItemFocusCleared,
  });

  @override
  Widget build(BuildContext context) {
    final sortedItems = List<AggregatedItem>.from(items)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final sections = <MapEntry<String, List<AggregatedItem>>>[];

    if (organizeMode == _BookOrganizeMode.all) {
      sections.add(MapEntry('All', sortedItems));
    } else {
      final grouped = <String, List<AggregatedItem>>{};
      for (final item in sortedItems) {
        final key = organizeMode == _BookOrganizeMode.author
            ? primaryAuthorBuilder(item)
            : primaryGenreBuilder(item);
        grouped.putIfAbsent(key, () => []).add(item);
      }
      final keys = grouped.keys.toList()..sort();
      for (final key in keys) {
        sections.add(MapEntry(key, grouped[key]!));
      }
    }

    final isMobile = _isCompact(context);
    final watchedBehavior = prefs.get(
      UserPreferences.watchedIndicatorBehavior,
    );
    final focusExpansion = prefs.get(UserPreferences.cardFocusExpansion);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 28,
        vertical: isMobile ? 16 : 24,
      ),
      backgroundColor: const Color(0xFF0F182A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 1100,
          maxHeight: isMobile ? 760 : 860,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = isMobile ? 16.0 : 24.0;
            final spacing = isMobile ? 10.0 : 14.0;
            final desiredWidth = isMobile ? 112.0 : 136.0;
            final crossAxisCount = ((constraints.maxWidth - padding * 2 + spacing) /
                    (desiredWidth + spacing))
                .floor()
                .clamp(2, 8);
            final cellWidth = (constraints.maxWidth - padding * 2 -
                    (crossAxisCount - 1) * spacing) /
                crossAxisCount;
            const cardRatio = 2 / 3;
            const textHeight = 40.0;
            final childAspectRatio = cellWidth / (cellWidth / cardRatio + textHeight);

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, padding, padding, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context).itemCountLabel(items.length),
                              style: const TextStyle(
                                color: Color(0xFF9EDBFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x223E5F82)),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context).noItemsFound,
                            style: const TextStyle(color: Color(0xFFDCEFFF)),
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                padding,
                                16,
                                padding,
                                padding,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((context, index) {
                                  final section = sections[index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (organizeMode != _BookOrganizeMode.all)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Text(
                                            section.key,
                                            style: const TextStyle(
                                              color: Color(0xFFFFE6C3),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: section.value.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: spacing,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                        itemBuilder: (context, itemIndex) {
                                          final item = section.value[itemIndex];
                                          return MediaCard(
                                            title: item.name,
                                            subtitle: primaryAuthorBuilder(item),
                                            imageUrl: imageUrlBuilder(item),
                                            width: double.infinity,
                                            aspectRatio: 2 / 3,
                                            focusColor: _bookAccent,
                                            cardFocusExpansion: focusExpansion,
                                            isPlayed: item.isPlayed,
                                            isFavorite: item.isFavorite,
                                            playedPercentage:
                                              playedPercentageBuilder(item),
                                            watchedBehavior: watchedBehavior,
                                            itemType: item.type,
                                            onFocus: isMobile ? null : () => onItemFocused(item),
                                            onHoverStart:
                                                isMobile ? null : () => onItemFocused(item),
                                            onHoverEnd:
                                                isMobile ? null : onItemFocusCleared,
                                            onTap: () => onItemTap(item),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                    ],
                                  );
                                }, childCount: sections.length),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StoredBookBookmark {
  final String label;
  final int position;
  final String mode;
  final DateTime createdAt;

  const _StoredBookBookmark({
    required this.label,
    required this.position,
    required this.mode,
    required this.createdAt,
  });

  factory _StoredBookBookmark.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return _StoredBookBookmark(
      label: map['label'] as String? ?? '',
      position: map['position'] as int? ?? 0,
      mode: map['mode'] as String? ?? 'epub',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class _BookBookmarksDialog extends StatelessWidget {
  final AggregatedItem item;
  final Future<List<_StoredBookBookmark>> bookmarksFuture;
  final String? imageUrl;
  final String author;
  final VoidCallback onOpenBook;
  final void Function(_StoredBookBookmark bookmark) onOpenBookmark;

  const _BookBookmarksDialog({
    required this.item,
    required this.bookmarksFuture,
    required this.imageUrl,
    required this.author,
    required this.onOpenBook,
    required this.onOpenBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 28,
        vertical: isMobile ? 18 : 24,
      ),
      backgroundColor: const Color(0xFF0F182A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 760,
          maxHeight: isMobile ? 760 : 820,
        ),
        child: FutureBuilder<List<_StoredBookBookmark>>(
          future: bookmarksFuture,
          builder: (context, snapshot) {
            final bookmarks = snapshot.data ?? const <_StoredBookBookmark>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 22,
                    isMobile ? 16 : 22,
                    isMobile ? 12 : 16,
                    12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isMobile ? 72 : 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x24000000),
                              blurRadius: 14,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: imageUrl == null
                                ? Container(
                                    color: const Color(0xFF2C77B7),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      item.name,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: const Color(0xFF2C77B7),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              author,
                              style: const TextStyle(
                                color: Color(0xFF9EDBFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppLocalizations.of(context).bookmarks,
                              style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x223E5F82)),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(
                          child: CircularProgressIndicator(color: _bookAccent),
                        )
                      : bookmarks.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bookmark_border_rounded,
                                      color: Color(0xFF9EDBFF),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      AppLocalizations.of(context).noSavedBookmarks,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(220),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16 : 22,
                                16,
                                isMobile ? 16 : 22,
                                16,
                              ),
                              itemCount: bookmarks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final bookmark = bookmarks[index];
                                return Material(
                                  color: const Color(0xFF16243A),
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => onOpenBookmark(bookmark),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF1F3553),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.bookmark_rounded,
                                              color: _bookAccent,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  bookmark.label,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_formatBookmarkMode(bookmark.mode, AppLocalizations.of(context))} • ${_formatBookmarkDate(bookmark.createdAt, AppLocalizations.of(context))}',
                                                  style: TextStyle(
                                                    color: Colors.white.withAlpha(145),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.white.withAlpha(120),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 22,
                    8,
                    isMobile ? 16 : 22,
                    isMobile ? 16 : 22,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onOpenBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bookAccent,
                        foregroundColor: const Color(0xFF0E2339),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(AppLocalizations.of(context).openBook),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatBookmarkMode(String mode, AppLocalizations l10n) {
    return switch (mode) {
      'epub' => l10n.chapter,
      'pdf' => l10n.page,
      'comic' => l10n.page,
      _ => l10n.bookmark,
    };
  }

  static String _formatBookmarkDate(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile ||
    MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

enum _BookMediaTab { books, audiobooks }

enum _BookOrganizeMode { all, author, genre }

enum _BookAppSection { library, bookmarks, audiobooks }

class LibraryBrowseScreen extends StatefulWidget {
  final String libraryId;
  final String? genreId;
  final String? genreName;
  final List<String>? includeItemTypes;
  final bool forceBookExperience;

  const LibraryBrowseScreen({
    super.key,
    required this.libraryId,
    this.genreId,
    this.genreName,
    this.includeItemTypes,
    this.forceBookExperience = false,
  });

  @override
  State<LibraryBrowseScreen> createState() => _LibraryBrowseScreenState();
}

class _LibraryBrowseScreenState extends State<LibraryBrowseScreen> {
  late final LibraryBrowseViewModel _vm;
  final _scrollController = ScrollController();
  final _prefs = GetIt.instance<UserPreferences>();
  final _backgroundService = GetIt.instance<BackgroundService>();
  StreamSubscription<String?>? _backgroundSub;
  String? _backdropUrl;
  _BookMediaTab _bookMediaTab = _BookMediaTab.books;
  _BookOrganizeMode _bookOrganizeMode = _BookOrganizeMode.all;
  _BookAppSection _bookAppSection = _BookAppSection.library;
  final Dio _discoverDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 7),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );
  Set<String> _bookmarkedItemIds = const {};
  List<String> _discoverGenres = const ['fantasy', 'romance', 'science_fiction'];
  final Map<String, List<_DiscoverBook>> _discoverBooksByGenre = {};
  final Map<String, ScrollController> _discoverRowControllers = {};
  final Set<String> _discoverLoadingGenres = {};
  final Set<String> _discoverFailedGenres = {};
  bool _discoverInitialized = false;
  bool _discoverBootstrapping = false;
  List<String> _discoverAudiobookGenres = const [
    'Science Fiction',
    'Fantasy Fiction',
    'Mystery & Detective Stories',
  ];
  final Map<String, List<_LibrivoxBook>> _discoverAudiobooksByGenre = {};
  final Map<String, ScrollController> _discoverAudiobookRowControllers = {};
  final Set<String> _discoverAudiobookLoadingGenres = {};
  final Set<String> _discoverAudiobookFailedGenres = {};
  bool _discoverAudiobookInitialized = false;
  bool _discoverAudiobookBootstrapping = false;
  final Map<String, String?> _librivoxCoverCache = {};
  late final int _unreadShuffleSeed;
  Set<String> _localProgressItemIds = const {};
  bool _loadingLocalProgress = false;

  bool get _isBookExperience => widget.forceBookExperience || _vm.isBookLibrary;

  @override
  void initState() {
    super.initState();
    _vm = LibraryBrowseViewModel(
      libraryId: widget.libraryId,
      client: GetIt.instance<MediaServerClient>(),
      prefs: _prefs,
      mdbListRepository: GetIt.instance<MdbListRepository>(),
      genreId: widget.genreId,
      overrideName: widget.genreName,
      includeItemTypes: widget.includeItemTypes,
    );
    _vm.addListener(_onChanged);
    _vm.load();
    _scrollController.addListener(_onScroll);
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;
    _prefs.addListener(_onChanged);
    unawaited(_loadDiscoverPreferences());
    unawaited(_loadBookmarkedItemIds());
    _unreadShuffleSeed = DateTime.now().millisecondsSinceEpoch;
    if (widget.forceBookExperience) {
      unawaited(_bootstrapDiscovery());
    }
  }

  Future<void> _loadDiscoverPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final storedSubjects = prefs
        .getStringList(_discoverSubjectsPrefKey)
        ?.where(_discoverGenrePool.contains)
        .toSet()
        .toList();

    final storedAudiobookGenres = prefs
        .getStringList(_discoverAudiobookGenresPrefKey)
        ?.where(_librivoxGenrePool.contains)
        .toSet()
        .toList();

    if (!mounted) return;

    final nextSubjects =
        (storedSubjects == null || storedSubjects.isEmpty)
            ? _discoverGenres
            : (storedSubjects..sort((a, b) => _displayGenre(a).compareTo(_displayGenre(b))));
    final nextAudiobookGenres =
        (storedAudiobookGenres == null || storedAudiobookGenres.isEmpty)
            ? _discoverAudiobookGenres
            : (storedAudiobookGenres..sort());

    final subjectsChanged =
        nextSubjects.length != _discoverGenres.length ||
        nextSubjects.any((s) => !_discoverGenres.contains(s));
    final audiobookChanged =
        nextAudiobookGenres.length != _discoverAudiobookGenres.length ||
        nextAudiobookGenres.any((g) => !_discoverAudiobookGenres.contains(g));

    if (!subjectsChanged && !audiobookChanged) return;

    setState(() {
      if (subjectsChanged) {
        _discoverGenres = nextSubjects;
        _discoverInitialized = false;
        _discoverBooksByGenre.clear();
        _discoverLoadingGenres.clear();
        _discoverFailedGenres.clear();
        for (final controller in _discoverRowControllers.values) {
          controller.dispose();
        }
        _discoverRowControllers.clear();
      }

      if (audiobookChanged) {
        _discoverAudiobookGenres = nextAudiobookGenres;
        _discoverAudiobookInitialized = false;
        _discoverAudiobooksByGenre.clear();
        _discoverAudiobookLoadingGenres.clear();
        _discoverAudiobookFailedGenres.clear();
        for (final controller in _discoverAudiobookRowControllers.values) {
          controller.dispose();
        }
        _discoverAudiobookRowControllers.clear();
      }
    });

    if (subjectsChanged && _isBookExperience) {
      unawaited(_bootstrapDiscovery());
    }
    if (audiobookChanged &&
        _isBookExperience &&
        _bookAppSection == _BookAppSection.audiobooks) {
      unawaited(_bootstrapAudiobookDiscovery());
    }
  }

  @override
  void dispose() {
    _backgroundSub?.cancel();
    _scrollController.dispose();
    for (final controller in _discoverRowControllers.values) {
      controller.dispose();
    }
    for (final controller in _discoverAudiobookRowControllers.values) {
      controller.dispose();
    }
    _vm.removeListener(_onChanged);
    _prefs.removeListener(_onChanged);
    _discoverDio.close(force: true);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
    if (_isBookExperience && _vm.state == LibraryBrowseState.ready) {
      unawaited(_refreshLocalBookProgress());
    }
    if (_isBookExperience && !_discoverInitialized && !_discoverBootstrapping) {
      unawaited(_bootstrapDiscovery());
    }
    if (_isBookExperience &&
        _bookAppSection == _BookAppSection.audiobooks &&
        !_discoverAudiobookInitialized &&
        !_discoverAudiobookBootstrapping) {
      unawaited(_bootstrapAudiobookDiscovery());
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 600) {
      _vm.loadMore();
    }
  }

  void _onItemFocused(AggregatedItem item) {
    _vm.setFocusedItem(item);
    _backgroundService.setBackground(item, context: BlurContext.browsing);
  }

  void _onItemTap(AggregatedItem item) {
    if (_vm.isNavigableFolder(item)) {
      context.push(Destinations.folder(item.id));
      return;
    }

    context
        .push(
          Destinations.itemOrPhoto(
            item.id,
            serverId: item.serverId,
            type: item.type,
          ),
        )
        .then((result) {
          if (result == true && mounted) {
            _vm.load();
          }
        });
  }

  Future<void> _bootstrapDiscovery() async {
    if (_discoverBootstrapping) return;
    _discoverBootstrapping = true;
    try {
      await Future.wait(
        _discoverGenres.map((subject) => _loadDiscoverPage(subject, reset: true)),
      );
      if (mounted) {
        setState(() => _discoverInitialized = true);
      }
    } finally {
      _discoverBootstrapping = false;
    }
  }

  ScrollController _controllerForDiscoverSubject(String subject) {
    return _discoverRowControllers.putIfAbsent(subject, ScrollController.new);
  }

  Future<void> _scrollDiscoverSubjectRow(String subject, int direction) async {
    final controller = _controllerForDiscoverSubject(subject);
    if (!controller.hasClients) return;

    final viewport = controller.position.viewportDimension;
    final scrollAmount = (viewport * 0.84).clamp(180.0, 420.0);
    final target = (controller.offset + (scrollAmount * direction)).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    if ((target - controller.offset).abs() < 1) return;

    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadDiscoverPage(String subject, {bool reset = false}) async {
    if (_discoverLoadingGenres.contains(subject)) return;

    setState(() {
      _discoverLoadingGenres.add(subject);
      _discoverFailedGenres.remove(subject);
      if (reset) {
        _discoverBooksByGenre[subject] = <_DiscoverBook>[];
      }
    });

    try {
      final subjectKey = Uri.decodeComponent(subject);
      final response = await _discoverDio.get<Map<String, dynamic>>(
        'https://openlibrary.org/search.json',
        queryParameters: {
          'q': 'subject_key:"$subjectKey"',
          'sort': 'trending',
          'limit': _discoverPageSize,
          'page': 1,
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      final docs = (data['docs'] as List?) ?? const [];
      final parsed = docs
          .whereType<Map>()
          .map((w) => _DiscoverBook.fromOpenLibraryMap(Map<String, dynamic>.from(w)))
          .where((book) => book.title.trim().isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _discoverBooksByGenre[subject] = parsed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _discoverFailedGenres.add(subject));
    } finally {
      if (mounted) {
        setState(() => _discoverLoadingGenres.remove(subject));
      }
    }
  }

  Future<void> _showDiscoverGenreSheet() async {
    final temp = {..._discoverGenres};
    final result = await showGeneralDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close subject panel',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final width = MediaQuery.of(context).size.width.clamp(320.0, 420.0).toDouble();
        final sortedSubjects = _discoverGenrePool.toList()
          ..sort((a, b) => _displayGenre(a).compareTo(_displayGenre(b)));
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: const Color(0xFFF0F7FF),
              child: SizedBox(
                width: width,
                child: SafeArea(
                  child: StatefulBuilder(
                    builder: (context, setPanelState) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context).discoverySubjects,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF13233A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).pickDiscoverySubjects,
                            style: const TextStyle(color: Color(0xFF5C7290)),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedSubjects.length,
                              itemBuilder: (context, index) {
                                final subject = sortedSubjects[index];
                                final selected = temp.contains(subject);
                                return CheckboxListTile(
                                  value: selected,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: const Color(0xFF0D47A1),
                                  checkColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFF5C7290),
                                    width: 2,
                                  ),
                                  title: Text(
                                    _displayGenre(subject),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF13233A),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setPanelState(() {
                                      if (value == true) {
                                        temp.add(subject);
                                      } else if (temp.length > 1) {
                                        temp.remove(subject);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(temp.toList()),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == null || result.isEmpty || !mounted) return;
    final sortedResult = result.toList()
      ..sort((a, b) => _displayGenre(a).compareTo(_displayGenre(b)));
    final changed =
        sortedResult.length != _discoverGenres.length ||
        sortedResult.any((s) => !_discoverGenres.contains(s));
    if (!changed) return;

    setState(() {
      _discoverGenres = sortedResult;
      _discoverInitialized = false;
      _discoverBooksByGenre.clear();
      _discoverLoadingGenres.clear();
      _discoverFailedGenres.clear();
      for (final controller in _discoverRowControllers.values) {
        controller.dispose();
      }
      _discoverRowControllers.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_discoverSubjectsPrefKey, sortedResult);
    await _bootstrapDiscovery();
  }

  Future<void> _bootstrapAudiobookDiscovery() async {
    if (_discoverAudiobookBootstrapping) return;
    _discoverAudiobookBootstrapping = true;
    try {
      await Future.wait(
        _discoverAudiobookGenres.map(
          (genre) => _loadAudiobookDiscoverPage(genre, reset: true),
        ),
      );
      if (mounted) {
        setState(() => _discoverAudiobookInitialized = true);
      }
    } finally {
      _discoverAudiobookBootstrapping = false;
    }
  }

  ScrollController _controllerForAudiobookDiscoverGenre(String genre) {
    return _discoverAudiobookRowControllers.putIfAbsent(
      genre,
      ScrollController.new,
    );
  }

  Future<void> _scrollAudiobookDiscoverRow(String genre, int direction) async {
    final controller = _controllerForAudiobookDiscoverGenre(genre);
    if (!controller.hasClients) return;

    final viewport = controller.position.viewportDimension;
    final scrollAmount = (viewport * 0.84).clamp(180.0, 420.0);
    final target = (controller.offset + (scrollAmount * direction)).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    if ((target - controller.offset).abs() < 1) return;

    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadAudiobookDiscoverPage(
    String genre, {
    bool reset = false,
  }) async {
    if (_discoverAudiobookLoadingGenres.contains(genre)) return;

    setState(() {
      _discoverAudiobookLoadingGenres.add(genre);
      _discoverAudiobookFailedGenres.remove(genre);
      if (reset) {
        _discoverAudiobooksByGenre[genre] = <_LibrivoxBook>[];
      }
    });

    try {
      final response = await _discoverDio.get<Map<String, dynamic>>(
        'https://librivox.org/api/feed/audiobooks/',
        queryParameters: {
          'format': 'json',
          'genre': genre,
          'sort_field': 'popularity',
          'sort_order': 'desc',
          'limit': _discoverPageSize,
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      final books = (data['books'] as List?) ?? const [];
      final parsed = books
          .whereType<Map>()
          .map((b) => _LibrivoxBook.fromMap(Map<String, dynamic>.from(b)))
          .where((book) => book.title.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _discoverAudiobooksByGenre[genre] = parsed;
      });
      unawaited(_fetchCoversForBooks(parsed));
    } catch (_) {
      if (!mounted) return;
      setState(() => _discoverAudiobookFailedGenres.add(genre));
    } finally {
      if (mounted) {
        setState(() => _discoverAudiobookLoadingGenres.remove(genre));
      }
    }
  }

  Future<void> _fetchCoversForBooks(List<_LibrivoxBook> books) async {
    const batchSize = 8;
    final unresolved = <_LibrivoxBook>[];
    final immediateUpdates = <String, String?>{};

    for (final book in books) {
      if (_librivoxCoverCache.containsKey(book.id) ||
          immediateUpdates.containsKey(book.id)) {
        continue;
      }
      final archiveCover = _archiveCoverUrlForBook(book);
      if (archiveCover != null) {
        immediateUpdates[book.id] = archiveCover;
        continue;
      }
      final isbnCover = _isbnCoverUrlForBook(book);
      if (isbnCover != null) {
        immediateUpdates[book.id] = isbnCover;
        continue;
      }
      unresolved.add(book);
    }

    if (mounted && immediateUpdates.isNotEmpty) {
      setState(() => _librivoxCoverCache.addAll(immediateUpdates));
    }

    for (var i = 0; i < unresolved.length; i += batchSize) {
      if (!mounted) return;
      final batch = unresolved.skip(i).take(batchSize).toList();
      final results = await Future.wait(batch.map(_searchOpenLibraryCoverForBook));
      if (!mounted) return;
      setState(() {
        for (var j = 0; j < batch.length; j++) {
          _librivoxCoverCache[batch[j].id] = results[j];
        }
      });
    }
  }

  String? _archiveCoverUrlForBook(_LibrivoxBook book) {
    final archiveUrl = book.archiveUrl;
    if ((archiveUrl ?? '').isEmpty) return null;
    final uri = Uri.tryParse(archiveUrl!);
    final segments = uri?.pathSegments.where((s) => s.isNotEmpty).toList();
    final identifier = segments?.isNotEmpty == true ? segments!.last : null;
    if (identifier == null || identifier.isEmpty) return null;
    return 'https://archive.org/services/img/$identifier';
  }

  String? _isbnCoverUrlForBook(_LibrivoxBook book) {
    final isbn = book.preferredIsbn;
    if (isbn == null || isbn.isEmpty) return null;
    return 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false';
  }

  Future<String?> _searchOpenLibraryCoverForBook(_LibrivoxBook book) async {
    try {
      final response = await _discoverDio.get<Map<String, dynamic>>(
        'https://openlibrary.org/search.json',
        queryParameters: {
          'q': '${book.title} ${book.authorName}',
          'limit': 1,
          'fields': 'cover_i',
        },
      );
      final docs = (response.data?['docs'] as List?) ?? const [];
      final coverId = docs.whereType<Map>().firstOrNull?['cover_i'] as num?;
      return coverId != null
          ? 'https://covers.openlibrary.org/b/id/${coverId.toInt()}-M.jpg'
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showAudiobookGenreSheet() async {
    final temp = {..._discoverAudiobookGenres};
    final result = await showGeneralDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close genre panel',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final width =
            MediaQuery.of(context).size.width.clamp(320.0, 420.0).toDouble();
        final sortedGenres = _librivoxGenrePool.toList()..sort();
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: const Color(0xFFF0F7FF),
              child: SizedBox(
                width: width,
                child: SafeArea(
                  child: StatefulBuilder(
                    builder: (context, setPanelState) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context).audiobookGenres,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF13233A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).pickAudiobookGenres,
                            style: const TextStyle(color: Color(0xFF5C7290)),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedGenres.length,
                              itemBuilder: (context, index) {
                                final genre = sortedGenres[index];
                                final selected = temp.contains(genre);
                                return CheckboxListTile(
                                  value: selected,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: const Color(0xFF0D47A1),
                                  checkColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFF5C7290),
                                    width: 2,
                                  ),
                                  title: Text(
                                    genre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF13233A),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setPanelState(() {
                                      if (value == true) {
                                        temp.add(genre);
                                      } else if (temp.length > 1) {
                                        temp.remove(genre);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(temp.toList()),
                              child: Text(AppLocalizations.of(context).apply),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == null || result.isEmpty || !mounted) return;
    final sortedResult = result.toList()..sort();
    final changed =
        sortedResult.length != _discoverAudiobookGenres.length ||
        sortedResult.any((s) => !_discoverAudiobookGenres.contains(s));
    if (!changed) return;

    setState(() {
      _discoverAudiobookGenres = sortedResult;
      _discoverAudiobookInitialized = false;
      _discoverAudiobooksByGenre.clear();
      _discoverAudiobookLoadingGenres.clear();
      _discoverAudiobookFailedGenres.clear();
      for (final controller in _discoverAudiobookRowControllers.values) {
        controller.dispose();
      }
      _discoverAudiobookRowControllers.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_discoverAudiobookGenresPrefKey, sortedResult);
    await _bootstrapAudiobookDiscovery();
  }

  Widget _buildAudiobookDiscoverCard({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F2E4D),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 28,
        isMobile ? 22 : 30,
        isMobile ? 18 : 28,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).discoverAudiobooks,
                      style: const TextStyle(
                        color: Color(0xFF13233A),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context).librivoxDescription,
                      style: const TextStyle(
                        color: Color(0xFF5C7290),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildBookIconButton(
                icon: Icons.people_alt_rounded,
                onTap: () {
                  final allBooks = _discoverAudiobooksByGenre.values
                      .expand((b) => b)
                      .toList();
                  final unique =
                      {for (final b in allBooks) b.id: b}.values.toList();
                  if (unique.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _LibrivoxAuthorsScreen(
                        books: unique,
                        coverCache: Map.unmodifiable(_librivoxCoverCache),
                      ),
                    ),
                  );
                },
                foregroundColor: const Color(0xFF1D3654),
                backgroundColor: const Color(0xFFE2F0FF),
              ),
              const SizedBox(width: 4),
              _buildBookIconButton(
                icon: Icons.tune_rounded,
                onTap: _showAudiobookGenreSheet,
                foregroundColor: const Color(0xFF1D3654),
                backgroundColor: const Color(0xFFE2F0FF),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _discoverAudiobookGenres
                .map(
                  (genre) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEEFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      genre,
                      style: const TextStyle(
                        color: Color(0xFF1D3654),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          if (_discoverAudiobookBootstrapping && !_discoverAudiobookInitialized)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: _bookAccent),
              ),
            )
          else
            ..._discoverAudiobookGenres.map(_buildAudiobookDiscoverGenreRow),
        ],
      ),
    );
  }

  Widget _buildAudiobookDiscoverGenreRow(String genre) {
    final items =
        _discoverAudiobooksByGenre[genre] ?? const <_LibrivoxBook>[];
    final isLoading = _discoverAudiobookLoadingGenres.contains(genre);
    final hasFailed = _discoverAudiobookFailedGenres.contains(genre);
    final rowController = _controllerForAudiobookDiscoverGenre(genre);
    final canScrollRow = items.length > 2 && !isLoading;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  genre,
                  style: const TextStyle(
                    color: Color(0xFF13233A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context).titlesCount(items.length),
                style: const TextStyle(
                  color: Color(0xFF5C7290),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: AppLocalizations.of(context).scrollLeft,
                onPressed: canScrollRow
                    ? () => _scrollAudiobookDiscoverRow(genre, -1)
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF16304D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD7E3F0),
                  disabledForegroundColor: const Color(0xFF90A5BC),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).scrollRight,
                onPressed: canScrollRow
                    ? () => _scrollAudiobookDiscoverRow(genre, 1)
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF16304D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD7E3F0),
                  disabledForegroundColor: const Color(0xFF90A5BC),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty && isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: _bookAccent),
              ),
            )
          else if (items.isEmpty && hasFailed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).couldNotLoadGenre,
                    style: const TextStyle(color: Color(0xFF5C7290)),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _loadAudiobookDiscoverPage(genre, reset: true),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                controller: rowController,
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 150,
                  child: _buildLibrivoxBookCard(items[index]),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (isLoading && items.isNotEmpty)
            const SizedBox(
              height: 30,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: _bookAccent,
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAudiobookCoverPlaceholder(Color color, String duration) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withAlpha(180)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.headphones_rounded, color: Colors.white, size: 32),
          if (duration.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(50),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                duration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLibrivoxBookCard(_LibrivoxBook book) {
    final colorIndex =
        book.id.hashCode.abs() % _audiobookPlaceholderColors.length;
    final placeholderColor = _audiobookPlaceholderColors[colorIndex];
    final coverUrl = _librivoxCoverCache[book.id];
    final hasCover = _librivoxCoverCache.containsKey(book.id) && coverUrl != null;
    final resolvedCover = coverUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final allBooksById = <String, _LibrivoxBook>{};
        for (final bookList in _discoverAudiobooksByGenre.values) {
          for (final discoveredBook in bookList) {
            allBooksById[discoveredBook.id] = discoveredBook;
          }
        }
        final allBooks = allBooksById.values.toList();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _LibrivoxBookDetailScreen(
              book: book,
              coverUrl: coverUrl,
              allBooks: allBooks,
              coverCache: Map.of(_librivoxCoverCache),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: hasCover
                  ? CachedNetworkImage(
                      imageUrl: resolvedCover ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildAudiobookCoverPlaceholder(
                        placeholderColor, book.formattedDuration),
                    )
                  : _buildAudiobookCoverPlaceholder(
                      placeholderColor, book.formattedDuration),
            ),
          ),
          const SizedBox(height: 8),
          _HoverMarqueeText(
            text: book.title,
            style: const TextStyle(
              color: Color(0xFF13233A),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          _HoverMarqueeText(
            text: book.authorName,
            style: const TextStyle(
              color: Color(0xFF5C7290),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _displayGenre(String slug) {
    final overridden = _discoverSubjectLabelOverrides[slug];
    if (overridden != null) return overridden;

    final decoded = Uri.decodeComponent(slug);
    final normalized = decoded.replaceAll(RegExp(r'_+'), ' ').replaceAll(':', ' ');
    final words = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .toList();
    return words.join(' ');
  }

  bool _isAudiobook(AggregatedItem item) {
    final type = (item.type ?? '').toLowerCase();
    final mediaType = (item.rawData['MediaType'] as String? ?? '').toLowerCase();
    return type == 'audio' || type == 'audiobook' || mediaType == 'audio';
  }

  String _primaryAuthor(AggregatedItem item) {
    final directAuthor = (item.rawData['Author'] as String?)?.trim();
    if (directAuthor != null && directAuthor.isNotEmpty) {
      return directAuthor;
    }

    final authors = (item.rawData['Authors'] as List?)
        ?.whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (authors != null && authors.isNotEmpty) {
      return authors.first;
    }

    final people = (item.rawData['People'] as List?)
            ?.whereType<Map>()
            .map((p) => p.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    for (final person in people) {
      final type = (person['Type'] as String?)?.toLowerCase();
      if (type != 'author' && type != 'writer') continue;
      final name = (person['Name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    if ((item.albumArtist ?? '').trim().isNotEmpty) {
      return item.albumArtist!.trim();
    }
    if (item.albumArtists.isNotEmpty) {
      final first = (item.albumArtists.first['Name'] as String?)?.trim();
      if (first != null && first.isNotEmpty) {
        return first;
      }
    }
    if (item.artists.isNotEmpty && item.artists.first.trim().isNotEmpty) {
      return item.artists.first.trim();
    }
    return AppLocalizations.of(context).unknownAuthor;
  }

  String _primaryGenre(AggregatedItem item) {
    if (item.genres.isNotEmpty && item.genres.first.trim().isNotEmpty) {
      return item.genres.first.trim();
    }
    return AppLocalizations.of(context).uncategorized;
  }

  List<AggregatedItem> _bookItems() => _vm.items
      .where((item) => !_vm.isNavigableFolder(item) && !_isAudiobook(item))
      .toList();

  List<AggregatedItem> _audioBookItems() => _vm.items
      .where((item) => !_vm.isNavigableFolder(item) && _isAudiobook(item))
      .toList();

  Future<void> _loadBookmarkedItemIds() async {
    final prefs = await SharedPreferences.getInstance();
    const prefix = 'book_reader_bookmarks_';
    final ids = <String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final entries = prefs.getStringList(key);
      if (entries == null || entries.isEmpty) continue;
      final withoutPrefix = key.substring(prefix.length);
      final lastUnderscore = withoutPrefix.lastIndexOf('_');
      if (lastUnderscore >= 0) {
        ids.add(withoutPrefix.substring(lastUnderscore + 1));
      }
    }
    if (mounted) setState(() => _bookmarkedItemIds = ids);
  }

  String _bookmarkPrefKeyForItem(AggregatedItem item) =>
      'book_reader_bookmarks_${item.serverId}_${item.id}';

  Future<List<_StoredBookBookmark>> _loadBookmarksForItem(
    AggregatedItem item,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_bookmarkPrefKeyForItem(item)) ?? const [];
    return raw
        .map((entry) {
          try {
            return _StoredBookBookmark.fromJson(entry);
          } catch (_) {
            return null;
          }
        })
        .whereType<_StoredBookBookmark>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _refreshLocalBookProgress() async {
    if (_loadingLocalProgress) return;
    _loadingLocalProgress = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localProgress = <String>{};

      for (final item in _bookItems()) {
        final base = '${item.serverId}_${item.id}';
        final hasEpub = prefs.containsKey('book_reader_epub_${base}_chapter');
        final hasPdf = (prefs.getInt('book_reader_pdf_${base}_page') ?? 0) > 1;
        final hasComic = (prefs.getInt('book_reader_comic_${base}_page') ?? 0) > 0;

        if (hasEpub || hasPdf || hasComic) {
          localProgress.add(item.id);
        }
      }

      if (!mounted) return;
      if (setEquals(_localProgressItemIds, localProgress)) return;
      setState(() => _localProgressItemIds = localProgress);
    } finally {
      _loadingLocalProgress = false;
    }
  }

  List<AggregatedItem> _bookmarkItems() {
    final items = _bookItems();
    final bookmarked =
        items.where((item) => _bookmarkedItemIds.contains(item.id)).toList();
    return bookmarked;
  }

  double? _displayPlayedPercentage(AggregatedItem item) {
    final server = item.playedPercentage;
    if (server != null && server > 0) {
      return server;
    }
    final hasTicks = (item.playbackPositionTicks ?? 0) > 0;
    if (hasTicks || _localProgressItemIds.contains(item.id)) {
      return 3;
    }
    return null;
  }

  bool _hasReadingProgress(AggregatedItem item) {
    final progress = item.playedPercentage ?? 0;
    final ticks = item.playbackPositionTicks ?? 0;
    return _localProgressItemIds.contains(item.id) ||
        (!item.isPlayed && (ticks > 0 || (progress > 0 && progress < 100)));
  }

  DateTime? _lastPlayedAt(AggregatedItem item) {
    final userData = item.rawData['UserData'] as Map?;
    final value =
        userData?['DateLastPlayed'] ??
        userData?['LastPlayedDate'] ??
        item.rawData['DateLastPlayed'];
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  void _onBookPrimaryAction(AggregatedItem item, {int? initialPosition, String? initialMode}) {
    if (!_isAudiobook(item)) {
      final extra = (initialPosition != null && initialMode != null)
          ? <String, dynamic>{
              'initialPosition': initialPosition,
              'initialMode': initialMode,
            }
          : null;
      context
          .push(Destinations.book(item.id, serverId: item.serverId), extra: extra)
          .then((result) {
            if (!mounted) {
              return;
            }
            unawaited(_loadBookmarkedItemIds());
            unawaited(_refreshLocalBookProgress());
            if (result == true) {
              _vm.load();
            }
          });
      return;
    }
    _onItemTap(item);
  }

  List<AggregatedItem> _activeBookExperienceItems() {
    final items = switch (_bookAppSection) {
      _BookAppSection.library => _bookItems(),
      _BookAppSection.bookmarks => _bookmarkItems(),
      _BookAppSection.audiobooks => _audioBookItems(),
    };
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  AggregatedItem? _continueReadingItem(List<AggregatedItem> items) {
    final candidates = items.where(_hasReadingProgress).toList()
      ..sort((a, b) {
        final aLast = _lastPlayedAt(a);
        final bLast = _lastPlayedAt(b);
        if (aLast != null && bLast != null) {
          return bLast.compareTo(aLast);
        }
        if (aLast != null) return -1;
        if (bLast != null) return 1;

        final aTicks = a.playbackPositionTicks ?? 0;
        final bTicks = b.playbackPositionTicks ?? 0;
        if (aTicks != bTicks) return bTicks.compareTo(aTicks);

        return (b.playedPercentage ?? 0).compareTo(a.playedPercentage ?? 0);
      });
    return candidates.isNotEmpty ? candidates.first : null;
  }

  String _bookSectionTitle() {
    final l10n = AppLocalizations.of(context);
    return switch (_bookAppSection) {
      _BookAppSection.library => l10n.continueReading,
      _BookAppSection.bookmarks => l10n.savedHighlights,
      _BookAppSection.audiobooks => l10n.continueListening,
    };
  }

  String _bookPrimaryActionLabel() {
    final l10n = AppLocalizations.of(context);
    return switch (_bookAppSection) {
      _BookAppSection.audiobooks => l10n.listen,
      _ => l10n.resume,
    };
  }

  void _activateBookSection(_BookAppSection section) {
    if (_bookAppSection == section) return;
    if (section == _BookAppSection.bookmarks) {
      unawaited(_loadBookmarkedItemIds());
    }
    if (section == _BookAppSection.audiobooks &&
        !_discoverAudiobookInitialized &&
        !_discoverAudiobookBootstrapping) {
      unawaited(_bootstrapAudiobookDiscovery());
    }
    setState(() => _bookAppSection = section);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildBookExperienceScaffold() {
    final hasBackdrop = _backdropUrl != null;
    return Scaffold(
      backgroundColor: _bookBackground,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF18263D), _bookBackground, Color(0xFF0B1424)],
                ),
              ),
            ),
          ),
          if (hasBackdrop)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: CachedNetworkImage(
                  imageUrl: _backdropUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fadeInDuration: const Duration(milliseconds: 300),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(20),
                    _bookBackground.withAlpha(150),
                    const Color(0xFFEFF6FF),
                  ],
                  stops: const [0, 0.45, 0.75],
                ),
              ),
            ),
          ),
          SafeArea(
            child: switch (_vm.state) {
              LibraryBrowseState.loading => _buildBookExperienceState(
                child: const CircularProgressIndicator(color: _bookAccent),
              ),
              LibraryBrowseState.error => _buildBookExperienceState(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _vm.errorMessage ?? AppLocalizations.of(context).failedToLoadLibrary,
                      style: const TextStyle(
                        color: Color(0xFFE8F3FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _vm.load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bookAccent,
                        foregroundColor: const Color(0xFF0D2338),
                      ),
                      child: Text(AppLocalizations.of(context).retry),
                    ),
                  ],
                ),
              ),
              LibraryBrowseState.ready => _buildBookExperienceBody(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookExperienceState({required Widget child}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildBookTopBar(),
        ),
        Expanded(child: Center(child: child)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _buildBookBottomNav(),
        ),
      ],
    );
  }

  Widget _buildBookExperienceBody() {
    final isMobile = _isCompact(context);
    final horizontalPadding = isMobile ? 16.0 : 32.0;
    final items = _activeBookExperienceItems();
    final continueItem = _continueReadingItem(items);
    final primaryShelf = items.where((item) => item.id != continueItem?.id).take(12).toList();
    final favorites = items.where((item) => item.isFavorite).take(12).toList();
    final inProgress = items
        .where((item) {
          return item.id != continueItem?.id && _hasReadingProgress(item);
        })
        .take(12)
        .toList();
    final unreadPool = items
        .where((item) => !item.isPlayed && !_hasReadingProgress(item))
        .toList();
    final unread = List<AggregatedItem>.from(unreadPool)
      ..shuffle(
        Random(
          _unreadShuffleSeed + items.length + (_bookAppSection.index * 997),
        ),
      );
    final unreadSelection = unread.take(12).toList();
    final l10n = AppLocalizations.of(context);
    final authorCount = items
      .map(_primaryAuthor)
      .where((author) => author != l10n.unknownAuthor)
      .toSet()
      .length;
    final genreCount = items.map(_primaryGenre).toSet().length;

    final primaryTitle = switch (_bookAppSection) {
      _BookAppSection.library => l10n.popularNow,
      _BookAppSection.bookmarks => l10n.savedForLater,
      _BookAppSection.audiobooks => l10n.topListens,
    };
    final secondaryTitle = switch (_bookAppSection) {
      _BookAppSection.library => l10n.unreadDiscoveries,
      _BookAppSection.bookmarks => l10n.pickUpAgain,
      _BookAppSection.audiobooks => l10n.continueListening,
    };

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookTopBar(),
                      const SizedBox(height: 18),
                      if (_bookAppSection != _BookAppSection.bookmarks) ...[
                        _buildBookHeroCard(
                          item: continueItem,
                          totalItems: items.length,
                          authorCount: authorCount,
                          genreCount: genreCount,
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (_bookAppSection == _BookAppSection.bookmarks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.savedHighlights,
                                style: const TextStyle(
                                  color: Color(0xFF13233A),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.bookHighlightsDescription,
                                style: const TextStyle(
                                  color: Color(0xFF5C7290),
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_bookAppSection != _BookAppSection.bookmarks)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x24000000),
                                blurRadius: 36,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 18 : 28,
                            isMobile ? 22 : 30,
                            isMobile ? 18 : 28,
                            28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBookPanelHeader(items.length),
                              const SizedBox(height: 22),
                              _buildBookStatsRow(
                                items: items,
                                totalItems: items.length,
                                favorites: items.where((item) => item.isFavorite).length,
                                authorCount: authorCount,
                                genreCount: genreCount,
                              ),
                              if (primaryShelf.isEmpty && continueItem == null) ...[
                                const SizedBox(height: 36),
                                _buildBookEmptyState(),
                              ] else ...[
                                const SizedBox(height: 24),
                                _buildBookRail(
                                  title: primaryTitle,
                                  subtitle:
                                      _bookAppSection == _BookAppSection.audiobooks ? l10n.handPickedFromListeningQueue : l10n.handPickedFromLibrary,
                                  items: primaryShelf,
                                ),
                                if (_bookAppSection == _BookAppSection.audiobooks
                                      ? inProgress.isNotEmpty
                                      : secondaryTitle.isNotEmpty)
                                  _buildBookRail(
                                    title: secondaryTitle,
                                    subtitle: _bookAppSection == _BookAppSection.bookmarks
                                        ? l10n.booksWithHighlights
                                        : _bookAppSection == _BookAppSection.audiobooks
                                            ? l10n.jumpBackNarration
                                            : l10n.unreadBooksReady,
                                    items: _bookAppSection == _BookAppSection.bookmarks
                                        ? inProgress
                                        : _bookAppSection == _BookAppSection.audiobooks
                                            ? inProgress
                                            : unreadSelection,
                                  ),
                                if (favorites.isNotEmpty)
                                  _buildBookRail(
                                    title: l10n.favorites,
                                    subtitle:
                                        l10n.quickAccessFavorites,
                                    items: favorites,
                                  ),
                              ],
                              if (_vm.loadingMore)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: _bookAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (_bookAppSection == _BookAppSection.bookmarks)
                        _buildBookmarksGrid(),
                      if (_bookAppSection == _BookAppSection.library) ...[
                        const SizedBox(height: 18),
                        _buildDiscoverCard(isMobile: isMobile),
                      ],
                      if (_bookAppSection == _BookAppSection.audiobooks) ...[
                        const SizedBox(height: 18),
                        _buildAudiobookDiscoverCard(isMobile: isMobile),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 12),
          child: _buildBookBottomNav(),
        ),
      ],
    );
  }

  Widget _buildBookTopBar() {
    final isMobile = _isCompact(context);
    return Row(
      children: [
        _buildBookIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => context.popOrHome(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              final scopedLibraryId = (_vm.libraryFilter ?? widget.libraryId).trim();
              if (scopedLibraryId.isEmpty) {
                context.push(Destinations.search);
              } else {
                context.push(Destinations.searchInLibrary(scopedLibraryId));
              }
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(isMobile ? 24 : 28),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withAlpha(38)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFFE4F2FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _bookAppSection == _BookAppSection.audiobooks
                          ? AppLocalizations.of(context).searchAudiobooks
                          : AppLocalizations.of(context).searchYourLibrary,
                      style: TextStyle(
                        color: const Color(0xFFE4F2FF).withAlpha(214),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookHeroCard({
    required AggregatedItem? item,
    required int totalItems,
    required int authorCount,
    required int genreCount,
  }) {
    final isMobile = _isCompact(context);
    final imageUrl = item != null ? _imageUrl(item) : null;
    final progressPercent = item?.playedPercentage ?? 0;
    final clampedProgress = (progressPercent / 100).clamp(0, 1).toDouble();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2D49), Color(0xFF0D1A30)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2C77B7).withAlpha(72),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 22 : 30),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBookHeroText(
                          item: item,
                          totalItems: totalItems,
                          authorCount: authorCount,
                          genreCount: genreCount,
                          progress: clampedProgress,
                        ),
                        if (imageUrl != null) ...[
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildBookCoverPreview(item!),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildBookHeroText(
                            item: item,
                            totalItems: totalItems,
                            authorCount: authorCount,
                            genreCount: genreCount,
                            progress: clampedProgress,
                          ),
                        ),
                        if (item != null) ...[
                          const SizedBox(width: 24),
                          _buildBookCoverPreview(item),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookHeroText({
    required AggregatedItem? item,
    required int totalItems,
    required int authorCount,
    required int genreCount,
    required double progress,
  }) {
    final l10n = AppLocalizations.of(context);
    final subtitle = switch (_bookAppSection) {
      _BookAppSection.library => l10n.pickUpStory,
      _BookAppSection.bookmarks => l10n.savedPlacesChapters,
      _BookAppSection.audiobooks => l10n.pickUpStory,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _vm.libraryName.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF9EDBFF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _bookSectionTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            color: const Color(0xFFDCEFFF).withAlpha(214),
            fontSize: 15,
            height: 1.35,
          ),
        ),
        if (_bookAppSection == _BookAppSection.bookmarks) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildBookMetricPill(l10n.titlesCount(totalItems)),
              _buildBookMetricPill(l10n.authorsCount(authorCount)),
              _buildBookMetricPill(l10n.genresCount(genreCount)),
            ],
          ),
          const SizedBox(height: 22),
        ] else
          const SizedBox(height: 10),
        if (item != null) ...[
          Text(
            item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _primaryAuthor(item),
            style: const TextStyle(
              color: Color(0xFF9EDBFF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if ((item.overview ?? '').trim().isNotEmpty)
            Text(
              item.overview!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFFDCEFFF).withAlpha(204),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress > 0 ? progress : 0.08,
              backgroundColor: Colors.white.withAlpha(24),
              color: _bookAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress > 0
                ? l10n.percentCompleted((progress * 100).round())
                : l10n.readyWhenYouAre,
            style: TextStyle(
              color: const Color(0xFFDCEFFF).withAlpha(194),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => _onBookPrimaryAction(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bookAccent,
                  foregroundColor: const Color(0xFF0E2339),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: Text(_bookPrimaryActionLabel()),
              ),
              OutlinedButton(
                onPressed: () => _onItemTap(item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withAlpha(76)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: Text(l10n.details),
              ),
            ],
          ),
        ] 
      ],
    );
  }

  Widget _buildBookMetricPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFDCEFFF),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBookCoverPreview(AggregatedItem item) {
    final imageUrl = _imageUrl(item);
    return Container(
      width: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 26,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: imageUrl == null
              ? Container(
                  color: const Color(0xFF2C77B7),
                  alignment: Alignment.center,
                  child: Text(
                    item.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF2C77B7)),
                ),
        ),
      ),
    );
  }

  Widget _buildBookPanelHeader(int totalItems) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _bookAppSection == _BookAppSection.audiobooks
              ? l10n.listeningRoom
              : _bookAppSection == _BookAppSection.bookmarks
                  ? l10n.bookmarksAndProgress
                  : l10n.library,
          style: const TextStyle(
            color: Color(0xFF13233A),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.titlesArrangedForBrowsing(totalItems),
          style: const TextStyle(
            color: Color(0xFF5C7290),
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildBookStatsRow({
    required List<AggregatedItem> items,
    required int totalItems,
    required int favorites,
    required int authorCount,
    required int genreCount,
  }) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildBookStatCard(
          label: l10n.titles,
          value: '$totalItems',
          onTap: () => _showBookCollectionPicker(
            title: l10n.allTitles,
            items: items,
          ),
        ),
        _buildBookStatCard(
          label: l10n.favorites,
          value: '$favorites',
          onTap: () => _showBookCollectionPicker(
            title: l10n.favorites,
            items: items.where((item) => item.isFavorite).toList(),
          ),
        ),
        _buildBookStatCard(
          label: l10n.authors,
          value: '$authorCount',
          onTap: () => _showBookCollectionPicker(
            title: l10n.browseByAuthor,
            items: items,
            organizeMode: _BookOrganizeMode.author,
          ),
        ),
        _buildBookStatCard(
          label: l10n.genres,
          value: '$genreCount',
          onTap: () => _showBookCollectionPicker(
            title: l10n.browseByGenre,
            items: items,
            organizeMode: _BookOrganizeMode.genre,
          ),
        ),
      ],
    );
  }

  Widget _buildBookStatCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF13233A),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF5C7290),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookCollectionPicker({
    required String title,
    required List<AggregatedItem> items,
    _BookOrganizeMode organizeMode = _BookOrganizeMode.all,
  }) {
    if (items.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => _BookCollectionPickerDialog(
        title: title,
        items: items,
        organizeMode: organizeMode,
        prefs: _prefs,
        imageUrlBuilder: _imageUrl,
        primaryAuthorBuilder: _primaryAuthor,
        primaryGenreBuilder: _primaryGenre,
        playedPercentageBuilder: _displayPlayedPercentage,
        onItemTap: (item) {
          Navigator.of(context).pop();
          _onItemTap(item);
        },
        onItemFocused: _onItemFocused,
        onItemFocusCleared: () => _vm.setFocusedItem(null),
      ),
    );
  }

  void _showBookBookmarksDialog(AggregatedItem item) {
    final bookmarksFuture = _loadBookmarksForItem(item);
    showDialog(
      context: context,
      builder: (_) => _BookBookmarksDialog(
        item: item,
        bookmarksFuture: bookmarksFuture,
        imageUrl: _imageUrl(item),
        author: _primaryAuthor(item),
        onOpenBook: () {
          Navigator.of(context).pop();
          _onBookPrimaryAction(item);
        },
        onOpenBookmark: (bookmark) {
          Navigator.of(context).pop();
          _onBookPrimaryAction(
            item,
            initialPosition: bookmark.position,
            initialMode: bookmark.mode,
          );
        },
      ),
    );
  }

  Widget _buildDiscoverCard({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F2E4D),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 28,
        isMobile ? 22 : 30,
        isMobile ? 18 : 28,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).discover,
                      style: const TextStyle(
                        color: Color(0xFF13233A),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context).trendingTitlesOpenLibrary,
                      style: TextStyle(
                        color: Color(0xFF5C7290),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildBookIconButton(
                icon: Icons.tune_rounded,
                onTap: _showDiscoverGenreSheet,
                foregroundColor: const Color(0xFF1D3654),
                backgroundColor: const Color(0xFFE2F0FF),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _discoverGenres
                .map(
                  (genre) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEEFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _displayGenre(genre),
                      style: const TextStyle(
                        color: Color(0xFF1D3654),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          if (_discoverBootstrapping && !_discoverInitialized)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator(color: _bookAccent)),
            )
          else
            ..._discoverGenres.map((genre) => _buildDiscoverGenreRow(genre)),
        ],
      ),
    );
  }

  Widget _buildDiscoverGenreRow(String genre) {
    final items = _discoverBooksByGenre[genre] ?? const <_DiscoverBook>[];
    final isLoading = _discoverLoadingGenres.contains(genre);
    final hasFailed = _discoverFailedGenres.contains(genre);
    final rowController = _controllerForDiscoverSubject(genre);
    final canScrollRow = items.length > 2 && !isLoading;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _displayGenre(genre),
                  style: const TextStyle(
                    color: Color(0xFF13233A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context).booksCount(items.length),
                style: const TextStyle(
                  color: Color(0xFF5C7290),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: AppLocalizations.of(context).scrollLeft,
                onPressed: canScrollRow ? () => _scrollDiscoverSubjectRow(genre, -1) : null,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF16304D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD7E3F0),
                  disabledForegroundColor: const Color(0xFF90A5BC),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).scrollRight,
                onPressed: canScrollRow ? () => _scrollDiscoverSubjectRow(genre, 1) : null,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF16304D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD7E3F0),
                  disabledForegroundColor: const Color(0xFF90A5BC),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty && isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: _bookAccent)),
            )
          else if (items.isEmpty && hasFailed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).couldNotLoadSubject,
                    style: const TextStyle(color: Color(0xFF5C7290)),
                  ),
                ),
                TextButton(
                  onPressed: () => _loadDiscoverPage(genre, reset: true),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            )
          else
            SizedBox(
              height: 240,
              child: ListView.separated(
                controller: rowController,
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 140,
                  child: _buildDiscoverBookCard(items[index]),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (isLoading && items.isNotEmpty)
            const SizedBox(
              height: 30,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: _bookAccent)),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDiscoverBookCard(_DiscoverBook item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _DiscoverBookDetailScreen(book: item),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: item.coverUrl == null
                  ? Container(
                      color: const Color(0xFF2C77B7),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF2C77B7),
                        alignment: Alignment.center,
                        child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          _HoverMarqueeText(
            text: item.title,
            style: const TextStyle(
              color: Color(0xFF13233A),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          _HoverMarqueeText(
            text: item.author,
            style: const TextStyle(
              color: Color(0xFF5C7290),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksGrid() {
    final isMobile = _isCompact(context);
    final items = _bookmarkItems();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            AppLocalizations.of(context).noBookmarkedItems,
            style: TextStyle(
              color: const Color(0xFF5C7290).withAlpha(179),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isMobile ? 10.0 : 14.0;
        final desiredWidth = isMobile ? 112.0 : 136.0;
        final crossAxisCount =
            ((constraints.maxWidth + spacing) / (desiredWidth + spacing))
                .floor()
                .clamp(2, 8);
        final cellWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        const cardRatio = 2 / 3;
        const textHeight = 40.0;
        final childAspectRatio =
            cellWidth / (cellWidth / cardRatio + textHeight);
        final watchedBehavior = _prefs.get(
          UserPreferences.watchedIndicatorBehavior,
        );
        final focusExpansion = _prefs.get(UserPreferences.cardFocusExpansion);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MediaCard(
              title: item.name,
              subtitle: _primaryAuthor(item),
              imageUrl: _imageUrl(item),
              width: double.infinity,
              aspectRatio: 2 / 3,
              focusColor: _bookAccent,
              cardFocusExpansion: focusExpansion,
              isPlayed: item.isPlayed,
              isFavorite: item.isFavorite,
              playedPercentage: _displayPlayedPercentage(item),
              watchedBehavior: watchedBehavior,
              itemType: item.type,
              onFocus: isMobile ? null : () => _onItemFocused(item),
              onHoverStart: isMobile ? null : () => _onItemFocused(item),
              onHoverEnd: isMobile ? null : () => _vm.setFocusedItem(null),
              onTap: () => _showBookBookmarksDialog(item),
            );
          },
        );
      },
    );
  }

  Widget _buildBookRail({
    required String title,
    required String subtitle,
    required List<AggregatedItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 100.0 : 128.0;
    final railHeight = isMobile ? 204.0 : 244.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF13233A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5C7290),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: cardWidth,
                  child: _buildBookRailCard(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookRailCard(AggregatedItem item) {
    final imageUrl = _imageUrl(item);
    final serverProgress = ((item.playedPercentage ?? 0) / 100).clamp(0, 1).toDouble();
    final hasTicks = (item.playbackPositionTicks ?? 0) > 0;
    final hasLocal = _localProgressItemIds.contains(item.id);
    final progress = serverProgress > 0 ? serverProgress : (hasTicks || hasLocal ? 0.03 : 0.0);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _onItemTap(item),
      onHover: (hovering) {
        if (hovering) {
          _onItemFocused(item);
        } else {
          _vm.setFocusedItem(null);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl == null
                        ? Container(
                            color: const Color(0xFF2C77B7),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              item.name,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF2C77B7),
                            ),
                          ),
                    if (progress > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: progress,
                          backgroundColor: Colors.black.withAlpha(80),
                          color: item.isFavorite
                              ? const Color(0xFF249AD0)
                              : _bookAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF13233A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _primaryAuthor(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5C7290),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        AppLocalizations.of(context).nothingMatchesSection,
        style: TextStyle(
          color: Color(0xFF5B6F8A),
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBookBottomNav() {
    final isMobile = _isCompact(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: const Color(0xFF101D31).withAlpha(isMobile ? 238 : 230),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withAlpha(24)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BookBottomNavItem(
              label: l10n.library,
              icon: Icons.menu_book_rounded,
              isActive: _bookAppSection == _BookAppSection.library,
              onTap: () => _activateBookSection(_BookAppSection.library),
            ),
            _BookBottomNavItem(
              label: l10n.bookmarks,
              icon: Icons.bookmark_rounded,
              isActive: _bookAppSection == _BookAppSection.bookmarks,
              onTap: () => _activateBookSection(_BookAppSection.bookmarks),
            ),
            _BookBottomNavItem(
              label: l10n.audiobooks,
              icon: Icons.headphones_rounded,
              isActive: _bookAppSection == _BookAppSection.audiobooks,
              onTap: () => _activateBookSection(_BookAppSection.audiobooks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color backgroundColor = const Color(0x1FEAF4FF),
    Color foregroundColor = const Color(0xFFEAF4FF),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: foregroundColor.withAlpha(28)),
        ),
        child: Icon(icon, color: foregroundColor),
      ),
    );
  }

  double _cardWidth() {
    if (_vm.isMusicBrowse || _vm.isPlaylistBrowse) {
      return _vm.posterSize.portraitHeight.toDouble();
    }
    final posterSize = _vm.posterSize;
    return switch (_vm.imageType) {
      ImageType.thumb => posterSize.landscapeHeight * (16 / 9),
      ImageType.banner => posterSize.landscapeHeight * (16 / 9),
      ImageType.poster => posterSize.portraitHeight * (2 / 3),
    };
  }

  double _selectedImageAspectRatio() {
    return switch (_vm.imageType) {
      ImageType.thumb => 16 / 9,
      ImageType.banner => 16 / 9,
      ImageType.poster => 2 / 3,
    };
  }

  double _gridBaseAspectRatio() {
    if (_vm.isMusicBrowse || _vm.isPlaylistBrowse) return 1.0;
    if (_vm.isGenreBrowse) return _selectedImageAspectRatio();
    if (_vm.imageType != ImageType.poster &&
        _vm.items.isNotEmpty &&
        _vm.items.every(_vm.isNavigableFolder)) {
      return 16 / 9;
    }
    return switch (_vm.imageType) {
      ImageType.thumb => 16 / 9,
      ImageType.banner => 16 / 9,
      ImageType.poster => 2 / 3,
    };
  }

  double _itemAspectRatio(AggregatedItem item) {
    if (_vm.isMusicBrowse || _vm.isPlaylistBrowse) return 1.0;
    if (_vm.isGenreBrowse) return _selectedImageAspectRatio();
    if (_vm.isNavigableFolder(item) && _vm.imageType != ImageType.poster) {
      return 16 / 9;
    }
    return switch (_vm.imageType) {
      ImageType.thumb => switch (item.type) {
        'MusicAlbum' ||
        'MusicArtist' ||
        'Audio' ||
        'Playlist' ||
        'Person' => 1.0,
        _ => 16 / 9,
      },
      ImageType.banner => 16 / 9,
      ImageType.poster => MediaCard.aspectRatioForType(item.type),
    };
  }

  bool _prefersThumbArtwork(AggregatedItem item) {
    return switch (item.type) {
      'Episode' || 'Program' || 'Recording' || 'Video' || 'MusicVideo' => true,
      _ => false,
    };
  }

  String? _tagForType(AggregatedItem item, String imageType) {
    final tags = item.rawData['ImageTags'];
    if (tags is! Map) return null;
    return tags[imageType] as String?;
  }

  String? _imageUrl(AggregatedItem item) {
    final api = _vm.imageApi;

    final itemThumbTag = _tagForType(item, 'Thumb');
    final itemBannerTag = _tagForType(item, 'Banner');
    final parentThumbItemId = item.rawData['ParentThumbItemId'] as String?;
    final parentThumbTag = item.rawData['ParentThumbImageTag'] as String?;
    final prefersThumbArtwork = _prefersThumbArtwork(item);

    if (_vm.isNavigableFolder(item)) {
      if (_vm.imageType == ImageType.poster) {
        if (item.primaryImageTag != null) {
          return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
        }
        if (itemThumbTag != null) {
          return api.getThumbImageUrl(item.id, tag: itemThumbTag);
        }
        if (item.backdropImageTags.isNotEmpty) {
          return api.getBackdropImageUrl(
            item.id,
            tag: item.backdropImageTags.first,
          );
        }
        return null;
      }
      if (itemThumbTag != null) {
        return api.getThumbImageUrl(item.id, tag: itemThumbTag);
      }
      if (itemBannerTag != null) {
        return api.getBannerImageUrl(item.id, tag: itemBannerTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      if (item.primaryImageTag != null) {
        return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return api.getThumbImageUrl(parentThumbItemId, tag: parentThumbTag);
      }
      return null;
    }

    if (_vm.isPlaylistBrowse) {
      return item.primaryImageTag != null
          ? api.getPrimaryImageUrl(item.id)
          : null;
    }

    if (_vm.imageType == ImageType.banner) {
      if (itemBannerTag != null) {
        return api.getBannerImageUrl(item.id, tag: itemBannerTag);
      }
      if (item.primaryImageTag != null) {
        return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      return null;
    }

    if (_vm.imageType == ImageType.thumb) {
      if (itemThumbTag != null) {
        return api.getThumbImageUrl(item.id, tag: itemThumbTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return api.getThumbImageUrl(parentThumbItemId, tag: parentThumbTag);
      }
      if (item.parentBackdropItemId != null &&
          item.parentBackdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.parentBackdropItemId!,
          tag: item.parentBackdropImageTags.first,
        );
      }
      if (item.primaryImageTag != null) {
        return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
      }
      return null;
    }

    if (prefersThumbArtwork && !_vm.isGenreBrowse) {
      if (itemThumbTag != null) {
        return api.getThumbImageUrl(item.id, tag: itemThumbTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return api.getBackdropImageUrl(
          item.id,
          tag: item.backdropImageTags.first,
        );
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return api.getThumbImageUrl(parentThumbItemId, tag: parentThumbTag);
      }
    }

    if (item.primaryImageTag != null) {
      return api.getPrimaryImageUrl(item.id, tag: item.primaryImageTag);
    }

    if (item.seriesId != null && item.seriesPrimaryImageTag != null) {
      return api.getPrimaryImageUrl(
        item.seriesId!,
        tag: item.seriesPrimaryImageTag,
      );
    }

    if (itemThumbTag != null) {
      return api.getThumbImageUrl(item.id, tag: itemThumbTag);
    }

    if (item.backdropImageTags.isNotEmpty) {
      return api.getBackdropImageUrl(
        item.id,
        tag: item.backdropImageTags.first,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final isBookBrowse = _isBookExperience;
    if (isBookBrowse) {
      return _buildBookExperienceScaffold();
    }
    final hasBackdrop = !isMobile && _backdropUrl != null;
    return Scaffold(
      backgroundColor: isBookBrowse ? _bookBackground : _navyBackground,
      body: Stack(
        children: [
          if (hasBackdrop)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: BackgroundService.transitionDuration,
                child: CachedNetworkImage(
                  key: ValueKey(_backdropUrl),
                  imageUrl: _backdropUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fadeInDuration: const Duration(milliseconds: 300),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: (isBookBrowse ? _bookBackground : _navyBackground)
                    .withAlpha(hasBackdrop ? 115 : 191),
                gradient: isBookBrowse
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xAA2E2318),
                          _bookBackground.withAlpha(220),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          Column(
            children: [
              _LibraryHeader(
                libraryName: _vm.libraryName,
                totalCount: _vm.totalCount,
                focusedItem: _vm.focusedItem,
                focusedRatings: _vm.focusedRatings,
                enableAdditionalRatings: _prefs.get(
                  UserPreferences.enableAdditionalRatings,
                ),
                enabledRatings: _prefs.get(UserPreferences.enabledRatings),
                blockedRatings: _prefs.get(UserPreferences.blockedRatings),
                showLabels: _prefs.get(UserPreferences.showRatingLabels),
                showBadges: _prefs.get(UserPreferences.showRatingBadges),
                sortBy: _vm.sortBy,
                letterFilter: _vm.letterFilter,
                isMusicBrowse: _vm.isMusicBrowse,
                isBookBrowse: isBookBrowse,
                activeBookTab: _bookMediaTab,
                bookOrganizeMode: _bookOrganizeMode,
                playedFilter: _vm.playedFilter,
                favoriteFilter: _vm.favoriteFilter,
                onBack: () => context.pop(),
                onSort: () => _showFilterSortDialog(context),
                onSettings: () => _showSettingsDialog(context),
                onBookTabChanged: (tab) => setState(() => _bookMediaTab = tab),
                onBookOrganizeChanged: (mode) =>
                    setState(() => _bookOrganizeMode = mode),
                onLetterChanged: (l) => _vm.setLetterFilter(l),
                onPlayedFilterChanged: (status) => _vm.setPlayedFilter(status),
                onFavoriteFilterChanged: (value) => _vm.setFavoriteFilter(value),
              ),
              Expanded(child: _buildBody()),
              _LibraryStatusBar(
                statusText: _vm.statusText,
                counterText: _vm.counterText,
                isBookBrowse: isBookBrowse,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final spinnerColor = _vm.isBookLibrary ? _bookAccent : _jellyfinBlue;
    return switch (_vm.state) {
      LibraryBrowseState.loading => Center(
        child: CircularProgressIndicator(color: spinnerColor),
      ),
      LibraryBrowseState.error => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _vm.errorMessage ?? AppLocalizations.of(context).failedToLoadLibrary,
              style: TextStyle(
                color: _vm.isBookLibrary ? const Color(0xFFF4E6D5) : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _vm.load, child: Text(AppLocalizations.of(context).retry)),
          ],
        ),
      ),
      LibraryBrowseState.ready =>
        _vm.isBookLibrary ? _buildBookGrid() : _buildGrid(),
    };
  }

  Widget _buildGrid() {
    if (_vm.items.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noItemsFound, style: const TextStyle(color: Colors.white70)),
      );
    }

    final cardWidth = _cardWidth();
    final spacing = _vm.isBookLibrary ? 16.0 : 12.0;
    final watchedBehavior = _prefs.get(
      UserPreferences.watchedIndicatorBehavior,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = _isCompact(context);
        final gridPadding = isMobile ? 16.0 : _horizontalPadding;
        final crossAxisCount =
            ((constraints.maxWidth - gridPadding * 2 + spacing) /
                    (cardWidth + spacing))
                .floor()
                .clamp(2, 20);

        final cellWidth =
            (constraints.maxWidth -
                gridPadding * 2 -
                (crossAxisCount - 1) * spacing) /
            crossAxisCount;
        final ar = _gridBaseAspectRatio();
        final hasSubtitles = _vm.items.any(
          (item) => (_cardSubtitle(item)?.isNotEmpty ?? false),
        );
        final textHeight = hasSubtitles ? 38.0 : 22.0;
        final childAspectRatio = cellWidth / (cellWidth / ar + textHeight);

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gridPadding, 20, gridPadding, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _vm.items[index];
                  final itemAspectRatio = _itemAspectRatio(item);
                  final focusColor = Color(
                    _prefs.get(UserPreferences.focusColor).colorValue,
                  );
                  Widget card = MediaCard(
                    title: item.name,
                    subtitle: _cardSubtitle(item),
                    imageUrl: _imageUrl(item),
                    width: double.infinity,
                    aspectRatio: itemAspectRatio,
                    focusColor: focusColor,
                    cardFocusExpansion: _prefs.get(
                      UserPreferences.cardFocusExpansion,
                    ),
                    isPlayed: item.isPlayed,
                    isFavorite: item.isFavorite,
                    unplayedCount: item.unplayedItemCount,
                    playedPercentage: _displayPlayedPercentage(item),
                    watchedBehavior: watchedBehavior,
                    itemType: item.type,
                    onFocus: isMobile ? null : () => _onItemFocused(item),
                    onHoverStart: isMobile ? null : () => _onItemFocused(item),
                    onHoverEnd: isMobile
                        ? null
                        : () => _vm.setFocusedItem(null),
                    onLongPress: isMobile ? null : () => _onItemFocused(item),
                    onTap: () => _onItemTap(item),
                  );
                  return card;
                }, childCount: _vm.items.length),
              ),
            ),
            if (_vm.loadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _vm.isBookLibrary ? _bookAccent : _jellyfinBlue,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBookGrid() {
    final baseItems = _vm.items.where((item) => !_vm.isNavigableFolder(item));
    final tabFiltered = baseItems.where(
      (item) => _bookMediaTab == _BookMediaTab.books
          ? !_isAudiobook(item)
          : _isAudiobook(item),
    );

    final filtered = tabFiltered.where((item) {
      final progress = item.playedPercentage ?? 0;
      final watchedMatch = switch (_vm.playedFilter) {
        PlayedStatusFilter.all => true,
        PlayedStatusFilter.watched => item.isPlayed || progress >= 100,
        PlayedStatusFilter.unwatched => !item.isPlayed && progress < 100,
      };
      final favoriteMatch = !_vm.favoriteFilter || item.isFavorite;
      return watchedMatch && favoriteMatch;
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (filtered.isEmpty) {
      final label = _bookMediaTab == _BookMediaTab.books ? AppLocalizations.of(context).books.toLowerCase() : AppLocalizations.of(context).audiobooks.toLowerCase();
      return Center(
        child: Text(
          AppLocalizations.of(context).noLabelFound(label),
          style: const TextStyle(color: Color(0xFFD4B28B)),
        ),
      );
    }

    final sections = <MapEntry<String, List<AggregatedItem>>>[];
    if (_bookOrganizeMode == _BookOrganizeMode.all) {
      sections.add(MapEntry('All', List<AggregatedItem>.from(filtered)));
    } else {
      final grouped = <String, List<AggregatedItem>>{};
      for (final item in filtered) {
        final key = _bookOrganizeMode == _BookOrganizeMode.author
            ? _primaryAuthor(item)
            : _primaryGenre(item);
        grouped.putIfAbsent(key, () => []).add(item);
      }
      final keys = grouped.keys.toList()..sort();
      for (final key in keys) {
        sections.add(MapEntry(key, grouped[key]!));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = _isCompact(context);
        final hPad = isMobile ? 16.0 : _horizontalPadding;
        final spacing = isMobile ? 10.0 : 14.0;
        final desiredWidth = isMobile ? 112.0 : 136.0;
        final crossAxisCount =
            ((constraints.maxWidth - hPad * 2 + spacing) / (desiredWidth + spacing))
                .floor()
                .clamp(2, 10);

        final cellWidth =
            (constraints.maxWidth - hPad * 2 - (crossAxisCount - 1) * spacing) /
                crossAxisCount;
        const cardRatio = 2 / 3;
        const textHeight = 40.0;
        final childAspectRatio = cellWidth / (cellWidth / cardRatio + textHeight);

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final section = sections[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_bookOrganizeMode != _BookOrganizeMode.all)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            section.key,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFE6C3),
                            ),
                          ),
                        ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: section.value.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: 10,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, i) {
                          final item = section.value[i];
                          return MediaCard(
                            title: item.name,
                            subtitle: _primaryAuthor(item),
                            imageUrl: _imageUrl(item),
                            width: double.infinity,
                            aspectRatio: 2 / 3,
                            focusColor: _bookAccent,
                            cardFocusExpansion: _prefs.get(
                              UserPreferences.cardFocusExpansion,
                            ),
                            isPlayed: item.isPlayed,
                            isFavorite: item.isFavorite,
                            playedPercentage: _displayPlayedPercentage(item),
                            watchedBehavior: _prefs.get(
                              UserPreferences.watchedIndicatorBehavior,
                            ),
                            itemType: item.type,
                            onFocus: isMobile ? null : () => _onItemFocused(item),
                            onHoverStart:
                                isMobile ? null : () => _onItemFocused(item),
                            onHoverEnd:
                                isMobile ? null : () => _vm.setFocusedItem(null),
                            onTap: () => _onItemTap(item),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  );
                }, childCount: sections.length),
              ),
            ),
            if (_vm.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: _bookAccent),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String? _cardSubtitle(AggregatedItem item) {
    final parts = <String>[];
    if (_vm.isNavigableFolder(item)) {
      if (item.childCount != null) {
        parts.add(AppLocalizations.of(context).itemCountLabel(item.childCount!));
      }
      return parts.isEmpty ? AppLocalizations.of(context).folder : parts.join('  ');
    }

    if (item.productionYear != null) parts.add('${item.productionYear}');
    if (item.officialRating != null) parts.add(item.officialRating!);
    final rt = item.runtime;
    if (rt != null) {
      final h = rt.inHours;
      final m = rt.inMinutes % 60;
      if (h > 0) {
        parts.add('${h}h ${m}m');
      } else {
        parts.add('${m}m');
      }
    }
    if (item.communityRating != null) {
      parts.add('★ ${item.communityRating!.toStringAsFixed(1)}');
    }
    return parts.isEmpty ? null : parts.join('  ');
  }

  void _showFilterSortDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => _FilterSortDialog(vm: _vm),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) => _SettingsDialog(vm: _vm),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final String libraryName;
  final int totalCount;
  final AggregatedItem? focusedItem;
  final Map<String, double> focusedRatings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;
  final bool showBadges;
  final LibrarySortBy sortBy;
  final String letterFilter;
  final bool isMusicBrowse;
  final bool isBookBrowse;
  final _BookMediaTab activeBookTab;
  final _BookOrganizeMode bookOrganizeMode;
  final PlayedStatusFilter playedFilter;
  final bool favoriteFilter;
  final VoidCallback onBack;
  final VoidCallback onSort;
  final VoidCallback onSettings;
  final ValueChanged<_BookMediaTab> onBookTabChanged;
  final ValueChanged<_BookOrganizeMode> onBookOrganizeChanged;
  final ValueChanged<String> onLetterChanged;
  final ValueChanged<PlayedStatusFilter> onPlayedFilterChanged;
  final ValueChanged<bool> onFavoriteFilterChanged;

  const _LibraryHeader({
    required this.libraryName,
    required this.totalCount,
    this.focusedItem,
    this.focusedRatings = const {},
    this.enableAdditionalRatings = false,
    this.enabledRatings = 'tomatoes,stars',
    this.blockedRatings = '',
    this.showLabels = true,
    this.showBadges = true,
    required this.sortBy,
    required this.letterFilter,
    this.isMusicBrowse = false,
    this.isBookBrowse = false,
    this.activeBookTab = _BookMediaTab.books,
    this.bookOrganizeMode = _BookOrganizeMode.all,
    this.playedFilter = PlayedStatusFilter.all,
    this.favoriteFilter = false,
    required this.onBack,
    required this.onSort,
    required this.onSettings,
    required this.onBookTabChanged,
    required this.onBookOrganizeChanged,
    required this.onLetterChanged,
    required this.onPlayedFilterChanged,
    required this.onFavoriteFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isMobile && isLandscape;
    final isCompactPortrait = isMobile && !isLandscape;
    final showInlineAlpha =
      !isBookBrowse && sortBy == LibrarySortBy.name && (!isMobile || isCompactLandscape);
    final showBelowAlpha = !isBookBrowse && sortBy == LibrarySortBy.name && isCompactPortrait;
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
                libraryName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: isBookBrowse ? FontWeight.w600 : FontWeight.w300,
                  color: isBookBrowse ? const Color(0xFFF3E3CF) : Colors.white,
                  letterSpacing: isBookBrowse ? 0.4 : 0,
                ),
              ),
              if (totalCount > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '$totalCount Items',
                  style: TextStyle(
                    fontSize: 12,
                    color: isBookBrowse
                        ? const Color(0xFFE5C9A3)
                        : Colors.white.withAlpha(102),
                  ),
                ),
              ],
            ],
          ),
          if (!isMobile && !isBookBrowse) ...[
            const SizedBox(height: 6),
            _FocusedItemHud(
              item: focusedItem,
              ratings: focusedRatings,
              enableAdditionalRatings: enableAdditionalRatings,
              enabledRatings: enabledRatings,
              blockedRatings: blockedRatings,
              showLabels: showLabels,
              showBadges: showBadges,
            ),
          ],
          SizedBox(height: isBookBrowse ? 2 : 6),
          Row(
            mainAxisAlignment: (isMobile && !showInlineAlpha)
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              _ToolbarButton(icon: Icons.arrow_back, onTap: onBack),
              if (!isBookBrowse) ...[
                const SizedBox(width: 4),
                _ToolbarButton(
                  icon: Icons.sort,
                  onTap: onSort,
                  accentColor: _jellyfinBlue,
                ),
              ],
              if (!isMusicBrowse && !isBookBrowse) ...[
                const SizedBox(width: 4),
                _ToolbarButton(
                  icon: Icons.settings,
                  onTap: onSettings,
                  accentColor: _jellyfinBlue,
                ),
              ],
              if (showInlineAlpha) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _AlphaPickerBar(
                    selected: letterFilter,
                    onChanged: onLetterChanged,
                  ),
                ),
              ],
            ],
          ),
          if (showBelowAlpha) ...[
            const SizedBox(height: 8),
            _AlphaPickerBar(selected: letterFilter, onChanged: onLetterChanged),
          ],
          if (isBookBrowse) ...[
            const SizedBox(height: 10),
            _BookMediaTabs(
              activeTab: activeBookTab,
              onChanged: onBookTabChanged,
            ),
            const SizedBox(height: 8),
            _BookStatusCategories(
              playedFilter: playedFilter,
              favoriteFilter: favoriteFilter,
              onPlayedFilterChanged: onPlayedFilterChanged,
              onFavoriteFilterChanged: onFavoriteFilterChanged,
            ),
            const SizedBox(height: 8),
            _BookOrganizeChips(
              mode: bookOrganizeMode,
              onChanged: onBookOrganizeChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _FocusedItemHud extends StatelessWidget {
  final AggregatedItem? item;
  final Map<String, double> ratings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;
  final bool showBadges;

  const _FocusedItemHud({
    this.item,
    this.ratings = const {},
    this.enableAdditionalRatings = false,
    this.enabledRatings = 'tomatoes,stars',
    this.blockedRatings = '',
    this.showLabels = true,
    this.showBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    final hudHeight = showLabels ? 96.0 : 80.0;
    return SizedBox(
      height: hudHeight,
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
                    item!.name,
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
                  const SizedBox(height: 4),
                  RatingsRow(
                    ratings: ratings,
                    communityRating: item!.communityRating,
                    criticRating: item!.criticRating,
                    enableAdditionalRatings: enableAdditionalRatings,
                    enabledRatings: enabledRatings,
                    blockedRatings: blockedRatings,
                    showLabels: showLabels,
                    showBadges: showBadges,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final AggregatedItem item;

  const _MetadataRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (item.productionYear != null) {
      children.add(_infoText('${item.productionYear}'));
    }

    if (item.type != 'Series') {
      final rt = item.runtime;
      if (rt != null) {
        final h = rt.inHours;
        final m = rt.inMinutes % 60;
        final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
        children.add(_infoText(timeStr));
      }
    }

    if (item.type == 'Series' && item.status != null) {
      final continuing = item.status == 'Continuing';
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: continuing
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            continuing ? 'Continuing' : 'Ended',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (item.officialRating != null) {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.officialRating!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
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
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    this.accentColor = _jellyfinBlue,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final prefFocusColor = Color(
      GetIt.instance<UserPreferences>()
          .get(UserPreferences.focusColor)
          .colorValue,
    );
    final focusColor = widget.accentColor == _jellyfinBlue
        ? prefFocusColor
        : widget.accentColor;
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
              border: showFocusBorder
                  ? Border.all(color: focusColor, width: 1.5)
                  : null,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _letters.map((letter) {
          final isSelected = selected == letter;
          return _AlphaLetterButton(
            label: letter.isEmpty ? AppLocalizations.of(context).all : letter,
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
    final focusColor = Color(
      GetIt.instance<UserPreferences>()
          .get(UserPreferences.focusColor)
          .colorValue,
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
              border: showFocusBorder
                  ? Border.all(color: focusColor, width: 1.5)
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: widget.isSelected
                    ? _jellyfinBlue
                    : Colors.white.withAlpha(140),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryStatusBar extends StatelessWidget {
  final String statusText;
  final String counterText;
  final bool isBookBrowse;

  const _LibraryStatusBar({
    required this.statusText,
    required this.counterText,
    this.isBookBrowse = false,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = _isCompact(context) ? 16.0 : _horizontalPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              color: isBookBrowse
                  ? const Color(0xFFD7B890).withAlpha(170)
                  : Colors.white.withAlpha(77),
            ),
          ),
          Text(
            counterText,
            style: TextStyle(
              fontSize: 13,
              color: isBookBrowse
                  ? const Color(0xFFE8CFB0).withAlpha(190)
                  : Colors.white.withAlpha(115),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSortDialog extends StatefulWidget {
  final LibraryBrowseViewModel vm;

  const _FilterSortDialog({required this.vm});

  @override
  State<_FilterSortDialog> createState() => _FilterSortDialogState();
}

class _FilterSortDialogState extends State<_FilterSortDialog> {
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
    final isBookBrowse = vm.isBookLibrary;
    final accent = isBookBrowse ? _bookAccent : _jellyfinBlue;
    final l10n = AppLocalizations.of(context);
    final dialogWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      280.0,
      380.0,
    );
    return Dialog(
      backgroundColor: isBookBrowse
          ? const Color(0xEE211A14)
          : const Color(0xE6141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isBookBrowse
              ? const Color(0x80D9A563)
              : Colors.white.withAlpha(26),
        ),
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
                l10n.sortAndFilter,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            _sectionHeader(l10n.sortBy),
            for (final option in LibrarySortBy.values)
              _radioTile(
                label: option.displayName,
                selected: vm.sortBy == option,
                trailing: vm.sortBy == option
                    ? IconButton(
                        icon: Icon(
                          vm.sortDirection == SortDirection.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: _jellyfinBlue,
                          size: 18,
                        ),
                        onPressed: () => vm.toggleSortDirection(),
                      )
                    : null,
                onTap: () {
                  if (vm.sortBy == option) {
                    vm.toggleSortDirection();
                  } else {
                    vm.setSortBy(option);
                  }
                },
              ),
            Divider(color: Colors.white.withAlpha(20)),
            _sectionHeader(l10n.filters),
            _checkboxTile(
              label: l10n.favorites,
              checked: vm.favoriteFilter,
              onTap: () => vm.setFavoriteFilter(!vm.favoriteFilter),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            _sectionHeader(isBookBrowse ? l10n.readingStatus : l10n.playedStatus),
            for (final status in PlayedStatusFilter.values)
              _radioTile(
                label: switch (status) {
                  PlayedStatusFilter.all => l10n.all,
                  PlayedStatusFilter.watched => isBookBrowse
                      ? l10n.readStatus
                      : l10n.watched,
                  PlayedStatusFilter.unwatched => isBookBrowse
                      ? l10n.unread
                      : l10n.unwatched,
                },
                selected: vm.playedFilter == status,
                onTap: () => vm.setPlayedFilter(status),
                accent: accent,
              ),
            if (vm.isSeriesLibrary) ...[
              Divider(color: Colors.white.withAlpha(20)),
              _sectionHeader(l10n.seriesStatus),
              for (final status in SeriesStatusFilter.values)
                _radioTile(
                  label: switch (status) {
                    SeriesStatusFilter.all => l10n.all,
                    SeriesStatusFilter.continuing => l10n.continuing,
                    SeriesStatusFilter.ended => l10n.ended,
                  },
                  selected: vm.seriesFilter == status,
                  onTap: () => vm.setSeriesFilter(status),
                  accent: accent,
                ),
            ],
            if (vm.isGenreBrowse && vm.libraries.isNotEmpty) ...[
              Divider(color: Colors.white.withAlpha(20)),
              _sectionHeader(l10n.library),
              _radioTile(
                label: l10n.allLibraries,
                selected: vm.libraryFilter == null,
                onTap: () => vm.setLibraryFilter(null),
                accent: accent,
              ),
              for (final lib in vm.libraries)
                _radioTile(
                  label: lib['Name'] as String? ?? '',
                  selected: vm.libraryFilter == lib['Id'],
                  onTap: () => vm.setLibraryFilter(lib['Id'] as String),
                  accent: accent,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withAlpha(115),
        ),
      ),
    );
  }

  Widget _radioTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
    Color accent = _jellyfinBlue,
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
                  color: selected ? accent : Colors.white.withAlpha(128),
                  width: 2,
                ),
                color: selected ? accent : Colors.transparent,
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
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _checkboxTile({
    required String label,
    required bool checked,
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
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked ? _jellyfinBlue : Colors.white.withAlpha(128),
                  width: 2,
                ),
                color: checked ? _jellyfinBlue : Colors.transparent,
              ),
              child: checked
                  ? const Center(
                      child: Text(
                        '✓',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: checked ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  final LibraryBrowseViewModel vm;

  const _SettingsDialog({required this.vm});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
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
    final isBookBrowse = vm.isBookLibrary;
    final l10n = AppLocalizations.of(context);
    final dialogWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      280.0,
      340.0,
    );
    return Dialog(
      backgroundColor: isBookBrowse
          ? const Color(0xEE211A14)
          : const Color(0xE6141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isBookBrowse
              ? const Color(0x80D9A563)
              : Colors.white.withAlpha(26),
        ),
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
                l10n.display,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white.withAlpha(20)),
            if (!vm.isPlaylistBrowse) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Text(
                  l10n.imageType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(115),
                  ),
                ),
              ),
              for (final type in ImageType.values) _settingsRadioTile(vm, type),
              Divider(color: Colors.white.withAlpha(20)),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                l10n.posterSize,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(115),
                ),
              ),
            ),
            for (final size in PosterSize.values)
              _posterSizeRadioTile(vm, size),
          ],
        ),
      ),
    );
  }

  Widget _settingsRadioTile(LibraryBrowseViewModel vm, ImageType type) {
    final selected = vm.imageType == type;
    final accent = vm.isBookLibrary ? _bookAccent : _jellyfinBlue;
    return InkWell(
      onTap: () => vm.setImageType(type),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _radioCircle(selected, accent),
            const SizedBox(width: 12),
            Text(
              type.name[0].toUpperCase() + type.name.substring(1),
              style: TextStyle(
                fontSize: 15,
                color: selected ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterSizeRadioTile(LibraryBrowseViewModel vm, PosterSize size) {
    final selected = vm.posterSize == size;
    final accent = vm.isBookLibrary ? _bookAccent : _jellyfinBlue;
    final label = switch (size) {
      PosterSize.small => AppLocalizations.of(context).small,
      PosterSize.medium => AppLocalizations.of(context).medium,
      PosterSize.large => AppLocalizations.of(context).large,
      PosterSize.extraLarge => AppLocalizations.of(context).extraLarge,
    };
    return InkWell(
      onTap: () => vm.setPosterSize(size),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            _radioCircle(selected, accent),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: selected ? Colors.white : Colors.white.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected, Color accent) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? accent : Colors.white.withAlpha(128),
          width: 2,
        ),
        color: selected ? accent : Colors.transparent,
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
    );
  }
}

class _BookMediaTabs extends StatelessWidget {
  final _BookMediaTab activeTab;
  final ValueChanged<_BookMediaTab> onChanged;

  const _BookMediaTabs({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _BookFilterChip(
            label: l10n.books,
            selected: activeTab == _BookMediaTab.books,
            onTap: () => onChanged(_BookMediaTab.books),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BookFilterChip(
            label: l10n.audiobooks,
            selected: activeTab == _BookMediaTab.audiobooks,
            onTap: () => onChanged(_BookMediaTab.audiobooks),
          ),
        ),
      ],
    );
  }
}

class _BookOrganizeChips extends StatelessWidget {
  final _BookOrganizeMode mode;
  final ValueChanged<_BookOrganizeMode> onChanged;

  const _BookOrganizeChips({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BookFilterChip(
          label: l10n.all,
          selected: mode == _BookOrganizeMode.all,
          onTap: () => onChanged(_BookOrganizeMode.all),
        ),
        _BookFilterChip(
          label: l10n.author,
          selected: mode == _BookOrganizeMode.author,
          onTap: () => onChanged(_BookOrganizeMode.author),
        ),
        _BookFilterChip(
          label: l10n.genres,
          selected: mode == _BookOrganizeMode.genre,
          onTap: () => onChanged(_BookOrganizeMode.genre),
        ),
      ],
    );
  }
}

class _BookStatusCategories extends StatelessWidget {
  final PlayedStatusFilter playedFilter;
  final bool favoriteFilter;
  final ValueChanged<PlayedStatusFilter> onPlayedFilterChanged;
  final ValueChanged<bool> onFavoriteFilterChanged;

  const _BookStatusCategories({
    required this.playedFilter,
    required this.favoriteFilter,
    required this.onPlayedFilterChanged,
    required this.onFavoriteFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BookFilterChip(
          label: l10n.all,
          selected: playedFilter == PlayedStatusFilter.all && !favoriteFilter,
          onTap: () {
            onFavoriteFilterChanged(false);
            onPlayedFilterChanged(PlayedStatusFilter.all);
          },
        ),
        _BookFilterChip(
          label: l10n.unread,
          selected: playedFilter == PlayedStatusFilter.unwatched,
          onTap: () => onPlayedFilterChanged(PlayedStatusFilter.unwatched),
        ),
        _BookFilterChip(
          label: l10n.readStatus,
          selected: playedFilter == PlayedStatusFilter.watched,
          onTap: () => onPlayedFilterChanged(PlayedStatusFilter.watched),
        ),
        _BookFilterChip(
          label: l10n.favorites,
          selected: favoriteFilter,
          onTap: () => onFavoriteFilterChanged(!favoriteFilter),
        ),
      ],
    );
  }
}

class _BookFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BookFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? const Color(0x3332B9E8) : const Color(0x22131E33),
          border: Border.all(
            color: selected ? _bookAccent : const Color(0x556388A8),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFFD9F2FF) : const Color(0xFFAECBE2),
          ),
        ),
      ),
    );
  }
}

class _BookBottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _BookBottomNavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? _bookAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? const Color(0xFF0E2339) : const Color(0xFFDCEBFF),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? const Color(0xFF0E2339) : const Color(0xFFDCEBFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrivoxBook {
  final String id;
  final String title;
  final String authorName;
  final List<String> isbns;
  final String? description;
  final String? language;
  final int? copyrightYear;
  final int? sectionCount;
  final List<String> genres;
  final List<String> readerNames;
  final String? archiveUrl;
  final String? zipUrl;
  final String? rssUrl;
  final String? librivoxUrl;
  final int totalTimeSecs;

  const _LibrivoxBook({
    required this.id,
    required this.title,
    required this.authorName,
    required this.isbns,
    required this.description,
    required this.language,
    required this.copyrightYear,
    required this.sectionCount,
    required this.genres,
    required this.readerNames,
    required this.archiveUrl,
    required this.zipUrl,
    required this.rssUrl,
    required this.librivoxUrl,
    required this.totalTimeSecs,
  });

  factory _LibrivoxBook.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? '').toString().trim();
    final title = (map['title'] as String? ?? '').trim();
    final authors = (map['authors'] as List?) ?? const [];
    final authorName = authors
        .whereType<Map>()
        .map((a) {
          final first = (a['first_name'] as String? ?? '').trim();
          final last = (a['last_name'] as String? ?? '').trim();
          return [first, last].where((n) => n.isNotEmpty).join(' ');
        })
        .where((name) => name.isNotEmpty)
        .firstOrNull ?? 'Unknown Author';
    final isbns = <String>{};
    String? normalizeIsbn(dynamic raw) {
      final value = (raw ?? '').toString().trim();
      if (value.isEmpty) return null;
      final normalized = value.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
      if (normalized.length == 10 || normalized.length == 13) {
        return normalized;
      }
      return null;
    }
    for (final key in const ['isbn', 'isbn13', 'isbn_13', 'isbn10', 'isbn_10']) {
      final raw = map[key];
      if (raw is List) {
        for (final item in raw) {
          final parsed = normalizeIsbn(item);
          if (parsed != null) isbns.add(parsed);
        }
      } else {
        final parsed = normalizeIsbn(raw);
        if (parsed != null) isbns.add(parsed);
      }
    }
    final description = (map['description'] as String?)?.trim();
    final language = (map['language'] as String?)?.trim();
    // LibriVox returns these as JSON strings (e.g. "1963", "20"), not numbers.
    int? parseField(dynamic v) =>
        v is num ? v.toInt() : v is String ? int.tryParse(v) : null;
    final copyrightYear = parseField(map['copyright_year']);
    final sectionCount = parseField(map['num_sections']);
    final totalTimeSecs = parseField(map['totaltimesecs']) ?? 0;
    final genres = ((map['genres'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((g) => (g['name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    final readerNames = ((map['readers'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((reader) {
          final first = (reader['first_name'] as String? ?? '').trim();
          final last = (reader['last_name'] as String? ?? '').trim();
          final display = (reader['display_name'] as String? ?? '').trim();
          if (display.isNotEmpty) return display;
          return [first, last].where((n) => n.isNotEmpty).join(' ');
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    // Treat empty strings from the API as null.
    String? parseUrl(String key) {
      final v = (map[key] as String? ?? '').trim();
      return v.isEmpty ? null : v;
    }
    final archiveUrl = parseUrl('url_iarchive');
    final zipUrl = parseUrl('url_zip_file');
    final rssUrl = parseUrl('url_rss');
    final librivoxUrl = parseUrl('url_librivox');

    return _LibrivoxBook(
      id: id,
      title: title,
      authorName: authorName,
      isbns: isbns.toList(),
      description: description,
      language: language,
      copyrightYear: copyrightYear,
      sectionCount: sectionCount,
      genres: genres,
      readerNames: readerNames,
      archiveUrl: archiveUrl,
      zipUrl: zipUrl,
      rssUrl: rssUrl,
      librivoxUrl: librivoxUrl,
      totalTimeSecs: totalTimeSecs,
    );
  }

  String? get preferredIsbn => isbns.firstOrNull;

  String get formattedDuration {
    if (totalTimeSecs <= 0) return '';
    final hours = totalTimeSecs ~/ 3600;
    final minutes = (totalTimeSecs % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '${totalTimeSecs}s';
  }
}

class _LibrivoxBookDetailScreen extends StatelessWidget {
  final _LibrivoxBook book;
  final String? coverUrl;
  final List<_LibrivoxBook> allBooks;
  final Map<String, String?> coverCache;

  const _LibrivoxBookDetailScreen({
    required this.book,
    required this.allBooks,
    required this.coverCache,
    this.coverUrl,
  });

  Future<void> _openExternal(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorIndex = book.id.hashCode.abs() % _audiobookPlaceholderColors.length;
    final accent = _audiobookPlaceholderColors[colorIndex];
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F182A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.audiobookDetails),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 120,
                      height: 180,
                      child: coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: coverUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _buildCoverFallback(accent),
                            )
                          : _buildCoverFallback(accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            final authorBooks = allBooks
                                .where((b) => b.authorName == book.authorName)
                                .toList();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _LibrivoxAuthorBooksScreen(
                                  author: book.authorName,
                                  books: authorBooks.isNotEmpty
                                      ? authorBooks
                                      : [book],
                                  coverCache: coverCache,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            book.authorName,
                            style: const TextStyle(
                              color: Color(0xFF9EDBFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF9EDBFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (book.formattedDuration.isNotEmpty)
                              _buildDetailChip(book.formattedDuration),
                            if ((book.language ?? '').isNotEmpty)
                              _buildDetailChip(book.language!),
                            if ((book.sectionCount ?? 0) > 0)
                              _buildDetailChip(l10n.sectionCountLabel(book.sectionCount!)),
                            if ((book.copyrightYear ?? 0) > 0)
                              _buildDetailChip('${book.copyrightYear}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                l10n.overview,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (book.description ?? '').trim().isEmpty
                    ? l10n.noLibrivoxDescription
                    : book.description!.trim(),
                style: const TextStyle(
                  color: Color(0xFFD7E8F6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (book.genres.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.genres,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: book.genres
                      .take(20)
                      .map(
                        (genre) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x1F8EC8F0),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0x558EC8F0)),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              color: Color(0xFFD7E8F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (book.readerNames.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.readers,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.readerNames.join(', '),
                  style: const TextStyle(
                    color: Color(0xFFD7E8F6),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                l10n.openLinks,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if ((book.librivoxUrl ?? '').isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _openExternal(book.librivoxUrl!),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l10n.librivoxPage),
                    ),
                  if ((book.archiveUrl ?? '').isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _openExternal(book.archiveUrl!),
                      icon: const Icon(Icons.archive_rounded),
                      label: Text(l10n.internetArchive),
                    ),
                  if ((book.rssUrl ?? '').isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _openExternal(book.rssUrl!),
                      icon: const Icon(Icons.rss_feed_rounded),
                      label: Text(l10n.rssFeed),
                    ),
                  if ((book.zipUrl ?? '').isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _openExternal(book.zipUrl!),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(l10n.downloadZip),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(44),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCoverFallback(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withAlpha(165)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 40),
    );
  }
}

class _LibrivoxAuthorsScreen extends StatelessWidget {
  final List<_LibrivoxBook> books;
  final Map<String, String?> coverCache;

  const _LibrivoxAuthorsScreen({
    required this.books,
    required this.coverCache,
  });

  @override
  Widget build(BuildContext context) {
    final authorMap = <String, List<_LibrivoxBook>>{};
    for (final book in books) {
      authorMap.putIfAbsent(book.authorName, () => []).add(book);
    }
    final authors = authorMap.keys.toList()..sort();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F182A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.authorsCountTitle(authors.length)),
      ),
      body: ListView.builder(
        itemCount: authors.length,
        itemBuilder: (context, index) {
          final author = authors[index];
          final authorBooks = authorMap[author]!;
          final initial =
              author.trim().isNotEmpty ? author.trim()[0].toUpperCase() : '?';
          final avatarColor = _audiobookPlaceholderColors[
              author.hashCode.abs() % _audiobookPlaceholderColors.length];
          return ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _LibrivoxAuthorBooksScreen(
                  author: author,
                  books: authorBooks,
                  coverCache: coverCache,
                ),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: avatarColor,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              author,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              l10n.audiobookCountLabel(authorBooks.length),
              style: const TextStyle(color: Color(0xFF9EDBFF), fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF5C7290)),
          );
        },
      ),
    );
  }
}

class _LibrivoxAuthorBooksScreen extends StatelessWidget {
  final String author;
  final List<_LibrivoxBook> books;
  final Map<String, String?> coverCache;

  const _LibrivoxAuthorBooksScreen({
    required this.author,
    required this.books,
    required this.coverCache,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F182A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(author, overflow: TextOverflow.ellipsis),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          8,
          isMobile ? 16 : 24,
          24,
        ),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final book = books[index];
          final coverUrl = coverCache[book.id];
          final colorIndex =
              book.id.hashCode.abs() % _audiobookPlaceholderColors.length;
          final placeholderColor = _audiobookPlaceholderColors[colorIndex];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _LibrivoxBookDetailScreen(
                  book: book,
                  coverUrl: coverUrl,
                  allBooks: books,
                  coverCache: coverCache,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2740),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 90,
                      child: coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: placeholderColor,
                                alignment: Alignment.center,
                                child: const Icon(Icons.headphones_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            )
                          : Container(
                              color: placeholderColor,
                              alignment: Alignment.center,
                              child: const Icon(Icons.headphones_rounded,
                                  color: Colors.white, size: 20),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (book.formattedDuration.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            book.formattedDuration,
                            style: const TextStyle(
                              color: Color(0xFF9EDBFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (book.genres.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            book.genres.take(2).join(' · '),
                            style: const TextStyle(
                              color: Color(0xFF5C7290),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF5C7290)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverBook {
  final String identity;
  final String title;
  final String author;
  final String? coverUrl;
  final String? workKey;
  final int? firstPublishYear;

  const _DiscoverBook({
    required this.identity,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.workKey,
    required this.firstPublishYear,
  });

  factory _DiscoverBook.fromOpenLibraryMap(Map<String, dynamic> map) {
    final key = map['key'] as String? ?? '';
    final title = (map['title'] as String? ?? '').trim();
    final authorNamesFromSearch = (map['author_name'] as List?)
        ?.whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList() ??
      const <String>[];
    final authorNamesFromWorks = (map['authors'] as List?)
        ?.whereType<Map>()
        .map((a) => (a['name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList() ??
      const <String>[];
    final author = authorNamesFromSearch.isNotEmpty
      ? authorNamesFromSearch.first
      : authorNamesFromWorks.isNotEmpty
        ? authorNamesFromWorks.first
        : 'Unknown Author';

    final coverId = (map['cover_i'] as num?)?.toInt() ??
      (map['cover_id'] as num?)?.toInt();
    final coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
        : null;
    final firstPublishYear = (map['first_publish_year'] as num?)?.toInt();

    return _DiscoverBook(
      identity: key.isNotEmpty ? key : '$title::$author',
      title: title,
      author: author,
      coverUrl: coverUrl,
      workKey: key.startsWith('/works/') ? key : null,
      firstPublishYear: firstPublishYear,
    );
  }
}

class _HoverMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _HoverMarqueeText({
    required this.text,
    required this.style,
  });

  @override
  State<_HoverMarqueeText> createState() => _HoverMarqueeTextState();
}

class _HoverMarqueeTextState extends State<_HoverMarqueeText> {
  final ScrollController _controller = ScrollController();
  bool _hovering = false;
  bool _running = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runMarquee() async {
    if (_running || !_hovering) return;
    _running = true;
    try {
      while (_hovering && mounted) {
        if (!_controller.hasClients) break;
        final max = _controller.position.maxScrollExtent;
        if (max <= 0) break;

        final forwardMs = (max * 24).clamp(700, 4200).toInt();
        final backwardMs = (max * 18).clamp(500, 3200).toInt();

        await _controller.animateTo(
          max,
          duration: Duration(milliseconds: forwardMs),
          curve: Curves.linear,
        );
        if (!_hovering || !mounted) break;
        await Future.delayed(const Duration(milliseconds: 240));
        if (!_hovering || !mounted) break;
        await _controller.animateTo(
          0,
          duration: Duration(milliseconds: backwardMs),
          curve: Curves.easeOut,
        );
        if (!_hovering || !mounted) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hovering = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_runMarquee());
          }
        });
      },
      onExit: (_) {
        _hovering = false;
        if (_controller.hasClients) {
          _controller.animateTo(
            0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
          );
        }
      },
      child: ClipRect(
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              widget.text,
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              style: widget.style,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverBookDetailScreen extends StatefulWidget {
  final _DiscoverBook book;

  const _DiscoverBookDetailScreen({required this.book});

  @override
  State<_DiscoverBookDetailScreen> createState() => _DiscoverBookDetailScreenState();
}

class _DiscoverBookDetailScreenState extends State<_DiscoverBookDetailScreen> {
  late final Future<_OpenLibraryWorkDetail?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<_OpenLibraryWorkDetail?> _loadDetail() async {
    final workKey = widget.book.workKey;
    if (workKey == null) return null;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    try {
      final workFuture = dio.get<Map<String, dynamic>>(
        'https://openlibrary.org$workKey.json',
      );
      final editionFuture = _loadOpenLibraryEditionDescription(dio, workKey);
      final googleFuture = _loadGoogleBooksDescription(dio);

      final workMap = (await workFuture).data;
      if (workMap == null) return null;

      String? editionDescription;
      try {
        editionDescription = await editionFuture.timeout(
          const Duration(milliseconds: 1600),
        );
      } catch (_) {
        editionDescription = null;
      }

      String? googleDescription;
      if (editionDescription == null || editionDescription.trim().isEmpty) {
        try {
          googleDescription = await googleFuture.timeout(
            const Duration(milliseconds: 1600),
          );
        } catch (_) {
          googleDescription = null;
        }
      }

      final detailFromWork = _OpenLibraryWorkDetail.fromMap(workMap);
      final description =
          editionDescription ??
          googleDescription ??
          detailFromWork.description;

      return _OpenLibraryWorkDetail(
        description: description,
        subjects: detailFromWork.subjects,
      );
    } catch (_) {
      return null;
    } finally {
      dio.close(force: true);
    }
  }

  Future<String?> _loadOpenLibraryEditionDescription(
    Dio dio,
    String workKey,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        'https://openlibrary.org$workKey/editions.json',
        queryParameters: const {'limit': 30},
      );
      final data = response.data;
      if (data == null) return null;

      final entries = (data['entries'] as List?)?.whereType<Map>().toList() ??
          const <Map>[];
      for (final entry in entries) {
        final description = _OpenLibraryWorkDetail.extractDescription(entry);
        if (description != null && description.trim().isNotEmpty) {
          return description.trim();
        }
      }
    } catch (_) {
      // Ignore fallback failure and continue to secondary sources.
    }
    return null;
  }

  Future<String?> _loadGoogleBooksDescription(Dio dio) async {
    try {
      final query =
          'intitle:${widget.book.title} inauthor:${widget.book.author}';
      final response = await dio.get<Map<String, dynamic>>(
        'https://www.googleapis.com/books/v1/volumes',
        queryParameters: {
          'q': query,
          'printType': 'books',
          'maxResults': 5,
          'orderBy': 'relevance',
        },
      );
      final data = response.data;
      if (data == null) return null;
      final items =
          (data['items'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
              const <Map<String, dynamic>>[];
      for (final item in items) {
        final volumeInfo = item['volumeInfo'];
        if (volumeInfo is! Map) continue;
        final description = (volumeInfo['description'] as String?)?.trim();
        if (description != null && description.isNotEmpty) {
          return description;
        }
      }
    } catch (_) {
      // Ignore fallback failure and keep existing no-description behavior.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F182A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.details),
      ),
      body: SafeArea(
        child: FutureBuilder<_OpenLibraryWorkDetail?>(
          future: _detailFuture,
          builder: (context, snapshot) {
            final detail = snapshot.data;
            final description = detail?.description;
            final subjects = detail?.subjects ?? const <String>[];
            final width = MediaQuery.sizeOf(context).width;
            final horizontalPadding =
                width >= 1200 ? 72.0 : width >= 800 ? 40.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 132,
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: book.coverUrl == null
                                ? Container(
                                    color: const Color(0xFF2C77B7),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.auto_stories_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: book.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: const Color(0xFF2C77B7),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.auto_stories_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              book.author,
                              style: const TextStyle(
                                color: Color(0xFF9EDBFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (book.firstPublishYear != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.firstPublished(book.firstPublishYear!),
                                style: const TextStyle(
                                  color: Color(0xFFBDD8EE),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.overview,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(color: _bookAccent),
                    )
                  else
                    Text(
                      (description == null || description.trim().isEmpty)
                          ? l10n.noOpenLibraryOverview
                          : description,
                      style: const TextStyle(
                        color: Color(0xFFD7E8F6),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  if (subjects.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      l10n.subjects,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: subjects
                          .take(24)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x1F8EC8F0),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0x558EC8F0)),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  color: Color(0xFFD7E8F6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OpenLibraryWorkDetail {
  final String? description;
  final List<String> subjects;

  const _OpenLibraryWorkDetail({required this.description, required this.subjects});

  factory _OpenLibraryWorkDetail.fromMap(Map<String, dynamic> map) {
    final description = extractDescription(map);

    final subjects = ((map['subjects'] as List?) ?? const <dynamic>[])
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return _OpenLibraryWorkDetail(description: description, subjects: subjects);
  }

  static String? extractDescription(Map map) {
    final dynamic rawDescription = map['description'];
    if (rawDescription is String) {
      return rawDescription;
    }
    if (rawDescription is Map) {
      return rawDescription['value'] as String?;
    }

    final dynamic rawFirstSentence = map['first_sentence'];
    if (rawFirstSentence is String) {
      return rawFirstSentence;
    }
    if (rawFirstSentence is Map) {
      return rawFirstSentence['value'] as String?;
    }

    return null;
  }
}
