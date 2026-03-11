import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/services/background_service.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../../data/models/media_bar_state.dart';
import '../../../data/viewmodels/media_bar_view_model.dart';
import '../../widgets/info_area.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_bar.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/seasonal_effects.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: _HomeShell(),
      tvBody: _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _userPrefs = GetIt.instance<UserPreferences>();
  late final HomeViewModel _viewModel;

  AggregatedItem? _selectedItem;
  String? _backdropUrl;
  Timer? _selectionDebounce;
  Timer? _backdropDebounce;
  StreamSubscription<String?>? _backgroundSub;

  static const _selectionDelay = Duration(milliseconds: 150);
  static const _backdropDelay = Duration(milliseconds: 200);
  static const _infoAreaTop = 80.0;
  static const _contentTop = 243.0;

  @override
  void initState() {
    super.initState();
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;

    _viewModel = GetIt.instance<HomeViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
    _selectionDebounce?.cancel();
    _backdropDebounce?.cancel();
    _backgroundSub?.cancel();
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void onItemSelected(AggregatedItem? item) {
    _selectionDebounce?.cancel();
    _selectionDebounce = Timer(_selectionDelay, () {
      if (!mounted) return;
      setState(() => _selectedItem = item);

      _backdropDebounce?.cancel();
      _backdropDebounce = Timer(_backdropDelay, () {
        _backgroundService.setBackground(item, context: BlurContext.browsing);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final backdropEnabled = _userPrefs.get(UserPreferences.backdropEnabled);
    final blurAmount = _userPrefs.get(UserPreferences.browsingBackgroundBlurAmount).toDouble();
    final seasonalEffect = _userPrefs.get(UserPreferences.seasonalSurprise);
    final confirmExit = PlatformDetection.isDesktop &&
        _userPrefs.get(UserPreferences.confirmExit);

    return PopScope(
      canPop: !confirmExit,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitConfirmation(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NavigationLayout(
          activeRoute: Destinations.home,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (backdropEnabled) _Backdrop(url: _backdropUrl, blurAmount: blurAmount),
              const _GradientScrim(),
              Positioned(
                left: 48,
                top: _infoAreaTop,
                child: SafeArea(
                  child: InfoArea(item: _selectedItem),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: _contentTop,
                bottom: 0,
                child: _ContentRows(
                  viewModel: _viewModel,
                  mediaBarViewModel: _viewModel.mediaBarViewModel,
                  prefs: _userPrefs,
                  onItemSelected: onItemSelected,
                ),
              ),
              if (seasonalEffect != 'none')
                Positioned.fill(
                  child: SeasonalEffects(effect: seasonalEffect),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Moonfin?'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (result == true) {
      SystemNavigator.pop();
    }
  }
}

class _Backdrop extends StatelessWidget {
  final String? url;
  final double blurAmount;

  const _Backdrop({this.url, required this.blurAmount});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BackgroundService.transitionDuration,
      child: url != null
          ? SizedBox.expand(
              key: ValueKey(url),
              child: _blurredImage(url!, blurAmount),
            )
          : const SizedBox.expand(key: ValueKey('empty')),
    );
  }

  Widget _blurredImage(String imageUrl, double blur) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
    if (blur <= 0) return image;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
        tileMode: TileMode.decal,
      ),
      child: image,
    );
  }
}

class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xAA000000),
            Color(0x44000000),
            Color(0xBB000000),
          ],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _ContentRows extends StatelessWidget {
  final HomeViewModel viewModel;
  final MediaBarViewModel mediaBarViewModel;
  final UserPreferences prefs;
  final ValueChanged<AggregatedItem?> onItemSelected;

  const _ContentRows({
    required this.viewModel,
    required this.mediaBarViewModel,
    required this.prefs,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rows = viewModel.rows;
    final posterSize = prefs.get(UserPreferences.posterSize);
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final focusColor = Color(prefs.get(UserPreferences.focusColor).colorValue);
    final cardExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final useSeriesThumbs = prefs.get(UserPreferences.seriesThumbnailsEnabled);

    if (viewModel.isLoading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final showMediaBar = mediaBarViewModel.state is MediaBarReady;
    final offset = showMediaBar ? 1 : 0;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: rows.length + offset,
      itemBuilder: (context, index) {
        if (showMediaBar && index == 0) {
          return MediaBar(
            viewModel: mediaBarViewModel,
            prefs: prefs,
          );
        }
        final row = rows[index - offset];
        if (row.isLoading) {
          return LibraryRow(title: row.title, children: const []);
        }
        double maxCardHeight = 0;
        final cards = row.items.map((item) {
            final ar = MediaCard.aspectRatioForType(item.type);
            final height = ar > 1
                ? posterSize.landscapeHeight.toDouble()
                : posterSize.portraitHeight.toDouble();
            final cardHeight = height + 40;
            if (cardHeight > maxCardHeight) maxCardHeight = cardHeight;
            final width = height * ar;
            final imageUrl = _resolveImageUrl(
              item, viewModel.imageApi, height, useSeriesThumbs,
            );
            return MediaCard(
              title: item.name,
              subtitle: item.subtitle,
              imageUrl: imageUrl,
              width: width,
              aspectRatio: ar,
              isFavorite: item.isFavorite,
              isPlayed: item.isPlayed,
              unplayedCount: item.unplayedItemCount,
              playedPercentage: item.playedPercentage,
              watchedBehavior: watchedBehavior,
              itemType: item.type,
              focusColor: focusColor,
              cardFocusExpansion: cardExpansion,
              onFocus: () => onItemSelected(item),
              onHoverStart: () => onItemSelected(item),
              onLongPress: () => onItemSelected(item),
              onTap: () => context.push(Destinations.item(item.id)),
            );
          }).toList();
        return LibraryRow(
          title: row.title,
          rowHeight: maxCardHeight,
          children: cards,
        );
      },
    );
  }

  static String? _resolveImageUrl(
    AggregatedItem item,
    ImageApi imageApi,
    double height,
    bool useSeriesThumbs,
  ) {
    final maxH = (height * 2).toInt();
    if (useSeriesThumbs &&
        item.type == 'Episode' &&
        item.seriesId != null &&
        item.seriesPrimaryImageTag != null) {
      return imageApi.getPrimaryImageUrl(
        item.seriesId!,
        maxHeight: maxH,
        tag: item.seriesPrimaryImageTag,
      );
    }
    if (item.primaryImageTag != null) {
      return imageApi.getPrimaryImageUrl(
        item.id,
        maxHeight: maxH,
        tag: item.primaryImageTag,
      );
    }
    return null;
  }
}
