import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/viewmodels/seerr_person_view_model.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';

const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';
const _tmdbProfileLarge = 'https://image.tmdb.org/t/p/w500';

class SeerrPersonScreen extends StatefulWidget {
  final String personId;

  const SeerrPersonScreen({super.key, required this.personId});

  @override
  State<SeerrPersonScreen> createState() =>
      _SeerrPersonScreenState();
}

class _SeerrPersonScreenState extends State<SeerrPersonScreen> {
  SeerrPersonViewModel? _vm;
  bool _initializing = true;
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = await GetIt.instance.getAsync<SeerrRepository>();
    final vm = SeerrPersonViewModel(repo);
    vm.addListener(_onChanged);

    if (!mounted) {
      vm.dispose();
      return;
    }

    setState(() {
      _vm = vm;
      _initializing = false;
    });

    _loadPerson();
  }

  void _loadPerson() {
    final vm = _vm;
    if (vm == null) return;
    final id = int.tryParse(widget.personId);
    if (id == null) return;
    vm.load(id);
  }

  @override
  void dispose() {
    _vm?.removeListener(_onChanged);
    _vm?.dispose();
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
              onPressed: _loadPerson,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final person = s.person;
    if (person == null) return const SizedBox.shrink();

    return _buildContent(person, s);
  }

  Widget _buildContent(SeerrPersonDetails person, SeerrPersonState s) {
    final theme = Theme.of(context);
    final topPad = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(32, topPad + 16, 32, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: person.profilePath != null
                      ? CachedNetworkImage(
                          imageUrl: '$_tmdbProfileLarge${person.profilePath}',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _profilePlaceholder(),
                        )
                      : _profilePlaceholder(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        person.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (person.knownForDepartment != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          person.knownForDepartment!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.white60),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildBirthInfo(person),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (person.biography != null && person.biography!.isNotEmpty)
          SliverToBoxAdapter(child: _buildBiography(person.biography!)),
        if (s.castCredits.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildCreditsRow('Appearances', s.castCredits, true),
          ),
        if (s.crewCredits.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildCreditsRow('Crew', s.crewCredits, false),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _profilePlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[800],
      child: const Icon(Icons.person, color: Colors.white38, size: 48),
    );
  }

  Widget _buildBirthInfo(SeerrPersonDetails person) {
    final parts = <String>[];

    if (person.birthday != null) {
      final formatted = _formatDate(person.birthday!);
      if (formatted != null) {
        if (person.deathday != null) {
          final deathFormatted = _formatDate(person.deathday!);
          parts.add('$formatted — ${deathFormatted ?? person.deathday}');
        } else {
          final age = _calculateAge(person.birthday!);
          parts.add(age != null ? '$formatted (age $age)' : formatted);
        }
      }
    }

    if (person.placeOfBirth != null) {
      parts.add(person.placeOfBirth!);
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join('\n'),
      style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
    );
  }

  Widget _buildBiography(String bio) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biography',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            maxLines: _bioExpanded ? null : 4,
            overflow: _bioExpanded ? null : TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _bioExpanded = !_bioExpanded),
            child: Text(
              _bioExpanded ? 'Show Less' : 'Show More',
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsRow(
      String title, List<SeerrDiscoverItem> items, bool isCast) {
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    final cardExpansion =
      GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);
    return LibraryRow(
      title: title,
      children: items
          .map((item) => MediaCard(
                title: item.displayTitle,
                subtitle: isCast
                    ? item.character
                    : item.job ?? item.department,
                imageUrl: item.posterPath != null
                    ? '$_tmdbPosterBase${item.posterPath}'
                    : null,
                width: 130,
                aspectRatio: 2 / 3,
                seerrMediaType: item.mediaType,
                seerrStatus: item.mediaInfo?.status,
                focusColor: focusColor,
                cardFocusExpansion: cardExpansion,
                onTap: () {
                  final mediaType = item.mediaType ?? 'movie';
                  context.push(
                    Destinations.seerrMedia(item.id.toString()),
                    extra: {'mediaType': mediaType},
                  );
                },
              ))
          .toList(),
    );
  }

  static String? _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return null;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static int? _calculateAge(String birthday) {
    final birth = DateTime.tryParse(birthday);
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
}
