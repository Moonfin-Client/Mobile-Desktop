import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../l10n/app_localizations.dart';
import '../../preference/user_preferences.dart';

const _kAccent = Color(0xFF00A4DC);

class TrackOption {
  final String label;
  final String? subtitle;

  const TrackOption({required this.label, this.subtitle});
}

class TrackSelectorDialog extends StatelessWidget {
  final String title;
  final List<TrackOption> options;
  final int? selectedIndex;

  const TrackSelectorDialog({
    super.key,
    required this.title,
    required this.options,
    this.selectedIndex,
  });

  static Future<int?> show(
    BuildContext context, {
    required String title,
    required List<TrackOption> options,
    int? selectedIndex,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => TrackSelectorDialog(
        title: title,
        options: options,
        selectedIndex: selectedIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 340, maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xE6141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) => _TrackRow(
                  option: options[i],
                  isSelected: selected == i,
                  autofocus: selected == i || (selected == null && i == 0),
                  onTap: () => Navigator.pop(context, i),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 4),
            _TrackRow(
              option: TrackOption(label: AppLocalizations.of(context).cancel),
              isSelected: false,
              onTap: () => Navigator.pop(context),
              dimmed: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackRow extends StatefulWidget {
  final TrackOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final bool autofocus;
  final bool dimmed;

  const _TrackRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.autofocus = false,
    this.dimmed = false,
  });

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  final _prefs = GetIt.instance<UserPreferences>();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = Color(_prefs.get(UserPreferences.focusColor).colorValue);
    final baseColor = widget.dimmed
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);
    final color = _isFocused ? focusColor : baseColor;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          color: _isFocused ? focusColor.withValues(alpha: 0.2) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              if (widget.isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.check_circle, color: _kAccent, size: 20),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.radio_button_unchecked, color: Colors.white38, size: 20),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.label,
                      style: TextStyle(fontSize: 16, color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.option.subtitle != null)
                      Text(
                        widget.option.subtitle!,
                        style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.6)),
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
}
