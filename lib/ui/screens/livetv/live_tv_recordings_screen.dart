import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/viewmodels/recordings_view_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../navigation/destinations.dart';
import '../../widgets/navigation_layout.dart';

class LiveTvRecordingsScreen extends StatefulWidget {
  const LiveTvRecordingsScreen({super.key});

  @override
  State<LiveTvRecordingsScreen> createState() => _LiveTvRecordingsScreenState();
}

class _LiveTvRecordingsScreenState extends State<LiveTvRecordingsScreen> {
  late final RecordingsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = RecordingsViewModel(GetIt.instance<MediaServerClient>());
    _vm.addListener(_onChanged);
    _vm.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 60, top: 80, bottom: 8),
      child: Column(
        children: [
          Center(
            child: Text(
              l10n.recordings,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _FocusedItemHud(item: _vm.focusedItem),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_vm.state == RecordingsState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0066CC)),
      );
    }

    if (_vm.state == RecordingsState.error) {
      return Center(
        child: Text(
          AppLocalizations.of(context).failedToLoadRecordings,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildNavRow(),
        if (_vm.scheduledNext24h.isNotEmpty)
          _RecordingRow(
            title: AppLocalizations.of(context).scheduledInNext24Hours,
            items: _vm.scheduledNext24h,
            imageApi: _vm.imageApi,
            onItemFocused: _vm.setFocusedItem,
            onItemTap: _onItemTap,
          ),
        if (_vm.recentRecordings.isNotEmpty)
          _RecordingRow(
            title: AppLocalizations.of(context).recentRecordings,
            items: _vm.recentRecordings,
            imageApi: _vm.imageApi,
            onItemFocused: _vm.setFocusedItem,
            onItemTap: _onItemTap,
          ),
        if (_vm.seriesRecordings.isNotEmpty)
          _RecordingRow(
            title: AppLocalizations.of(context).tvSeries,
            items: _vm.seriesRecordings,
            imageApi: _vm.imageApi,
            onItemFocused: _vm.setFocusedItem,
            onItemTap: _onItemTap,
          ),
        if (_vm.movieRecordings.isNotEmpty)
          _RecordingRow(
            title: AppLocalizations.of(context).movies,
            items: _vm.movieRecordings,
            imageApi: _vm.imageApi,
            onItemFocused: _vm.setFocusedItem,
            onItemTap: _onItemTap,
          ),
        if (_vm.sportsRecordings.isNotEmpty)
          _RecordingRow(
            title: AppLocalizations.of(context).sports,
            items: _vm.sportsRecordings,
            imageApi: _vm.imageApi,
            onItemFocused: _vm.setFocusedItem,
            onItemTap: _onItemTap,
          ),
        if (_vm.kidsRecordings.isNotEmpty)
          _RecordingRow(
            title: AppLocalizations.of(context).kids,
            items: _vm.kidsRecordings,
            imageApi: _vm.imageApi,
            onItemFocused: _vm.setFocusedItem,
            onItemTap: _onItemTap,
          ),
      ],
    );
  }

  Widget _buildNavRow() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 60, bottom: 8),
            child: Text(
              l10n.views,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 60),
              children: [
                _NavButton(
                  label: l10n.schedule,
                  icon: Icons.schedule,
                  onTap: () => context.push(Destinations.liveTvSchedule),
                ),
                const SizedBox(width: 12),
                _NavButton(
                  label: l10n.seriesRecordings,
                  icon: Icons.fiber_smart_record,
                  onTap: () =>
                      context.push(Destinations.liveTvSeriesRecordings),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTap(RecordingItem item) {
    context.push(Destinations.itemDetail.replaceFirst(':itemId', item.id));
  }
}

class _FocusedItemHud extends StatelessWidget {
  final RecordingItem? item;

  const _FocusedItemHud({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: item == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item!.subtitle.isNotEmpty)
                  Text(
                    item!.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
    );
  }
}

class _RecordingRow extends StatelessWidget {
  final String title;
  final List<RecordingItem> items;
  final ImageApi imageApi;
  final ValueChanged<RecordingItem> onItemFocused;
  final ValueChanged<RecordingItem> onItemTap;

  const _RecordingRow({
    required this.title,
    required this.items,
    required this.imageApi,
    required this.onItemFocused,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 60, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 60),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _RecordingCard(
                  item: item,
                  imageUrl: item.imageUrl(imageApi),
                  onFocused: () => onItemFocused(item),
                  onTap: () => onItemTap(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingCard extends StatefulWidget {
  final RecordingItem item;
  final String? imageUrl;
  final VoidCallback onFocused;
  final VoidCallback onTap;

  const _RecordingCard({
    required this.item,
    required this.imageUrl,
    required this.onFocused,
    required this.onTap,
  });

  @override
  State<_RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<_RecordingCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final cardExpansion =
        GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);
    final scale = cardExpansion && showFocusBorder ? 1.08 : 1.0;
    final alpha = showFocusBorder ? 1.0 : 0.75;
    final focusColor = Color(
      GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (focused) {
          setFocused(focused);
          if (focused) widget.onFocused();
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            child: Opacity(
              opacity: alpha,
              child: SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                        border: showFocusBorder
                            ? Border.all(color: focusColor, width: 1.5)
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildImage(),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.item.subtitle.isNotEmpty)
                      Text(
                        widget.item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        width: 200,
        height: 112,
      );
    }
    return Center(
      child: Icon(
        Icons.fiber_dvr,
        size: 48,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final bgColor = focused
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.08);

    return Focus(
      onFocusChange: (f) => setFocused(f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: focused
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: focused ? FontWeight.w600 : FontWeight.normal,
                  color: focused
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
