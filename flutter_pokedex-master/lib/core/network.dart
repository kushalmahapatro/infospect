import 'package:dio/dio.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:pokedex/core/utils.dart';

class NetworkManager {
  final Dio dio;

  const NetworkManager._(this.dio);

  factory NetworkManager(Infospect infospect) {
    final dio = Dio();

    dio.interceptors.add(infospect.dioInterceptor);

    //
    // dio.interceptors.add(DioCacheManager(CacheConfig(
    //   defaultMaxAge: Duration(days: 10),
    //   maxMemoryCacheCount: 3,
    // )).interceptor);

    return NetworkManager._(dio);
  }

  Future<Response<T>> request<T>(
    RequestMethod method,
    String url, {
    data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.request(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        method: method.value,
        headers: headers,
      ),
    );
  }
}

enum RequestMethod {
  get,
  head,
  post,
  put,
  delete,
  connect,
  options,
  trace,
  patch,
}

extension RequestMethodX on RequestMethod {
  String get value => getEnumValue(this).toUpperCase();
}
