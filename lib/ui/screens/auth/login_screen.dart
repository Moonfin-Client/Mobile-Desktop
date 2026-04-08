import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../../auth/models/login_state.dart';
import '../../../auth/models/server.dart';
import '../../../auth/repositories/auth_repository.dart';
import '../../../auth/repositories/server_repository.dart';
import '../../../auth/repositories/session_repository.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../navigation/destinations.dart';
import '../../widgets/login_scaffold.dart';

const _kAccent = Color(0xFF00A4DC);

class LoginScreen extends StatefulWidget {
  final String serverId;
  final String? prefillUsername;

  const LoginScreen({super.key, required this.serverId, this.prefillUsername});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverRepo = GetIt.instance<ServerRepository>();
  final _authRepo = GetIt.instance<AuthRepository>();
  final _sessionRepo = GetIt.instance<SessionRepository>();
  final _clientFactory = GetIt.instance<MediaServerClientFactory>();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _signInFocus = FocusNode();
  final _backFocus = FocusNode();
  final _qcBtnFocus = FocusNode();
  final _pwBtnFocus = FocusNode();

  Server? _server;
  MediaServerClient? _client;
  bool _isLoading = false;
  String? _errorMessage;

  bool _supportsQuickConnect = false;
  bool _showQuickConnect = true;

  Timer? _quickConnectTimer;
  String? _quickConnectCode;
  String? _quickConnectSecret;

  bool get _hasUsername => widget.prefillUsername != null;

  @override
  void initState() {
    super.initState();
    if (widget.prefillUsername != null) {
      _usernameController.text = widget.prefillUsername!;
    }
    _setupFocusHandlers();
    _initServer();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _signInFocus.dispose();
    _backFocus.dispose();
    _qcBtnFocus.dispose();
    _pwBtnFocus.dispose();
    _quickConnectTimer?.cancel();
    super.dispose();
  }

  void _setupFocusHandlers() {
    _usernameFocus.onKeyEvent =
        (node, event) => _verticalNav(
          event,
          up: _supportsQuickConnect ? _pwBtnFocus : null,
          down: _passwordFocus,
        );
    _passwordFocus.onKeyEvent =
        (node, event) => _verticalNav(
          event,
          up:
              _hasUsername
                  ? (_supportsQuickConnect ? _pwBtnFocus : null)
                  : _usernameFocus,
          down: _signInFocus,
        );
  }

  KeyEventResult _verticalNav(
    KeyEvent event, {
    FocusNode? up,
    FocusNode? down,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && up != null) {
      up.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && down != null) {
      down.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _initServer() async {
    await _serverRepo.loadStoredServers();
    final server = _serverRepo.getServer(widget.serverId);
    if (server == null) {
      if (mounted) context.go(Destinations.serverSelect);
      return;
    }

    final client = _clientFactory.getClient(
      serverId: server.id,
      serverType: server.serverType,
      baseUrl: server.address,
    );

    final features = FeatureDetector(
      serverType: server.serverType,
      serverVersion: server.version,
    );

    if (mounted) {
      final supportsQC = features.supportsQuickConnect;
      setState(() {
        _server = server;
        _client = client;
        _supportsQuickConnect = supportsQC;
        _showQuickConnect = supportsQC;
      });
      if (supportsQC) {
        _startQuickConnect();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            (_hasUsername ? _passwordFocus : _usernameFocus).requestFocus();
          }
        });
      }
    }
  }

  void _selectQuickConnect() {
    if (_showQuickConnect) return;
    setState(() {
      _showQuickConnect = true;
      _errorMessage = null;
    });
    if (_quickConnectTimer == null) _startQuickConnect();
  }

  void _selectPassword() {
    if (!_showQuickConnect) return;
    _stopQuickConnect();
    setState(() {
      _showQuickConnect = false;
      _errorMessage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        (_hasUsername ? _passwordFocus : _usernameFocus).requestFocus();
      }
    });
  }

  Future<void> _startQuickConnect() async {
    final client = _client;
    if (client == null) return;

    try {
      final result = await client.authApi.initiateQuickConnect();
      final code = result['Code'] as String?;
      final secret = result['Secret'] as String?;
      if (code == null || secret == null) return;

      if (mounted) {
        setState(() {
          _quickConnectCode = code;
          _quickConnectSecret = secret;
        });
      }

      _quickConnectTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _pollQuickConnect(),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final detail =
          e.response?.data?.toString() ??
          e.error?.toString() ??
          e.message ??
          'unknown error';
      final l10n = AppLocalizations.of(context);
      setState(() {
        _errorMessage =
            status == null
                ? l10n.quickConnectUnavailableWithStatus(e.type.name, detail)
                : l10n.quickConnectUnavailableWithStatus('$status, ${e.type.name}', detail);
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _errorMessage = l10n.quickConnectUnavailable('$e'));
    }
  }

  Future<void> _pollQuickConnect() async {
    final client = _client;
    final secret = _quickConnectSecret;
    if (client == null || secret == null) return;

    try {
      final result = await client.authApi.checkQuickConnect(secret);
      final authenticated = result['Authenticated'] as bool? ?? false;
      if (authenticated) {
        _stopQuickConnect();
        final authResult = await _authRepo.authenticateWithQuickConnect(
          client: client,
          serverId: _server!.id,
          secret: secret,
        );
        if (authResult is Authenticated && mounted) {
          await _sessionRepo.switchCurrentSession(
            serverId: authResult.serverId,
            userId: authResult.userId,
          );
          if (mounted) context.go(Destinations.home);
        }
      }
    } catch (_) {}
  }

  void _stopQuickConnect() {
    _quickConnectTimer?.cancel();
    _quickConnectTimer = null;
    if (mounted) {
      setState(() {
        _quickConnectCode = null;
        _quickConnectSecret = null;
      });
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || _client == null || _server == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authRepo.authenticate(
      client: _client!,
      serverId: _server!.id,
      username: username,
      password: _passwordController.text,
    );

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    switch (result) {
      case Authenticated():
        await _sessionRepo.switchCurrentSession(
          serverId: result.serverId,
          userId: result.userId,
          username: username,
          password: _passwordController.text,
        );
        if (mounted) context.go(Destinations.home);
      case ApiClientError(:final error):
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      case ServerUnavailable():
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.serverUnavailable;
        });
      default:
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.loginFailed;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_server == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);

    return LoginScaffold(
      maxWidth: 600,
      header: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Image.asset('assets/images/logo_and_text.png', height: 64),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.signIn,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.connectingToServer(_server!.name),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          if (_supportsQuickConnect) ...[
            _buildToggleRow(),
            const SizedBox(height: 24),
            if (_showQuickConnect)
              _buildQuickConnectContent()
            else
              _buildCredentialsContent(),
          ] else
            _buildCredentialsContent(),
        ],
      ),
    );
  }

  Widget _buildToggleRow() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildToggleButton(
          label: l10n.quickConnect,
          isSelected: _showQuickConnect,
          focusNode: _qcBtnFocus,
          onPressed: _selectQuickConnect,
        ),
        _buildToggleButton(
          label: l10n.password,
          isSelected: !_showQuickConnect,
          focusNode: _pwBtnFocus,
          onPressed: _selectPassword,
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required FocusNode focusNode,
    required VoidCallback onPressed,
  }) {
    if (isSelected) {
      return FilledButton(
        focusNode: focusNode,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 44),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: Colors.white, width: 2);
            }
            return null;
          }),
        ),
        child: Text(label),
      );
    }
    return OutlinedButton(
      focusNode: focusNode,
      onPressed: onPressed,
      style: _outlinedFocusStyle(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ).copyWith(minimumSize: const WidgetStatePropertyAll(Size(120, 44))),
      child: Text(label),
    );
  }

  ButtonStyle _outlinedFocusStyle({required EdgeInsetsGeometry padding}) {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white.withValues(alpha: 0.8),
      padding: padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ).copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: _kAccent, width: 2);
        }
        return BorderSide(color: Colors.white.withValues(alpha: 0.2));
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return _kAccent;
        return Colors.white.withValues(alpha: 0.8);
      }),
    );
  }

  Widget _buildQuickConnectContent() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.quickConnectInstruction,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (_quickConnectCode != null) ...[
          Text(
            _formatCode(_quickConnectCode!),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: _kAccent,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kAccent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.waitingForAuthorization,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ] else
          const CircularProgressIndicator(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFef4444)),
          ),
        ],
        const SizedBox(height: 24),
        _buildActionButton(
          label: l10n.back,
          focusNode: _backFocus,
          onPressed:
              () =>
                  context.go('${Destinations.server}?serverId=${_server!.id}'),
        ),
      ],
    );
  }

  Widget _buildCredentialsContent() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_hasUsername) ...[
          _buildTextField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            label: l10n.username,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
        ],
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: l10n.password,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Color(0xFFef4444)),
          ),
        ],
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              label: l10n.back,
              focusNode: _backFocus,
              onPressed:
                  () => context.go(
                    '${Destinations.server}?serverId=${_server!.id}',
                  ),
            ),
            _buildActionButton(
              label: l10n.signIn,
              focusNode: _signInFocus,
              onPressed: _isLoading ? null : _login,
              isLoading: _isLoading,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    bool obscureText = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      enabled: !_isLoading,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
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
          borderSide: const BorderSide(color: _kAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required FocusNode focusNode,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return OutlinedButton(
      focusNode: focusNode,
      onPressed: onPressed,
      style: _outlinedFocusStyle(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
      child:
          isLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Text(label),
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) return '${code.substring(0, 3)} ${code.substring(3)}';
    return code;
  }
}
