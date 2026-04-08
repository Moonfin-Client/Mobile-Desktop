import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../data/viewmodels/series_recordings_view_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../widgets/navigation_layout.dart';

class LiveTvSeriesRecordingsScreen extends StatefulWidget {
  const LiveTvSeriesRecordingsScreen({super.key});

  @override
  State<LiveTvSeriesRecordingsScreen> createState() =>
      _LiveTvSeriesRecordingsScreenState();
}

class _LiveTvSeriesRecordingsScreenState
    extends State<LiveTvSeriesRecordingsScreen> {
  late final SeriesRecordingsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SeriesRecordingsViewModel(GetIt.instance<MediaServerClient>());
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
              AppLocalizations.of(context).seriesRecordings,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _FocusedTimerHud(timer: _vm.focusedTimer),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_vm.state == SeriesRecordingsState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0066CC)),
      );
    }

    if (_vm.state == SeriesRecordingsState.error) {
      return Center(
        child: Text(
          AppLocalizations.of(context).failedToLoadSeriesRecordings,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    if (_vm.seriesTimers.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noSeriesRecordings,
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
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 60, bottom: 8),
                child: Text(
                  AppLocalizations.of(context).seriesRecordings,
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
                  itemCount: _vm.seriesTimers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final timer = _vm.seriesTimers[index];
                    return _SeriesTimerCard(
                      timer: timer,
                      onFocused: () => _vm.setFocusedTimer(timer),
                      onTap: () => _showSeriesTimerOptions(timer),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSeriesTimerOptions(SeriesTimerItem timer) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          timer.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timer.subtitle.isNotEmpty)
              Text(
                timer.subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelSeriesTimer(timer);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.cancelSeriesRecording),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSeriesTimer(SeriesTimerItem timer) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          l10n.cancelSeriesRecordingQuestion,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.stopRecordingName(timer.name),
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
        await _vm.cancelSeriesTimer(timer.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToCancelSeriesRecording)),
          );
        }
      }
    }
  }
}

class _FocusedTimerHud extends StatelessWidget {
  final SeriesTimerItem? timer;

  const _FocusedTimerHud({required this.timer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: timer == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timer!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timer!.subtitle.isNotEmpty)
                  Text(
                    timer!.subtitle,
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

class _SeriesTimerCard extends StatefulWidget {
  final SeriesTimerItem timer;
  final VoidCallback onFocused;
  final VoidCallback onTap;

  const _SeriesTimerCard({
    required this.timer,
    required this.onFocused,
    required this.onTap,
  });

  @override
  State<_SeriesTimerCard> createState() => _SeriesTimerCardState();
}

class _SeriesTimerCardState extends State<_SeriesTimerCard> with FocusStateMixin {

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
                      child: Center(
                        child: Icon(
                          Icons.fiber_smart_record,
                          size: 48,
                          color: showFocusBorder
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.timer.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.timer.subtitle.isNotEmpty)
                      Text(
                        widget.timer.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
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
}
