import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/viewmodels/live_tv_guide_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/horizontal_scroll_section.dart';
import '../../widgets/navigation_layout.dart';

const _kChannelColumnWidth = 160.0;
const _kRowHeight = 74.0;
const _kTimeHeaderHeight = 40.0;
const _kPixelsPerMinute = 6.0;
const _kMinGuideHours = 3;
const _kMaxGuideHours = 12;

int _guideHoursForWidth(double availableWidth) {
  final guideWidth = availableWidth - _kChannelColumnWidth;
  if (guideWidth <= 0) return _kMinGuideHours;
  final hours = (guideWidth / (_kPixelsPerMinute * 60)).floor();
  return hours.clamp(_kMinGuideHours, _kMaxGuideHours);
}

class LiveTvGuideScreen extends StatefulWidget {
  const LiveTvGuideScreen({super.key});

  @override
  State<LiveTvGuideScreen> createState() => _LiveTvGuideScreenState();
}

class _LiveTvGuideScreenState extends State<LiveTvGuideScreen> {
  late final LiveTvGuideViewModel _vm;
  final _prefs = GetIt.instance<UserPreferences>();
  final _channelScrollController = ScrollController();
  final _programScrollController = ScrollController();
  final _timeHeaderHorizontalScrollController = ScrollController();
  final _guideHorizontalScrollController = ScrollController();

  double _contentTopInset() {
    if (PlatformDetection.isTV) {
      final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
      if (navbarPosition != NavbarPosition.top) {
        return 8.0;
      }
      return 95.0;
    }

    return 50.0;
  }

  double _contentLeftInset() {
    if (PlatformDetection.isTV) {
      final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
      if (navbarPosition == NavbarPosition.top) {
        return 0.0;
      }
      return 104.0;
    }

    return 8.0;
  }

  @override
  void initState() {
    super.initState();
    _vm = LiveTvGuideViewModel(GetIt.instance<MediaServerClient>());
    _vm.addListener(_onChanged);

    _channelScrollController.addListener(_syncVerticalScroll);
    _programScrollController.addListener(_syncVerticalScroll);
    _timeHeaderHorizontalScrollController.addListener(_syncHorizontalFromHeader);
    _guideHorizontalScrollController.addListener(_syncHorizontalFromGuide);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final width = MediaQuery.sizeOf(context).width - _contentLeftInset();
      _vm.load(windowHours: _guideHoursForWidth(width));
    });
  }

  bool _syncingScroll = false;
  bool _syncingHorizontalScroll = false;
  void _syncVerticalScroll() {
    if (_syncingScroll) return;
    if (!_channelScrollController.hasClients || !_programScrollController.hasClients) return;
    _syncingScroll = true;
    try {
      final source = _channelScrollController.position.isScrollingNotifier.value
          ? _channelScrollController
          : _programScrollController;
      final target = source == _channelScrollController
          ? _programScrollController
          : _channelScrollController;
      if (target.hasClients) {
        target.jumpTo(source.offset);
      }
    } catch (_) {
    }
    _syncingScroll = false;
  }

  void _syncHorizontalFromHeader() {
    _syncHorizontalScroll(
      _timeHeaderHorizontalScrollController,
      _guideHorizontalScrollController,
    );
  }

  void _syncHorizontalFromGuide() {
    _syncHorizontalScroll(
      _guideHorizontalScrollController,
      _timeHeaderHorizontalScrollController,
    );
  }

  void _syncHorizontalScroll(ScrollController source, ScrollController target) {
    if (_syncingHorizontalScroll) return;
    if (!source.hasClients || !target.hasClients) return;

    _syncingHorizontalScroll = true;
    try {
      final targetOffset = source.offset.clamp(
        0.0,
        target.position.maxScrollExtent,
      );
      if ((target.offset - targetOffset).abs() > 0.5) {
        target.jumpTo(targetOffset);
      }
    } catch (_) {}
    _syncingHorizontalScroll = false;
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _channelScrollController.dispose();
    _programScrollController.dispose();
    _timeHeaderHorizontalScrollController.dispose();
    _guideHorizontalScrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m $amPm';
  }

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  double _totalGuideWidth() {
    final minutes = _vm.windowEnd.difference(_vm.windowStart).inMinutes;
    return minutes * _kPixelsPerMinute;
  }

  int _lastComputedHours = _kMinGuideHours;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hours = _guideHoursForWidth(
                constraints.maxWidth - _contentLeftInset(),
              );
              if (hours != _lastComputedHours &&
                  _vm.state == GuideState.ready) {
                _lastComputedHours = hours;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _vm.setWindowHours(hours);
                });
              }
              return Padding(
                padding: EdgeInsets.only(
                  top: _contentTopInset(),
                  left: _contentLeftInset(),
                ),
                child: Column(
                  children: [
                    _buildToolbar(),
                    _buildFilterChips(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildBody()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => _vm.shiftWindow(-_vm.guideWindowHours),
          ),
          TextButton(
            onPressed: () => _vm.goToNow(),
            child: const Text('Now', style: TextStyle(color: Colors.blue)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => _vm.shiftWindow(_vm.guideWindowHours),
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatDate(_vm.guideDate)}  ${_formatTime(_vm.windowStart)} – ${_formatTime(_vm.windowEnd)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _vm.guideDate,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 14)),
              );
              if (picked != null) _vm.setDate(picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: GuideFilter.values.map((f) {
          final selected = _vm.filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filterLabel(f)),
              selected: selected,
              onSelected: (_) => _vm.setFilter(selected ? GuideFilter.all : f),
              selectedColor: Colors.blue.withAlpha(77),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: selected ? Colors.blue : Colors.white70,
                fontSize: 13,
              ),
              backgroundColor: const Color(0xFF1E1E1E),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(GuideFilter f) => switch (f) {
    GuideFilter.all => 'All',
    GuideFilter.movies => 'Movies',
    GuideFilter.series => 'Series',
    GuideFilter.sports => 'Sports',
    GuideFilter.news => 'News',
    GuideFilter.kids => 'Kids',
    GuideFilter.premiere => 'Premiere',
    GuideFilter.favorites => 'Favorites',
  };

  Widget _buildBody() {
    switch (_vm.state) {
      case GuideState.loading:
        return const Center(child: CircularProgressIndicator());
      case GuideState.error:
        return Center(
          child: Text(
            'Failed to load guide: ${_vm.errorMessage}',
            style: TextStyle(color: Colors.white.withAlpha(179)),
          ),
        );
      case GuideState.ready:
        final channels = _vm.filteredChannels;
        if (channels.isEmpty) {
          return Center(
            child: Text(
              'No channels found',
              style: TextStyle(color: Colors.white.withAlpha(179)),
            ),
          );
        }
        return _buildGuideGrid(channels);
    }
  }

  Widget _buildGuideGrid(List<GuideChannel> channels) {
    final guideWidth = _totalGuideWidth();

    return Column(
      children: [
        HorizontalScrollSection(
          title: 'Guide Timeline',
          scrollController: _timeHeaderHorizontalScrollController,
          onScrollPastStart: () => _vm.shiftWindow(-1),
          onScrollPastEnd: () => _vm.shiftWindow(1),
          titleStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          headerPadding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
          contentSpacing: 2,
          builder: (_, controller) => SizedBox(
            height: _kTimeHeaderHeight,
            child: Row(
              children: [
                const SizedBox(width: _kChannelColumnWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    child: _buildTimeHeader(guideWidth),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: _kChannelColumnWidth,
                child: ListView.builder(
                  controller: _channelScrollController,
                  itemCount: channels.length,
                  itemExtent: _kRowHeight,
                  itemBuilder: (context, index) => _buildChannelCell(channels[index]),
                ),
              ),
              const VerticalDivider(width: 1, color: Colors.white24),
              Expanded(
                child: _GuideGridView(
                  channels: channels,
                  guideWidth: guideWidth,
                  verticalController: _programScrollController,
                  horizontalController: _guideHorizontalScrollController,
                  buildProgramRow: _buildProgramRow,
                  programsForChannel: _vm.programsForChannel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeHeader(double totalWidth) {
    final slots = <Widget>[];
    var t = _vm.windowStart;
    while (t.isBefore(_vm.windowEnd)) {
      final slotWidth = 30 * _kPixelsPerMinute;
      slots.add(
        SizedBox(
          width: slotWidth,
          height: _kTimeHeaderHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                _formatTime(t),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
      );
      t = t.add(const Duration(minutes: 30));
    }
    return SizedBox(
      width: totalWidth,
      height: _kTimeHeaderHeight,
      child: Row(children: slots),
    );
  }

  Widget _buildChannelCell(GuideChannel channel) {
    final imageUrl = channel.imageTag != null
        ? _vm.imageApi.getPrimaryImageUrl(channel.id, tag: channel.imageTag)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _watchChannel(channel.id),
        child: Container(
          height: _kRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.tv, color: Colors.white38, size: 24),
                  ),
                )
              else
                const Icon(Icons.tv, color: Colors.white38, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (channel.number != null)
                      Text(
                        channel.number!,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                      ),
                    Text(
                      channel.name,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramRow(List<GuideProgram> programs) {
    if (programs.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white12)),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Stack(
        children: programs.map((p) => _buildProgramCell(p)).toList(),
      ),
    );
  }

  Widget _buildProgramCell(GuideProgram program) {
    final offsetMinutes = program.startDate.difference(_vm.windowStart).inMinutes.toDouble();
    final clampedStart = offsetMinutes < 0 ? 0.0 : offsetMinutes;

    final endOffset = program.endDate.difference(_vm.windowStart).inMinutes.toDouble();
    final totalMinutes = _vm.windowEnd.difference(_vm.windowStart).inMinutes.toDouble();
    final clampedEnd = endOffset > totalMinutes ? totalMinutes : endOffset;

    final left = clampedStart * _kPixelsPerMinute;
    final width = (clampedEnd - clampedStart) * _kPixelsPerMinute;

    if (width <= 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final isLive = now.isAfter(program.startDate) && now.isBefore(program.endDate);

    return Positioned(
      left: left,
      width: width,
      top: 2,
      bottom: 2,
      child: GestureDetector(
        onTap: () => _showProgramDetails(program),
        child: Container(
          margin: const EdgeInsets.only(right: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isLive ? Colors.blue.withAlpha(51) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(4),
            border: isLive ? Border.all(color: Colors.blue.withAlpha(128)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (isLive)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  if (program.hasTimer)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                    ),
                  Expanded(
                    child: Text(
                      program.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (width > 80)
                Text(
                  '${_formatTime(program.startDate)} – ${_formatTime(program.endDate)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  maxLines: 1,
                ),
              if (isLive)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: LinearProgressIndicator(
                    value: program.progressAt(now),
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                    minHeight: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _watchChannel(String channelId) {
    final channels = _vm.filteredChannels;
    final index = channels.indexWhere((c) => c.id == channelId);
    if (index < 0) return;
    context.push(Destinations.liveTvPlayer, extra: {
      'channels': channels,
      'startIndex': index,
    });
  }

  void _showProgramDetails(GuideProgram program) {
    final channel = _vm.channelForId(program.channelId);
    final isFavoriteChannel = channel?.isFavorite ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(program.name, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_formatTime(program.startDate)} – ${_formatTime(program.endDate)}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (program.episodeTitle != null) ...[
                const SizedBox(height: 8),
                Text(program.episodeTitle!, style: const TextStyle(color: Colors.white70)),
              ],
              if (program.overview != null && program.overview!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(program.overview!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (program.isMovie) const Chip(label: Text('Movie'), visualDensity: VisualDensity.compact),
                  if (program.isSeries) const Chip(label: Text('Series'), visualDensity: VisualDensity.compact),
                  if (program.isSports) const Chip(label: Text('Sports'), visualDensity: VisualDensity.compact),
                  if (program.isNews) const Chip(label: Text('News'), visualDensity: VisualDensity.compact),
                  if (program.isKids) const Chip(label: Text('Kids'), visualDensity: VisualDensity.compact),
                  if (program.isPremiere) const Chip(label: Text('Premiere'), visualDensity: VisualDensity.compact),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: channel == null
                ? null
                : () async {
                    try {
                      await _vm.toggleChannelFavorite(program.channelId);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavoriteChannel
                                ? 'Removed from favorite channels'
                                : 'Added to favorite channels',
                          ),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update favorite channel'),
                        ),
                      );
                    }
                  },
            child: Text(
              isFavoriteChannel ? 'Unfavorite Channel' : 'Favorite Channel',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _watchChannel(program.channelId);
            },
            child: const Text('Watch'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _GuideGridView extends StatefulWidget {
  final List<GuideChannel> channels;
  final double guideWidth;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final Widget Function(List<GuideProgram>) buildProgramRow;
  final List<GuideProgram> Function(String channelId) programsForChannel;

  const _GuideGridView({
    required this.channels,
    required this.guideWidth,
    required this.verticalController,
    required this.horizontalController,
    required this.buildProgramRow,
    required this.programsForChannel,
  });

  @override
  State<_GuideGridView> createState() => _GuideGridViewState();
}

class _GuideGridViewState extends State<_GuideGridView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: widget.horizontalController,
      child: SizedBox(
        width: widget.guideWidth,
        child: ListView.builder(
          controller: widget.verticalController,
          itemCount: widget.channels.length,
          itemExtent: _kRowHeight,
          itemBuilder: (context, index) {
            final channel = widget.channels[index];
            final programs = widget.programsForChannel(channel.id);
            return SizedBox(
              width: widget.guideWidth,
              height: _kRowHeight,
              child: widget.buildProgramRow(programs),
            );
          },
        ),
      ),
    );
  }
}
