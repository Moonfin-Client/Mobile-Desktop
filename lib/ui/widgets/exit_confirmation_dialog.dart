import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../util/app_exit.dart';
import '../../util/focus/key_event_utils.dart';

Future<void> showExitConfirmationDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showGeneralDialog<bool>(
    context: context,
    useRootNavigator: true,
    requestFocus: true,
    barrierDismissible: true,
    barrierLabel: l10n.cancel,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return ExitConfirmationDialog(
        title: l10n.exitApp,
        message: l10n.exitAppConfirmation,
        cancelLabel: l10n.cancel,
        exitLabel: l10n.exit,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
  if (result == true) {
    await AppExit.closeApp();
  }
}

class ExitConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String exitLabel;

  const ExitConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.exitLabel,
  });

  @override
  State<ExitConfirmationDialog> createState() => _ExitConfirmationDialogState();
}

class _ExitConfirmationDialogState extends State<ExitConfirmationDialog> {
  final _cancelFocus = FocusNode(debugLabel: 'ExitDialogCancel');
  final _exitFocus = FocusNode(debugLabel: 'ExitDialogExit');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cancelFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _cancelFocus.dispose();
    _exitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(false);
      },
      child: FocusScope(
        autofocus: true,
        onKeyEvent: (node, event) {
          return handleBackKeyAction(event, () => Navigator.of(context).pop(false));
        },
        child: Center(
          child: ConstrainedBox(
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
                  const Icon(
                    Icons.exit_to_app_rounded,
                    size: 40,
                    color: Color(0xFF00A4DC),
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
                        focusNode: _cancelFocus,
                        autofocus: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const SizedBox(width: 16),
                      _ExitDialogButton(
                        label: widget.exitLabel,
                        focusNode: _exitFocus,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
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
