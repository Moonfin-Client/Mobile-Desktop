import 'package:flutter/material.dart';

class HorizontalScrollSection extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext context, ScrollController controller)
  builder;
  final ScrollController? scrollController;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry headerPadding;
  final double contentSpacing;
  final Widget? trailing;
  final bool showControls;
  final VoidCallback? onScrollPastStart;
  final VoidCallback? onScrollPastEnd;

  const HorizontalScrollSection({
    super.key,
    required this.title,
    required this.builder,
    this.scrollController,
    this.titleStyle,
    this.headerPadding = EdgeInsets.zero,
    this.contentSpacing = 12,
    this.trailing,
    this.showControls = true,
    this.onScrollPastStart,
    this.onScrollPastEnd,
  });

  @override
  State<HorizontalScrollSection> createState() =>
      _HorizontalScrollSectionState();
}

class _HorizontalScrollSectionState extends State<HorizontalScrollSection> {
  late ScrollController _controller;
  late bool _ownsController;

  static const _scrollStep = 480.0;
  static const _scrollDuration = Duration(milliseconds: 380);
  static const _scrollCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.scrollController == null;
    _controller = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant HorizontalScrollSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController == widget.scrollController) {
      return;
    }

    if (_ownsController) {
      _controller.dispose();
    }
    _ownsController = widget.scrollController == null;
    _controller = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) {
      if (delta < 0) {
        widget.onScrollPastStart?.call();
      } else {
        widget.onScrollPastEnd?.call();
      }
      return;
    }

    final current = _controller.offset;
    final target = (_controller.offset + delta).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );

    if ((target - current).abs() < 0.5) {
      if (delta < 0) {
        widget.onScrollPastStart?.call();
      } else {
        widget.onScrollPastEnd?.call();
      }
      return;
    }

    _controller.animateTo(
      target,
      duration: _scrollDuration,
      curve: _scrollCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: widget.headerPadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: widget.titleStyle ?? Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
              if (widget.showControls) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _scrollBy(-_scrollStep),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _scrollBy(_scrollStep),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
        if (widget.contentSpacing > 0) SizedBox(height: widget.contentSpacing),
        widget.builder(context, _controller),
      ],
    );
  }
}