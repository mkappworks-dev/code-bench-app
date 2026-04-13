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
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: headers ?? const {},
        connectTimeout: connectTimeout ?? ApiConstants.connectTimeout,
        receiveTimeout: receiveTimeout ?? ApiConstants.receiveTimeout,
      ),
    );
  }
}
