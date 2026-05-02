import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';

/// Centralised Dio builder. Keeps BaseOptions configuration in one place.
/// Datasource implementations call [DioFactory.create] rather than
/// constructing Dio inline.
class DioFactory {
  const DioFactory._();

  static Dio create({
    required String baseUrl,
    Map<String, dynamic>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool followRedirects = true,
    int maxRedirects = 5,
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: headers ?? const {},
        connectTimeout: connectTimeout ?? ApiConstants.connectTimeout,
        receiveTimeout: receiveTimeout ?? ApiConstants.receiveTimeout,
        followRedirects: followRedirects,
        // Pinned explicitly. Dio's default is also 5, but a future change to
        // the package or this factory could open an unbounded chain — and the
        // update-allowlist check trusts that the chain it walks is bounded.
        maxRedirects: maxRedirects,
      ),
    );
  }
}
