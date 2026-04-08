import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

import '../../auth/repositories/session_repository.dart';
import '../../preference/user_preferences.dart';
import '../../auth/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/destinations.dart';
import 'remote_control_dialog.dart';

const _kAccent = Color(0xFF00A4DC);

enum _UserMenuAction { quickConnect }

void showUserMenu(BuildContext context) {
  final userRepo = GetIt.instance<UserRepository>();
  final user = userRepo.currentUser;
  final l10n = AppLocalizations.of(context);

  showDialog<_UserMenuAction>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
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
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: _kAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.name ?? l10n.unknownUser,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            _MenuRow(
              icon: Icons.swap_horiz_rounded,
              label: l10n.switchUser,
              autofocus: true,
              onTap: () {
                Navigator.pop(ctx);
                context.go(Destinations.serverSelect);
              },
            ),
            _MenuRow(
              icon: Icons.settings_rounded,
              label: l10n.settings,
              onTap: () {
                Navigator.pop(ctx);
                context.push(Destinations.settings);
              },
            ),
            _MenuRow(
              icon: Icons.phonelink_lock_rounded,
              label: l10n.quickConnect,
              onTap: () {
                Navigator.pop(ctx, _UserMenuAction.quickConnect);
              },
            ),
            _MenuRow(
              icon: Icons.download_done_rounded,
              label: l10n.savedMedia,
              onTap: () {
                Navigator.pop(ctx);
                context.push(Destinations.downloads);
              },
            ),
            _MenuRow(
              icon: Icons.settings_remote_rounded,
              label: l10n.remoteControl,
              onTap: () {
                Navigator.pop(ctx);
                showRemoteControlDialog(context);
              },
            ),
            const SizedBox(height: 4),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 4),
            _MenuRow(
              icon: Icons.logout_rounded,
              label: l10n.signOut,
              contentColor: Colors.redAccent,
              onTap: () async {
                Navigator.pop(ctx);
                await GetIt.instance<SessionRepository>().destroyCurrentSession();
                if (context.mounted) context.go(Destinations.serverSelect);
              },
            ),
          ],
        ),
      ),
    ),
  ).then((action) {
    if (action != _UserMenuAction.quickConnect) return;
    if (!context.mounted) return;
    _showQuickConnectCodeDialog(context);
  });
}

Future<void> _showQuickConnectCodeDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final code = await _promptQuickConnectCode(context);
  if (code == null || code.isEmpty || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);

  try {
    final client = GetIt.instance<MediaServerClient>();
    final userId = GetIt.instance<UserRepository>().currentUser?.id;
    final authorized = await client.authApi.authorizeQuickConnect(
      code,
      userId: userId,
    );

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          authorized
              ? l10n.quickConnectAuthorized
              : l10n.quickConnectInvalidOrExpired,
        ),
      ),
    );
  } on UnsupportedError {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.quickConnectNotSupported)),
    );
  } on DioException catch (e) {
    final message = _quickConnectErrorMessage(e, l10n);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.quickConnectAuthorizeFailed)),
    );
  }
}

String _quickConnectErrorMessage(DioException e, AppLocalizations l10n) {
  final status = e.response?.statusCode;
  final data = e.response?.data;
  final serverMessage = data is String
      ? data
      : (data is Map<String, dynamic>
            ? (data['message'] ?? data['Message'])?.toString()
            : null);

  if (status == 401) {
    return l10n.quickConnectDisabled;
  }

  if (status == 403) {
    return serverMessage ?? l10n.quickConnectForbidden;
  }

  if (status == 404) {
    return l10n.quickConnectNotFound;
  }

  if (serverMessage != null && serverMessage.isNotEmpty) {
    return l10n.quickConnectFailedWithMessage(serverMessage);
  }

  return l10n.quickConnectAuthorizeFailed;
}

Future<String?> _promptQuickConnectCode(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();

  String normalizedCode() => controller.text.replaceAll(RegExp(r'\D'), '');

  final code = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xE6141414),
      title: Text(l10n.quickConnect, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: l10n.quickConnectEnterCode,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
        onSubmitted: (_) {
          final value = normalizedCode();
          if (value.isNotEmpty) Navigator.pop(ctx, value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = normalizedCode();
            if (value.isNotEmpty) Navigator.pop(ctx, value);
          },
          child: Text(l10n.quickConnectAuthorize),
        ),
      ],
    ),
  );

  controller.dispose();
  return code;
}

class _MenuRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color contentColor;
  final bool autofocus;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.contentColor = const Color.fromRGBO(255, 255, 255, 0.8),
    this.autofocus = false,
  });

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
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
    final color = _isFocused ? focusColor : widget.contentColor;

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
              Icon(widget.icon, size: 20, color: color),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(fontSize: 16, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
