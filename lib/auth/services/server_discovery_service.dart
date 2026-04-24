import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:server_core/server_core.dart';

class DiscoveredServer {
  final String id;
  final String name;
  final String address;
  final ServerType serverType;

  const DiscoveredServer({
    required this.id,
    required this.name,
    required this.address,
    required this.serverType,
  });
}

class ServerDiscoveryService {
  static const _discoveryPort = 7359;
  static const _jellyfinMessage = 'who is JellyfinServer?';
  static const _embyMessage = 'who is EmbyServer?';
  static const _listenDuration = Duration(milliseconds: 2500);
  static const _rebroadcastInterval = Duration(milliseconds: 800);

  Stream<DiscoveredServer> discoverLocalServers() async* {
    final controller = StreamController<DiscoveredServer>();
    final seen = <String>{};
    RawDatagramSocket? socket;
    Timer? rebroadcastTimer;
    Timer? stopTimer;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final broadcastAddresses = await _getBroadcastAddresses();
      final jellyfinData = utf8.encode(_jellyfinMessage);
      final embyData = utf8.encode(_embyMessage);

      void sendBroadcasts() {
        for (final addr in broadcastAddresses) {
          try {
            socket!.send(jellyfinData, addr, _discoveryPort);
            socket.send(embyData, addr, _discoveryPort);
          } catch (_) {}
        }
      }

      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket!.receive();
        if (datagram == null) return;
        final response = utf8.decode(datagram.data);
        final server = _parseResponse(response);
        if (server == null) return;
        if (seen.add(server.id)) {
          controller.add(server);
        }
      });

      sendBroadcasts();
      rebroadcastTimer = Timer.periodic(_rebroadcastInterval, (_) {
        sendBroadcasts();
      });
      stopTimer = Timer(_listenDuration, () {
        if (!controller.isClosed) controller.close();
      });

      yield* controller.stream;
    } catch (_) {
      if (!controller.isClosed) await controller.close();
    } finally {
      rebroadcastTimer?.cancel();
      stopTimer?.cancel();
      socket?.close();
      if (!controller.isClosed) await controller.close();
    }
  }

  DiscoveredServer? _parseResponse(String response) {
    try {
      final data = jsonDecode(response) as Map<String, dynamic>;
      final address = data['Address'] as String?;
      final id = data['Id'] as String?;
      if (address == null || id == null) return null;

      final name = data['Name'] as String? ?? id;

      final serverType = name.toLowerCase().contains('emby')
          ? ServerType.emby
          : ServerType.jellyfin;

      return DiscoveredServer(
        id: id,
        name: name,
        address: address,
        serverType: serverType,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<InternetAddress>> _getBroadcastAddresses() async {
    final addresses = <InternetAddress>[InternetAddress('255.255.255.255')];
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final broadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              final broadcastAddr = InternetAddress(broadcast);
              if (!addresses.any((a) => a.address == broadcastAddr.address)) {
                addresses.add(broadcastAddr);
              }
            }
          }
        }
      }
    } catch (_) {}
    return addresses;
  }
}
