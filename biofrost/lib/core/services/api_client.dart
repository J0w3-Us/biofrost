import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  /// Creates an ApiClient. Default baseUrl targets Android emulator host.
  factory ApiClient({String? baseUrl}) {
    final effective = baseUrl ?? 'http://10.0.2.2:5093';
    final dio = Dio(BaseOptions(baseUrl: effective, connectTimeout: Duration(milliseconds: 5000), receiveTimeout: Duration(milliseconds: 5000)));
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    return ApiClient._(dio);
  }

  Future<Response> post(String path, dynamic data) => dio.post(path, data: data);
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) => dio.get(path, queryParameters: queryParameters);
}
