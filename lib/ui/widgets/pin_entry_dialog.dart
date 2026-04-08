import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum PinEntryMode { set, verify }

/// A TV-friendly PIN entry dialog with a numeric keypad grid.
///
/// Supports two modes:
/// - [PinEntryMode.set]: Setting a new PIN (requires confirmation).
/// - [PinEntryMode.verify]: Verifying an existing PIN.
class PinEntryDialog extends StatefulWidget {
  final PinEntryMode mode;
  final bool Function(String pin)? onVerify;
  final void Function(String pin)? onPinSet;
  final VoidCallback? onForgotPin;
  final int pinLength;

  const PinEntryDialog({
    super.key,
    required this.mode,
    this.onVerify,
    this.onPinSet,
    this.onForgotPin,
    this.pinLength = 4,
  });

  /// Show the PIN dialog and return true if verified/set, false otherwise.
  static Future<bool> show(
    BuildContext context, {
    required PinEntryMode mode,
    bool Function(String pin)? onVerify,
    void Function(String pin)? onPinSet,
    VoidCallback? onForgotPin,
    int pinLength = 4,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinEntryDialog(
        mode: mode,
        onVerify: onVerify,
        onPinSet: onPinSet,
        onForgotPin: onForgotPin,
        pinLength: pinLength,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  String _enteredPin = '';
  String? _firstPin; // For set mode: stores the first entry for confirmation
  String? _errorText;
  bool _isConfirming = false;

  String _title(AppLocalizations l10n) {
    if (widget.mode == PinEntryMode.set) {
      return _isConfirming ? l10n.pinConfirmTitle : l10n.pinSetTitle;
    }
    return l10n.pinEnterTitle;
  }

  String _subtitle(AppLocalizations l10n) {
    if (widget.mode == PinEntryMode.set) {
      return _isConfirming
          ? l10n.pinReenterToConfirm
          : l10n.pinEnterNDigit(widget.pinLength);
    }
    return l10n.pinEnterYourNDigit(widget.pinLength);
  }

  void _onDigitPressed(int digit) {
    if (_enteredPin.length >= widget.pinLength) return;
    setState(() {
      _enteredPin += digit.toString();
      _errorText = null;
    });

    if (_enteredPin.length == widget.pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _errorText = null;
    });
  }

  void _onPinComplete() {
    if (widget.mode == PinEntryMode.verify) {
      if (widget.onVerify?.call(_enteredPin) ?? false) {
        Navigator.of(context).pop(true);
      } else {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorText = l10n.pinIncorrect;
          _enteredPin = '';
        });
      }
    } else {
      // Set mode
      if (!_isConfirming) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _firstPin) {
          widget.onPinSet?.call(_enteredPin);
          Navigator.of(context).pop(true);
        } else {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _errorText = l10n.pinMismatch;
            _enteredPin = '';
            _isConfirming = false;
            _firstPin = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Icon(Icons.lock, size: 40, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(_title(l10n), style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              _subtitle(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pinLength, (i) {
                final isFilled = i < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            // Error text
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Numeric keypad (1-9, clear, 0, backspace)
            _buildKeypad(context),

            const SizedBox(height: 16),

            // Bottom actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.mode == PinEntryMode.verify &&
                    widget.onForgotPin != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      widget.onForgotPin!();
                    },
                    child: Text(l10n.pinForgot),
                  )
                else
                  const SizedBox.shrink(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(1),
            _buildKeypadButton(2),
            _buildKeypadButton(3),
          ],
        ),
        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(4),
            _buildKeypadButton(5),
            _buildKeypadButton(6),
          ],
        ),
        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(7),
            _buildKeypadButton(8),
            _buildKeypadButton(9),
          ],
        ),
        // Row 4: Clear, 0, Backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              icon: Icons.clear_all,
              onPressed: _onClear,
              semanticLabel: l10n.pinClear,
            ),
            _buildKeypadButton(0),
            _buildActionButton(
              icon: Icons.backspace_outlined,
              onPressed: _onBackspace,
              semanticLabel: l10n.pinBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(int digit) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: 64,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _onDigitPressed(digit),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: digit == 1,
          child: Text(
            '$digit',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String semanticLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: 64,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Semantics(
            label: semanticLabel,
            child: Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }
}
