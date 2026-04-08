import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../auth/repositories/session_repository.dart';
import '../../../util/pin_code_util.dart';
import '../../widgets/pin_entry_dialog.dart';
import '../../../l10n/app_localizations.dart';

/// Settings screen for managing PIN code protection.
class PinCodeSettingsScreen extends StatefulWidget {
  const PinCodeSettingsScreen({super.key});

  @override
  State<PinCodeSettingsScreen> createState() => _PinCodeSettingsScreenState();
}

class _PinCodeSettingsScreenState extends State<PinCodeSettingsScreen> {
  late final PinCodeUtil _pinUtil;
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    final session = GetIt.instance<SessionRepository>();
    final store = GetIt.instance<PreferenceStore>();
    final userId = session.activeUserId ?? '';
    _pinUtil = PinCodeUtil(store, userId);
    _pinEnabled = _pinUtil.isPinEnabled;
  }

  void _refresh() {
    setState(() {
      _pinEnabled = _pinUtil.isPinEnabled;
    });
  }

  Future<void> _setPin() async {
    final result = await PinEntryDialog.show(
      context,
      mode: PinEntryMode.set,
      onPinSet: (pin) async {
        await _pinUtil.setPin(pin);
      },
    );
    if (result) _refresh();
  }

  Future<void> _changePin() async {
    // Verify current PIN first
    final verified = await PinEntryDialog.show(
      context,
      mode: PinEntryMode.verify,
      onVerify: _pinUtil.verifyPin,
    );
    if (!verified || !mounted) return;

    // Set new PIN
    final changed = await PinEntryDialog.show(
      context,
      mode: PinEntryMode.set,
      onPinSet: (pin) async {
        await _pinUtil.setPin(pin);
      },
    );
    if (changed) _refresh();
  }

  Future<void> _removePin() async {
    final verified = await PinEntryDialog.show(
      context,
      mode: PinEntryMode.verify,
      onVerify: _pinUtil.verifyPin,
    );
    if (!verified || !mounted) return;

    await _pinUtil.removePin();
    _refresh();
  }

  Future<void> _togglePinEnabled(bool enabled) async {
    if (enabled && !_pinEnabled) {
      // Must set a PIN first
      await _setPin();
    } else if (!enabled && _pinEnabled) {
      // Verify before disabling
      final verified = await PinEntryDialog.show(
        context,
        mode: PinEntryMode.verify,
        onVerify: _pinUtil.verifyPin,
      );
      if (!verified || !mounted) return;
      await _pinUtil.setPinEnabled(false);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pinCode)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.enablePinCode),
            subtitle: Text(l10n.requirePinToAccess),
            secondary: const Icon(Icons.lock),
            value: _pinEnabled,
            onChanged: _togglePinEnabled,
          ),
          if (_pinEnabled) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.changePin),
              subtitle: Text(l10n.setNewPinCode),
              onTap: _changePin,
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(l10n.removePin),
              subtitle: Text(l10n.removePinProtection),
              onTap: _removePin,
            ),
          ],
        ],
      ),
    );
  }
}
