import 'dart:async';

import 'package:custom_tv_text_field/custom_tv_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../auth/models/server.dart';
import '../../../auth/models/server_addition_state.dart';
import '../../../auth/repositories/server_repository.dart';
import '../../../auth/services/server_discovery_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../util/focus/dpad_keys.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/login_scaffold.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/server_type_icon.dart';

const _kAccent = Color(0xFF00A4DC);

class ServerSelectScreen extends StatefulWidget {
  const ServerSelectScreen({super.key});

  @override
  State<ServerSelectScreen> createState() => _ServerSelectScreenState();
}

class _ServerSelectScreenState extends State<ServerSelectScreen> {
  final _addressController = TextEditingController();
  final _serverRepo = GetIt.instance<ServerRepository>();
  final _deviceInfo = GetIt.instance<DeviceInfo>();
  final _discoveryService = ServerDiscoveryService();
  StreamSubscription<ServerAdditionState>? _additionSub;
  StreamSubscription<DiscoveredServer>? _discoverySub;

  bool _isConnecting = false;
  String? _errorMessage;

  final List<DiscoveredServer> _discoveredServers = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
    _additionSub = _serverRepo.additionState.listen(_onAdditionState);
    _startDiscovery();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _additionSub?.cancel();
    _discoverySub?.cancel();
    super.dispose();
  }

  Future<void> _loadServers() async {
    await _serverRepo.loadStoredServers();
    if (mounted) setState(() {});
  }

  void _startDiscovery() {
    setState(() => _isDiscovering = true);
    _discoveredServers.clear();

    _discoverySub?.cancel();
    _discoverySub = _discoveryService.discoverLocalServers().listen(
      (server) {
        final savedAddresses = _serverRepo.servers
            .map((s) => s.address)
            .toSet();
        if (!savedAddresses.contains(server.address)) {
          if (mounted) {
            setState(() => _discoveredServers.add(server));
          }
        }
      },
      onDone: () {
        if (mounted) setState(() => _isDiscovering = false);
      },
      onError: (_) {
        if (mounted) setState(() => _isDiscovering = false);
      },
    );
  }

  void _onAdditionState(ServerAdditionState state) {
    if (!mounted) return;
    switch (state) {
      case ServerConnecting():
        setState(() {
          _isConnecting = true;
          _errorMessage = null;
        });
      case ServerConnected(:final id):
        setState(() => _isConnecting = false);
        _addressController.clear();
        context.go('${Destinations.server}?serverId=$id');
      case ServerUnableToConnect():
        setState(() {
          _isConnecting = false;
          _errorMessage = AppLocalizations.of(context).unableToConnectToServer;
        });
    }
  }

  Future<void> _connectToDiscovered(DiscoveredServer discovered) async {
    await _serverRepo.addServer(discovered.address);
  }

  Future<void> _deleteServer(Server server) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFocusRestoringDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeServer),
        content: Text(l10n.removeServerConfirmation(server.name)),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _serverRepo.deleteServer(server.id);
      if (mounted) setState(() {});
    }
  }

  Widget _buildFooterActionButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: const TextStyle(fontSize: 15),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
      ).copyWith(
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            return const BorderSide(color: _kAccent, width: 2);
          }
          return BorderSide(color: Colors.white.withValues(alpha: 0.2));
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            return _kAccent;
          }
          return Colors.white.withValues(alpha: 0.8);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servers = _serverRepo.servers;
    final l10n = AppLocalizations.of(context);

    return LoginScaffold(
      header: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Image.asset('assets/images/logo_and_text.png', height: 80),
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          l10n.appVersionFooter(_deviceInfo.appVersion),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.4),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (servers.isNotEmpty) ...[
            Text(
              l10n.savedServers,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...servers.map((server) => _buildSavedServerTile(server)),
            const SizedBox(height: 20),
          ],
          Text(
            l10n.discoveredServers,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_discoveredServers.isNotEmpty)
            ..._discoveredServers.map(
              (server) => _buildDiscoveredServerTile(server),
            )
          else if (_isDiscovering)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.noneFound,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ),
          if (_isDiscovering && _discoveredServers.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 8),
              child: Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFef4444), fontSize: 14),
              ),
            ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isVerySmall = constraints.maxWidth < 360;
              final addServerButton = _buildFooterActionButton(
                onPressed: _isConnecting ? null : _showAddServerDialog,
                icon: const Icon(Icons.add, size: 16),
                label: l10n.addServer,
              );

              final embyConnectButton = _buildFooterActionButton(
                onPressed: _isConnecting
                    ? null
                    : () => context.go(Destinations.embyConnect),
                icon: const ServerTypeIcon(
                  serverType: ServerType.emby,
                  size: 16,
                ),
                label: l10n.embyConnect,
              );

              if (isVerySmall) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: addServerButton),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: embyConnectButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: addServerButton),
                  const SizedBox(width: 8),
                  Expanded(child: embyConnectButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavedServerTile(Server server) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _FocusableTile(
        onTap: () =>
            context.go('${Destinations.server}?serverId=${server.id}'),
        onLongPress: () => _deleteServer(server),
        child: Row(
          children: [
            ServerTypeIcon(
              serverType: server.serverType,
              size: 24,
              color: Colors.white.withValues(alpha: 0.7),
            ),
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
                    '${server.address} • ${server.version}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredServerTile(DiscoveredServer server) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _FocusableTile(
        onTap: _isConnecting ? null : () => _connectToDiscovered(server),
        child: Row(
          children: [
            ServerTypeIcon(
              serverType: server.serverType,
              size: 24,
              color: Colors.white.withValues(alpha: 0.7),
            ),
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
                    server.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAddDialogOpen = false;

  Future<void> _showAddServerDialog() async {
    if (_isAddDialogOpen) return;
    _isAddDialogOpen = true;
    final l10n = AppLocalizations.of(context);
    _addressController.clear();
    try {
      final address = await showFocusRestoringDialog<String>(
        context: context,
        builder: (ctx) => _AddServerDialog(
          l10n: l10n,
          controller: _addressController,
        ),
      );
      if (address != null && address.trim().isNotEmpty) {
        await _serverRepo.addServer(address.trim());
      }
    } finally {
      _isAddDialogOpen = false;
    }
  }
}

class _FocusableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _FocusableTile({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_FocusableTile> createState() => _FocusableTileState();
}

class _FocusableTileState extends State<_FocusableTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: _focused
          ? _kAccent.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.05),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        focusColor: _kAccent.withValues(alpha: 0.2),
        hoverColor: _kAccent.withValues(alpha: 0.12),
        onFocusChange: (f) => setState(() => _focused = f),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _focused ? _kAccent : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: widget.child,
        ),
      ),
    );
  }
}

class _AddServerDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final TextEditingController controller;

  const _AddServerDialog({required this.l10n, required this.controller});

  @override
  State<_AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<_AddServerDialog> {
  final _addressFocus = FocusNode(debugLabel: 'addServerAddress');
  final _connectFocus = FocusNode(debugLabel: 'addServerConnect');
  final _cancelFocus = FocusNode(debugLabel: 'addServerCancel');
  final _tvFieldKey = GlobalKey<CustomTVTextFieldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _addressFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _addressFocus.dispose();
    _connectFocus.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(widget.controller.text);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  KeyEventResult _onDialogKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key.isBackKey) {
      if (event is KeyDownEvent) {
        _cancel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (!PlatformDetection.isTV) return KeyEventResult.ignored;

    final onField = _addressFocus.hasFocus;
    final onCancel = _cancelFocus.hasFocus;
    final onConnect = _connectFocus.hasFocus;

    if (onField) {
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select) {
        _tvFieldKey.currentState?.openKeyboard();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _connectFocus.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (onCancel || onConnect) {
      if (key == LogicalKeyboardKey.arrowUp) {
        _addressFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft && onConnect) {
        _cancelFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight && onCancel) {
        _connectFocus.requestFocus();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  ButtonStyle _actionStyle() {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ).copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered)) {
          return const BorderSide(color: _kAccent, width: 2);
        }
        return BorderSide(color: Colors.white.withValues(alpha: 0.2));
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered)) {
          return _kAccent;
        }
        return Colors.white.withValues(alpha: 0.85);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isTV = PlatformDetection.isTV;

    final field = isTV
        ? Focus(
            focusNode: _addressFocus,
            child: ListenableBuilder(
              listenable: _addressFocus,
              builder: (_, _) {
                final focused = _addressFocus.hasFocus;
                return CustomTVTextField(
                  key: _tvFieldKey,
                  controller: widget.controller,
                  isFocused: focused,
                  hint: l10n.serverAddressHint,
                  textFieldType: TextFieldType.url,
                  keyboardType: KeyboardType.alphabetic,
                  filled: true,
                  fillColor: focused
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.08),
                  borderColor: Theme.of(context).colorScheme.outline,
                  focusedBorderColor: _kAccent,
                  hintStyle: TextStyle(
                    color: focused
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  textStyle: TextStyle(
                    color: focused ? Colors.black : Colors.white,
                  ),
                  prefixIcon: Icon(
                    Icons.dns,
                    color: focused ? Colors.black : Colors.white,
                  ),
                  onFieldSubmitted: (value) =>
                      Navigator.of(context).pop(value),
                );
              },
            ),
          )
        : TextField(
            controller: widget.controller,
            focusNode: _addressFocus,
            decoration: InputDecoration(
              labelText: l10n.serverAddress,
              hintText: l10n.serverAddressHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.dns),
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          );

    final cancelButton = OutlinedButton(
      focusNode: _cancelFocus,
      onPressed: _cancel,
      style: _actionStyle(),
      child: Text(l10n.cancel),
    );

    final connectButton = OutlinedButton(
      focusNode: _connectFocus,
      onPressed: _submit,
      style: _actionStyle(),
      child: Text(l10n.connect),
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onDialogKey,
      child: AlertDialog(
        title: Text(l10n.connectToServer),
        content: field,
        actions: [cancelButton, connectButton],
      ),
    );
  }
}
