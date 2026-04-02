import 'package:dio/dio.dart';

/// Interceptor that follows HTTP redirects (301, 302, 307, 308) for all
/// request methods including POST/PUT, which Dart's HttpClient does not
/// follow automatically.
Interceptor redirectInterceptor(Dio dio) {
  return InterceptorsWrapper(
    onError: (error, handler) async {
      final statusCode = error.response?.statusCode;
      if (statusCode != null &&
          (statusCode == 301 ||
              statusCode == 302 ||
              statusCode == 307 ||
              statusCode == 308)) {
        final depth =
            (error.requestOptions.extra['_redirectDepth'] as int?) ?? 0;
        if (depth >= 5) return handler.next(error);
        final location = error.response?.headers.value('location');
        if (location != null && location.isNotEmpty) {
          final redirectUri = error.requestOptions.uri.resolve(location);
          try {
            final response = await dio.request(
              redirectUri.toString(),
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
                extra: {
                  ...error.requestOptions.extra,
                  '_redirectDepth': depth + 1,
                },
              ),
            );
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
      }
      handler.next(error);
    },
  );
}
