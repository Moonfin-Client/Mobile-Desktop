import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../l10n/app_localizations.dart';
import '../../util/app_exit.dart';
import '../../util/focus/key_event_utils.dart';
import 'overlay_sheet.dart';

Future<void> showExitConfirmationDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final cancelFocus = FocusNode(debugLabel: 'ExitDialogCancel');
  try {
    final result = await OverlaySheetController.show<bool>(
      context,
      initialFocusNode: cancelFocus,
      builder: (sheetContext) => _ExitConfirmationContent(
        title: l10n.exitApp,
        message: l10n.exitAppConfirmation,
        cancelLabel: l10n.cancel,
        exitLabel: l10n.exit,
        cancelFocus: cancelFocus,
        onCancel: () =>
            OverlaySheetController.closeAdaptive(sheetContext, false),
        onExit: () =>
            OverlaySheetController.closeAdaptive(sheetContext, true),
      ),
    );
    if (result == true) {
      await AppExit.closeApp();
    }
  } finally {
    cancelFocus.dispose();
  }
}

class _ExitConfirmationContent extends StatefulWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String exitLabel;
  final FocusNode cancelFocus;
  final VoidCallback onCancel;
  final VoidCallback onExit;

  const _ExitConfirmationContent({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.exitLabel,
    required this.cancelFocus,
    required this.onCancel,
    required this.onExit,
  });

  @override
  State<_ExitConfirmationContent> createState() =>
      _ExitConfirmationContentState();
}

class _ExitConfirmationContentState extends State<_ExitConfirmationContent> {
  final _exitFocus = FocusNode(debugLabel: 'ExitDialogExit');

  @override
  void dispose() {
    _exitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              size: 40,
              color: AppColorScheme.accent,
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.7),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ExitDialogButton(
                  label: widget.cancelLabel,
                  focusNode: widget.cancelFocus,
                  autofocus: true,
                  onPressed: widget.onCancel,
                ),
                const SizedBox(width: 16),
                _ExitDialogButton(
                  label: widget.exitLabel,
                  focusNode: _exitFocus,
                  onPressed: widget.onExit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExitDialogButton extends StatefulWidget {
  final String label;
  final FocusNode focusNode;
  final VoidCallback onPressed;
  final bool autofocus;

  const _ExitDialogButton({
    required this.label,
    required this.focusNode,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  State<_ExitDialogButton> createState() => _ExitDialogButtonState();
}

class _ExitDialogButtonState extends State<_ExitDialogButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) => handleOneShotSelect(event, widget.onPressed),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _focused ? Colors.white : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _focused ? Colors.black : Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
