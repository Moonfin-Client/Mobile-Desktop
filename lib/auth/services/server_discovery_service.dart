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
  static const _receiveTimeoutMs = 5000;
  static const _discoveryRounds = 3;
  static const _roundDelay = Duration(milliseconds: 1500);

  Stream<DiscoveredServer> discoverLocalServers() async* {
    final seen = <String>{};

    for (var round = 0; round < _discoveryRounds; round++) {
      try {
        final servers = await _sendDiscoveryBroadcast();
        for (final server in servers) {
          if (seen.add(server.id)) {
            yield server;
          }
        }
      } catch (_) {}

      if (round < _discoveryRounds - 1) {
        await Future.delayed(_roundDelay);
      }
    }
  }

  Future<List<DiscoveredServer>> _sendDiscoveryBroadcast() async {
    final results = <DiscoveredServer>[];
    RawDatagramSocket? socket;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final broadcastAddresses = await _getBroadcastAddresses();

      final jellyfinData = utf8.encode(_jellyfinMessage);
      final embyData = utf8.encode(_embyMessage);
      for (final addr in broadcastAddresses) {
        socket.send(jellyfinData, addr, _discoveryPort);
        socket.send(embyData, addr, _discoveryPort);
      }

      final completer = Completer<List<DiscoveredServer>>();
      final timer = Timer(Duration(milliseconds: _receiveTimeoutMs), () {
        if (!completer.isCompleted) completer.complete(results);
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram != null) {
            final response = utf8.decode(datagram.data);
            final server = _parseResponse(response);
            if (server != null) results.add(server);
          }
        }
      });

      await completer.future;
      timer.cancel();
    } finally {
      socket?.close();
    }

    return results;
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
