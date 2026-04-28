import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
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
import '../../widgets/overlay_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/focus/request_initial_focus.dart';

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
  final FocusNode _firstActionFocusNode = FocusNode(debugLabel: 'seerr-first-action');
  final FocusNode _overviewFocusNode = FocusNode(debugLabel: 'seerr-overview');
  final FocusNode _titleFocusNode = FocusNode(debugLabel: 'seerr-title-hidden');
  final ScrollController _wideScrollController = ScrollController();

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
    _firstActionFocusNode.dispose();
    _overviewFocusNode.dispose();
    _titleFocusNode.dispose();
    _wideScrollController.dispose();
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
    final ready = !_initializing &&
        _vm != null &&
        !_vm!.state.isLoading &&
        _vm!.state.error == null;
    return RequestInitialFocus(
      targetNode: (PlatformDetection.isTV && ready) ? _overviewFocusNode : null,
      child: _buildScreenContent(context),
    );
  }

  Widget _buildScreenContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
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
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return _buildContent(s);
  }

  Widget _buildContent(SeerrMediaDetailState s) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final useWideLayout = PlatformDetection.useDesktopUi ||
        PlatformDetection.isTV ||
        (PlatformDetection.useMobileUi && isLandscape);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (s.backdropPath != null)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: '$_tmdbBackdropBase${s.backdropPath}',
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: useWideLayout ? 0.35 : 0.7),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ),
        if (useWideLayout)
          _buildWideScroll(s, l10n)
        else
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(s)),
              SliverToBoxAdapter(child: _buildMetadata(s)),
              SliverToBoxAdapter(child: _buildRequestSection(s)),
              if (s.overview != null && s.overview!.isNotEmpty)
                SliverToBoxAdapter(child: _buildOverview(s.overview!)),
              if (s.credits != null && s.credits!.cast.isNotEmpty)
                SliverToBoxAdapter(child: _buildCastRow(s.credits!.cast, l10n)),
              if (s.similar.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildRelatedRow(l10n.similar, s.similar),
                ),
              if (s.recommendations.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildRelatedRow(l10n.recommendations, s.recommendations),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
      ],
    );
  }

  Widget _buildWideScroll(SeerrMediaDetailState s, AppLocalizations l10n) {
    final size = MediaQuery.of(context).size;
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
    final hSidePad = PlatformDetection.isTV
        ? 56.0
        : PlatformDetection.useDesktopUi
            ? 64.0
            : 32.0;
    final heroHeight = (size.height * 0.62).clamp(360.0, 720.0);
    return CustomScrollView(
      controller: _wideScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: heroHeight,
            child: _buildWideHero(s, hSidePad, topPad + navbarHeight),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hSidePad, 24, hSidePad, 12),
            child: _buildWideOverviewAndStats(s, l10n),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hSidePad, 8, hSidePad, 16),
            child: _buildWideActions(s, l10n),
          ),
        ),
        if (s.credits != null && s.credits!.cast.isNotEmpty)
          SliverToBoxAdapter(child: _buildCastRow(s.credits!.cast, l10n)),
        if (s.similar.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildRelatedRow(l10n.similar, s.similar),
          ),
        if (s.recommendations.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildRelatedRow(l10n.recommendations, s.recommendations),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }

  Widget _buildWideHero(SeerrMediaDetailState s, double hSidePad, double topInset) {
    final theme = Theme.of(context);
    final posterWidth = PlatformDetection.useDesktopUi ? 240.0 : 220.0;
    final posterHeight = posterWidth * 1.5;
    return Padding(
      padding: EdgeInsets.fromLTRB(hSidePad, topInset + 8, hSidePad, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (s.posterPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: '$_tmdbPosterBase${s.posterPath}',
                width: posterWidth,
                height: posterHeight,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  width: posterWidth,
                  height: posterHeight,
                  color: Colors.white12,
                ),
              ),
            ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWideStatusPill(s, l10n: AppLocalizations.of(context)),
                const SizedBox(height: 10),
                Focus(
                  focusNode: _titleFocusNode,
                  onFocusChange: (focused) {
                    if (focused) _scrollToTop();
                  },
                  onKeyEvent: _handleNavbarUpKey,
                  child: Text(
                    _titleWithYear(s),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _wideMetaLine(s),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (s.tagline != null && s.tagline!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${s.tagline!}"',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideStatusPill(SeerrMediaDetailState s, {required AppLocalizations l10n}) {
    final label = _localizedStatusText(s, l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildWideOverviewAndStats(SeerrMediaDetailState s, AppLocalizations l10n) {
    final mediaType = s.isTv ? 'tv' : 'movie';
    final overviewText = (s.overview != null && s.overview!.isNotEmpty)
        ? Text(
            s.overview!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          )
        : null;
    final overviewCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.overview,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (overviewText != null)
          PlatformDetection.isTV
              ? Focus(
                  focusNode: _overviewFocusNode,
                  onFocusChange: (focused) {
                    if (focused) _scrollToTop();
                  },
                  onKeyEvent: _handleNavbarUpKey,
                  child: Builder(
                    builder: (ctx) {
                      final focused = Focus.of(ctx).hasFocus;
                      final focusColor = Color(GetIt.instance<UserPreferences>()
                          .get(UserPreferences.focusColor)
                          .colorValue);
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.fromBorderSide(
                            ThemeRegistry.active.borders.focusBorder.copyWith(
                              color: focused ? focusColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: overviewText,
                      );
                    },
                  ),
                )
              : overviewText,
        if (s.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: s.genres
                .map((g) => _browseChip(
                      label: g.name,
                      color: Colors.white12,
                      onTap: () => context.push(
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: s.networks
                .map((n) => _browseChip(
                      label: n.name,
                      color: Colors.transparent,
                      borderColor: Colors.white24,
                      labelColor: Colors.white70,
                      onTap: () => context.push(
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
            runSpacing: 6,
            children: s.keywords
                .map((k) => _browseChip(
                      label: k.name,
                      color: Colors.white.withValues(alpha: 0.05),
                      labelColor: Colors.white60,
                      dense: true,
                      onTap: () => context.push(
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
    );
    final stats = _buildStatsCard(s, l10n);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              overviewCol,
              const SizedBox(height: 16),
              stats,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: overviewCol),
            const SizedBox(width: 32),
            Expanded(flex: 2, child: stats),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard(SeerrMediaDetailState s, AppLocalizations l10n) {
    final rows = <_StatRow>[];
    if (s.voteAverage != null && s.voteAverage! > 0) {
      rows.add(_StatRow(l10n.tmdbScore, '${(s.voteAverage! * 10).round()}%'));
    }
    final statusText = _productionStatusText(s);
    if (statusText != null) {
      rows.add(_StatRow(l10n.status, statusText));
    }
    if (s.isMovie) {
      final dateLabel = _formatDate(s.releaseDate);
      if (dateLabel != null) {
        rows.add(_StatRow(l10n.releaseDateLabel, dateLabel));
      }
    } else {
      final dateLabel = _formatDate(s.firstAirDate);
      if (dateLabel != null) {
        rows.add(_StatRow(l10n.firstAirDateLabel, dateLabel));
      }
    }
    if (s.isTv) {
      if (s.numberOfSeasons != null && s.numberOfSeasons! > 0) {
        rows.add(_StatRow(l10n.seasonsLabel, s.numberOfSeasons.toString()));
      }
      if (s.numberOfEpisodes != null && s.numberOfEpisodes! > 0) {
        rows.add(_StatRow(l10n.episodesLabel, s.numberOfEpisodes.toString()));
      }
    }
    if (s.revenue != null && s.revenue! > 0) {
      rows.add(_StatRow(l10n.revenueLabel, _formatMoneyFull(s.revenue!)));
    }
    if (s.runtime != null && s.runtime! > 0) {
      rows.add(_StatRow(l10n.runtimeLabel, _formatRuntime(s.runtime!)));
    }
    if (s.budget != null && s.budget! > 0) {
      rows.add(_StatRow(l10n.budgetLabel, _formatMoneyFull(s.budget!)));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.fromBorderSide(ThemeRegistry.active.borders.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, thickness: 1, color: Colors.white10),
          ],
        ],
      ),
    );
  }

  Widget _buildWideActions(SeerrMediaDetailState s, AppLocalizations l10n) {
    final vm = _vm!;
    final canShowRequest = vm.canRequest &&
        !s.isFullyAvailable &&
        (!s.hasExistingRequest || s.isPartiallyAvailable);
    final requestLabel = s.isPartiallyAvailable ? l10n.requestMore : l10n.request;
    final canManage = vm.canManageRequests;
    final trailer = s.bestTrailer;
    final showTrailer = trailer != null;
    final showCancel = s.activeRequests.isNotEmpty && !s.isFullyAvailable;

    final tiles = <Widget>[];
    FocusNode? nextFirstNode = _firstActionFocusNode;
    FocusNode? takeFirst() {
      final n = nextFirstNode;
      nextFirstNode = null;
      return n;
    }

    if (showCancel) {
      tiles.add(_ActionTile(
        icon: Icons.close,
        label: l10n.cancelRequest,
        onTap: s.isRequesting ? null : () => _showCancelDialog(s),
        primary: !(s.isFullyAvailable || s.isPartiallyAvailable),
        focusNode: takeFirst(),
      ));
    } else if (canShowRequest) {
      tiles.add(_ActionTile(
        icon: Icons.add,
        label: requestLabel,
        onTap: s.isRequesting ? null : _showRequestSheet,
        primary: !(s.isFullyAvailable || s.isPartiallyAvailable),
        focusNode: takeFirst(),
      ));
    }
    if (s.isFullyAvailable || s.isPartiallyAvailable) {
      tiles.add(_ActionTile(
        icon: Icons.play_arrow,
        label: l10n.playInMoonfin,
        onTap: () => _playInMoonfin(s),
        primary: tiles.isEmpty,
        focusNode: takeFirst(),
      ));
    }
    if (showTrailer) {
      tiles.add(_ActionTile(
        icon: Icons.movie_outlined,
        label: l10n.trailer,
        onTap: () => _openTrailer(trailer),
        focusNode: takeFirst(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.activeRequests.isNotEmpty) ...[
          for (final req in s.activeRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.white54),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.requestedByName(req.requestedBy?.bestName ?? l10n.unknown),
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canManage && req.status == SeerrRequest.statusPending) ...[
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
          const SizedBox(height: 8),
        ],
        if (tiles.isNotEmpty)
          Wrap(spacing: 16, runSpacing: 16, children: tiles),
      ],
    );
  }

  Widget _browseChip({
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white12,
    Color? borderColor,
    Color labelColor = Colors.white,
    bool dense = false,
  }) =>
      _BrowseChip(
        label: label,
        onTap: onTap,
        color: color,
        borderColor: borderColor,
        labelColor: labelColor,
        dense: dense,
      );

  KeyEventResult _handleNavbarUpKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final cb = NavigationLayout.focusNavbarNotifier.value;
      if (cb != null) {
        cb();
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (identical(node, _titleFocusNode) && _requestFirstActionFocus()) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  bool _requestFirstActionFocus() {
    if (!_firstActionFocusNode.canRequestFocus) return false;
    if (_firstActionFocusNode.context == null) return false;
    _firstActionFocusNode.requestFocus();
    return true;
  }

  void _scrollToTop() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_wideScrollController.hasClients) return;
      final position = _wideScrollController.position;
      if (position.pixels <= position.minScrollExtent) return;
      position.animateTo(
        position.minScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _titleWithYear(SeerrMediaDetailState s) {
    final year = _extractYear(s);
    if (year == null) return s.displayTitle;
    return '${s.displayTitle} ($year)';
  }

  String _wideMetaLine(SeerrMediaDetailState s) {
    final parts = <String>[];
    if (s.runtime != null && s.runtime! > 0) {
      parts.add('${s.runtime} min');
    }
    if (s.genres.isNotEmpty) {
      parts.addAll(s.genres.take(3).map((g) => g.name));
    } else if (s.isTv && s.tvStatus != null) {
      parts.add(s.tvStatus!);
    }
    return parts.join(' \u2022 ');
  }

  String _localizedStatusText(SeerrMediaDetailState s, AppLocalizations l10n) {
    if (s.isFullyAvailable) return l10n.seerrAvailableStatus;
    if (s.isPartiallyAvailable) return l10n.partiallyAvailable;
    if (s.isProcessing) return l10n.seerrRequestedStatus;
    if (s.isPending) return l10n.pendingStatus;
    if (s.isBlacklisted) return l10n.blocklistedStatus;
    if (s.isDeleted) return l10n.deletedStatus;
    if (s.hasExistingRequest) return l10n.seerrRequestedStatus;
    return l10n.notRequestedStatus;
  }

  String? _productionStatusText(SeerrMediaDetailState s) {
    if (s.isMovie) return s.movie?.status;
    return s.tv?.status;
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.length < 10) return null;
    try {
      final d = DateTime.parse(iso);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _formatMoneyFull(int amount) {
    final s = amount.toString();
    final buf = StringBuffer(r'$');
    final start = s.length % 3;
    for (var i = 0; i < s.length; i++) {
      if (i != 0 && (i - start) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    buf.write('.00');
    return buf.toString();
  }

  Future<void> _openTrailer(SeerrVideo video) async {
    final isYouTube = (video.site ?? '').toLowerCase() == 'youtube';
    final key = video.key;
    if (isYouTube && key != null && key.isNotEmpty) {
      await context.push(Destinations.trailer(videoId: key));
      return;
    }
    String? url = video.url;
    if ((url == null || url.isEmpty) && key != null && key.isNotEmpty) {
      url = 'https://www.youtube.com/watch?v=$key';
    }
    if (url == null || url.isEmpty) return;
    await context.push(Destinations.trailer(url: url));
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
                  errorWidget: (_, _, _) =>
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
        border: Border.fromBorderSide(
          ThemeRegistry.active.borders.chipBorder.copyWith(color: color),
        ),
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
    final l10n = AppLocalizations.of(context);
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
        final label = s.numberOfSeasons == 1 ? l10n.season : l10n.seasons;
        chips.add(_metaText(l10n.seasonsCount(s.numberOfSeasons!, label)));
      }
      if (s.tvStatus != null) {
        chips.add(_tvStatusBadge(s.tvStatus!));
      }
    }

    if (s.budget != null && s.budget! > 0) {
      chips.add(_metaText(l10n.budgetAmount(_formatMoney(s.budget!))));
    }
    if (s.revenue != null && s.revenue! > 0) {
      chips.add(_metaText(l10n.revenueAmount(_formatMoney(s.revenue!))));
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
                      side: ThemeRegistry.active.borders.chipBorder,
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
    final l10n = AppLocalizations.of(context);
    final vm = _vm!;
    final canShowRequest = vm.canRequest &&
        !s.isFullyAvailable &&
        (!s.hasExistingRequest || s.isPartiallyAvailable);
    final requestLabel = s.isPartiallyAvailable ? l10n.requestMore : l10n.request;
    final canManage = vm.canManageRequests;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.activeRequests.isNotEmpty) ...[
            for (final req in s.activeRequests)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.white54),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.requestedByName(req.requestedBy?.bestName ?? l10n.unknown),
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canManage && req.status == SeerrRequest.statusPending) ...[
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
                  label: Text(l10n.playInMoonfin),
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
                  label: Text(l10n.cancelRequest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[300],
                    side: ThemeRegistry.active.borders.chipBorder.copyWith(
                      color: Colors.red[300]!,
                    ),
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

  Widget _buildCastRow(List<SeerrCastMember> cast, AppLocalizations l10n) {
    final visible = cast.length > 20 ? cast.sublist(0, 20) : cast;
    return LibraryRow(
      title: l10n.cast,
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
    final isNeon = ThemeRegistry.active.id == ThemeRegistry.neonPulseId;
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
                suppressFocusGlow: isNeon,
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
    showFocusRestoringModalBottomSheet(
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
    final l10n = AppLocalizations.of(context);
    final active = s.activeRequests;
    if (active.isEmpty) return;

    final title = s.displayTitle;
    final count = active.length;
    final message = count == 1
        ? l10n.cancelRequestForTitle(title)
        : l10n.cancelCountRequestsForTitle(count, title);

    showFocusRestoringDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(l10n.cancelRequest,
            style: const TextStyle(color: Colors.white)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keep),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelRequests(active);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red[300]),
            child: Text(l10n.cancelRequest),
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
    final l10n = AppLocalizations.of(context);
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
          SnackBar(
            content: Text(l10n.itemNotFoundInLibrary),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorSearchingLibrary),
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
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: isLoading ? null : onApprove,
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          tooltip: l10n.approve,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: isLoading ? null : onDecline,
          icon: Icon(Icons.cancel_outlined, color: Colors.red[300], size: 20),
          tooltip: l10n.declineAction,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _BrowseChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? borderColor;
  final Color labelColor;
  final bool dense;

  const _BrowseChip({
    required this.label,
    required this.onTap,
    required this.color,
    required this.borderColor,
    required this.labelColor,
    required this.dense,
  });

  @override
  State<_BrowseChip> createState() => _BrowseChipState();
}

class _BrowseChipState extends State<_BrowseChip> with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final hPad = widget.dense ? 8.0 : 10.0;
    final vPad = widget.dense ? 4.0 : 6.0;
    final borderRadius = BorderRadius.circular(999);
    return Focus(
      onFocusChange: setFocused,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setHovered(true),
        onExit: (_) => setHovered(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: showFocusBorder ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: borderRadius,
                border: Border.fromBorderSide(
                  ThemeRegistry.active.borders.chipBorder.copyWith(
                    color: showFocusBorder
                        ? focusColor
                        : (widget.borderColor ?? Colors.transparent),
                    width: showFocusBorder ? 2 : 1,
                  ),
                ),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.dense ? 11 : 12,
                  color: widget.labelColor,
                ),
              ),
            ),
          ),
        ),
      ),
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
                          ? Border.fromBorderSide(
                              ThemeRegistry.active.borders.focusBorder.copyWith(
                                color: focusColor,
                                width: 2,
                              ),
                            )
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

class _StatRow {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final FocusNode? focusNode;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.focusNode,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final focusColor = Color(GetIt.instance<UserPreferences>()
        .get(UserPreferences.focusColor)
        .colorValue);
    final disabled = widget.onTap == null;
    final isHighlighted = showFocusBorder;
    final bg = (widget.primary && isHighlighted)
        ? Colors.white
        : Colors.white.withValues(alpha: 0.10);
    final fg = (widget.primary && isHighlighted) ? Colors.black : Colors.white;
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: setFocused,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (!disabled &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) => setHovered(true),
          onExit: (_) => setHovered(false),
          child: AnimatedScale(
            scale: showFocusBorder ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: 96,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: showFocusBorder
                          ? Border.fromBorderSide(
                              ThemeRegistry.active.borders.focusBorder.copyWith(
                                color: focusColor,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Icon(widget.icon, color: fg, size: 38),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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
    _applySavedPreferences();
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
    _selectedServerId ??= server.server.id;
    _selectedProfileId ??= server.server.activeProfileId;
    final dir = server.server.activeDirectory;
    if (_selectedRootFolderId == null && dir.isNotEmpty) {
      final match = server.rootFolders
          .where((f) => f.path == dir)
          .firstOrNull;
      if (match != null) _selectedRootFolderId = match.id;
    }
  }

  int? get _effectiveServerId {
    return _selectedServerId ?? _servers?.firstOrNull?.server.id;
  }

  int? get _effectiveProfileId {
    if (_selectedProfileId != null) return _selectedProfileId;
    final server = _activeServer;
    if (server == null) return null;
    return server.server.activeProfileId;
  }

  String? get _effectiveRootFolderPath {
    final server = _activeServer;
    if (server == null) return null;

    if (_selectedRootFolderId != null) {
      return server.rootFolders
          .where((f) => f.id == _selectedRootFolderId)
          .firstOrNull
          ?.path;
    }

    final dir = server.server.activeDirectory;
    if (dir.isNotEmpty) {
      final match =
          server.rootFolders.where((f) => f.path == dir).firstOrNull;
      if (match != null) return match.path;
    }

    return server.rootFolders.firstOrNull?.path;
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
      profileId: _effectiveProfileId,
      rootFolder: _effectiveRootFolderPath,
      serverId: _effectiveServerId,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              l10n.requestSeriesOrMovie(widget.isTv ? l10n.series : l10n.movie),
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
              child: Text(l10n.submitRequest,
                  style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSelector() {
    final l10n = AppLocalizations.of(context);
    final seasonCount = widget.numberOfSeasons;
    final requested = widget.requestedSeasons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(l10n.allSeasons,
              style: const TextStyle(color: Colors.white)),
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
    final l10n = AppLocalizations.of(context);
    return ExpansionTile(
      title: Text(l10n.advancedOptions,
          style: const TextStyle(color: Colors.white70)),
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l10n.noServiceServersConfigured,
              style: const TextStyle(color: Colors.white54),
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
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: l10n.server,
        labelStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: ThemeRegistry.active.borders.chipBorder,
        ),
      ),
      dropdownColor: const Color(0xFF1A1A2E),
      initialValue: _selectedServerId ?? _servers?.firstOrNull?.server.id,
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
        _applyServerDefaults();
      }),
    );
  }

  Widget _buildProfileDropdown() {
    final l10n = AppLocalizations.of(context);
    final profiles = _activeServer?.profiles ?? [];
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: l10n.qualityProfile,
        labelStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: ThemeRegistry.active.borders.chipBorder,
        ),
      ),
      dropdownColor: const Color(0xFF1A1A2E),
      initialValue: _selectedProfileId ?? profiles.firstOrNull?.id,
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
    final l10n = AppLocalizations.of(context);
    final folders = _activeServer?.rootFolders ?? [];
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: l10n.rootFolder,
        labelStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: ThemeRegistry.active.borders.chipBorder,
        ),
      ),
      dropdownColor: const Color(0xFF1A1A2E),
      initialValue: _selectedRootFolderId ?? folders.firstOrNull?.id,
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
