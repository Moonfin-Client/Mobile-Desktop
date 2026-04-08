import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../auth/repositories/server_repository.dart';
import '../../../auth/repositories/session_repository.dart';
import '../../../auth/store/credential_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../../util/pin_code_util.dart';
import '../../navigation/destinations.dart';
import '../../widgets/pin_entry_dialog.dart';

const _kGradientColors = [
  Color(0xFF0a0a0a),
  Color(0xFF1a1a2e),
  Color(0xFF16213e),
];

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _initialize();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final session = GetIt.instance<SessionRepository>();
    final serverRepo = GetIt.instance<ServerRepository>();
    final credentialStore = GetIt.instance<CredentialStore>();

    if (session.state != SessionState.ready) {
      await session.stateStream.firstWhere((s) => s == SessionState.ready);
    }

    await serverRepo.loadStoredServers();
    final restored = await session.restoreSession();

    if (!mounted) return;

    if (credentialStore.consumeSecureStorageUnavailable()) {
      await _showSecureStorageWarning();
      if (!mounted) return;
    }

    if (restored && session.activeUserId != null) {
      final store = GetIt.instance<PreferenceStore>();
      final pinUtil = PinCodeUtil(store, session.activeUserId!);

      if (pinUtil.isPinEnabled) {
        final verified = await PinEntryDialog.show(
          context,
          mode: PinEntryMode.verify,
          onVerify: pinUtil.verifyPin,
          onForgotPin: () {
            if (mounted) context.go(Destinations.serverSelect);
          },
        );

        if (!verified) {
          if (mounted) context.go(Destinations.serverSelect);
          return;
        }
      }

      if (mounted) context.go(Destinations.home);
    } else {
      if (mounted) context.go(Destinations.serverSelect);
    }
  }

  Future<void> _showSecureStorageWarning() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(l10n.secureStorageUnavailable),
        content: Text(
          l10n.secureStorageUnavailableMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  bool get _isLargeScreen {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _kGradientColors,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_and_text.png',
                  height: _isLargeScreen ? 80 : 56,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF00A4DC).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
