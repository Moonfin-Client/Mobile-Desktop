import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureServerDio(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();

      client.badCertificateCallback = (_, __, ___) => true;

      client.connectionTimeout = const Duration(seconds: 30);
      client.idleTimeout = const Duration(seconds: 120);

      client.maxConnectionsPerHost = 15;

      return client;
    },
  );
}