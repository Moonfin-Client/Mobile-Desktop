import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../auth/models/user.dart';
import '../../../auth/repositories/server_repository.dart';
import '../../../auth/store/authentication_store.dart';
import '../../../data/services/emby_connect_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/destinations.dart';
import '../../widgets/login_scaffold.dart';
import '../../widgets/server_type_icon.dart';

enum _EmbyConnectPhase {
  credentials,
  authenticating,
  loadingServers,
  serverList,
  connectingToServer,
}

class EmbyConnectScreen extends StatefulWidget {
  const EmbyConnectScreen({super.key});

  @override
  State<EmbyConnectScreen> createState() => _EmbyConnectScreenState();
}

class _EmbyConnectScreenState extends State<EmbyConnectScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverRepo = GetIt.instance<ServerRepository>();
  final _authStore = GetIt.instance<AuthenticationStore>();
  final _connectService = EmbyConnectService(
    deviceInfo: GetIt.instance<DeviceInfo>(),
  );

  _EmbyConnectPhase _phase = _EmbyConnectPhase.credentials;
  List<EmbyConnectServer> _servers = const [];
  String? _errorMessage;
  String? _connectUserId;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _phase = _EmbyConnectPhase.authenticating;
      _errorMessage = null;
    });

    try {
      final auth = await _connectService.authenticate(
        username: username,
        password: _passwordController.text,
      );

      if (auth.accessToken.isEmpty || auth.user.id.isEmpty) {
        if (!mounted) return;
        setState(() {
          _phase = _EmbyConnectPhase.credentials;
          _errorMessage = AppLocalizations.of(context).invalidEmbyConnectCredentials;
        });
        return;
      }

      _connectUserId = auth.user.id;

      if (!mounted) return;
      setState(() => _phase = _EmbyConnectPhase.loadingServers);

      final servers = await _connectService.getServers(
        connectUserId: auth.user.id,
        connectAccessToken: auth.accessToken,
      );

      if (!mounted) return;

      if (servers.isEmpty) {
        setState(() {
          _phase = _EmbyConnectPhase.credentials;
          _errorMessage = AppLocalizations.of(context).noLinkedServers;
        });
        return;
      }

      _servers = servers;
      if (_servers.length == 1) {
        await _connectToServer(_servers.first);
      } else {
        setState(() => _phase = _EmbyConnectPhase.serverList);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _EmbyConnectPhase.credentials;
        _errorMessage = _dioMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _EmbyConnectPhase.credentials;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _connectToServer(EmbyConnectServer server) async {
    final connectUserId = _connectUserId;
    final username = _usernameController.text.trim();
    if (connectUserId == null || username.isEmpty) return;

    setState(() {
      _phase = _EmbyConnectPhase.connectingToServer;
      _errorMessage = null;
    });

    Object? lastError;

    final l10n = AppLocalizations.of(context);
    for (final address in server.candidateAddresses) {
      try {
        final exchange = await _connectService.exchange(
          serverAddress: address,
          connectUserId: connectUserId,
          accessKey: server.accessKey,
        );

        if (exchange.localUserId.isEmpty || exchange.accessToken.isEmpty) {
          lastError = l10n.invalidServerExchangeResponse;
          continue;
        }

        final connectedServer = await _serverRepo.addServer(address);
        if (connectedServer == null) {
          lastError = l10n.unableToConnectTo(address);
          continue;
        }

        await _authStore.putUser(
          PrivateUser(
            id: exchange.localUserId,
            name: username,
            serverId: connectedServer.id,
            accessToken: exchange.accessToken,
            lastUsed: DateTime.now(),
          ),
        );

        if (!mounted) return;
        context.go('${Destinations.server}?serverId=${connectedServer.id}');
        return;
      } on DioException catch (e) {
        lastError = _dioMessage(e);
      } catch (e) {
        lastError = e;
      }
    }

    if (!mounted) return;
    setState(() {
      _phase = _EmbyConnectPhase.serverList;
      _errorMessage =
          lastError?.toString() ?? l10n.unableToConnectTo(server.name);
    });
  }

  String _dioMessage(DioException e) {
    final l10n = AppLocalizations.of(context);
    final statusCode = e.response?.statusCode;
    if (statusCode == 400 || statusCode == 401) {
      return l10n.invalidEmbyConnectLogin;
    }
    if (statusCode == 404) {
      return l10n.embyConnectExchangeNotSupported;
    }
    return e.message ??
        l10n.embyConnectNetworkError;
  }

  void _resetAfterError() {
    setState(() {
      _errorMessage = null;
      _phase =
          _servers.isEmpty
              ? _EmbyConnectPhase.credentials
              : _EmbyConnectPhase.serverList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LoginScaffold(
      maxWidth: 700,
      header: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Image.asset('assets/images/logo_and_text.png', height: 80),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ServerTypeIcon(serverType: ServerType.emby, size: 28),
              const SizedBox(width: 10),
              Text(
                l10n.embyConnect,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.embyConnectSignInSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _EmbyConnectPhase.credentials:
      case _EmbyConnectPhase.authenticating:
        return _buildCredentialsView();
      case _EmbyConnectPhase.loadingServers:
        return _buildLoadingView(AppLocalizations.of(context).loadingLinkedServers);
      case _EmbyConnectPhase.serverList:
        return _buildServerListView();
      case _EmbyConnectPhase.connectingToServer:
        return _buildLoadingView(AppLocalizations.of(context).connectingToServerEllipsis);
    }
  }

  Widget _buildCredentialsView() {
    final l10n = AppLocalizations.of(context);
    final isBusy = _phase == _EmbyConnectPhase.authenticating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _usernameController,
          enabled: !isBusy,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(l10n.emailOrUsername),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          enabled: !isBusy,
          obscureText: true,
          onSubmitted: (_) => _signIn(),
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(l10n.password),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFef4444)),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    isBusy ? null : () => context.go(Destinations.serverSelect),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.back),
                ),
                style: _focusableButtonStyle(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : _signIn,
                icon:
                    isBusy
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.login, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.signIn),
                ),
                style: _focusableButtonStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServerListView() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectAServer,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._servers.map(_buildServerTile),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFef4444)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(Destinations.serverSelect),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.back),
                ),
                style: _focusableButtonStyle(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetAfterError,
                icon: const Icon(Icons.refresh, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.tryAgain),
                ),
                style: _focusableButtonStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServerTile(EmbyConnectServer server) {
    final subtitle =
        server.candidateAddresses.isNotEmpty
            ? server.candidateAddresses.first
            : AppLocalizations.of(context).noReachableAddress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _connectToServer(server),
          focusColor: const Color(0xFF00A4DC),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const ServerTypeIcon(serverType: ServerType.emby, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Column(
      children: [
        const SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00A4DC), width: 2),
      ),
    );
  }

  ButtonStyle _focusableButtonStyle() {
    return ButtonStyle(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered)) {
          return const BorderSide(color: Color(0xFF00A4DC), width: 2);
        }
        return BorderSide(color: Colors.white.withValues(alpha: 0.2));
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered)) {
          return const Color(0xFF00A4DC);
        }
        return Colors.white.withValues(alpha: 0.8);
      }),
    );
  }
}
