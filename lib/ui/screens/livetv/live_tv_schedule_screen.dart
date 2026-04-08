import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/viewmodels/recordings_view_model.dart';
import '../../../data/viewmodels/schedule_view_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../widgets/navigation_layout.dart';

class LiveTvScheduleScreen extends StatefulWidget {
  const LiveTvScheduleScreen({super.key});

  @override
  State<LiveTvScheduleScreen> createState() => _LiveTvScheduleScreenState();
}

class _LiveTvScheduleScreenState extends State<LiveTvScheduleScreen> {
  late final ScheduleViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ScheduleViewModel(GetIt.instance<MediaServerClient>());
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
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 60, top: 80, bottom: 8),
      child: Column(
        children: [
          Center(
            child: Text(
              AppLocalizations.of(context).schedule,
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
    if (_vm.state == ScheduleState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0066CC)),
      );
    }

    if (_vm.state == ScheduleState.error) {
      return Center(
        child: Text(
          AppLocalizations.of(context).failedToLoadSchedule,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    if (_vm.groups.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noScheduledRecordings,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final group in _vm.groups)
          _ScheduleGroupRow(
            group: group,
            vm: _vm,
            onCancelTimer: _cancelTimer,
          ),
      ],
    );
  }

  Future<void> _cancelTimer(RecordingItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          l10n.cancelRecording,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.cancelScheduledRecordingOf(item.name),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.yesCancel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _vm.cancelTimer(item.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToCancelRecording)),
          );
        }
      }
    }
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

class _ScheduleGroupRow extends StatelessWidget {
  final ScheduleGroup group;
  final ScheduleViewModel vm;
  final Future<void> Function(RecordingItem) onCancelTimer;

  const _ScheduleGroupRow({
    required this.group,
    required this.vm,
    required this.onCancelTimer,
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
              group.dateLabel,
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
              itemCount: group.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = group.items[index];
                return _ScheduleCard(
                  item: item,
                  imageUrl: item.imageUrl(vm.imageApi),
                  onFocused: () => vm.setFocusedItem(item),
                  onTap: () => onCancelTimer(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatefulWidget {
  final RecordingItem item;
  final String? imageUrl;
  final VoidCallback onFocused;
  final VoidCallback onTap;

  const _ScheduleCard({
    required this.item,
    required this.imageUrl,
    required this.onFocused,
    required this.onTap,
  });

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> with FocusStateMixin {

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
        Icons.schedule,
        size: 48,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}
