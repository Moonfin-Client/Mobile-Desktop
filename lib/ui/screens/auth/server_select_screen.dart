import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../auth/models/server.dart';
import '../../../auth/models/server_addition_state.dart';
import '../../../auth/repositories/server_repository.dart';
import '../../../auth/services/server_discovery_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/destinations.dart';
import '../../widgets/login_scaffold.dart';
import '../../widgets/server_type_icon.dart';

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
    final confirmed = await showDialog<bool>(
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
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        foregroundColor: Colors.white.withValues(alpha: 0.8),
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
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          focusColor: const Color(0xFF00A4DC),
          hoverColor: const Color(0xFF00A4DC).withValues(alpha: 0.3),
          onTap: () =>
              context.go('${Destinations.server}?serverId=${server.id}'),
          onLongPress: () => _deleteServer(server),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ),
      ),
    );
  }

  Widget _buildDiscoveredServerTile(DiscoveredServer server) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          focusColor: const Color(0xFF00A4DC),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          onTap: _isConnecting ? null : () => _connectToDiscovered(server),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ),
      ),
    );
  }

  Future<void> _showAddServerDialog() async {
    final l10n = AppLocalizations.of(context);
    _addressController.clear();
    final address = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.connectToServer),
        content: TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: l10n.serverAddress,
            hintText: l10n.serverAddressHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.dns),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_addressController.text),
            child: Text(l10n.connect),
          ),
        ],
      ),
    );
    if (address != null && address.trim().isNotEmpty) {
      await _serverRepo.addServer(address.trim());
    }
  }
}
