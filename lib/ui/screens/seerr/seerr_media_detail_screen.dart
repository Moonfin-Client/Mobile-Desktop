import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/viewmodels/seerr_media_detail_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/seerr_preferences.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';

const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';
const _tmdbBackdropBase = 'https://image.tmdb.org/t/p/w1280';
const _tmdbProfileBase = 'https://image.tmdb.org/t/p/w185';

class SeerrMediaDetailScreen extends StatefulWidget {
  final String itemId;

  const SeerrMediaDetailScreen({super.key, required this.itemId});

  @override
  State<SeerrMediaDetailScreen> createState() =>
      _SeerrMediaDetailScreenState();
}

class _SeerrMediaDetailScreenState
    extends State<SeerrMediaDetailScreen> {
  SeerrMediaDetailViewModel? _vm;
  bool _initializing = true;
  final _userPrefs = GetIt.instance<UserPreferences>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = await GetIt.instance.getAsync<SeerrRepository>();
    final prefs = GetIt.instance<SeerrPreferences>();
    final vm = SeerrMediaDetailViewModel(repo, prefs);
    vm.addListener(_onChanged);

    if (!mounted) {
      vm.dispose();
      return;
    }

    setState(() {
      _vm = vm;
      _initializing = false;
    });

    _loadDetails();
  }

  void _showFeedback(SeerrMediaDetailState s) {
    if (s.requestSuccess != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.requestSuccess!),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      _vm?.clearFeedback();
    } else if (s.requestError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.requestError!),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      _vm?.clearFeedback();
    }
  }

  void _loadDetails() {
    final vm = _vm;
    if (vm == null) return;

    final tmdbId = int.tryParse(widget.itemId);
    if (tmdbId == null) return;

    final extra = GoRouterState.of(context).extra;
    final mediaType =
        (extra is Map<String, dynamic> ? extra['mediaType'] as String? : null) ??
            'movie';

    vm.load(tmdbId, mediaType);
  }

  @override
  void dispose() {
    _vm?.removeListener(_onChanged);
    _vm?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final s = _vm?.state;
    if (s != null) _showFeedback(s);
    setState(() {});
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
              onPressed: _loadDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildContent(s);
  }

  Widget _buildContent(SeerrMediaDetailState s) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (s.backdropPath != null)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: '$_tmdbBackdropBase${s.backdropPath}',
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ),
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(s)),
            SliverToBoxAdapter(child: _buildMetadata(s)),
            SliverToBoxAdapter(child: _buildRequestSection(s)),
            if (s.overview != null && s.overview!.isNotEmpty)
              SliverToBoxAdapter(child: _buildOverview(s.overview!)),
            if (s.credits != null && s.credits!.cast.isNotEmpty)
              SliverToBoxAdapter(child: _buildCastRow(s.credits!.cast)),
            if (s.similar.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRelatedRow('Similar', s.similar),
              ),
            if (s.recommendations.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRelatedRow('Recommendations', s.recommendations),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(SeerrMediaDetailState s) {
    final theme = Theme.of(context);
    final topPad = MediaQuery.of(context).padding.top;
    final navbarIsTop =
        _userPrefs.get(UserPreferences.navbarPosition) == NavbarPosition.top;
    final navbarHeight = navbarIsTop
        ? (PlatformDetection.isTV
            ? 95.0
            : PlatformDetection.useMobileUi
                ? 60.0
                : 80.0)
        : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(32, topPad + navbarHeight + 16, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.posterPath != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: '$_tmdbPosterBase${s.posterPath}',
                  width: 180,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const SizedBox(width: 180, height: 270),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            s.displayTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (s.tagline != null && s.tagline!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              s.tagline!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          _buildStatusBadge(s),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SeerrMediaDetailState s) {
    final Color color;
    if (s.isFullyAvailable) {
      color = Colors.green;
    } else if (s.isPartiallyAvailable || s.isProcessing) {
      color = Colors.orange;
    } else if (s.hasExistingRequest) {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        s.requestStatusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMetadata(SeerrMediaDetailState s) {
    final chips = <Widget>[];

    final year = _extractYear(s);
    if (year != null) chips.add(_metaText(year));

    if (s.runtime != null && s.runtime! > 0) {
      chips.add(_metaText(_formatRuntime(s.runtime!)));
    }

    if (s.voteAverage != null && s.voteAverage! > 0) {
      chips.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
          const SizedBox(width: 2),
          Text(
            s.voteAverage!.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ));
    }

    if (s.isTv) {
      if (s.numberOfSeasons != null) {
        final label = s.numberOfSeasons == 1 ? 'Season' : 'Seasons';
        chips.add(_metaText('${s.numberOfSeasons} $label'));
      }
      if (s.tvStatus != null) {
        chips.add(_tvStatusBadge(s.tvStatus!));
      }
    }

    if (s.budget != null && s.budget! > 0) {
      chips.add(_metaText('Budget: \$${_formatMoney(s.budget!)}'));
    }
    if (s.revenue != null && s.revenue! > 0) {
      chips.add(_metaText('Revenue: \$${_formatMoney(s.revenue!)}'));
    }

    final mediaType = s.isTv ? 'tv' : 'movie';

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 6, children: chips),
          if (s.genres.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: s.genres
                  .map((g) => ActionChip(
                        label: Text(g.name,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.white12,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push(
                          Destinations.seerrBrowseWith(
                            filterId: g.id.toString(),
                            filterName: g.name,
                            mediaType: mediaType,
                            filterType: 'genre',
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (s.networks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: s.networks
                  .map((n) => ActionChip(
                        label: Text(n.name,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white54)),
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: Colors.white24),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push(
                          Destinations.seerrBrowseWith(
                            filterId: n.id.toString(),
                            filterName: n.name,
                            mediaType: mediaType,
                            filterType: 'network',
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (s.keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: s.keywords
                  .map((k) => ActionChip(
                        label: Text(k.name,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white60)),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push(
                          Destinations.seerrBrowseWith(
                            filterId: k.id.toString(),
                            filterName: k.name,
                            mediaType: mediaType,
                            filterType: 'keyword',
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestSection(SeerrMediaDetailState s) {
    final vm = _vm!;
    final canShowRequest = vm.canRequest &&
        !s.isFullyAvailable &&
        (!s.hasExistingRequest || s.isPartiallyAvailable);
    final requestLabel = s.isPartiallyAvailable ? 'Request More' : 'Request';
    final canManage = vm.canManageRequests;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.pendingRequests.isNotEmpty) ...[
            for (final req in s.pendingRequests)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.white54),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Requested by ${req.requestedBy?.bestName ?? 'Unknown'}',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 8),
                      _ApproveDeclineButtons(
                        isLoading: s.isRequesting,
                        onApprove: () => vm.approveRequest(req.id),
                        onDecline: () => vm.declineRequest(req.id),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 4),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (s.isFullyAvailable || s.isPartiallyAvailable)
                ElevatedButton.icon(
                  onPressed: () => _playInMoonfin(s),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play in Moonfin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              if (canShowRequest)
                ElevatedButton.icon(
                  onPressed: s.isRequesting ? null : () => _showRequestSheet(),
                  icon: s.isRequesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(requestLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
              if (s.activeRequests.isNotEmpty && !s.isFullyAvailable)
                OutlinedButton.icon(
                  onPressed: s.isRequesting
                      ? null
                      : () => _showCancelDialog(s),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[300],
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
      ),
    );
  }

  Widget _buildCastRow(List<SeerrCastMember> cast) {
    final visible = cast.length > 20 ? cast.sublist(0, 20) : cast;
    return LibraryRow(
      title: 'Cast',
      rowHeight: 170,
      children: visible
          .map((m) => _CastCard(
                member: m,
                onTap: () => context.push(
                  Destinations.seerrPerson(m.id.toString()),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRelatedRow(String title, List<SeerrDiscoverItem> items) {
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    final cardExpansion =
        GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);
    return LibraryRow(
      title: title,
      rowHeight: 236,
      children: items
          .map((item) => MediaCard(
                title: item.displayTitle,
                subtitle: _yearFromItem(item),
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

  void _showRequestSheet() {
    final vm = _vm!;
    final s = vm.state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RequestBottomSheet(
        vm: vm,
        isTv: s.isTv,
        numberOfSeasons: s.numberOfSeasons ?? 0,
        requestedSeasons: s.requestedSeasons,
      ),
    );
  }

  void _showCancelDialog(SeerrMediaDetailState s) {
    final active = s.activeRequests;
    if (active.isEmpty) return;

    final title = s.displayTitle;
    final count = active.length;
    final message = count == 1
        ? 'Cancel request for "$title"?'
        : 'Cancel $count requests for "$title"?';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Cancel Request',
            style: TextStyle(color: Colors.white)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelRequests(active);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red[300]),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequests(List<SeerrRequest> requests) async {
    final vm = _vm;
    if (vm == null) return;
    await vm.cancelRequests(requests.map((r) => r.id).toList());
  }

  Future<void> _playInMoonfin(SeerrMediaDetailState s) async {
    final client = GetIt.instance<MediaServerClient>();
    final externalIds = s.externalIds;
    final tmdbId = externalIds?.tmdbId ?? (s.tmdbId != 0 ? s.tmdbId : null);
    final tvdbId = externalIds?.tvdbId;
    final imdbId = externalIds?.imdbId;
    final title = s.displayTitle;
    final mediaType = s.isMovie ? 'Movie' : 'Series';

    try {
      final response = await client.itemsApi.getItems(
        searchTerm: title,
        includeItemTypes: [mediaType],
        recursive: true,
        limit: 50,
        fields: 'ProviderIds',
      );

      final items = (response['Items'] as List?)
              ?.cast<Map<String, dynamic>?>() ??
          <Map<String, dynamic>?>[];

      Map<String, dynamic>? match;

      if (tmdbId != null) {
        match = items.firstWhere(
          (item) => (item!['ProviderIds'] as Map?)?['Tmdb'] == tmdbId.toString(),
          orElse: () => null,
        );
      }

      if (match == null && tvdbId != null) {
        match = items.firstWhere(
          (item) => (item!['ProviderIds'] as Map?)?['Tvdb'] == tvdbId.toString(),
          orElse: () => null,
        );
      }

      if (match == null && imdbId != null) {
        match = items.firstWhere(
          (item) => (item!['ProviderIds'] as Map?)?['Imdb'] == imdbId,
          orElse: () => null,
        );
      }

      match ??= items.firstWhere(
        (item) => (item!['Name'] as String?)?.toLowerCase() == title.toLowerCase(),
        orElse: () => null,
      );

      if (!mounted) return;

      if (match != null) {
        final itemId = match['Id'] as String;
        context.push(Destinations.item(itemId));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item not found in your Moonfin library'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error searching library'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String? _extractYear(SeerrMediaDetailState s) {
    final date = s.releaseDate ?? s.firstAirDate;
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }

  static String? _yearFromItem(SeerrDiscoverItem item) {
    final date = item.releaseDate ?? item.firstAirDate;
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }

  static Widget _metaText(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      );

  static Widget _tvStatusBadge(String status) {
    final lower = status.toLowerCase();
    final Color bg;
    if (lower == 'returning series' || lower == 'continuing') {
      bg = Colors.green;
    } else if (lower == 'ended' || lower == 'canceled') {
      bg = Colors.red;
    } else {
      bg = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: bg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _formatRuntime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  static String _formatMoney(int amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }
}

class _ApproveDeclineButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const _ApproveDeclineButtons({
    required this.isLoading,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: isLoading ? null : onApprove,
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          tooltip: 'Approve',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: isLoading ? null : onDecline,
          icon: Icon(Icons.cancel_outlined, color: Colors.red[300], size: 20),
          tooltip: 'Decline',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _CastCard extends StatefulWidget {
  final SeerrCastMember member;
  final VoidCallback? onTap;

  const _CastCard({required this.member, this.onTap});

  @override
  State<_CastCard> createState() => _CastCardState();
}

class _CastCardState extends State<_CastCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    return Focus(
      onFocusChange: (f) => setFocused(f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setHovered(true),
          onExit: (_) => setHovered(false),
          child: AnimatedScale(
            scale: showFocusBorder ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: showFocusBorder
                          ? Border.all(color: focusColor, width: 2)
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: m.profilePath != null
                          ? CachedNetworkImageProvider(
                              '$_tmdbProfileBase${m.profilePath}')
                          : null,
                      child: m.profilePath == null
                          ? const Icon(Icons.person,
                              color: Colors.white38, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (m.character != null)
                    Text(
                      m.character!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestBottomSheet extends StatefulWidget {
  final SeerrMediaDetailViewModel vm;
  final bool isTv;
  final int numberOfSeasons;
  final Set<int> requestedSeasons;

  const _RequestBottomSheet({
    required this.vm,
    required this.isTv,
    required this.numberOfSeasons,
    this.requestedSeasons = const {},
  });

  @override
  State<_RequestBottomSheet> createState() => _RequestBottomSheetState();
}

class _RequestBottomSheetState extends State<_RequestBottomSheet> {
  bool _is4k = false;
  bool _allSeasons = true;
  final Set<int> _selectedSeasons = {};
  bool _showAdvanced = false;

  List<SeerrServiceServerDetails>? _servers;
  int? _selectedServerId;
  int? _selectedProfileId;
  int? _selectedRootFolderId;
  bool _loadingServers = false;

  @override
  void initState() {
    super.initState();
    if (widget.vm.canRequestAdvanced) {
      _loadServers();
    }
  }

  Future<void> _loadServers() async {
    setState(() => _loadingServers = true);
    try {
      final repo = GetIt.instance<SeerrRepository>();

      if (widget.isTv) {
        final sonarrServers = await repo.getSonarrServers();
        final details = await Future.wait(
          sonarrServers.map((s) => repo.getSonarrServerDetails(s.id)),
        );
        setState(() {
          _servers = details;
          _applySavedPreferences();
        });
      } else {
        final radarrServers = await repo.getRadarrServers();
        final details = await Future.wait(
          radarrServers.map((s) => repo.getRadarrServerDetails(s.id)),
        );
        setState(() {
          _servers = details;
          _applySavedPreferences();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingServers = false);
    }
  }

  void _applySavedPreferences() {
    final vm = widget.vm;
    final savedServer = _is4k ? vm.saved4kServerId : vm.savedServerId;
    final savedProfile = _is4k ? vm.saved4kProfileId : vm.savedProfileId;
    final savedFolder =
        _is4k ? vm.saved4kRootFolderId : vm.savedRootFolderId;

    if (savedServer != null && savedServer.isNotEmpty) {
      _selectedServerId = int.tryParse(savedServer);
    }
    if (savedProfile != null && savedProfile.isNotEmpty) {
      _selectedProfileId = int.tryParse(savedProfile);
    }
    if (savedFolder != null && savedFolder.isNotEmpty) {
      _selectedRootFolderId = int.tryParse(savedFolder);
    }

    _applyServerDefaults();
  }

  void _applyServerDefaults() {
    final server = _activeServer;
    if (server == null) return;
    _selectedProfileId ??= server.server.activeProfileId;
    final dir = server.server.activeDirectory;
    if (_selectedRootFolderId == null && dir.isNotEmpty) {
      final match = server.rootFolders
          .where((f) => f.path == dir)
          .firstOrNull;
      if (match != null) _selectedRootFolderId = match.id;
    }
  }

  void _submit() {
    List<int>? seasons;
    if (widget.isTv && !_allSeasons) {
      seasons = _selectedSeasons.toList()..sort();
      if (seasons.isEmpty) return;
    }

    widget.vm.submitRequest(
      is4k: _is4k,
      seasons: seasons,
      allSeasons: widget.isTv && _allSeasons,
      profileId: _selectedProfileId,
      rootFolderId: _selectedRootFolderId,
      serverId: _selectedServerId,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request ${widget.isTv ? "Series" : "Movie"}',
              style:
                  theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (widget.vm.canRequest4k)
              SwitchListTile(
                title:
                    const Text('4K', style: TextStyle(color: Colors.white)),
                value: _is4k,
                onChanged: (v) => setState(() {
                  _is4k = v;
                  _selectedProfileId = null;
                  _selectedRootFolderId = null;
                  _applySavedPreferences();
                }),
                contentPadding: EdgeInsets.zero,
              ),
            if (widget.isTv) ...[
              const Divider(color: Colors.white12),
              _buildSeasonSelector(),
            ],
            if (widget.vm.canRequestAdvanced) ...[
              const Divider(color: Colors.white12),
              _buildAdvancedOptions(theme),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Submit Request',
                  style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSelector() {
    final seasonCount = widget.numberOfSeasons;
    final requested = widget.requestedSeasons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('All Seasons',
              style: TextStyle(color: Colors.white)),
          value: _allSeasons,
          onChanged: (v) => setState(() {
            _allSeasons = v ?? true;
            if (_allSeasons) _selectedSeasons.clear();
          }),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (!_allSeasons && seasonCount > 0)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(seasonCount, (i) {
              final num = i + 1;
              final alreadyRequested = requested.contains(num);
              final selected = _selectedSeasons.contains(num);
              return FilterChip(
                label: Text('S$num',
                    style: TextStyle(
                      fontSize: 13,
                      color: alreadyRequested
                          ? Colors.white38
                          : selected
                              ? Colors.white
                              : Colors.white70,
                    )),
                selected: selected,
                onSelected: alreadyRequested
                    ? null
                    : (v) => setState(() {
                          if (v) {
                            _selectedSeasons.add(num);
                          } else {
                            _selectedSeasons.remove(num);
                          }
                        }),
                selectedColor: const Color(0xFF6366F1),
                checkmarkColor: Colors.white,
                disabledColor: Colors.white.withValues(alpha: 0.05),
                backgroundColor: Colors.white12,
                side: BorderSide.none,
              );
            }),
          ),
      ],
    );
  }

  Widget _buildAdvancedOptions(ThemeData theme) {
    return ExpansionTile(
      title: const Text('Advanced Options',
          style: TextStyle(color: Colors.white70)),
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: _showAdvanced,
      onExpansionChanged: (v) => _showAdvanced = v,
      children: [
        if (_loadingServers)
          const Padding(
            padding: EdgeInsets.all(16),
            child:
                Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_servers != null && _servers!.isNotEmpty) ...[
          _buildServerDropdown(),
          const SizedBox(height: 16),
          _buildProfileDropdown(),
          const SizedBox(height: 16),
          _buildRootFolderDropdown(),
        ] else
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'No service servers configured',
              style: TextStyle(color: Colors.white54),
            ),
          ),
      ],
    );
  }

  SeerrServiceServerDetails? get _activeServer {
    if (_servers == null || _servers!.isEmpty) return null;
    if (_selectedServerId == null) return _servers!.first;
    return _servers!
            .where((s) => s.server.id == _selectedServerId)
            .firstOrNull ??
        _servers!.first;
  }

  Widget _buildServerDropdown() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Server',
        labelStyle: TextStyle(color: Colors.white54),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      dropdownColor: const Color(0xFF1A1A2E),
      value: _selectedServerId ?? _servers?.firstOrNull?.server.id,
      items: _servers
          ?.map((s) => DropdownMenuItem(
                value: s.server.id,
                child: Text(
                  '${s.server.name}${s.server.is4k ? " (4K)" : ""}',
                  style: const TextStyle(color: Colors.white),
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() {
        _selectedServerId = v;
        _selectedProfileId = null;
        _selectedRootFolderId = null;
      }),
    );
  }

  Widget _buildProfileDropdown() {
    final profiles = _activeServer?.profiles ?? [];
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Quality Profile',
        labelStyle: TextStyle(color: Colors.white54),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      dropdownColor: const Color(0xFF1A1A2E),
      value: _selectedProfileId ?? profiles.firstOrNull?.id,
      items: profiles
          .map((p) => DropdownMenuItem(
                value: p.id,
                child: Text(p.name,
                    style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedProfileId = v),
    );
  }

  Widget _buildRootFolderDropdown() {
    final folders = _activeServer?.rootFolders ?? [];
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Root Folder',
        labelStyle: TextStyle(color: Colors.white54),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      dropdownColor: const Color(0xFF1A1A2E),
      value: _selectedRootFolderId ?? folders.firstOrNull?.id,
      items: folders
          .map((f) => DropdownMenuItem(
                value: f.id,
                child: Text(f.path,
                    style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedRootFolderId = v),
    );
  }
}
