import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../auth/models/server.dart';
import '../../../auth/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../auth/repositories/server_repository.dart';
import '../../../auth/repositories/server_user_repository.dart';
import '../../../auth/repositories/session_repository.dart';
import '../../../auth/models/login_state.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../util/pin_code_util.dart';
import '../../navigation/destinations.dart';
import '../../widgets/login_scaffold.dart';
import '../../widgets/pin_entry_dialog.dart';

class ServerScreen extends StatefulWidget {
  final String serverId;
  const ServerScreen({super.key, required this.serverId});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  final _serverRepo = GetIt.instance<ServerRepository>();
  final _userRepo = GetIt.instance<ServerUserRepository>();
  final _authRepo = GetIt.instance<AuthRepository>();
  final _sessionRepo = GetIt.instance<SessionRepository>();
  final _clientFactory = GetIt.instance<MediaServerClientFactory>();

  Server? _server;
  List<_MergedUser> _users = [];
  bool _isLoading = true;
  final _scrollController = ScrollController();
  final List<FocusNode> _userFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _serverRepo.loadStoredServers();
    final server = _serverRepo.getServer(widget.serverId);
    if (server == null) {
      if (mounted) context.go(Destinations.serverSelect);
      return;
    }

    final stored = _userRepo.getStoredServerUsers(server.id);
    final publicUsers = await _userRepo.getPublicServerUsers(server);

    final merged = <String, _MergedUser>{};
    for (final u in stored) {
      merged[u.id] = _MergedUser(id: u.id, name: u.name, imageTag: u.imageTag, hasToken: true, hasPassword: true);
    }
    for (final u in publicUsers) {
      merged.putIfAbsent(u.id, () => _MergedUser(id: u.id, name: u.name, imageTag: u.imageTag, hasToken: false, hasPassword: u.hasPassword));
    }

    if (mounted) {
      for (final node in _userFocusNodes) {
        node.dispose();
      }
      final allUsers = merged.values.toList();
      _userFocusNodes.clear();
      _userFocusNodes.addAll(List.generate(allUsers.length, (_) => FocusNode()));

      setState(() {
        _server = server;
        _users = allUsers;
        _isLoading = false;
      });

      if (allUsers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _userFocusNodes.isNotEmpty) {
            _userFocusNodes[0].requestFocus();
          }
        });
      }
    }
  }

  Future<void> _onUserTap(_MergedUser user) async {
    final server = _server!;
    final store = GetIt.instance<PreferenceStore>();
    final pinUtil = PinCodeUtil(store, user.id);

    if (pinUtil.isPinEnabled) {
      final verified = await PinEntryDialog.show(
        context,
        mode: PinEntryMode.verify,
        onVerify: pinUtil.verifyPin,
        onForgotPin: () {
          if (mounted) {
            context.go('${Destinations.login}?serverId=${server.id}&username=${Uri.encodeComponent(user.name)}');
          }
        },
      );
      if (!verified) return;
    }

    if (user.hasToken) {
      final success = await _sessionRepo.switchCurrentSession(
        serverId: server.id,
        userId: user.id,
      );
      if (success && mounted) {
        context.go(Destinations.home);
        return;
      }
    }

    if (!user.hasPassword) {
      final client = _clientFactory.getClient(
        serverId: server.id,
        serverType: server.serverType,
        baseUrl: server.address,
      );
      final result = await _authRepo.authenticate(
        client: client,
        serverId: server.id,
        username: user.name,
        password: '',
      );
      if (result is Authenticated && mounted) {
        await _sessionRepo.switchCurrentSession(serverId: server.id, userId: result.userId);
        if (mounted) context.go(Destinations.home);
        return;
      }
    }

    if (mounted) {
      context.go('${Destinations.login}?serverId=${server.id}&username=${Uri.encodeComponent(user.name)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final server = _server!;
    final l10n = AppLocalizations.of(context);
    return LoginScaffold(
      header: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Image.asset('assets/images/logo_and_text.png', height: 80),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            server.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.whosWatching,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (server.loginDisclaimer != null && server.loginDisclaimer!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              server.loginDisclaimer!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          _buildUserRow(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('${Destinations.login}?serverId=${_server!.id}'),
                  icon: const Icon(Icons.person, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.addUser),
                  ),
                  style: _focusableButtonStyle(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(Destinations.serverSelect),
                  icon: const Icon(Icons.home, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.selectServer),
                  ),
                  style: _focusableButtonStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _focusableButtonStyle() {
    return ButtonStyle(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) || states.contains(WidgetState.hovered)) {
          return const BorderSide(color: Color(0xFF00A4DC), width: 2);
        }
        return BorderSide(color: Colors.white.withValues(alpha: 0.2));
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) || states.contains(WidgetState.hovered)) {
          return const Color(0xFF00A4DC);
        }
        return Colors.white.withValues(alpha: 0.8);
      }),
    );
  }

  Widget _buildUserRow() {
    final items = <Widget>[
      for (var i = 0; i < _users.length; i++)
        _buildUserCard(_users[i], i),
    ];

    final listView = SizedBox(
      height: 130,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        children: items,
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        listView,
        Positioned(
          left: -40,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              onPressed: () => _scrollController.animateTo(
                (_scrollController.offset - 150).clamp(0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              icon: const Icon(Icons.chevron_left, color: Colors.white54, size: 28),
              splashRadius: 20,
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              onPressed: () => _scrollController.animateTo(
                (_scrollController.offset + 150).clamp(0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              icon: const Icon(Icons.chevron_right, color: Colors.white54, size: 28),
              splashRadius: 20,
            ),
          ),
        ),
      ],
    );
  }

  String _userImageUrl(_MergedUser user) {
    final server = _server!;
    return '${server.address}/Users/${user.id}/Images/Primary?tag=${user.imageTag}';
  }

  Widget _buildUserCard(_MergedUser user, int index) {
    final hasFocus = ValueNotifier(false);
    final focusNode = index < _userFocusNodes.length ? _userFocusNodes[index] : FocusNode();

    return ValueListenableBuilder<bool>(
      valueListenable: hasFocus,
      builder: (context, focused, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 110,
            child: InkWell(
              focusNode: focusNode,
              onFocusChange: (f) => hasFocus.value = f,
              onTap: () => _onUserTap(user),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: focused
                            ? Border.all(color: const Color(0xFF00A4DC), width: 3)
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        backgroundImage: user.imageTag != null
                            ? NetworkImage(_userImageUrl(user))
                            : null,
                        child: user.imageTag == null
                            ? Icon(Icons.person, size: 32, color: Colors.white.withValues(alpha: 0.6))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: focused ? const Color(0xFF00A4DC) : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final node in _userFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

class _MergedUser {
  final String id;
  final String name;
  final String? imageTag;
  final bool hasToken;
  final bool hasPassword;

  const _MergedUser({
    required this.id,
    required this.name,
    this.imageTag,
    required this.hasToken,
    required this.hasPassword,
  });
}
