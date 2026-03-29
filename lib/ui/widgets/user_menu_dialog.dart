import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

import '../../auth/repositories/session_repository.dart';
import '../../preference/user_preferences.dart';
import '../../auth/repositories/user_repository.dart';
import '../navigation/destinations.dart';
import 'remote_control_dialog.dart';

const _kAccent = Color(0xFF00A4DC);

enum _UserMenuAction { quickConnect }

void showUserMenu(BuildContext context) {
  final userRepo = GetIt.instance<UserRepository>();
  final user = userRepo.currentUser;

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
                      user?.name ?? 'User',
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
              label: 'Switch User',
              autofocus: true,
              onTap: () {
                Navigator.pop(ctx);
                context.go(Destinations.serverSelect);
              },
            ),
            _MenuRow(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () {
                Navigator.pop(ctx);
                context.push(Destinations.settings);
              },
            ),
            _MenuRow(
              icon: Icons.phonelink_lock_rounded,
              label: 'Quick Connect',
              onTap: () {
                Navigator.pop(ctx, _UserMenuAction.quickConnect);
              },
            ),
            _MenuRow(
              icon: Icons.download_done_rounded,
              label: 'Saved Media',
              onTap: () {
                Navigator.pop(ctx);
                context.push(Destinations.downloads);
              },
            ),
            _MenuRow(
              icon: Icons.settings_remote_rounded,
              label: 'Remote Control',
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
              label: 'Sign Out',
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
              ? 'Quick Connect request authorized.'
              : 'Quick Connect code is invalid or expired.',
        ),
      ),
    );
  } on UnsupportedError {
    messenger.showSnackBar(
      const SnackBar(content: Text('Quick Connect is not supported on this server.')),
    );
  } on DioException catch (e) {
    final message = _quickConnectErrorMessage(e);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Failed to authorize Quick Connect code.')),
    );
  }
}

String _quickConnectErrorMessage(DioException e) {
  final status = e.response?.statusCode;
  final data = e.response?.data;
  final serverMessage = data is String
      ? data
      : (data is Map<String, dynamic>
            ? (data['message'] ?? data['Message'])?.toString()
            : null);

  if (status == 401) {
    return 'Quick Connect is disabled on this server.';
  }

  if (status == 403) {
    return serverMessage ?? 'Your account cannot authorize this Quick Connect request.';
  }

  if (status == 404) {
    return 'Quick Connect code was not found. Try a new code.';
  }

  if (serverMessage != null && serverMessage.isNotEmpty) {
    return 'Quick Connect failed: $serverMessage';
  }

  return 'Failed to authorize Quick Connect code.';
}

Future<String?> _promptQuickConnectCode(BuildContext context) async {
  final controller = TextEditingController();

  String normalizedCode() => controller.text.replaceAll(RegExp(r'\D'), '');

  final code = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xE6141414),
      title: const Text('Quick Connect', style: TextStyle(color: Colors.white)),
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
          hintText: 'Enter code',
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = normalizedCode();
            if (value.isNotEmpty) Navigator.pop(ctx, value);
          },
          child: const Text('Authorize'),
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
