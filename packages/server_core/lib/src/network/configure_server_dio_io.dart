import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureServerDio(Dio dio) {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      return client;
    },
  );
}